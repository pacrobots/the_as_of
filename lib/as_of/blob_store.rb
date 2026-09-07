# frozen_string_literal: true

require "digest"
require "fileutils"

module AsOf
  # Content-addressed bytes. The Ledger is the minute-book, not the filing
  # cabinet — raw source lives here, keyed by `sha256:` + hex of the bytes.
  class BlobStore
    PREFIX = "sha256:"

    def initialize(root: ENV.fetch("BLOB_DIR", File.expand_path("../../storage/blobs", __dir__)))
      @root = root
    end

    attr_reader :root

    def put(bytes)
      data = bytes.to_s.b
      hash = self.class.hash_of(data)
      path = path_for(hash)
      unless File.exist?(path)
        FileUtils.mkdir_p(File.dirname(path))
        tmp = "#{path}.tmp-#{Process.pid}-#{Thread.current.object_id}"
        File.binwrite(tmp, data)
        File.rename(tmp, path)
      end
      hash
    end

    def get(hash)
      path = path_for(hash)
      raise ArgumentError, "unknown blob #{hash}" unless File.exist?(path)

      File.binread(path)
    end

    def exist?(hash) = File.exist?(path_for(hash))

    def bytesize(hash)
      path = path_for(hash)
      raise ArgumentError, "unknown blob #{hash}" unless File.exist?(path)

      File.size(path)
    end

    def self.hash_of(bytes) = "#{PREFIX}#{Digest::SHA256.hexdigest(bytes.to_s.b)}"

    def self.parse(hash)
      raise ArgumentError, "hash must start with #{PREFIX}" unless hash.to_s.start_with?(PREFIX)

      hex = hash.to_s.delete_prefix(PREFIX)
      raise ArgumentError, "hash is not sha256 hex" unless hex.match?(/\A[0-9a-f]{64}\z/)

      hex
    end

    private

    def path_for(hash)
      hex = self.class.parse(hash)
      File.join(@root, hex[0, 2], hex[2, 2], hex)
    end
  end
end
