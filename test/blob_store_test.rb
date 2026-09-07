# frozen_string_literal: true

require "test_helper"
require "fileutils"
require "as_of/blob_store"

class BlobStoreTest < Lightyear::Support::TestCase
  setup do
    @dir = Dir.mktmpdir("tao-blobs")
    @store = AsOf::BlobStore.new(root: @dir)
  end

  teardown { FileUtils.remove_entry(@dir) }

  test "put returns sha256 of the raw bytes and get returns them" do
    hash = @store.put("hello 8-K")
    assert_match(/\Asha256:[0-9a-f]{64}\z/, hash)
    assert_equal "hello 8-K", @store.get(hash)
    assert_equal 9, @store.bytesize(hash)
  end

  test "same bytes re-put yield one hash and one file" do
    a = @store.put("same")
    b = @store.put("same")
    assert_equal a, b
    files = Dir.glob(File.join(@dir, "**", "*")).select { |p| File.file?(p) }
    assert_equal 1, files.size
  end

  test "different bytes are different hashes" do
    refute_equal @store.put("a"), @store.put("b")
  end

  test "unknown hash raises" do
    missing = AsOf::BlobStore.hash_of("never-stored")
    assert_raises(ArgumentError) { @store.get(missing) }
  end
end
