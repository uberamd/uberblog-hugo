+++
tags = [
  "monitoring",
  "sensu",
  "unifi",
  "tutorial"
]
date = "2016-11-18T12:19:06-06:00"
title = "unifi wireless metrics with sensu"
description = "Collecting Unifi AP stats with Sensu"
author = "Steve Morrissey"

+++

The goal of this exercise is to create a Metric for Sensu that'll poll the Unifi controller and display the signal strength of connected wireless devices. This will allow me to get a visual of the type of connection devices in my house are getting as well as let me somewhat track the comings and goings of my devices. 


Because no scripts like this currently exist for Unifi, I had to dig in and see what my options were. Rather than writing something entirely from scratch, I found an existing Unifi rubygem I could modify and implement in the project, which was a big time savings as I got to avoid one major headache: writing code to authenticate against Unifi and carry the cookies between API calls. 


You can find my fork of the repo here: https://github.com/uberamd/unifi where changes are basic but include 2 critical components:

 * Hitting the stats endpoint
 * Allowing passing of credentials as arguments

With the gem modified to fit my needs I now needed to simply whip up the metric file itself. This is also a very simple script: 

```ruby
#! /usr/bin/env ruby

require 'sensu-plugin/metric/cli'
require 'socket'
require 'unifi'
require 'json'

class UbiquitiClients < Sensu::Plugin::Metric::CLI::Graphite
  option :scheme,
         description: 'Metric naming scheme, text to prepend to .$parent.$child',
         long: '--scheme SCHEME',
         short: '-s',
         default: Socket.gethostname.to_s

  option :username,
         description: 'Username to connect to the controller',
         long: '--USERNAME USERNAME',
         short: '-u',
         default: 'admin'

  option :password,
         description: 'Password for the controller user',
         long: '--password PASSWORD',
         short: '-p',
         default: 'password'

  option :hostname,
         description: 'Unifi controller hostname',
         long: '--hostname HOSTNAME',
         short: '-h',
         default: 'localhost'

  option :port,
         description: 'Unifi controller port',
         long: '--port PORT',
         default: '8443'

  option :site,
         description: 'Unifi controller site to connect to',
         long: '--site SITE',
         default: 'default'

  def run
    timestamp = Time.now.to_i

    controller = Unifi::Controller.new(host: config[:hostname], port: config[:port], site: config[:site])

    controller.login(username: config[:username], password: config[:password])

    # hash to store specific info
    stats_by_ssid = {}

    controller_response = JSON.parse(controller.stats(endpoint: 'sta').body)
    controller_response['data'].each do |client|
      hostname = client['hostname'] || 'undefined'
      mac      = client['mac'] || 'nomac'

      output "#{config[:scheme]}.unifi.ssid.#{client['essid']}.client_by_mac.#{mac}.rx_bytes", client['rx_bytes'], timestamp
      output "#{config[:scheme]}.unifi.ssid.#{client['essid']}.client_by_mac.#{mac}.tx_bytes", client['tx_bytes'], timestamp
      output "#{config[:scheme]}.unifi.ssid.#{client['essid']}.client_by_mac.#{mac}.signal", client['signal'], timestamp
      
      # format with the hostname as another option
      output "#{config[:scheme]}.unifi.ssid.#{client['essid']}.client.#{hostname}_#{mac}.rx_bytes", client['rx_bytes'], timestamp
      output "#{config[:scheme]}.unifi.ssid.#{client['essid']}.client.#{hostname}_#{mac}.tx_bytes", client['tx_bytes'], timestamp
      output "#{config[:scheme]}.unifi.ssid.#{client['essid']}.client.#{hostname}_#{mac}.signal", client['signal'], timestamp

      unless stats_by_ssid.has_key?(client['essid'])
        stats_by_ssid[client['essid']] = {}
      end
      cur_rx_bytes = stats_by_ssid[client['essid']]['rx_bytes'] || 0
      new_rx_bytes = cur_rx_bytes + client['rx_bytes']

      cur_tx_bytes = stats_by_ssid[client['essid']]['tx_bytes'] || 0
      new_tx_bytes = cur_tx_bytes + client['tx_bytes']

      cur_clients = stats_by_ssid[client['essid']]['connected_clients'] || 0
      new_cur_clients = cur_clients += 1

      stats_by_ssid[client['essid']]['rx_bytes'] = new_rx_bytes
      stats_by_ssid[client['essid']]['tx_bytes'] = new_tx_bytes
      stats_by_ssid[client['essid']]['connected_clients'] = new_cur_clients
    end

    output "#{config[:scheme]}.unifi.connected_clients", controller_response['data'].count, timestamp

    stats_by_ssid.each do |ssid|
      ssid[1].each do |k,v|
        output "#{config[:scheme]}.unifi.ssid.#{ssid[0]}.#{k}", v, timestamp
      end
    end
    ok
  end
end
```

What you get from this script is data ready for Graphite that includes total bytes (rx and tx), clients by SSID, total bytes (rx and tx) by client, and total clients. Clients are formatted as "HOSTNAME_MAC_ADDRESS", as well as just MAC to avoid issues of duplicate names or changing names. If you set the metric up properly with a graphite handler you should begin seeing data flowing in which will allow you to produce graphs like this:

![wireless-graph](/img/unifi-wireless-1.png)

The graphite datasource query looks like this:

![wireless-graph](/img/unifi-wireless-2.png)

And finally, the Sensu check definition:

```json
"unifi_stats_metrics": {
  "type": "metric",
  "interval": 60,
  "command": "/opt/sensu-plugins/checks/unifi/metric-ubiquiti-clients.rb -h unifi.mydomain.local -p SOMEPASSHERE",
  "subscribers": [
    "unifi"
  ],
  "handlers": [
    "graphite"
  ]
}
```
