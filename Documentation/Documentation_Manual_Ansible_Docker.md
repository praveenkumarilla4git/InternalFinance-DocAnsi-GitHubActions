######################################
Phase 1: Create Infra using terraform
######################################
cd Ops-Infra
Do terraform apply and create a server 

######################################
Phase 2: Connect to created Server and Install Ansible and git
######################################
ssh connect to the server
ssh -i batch3.pem ec2-user@44.223.82.237

#Install Ansible and git

# Update the server
sudo dnf update -y

# Install Ansible and Git
sudo dnf install -y ansible-core git

#####################################
Phase 3: Create the Ansible Files
#####################################
Location: Inside the EC2 Terminal
We will create the automation scripts on the server.
1. Create the folder
mkdir -p /home/ec2-user/ansible_home
cd /home/ec2-user/ansible_home
2. touch hosts.ini

[webserver]
localhost ansible_connection=local

3. touch deploy.yml

---
- name: Deploy Finance App on Localhost
  hosts: webserver
  become: yes
  vars:
    repo_url: "https://github.com/praveenkumarilla4git/InternalFinance-Docker.git"
    project_dir: "/home/ec2-user/InternalFinance-Docker"
    image_name: "finance-app"

  tasks:
    # 1. Start Docker
    - name: Ensure Docker service is running
      service:
        name: docker
        state: started
        enabled: yes

    # 2. Download Code
    - name: Pull latest code from GitHub
      git:
        repo: "{{ repo_url }}"
        dest: "{{ project_dir }}"
        version: main
        force: yes

    # 3. Handle requirements.txt location
    - name: Check if requirements.txt exists in app/ folder
      stat:
        path: "{{ project_dir }}/app/requirements.txt"
      register: req_file

    - name: Move requirements.txt to main folder
      command: mv {{ project_dir }}/app/requirements.txt {{ project_dir }}/
      when: req_file.stat.exists

    # 4. Cleanup Old Container
    - name: Check for running container
      shell: docker ps -q --filter ancestor={{ image_name }}
      register: running_container
      ignore_errors: yes

    - name: Stop and remove existing container
      shell: docker rm -f {{ running_container.stdout }}
      when: running_container.stdout != ""

    # 5. Build & Run
    - name: Build Docker Image
      shell: "docker build -t {{ image_name }} ."
      args:
        chdir: "{{ project_dir }}"

    - name: Run Docker Container
      shell: "docker run -d -p 5000:5000 {{ image_name }}"
	  
Phase 4: Run the Automation
Location: Inside the EC2 Terminal

Run the playbook to execute the deployment:
ansible-playbook -i hosts.ini deploy.yml
http://44.223.82.237:5000
http://44.200.129.99:5000


