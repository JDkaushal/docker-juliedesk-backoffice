module Api::V1::Concerns::MessagesThreadsMethods

  def valid_remove_syncing_tag_params(params)
    data = remove_syncing_tag_params(params)
    schema = {
        "type": "object",
        "properties": {
            "account_email": {
                "type": "string",
                "format": "email"
            }
        },
        "required": ["account_email"]
    }

    errors = JSON::Validator.fully_validate(schema, data.to_h)
    raise Api::InvalidParamsException.new("INVALID_PARAMS", errors) if errors.any?
    data
  end

  def valid_get_user_details_params(params)
    data = extract_get_user_details_params(params)
    schema = {
        "type": "object",
        "properties": {
            "id": {
                "type": "string"
            },
            "user_email": {
                "type": "string",
                "format": "email"
            }
        },
        "required": ["id", "user_email"]
    }

    errors = JSON::Validator.fully_validate(schema, data.to_h)
    raise Api::InvalidParamsException.new("INVALID_PARAMS", errors) if errors.any?
    data
  end

  alias valid_add_syncing_tag_params valid_remove_syncing_tag_params

  def remove_syncing_tag_params(params)
    params.permit(:account_email)
  end

  def extract_get_user_details_params(params)
    params.permit(:id, :user_email)
  end

end