require 'spec_helper'

describe MailRoom::Mailbox do
  let(:sample_message) { {'RFC822' => 'a message', 'UID' => 123} }

  describe "#deliver" do
    context "with arbitration_method of noop" do
      it 'arbitrates with a Noop instance' do
        mailbox = build_mailbox({:arbitration_method => 'noop'})
        noop = stub(:deliver?)
        MailRoom::Arbitration['noop'].stubs(:new => noop)

        uid = 123

        mailbox.deliver?(uid)

        expect(noop).to have_received(:deliver?).with(uid)
      end
    end

    context "with arbitration_method of redis" do
      it 'arbitrates with a Redis instance' do
        mailbox = build_mailbox({:arbitration_method => 'redis'})
        redis = stub(:deliver?)
        MailRoom::Arbitration['redis'].stubs(:new => redis)

        uid = 123

        mailbox.deliver?(uid)

        expect(redis).to have_received(:deliver?).with(uid)
      end
    end

    context "with delivery_method of noop" do
      it 'delivers with a Noop instance' do
        mailbox = build_mailbox({:delivery_method => 'noop'})
        noop = stub(:deliver)
        MailRoom::Delivery['noop'].stubs(:new => noop)

        mailbox.deliver(stub(:attr => sample_message))

        expect(noop).to have_received(:deliver).with('a message')
      end
    end

    context "with delivery_method of logger" do
      it 'delivers with a Logger instance' do
        mailbox = build_mailbox({:delivery_method => 'logger'})
        logger = stub(:deliver)
        MailRoom::Delivery['logger'].stubs(:new => logger)

        mailbox.deliver(stub(:attr => sample_message))

        expect(logger).to have_received(:deliver).with('a message')
      end
    end

    context "with delivery_method of postback" do
      it 'delivers with a Postback instance' do
        mailbox = build_mailbox({:delivery_method => 'postback'})
        postback = stub(:deliver)
        MailRoom::Delivery['postback'].stubs(:new => postback)

        mailbox.deliver(stub(:attr => sample_message))

        expect(postback).to have_received(:deliver).with('a message')
      end
    end

    context "with delivery_method of letter_opener" do
      it 'delivers with a LetterOpener instance' do
        mailbox = build_mailbox({:delivery_method => 'letter_opener'})
        letter_opener = stub(:deliver)
        MailRoom::Delivery['letter_opener'].stubs(:new => letter_opener)

        mailbox.deliver(stub(:attr => sample_message))

        expect(letter_opener).to have_received(:deliver).with('a message')
      end
    end

    context "without an RFC822 attribute" do
      it "doesn't deliver the message" do
        mailbox = build_mailbox({ name: "magic mailbox", delivery_method: 'noop' })
        noop = stub(:deliver)
        MailRoom::Delivery['noop'].stubs(:new => noop)

        mailbox.deliver(stub(:attr => {'FLAGS' => [:Seen, :Recent]}))

        expect(noop).to have_received(:deliver).never
      end
    end

    context "with ssl options hash" do
      it 'replaces verify mode with constant' do
        mailbox = build_mailbox({:ssl => {:verify_mode => :none}})

        expect(mailbox.ssl_options).to eq({:verify_mode => OpenSSL::SSL::VERIFY_NONE})
      end
    end

    context 'structured logger setup' do
      it 'sets up the logger correctly and does not error' do
        mailbox = build_mailbox({ name: "magic mailbox", logger: { log_path: '/dev/null' } })

        expect{ mailbox.logger.info(message: "asdf") }.not_to raise_error
      end

      it 'sets up the noop logger correctly and does not error' do
        mailbox = build_mailbox({ name: "magic mailbox" })

        expect{ mailbox.logger.info(message: "asdf") }.not_to raise_error
      end
    end
  end

  describe "#validate!" do
    context "with missing configuration" do
      it 'raises an error' do
        expect { build_mailbox({:name => nil}) }.to raise_error(MailRoom::ConfigurationError)
        expect { build_mailbox({:host => nil}) }.to raise_error(MailRoom::ConfigurationError)
      end
    end
  end
end
