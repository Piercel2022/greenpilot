require "test_helper"

class Api::V1::ContactRequestsControllerTest < ActionDispatch::IntegrationTest
  test "creates a contact request without authentication" do
    assert_difference("ContactRequest.count", 1) do
      post api_v1_contact_requests_url,
           params: {
             contact_request: {
               first_name: "Jean",
               last_name: "Dupont",
               email: "jean@entreprise.fr",
               company: "Entreprise Dupont",
               phone: "0600000000",
               request_type: "Demander une démonstration",
               message: "Je souhaite découvrir GreenPilot."
             }
           },
           as: :json
    end

    assert_response :created

    body = JSON.parse(response.body)

    assert_equal "Jean", body["first_name"]
    assert_equal "Dupont", body["last_name"]
    assert_equal "jean@entreprise.fr", body["email"]
    assert_equal "Entreprise Dupont", body["company"]
    assert_equal "Demander une démonstration", body["request_type"]
    assert_equal "Je souhaite découvrir GreenPilot.", body["message"]
    assert_equal "new", body["status"]
  end

  test "rejects contact request when required fields are missing" do
    assert_no_difference("ContactRequest.count") do
      post api_v1_contact_requests_url,
           params: {
             contact_request: {
               first_name: "",
               last_name: "",
               email: "",
               company: "",
               request_type: "",
               message: ""
             }
           },
           as: :json
    end

    assert_response :unprocessable_entity

    body = JSON.parse(response.body)

    assert_equal "Unprocessable Entity", body["error"]
    assert body["messages"].any?
  end

  test "rejects contact request with invalid email" do
    assert_no_difference("ContactRequest.count") do
      post api_v1_contact_requests_url,
           params: {
             contact_request: {
               first_name: "Jean",
               last_name: "Dupont",
               email: "email-invalide",
               company: "Entreprise Dupont",
               request_type: "Poser une question",
               message: "Bonjour GreenPilot."
             }
           },
           as: :json
    end

    assert_response :unprocessable_entity

    body = JSON.parse(response.body)

    assert_includes body["messages"], "Email is invalid"
  end

  test "rejects contact request with invalid request type" do
    assert_no_difference("ContactRequest.count") do
      post api_v1_contact_requests_url,
           params: {
             contact_request: {
               first_name: "Jean",
               last_name: "Dupont",
               email: "jean@example.com",
               company: "Entreprise Dupont",
               request_type: "Invalid request type",
               message: "Bonjour GreenPilot."
             }
           },
           as: :json
    end

    assert_response :unprocessable_entity

    body = JSON.parse(response.body)

    assert body["messages"].any? do |message|
      message.include?("Request type")
    end
  end

  test "creates contact request with new status by default" do
    post api_v1_contact_requests_url,
         params: {
           contact_request: {
             first_name: "Marie",
             last_name: "Martin",
             email: "marie@example.com",
             company: "Martin Paysage",
             request_type: "Poser une question",
             message: "J'ai une question sur GreenPilot."
           }
         },
         as: :json

    assert_response :created

    contact_request = ContactRequest.order(:created_at).last

    assert_equal "new", contact_request.status
  end
end