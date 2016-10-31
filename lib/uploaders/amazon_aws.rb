module Uploaders
  class AmazonAws

    def self.s3_bucket
      @@bucket ||= Aws::S3::Resource.new.bucket(ENV['AWS_PLANNING_CONSTRAINTS_BUCKET'])
    end

    def self.store_file path, file
      self.s3_bucket.object(path).put(body: file)
    end

    def self.load_file path
      object = self.s3_bucket.object(path)
      object.get.body.string
    end

  end

end
