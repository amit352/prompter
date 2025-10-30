# frozen_string_literal: true

module Prompter
  class Railtie < Rails::Railtie
    railtie_name :prompter

    rake_tasks do
      load File.expand_path('tasks/prompter.rake', __dir__.sub('/prompter', ''))
    end
  end
end
