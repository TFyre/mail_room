require 'spec_helper'
require 'mail_room/structured_logger'
require 'json'

describe MailRoom::StructuredLogger do

  subject { described_class.new $stdout }

  let!(:now) { Time.now }
  let(:message) { 'testing 123' }

  before do
    Time.stubs(:now).returns(now)
  end

  [:debug, :info, :warn, :error, :fatal].each do |level|
    it "logs #{level}" do
      expect { subject.send(level, message) }.to output(json_matching(level.to_s.upcase, message)).to_stdout_from_any_process
    end
  end

  it 'logs unknown' do
    expect { subject.unknown(message) }.to output(json_matching("ANY", message)).to_stdout_from_any_process
  end

  context 'logging a hash as a message' do
    it 'merges the contents' do
      input = {
          additional_field: "some value"
      }
      expected = {
          severity: 'DEBUG',
          time: now,
          additional_field: "some value"
      }

      expect { subject.debug(input) }.to output(as_regex(expected)).to_stdout_from_any_process
    end
  end

  def json_matching(level, message)
    contents = {
        severity: level,
        time: now,
        message: message
    }

    as_regex(contents)
  end

  def as_regex(contents)
    /#{Regexp.quote(contents.to_json)}/
  end
end
