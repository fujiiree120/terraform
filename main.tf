variable = "example_instance_type"{
    default = "t3.micro"
}

resource "aws_instance" "example"{
    ami = "ami-03cfd0f5d33134a76"
    instance_type = var.example_instance_type
    user_data = file("./user_data.sh")
}

//apply時の出力
output "example_instance_id" {
  value       = aws_instance_id
  sensitive   = true
  description = "description"
  depends_on  = []
}



/*
locals = {
    example_instance_type = "t3.micro"
}

resource "aws_instance" "example"{
        ami = "ami-03cfd0f5d33134a76"
        instance_type = locals.example_instance_type
}
*/