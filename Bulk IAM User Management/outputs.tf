output "user_names"{
    value = [for user in local.users: "${user.first_name}_${user.last_name}"]
}

output "user_passwords"{
    value = {
        for user,profile in aws_iam_user_login_profile.users: user=> "password created - user must reset password on first login"
        }
        sensitive = true
}