class AuditBotJob < ApplicationJob
  queue_as :default

  # after_perform { AuditBotJob.set(wait: 5.seconds).perform later}

  def self.perform(*args)
    logger.info 'JOB WORKS!'
  end
end
