module AutomaticsEmails
  module Rules
    TYPE_ACCESS_LOST_IN_THREAD_NATIVE_CONNEXION = :access_lost_in_thread_native_connexion
    TYPE_ACCESS_LOST_IN_THREAD_SHARED_CONNEXION = :access_lost_in_thread_shared_connexion

    RULES = {}

    RULES[TYPE_ACCESS_LOST_IN_THREAD_NATIVE_CONNEXION] = [
      {
        filter: AutomaticsEmails::Filters::Client.new(TYPE_ACCESS_LOST_IN_THREAD_NATIVE_CONNEXION, 4.hours),
        conditions: [AutomaticsEmails::Conditions::CountLimit.new(5)]
      },
      {
        filter: AutomaticsEmails::Filters::Thread.new(TYPE_ACCESS_LOST_IN_THREAD_NATIVE_CONNEXION, 4.hours),
        conditions: [AutomaticsEmails::Conditions::CountLimit.new(1)]
      }
    ]

    RULES[TYPE_ACCESS_LOST_IN_THREAD_SHARED_CONNEXION] = [
        {
            filter: AutomaticsEmails::Filters::Client.new(TYPE_ACCESS_LOST_IN_THREAD_SHARED_CONNEXION, 4.hours),
            conditions: [AutomaticsEmails::Conditions::CountLimit.new(5)]
        },
        {
            filter: AutomaticsEmails::Filters::Thread.new(TYPE_ACCESS_LOST_IN_THREAD_SHARED_CONNEXION, 4.hours),
            conditions: [AutomaticsEmails::Conditions::CountLimit.new(1)]
        }
    ]

  end
end