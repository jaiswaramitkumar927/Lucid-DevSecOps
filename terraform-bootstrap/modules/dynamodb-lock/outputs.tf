output "table_name" {

  value = aws_dynamodb_table.lock.name

}


output "table_id" {

  value = aws_dynamodb_table.lock.id

}