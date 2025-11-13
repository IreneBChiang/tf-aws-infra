resource "aws_sns_topic" "user_signup" {
  name = "irenec-user-signup-topic"
}
output "user_signup_topic_arn" {
  value = aws_sns_topic.user_signup.arn
}
