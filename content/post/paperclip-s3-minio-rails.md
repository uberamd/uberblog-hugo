+++
description = ""
author = "Steve Morrissey"
tags = [
    "ruby",
    "rails",
    "minio",
    "paperclip",
    "s3",
    "tutorial"
]
date = "2017-10-27T12:30:00-06:00"
title = "using rails 5 and paperclip s3 with minio"

+++
Odds are if you've landed here you're aware of what Paperclip is and the purpose it servces within a Rails application. If not, it's basically a gem that will handle file 
uploads. In my case I use it for resizing images, saving them somewhere (S3), then easily presenting them back to the user inside of a view.

**Note**: This tutorial should work with any S3 compatible object storage API. Minio is just one of the more common ones.


## The Problem

What we want to do is store uploads from Paperclip in Minio instead of S3.

From the website [minio.io](https://minio.io): Minio is an open source object storage server with Amazon S3 compatible API.

This means that, in theory, we should be able to use Paperclip to upload images to a self-hosted Minio instance using the built in S3 storage option 
provided we're able to throw the correct config flags at it. This will give us full control over the storage pipeline and allow us to leverage our existing bandwidth.


## The Solution

The solution is actually quite simple. First off, in my `Gemfile` I have the expected Paperclip bits:

```
gem 'paperclip', git: 'https://github.com/thoughtbot/paperclip.git'
gem 'aws-sdk', '~> 2.3'
```

Then I have within my `config/environments/development.rb` file:

```
Rails.application.configure do
  ...
  ...

  config.paperclip_defaults = {
      storage: :s3,
      s3_credentials: {
          bucket: 'my-dev-bucket',
          access_key_id: ENV['MINIO_ACCESS_KEY'],
          secret_access_key: ENV['MINIO_SECRET_KEY'],
          region: 'us-east-1'
      },
      s3_options: {
          force_path_style: true,
          endpoint: 'https://s3.stevem.io'
      },
      s3_region: 'us-east-1',
      s3_host_name: 's3.stevem.io',
      path: '/:class/:attachment/:id_partition/:style/:filename'
  }

  ...
  ...
end
```

The key bits here are `s3_host_name`, and the `s3_options` block which is able to take options that get passed to `Aws::S3::Resource.new()`. Here we tell 
our application that it should use the path style for referencing the bucket, which kills the default behavior of trying to access the bucket via a subdomain. 
We're also setting the endpoint to the FQDN of your minio install.

Finally, we specify a path for storing data within our bucket.

It's that simple. Just make sure that you have a public bucket policy on your minio bucket, which you can verify with this command using the minio client:

```
$ mc policy list minio/my-dev-bucket
my-dev-bucket/* => readwrite
```

Let me know if you run into problems.

