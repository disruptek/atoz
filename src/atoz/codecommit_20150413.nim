
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS CodeCommit
## version: 2015-04-13
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS CodeCommit</fullname> <p>This is the <i>AWS CodeCommit API Reference</i>. This reference provides descriptions of the operations and data types for AWS CodeCommit API along with usage examples.</p> <p>You can use the AWS CodeCommit API to work with the following objects:</p> <p>Repositories, by calling the following:</p> <ul> <li> <p> <a>BatchGetRepositories</a>, which returns information about one or more repositories associated with your AWS account.</p> </li> <li> <p> <a>CreateRepository</a>, which creates an AWS CodeCommit repository.</p> </li> <li> <p> <a>DeleteRepository</a>, which deletes an AWS CodeCommit repository.</p> </li> <li> <p> <a>GetRepository</a>, which returns information about a specified repository.</p> </li> <li> <p> <a>ListRepositories</a>, which lists all AWS CodeCommit repositories associated with your AWS account.</p> </li> <li> <p> <a>UpdateRepositoryDescription</a>, which sets or updates the description of the repository.</p> </li> <li> <p> <a>UpdateRepositoryName</a>, which changes the name of the repository. If you change the name of a repository, no other users of that repository can access it until you send them the new HTTPS or SSH URL to use.</p> </li> </ul> <p>Branches, by calling the following:</p> <ul> <li> <p> <a>CreateBranch</a>, which creates a branch in a specified repository.</p> </li> <li> <p> <a>DeleteBranch</a>, which deletes the specified branch in a repository unless it is the default branch.</p> </li> <li> <p> <a>GetBranch</a>, which returns information about a specified branch.</p> </li> <li> <p> <a>ListBranches</a>, which lists all branches for a specified repository.</p> </li> <li> <p> <a>UpdateDefaultBranch</a>, which changes the default branch for a repository.</p> </li> </ul> <p>Files, by calling the following:</p> <ul> <li> <p> <a>DeleteFile</a>, which deletes the content of a specified file from a specified branch.</p> </li> <li> <p> <a>GetBlob</a>, which returns the base-64 encoded content of an individual Git blob object in a repository.</p> </li> <li> <p> <a>GetFile</a>, which returns the base-64 encoded content of a specified file.</p> </li> <li> <p> <a>GetFolder</a>, which returns the contents of a specified folder or directory.</p> </li> <li> <p> <a>PutFile</a>, which adds or modifies a single file in a specified repository and branch.</p> </li> </ul> <p>Commits, by calling the following:</p> <ul> <li> <p> <a>BatchGetCommits</a>, which returns information about one or more commits in a repository.</p> </li> <li> <p> <a>CreateCommit</a>, which creates a commit for changes to a repository.</p> </li> <li> <p> <a>GetCommit</a>, which returns information about a commit, including commit messages and author and committer information.</p> </li> <li> <p> <a>GetDifferences</a>, which returns information about the differences in a valid commit specifier (such as a branch, tag, HEAD, commit ID, or other fully qualified reference).</p> </li> </ul> <p>Merges, by calling the following:</p> <ul> <li> <p> <a>BatchDescribeMergeConflicts</a>, which returns information about conflicts in a merge between commits in a repository.</p> </li> <li> <p> <a>CreateUnreferencedMergeCommit</a>, which creates an unreferenced commit between two branches or commits for the purpose of comparing them and identifying any potential conflicts.</p> </li> <li> <p> <a>DescribeMergeConflicts</a>, which returns information about merge conflicts between the base, source, and destination versions of a file in a potential merge.</p> </li> <li> <p> <a>GetMergeCommit</a>, which returns information about the merge between a source and destination commit. </p> </li> <li> <p> <a>GetMergeConflicts</a>, which returns information about merge conflicts between the source and destination branch in a pull request.</p> </li> <li> <p> <a>GetMergeOptions</a>, which returns information about the available merge options between two branches or commit specifiers.</p> </li> <li> <p> <a>MergeBranchesByFastForward</a>, which merges two branches using the fast-forward merge option.</p> </li> <li> <p> <a>MergeBranchesBySquash</a>, which merges two branches using the squash merge option.</p> </li> <li> <p> <a>MergeBranchesByThreeWay</a>, which merges two branches using the three-way merge option.</p> </li> </ul> <p>Pull requests, by calling the following:</p> <ul> <li> <p> <a>CreatePullRequest</a>, which creates a pull request in a specified repository.</p> </li> <li> <p> <a>CreatePullRequestApprovalRule</a>, which creates an approval rule for a specified pull request.</p> </li> <li> <p> <a>DeletePullRequestApprovalRule</a>, which deletes an approval rule for a specified pull request.</p> </li> <li> <p> <a>DescribePullRequestEvents</a>, which returns information about one or more pull request events.</p> </li> <li> <p> <a>EvaluatePullRequestApprovalRules</a>, which evaluates whether a pull request has met all the conditions specified in its associated approval rules.</p> </li> <li> <p> <a>GetCommentsForPullRequest</a>, which returns information about comments on a specified pull request.</p> </li> <li> <p> <a>GetPullRequest</a>, which returns information about a specified pull request.</p> </li> <li> <p> <a>GetPullRequestApprovalStates</a>, which returns information about the approval states for a specified pull request.</p> </li> <li> <p> <a>GetPullRequestOverrideState</a>, which returns information about whether approval rules have been set aside (overriden) for a pull request, and if so, the Amazon Resource Name (ARN) of the user or identity that overrode the rules and their requirements for the pull request.</p> </li> <li> <p> <a>ListPullRequests</a>, which lists all pull requests for a repository.</p> </li> <li> <p> <a>MergePullRequestByFastForward</a>, which merges the source destination branch of a pull request into the specified destination branch for that pull request using the fast-forward merge option.</p> </li> <li> <p> <a>MergePullRequestBySquash</a>, which merges the source destination branch of a pull request into the specified destination branch for that pull request using the squash merge option.</p> </li> <li> <p> <a>MergePullRequestByThreeWay</a>. which merges the source destination branch of a pull request into the specified destination branch for that pull request using the three-way merge option.</p> </li> <li> <p> <a>OverridePullRequestApprovalRules</a>, which sets aside all approval rule requirements for a pull request.</p> </li> <li> <p> <a>PostCommentForPullRequest</a>, which posts a comment to a pull request at the specified line, file, or request.</p> </li> <li> <p> <a>UpdatePullRequestApprovalRuleContent</a>, which updates the structure of an approval rule for a pull request.</p> </li> <li> <p> <a>UpdatePullRequestApprovalState</a>, which updates the state of an approval on a pull request.</p> </li> <li> <p> <a>UpdatePullRequestDescription</a>, which updates the description of a pull request.</p> </li> <li> <p> <a>UpdatePullRequestStatus</a>, which updates the status of a pull request.</p> </li> <li> <p> <a>UpdatePullRequestTitle</a>, which updates the title of a pull request.</p> </li> </ul> <p>Approval rule templates, by calling the following:</p> <ul> <li> <p> <a>AssociateApprovalRuleTemplateWithRepository</a>, which associates a template with a specified repository. After the template is associated with a repository, AWS CodeCommit creates approval rules that match the template conditions on every pull request created in the specified repository.</p> </li> <li> <p> <a>BatchAssociateApprovalRuleTemplateWithRepositories</a>, which associates a template with one or more specified repositories. After the template is associated with a repository, AWS CodeCommit creates approval rules that match the template conditions on every pull request created in the specified repositories.</p> </li> <li> <p> <a>BatchDisassociateApprovalRuleTemplateFromRepositories</a>, which removes the association between a template and specified repositories so that approval rules based on the template are not automatically created when pull requests are created in those repositories.</p> </li> <li> <p> <a>CreateApprovalRuleTemplate</a>, which creates a template for approval rules that can then be associated with one or more repositories in your AWS account.</p> </li> <li> <p> <a>DeleteApprovalRuleTemplate</a>, which deletes the specified template. It does not remove approval rules on pull requests already created with the template.</p> </li> <li> <p> <a>DisassociateApprovalRuleTemplateFromRepository</a>, which removes the association between a template and a repository so that approval rules based on the template are not automatically created when pull requests are created in the specified repository.</p> </li> <li> <p> <a>GetApprovalRuleTemplate</a>, which returns information about an approval rule template.</p> </li> <li> <p> <a>ListApprovalRuleTemplates</a>, which lists all approval rule templates in the AWS Region in your AWS account.</p> </li> <li> <p> <a>ListAssociatedApprovalRuleTemplatesForRepository</a>, which lists all approval rule templates that are associated with a specified repository.</p> </li> <li> <p> <a>ListRepositoriesForApprovalRuleTemplate</a>, which lists all repositories associated with the specified approval rule template.</p> </li> <li> <p> <a>UpdateApprovalRuleTemplateDescription</a>, which updates the description of an approval rule template.</p> </li> <li> <p> <a>UpdateApprovalRuleTemplateName</a>, which updates the name of an approval rule template.</p> </li> <li> <p> <a>UpdateApprovalRuleTemplateContent</a>, which updates the content of an approval rule template.</p> </li> </ul> <p>Comments in a repository, by calling the following:</p> <ul> <li> <p> <a>DeleteCommentContent</a>, which deletes the content of a comment on a commit in a repository.</p> </li> <li> <p> <a>GetComment</a>, which returns information about a comment on a commit.</p> </li> <li> <p> <a>GetCommentsForComparedCommit</a>, which returns information about comments on the comparison between two commit specifiers in a repository.</p> </li> <li> <p> <a>PostCommentForComparedCommit</a>, which creates a comment on the comparison between two commit specifiers in a repository.</p> </li> <li> <p> <a>PostCommentReply</a>, which creates a reply to a comment.</p> </li> <li> <p> <a>UpdateComment</a>, which updates the content of a comment on a commit in a repository.</p> </li> </ul> <p>Tags used to tag resources in AWS CodeCommit (not Git tags), by calling the following:</p> <ul> <li> <p> <a>ListTagsForResource</a>, which gets information about AWS tags for a specified Amazon Resource Name (ARN) in AWS CodeCommit.</p> </li> <li> <p> <a>TagResource</a>, which adds or updates tags for a resource in AWS CodeCommit.</p> </li> <li> <p> <a>UntagResource</a>, which removes tags for a resource in AWS CodeCommit.</p> </li> </ul> <p>Triggers, by calling the following:</p> <ul> <li> <p> <a>GetRepositoryTriggers</a>, which returns information about triggers configured for a repository.</p> </li> <li> <p> <a>PutRepositoryTriggers</a>, which replaces all triggers for a repository and can be used to create or delete triggers.</p> </li> <li> <p> <a>TestRepositoryTriggers</a>, which tests the functionality of a repository trigger by sending data to the trigger target.</p> </li> </ul> <p>For information about how to use AWS CodeCommit, see the <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/welcome.html">AWS CodeCommit User Guide</a>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/codecommit/
type
  Scheme {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (query: JsonNode = nil; body: JsonNode = nil;
                          header: JsonNode = nil; path: JsonNode = nil;
                          formData: JsonNode = nil): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    url*: proc (protocol: Scheme; host: string; base: string; route: string;
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_612658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612658): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low ..
      Scheme.high:
    if scheme notin t.schemes:
      continue
    if scheme in [Scheme.Https, Scheme.Wss]:
      when defined(ssl):
        return some(scheme)
      else:
        continue
    return some(scheme)

proc validateParameter(js: JsonNode; kind: JsonNodeKind; required: bool;
                      default: JsonNode = nil): JsonNode =
  ## ensure an input is of the correct json type and yield
  ## a suitable default value when appropriate
  if js ==
      nil:
    if default != nil:
      return validateParameter(default, kind, required = required)
  result = js
  if result ==
      nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind ==
        kind, $kind & " expected; received " &
        $js.kind

type
  KeyVal {.used.} = tuple[key: string, val: string]
  PathTokenKind = enum
    ConstantSegment, VariableSegment
  PathToken = tuple[kind: PathTokenKind, value: string]
proc queryString(query: JsonNode): string {.used.} =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.used.} =
  ## reconstitute a path with constants and variable values taken from json
  var head: string
  if segments.len == 0:
    return some("")
  head = segments[0].value
  case segments[0].kind
  of ConstantSegment:
    discard
  of VariableSegment:
    if head notin input:
      return
    let js = input[head]
    case js.kind
    of JInt, JFloat, JNull, JBool:
      head = $js
    of JString:
      head = js.getStr
    else:
      return
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get)

