class OperatorAction < ActiveRecord::Base
  belongs_to :target, polymorphic: true
  belongs_to :messages_thread
  belongs_to :operator

  NATURE_ARCHIVE = "archive"
  NATURE_OPEN    = "open"
  NATURE_LOCK    = "lock"
  NATURE_UNLOCK  = "unlock"
end