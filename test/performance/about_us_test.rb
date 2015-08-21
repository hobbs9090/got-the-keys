require 'test_helper'
require 'rails/performance_test_help'

class AboutUsTest < ActionDispatch::PerformanceTest
  # Refer to the documentation for all available options
  # self.profile_options = { runs: 5, metrics: [:wall_time, :memory],
  #                          output: 'tmp/performance', formats: [:flat] }

  test "about us" do
    get '/about_us'
  end
end
