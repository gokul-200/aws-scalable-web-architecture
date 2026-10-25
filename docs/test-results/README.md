# Test results

Put screenshots and terminal output here **only for tests you actually ran**.
Name files so they match the validation table in the main README.

| File | What it should show | How to capture |
|------|---------------------|----------------|
| `01-targets-healthy.png` | Two registered targets, both healthy, in different AZs | EC2 > Target Groups > Targets tab |
| `02-browser-page.png` | The web page served through the ALB DNS name | Browser |
| `03-distribution.txt` | Requests split across both instances | `./scripts/verify.sh <alb-dns> 20 \| tee docs/test-results/03-distribution.txt` |
| `04-failure-unhealthy.png` | One target unhealthy after stopping the app | Target Groups > Targets, after `sudo systemctl stop webapp` |
| `05-asg-replacement.txt` | ASG terminating the failed instance and launching a new one | `aws autoscaling describe-scaling-activities --auto-scaling-group-name scalable-web-asg --max-items 5 > docs/test-results/05-asg-replacement.txt` |
| `06-scale-out.png` | CloudWatch average CPU above target and ASG instance count rising | CloudWatch graph + ASG Activity tab during `./scripts/loadtest.sh` |

Do not edit or invent output. Remove account IDs before committing.
