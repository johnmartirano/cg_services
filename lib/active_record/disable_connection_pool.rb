if RUBY_PLATFORM =~ /java/ and ENV['RACK_ENV'] != 'development'
  class ActiveRecord::ConnectionAdapters::ConnectionPool
    def checkout
      # Checkout an available connection
      @connection_mutex.synchronize do
        checkout_new_connection
      end
    end

    def checkin(conn)
      @connection_mutex.synchronize do
        conn.send(:_run_checkin_callbacks) do
          @checked_out.delete conn
          @queue.signal
        end
        @connections.delete(conn)
        conn.disconnect!
      end
    end
  end
end
