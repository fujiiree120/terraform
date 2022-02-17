//データソースの定義
data "aws_ami" "recent_amazon_linux_2"{
    most_recent = true //最新バージョン取得
    owners = ["amazon"]
}

filter {
    name = "name"
    values = ["amzn2-ami-hvm-2.0"]
}