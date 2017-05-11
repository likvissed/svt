class LoadAuditData
  attr_reader :audit_data

  def initialize(inv_num)
    @inv_num = inv_num
  end

  def load
    get_host_name unless @host

    begin
      Timeout.timeout(Audit::TIMEOUT_FOR_REQUEST) do
        loop do
          begin
            @audit_data = Audit.get_data(@host['name'])
            break
          rescue Exception
          end
        end
      end
    rescue Timeout::Error
      return false
    end
  end

  private

  def get_host_name
    @host = HostIss.get_host(@inv_num)

    # if @host.nil?
    #   raise 'Not found'
    # end
  end
end
