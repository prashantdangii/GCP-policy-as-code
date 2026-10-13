variable "name" {
  type        = string
  description = "Firewall rule name."

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,61}[a-z0-9]$", var.name))
    error_message = "name must be a lowercase RFC1035-ish firewall name."
  }
}

variable "project_id" {
  type        = string
  description = "Project that owns the network."
}

variable "network" {
  type        = string
  description = "VPC name or self link the rule attaches to."
}

variable "direction" {
  type        = string
  description = "INGRESS or EGRESS."

  validation {
    condition     = contains(["INGRESS", "EGRESS"], upper(var.direction))
    error_message = "direction must be INGRESS or EGRESS."
  }
}

variable "action" {
  type        = string
  description = "allow or deny."

  validation {
    condition     = contains(["allow", "deny"], var.action)
    error_message = "action must be allow or deny."
  }
}

variable "protocol" {
  type        = string
  description = "IP protocol, for example tcp, udp, icmp, or all."
}

variable "ports" {
  type        = list(string)
  description = "Ports for tcp/udp. Empty means every port for that protocol."
  default     = []
}

variable "ranges" {
  type        = list(string)
  description = "Source ranges for ingress, destination ranges for egress."

  validation {
    condition     = length(var.ranges) > 0 && alltrue([for cidr in var.ranges : can(cidrhost(cidr, 0))])
    error_message = "ranges must be one or more CIDR blocks."
  }
}

variable "priority" {
  type        = number
  description = "Rule priority from 0 through 65534. Lower numbers win."

  validation {
    condition     = var.priority >= 0 && var.priority <= 65534
    error_message = "priority must be between 0 and 65534."
  }
}

variable "description" {
  type        = string
  description = "Why this rule exists. Shown to reviewers and in the console."

  validation {
    condition     = length(trimspace(var.description)) > 0
    error_message = "description is required."
  }
}

variable "target_tags" {
  type        = list(string)
  description = "Instance tags the rule applies to."
  default     = []

  validation {
    condition     = length(var.target_tags) + length(var.target_service_accounts) > 0
    error_message = "Set target_tags or target_service_accounts so the rule cannot hit every instance by accident."
  }
}

variable "target_service_accounts" {
  type        = list(string)
  description = "Service accounts the rule applies to."
  default     = []
}

variable "allow_open_admin_ports" {
  type        = bool
  description = "Escape hatch for ingress 22/3389/all from 0.0.0.0/0 or ::/0. Leave false."
  default     = false
}

variable "justification" {
  type        = string
  description = "Required when allow_open_admin_ports is true."
  default     = ""

  validation {
    condition = (
      !(
        var.action == "allow" &&
        upper(var.direction) == "INGRESS" &&
        (contains(var.ranges, "0.0.0.0/0") || contains(var.ranges, "::/0")) &&
        (
          contains(var.ports, "22") ||
          contains(var.ports, "3389") ||
          var.protocol == "all" ||
          (var.protocol == "tcp" && length(var.ports) == 0)
        )
      )
      ) || (
      var.allow_open_admin_ports && length(trimspace(var.justification)) > 0
    )
    error_message = "Refusing world-ingress to tcp/22, tcp/3389, all ports, or protocol all. Set allow_open_admin_ports and a non-empty justification to override."
  }
}
