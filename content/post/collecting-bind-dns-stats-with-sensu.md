+++
description = ""
author = "Steve Morrissey"
tags = [
    "sensu",
    "bind",
    "monitoring",
    "dns",
    "grafana",
    "graphite"
]
date = "2017-01-12T22:14:11-06:00"
title = "collecting bind dns stats with sensu"

+++
[![grafana graph](/img/bind-grafana-lead.png)](/img/bind-grafana-lead.png)

Recently I migrated off of AWS Route53 to my own BIND servers for a few of my domains. I didn't do this because I think I can do DNS better than the folks at Amazon. Instead, I'm looking to collect some detailed statistics about DNS usage and running my own DNS servers was the path of least resistance to reach that goal.

## Prepping the DNS servers

My DNS setup is fairly typical, with a master and slave DNS server, each one located on different sides of the US. The master, `ns1.stevem.io`, is in New York, NY while the slave, `ns2.stevem.io` is in San Francisco, CA.

First thing to do is ensure statistics are enabled for BIND. In my `/etc/bind/named.conf.options` file on BOTH of my DNS servers I have:
```
options {
    ...

    // enable statistics
    statistics-file "named.stats";
    zone-statistics yes;
    
    ...
}

statistics-channels {
        inet 0.0.0.0 port 8080 allow { MY.EXTERNAL.IP.1; MY.EXTERNAL.IP.2; };
};
```

What this does is write a statistics file to `/var/cache/bind/named.stats` as well as enable the statistics HTTP endpoint on port `8080` from two external IP addresses. In this case I'm having it bind to `0.0.0.0` so I can reach the stats page by hitting either one of the public IPs assigned to the DNS server.

After making this change I simply issued a `systemctl restart bind9` and things were working as intended. Visiting `http://ns1.stevem.io:8080/` in my web browser presented a formatted page of statistics, while using curl to grab that URL gave me raw XML. It's the XML that my script parses to build out the metrics.

## Sensu Metric script

Now that our BIND servers are configured for statistic output on port 8080 we just need a script we can have a Sensu Client execute to begin gathering the metrics. I created a script named `metric-bind9-xml.rb` with the following contents:
```
#! /usr/bin/env ruby

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/metric/cli'
require 'nokogiri'
require 'open-uri'
require 'socket'
require 'uri'

class MetricBind < Sensu::Plugin::Metric::CLI::Graphite
  option :url, short: '-u URL'
  option :scheme, short: '-s SCHEME', default: "#{Socket.gethostname}.bind"

  def run
    if !config[:url]
      # #YELLOW
      unknown 'No URL specified'
    end
    acquire_resource
  end

  def acquire_resource
    doc = Nokogiri::XML(open(config[:url]))
    uri = URI(config[:url])

    if uri.host
      config[:scheme] = "#{uri.host}.bind"
    end

    results = {}

    # store the qtype counters (query types)
    doc.xpath('//server//counters[@type="qtype"]//counter').each do |row|
      results.store("counter.qtype.#{row.attr('name')}", row.text)
    end

    # store the nsstat counters
    doc.xpath('//server//counters[@type="nsstat"]//counter').each do |row|
      results.store("counter.nsstat.#{row.attr('name')}", row.text)
    end

    # loop through zones
    doc.xpath('//views//view[@name="_default"]//zones//zone').each do |zone|
      zone_name = zone.attr('name').gsub(/\./, '_')
      zone.xpath('counters//counter').each do |counter|
        results.store("zone.#{zone_name}.#{counter.attr('name')}", counter.text)
      end
    end

    results.each do |k,v|
      output "#{config[:scheme]}.#{k}", v
    end

    ok

  end
end
```

This is a pretty simple script that uses the `nokogiri` gem to parse an XML document and grab relevant data for metric usage. It will grab the general stats, as well as stats for each zone, and return Graphite-formatted metrics results.

The Sensu Check definition looks like this:
```
{
    "checks": {
        "ns1_stevem_io_bind_metrics": {
            "type": "metric",
            "interval": 60,
            "command": "\/opt\/sensu-plugins\/plugins\/dns\/metrics-bind9-xml.rb -u http:\/\/ns1.stevem.io:8080\/",
            "handlers": [
                "graphite"
            ],
            "subscribers": [
                "netmon"
            ]
        },
        "ns2_stevem_io_bind_metrics": {
            "type": "metric",
            "interval": 60,
            "command": "\/opt\/sensu-plugins\/plugins\/dns\/metrics-bind9-xml.rb -u http:\/\/ns2.stevem.io:8080\/",
            "handlers": [
                "graphite"
            ],
            "subscribers": [
                "netmon"
            ]
        }
    }
}
```

Again, pretty simple. Every 60 seconds the script is run with a single parameter, `-u http://YOUR.NAME.SERVER.HERE:8080/` passed in. The result is handled by a `graphite` handler, and is executed by clients subscribing to `netmon`.

Sample output from a check run looks like this:
```
ns1.stevem.io.bind.zone.stevem_io.SitMatch 0 1484282548
ns1.stevem.io.bind.zone.stevem_io.A 4033 1484282548
ns1.stevem.io.bind.zone.stevem_io.NS 18 1484282548
ns1.stevem.io.bind.zone.stevem_io.SOA 38 1484282548
ns1.stevem.io.bind.zone.stevem_io.MX 1 1484282548
ns1.stevem.io.bind.zone.stevem_io.TXT 1 1484282548
ns1.stevem.io.bind.zone.stevem_io.AAAA 2507 1484282548
ns1.stevem.io.bind.zone.stevem_io.SRV 16 1484282548
ns1.stevem.io.bind.zone.stevem_io.A6 2 1484282548
ns1.stevem.io.bind.zone.stevem_io.ANY 3 1484282548
```

## Visualizing with Grafana

Assuming you're feeding these metrics into a Time Series Database such as Graphite, simply build out a query in Grafana to present the data in the way you determine works best. Personally, I have a couple graphs for the general stats, then one for each zone. I use stacked lines as the total number of queries I care about is a sum of A, AAAA, and CNAME requests.

[![grafana graph](/img/bind-grafana-stats.png)](/img/bind-grafana-stats.png)

With queries looking something like this:
```
aliasByNode(nonNegativeDerivative(ns*.stevem.io.bind.counter.nsstat.{Requestv4,QryNXDOMAIN,QryFailure,QryAuthAns,QrySuccess}), 0, 6)
```

Pretty simple! Ask questions if you have 'em.