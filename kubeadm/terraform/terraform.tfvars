gcp_project = "kubernetes-security-xxx"
key_path = "C:\\Users\\xxx\\Downloads\\kubernetes-security.json"
project_zone = "us-central1-a"
ssh_path = "C:\\Users\\xxx\\.ssh/kubeadmxxx.pub"
ssh_private_key_path = "C:\\Users\\xxx/.ssh/kubeadmxxx"

region = "us-central1"
instances_names = [ "my-machine", "control-plane", "worker-node", "webhook-server", "worker-node-1" ]

firewall_object = [ 
    {
        target_tags = [ "kubeadm-vm" ]
        direction = "INGRESS"
        name = "app-ingress"
        ports = []
        priority = 900
        protocol = "all"
        source_ranges = [ "10.10.0.0/16" ]
    },
    {
        target_tags = [ "kubeadm-vm" ]
        direction = "INGRESS"
        name = "ssh"
        ports = ["22"]
        priority = 900
        protocol = "tcp"
        source_ranges = [ "0.0.0.0/0" ]
    }
]