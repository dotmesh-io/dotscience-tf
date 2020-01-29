variable "amis" {
  type = map
  default = {
    "us-east-1" : {
      "Hub" : "ami-0438340d48f1ecf2b",
      "CPURunner" : "ami-059b4ecdb5d31f499",
      "GPURunner" : "ami-0e8c502966ca4cc57"
    }
  }
}