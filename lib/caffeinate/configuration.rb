# frozen_string_literal: true

module Caffeinate
  # Global configuration
  class Configuration

    # Used for relation to a lot of things. If you have a weird time setup, set this.
    # Accepts anything that responds to `#call`; you'll probably use a block.
    attr_accessor :now

    # If true, enqueues the processing of a `Caffeinate::Mailing` to the background worker class
    # as defined in `async_delivery_class`
    #
    # Default is false
    attr_accessor :async_delivery

    # The background worker class for `async_delivery`.
    attr_accessor :async_delivery_class

    # An optional callable (anything responding to `#call`, e.g. a lambda) used to route an
    # individual `Caffeinate::Mailing` to a specific background queue when it is delivered
    # asynchronously. It receives the mailing about to be enqueued and must return the name of
    # the queue to use, or a blank value (`nil`/`""`) to fall back to `async_delivery_class`'s
    # default queue. Only applied when the delivery class responds to `.set` (Sidekiq/ActiveJob).
    #
    # Default is nil (every mailing uses the delivery class's default queue).
    #
    #   config.async_delivery_queue_resolver = ->(mailing) { 'critical' if mailing.mailer_class == 'FooMailer' }
    attr_accessor :async_delivery_queue_resolver

    # If true, uses `deliver_later` instead of `deliver`
    attr_accessor :deliver_later

    # The number of `Caffeinate::Mailing` records we find in a batch at once.
    attr_accessor :batch_size

    # The path to the drippers
    attr_accessor :drippers_path

    # Automatically creates a `Caffeinate::Campaign` record by the named slug of the campaign from a dripper
    # if none is found by the slug.
    attr_accessor :implicit_campaigns

    # The default reason for an ended `Caffeinate::CampaignSubscription`
    attr_accessor :default_ended_reason

    # The default reason for an unsubscribed `Caffeinate::CampaignSubscription`
    attr_accessor :default_unsubscribe_reason

    # An array of Drippers that are enabled. Only used if you use Caffeinate.perform in
    # your worker instead of calling separate drippers. If nil, will run all the campaigns.
    attr_accessor :enabled_drippers

    def initialize
      @now = -> { Time.current }
      @async_delivery = false
      @deliver_later = false
      @async_delivery_class = nil
      @batch_size = 1_000
      @drippers_path = 'app/drippers'
      @implicit_campaigns = true
      @default_ended_reason = nil
      @default_unsubscribe_reason = nil
      @enabled_drippers = nil
      @async_delivery_queue_resolver = nil
    end

    def now=(val)
      raise ArgumentError, '#now must be a proc' unless val.respond_to?(:call)

      @now = val
    end

    def implicit_campaigns?
      @implicit_campaigns
    end

    def time_now
      @now.call
    end

    def async_delivery?
      @async_delivery
    end

    def deliver_later?
      @deliver_later
    end

    def async_delivery_class
      @async_delivery_class.constantize
    end

    # Resolves the background queue for a given mailing using `async_delivery_queue_resolver`.
    # Returns nil when no resolver is configured or the resolver returns a blank value, in which
    # case the delivery class's default queue is used.
    def async_delivery_queue_for(mailing)
      return nil unless @async_delivery_queue_resolver.respond_to?(:call)

      queue = @async_delivery_queue_resolver.call(mailing)
      queue.presence
    end
  end
end