const
  awsServers = {Scheme.Http: {"ap-northeast-1": "codecommit.ap-northeast-1.amazonaws.com", "ap-southeast-1": "codecommit.ap-southeast-1.amazonaws.com",
                           "us-west-2": "codecommit.us-west-2.amazonaws.com",
                           "eu-west-2": "codecommit.eu-west-2.amazonaws.com", "ap-northeast-3": "codecommit.ap-northeast-3.amazonaws.com", "eu-central-1": "codecommit.eu-central-1.amazonaws.com",
                           "us-east-2": "codecommit.us-east-2.amazonaws.com",
                           "us-east-1": "codecommit.us-east-1.amazonaws.com", "cn-northwest-1": "codecommit.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "codecommit.ap-south-1.amazonaws.com",
                           "eu-north-1": "codecommit.eu-north-1.amazonaws.com", "ap-northeast-2": "codecommit.ap-northeast-2.amazonaws.com",
                           "us-west-1": "codecommit.us-west-1.amazonaws.com", "us-gov-east-1": "codecommit.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "codecommit.eu-west-3.amazonaws.com", "cn-north-1": "codecommit.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "codecommit.sa-east-1.amazonaws.com",
                           "eu-west-1": "codecommit.eu-west-1.amazonaws.com", "us-gov-west-1": "codecommit.us-gov-west-1.amazonaws.com", "ap-southeast-2": "codecommit.ap-southeast-2.amazonaws.com", "ca-central-1": "codecommit.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "codecommit.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "codecommit.ap-southeast-1.amazonaws.com",
      "us-west-2": "codecommit.us-west-2.amazonaws.com",
      "eu-west-2": "codecommit.eu-west-2.amazonaws.com",
      "ap-northeast-3": "codecommit.ap-northeast-3.amazonaws.com",
      "eu-central-1": "codecommit.eu-central-1.amazonaws.com",
      "us-east-2": "codecommit.us-east-2.amazonaws.com",
      "us-east-1": "codecommit.us-east-1.amazonaws.com",
      "cn-northwest-1": "codecommit.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "codecommit.ap-south-1.amazonaws.com",
      "eu-north-1": "codecommit.eu-north-1.amazonaws.com",
      "ap-northeast-2": "codecommit.ap-northeast-2.amazonaws.com",
      "us-west-1": "codecommit.us-west-1.amazonaws.com",
      "us-gov-east-1": "codecommit.us-gov-east-1.amazonaws.com",
      "eu-west-3": "codecommit.eu-west-3.amazonaws.com",
      "cn-north-1": "codecommit.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "codecommit.sa-east-1.amazonaws.com",
      "eu-west-1": "codecommit.eu-west-1.amazonaws.com",
      "us-gov-west-1": "codecommit.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "codecommit.ap-southeast-2.amazonaws.com",
      "ca-central-1": "codecommit.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "codecommit"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AssociateApprovalRuleTemplateWithRepository_612996 = ref object of OpenApiRestCall_612658
proc url_AssociateApprovalRuleTemplateWithRepository_612998(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateApprovalRuleTemplateWithRepository_612997(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates an association between an approval rule template and a specified repository. Then, the next time a pull request is created in the repository where the destination reference (if specified) matches the destination reference (branch) for the pull request, an approval rule that matches the template conditions is automatically created for that pull request. If no destination references are specified in the template, an approval rule that matches the template contents is created for all pull requests in that repository.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613123 = header.getOrDefault("X-Amz-Target")
  valid_613123 = validateParameter(valid_613123, JString, required = true, default = newJString(
      "CodeCommit_20150413.AssociateApprovalRuleTemplateWithRepository"))
  if valid_613123 != nil:
    section.add "X-Amz-Target", valid_613123
  var valid_613124 = header.getOrDefault("X-Amz-Signature")
  valid_613124 = validateParameter(valid_613124, JString, required = false,
                                 default = nil)
  if valid_613124 != nil:
    section.add "X-Amz-Signature", valid_613124
  var valid_613125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613125 = validateParameter(valid_613125, JString, required = false,
                                 default = nil)
  if valid_613125 != nil:
    section.add "X-Amz-Content-Sha256", valid_613125
  var valid_613126 = header.getOrDefault("X-Amz-Date")
  valid_613126 = validateParameter(valid_613126, JString, required = false,
                                 default = nil)
  if valid_613126 != nil:
    section.add "X-Amz-Date", valid_613126
  var valid_613127 = header.getOrDefault("X-Amz-Credential")
  valid_613127 = validateParameter(valid_613127, JString, required = false,
                                 default = nil)
  if valid_613127 != nil:
    section.add "X-Amz-Credential", valid_613127
  var valid_613128 = header.getOrDefault("X-Amz-Security-Token")
  valid_613128 = validateParameter(valid_613128, JString, required = false,
                                 default = nil)
  if valid_613128 != nil:
    section.add "X-Amz-Security-Token", valid_613128
  var valid_613129 = header.getOrDefault("X-Amz-Algorithm")
  valid_613129 = validateParameter(valid_613129, JString, required = false,
                                 default = nil)
  if valid_613129 != nil:
    section.add "X-Amz-Algorithm", valid_613129
  var valid_613130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613130 = validateParameter(valid_613130, JString, required = false,
                                 default = nil)
  if valid_613130 != nil:
    section.add "X-Amz-SignedHeaders", valid_613130
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613154: Call_AssociateApprovalRuleTemplateWithRepository_612996;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates an association between an approval rule template and a specified repository. Then, the next time a pull request is created in the repository where the destination reference (if specified) matches the destination reference (branch) for the pull request, an approval rule that matches the template conditions is automatically created for that pull request. If no destination references are specified in the template, an approval rule that matches the template contents is created for all pull requests in that repository.
  ## 
  let valid = call_613154.validator(path, query, header, formData, body)
  let scheme = call_613154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613154.url(scheme.get, call_613154.host, call_613154.base,
                         call_613154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613154, url, valid)

proc call*(call_613225: Call_AssociateApprovalRuleTemplateWithRepository_612996;
          body: JsonNode): Recallable =
  ## associateApprovalRuleTemplateWithRepository
  ## Creates an association between an approval rule template and a specified repository. Then, the next time a pull request is created in the repository where the destination reference (if specified) matches the destination reference (branch) for the pull request, an approval rule that matches the template conditions is automatically created for that pull request. If no destination references are specified in the template, an approval rule that matches the template contents is created for all pull requests in that repository.
  ##   body: JObject (required)
  var body_613226 = newJObject()
  if body != nil:
    body_613226 = body
  result = call_613225.call(nil, nil, nil, nil, body_613226)

var associateApprovalRuleTemplateWithRepository* = Call_AssociateApprovalRuleTemplateWithRepository_612996(
    name: "associateApprovalRuleTemplateWithRepository",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.AssociateApprovalRuleTemplateWithRepository",
    validator: validate_AssociateApprovalRuleTemplateWithRepository_612997,
    base: "/", url: url_AssociateApprovalRuleTemplateWithRepository_612998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchAssociateApprovalRuleTemplateWithRepositories_613265 = ref object of OpenApiRestCall_612658
proc url_BatchAssociateApprovalRuleTemplateWithRepositories_613267(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchAssociateApprovalRuleTemplateWithRepositories_613266(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode): JsonNode =
  ## Creates an association between an approval rule template and one or more specified repositories. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613268 = header.getOrDefault("X-Amz-Target")
  valid_613268 = validateParameter(valid_613268, JString, required = true, default = newJString(
      "CodeCommit_20150413.BatchAssociateApprovalRuleTemplateWithRepositories"))
  if valid_613268 != nil:
    section.add "X-Amz-Target", valid_613268
  var valid_613269 = header.getOrDefault("X-Amz-Signature")
  valid_613269 = validateParameter(valid_613269, JString, required = false,
                                 default = nil)
  if valid_613269 != nil:
    section.add "X-Amz-Signature", valid_613269
  var valid_613270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613270 = validateParameter(valid_613270, JString, required = false,
                                 default = nil)
  if valid_613270 != nil:
    section.add "X-Amz-Content-Sha256", valid_613270
  var valid_613271 = header.getOrDefault("X-Amz-Date")
  valid_613271 = validateParameter(valid_613271, JString, required = false,
                                 default = nil)
  if valid_613271 != nil:
    section.add "X-Amz-Date", valid_613271
  var valid_613272 = header.getOrDefault("X-Amz-Credential")
  valid_613272 = validateParameter(valid_613272, JString, required = false,
                                 default = nil)
  if valid_613272 != nil:
    section.add "X-Amz-Credential", valid_613272
  var valid_613273 = header.getOrDefault("X-Amz-Security-Token")
  valid_613273 = validateParameter(valid_613273, JString, required = false,
                                 default = nil)
  if valid_613273 != nil:
    section.add "X-Amz-Security-Token", valid_613273
  var valid_613274 = header.getOrDefault("X-Amz-Algorithm")
  valid_613274 = validateParameter(valid_613274, JString, required = false,
                                 default = nil)
  if valid_613274 != nil:
    section.add "X-Amz-Algorithm", valid_613274
  var valid_613275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613275 = validateParameter(valid_613275, JString, required = false,
                                 default = nil)
  if valid_613275 != nil:
    section.add "X-Amz-SignedHeaders", valid_613275
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613277: Call_BatchAssociateApprovalRuleTemplateWithRepositories_613265;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates an association between an approval rule template and one or more specified repositories. 
  ## 
  let valid = call_613277.validator(path, query, header, formData, body)
  let scheme = call_613277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613277.url(scheme.get, call_613277.host, call_613277.base,
                         call_613277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613277, url, valid)

proc call*(call_613278: Call_BatchAssociateApprovalRuleTemplateWithRepositories_613265;
          body: JsonNode): Recallable =
  ## batchAssociateApprovalRuleTemplateWithRepositories
  ## Creates an association between an approval rule template and one or more specified repositories. 
  ##   body: JObject (required)
  var body_613279 = newJObject()
  if body != nil:
    body_613279 = body
  result = call_613278.call(nil, nil, nil, nil, body_613279)

var batchAssociateApprovalRuleTemplateWithRepositories* = Call_BatchAssociateApprovalRuleTemplateWithRepositories_613265(
    name: "batchAssociateApprovalRuleTemplateWithRepositories",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.BatchAssociateApprovalRuleTemplateWithRepositories",
    validator: validate_BatchAssociateApprovalRuleTemplateWithRepositories_613266,
    base: "/", url: url_BatchAssociateApprovalRuleTemplateWithRepositories_613267,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDescribeMergeConflicts_613280 = ref object of OpenApiRestCall_612658
proc url_BatchDescribeMergeConflicts_613282(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchDescribeMergeConflicts_613281(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about one or more merge conflicts in the attempted merge of two commit specifiers using the squash or three-way merge strategy.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613283 = header.getOrDefault("X-Amz-Target")
  valid_613283 = validateParameter(valid_613283, JString, required = true, default = newJString(
      "CodeCommit_20150413.BatchDescribeMergeConflicts"))
  if valid_613283 != nil:
    section.add "X-Amz-Target", valid_613283
  var valid_613284 = header.getOrDefault("X-Amz-Signature")
  valid_613284 = validateParameter(valid_613284, JString, required = false,
                                 default = nil)
  if valid_613284 != nil:
    section.add "X-Amz-Signature", valid_613284
  var valid_613285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613285 = validateParameter(valid_613285, JString, required = false,
                                 default = nil)
  if valid_613285 != nil:
    section.add "X-Amz-Content-Sha256", valid_613285
  var valid_613286 = header.getOrDefault("X-Amz-Date")
  valid_613286 = validateParameter(valid_613286, JString, required = false,
                                 default = nil)
  if valid_613286 != nil:
    section.add "X-Amz-Date", valid_613286
  var valid_613287 = header.getOrDefault("X-Amz-Credential")
  valid_613287 = validateParameter(valid_613287, JString, required = false,
                                 default = nil)
  if valid_613287 != nil:
    section.add "X-Amz-Credential", valid_613287
  var valid_613288 = header.getOrDefault("X-Amz-Security-Token")
  valid_613288 = validateParameter(valid_613288, JString, required = false,
                                 default = nil)
  if valid_613288 != nil:
    section.add "X-Amz-Security-Token", valid_613288
  var valid_613289 = header.getOrDefault("X-Amz-Algorithm")
  valid_613289 = validateParameter(valid_613289, JString, required = false,
                                 default = nil)
  if valid_613289 != nil:
    section.add "X-Amz-Algorithm", valid_613289
  var valid_613290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613290 = validateParameter(valid_613290, JString, required = false,
                                 default = nil)
  if valid_613290 != nil:
    section.add "X-Amz-SignedHeaders", valid_613290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613292: Call_BatchDescribeMergeConflicts_613280; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about one or more merge conflicts in the attempted merge of two commit specifiers using the squash or three-way merge strategy.
  ## 
  let valid = call_613292.validator(path, query, header, formData, body)
  let scheme = call_613292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613292.url(scheme.get, call_613292.host, call_613292.base,
                         call_613292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613292, url, valid)

proc call*(call_613293: Call_BatchDescribeMergeConflicts_613280; body: JsonNode): Recallable =
  ## batchDescribeMergeConflicts
  ## Returns information about one or more merge conflicts in the attempted merge of two commit specifiers using the squash or three-way merge strategy.
  ##   body: JObject (required)
  var body_613294 = newJObject()
  if body != nil:
    body_613294 = body
  result = call_613293.call(nil, nil, nil, nil, body_613294)

var batchDescribeMergeConflicts* = Call_BatchDescribeMergeConflicts_613280(
    name: "batchDescribeMergeConflicts", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.BatchDescribeMergeConflicts",
    validator: validate_BatchDescribeMergeConflicts_613281, base: "/",
    url: url_BatchDescribeMergeConflicts_613282,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDisassociateApprovalRuleTemplateFromRepositories_613295 = ref object of OpenApiRestCall_612658
proc url_BatchDisassociateApprovalRuleTemplateFromRepositories_613297(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchDisassociateApprovalRuleTemplateFromRepositories_613296(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode): JsonNode =
  ## Removes the association between an approval rule template and one or more specified repositories. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613298 = header.getOrDefault("X-Amz-Target")
  valid_613298 = validateParameter(valid_613298, JString, required = true, default = newJString("CodeCommit_20150413.BatchDisassociateApprovalRuleTemplateFromRepositories"))
  if valid_613298 != nil:
    section.add "X-Amz-Target", valid_613298
  var valid_613299 = header.getOrDefault("X-Amz-Signature")
  valid_613299 = validateParameter(valid_613299, JString, required = false,
                                 default = nil)
  if valid_613299 != nil:
    section.add "X-Amz-Signature", valid_613299
  var valid_613300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613300 = validateParameter(valid_613300, JString, required = false,
                                 default = nil)
  if valid_613300 != nil:
    section.add "X-Amz-Content-Sha256", valid_613300
  var valid_613301 = header.getOrDefault("X-Amz-Date")
  valid_613301 = validateParameter(valid_613301, JString, required = false,
                                 default = nil)
  if valid_613301 != nil:
    section.add "X-Amz-Date", valid_613301
  var valid_613302 = header.getOrDefault("X-Amz-Credential")
  valid_613302 = validateParameter(valid_613302, JString, required = false,
                                 default = nil)
  if valid_613302 != nil:
    section.add "X-Amz-Credential", valid_613302
  var valid_613303 = header.getOrDefault("X-Amz-Security-Token")
  valid_613303 = validateParameter(valid_613303, JString, required = false,
                                 default = nil)
  if valid_613303 != nil:
    section.add "X-Amz-Security-Token", valid_613303
  var valid_613304 = header.getOrDefault("X-Amz-Algorithm")
  valid_613304 = validateParameter(valid_613304, JString, required = false,
                                 default = nil)
  if valid_613304 != nil:
    section.add "X-Amz-Algorithm", valid_613304
  var valid_613305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613305 = validateParameter(valid_613305, JString, required = false,
                                 default = nil)
  if valid_613305 != nil:
    section.add "X-Amz-SignedHeaders", valid_613305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613307: Call_BatchDisassociateApprovalRuleTemplateFromRepositories_613295;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Removes the association between an approval rule template and one or more specified repositories. 
  ## 
  let valid = call_613307.validator(path, query, header, formData, body)
  let scheme = call_613307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613307.url(scheme.get, call_613307.host, call_613307.base,
                         call_613307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613307, url, valid)

proc call*(call_613308: Call_BatchDisassociateApprovalRuleTemplateFromRepositories_613295;
          body: JsonNode): Recallable =
  ## batchDisassociateApprovalRuleTemplateFromRepositories
  ## Removes the association between an approval rule template and one or more specified repositories. 
  ##   body: JObject (required)
  var body_613309 = newJObject()
  if body != nil:
    body_613309 = body
  result = call_613308.call(nil, nil, nil, nil, body_613309)

var batchDisassociateApprovalRuleTemplateFromRepositories* = Call_BatchDisassociateApprovalRuleTemplateFromRepositories_613295(
    name: "batchDisassociateApprovalRuleTemplateFromRepositories",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.BatchDisassociateApprovalRuleTemplateFromRepositories",
    validator: validate_BatchDisassociateApprovalRuleTemplateFromRepositories_613296,
    base: "/", url: url_BatchDisassociateApprovalRuleTemplateFromRepositories_613297,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetCommits_613310 = ref object of OpenApiRestCall_612658
proc url_BatchGetCommits_613312(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetCommits_613311(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Returns information about the contents of one or more commits in a repository.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613313 = header.getOrDefault("X-Amz-Target")
  valid_613313 = validateParameter(valid_613313, JString, required = true, default = newJString(
      "CodeCommit_20150413.BatchGetCommits"))
  if valid_613313 != nil:
    section.add "X-Amz-Target", valid_613313
  var valid_613314 = header.getOrDefault("X-Amz-Signature")
  valid_613314 = validateParameter(valid_613314, JString, required = false,
                                 default = nil)
  if valid_613314 != nil:
    section.add "X-Amz-Signature", valid_613314
  var valid_613315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613315 = validateParameter(valid_613315, JString, required = false,
                                 default = nil)
  if valid_613315 != nil:
    section.add "X-Amz-Content-Sha256", valid_613315
  var valid_613316 = header.getOrDefault("X-Amz-Date")
  valid_613316 = validateParameter(valid_613316, JString, required = false,
                                 default = nil)
  if valid_613316 != nil:
    section.add "X-Amz-Date", valid_613316
  var valid_613317 = header.getOrDefault("X-Amz-Credential")
  valid_613317 = validateParameter(valid_613317, JString, required = false,
                                 default = nil)
  if valid_613317 != nil:
    section.add "X-Amz-Credential", valid_613317
  var valid_613318 = header.getOrDefault("X-Amz-Security-Token")
  valid_613318 = validateParameter(valid_613318, JString, required = false,
                                 default = nil)
  if valid_613318 != nil:
    section.add "X-Amz-Security-Token", valid_613318
  var valid_613319 = header.getOrDefault("X-Amz-Algorithm")
  valid_613319 = validateParameter(valid_613319, JString, required = false,
                                 default = nil)
  if valid_613319 != nil:
    section.add "X-Amz-Algorithm", valid_613319
  var valid_613320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613320 = validateParameter(valid_613320, JString, required = false,
                                 default = nil)
  if valid_613320 != nil:
    section.add "X-Amz-SignedHeaders", valid_613320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613322: Call_BatchGetCommits_613310; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the contents of one or more commits in a repository.
  ## 
  let valid = call_613322.validator(path, query, header, formData, body)
  let scheme = call_613322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613322.url(scheme.get, call_613322.host, call_613322.base,
                         call_613322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613322, url, valid)

proc call*(call_613323: Call_BatchGetCommits_613310; body: JsonNode): Recallable =
  ## batchGetCommits
  ## Returns information about the contents of one or more commits in a repository.
  ##   body: JObject (required)
  var body_613324 = newJObject()
  if body != nil:
    body_613324 = body
  result = call_613323.call(nil, nil, nil, nil, body_613324)

var batchGetCommits* = Call_BatchGetCommits_613310(name: "batchGetCommits",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.BatchGetCommits",
    validator: validate_BatchGetCommits_613311, base: "/", url: url_BatchGetCommits_613312,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetRepositories_613325 = ref object of OpenApiRestCall_612658
proc url_BatchGetRepositories_613327(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetRepositories_613326(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns information about one or more repositories.</p> <note> <p>The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a webpage can expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a webpage.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613328 = header.getOrDefault("X-Amz-Target")
  valid_613328 = validateParameter(valid_613328, JString, required = true, default = newJString(
      "CodeCommit_20150413.BatchGetRepositories"))
  if valid_613328 != nil:
    section.add "X-Amz-Target", valid_613328
  var valid_613329 = header.getOrDefault("X-Amz-Signature")
  valid_613329 = validateParameter(valid_613329, JString, required = false,
                                 default = nil)
  if valid_613329 != nil:
    section.add "X-Amz-Signature", valid_613329
  var valid_613330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613330 = validateParameter(valid_613330, JString, required = false,
                                 default = nil)
  if valid_613330 != nil:
    section.add "X-Amz-Content-Sha256", valid_613330
  var valid_613331 = header.getOrDefault("X-Amz-Date")
  valid_613331 = validateParameter(valid_613331, JString, required = false,
                                 default = nil)
  if valid_613331 != nil:
    section.add "X-Amz-Date", valid_613331
  var valid_613332 = header.getOrDefault("X-Amz-Credential")
  valid_613332 = validateParameter(valid_613332, JString, required = false,
                                 default = nil)
  if valid_613332 != nil:
    section.add "X-Amz-Credential", valid_613332
  var valid_613333 = header.getOrDefault("X-Amz-Security-Token")
  valid_613333 = validateParameter(valid_613333, JString, required = false,
                                 default = nil)
  if valid_613333 != nil:
    section.add "X-Amz-Security-Token", valid_613333
  var valid_613334 = header.getOrDefault("X-Amz-Algorithm")
  valid_613334 = validateParameter(valid_613334, JString, required = false,
                                 default = nil)
  if valid_613334 != nil:
    section.add "X-Amz-Algorithm", valid_613334
  var valid_613335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613335 = validateParameter(valid_613335, JString, required = false,
                                 default = nil)
  if valid_613335 != nil:
    section.add "X-Amz-SignedHeaders", valid_613335
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613337: Call_BatchGetRepositories_613325; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about one or more repositories.</p> <note> <p>The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a webpage can expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a webpage.</p> </note>
  ## 
  let valid = call_613337.validator(path, query, header, formData, body)
  let scheme = call_613337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613337.url(scheme.get, call_613337.host, call_613337.base,
                         call_613337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613337, url, valid)

proc call*(call_613338: Call_BatchGetRepositories_613325; body: JsonNode): Recallable =
  ## batchGetRepositories
  ## <p>Returns information about one or more repositories.</p> <note> <p>The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a webpage can expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a webpage.</p> </note>
  ##   body: JObject (required)
  var body_613339 = newJObject()
  if body != nil:
    body_613339 = body
  result = call_613338.call(nil, nil, nil, nil, body_613339)

var batchGetRepositories* = Call_BatchGetRepositories_613325(
    name: "batchGetRepositories", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.BatchGetRepositories",
    validator: validate_BatchGetRepositories_613326, base: "/",
    url: url_BatchGetRepositories_613327, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateApprovalRuleTemplate_613340 = ref object of OpenApiRestCall_612658
proc url_CreateApprovalRuleTemplate_613342(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateApprovalRuleTemplate_613341(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a template for approval rules that can then be associated with one or more repositories in your AWS account. When you associate a template with a repository, AWS CodeCommit creates an approval rule that matches the conditions of the template for all pull requests that meet the conditions of the template. For more information, see <a>AssociateApprovalRuleTemplateWithRepository</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613343 = header.getOrDefault("X-Amz-Target")
  valid_613343 = validateParameter(valid_613343, JString, required = true, default = newJString(
      "CodeCommit_20150413.CreateApprovalRuleTemplate"))
  if valid_613343 != nil:
    section.add "X-Amz-Target", valid_613343
  var valid_613344 = header.getOrDefault("X-Amz-Signature")
  valid_613344 = validateParameter(valid_613344, JString, required = false,
                                 default = nil)
  if valid_613344 != nil:
    section.add "X-Amz-Signature", valid_613344
  var valid_613345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613345 = validateParameter(valid_613345, JString, required = false,
                                 default = nil)
  if valid_613345 != nil:
    section.add "X-Amz-Content-Sha256", valid_613345
  var valid_613346 = header.getOrDefault("X-Amz-Date")
  valid_613346 = validateParameter(valid_613346, JString, required = false,
                                 default = nil)
  if valid_613346 != nil:
    section.add "X-Amz-Date", valid_613346
  var valid_613347 = header.getOrDefault("X-Amz-Credential")
  valid_613347 = validateParameter(valid_613347, JString, required = false,
                                 default = nil)
  if valid_613347 != nil:
    section.add "X-Amz-Credential", valid_613347
  var valid_613348 = header.getOrDefault("X-Amz-Security-Token")
  valid_613348 = validateParameter(valid_613348, JString, required = false,
                                 default = nil)
  if valid_613348 != nil:
    section.add "X-Amz-Security-Token", valid_613348
  var valid_613349 = header.getOrDefault("X-Amz-Algorithm")
  valid_613349 = validateParameter(valid_613349, JString, required = false,
                                 default = nil)
  if valid_613349 != nil:
    section.add "X-Amz-Algorithm", valid_613349
  var valid_613350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613350 = validateParameter(valid_613350, JString, required = false,
                                 default = nil)
  if valid_613350 != nil:
    section.add "X-Amz-SignedHeaders", valid_613350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613352: Call_CreateApprovalRuleTemplate_613340; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a template for approval rules that can then be associated with one or more repositories in your AWS account. When you associate a template with a repository, AWS CodeCommit creates an approval rule that matches the conditions of the template for all pull requests that meet the conditions of the template. For more information, see <a>AssociateApprovalRuleTemplateWithRepository</a>.
  ## 
  let valid = call_613352.validator(path, query, header, formData, body)
  let scheme = call_613352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613352.url(scheme.get, call_613352.host, call_613352.base,
                         call_613352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613352, url, valid)

proc call*(call_613353: Call_CreateApprovalRuleTemplate_613340; body: JsonNode): Recallable =
  ## createApprovalRuleTemplate
  ## Creates a template for approval rules that can then be associated with one or more repositories in your AWS account. When you associate a template with a repository, AWS CodeCommit creates an approval rule that matches the conditions of the template for all pull requests that meet the conditions of the template. For more information, see <a>AssociateApprovalRuleTemplateWithRepository</a>.
  ##   body: JObject (required)
  var body_613354 = newJObject()
  if body != nil:
    body_613354 = body
  result = call_613353.call(nil, nil, nil, nil, body_613354)

var createApprovalRuleTemplate* = Call_CreateApprovalRuleTemplate_613340(
    name: "createApprovalRuleTemplate", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.CreateApprovalRuleTemplate",
    validator: validate_CreateApprovalRuleTemplate_613341, base: "/",
    url: url_CreateApprovalRuleTemplate_613342,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBranch_613355 = ref object of OpenApiRestCall_612658
proc url_CreateBranch_613357(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateBranch_613356(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a branch in a repository and points the branch to a commit.</p> <note> <p>Calling the create branch operation does not set a repository's default branch. To do this, call the update default branch operation.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613358 = header.getOrDefault("X-Amz-Target")
  valid_613358 = validateParameter(valid_613358, JString, required = true, default = newJString(
      "CodeCommit_20150413.CreateBranch"))
  if valid_613358 != nil:
    section.add "X-Amz-Target", valid_613358
  var valid_613359 = header.getOrDefault("X-Amz-Signature")
  valid_613359 = validateParameter(valid_613359, JString, required = false,
                                 default = nil)
  if valid_613359 != nil:
    section.add "X-Amz-Signature", valid_613359
  var valid_613360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613360 = validateParameter(valid_613360, JString, required = false,
                                 default = nil)
  if valid_613360 != nil:
    section.add "X-Amz-Content-Sha256", valid_613360
  var valid_613361 = header.getOrDefault("X-Amz-Date")
  valid_613361 = validateParameter(valid_613361, JString, required = false,
                                 default = nil)
  if valid_613361 != nil:
    section.add "X-Amz-Date", valid_613361
  var valid_613362 = header.getOrDefault("X-Amz-Credential")
  valid_613362 = validateParameter(valid_613362, JString, required = false,
                                 default = nil)
  if valid_613362 != nil:
    section.add "X-Amz-Credential", valid_613362
  var valid_613363 = header.getOrDefault("X-Amz-Security-Token")
  valid_613363 = validateParameter(valid_613363, JString, required = false,
                                 default = nil)
  if valid_613363 != nil:
    section.add "X-Amz-Security-Token", valid_613363
  var valid_613364 = header.getOrDefault("X-Amz-Algorithm")
  valid_613364 = validateParameter(valid_613364, JString, required = false,
                                 default = nil)
  if valid_613364 != nil:
    section.add "X-Amz-Algorithm", valid_613364
  var valid_613365 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613365 = validateParameter(valid_613365, JString, required = false,
                                 default = nil)
  if valid_613365 != nil:
    section.add "X-Amz-SignedHeaders", valid_613365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613367: Call_CreateBranch_613355; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a branch in a repository and points the branch to a commit.</p> <note> <p>Calling the create branch operation does not set a repository's default branch. To do this, call the update default branch operation.</p> </note>
  ## 
  let valid = call_613367.validator(path, query, header, formData, body)
  let scheme = call_613367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613367.url(scheme.get, call_613367.host, call_613367.base,
                         call_613367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613367, url, valid)

proc call*(call_613368: Call_CreateBranch_613355; body: JsonNode): Recallable =
  ## createBranch
  ## <p>Creates a branch in a repository and points the branch to a commit.</p> <note> <p>Calling the create branch operation does not set a repository's default branch. To do this, call the update default branch operation.</p> </note>
  ##   body: JObject (required)
  var body_613369 = newJObject()
  if body != nil:
    body_613369 = body
  result = call_613368.call(nil, nil, nil, nil, body_613369)

var createBranch* = Call_CreateBranch_613355(name: "createBranch",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.CreateBranch",
    validator: validate_CreateBranch_613356, base: "/", url: url_CreateBranch_613357,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCommit_613370 = ref object of OpenApiRestCall_612658
proc url_CreateCommit_613372(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateCommit_613371(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a commit for a repository on the tip of a specified branch.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613373 = header.getOrDefault("X-Amz-Target")
  valid_613373 = validateParameter(valid_613373, JString, required = true, default = newJString(
      "CodeCommit_20150413.CreateCommit"))
  if valid_613373 != nil:
    section.add "X-Amz-Target", valid_613373
  var valid_613374 = header.getOrDefault("X-Amz-Signature")
  valid_613374 = validateParameter(valid_613374, JString, required = false,
                                 default = nil)
  if valid_613374 != nil:
    section.add "X-Amz-Signature", valid_613374
  var valid_613375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613375 = validateParameter(valid_613375, JString, required = false,
                                 default = nil)
  if valid_613375 != nil:
    section.add "X-Amz-Content-Sha256", valid_613375
  var valid_613376 = header.getOrDefault("X-Amz-Date")
  valid_613376 = validateParameter(valid_613376, JString, required = false,
                                 default = nil)
  if valid_613376 != nil:
    section.add "X-Amz-Date", valid_613376
  var valid_613377 = header.getOrDefault("X-Amz-Credential")
  valid_613377 = validateParameter(valid_613377, JString, required = false,
                                 default = nil)
  if valid_613377 != nil:
    section.add "X-Amz-Credential", valid_613377
  var valid_613378 = header.getOrDefault("X-Amz-Security-Token")
  valid_613378 = validateParameter(valid_613378, JString, required = false,
                                 default = nil)
  if valid_613378 != nil:
    section.add "X-Amz-Security-Token", valid_613378
  var valid_613379 = header.getOrDefault("X-Amz-Algorithm")
  valid_613379 = validateParameter(valid_613379, JString, required = false,
                                 default = nil)
  if valid_613379 != nil:
    section.add "X-Amz-Algorithm", valid_613379
  var valid_613380 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613380 = validateParameter(valid_613380, JString, required = false,
                                 default = nil)
  if valid_613380 != nil:
    section.add "X-Amz-SignedHeaders", valid_613380
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613382: Call_CreateCommit_613370; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a commit for a repository on the tip of a specified branch.
  ## 
  let valid = call_613382.validator(path, query, header, formData, body)
  let scheme = call_613382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613382.url(scheme.get, call_613382.host, call_613382.base,
                         call_613382.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613382, url, valid)

proc call*(call_613383: Call_CreateCommit_613370; body: JsonNode): Recallable =
  ## createCommit
  ## Creates a commit for a repository on the tip of a specified branch.
  ##   body: JObject (required)
  var body_613384 = newJObject()
  if body != nil:
    body_613384 = body
  result = call_613383.call(nil, nil, nil, nil, body_613384)

var createCommit* = Call_CreateCommit_613370(name: "createCommit",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.CreateCommit",
    validator: validate_CreateCommit_613371, base: "/", url: url_CreateCommit_613372,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePullRequest_613385 = ref object of OpenApiRestCall_612658
proc url_CreatePullRequest_613387(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePullRequest_613386(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Creates a pull request in the specified repository.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613388 = header.getOrDefault("X-Amz-Target")
  valid_613388 = validateParameter(valid_613388, JString, required = true, default = newJString(
      "CodeCommit_20150413.CreatePullRequest"))
  if valid_613388 != nil:
    section.add "X-Amz-Target", valid_613388
  var valid_613389 = header.getOrDefault("X-Amz-Signature")
  valid_613389 = validateParameter(valid_613389, JString, required = false,
                                 default = nil)
  if valid_613389 != nil:
    section.add "X-Amz-Signature", valid_613389
  var valid_613390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613390 = validateParameter(valid_613390, JString, required = false,
                                 default = nil)
  if valid_613390 != nil:
    section.add "X-Amz-Content-Sha256", valid_613390
  var valid_613391 = header.getOrDefault("X-Amz-Date")
  valid_613391 = validateParameter(valid_613391, JString, required = false,
                                 default = nil)
  if valid_613391 != nil:
    section.add "X-Amz-Date", valid_613391
  var valid_613392 = header.getOrDefault("X-Amz-Credential")
  valid_613392 = validateParameter(valid_613392, JString, required = false,
                                 default = nil)
  if valid_613392 != nil:
    section.add "X-Amz-Credential", valid_613392
  var valid_613393 = header.getOrDefault("X-Amz-Security-Token")
  valid_613393 = validateParameter(valid_613393, JString, required = false,
                                 default = nil)
  if valid_613393 != nil:
    section.add "X-Amz-Security-Token", valid_613393
  var valid_613394 = header.getOrDefault("X-Amz-Algorithm")
  valid_613394 = validateParameter(valid_613394, JString, required = false,
                                 default = nil)
  if valid_613394 != nil:
    section.add "X-Amz-Algorithm", valid_613394
  var valid_613395 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613395 = validateParameter(valid_613395, JString, required = false,
                                 default = nil)
  if valid_613395 != nil:
    section.add "X-Amz-SignedHeaders", valid_613395
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613397: Call_CreatePullRequest_613385; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a pull request in the specified repository.
  ## 
  let valid = call_613397.validator(path, query, header, formData, body)
  let scheme = call_613397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613397.url(scheme.get, call_613397.host, call_613397.base,
                         call_613397.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613397, url, valid)

proc call*(call_613398: Call_CreatePullRequest_613385; body: JsonNode): Recallable =
  ## createPullRequest
  ## Creates a pull request in the specified repository.
  ##   body: JObject (required)
  var body_613399 = newJObject()
  if body != nil:
    body_613399 = body
  result = call_613398.call(nil, nil, nil, nil, body_613399)

var createPullRequest* = Call_CreatePullRequest_613385(name: "createPullRequest",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.CreatePullRequest",
    validator: validate_CreatePullRequest_613386, base: "/",
    url: url_CreatePullRequest_613387, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePullRequestApprovalRule_613400 = ref object of OpenApiRestCall_612658
proc url_CreatePullRequestApprovalRule_613402(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePullRequestApprovalRule_613401(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates an approval rule for a pull request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613403 = header.getOrDefault("X-Amz-Target")
  valid_613403 = validateParameter(valid_613403, JString, required = true, default = newJString(
      "CodeCommit_20150413.CreatePullRequestApprovalRule"))
  if valid_613403 != nil:
    section.add "X-Amz-Target", valid_613403
  var valid_613404 = header.getOrDefault("X-Amz-Signature")
  valid_613404 = validateParameter(valid_613404, JString, required = false,
                                 default = nil)
  if valid_613404 != nil:
    section.add "X-Amz-Signature", valid_613404
  var valid_613405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613405 = validateParameter(valid_613405, JString, required = false,
                                 default = nil)
  if valid_613405 != nil:
    section.add "X-Amz-Content-Sha256", valid_613405
  var valid_613406 = header.getOrDefault("X-Amz-Date")
  valid_613406 = validateParameter(valid_613406, JString, required = false,
                                 default = nil)
  if valid_613406 != nil:
    section.add "X-Amz-Date", valid_613406
  var valid_613407 = header.getOrDefault("X-Amz-Credential")
  valid_613407 = validateParameter(valid_613407, JString, required = false,
                                 default = nil)
  if valid_613407 != nil:
    section.add "X-Amz-Credential", valid_613407
  var valid_613408 = header.getOrDefault("X-Amz-Security-Token")
  valid_613408 = validateParameter(valid_613408, JString, required = false,
                                 default = nil)
  if valid_613408 != nil:
    section.add "X-Amz-Security-Token", valid_613408
  var valid_613409 = header.getOrDefault("X-Amz-Algorithm")
  valid_613409 = validateParameter(valid_613409, JString, required = false,
                                 default = nil)
  if valid_613409 != nil:
    section.add "X-Amz-Algorithm", valid_613409
  var valid_613410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613410 = validateParameter(valid_613410, JString, required = false,
                                 default = nil)
  if valid_613410 != nil:
    section.add "X-Amz-SignedHeaders", valid_613410
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613412: Call_CreatePullRequestApprovalRule_613400; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an approval rule for a pull request.
  ## 
  let valid = call_613412.validator(path, query, header, formData, body)
  let scheme = call_613412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613412.url(scheme.get, call_613412.host, call_613412.base,
                         call_613412.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613412, url, valid)

proc call*(call_613413: Call_CreatePullRequestApprovalRule_613400; body: JsonNode): Recallable =
  ## createPullRequestApprovalRule
  ## Creates an approval rule for a pull request.
  ##   body: JObject (required)
  var body_613414 = newJObject()
  if body != nil:
    body_613414 = body
  result = call_613413.call(nil, nil, nil, nil, body_613414)

var createPullRequestApprovalRule* = Call_CreatePullRequestApprovalRule_613400(
    name: "createPullRequestApprovalRule", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.CreatePullRequestApprovalRule",
    validator: validate_CreatePullRequestApprovalRule_613401, base: "/",
    url: url_CreatePullRequestApprovalRule_613402,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRepository_613415 = ref object of OpenApiRestCall_612658
proc url_CreateRepository_613417(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateRepository_613416(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Creates a new, empty repository.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613418 = header.getOrDefault("X-Amz-Target")
  valid_613418 = validateParameter(valid_613418, JString, required = true, default = newJString(
      "CodeCommit_20150413.CreateRepository"))
  if valid_613418 != nil:
    section.add "X-Amz-Target", valid_613418
  var valid_613419 = header.getOrDefault("X-Amz-Signature")
  valid_613419 = validateParameter(valid_613419, JString, required = false,
                                 default = nil)
  if valid_613419 != nil:
    section.add "X-Amz-Signature", valid_613419
  var valid_613420 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613420 = validateParameter(valid_613420, JString, required = false,
                                 default = nil)
  if valid_613420 != nil:
    section.add "X-Amz-Content-Sha256", valid_613420
  var valid_613421 = header.getOrDefault("X-Amz-Date")
  valid_613421 = validateParameter(valid_613421, JString, required = false,
                                 default = nil)
  if valid_613421 != nil:
    section.add "X-Amz-Date", valid_613421
  var valid_613422 = header.getOrDefault("X-Amz-Credential")
  valid_613422 = validateParameter(valid_613422, JString, required = false,
                                 default = nil)
  if valid_613422 != nil:
    section.add "X-Amz-Credential", valid_613422
  var valid_613423 = header.getOrDefault("X-Amz-Security-Token")
  valid_613423 = validateParameter(valid_613423, JString, required = false,
                                 default = nil)
  if valid_613423 != nil:
    section.add "X-Amz-Security-Token", valid_613423
  var valid_613424 = header.getOrDefault("X-Amz-Algorithm")
  valid_613424 = validateParameter(valid_613424, JString, required = false,
                                 default = nil)
  if valid_613424 != nil:
    section.add "X-Amz-Algorithm", valid_613424
  var valid_613425 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613425 = validateParameter(valid_613425, JString, required = false,
                                 default = nil)
  if valid_613425 != nil:
    section.add "X-Amz-SignedHeaders", valid_613425
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613427: Call_CreateRepository_613415; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new, empty repository.
  ## 
  let valid = call_613427.validator(path, query, header, formData, body)
  let scheme = call_613427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613427.url(scheme.get, call_613427.host, call_613427.base,
                         call_613427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613427, url, valid)

proc call*(call_613428: Call_CreateRepository_613415; body: JsonNode): Recallable =
  ## createRepository
  ## Creates a new, empty repository.
  ##   body: JObject (required)
  var body_613429 = newJObject()
  if body != nil:
    body_613429 = body
  result = call_613428.call(nil, nil, nil, nil, body_613429)

var createRepository* = Call_CreateRepository_613415(name: "createRepository",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.CreateRepository",
    validator: validate_CreateRepository_613416, base: "/",
    url: url_CreateRepository_613417, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUnreferencedMergeCommit_613430 = ref object of OpenApiRestCall_612658
proc url_CreateUnreferencedMergeCommit_613432(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateUnreferencedMergeCommit_613431(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an unreferenced commit that represents the result of merging two branches using a specified merge strategy. This can help you determine the outcome of a potential merge. This API cannot be used with the fast-forward merge strategy because that strategy does not create a merge commit.</p> <note> <p>This unreferenced merge commit can only be accessed using the GetCommit API or through git commands such as git fetch. To retrieve this commit, you must specify its commit ID or otherwise reference it.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613433 = header.getOrDefault("X-Amz-Target")
  valid_613433 = validateParameter(valid_613433, JString, required = true, default = newJString(
      "CodeCommit_20150413.CreateUnreferencedMergeCommit"))
  if valid_613433 != nil:
    section.add "X-Amz-Target", valid_613433
  var valid_613434 = header.getOrDefault("X-Amz-Signature")
  valid_613434 = validateParameter(valid_613434, JString, required = false,
                                 default = nil)
  if valid_613434 != nil:
    section.add "X-Amz-Signature", valid_613434
  var valid_613435 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613435 = validateParameter(valid_613435, JString, required = false,
                                 default = nil)
  if valid_613435 != nil:
    section.add "X-Amz-Content-Sha256", valid_613435
  var valid_613436 = header.getOrDefault("X-Amz-Date")
  valid_613436 = validateParameter(valid_613436, JString, required = false,
                                 default = nil)
  if valid_613436 != nil:
    section.add "X-Amz-Date", valid_613436
  var valid_613437 = header.getOrDefault("X-Amz-Credential")
  valid_613437 = validateParameter(valid_613437, JString, required = false,
                                 default = nil)
  if valid_613437 != nil:
    section.add "X-Amz-Credential", valid_613437
  var valid_613438 = header.getOrDefault("X-Amz-Security-Token")
  valid_613438 = validateParameter(valid_613438, JString, required = false,
                                 default = nil)
  if valid_613438 != nil:
    section.add "X-Amz-Security-Token", valid_613438
  var valid_613439 = header.getOrDefault("X-Amz-Algorithm")
  valid_613439 = validateParameter(valid_613439, JString, required = false,
                                 default = nil)
  if valid_613439 != nil:
    section.add "X-Amz-Algorithm", valid_613439
  var valid_613440 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613440 = validateParameter(valid_613440, JString, required = false,
                                 default = nil)
  if valid_613440 != nil:
    section.add "X-Amz-SignedHeaders", valid_613440
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613442: Call_CreateUnreferencedMergeCommit_613430; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an unreferenced commit that represents the result of merging two branches using a specified merge strategy. This can help you determine the outcome of a potential merge. This API cannot be used with the fast-forward merge strategy because that strategy does not create a merge commit.</p> <note> <p>This unreferenced merge commit can only be accessed using the GetCommit API or through git commands such as git fetch. To retrieve this commit, you must specify its commit ID or otherwise reference it.</p> </note>
  ## 
  let valid = call_613442.validator(path, query, header, formData, body)
  let scheme = call_613442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613442.url(scheme.get, call_613442.host, call_613442.base,
                         call_613442.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613442, url, valid)

proc call*(call_613443: Call_CreateUnreferencedMergeCommit_613430; body: JsonNode): Recallable =
  ## createUnreferencedMergeCommit
  ## <p>Creates an unreferenced commit that represents the result of merging two branches using a specified merge strategy. This can help you determine the outcome of a potential merge. This API cannot be used with the fast-forward merge strategy because that strategy does not create a merge commit.</p> <note> <p>This unreferenced merge commit can only be accessed using the GetCommit API or through git commands such as git fetch. To retrieve this commit, you must specify its commit ID or otherwise reference it.</p> </note>
  ##   body: JObject (required)
  var body_613444 = newJObject()
  if body != nil:
    body_613444 = body
  result = call_613443.call(nil, nil, nil, nil, body_613444)

var createUnreferencedMergeCommit* = Call_CreateUnreferencedMergeCommit_613430(
    name: "createUnreferencedMergeCommit", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.CreateUnreferencedMergeCommit",
    validator: validate_CreateUnreferencedMergeCommit_613431, base: "/",
    url: url_CreateUnreferencedMergeCommit_613432,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApprovalRuleTemplate_613445 = ref object of OpenApiRestCall_612658
proc url_DeleteApprovalRuleTemplate_613447(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteApprovalRuleTemplate_613446(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a specified approval rule template. Deleting a template does not remove approval rules on pull requests already created with the template.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613448 = header.getOrDefault("X-Amz-Target")
  valid_613448 = validateParameter(valid_613448, JString, required = true, default = newJString(
      "CodeCommit_20150413.DeleteApprovalRuleTemplate"))
  if valid_613448 != nil:
    section.add "X-Amz-Target", valid_613448
  var valid_613449 = header.getOrDefault("X-Amz-Signature")
  valid_613449 = validateParameter(valid_613449, JString, required = false,
                                 default = nil)
  if valid_613449 != nil:
    section.add "X-Amz-Signature", valid_613449
  var valid_613450 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613450 = validateParameter(valid_613450, JString, required = false,
                                 default = nil)
  if valid_613450 != nil:
    section.add "X-Amz-Content-Sha256", valid_613450
  var valid_613451 = header.getOrDefault("X-Amz-Date")
  valid_613451 = validateParameter(valid_613451, JString, required = false,
                                 default = nil)
  if valid_613451 != nil:
    section.add "X-Amz-Date", valid_613451
  var valid_613452 = header.getOrDefault("X-Amz-Credential")
  valid_613452 = validateParameter(valid_613452, JString, required = false,
                                 default = nil)
  if valid_613452 != nil:
    section.add "X-Amz-Credential", valid_613452
  var valid_613453 = header.getOrDefault("X-Amz-Security-Token")
  valid_613453 = validateParameter(valid_613453, JString, required = false,
                                 default = nil)
  if valid_613453 != nil:
    section.add "X-Amz-Security-Token", valid_613453
  var valid_613454 = header.getOrDefault("X-Amz-Algorithm")
  valid_613454 = validateParameter(valid_613454, JString, required = false,
                                 default = nil)
  if valid_613454 != nil:
    section.add "X-Amz-Algorithm", valid_613454
  var valid_613455 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613455 = validateParameter(valid_613455, JString, required = false,
                                 default = nil)
  if valid_613455 != nil:
    section.add "X-Amz-SignedHeaders", valid_613455
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613457: Call_DeleteApprovalRuleTemplate_613445; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified approval rule template. Deleting a template does not remove approval rules on pull requests already created with the template.
  ## 
  let valid = call_613457.validator(path, query, header, formData, body)
  let scheme = call_613457.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613457.url(scheme.get, call_613457.host, call_613457.base,
                         call_613457.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613457, url, valid)

proc call*(call_613458: Call_DeleteApprovalRuleTemplate_613445; body: JsonNode): Recallable =
  ## deleteApprovalRuleTemplate
  ## Deletes a specified approval rule template. Deleting a template does not remove approval rules on pull requests already created with the template.
  ##   body: JObject (required)
  var body_613459 = newJObject()
  if body != nil:
    body_613459 = body
  result = call_613458.call(nil, nil, nil, nil, body_613459)

var deleteApprovalRuleTemplate* = Call_DeleteApprovalRuleTemplate_613445(
    name: "deleteApprovalRuleTemplate", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.DeleteApprovalRuleTemplate",
    validator: validate_DeleteApprovalRuleTemplate_613446, base: "/",
    url: url_DeleteApprovalRuleTemplate_613447,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBranch_613460 = ref object of OpenApiRestCall_612658
proc url_DeleteBranch_613462(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteBranch_613461(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a branch from a repository, unless that branch is the default branch for the repository. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613463 = header.getOrDefault("X-Amz-Target")
  valid_613463 = validateParameter(valid_613463, JString, required = true, default = newJString(
      "CodeCommit_20150413.DeleteBranch"))
  if valid_613463 != nil:
    section.add "X-Amz-Target", valid_613463
  var valid_613464 = header.getOrDefault("X-Amz-Signature")
  valid_613464 = validateParameter(valid_613464, JString, required = false,
                                 default = nil)
  if valid_613464 != nil:
    section.add "X-Amz-Signature", valid_613464
  var valid_613465 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613465 = validateParameter(valid_613465, JString, required = false,
                                 default = nil)
  if valid_613465 != nil:
    section.add "X-Amz-Content-Sha256", valid_613465
  var valid_613466 = header.getOrDefault("X-Amz-Date")
  valid_613466 = validateParameter(valid_613466, JString, required = false,
                                 default = nil)
  if valid_613466 != nil:
    section.add "X-Amz-Date", valid_613466
  var valid_613467 = header.getOrDefault("X-Amz-Credential")
  valid_613467 = validateParameter(valid_613467, JString, required = false,
                                 default = nil)
  if valid_613467 != nil:
    section.add "X-Amz-Credential", valid_613467
  var valid_613468 = header.getOrDefault("X-Amz-Security-Token")
  valid_613468 = validateParameter(valid_613468, JString, required = false,
                                 default = nil)
  if valid_613468 != nil:
    section.add "X-Amz-Security-Token", valid_613468
  var valid_613469 = header.getOrDefault("X-Amz-Algorithm")
  valid_613469 = validateParameter(valid_613469, JString, required = false,
                                 default = nil)
  if valid_613469 != nil:
    section.add "X-Amz-Algorithm", valid_613469
  var valid_613470 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613470 = validateParameter(valid_613470, JString, required = false,
                                 default = nil)
  if valid_613470 != nil:
    section.add "X-Amz-SignedHeaders", valid_613470
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613472: Call_DeleteBranch_613460; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a branch from a repository, unless that branch is the default branch for the repository. 
  ## 
  let valid = call_613472.validator(path, query, header, formData, body)
  let scheme = call_613472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613472.url(scheme.get, call_613472.host, call_613472.base,
                         call_613472.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613472, url, valid)

proc call*(call_613473: Call_DeleteBranch_613460; body: JsonNode): Recallable =
  ## deleteBranch
  ## Deletes a branch from a repository, unless that branch is the default branch for the repository. 
  ##   body: JObject (required)
  var body_613474 = newJObject()
  if body != nil:
    body_613474 = body
  result = call_613473.call(nil, nil, nil, nil, body_613474)

var deleteBranch* = Call_DeleteBranch_613460(name: "deleteBranch",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.DeleteBranch",
    validator: validate_DeleteBranch_613461, base: "/", url: url_DeleteBranch_613462,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCommentContent_613475 = ref object of OpenApiRestCall_612658
proc url_DeleteCommentContent_613477(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteCommentContent_613476(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the content of a comment made on a change, file, or commit in a repository.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613478 = header.getOrDefault("X-Amz-Target")
  valid_613478 = validateParameter(valid_613478, JString, required = true, default = newJString(
      "CodeCommit_20150413.DeleteCommentContent"))
  if valid_613478 != nil:
    section.add "X-Amz-Target", valid_613478
  var valid_613479 = header.getOrDefault("X-Amz-Signature")
  valid_613479 = validateParameter(valid_613479, JString, required = false,
                                 default = nil)
  if valid_613479 != nil:
    section.add "X-Amz-Signature", valid_613479
  var valid_613480 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613480 = validateParameter(valid_613480, JString, required = false,
                                 default = nil)
  if valid_613480 != nil:
    section.add "X-Amz-Content-Sha256", valid_613480
  var valid_613481 = header.getOrDefault("X-Amz-Date")
  valid_613481 = validateParameter(valid_613481, JString, required = false,
                                 default = nil)
  if valid_613481 != nil:
    section.add "X-Amz-Date", valid_613481
  var valid_613482 = header.getOrDefault("X-Amz-Credential")
  valid_613482 = validateParameter(valid_613482, JString, required = false,
                                 default = nil)
  if valid_613482 != nil:
    section.add "X-Amz-Credential", valid_613482
  var valid_613483 = header.getOrDefault("X-Amz-Security-Token")
  valid_613483 = validateParameter(valid_613483, JString, required = false,
                                 default = nil)
  if valid_613483 != nil:
    section.add "X-Amz-Security-Token", valid_613483
  var valid_613484 = header.getOrDefault("X-Amz-Algorithm")
  valid_613484 = validateParameter(valid_613484, JString, required = false,
                                 default = nil)
  if valid_613484 != nil:
    section.add "X-Amz-Algorithm", valid_613484
  var valid_613485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613485 = validateParameter(valid_613485, JString, required = false,
                                 default = nil)
  if valid_613485 != nil:
    section.add "X-Amz-SignedHeaders", valid_613485
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613487: Call_DeleteCommentContent_613475; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the content of a comment made on a change, file, or commit in a repository.
  ## 
  let valid = call_613487.validator(path, query, header, formData, body)
  let scheme = call_613487.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613487.url(scheme.get, call_613487.host, call_613487.base,
                         call_613487.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613487, url, valid)

proc call*(call_613488: Call_DeleteCommentContent_613475; body: JsonNode): Recallable =
  ## deleteCommentContent
  ## Deletes the content of a comment made on a change, file, or commit in a repository.
  ##   body: JObject (required)
  var body_613489 = newJObject()
  if body != nil:
    body_613489 = body
  result = call_613488.call(nil, nil, nil, nil, body_613489)

var deleteCommentContent* = Call_DeleteCommentContent_613475(
    name: "deleteCommentContent", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.DeleteCommentContent",
    validator: validate_DeleteCommentContent_613476, base: "/",
    url: url_DeleteCommentContent_613477, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFile_613490 = ref object of OpenApiRestCall_612658
proc url_DeleteFile_613492(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteFile_613491(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a specified file from a specified branch. A commit is created on the branch that contains the revision. The file still exists in the commits earlier to the commit that contains the deletion.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613493 = header.getOrDefault("X-Amz-Target")
  valid_613493 = validateParameter(valid_613493, JString, required = true, default = newJString(
      "CodeCommit_20150413.DeleteFile"))
  if valid_613493 != nil:
    section.add "X-Amz-Target", valid_613493
  var valid_613494 = header.getOrDefault("X-Amz-Signature")
  valid_613494 = validateParameter(valid_613494, JString, required = false,
                                 default = nil)
  if valid_613494 != nil:
    section.add "X-Amz-Signature", valid_613494
  var valid_613495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613495 = validateParameter(valid_613495, JString, required = false,
                                 default = nil)
  if valid_613495 != nil:
    section.add "X-Amz-Content-Sha256", valid_613495
  var valid_613496 = header.getOrDefault("X-Amz-Date")
  valid_613496 = validateParameter(valid_613496, JString, required = false,
                                 default = nil)
  if valid_613496 != nil:
    section.add "X-Amz-Date", valid_613496
  var valid_613497 = header.getOrDefault("X-Amz-Credential")
  valid_613497 = validateParameter(valid_613497, JString, required = false,
                                 default = nil)
  if valid_613497 != nil:
    section.add "X-Amz-Credential", valid_613497
  var valid_613498 = header.getOrDefault("X-Amz-Security-Token")
  valid_613498 = validateParameter(valid_613498, JString, required = false,
                                 default = nil)
  if valid_613498 != nil:
    section.add "X-Amz-Security-Token", valid_613498
  var valid_613499 = header.getOrDefault("X-Amz-Algorithm")
  valid_613499 = validateParameter(valid_613499, JString, required = false,
                                 default = nil)
  if valid_613499 != nil:
    section.add "X-Amz-Algorithm", valid_613499
  var valid_613500 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613500 = validateParameter(valid_613500, JString, required = false,
                                 default = nil)
  if valid_613500 != nil:
    section.add "X-Amz-SignedHeaders", valid_613500
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613502: Call_DeleteFile_613490; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified file from a specified branch. A commit is created on the branch that contains the revision. The file still exists in the commits earlier to the commit that contains the deletion.
  ## 
  let valid = call_613502.validator(path, query, header, formData, body)
  let scheme = call_613502.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613502.url(scheme.get, call_613502.host, call_613502.base,
                         call_613502.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613502, url, valid)

proc call*(call_613503: Call_DeleteFile_613490; body: JsonNode): Recallable =
  ## deleteFile
  ## Deletes a specified file from a specified branch. A commit is created on the branch that contains the revision. The file still exists in the commits earlier to the commit that contains the deletion.
  ##   body: JObject (required)
  var body_613504 = newJObject()
  if body != nil:
    body_613504 = body
  result = call_613503.call(nil, nil, nil, nil, body_613504)

var deleteFile* = Call_DeleteFile_613490(name: "deleteFile",
                                      meth: HttpMethod.HttpPost,
                                      host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.DeleteFile",
                                      validator: validate_DeleteFile_613491,
                                      base: "/", url: url_DeleteFile_613492,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePullRequestApprovalRule_613505 = ref object of OpenApiRestCall_612658
proc url_DeletePullRequestApprovalRule_613507(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeletePullRequestApprovalRule_613506(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an approval rule from a specified pull request. Approval rules can be deleted from a pull request only if the pull request is open, and if the approval rule was created specifically for a pull request and not generated from an approval rule template associated with the repository where the pull request was created. You cannot delete an approval rule from a merged or closed pull request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613508 = header.getOrDefault("X-Amz-Target")
  valid_613508 = validateParameter(valid_613508, JString, required = true, default = newJString(
      "CodeCommit_20150413.DeletePullRequestApprovalRule"))
  if valid_613508 != nil:
    section.add "X-Amz-Target", valid_613508
  var valid_613509 = header.getOrDefault("X-Amz-Signature")
  valid_613509 = validateParameter(valid_613509, JString, required = false,
                                 default = nil)
  if valid_613509 != nil:
    section.add "X-Amz-Signature", valid_613509
  var valid_613510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613510 = validateParameter(valid_613510, JString, required = false,
                                 default = nil)
  if valid_613510 != nil:
    section.add "X-Amz-Content-Sha256", valid_613510
  var valid_613511 = header.getOrDefault("X-Amz-Date")
  valid_613511 = validateParameter(valid_613511, JString, required = false,
                                 default = nil)
  if valid_613511 != nil:
    section.add "X-Amz-Date", valid_613511
  var valid_613512 = header.getOrDefault("X-Amz-Credential")
  valid_613512 = validateParameter(valid_613512, JString, required = false,
                                 default = nil)
  if valid_613512 != nil:
    section.add "X-Amz-Credential", valid_613512
  var valid_613513 = header.getOrDefault("X-Amz-Security-Token")
  valid_613513 = validateParameter(valid_613513, JString, required = false,
                                 default = nil)
  if valid_613513 != nil:
    section.add "X-Amz-Security-Token", valid_613513
  var valid_613514 = header.getOrDefault("X-Amz-Algorithm")
  valid_613514 = validateParameter(valid_613514, JString, required = false,
                                 default = nil)
  if valid_613514 != nil:
    section.add "X-Amz-Algorithm", valid_613514
  var valid_613515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613515 = validateParameter(valid_613515, JString, required = false,
                                 default = nil)
  if valid_613515 != nil:
    section.add "X-Amz-SignedHeaders", valid_613515
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613517: Call_DeletePullRequestApprovalRule_613505; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an approval rule from a specified pull request. Approval rules can be deleted from a pull request only if the pull request is open, and if the approval rule was created specifically for a pull request and not generated from an approval rule template associated with the repository where the pull request was created. You cannot delete an approval rule from a merged or closed pull request.
  ## 
  let valid = call_613517.validator(path, query, header, formData, body)
  let scheme = call_613517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613517.url(scheme.get, call_613517.host, call_613517.base,
                         call_613517.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613517, url, valid)

proc call*(call_613518: Call_DeletePullRequestApprovalRule_613505; body: JsonNode): Recallable =
  ## deletePullRequestApprovalRule
  ## Deletes an approval rule from a specified pull request. Approval rules can be deleted from a pull request only if the pull request is open, and if the approval rule was created specifically for a pull request and not generated from an approval rule template associated with the repository where the pull request was created. You cannot delete an approval rule from a merged or closed pull request.
  ##   body: JObject (required)
  var body_613519 = newJObject()
  if body != nil:
    body_613519 = body
  result = call_613518.call(nil, nil, nil, nil, body_613519)

var deletePullRequestApprovalRule* = Call_DeletePullRequestApprovalRule_613505(
    name: "deletePullRequestApprovalRule", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.DeletePullRequestApprovalRule",
    validator: validate_DeletePullRequestApprovalRule_613506, base: "/",
    url: url_DeletePullRequestApprovalRule_613507,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRepository_613520 = ref object of OpenApiRestCall_612658
proc url_DeleteRepository_613522(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteRepository_613521(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Deletes a repository. If a specified repository was already deleted, a null repository ID is returned.</p> <important> <p>Deleting a repository also deletes all associated objects and metadata. After a repository is deleted, all future push calls to the deleted repository fail.</p> </important>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613523 = header.getOrDefault("X-Amz-Target")
  valid_613523 = validateParameter(valid_613523, JString, required = true, default = newJString(
      "CodeCommit_20150413.DeleteRepository"))
  if valid_613523 != nil:
    section.add "X-Amz-Target", valid_613523
  var valid_613524 = header.getOrDefault("X-Amz-Signature")
  valid_613524 = validateParameter(valid_613524, JString, required = false,
                                 default = nil)
  if valid_613524 != nil:
    section.add "X-Amz-Signature", valid_613524
  var valid_613525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613525 = validateParameter(valid_613525, JString, required = false,
                                 default = nil)
  if valid_613525 != nil:
    section.add "X-Amz-Content-Sha256", valid_613525
  var valid_613526 = header.getOrDefault("X-Amz-Date")
  valid_613526 = validateParameter(valid_613526, JString, required = false,
                                 default = nil)
  if valid_613526 != nil:
    section.add "X-Amz-Date", valid_613526
  var valid_613527 = header.getOrDefault("X-Amz-Credential")
  valid_613527 = validateParameter(valid_613527, JString, required = false,
                                 default = nil)
  if valid_613527 != nil:
    section.add "X-Amz-Credential", valid_613527
  var valid_613528 = header.getOrDefault("X-Amz-Security-Token")
  valid_613528 = validateParameter(valid_613528, JString, required = false,
                                 default = nil)
  if valid_613528 != nil:
    section.add "X-Amz-Security-Token", valid_613528
  var valid_613529 = header.getOrDefault("X-Amz-Algorithm")
  valid_613529 = validateParameter(valid_613529, JString, required = false,
                                 default = nil)
  if valid_613529 != nil:
    section.add "X-Amz-Algorithm", valid_613529
  var valid_613530 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613530 = validateParameter(valid_613530, JString, required = false,
                                 default = nil)
  if valid_613530 != nil:
    section.add "X-Amz-SignedHeaders", valid_613530
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613532: Call_DeleteRepository_613520; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a repository. If a specified repository was already deleted, a null repository ID is returned.</p> <important> <p>Deleting a repository also deletes all associated objects and metadata. After a repository is deleted, all future push calls to the deleted repository fail.</p> </important>
  ## 
  let valid = call_613532.validator(path, query, header, formData, body)
  let scheme = call_613532.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613532.url(scheme.get, call_613532.host, call_613532.base,
                         call_613532.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613532, url, valid)

proc call*(call_613533: Call_DeleteRepository_613520; body: JsonNode): Recallable =
  ## deleteRepository
  ## <p>Deletes a repository. If a specified repository was already deleted, a null repository ID is returned.</p> <important> <p>Deleting a repository also deletes all associated objects and metadata. After a repository is deleted, all future push calls to the deleted repository fail.</p> </important>
  ##   body: JObject (required)
  var body_613534 = newJObject()
  if body != nil:
    body_613534 = body
  result = call_613533.call(nil, nil, nil, nil, body_613534)

var deleteRepository* = Call_DeleteRepository_613520(name: "deleteRepository",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.DeleteRepository",
    validator: validate_DeleteRepository_613521, base: "/",
    url: url_DeleteRepository_613522, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMergeConflicts_613535 = ref object of OpenApiRestCall_612658
proc url_DescribeMergeConflicts_613537(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeMergeConflicts_613536(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about one or more merge conflicts in the attempted merge of two commit specifiers using the squash or three-way merge strategy. If the merge option for the attempted merge is specified as FAST_FORWARD_MERGE, an exception is thrown.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxMergeHunks: JString
  ##                : Pagination limit
  section = newJObject()
  var valid_613538 = query.getOrDefault("nextToken")
  valid_613538 = validateParameter(valid_613538, JString, required = false,
                                 default = nil)
  if valid_613538 != nil:
    section.add "nextToken", valid_613538
  var valid_613539 = query.getOrDefault("maxMergeHunks")
  valid_613539 = validateParameter(valid_613539, JString, required = false,
                                 default = nil)
  if valid_613539 != nil:
    section.add "maxMergeHunks", valid_613539
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613540 = header.getOrDefault("X-Amz-Target")
  valid_613540 = validateParameter(valid_613540, JString, required = true, default = newJString(
      "CodeCommit_20150413.DescribeMergeConflicts"))
  if valid_613540 != nil:
    section.add "X-Amz-Target", valid_613540
  var valid_613541 = header.getOrDefault("X-Amz-Signature")
  valid_613541 = validateParameter(valid_613541, JString, required = false,
                                 default = nil)
  if valid_613541 != nil:
    section.add "X-Amz-Signature", valid_613541
  var valid_613542 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613542 = validateParameter(valid_613542, JString, required = false,
                                 default = nil)
  if valid_613542 != nil:
    section.add "X-Amz-Content-Sha256", valid_613542
  var valid_613543 = header.getOrDefault("X-Amz-Date")
  valid_613543 = validateParameter(valid_613543, JString, required = false,
                                 default = nil)
  if valid_613543 != nil:
    section.add "X-Amz-Date", valid_613543
  var valid_613544 = header.getOrDefault("X-Amz-Credential")
  valid_613544 = validateParameter(valid_613544, JString, required = false,
                                 default = nil)
  if valid_613544 != nil:
    section.add "X-Amz-Credential", valid_613544
  var valid_613545 = header.getOrDefault("X-Amz-Security-Token")
  valid_613545 = validateParameter(valid_613545, JString, required = false,
                                 default = nil)
  if valid_613545 != nil:
    section.add "X-Amz-Security-Token", valid_613545
  var valid_613546 = header.getOrDefault("X-Amz-Algorithm")
  valid_613546 = validateParameter(valid_613546, JString, required = false,
                                 default = nil)
  if valid_613546 != nil:
    section.add "X-Amz-Algorithm", valid_613546
  var valid_613547 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613547 = validateParameter(valid_613547, JString, required = false,
                                 default = nil)
  if valid_613547 != nil:
    section.add "X-Amz-SignedHeaders", valid_613547
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613549: Call_DescribeMergeConflicts_613535; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about one or more merge conflicts in the attempted merge of two commit specifiers using the squash or three-way merge strategy. If the merge option for the attempted merge is specified as FAST_FORWARD_MERGE, an exception is thrown.
  ## 
  let valid = call_613549.validator(path, query, header, formData, body)
  let scheme = call_613549.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613549.url(scheme.get, call_613549.host, call_613549.base,
                         call_613549.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613549, url, valid)

proc call*(call_613550: Call_DescribeMergeConflicts_613535; body: JsonNode;
          nextToken: string = ""; maxMergeHunks: string = ""): Recallable =
  ## describeMergeConflicts
  ## Returns information about one or more merge conflicts in the attempted merge of two commit specifiers using the squash or three-way merge strategy. If the merge option for the attempted merge is specified as FAST_FORWARD_MERGE, an exception is thrown.
  ##   nextToken: string
  ##            : Pagination token
  ##   maxMergeHunks: string
  ##                : Pagination limit
  ##   body: JObject (required)
  var query_613551 = newJObject()
  var body_613552 = newJObject()
  add(query_613551, "nextToken", newJString(nextToken))
  add(query_613551, "maxMergeHunks", newJString(maxMergeHunks))
  if body != nil:
    body_613552 = body
  result = call_613550.call(nil, query_613551, nil, nil, body_613552)

var describeMergeConflicts* = Call_DescribeMergeConflicts_613535(
    name: "describeMergeConflicts", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.DescribeMergeConflicts",
    validator: validate_DescribeMergeConflicts_613536, base: "/",
    url: url_DescribeMergeConflicts_613537, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePullRequestEvents_613554 = ref object of OpenApiRestCall_612658
proc url_DescribePullRequestEvents_613556(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribePullRequestEvents_613555(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about one or more pull request events.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_613557 = query.getOrDefault("nextToken")
  valid_613557 = validateParameter(valid_613557, JString, required = false,
                                 default = nil)
  if valid_613557 != nil:
    section.add "nextToken", valid_613557
  var valid_613558 = query.getOrDefault("maxResults")
  valid_613558 = validateParameter(valid_613558, JString, required = false,
                                 default = nil)
  if valid_613558 != nil:
    section.add "maxResults", valid_613558
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613559 = header.getOrDefault("X-Amz-Target")
  valid_613559 = validateParameter(valid_613559, JString, required = true, default = newJString(
      "CodeCommit_20150413.DescribePullRequestEvents"))
  if valid_613559 != nil:
    section.add "X-Amz-Target", valid_613559
  var valid_613560 = header.getOrDefault("X-Amz-Signature")
  valid_613560 = validateParameter(valid_613560, JString, required = false,
                                 default = nil)
  if valid_613560 != nil:
    section.add "X-Amz-Signature", valid_613560
  var valid_613561 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613561 = validateParameter(valid_613561, JString, required = false,
                                 default = nil)
  if valid_613561 != nil:
    section.add "X-Amz-Content-Sha256", valid_613561
  var valid_613562 = header.getOrDefault("X-Amz-Date")
  valid_613562 = validateParameter(valid_613562, JString, required = false,
                                 default = nil)
  if valid_613562 != nil:
    section.add "X-Amz-Date", valid_613562
  var valid_613563 = header.getOrDefault("X-Amz-Credential")
  valid_613563 = validateParameter(valid_613563, JString, required = false,
                                 default = nil)
  if valid_613563 != nil:
    section.add "X-Amz-Credential", valid_613563
  var valid_613564 = header.getOrDefault("X-Amz-Security-Token")
  valid_613564 = validateParameter(valid_613564, JString, required = false,
                                 default = nil)
  if valid_613564 != nil:
    section.add "X-Amz-Security-Token", valid_613564
  var valid_613565 = header.getOrDefault("X-Amz-Algorithm")
  valid_613565 = validateParameter(valid_613565, JString, required = false,
                                 default = nil)
  if valid_613565 != nil:
    section.add "X-Amz-Algorithm", valid_613565
  var valid_613566 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613566 = validateParameter(valid_613566, JString, required = false,
                                 default = nil)
  if valid_613566 != nil:
    section.add "X-Amz-SignedHeaders", valid_613566
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613568: Call_DescribePullRequestEvents_613554; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about one or more pull request events.
  ## 
  let valid = call_613568.validator(path, query, header, formData, body)
  let scheme = call_613568.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613568.url(scheme.get, call_613568.host, call_613568.base,
                         call_613568.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613568, url, valid)

proc call*(call_613569: Call_DescribePullRequestEvents_613554; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## describePullRequestEvents
  ## Returns information about one or more pull request events.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_613570 = newJObject()
  var body_613571 = newJObject()
  add(query_613570, "nextToken", newJString(nextToken))
  if body != nil:
    body_613571 = body
  add(query_613570, "maxResults", newJString(maxResults))
  result = call_613569.call(nil, query_613570, nil, nil, body_613571)

var describePullRequestEvents* = Call_DescribePullRequestEvents_613554(
    name: "describePullRequestEvents", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.DescribePullRequestEvents",
    validator: validate_DescribePullRequestEvents_613555, base: "/",
    url: url_DescribePullRequestEvents_613556,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateApprovalRuleTemplateFromRepository_613572 = ref object of OpenApiRestCall_612658
proc url_DisassociateApprovalRuleTemplateFromRepository_613574(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateApprovalRuleTemplateFromRepository_613573(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode): JsonNode =
  ## Removes the association between a template and a repository so that approval rules based on the template are not automatically created when pull requests are created in the specified repository. This does not delete any approval rules previously created for pull requests through the template association.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613575 = header.getOrDefault("X-Amz-Target")
  valid_613575 = validateParameter(valid_613575, JString, required = true, default = newJString(
      "CodeCommit_20150413.DisassociateApprovalRuleTemplateFromRepository"))
  if valid_613575 != nil:
    section.add "X-Amz-Target", valid_613575
  var valid_613576 = header.getOrDefault("X-Amz-Signature")
  valid_613576 = validateParameter(valid_613576, JString, required = false,
                                 default = nil)
  if valid_613576 != nil:
    section.add "X-Amz-Signature", valid_613576
  var valid_613577 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613577 = validateParameter(valid_613577, JString, required = false,
                                 default = nil)
  if valid_613577 != nil:
    section.add "X-Amz-Content-Sha256", valid_613577
  var valid_613578 = header.getOrDefault("X-Amz-Date")
  valid_613578 = validateParameter(valid_613578, JString, required = false,
                                 default = nil)
  if valid_613578 != nil:
    section.add "X-Amz-Date", valid_613578
  var valid_613579 = header.getOrDefault("X-Amz-Credential")
  valid_613579 = validateParameter(valid_613579, JString, required = false,
                                 default = nil)
  if valid_613579 != nil:
    section.add "X-Amz-Credential", valid_613579
  var valid_613580 = header.getOrDefault("X-Amz-Security-Token")
  valid_613580 = validateParameter(valid_613580, JString, required = false,
                                 default = nil)
  if valid_613580 != nil:
    section.add "X-Amz-Security-Token", valid_613580
  var valid_613581 = header.getOrDefault("X-Amz-Algorithm")
  valid_613581 = validateParameter(valid_613581, JString, required = false,
                                 default = nil)
  if valid_613581 != nil:
    section.add "X-Amz-Algorithm", valid_613581
  var valid_613582 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613582 = validateParameter(valid_613582, JString, required = false,
                                 default = nil)
  if valid_613582 != nil:
    section.add "X-Amz-SignedHeaders", valid_613582
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613584: Call_DisassociateApprovalRuleTemplateFromRepository_613572;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Removes the association between a template and a repository so that approval rules based on the template are not automatically created when pull requests are created in the specified repository. This does not delete any approval rules previously created for pull requests through the template association.
  ## 
  let valid = call_613584.validator(path, query, header, formData, body)
  let scheme = call_613584.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613584.url(scheme.get, call_613584.host, call_613584.base,
                         call_613584.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613584, url, valid)

proc call*(call_613585: Call_DisassociateApprovalRuleTemplateFromRepository_613572;
          body: JsonNode): Recallable =
  ## disassociateApprovalRuleTemplateFromRepository
  ## Removes the association between a template and a repository so that approval rules based on the template are not automatically created when pull requests are created in the specified repository. This does not delete any approval rules previously created for pull requests through the template association.
  ##   body: JObject (required)
  var body_613586 = newJObject()
  if body != nil:
    body_613586 = body
  result = call_613585.call(nil, nil, nil, nil, body_613586)

var disassociateApprovalRuleTemplateFromRepository* = Call_DisassociateApprovalRuleTemplateFromRepository_613572(
    name: "disassociateApprovalRuleTemplateFromRepository",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.DisassociateApprovalRuleTemplateFromRepository",
    validator: validate_DisassociateApprovalRuleTemplateFromRepository_613573,
    base: "/", url: url_DisassociateApprovalRuleTemplateFromRepository_613574,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_EvaluatePullRequestApprovalRules_613587 = ref object of OpenApiRestCall_612658
proc url_EvaluatePullRequestApprovalRules_613589(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_EvaluatePullRequestApprovalRules_613588(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Evaluates whether a pull request has met all the conditions specified in its associated approval rules.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613590 = header.getOrDefault("X-Amz-Target")
  valid_613590 = validateParameter(valid_613590, JString, required = true, default = newJString(
      "CodeCommit_20150413.EvaluatePullRequestApprovalRules"))
  if valid_613590 != nil:
    section.add "X-Amz-Target", valid_613590
  var valid_613591 = header.getOrDefault("X-Amz-Signature")
  valid_613591 = validateParameter(valid_613591, JString, required = false,
                                 default = nil)
  if valid_613591 != nil:
    section.add "X-Amz-Signature", valid_613591
  var valid_613592 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613592 = validateParameter(valid_613592, JString, required = false,
                                 default = nil)
  if valid_613592 != nil:
    section.add "X-Amz-Content-Sha256", valid_613592
  var valid_613593 = header.getOrDefault("X-Amz-Date")
  valid_613593 = validateParameter(valid_613593, JString, required = false,
                                 default = nil)
  if valid_613593 != nil:
    section.add "X-Amz-Date", valid_613593
  var valid_613594 = header.getOrDefault("X-Amz-Credential")
  valid_613594 = validateParameter(valid_613594, JString, required = false,
                                 default = nil)
  if valid_613594 != nil:
    section.add "X-Amz-Credential", valid_613594
  var valid_613595 = header.getOrDefault("X-Amz-Security-Token")
  valid_613595 = validateParameter(valid_613595, JString, required = false,
                                 default = nil)
  if valid_613595 != nil:
    section.add "X-Amz-Security-Token", valid_613595
  var valid_613596 = header.getOrDefault("X-Amz-Algorithm")
  valid_613596 = validateParameter(valid_613596, JString, required = false,
                                 default = nil)
  if valid_613596 != nil:
    section.add "X-Amz-Algorithm", valid_613596
  var valid_613597 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613597 = validateParameter(valid_613597, JString, required = false,
                                 default = nil)
  if valid_613597 != nil:
    section.add "X-Amz-SignedHeaders", valid_613597
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613599: Call_EvaluatePullRequestApprovalRules_613587;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Evaluates whether a pull request has met all the conditions specified in its associated approval rules.
  ## 
  let valid = call_613599.validator(path, query, header, formData, body)
  let scheme = call_613599.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613599.url(scheme.get, call_613599.host, call_613599.base,
                         call_613599.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613599, url, valid)

proc call*(call_613600: Call_EvaluatePullRequestApprovalRules_613587;
          body: JsonNode): Recallable =
  ## evaluatePullRequestApprovalRules
  ## Evaluates whether a pull request has met all the conditions specified in its associated approval rules.
  ##   body: JObject (required)
  var body_613601 = newJObject()
  if body != nil:
    body_613601 = body
  result = call_613600.call(nil, nil, nil, nil, body_613601)

var evaluatePullRequestApprovalRules* = Call_EvaluatePullRequestApprovalRules_613587(
    name: "evaluatePullRequestApprovalRules", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.EvaluatePullRequestApprovalRules",
    validator: validate_EvaluatePullRequestApprovalRules_613588, base: "/",
    url: url_EvaluatePullRequestApprovalRules_613589,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApprovalRuleTemplate_613602 = ref object of OpenApiRestCall_612658
proc url_GetApprovalRuleTemplate_613604(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetApprovalRuleTemplate_613603(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about a specified approval rule template.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613605 = header.getOrDefault("X-Amz-Target")
  valid_613605 = validateParameter(valid_613605, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetApprovalRuleTemplate"))
  if valid_613605 != nil:
    section.add "X-Amz-Target", valid_613605
  var valid_613606 = header.getOrDefault("X-Amz-Signature")
  valid_613606 = validateParameter(valid_613606, JString, required = false,
                                 default = nil)
  if valid_613606 != nil:
    section.add "X-Amz-Signature", valid_613606
  var valid_613607 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613607 = validateParameter(valid_613607, JString, required = false,
                                 default = nil)
  if valid_613607 != nil:
    section.add "X-Amz-Content-Sha256", valid_613607
  var valid_613608 = header.getOrDefault("X-Amz-Date")
  valid_613608 = validateParameter(valid_613608, JString, required = false,
                                 default = nil)
  if valid_613608 != nil:
    section.add "X-Amz-Date", valid_613608
  var valid_613609 = header.getOrDefault("X-Amz-Credential")
  valid_613609 = validateParameter(valid_613609, JString, required = false,
                                 default = nil)
  if valid_613609 != nil:
    section.add "X-Amz-Credential", valid_613609
  var valid_613610 = header.getOrDefault("X-Amz-Security-Token")
  valid_613610 = validateParameter(valid_613610, JString, required = false,
                                 default = nil)
  if valid_613610 != nil:
    section.add "X-Amz-Security-Token", valid_613610
  var valid_613611 = header.getOrDefault("X-Amz-Algorithm")
  valid_613611 = validateParameter(valid_613611, JString, required = false,
                                 default = nil)
  if valid_613611 != nil:
    section.add "X-Amz-Algorithm", valid_613611
  var valid_613612 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613612 = validateParameter(valid_613612, JString, required = false,
                                 default = nil)
  if valid_613612 != nil:
    section.add "X-Amz-SignedHeaders", valid_613612
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613614: Call_GetApprovalRuleTemplate_613602; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specified approval rule template.
  ## 
  let valid = call_613614.validator(path, query, header, formData, body)
  let scheme = call_613614.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613614.url(scheme.get, call_613614.host, call_613614.base,
                         call_613614.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613614, url, valid)

proc call*(call_613615: Call_GetApprovalRuleTemplate_613602; body: JsonNode): Recallable =
  ## getApprovalRuleTemplate
  ## Returns information about a specified approval rule template.
  ##   body: JObject (required)
  var body_613616 = newJObject()
  if body != nil:
    body_613616 = body
  result = call_613615.call(nil, nil, nil, nil, body_613616)

var getApprovalRuleTemplate* = Call_GetApprovalRuleTemplate_613602(
    name: "getApprovalRuleTemplate", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetApprovalRuleTemplate",
    validator: validate_GetApprovalRuleTemplate_613603, base: "/",
    url: url_GetApprovalRuleTemplate_613604, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBlob_613617 = ref object of OpenApiRestCall_612658
proc url_GetBlob_613619(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetBlob_613618(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the base-64 encoded content of an individual blob in a repository.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613620 = header.getOrDefault("X-Amz-Target")
  valid_613620 = validateParameter(valid_613620, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetBlob"))
  if valid_613620 != nil:
    section.add "X-Amz-Target", valid_613620
  var valid_613621 = header.getOrDefault("X-Amz-Signature")
  valid_613621 = validateParameter(valid_613621, JString, required = false,
                                 default = nil)
  if valid_613621 != nil:
    section.add "X-Amz-Signature", valid_613621
  var valid_613622 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613622 = validateParameter(valid_613622, JString, required = false,
                                 default = nil)
  if valid_613622 != nil:
    section.add "X-Amz-Content-Sha256", valid_613622
  var valid_613623 = header.getOrDefault("X-Amz-Date")
  valid_613623 = validateParameter(valid_613623, JString, required = false,
                                 default = nil)
  if valid_613623 != nil:
    section.add "X-Amz-Date", valid_613623
  var valid_613624 = header.getOrDefault("X-Amz-Credential")
  valid_613624 = validateParameter(valid_613624, JString, required = false,
                                 default = nil)
  if valid_613624 != nil:
    section.add "X-Amz-Credential", valid_613624
  var valid_613625 = header.getOrDefault("X-Amz-Security-Token")
  valid_613625 = validateParameter(valid_613625, JString, required = false,
                                 default = nil)
  if valid_613625 != nil:
    section.add "X-Amz-Security-Token", valid_613625
  var valid_613626 = header.getOrDefault("X-Amz-Algorithm")
  valid_613626 = validateParameter(valid_613626, JString, required = false,
                                 default = nil)
  if valid_613626 != nil:
    section.add "X-Amz-Algorithm", valid_613626
  var valid_613627 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613627 = validateParameter(valid_613627, JString, required = false,
                                 default = nil)
  if valid_613627 != nil:
    section.add "X-Amz-SignedHeaders", valid_613627
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613629: Call_GetBlob_613617; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the base-64 encoded content of an individual blob in a repository.
  ## 
  let valid = call_613629.validator(path, query, header, formData, body)
  let scheme = call_613629.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613629.url(scheme.get, call_613629.host, call_613629.base,
                         call_613629.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613629, url, valid)

proc call*(call_613630: Call_GetBlob_613617; body: JsonNode): Recallable =
  ## getBlob
  ## Returns the base-64 encoded content of an individual blob in a repository.
  ##   body: JObject (required)
  var body_613631 = newJObject()
  if body != nil:
    body_613631 = body
  result = call_613630.call(nil, nil, nil, nil, body_613631)

var getBlob* = Call_GetBlob_613617(name: "getBlob", meth: HttpMethod.HttpPost,
                                host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.GetBlob",
                                validator: validate_GetBlob_613618, base: "/",
                                url: url_GetBlob_613619,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBranch_613632 = ref object of OpenApiRestCall_612658
proc url_GetBranch_613634(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetBranch_613633(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about a repository branch, including its name and the last commit ID.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613635 = header.getOrDefault("X-Amz-Target")
  valid_613635 = validateParameter(valid_613635, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetBranch"))
  if valid_613635 != nil:
    section.add "X-Amz-Target", valid_613635
  var valid_613636 = header.getOrDefault("X-Amz-Signature")
  valid_613636 = validateParameter(valid_613636, JString, required = false,
                                 default = nil)
  if valid_613636 != nil:
    section.add "X-Amz-Signature", valid_613636
  var valid_613637 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613637 = validateParameter(valid_613637, JString, required = false,
                                 default = nil)
  if valid_613637 != nil:
    section.add "X-Amz-Content-Sha256", valid_613637
  var valid_613638 = header.getOrDefault("X-Amz-Date")
  valid_613638 = validateParameter(valid_613638, JString, required = false,
                                 default = nil)
  if valid_613638 != nil:
    section.add "X-Amz-Date", valid_613638
  var valid_613639 = header.getOrDefault("X-Amz-Credential")
  valid_613639 = validateParameter(valid_613639, JString, required = false,
                                 default = nil)
  if valid_613639 != nil:
    section.add "X-Amz-Credential", valid_613639
  var valid_613640 = header.getOrDefault("X-Amz-Security-Token")
  valid_613640 = validateParameter(valid_613640, JString, required = false,
                                 default = nil)
  if valid_613640 != nil:
    section.add "X-Amz-Security-Token", valid_613640
  var valid_613641 = header.getOrDefault("X-Amz-Algorithm")
  valid_613641 = validateParameter(valid_613641, JString, required = false,
                                 default = nil)
  if valid_613641 != nil:
    section.add "X-Amz-Algorithm", valid_613641
  var valid_613642 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613642 = validateParameter(valid_613642, JString, required = false,
                                 default = nil)
  if valid_613642 != nil:
    section.add "X-Amz-SignedHeaders", valid_613642
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613644: Call_GetBranch_613632; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a repository branch, including its name and the last commit ID.
  ## 
  let valid = call_613644.validator(path, query, header, formData, body)
  let scheme = call_613644.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613644.url(scheme.get, call_613644.host, call_613644.base,
                         call_613644.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613644, url, valid)

proc call*(call_613645: Call_GetBranch_613632; body: JsonNode): Recallable =
  ## getBranch
  ## Returns information about a repository branch, including its name and the last commit ID.
  ##   body: JObject (required)
  var body_613646 = newJObject()
  if body != nil:
    body_613646 = body
  result = call_613645.call(nil, nil, nil, nil, body_613646)

var getBranch* = Call_GetBranch_613632(name: "getBranch", meth: HttpMethod.HttpPost,
                                    host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.GetBranch",
                                    validator: validate_GetBranch_613633,
                                    base: "/", url: url_GetBranch_613634,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetComment_613647 = ref object of OpenApiRestCall_612658
proc url_GetComment_613649(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetComment_613648(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the content of a comment made on a change, file, or commit in a repository.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613650 = header.getOrDefault("X-Amz-Target")
  valid_613650 = validateParameter(valid_613650, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetComment"))
  if valid_613650 != nil:
    section.add "X-Amz-Target", valid_613650
  var valid_613651 = header.getOrDefault("X-Amz-Signature")
  valid_613651 = validateParameter(valid_613651, JString, required = false,
                                 default = nil)
  if valid_613651 != nil:
    section.add "X-Amz-Signature", valid_613651
  var valid_613652 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613652 = validateParameter(valid_613652, JString, required = false,
                                 default = nil)
  if valid_613652 != nil:
    section.add "X-Amz-Content-Sha256", valid_613652
  var valid_613653 = header.getOrDefault("X-Amz-Date")
  valid_613653 = validateParameter(valid_613653, JString, required = false,
                                 default = nil)
  if valid_613653 != nil:
    section.add "X-Amz-Date", valid_613653
  var valid_613654 = header.getOrDefault("X-Amz-Credential")
  valid_613654 = validateParameter(valid_613654, JString, required = false,
                                 default = nil)
  if valid_613654 != nil:
    section.add "X-Amz-Credential", valid_613654
  var valid_613655 = header.getOrDefault("X-Amz-Security-Token")
  valid_613655 = validateParameter(valid_613655, JString, required = false,
                                 default = nil)
  if valid_613655 != nil:
    section.add "X-Amz-Security-Token", valid_613655
  var valid_613656 = header.getOrDefault("X-Amz-Algorithm")
  valid_613656 = validateParameter(valid_613656, JString, required = false,
                                 default = nil)
  if valid_613656 != nil:
    section.add "X-Amz-Algorithm", valid_613656
  var valid_613657 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613657 = validateParameter(valid_613657, JString, required = false,
                                 default = nil)
  if valid_613657 != nil:
    section.add "X-Amz-SignedHeaders", valid_613657
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613659: Call_GetComment_613647; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the content of a comment made on a change, file, or commit in a repository.
  ## 
  let valid = call_613659.validator(path, query, header, formData, body)
  let scheme = call_613659.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613659.url(scheme.get, call_613659.host, call_613659.base,
                         call_613659.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613659, url, valid)

proc call*(call_613660: Call_GetComment_613647; body: JsonNode): Recallable =
  ## getComment
  ## Returns the content of a comment made on a change, file, or commit in a repository.
  ##   body: JObject (required)
  var body_613661 = newJObject()
  if body != nil:
    body_613661 = body
  result = call_613660.call(nil, nil, nil, nil, body_613661)

var getComment* = Call_GetComment_613647(name: "getComment",
                                      meth: HttpMethod.HttpPost,
                                      host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.GetComment",
                                      validator: validate_GetComment_613648,
                                      base: "/", url: url_GetComment_613649,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCommentsForComparedCommit_613662 = ref object of OpenApiRestCall_612658
proc url_GetCommentsForComparedCommit_613664(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCommentsForComparedCommit_613663(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about comments made on the comparison between two commits.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_613665 = query.getOrDefault("nextToken")
  valid_613665 = validateParameter(valid_613665, JString, required = false,
                                 default = nil)
  if valid_613665 != nil:
    section.add "nextToken", valid_613665
  var valid_613666 = query.getOrDefault("maxResults")
  valid_613666 = validateParameter(valid_613666, JString, required = false,
                                 default = nil)
  if valid_613666 != nil:
    section.add "maxResults", valid_613666
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613667 = header.getOrDefault("X-Amz-Target")
  valid_613667 = validateParameter(valid_613667, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetCommentsForComparedCommit"))
  if valid_613667 != nil:
    section.add "X-Amz-Target", valid_613667
  var valid_613668 = header.getOrDefault("X-Amz-Signature")
  valid_613668 = validateParameter(valid_613668, JString, required = false,
                                 default = nil)
  if valid_613668 != nil:
    section.add "X-Amz-Signature", valid_613668
  var valid_613669 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613669 = validateParameter(valid_613669, JString, required = false,
                                 default = nil)
  if valid_613669 != nil:
    section.add "X-Amz-Content-Sha256", valid_613669
  var valid_613670 = header.getOrDefault("X-Amz-Date")
  valid_613670 = validateParameter(valid_613670, JString, required = false,
                                 default = nil)
  if valid_613670 != nil:
    section.add "X-Amz-Date", valid_613670
  var valid_613671 = header.getOrDefault("X-Amz-Credential")
  valid_613671 = validateParameter(valid_613671, JString, required = false,
                                 default = nil)
  if valid_613671 != nil:
    section.add "X-Amz-Credential", valid_613671
  var valid_613672 = header.getOrDefault("X-Amz-Security-Token")
  valid_613672 = validateParameter(valid_613672, JString, required = false,
                                 default = nil)
  if valid_613672 != nil:
    section.add "X-Amz-Security-Token", valid_613672
  var valid_613673 = header.getOrDefault("X-Amz-Algorithm")
  valid_613673 = validateParameter(valid_613673, JString, required = false,
                                 default = nil)
  if valid_613673 != nil:
    section.add "X-Amz-Algorithm", valid_613673
  var valid_613674 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613674 = validateParameter(valid_613674, JString, required = false,
                                 default = nil)
  if valid_613674 != nil:
    section.add "X-Amz-SignedHeaders", valid_613674
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613676: Call_GetCommentsForComparedCommit_613662; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about comments made on the comparison between two commits.
  ## 
  let valid = call_613676.validator(path, query, header, formData, body)
  let scheme = call_613676.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613676.url(scheme.get, call_613676.host, call_613676.base,
                         call_613676.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613676, url, valid)

proc call*(call_613677: Call_GetCommentsForComparedCommit_613662; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getCommentsForComparedCommit
  ## Returns information about comments made on the comparison between two commits.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_613678 = newJObject()
  var body_613679 = newJObject()
  add(query_613678, "nextToken", newJString(nextToken))
  if body != nil:
    body_613679 = body
  add(query_613678, "maxResults", newJString(maxResults))
  result = call_613677.call(nil, query_613678, nil, nil, body_613679)

var getCommentsForComparedCommit* = Call_GetCommentsForComparedCommit_613662(
    name: "getCommentsForComparedCommit", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetCommentsForComparedCommit",
    validator: validate_GetCommentsForComparedCommit_613663, base: "/",
    url: url_GetCommentsForComparedCommit_613664,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCommentsForPullRequest_613680 = ref object of OpenApiRestCall_612658
proc url_GetCommentsForPullRequest_613682(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCommentsForPullRequest_613681(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns comments made on a pull request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_613683 = query.getOrDefault("nextToken")
  valid_613683 = validateParameter(valid_613683, JString, required = false,
                                 default = nil)
  if valid_613683 != nil:
    section.add "nextToken", valid_613683
  var valid_613684 = query.getOrDefault("maxResults")
  valid_613684 = validateParameter(valid_613684, JString, required = false,
                                 default = nil)
  if valid_613684 != nil:
    section.add "maxResults", valid_613684
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613685 = header.getOrDefault("X-Amz-Target")
  valid_613685 = validateParameter(valid_613685, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetCommentsForPullRequest"))
  if valid_613685 != nil:
    section.add "X-Amz-Target", valid_613685
  var valid_613686 = header.getOrDefault("X-Amz-Signature")
  valid_613686 = validateParameter(valid_613686, JString, required = false,
                                 default = nil)
  if valid_613686 != nil:
    section.add "X-Amz-Signature", valid_613686
  var valid_613687 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613687 = validateParameter(valid_613687, JString, required = false,
                                 default = nil)
  if valid_613687 != nil:
    section.add "X-Amz-Content-Sha256", valid_613687
  var valid_613688 = header.getOrDefault("X-Amz-Date")
  valid_613688 = validateParameter(valid_613688, JString, required = false,
                                 default = nil)
  if valid_613688 != nil:
    section.add "X-Amz-Date", valid_613688
  var valid_613689 = header.getOrDefault("X-Amz-Credential")
  valid_613689 = validateParameter(valid_613689, JString, required = false,
                                 default = nil)
  if valid_613689 != nil:
    section.add "X-Amz-Credential", valid_613689
  var valid_613690 = header.getOrDefault("X-Amz-Security-Token")
  valid_613690 = validateParameter(valid_613690, JString, required = false,
                                 default = nil)
  if valid_613690 != nil:
    section.add "X-Amz-Security-Token", valid_613690
  var valid_613691 = header.getOrDefault("X-Amz-Algorithm")
  valid_613691 = validateParameter(valid_613691, JString, required = false,
                                 default = nil)
  if valid_613691 != nil:
    section.add "X-Amz-Algorithm", valid_613691
  var valid_613692 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613692 = validateParameter(valid_613692, JString, required = false,
                                 default = nil)
  if valid_613692 != nil:
    section.add "X-Amz-SignedHeaders", valid_613692
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613694: Call_GetCommentsForPullRequest_613680; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns comments made on a pull request.
  ## 
  let valid = call_613694.validator(path, query, header, formData, body)
  let scheme = call_613694.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613694.url(scheme.get, call_613694.host, call_613694.base,
                         call_613694.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613694, url, valid)

proc call*(call_613695: Call_GetCommentsForPullRequest_613680; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getCommentsForPullRequest
  ## Returns comments made on a pull request.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_613696 = newJObject()
  var body_613697 = newJObject()
  add(query_613696, "nextToken", newJString(nextToken))
  if body != nil:
    body_613697 = body
  add(query_613696, "maxResults", newJString(maxResults))
  result = call_613695.call(nil, query_613696, nil, nil, body_613697)

var getCommentsForPullRequest* = Call_GetCommentsForPullRequest_613680(
    name: "getCommentsForPullRequest", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetCommentsForPullRequest",
    validator: validate_GetCommentsForPullRequest_613681, base: "/",
    url: url_GetCommentsForPullRequest_613682,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCommit_613698 = ref object of OpenApiRestCall_612658
proc url_GetCommit_613700(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCommit_613699(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about a commit, including commit message and committer information.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613701 = header.getOrDefault("X-Amz-Target")
  valid_613701 = validateParameter(valid_613701, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetCommit"))
  if valid_613701 != nil:
    section.add "X-Amz-Target", valid_613701
  var valid_613702 = header.getOrDefault("X-Amz-Signature")
  valid_613702 = validateParameter(valid_613702, JString, required = false,
                                 default = nil)
  if valid_613702 != nil:
    section.add "X-Amz-Signature", valid_613702
  var valid_613703 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613703 = validateParameter(valid_613703, JString, required = false,
                                 default = nil)
  if valid_613703 != nil:
    section.add "X-Amz-Content-Sha256", valid_613703
  var valid_613704 = header.getOrDefault("X-Amz-Date")
  valid_613704 = validateParameter(valid_613704, JString, required = false,
                                 default = nil)
  if valid_613704 != nil:
    section.add "X-Amz-Date", valid_613704
  var valid_613705 = header.getOrDefault("X-Amz-Credential")
  valid_613705 = validateParameter(valid_613705, JString, required = false,
                                 default = nil)
  if valid_613705 != nil:
    section.add "X-Amz-Credential", valid_613705
  var valid_613706 = header.getOrDefault("X-Amz-Security-Token")
  valid_613706 = validateParameter(valid_613706, JString, required = false,
                                 default = nil)
  if valid_613706 != nil:
    section.add "X-Amz-Security-Token", valid_613706
  var valid_613707 = header.getOrDefault("X-Amz-Algorithm")
  valid_613707 = validateParameter(valid_613707, JString, required = false,
                                 default = nil)
  if valid_613707 != nil:
    section.add "X-Amz-Algorithm", valid_613707
  var valid_613708 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613708 = validateParameter(valid_613708, JString, required = false,
                                 default = nil)
  if valid_613708 != nil:
    section.add "X-Amz-SignedHeaders", valid_613708
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613710: Call_GetCommit_613698; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a commit, including commit message and committer information.
  ## 
  let valid = call_613710.validator(path, query, header, formData, body)
  let scheme = call_613710.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613710.url(scheme.get, call_613710.host, call_613710.base,
                         call_613710.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613710, url, valid)

proc call*(call_613711: Call_GetCommit_613698; body: JsonNode): Recallable =
  ## getCommit
  ## Returns information about a commit, including commit message and committer information.
  ##   body: JObject (required)
  var body_613712 = newJObject()
  if body != nil:
    body_613712 = body
  result = call_613711.call(nil, nil, nil, nil, body_613712)

var getCommit* = Call_GetCommit_613698(name: "getCommit", meth: HttpMethod.HttpPost,
                                    host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.GetCommit",
                                    validator: validate_GetCommit_613699,
                                    base: "/", url: url_GetCommit_613700,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDifferences_613713 = ref object of OpenApiRestCall_612658
proc url_GetDifferences_613715(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDifferences_613714(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Returns information about the differences in a valid commit specifier (such as a branch, tag, HEAD, commit ID, or other fully qualified reference). Results can be limited to a specified path.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_613716 = query.getOrDefault("MaxResults")
  valid_613716 = validateParameter(valid_613716, JString, required = false,
                                 default = nil)
  if valid_613716 != nil:
    section.add "MaxResults", valid_613716
  var valid_613717 = query.getOrDefault("NextToken")
  valid_613717 = validateParameter(valid_613717, JString, required = false,
                                 default = nil)
  if valid_613717 != nil:
    section.add "NextToken", valid_613717
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613718 = header.getOrDefault("X-Amz-Target")
  valid_613718 = validateParameter(valid_613718, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetDifferences"))
  if valid_613718 != nil:
    section.add "X-Amz-Target", valid_613718
  var valid_613719 = header.getOrDefault("X-Amz-Signature")
  valid_613719 = validateParameter(valid_613719, JString, required = false,
                                 default = nil)
  if valid_613719 != nil:
    section.add "X-Amz-Signature", valid_613719
  var valid_613720 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613720 = validateParameter(valid_613720, JString, required = false,
                                 default = nil)
  if valid_613720 != nil:
    section.add "X-Amz-Content-Sha256", valid_613720
  var valid_613721 = header.getOrDefault("X-Amz-Date")
  valid_613721 = validateParameter(valid_613721, JString, required = false,
                                 default = nil)
  if valid_613721 != nil:
    section.add "X-Amz-Date", valid_613721
  var valid_613722 = header.getOrDefault("X-Amz-Credential")
  valid_613722 = validateParameter(valid_613722, JString, required = false,
                                 default = nil)
  if valid_613722 != nil:
    section.add "X-Amz-Credential", valid_613722
  var valid_613723 = header.getOrDefault("X-Amz-Security-Token")
  valid_613723 = validateParameter(valid_613723, JString, required = false,
                                 default = nil)
  if valid_613723 != nil:
    section.add "X-Amz-Security-Token", valid_613723
  var valid_613724 = header.getOrDefault("X-Amz-Algorithm")
  valid_613724 = validateParameter(valid_613724, JString, required = false,
                                 default = nil)
  if valid_613724 != nil:
    section.add "X-Amz-Algorithm", valid_613724
  var valid_613725 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613725 = validateParameter(valid_613725, JString, required = false,
                                 default = nil)
  if valid_613725 != nil:
    section.add "X-Amz-SignedHeaders", valid_613725
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613727: Call_GetDifferences_613713; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the differences in a valid commit specifier (such as a branch, tag, HEAD, commit ID, or other fully qualified reference). Results can be limited to a specified path.
  ## 
  let valid = call_613727.validator(path, query, header, formData, body)
  let scheme = call_613727.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613727.url(scheme.get, call_613727.host, call_613727.base,
                         call_613727.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613727, url, valid)

proc call*(call_613728: Call_GetDifferences_613713; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getDifferences
  ## Returns information about the differences in a valid commit specifier (such as a branch, tag, HEAD, commit ID, or other fully qualified reference). Results can be limited to a specified path.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613729 = newJObject()
  var body_613730 = newJObject()
  add(query_613729, "MaxResults", newJString(MaxResults))
  add(query_613729, "NextToken", newJString(NextToken))
  if body != nil:
    body_613730 = body
  result = call_613728.call(nil, query_613729, nil, nil, body_613730)

var getDifferences* = Call_GetDifferences_613713(name: "getDifferences",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetDifferences",
    validator: validate_GetDifferences_613714, base: "/", url: url_GetDifferences_613715,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFile_613731 = ref object of OpenApiRestCall_612658
proc url_GetFile_613733(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetFile_613732(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the base-64 encoded contents of a specified file and its metadata.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613734 = header.getOrDefault("X-Amz-Target")
  valid_613734 = validateParameter(valid_613734, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetFile"))
  if valid_613734 != nil:
    section.add "X-Amz-Target", valid_613734
  var valid_613735 = header.getOrDefault("X-Amz-Signature")
  valid_613735 = validateParameter(valid_613735, JString, required = false,
                                 default = nil)
  if valid_613735 != nil:
    section.add "X-Amz-Signature", valid_613735
  var valid_613736 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613736 = validateParameter(valid_613736, JString, required = false,
                                 default = nil)
  if valid_613736 != nil:
    section.add "X-Amz-Content-Sha256", valid_613736
  var valid_613737 = header.getOrDefault("X-Amz-Date")
  valid_613737 = validateParameter(valid_613737, JString, required = false,
                                 default = nil)
  if valid_613737 != nil:
    section.add "X-Amz-Date", valid_613737
  var valid_613738 = header.getOrDefault("X-Amz-Credential")
  valid_613738 = validateParameter(valid_613738, JString, required = false,
                                 default = nil)
  if valid_613738 != nil:
    section.add "X-Amz-Credential", valid_613738
  var valid_613739 = header.getOrDefault("X-Amz-Security-Token")
  valid_613739 = validateParameter(valid_613739, JString, required = false,
                                 default = nil)
  if valid_613739 != nil:
    section.add "X-Amz-Security-Token", valid_613739
  var valid_613740 = header.getOrDefault("X-Amz-Algorithm")
  valid_613740 = validateParameter(valid_613740, JString, required = false,
                                 default = nil)
  if valid_613740 != nil:
    section.add "X-Amz-Algorithm", valid_613740
  var valid_613741 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613741 = validateParameter(valid_613741, JString, required = false,
                                 default = nil)
  if valid_613741 != nil:
    section.add "X-Amz-SignedHeaders", valid_613741
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613743: Call_GetFile_613731; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the base-64 encoded contents of a specified file and its metadata.
  ## 
  let valid = call_613743.validator(path, query, header, formData, body)
  let scheme = call_613743.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613743.url(scheme.get, call_613743.host, call_613743.base,
                         call_613743.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613743, url, valid)

proc call*(call_613744: Call_GetFile_613731; body: JsonNode): Recallable =
  ## getFile
  ## Returns the base-64 encoded contents of a specified file and its metadata.
  ##   body: JObject (required)
  var body_613745 = newJObject()
  if body != nil:
    body_613745 = body
  result = call_613744.call(nil, nil, nil, nil, body_613745)

var getFile* = Call_GetFile_613731(name: "getFile", meth: HttpMethod.HttpPost,
                                host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.GetFile",
                                validator: validate_GetFile_613732, base: "/",
                                url: url_GetFile_613733,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFolder_613746 = ref object of OpenApiRestCall_612658
proc url_GetFolder_613748(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetFolder_613747(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the contents of a specified folder in a repository.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613749 = header.getOrDefault("X-Amz-Target")
  valid_613749 = validateParameter(valid_613749, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetFolder"))
  if valid_613749 != nil:
    section.add "X-Amz-Target", valid_613749
  var valid_613750 = header.getOrDefault("X-Amz-Signature")
  valid_613750 = validateParameter(valid_613750, JString, required = false,
                                 default = nil)
  if valid_613750 != nil:
    section.add "X-Amz-Signature", valid_613750
  var valid_613751 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613751 = validateParameter(valid_613751, JString, required = false,
                                 default = nil)
  if valid_613751 != nil:
    section.add "X-Amz-Content-Sha256", valid_613751
  var valid_613752 = header.getOrDefault("X-Amz-Date")
  valid_613752 = validateParameter(valid_613752, JString, required = false,
                                 default = nil)
  if valid_613752 != nil:
    section.add "X-Amz-Date", valid_613752
  var valid_613753 = header.getOrDefault("X-Amz-Credential")
  valid_613753 = validateParameter(valid_613753, JString, required = false,
                                 default = nil)
  if valid_613753 != nil:
    section.add "X-Amz-Credential", valid_613753
  var valid_613754 = header.getOrDefault("X-Amz-Security-Token")
  valid_613754 = validateParameter(valid_613754, JString, required = false,
                                 default = nil)
  if valid_613754 != nil:
    section.add "X-Amz-Security-Token", valid_613754
  var valid_613755 = header.getOrDefault("X-Amz-Algorithm")
  valid_613755 = validateParameter(valid_613755, JString, required = false,
                                 default = nil)
  if valid_613755 != nil:
    section.add "X-Amz-Algorithm", valid_613755
  var valid_613756 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613756 = validateParameter(valid_613756, JString, required = false,
                                 default = nil)
  if valid_613756 != nil:
    section.add "X-Amz-SignedHeaders", valid_613756
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613758: Call_GetFolder_613746; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the contents of a specified folder in a repository.
  ## 
  let valid = call_613758.validator(path, query, header, formData, body)
  let scheme = call_613758.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613758.url(scheme.get, call_613758.host, call_613758.base,
                         call_613758.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613758, url, valid)

proc call*(call_613759: Call_GetFolder_613746; body: JsonNode): Recallable =
  ## getFolder
  ## Returns the contents of a specified folder in a repository.
  ##   body: JObject (required)
  var body_613760 = newJObject()
  if body != nil:
    body_613760 = body
  result = call_613759.call(nil, nil, nil, nil, body_613760)

var getFolder* = Call_GetFolder_613746(name: "getFolder", meth: HttpMethod.HttpPost,
                                    host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.GetFolder",
                                    validator: validate_GetFolder_613747,
                                    base: "/", url: url_GetFolder_613748,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMergeCommit_613761 = ref object of OpenApiRestCall_612658
proc url_GetMergeCommit_613763(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMergeCommit_613762(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Returns information about a specified merge commit.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613764 = header.getOrDefault("X-Amz-Target")
  valid_613764 = validateParameter(valid_613764, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetMergeCommit"))
  if valid_613764 != nil:
    section.add "X-Amz-Target", valid_613764
  var valid_613765 = header.getOrDefault("X-Amz-Signature")
  valid_613765 = validateParameter(valid_613765, JString, required = false,
                                 default = nil)
  if valid_613765 != nil:
    section.add "X-Amz-Signature", valid_613765
  var valid_613766 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613766 = validateParameter(valid_613766, JString, required = false,
                                 default = nil)
  if valid_613766 != nil:
    section.add "X-Amz-Content-Sha256", valid_613766
  var valid_613767 = header.getOrDefault("X-Amz-Date")
  valid_613767 = validateParameter(valid_613767, JString, required = false,
                                 default = nil)
  if valid_613767 != nil:
    section.add "X-Amz-Date", valid_613767
  var valid_613768 = header.getOrDefault("X-Amz-Credential")
  valid_613768 = validateParameter(valid_613768, JString, required = false,
                                 default = nil)
  if valid_613768 != nil:
    section.add "X-Amz-Credential", valid_613768
  var valid_613769 = header.getOrDefault("X-Amz-Security-Token")
  valid_613769 = validateParameter(valid_613769, JString, required = false,
                                 default = nil)
  if valid_613769 != nil:
    section.add "X-Amz-Security-Token", valid_613769
  var valid_613770 = header.getOrDefault("X-Amz-Algorithm")
  valid_613770 = validateParameter(valid_613770, JString, required = false,
                                 default = nil)
  if valid_613770 != nil:
    section.add "X-Amz-Algorithm", valid_613770
  var valid_613771 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613771 = validateParameter(valid_613771, JString, required = false,
                                 default = nil)
  if valid_613771 != nil:
    section.add "X-Amz-SignedHeaders", valid_613771
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613773: Call_GetMergeCommit_613761; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specified merge commit.
  ## 
  let valid = call_613773.validator(path, query, header, formData, body)
  let scheme = call_613773.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613773.url(scheme.get, call_613773.host, call_613773.base,
                         call_613773.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613773, url, valid)

proc call*(call_613774: Call_GetMergeCommit_613761; body: JsonNode): Recallable =
  ## getMergeCommit
  ## Returns information about a specified merge commit.
  ##   body: JObject (required)
  var body_613775 = newJObject()
  if body != nil:
    body_613775 = body
  result = call_613774.call(nil, nil, nil, nil, body_613775)

var getMergeCommit* = Call_GetMergeCommit_613761(name: "getMergeCommit",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetMergeCommit",
    validator: validate_GetMergeCommit_613762, base: "/", url: url_GetMergeCommit_613763,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMergeConflicts_613776 = ref object of OpenApiRestCall_612658
proc url_GetMergeConflicts_613778(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMergeConflicts_613777(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Returns information about merge conflicts between the before and after commit IDs for a pull request in a repository.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxConflictFiles: JString
  ##                   : Pagination limit
  section = newJObject()
  var valid_613779 = query.getOrDefault("nextToken")
  valid_613779 = validateParameter(valid_613779, JString, required = false,
                                 default = nil)
  if valid_613779 != nil:
    section.add "nextToken", valid_613779
  var valid_613780 = query.getOrDefault("maxConflictFiles")
  valid_613780 = validateParameter(valid_613780, JString, required = false,
                                 default = nil)
  if valid_613780 != nil:
    section.add "maxConflictFiles", valid_613780
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613781 = header.getOrDefault("X-Amz-Target")
  valid_613781 = validateParameter(valid_613781, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetMergeConflicts"))
  if valid_613781 != nil:
    section.add "X-Amz-Target", valid_613781
  var valid_613782 = header.getOrDefault("X-Amz-Signature")
  valid_613782 = validateParameter(valid_613782, JString, required = false,
                                 default = nil)
  if valid_613782 != nil:
    section.add "X-Amz-Signature", valid_613782
  var valid_613783 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613783 = validateParameter(valid_613783, JString, required = false,
                                 default = nil)
  if valid_613783 != nil:
    section.add "X-Amz-Content-Sha256", valid_613783
  var valid_613784 = header.getOrDefault("X-Amz-Date")
  valid_613784 = validateParameter(valid_613784, JString, required = false,
                                 default = nil)
  if valid_613784 != nil:
    section.add "X-Amz-Date", valid_613784
  var valid_613785 = header.getOrDefault("X-Amz-Credential")
  valid_613785 = validateParameter(valid_613785, JString, required = false,
                                 default = nil)
  if valid_613785 != nil:
    section.add "X-Amz-Credential", valid_613785
  var valid_613786 = header.getOrDefault("X-Amz-Security-Token")
  valid_613786 = validateParameter(valid_613786, JString, required = false,
                                 default = nil)
  if valid_613786 != nil:
    section.add "X-Amz-Security-Token", valid_613786
  var valid_613787 = header.getOrDefault("X-Amz-Algorithm")
  valid_613787 = validateParameter(valid_613787, JString, required = false,
                                 default = nil)
  if valid_613787 != nil:
    section.add "X-Amz-Algorithm", valid_613787
  var valid_613788 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613788 = validateParameter(valid_613788, JString, required = false,
                                 default = nil)
  if valid_613788 != nil:
    section.add "X-Amz-SignedHeaders", valid_613788
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613790: Call_GetMergeConflicts_613776; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about merge conflicts between the before and after commit IDs for a pull request in a repository.
  ## 
  let valid = call_613790.validator(path, query, header, formData, body)
  let scheme = call_613790.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613790.url(scheme.get, call_613790.host, call_613790.base,
                         call_613790.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613790, url, valid)

proc call*(call_613791: Call_GetMergeConflicts_613776; body: JsonNode;
          nextToken: string = ""; maxConflictFiles: string = ""): Recallable =
  ## getMergeConflicts
  ## Returns information about merge conflicts between the before and after commit IDs for a pull request in a repository.
  ##   nextToken: string
  ##            : Pagination token
  ##   maxConflictFiles: string
  ##                   : Pagination limit
  ##   body: JObject (required)
  var query_613792 = newJObject()
  var body_613793 = newJObject()
  add(query_613792, "nextToken", newJString(nextToken))
  add(query_613792, "maxConflictFiles", newJString(maxConflictFiles))
  if body != nil:
    body_613793 = body
  result = call_613791.call(nil, query_613792, nil, nil, body_613793)

var getMergeConflicts* = Call_GetMergeConflicts_613776(name: "getMergeConflicts",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetMergeConflicts",
    validator: validate_GetMergeConflicts_613777, base: "/",
    url: url_GetMergeConflicts_613778, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMergeOptions_613794 = ref object of OpenApiRestCall_612658
proc url_GetMergeOptions_613796(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMergeOptions_613795(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Returns information about the merge options available for merging two specified branches. For details about why a merge option is not available, use GetMergeConflicts or DescribeMergeConflicts.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613797 = header.getOrDefault("X-Amz-Target")
  valid_613797 = validateParameter(valid_613797, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetMergeOptions"))
  if valid_613797 != nil:
    section.add "X-Amz-Target", valid_613797
  var valid_613798 = header.getOrDefault("X-Amz-Signature")
  valid_613798 = validateParameter(valid_613798, JString, required = false,
                                 default = nil)
  if valid_613798 != nil:
    section.add "X-Amz-Signature", valid_613798
  var valid_613799 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613799 = validateParameter(valid_613799, JString, required = false,
                                 default = nil)
  if valid_613799 != nil:
    section.add "X-Amz-Content-Sha256", valid_613799
  var valid_613800 = header.getOrDefault("X-Amz-Date")
  valid_613800 = validateParameter(valid_613800, JString, required = false,
                                 default = nil)
  if valid_613800 != nil:
    section.add "X-Amz-Date", valid_613800
  var valid_613801 = header.getOrDefault("X-Amz-Credential")
  valid_613801 = validateParameter(valid_613801, JString, required = false,
                                 default = nil)
  if valid_613801 != nil:
    section.add "X-Amz-Credential", valid_613801
  var valid_613802 = header.getOrDefault("X-Amz-Security-Token")
  valid_613802 = validateParameter(valid_613802, JString, required = false,
                                 default = nil)
  if valid_613802 != nil:
    section.add "X-Amz-Security-Token", valid_613802
  var valid_613803 = header.getOrDefault("X-Amz-Algorithm")
  valid_613803 = validateParameter(valid_613803, JString, required = false,
                                 default = nil)
  if valid_613803 != nil:
    section.add "X-Amz-Algorithm", valid_613803
  var valid_613804 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613804 = validateParameter(valid_613804, JString, required = false,
                                 default = nil)
  if valid_613804 != nil:
    section.add "X-Amz-SignedHeaders", valid_613804
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613806: Call_GetMergeOptions_613794; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the merge options available for merging two specified branches. For details about why a merge option is not available, use GetMergeConflicts or DescribeMergeConflicts.
  ## 
  let valid = call_613806.validator(path, query, header, formData, body)
  let scheme = call_613806.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613806.url(scheme.get, call_613806.host, call_613806.base,
                         call_613806.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613806, url, valid)

proc call*(call_613807: Call_GetMergeOptions_613794; body: JsonNode): Recallable =
  ## getMergeOptions
  ## Returns information about the merge options available for merging two specified branches. For details about why a merge option is not available, use GetMergeConflicts or DescribeMergeConflicts.
  ##   body: JObject (required)
  var body_613808 = newJObject()
  if body != nil:
    body_613808 = body
  result = call_613807.call(nil, nil, nil, nil, body_613808)

var getMergeOptions* = Call_GetMergeOptions_613794(name: "getMergeOptions",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetMergeOptions",
    validator: validate_GetMergeOptions_613795, base: "/", url: url_GetMergeOptions_613796,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPullRequest_613809 = ref object of OpenApiRestCall_612658
proc url_GetPullRequest_613811(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPullRequest_613810(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Gets information about a pull request in a specified repository.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613812 = header.getOrDefault("X-Amz-Target")
  valid_613812 = validateParameter(valid_613812, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetPullRequest"))
  if valid_613812 != nil:
    section.add "X-Amz-Target", valid_613812
  var valid_613813 = header.getOrDefault("X-Amz-Signature")
  valid_613813 = validateParameter(valid_613813, JString, required = false,
                                 default = nil)
  if valid_613813 != nil:
    section.add "X-Amz-Signature", valid_613813
  var valid_613814 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613814 = validateParameter(valid_613814, JString, required = false,
                                 default = nil)
  if valid_613814 != nil:
    section.add "X-Amz-Content-Sha256", valid_613814
  var valid_613815 = header.getOrDefault("X-Amz-Date")
  valid_613815 = validateParameter(valid_613815, JString, required = false,
                                 default = nil)
  if valid_613815 != nil:
    section.add "X-Amz-Date", valid_613815
  var valid_613816 = header.getOrDefault("X-Amz-Credential")
  valid_613816 = validateParameter(valid_613816, JString, required = false,
                                 default = nil)
  if valid_613816 != nil:
    section.add "X-Amz-Credential", valid_613816
  var valid_613817 = header.getOrDefault("X-Amz-Security-Token")
  valid_613817 = validateParameter(valid_613817, JString, required = false,
                                 default = nil)
  if valid_613817 != nil:
    section.add "X-Amz-Security-Token", valid_613817
  var valid_613818 = header.getOrDefault("X-Amz-Algorithm")
  valid_613818 = validateParameter(valid_613818, JString, required = false,
                                 default = nil)
  if valid_613818 != nil:
    section.add "X-Amz-Algorithm", valid_613818
  var valid_613819 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613819 = validateParameter(valid_613819, JString, required = false,
                                 default = nil)
  if valid_613819 != nil:
    section.add "X-Amz-SignedHeaders", valid_613819
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613821: Call_GetPullRequest_613809; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a pull request in a specified repository.
  ## 
  let valid = call_613821.validator(path, query, header, formData, body)
  let scheme = call_613821.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613821.url(scheme.get, call_613821.host, call_613821.base,
                         call_613821.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613821, url, valid)

proc call*(call_613822: Call_GetPullRequest_613809; body: JsonNode): Recallable =
  ## getPullRequest
  ## Gets information about a pull request in a specified repository.
  ##   body: JObject (required)
  var body_613823 = newJObject()
  if body != nil:
    body_613823 = body
  result = call_613822.call(nil, nil, nil, nil, body_613823)

var getPullRequest* = Call_GetPullRequest_613809(name: "getPullRequest",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetPullRequest",
    validator: validate_GetPullRequest_613810, base: "/", url: url_GetPullRequest_613811,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPullRequestApprovalStates_613824 = ref object of OpenApiRestCall_612658
proc url_GetPullRequestApprovalStates_613826(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPullRequestApprovalStates_613825(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the approval states for a specified pull request. Approval states only apply to pull requests that have one or more approval rules applied to them.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613827 = header.getOrDefault("X-Amz-Target")
  valid_613827 = validateParameter(valid_613827, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetPullRequestApprovalStates"))
  if valid_613827 != nil:
    section.add "X-Amz-Target", valid_613827
  var valid_613828 = header.getOrDefault("X-Amz-Signature")
  valid_613828 = validateParameter(valid_613828, JString, required = false,
                                 default = nil)
  if valid_613828 != nil:
    section.add "X-Amz-Signature", valid_613828
  var valid_613829 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613829 = validateParameter(valid_613829, JString, required = false,
                                 default = nil)
  if valid_613829 != nil:
    section.add "X-Amz-Content-Sha256", valid_613829
  var valid_613830 = header.getOrDefault("X-Amz-Date")
  valid_613830 = validateParameter(valid_613830, JString, required = false,
                                 default = nil)
  if valid_613830 != nil:
    section.add "X-Amz-Date", valid_613830
  var valid_613831 = header.getOrDefault("X-Amz-Credential")
  valid_613831 = validateParameter(valid_613831, JString, required = false,
                                 default = nil)
  if valid_613831 != nil:
    section.add "X-Amz-Credential", valid_613831
  var valid_613832 = header.getOrDefault("X-Amz-Security-Token")
  valid_613832 = validateParameter(valid_613832, JString, required = false,
                                 default = nil)
  if valid_613832 != nil:
    section.add "X-Amz-Security-Token", valid_613832
  var valid_613833 = header.getOrDefault("X-Amz-Algorithm")
  valid_613833 = validateParameter(valid_613833, JString, required = false,
                                 default = nil)
  if valid_613833 != nil:
    section.add "X-Amz-Algorithm", valid_613833
  var valid_613834 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613834 = validateParameter(valid_613834, JString, required = false,
                                 default = nil)
  if valid_613834 != nil:
    section.add "X-Amz-SignedHeaders", valid_613834
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613836: Call_GetPullRequestApprovalStates_613824; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the approval states for a specified pull request. Approval states only apply to pull requests that have one or more approval rules applied to them.
  ## 
  let valid = call_613836.validator(path, query, header, formData, body)
  let scheme = call_613836.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613836.url(scheme.get, call_613836.host, call_613836.base,
                         call_613836.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613836, url, valid)

proc call*(call_613837: Call_GetPullRequestApprovalStates_613824; body: JsonNode): Recallable =
  ## getPullRequestApprovalStates
  ## Gets information about the approval states for a specified pull request. Approval states only apply to pull requests that have one or more approval rules applied to them.
  ##   body: JObject (required)
  var body_613838 = newJObject()
  if body != nil:
    body_613838 = body
  result = call_613837.call(nil, nil, nil, nil, body_613838)

var getPullRequestApprovalStates* = Call_GetPullRequestApprovalStates_613824(
    name: "getPullRequestApprovalStates", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetPullRequestApprovalStates",
    validator: validate_GetPullRequestApprovalStates_613825, base: "/",
    url: url_GetPullRequestApprovalStates_613826,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPullRequestOverrideState_613839 = ref object of OpenApiRestCall_612658
proc url_GetPullRequestOverrideState_613841(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPullRequestOverrideState_613840(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about whether approval rules have been set aside (overridden) for a pull request, and if so, the Amazon Resource Name (ARN) of the user or identity that overrode the rules and their requirements for the pull request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613842 = header.getOrDefault("X-Amz-Target")
  valid_613842 = validateParameter(valid_613842, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetPullRequestOverrideState"))
  if valid_613842 != nil:
    section.add "X-Amz-Target", valid_613842
  var valid_613843 = header.getOrDefault("X-Amz-Signature")
  valid_613843 = validateParameter(valid_613843, JString, required = false,
                                 default = nil)
  if valid_613843 != nil:
    section.add "X-Amz-Signature", valid_613843
  var valid_613844 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613844 = validateParameter(valid_613844, JString, required = false,
                                 default = nil)
  if valid_613844 != nil:
    section.add "X-Amz-Content-Sha256", valid_613844
  var valid_613845 = header.getOrDefault("X-Amz-Date")
  valid_613845 = validateParameter(valid_613845, JString, required = false,
                                 default = nil)
  if valid_613845 != nil:
    section.add "X-Amz-Date", valid_613845
  var valid_613846 = header.getOrDefault("X-Amz-Credential")
  valid_613846 = validateParameter(valid_613846, JString, required = false,
                                 default = nil)
  if valid_613846 != nil:
    section.add "X-Amz-Credential", valid_613846
  var valid_613847 = header.getOrDefault("X-Amz-Security-Token")
  valid_613847 = validateParameter(valid_613847, JString, required = false,
                                 default = nil)
  if valid_613847 != nil:
    section.add "X-Amz-Security-Token", valid_613847
  var valid_613848 = header.getOrDefault("X-Amz-Algorithm")
  valid_613848 = validateParameter(valid_613848, JString, required = false,
                                 default = nil)
  if valid_613848 != nil:
    section.add "X-Amz-Algorithm", valid_613848
  var valid_613849 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613849 = validateParameter(valid_613849, JString, required = false,
                                 default = nil)
  if valid_613849 != nil:
    section.add "X-Amz-SignedHeaders", valid_613849
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613851: Call_GetPullRequestOverrideState_613839; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about whether approval rules have been set aside (overridden) for a pull request, and if so, the Amazon Resource Name (ARN) of the user or identity that overrode the rules and their requirements for the pull request.
  ## 
  let valid = call_613851.validator(path, query, header, formData, body)
  let scheme = call_613851.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613851.url(scheme.get, call_613851.host, call_613851.base,
                         call_613851.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613851, url, valid)

proc call*(call_613852: Call_GetPullRequestOverrideState_613839; body: JsonNode): Recallable =
  ## getPullRequestOverrideState
  ## Returns information about whether approval rules have been set aside (overridden) for a pull request, and if so, the Amazon Resource Name (ARN) of the user or identity that overrode the rules and their requirements for the pull request.
  ##   body: JObject (required)
  var body_613853 = newJObject()
  if body != nil:
    body_613853 = body
  result = call_613852.call(nil, nil, nil, nil, body_613853)

var getPullRequestOverrideState* = Call_GetPullRequestOverrideState_613839(
    name: "getPullRequestOverrideState", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetPullRequestOverrideState",
    validator: validate_GetPullRequestOverrideState_613840, base: "/",
    url: url_GetPullRequestOverrideState_613841,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRepository_613854 = ref object of OpenApiRestCall_612658
proc url_GetRepository_613856(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRepository_613855(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns information about a repository.</p> <note> <p>The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a webpage can expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a webpage.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613857 = header.getOrDefault("X-Amz-Target")
  valid_613857 = validateParameter(valid_613857, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetRepository"))
  if valid_613857 != nil:
    section.add "X-Amz-Target", valid_613857
  var valid_613858 = header.getOrDefault("X-Amz-Signature")
  valid_613858 = validateParameter(valid_613858, JString, required = false,
                                 default = nil)
  if valid_613858 != nil:
    section.add "X-Amz-Signature", valid_613858
  var valid_613859 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613859 = validateParameter(valid_613859, JString, required = false,
                                 default = nil)
  if valid_613859 != nil:
    section.add "X-Amz-Content-Sha256", valid_613859
  var valid_613860 = header.getOrDefault("X-Amz-Date")
  valid_613860 = validateParameter(valid_613860, JString, required = false,
                                 default = nil)
  if valid_613860 != nil:
    section.add "X-Amz-Date", valid_613860
  var valid_613861 = header.getOrDefault("X-Amz-Credential")
  valid_613861 = validateParameter(valid_613861, JString, required = false,
                                 default = nil)
  if valid_613861 != nil:
    section.add "X-Amz-Credential", valid_613861
  var valid_613862 = header.getOrDefault("X-Amz-Security-Token")
  valid_613862 = validateParameter(valid_613862, JString, required = false,
                                 default = nil)
  if valid_613862 != nil:
    section.add "X-Amz-Security-Token", valid_613862
  var valid_613863 = header.getOrDefault("X-Amz-Algorithm")
  valid_613863 = validateParameter(valid_613863, JString, required = false,
                                 default = nil)
  if valid_613863 != nil:
    section.add "X-Amz-Algorithm", valid_613863
  var valid_613864 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613864 = validateParameter(valid_613864, JString, required = false,
                                 default = nil)
  if valid_613864 != nil:
    section.add "X-Amz-SignedHeaders", valid_613864
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613866: Call_GetRepository_613854; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about a repository.</p> <note> <p>The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a webpage can expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a webpage.</p> </note>
  ## 
  let valid = call_613866.validator(path, query, header, formData, body)
  let scheme = call_613866.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613866.url(scheme.get, call_613866.host, call_613866.base,
                         call_613866.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613866, url, valid)

proc call*(call_613867: Call_GetRepository_613854; body: JsonNode): Recallable =
  ## getRepository
  ## <p>Returns information about a repository.</p> <note> <p>The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a webpage can expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a webpage.</p> </note>
  ##   body: JObject (required)
  var body_613868 = newJObject()
  if body != nil:
    body_613868 = body
  result = call_613867.call(nil, nil, nil, nil, body_613868)

var getRepository* = Call_GetRepository_613854(name: "getRepository",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetRepository",
    validator: validate_GetRepository_613855, base: "/", url: url_GetRepository_613856,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRepositoryTriggers_613869 = ref object of OpenApiRestCall_612658
proc url_GetRepositoryTriggers_613871(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRepositoryTriggers_613870(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about triggers configured for a repository.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613872 = header.getOrDefault("X-Amz-Target")
  valid_613872 = validateParameter(valid_613872, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetRepositoryTriggers"))
  if valid_613872 != nil:
    section.add "X-Amz-Target", valid_613872
  var valid_613873 = header.getOrDefault("X-Amz-Signature")
  valid_613873 = validateParameter(valid_613873, JString, required = false,
                                 default = nil)
  if valid_613873 != nil:
    section.add "X-Amz-Signature", valid_613873
  var valid_613874 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613874 = validateParameter(valid_613874, JString, required = false,
                                 default = nil)
  if valid_613874 != nil:
    section.add "X-Amz-Content-Sha256", valid_613874
  var valid_613875 = header.getOrDefault("X-Amz-Date")
  valid_613875 = validateParameter(valid_613875, JString, required = false,
                                 default = nil)
  if valid_613875 != nil:
    section.add "X-Amz-Date", valid_613875
  var valid_613876 = header.getOrDefault("X-Amz-Credential")
  valid_613876 = validateParameter(valid_613876, JString, required = false,
                                 default = nil)
  if valid_613876 != nil:
    section.add "X-Amz-Credential", valid_613876
  var valid_613877 = header.getOrDefault("X-Amz-Security-Token")
  valid_613877 = validateParameter(valid_613877, JString, required = false,
                                 default = nil)
  if valid_613877 != nil:
    section.add "X-Amz-Security-Token", valid_613877
  var valid_613878 = header.getOrDefault("X-Amz-Algorithm")
  valid_613878 = validateParameter(valid_613878, JString, required = false,
                                 default = nil)
  if valid_613878 != nil:
    section.add "X-Amz-Algorithm", valid_613878
  var valid_613879 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613879 = validateParameter(valid_613879, JString, required = false,
                                 default = nil)
  if valid_613879 != nil:
    section.add "X-Amz-SignedHeaders", valid_613879
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613881: Call_GetRepositoryTriggers_613869; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about triggers configured for a repository.
  ## 
  let valid = call_613881.validator(path, query, header, formData, body)
  let scheme = call_613881.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613881.url(scheme.get, call_613881.host, call_613881.base,
                         call_613881.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613881, url, valid)

proc call*(call_613882: Call_GetRepositoryTriggers_613869; body: JsonNode): Recallable =
  ## getRepositoryTriggers
  ## Gets information about triggers configured for a repository.
  ##   body: JObject (required)
  var body_613883 = newJObject()
  if body != nil:
    body_613883 = body
  result = call_613882.call(nil, nil, nil, nil, body_613883)

var getRepositoryTriggers* = Call_GetRepositoryTriggers_613869(
    name: "getRepositoryTriggers", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetRepositoryTriggers",
    validator: validate_GetRepositoryTriggers_613870, base: "/",
    url: url_GetRepositoryTriggers_613871, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApprovalRuleTemplates_613884 = ref object of OpenApiRestCall_612658
proc url_ListApprovalRuleTemplates_613886(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListApprovalRuleTemplates_613885(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all approval rule templates in the specified AWS Region in your AWS account. If an AWS Region is not specified, the AWS Region where you are signed in is used.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_613887 = query.getOrDefault("nextToken")
  valid_613887 = validateParameter(valid_613887, JString, required = false,
                                 default = nil)
  if valid_613887 != nil:
    section.add "nextToken", valid_613887
  var valid_613888 = query.getOrDefault("maxResults")
  valid_613888 = validateParameter(valid_613888, JString, required = false,
                                 default = nil)
  if valid_613888 != nil:
    section.add "maxResults", valid_613888
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613889 = header.getOrDefault("X-Amz-Target")
  valid_613889 = validateParameter(valid_613889, JString, required = true, default = newJString(
      "CodeCommit_20150413.ListApprovalRuleTemplates"))
  if valid_613889 != nil:
    section.add "X-Amz-Target", valid_613889
  var valid_613890 = header.getOrDefault("X-Amz-Signature")
  valid_613890 = validateParameter(valid_613890, JString, required = false,
                                 default = nil)
  if valid_613890 != nil:
    section.add "X-Amz-Signature", valid_613890
  var valid_613891 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613891 = validateParameter(valid_613891, JString, required = false,
                                 default = nil)
  if valid_613891 != nil:
    section.add "X-Amz-Content-Sha256", valid_613891
  var valid_613892 = header.getOrDefault("X-Amz-Date")
  valid_613892 = validateParameter(valid_613892, JString, required = false,
                                 default = nil)
  if valid_613892 != nil:
    section.add "X-Amz-Date", valid_613892
  var valid_613893 = header.getOrDefault("X-Amz-Credential")
  valid_613893 = validateParameter(valid_613893, JString, required = false,
                                 default = nil)
  if valid_613893 != nil:
    section.add "X-Amz-Credential", valid_613893
  var valid_613894 = header.getOrDefault("X-Amz-Security-Token")
  valid_613894 = validateParameter(valid_613894, JString, required = false,
                                 default = nil)
  if valid_613894 != nil:
    section.add "X-Amz-Security-Token", valid_613894
  var valid_613895 = header.getOrDefault("X-Amz-Algorithm")
  valid_613895 = validateParameter(valid_613895, JString, required = false,
                                 default = nil)
  if valid_613895 != nil:
    section.add "X-Amz-Algorithm", valid_613895
  var valid_613896 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613896 = validateParameter(valid_613896, JString, required = false,
                                 default = nil)
  if valid_613896 != nil:
    section.add "X-Amz-SignedHeaders", valid_613896
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613898: Call_ListApprovalRuleTemplates_613884; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all approval rule templates in the specified AWS Region in your AWS account. If an AWS Region is not specified, the AWS Region where you are signed in is used.
  ## 
  let valid = call_613898.validator(path, query, header, formData, body)
  let scheme = call_613898.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613898.url(scheme.get, call_613898.host, call_613898.base,
                         call_613898.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613898, url, valid)

proc call*(call_613899: Call_ListApprovalRuleTemplates_613884; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listApprovalRuleTemplates
  ## Lists all approval rule templates in the specified AWS Region in your AWS account. If an AWS Region is not specified, the AWS Region where you are signed in is used.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_613900 = newJObject()
  var body_613901 = newJObject()
  add(query_613900, "nextToken", newJString(nextToken))
  if body != nil:
    body_613901 = body
  add(query_613900, "maxResults", newJString(maxResults))
  result = call_613899.call(nil, query_613900, nil, nil, body_613901)

var listApprovalRuleTemplates* = Call_ListApprovalRuleTemplates_613884(
    name: "listApprovalRuleTemplates", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.ListApprovalRuleTemplates",
    validator: validate_ListApprovalRuleTemplates_613885, base: "/",
    url: url_ListApprovalRuleTemplates_613886,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssociatedApprovalRuleTemplatesForRepository_613902 = ref object of OpenApiRestCall_612658
proc url_ListAssociatedApprovalRuleTemplatesForRepository_613904(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAssociatedApprovalRuleTemplatesForRepository_613903(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode): JsonNode =
  ## Lists all approval rule templates that are associated with a specified repository.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_613905 = query.getOrDefault("nextToken")
  valid_613905 = validateParameter(valid_613905, JString, required = false,
                                 default = nil)
  if valid_613905 != nil:
    section.add "nextToken", valid_613905
  var valid_613906 = query.getOrDefault("maxResults")
  valid_613906 = validateParameter(valid_613906, JString, required = false,
                                 default = nil)
  if valid_613906 != nil:
    section.add "maxResults", valid_613906
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613907 = header.getOrDefault("X-Amz-Target")
  valid_613907 = validateParameter(valid_613907, JString, required = true, default = newJString(
      "CodeCommit_20150413.ListAssociatedApprovalRuleTemplatesForRepository"))
  if valid_613907 != nil:
    section.add "X-Amz-Target", valid_613907
  var valid_613908 = header.getOrDefault("X-Amz-Signature")
  valid_613908 = validateParameter(valid_613908, JString, required = false,
                                 default = nil)
  if valid_613908 != nil:
    section.add "X-Amz-Signature", valid_613908
  var valid_613909 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613909 = validateParameter(valid_613909, JString, required = false,
                                 default = nil)
  if valid_613909 != nil:
    section.add "X-Amz-Content-Sha256", valid_613909
  var valid_613910 = header.getOrDefault("X-Amz-Date")
  valid_613910 = validateParameter(valid_613910, JString, required = false,
                                 default = nil)
  if valid_613910 != nil:
    section.add "X-Amz-Date", valid_613910
  var valid_613911 = header.getOrDefault("X-Amz-Credential")
  valid_613911 = validateParameter(valid_613911, JString, required = false,
                                 default = nil)
  if valid_613911 != nil:
    section.add "X-Amz-Credential", valid_613911
  var valid_613912 = header.getOrDefault("X-Amz-Security-Token")
  valid_613912 = validateParameter(valid_613912, JString, required = false,
                                 default = nil)
  if valid_613912 != nil:
    section.add "X-Amz-Security-Token", valid_613912
  var valid_613913 = header.getOrDefault("X-Amz-Algorithm")
  valid_613913 = validateParameter(valid_613913, JString, required = false,
                                 default = nil)
  if valid_613913 != nil:
    section.add "X-Amz-Algorithm", valid_613913
  var valid_613914 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613914 = validateParameter(valid_613914, JString, required = false,
                                 default = nil)
  if valid_613914 != nil:
    section.add "X-Amz-SignedHeaders", valid_613914
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613916: Call_ListAssociatedApprovalRuleTemplatesForRepository_613902;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists all approval rule templates that are associated with a specified repository.
  ## 
  let valid = call_613916.validator(path, query, header, formData, body)
  let scheme = call_613916.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613916.url(scheme.get, call_613916.host, call_613916.base,
                         call_613916.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613916, url, valid)

proc call*(call_613917: Call_ListAssociatedApprovalRuleTemplatesForRepository_613902;
          body: JsonNode; nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listAssociatedApprovalRuleTemplatesForRepository
  ## Lists all approval rule templates that are associated with a specified repository.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_613918 = newJObject()
  var body_613919 = newJObject()
  add(query_613918, "nextToken", newJString(nextToken))
  if body != nil:
    body_613919 = body
  add(query_613918, "maxResults", newJString(maxResults))
  result = call_613917.call(nil, query_613918, nil, nil, body_613919)

var listAssociatedApprovalRuleTemplatesForRepository* = Call_ListAssociatedApprovalRuleTemplatesForRepository_613902(
    name: "listAssociatedApprovalRuleTemplatesForRepository",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.ListAssociatedApprovalRuleTemplatesForRepository",
    validator: validate_ListAssociatedApprovalRuleTemplatesForRepository_613903,
    base: "/", url: url_ListAssociatedApprovalRuleTemplatesForRepository_613904,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBranches_613920 = ref object of OpenApiRestCall_612658
proc url_ListBranches_613922(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListBranches_613921(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about one or more branches in a repository.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_613923 = query.getOrDefault("nextToken")
  valid_613923 = validateParameter(valid_613923, JString, required = false,
                                 default = nil)
  if valid_613923 != nil:
    section.add "nextToken", valid_613923
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613924 = header.getOrDefault("X-Amz-Target")
  valid_613924 = validateParameter(valid_613924, JString, required = true, default = newJString(
      "CodeCommit_20150413.ListBranches"))
  if valid_613924 != nil:
    section.add "X-Amz-Target", valid_613924
  var valid_613925 = header.getOrDefault("X-Amz-Signature")
  valid_613925 = validateParameter(valid_613925, JString, required = false,
                                 default = nil)
  if valid_613925 != nil:
    section.add "X-Amz-Signature", valid_613925
  var valid_613926 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613926 = validateParameter(valid_613926, JString, required = false,
                                 default = nil)
  if valid_613926 != nil:
    section.add "X-Amz-Content-Sha256", valid_613926
  var valid_613927 = header.getOrDefault("X-Amz-Date")
  valid_613927 = validateParameter(valid_613927, JString, required = false,
                                 default = nil)
  if valid_613927 != nil:
    section.add "X-Amz-Date", valid_613927
  var valid_613928 = header.getOrDefault("X-Amz-Credential")
  valid_613928 = validateParameter(valid_613928, JString, required = false,
                                 default = nil)
  if valid_613928 != nil:
    section.add "X-Amz-Credential", valid_613928
  var valid_613929 = header.getOrDefault("X-Amz-Security-Token")
  valid_613929 = validateParameter(valid_613929, JString, required = false,
                                 default = nil)
  if valid_613929 != nil:
    section.add "X-Amz-Security-Token", valid_613929
  var valid_613930 = header.getOrDefault("X-Amz-Algorithm")
  valid_613930 = validateParameter(valid_613930, JString, required = false,
                                 default = nil)
  if valid_613930 != nil:
    section.add "X-Amz-Algorithm", valid_613930
  var valid_613931 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613931 = validateParameter(valid_613931, JString, required = false,
                                 default = nil)
  if valid_613931 != nil:
    section.add "X-Amz-SignedHeaders", valid_613931
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613933: Call_ListBranches_613920; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about one or more branches in a repository.
  ## 
  let valid = call_613933.validator(path, query, header, formData, body)
  let scheme = call_613933.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613933.url(scheme.get, call_613933.host, call_613933.base,
                         call_613933.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613933, url, valid)

proc call*(call_613934: Call_ListBranches_613920; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listBranches
  ## Gets information about one or more branches in a repository.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613935 = newJObject()
  var body_613936 = newJObject()
  add(query_613935, "nextToken", newJString(nextToken))
  if body != nil:
    body_613936 = body
  result = call_613934.call(nil, query_613935, nil, nil, body_613936)

var listBranches* = Call_ListBranches_613920(name: "listBranches",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.ListBranches",
    validator: validate_ListBranches_613921, base: "/", url: url_ListBranches_613922,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPullRequests_613937 = ref object of OpenApiRestCall_612658
proc url_ListPullRequests_613939(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPullRequests_613938(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Returns a list of pull requests for a specified repository. The return list can be refined by pull request status or pull request author ARN.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_613940 = query.getOrDefault("nextToken")
  valid_613940 = validateParameter(valid_613940, JString, required = false,
                                 default = nil)
  if valid_613940 != nil:
    section.add "nextToken", valid_613940
  var valid_613941 = query.getOrDefault("maxResults")
  valid_613941 = validateParameter(valid_613941, JString, required = false,
                                 default = nil)
  if valid_613941 != nil:
    section.add "maxResults", valid_613941
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613942 = header.getOrDefault("X-Amz-Target")
  valid_613942 = validateParameter(valid_613942, JString, required = true, default = newJString(
      "CodeCommit_20150413.ListPullRequests"))
  if valid_613942 != nil:
    section.add "X-Amz-Target", valid_613942
  var valid_613943 = header.getOrDefault("X-Amz-Signature")
  valid_613943 = validateParameter(valid_613943, JString, required = false,
                                 default = nil)
  if valid_613943 != nil:
    section.add "X-Amz-Signature", valid_613943
  var valid_613944 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613944 = validateParameter(valid_613944, JString, required = false,
                                 default = nil)
  if valid_613944 != nil:
    section.add "X-Amz-Content-Sha256", valid_613944
  var valid_613945 = header.getOrDefault("X-Amz-Date")
  valid_613945 = validateParameter(valid_613945, JString, required = false,
                                 default = nil)
  if valid_613945 != nil:
    section.add "X-Amz-Date", valid_613945
  var valid_613946 = header.getOrDefault("X-Amz-Credential")
  valid_613946 = validateParameter(valid_613946, JString, required = false,
                                 default = nil)
  if valid_613946 != nil:
    section.add "X-Amz-Credential", valid_613946
  var valid_613947 = header.getOrDefault("X-Amz-Security-Token")
  valid_613947 = validateParameter(valid_613947, JString, required = false,
                                 default = nil)
  if valid_613947 != nil:
    section.add "X-Amz-Security-Token", valid_613947
  var valid_613948 = header.getOrDefault("X-Amz-Algorithm")
  valid_613948 = validateParameter(valid_613948, JString, required = false,
                                 default = nil)
  if valid_613948 != nil:
    section.add "X-Amz-Algorithm", valid_613948
  var valid_613949 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613949 = validateParameter(valid_613949, JString, required = false,
                                 default = nil)
  if valid_613949 != nil:
    section.add "X-Amz-SignedHeaders", valid_613949
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613951: Call_ListPullRequests_613937; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of pull requests for a specified repository. The return list can be refined by pull request status or pull request author ARN.
  ## 
  let valid = call_613951.validator(path, query, header, formData, body)
  let scheme = call_613951.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613951.url(scheme.get, call_613951.host, call_613951.base,
                         call_613951.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613951, url, valid)

proc call*(call_613952: Call_ListPullRequests_613937; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listPullRequests
  ## Returns a list of pull requests for a specified repository. The return list can be refined by pull request status or pull request author ARN.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_613953 = newJObject()
  var body_613954 = newJObject()
  add(query_613953, "nextToken", newJString(nextToken))
  if body != nil:
    body_613954 = body
  add(query_613953, "maxResults", newJString(maxResults))
  result = call_613952.call(nil, query_613953, nil, nil, body_613954)

var listPullRequests* = Call_ListPullRequests_613937(name: "listPullRequests",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.ListPullRequests",
    validator: validate_ListPullRequests_613938, base: "/",
    url: url_ListPullRequests_613939, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRepositories_613955 = ref object of OpenApiRestCall_612658
proc url_ListRepositories_613957(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListRepositories_613956(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Gets information about one or more repositories.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_613958 = query.getOrDefault("nextToken")
  valid_613958 = validateParameter(valid_613958, JString, required = false,
                                 default = nil)
  if valid_613958 != nil:
    section.add "nextToken", valid_613958
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613959 = header.getOrDefault("X-Amz-Target")
  valid_613959 = validateParameter(valid_613959, JString, required = true, default = newJString(
      "CodeCommit_20150413.ListRepositories"))
  if valid_613959 != nil:
    section.add "X-Amz-Target", valid_613959
  var valid_613960 = header.getOrDefault("X-Amz-Signature")
  valid_613960 = validateParameter(valid_613960, JString, required = false,
                                 default = nil)
  if valid_613960 != nil:
    section.add "X-Amz-Signature", valid_613960
  var valid_613961 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613961 = validateParameter(valid_613961, JString, required = false,
                                 default = nil)
  if valid_613961 != nil:
    section.add "X-Amz-Content-Sha256", valid_613961
  var valid_613962 = header.getOrDefault("X-Amz-Date")
  valid_613962 = validateParameter(valid_613962, JString, required = false,
                                 default = nil)
  if valid_613962 != nil:
    section.add "X-Amz-Date", valid_613962
  var valid_613963 = header.getOrDefault("X-Amz-Credential")
  valid_613963 = validateParameter(valid_613963, JString, required = false,
                                 default = nil)
  if valid_613963 != nil:
    section.add "X-Amz-Credential", valid_613963
  var valid_613964 = header.getOrDefault("X-Amz-Security-Token")
  valid_613964 = validateParameter(valid_613964, JString, required = false,
                                 default = nil)
  if valid_613964 != nil:
    section.add "X-Amz-Security-Token", valid_613964
  var valid_613965 = header.getOrDefault("X-Amz-Algorithm")
  valid_613965 = validateParameter(valid_613965, JString, required = false,
                                 default = nil)
  if valid_613965 != nil:
    section.add "X-Amz-Algorithm", valid_613965
  var valid_613966 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613966 = validateParameter(valid_613966, JString, required = false,
                                 default = nil)
  if valid_613966 != nil:
    section.add "X-Amz-SignedHeaders", valid_613966
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613968: Call_ListRepositories_613955; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about one or more repositories.
  ## 
  let valid = call_613968.validator(path, query, header, formData, body)
  let scheme = call_613968.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613968.url(scheme.get, call_613968.host, call_613968.base,
                         call_613968.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613968, url, valid)

proc call*(call_613969: Call_ListRepositories_613955; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listRepositories
  ## Gets information about one or more repositories.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613970 = newJObject()
  var body_613971 = newJObject()
  add(query_613970, "nextToken", newJString(nextToken))
  if body != nil:
    body_613971 = body
  result = call_613969.call(nil, query_613970, nil, nil, body_613971)

var listRepositories* = Call_ListRepositories_613955(name: "listRepositories",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.ListRepositories",
    validator: validate_ListRepositories_613956, base: "/",
    url: url_ListRepositories_613957, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRepositoriesForApprovalRuleTemplate_613972 = ref object of OpenApiRestCall_612658
proc url_ListRepositoriesForApprovalRuleTemplate_613974(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListRepositoriesForApprovalRuleTemplate_613973(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all repositories associated with the specified approval rule template.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_613975 = query.getOrDefault("nextToken")
  valid_613975 = validateParameter(valid_613975, JString, required = false,
                                 default = nil)
  if valid_613975 != nil:
    section.add "nextToken", valid_613975
  var valid_613976 = query.getOrDefault("maxResults")
  valid_613976 = validateParameter(valid_613976, JString, required = false,
                                 default = nil)
  if valid_613976 != nil:
    section.add "maxResults", valid_613976
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613977 = header.getOrDefault("X-Amz-Target")
  valid_613977 = validateParameter(valid_613977, JString, required = true, default = newJString(
      "CodeCommit_20150413.ListRepositoriesForApprovalRuleTemplate"))
  if valid_613977 != nil:
    section.add "X-Amz-Target", valid_613977
  var valid_613978 = header.getOrDefault("X-Amz-Signature")
  valid_613978 = validateParameter(valid_613978, JString, required = false,
                                 default = nil)
  if valid_613978 != nil:
    section.add "X-Amz-Signature", valid_613978
  var valid_613979 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613979 = validateParameter(valid_613979, JString, required = false,
                                 default = nil)
  if valid_613979 != nil:
    section.add "X-Amz-Content-Sha256", valid_613979
  var valid_613980 = header.getOrDefault("X-Amz-Date")
  valid_613980 = validateParameter(valid_613980, JString, required = false,
                                 default = nil)
  if valid_613980 != nil:
    section.add "X-Amz-Date", valid_613980
  var valid_613981 = header.getOrDefault("X-Amz-Credential")
  valid_613981 = validateParameter(valid_613981, JString, required = false,
                                 default = nil)
  if valid_613981 != nil:
    section.add "X-Amz-Credential", valid_613981
  var valid_613982 = header.getOrDefault("X-Amz-Security-Token")
  valid_613982 = validateParameter(valid_613982, JString, required = false,
                                 default = nil)
  if valid_613982 != nil:
    section.add "X-Amz-Security-Token", valid_613982
  var valid_613983 = header.getOrDefault("X-Amz-Algorithm")
  valid_613983 = validateParameter(valid_613983, JString, required = false,
                                 default = nil)
  if valid_613983 != nil:
    section.add "X-Amz-Algorithm", valid_613983
  var valid_613984 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613984 = validateParameter(valid_613984, JString, required = false,
                                 default = nil)
  if valid_613984 != nil:
    section.add "X-Amz-SignedHeaders", valid_613984
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613986: Call_ListRepositoriesForApprovalRuleTemplate_613972;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists all repositories associated with the specified approval rule template.
  ## 
  let valid = call_613986.validator(path, query, header, formData, body)
  let scheme = call_613986.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613986.url(scheme.get, call_613986.host, call_613986.base,
                         call_613986.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613986, url, valid)

proc call*(call_613987: Call_ListRepositoriesForApprovalRuleTemplate_613972;
          body: JsonNode; nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listRepositoriesForApprovalRuleTemplate
  ## Lists all repositories associated with the specified approval rule template.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_613988 = newJObject()
  var body_613989 = newJObject()
  add(query_613988, "nextToken", newJString(nextToken))
  if body != nil:
    body_613989 = body
  add(query_613988, "maxResults", newJString(maxResults))
  result = call_613987.call(nil, query_613988, nil, nil, body_613989)

var listRepositoriesForApprovalRuleTemplate* = Call_ListRepositoriesForApprovalRuleTemplate_613972(
    name: "listRepositoriesForApprovalRuleTemplate", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.ListRepositoriesForApprovalRuleTemplate",
    validator: validate_ListRepositoriesForApprovalRuleTemplate_613973, base: "/",
    url: url_ListRepositoriesForApprovalRuleTemplate_613974,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_613990 = ref object of OpenApiRestCall_612658
proc url_ListTagsForResource_613992(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_613991(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Gets information about AWS tags for a specified Amazon Resource Name (ARN) in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats">CodeCommit Resources and Operations</a> in the<i> AWS CodeCommit User Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613993 = header.getOrDefault("X-Amz-Target")
  valid_613993 = validateParameter(valid_613993, JString, required = true, default = newJString(
      "CodeCommit_20150413.ListTagsForResource"))
  if valid_613993 != nil:
    section.add "X-Amz-Target", valid_613993
  var valid_613994 = header.getOrDefault("X-Amz-Signature")
  valid_613994 = validateParameter(valid_613994, JString, required = false,
                                 default = nil)
  if valid_613994 != nil:
    section.add "X-Amz-Signature", valid_613994
  var valid_613995 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613995 = validateParameter(valid_613995, JString, required = false,
                                 default = nil)
  if valid_613995 != nil:
    section.add "X-Amz-Content-Sha256", valid_613995
  var valid_613996 = header.getOrDefault("X-Amz-Date")
  valid_613996 = validateParameter(valid_613996, JString, required = false,
                                 default = nil)
  if valid_613996 != nil:
    section.add "X-Amz-Date", valid_613996
  var valid_613997 = header.getOrDefault("X-Amz-Credential")
  valid_613997 = validateParameter(valid_613997, JString, required = false,
                                 default = nil)
  if valid_613997 != nil:
    section.add "X-Amz-Credential", valid_613997
  var valid_613998 = header.getOrDefault("X-Amz-Security-Token")
  valid_613998 = validateParameter(valid_613998, JString, required = false,
                                 default = nil)
  if valid_613998 != nil:
    section.add "X-Amz-Security-Token", valid_613998
  var valid_613999 = header.getOrDefault("X-Amz-Algorithm")
  valid_613999 = validateParameter(valid_613999, JString, required = false,
                                 default = nil)
  if valid_613999 != nil:
    section.add "X-Amz-Algorithm", valid_613999
  var valid_614000 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614000 = validateParameter(valid_614000, JString, required = false,
                                 default = nil)
  if valid_614000 != nil:
    section.add "X-Amz-SignedHeaders", valid_614000
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614002: Call_ListTagsForResource_613990; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about AWS tags for a specified Amazon Resource Name (ARN) in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats">CodeCommit Resources and Operations</a> in the<i> AWS CodeCommit User Guide</i>.
  ## 
  let valid = call_614002.validator(path, query, header, formData, body)
  let scheme = call_614002.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614002.url(scheme.get, call_614002.host, call_614002.base,
                         call_614002.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614002, url, valid)

proc call*(call_614003: Call_ListTagsForResource_613990; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Gets information about AWS tags for a specified Amazon Resource Name (ARN) in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats">CodeCommit Resources and Operations</a> in the<i> AWS CodeCommit User Guide</i>.
  ##   body: JObject (required)
  var body_614004 = newJObject()
  if body != nil:
    body_614004 = body
  result = call_614003.call(nil, nil, nil, nil, body_614004)

var listTagsForResource* = Call_ListTagsForResource_613990(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.ListTagsForResource",
    validator: validate_ListTagsForResource_613991, base: "/",
    url: url_ListTagsForResource_613992, schemes: {Scheme.Https, Scheme.Http})
type
  Call_MergeBranchesByFastForward_614005 = ref object of OpenApiRestCall_612658
proc url_MergeBranchesByFastForward_614007(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_MergeBranchesByFastForward_614006(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Merges two branches using the fast-forward merge strategy.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614008 = header.getOrDefault("X-Amz-Target")
  valid_614008 = validateParameter(valid_614008, JString, required = true, default = newJString(
      "CodeCommit_20150413.MergeBranchesByFastForward"))
  if valid_614008 != nil:
    section.add "X-Amz-Target", valid_614008
  var valid_614009 = header.getOrDefault("X-Amz-Signature")
  valid_614009 = validateParameter(valid_614009, JString, required = false,
                                 default = nil)
  if valid_614009 != nil:
    section.add "X-Amz-Signature", valid_614009
  var valid_614010 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614010 = validateParameter(valid_614010, JString, required = false,
                                 default = nil)
  if valid_614010 != nil:
    section.add "X-Amz-Content-Sha256", valid_614010
  var valid_614011 = header.getOrDefault("X-Amz-Date")
  valid_614011 = validateParameter(valid_614011, JString, required = false,
                                 default = nil)
  if valid_614011 != nil:
    section.add "X-Amz-Date", valid_614011
  var valid_614012 = header.getOrDefault("X-Amz-Credential")
  valid_614012 = validateParameter(valid_614012, JString, required = false,
                                 default = nil)
  if valid_614012 != nil:
    section.add "X-Amz-Credential", valid_614012
  var valid_614013 = header.getOrDefault("X-Amz-Security-Token")
  valid_614013 = validateParameter(valid_614013, JString, required = false,
                                 default = nil)
  if valid_614013 != nil:
    section.add "X-Amz-Security-Token", valid_614013
  var valid_614014 = header.getOrDefault("X-Amz-Algorithm")
  valid_614014 = validateParameter(valid_614014, JString, required = false,
                                 default = nil)
  if valid_614014 != nil:
    section.add "X-Amz-Algorithm", valid_614014
  var valid_614015 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614015 = validateParameter(valid_614015, JString, required = false,
                                 default = nil)
  if valid_614015 != nil:
    section.add "X-Amz-SignedHeaders", valid_614015
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614017: Call_MergeBranchesByFastForward_614005; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Merges two branches using the fast-forward merge strategy.
  ## 
  let valid = call_614017.validator(path, query, header, formData, body)
  let scheme = call_614017.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614017.url(scheme.get, call_614017.host, call_614017.base,
                         call_614017.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614017, url, valid)

proc call*(call_614018: Call_MergeBranchesByFastForward_614005; body: JsonNode): Recallable =
  ## mergeBranchesByFastForward
  ## Merges two branches using the fast-forward merge strategy.
  ##   body: JObject (required)
  var body_614019 = newJObject()
  if body != nil:
    body_614019 = body
  result = call_614018.call(nil, nil, nil, nil, body_614019)

var mergeBranchesByFastForward* = Call_MergeBranchesByFastForward_614005(
    name: "mergeBranchesByFastForward", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.MergeBranchesByFastForward",
    validator: validate_MergeBranchesByFastForward_614006, base: "/",
    url: url_MergeBranchesByFastForward_614007,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_MergeBranchesBySquash_614020 = ref object of OpenApiRestCall_612658
proc url_MergeBranchesBySquash_614022(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_MergeBranchesBySquash_614021(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Merges two branches using the squash merge strategy.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614023 = header.getOrDefault("X-Amz-Target")
  valid_614023 = validateParameter(valid_614023, JString, required = true, default = newJString(
      "CodeCommit_20150413.MergeBranchesBySquash"))
  if valid_614023 != nil:
    section.add "X-Amz-Target", valid_614023
  var valid_614024 = header.getOrDefault("X-Amz-Signature")
  valid_614024 = validateParameter(valid_614024, JString, required = false,
                                 default = nil)
  if valid_614024 != nil:
    section.add "X-Amz-Signature", valid_614024
  var valid_614025 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614025 = validateParameter(valid_614025, JString, required = false,
                                 default = nil)
  if valid_614025 != nil:
    section.add "X-Amz-Content-Sha256", valid_614025
  var valid_614026 = header.getOrDefault("X-Amz-Date")
  valid_614026 = validateParameter(valid_614026, JString, required = false,
                                 default = nil)
  if valid_614026 != nil:
    section.add "X-Amz-Date", valid_614026
  var valid_614027 = header.getOrDefault("X-Amz-Credential")
  valid_614027 = validateParameter(valid_614027, JString, required = false,
                                 default = nil)
  if valid_614027 != nil:
    section.add "X-Amz-Credential", valid_614027
  var valid_614028 = header.getOrDefault("X-Amz-Security-Token")
  valid_614028 = validateParameter(valid_614028, JString, required = false,
                                 default = nil)
  if valid_614028 != nil:
    section.add "X-Amz-Security-Token", valid_614028
  var valid_614029 = header.getOrDefault("X-Amz-Algorithm")
  valid_614029 = validateParameter(valid_614029, JString, required = false,
                                 default = nil)
  if valid_614029 != nil:
    section.add "X-Amz-Algorithm", valid_614029
  var valid_614030 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614030 = validateParameter(valid_614030, JString, required = false,
                                 default = nil)
  if valid_614030 != nil:
    section.add "X-Amz-SignedHeaders", valid_614030
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614032: Call_MergeBranchesBySquash_614020; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Merges two branches using the squash merge strategy.
  ## 
  let valid = call_614032.validator(path, query, header, formData, body)
  let scheme = call_614032.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614032.url(scheme.get, call_614032.host, call_614032.base,
                         call_614032.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614032, url, valid)

proc call*(call_614033: Call_MergeBranchesBySquash_614020; body: JsonNode): Recallable =
  ## mergeBranchesBySquash
  ## Merges two branches using the squash merge strategy.
  ##   body: JObject (required)
  var body_614034 = newJObject()
  if body != nil:
    body_614034 = body
  result = call_614033.call(nil, nil, nil, nil, body_614034)

var mergeBranchesBySquash* = Call_MergeBranchesBySquash_614020(
    name: "mergeBranchesBySquash", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.MergeBranchesBySquash",
    validator: validate_MergeBranchesBySquash_614021, base: "/",
    url: url_MergeBranchesBySquash_614022, schemes: {Scheme.Https, Scheme.Http})
type
  Call_MergeBranchesByThreeWay_614035 = ref object of OpenApiRestCall_612658
proc url_MergeBranchesByThreeWay_614037(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_MergeBranchesByThreeWay_614036(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Merges two specified branches using the three-way merge strategy.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614038 = header.getOrDefault("X-Amz-Target")
  valid_614038 = validateParameter(valid_614038, JString, required = true, default = newJString(
      "CodeCommit_20150413.MergeBranchesByThreeWay"))
  if valid_614038 != nil:
    section.add "X-Amz-Target", valid_614038
  var valid_614039 = header.getOrDefault("X-Amz-Signature")
  valid_614039 = validateParameter(valid_614039, JString, required = false,
                                 default = nil)
  if valid_614039 != nil:
    section.add "X-Amz-Signature", valid_614039
  var valid_614040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614040 = validateParameter(valid_614040, JString, required = false,
                                 default = nil)
  if valid_614040 != nil:
    section.add "X-Amz-Content-Sha256", valid_614040
  var valid_614041 = header.getOrDefault("X-Amz-Date")
  valid_614041 = validateParameter(valid_614041, JString, required = false,
                                 default = nil)
  if valid_614041 != nil:
    section.add "X-Amz-Date", valid_614041
  var valid_614042 = header.getOrDefault("X-Amz-Credential")
  valid_614042 = validateParameter(valid_614042, JString, required = false,
                                 default = nil)
  if valid_614042 != nil:
    section.add "X-Amz-Credential", valid_614042
  var valid_614043 = header.getOrDefault("X-Amz-Security-Token")
  valid_614043 = validateParameter(valid_614043, JString, required = false,
                                 default = nil)
  if valid_614043 != nil:
    section.add "X-Amz-Security-Token", valid_614043
  var valid_614044 = header.getOrDefault("X-Amz-Algorithm")
  valid_614044 = validateParameter(valid_614044, JString, required = false,
                                 default = nil)
  if valid_614044 != nil:
    section.add "X-Amz-Algorithm", valid_614044
  var valid_614045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614045 = validateParameter(valid_614045, JString, required = false,
                                 default = nil)
  if valid_614045 != nil:
    section.add "X-Amz-SignedHeaders", valid_614045
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614047: Call_MergeBranchesByThreeWay_614035; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Merges two specified branches using the three-way merge strategy.
  ## 
  let valid = call_614047.validator(path, query, header, formData, body)
  let scheme = call_614047.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614047.url(scheme.get, call_614047.host, call_614047.base,
                         call_614047.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614047, url, valid)

proc call*(call_614048: Call_MergeBranchesByThreeWay_614035; body: JsonNode): Recallable =
  ## mergeBranchesByThreeWay
  ## Merges two specified branches using the three-way merge strategy.
  ##   body: JObject (required)
  var body_614049 = newJObject()
  if body != nil:
    body_614049 = body
  result = call_614048.call(nil, nil, nil, nil, body_614049)

var mergeBranchesByThreeWay* = Call_MergeBranchesByThreeWay_614035(
    name: "mergeBranchesByThreeWay", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.MergeBranchesByThreeWay",
    validator: validate_MergeBranchesByThreeWay_614036, base: "/",
    url: url_MergeBranchesByThreeWay_614037, schemes: {Scheme.Https, Scheme.Http})
type
  Call_MergePullRequestByFastForward_614050 = ref object of OpenApiRestCall_612658
proc url_MergePullRequestByFastForward_614052(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_MergePullRequestByFastForward_614051(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Attempts to merge the source commit of a pull request into the specified destination branch for that pull request at the specified commit using the fast-forward merge strategy. If the merge is successful, it closes the pull request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614053 = header.getOrDefault("X-Amz-Target")
  valid_614053 = validateParameter(valid_614053, JString, required = true, default = newJString(
      "CodeCommit_20150413.MergePullRequestByFastForward"))
  if valid_614053 != nil:
    section.add "X-Amz-Target", valid_614053
  var valid_614054 = header.getOrDefault("X-Amz-Signature")
  valid_614054 = validateParameter(valid_614054, JString, required = false,
                                 default = nil)
  if valid_614054 != nil:
    section.add "X-Amz-Signature", valid_614054
  var valid_614055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614055 = validateParameter(valid_614055, JString, required = false,
                                 default = nil)
  if valid_614055 != nil:
    section.add "X-Amz-Content-Sha256", valid_614055
  var valid_614056 = header.getOrDefault("X-Amz-Date")
  valid_614056 = validateParameter(valid_614056, JString, required = false,
                                 default = nil)
  if valid_614056 != nil:
    section.add "X-Amz-Date", valid_614056
  var valid_614057 = header.getOrDefault("X-Amz-Credential")
  valid_614057 = validateParameter(valid_614057, JString, required = false,
                                 default = nil)
  if valid_614057 != nil:
    section.add "X-Amz-Credential", valid_614057
  var valid_614058 = header.getOrDefault("X-Amz-Security-Token")
  valid_614058 = validateParameter(valid_614058, JString, required = false,
                                 default = nil)
  if valid_614058 != nil:
    section.add "X-Amz-Security-Token", valid_614058
  var valid_614059 = header.getOrDefault("X-Amz-Algorithm")
  valid_614059 = validateParameter(valid_614059, JString, required = false,
                                 default = nil)
  if valid_614059 != nil:
    section.add "X-Amz-Algorithm", valid_614059
  var valid_614060 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614060 = validateParameter(valid_614060, JString, required = false,
                                 default = nil)
  if valid_614060 != nil:
    section.add "X-Amz-SignedHeaders", valid_614060
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614062: Call_MergePullRequestByFastForward_614050; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attempts to merge the source commit of a pull request into the specified destination branch for that pull request at the specified commit using the fast-forward merge strategy. If the merge is successful, it closes the pull request.
  ## 
  let valid = call_614062.validator(path, query, header, formData, body)
  let scheme = call_614062.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614062.url(scheme.get, call_614062.host, call_614062.base,
                         call_614062.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614062, url, valid)

proc call*(call_614063: Call_MergePullRequestByFastForward_614050; body: JsonNode): Recallable =
  ## mergePullRequestByFastForward
  ## Attempts to merge the source commit of a pull request into the specified destination branch for that pull request at the specified commit using the fast-forward merge strategy. If the merge is successful, it closes the pull request.
  ##   body: JObject (required)
  var body_614064 = newJObject()
  if body != nil:
    body_614064 = body
  result = call_614063.call(nil, nil, nil, nil, body_614064)

var mergePullRequestByFastForward* = Call_MergePullRequestByFastForward_614050(
    name: "mergePullRequestByFastForward", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.MergePullRequestByFastForward",
    validator: validate_MergePullRequestByFastForward_614051, base: "/",
    url: url_MergePullRequestByFastForward_614052,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_MergePullRequestBySquash_614065 = ref object of OpenApiRestCall_612658
proc url_MergePullRequestBySquash_614067(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_MergePullRequestBySquash_614066(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Attempts to merge the source commit of a pull request into the specified destination branch for that pull request at the specified commit using the squash merge strategy. If the merge is successful, it closes the pull request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614068 = header.getOrDefault("X-Amz-Target")
  valid_614068 = validateParameter(valid_614068, JString, required = true, default = newJString(
      "CodeCommit_20150413.MergePullRequestBySquash"))
  if valid_614068 != nil:
    section.add "X-Amz-Target", valid_614068
  var valid_614069 = header.getOrDefault("X-Amz-Signature")
  valid_614069 = validateParameter(valid_614069, JString, required = false,
                                 default = nil)
  if valid_614069 != nil:
    section.add "X-Amz-Signature", valid_614069
  var valid_614070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614070 = validateParameter(valid_614070, JString, required = false,
                                 default = nil)
  if valid_614070 != nil:
    section.add "X-Amz-Content-Sha256", valid_614070
  var valid_614071 = header.getOrDefault("X-Amz-Date")
  valid_614071 = validateParameter(valid_614071, JString, required = false,
                                 default = nil)
  if valid_614071 != nil:
    section.add "X-Amz-Date", valid_614071
  var valid_614072 = header.getOrDefault("X-Amz-Credential")
  valid_614072 = validateParameter(valid_614072, JString, required = false,
                                 default = nil)
  if valid_614072 != nil:
    section.add "X-Amz-Credential", valid_614072
  var valid_614073 = header.getOrDefault("X-Amz-Security-Token")
  valid_614073 = validateParameter(valid_614073, JString, required = false,
                                 default = nil)
  if valid_614073 != nil:
    section.add "X-Amz-Security-Token", valid_614073
  var valid_614074 = header.getOrDefault("X-Amz-Algorithm")
  valid_614074 = validateParameter(valid_614074, JString, required = false,
                                 default = nil)
  if valid_614074 != nil:
    section.add "X-Amz-Algorithm", valid_614074
  var valid_614075 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614075 = validateParameter(valid_614075, JString, required = false,
                                 default = nil)
  if valid_614075 != nil:
    section.add "X-Amz-SignedHeaders", valid_614075
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614077: Call_MergePullRequestBySquash_614065; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attempts to merge the source commit of a pull request into the specified destination branch for that pull request at the specified commit using the squash merge strategy. If the merge is successful, it closes the pull request.
  ## 
  let valid = call_614077.validator(path, query, header, formData, body)
  let scheme = call_614077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614077.url(scheme.get, call_614077.host, call_614077.base,
                         call_614077.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614077, url, valid)

proc call*(call_614078: Call_MergePullRequestBySquash_614065; body: JsonNode): Recallable =
  ## mergePullRequestBySquash
  ## Attempts to merge the source commit of a pull request into the specified destination branch for that pull request at the specified commit using the squash merge strategy. If the merge is successful, it closes the pull request.
  ##   body: JObject (required)
  var body_614079 = newJObject()
  if body != nil:
    body_614079 = body
  result = call_614078.call(nil, nil, nil, nil, body_614079)

var mergePullRequestBySquash* = Call_MergePullRequestBySquash_614065(
    name: "mergePullRequestBySquash", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.MergePullRequestBySquash",
    validator: validate_MergePullRequestBySquash_614066, base: "/",
    url: url_MergePullRequestBySquash_614067, schemes: {Scheme.Https, Scheme.Http})
type
  Call_MergePullRequestByThreeWay_614080 = ref object of OpenApiRestCall_612658
proc url_MergePullRequestByThreeWay_614082(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_MergePullRequestByThreeWay_614081(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Attempts to merge the source commit of a pull request into the specified destination branch for that pull request at the specified commit using the three-way merge strategy. If the merge is successful, it closes the pull request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614083 = header.getOrDefault("X-Amz-Target")
  valid_614083 = validateParameter(valid_614083, JString, required = true, default = newJString(
      "CodeCommit_20150413.MergePullRequestByThreeWay"))
  if valid_614083 != nil:
    section.add "X-Amz-Target", valid_614083
  var valid_614084 = header.getOrDefault("X-Amz-Signature")
  valid_614084 = validateParameter(valid_614084, JString, required = false,
                                 default = nil)
  if valid_614084 != nil:
    section.add "X-Amz-Signature", valid_614084
  var valid_614085 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614085 = validateParameter(valid_614085, JString, required = false,
                                 default = nil)
  if valid_614085 != nil:
    section.add "X-Amz-Content-Sha256", valid_614085
  var valid_614086 = header.getOrDefault("X-Amz-Date")
  valid_614086 = validateParameter(valid_614086, JString, required = false,
                                 default = nil)
  if valid_614086 != nil:
    section.add "X-Amz-Date", valid_614086
  var valid_614087 = header.getOrDefault("X-Amz-Credential")
  valid_614087 = validateParameter(valid_614087, JString, required = false,
                                 default = nil)
  if valid_614087 != nil:
    section.add "X-Amz-Credential", valid_614087
  var valid_614088 = header.getOrDefault("X-Amz-Security-Token")
  valid_614088 = validateParameter(valid_614088, JString, required = false,
                                 default = nil)
  if valid_614088 != nil:
    section.add "X-Amz-Security-Token", valid_614088
  var valid_614089 = header.getOrDefault("X-Amz-Algorithm")
  valid_614089 = validateParameter(valid_614089, JString, required = false,
                                 default = nil)
  if valid_614089 != nil:
    section.add "X-Amz-Algorithm", valid_614089
  var valid_614090 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614090 = validateParameter(valid_614090, JString, required = false,
                                 default = nil)
  if valid_614090 != nil:
    section.add "X-Amz-SignedHeaders", valid_614090
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614092: Call_MergePullRequestByThreeWay_614080; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attempts to merge the source commit of a pull request into the specified destination branch for that pull request at the specified commit using the three-way merge strategy. If the merge is successful, it closes the pull request.
  ## 
  let valid = call_614092.validator(path, query, header, formData, body)
  let scheme = call_614092.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614092.url(scheme.get, call_614092.host, call_614092.base,
                         call_614092.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614092, url, valid)

proc call*(call_614093: Call_MergePullRequestByThreeWay_614080; body: JsonNode): Recallable =
  ## mergePullRequestByThreeWay
  ## Attempts to merge the source commit of a pull request into the specified destination branch for that pull request at the specified commit using the three-way merge strategy. If the merge is successful, it closes the pull request.
  ##   body: JObject (required)
  var body_614094 = newJObject()
  if body != nil:
    body_614094 = body
  result = call_614093.call(nil, nil, nil, nil, body_614094)

var mergePullRequestByThreeWay* = Call_MergePullRequestByThreeWay_614080(
    name: "mergePullRequestByThreeWay", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.MergePullRequestByThreeWay",
    validator: validate_MergePullRequestByThreeWay_614081, base: "/",
    url: url_MergePullRequestByThreeWay_614082,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_OverridePullRequestApprovalRules_614095 = ref object of OpenApiRestCall_612658
proc url_OverridePullRequestApprovalRules_614097(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_OverridePullRequestApprovalRules_614096(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Sets aside (overrides) all approval rule requirements for a specified pull request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614098 = header.getOrDefault("X-Amz-Target")
  valid_614098 = validateParameter(valid_614098, JString, required = true, default = newJString(
      "CodeCommit_20150413.OverridePullRequestApprovalRules"))
  if valid_614098 != nil:
    section.add "X-Amz-Target", valid_614098
  var valid_614099 = header.getOrDefault("X-Amz-Signature")
  valid_614099 = validateParameter(valid_614099, JString, required = false,
                                 default = nil)
  if valid_614099 != nil:
    section.add "X-Amz-Signature", valid_614099
  var valid_614100 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614100 = validateParameter(valid_614100, JString, required = false,
                                 default = nil)
  if valid_614100 != nil:
    section.add "X-Amz-Content-Sha256", valid_614100
  var valid_614101 = header.getOrDefault("X-Amz-Date")
  valid_614101 = validateParameter(valid_614101, JString, required = false,
                                 default = nil)
  if valid_614101 != nil:
    section.add "X-Amz-Date", valid_614101
  var valid_614102 = header.getOrDefault("X-Amz-Credential")
  valid_614102 = validateParameter(valid_614102, JString, required = false,
                                 default = nil)
  if valid_614102 != nil:
    section.add "X-Amz-Credential", valid_614102
  var valid_614103 = header.getOrDefault("X-Amz-Security-Token")
  valid_614103 = validateParameter(valid_614103, JString, required = false,
                                 default = nil)
  if valid_614103 != nil:
    section.add "X-Amz-Security-Token", valid_614103
  var valid_614104 = header.getOrDefault("X-Amz-Algorithm")
  valid_614104 = validateParameter(valid_614104, JString, required = false,
                                 default = nil)
  if valid_614104 != nil:
    section.add "X-Amz-Algorithm", valid_614104
  var valid_614105 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614105 = validateParameter(valid_614105, JString, required = false,
                                 default = nil)
  if valid_614105 != nil:
    section.add "X-Amz-SignedHeaders", valid_614105
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614107: Call_OverridePullRequestApprovalRules_614095;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Sets aside (overrides) all approval rule requirements for a specified pull request.
  ## 
  let valid = call_614107.validator(path, query, header, formData, body)
  let scheme = call_614107.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614107.url(scheme.get, call_614107.host, call_614107.base,
                         call_614107.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614107, url, valid)

proc call*(call_614108: Call_OverridePullRequestApprovalRules_614095;
          body: JsonNode): Recallable =
  ## overridePullRequestApprovalRules
  ## Sets aside (overrides) all approval rule requirements for a specified pull request.
  ##   body: JObject (required)
  var body_614109 = newJObject()
  if body != nil:
    body_614109 = body
  result = call_614108.call(nil, nil, nil, nil, body_614109)

var overridePullRequestApprovalRules* = Call_OverridePullRequestApprovalRules_614095(
    name: "overridePullRequestApprovalRules", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.OverridePullRequestApprovalRules",
    validator: validate_OverridePullRequestApprovalRules_614096, base: "/",
    url: url_OverridePullRequestApprovalRules_614097,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCommentForComparedCommit_614110 = ref object of OpenApiRestCall_612658
proc url_PostCommentForComparedCommit_614112(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCommentForComparedCommit_614111(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Posts a comment on the comparison between two commits.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614113 = header.getOrDefault("X-Amz-Target")
  valid_614113 = validateParameter(valid_614113, JString, required = true, default = newJString(
      "CodeCommit_20150413.PostCommentForComparedCommit"))
  if valid_614113 != nil:
    section.add "X-Amz-Target", valid_614113
  var valid_614114 = header.getOrDefault("X-Amz-Signature")
  valid_614114 = validateParameter(valid_614114, JString, required = false,
                                 default = nil)
  if valid_614114 != nil:
    section.add "X-Amz-Signature", valid_614114
  var valid_614115 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614115 = validateParameter(valid_614115, JString, required = false,
                                 default = nil)
  if valid_614115 != nil:
    section.add "X-Amz-Content-Sha256", valid_614115
  var valid_614116 = header.getOrDefault("X-Amz-Date")
  valid_614116 = validateParameter(valid_614116, JString, required = false,
                                 default = nil)
  if valid_614116 != nil:
    section.add "X-Amz-Date", valid_614116
  var valid_614117 = header.getOrDefault("X-Amz-Credential")
  valid_614117 = validateParameter(valid_614117, JString, required = false,
                                 default = nil)
  if valid_614117 != nil:
    section.add "X-Amz-Credential", valid_614117
  var valid_614118 = header.getOrDefault("X-Amz-Security-Token")
  valid_614118 = validateParameter(valid_614118, JString, required = false,
                                 default = nil)
  if valid_614118 != nil:
    section.add "X-Amz-Security-Token", valid_614118
  var valid_614119 = header.getOrDefault("X-Amz-Algorithm")
  valid_614119 = validateParameter(valid_614119, JString, required = false,
                                 default = nil)
  if valid_614119 != nil:
    section.add "X-Amz-Algorithm", valid_614119
  var valid_614120 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614120 = validateParameter(valid_614120, JString, required = false,
                                 default = nil)
  if valid_614120 != nil:
    section.add "X-Amz-SignedHeaders", valid_614120
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614122: Call_PostCommentForComparedCommit_614110; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Posts a comment on the comparison between two commits.
  ## 
  let valid = call_614122.validator(path, query, header, formData, body)
  let scheme = call_614122.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614122.url(scheme.get, call_614122.host, call_614122.base,
                         call_614122.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614122, url, valid)

proc call*(call_614123: Call_PostCommentForComparedCommit_614110; body: JsonNode): Recallable =
  ## postCommentForComparedCommit
  ## Posts a comment on the comparison between two commits.
  ##   body: JObject (required)
  var body_614124 = newJObject()
  if body != nil:
    body_614124 = body
  result = call_614123.call(nil, nil, nil, nil, body_614124)

var postCommentForComparedCommit* = Call_PostCommentForComparedCommit_614110(
    name: "postCommentForComparedCommit", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.PostCommentForComparedCommit",
    validator: validate_PostCommentForComparedCommit_614111, base: "/",
    url: url_PostCommentForComparedCommit_614112,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCommentForPullRequest_614125 = ref object of OpenApiRestCall_612658
proc url_PostCommentForPullRequest_614127(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCommentForPullRequest_614126(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Posts a comment on a pull request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614128 = header.getOrDefault("X-Amz-Target")
  valid_614128 = validateParameter(valid_614128, JString, required = true, default = newJString(
      "CodeCommit_20150413.PostCommentForPullRequest"))
  if valid_614128 != nil:
    section.add "X-Amz-Target", valid_614128
  var valid_614129 = header.getOrDefault("X-Amz-Signature")
  valid_614129 = validateParameter(valid_614129, JString, required = false,
                                 default = nil)
  if valid_614129 != nil:
    section.add "X-Amz-Signature", valid_614129
  var valid_614130 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614130 = validateParameter(valid_614130, JString, required = false,
                                 default = nil)
  if valid_614130 != nil:
    section.add "X-Amz-Content-Sha256", valid_614130
  var valid_614131 = header.getOrDefault("X-Amz-Date")
  valid_614131 = validateParameter(valid_614131, JString, required = false,
                                 default = nil)
  if valid_614131 != nil:
    section.add "X-Amz-Date", valid_614131
  var valid_614132 = header.getOrDefault("X-Amz-Credential")
  valid_614132 = validateParameter(valid_614132, JString, required = false,
                                 default = nil)
  if valid_614132 != nil:
    section.add "X-Amz-Credential", valid_614132
  var valid_614133 = header.getOrDefault("X-Amz-Security-Token")
  valid_614133 = validateParameter(valid_614133, JString, required = false,
                                 default = nil)
  if valid_614133 != nil:
    section.add "X-Amz-Security-Token", valid_614133
  var valid_614134 = header.getOrDefault("X-Amz-Algorithm")
  valid_614134 = validateParameter(valid_614134, JString, required = false,
                                 default = nil)
  if valid_614134 != nil:
    section.add "X-Amz-Algorithm", valid_614134
  var valid_614135 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614135 = validateParameter(valid_614135, JString, required = false,
                                 default = nil)
  if valid_614135 != nil:
    section.add "X-Amz-SignedHeaders", valid_614135
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614137: Call_PostCommentForPullRequest_614125; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Posts a comment on a pull request.
  ## 
  let valid = call_614137.validator(path, query, header, formData, body)
  let scheme = call_614137.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614137.url(scheme.get, call_614137.host, call_614137.base,
                         call_614137.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614137, url, valid)

proc call*(call_614138: Call_PostCommentForPullRequest_614125; body: JsonNode): Recallable =
  ## postCommentForPullRequest
  ## Posts a comment on a pull request.
  ##   body: JObject (required)
  var body_614139 = newJObject()
  if body != nil:
    body_614139 = body
  result = call_614138.call(nil, nil, nil, nil, body_614139)

var postCommentForPullRequest* = Call_PostCommentForPullRequest_614125(
    name: "postCommentForPullRequest", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.PostCommentForPullRequest",
    validator: validate_PostCommentForPullRequest_614126, base: "/",
    url: url_PostCommentForPullRequest_614127,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCommentReply_614140 = ref object of OpenApiRestCall_612658
proc url_PostCommentReply_614142(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCommentReply_614141(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Posts a comment in reply to an existing comment on a comparison between commits or a pull request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614143 = header.getOrDefault("X-Amz-Target")
  valid_614143 = validateParameter(valid_614143, JString, required = true, default = newJString(
      "CodeCommit_20150413.PostCommentReply"))
  if valid_614143 != nil:
    section.add "X-Amz-Target", valid_614143
  var valid_614144 = header.getOrDefault("X-Amz-Signature")
  valid_614144 = validateParameter(valid_614144, JString, required = false,
                                 default = nil)
  if valid_614144 != nil:
    section.add "X-Amz-Signature", valid_614144
  var valid_614145 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614145 = validateParameter(valid_614145, JString, required = false,
                                 default = nil)
  if valid_614145 != nil:
    section.add "X-Amz-Content-Sha256", valid_614145
  var valid_614146 = header.getOrDefault("X-Amz-Date")
  valid_614146 = validateParameter(valid_614146, JString, required = false,
                                 default = nil)
  if valid_614146 != nil:
    section.add "X-Amz-Date", valid_614146
  var valid_614147 = header.getOrDefault("X-Amz-Credential")
  valid_614147 = validateParameter(valid_614147, JString, required = false,
                                 default = nil)
  if valid_614147 != nil:
    section.add "X-Amz-Credential", valid_614147
  var valid_614148 = header.getOrDefault("X-Amz-Security-Token")
  valid_614148 = validateParameter(valid_614148, JString, required = false,
                                 default = nil)
  if valid_614148 != nil:
    section.add "X-Amz-Security-Token", valid_614148
  var valid_614149 = header.getOrDefault("X-Amz-Algorithm")
  valid_614149 = validateParameter(valid_614149, JString, required = false,
                                 default = nil)
  if valid_614149 != nil:
    section.add "X-Amz-Algorithm", valid_614149
  var valid_614150 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614150 = validateParameter(valid_614150, JString, required = false,
                                 default = nil)
  if valid_614150 != nil:
    section.add "X-Amz-SignedHeaders", valid_614150
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614152: Call_PostCommentReply_614140; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Posts a comment in reply to an existing comment on a comparison between commits or a pull request.
  ## 
  let valid = call_614152.validator(path, query, header, formData, body)
  let scheme = call_614152.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614152.url(scheme.get, call_614152.host, call_614152.base,
                         call_614152.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614152, url, valid)

proc call*(call_614153: Call_PostCommentReply_614140; body: JsonNode): Recallable =
  ## postCommentReply
  ## Posts a comment in reply to an existing comment on a comparison between commits or a pull request.
  ##   body: JObject (required)
  var body_614154 = newJObject()
  if body != nil:
    body_614154 = body
  result = call_614153.call(nil, nil, nil, nil, body_614154)

var postCommentReply* = Call_PostCommentReply_614140(name: "postCommentReply",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.PostCommentReply",
    validator: validate_PostCommentReply_614141, base: "/",
    url: url_PostCommentReply_614142, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutFile_614155 = ref object of OpenApiRestCall_612658
proc url_PutFile_614157(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutFile_614156(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds or updates a file in a branch in an AWS CodeCommit repository, and generates a commit for the addition in the specified branch.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614158 = header.getOrDefault("X-Amz-Target")
  valid_614158 = validateParameter(valid_614158, JString, required = true, default = newJString(
      "CodeCommit_20150413.PutFile"))
  if valid_614158 != nil:
    section.add "X-Amz-Target", valid_614158
  var valid_614159 = header.getOrDefault("X-Amz-Signature")
  valid_614159 = validateParameter(valid_614159, JString, required = false,
                                 default = nil)
  if valid_614159 != nil:
    section.add "X-Amz-Signature", valid_614159
  var valid_614160 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614160 = validateParameter(valid_614160, JString, required = false,
                                 default = nil)
  if valid_614160 != nil:
    section.add "X-Amz-Content-Sha256", valid_614160
  var valid_614161 = header.getOrDefault("X-Amz-Date")
  valid_614161 = validateParameter(valid_614161, JString, required = false,
                                 default = nil)
  if valid_614161 != nil:
    section.add "X-Amz-Date", valid_614161
  var valid_614162 = header.getOrDefault("X-Amz-Credential")
  valid_614162 = validateParameter(valid_614162, JString, required = false,
                                 default = nil)
  if valid_614162 != nil:
    section.add "X-Amz-Credential", valid_614162
  var valid_614163 = header.getOrDefault("X-Amz-Security-Token")
  valid_614163 = validateParameter(valid_614163, JString, required = false,
                                 default = nil)
  if valid_614163 != nil:
    section.add "X-Amz-Security-Token", valid_614163
  var valid_614164 = header.getOrDefault("X-Amz-Algorithm")
  valid_614164 = validateParameter(valid_614164, JString, required = false,
                                 default = nil)
  if valid_614164 != nil:
    section.add "X-Amz-Algorithm", valid_614164
  var valid_614165 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614165 = validateParameter(valid_614165, JString, required = false,
                                 default = nil)
  if valid_614165 != nil:
    section.add "X-Amz-SignedHeaders", valid_614165
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614167: Call_PutFile_614155; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds or updates a file in a branch in an AWS CodeCommit repository, and generates a commit for the addition in the specified branch.
  ## 
  let valid = call_614167.validator(path, query, header, formData, body)
  let scheme = call_614167.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614167.url(scheme.get, call_614167.host, call_614167.base,
                         call_614167.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614167, url, valid)

proc call*(call_614168: Call_PutFile_614155; body: JsonNode): Recallable =
  ## putFile
  ## Adds or updates a file in a branch in an AWS CodeCommit repository, and generates a commit for the addition in the specified branch.
  ##   body: JObject (required)
  var body_614169 = newJObject()
  if body != nil:
    body_614169 = body
  result = call_614168.call(nil, nil, nil, nil, body_614169)

var putFile* = Call_PutFile_614155(name: "putFile", meth: HttpMethod.HttpPost,
                                host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.PutFile",
                                validator: validate_PutFile_614156, base: "/",
                                url: url_PutFile_614157,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutRepositoryTriggers_614170 = ref object of OpenApiRestCall_612658
proc url_PutRepositoryTriggers_614172(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutRepositoryTriggers_614171(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Replaces all triggers for a repository. Used to create or delete triggers.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614173 = header.getOrDefault("X-Amz-Target")
  valid_614173 = validateParameter(valid_614173, JString, required = true, default = newJString(
      "CodeCommit_20150413.PutRepositoryTriggers"))
  if valid_614173 != nil:
    section.add "X-Amz-Target", valid_614173
  var valid_614174 = header.getOrDefault("X-Amz-Signature")
  valid_614174 = validateParameter(valid_614174, JString, required = false,
                                 default = nil)
  if valid_614174 != nil:
    section.add "X-Amz-Signature", valid_614174
  var valid_614175 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614175 = validateParameter(valid_614175, JString, required = false,
                                 default = nil)
  if valid_614175 != nil:
    section.add "X-Amz-Content-Sha256", valid_614175
  var valid_614176 = header.getOrDefault("X-Amz-Date")
  valid_614176 = validateParameter(valid_614176, JString, required = false,
                                 default = nil)
  if valid_614176 != nil:
    section.add "X-Amz-Date", valid_614176
  var valid_614177 = header.getOrDefault("X-Amz-Credential")
  valid_614177 = validateParameter(valid_614177, JString, required = false,
                                 default = nil)
  if valid_614177 != nil:
    section.add "X-Amz-Credential", valid_614177
  var valid_614178 = header.getOrDefault("X-Amz-Security-Token")
  valid_614178 = validateParameter(valid_614178, JString, required = false,
                                 default = nil)
  if valid_614178 != nil:
    section.add "X-Amz-Security-Token", valid_614178
  var valid_614179 = header.getOrDefault("X-Amz-Algorithm")
  valid_614179 = validateParameter(valid_614179, JString, required = false,
                                 default = nil)
  if valid_614179 != nil:
    section.add "X-Amz-Algorithm", valid_614179
  var valid_614180 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614180 = validateParameter(valid_614180, JString, required = false,
                                 default = nil)
  if valid_614180 != nil:
    section.add "X-Amz-SignedHeaders", valid_614180
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614182: Call_PutRepositoryTriggers_614170; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Replaces all triggers for a repository. Used to create or delete triggers.
  ## 
  let valid = call_614182.validator(path, query, header, formData, body)
  let scheme = call_614182.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614182.url(scheme.get, call_614182.host, call_614182.base,
                         call_614182.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614182, url, valid)

proc call*(call_614183: Call_PutRepositoryTriggers_614170; body: JsonNode): Recallable =
  ## putRepositoryTriggers
  ## Replaces all triggers for a repository. Used to create or delete triggers.
  ##   body: JObject (required)
  var body_614184 = newJObject()
  if body != nil:
    body_614184 = body
  result = call_614183.call(nil, nil, nil, nil, body_614184)

var putRepositoryTriggers* = Call_PutRepositoryTriggers_614170(
    name: "putRepositoryTriggers", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.PutRepositoryTriggers",
    validator: validate_PutRepositoryTriggers_614171, base: "/",
    url: url_PutRepositoryTriggers_614172, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_614185 = ref object of OpenApiRestCall_612658
proc url_TagResource_614187(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_614186(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds or updates tags for a resource in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats">CodeCommit Resources and Operations</a> in the <i>AWS CodeCommit User Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614188 = header.getOrDefault("X-Amz-Target")
  valid_614188 = validateParameter(valid_614188, JString, required = true, default = newJString(
      "CodeCommit_20150413.TagResource"))
  if valid_614188 != nil:
    section.add "X-Amz-Target", valid_614188
  var valid_614189 = header.getOrDefault("X-Amz-Signature")
  valid_614189 = validateParameter(valid_614189, JString, required = false,
                                 default = nil)
  if valid_614189 != nil:
    section.add "X-Amz-Signature", valid_614189
  var valid_614190 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614190 = validateParameter(valid_614190, JString, required = false,
                                 default = nil)
  if valid_614190 != nil:
    section.add "X-Amz-Content-Sha256", valid_614190
  var valid_614191 = header.getOrDefault("X-Amz-Date")
  valid_614191 = validateParameter(valid_614191, JString, required = false,
                                 default = nil)
  if valid_614191 != nil:
    section.add "X-Amz-Date", valid_614191
  var valid_614192 = header.getOrDefault("X-Amz-Credential")
  valid_614192 = validateParameter(valid_614192, JString, required = false,
                                 default = nil)
  if valid_614192 != nil:
    section.add "X-Amz-Credential", valid_614192
  var valid_614193 = header.getOrDefault("X-Amz-Security-Token")
  valid_614193 = validateParameter(valid_614193, JString, required = false,
                                 default = nil)
  if valid_614193 != nil:
    section.add "X-Amz-Security-Token", valid_614193
  var valid_614194 = header.getOrDefault("X-Amz-Algorithm")
  valid_614194 = validateParameter(valid_614194, JString, required = false,
                                 default = nil)
  if valid_614194 != nil:
    section.add "X-Amz-Algorithm", valid_614194
  var valid_614195 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614195 = validateParameter(valid_614195, JString, required = false,
                                 default = nil)
  if valid_614195 != nil:
    section.add "X-Amz-SignedHeaders", valid_614195
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614197: Call_TagResource_614185; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds or updates tags for a resource in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats">CodeCommit Resources and Operations</a> in the <i>AWS CodeCommit User Guide</i>.
  ## 
  let valid = call_614197.validator(path, query, header, formData, body)
  let scheme = call_614197.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614197.url(scheme.get, call_614197.host, call_614197.base,
                         call_614197.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614197, url, valid)

proc call*(call_614198: Call_TagResource_614185; body: JsonNode): Recallable =
  ## tagResource
  ## Adds or updates tags for a resource in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats">CodeCommit Resources and Operations</a> in the <i>AWS CodeCommit User Guide</i>.
  ##   body: JObject (required)
  var body_614199 = newJObject()
  if body != nil:
    body_614199 = body
  result = call_614198.call(nil, nil, nil, nil, body_614199)

var tagResource* = Call_TagResource_614185(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.TagResource",
                                        validator: validate_TagResource_614186,
                                        base: "/", url: url_TagResource_614187,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestRepositoryTriggers_614200 = ref object of OpenApiRestCall_612658
proc url_TestRepositoryTriggers_614202(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TestRepositoryTriggers_614201(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Tests the functionality of repository triggers by sending information to the trigger target. If real data is available in the repository, the test sends data from the last commit. If no data is available, sample data is generated.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614203 = header.getOrDefault("X-Amz-Target")
  valid_614203 = validateParameter(valid_614203, JString, required = true, default = newJString(
      "CodeCommit_20150413.TestRepositoryTriggers"))
  if valid_614203 != nil:
    section.add "X-Amz-Target", valid_614203
  var valid_614204 = header.getOrDefault("X-Amz-Signature")
  valid_614204 = validateParameter(valid_614204, JString, required = false,
                                 default = nil)
  if valid_614204 != nil:
    section.add "X-Amz-Signature", valid_614204
  var valid_614205 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614205 = validateParameter(valid_614205, JString, required = false,
                                 default = nil)
  if valid_614205 != nil:
    section.add "X-Amz-Content-Sha256", valid_614205
  var valid_614206 = header.getOrDefault("X-Amz-Date")
  valid_614206 = validateParameter(valid_614206, JString, required = false,
                                 default = nil)
  if valid_614206 != nil:
    section.add "X-Amz-Date", valid_614206
  var valid_614207 = header.getOrDefault("X-Amz-Credential")
  valid_614207 = validateParameter(valid_614207, JString, required = false,
                                 default = nil)
  if valid_614207 != nil:
    section.add "X-Amz-Credential", valid_614207
  var valid_614208 = header.getOrDefault("X-Amz-Security-Token")
  valid_614208 = validateParameter(valid_614208, JString, required = false,
                                 default = nil)
  if valid_614208 != nil:
    section.add "X-Amz-Security-Token", valid_614208
  var valid_614209 = header.getOrDefault("X-Amz-Algorithm")
  valid_614209 = validateParameter(valid_614209, JString, required = false,
                                 default = nil)
  if valid_614209 != nil:
    section.add "X-Amz-Algorithm", valid_614209
  var valid_614210 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614210 = validateParameter(valid_614210, JString, required = false,
                                 default = nil)
  if valid_614210 != nil:
    section.add "X-Amz-SignedHeaders", valid_614210
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614212: Call_TestRepositoryTriggers_614200; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tests the functionality of repository triggers by sending information to the trigger target. If real data is available in the repository, the test sends data from the last commit. If no data is available, sample data is generated.
  ## 
  let valid = call_614212.validator(path, query, header, formData, body)
  let scheme = call_614212.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614212.url(scheme.get, call_614212.host, call_614212.base,
                         call_614212.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614212, url, valid)

proc call*(call_614213: Call_TestRepositoryTriggers_614200; body: JsonNode): Recallable =
  ## testRepositoryTriggers
  ## Tests the functionality of repository triggers by sending information to the trigger target. If real data is available in the repository, the test sends data from the last commit. If no data is available, sample data is generated.
  ##   body: JObject (required)
  var body_614214 = newJObject()
  if body != nil:
    body_614214 = body
  result = call_614213.call(nil, nil, nil, nil, body_614214)

var testRepositoryTriggers* = Call_TestRepositoryTriggers_614200(
    name: "testRepositoryTriggers", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.TestRepositoryTriggers",
    validator: validate_TestRepositoryTriggers_614201, base: "/",
    url: url_TestRepositoryTriggers_614202, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_614215 = ref object of OpenApiRestCall_612658
proc url_UntagResource_614217(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_614216(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes tags for a resource in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats">CodeCommit Resources and Operations</a> in the <i>AWS CodeCommit User Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614218 = header.getOrDefault("X-Amz-Target")
  valid_614218 = validateParameter(valid_614218, JString, required = true, default = newJString(
      "CodeCommit_20150413.UntagResource"))
  if valid_614218 != nil:
    section.add "X-Amz-Target", valid_614218
  var valid_614219 = header.getOrDefault("X-Amz-Signature")
  valid_614219 = validateParameter(valid_614219, JString, required = false,
                                 default = nil)
  if valid_614219 != nil:
    section.add "X-Amz-Signature", valid_614219
  var valid_614220 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614220 = validateParameter(valid_614220, JString, required = false,
                                 default = nil)
  if valid_614220 != nil:
    section.add "X-Amz-Content-Sha256", valid_614220
  var valid_614221 = header.getOrDefault("X-Amz-Date")
  valid_614221 = validateParameter(valid_614221, JString, required = false,
                                 default = nil)
  if valid_614221 != nil:
    section.add "X-Amz-Date", valid_614221
  var valid_614222 = header.getOrDefault("X-Amz-Credential")
  valid_614222 = validateParameter(valid_614222, JString, required = false,
                                 default = nil)
  if valid_614222 != nil:
    section.add "X-Amz-Credential", valid_614222
  var valid_614223 = header.getOrDefault("X-Amz-Security-Token")
  valid_614223 = validateParameter(valid_614223, JString, required = false,
                                 default = nil)
  if valid_614223 != nil:
    section.add "X-Amz-Security-Token", valid_614223
  var valid_614224 = header.getOrDefault("X-Amz-Algorithm")
  valid_614224 = validateParameter(valid_614224, JString, required = false,
                                 default = nil)
  if valid_614224 != nil:
    section.add "X-Amz-Algorithm", valid_614224
  var valid_614225 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614225 = validateParameter(valid_614225, JString, required = false,
                                 default = nil)
  if valid_614225 != nil:
    section.add "X-Amz-SignedHeaders", valid_614225
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614227: Call_UntagResource_614215; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tags for a resource in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats">CodeCommit Resources and Operations</a> in the <i>AWS CodeCommit User Guide</i>.
  ## 
  let valid = call_614227.validator(path, query, header, formData, body)
  let scheme = call_614227.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614227.url(scheme.get, call_614227.host, call_614227.base,
                         call_614227.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614227, url, valid)

proc call*(call_614228: Call_UntagResource_614215; body: JsonNode): Recallable =
  ## untagResource
  ## Removes tags for a resource in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats">CodeCommit Resources and Operations</a> in the <i>AWS CodeCommit User Guide</i>.
  ##   body: JObject (required)
  var body_614229 = newJObject()
  if body != nil:
    body_614229 = body
  result = call_614228.call(nil, nil, nil, nil, body_614229)

var untagResource* = Call_UntagResource_614215(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UntagResource",
    validator: validate_UntagResource_614216, base: "/", url: url_UntagResource_614217,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApprovalRuleTemplateContent_614230 = ref object of OpenApiRestCall_612658
proc url_UpdateApprovalRuleTemplateContent_614232(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateApprovalRuleTemplateContent_614231(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the content of an approval rule template. You can change the number of required approvals, the membership of the approval rule, and whether an approval pool is defined.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614233 = header.getOrDefault("X-Amz-Target")
  valid_614233 = validateParameter(valid_614233, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdateApprovalRuleTemplateContent"))
  if valid_614233 != nil:
    section.add "X-Amz-Target", valid_614233
  var valid_614234 = header.getOrDefault("X-Amz-Signature")
  valid_614234 = validateParameter(valid_614234, JString, required = false,
                                 default = nil)
  if valid_614234 != nil:
    section.add "X-Amz-Signature", valid_614234
  var valid_614235 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614235 = validateParameter(valid_614235, JString, required = false,
                                 default = nil)
  if valid_614235 != nil:
    section.add "X-Amz-Content-Sha256", valid_614235
  var valid_614236 = header.getOrDefault("X-Amz-Date")
  valid_614236 = validateParameter(valid_614236, JString, required = false,
                                 default = nil)
  if valid_614236 != nil:
    section.add "X-Amz-Date", valid_614236
  var valid_614237 = header.getOrDefault("X-Amz-Credential")
  valid_614237 = validateParameter(valid_614237, JString, required = false,
                                 default = nil)
  if valid_614237 != nil:
    section.add "X-Amz-Credential", valid_614237
  var valid_614238 = header.getOrDefault("X-Amz-Security-Token")
  valid_614238 = validateParameter(valid_614238, JString, required = false,
                                 default = nil)
  if valid_614238 != nil:
    section.add "X-Amz-Security-Token", valid_614238
  var valid_614239 = header.getOrDefault("X-Amz-Algorithm")
  valid_614239 = validateParameter(valid_614239, JString, required = false,
                                 default = nil)
  if valid_614239 != nil:
    section.add "X-Amz-Algorithm", valid_614239
  var valid_614240 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614240 = validateParameter(valid_614240, JString, required = false,
                                 default = nil)
  if valid_614240 != nil:
    section.add "X-Amz-SignedHeaders", valid_614240
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614242: Call_UpdateApprovalRuleTemplateContent_614230;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Updates the content of an approval rule template. You can change the number of required approvals, the membership of the approval rule, and whether an approval pool is defined.
  ## 
  let valid = call_614242.validator(path, query, header, formData, body)
  let scheme = call_614242.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614242.url(scheme.get, call_614242.host, call_614242.base,
                         call_614242.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614242, url, valid)

proc call*(call_614243: Call_UpdateApprovalRuleTemplateContent_614230;
          body: JsonNode): Recallable =
  ## updateApprovalRuleTemplateContent
  ## Updates the content of an approval rule template. You can change the number of required approvals, the membership of the approval rule, and whether an approval pool is defined.
  ##   body: JObject (required)
  var body_614244 = newJObject()
  if body != nil:
    body_614244 = body
  result = call_614243.call(nil, nil, nil, nil, body_614244)

var updateApprovalRuleTemplateContent* = Call_UpdateApprovalRuleTemplateContent_614230(
    name: "updateApprovalRuleTemplateContent", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.UpdateApprovalRuleTemplateContent",
    validator: validate_UpdateApprovalRuleTemplateContent_614231, base: "/",
    url: url_UpdateApprovalRuleTemplateContent_614232,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApprovalRuleTemplateDescription_614245 = ref object of OpenApiRestCall_612658
proc url_UpdateApprovalRuleTemplateDescription_614247(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateApprovalRuleTemplateDescription_614246(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the description for a specified approval rule template.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614248 = header.getOrDefault("X-Amz-Target")
  valid_614248 = validateParameter(valid_614248, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdateApprovalRuleTemplateDescription"))
  if valid_614248 != nil:
    section.add "X-Amz-Target", valid_614248
  var valid_614249 = header.getOrDefault("X-Amz-Signature")
  valid_614249 = validateParameter(valid_614249, JString, required = false,
                                 default = nil)
  if valid_614249 != nil:
    section.add "X-Amz-Signature", valid_614249
  var valid_614250 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614250 = validateParameter(valid_614250, JString, required = false,
                                 default = nil)
  if valid_614250 != nil:
    section.add "X-Amz-Content-Sha256", valid_614250
  var valid_614251 = header.getOrDefault("X-Amz-Date")
  valid_614251 = validateParameter(valid_614251, JString, required = false,
                                 default = nil)
  if valid_614251 != nil:
    section.add "X-Amz-Date", valid_614251
  var valid_614252 = header.getOrDefault("X-Amz-Credential")
  valid_614252 = validateParameter(valid_614252, JString, required = false,
                                 default = nil)
  if valid_614252 != nil:
    section.add "X-Amz-Credential", valid_614252
  var valid_614253 = header.getOrDefault("X-Amz-Security-Token")
  valid_614253 = validateParameter(valid_614253, JString, required = false,
                                 default = nil)
  if valid_614253 != nil:
    section.add "X-Amz-Security-Token", valid_614253
  var valid_614254 = header.getOrDefault("X-Amz-Algorithm")
  valid_614254 = validateParameter(valid_614254, JString, required = false,
                                 default = nil)
  if valid_614254 != nil:
    section.add "X-Amz-Algorithm", valid_614254
  var valid_614255 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614255 = validateParameter(valid_614255, JString, required = false,
                                 default = nil)
  if valid_614255 != nil:
    section.add "X-Amz-SignedHeaders", valid_614255
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614257: Call_UpdateApprovalRuleTemplateDescription_614245;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Updates the description for a specified approval rule template.
  ## 
  let valid = call_614257.validator(path, query, header, formData, body)
  let scheme = call_614257.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614257.url(scheme.get, call_614257.host, call_614257.base,
                         call_614257.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614257, url, valid)

proc call*(call_614258: Call_UpdateApprovalRuleTemplateDescription_614245;
          body: JsonNode): Recallable =
  ## updateApprovalRuleTemplateDescription
  ## Updates the description for a specified approval rule template.
  ##   body: JObject (required)
  var body_614259 = newJObject()
  if body != nil:
    body_614259 = body
  result = call_614258.call(nil, nil, nil, nil, body_614259)

var updateApprovalRuleTemplateDescription* = Call_UpdateApprovalRuleTemplateDescription_614245(
    name: "updateApprovalRuleTemplateDescription", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.UpdateApprovalRuleTemplateDescription",
    validator: validate_UpdateApprovalRuleTemplateDescription_614246, base: "/",
    url: url_UpdateApprovalRuleTemplateDescription_614247,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApprovalRuleTemplateName_614260 = ref object of OpenApiRestCall_612658
proc url_UpdateApprovalRuleTemplateName_614262(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateApprovalRuleTemplateName_614261(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the name of a specified approval rule template.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614263 = header.getOrDefault("X-Amz-Target")
  valid_614263 = validateParameter(valid_614263, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdateApprovalRuleTemplateName"))
  if valid_614263 != nil:
    section.add "X-Amz-Target", valid_614263
  var valid_614264 = header.getOrDefault("X-Amz-Signature")
  valid_614264 = validateParameter(valid_614264, JString, required = false,
                                 default = nil)
  if valid_614264 != nil:
    section.add "X-Amz-Signature", valid_614264
  var valid_614265 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614265 = validateParameter(valid_614265, JString, required = false,
                                 default = nil)
  if valid_614265 != nil:
    section.add "X-Amz-Content-Sha256", valid_614265
  var valid_614266 = header.getOrDefault("X-Amz-Date")
  valid_614266 = validateParameter(valid_614266, JString, required = false,
                                 default = nil)
  if valid_614266 != nil:
    section.add "X-Amz-Date", valid_614266
  var valid_614267 = header.getOrDefault("X-Amz-Credential")
  valid_614267 = validateParameter(valid_614267, JString, required = false,
                                 default = nil)
  if valid_614267 != nil:
    section.add "X-Amz-Credential", valid_614267
  var valid_614268 = header.getOrDefault("X-Amz-Security-Token")
  valid_614268 = validateParameter(valid_614268, JString, required = false,
                                 default = nil)
  if valid_614268 != nil:
    section.add "X-Amz-Security-Token", valid_614268
  var valid_614269 = header.getOrDefault("X-Amz-Algorithm")
  valid_614269 = validateParameter(valid_614269, JString, required = false,
                                 default = nil)
  if valid_614269 != nil:
    section.add "X-Amz-Algorithm", valid_614269
  var valid_614270 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614270 = validateParameter(valid_614270, JString, required = false,
                                 default = nil)
  if valid_614270 != nil:
    section.add "X-Amz-SignedHeaders", valid_614270
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614272: Call_UpdateApprovalRuleTemplateName_614260; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the name of a specified approval rule template.
  ## 
  let valid = call_614272.validator(path, query, header, formData, body)
  let scheme = call_614272.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614272.url(scheme.get, call_614272.host, call_614272.base,
                         call_614272.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614272, url, valid)

proc call*(call_614273: Call_UpdateApprovalRuleTemplateName_614260; body: JsonNode): Recallable =
  ## updateApprovalRuleTemplateName
  ## Updates the name of a specified approval rule template.
  ##   body: JObject (required)
  var body_614274 = newJObject()
  if body != nil:
    body_614274 = body
  result = call_614273.call(nil, nil, nil, nil, body_614274)

var updateApprovalRuleTemplateName* = Call_UpdateApprovalRuleTemplateName_614260(
    name: "updateApprovalRuleTemplateName", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UpdateApprovalRuleTemplateName",
    validator: validate_UpdateApprovalRuleTemplateName_614261, base: "/",
    url: url_UpdateApprovalRuleTemplateName_614262,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateComment_614275 = ref object of OpenApiRestCall_612658
proc url_UpdateComment_614277(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateComment_614276(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Replaces the contents of a comment.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614278 = header.getOrDefault("X-Amz-Target")
  valid_614278 = validateParameter(valid_614278, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdateComment"))
  if valid_614278 != nil:
    section.add "X-Amz-Target", valid_614278
  var valid_614279 = header.getOrDefault("X-Amz-Signature")
  valid_614279 = validateParameter(valid_614279, JString, required = false,
                                 default = nil)
  if valid_614279 != nil:
    section.add "X-Amz-Signature", valid_614279
  var valid_614280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614280 = validateParameter(valid_614280, JString, required = false,
                                 default = nil)
  if valid_614280 != nil:
    section.add "X-Amz-Content-Sha256", valid_614280
  var valid_614281 = header.getOrDefault("X-Amz-Date")
  valid_614281 = validateParameter(valid_614281, JString, required = false,
                                 default = nil)
  if valid_614281 != nil:
    section.add "X-Amz-Date", valid_614281
  var valid_614282 = header.getOrDefault("X-Amz-Credential")
  valid_614282 = validateParameter(valid_614282, JString, required = false,
                                 default = nil)
  if valid_614282 != nil:
    section.add "X-Amz-Credential", valid_614282
  var valid_614283 = header.getOrDefault("X-Amz-Security-Token")
  valid_614283 = validateParameter(valid_614283, JString, required = false,
                                 default = nil)
  if valid_614283 != nil:
    section.add "X-Amz-Security-Token", valid_614283
  var valid_614284 = header.getOrDefault("X-Amz-Algorithm")
  valid_614284 = validateParameter(valid_614284, JString, required = false,
                                 default = nil)
  if valid_614284 != nil:
    section.add "X-Amz-Algorithm", valid_614284
  var valid_614285 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614285 = validateParameter(valid_614285, JString, required = false,
                                 default = nil)
  if valid_614285 != nil:
    section.add "X-Amz-SignedHeaders", valid_614285
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614287: Call_UpdateComment_614275; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Replaces the contents of a comment.
  ## 
  let valid = call_614287.validator(path, query, header, formData, body)
  let scheme = call_614287.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614287.url(scheme.get, call_614287.host, call_614287.base,
                         call_614287.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614287, url, valid)

proc call*(call_614288: Call_UpdateComment_614275; body: JsonNode): Recallable =
  ## updateComment
  ## Replaces the contents of a comment.
  ##   body: JObject (required)
  var body_614289 = newJObject()
  if body != nil:
    body_614289 = body
  result = call_614288.call(nil, nil, nil, nil, body_614289)

var updateComment* = Call_UpdateComment_614275(name: "updateComment",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UpdateComment",
    validator: validate_UpdateComment_614276, base: "/", url: url_UpdateComment_614277,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDefaultBranch_614290 = ref object of OpenApiRestCall_612658
proc url_UpdateDefaultBranch_614292(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDefaultBranch_614291(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Sets or changes the default branch name for the specified repository.</p> <note> <p>If you use this operation to change the default branch name to the current default branch name, a success message is returned even though the default branch did not change.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614293 = header.getOrDefault("X-Amz-Target")
  valid_614293 = validateParameter(valid_614293, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdateDefaultBranch"))
  if valid_614293 != nil:
    section.add "X-Amz-Target", valid_614293
  var valid_614294 = header.getOrDefault("X-Amz-Signature")
  valid_614294 = validateParameter(valid_614294, JString, required = false,
                                 default = nil)
  if valid_614294 != nil:
    section.add "X-Amz-Signature", valid_614294
  var valid_614295 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614295 = validateParameter(valid_614295, JString, required = false,
                                 default = nil)
  if valid_614295 != nil:
    section.add "X-Amz-Content-Sha256", valid_614295
  var valid_614296 = header.getOrDefault("X-Amz-Date")
  valid_614296 = validateParameter(valid_614296, JString, required = false,
                                 default = nil)
  if valid_614296 != nil:
    section.add "X-Amz-Date", valid_614296
  var valid_614297 = header.getOrDefault("X-Amz-Credential")
  valid_614297 = validateParameter(valid_614297, JString, required = false,
                                 default = nil)
  if valid_614297 != nil:
    section.add "X-Amz-Credential", valid_614297
  var valid_614298 = header.getOrDefault("X-Amz-Security-Token")
  valid_614298 = validateParameter(valid_614298, JString, required = false,
                                 default = nil)
  if valid_614298 != nil:
    section.add "X-Amz-Security-Token", valid_614298
  var valid_614299 = header.getOrDefault("X-Amz-Algorithm")
  valid_614299 = validateParameter(valid_614299, JString, required = false,
                                 default = nil)
  if valid_614299 != nil:
    section.add "X-Amz-Algorithm", valid_614299
  var valid_614300 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614300 = validateParameter(valid_614300, JString, required = false,
                                 default = nil)
  if valid_614300 != nil:
    section.add "X-Amz-SignedHeaders", valid_614300
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614302: Call_UpdateDefaultBranch_614290; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets or changes the default branch name for the specified repository.</p> <note> <p>If you use this operation to change the default branch name to the current default branch name, a success message is returned even though the default branch did not change.</p> </note>
  ## 
  let valid = call_614302.validator(path, query, header, formData, body)
  let scheme = call_614302.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614302.url(scheme.get, call_614302.host, call_614302.base,
                         call_614302.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614302, url, valid)

proc call*(call_614303: Call_UpdateDefaultBranch_614290; body: JsonNode): Recallable =
  ## updateDefaultBranch
  ## <p>Sets or changes the default branch name for the specified repository.</p> <note> <p>If you use this operation to change the default branch name to the current default branch name, a success message is returned even though the default branch did not change.</p> </note>
  ##   body: JObject (required)
  var body_614304 = newJObject()
  if body != nil:
    body_614304 = body
  result = call_614303.call(nil, nil, nil, nil, body_614304)

var updateDefaultBranch* = Call_UpdateDefaultBranch_614290(
    name: "updateDefaultBranch", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UpdateDefaultBranch",
    validator: validate_UpdateDefaultBranch_614291, base: "/",
    url: url_UpdateDefaultBranch_614292, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePullRequestApprovalRuleContent_614305 = ref object of OpenApiRestCall_612658
proc url_UpdatePullRequestApprovalRuleContent_614307(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdatePullRequestApprovalRuleContent_614306(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the structure of an approval rule created specifically for a pull request. For example, you can change the number of required approvers and the approval pool for approvers. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614308 = header.getOrDefault("X-Amz-Target")
  valid_614308 = validateParameter(valid_614308, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdatePullRequestApprovalRuleContent"))
  if valid_614308 != nil:
    section.add "X-Amz-Target", valid_614308
  var valid_614309 = header.getOrDefault("X-Amz-Signature")
  valid_614309 = validateParameter(valid_614309, JString, required = false,
                                 default = nil)
  if valid_614309 != nil:
    section.add "X-Amz-Signature", valid_614309
  var valid_614310 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614310 = validateParameter(valid_614310, JString, required = false,
                                 default = nil)
  if valid_614310 != nil:
    section.add "X-Amz-Content-Sha256", valid_614310
  var valid_614311 = header.getOrDefault("X-Amz-Date")
  valid_614311 = validateParameter(valid_614311, JString, required = false,
                                 default = nil)
  if valid_614311 != nil:
    section.add "X-Amz-Date", valid_614311
  var valid_614312 = header.getOrDefault("X-Amz-Credential")
  valid_614312 = validateParameter(valid_614312, JString, required = false,
                                 default = nil)
  if valid_614312 != nil:
    section.add "X-Amz-Credential", valid_614312
  var valid_614313 = header.getOrDefault("X-Amz-Security-Token")
  valid_614313 = validateParameter(valid_614313, JString, required = false,
                                 default = nil)
  if valid_614313 != nil:
    section.add "X-Amz-Security-Token", valid_614313
  var valid_614314 = header.getOrDefault("X-Amz-Algorithm")
  valid_614314 = validateParameter(valid_614314, JString, required = false,
                                 default = nil)
  if valid_614314 != nil:
    section.add "X-Amz-Algorithm", valid_614314
  var valid_614315 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614315 = validateParameter(valid_614315, JString, required = false,
                                 default = nil)
  if valid_614315 != nil:
    section.add "X-Amz-SignedHeaders", valid_614315
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614317: Call_UpdatePullRequestApprovalRuleContent_614305;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Updates the structure of an approval rule created specifically for a pull request. For example, you can change the number of required approvers and the approval pool for approvers. 
  ## 
  let valid = call_614317.validator(path, query, header, formData, body)
  let scheme = call_614317.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614317.url(scheme.get, call_614317.host, call_614317.base,
                         call_614317.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614317, url, valid)

proc call*(call_614318: Call_UpdatePullRequestApprovalRuleContent_614305;
          body: JsonNode): Recallable =
  ## updatePullRequestApprovalRuleContent
  ## Updates the structure of an approval rule created specifically for a pull request. For example, you can change the number of required approvers and the approval pool for approvers. 
  ##   body: JObject (required)
  var body_614319 = newJObject()
  if body != nil:
    body_614319 = body
  result = call_614318.call(nil, nil, nil, nil, body_614319)

var updatePullRequestApprovalRuleContent* = Call_UpdatePullRequestApprovalRuleContent_614305(
    name: "updatePullRequestApprovalRuleContent", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.UpdatePullRequestApprovalRuleContent",
    validator: validate_UpdatePullRequestApprovalRuleContent_614306, base: "/",
    url: url_UpdatePullRequestApprovalRuleContent_614307,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePullRequestApprovalState_614320 = ref object of OpenApiRestCall_612658
proc url_UpdatePullRequestApprovalState_614322(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdatePullRequestApprovalState_614321(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the state of a user's approval on a pull request. The user is derived from the signed-in account when the request is made.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614323 = header.getOrDefault("X-Amz-Target")
  valid_614323 = validateParameter(valid_614323, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdatePullRequestApprovalState"))
  if valid_614323 != nil:
    section.add "X-Amz-Target", valid_614323
  var valid_614324 = header.getOrDefault("X-Amz-Signature")
  valid_614324 = validateParameter(valid_614324, JString, required = false,
                                 default = nil)
  if valid_614324 != nil:
    section.add "X-Amz-Signature", valid_614324
  var valid_614325 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614325 = validateParameter(valid_614325, JString, required = false,
                                 default = nil)
  if valid_614325 != nil:
    section.add "X-Amz-Content-Sha256", valid_614325
  var valid_614326 = header.getOrDefault("X-Amz-Date")
  valid_614326 = validateParameter(valid_614326, JString, required = false,
                                 default = nil)
  if valid_614326 != nil:
    section.add "X-Amz-Date", valid_614326
  var valid_614327 = header.getOrDefault("X-Amz-Credential")
  valid_614327 = validateParameter(valid_614327, JString, required = false,
                                 default = nil)
  if valid_614327 != nil:
    section.add "X-Amz-Credential", valid_614327
  var valid_614328 = header.getOrDefault("X-Amz-Security-Token")
  valid_614328 = validateParameter(valid_614328, JString, required = false,
                                 default = nil)
  if valid_614328 != nil:
    section.add "X-Amz-Security-Token", valid_614328
  var valid_614329 = header.getOrDefault("X-Amz-Algorithm")
  valid_614329 = validateParameter(valid_614329, JString, required = false,
                                 default = nil)
  if valid_614329 != nil:
    section.add "X-Amz-Algorithm", valid_614329
  var valid_614330 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614330 = validateParameter(valid_614330, JString, required = false,
                                 default = nil)
  if valid_614330 != nil:
    section.add "X-Amz-SignedHeaders", valid_614330
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614332: Call_UpdatePullRequestApprovalState_614320; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the state of a user's approval on a pull request. The user is derived from the signed-in account when the request is made.
  ## 
  let valid = call_614332.validator(path, query, header, formData, body)
  let scheme = call_614332.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614332.url(scheme.get, call_614332.host, call_614332.base,
                         call_614332.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614332, url, valid)

proc call*(call_614333: Call_UpdatePullRequestApprovalState_614320; body: JsonNode): Recallable =
  ## updatePullRequestApprovalState
  ## Updates the state of a user's approval on a pull request. The user is derived from the signed-in account when the request is made.
  ##   body: JObject (required)
  var body_614334 = newJObject()
  if body != nil:
    body_614334 = body
  result = call_614333.call(nil, nil, nil, nil, body_614334)

var updatePullRequestApprovalState* = Call_UpdatePullRequestApprovalState_614320(
    name: "updatePullRequestApprovalState", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UpdatePullRequestApprovalState",
    validator: validate_UpdatePullRequestApprovalState_614321, base: "/",
    url: url_UpdatePullRequestApprovalState_614322,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePullRequestDescription_614335 = ref object of OpenApiRestCall_612658
proc url_UpdatePullRequestDescription_614337(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdatePullRequestDescription_614336(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Replaces the contents of the description of a pull request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614338 = header.getOrDefault("X-Amz-Target")
  valid_614338 = validateParameter(valid_614338, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdatePullRequestDescription"))
  if valid_614338 != nil:
    section.add "X-Amz-Target", valid_614338
  var valid_614339 = header.getOrDefault("X-Amz-Signature")
  valid_614339 = validateParameter(valid_614339, JString, required = false,
                                 default = nil)
  if valid_614339 != nil:
    section.add "X-Amz-Signature", valid_614339
  var valid_614340 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614340 = validateParameter(valid_614340, JString, required = false,
                                 default = nil)
  if valid_614340 != nil:
    section.add "X-Amz-Content-Sha256", valid_614340
  var valid_614341 = header.getOrDefault("X-Amz-Date")
  valid_614341 = validateParameter(valid_614341, JString, required = false,
                                 default = nil)
  if valid_614341 != nil:
    section.add "X-Amz-Date", valid_614341
  var valid_614342 = header.getOrDefault("X-Amz-Credential")
  valid_614342 = validateParameter(valid_614342, JString, required = false,
                                 default = nil)
  if valid_614342 != nil:
    section.add "X-Amz-Credential", valid_614342
  var valid_614343 = header.getOrDefault("X-Amz-Security-Token")
  valid_614343 = validateParameter(valid_614343, JString, required = false,
                                 default = nil)
  if valid_614343 != nil:
    section.add "X-Amz-Security-Token", valid_614343
  var valid_614344 = header.getOrDefault("X-Amz-Algorithm")
  valid_614344 = validateParameter(valid_614344, JString, required = false,
                                 default = nil)
  if valid_614344 != nil:
    section.add "X-Amz-Algorithm", valid_614344
  var valid_614345 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614345 = validateParameter(valid_614345, JString, required = false,
                                 default = nil)
  if valid_614345 != nil:
    section.add "X-Amz-SignedHeaders", valid_614345
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614347: Call_UpdatePullRequestDescription_614335; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Replaces the contents of the description of a pull request.
  ## 
  let valid = call_614347.validator(path, query, header, formData, body)
  let scheme = call_614347.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614347.url(scheme.get, call_614347.host, call_614347.base,
                         call_614347.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614347, url, valid)

proc call*(call_614348: Call_UpdatePullRequestDescription_614335; body: JsonNode): Recallable =
  ## updatePullRequestDescription
  ## Replaces the contents of the description of a pull request.
  ##   body: JObject (required)
  var body_614349 = newJObject()
  if body != nil:
    body_614349 = body
  result = call_614348.call(nil, nil, nil, nil, body_614349)

var updatePullRequestDescription* = Call_UpdatePullRequestDescription_614335(
    name: "updatePullRequestDescription", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UpdatePullRequestDescription",
    validator: validate_UpdatePullRequestDescription_614336, base: "/",
    url: url_UpdatePullRequestDescription_614337,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePullRequestStatus_614350 = ref object of OpenApiRestCall_612658
proc url_UpdatePullRequestStatus_614352(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdatePullRequestStatus_614351(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the status of a pull request. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614353 = header.getOrDefault("X-Amz-Target")
  valid_614353 = validateParameter(valid_614353, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdatePullRequestStatus"))
  if valid_614353 != nil:
    section.add "X-Amz-Target", valid_614353
  var valid_614354 = header.getOrDefault("X-Amz-Signature")
  valid_614354 = validateParameter(valid_614354, JString, required = false,
                                 default = nil)
  if valid_614354 != nil:
    section.add "X-Amz-Signature", valid_614354
  var valid_614355 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614355 = validateParameter(valid_614355, JString, required = false,
                                 default = nil)
  if valid_614355 != nil:
    section.add "X-Amz-Content-Sha256", valid_614355
  var valid_614356 = header.getOrDefault("X-Amz-Date")
  valid_614356 = validateParameter(valid_614356, JString, required = false,
                                 default = nil)
  if valid_614356 != nil:
    section.add "X-Amz-Date", valid_614356
  var valid_614357 = header.getOrDefault("X-Amz-Credential")
  valid_614357 = validateParameter(valid_614357, JString, required = false,
                                 default = nil)
  if valid_614357 != nil:
    section.add "X-Amz-Credential", valid_614357
  var valid_614358 = header.getOrDefault("X-Amz-Security-Token")
  valid_614358 = validateParameter(valid_614358, JString, required = false,
                                 default = nil)
  if valid_614358 != nil:
    section.add "X-Amz-Security-Token", valid_614358
  var valid_614359 = header.getOrDefault("X-Amz-Algorithm")
  valid_614359 = validateParameter(valid_614359, JString, required = false,
                                 default = nil)
  if valid_614359 != nil:
    section.add "X-Amz-Algorithm", valid_614359
  var valid_614360 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614360 = validateParameter(valid_614360, JString, required = false,
                                 default = nil)
  if valid_614360 != nil:
    section.add "X-Amz-SignedHeaders", valid_614360
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614362: Call_UpdatePullRequestStatus_614350; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the status of a pull request. 
  ## 
  let valid = call_614362.validator(path, query, header, formData, body)
  let scheme = call_614362.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614362.url(scheme.get, call_614362.host, call_614362.base,
                         call_614362.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614362, url, valid)

proc call*(call_614363: Call_UpdatePullRequestStatus_614350; body: JsonNode): Recallable =
  ## updatePullRequestStatus
  ## Updates the status of a pull request. 
  ##   body: JObject (required)
  var body_614364 = newJObject()
  if body != nil:
    body_614364 = body
  result = call_614363.call(nil, nil, nil, nil, body_614364)

var updatePullRequestStatus* = Call_UpdatePullRequestStatus_614350(
    name: "updatePullRequestStatus", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UpdatePullRequestStatus",
    validator: validate_UpdatePullRequestStatus_614351, base: "/",
    url: url_UpdatePullRequestStatus_614352, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePullRequestTitle_614365 = ref object of OpenApiRestCall_612658
proc url_UpdatePullRequestTitle_614367(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdatePullRequestTitle_614366(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Replaces the title of a pull request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614368 = header.getOrDefault("X-Amz-Target")
  valid_614368 = validateParameter(valid_614368, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdatePullRequestTitle"))
  if valid_614368 != nil:
    section.add "X-Amz-Target", valid_614368
  var valid_614369 = header.getOrDefault("X-Amz-Signature")
  valid_614369 = validateParameter(valid_614369, JString, required = false,
                                 default = nil)
  if valid_614369 != nil:
    section.add "X-Amz-Signature", valid_614369
  var valid_614370 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614370 = validateParameter(valid_614370, JString, required = false,
                                 default = nil)
  if valid_614370 != nil:
    section.add "X-Amz-Content-Sha256", valid_614370
  var valid_614371 = header.getOrDefault("X-Amz-Date")
  valid_614371 = validateParameter(valid_614371, JString, required = false,
                                 default = nil)
  if valid_614371 != nil:
    section.add "X-Amz-Date", valid_614371
  var valid_614372 = header.getOrDefault("X-Amz-Credential")
  valid_614372 = validateParameter(valid_614372, JString, required = false,
                                 default = nil)
  if valid_614372 != nil:
    section.add "X-Amz-Credential", valid_614372
  var valid_614373 = header.getOrDefault("X-Amz-Security-Token")
  valid_614373 = validateParameter(valid_614373, JString, required = false,
                                 default = nil)
  if valid_614373 != nil:
    section.add "X-Amz-Security-Token", valid_614373
  var valid_614374 = header.getOrDefault("X-Amz-Algorithm")
  valid_614374 = validateParameter(valid_614374, JString, required = false,
                                 default = nil)
  if valid_614374 != nil:
    section.add "X-Amz-Algorithm", valid_614374
  var valid_614375 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614375 = validateParameter(valid_614375, JString, required = false,
                                 default = nil)
  if valid_614375 != nil:
    section.add "X-Amz-SignedHeaders", valid_614375
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614377: Call_UpdatePullRequestTitle_614365; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Replaces the title of a pull request.
  ## 
  let valid = call_614377.validator(path, query, header, formData, body)
  let scheme = call_614377.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614377.url(scheme.get, call_614377.host, call_614377.base,
                         call_614377.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614377, url, valid)

proc call*(call_614378: Call_UpdatePullRequestTitle_614365; body: JsonNode): Recallable =
  ## updatePullRequestTitle
  ## Replaces the title of a pull request.
  ##   body: JObject (required)
  var body_614379 = newJObject()
  if body != nil:
    body_614379 = body
  result = call_614378.call(nil, nil, nil, nil, body_614379)

var updatePullRequestTitle* = Call_UpdatePullRequestTitle_614365(
    name: "updatePullRequestTitle", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UpdatePullRequestTitle",
    validator: validate_UpdatePullRequestTitle_614366, base: "/",
    url: url_UpdatePullRequestTitle_614367, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRepositoryDescription_614380 = ref object of OpenApiRestCall_612658
proc url_UpdateRepositoryDescription_614382(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateRepositoryDescription_614381(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Sets or changes the comment or description for a repository.</p> <note> <p>The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a webpage can expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a webpage.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614383 = header.getOrDefault("X-Amz-Target")
  valid_614383 = validateParameter(valid_614383, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdateRepositoryDescription"))
  if valid_614383 != nil:
    section.add "X-Amz-Target", valid_614383
  var valid_614384 = header.getOrDefault("X-Amz-Signature")
  valid_614384 = validateParameter(valid_614384, JString, required = false,
                                 default = nil)
  if valid_614384 != nil:
    section.add "X-Amz-Signature", valid_614384
  var valid_614385 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614385 = validateParameter(valid_614385, JString, required = false,
                                 default = nil)
  if valid_614385 != nil:
    section.add "X-Amz-Content-Sha256", valid_614385
  var valid_614386 = header.getOrDefault("X-Amz-Date")
  valid_614386 = validateParameter(valid_614386, JString, required = false,
                                 default = nil)
  if valid_614386 != nil:
    section.add "X-Amz-Date", valid_614386
  var valid_614387 = header.getOrDefault("X-Amz-Credential")
  valid_614387 = validateParameter(valid_614387, JString, required = false,
                                 default = nil)
  if valid_614387 != nil:
    section.add "X-Amz-Credential", valid_614387
  var valid_614388 = header.getOrDefault("X-Amz-Security-Token")
  valid_614388 = validateParameter(valid_614388, JString, required = false,
                                 default = nil)
  if valid_614388 != nil:
    section.add "X-Amz-Security-Token", valid_614388
  var valid_614389 = header.getOrDefault("X-Amz-Algorithm")
  valid_614389 = validateParameter(valid_614389, JString, required = false,
                                 default = nil)
  if valid_614389 != nil:
    section.add "X-Amz-Algorithm", valid_614389
  var valid_614390 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614390 = validateParameter(valid_614390, JString, required = false,
                                 default = nil)
  if valid_614390 != nil:
    section.add "X-Amz-SignedHeaders", valid_614390
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614392: Call_UpdateRepositoryDescription_614380; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets or changes the comment or description for a repository.</p> <note> <p>The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a webpage can expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a webpage.</p> </note>
  ## 
  let valid = call_614392.validator(path, query, header, formData, body)
  let scheme = call_614392.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614392.url(scheme.get, call_614392.host, call_614392.base,
                         call_614392.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614392, url, valid)

proc call*(call_614393: Call_UpdateRepositoryDescription_614380; body: JsonNode): Recallable =
  ## updateRepositoryDescription
  ## <p>Sets or changes the comment or description for a repository.</p> <note> <p>The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a webpage can expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a webpage.</p> </note>
  ##   body: JObject (required)
  var body_614394 = newJObject()
  if body != nil:
    body_614394 = body
  result = call_614393.call(nil, nil, nil, nil, body_614394)

var updateRepositoryDescription* = Call_UpdateRepositoryDescription_614380(
    name: "updateRepositoryDescription", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UpdateRepositoryDescription",
    validator: validate_UpdateRepositoryDescription_614381, base: "/",
    url: url_UpdateRepositoryDescription_614382,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRepositoryName_614395 = ref object of OpenApiRestCall_612658
proc url_UpdateRepositoryName_614397(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateRepositoryName_614396(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Renames a repository. The repository name must be unique across the calling AWS account. Repository names are limited to 100 alphanumeric, dash, and underscore characters, and cannot include certain characters. The suffix .git is prohibited. For more information about the limits on repository names, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/limits.html">Limits</a> in the AWS CodeCommit User Guide.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614398 = header.getOrDefault("X-Amz-Target")
  valid_614398 = validateParameter(valid_614398, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdateRepositoryName"))
  if valid_614398 != nil:
    section.add "X-Amz-Target", valid_614398
  var valid_614399 = header.getOrDefault("X-Amz-Signature")
  valid_614399 = validateParameter(valid_614399, JString, required = false,
                                 default = nil)
  if valid_614399 != nil:
    section.add "X-Amz-Signature", valid_614399
  var valid_614400 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614400 = validateParameter(valid_614400, JString, required = false,
                                 default = nil)
  if valid_614400 != nil:
    section.add "X-Amz-Content-Sha256", valid_614400
  var valid_614401 = header.getOrDefault("X-Amz-Date")
  valid_614401 = validateParameter(valid_614401, JString, required = false,
                                 default = nil)
  if valid_614401 != nil:
    section.add "X-Amz-Date", valid_614401
  var valid_614402 = header.getOrDefault("X-Amz-Credential")
  valid_614402 = validateParameter(valid_614402, JString, required = false,
                                 default = nil)
  if valid_614402 != nil:
    section.add "X-Amz-Credential", valid_614402
  var valid_614403 = header.getOrDefault("X-Amz-Security-Token")
  valid_614403 = validateParameter(valid_614403, JString, required = false,
                                 default = nil)
  if valid_614403 != nil:
    section.add "X-Amz-Security-Token", valid_614403
  var valid_614404 = header.getOrDefault("X-Amz-Algorithm")
  valid_614404 = validateParameter(valid_614404, JString, required = false,
                                 default = nil)
  if valid_614404 != nil:
    section.add "X-Amz-Algorithm", valid_614404
  var valid_614405 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614405 = validateParameter(valid_614405, JString, required = false,
                                 default = nil)
  if valid_614405 != nil:
    section.add "X-Amz-SignedHeaders", valid_614405
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614407: Call_UpdateRepositoryName_614395; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Renames a repository. The repository name must be unique across the calling AWS account. Repository names are limited to 100 alphanumeric, dash, and underscore characters, and cannot include certain characters. The suffix .git is prohibited. For more information about the limits on repository names, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/limits.html">Limits</a> in the AWS CodeCommit User Guide.
  ## 
  let valid = call_614407.validator(path, query, header, formData, body)
  let scheme = call_614407.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614407.url(scheme.get, call_614407.host, call_614407.base,
                         call_614407.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614407, url, valid)

proc call*(call_614408: Call_UpdateRepositoryName_614395; body: JsonNode): Recallable =
  ## updateRepositoryName
  ## Renames a repository. The repository name must be unique across the calling AWS account. Repository names are limited to 100 alphanumeric, dash, and underscore characters, and cannot include certain characters. The suffix .git is prohibited. For more information about the limits on repository names, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/limits.html">Limits</a> in the AWS CodeCommit User Guide.
  ##   body: JObject (required)
  var body_614409 = newJObject()
  if body != nil:
    body_614409 = body
  result = call_614408.call(nil, nil, nil, nil, body_614409)

var updateRepositoryName* = Call_UpdateRepositoryName_614395(
    name: "updateRepositoryName", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UpdateRepositoryName",
    validator: validate_UpdateRepositoryName_614396, base: "/",
    url: url_UpdateRepositoryName_614397, schemes: {Scheme.Https, Scheme.Http})
export
  rest

type
  EnvKind = enum
    BakeIntoBinary = "Baking $1 into the binary",
    FetchFromEnv = "Fetch $1 from the environment"
template sloppyConst(via: EnvKind; name: untyped): untyped =
  import
    macros

  const
    name {.strdefine.}: string = case via
    of BakeIntoBinary:
      getEnv(astToStr(name), "")
    of FetchFromEnv:
      ""
  static :
    let msg = block:
      if name == "":
        "Missing $1 in the environment"
      else:
        $via
    warning msg % [astToStr(name)]

sloppyConst FetchFromEnv, AWS_ACCESS_KEY_ID
sloppyConst FetchFromEnv, AWS_SECRET_ACCESS_KEY
sloppyConst BakeIntoBinary, AWS_REGION
sloppyConst FetchFromEnv, AWS_ACCOUNT_ID
proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", AWS_ACCESS_KEY_ID)
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", AWS_SECRET_ACCESS_KEY)
    region = os.getEnv("AWS_REGION", AWS_REGION)
  assert secret != "", "need $AWS_SECRET_ACCESS_KEY in environment"
  assert access != "", "need $AWS_ACCESS_KEY_ID in environment"
  assert region != "", "need $AWS_REGION in environment"
  var
    normal: PathNormal
    url = normalizeUrl(recall.url, query, normalize = normal)
    scheme = parseEnum[Scheme](url.scheme)
  assert scheme in awsServers, "unknown scheme `" & $scheme & "`"
  assert region in awsServers[scheme], "unknown region `" & region & "`"
  url.hostname = awsServers[scheme][region]
  case awsServiceName.toLowerAscii
  of "s3":
    normal = PathNormal.S3
  else:
    normal = PathNormal.Default
  recall.headers["Host"] = url.hostname
  recall.headers["X-Amz-Date"] = date
  let
    algo = SHA256
    scope = credentialScope(region = region, service = awsServiceName, date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers, recall.body,
                             normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date, region = region,
                                 service = awsServiceName, sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  recall.headers.del "Host"
  recall.url = $url

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  ## the hook is a terrible earworm
  var headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
  let
    body = input.getOrDefault("body")
    text = if body == nil:
      "" elif body.kind == JString:
      body.getStr else:
      $body
  if body != nil and body.kind != JString:
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  const
    XAmzSecurityToken = "X-Amz-Security-Token"
  if not headers.hasKey(XAmzSecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[XAmzSecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
