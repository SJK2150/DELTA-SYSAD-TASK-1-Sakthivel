


CORE_HOME="/home/core"
MENTEE_DETAILS="${CORE_HOME}/menteeDetails.txt"
MENTOR_DETAILS="${CORE_HOME}/mentorDetails.txt"
MENTEES_DOMAIN="${CORE_HOME}/mentees_domain.txt"


sudo useradd -m core


sudo mkdir -p ${CORE_HOME}/mentors/{Webdev,Appdev,Sysad}
sudo mkdir -p ${CORE_HOME}/mentees


sudo touch ${MENTEE_DETAILS} ${MENTOR_DETAILS}


echo "mentee1 12345" | sudo tee -a ${MENTEE_DETAILS}
echo "mentee2 12346" | sudo tee -a ${MENTEE_DETAILS}
echo "mentee3 12347" | sudo tee -a ${MENTEE_DETAILS}


echo "Webdev_mentor 3" | sudo tee -a ${MENTOR_DETAILS}
echo "Appdev_mentor 2" | sudo tee -a ${MENTOR_DETAILS}
echo "Sysad_mentor 2" | sudo tee -a ${MENTOR_DETAILS}


while read -r mentor capacity; do
    sudo useradd -m -d ${CORE_HOME}/mentors/${mentor} ${mentor}
    sudo mkdir -p ${CORE_HOME}/mentors/${mentor}/submittedTasks/{task1,task2,task3}
    echo "" | sudo tee ${CORE_HOME}/mentors/${mentor}/allocatedMentees.txt
done < ${MENTOR_DETAILS}


while read -r mentee roll; do
    sudo useradd -m -d ${CORE_HOME}/mentees/${mentee} ${mentee}
    echo "" | sudo tee ${CORE_HOME}/mentees/${mentee}/domain_pref.txt
    echo "" | sudo tee ${CORE_HOME}/mentees/${mentee}/task_completed.txt
    echo "" | sudo tee ${CORE_HOME}/mentees/${mentee}/task_submitted.txt
done < ${MENTEE_DETAILS}


sudo chmod 711 ${CORE_HOME}
sudo chmod 750 ${CORE_HOME}/mentors
sudo chmod 750 ${CORE_HOME}/mentees

for mentor in Webdev Appdev Sysad; do
    sudo chmod 700 ${CORE_HOME}/mentors/${mentor}
done

while read -r mentee roll; do
    sudo chmod 700 ${CORE_HOME}/mentees/${mentee}
done < ${MENTEE_DETAILS}


echo "" | sudo tee ${MENTEES_DOMAIN}
sudo chmod 722 ${MENTEES_DOMAIN}


sudo su - core << 'EOF'


echo 'alias domainPref='"'"'function _domainPref() { \
    read -p "Enter your roll number: " roll; \
    read -p "Enter your domain preferences (space-separated): " prefs; \
    echo $prefs > ~/domain_pref.txt; \
    echo "$roll $prefs" >> /home/core/mentees_domain.txt; \
    for domain in $prefs; do \
        mkdir -p ~/$domain; \
    done; \
}; _domainPref'"'" >> ~/.bashrc

echo 'alias mentorAllocation='"'"'function _mentorAllocation() { \
    while IFS= read -r mentor capacity; do \
        mentees=($(grep -E "^[^ ]+ +${mentor}$" /home/core/mentees_domain.txt | cut -d " " -f 1)); \
        count=0; \
        for mentee in "${mentees[@]}"; do \
            if (( count < capacity )); then \
                echo "$mentee" >> /home/core/mentors/${mentor}/allocatedMentees.txt; \
                count=$((count + 1)); \
            fi; \
        done; \
    done < /home/core/mentorDetails.txt; \
}; _mentorAllocation'"'" >> ~/.bashrc

echo 'alias submitTask='"'"'function _submitTask() { \
    read -p "Enter task number (1, 2, or 3): " task_num; \
    read -p "Enter the domain of the task: " domain; \
    mkdir -p ~/$domain/task$task_num; \
    echo "Task $task_num for $domain submitted" >> ~/task_submitted.txt; \
    if [ "$(ls -A ~/$domain/task$task_num)" ]; then \
        echo "Task $task_num for $domain completed" >> ~/task_completed.txt; \
    fi; \
    mentor=$(grep "$USER" /home/core/mentors/${domain}_mentor/allocatedMentees.txt | cut -d " " -f 2); \
    ln -s ~/$domain/task$task_num /home/core/mentors/${domain}_mentor/submittedTasks/task$task_num/$USER; \
}; _submitTask'"'" >> ~/.bashrc

echo 'alias displayStatus='"'"'function _displayStatus() { \
    for task_num in 1 2 3; do \
        total=$(grep -c "Task $task_num" /home/core/mentees/*/task_submitted.txt); \
        echo "Task $task_num: $total submissions"; \
    done; \
}; _displayStatus'"'" >> ~/.bashrc


source ~/.bashrc

EOF

echo "Setup complete. Switch to the 'core' user and test the aliases."
