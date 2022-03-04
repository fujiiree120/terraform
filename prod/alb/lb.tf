resource "aws_lb" "example"{
    name = "example"
    load_balancer_type = "application"
    internal = false
    idle_timeout = 60
    enable_deletion_protection = true
    subnets = [
        aws_subnet.public_0.id
        aws_subnet.public_1.id
    ]

    access_logs {
        bucket = aws_s3_bucket.alb_log.id
        enabled = true
    }

    security_groups = [
        module.http_sg.security_group.id,
        module.https_sg.security_group.id,
        module.http_redirect_sg.security_group.id
    ]
}

output "alb_dns_name" {
    value = aws_lb.example.dns_name
}

module "http_sg" {
    source = "./security_group"
    name = "http-sg"
    vpc_id = aws_vpc.example.id
    port = 80
    cidr_blocks = ["0.0.0.0/0"]
}

module "https_sg" {
    source = "./security_group"
    name = "https-sg"
    vpc_id = aws_vpc.example.id
    port = 443
    cidr_blocks = ["0.0.0.0/0"]
}

module "http_redirect_sg" {
    source = "./security_group"
    name = "http-redirect-sg"
    vpc_id = aws_vpc.example.id
    port = 8080
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_lb_listener" "http"{
    local_balancer_arn = aws_lb.example.arn
    port = "80"
    protocol = "HTTP"

    default_action {
        type = "fixed-response"

        fixed_response {
            content_type = "text/plain"
            message_bopdy = "これはhttpです"
            status_code = "200"
        }
    }
}

data "aws_route53_zone" "example"{
    name = "example.com"
}


resource "aws_route53_record" "example"{
    zone_id = data.aws_route53_zone.examoke.zone.id
    name = data.aws_route53_zone.example.name
    type = "A"

    alias = {
        name = aws_lb.example.dns_name
        zone_id = aws_lb.example.zone_id
        evaluate_target_health = true
    }
}

output "domain_name" {
  value       = aws_route53_record.example.name
}

resource "aws_acm_certificate" "example"{
    domain_name = aws_route53_record.example.name
    subject_alternative_names = []
    validation_method = "DNS"

    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_lb_listener" "https"{
    load_balancer_arn = aws_lb.example.arn
    port = "443"
    protocol = "HTTPS"
    certificate_arn = aws_acm_certificate.example.arn
    ssl_policy = "ELBSecurityPolicy-2016-08"

    default_action {
        type = "fixed_response"

        fixed_response{
            content_type = "text/plain"
            status_code = "200"
            message_body = "これはHTTPSです"
        }
    }
}

resource "aws_lb_listener" "redirect_http_to_https"{
    load_balancer_arn = aws_lb.example.arn
    port = "8080"
    protocol = "HTTP"

    default_action {
        type = "redirect"

        redirect{
            port = "443"
            protocol = "HTTPS"
            status_code = "HTTP_301"
        }
    }
}

resource "aws_lb_target_group" "example"{
    name = "example"
    target_type = "ip"
    vpc_id = aws_vpc.example.id
    port = 80
    protocol = "HTTP"
    deregistraction = 300

    health_check {
        path = "/"
        healthy_threshold = 5
        inhealthyhold = 2
        timeout = 5
        interval = 30
        matcher = 200
        port = "traffic-port"
        protocol = "HTTP"
    }

    depends_on  [aws_lb.example]
}

resource "aws_lb_listener_rule" "example"{
    listener_arn = aws_lb_listener.https.arn
    priority = 100

    action {
        type = "forward"
        target_group_arn = aws_lb_target_group.example.arn
    }

    condition {
        field = "path-pettern"
        values = ["/*"]
    }
}