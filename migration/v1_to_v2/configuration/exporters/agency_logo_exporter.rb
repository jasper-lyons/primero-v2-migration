# frozen_string_literal: true

require_relative('configuration_exporter.rb')
require 'mini_magick'
require 'erb'

# Class that get agency's logo from v1.7 and generate files to be inserted on v2.x
class AgencyLogoExporter
  def initialize(export_dir: 'seed-files', batch_size: 500)
    @export_dir = "#{export_dir}/agency_logos"
    @batch_size = batch_size
    @template = ERB.new(DATA)
  end

  def export
    puts 'Exporting Agencies'
    Agency.each_slice(@batch_size).with_index do |agencies, index|
      agencies.each do |agency|
        next if agency['logo_key'].blank? || agency['_attachments'].blank?

        puts "- Skipped logo for #{agency['_id']}. Content-type is not image/png" unless logo_is_png?(agency)
        next unless logo_is_png?(agency)

        puts "- Exporting #{agency['_id']} logo"
        File.open("#{@export_dir}/#{logo_name(agency)}", 'wb') do |f|
          f.write(agency.fetch_attachment(agency['logo_key']))
        end

        File.open("#{@export_dir}/agencies.#{index}.rb", 'a') do |agency_file|
          agency_logo_loader_string = @template.result_with_hash({
            agency_id: agency['_id'],
            logo_name: logo_name(agency),
            logo_key: agency['logo_key']
          })

          agency_file.write(agency_logo_loader_string)
        end
      end
    end
  end

  private

  def logo_is_png?(agency)
    MiniMagick::Image.read(agency.fetch_attachment(agency['logo_key'])).try(:mime_type) == 'image/png'
  end

  def logo_name(agency)
    "#{agency['_id']}-#{agency['logo_key'].gsub(/%s/, '-')}"
  end
end
__END__

agency = Agency.find_by(unique_id: '<%= agency_id %>')
puts 'Adding logo to <%= agency_id %>'
logo_hash = {
  io: File.open("<%= File.join(File.dirname(__FILE__), logo_name) %>"),
  filename: '<%= logo_key %>'
}
agency.logo_full.attach(logo_hash)
agency.logo_icon.attach(logo_hash)
agency.save!
