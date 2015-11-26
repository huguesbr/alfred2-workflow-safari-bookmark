#!/usr/bin/env ruby
# encoding: utf-8

require 'CFPropertyList'
require 'securerandom'

class Bookmark
  def initialize(path)
    @path = path
  end

  def uuid
    @path.split('/').last.split('.')[0..-2].join('.')
  end

  def delete
    File.delete(@path)
    # puts "#{@path} deleted"
  end

  def write(name, url)
    data = <<EOS
// !!! BINARY PROPERTY LIST WARNING !!!
//
// The pretty-printed property list below has been created
// from a binary version on disk and should not be saved as
// the ASCII format is a subset of the binary representation!
//
{ Name = "#{name}";
  URL = "#{url}";
}
EOS
    File.open(@path, "wb+") do |f|
      f.write(data)
      f.close
    end

    # puts "#{@path} renamed"
  end
end

class Bookmarks

  def initialize(path)
    @path = path
    plist = CFPropertyList::List.new(:file => @path)
    @data = CFPropertyList.native_types(plist.value)
    @changed = false
  end

  def save
    plist = CFPropertyList::List.new
    plist.value = CFPropertyList.guess(@data)
    plist.save(@path, CFPropertyList::List::FORMAT_XML)
    # puts 'saved'
  end

  def delete(uuid)
    find_and_perform(@data, uuid) do |c, i| 
      b = c[i]
      title = title(b)

      # iCloud sync entry
      mark_change(b, 'Delete')

      # bookmark entry
      c.delete_at(i)
      @changed = true

      puts "#{title} deleted"

      return true
    end
  end

  def find_and_perform(node, uuid, &block)
    if node['WebBookmarkUUID'] == uuid
      true
    else 
      children = node['Children']
      children.each_with_index do |c, i|
        founded = find_and_perform(c, uuid, &block)
        if founded
          yield(children, i)
          break
        end
      end if children
      false
    end
  end

  def title(node)
    node['URIDictionary']['title']
  end

  def url(uuid)
    find_and_perform(@data, uuid) do |c, i| 
      return c[i]['URLString']
    end
  end

  def mark_change(node, operation_type)
    # iCloud sync entry
    @data['Sync']['Changes'] = [] if @data['Sync']['Changes'].nil?
    @data['Sync']['Changes'] << {
      'BookmarkServerID' => node['Sync']['ServerID'],
      'BookmarkType' => "Leaf",
      'BookmarkUUID' => node['WebBookmarkUUID'],
      'Token' => SecureRandom.uuid,
      'Type' => operation_type
    }
  end

  def rename(uuid, new_name = '')
    find_and_perform(@data, uuid) do |c, i| 
      @changed = true
      old_name = title(c[i])
      c[i]['URIDictionary']['title'] = new_name
      puts "#{old_name} renamed #{new_name}"
      mark_change(c[i], 'Modify')
      return true
    end
  end

end


method = ARGV[0]
bs = Bookmarks.new('/Users/hugues/Library/Safari/Bookmarks.plist')
b = Bookmark.new(File.open('file_list').gets.strip)
ARGV[0] = b.uuid
case method
  when 'rename'

    # bookmark info
    new_name = ARGV[1]
    url = bs.url(b.uuid)

    # update plist
    bs.rename(b.uuid, new_name)
    bs.save

    # rewrite bookmark cache file
    b.write(new_name, url)
  when 'delete'
    # update plist
    bs.delete(b.uuid)
    bs.save

    # delete from cache
    b.delete
end


