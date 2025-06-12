resource "aws_s3_bucket" "demo_bucket" {
  bucket = "this-is-a-demo-bucket-for-task-1"
  
  lifecycle {
    prevent_destroy = false
  }
}
