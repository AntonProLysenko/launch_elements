defmodule LaunchCartWeb.UserRegistrationControllerTest do
  use LaunchCartWeb.ConnCase, async: true

  import LaunchCart.AccountsFixtures
  import LaunchCart.Factory

  describe "GET /users/register" do
    test "renders registration page", %{conn: conn} do
      conn = get(conn, Routes.user_registration_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "<h1>Register</h1>"
      assert response =~ "Log in</a>"
      assert response =~ "Register</a>"
    end

    test "redirects if already logged in", %{conn: conn} do
      conn = conn |> log_in_user(insert(:user)) |> get(Routes.user_registration_path(conn, :new))
      assert redirected_to(conn) == "/stripe_accounts"
    end
  end

  describe "POST /users/register" do
    @tag :capture_log
    test "thanks the user", %{conn: conn} do
      email = unique_user_email()

      conn =
        post(conn, Routes.user_registration_path(conn, :create), %{
          "user" => %{email: email}
        })

      response = html_response(conn, 200)
      assert response =~ "Thanks"
    end
  end
end
