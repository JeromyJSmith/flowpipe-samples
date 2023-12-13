pipeline "block_s3_public_access" {

  param "aws_region" {
    type        = string
    description = "AWS region."
    default     = var.aws_region
  }

  param "bucket" {
    type        = string
    description = "AWS S3 bucket name."
  }

  param "issue_id" {
    type        = string
    description = "Jira issue id."
  }

  step "pipeline" "put_s3_bucket_public_access_block" {
    pipeline = aws.pipeline.put_s3_bucket_public_access_block
    args = {
      region                  = param.aws_region
      bucket                  = param.bucket
      block_public_acls       = true
      ignore_public_acls      = true
      block_public_policy     = true
      restrict_public_buckets = true
    }
  }

  step "pipeline" "add_comment" {
    depends_on = [step.pipeline.put_s3_bucket_public_access_block]
    pipeline   = jira.pipeline.add_comment
    args = {
      issue_id     = param.issue_id
      comment_text = "AWS S3 bucket public access blocked."
    }
  }

  step "pipeline" "get_issue_transitions" {
    depends_on = [step.pipeline.add_comment]
    pipeline   = jira.pipeline.get_issue_transitions
    args = {
      issue_key = param.issue_id
    }
  }

  step "pipeline" "transition_issue" {
    depends_on = [step.pipeline.get_issue_transitions]
    pipeline   = jira.pipeline.transition_issue
    args = {
      issue_id      = param.issue_id
      transition_id = tonumber([for transition in step.pipeline.get_issue_transitions.output.transitions : transition.id if transition.name == "Done"][0])
    }
  }

}