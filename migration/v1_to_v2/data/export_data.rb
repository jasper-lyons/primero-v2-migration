# frozen_string_literal: true

require File.dirname(__FILE__) + '/exporters/record_data_exporter.rb'
data_exporter = RecordDataExporter.new(batch_size: 10)
data_exporter.export