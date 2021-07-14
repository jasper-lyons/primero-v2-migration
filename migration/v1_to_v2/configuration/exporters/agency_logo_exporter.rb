# frozen_string_literal: true

require_relative('configuration_exporter')
require 'mini_magick'
require 'erb'
require 'ostruct'
require 'fileutils'

class Template < OpenStruct
  def render(template)
    ERB.new(template).result(binding)
  end
end

# Blank line at the beginning is important as we'll be writing this template
# repeatedly to a file and we'd like a space between each block of code!
AGENCY_LOGO_TEMPLATE = <<~ERB

  agency = Agency.find_by(unique_id: '<%= agency_id %>')
  puts 'Adding logo to <%= agency_id %>'
  logo_hash = {
    io: File.open("<%= File.join(File.dirname(__FILE__), logo_name) %>"),
    filename: '<%= logo_key %>'
  }
  agency.logo_full.attach(logo_hash)
  agency.logo_icon.attach(logo_hash)
  agency.save!
ERB

# Class that get agency's logo from v1.7 and generate files to be inserted on v2.x
class AgencyLogoExporter
  def initialize(export_dir: 'seed-files', batch_size: 500)
    @export_dir = "#{export_dir}/agency_logos"
    @batch_size = batch_size
    FileUtils.mkdir_p(@export_dir)
  end

  def export
    puts 'Exporting Agencies'
    Agency.all.each_slice(@batch_size).with_index do |agencies, index|
      agencies.each do |agency|
        next if no_logo?(agency)
        next puts "- Skipped logo for #{agency['_id']}. Content-type is not image/png" unless logo_is_png?(agency)

        puts "- Exporting #{agency['_id']} logo"
        # write the logo image it's self
        File.write(export_path(logo_name(agency)), agency.fetch_attachment(agency['logo_key']), 'wb')
        # write the loader to the batch file
        File.write(export_path("agencies.#{index}.rb"), agency_logo_loader_string(agency), mode: 'a')
      end
    end
  end

  private

  def no_logo?(agency)
    agency['logo_key'].blank? || agency['_attachments'].blank?
  end

  def logo_is_png?(agency)
    MiniMagick::Image.read(agency.fetch_attachment(agency['logo_key'])).try(:mime_type) == 'image/png'
  end

  def logo_name(agency)
    "#{agency['_id']}-#{agency['logo_key'].gsub(/\s/, '-')}"
  end

  def export_path(path)
    File.join(@export_dir, path)
  end

  def agency_logo_loader_string(agency)
    Template.new({
      agency_id: agency['_id'],
      logo_name: logo_name(agency),
      logo_key: agency['logo_key']
    }).render(AGENCY_LOGO_TEMPLATE)
  end
end
