provider "local" {
}

# Infra resource
resource "local_file" "foo" {
  filename = "${path.module}/foo.txt"
  content  = data.local_file.bar.content
}

data "local_file" "bar" {
	filename = "${path.module}/bar.txt"
}

output "bar_c" {
	value = data.local_file.bar.content
}

