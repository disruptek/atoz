
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Simple Systems Manager (SSM)
## version: 2014-11-06
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS Systems Manager</fullname> <p>AWS Systems Manager is a collection of capabilities that helps you automate management tasks such as collecting system inventory, applying operating system (OS) patches, automating the creation of Amazon Machine Images (AMIs), and configuring operating systems (OSs) and applications at scale. Systems Manager lets you remotely and securely manage the configuration of your managed instances. A <i>managed instance</i> is any Amazon EC2 instance or on-premises machine in your hybrid environment that has been configured for Systems Manager.</p> <p>This reference is intended to be used with the <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/">AWS Systems Manager User Guide</a>.</p> <p>To get started, verify prerequisites and configure managed instances. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-setting-up.html">Setting Up AWS Systems Manager</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>For information about other API actions you can perform on Amazon EC2 instances, see the <a href="http://docs.aws.amazon.com/AWSEC2/latest/APIReference/">Amazon EC2 API Reference</a>. For information about how to use a Query API, see <a href="http://docs.aws.amazon.com/AWSEC2/latest/APIReference/making-api-requests.html">Making API Requests</a>. </p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/ssm/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "ssm.ap-northeast-1.amazonaws.com", "ap-southeast-1": "ssm.ap-southeast-1.amazonaws.com",
                           "us-west-2": "ssm.us-west-2.amazonaws.com",
                           "eu-west-2": "ssm.eu-west-2.amazonaws.com", "ap-northeast-3": "ssm.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "ssm.eu-central-1.amazonaws.com",
                           "us-east-2": "ssm.us-east-2.amazonaws.com",
                           "us-east-1": "ssm.us-east-1.amazonaws.com", "cn-northwest-1": "ssm.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "ssm.ap-south-1.amazonaws.com",
                           "eu-north-1": "ssm.eu-north-1.amazonaws.com", "ap-northeast-2": "ssm.ap-northeast-2.amazonaws.com",
                           "us-west-1": "ssm.us-west-1.amazonaws.com",
                           "us-gov-east-1": "ssm.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "ssm.eu-west-3.amazonaws.com",
                           "cn-north-1": "ssm.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "ssm.sa-east-1.amazonaws.com",
                           "eu-west-1": "ssm.eu-west-1.amazonaws.com",
                           "us-gov-west-1": "ssm.us-gov-west-1.amazonaws.com", "ap-southeast-2": "ssm.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "ssm.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "ssm.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "ssm.ap-southeast-1.amazonaws.com",
      "us-west-2": "ssm.us-west-2.amazonaws.com",
      "eu-west-2": "ssm.eu-west-2.amazonaws.com",
      "ap-northeast-3": "ssm.ap-northeast-3.amazonaws.com",
      "eu-central-1": "ssm.eu-central-1.amazonaws.com",
      "us-east-2": "ssm.us-east-2.amazonaws.com",
      "us-east-1": "ssm.us-east-1.amazonaws.com",
      "cn-northwest-1": "ssm.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "ssm.ap-south-1.amazonaws.com",
      "eu-north-1": "ssm.eu-north-1.amazonaws.com",
      "ap-northeast-2": "ssm.ap-northeast-2.amazonaws.com",
      "us-west-1": "ssm.us-west-1.amazonaws.com",
      "us-gov-east-1": "ssm.us-gov-east-1.amazonaws.com",
      "eu-west-3": "ssm.eu-west-3.amazonaws.com",
      "cn-north-1": "ssm.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "ssm.sa-east-1.amazonaws.com",
      "eu-west-1": "ssm.eu-west-1.amazonaws.com",
      "us-gov-west-1": "ssm.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "ssm.ap-southeast-2.amazonaws.com",
      "ca-central-1": "ssm.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "ssm"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AddTagsToResource_612996 = ref object of OpenApiRestCall_612658
proc url_AddTagsToResource_612998(protocol: Scheme; host: string; base: string;
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

proc validate_AddTagsToResource_612997(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Adds or overwrites one or more tags for the specified resource. Tags are metadata that you can assign to your documents, managed instances, maintenance windows, Parameter Store parameters, and patch baselines. Tags enable you to categorize your resources in different ways, for example, by purpose, owner, or environment. Each tag consists of a key and an optional value, both of which you define. For example, you could define a set of tags for your account's managed instances that helps you track each instance's owner and stack level. For example: Key=Owner and Value=DbAdmin, SysAdmin, or Dev. Or Key=Stack and Value=Production, Pre-Production, or Test.</p> <p>Each resource can have a maximum of 50 tags. </p> <p>We recommend that you devise a set of tag keys that meets your needs for each resource type. Using a consistent set of tag keys makes it easier for you to manage your resources. You can search and filter the resources based on the tags you add. Tags don't have any semantic meaning to Amazon EC2 and are interpreted strictly as a string of characters. </p> <p>For more information about tags, see <a href="http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Using_Tags.html">Tagging Your Amazon EC2 Resources</a> in the <i>Amazon EC2 User Guide</i>.</p>
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
      "AmazonSSM.AddTagsToResource"))
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

proc call*(call_613154: Call_AddTagsToResource_612996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds or overwrites one or more tags for the specified resource. Tags are metadata that you can assign to your documents, managed instances, maintenance windows, Parameter Store parameters, and patch baselines. Tags enable you to categorize your resources in different ways, for example, by purpose, owner, or environment. Each tag consists of a key and an optional value, both of which you define. For example, you could define a set of tags for your account's managed instances that helps you track each instance's owner and stack level. For example: Key=Owner and Value=DbAdmin, SysAdmin, or Dev. Or Key=Stack and Value=Production, Pre-Production, or Test.</p> <p>Each resource can have a maximum of 50 tags. </p> <p>We recommend that you devise a set of tag keys that meets your needs for each resource type. Using a consistent set of tag keys makes it easier for you to manage your resources. You can search and filter the resources based on the tags you add. Tags don't have any semantic meaning to Amazon EC2 and are interpreted strictly as a string of characters. </p> <p>For more information about tags, see <a href="http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Using_Tags.html">Tagging Your Amazon EC2 Resources</a> in the <i>Amazon EC2 User Guide</i>.</p>
  ## 
  let valid = call_613154.validator(path, query, header, formData, body)
  let scheme = call_613154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613154.url(scheme.get, call_613154.host, call_613154.base,
                         call_613154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613154, url, valid)

proc call*(call_613225: Call_AddTagsToResource_612996; body: JsonNode): Recallable =
  ## addTagsToResource
  ## <p>Adds or overwrites one or more tags for the specified resource. Tags are metadata that you can assign to your documents, managed instances, maintenance windows, Parameter Store parameters, and patch baselines. Tags enable you to categorize your resources in different ways, for example, by purpose, owner, or environment. Each tag consists of a key and an optional value, both of which you define. For example, you could define a set of tags for your account's managed instances that helps you track each instance's owner and stack level. For example: Key=Owner and Value=DbAdmin, SysAdmin, or Dev. Or Key=Stack and Value=Production, Pre-Production, or Test.</p> <p>Each resource can have a maximum of 50 tags. </p> <p>We recommend that you devise a set of tag keys that meets your needs for each resource type. Using a consistent set of tag keys makes it easier for you to manage your resources. You can search and filter the resources based on the tags you add. Tags don't have any semantic meaning to Amazon EC2 and are interpreted strictly as a string of characters. </p> <p>For more information about tags, see <a href="http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Using_Tags.html">Tagging Your Amazon EC2 Resources</a> in the <i>Amazon EC2 User Guide</i>.</p>
  ##   body: JObject (required)
  var body_613226 = newJObject()
  if body != nil:
    body_613226 = body
  result = call_613225.call(nil, nil, nil, nil, body_613226)

var addTagsToResource* = Call_AddTagsToResource_612996(name: "addTagsToResource",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.AddTagsToResource",
    validator: validate_AddTagsToResource_612997, base: "/",
    url: url_AddTagsToResource_612998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelCommand_613265 = ref object of OpenApiRestCall_612658
proc url_CancelCommand_613267(protocol: Scheme; host: string; base: string;
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

proc validate_CancelCommand_613266(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Attempts to cancel the command specified by the Command ID. There is no guarantee that the command will be terminated and the underlying process stopped.
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
      "AmazonSSM.CancelCommand"))
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

proc call*(call_613277: Call_CancelCommand_613265; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attempts to cancel the command specified by the Command ID. There is no guarantee that the command will be terminated and the underlying process stopped.
  ## 
  let valid = call_613277.validator(path, query, header, formData, body)
  let scheme = call_613277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613277.url(scheme.get, call_613277.host, call_613277.base,
                         call_613277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613277, url, valid)

proc call*(call_613278: Call_CancelCommand_613265; body: JsonNode): Recallable =
  ## cancelCommand
  ## Attempts to cancel the command specified by the Command ID. There is no guarantee that the command will be terminated and the underlying process stopped.
  ##   body: JObject (required)
  var body_613279 = newJObject()
  if body != nil:
    body_613279 = body
  result = call_613278.call(nil, nil, nil, nil, body_613279)

var cancelCommand* = Call_CancelCommand_613265(name: "cancelCommand",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CancelCommand",
    validator: validate_CancelCommand_613266, base: "/", url: url_CancelCommand_613267,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelMaintenanceWindowExecution_613280 = ref object of OpenApiRestCall_612658
proc url_CancelMaintenanceWindowExecution_613282(protocol: Scheme; host: string;
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

proc validate_CancelMaintenanceWindowExecution_613281(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Stops a maintenance window execution that is already in progress and cancels any tasks in the window that have not already starting running. (Tasks already in progress will continue to completion.)
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
      "AmazonSSM.CancelMaintenanceWindowExecution"))
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

proc call*(call_613292: Call_CancelMaintenanceWindowExecution_613280;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Stops a maintenance window execution that is already in progress and cancels any tasks in the window that have not already starting running. (Tasks already in progress will continue to completion.)
  ## 
  let valid = call_613292.validator(path, query, header, formData, body)
  let scheme = call_613292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613292.url(scheme.get, call_613292.host, call_613292.base,
                         call_613292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613292, url, valid)

proc call*(call_613293: Call_CancelMaintenanceWindowExecution_613280;
          body: JsonNode): Recallable =
  ## cancelMaintenanceWindowExecution
  ## Stops a maintenance window execution that is already in progress and cancels any tasks in the window that have not already starting running. (Tasks already in progress will continue to completion.)
  ##   body: JObject (required)
  var body_613294 = newJObject()
  if body != nil:
    body_613294 = body
  result = call_613293.call(nil, nil, nil, nil, body_613294)

var cancelMaintenanceWindowExecution* = Call_CancelMaintenanceWindowExecution_613280(
    name: "cancelMaintenanceWindowExecution", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CancelMaintenanceWindowExecution",
    validator: validate_CancelMaintenanceWindowExecution_613281, base: "/",
    url: url_CancelMaintenanceWindowExecution_613282,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateActivation_613295 = ref object of OpenApiRestCall_612658
proc url_CreateActivation_613297(protocol: Scheme; host: string; base: string;
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

proc validate_CreateActivation_613296(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Generates an activation code and activation ID you can use to register your on-premises server or virtual machine (VM) with Systems Manager. Registering these machines with Systems Manager makes it possible to manage them using Systems Manager capabilities. You use the activation code and ID when installing SSM Agent on machines in your hybrid environment. For more information about requirements for managing on-premises instances and VMs using Systems Manager, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-managedinstances.html">Setting Up AWS Systems Manager for Hybrid Environments</a> in the <i>AWS Systems Manager User Guide</i>. </p> <note> <p>On-premises servers or VMs that are registered with Systems Manager and Amazon EC2 instances that you manage with Systems Manager are all called <i>managed instances</i>.</p> </note>
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
  valid_613298 = validateParameter(valid_613298, JString, required = true, default = newJString(
      "AmazonSSM.CreateActivation"))
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

proc call*(call_613307: Call_CreateActivation_613295; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Generates an activation code and activation ID you can use to register your on-premises server or virtual machine (VM) with Systems Manager. Registering these machines with Systems Manager makes it possible to manage them using Systems Manager capabilities. You use the activation code and ID when installing SSM Agent on machines in your hybrid environment. For more information about requirements for managing on-premises instances and VMs using Systems Manager, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-managedinstances.html">Setting Up AWS Systems Manager for Hybrid Environments</a> in the <i>AWS Systems Manager User Guide</i>. </p> <note> <p>On-premises servers or VMs that are registered with Systems Manager and Amazon EC2 instances that you manage with Systems Manager are all called <i>managed instances</i>.</p> </note>
  ## 
  let valid = call_613307.validator(path, query, header, formData, body)
  let scheme = call_613307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613307.url(scheme.get, call_613307.host, call_613307.base,
                         call_613307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613307, url, valid)

proc call*(call_613308: Call_CreateActivation_613295; body: JsonNode): Recallable =
  ## createActivation
  ## <p>Generates an activation code and activation ID you can use to register your on-premises server or virtual machine (VM) with Systems Manager. Registering these machines with Systems Manager makes it possible to manage them using Systems Manager capabilities. You use the activation code and ID when installing SSM Agent on machines in your hybrid environment. For more information about requirements for managing on-premises instances and VMs using Systems Manager, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-managedinstances.html">Setting Up AWS Systems Manager for Hybrid Environments</a> in the <i>AWS Systems Manager User Guide</i>. </p> <note> <p>On-premises servers or VMs that are registered with Systems Manager and Amazon EC2 instances that you manage with Systems Manager are all called <i>managed instances</i>.</p> </note>
  ##   body: JObject (required)
  var body_613309 = newJObject()
  if body != nil:
    body_613309 = body
  result = call_613308.call(nil, nil, nil, nil, body_613309)

var createActivation* = Call_CreateActivation_613295(name: "createActivation",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateActivation",
    validator: validate_CreateActivation_613296, base: "/",
    url: url_CreateActivation_613297, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAssociation_613310 = ref object of OpenApiRestCall_612658
proc url_CreateAssociation_613312(protocol: Scheme; host: string; base: string;
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

proc validate_CreateAssociation_613311(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Associates the specified Systems Manager document with the specified instances or targets.</p> <p>When you associate a document with one or more instances using instance IDs or tags, SSM Agent running on the instance processes the document and configures the instance as specified.</p> <p>If you associate a document with an instance that already has an associated document, the system returns the AssociationAlreadyExists exception.</p>
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
      "AmazonSSM.CreateAssociation"))
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

proc call*(call_613322: Call_CreateAssociation_613310; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates the specified Systems Manager document with the specified instances or targets.</p> <p>When you associate a document with one or more instances using instance IDs or tags, SSM Agent running on the instance processes the document and configures the instance as specified.</p> <p>If you associate a document with an instance that already has an associated document, the system returns the AssociationAlreadyExists exception.</p>
  ## 
  let valid = call_613322.validator(path, query, header, formData, body)
  let scheme = call_613322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613322.url(scheme.get, call_613322.host, call_613322.base,
                         call_613322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613322, url, valid)

proc call*(call_613323: Call_CreateAssociation_613310; body: JsonNode): Recallable =
  ## createAssociation
  ## <p>Associates the specified Systems Manager document with the specified instances or targets.</p> <p>When you associate a document with one or more instances using instance IDs or tags, SSM Agent running on the instance processes the document and configures the instance as specified.</p> <p>If you associate a document with an instance that already has an associated document, the system returns the AssociationAlreadyExists exception.</p>
  ##   body: JObject (required)
  var body_613324 = newJObject()
  if body != nil:
    body_613324 = body
  result = call_613323.call(nil, nil, nil, nil, body_613324)

var createAssociation* = Call_CreateAssociation_613310(name: "createAssociation",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateAssociation",
    validator: validate_CreateAssociation_613311, base: "/",
    url: url_CreateAssociation_613312, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAssociationBatch_613325 = ref object of OpenApiRestCall_612658
proc url_CreateAssociationBatch_613327(protocol: Scheme; host: string; base: string;
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

proc validate_CreateAssociationBatch_613326(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Associates the specified Systems Manager document with the specified instances or targets.</p> <p>When you associate a document with one or more instances using instance IDs or tags, SSM Agent running on the instance processes the document and configures the instance as specified.</p> <p>If you associate a document with an instance that already has an associated document, the system returns the AssociationAlreadyExists exception.</p>
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
      "AmazonSSM.CreateAssociationBatch"))
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

proc call*(call_613337: Call_CreateAssociationBatch_613325; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates the specified Systems Manager document with the specified instances or targets.</p> <p>When you associate a document with one or more instances using instance IDs or tags, SSM Agent running on the instance processes the document and configures the instance as specified.</p> <p>If you associate a document with an instance that already has an associated document, the system returns the AssociationAlreadyExists exception.</p>
  ## 
  let valid = call_613337.validator(path, query, header, formData, body)
  let scheme = call_613337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613337.url(scheme.get, call_613337.host, call_613337.base,
                         call_613337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613337, url, valid)

proc call*(call_613338: Call_CreateAssociationBatch_613325; body: JsonNode): Recallable =
  ## createAssociationBatch
  ## <p>Associates the specified Systems Manager document with the specified instances or targets.</p> <p>When you associate a document with one or more instances using instance IDs or tags, SSM Agent running on the instance processes the document and configures the instance as specified.</p> <p>If you associate a document with an instance that already has an associated document, the system returns the AssociationAlreadyExists exception.</p>
  ##   body: JObject (required)
  var body_613339 = newJObject()
  if body != nil:
    body_613339 = body
  result = call_613338.call(nil, nil, nil, nil, body_613339)

var createAssociationBatch* = Call_CreateAssociationBatch_613325(
    name: "createAssociationBatch", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateAssociationBatch",
    validator: validate_CreateAssociationBatch_613326, base: "/",
    url: url_CreateAssociationBatch_613327, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDocument_613340 = ref object of OpenApiRestCall_612658
proc url_CreateDocument_613342(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDocument_613341(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Creates a Systems Manager document.</p> <p>After you create a document, you can use CreateAssociation to associate it with one or more running instances.</p>
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
      "AmazonSSM.CreateDocument"))
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

proc call*(call_613352: Call_CreateDocument_613340; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Systems Manager document.</p> <p>After you create a document, you can use CreateAssociation to associate it with one or more running instances.</p>
  ## 
  let valid = call_613352.validator(path, query, header, formData, body)
  let scheme = call_613352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613352.url(scheme.get, call_613352.host, call_613352.base,
                         call_613352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613352, url, valid)

proc call*(call_613353: Call_CreateDocument_613340; body: JsonNode): Recallable =
  ## createDocument
  ## <p>Creates a Systems Manager document.</p> <p>After you create a document, you can use CreateAssociation to associate it with one or more running instances.</p>
  ##   body: JObject (required)
  var body_613354 = newJObject()
  if body != nil:
    body_613354 = body
  result = call_613353.call(nil, nil, nil, nil, body_613354)

var createDocument* = Call_CreateDocument_613340(name: "createDocument",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateDocument",
    validator: validate_CreateDocument_613341, base: "/", url: url_CreateDocument_613342,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMaintenanceWindow_613355 = ref object of OpenApiRestCall_612658
proc url_CreateMaintenanceWindow_613357(protocol: Scheme; host: string; base: string;
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

proc validate_CreateMaintenanceWindow_613356(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new maintenance window.</p> <note> <p>The value you specify for <code>Duration</code> determines the specific end time for the maintenance window based on the time it begins. No maintenance window tasks are permitted to start after the resulting endtime minus the number of hours you specify for <code>Cutoff</code>. For example, if the maintenance window starts at 3 PM, the duration is three hours, and the value you specify for <code>Cutoff</code> is one hour, no maintenance window tasks can start after 5 PM.</p> </note>
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
      "AmazonSSM.CreateMaintenanceWindow"))
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

proc call*(call_613367: Call_CreateMaintenanceWindow_613355; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new maintenance window.</p> <note> <p>The value you specify for <code>Duration</code> determines the specific end time for the maintenance window based on the time it begins. No maintenance window tasks are permitted to start after the resulting endtime minus the number of hours you specify for <code>Cutoff</code>. For example, if the maintenance window starts at 3 PM, the duration is three hours, and the value you specify for <code>Cutoff</code> is one hour, no maintenance window tasks can start after 5 PM.</p> </note>
  ## 
  let valid = call_613367.validator(path, query, header, formData, body)
  let scheme = call_613367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613367.url(scheme.get, call_613367.host, call_613367.base,
                         call_613367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613367, url, valid)

proc call*(call_613368: Call_CreateMaintenanceWindow_613355; body: JsonNode): Recallable =
  ## createMaintenanceWindow
  ## <p>Creates a new maintenance window.</p> <note> <p>The value you specify for <code>Duration</code> determines the specific end time for the maintenance window based on the time it begins. No maintenance window tasks are permitted to start after the resulting endtime minus the number of hours you specify for <code>Cutoff</code>. For example, if the maintenance window starts at 3 PM, the duration is three hours, and the value you specify for <code>Cutoff</code> is one hour, no maintenance window tasks can start after 5 PM.</p> </note>
  ##   body: JObject (required)
  var body_613369 = newJObject()
  if body != nil:
    body_613369 = body
  result = call_613368.call(nil, nil, nil, nil, body_613369)

var createMaintenanceWindow* = Call_CreateMaintenanceWindow_613355(
    name: "createMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateMaintenanceWindow",
    validator: validate_CreateMaintenanceWindow_613356, base: "/",
    url: url_CreateMaintenanceWindow_613357, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateOpsItem_613370 = ref object of OpenApiRestCall_612658
proc url_CreateOpsItem_613372(protocol: Scheme; host: string; base: string;
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

proc validate_CreateOpsItem_613371(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new OpsItem. You must have permission in AWS Identity and Access Management (IAM) to create a new OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
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
      "AmazonSSM.CreateOpsItem"))
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

proc call*(call_613382: Call_CreateOpsItem_613370; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new OpsItem. You must have permission in AWS Identity and Access Management (IAM) to create a new OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ## 
  let valid = call_613382.validator(path, query, header, formData, body)
  let scheme = call_613382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613382.url(scheme.get, call_613382.host, call_613382.base,
                         call_613382.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613382, url, valid)

proc call*(call_613383: Call_CreateOpsItem_613370; body: JsonNode): Recallable =
  ## createOpsItem
  ## <p>Creates a new OpsItem. You must have permission in AWS Identity and Access Management (IAM) to create a new OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ##   body: JObject (required)
  var body_613384 = newJObject()
  if body != nil:
    body_613384 = body
  result = call_613383.call(nil, nil, nil, nil, body_613384)

var createOpsItem* = Call_CreateOpsItem_613370(name: "createOpsItem",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateOpsItem",
    validator: validate_CreateOpsItem_613371, base: "/", url: url_CreateOpsItem_613372,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePatchBaseline_613385 = ref object of OpenApiRestCall_612658
proc url_CreatePatchBaseline_613387(protocol: Scheme; host: string; base: string;
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

proc validate_CreatePatchBaseline_613386(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Creates a patch baseline.</p> <note> <p>For information about valid key and value pairs in <code>PatchFilters</code> for each supported operating system type, see <a href="http://docs.aws.amazon.com/systems-manager/latest/APIReference/API_PatchFilter.html">PatchFilter</a>.</p> </note>
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
      "AmazonSSM.CreatePatchBaseline"))
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

proc call*(call_613397: Call_CreatePatchBaseline_613385; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a patch baseline.</p> <note> <p>For information about valid key and value pairs in <code>PatchFilters</code> for each supported operating system type, see <a href="http://docs.aws.amazon.com/systems-manager/latest/APIReference/API_PatchFilter.html">PatchFilter</a>.</p> </note>
  ## 
  let valid = call_613397.validator(path, query, header, formData, body)
  let scheme = call_613397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613397.url(scheme.get, call_613397.host, call_613397.base,
                         call_613397.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613397, url, valid)

proc call*(call_613398: Call_CreatePatchBaseline_613385; body: JsonNode): Recallable =
  ## createPatchBaseline
  ## <p>Creates a patch baseline.</p> <note> <p>For information about valid key and value pairs in <code>PatchFilters</code> for each supported operating system type, see <a href="http://docs.aws.amazon.com/systems-manager/latest/APIReference/API_PatchFilter.html">PatchFilter</a>.</p> </note>
  ##   body: JObject (required)
  var body_613399 = newJObject()
  if body != nil:
    body_613399 = body
  result = call_613398.call(nil, nil, nil, nil, body_613399)

var createPatchBaseline* = Call_CreatePatchBaseline_613385(
    name: "createPatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreatePatchBaseline",
    validator: validate_CreatePatchBaseline_613386, base: "/",
    url: url_CreatePatchBaseline_613387, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResourceDataSync_613400 = ref object of OpenApiRestCall_612658
proc url_CreateResourceDataSync_613402(protocol: Scheme; host: string; base: string;
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

proc validate_CreateResourceDataSync_613401(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>A resource data sync helps you view data from multiple sources in a single location. Systems Manager offers two types of resource data sync: <code>SyncToDestination</code> and <code>SyncFromSource</code>.</p> <p>You can configure Systems Manager Inventory to use the <code>SyncToDestination</code> type to synchronize Inventory data from multiple AWS Regions to a single Amazon S3 bucket. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-inventory-datasync.html">Configuring Resource Data Sync for Inventory</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>You can configure Systems Manager Explorer to use the <code>SyncFromSource</code> type to synchronize operational work items (OpsItems) and operational data (OpsData) from multiple AWS Regions to a single Amazon S3 bucket. This type can synchronize OpsItems and OpsData from multiple AWS accounts and Regions or <code>EntireOrganization</code> by using AWS Organizations. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/Explorer-resource-data-sync.html">Setting Up Explorer to Display Data from Multiple Accounts and Regions</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>A resource data sync is an asynchronous operation that returns immediately. After a successful initial sync is completed, the system continuously syncs data. To check the status of a sync, use the <a>ListResourceDataSync</a>.</p> <note> <p>By default, data is not encrypted in Amazon S3. We strongly recommend that you enable encryption in Amazon S3 to ensure secure data storage. We also recommend that you secure access to the Amazon S3 bucket by creating a restrictive bucket policy. </p> </note>
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
      "AmazonSSM.CreateResourceDataSync"))
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

proc call*(call_613412: Call_CreateResourceDataSync_613400; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>A resource data sync helps you view data from multiple sources in a single location. Systems Manager offers two types of resource data sync: <code>SyncToDestination</code> and <code>SyncFromSource</code>.</p> <p>You can configure Systems Manager Inventory to use the <code>SyncToDestination</code> type to synchronize Inventory data from multiple AWS Regions to a single Amazon S3 bucket. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-inventory-datasync.html">Configuring Resource Data Sync for Inventory</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>You can configure Systems Manager Explorer to use the <code>SyncFromSource</code> type to synchronize operational work items (OpsItems) and operational data (OpsData) from multiple AWS Regions to a single Amazon S3 bucket. This type can synchronize OpsItems and OpsData from multiple AWS accounts and Regions or <code>EntireOrganization</code> by using AWS Organizations. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/Explorer-resource-data-sync.html">Setting Up Explorer to Display Data from Multiple Accounts and Regions</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>A resource data sync is an asynchronous operation that returns immediately. After a successful initial sync is completed, the system continuously syncs data. To check the status of a sync, use the <a>ListResourceDataSync</a>.</p> <note> <p>By default, data is not encrypted in Amazon S3. We strongly recommend that you enable encryption in Amazon S3 to ensure secure data storage. We also recommend that you secure access to the Amazon S3 bucket by creating a restrictive bucket policy. </p> </note>
  ## 
  let valid = call_613412.validator(path, query, header, formData, body)
  let scheme = call_613412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613412.url(scheme.get, call_613412.host, call_613412.base,
                         call_613412.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613412, url, valid)

proc call*(call_613413: Call_CreateResourceDataSync_613400; body: JsonNode): Recallable =
  ## createResourceDataSync
  ## <p>A resource data sync helps you view data from multiple sources in a single location. Systems Manager offers two types of resource data sync: <code>SyncToDestination</code> and <code>SyncFromSource</code>.</p> <p>You can configure Systems Manager Inventory to use the <code>SyncToDestination</code> type to synchronize Inventory data from multiple AWS Regions to a single Amazon S3 bucket. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-inventory-datasync.html">Configuring Resource Data Sync for Inventory</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>You can configure Systems Manager Explorer to use the <code>SyncFromSource</code> type to synchronize operational work items (OpsItems) and operational data (OpsData) from multiple AWS Regions to a single Amazon S3 bucket. This type can synchronize OpsItems and OpsData from multiple AWS accounts and Regions or <code>EntireOrganization</code> by using AWS Organizations. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/Explorer-resource-data-sync.html">Setting Up Explorer to Display Data from Multiple Accounts and Regions</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>A resource data sync is an asynchronous operation that returns immediately. After a successful initial sync is completed, the system continuously syncs data. To check the status of a sync, use the <a>ListResourceDataSync</a>.</p> <note> <p>By default, data is not encrypted in Amazon S3. We strongly recommend that you enable encryption in Amazon S3 to ensure secure data storage. We also recommend that you secure access to the Amazon S3 bucket by creating a restrictive bucket policy. </p> </note>
  ##   body: JObject (required)
  var body_613414 = newJObject()
  if body != nil:
    body_613414 = body
  result = call_613413.call(nil, nil, nil, nil, body_613414)

var createResourceDataSync* = Call_CreateResourceDataSync_613400(
    name: "createResourceDataSync", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateResourceDataSync",
    validator: validate_CreateResourceDataSync_613401, base: "/",
    url: url_CreateResourceDataSync_613402, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteActivation_613415 = ref object of OpenApiRestCall_612658
proc url_DeleteActivation_613417(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteActivation_613416(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Deletes an activation. You are not required to delete an activation. If you delete an activation, you can no longer use it to register additional managed instances. Deleting an activation does not de-register managed instances. You must manually de-register managed instances.
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
      "AmazonSSM.DeleteActivation"))
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

proc call*(call_613427: Call_DeleteActivation_613415; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an activation. You are not required to delete an activation. If you delete an activation, you can no longer use it to register additional managed instances. Deleting an activation does not de-register managed instances. You must manually de-register managed instances.
  ## 
  let valid = call_613427.validator(path, query, header, formData, body)
  let scheme = call_613427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613427.url(scheme.get, call_613427.host, call_613427.base,
                         call_613427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613427, url, valid)

proc call*(call_613428: Call_DeleteActivation_613415; body: JsonNode): Recallable =
  ## deleteActivation
  ## Deletes an activation. You are not required to delete an activation. If you delete an activation, you can no longer use it to register additional managed instances. Deleting an activation does not de-register managed instances. You must manually de-register managed instances.
  ##   body: JObject (required)
  var body_613429 = newJObject()
  if body != nil:
    body_613429 = body
  result = call_613428.call(nil, nil, nil, nil, body_613429)

var deleteActivation* = Call_DeleteActivation_613415(name: "deleteActivation",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteActivation",
    validator: validate_DeleteActivation_613416, base: "/",
    url: url_DeleteActivation_613417, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAssociation_613430 = ref object of OpenApiRestCall_612658
proc url_DeleteAssociation_613432(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAssociation_613431(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Disassociates the specified Systems Manager document from the specified instance.</p> <p>When you disassociate a document from an instance, it does not change the configuration of the instance. To change the configuration state of an instance after you disassociate a document, you must create a new document with the desired configuration and associate it with the instance.</p>
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
      "AmazonSSM.DeleteAssociation"))
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

proc call*(call_613442: Call_DeleteAssociation_613430; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disassociates the specified Systems Manager document from the specified instance.</p> <p>When you disassociate a document from an instance, it does not change the configuration of the instance. To change the configuration state of an instance after you disassociate a document, you must create a new document with the desired configuration and associate it with the instance.</p>
  ## 
  let valid = call_613442.validator(path, query, header, formData, body)
  let scheme = call_613442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613442.url(scheme.get, call_613442.host, call_613442.base,
                         call_613442.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613442, url, valid)

proc call*(call_613443: Call_DeleteAssociation_613430; body: JsonNode): Recallable =
  ## deleteAssociation
  ## <p>Disassociates the specified Systems Manager document from the specified instance.</p> <p>When you disassociate a document from an instance, it does not change the configuration of the instance. To change the configuration state of an instance after you disassociate a document, you must create a new document with the desired configuration and associate it with the instance.</p>
  ##   body: JObject (required)
  var body_613444 = newJObject()
  if body != nil:
    body_613444 = body
  result = call_613443.call(nil, nil, nil, nil, body_613444)

var deleteAssociation* = Call_DeleteAssociation_613430(name: "deleteAssociation",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteAssociation",
    validator: validate_DeleteAssociation_613431, base: "/",
    url: url_DeleteAssociation_613432, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDocument_613445 = ref object of OpenApiRestCall_612658
proc url_DeleteDocument_613447(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDocument_613446(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Deletes the Systems Manager document and all instance associations to the document.</p> <p>Before you delete the document, we recommend that you use <a>DeleteAssociation</a> to disassociate all instances that are associated with the document.</p>
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
      "AmazonSSM.DeleteDocument"))
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

proc call*(call_613457: Call_DeleteDocument_613445; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the Systems Manager document and all instance associations to the document.</p> <p>Before you delete the document, we recommend that you use <a>DeleteAssociation</a> to disassociate all instances that are associated with the document.</p>
  ## 
  let valid = call_613457.validator(path, query, header, formData, body)
  let scheme = call_613457.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613457.url(scheme.get, call_613457.host, call_613457.base,
                         call_613457.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613457, url, valid)

proc call*(call_613458: Call_DeleteDocument_613445; body: JsonNode): Recallable =
  ## deleteDocument
  ## <p>Deletes the Systems Manager document and all instance associations to the document.</p> <p>Before you delete the document, we recommend that you use <a>DeleteAssociation</a> to disassociate all instances that are associated with the document.</p>
  ##   body: JObject (required)
  var body_613459 = newJObject()
  if body != nil:
    body_613459 = body
  result = call_613458.call(nil, nil, nil, nil, body_613459)

var deleteDocument* = Call_DeleteDocument_613445(name: "deleteDocument",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteDocument",
    validator: validate_DeleteDocument_613446, base: "/", url: url_DeleteDocument_613447,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInventory_613460 = ref object of OpenApiRestCall_612658
proc url_DeleteInventory_613462(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteInventory_613461(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Delete a custom inventory type, or the data associated with a custom Inventory type. Deleting a custom inventory type is also referred to as deleting a custom inventory schema.
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
      "AmazonSSM.DeleteInventory"))
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

proc call*(call_613472: Call_DeleteInventory_613460; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a custom inventory type, or the data associated with a custom Inventory type. Deleting a custom inventory type is also referred to as deleting a custom inventory schema.
  ## 
  let valid = call_613472.validator(path, query, header, formData, body)
  let scheme = call_613472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613472.url(scheme.get, call_613472.host, call_613472.base,
                         call_613472.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613472, url, valid)

proc call*(call_613473: Call_DeleteInventory_613460; body: JsonNode): Recallable =
  ## deleteInventory
  ## Delete a custom inventory type, or the data associated with a custom Inventory type. Deleting a custom inventory type is also referred to as deleting a custom inventory schema.
  ##   body: JObject (required)
  var body_613474 = newJObject()
  if body != nil:
    body_613474 = body
  result = call_613473.call(nil, nil, nil, nil, body_613474)

var deleteInventory* = Call_DeleteInventory_613460(name: "deleteInventory",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteInventory",
    validator: validate_DeleteInventory_613461, base: "/", url: url_DeleteInventory_613462,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMaintenanceWindow_613475 = ref object of OpenApiRestCall_612658
proc url_DeleteMaintenanceWindow_613477(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteMaintenanceWindow_613476(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a maintenance window.
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
      "AmazonSSM.DeleteMaintenanceWindow"))
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

proc call*(call_613487: Call_DeleteMaintenanceWindow_613475; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a maintenance window.
  ## 
  let valid = call_613487.validator(path, query, header, formData, body)
  let scheme = call_613487.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613487.url(scheme.get, call_613487.host, call_613487.base,
                         call_613487.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613487, url, valid)

proc call*(call_613488: Call_DeleteMaintenanceWindow_613475; body: JsonNode): Recallable =
  ## deleteMaintenanceWindow
  ## Deletes a maintenance window.
  ##   body: JObject (required)
  var body_613489 = newJObject()
  if body != nil:
    body_613489 = body
  result = call_613488.call(nil, nil, nil, nil, body_613489)

var deleteMaintenanceWindow* = Call_DeleteMaintenanceWindow_613475(
    name: "deleteMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteMaintenanceWindow",
    validator: validate_DeleteMaintenanceWindow_613476, base: "/",
    url: url_DeleteMaintenanceWindow_613477, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteParameter_613490 = ref object of OpenApiRestCall_612658
proc url_DeleteParameter_613492(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteParameter_613491(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Delete a parameter from the system.
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
      "AmazonSSM.DeleteParameter"))
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

proc call*(call_613502: Call_DeleteParameter_613490; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a parameter from the system.
  ## 
  let valid = call_613502.validator(path, query, header, formData, body)
  let scheme = call_613502.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613502.url(scheme.get, call_613502.host, call_613502.base,
                         call_613502.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613502, url, valid)

proc call*(call_613503: Call_DeleteParameter_613490; body: JsonNode): Recallable =
  ## deleteParameter
  ## Delete a parameter from the system.
  ##   body: JObject (required)
  var body_613504 = newJObject()
  if body != nil:
    body_613504 = body
  result = call_613503.call(nil, nil, nil, nil, body_613504)

var deleteParameter* = Call_DeleteParameter_613490(name: "deleteParameter",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteParameter",
    validator: validate_DeleteParameter_613491, base: "/", url: url_DeleteParameter_613492,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteParameters_613505 = ref object of OpenApiRestCall_612658
proc url_DeleteParameters_613507(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteParameters_613506(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Delete a list of parameters.
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
      "AmazonSSM.DeleteParameters"))
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

proc call*(call_613517: Call_DeleteParameters_613505; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a list of parameters.
  ## 
  let valid = call_613517.validator(path, query, header, formData, body)
  let scheme = call_613517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613517.url(scheme.get, call_613517.host, call_613517.base,
                         call_613517.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613517, url, valid)

proc call*(call_613518: Call_DeleteParameters_613505; body: JsonNode): Recallable =
  ## deleteParameters
  ## Delete a list of parameters.
  ##   body: JObject (required)
  var body_613519 = newJObject()
  if body != nil:
    body_613519 = body
  result = call_613518.call(nil, nil, nil, nil, body_613519)

var deleteParameters* = Call_DeleteParameters_613505(name: "deleteParameters",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteParameters",
    validator: validate_DeleteParameters_613506, base: "/",
    url: url_DeleteParameters_613507, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePatchBaseline_613520 = ref object of OpenApiRestCall_612658
proc url_DeletePatchBaseline_613522(protocol: Scheme; host: string; base: string;
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

proc validate_DeletePatchBaseline_613521(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Deletes a patch baseline.
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
      "AmazonSSM.DeletePatchBaseline"))
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

proc call*(call_613532: Call_DeletePatchBaseline_613520; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a patch baseline.
  ## 
  let valid = call_613532.validator(path, query, header, formData, body)
  let scheme = call_613532.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613532.url(scheme.get, call_613532.host, call_613532.base,
                         call_613532.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613532, url, valid)

proc call*(call_613533: Call_DeletePatchBaseline_613520; body: JsonNode): Recallable =
  ## deletePatchBaseline
  ## Deletes a patch baseline.
  ##   body: JObject (required)
  var body_613534 = newJObject()
  if body != nil:
    body_613534 = body
  result = call_613533.call(nil, nil, nil, nil, body_613534)

var deletePatchBaseline* = Call_DeletePatchBaseline_613520(
    name: "deletePatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeletePatchBaseline",
    validator: validate_DeletePatchBaseline_613521, base: "/",
    url: url_DeletePatchBaseline_613522, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResourceDataSync_613535 = ref object of OpenApiRestCall_612658
proc url_DeleteResourceDataSync_613537(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteResourceDataSync_613536(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a Resource Data Sync configuration. After the configuration is deleted, changes to data on managed instances are no longer synced to or from the target. Deleting a sync configuration does not delete data.
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
  var valid_613538 = header.getOrDefault("X-Amz-Target")
  valid_613538 = validateParameter(valid_613538, JString, required = true, default = newJString(
      "AmazonSSM.DeleteResourceDataSync"))
  if valid_613538 != nil:
    section.add "X-Amz-Target", valid_613538
  var valid_613539 = header.getOrDefault("X-Amz-Signature")
  valid_613539 = validateParameter(valid_613539, JString, required = false,
                                 default = nil)
  if valid_613539 != nil:
    section.add "X-Amz-Signature", valid_613539
  var valid_613540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613540 = validateParameter(valid_613540, JString, required = false,
                                 default = nil)
  if valid_613540 != nil:
    section.add "X-Amz-Content-Sha256", valid_613540
  var valid_613541 = header.getOrDefault("X-Amz-Date")
  valid_613541 = validateParameter(valid_613541, JString, required = false,
                                 default = nil)
  if valid_613541 != nil:
    section.add "X-Amz-Date", valid_613541
  var valid_613542 = header.getOrDefault("X-Amz-Credential")
  valid_613542 = validateParameter(valid_613542, JString, required = false,
                                 default = nil)
  if valid_613542 != nil:
    section.add "X-Amz-Credential", valid_613542
  var valid_613543 = header.getOrDefault("X-Amz-Security-Token")
  valid_613543 = validateParameter(valid_613543, JString, required = false,
                                 default = nil)
  if valid_613543 != nil:
    section.add "X-Amz-Security-Token", valid_613543
  var valid_613544 = header.getOrDefault("X-Amz-Algorithm")
  valid_613544 = validateParameter(valid_613544, JString, required = false,
                                 default = nil)
  if valid_613544 != nil:
    section.add "X-Amz-Algorithm", valid_613544
  var valid_613545 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613545 = validateParameter(valid_613545, JString, required = false,
                                 default = nil)
  if valid_613545 != nil:
    section.add "X-Amz-SignedHeaders", valid_613545
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613547: Call_DeleteResourceDataSync_613535; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Resource Data Sync configuration. After the configuration is deleted, changes to data on managed instances are no longer synced to or from the target. Deleting a sync configuration does not delete data.
  ## 
  let valid = call_613547.validator(path, query, header, formData, body)
  let scheme = call_613547.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613547.url(scheme.get, call_613547.host, call_613547.base,
                         call_613547.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613547, url, valid)

proc call*(call_613548: Call_DeleteResourceDataSync_613535; body: JsonNode): Recallable =
  ## deleteResourceDataSync
  ## Deletes a Resource Data Sync configuration. After the configuration is deleted, changes to data on managed instances are no longer synced to or from the target. Deleting a sync configuration does not delete data.
  ##   body: JObject (required)
  var body_613549 = newJObject()
  if body != nil:
    body_613549 = body
  result = call_613548.call(nil, nil, nil, nil, body_613549)

var deleteResourceDataSync* = Call_DeleteResourceDataSync_613535(
    name: "deleteResourceDataSync", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteResourceDataSync",
    validator: validate_DeleteResourceDataSync_613536, base: "/",
    url: url_DeleteResourceDataSync_613537, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterManagedInstance_613550 = ref object of OpenApiRestCall_612658
proc url_DeregisterManagedInstance_613552(protocol: Scheme; host: string;
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

proc validate_DeregisterManagedInstance_613551(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes the server or virtual machine from the list of registered servers. You can reregister the instance again at any time. If you don't plan to use Run Command on the server, we suggest uninstalling SSM Agent first.
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
  var valid_613553 = header.getOrDefault("X-Amz-Target")
  valid_613553 = validateParameter(valid_613553, JString, required = true, default = newJString(
      "AmazonSSM.DeregisterManagedInstance"))
  if valid_613553 != nil:
    section.add "X-Amz-Target", valid_613553
  var valid_613554 = header.getOrDefault("X-Amz-Signature")
  valid_613554 = validateParameter(valid_613554, JString, required = false,
                                 default = nil)
  if valid_613554 != nil:
    section.add "X-Amz-Signature", valid_613554
  var valid_613555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613555 = validateParameter(valid_613555, JString, required = false,
                                 default = nil)
  if valid_613555 != nil:
    section.add "X-Amz-Content-Sha256", valid_613555
  var valid_613556 = header.getOrDefault("X-Amz-Date")
  valid_613556 = validateParameter(valid_613556, JString, required = false,
                                 default = nil)
  if valid_613556 != nil:
    section.add "X-Amz-Date", valid_613556
  var valid_613557 = header.getOrDefault("X-Amz-Credential")
  valid_613557 = validateParameter(valid_613557, JString, required = false,
                                 default = nil)
  if valid_613557 != nil:
    section.add "X-Amz-Credential", valid_613557
  var valid_613558 = header.getOrDefault("X-Amz-Security-Token")
  valid_613558 = validateParameter(valid_613558, JString, required = false,
                                 default = nil)
  if valid_613558 != nil:
    section.add "X-Amz-Security-Token", valid_613558
  var valid_613559 = header.getOrDefault("X-Amz-Algorithm")
  valid_613559 = validateParameter(valid_613559, JString, required = false,
                                 default = nil)
  if valid_613559 != nil:
    section.add "X-Amz-Algorithm", valid_613559
  var valid_613560 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613560 = validateParameter(valid_613560, JString, required = false,
                                 default = nil)
  if valid_613560 != nil:
    section.add "X-Amz-SignedHeaders", valid_613560
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613562: Call_DeregisterManagedInstance_613550; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the server or virtual machine from the list of registered servers. You can reregister the instance again at any time. If you don't plan to use Run Command on the server, we suggest uninstalling SSM Agent first.
  ## 
  let valid = call_613562.validator(path, query, header, formData, body)
  let scheme = call_613562.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613562.url(scheme.get, call_613562.host, call_613562.base,
                         call_613562.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613562, url, valid)

proc call*(call_613563: Call_DeregisterManagedInstance_613550; body: JsonNode): Recallable =
  ## deregisterManagedInstance
  ## Removes the server or virtual machine from the list of registered servers. You can reregister the instance again at any time. If you don't plan to use Run Command on the server, we suggest uninstalling SSM Agent first.
  ##   body: JObject (required)
  var body_613564 = newJObject()
  if body != nil:
    body_613564 = body
  result = call_613563.call(nil, nil, nil, nil, body_613564)

var deregisterManagedInstance* = Call_DeregisterManagedInstance_613550(
    name: "deregisterManagedInstance", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeregisterManagedInstance",
    validator: validate_DeregisterManagedInstance_613551, base: "/",
    url: url_DeregisterManagedInstance_613552,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterPatchBaselineForPatchGroup_613565 = ref object of OpenApiRestCall_612658
proc url_DeregisterPatchBaselineForPatchGroup_613567(protocol: Scheme;
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

proc validate_DeregisterPatchBaselineForPatchGroup_613566(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes a patch group from a patch baseline.
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
  var valid_613568 = header.getOrDefault("X-Amz-Target")
  valid_613568 = validateParameter(valid_613568, JString, required = true, default = newJString(
      "AmazonSSM.DeregisterPatchBaselineForPatchGroup"))
  if valid_613568 != nil:
    section.add "X-Amz-Target", valid_613568
  var valid_613569 = header.getOrDefault("X-Amz-Signature")
  valid_613569 = validateParameter(valid_613569, JString, required = false,
                                 default = nil)
  if valid_613569 != nil:
    section.add "X-Amz-Signature", valid_613569
  var valid_613570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613570 = validateParameter(valid_613570, JString, required = false,
                                 default = nil)
  if valid_613570 != nil:
    section.add "X-Amz-Content-Sha256", valid_613570
  var valid_613571 = header.getOrDefault("X-Amz-Date")
  valid_613571 = validateParameter(valid_613571, JString, required = false,
                                 default = nil)
  if valid_613571 != nil:
    section.add "X-Amz-Date", valid_613571
  var valid_613572 = header.getOrDefault("X-Amz-Credential")
  valid_613572 = validateParameter(valid_613572, JString, required = false,
                                 default = nil)
  if valid_613572 != nil:
    section.add "X-Amz-Credential", valid_613572
  var valid_613573 = header.getOrDefault("X-Amz-Security-Token")
  valid_613573 = validateParameter(valid_613573, JString, required = false,
                                 default = nil)
  if valid_613573 != nil:
    section.add "X-Amz-Security-Token", valid_613573
  var valid_613574 = header.getOrDefault("X-Amz-Algorithm")
  valid_613574 = validateParameter(valid_613574, JString, required = false,
                                 default = nil)
  if valid_613574 != nil:
    section.add "X-Amz-Algorithm", valid_613574
  var valid_613575 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613575 = validateParameter(valid_613575, JString, required = false,
                                 default = nil)
  if valid_613575 != nil:
    section.add "X-Amz-SignedHeaders", valid_613575
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613577: Call_DeregisterPatchBaselineForPatchGroup_613565;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Removes a patch group from a patch baseline.
  ## 
  let valid = call_613577.validator(path, query, header, formData, body)
  let scheme = call_613577.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613577.url(scheme.get, call_613577.host, call_613577.base,
                         call_613577.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613577, url, valid)

proc call*(call_613578: Call_DeregisterPatchBaselineForPatchGroup_613565;
          body: JsonNode): Recallable =
  ## deregisterPatchBaselineForPatchGroup
  ## Removes a patch group from a patch baseline.
  ##   body: JObject (required)
  var body_613579 = newJObject()
  if body != nil:
    body_613579 = body
  result = call_613578.call(nil, nil, nil, nil, body_613579)

var deregisterPatchBaselineForPatchGroup* = Call_DeregisterPatchBaselineForPatchGroup_613565(
    name: "deregisterPatchBaselineForPatchGroup", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeregisterPatchBaselineForPatchGroup",
    validator: validate_DeregisterPatchBaselineForPatchGroup_613566, base: "/",
    url: url_DeregisterPatchBaselineForPatchGroup_613567,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterTargetFromMaintenanceWindow_613580 = ref object of OpenApiRestCall_612658
proc url_DeregisterTargetFromMaintenanceWindow_613582(protocol: Scheme;
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

proc validate_DeregisterTargetFromMaintenanceWindow_613581(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes a target from a maintenance window.
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
  var valid_613583 = header.getOrDefault("X-Amz-Target")
  valid_613583 = validateParameter(valid_613583, JString, required = true, default = newJString(
      "AmazonSSM.DeregisterTargetFromMaintenanceWindow"))
  if valid_613583 != nil:
    section.add "X-Amz-Target", valid_613583
  var valid_613584 = header.getOrDefault("X-Amz-Signature")
  valid_613584 = validateParameter(valid_613584, JString, required = false,
                                 default = nil)
  if valid_613584 != nil:
    section.add "X-Amz-Signature", valid_613584
  var valid_613585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613585 = validateParameter(valid_613585, JString, required = false,
                                 default = nil)
  if valid_613585 != nil:
    section.add "X-Amz-Content-Sha256", valid_613585
  var valid_613586 = header.getOrDefault("X-Amz-Date")
  valid_613586 = validateParameter(valid_613586, JString, required = false,
                                 default = nil)
  if valid_613586 != nil:
    section.add "X-Amz-Date", valid_613586
  var valid_613587 = header.getOrDefault("X-Amz-Credential")
  valid_613587 = validateParameter(valid_613587, JString, required = false,
                                 default = nil)
  if valid_613587 != nil:
    section.add "X-Amz-Credential", valid_613587
  var valid_613588 = header.getOrDefault("X-Amz-Security-Token")
  valid_613588 = validateParameter(valid_613588, JString, required = false,
                                 default = nil)
  if valid_613588 != nil:
    section.add "X-Amz-Security-Token", valid_613588
  var valid_613589 = header.getOrDefault("X-Amz-Algorithm")
  valid_613589 = validateParameter(valid_613589, JString, required = false,
                                 default = nil)
  if valid_613589 != nil:
    section.add "X-Amz-Algorithm", valid_613589
  var valid_613590 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613590 = validateParameter(valid_613590, JString, required = false,
                                 default = nil)
  if valid_613590 != nil:
    section.add "X-Amz-SignedHeaders", valid_613590
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613592: Call_DeregisterTargetFromMaintenanceWindow_613580;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Removes a target from a maintenance window.
  ## 
  let valid = call_613592.validator(path, query, header, formData, body)
  let scheme = call_613592.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613592.url(scheme.get, call_613592.host, call_613592.base,
                         call_613592.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613592, url, valid)

proc call*(call_613593: Call_DeregisterTargetFromMaintenanceWindow_613580;
          body: JsonNode): Recallable =
  ## deregisterTargetFromMaintenanceWindow
  ## Removes a target from a maintenance window.
  ##   body: JObject (required)
  var body_613594 = newJObject()
  if body != nil:
    body_613594 = body
  result = call_613593.call(nil, nil, nil, nil, body_613594)

var deregisterTargetFromMaintenanceWindow* = Call_DeregisterTargetFromMaintenanceWindow_613580(
    name: "deregisterTargetFromMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeregisterTargetFromMaintenanceWindow",
    validator: validate_DeregisterTargetFromMaintenanceWindow_613581, base: "/",
    url: url_DeregisterTargetFromMaintenanceWindow_613582,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterTaskFromMaintenanceWindow_613595 = ref object of OpenApiRestCall_612658
proc url_DeregisterTaskFromMaintenanceWindow_613597(protocol: Scheme; host: string;
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

proc validate_DeregisterTaskFromMaintenanceWindow_613596(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes a task from a maintenance window.
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
  var valid_613598 = header.getOrDefault("X-Amz-Target")
  valid_613598 = validateParameter(valid_613598, JString, required = true, default = newJString(
      "AmazonSSM.DeregisterTaskFromMaintenanceWindow"))
  if valid_613598 != nil:
    section.add "X-Amz-Target", valid_613598
  var valid_613599 = header.getOrDefault("X-Amz-Signature")
  valid_613599 = validateParameter(valid_613599, JString, required = false,
                                 default = nil)
  if valid_613599 != nil:
    section.add "X-Amz-Signature", valid_613599
  var valid_613600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613600 = validateParameter(valid_613600, JString, required = false,
                                 default = nil)
  if valid_613600 != nil:
    section.add "X-Amz-Content-Sha256", valid_613600
  var valid_613601 = header.getOrDefault("X-Amz-Date")
  valid_613601 = validateParameter(valid_613601, JString, required = false,
                                 default = nil)
  if valid_613601 != nil:
    section.add "X-Amz-Date", valid_613601
  var valid_613602 = header.getOrDefault("X-Amz-Credential")
  valid_613602 = validateParameter(valid_613602, JString, required = false,
                                 default = nil)
  if valid_613602 != nil:
    section.add "X-Amz-Credential", valid_613602
  var valid_613603 = header.getOrDefault("X-Amz-Security-Token")
  valid_613603 = validateParameter(valid_613603, JString, required = false,
                                 default = nil)
  if valid_613603 != nil:
    section.add "X-Amz-Security-Token", valid_613603
  var valid_613604 = header.getOrDefault("X-Amz-Algorithm")
  valid_613604 = validateParameter(valid_613604, JString, required = false,
                                 default = nil)
  if valid_613604 != nil:
    section.add "X-Amz-Algorithm", valid_613604
  var valid_613605 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613605 = validateParameter(valid_613605, JString, required = false,
                                 default = nil)
  if valid_613605 != nil:
    section.add "X-Amz-SignedHeaders", valid_613605
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613607: Call_DeregisterTaskFromMaintenanceWindow_613595;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Removes a task from a maintenance window.
  ## 
  let valid = call_613607.validator(path, query, header, formData, body)
  let scheme = call_613607.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613607.url(scheme.get, call_613607.host, call_613607.base,
                         call_613607.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613607, url, valid)

proc call*(call_613608: Call_DeregisterTaskFromMaintenanceWindow_613595;
          body: JsonNode): Recallable =
  ## deregisterTaskFromMaintenanceWindow
  ## Removes a task from a maintenance window.
  ##   body: JObject (required)
  var body_613609 = newJObject()
  if body != nil:
    body_613609 = body
  result = call_613608.call(nil, nil, nil, nil, body_613609)

var deregisterTaskFromMaintenanceWindow* = Call_DeregisterTaskFromMaintenanceWindow_613595(
    name: "deregisterTaskFromMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeregisterTaskFromMaintenanceWindow",
    validator: validate_DeregisterTaskFromMaintenanceWindow_613596, base: "/",
    url: url_DeregisterTaskFromMaintenanceWindow_613597,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeActivations_613610 = ref object of OpenApiRestCall_612658
proc url_DescribeActivations_613612(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeActivations_613611(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Describes details about the activation, such as the date and time the activation was created, its expiration date, the IAM role assigned to the instances in the activation, and the number of instances registered by using this activation.
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
  var valid_613613 = query.getOrDefault("MaxResults")
  valid_613613 = validateParameter(valid_613613, JString, required = false,
                                 default = nil)
  if valid_613613 != nil:
    section.add "MaxResults", valid_613613
  var valid_613614 = query.getOrDefault("NextToken")
  valid_613614 = validateParameter(valid_613614, JString, required = false,
                                 default = nil)
  if valid_613614 != nil:
    section.add "NextToken", valid_613614
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
  var valid_613615 = header.getOrDefault("X-Amz-Target")
  valid_613615 = validateParameter(valid_613615, JString, required = true, default = newJString(
      "AmazonSSM.DescribeActivations"))
  if valid_613615 != nil:
    section.add "X-Amz-Target", valid_613615
  var valid_613616 = header.getOrDefault("X-Amz-Signature")
  valid_613616 = validateParameter(valid_613616, JString, required = false,
                                 default = nil)
  if valid_613616 != nil:
    section.add "X-Amz-Signature", valid_613616
  var valid_613617 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613617 = validateParameter(valid_613617, JString, required = false,
                                 default = nil)
  if valid_613617 != nil:
    section.add "X-Amz-Content-Sha256", valid_613617
  var valid_613618 = header.getOrDefault("X-Amz-Date")
  valid_613618 = validateParameter(valid_613618, JString, required = false,
                                 default = nil)
  if valid_613618 != nil:
    section.add "X-Amz-Date", valid_613618
  var valid_613619 = header.getOrDefault("X-Amz-Credential")
  valid_613619 = validateParameter(valid_613619, JString, required = false,
                                 default = nil)
  if valid_613619 != nil:
    section.add "X-Amz-Credential", valid_613619
  var valid_613620 = header.getOrDefault("X-Amz-Security-Token")
  valid_613620 = validateParameter(valid_613620, JString, required = false,
                                 default = nil)
  if valid_613620 != nil:
    section.add "X-Amz-Security-Token", valid_613620
  var valid_613621 = header.getOrDefault("X-Amz-Algorithm")
  valid_613621 = validateParameter(valid_613621, JString, required = false,
                                 default = nil)
  if valid_613621 != nil:
    section.add "X-Amz-Algorithm", valid_613621
  var valid_613622 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613622 = validateParameter(valid_613622, JString, required = false,
                                 default = nil)
  if valid_613622 != nil:
    section.add "X-Amz-SignedHeaders", valid_613622
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613624: Call_DescribeActivations_613610; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes details about the activation, such as the date and time the activation was created, its expiration date, the IAM role assigned to the instances in the activation, and the number of instances registered by using this activation.
  ## 
  let valid = call_613624.validator(path, query, header, formData, body)
  let scheme = call_613624.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613624.url(scheme.get, call_613624.host, call_613624.base,
                         call_613624.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613624, url, valid)

proc call*(call_613625: Call_DescribeActivations_613610; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## describeActivations
  ## Describes details about the activation, such as the date and time the activation was created, its expiration date, the IAM role assigned to the instances in the activation, and the number of instances registered by using this activation.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613626 = newJObject()
  var body_613627 = newJObject()
  add(query_613626, "MaxResults", newJString(MaxResults))
  add(query_613626, "NextToken", newJString(NextToken))
  if body != nil:
    body_613627 = body
  result = call_613625.call(nil, query_613626, nil, nil, body_613627)

var describeActivations* = Call_DescribeActivations_613610(
    name: "describeActivations", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeActivations",
    validator: validate_DescribeActivations_613611, base: "/",
    url: url_DescribeActivations_613612, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAssociation_613629 = ref object of OpenApiRestCall_612658
proc url_DescribeAssociation_613631(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeAssociation_613630(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Describes the association for the specified target or instance. If you created the association by using the <code>Targets</code> parameter, then you must retrieve the association by using the association ID. If you created the association by specifying an instance ID and a Systems Manager document, then you retrieve the association by specifying the document name and the instance ID. 
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
  var valid_613632 = header.getOrDefault("X-Amz-Target")
  valid_613632 = validateParameter(valid_613632, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAssociation"))
  if valid_613632 != nil:
    section.add "X-Amz-Target", valid_613632
  var valid_613633 = header.getOrDefault("X-Amz-Signature")
  valid_613633 = validateParameter(valid_613633, JString, required = false,
                                 default = nil)
  if valid_613633 != nil:
    section.add "X-Amz-Signature", valid_613633
  var valid_613634 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613634 = validateParameter(valid_613634, JString, required = false,
                                 default = nil)
  if valid_613634 != nil:
    section.add "X-Amz-Content-Sha256", valid_613634
  var valid_613635 = header.getOrDefault("X-Amz-Date")
  valid_613635 = validateParameter(valid_613635, JString, required = false,
                                 default = nil)
  if valid_613635 != nil:
    section.add "X-Amz-Date", valid_613635
  var valid_613636 = header.getOrDefault("X-Amz-Credential")
  valid_613636 = validateParameter(valid_613636, JString, required = false,
                                 default = nil)
  if valid_613636 != nil:
    section.add "X-Amz-Credential", valid_613636
  var valid_613637 = header.getOrDefault("X-Amz-Security-Token")
  valid_613637 = validateParameter(valid_613637, JString, required = false,
                                 default = nil)
  if valid_613637 != nil:
    section.add "X-Amz-Security-Token", valid_613637
  var valid_613638 = header.getOrDefault("X-Amz-Algorithm")
  valid_613638 = validateParameter(valid_613638, JString, required = false,
                                 default = nil)
  if valid_613638 != nil:
    section.add "X-Amz-Algorithm", valid_613638
  var valid_613639 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613639 = validateParameter(valid_613639, JString, required = false,
                                 default = nil)
  if valid_613639 != nil:
    section.add "X-Amz-SignedHeaders", valid_613639
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613641: Call_DescribeAssociation_613629; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the association for the specified target or instance. If you created the association by using the <code>Targets</code> parameter, then you must retrieve the association by using the association ID. If you created the association by specifying an instance ID and a Systems Manager document, then you retrieve the association by specifying the document name and the instance ID. 
  ## 
  let valid = call_613641.validator(path, query, header, formData, body)
  let scheme = call_613641.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613641.url(scheme.get, call_613641.host, call_613641.base,
                         call_613641.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613641, url, valid)

proc call*(call_613642: Call_DescribeAssociation_613629; body: JsonNode): Recallable =
  ## describeAssociation
  ## Describes the association for the specified target or instance. If you created the association by using the <code>Targets</code> parameter, then you must retrieve the association by using the association ID. If you created the association by specifying an instance ID and a Systems Manager document, then you retrieve the association by specifying the document name and the instance ID. 
  ##   body: JObject (required)
  var body_613643 = newJObject()
  if body != nil:
    body_613643 = body
  result = call_613642.call(nil, nil, nil, nil, body_613643)

var describeAssociation* = Call_DescribeAssociation_613629(
    name: "describeAssociation", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAssociation",
    validator: validate_DescribeAssociation_613630, base: "/",
    url: url_DescribeAssociation_613631, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAssociationExecutionTargets_613644 = ref object of OpenApiRestCall_612658
proc url_DescribeAssociationExecutionTargets_613646(protocol: Scheme; host: string;
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

proc validate_DescribeAssociationExecutionTargets_613645(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Use this API action to view information about a specific execution of a specific association.
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
  var valid_613647 = header.getOrDefault("X-Amz-Target")
  valid_613647 = validateParameter(valid_613647, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAssociationExecutionTargets"))
  if valid_613647 != nil:
    section.add "X-Amz-Target", valid_613647
  var valid_613648 = header.getOrDefault("X-Amz-Signature")
  valid_613648 = validateParameter(valid_613648, JString, required = false,
                                 default = nil)
  if valid_613648 != nil:
    section.add "X-Amz-Signature", valid_613648
  var valid_613649 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613649 = validateParameter(valid_613649, JString, required = false,
                                 default = nil)
  if valid_613649 != nil:
    section.add "X-Amz-Content-Sha256", valid_613649
  var valid_613650 = header.getOrDefault("X-Amz-Date")
  valid_613650 = validateParameter(valid_613650, JString, required = false,
                                 default = nil)
  if valid_613650 != nil:
    section.add "X-Amz-Date", valid_613650
  var valid_613651 = header.getOrDefault("X-Amz-Credential")
  valid_613651 = validateParameter(valid_613651, JString, required = false,
                                 default = nil)
  if valid_613651 != nil:
    section.add "X-Amz-Credential", valid_613651
  var valid_613652 = header.getOrDefault("X-Amz-Security-Token")
  valid_613652 = validateParameter(valid_613652, JString, required = false,
                                 default = nil)
  if valid_613652 != nil:
    section.add "X-Amz-Security-Token", valid_613652
  var valid_613653 = header.getOrDefault("X-Amz-Algorithm")
  valid_613653 = validateParameter(valid_613653, JString, required = false,
                                 default = nil)
  if valid_613653 != nil:
    section.add "X-Amz-Algorithm", valid_613653
  var valid_613654 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613654 = validateParameter(valid_613654, JString, required = false,
                                 default = nil)
  if valid_613654 != nil:
    section.add "X-Amz-SignedHeaders", valid_613654
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613656: Call_DescribeAssociationExecutionTargets_613644;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Use this API action to view information about a specific execution of a specific association.
  ## 
  let valid = call_613656.validator(path, query, header, formData, body)
  let scheme = call_613656.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613656.url(scheme.get, call_613656.host, call_613656.base,
                         call_613656.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613656, url, valid)

proc call*(call_613657: Call_DescribeAssociationExecutionTargets_613644;
          body: JsonNode): Recallable =
  ## describeAssociationExecutionTargets
  ## Use this API action to view information about a specific execution of a specific association.
  ##   body: JObject (required)
  var body_613658 = newJObject()
  if body != nil:
    body_613658 = body
  result = call_613657.call(nil, nil, nil, nil, body_613658)

var describeAssociationExecutionTargets* = Call_DescribeAssociationExecutionTargets_613644(
    name: "describeAssociationExecutionTargets", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAssociationExecutionTargets",
    validator: validate_DescribeAssociationExecutionTargets_613645, base: "/",
    url: url_DescribeAssociationExecutionTargets_613646,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAssociationExecutions_613659 = ref object of OpenApiRestCall_612658
proc url_DescribeAssociationExecutions_613661(protocol: Scheme; host: string;
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

proc validate_DescribeAssociationExecutions_613660(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Use this API action to view all executions for a specific association ID. 
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
  var valid_613662 = header.getOrDefault("X-Amz-Target")
  valid_613662 = validateParameter(valid_613662, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAssociationExecutions"))
  if valid_613662 != nil:
    section.add "X-Amz-Target", valid_613662
  var valid_613663 = header.getOrDefault("X-Amz-Signature")
  valid_613663 = validateParameter(valid_613663, JString, required = false,
                                 default = nil)
  if valid_613663 != nil:
    section.add "X-Amz-Signature", valid_613663
  var valid_613664 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613664 = validateParameter(valid_613664, JString, required = false,
                                 default = nil)
  if valid_613664 != nil:
    section.add "X-Amz-Content-Sha256", valid_613664
  var valid_613665 = header.getOrDefault("X-Amz-Date")
  valid_613665 = validateParameter(valid_613665, JString, required = false,
                                 default = nil)
  if valid_613665 != nil:
    section.add "X-Amz-Date", valid_613665
  var valid_613666 = header.getOrDefault("X-Amz-Credential")
  valid_613666 = validateParameter(valid_613666, JString, required = false,
                                 default = nil)
  if valid_613666 != nil:
    section.add "X-Amz-Credential", valid_613666
  var valid_613667 = header.getOrDefault("X-Amz-Security-Token")
  valid_613667 = validateParameter(valid_613667, JString, required = false,
                                 default = nil)
  if valid_613667 != nil:
    section.add "X-Amz-Security-Token", valid_613667
  var valid_613668 = header.getOrDefault("X-Amz-Algorithm")
  valid_613668 = validateParameter(valid_613668, JString, required = false,
                                 default = nil)
  if valid_613668 != nil:
    section.add "X-Amz-Algorithm", valid_613668
  var valid_613669 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613669 = validateParameter(valid_613669, JString, required = false,
                                 default = nil)
  if valid_613669 != nil:
    section.add "X-Amz-SignedHeaders", valid_613669
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613671: Call_DescribeAssociationExecutions_613659; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Use this API action to view all executions for a specific association ID. 
  ## 
  let valid = call_613671.validator(path, query, header, formData, body)
  let scheme = call_613671.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613671.url(scheme.get, call_613671.host, call_613671.base,
                         call_613671.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613671, url, valid)

proc call*(call_613672: Call_DescribeAssociationExecutions_613659; body: JsonNode): Recallable =
  ## describeAssociationExecutions
  ## Use this API action to view all executions for a specific association ID. 
  ##   body: JObject (required)
  var body_613673 = newJObject()
  if body != nil:
    body_613673 = body
  result = call_613672.call(nil, nil, nil, nil, body_613673)

var describeAssociationExecutions* = Call_DescribeAssociationExecutions_613659(
    name: "describeAssociationExecutions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAssociationExecutions",
    validator: validate_DescribeAssociationExecutions_613660, base: "/",
    url: url_DescribeAssociationExecutions_613661,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAutomationExecutions_613674 = ref object of OpenApiRestCall_612658
proc url_DescribeAutomationExecutions_613676(protocol: Scheme; host: string;
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

proc validate_DescribeAutomationExecutions_613675(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Provides details about all active and terminated Automation executions.
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
  var valid_613677 = header.getOrDefault("X-Amz-Target")
  valid_613677 = validateParameter(valid_613677, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAutomationExecutions"))
  if valid_613677 != nil:
    section.add "X-Amz-Target", valid_613677
  var valid_613678 = header.getOrDefault("X-Amz-Signature")
  valid_613678 = validateParameter(valid_613678, JString, required = false,
                                 default = nil)
  if valid_613678 != nil:
    section.add "X-Amz-Signature", valid_613678
  var valid_613679 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613679 = validateParameter(valid_613679, JString, required = false,
                                 default = nil)
  if valid_613679 != nil:
    section.add "X-Amz-Content-Sha256", valid_613679
  var valid_613680 = header.getOrDefault("X-Amz-Date")
  valid_613680 = validateParameter(valid_613680, JString, required = false,
                                 default = nil)
  if valid_613680 != nil:
    section.add "X-Amz-Date", valid_613680
  var valid_613681 = header.getOrDefault("X-Amz-Credential")
  valid_613681 = validateParameter(valid_613681, JString, required = false,
                                 default = nil)
  if valid_613681 != nil:
    section.add "X-Amz-Credential", valid_613681
  var valid_613682 = header.getOrDefault("X-Amz-Security-Token")
  valid_613682 = validateParameter(valid_613682, JString, required = false,
                                 default = nil)
  if valid_613682 != nil:
    section.add "X-Amz-Security-Token", valid_613682
  var valid_613683 = header.getOrDefault("X-Amz-Algorithm")
  valid_613683 = validateParameter(valid_613683, JString, required = false,
                                 default = nil)
  if valid_613683 != nil:
    section.add "X-Amz-Algorithm", valid_613683
  var valid_613684 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613684 = validateParameter(valid_613684, JString, required = false,
                                 default = nil)
  if valid_613684 != nil:
    section.add "X-Amz-SignedHeaders", valid_613684
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613686: Call_DescribeAutomationExecutions_613674; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides details about all active and terminated Automation executions.
  ## 
  let valid = call_613686.validator(path, query, header, formData, body)
  let scheme = call_613686.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613686.url(scheme.get, call_613686.host, call_613686.base,
                         call_613686.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613686, url, valid)

proc call*(call_613687: Call_DescribeAutomationExecutions_613674; body: JsonNode): Recallable =
  ## describeAutomationExecutions
  ## Provides details about all active and terminated Automation executions.
  ##   body: JObject (required)
  var body_613688 = newJObject()
  if body != nil:
    body_613688 = body
  result = call_613687.call(nil, nil, nil, nil, body_613688)

var describeAutomationExecutions* = Call_DescribeAutomationExecutions_613674(
    name: "describeAutomationExecutions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAutomationExecutions",
    validator: validate_DescribeAutomationExecutions_613675, base: "/",
    url: url_DescribeAutomationExecutions_613676,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAutomationStepExecutions_613689 = ref object of OpenApiRestCall_612658
proc url_DescribeAutomationStepExecutions_613691(protocol: Scheme; host: string;
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

proc validate_DescribeAutomationStepExecutions_613690(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Information about all active and terminated step executions in an Automation workflow.
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
  var valid_613692 = header.getOrDefault("X-Amz-Target")
  valid_613692 = validateParameter(valid_613692, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAutomationStepExecutions"))
  if valid_613692 != nil:
    section.add "X-Amz-Target", valid_613692
  var valid_613693 = header.getOrDefault("X-Amz-Signature")
  valid_613693 = validateParameter(valid_613693, JString, required = false,
                                 default = nil)
  if valid_613693 != nil:
    section.add "X-Amz-Signature", valid_613693
  var valid_613694 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613694 = validateParameter(valid_613694, JString, required = false,
                                 default = nil)
  if valid_613694 != nil:
    section.add "X-Amz-Content-Sha256", valid_613694
  var valid_613695 = header.getOrDefault("X-Amz-Date")
  valid_613695 = validateParameter(valid_613695, JString, required = false,
                                 default = nil)
  if valid_613695 != nil:
    section.add "X-Amz-Date", valid_613695
  var valid_613696 = header.getOrDefault("X-Amz-Credential")
  valid_613696 = validateParameter(valid_613696, JString, required = false,
                                 default = nil)
  if valid_613696 != nil:
    section.add "X-Amz-Credential", valid_613696
  var valid_613697 = header.getOrDefault("X-Amz-Security-Token")
  valid_613697 = validateParameter(valid_613697, JString, required = false,
                                 default = nil)
  if valid_613697 != nil:
    section.add "X-Amz-Security-Token", valid_613697
  var valid_613698 = header.getOrDefault("X-Amz-Algorithm")
  valid_613698 = validateParameter(valid_613698, JString, required = false,
                                 default = nil)
  if valid_613698 != nil:
    section.add "X-Amz-Algorithm", valid_613698
  var valid_613699 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613699 = validateParameter(valid_613699, JString, required = false,
                                 default = nil)
  if valid_613699 != nil:
    section.add "X-Amz-SignedHeaders", valid_613699
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613701: Call_DescribeAutomationStepExecutions_613689;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Information about all active and terminated step executions in an Automation workflow.
  ## 
  let valid = call_613701.validator(path, query, header, formData, body)
  let scheme = call_613701.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613701.url(scheme.get, call_613701.host, call_613701.base,
                         call_613701.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613701, url, valid)

proc call*(call_613702: Call_DescribeAutomationStepExecutions_613689;
          body: JsonNode): Recallable =
  ## describeAutomationStepExecutions
  ## Information about all active and terminated step executions in an Automation workflow.
  ##   body: JObject (required)
  var body_613703 = newJObject()
  if body != nil:
    body_613703 = body
  result = call_613702.call(nil, nil, nil, nil, body_613703)

var describeAutomationStepExecutions* = Call_DescribeAutomationStepExecutions_613689(
    name: "describeAutomationStepExecutions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAutomationStepExecutions",
    validator: validate_DescribeAutomationStepExecutions_613690, base: "/",
    url: url_DescribeAutomationStepExecutions_613691,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAvailablePatches_613704 = ref object of OpenApiRestCall_612658
proc url_DescribeAvailablePatches_613706(protocol: Scheme; host: string;
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

proc validate_DescribeAvailablePatches_613705(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all patches eligible to be included in a patch baseline.
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
  var valid_613707 = header.getOrDefault("X-Amz-Target")
  valid_613707 = validateParameter(valid_613707, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAvailablePatches"))
  if valid_613707 != nil:
    section.add "X-Amz-Target", valid_613707
  var valid_613708 = header.getOrDefault("X-Amz-Signature")
  valid_613708 = validateParameter(valid_613708, JString, required = false,
                                 default = nil)
  if valid_613708 != nil:
    section.add "X-Amz-Signature", valid_613708
  var valid_613709 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613709 = validateParameter(valid_613709, JString, required = false,
                                 default = nil)
  if valid_613709 != nil:
    section.add "X-Amz-Content-Sha256", valid_613709
  var valid_613710 = header.getOrDefault("X-Amz-Date")
  valid_613710 = validateParameter(valid_613710, JString, required = false,
                                 default = nil)
  if valid_613710 != nil:
    section.add "X-Amz-Date", valid_613710
  var valid_613711 = header.getOrDefault("X-Amz-Credential")
  valid_613711 = validateParameter(valid_613711, JString, required = false,
                                 default = nil)
  if valid_613711 != nil:
    section.add "X-Amz-Credential", valid_613711
  var valid_613712 = header.getOrDefault("X-Amz-Security-Token")
  valid_613712 = validateParameter(valid_613712, JString, required = false,
                                 default = nil)
  if valid_613712 != nil:
    section.add "X-Amz-Security-Token", valid_613712
  var valid_613713 = header.getOrDefault("X-Amz-Algorithm")
  valid_613713 = validateParameter(valid_613713, JString, required = false,
                                 default = nil)
  if valid_613713 != nil:
    section.add "X-Amz-Algorithm", valid_613713
  var valid_613714 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613714 = validateParameter(valid_613714, JString, required = false,
                                 default = nil)
  if valid_613714 != nil:
    section.add "X-Amz-SignedHeaders", valid_613714
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613716: Call_DescribeAvailablePatches_613704; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all patches eligible to be included in a patch baseline.
  ## 
  let valid = call_613716.validator(path, query, header, formData, body)
  let scheme = call_613716.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613716.url(scheme.get, call_613716.host, call_613716.base,
                         call_613716.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613716, url, valid)

proc call*(call_613717: Call_DescribeAvailablePatches_613704; body: JsonNode): Recallable =
  ## describeAvailablePatches
  ## Lists all patches eligible to be included in a patch baseline.
  ##   body: JObject (required)
  var body_613718 = newJObject()
  if body != nil:
    body_613718 = body
  result = call_613717.call(nil, nil, nil, nil, body_613718)

var describeAvailablePatches* = Call_DescribeAvailablePatches_613704(
    name: "describeAvailablePatches", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAvailablePatches",
    validator: validate_DescribeAvailablePatches_613705, base: "/",
    url: url_DescribeAvailablePatches_613706, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDocument_613719 = ref object of OpenApiRestCall_612658
proc url_DescribeDocument_613721(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeDocument_613720(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Describes the specified Systems Manager document.
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
  var valid_613722 = header.getOrDefault("X-Amz-Target")
  valid_613722 = validateParameter(valid_613722, JString, required = true, default = newJString(
      "AmazonSSM.DescribeDocument"))
  if valid_613722 != nil:
    section.add "X-Amz-Target", valid_613722
  var valid_613723 = header.getOrDefault("X-Amz-Signature")
  valid_613723 = validateParameter(valid_613723, JString, required = false,
                                 default = nil)
  if valid_613723 != nil:
    section.add "X-Amz-Signature", valid_613723
  var valid_613724 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613724 = validateParameter(valid_613724, JString, required = false,
                                 default = nil)
  if valid_613724 != nil:
    section.add "X-Amz-Content-Sha256", valid_613724
  var valid_613725 = header.getOrDefault("X-Amz-Date")
  valid_613725 = validateParameter(valid_613725, JString, required = false,
                                 default = nil)
  if valid_613725 != nil:
    section.add "X-Amz-Date", valid_613725
  var valid_613726 = header.getOrDefault("X-Amz-Credential")
  valid_613726 = validateParameter(valid_613726, JString, required = false,
                                 default = nil)
  if valid_613726 != nil:
    section.add "X-Amz-Credential", valid_613726
  var valid_613727 = header.getOrDefault("X-Amz-Security-Token")
  valid_613727 = validateParameter(valid_613727, JString, required = false,
                                 default = nil)
  if valid_613727 != nil:
    section.add "X-Amz-Security-Token", valid_613727
  var valid_613728 = header.getOrDefault("X-Amz-Algorithm")
  valid_613728 = validateParameter(valid_613728, JString, required = false,
                                 default = nil)
  if valid_613728 != nil:
    section.add "X-Amz-Algorithm", valid_613728
  var valid_613729 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613729 = validateParameter(valid_613729, JString, required = false,
                                 default = nil)
  if valid_613729 != nil:
    section.add "X-Amz-SignedHeaders", valid_613729
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613731: Call_DescribeDocument_613719; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified Systems Manager document.
  ## 
  let valid = call_613731.validator(path, query, header, formData, body)
  let scheme = call_613731.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613731.url(scheme.get, call_613731.host, call_613731.base,
                         call_613731.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613731, url, valid)

proc call*(call_613732: Call_DescribeDocument_613719; body: JsonNode): Recallable =
  ## describeDocument
  ## Describes the specified Systems Manager document.
  ##   body: JObject (required)
  var body_613733 = newJObject()
  if body != nil:
    body_613733 = body
  result = call_613732.call(nil, nil, nil, nil, body_613733)

var describeDocument* = Call_DescribeDocument_613719(name: "describeDocument",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeDocument",
    validator: validate_DescribeDocument_613720, base: "/",
    url: url_DescribeDocument_613721, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDocumentPermission_613734 = ref object of OpenApiRestCall_612658
proc url_DescribeDocumentPermission_613736(protocol: Scheme; host: string;
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

proc validate_DescribeDocumentPermission_613735(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the permissions for a Systems Manager document. If you created the document, you are the owner. If a document is shared, it can either be shared privately (by specifying a user's AWS account ID) or publicly (<i>All</i>). 
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
  var valid_613737 = header.getOrDefault("X-Amz-Target")
  valid_613737 = validateParameter(valid_613737, JString, required = true, default = newJString(
      "AmazonSSM.DescribeDocumentPermission"))
  if valid_613737 != nil:
    section.add "X-Amz-Target", valid_613737
  var valid_613738 = header.getOrDefault("X-Amz-Signature")
  valid_613738 = validateParameter(valid_613738, JString, required = false,
                                 default = nil)
  if valid_613738 != nil:
    section.add "X-Amz-Signature", valid_613738
  var valid_613739 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613739 = validateParameter(valid_613739, JString, required = false,
                                 default = nil)
  if valid_613739 != nil:
    section.add "X-Amz-Content-Sha256", valid_613739
  var valid_613740 = header.getOrDefault("X-Amz-Date")
  valid_613740 = validateParameter(valid_613740, JString, required = false,
                                 default = nil)
  if valid_613740 != nil:
    section.add "X-Amz-Date", valid_613740
  var valid_613741 = header.getOrDefault("X-Amz-Credential")
  valid_613741 = validateParameter(valid_613741, JString, required = false,
                                 default = nil)
  if valid_613741 != nil:
    section.add "X-Amz-Credential", valid_613741
  var valid_613742 = header.getOrDefault("X-Amz-Security-Token")
  valid_613742 = validateParameter(valid_613742, JString, required = false,
                                 default = nil)
  if valid_613742 != nil:
    section.add "X-Amz-Security-Token", valid_613742
  var valid_613743 = header.getOrDefault("X-Amz-Algorithm")
  valid_613743 = validateParameter(valid_613743, JString, required = false,
                                 default = nil)
  if valid_613743 != nil:
    section.add "X-Amz-Algorithm", valid_613743
  var valid_613744 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613744 = validateParameter(valid_613744, JString, required = false,
                                 default = nil)
  if valid_613744 != nil:
    section.add "X-Amz-SignedHeaders", valid_613744
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613746: Call_DescribeDocumentPermission_613734; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the permissions for a Systems Manager document. If you created the document, you are the owner. If a document is shared, it can either be shared privately (by specifying a user's AWS account ID) or publicly (<i>All</i>). 
  ## 
  let valid = call_613746.validator(path, query, header, formData, body)
  let scheme = call_613746.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613746.url(scheme.get, call_613746.host, call_613746.base,
                         call_613746.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613746, url, valid)

proc call*(call_613747: Call_DescribeDocumentPermission_613734; body: JsonNode): Recallable =
  ## describeDocumentPermission
  ## Describes the permissions for a Systems Manager document. If you created the document, you are the owner. If a document is shared, it can either be shared privately (by specifying a user's AWS account ID) or publicly (<i>All</i>). 
  ##   body: JObject (required)
  var body_613748 = newJObject()
  if body != nil:
    body_613748 = body
  result = call_613747.call(nil, nil, nil, nil, body_613748)

var describeDocumentPermission* = Call_DescribeDocumentPermission_613734(
    name: "describeDocumentPermission", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeDocumentPermission",
    validator: validate_DescribeDocumentPermission_613735, base: "/",
    url: url_DescribeDocumentPermission_613736,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEffectiveInstanceAssociations_613749 = ref object of OpenApiRestCall_612658
proc url_DescribeEffectiveInstanceAssociations_613751(protocol: Scheme;
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

proc validate_DescribeEffectiveInstanceAssociations_613750(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## All associations for the instance(s).
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
  var valid_613752 = header.getOrDefault("X-Amz-Target")
  valid_613752 = validateParameter(valid_613752, JString, required = true, default = newJString(
      "AmazonSSM.DescribeEffectiveInstanceAssociations"))
  if valid_613752 != nil:
    section.add "X-Amz-Target", valid_613752
  var valid_613753 = header.getOrDefault("X-Amz-Signature")
  valid_613753 = validateParameter(valid_613753, JString, required = false,
                                 default = nil)
  if valid_613753 != nil:
    section.add "X-Amz-Signature", valid_613753
  var valid_613754 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613754 = validateParameter(valid_613754, JString, required = false,
                                 default = nil)
  if valid_613754 != nil:
    section.add "X-Amz-Content-Sha256", valid_613754
  var valid_613755 = header.getOrDefault("X-Amz-Date")
  valid_613755 = validateParameter(valid_613755, JString, required = false,
                                 default = nil)
  if valid_613755 != nil:
    section.add "X-Amz-Date", valid_613755
  var valid_613756 = header.getOrDefault("X-Amz-Credential")
  valid_613756 = validateParameter(valid_613756, JString, required = false,
                                 default = nil)
  if valid_613756 != nil:
    section.add "X-Amz-Credential", valid_613756
  var valid_613757 = header.getOrDefault("X-Amz-Security-Token")
  valid_613757 = validateParameter(valid_613757, JString, required = false,
                                 default = nil)
  if valid_613757 != nil:
    section.add "X-Amz-Security-Token", valid_613757
  var valid_613758 = header.getOrDefault("X-Amz-Algorithm")
  valid_613758 = validateParameter(valid_613758, JString, required = false,
                                 default = nil)
  if valid_613758 != nil:
    section.add "X-Amz-Algorithm", valid_613758
  var valid_613759 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613759 = validateParameter(valid_613759, JString, required = false,
                                 default = nil)
  if valid_613759 != nil:
    section.add "X-Amz-SignedHeaders", valid_613759
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613761: Call_DescribeEffectiveInstanceAssociations_613749;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## All associations for the instance(s).
  ## 
  let valid = call_613761.validator(path, query, header, formData, body)
  let scheme = call_613761.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613761.url(scheme.get, call_613761.host, call_613761.base,
                         call_613761.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613761, url, valid)

proc call*(call_613762: Call_DescribeEffectiveInstanceAssociations_613749;
          body: JsonNode): Recallable =
  ## describeEffectiveInstanceAssociations
  ## All associations for the instance(s).
  ##   body: JObject (required)
  var body_613763 = newJObject()
  if body != nil:
    body_613763 = body
  result = call_613762.call(nil, nil, nil, nil, body_613763)

var describeEffectiveInstanceAssociations* = Call_DescribeEffectiveInstanceAssociations_613749(
    name: "describeEffectiveInstanceAssociations", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeEffectiveInstanceAssociations",
    validator: validate_DescribeEffectiveInstanceAssociations_613750, base: "/",
    url: url_DescribeEffectiveInstanceAssociations_613751,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEffectivePatchesForPatchBaseline_613764 = ref object of OpenApiRestCall_612658
proc url_DescribeEffectivePatchesForPatchBaseline_613766(protocol: Scheme;
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

proc validate_DescribeEffectivePatchesForPatchBaseline_613765(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the current effective patches (the patch and the approval state) for the specified patch baseline. Note that this API applies only to Windows patch baselines.
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
  var valid_613767 = header.getOrDefault("X-Amz-Target")
  valid_613767 = validateParameter(valid_613767, JString, required = true, default = newJString(
      "AmazonSSM.DescribeEffectivePatchesForPatchBaseline"))
  if valid_613767 != nil:
    section.add "X-Amz-Target", valid_613767
  var valid_613768 = header.getOrDefault("X-Amz-Signature")
  valid_613768 = validateParameter(valid_613768, JString, required = false,
                                 default = nil)
  if valid_613768 != nil:
    section.add "X-Amz-Signature", valid_613768
  var valid_613769 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613769 = validateParameter(valid_613769, JString, required = false,
                                 default = nil)
  if valid_613769 != nil:
    section.add "X-Amz-Content-Sha256", valid_613769
  var valid_613770 = header.getOrDefault("X-Amz-Date")
  valid_613770 = validateParameter(valid_613770, JString, required = false,
                                 default = nil)
  if valid_613770 != nil:
    section.add "X-Amz-Date", valid_613770
  var valid_613771 = header.getOrDefault("X-Amz-Credential")
  valid_613771 = validateParameter(valid_613771, JString, required = false,
                                 default = nil)
  if valid_613771 != nil:
    section.add "X-Amz-Credential", valid_613771
  var valid_613772 = header.getOrDefault("X-Amz-Security-Token")
  valid_613772 = validateParameter(valid_613772, JString, required = false,
                                 default = nil)
  if valid_613772 != nil:
    section.add "X-Amz-Security-Token", valid_613772
  var valid_613773 = header.getOrDefault("X-Amz-Algorithm")
  valid_613773 = validateParameter(valid_613773, JString, required = false,
                                 default = nil)
  if valid_613773 != nil:
    section.add "X-Amz-Algorithm", valid_613773
  var valid_613774 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613774 = validateParameter(valid_613774, JString, required = false,
                                 default = nil)
  if valid_613774 != nil:
    section.add "X-Amz-SignedHeaders", valid_613774
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613776: Call_DescribeEffectivePatchesForPatchBaseline_613764;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the current effective patches (the patch and the approval state) for the specified patch baseline. Note that this API applies only to Windows patch baselines.
  ## 
  let valid = call_613776.validator(path, query, header, formData, body)
  let scheme = call_613776.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613776.url(scheme.get, call_613776.host, call_613776.base,
                         call_613776.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613776, url, valid)

proc call*(call_613777: Call_DescribeEffectivePatchesForPatchBaseline_613764;
          body: JsonNode): Recallable =
  ## describeEffectivePatchesForPatchBaseline
  ## Retrieves the current effective patches (the patch and the approval state) for the specified patch baseline. Note that this API applies only to Windows patch baselines.
  ##   body: JObject (required)
  var body_613778 = newJObject()
  if body != nil:
    body_613778 = body
  result = call_613777.call(nil, nil, nil, nil, body_613778)

var describeEffectivePatchesForPatchBaseline* = Call_DescribeEffectivePatchesForPatchBaseline_613764(
    name: "describeEffectivePatchesForPatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeEffectivePatchesForPatchBaseline",
    validator: validate_DescribeEffectivePatchesForPatchBaseline_613765,
    base: "/", url: url_DescribeEffectivePatchesForPatchBaseline_613766,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInstanceAssociationsStatus_613779 = ref object of OpenApiRestCall_612658
proc url_DescribeInstanceAssociationsStatus_613781(protocol: Scheme; host: string;
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

proc validate_DescribeInstanceAssociationsStatus_613780(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## The status of the associations for the instance(s).
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
  var valid_613782 = header.getOrDefault("X-Amz-Target")
  valid_613782 = validateParameter(valid_613782, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInstanceAssociationsStatus"))
  if valid_613782 != nil:
    section.add "X-Amz-Target", valid_613782
  var valid_613783 = header.getOrDefault("X-Amz-Signature")
  valid_613783 = validateParameter(valid_613783, JString, required = false,
                                 default = nil)
  if valid_613783 != nil:
    section.add "X-Amz-Signature", valid_613783
  var valid_613784 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613784 = validateParameter(valid_613784, JString, required = false,
                                 default = nil)
  if valid_613784 != nil:
    section.add "X-Amz-Content-Sha256", valid_613784
  var valid_613785 = header.getOrDefault("X-Amz-Date")
  valid_613785 = validateParameter(valid_613785, JString, required = false,
                                 default = nil)
  if valid_613785 != nil:
    section.add "X-Amz-Date", valid_613785
  var valid_613786 = header.getOrDefault("X-Amz-Credential")
  valid_613786 = validateParameter(valid_613786, JString, required = false,
                                 default = nil)
  if valid_613786 != nil:
    section.add "X-Amz-Credential", valid_613786
  var valid_613787 = header.getOrDefault("X-Amz-Security-Token")
  valid_613787 = validateParameter(valid_613787, JString, required = false,
                                 default = nil)
  if valid_613787 != nil:
    section.add "X-Amz-Security-Token", valid_613787
  var valid_613788 = header.getOrDefault("X-Amz-Algorithm")
  valid_613788 = validateParameter(valid_613788, JString, required = false,
                                 default = nil)
  if valid_613788 != nil:
    section.add "X-Amz-Algorithm", valid_613788
  var valid_613789 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613789 = validateParameter(valid_613789, JString, required = false,
                                 default = nil)
  if valid_613789 != nil:
    section.add "X-Amz-SignedHeaders", valid_613789
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613791: Call_DescribeInstanceAssociationsStatus_613779;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## The status of the associations for the instance(s).
  ## 
  let valid = call_613791.validator(path, query, header, formData, body)
  let scheme = call_613791.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613791.url(scheme.get, call_613791.host, call_613791.base,
                         call_613791.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613791, url, valid)

proc call*(call_613792: Call_DescribeInstanceAssociationsStatus_613779;
          body: JsonNode): Recallable =
  ## describeInstanceAssociationsStatus
  ## The status of the associations for the instance(s).
  ##   body: JObject (required)
  var body_613793 = newJObject()
  if body != nil:
    body_613793 = body
  result = call_613792.call(nil, nil, nil, nil, body_613793)

var describeInstanceAssociationsStatus* = Call_DescribeInstanceAssociationsStatus_613779(
    name: "describeInstanceAssociationsStatus", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInstanceAssociationsStatus",
    validator: validate_DescribeInstanceAssociationsStatus_613780, base: "/",
    url: url_DescribeInstanceAssociationsStatus_613781,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInstanceInformation_613794 = ref object of OpenApiRestCall_612658
proc url_DescribeInstanceInformation_613796(protocol: Scheme; host: string;
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

proc validate_DescribeInstanceInformation_613795(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes one or more of your instances. You can use this to get information about instances like the operating system platform, the SSM Agent version (Linux), status etc. If you specify one or more instance IDs, it returns information for those instances. If you do not specify instance IDs, it returns information for all your instances. If you specify an instance ID that is not valid or an instance that you do not own, you receive an error. </p> <note> <p>The IamRole field for this API action is the Amazon Identity and Access Management (IAM) role assigned to on-premises instances. This call does not return the IAM role for Amazon EC2 instances.</p> </note>
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
  var valid_613797 = query.getOrDefault("MaxResults")
  valid_613797 = validateParameter(valid_613797, JString, required = false,
                                 default = nil)
  if valid_613797 != nil:
    section.add "MaxResults", valid_613797
  var valid_613798 = query.getOrDefault("NextToken")
  valid_613798 = validateParameter(valid_613798, JString, required = false,
                                 default = nil)
  if valid_613798 != nil:
    section.add "NextToken", valid_613798
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
  var valid_613799 = header.getOrDefault("X-Amz-Target")
  valid_613799 = validateParameter(valid_613799, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInstanceInformation"))
  if valid_613799 != nil:
    section.add "X-Amz-Target", valid_613799
  var valid_613800 = header.getOrDefault("X-Amz-Signature")
  valid_613800 = validateParameter(valid_613800, JString, required = false,
                                 default = nil)
  if valid_613800 != nil:
    section.add "X-Amz-Signature", valid_613800
  var valid_613801 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613801 = validateParameter(valid_613801, JString, required = false,
                                 default = nil)
  if valid_613801 != nil:
    section.add "X-Amz-Content-Sha256", valid_613801
  var valid_613802 = header.getOrDefault("X-Amz-Date")
  valid_613802 = validateParameter(valid_613802, JString, required = false,
                                 default = nil)
  if valid_613802 != nil:
    section.add "X-Amz-Date", valid_613802
  var valid_613803 = header.getOrDefault("X-Amz-Credential")
  valid_613803 = validateParameter(valid_613803, JString, required = false,
                                 default = nil)
  if valid_613803 != nil:
    section.add "X-Amz-Credential", valid_613803
  var valid_613804 = header.getOrDefault("X-Amz-Security-Token")
  valid_613804 = validateParameter(valid_613804, JString, required = false,
                                 default = nil)
  if valid_613804 != nil:
    section.add "X-Amz-Security-Token", valid_613804
  var valid_613805 = header.getOrDefault("X-Amz-Algorithm")
  valid_613805 = validateParameter(valid_613805, JString, required = false,
                                 default = nil)
  if valid_613805 != nil:
    section.add "X-Amz-Algorithm", valid_613805
  var valid_613806 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613806 = validateParameter(valid_613806, JString, required = false,
                                 default = nil)
  if valid_613806 != nil:
    section.add "X-Amz-SignedHeaders", valid_613806
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613808: Call_DescribeInstanceInformation_613794; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes one or more of your instances. You can use this to get information about instances like the operating system platform, the SSM Agent version (Linux), status etc. If you specify one or more instance IDs, it returns information for those instances. If you do not specify instance IDs, it returns information for all your instances. If you specify an instance ID that is not valid or an instance that you do not own, you receive an error. </p> <note> <p>The IamRole field for this API action is the Amazon Identity and Access Management (IAM) role assigned to on-premises instances. This call does not return the IAM role for Amazon EC2 instances.</p> </note>
  ## 
  let valid = call_613808.validator(path, query, header, formData, body)
  let scheme = call_613808.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613808.url(scheme.get, call_613808.host, call_613808.base,
                         call_613808.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613808, url, valid)

proc call*(call_613809: Call_DescribeInstanceInformation_613794; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## describeInstanceInformation
  ## <p>Describes one or more of your instances. You can use this to get information about instances like the operating system platform, the SSM Agent version (Linux), status etc. If you specify one or more instance IDs, it returns information for those instances. If you do not specify instance IDs, it returns information for all your instances. If you specify an instance ID that is not valid or an instance that you do not own, you receive an error. </p> <note> <p>The IamRole field for this API action is the Amazon Identity and Access Management (IAM) role assigned to on-premises instances. This call does not return the IAM role for Amazon EC2 instances.</p> </note>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613810 = newJObject()
  var body_613811 = newJObject()
  add(query_613810, "MaxResults", newJString(MaxResults))
  add(query_613810, "NextToken", newJString(NextToken))
  if body != nil:
    body_613811 = body
  result = call_613809.call(nil, query_613810, nil, nil, body_613811)

var describeInstanceInformation* = Call_DescribeInstanceInformation_613794(
    name: "describeInstanceInformation", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInstanceInformation",
    validator: validate_DescribeInstanceInformation_613795, base: "/",
    url: url_DescribeInstanceInformation_613796,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInstancePatchStates_613812 = ref object of OpenApiRestCall_612658
proc url_DescribeInstancePatchStates_613814(protocol: Scheme; host: string;
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

proc validate_DescribeInstancePatchStates_613813(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the high-level patch state of one or more instances.
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
  var valid_613815 = header.getOrDefault("X-Amz-Target")
  valid_613815 = validateParameter(valid_613815, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInstancePatchStates"))
  if valid_613815 != nil:
    section.add "X-Amz-Target", valid_613815
  var valid_613816 = header.getOrDefault("X-Amz-Signature")
  valid_613816 = validateParameter(valid_613816, JString, required = false,
                                 default = nil)
  if valid_613816 != nil:
    section.add "X-Amz-Signature", valid_613816
  var valid_613817 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613817 = validateParameter(valid_613817, JString, required = false,
                                 default = nil)
  if valid_613817 != nil:
    section.add "X-Amz-Content-Sha256", valid_613817
  var valid_613818 = header.getOrDefault("X-Amz-Date")
  valid_613818 = validateParameter(valid_613818, JString, required = false,
                                 default = nil)
  if valid_613818 != nil:
    section.add "X-Amz-Date", valid_613818
  var valid_613819 = header.getOrDefault("X-Amz-Credential")
  valid_613819 = validateParameter(valid_613819, JString, required = false,
                                 default = nil)
  if valid_613819 != nil:
    section.add "X-Amz-Credential", valid_613819
  var valid_613820 = header.getOrDefault("X-Amz-Security-Token")
  valid_613820 = validateParameter(valid_613820, JString, required = false,
                                 default = nil)
  if valid_613820 != nil:
    section.add "X-Amz-Security-Token", valid_613820
  var valid_613821 = header.getOrDefault("X-Amz-Algorithm")
  valid_613821 = validateParameter(valid_613821, JString, required = false,
                                 default = nil)
  if valid_613821 != nil:
    section.add "X-Amz-Algorithm", valid_613821
  var valid_613822 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613822 = validateParameter(valid_613822, JString, required = false,
                                 default = nil)
  if valid_613822 != nil:
    section.add "X-Amz-SignedHeaders", valid_613822
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613824: Call_DescribeInstancePatchStates_613812; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the high-level patch state of one or more instances.
  ## 
  let valid = call_613824.validator(path, query, header, formData, body)
  let scheme = call_613824.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613824.url(scheme.get, call_613824.host, call_613824.base,
                         call_613824.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613824, url, valid)

proc call*(call_613825: Call_DescribeInstancePatchStates_613812; body: JsonNode): Recallable =
  ## describeInstancePatchStates
  ## Retrieves the high-level patch state of one or more instances.
  ##   body: JObject (required)
  var body_613826 = newJObject()
  if body != nil:
    body_613826 = body
  result = call_613825.call(nil, nil, nil, nil, body_613826)

var describeInstancePatchStates* = Call_DescribeInstancePatchStates_613812(
    name: "describeInstancePatchStates", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInstancePatchStates",
    validator: validate_DescribeInstancePatchStates_613813, base: "/",
    url: url_DescribeInstancePatchStates_613814,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInstancePatchStatesForPatchGroup_613827 = ref object of OpenApiRestCall_612658
proc url_DescribeInstancePatchStatesForPatchGroup_613829(protocol: Scheme;
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

proc validate_DescribeInstancePatchStatesForPatchGroup_613828(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the high-level patch state for the instances in the specified patch group.
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
  var valid_613830 = header.getOrDefault("X-Amz-Target")
  valid_613830 = validateParameter(valid_613830, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInstancePatchStatesForPatchGroup"))
  if valid_613830 != nil:
    section.add "X-Amz-Target", valid_613830
  var valid_613831 = header.getOrDefault("X-Amz-Signature")
  valid_613831 = validateParameter(valid_613831, JString, required = false,
                                 default = nil)
  if valid_613831 != nil:
    section.add "X-Amz-Signature", valid_613831
  var valid_613832 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613832 = validateParameter(valid_613832, JString, required = false,
                                 default = nil)
  if valid_613832 != nil:
    section.add "X-Amz-Content-Sha256", valid_613832
  var valid_613833 = header.getOrDefault("X-Amz-Date")
  valid_613833 = validateParameter(valid_613833, JString, required = false,
                                 default = nil)
  if valid_613833 != nil:
    section.add "X-Amz-Date", valid_613833
  var valid_613834 = header.getOrDefault("X-Amz-Credential")
  valid_613834 = validateParameter(valid_613834, JString, required = false,
                                 default = nil)
  if valid_613834 != nil:
    section.add "X-Amz-Credential", valid_613834
  var valid_613835 = header.getOrDefault("X-Amz-Security-Token")
  valid_613835 = validateParameter(valid_613835, JString, required = false,
                                 default = nil)
  if valid_613835 != nil:
    section.add "X-Amz-Security-Token", valid_613835
  var valid_613836 = header.getOrDefault("X-Amz-Algorithm")
  valid_613836 = validateParameter(valid_613836, JString, required = false,
                                 default = nil)
  if valid_613836 != nil:
    section.add "X-Amz-Algorithm", valid_613836
  var valid_613837 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613837 = validateParameter(valid_613837, JString, required = false,
                                 default = nil)
  if valid_613837 != nil:
    section.add "X-Amz-SignedHeaders", valid_613837
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613839: Call_DescribeInstancePatchStatesForPatchGroup_613827;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the high-level patch state for the instances in the specified patch group.
  ## 
  let valid = call_613839.validator(path, query, header, formData, body)
  let scheme = call_613839.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613839.url(scheme.get, call_613839.host, call_613839.base,
                         call_613839.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613839, url, valid)

proc call*(call_613840: Call_DescribeInstancePatchStatesForPatchGroup_613827;
          body: JsonNode): Recallable =
  ## describeInstancePatchStatesForPatchGroup
  ## Retrieves the high-level patch state for the instances in the specified patch group.
  ##   body: JObject (required)
  var body_613841 = newJObject()
  if body != nil:
    body_613841 = body
  result = call_613840.call(nil, nil, nil, nil, body_613841)

var describeInstancePatchStatesForPatchGroup* = Call_DescribeInstancePatchStatesForPatchGroup_613827(
    name: "describeInstancePatchStatesForPatchGroup", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInstancePatchStatesForPatchGroup",
    validator: validate_DescribeInstancePatchStatesForPatchGroup_613828,
    base: "/", url: url_DescribeInstancePatchStatesForPatchGroup_613829,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInstancePatches_613842 = ref object of OpenApiRestCall_612658
proc url_DescribeInstancePatches_613844(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeInstancePatches_613843(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves information about the patches on the specified instance and their state relative to the patch baseline being used for the instance.
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
  var valid_613845 = header.getOrDefault("X-Amz-Target")
  valid_613845 = validateParameter(valid_613845, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInstancePatches"))
  if valid_613845 != nil:
    section.add "X-Amz-Target", valid_613845
  var valid_613846 = header.getOrDefault("X-Amz-Signature")
  valid_613846 = validateParameter(valid_613846, JString, required = false,
                                 default = nil)
  if valid_613846 != nil:
    section.add "X-Amz-Signature", valid_613846
  var valid_613847 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613847 = validateParameter(valid_613847, JString, required = false,
                                 default = nil)
  if valid_613847 != nil:
    section.add "X-Amz-Content-Sha256", valid_613847
  var valid_613848 = header.getOrDefault("X-Amz-Date")
  valid_613848 = validateParameter(valid_613848, JString, required = false,
                                 default = nil)
  if valid_613848 != nil:
    section.add "X-Amz-Date", valid_613848
  var valid_613849 = header.getOrDefault("X-Amz-Credential")
  valid_613849 = validateParameter(valid_613849, JString, required = false,
                                 default = nil)
  if valid_613849 != nil:
    section.add "X-Amz-Credential", valid_613849
  var valid_613850 = header.getOrDefault("X-Amz-Security-Token")
  valid_613850 = validateParameter(valid_613850, JString, required = false,
                                 default = nil)
  if valid_613850 != nil:
    section.add "X-Amz-Security-Token", valid_613850
  var valid_613851 = header.getOrDefault("X-Amz-Algorithm")
  valid_613851 = validateParameter(valid_613851, JString, required = false,
                                 default = nil)
  if valid_613851 != nil:
    section.add "X-Amz-Algorithm", valid_613851
  var valid_613852 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613852 = validateParameter(valid_613852, JString, required = false,
                                 default = nil)
  if valid_613852 != nil:
    section.add "X-Amz-SignedHeaders", valid_613852
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613854: Call_DescribeInstancePatches_613842; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the patches on the specified instance and their state relative to the patch baseline being used for the instance.
  ## 
  let valid = call_613854.validator(path, query, header, formData, body)
  let scheme = call_613854.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613854.url(scheme.get, call_613854.host, call_613854.base,
                         call_613854.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613854, url, valid)

proc call*(call_613855: Call_DescribeInstancePatches_613842; body: JsonNode): Recallable =
  ## describeInstancePatches
  ## Retrieves information about the patches on the specified instance and their state relative to the patch baseline being used for the instance.
  ##   body: JObject (required)
  var body_613856 = newJObject()
  if body != nil:
    body_613856 = body
  result = call_613855.call(nil, nil, nil, nil, body_613856)

var describeInstancePatches* = Call_DescribeInstancePatches_613842(
    name: "describeInstancePatches", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInstancePatches",
    validator: validate_DescribeInstancePatches_613843, base: "/",
    url: url_DescribeInstancePatches_613844, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInventoryDeletions_613857 = ref object of OpenApiRestCall_612658
proc url_DescribeInventoryDeletions_613859(protocol: Scheme; host: string;
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

proc validate_DescribeInventoryDeletions_613858(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes a specific delete inventory operation.
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
  var valid_613860 = header.getOrDefault("X-Amz-Target")
  valid_613860 = validateParameter(valid_613860, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInventoryDeletions"))
  if valid_613860 != nil:
    section.add "X-Amz-Target", valid_613860
  var valid_613861 = header.getOrDefault("X-Amz-Signature")
  valid_613861 = validateParameter(valid_613861, JString, required = false,
                                 default = nil)
  if valid_613861 != nil:
    section.add "X-Amz-Signature", valid_613861
  var valid_613862 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613862 = validateParameter(valid_613862, JString, required = false,
                                 default = nil)
  if valid_613862 != nil:
    section.add "X-Amz-Content-Sha256", valid_613862
  var valid_613863 = header.getOrDefault("X-Amz-Date")
  valid_613863 = validateParameter(valid_613863, JString, required = false,
                                 default = nil)
  if valid_613863 != nil:
    section.add "X-Amz-Date", valid_613863
  var valid_613864 = header.getOrDefault("X-Amz-Credential")
  valid_613864 = validateParameter(valid_613864, JString, required = false,
                                 default = nil)
  if valid_613864 != nil:
    section.add "X-Amz-Credential", valid_613864
  var valid_613865 = header.getOrDefault("X-Amz-Security-Token")
  valid_613865 = validateParameter(valid_613865, JString, required = false,
                                 default = nil)
  if valid_613865 != nil:
    section.add "X-Amz-Security-Token", valid_613865
  var valid_613866 = header.getOrDefault("X-Amz-Algorithm")
  valid_613866 = validateParameter(valid_613866, JString, required = false,
                                 default = nil)
  if valid_613866 != nil:
    section.add "X-Amz-Algorithm", valid_613866
  var valid_613867 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613867 = validateParameter(valid_613867, JString, required = false,
                                 default = nil)
  if valid_613867 != nil:
    section.add "X-Amz-SignedHeaders", valid_613867
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613869: Call_DescribeInventoryDeletions_613857; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a specific delete inventory operation.
  ## 
  let valid = call_613869.validator(path, query, header, formData, body)
  let scheme = call_613869.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613869.url(scheme.get, call_613869.host, call_613869.base,
                         call_613869.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613869, url, valid)

proc call*(call_613870: Call_DescribeInventoryDeletions_613857; body: JsonNode): Recallable =
  ## describeInventoryDeletions
  ## Describes a specific delete inventory operation.
  ##   body: JObject (required)
  var body_613871 = newJObject()
  if body != nil:
    body_613871 = body
  result = call_613870.call(nil, nil, nil, nil, body_613871)

var describeInventoryDeletions* = Call_DescribeInventoryDeletions_613857(
    name: "describeInventoryDeletions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInventoryDeletions",
    validator: validate_DescribeInventoryDeletions_613858, base: "/",
    url: url_DescribeInventoryDeletions_613859,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowExecutionTaskInvocations_613872 = ref object of OpenApiRestCall_612658
proc url_DescribeMaintenanceWindowExecutionTaskInvocations_613874(
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

proc validate_DescribeMaintenanceWindowExecutionTaskInvocations_613873(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode): JsonNode =
  ## Retrieves the individual task executions (one per target) for a particular task run as part of a maintenance window execution.
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
  var valid_613875 = header.getOrDefault("X-Amz-Target")
  valid_613875 = validateParameter(valid_613875, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowExecutionTaskInvocations"))
  if valid_613875 != nil:
    section.add "X-Amz-Target", valid_613875
  var valid_613876 = header.getOrDefault("X-Amz-Signature")
  valid_613876 = validateParameter(valid_613876, JString, required = false,
                                 default = nil)
  if valid_613876 != nil:
    section.add "X-Amz-Signature", valid_613876
  var valid_613877 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613877 = validateParameter(valid_613877, JString, required = false,
                                 default = nil)
  if valid_613877 != nil:
    section.add "X-Amz-Content-Sha256", valid_613877
  var valid_613878 = header.getOrDefault("X-Amz-Date")
  valid_613878 = validateParameter(valid_613878, JString, required = false,
                                 default = nil)
  if valid_613878 != nil:
    section.add "X-Amz-Date", valid_613878
  var valid_613879 = header.getOrDefault("X-Amz-Credential")
  valid_613879 = validateParameter(valid_613879, JString, required = false,
                                 default = nil)
  if valid_613879 != nil:
    section.add "X-Amz-Credential", valid_613879
  var valid_613880 = header.getOrDefault("X-Amz-Security-Token")
  valid_613880 = validateParameter(valid_613880, JString, required = false,
                                 default = nil)
  if valid_613880 != nil:
    section.add "X-Amz-Security-Token", valid_613880
  var valid_613881 = header.getOrDefault("X-Amz-Algorithm")
  valid_613881 = validateParameter(valid_613881, JString, required = false,
                                 default = nil)
  if valid_613881 != nil:
    section.add "X-Amz-Algorithm", valid_613881
  var valid_613882 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613882 = validateParameter(valid_613882, JString, required = false,
                                 default = nil)
  if valid_613882 != nil:
    section.add "X-Amz-SignedHeaders", valid_613882
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613884: Call_DescribeMaintenanceWindowExecutionTaskInvocations_613872;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the individual task executions (one per target) for a particular task run as part of a maintenance window execution.
  ## 
  let valid = call_613884.validator(path, query, header, formData, body)
  let scheme = call_613884.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613884.url(scheme.get, call_613884.host, call_613884.base,
                         call_613884.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613884, url, valid)

proc call*(call_613885: Call_DescribeMaintenanceWindowExecutionTaskInvocations_613872;
          body: JsonNode): Recallable =
  ## describeMaintenanceWindowExecutionTaskInvocations
  ## Retrieves the individual task executions (one per target) for a particular task run as part of a maintenance window execution.
  ##   body: JObject (required)
  var body_613886 = newJObject()
  if body != nil:
    body_613886 = body
  result = call_613885.call(nil, nil, nil, nil, body_613886)

var describeMaintenanceWindowExecutionTaskInvocations* = Call_DescribeMaintenanceWindowExecutionTaskInvocations_613872(
    name: "describeMaintenanceWindowExecutionTaskInvocations",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com", route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowExecutionTaskInvocations",
    validator: validate_DescribeMaintenanceWindowExecutionTaskInvocations_613873,
    base: "/", url: url_DescribeMaintenanceWindowExecutionTaskInvocations_613874,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowExecutionTasks_613887 = ref object of OpenApiRestCall_612658
proc url_DescribeMaintenanceWindowExecutionTasks_613889(protocol: Scheme;
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

proc validate_DescribeMaintenanceWindowExecutionTasks_613888(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## For a given maintenance window execution, lists the tasks that were run.
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
  var valid_613890 = header.getOrDefault("X-Amz-Target")
  valid_613890 = validateParameter(valid_613890, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowExecutionTasks"))
  if valid_613890 != nil:
    section.add "X-Amz-Target", valid_613890
  var valid_613891 = header.getOrDefault("X-Amz-Signature")
  valid_613891 = validateParameter(valid_613891, JString, required = false,
                                 default = nil)
  if valid_613891 != nil:
    section.add "X-Amz-Signature", valid_613891
  var valid_613892 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613892 = validateParameter(valid_613892, JString, required = false,
                                 default = nil)
  if valid_613892 != nil:
    section.add "X-Amz-Content-Sha256", valid_613892
  var valid_613893 = header.getOrDefault("X-Amz-Date")
  valid_613893 = validateParameter(valid_613893, JString, required = false,
                                 default = nil)
  if valid_613893 != nil:
    section.add "X-Amz-Date", valid_613893
  var valid_613894 = header.getOrDefault("X-Amz-Credential")
  valid_613894 = validateParameter(valid_613894, JString, required = false,
                                 default = nil)
  if valid_613894 != nil:
    section.add "X-Amz-Credential", valid_613894
  var valid_613895 = header.getOrDefault("X-Amz-Security-Token")
  valid_613895 = validateParameter(valid_613895, JString, required = false,
                                 default = nil)
  if valid_613895 != nil:
    section.add "X-Amz-Security-Token", valid_613895
  var valid_613896 = header.getOrDefault("X-Amz-Algorithm")
  valid_613896 = validateParameter(valid_613896, JString, required = false,
                                 default = nil)
  if valid_613896 != nil:
    section.add "X-Amz-Algorithm", valid_613896
  var valid_613897 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613897 = validateParameter(valid_613897, JString, required = false,
                                 default = nil)
  if valid_613897 != nil:
    section.add "X-Amz-SignedHeaders", valid_613897
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613899: Call_DescribeMaintenanceWindowExecutionTasks_613887;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## For a given maintenance window execution, lists the tasks that were run.
  ## 
  let valid = call_613899.validator(path, query, header, formData, body)
  let scheme = call_613899.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613899.url(scheme.get, call_613899.host, call_613899.base,
                         call_613899.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613899, url, valid)

proc call*(call_613900: Call_DescribeMaintenanceWindowExecutionTasks_613887;
          body: JsonNode): Recallable =
  ## describeMaintenanceWindowExecutionTasks
  ## For a given maintenance window execution, lists the tasks that were run.
  ##   body: JObject (required)
  var body_613901 = newJObject()
  if body != nil:
    body_613901 = body
  result = call_613900.call(nil, nil, nil, nil, body_613901)

var describeMaintenanceWindowExecutionTasks* = Call_DescribeMaintenanceWindowExecutionTasks_613887(
    name: "describeMaintenanceWindowExecutionTasks", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowExecutionTasks",
    validator: validate_DescribeMaintenanceWindowExecutionTasks_613888, base: "/",
    url: url_DescribeMaintenanceWindowExecutionTasks_613889,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowExecutions_613902 = ref object of OpenApiRestCall_612658
proc url_DescribeMaintenanceWindowExecutions_613904(protocol: Scheme; host: string;
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

proc validate_DescribeMaintenanceWindowExecutions_613903(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the executions of a maintenance window. This includes information about when the maintenance window was scheduled to be active, and information about tasks registered and run with the maintenance window.
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
  var valid_613905 = header.getOrDefault("X-Amz-Target")
  valid_613905 = validateParameter(valid_613905, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowExecutions"))
  if valid_613905 != nil:
    section.add "X-Amz-Target", valid_613905
  var valid_613906 = header.getOrDefault("X-Amz-Signature")
  valid_613906 = validateParameter(valid_613906, JString, required = false,
                                 default = nil)
  if valid_613906 != nil:
    section.add "X-Amz-Signature", valid_613906
  var valid_613907 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613907 = validateParameter(valid_613907, JString, required = false,
                                 default = nil)
  if valid_613907 != nil:
    section.add "X-Amz-Content-Sha256", valid_613907
  var valid_613908 = header.getOrDefault("X-Amz-Date")
  valid_613908 = validateParameter(valid_613908, JString, required = false,
                                 default = nil)
  if valid_613908 != nil:
    section.add "X-Amz-Date", valid_613908
  var valid_613909 = header.getOrDefault("X-Amz-Credential")
  valid_613909 = validateParameter(valid_613909, JString, required = false,
                                 default = nil)
  if valid_613909 != nil:
    section.add "X-Amz-Credential", valid_613909
  var valid_613910 = header.getOrDefault("X-Amz-Security-Token")
  valid_613910 = validateParameter(valid_613910, JString, required = false,
                                 default = nil)
  if valid_613910 != nil:
    section.add "X-Amz-Security-Token", valid_613910
  var valid_613911 = header.getOrDefault("X-Amz-Algorithm")
  valid_613911 = validateParameter(valid_613911, JString, required = false,
                                 default = nil)
  if valid_613911 != nil:
    section.add "X-Amz-Algorithm", valid_613911
  var valid_613912 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613912 = validateParameter(valid_613912, JString, required = false,
                                 default = nil)
  if valid_613912 != nil:
    section.add "X-Amz-SignedHeaders", valid_613912
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613914: Call_DescribeMaintenanceWindowExecutions_613902;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the executions of a maintenance window. This includes information about when the maintenance window was scheduled to be active, and information about tasks registered and run with the maintenance window.
  ## 
  let valid = call_613914.validator(path, query, header, formData, body)
  let scheme = call_613914.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613914.url(scheme.get, call_613914.host, call_613914.base,
                         call_613914.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613914, url, valid)

proc call*(call_613915: Call_DescribeMaintenanceWindowExecutions_613902;
          body: JsonNode): Recallable =
  ## describeMaintenanceWindowExecutions
  ## Lists the executions of a maintenance window. This includes information about when the maintenance window was scheduled to be active, and information about tasks registered and run with the maintenance window.
  ##   body: JObject (required)
  var body_613916 = newJObject()
  if body != nil:
    body_613916 = body
  result = call_613915.call(nil, nil, nil, nil, body_613916)

var describeMaintenanceWindowExecutions* = Call_DescribeMaintenanceWindowExecutions_613902(
    name: "describeMaintenanceWindowExecutions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowExecutions",
    validator: validate_DescribeMaintenanceWindowExecutions_613903, base: "/",
    url: url_DescribeMaintenanceWindowExecutions_613904,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowSchedule_613917 = ref object of OpenApiRestCall_612658
proc url_DescribeMaintenanceWindowSchedule_613919(protocol: Scheme; host: string;
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

proc validate_DescribeMaintenanceWindowSchedule_613918(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves information about upcoming executions of a maintenance window.
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
  var valid_613920 = header.getOrDefault("X-Amz-Target")
  valid_613920 = validateParameter(valid_613920, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowSchedule"))
  if valid_613920 != nil:
    section.add "X-Amz-Target", valid_613920
  var valid_613921 = header.getOrDefault("X-Amz-Signature")
  valid_613921 = validateParameter(valid_613921, JString, required = false,
                                 default = nil)
  if valid_613921 != nil:
    section.add "X-Amz-Signature", valid_613921
  var valid_613922 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613922 = validateParameter(valid_613922, JString, required = false,
                                 default = nil)
  if valid_613922 != nil:
    section.add "X-Amz-Content-Sha256", valid_613922
  var valid_613923 = header.getOrDefault("X-Amz-Date")
  valid_613923 = validateParameter(valid_613923, JString, required = false,
                                 default = nil)
  if valid_613923 != nil:
    section.add "X-Amz-Date", valid_613923
  var valid_613924 = header.getOrDefault("X-Amz-Credential")
  valid_613924 = validateParameter(valid_613924, JString, required = false,
                                 default = nil)
  if valid_613924 != nil:
    section.add "X-Amz-Credential", valid_613924
  var valid_613925 = header.getOrDefault("X-Amz-Security-Token")
  valid_613925 = validateParameter(valid_613925, JString, required = false,
                                 default = nil)
  if valid_613925 != nil:
    section.add "X-Amz-Security-Token", valid_613925
  var valid_613926 = header.getOrDefault("X-Amz-Algorithm")
  valid_613926 = validateParameter(valid_613926, JString, required = false,
                                 default = nil)
  if valid_613926 != nil:
    section.add "X-Amz-Algorithm", valid_613926
  var valid_613927 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613927 = validateParameter(valid_613927, JString, required = false,
                                 default = nil)
  if valid_613927 != nil:
    section.add "X-Amz-SignedHeaders", valid_613927
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613929: Call_DescribeMaintenanceWindowSchedule_613917;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves information about upcoming executions of a maintenance window.
  ## 
  let valid = call_613929.validator(path, query, header, formData, body)
  let scheme = call_613929.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613929.url(scheme.get, call_613929.host, call_613929.base,
                         call_613929.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613929, url, valid)

proc call*(call_613930: Call_DescribeMaintenanceWindowSchedule_613917;
          body: JsonNode): Recallable =
  ## describeMaintenanceWindowSchedule
  ## Retrieves information about upcoming executions of a maintenance window.
  ##   body: JObject (required)
  var body_613931 = newJObject()
  if body != nil:
    body_613931 = body
  result = call_613930.call(nil, nil, nil, nil, body_613931)

var describeMaintenanceWindowSchedule* = Call_DescribeMaintenanceWindowSchedule_613917(
    name: "describeMaintenanceWindowSchedule", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowSchedule",
    validator: validate_DescribeMaintenanceWindowSchedule_613918, base: "/",
    url: url_DescribeMaintenanceWindowSchedule_613919,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowTargets_613932 = ref object of OpenApiRestCall_612658
proc url_DescribeMaintenanceWindowTargets_613934(protocol: Scheme; host: string;
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

proc validate_DescribeMaintenanceWindowTargets_613933(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the targets registered with the maintenance window.
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
  var valid_613935 = header.getOrDefault("X-Amz-Target")
  valid_613935 = validateParameter(valid_613935, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowTargets"))
  if valid_613935 != nil:
    section.add "X-Amz-Target", valid_613935
  var valid_613936 = header.getOrDefault("X-Amz-Signature")
  valid_613936 = validateParameter(valid_613936, JString, required = false,
                                 default = nil)
  if valid_613936 != nil:
    section.add "X-Amz-Signature", valid_613936
  var valid_613937 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613937 = validateParameter(valid_613937, JString, required = false,
                                 default = nil)
  if valid_613937 != nil:
    section.add "X-Amz-Content-Sha256", valid_613937
  var valid_613938 = header.getOrDefault("X-Amz-Date")
  valid_613938 = validateParameter(valid_613938, JString, required = false,
                                 default = nil)
  if valid_613938 != nil:
    section.add "X-Amz-Date", valid_613938
  var valid_613939 = header.getOrDefault("X-Amz-Credential")
  valid_613939 = validateParameter(valid_613939, JString, required = false,
                                 default = nil)
  if valid_613939 != nil:
    section.add "X-Amz-Credential", valid_613939
  var valid_613940 = header.getOrDefault("X-Amz-Security-Token")
  valid_613940 = validateParameter(valid_613940, JString, required = false,
                                 default = nil)
  if valid_613940 != nil:
    section.add "X-Amz-Security-Token", valid_613940
  var valid_613941 = header.getOrDefault("X-Amz-Algorithm")
  valid_613941 = validateParameter(valid_613941, JString, required = false,
                                 default = nil)
  if valid_613941 != nil:
    section.add "X-Amz-Algorithm", valid_613941
  var valid_613942 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613942 = validateParameter(valid_613942, JString, required = false,
                                 default = nil)
  if valid_613942 != nil:
    section.add "X-Amz-SignedHeaders", valid_613942
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613944: Call_DescribeMaintenanceWindowTargets_613932;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the targets registered with the maintenance window.
  ## 
  let valid = call_613944.validator(path, query, header, formData, body)
  let scheme = call_613944.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613944.url(scheme.get, call_613944.host, call_613944.base,
                         call_613944.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613944, url, valid)

proc call*(call_613945: Call_DescribeMaintenanceWindowTargets_613932;
          body: JsonNode): Recallable =
  ## describeMaintenanceWindowTargets
  ## Lists the targets registered with the maintenance window.
  ##   body: JObject (required)
  var body_613946 = newJObject()
  if body != nil:
    body_613946 = body
  result = call_613945.call(nil, nil, nil, nil, body_613946)

var describeMaintenanceWindowTargets* = Call_DescribeMaintenanceWindowTargets_613932(
    name: "describeMaintenanceWindowTargets", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowTargets",
    validator: validate_DescribeMaintenanceWindowTargets_613933, base: "/",
    url: url_DescribeMaintenanceWindowTargets_613934,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowTasks_613947 = ref object of OpenApiRestCall_612658
proc url_DescribeMaintenanceWindowTasks_613949(protocol: Scheme; host: string;
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

proc validate_DescribeMaintenanceWindowTasks_613948(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the tasks in a maintenance window.
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
  var valid_613950 = header.getOrDefault("X-Amz-Target")
  valid_613950 = validateParameter(valid_613950, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowTasks"))
  if valid_613950 != nil:
    section.add "X-Amz-Target", valid_613950
  var valid_613951 = header.getOrDefault("X-Amz-Signature")
  valid_613951 = validateParameter(valid_613951, JString, required = false,
                                 default = nil)
  if valid_613951 != nil:
    section.add "X-Amz-Signature", valid_613951
  var valid_613952 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613952 = validateParameter(valid_613952, JString, required = false,
                                 default = nil)
  if valid_613952 != nil:
    section.add "X-Amz-Content-Sha256", valid_613952
  var valid_613953 = header.getOrDefault("X-Amz-Date")
  valid_613953 = validateParameter(valid_613953, JString, required = false,
                                 default = nil)
  if valid_613953 != nil:
    section.add "X-Amz-Date", valid_613953
  var valid_613954 = header.getOrDefault("X-Amz-Credential")
  valid_613954 = validateParameter(valid_613954, JString, required = false,
                                 default = nil)
  if valid_613954 != nil:
    section.add "X-Amz-Credential", valid_613954
  var valid_613955 = header.getOrDefault("X-Amz-Security-Token")
  valid_613955 = validateParameter(valid_613955, JString, required = false,
                                 default = nil)
  if valid_613955 != nil:
    section.add "X-Amz-Security-Token", valid_613955
  var valid_613956 = header.getOrDefault("X-Amz-Algorithm")
  valid_613956 = validateParameter(valid_613956, JString, required = false,
                                 default = nil)
  if valid_613956 != nil:
    section.add "X-Amz-Algorithm", valid_613956
  var valid_613957 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613957 = validateParameter(valid_613957, JString, required = false,
                                 default = nil)
  if valid_613957 != nil:
    section.add "X-Amz-SignedHeaders", valid_613957
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613959: Call_DescribeMaintenanceWindowTasks_613947; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tasks in a maintenance window.
  ## 
  let valid = call_613959.validator(path, query, header, formData, body)
  let scheme = call_613959.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613959.url(scheme.get, call_613959.host, call_613959.base,
                         call_613959.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613959, url, valid)

proc call*(call_613960: Call_DescribeMaintenanceWindowTasks_613947; body: JsonNode): Recallable =
  ## describeMaintenanceWindowTasks
  ## Lists the tasks in a maintenance window.
  ##   body: JObject (required)
  var body_613961 = newJObject()
  if body != nil:
    body_613961 = body
  result = call_613960.call(nil, nil, nil, nil, body_613961)

var describeMaintenanceWindowTasks* = Call_DescribeMaintenanceWindowTasks_613947(
    name: "describeMaintenanceWindowTasks", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowTasks",
    validator: validate_DescribeMaintenanceWindowTasks_613948, base: "/",
    url: url_DescribeMaintenanceWindowTasks_613949,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindows_613962 = ref object of OpenApiRestCall_612658
proc url_DescribeMaintenanceWindows_613964(protocol: Scheme; host: string;
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

proc validate_DescribeMaintenanceWindows_613963(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the maintenance windows in an AWS account.
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
  var valid_613965 = header.getOrDefault("X-Amz-Target")
  valid_613965 = validateParameter(valid_613965, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindows"))
  if valid_613965 != nil:
    section.add "X-Amz-Target", valid_613965
  var valid_613966 = header.getOrDefault("X-Amz-Signature")
  valid_613966 = validateParameter(valid_613966, JString, required = false,
                                 default = nil)
  if valid_613966 != nil:
    section.add "X-Amz-Signature", valid_613966
  var valid_613967 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613967 = validateParameter(valid_613967, JString, required = false,
                                 default = nil)
  if valid_613967 != nil:
    section.add "X-Amz-Content-Sha256", valid_613967
  var valid_613968 = header.getOrDefault("X-Amz-Date")
  valid_613968 = validateParameter(valid_613968, JString, required = false,
                                 default = nil)
  if valid_613968 != nil:
    section.add "X-Amz-Date", valid_613968
  var valid_613969 = header.getOrDefault("X-Amz-Credential")
  valid_613969 = validateParameter(valid_613969, JString, required = false,
                                 default = nil)
  if valid_613969 != nil:
    section.add "X-Amz-Credential", valid_613969
  var valid_613970 = header.getOrDefault("X-Amz-Security-Token")
  valid_613970 = validateParameter(valid_613970, JString, required = false,
                                 default = nil)
  if valid_613970 != nil:
    section.add "X-Amz-Security-Token", valid_613970
  var valid_613971 = header.getOrDefault("X-Amz-Algorithm")
  valid_613971 = validateParameter(valid_613971, JString, required = false,
                                 default = nil)
  if valid_613971 != nil:
    section.add "X-Amz-Algorithm", valid_613971
  var valid_613972 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613972 = validateParameter(valid_613972, JString, required = false,
                                 default = nil)
  if valid_613972 != nil:
    section.add "X-Amz-SignedHeaders", valid_613972
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613974: Call_DescribeMaintenanceWindows_613962; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the maintenance windows in an AWS account.
  ## 
  let valid = call_613974.validator(path, query, header, formData, body)
  let scheme = call_613974.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613974.url(scheme.get, call_613974.host, call_613974.base,
                         call_613974.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613974, url, valid)

proc call*(call_613975: Call_DescribeMaintenanceWindows_613962; body: JsonNode): Recallable =
  ## describeMaintenanceWindows
  ## Retrieves the maintenance windows in an AWS account.
  ##   body: JObject (required)
  var body_613976 = newJObject()
  if body != nil:
    body_613976 = body
  result = call_613975.call(nil, nil, nil, nil, body_613976)

var describeMaintenanceWindows* = Call_DescribeMaintenanceWindows_613962(
    name: "describeMaintenanceWindows", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindows",
    validator: validate_DescribeMaintenanceWindows_613963, base: "/",
    url: url_DescribeMaintenanceWindows_613964,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowsForTarget_613977 = ref object of OpenApiRestCall_612658
proc url_DescribeMaintenanceWindowsForTarget_613979(protocol: Scheme; host: string;
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

proc validate_DescribeMaintenanceWindowsForTarget_613978(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves information about the maintenance window targets or tasks that an instance is associated with.
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
  var valid_613980 = header.getOrDefault("X-Amz-Target")
  valid_613980 = validateParameter(valid_613980, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowsForTarget"))
  if valid_613980 != nil:
    section.add "X-Amz-Target", valid_613980
  var valid_613981 = header.getOrDefault("X-Amz-Signature")
  valid_613981 = validateParameter(valid_613981, JString, required = false,
                                 default = nil)
  if valid_613981 != nil:
    section.add "X-Amz-Signature", valid_613981
  var valid_613982 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613982 = validateParameter(valid_613982, JString, required = false,
                                 default = nil)
  if valid_613982 != nil:
    section.add "X-Amz-Content-Sha256", valid_613982
  var valid_613983 = header.getOrDefault("X-Amz-Date")
  valid_613983 = validateParameter(valid_613983, JString, required = false,
                                 default = nil)
  if valid_613983 != nil:
    section.add "X-Amz-Date", valid_613983
  var valid_613984 = header.getOrDefault("X-Amz-Credential")
  valid_613984 = validateParameter(valid_613984, JString, required = false,
                                 default = nil)
  if valid_613984 != nil:
    section.add "X-Amz-Credential", valid_613984
  var valid_613985 = header.getOrDefault("X-Amz-Security-Token")
  valid_613985 = validateParameter(valid_613985, JString, required = false,
                                 default = nil)
  if valid_613985 != nil:
    section.add "X-Amz-Security-Token", valid_613985
  var valid_613986 = header.getOrDefault("X-Amz-Algorithm")
  valid_613986 = validateParameter(valid_613986, JString, required = false,
                                 default = nil)
  if valid_613986 != nil:
    section.add "X-Amz-Algorithm", valid_613986
  var valid_613987 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613987 = validateParameter(valid_613987, JString, required = false,
                                 default = nil)
  if valid_613987 != nil:
    section.add "X-Amz-SignedHeaders", valid_613987
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613989: Call_DescribeMaintenanceWindowsForTarget_613977;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves information about the maintenance window targets or tasks that an instance is associated with.
  ## 
  let valid = call_613989.validator(path, query, header, formData, body)
  let scheme = call_613989.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613989.url(scheme.get, call_613989.host, call_613989.base,
                         call_613989.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613989, url, valid)

proc call*(call_613990: Call_DescribeMaintenanceWindowsForTarget_613977;
          body: JsonNode): Recallable =
  ## describeMaintenanceWindowsForTarget
  ## Retrieves information about the maintenance window targets or tasks that an instance is associated with.
  ##   body: JObject (required)
  var body_613991 = newJObject()
  if body != nil:
    body_613991 = body
  result = call_613990.call(nil, nil, nil, nil, body_613991)

var describeMaintenanceWindowsForTarget* = Call_DescribeMaintenanceWindowsForTarget_613977(
    name: "describeMaintenanceWindowsForTarget", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowsForTarget",
    validator: validate_DescribeMaintenanceWindowsForTarget_613978, base: "/",
    url: url_DescribeMaintenanceWindowsForTarget_613979,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeOpsItems_613992 = ref object of OpenApiRestCall_612658
proc url_DescribeOpsItems_613994(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeOpsItems_613993(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Query a set of OpsItems. You must have permission in AWS Identity and Access Management (IAM) to query a list of OpsItems. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
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
  var valid_613995 = header.getOrDefault("X-Amz-Target")
  valid_613995 = validateParameter(valid_613995, JString, required = true, default = newJString(
      "AmazonSSM.DescribeOpsItems"))
  if valid_613995 != nil:
    section.add "X-Amz-Target", valid_613995
  var valid_613996 = header.getOrDefault("X-Amz-Signature")
  valid_613996 = validateParameter(valid_613996, JString, required = false,
                                 default = nil)
  if valid_613996 != nil:
    section.add "X-Amz-Signature", valid_613996
  var valid_613997 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613997 = validateParameter(valid_613997, JString, required = false,
                                 default = nil)
  if valid_613997 != nil:
    section.add "X-Amz-Content-Sha256", valid_613997
  var valid_613998 = header.getOrDefault("X-Amz-Date")
  valid_613998 = validateParameter(valid_613998, JString, required = false,
                                 default = nil)
  if valid_613998 != nil:
    section.add "X-Amz-Date", valid_613998
  var valid_613999 = header.getOrDefault("X-Amz-Credential")
  valid_613999 = validateParameter(valid_613999, JString, required = false,
                                 default = nil)
  if valid_613999 != nil:
    section.add "X-Amz-Credential", valid_613999
  var valid_614000 = header.getOrDefault("X-Amz-Security-Token")
  valid_614000 = validateParameter(valid_614000, JString, required = false,
                                 default = nil)
  if valid_614000 != nil:
    section.add "X-Amz-Security-Token", valid_614000
  var valid_614001 = header.getOrDefault("X-Amz-Algorithm")
  valid_614001 = validateParameter(valid_614001, JString, required = false,
                                 default = nil)
  if valid_614001 != nil:
    section.add "X-Amz-Algorithm", valid_614001
  var valid_614002 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614002 = validateParameter(valid_614002, JString, required = false,
                                 default = nil)
  if valid_614002 != nil:
    section.add "X-Amz-SignedHeaders", valid_614002
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614004: Call_DescribeOpsItems_613992; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Query a set of OpsItems. You must have permission in AWS Identity and Access Management (IAM) to query a list of OpsItems. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ## 
  let valid = call_614004.validator(path, query, header, formData, body)
  let scheme = call_614004.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614004.url(scheme.get, call_614004.host, call_614004.base,
                         call_614004.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614004, url, valid)

proc call*(call_614005: Call_DescribeOpsItems_613992; body: JsonNode): Recallable =
  ## describeOpsItems
  ## <p>Query a set of OpsItems. You must have permission in AWS Identity and Access Management (IAM) to query a list of OpsItems. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ##   body: JObject (required)
  var body_614006 = newJObject()
  if body != nil:
    body_614006 = body
  result = call_614005.call(nil, nil, nil, nil, body_614006)

var describeOpsItems* = Call_DescribeOpsItems_613992(name: "describeOpsItems",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeOpsItems",
    validator: validate_DescribeOpsItems_613993, base: "/",
    url: url_DescribeOpsItems_613994, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeParameters_614007 = ref object of OpenApiRestCall_612658
proc url_DescribeParameters_614009(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeParameters_614008(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Get information about a parameter.</p> <note> <p>Request results are returned on a best-effort basis. If you specify <code>MaxResults</code> in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of <code>MaxResults</code>. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a <code>NextToken</code>. You can specify the <code>NextToken</code> in a subsequent call to get the next set of results.</p> </note>
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
  var valid_614010 = query.getOrDefault("MaxResults")
  valid_614010 = validateParameter(valid_614010, JString, required = false,
                                 default = nil)
  if valid_614010 != nil:
    section.add "MaxResults", valid_614010
  var valid_614011 = query.getOrDefault("NextToken")
  valid_614011 = validateParameter(valid_614011, JString, required = false,
                                 default = nil)
  if valid_614011 != nil:
    section.add "NextToken", valid_614011
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
  var valid_614012 = header.getOrDefault("X-Amz-Target")
  valid_614012 = validateParameter(valid_614012, JString, required = true, default = newJString(
      "AmazonSSM.DescribeParameters"))
  if valid_614012 != nil:
    section.add "X-Amz-Target", valid_614012
  var valid_614013 = header.getOrDefault("X-Amz-Signature")
  valid_614013 = validateParameter(valid_614013, JString, required = false,
                                 default = nil)
  if valid_614013 != nil:
    section.add "X-Amz-Signature", valid_614013
  var valid_614014 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614014 = validateParameter(valid_614014, JString, required = false,
                                 default = nil)
  if valid_614014 != nil:
    section.add "X-Amz-Content-Sha256", valid_614014
  var valid_614015 = header.getOrDefault("X-Amz-Date")
  valid_614015 = validateParameter(valid_614015, JString, required = false,
                                 default = nil)
  if valid_614015 != nil:
    section.add "X-Amz-Date", valid_614015
  var valid_614016 = header.getOrDefault("X-Amz-Credential")
  valid_614016 = validateParameter(valid_614016, JString, required = false,
                                 default = nil)
  if valid_614016 != nil:
    section.add "X-Amz-Credential", valid_614016
  var valid_614017 = header.getOrDefault("X-Amz-Security-Token")
  valid_614017 = validateParameter(valid_614017, JString, required = false,
                                 default = nil)
  if valid_614017 != nil:
    section.add "X-Amz-Security-Token", valid_614017
  var valid_614018 = header.getOrDefault("X-Amz-Algorithm")
  valid_614018 = validateParameter(valid_614018, JString, required = false,
                                 default = nil)
  if valid_614018 != nil:
    section.add "X-Amz-Algorithm", valid_614018
  var valid_614019 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614019 = validateParameter(valid_614019, JString, required = false,
                                 default = nil)
  if valid_614019 != nil:
    section.add "X-Amz-SignedHeaders", valid_614019
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614021: Call_DescribeParameters_614007; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Get information about a parameter.</p> <note> <p>Request results are returned on a best-effort basis. If you specify <code>MaxResults</code> in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of <code>MaxResults</code>. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a <code>NextToken</code>. You can specify the <code>NextToken</code> in a subsequent call to get the next set of results.</p> </note>
  ## 
  let valid = call_614021.validator(path, query, header, formData, body)
  let scheme = call_614021.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614021.url(scheme.get, call_614021.host, call_614021.base,
                         call_614021.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614021, url, valid)

proc call*(call_614022: Call_DescribeParameters_614007; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## describeParameters
  ## <p>Get information about a parameter.</p> <note> <p>Request results are returned on a best-effort basis. If you specify <code>MaxResults</code> in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of <code>MaxResults</code>. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a <code>NextToken</code>. You can specify the <code>NextToken</code> in a subsequent call to get the next set of results.</p> </note>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614023 = newJObject()
  var body_614024 = newJObject()
  add(query_614023, "MaxResults", newJString(MaxResults))
  add(query_614023, "NextToken", newJString(NextToken))
  if body != nil:
    body_614024 = body
  result = call_614022.call(nil, query_614023, nil, nil, body_614024)

var describeParameters* = Call_DescribeParameters_614007(
    name: "describeParameters", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeParameters",
    validator: validate_DescribeParameters_614008, base: "/",
    url: url_DescribeParameters_614009, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePatchBaselines_614025 = ref object of OpenApiRestCall_612658
proc url_DescribePatchBaselines_614027(protocol: Scheme; host: string; base: string;
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

proc validate_DescribePatchBaselines_614026(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the patch baselines in your AWS account.
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
  var valid_614028 = header.getOrDefault("X-Amz-Target")
  valid_614028 = validateParameter(valid_614028, JString, required = true, default = newJString(
      "AmazonSSM.DescribePatchBaselines"))
  if valid_614028 != nil:
    section.add "X-Amz-Target", valid_614028
  var valid_614029 = header.getOrDefault("X-Amz-Signature")
  valid_614029 = validateParameter(valid_614029, JString, required = false,
                                 default = nil)
  if valid_614029 != nil:
    section.add "X-Amz-Signature", valid_614029
  var valid_614030 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614030 = validateParameter(valid_614030, JString, required = false,
                                 default = nil)
  if valid_614030 != nil:
    section.add "X-Amz-Content-Sha256", valid_614030
  var valid_614031 = header.getOrDefault("X-Amz-Date")
  valid_614031 = validateParameter(valid_614031, JString, required = false,
                                 default = nil)
  if valid_614031 != nil:
    section.add "X-Amz-Date", valid_614031
  var valid_614032 = header.getOrDefault("X-Amz-Credential")
  valid_614032 = validateParameter(valid_614032, JString, required = false,
                                 default = nil)
  if valid_614032 != nil:
    section.add "X-Amz-Credential", valid_614032
  var valid_614033 = header.getOrDefault("X-Amz-Security-Token")
  valid_614033 = validateParameter(valid_614033, JString, required = false,
                                 default = nil)
  if valid_614033 != nil:
    section.add "X-Amz-Security-Token", valid_614033
  var valid_614034 = header.getOrDefault("X-Amz-Algorithm")
  valid_614034 = validateParameter(valid_614034, JString, required = false,
                                 default = nil)
  if valid_614034 != nil:
    section.add "X-Amz-Algorithm", valid_614034
  var valid_614035 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614035 = validateParameter(valid_614035, JString, required = false,
                                 default = nil)
  if valid_614035 != nil:
    section.add "X-Amz-SignedHeaders", valid_614035
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614037: Call_DescribePatchBaselines_614025; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the patch baselines in your AWS account.
  ## 
  let valid = call_614037.validator(path, query, header, formData, body)
  let scheme = call_614037.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614037.url(scheme.get, call_614037.host, call_614037.base,
                         call_614037.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614037, url, valid)

proc call*(call_614038: Call_DescribePatchBaselines_614025; body: JsonNode): Recallable =
  ## describePatchBaselines
  ## Lists the patch baselines in your AWS account.
  ##   body: JObject (required)
  var body_614039 = newJObject()
  if body != nil:
    body_614039 = body
  result = call_614038.call(nil, nil, nil, nil, body_614039)

var describePatchBaselines* = Call_DescribePatchBaselines_614025(
    name: "describePatchBaselines", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribePatchBaselines",
    validator: validate_DescribePatchBaselines_614026, base: "/",
    url: url_DescribePatchBaselines_614027, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePatchGroupState_614040 = ref object of OpenApiRestCall_612658
proc url_DescribePatchGroupState_614042(protocol: Scheme; host: string; base: string;
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

proc validate_DescribePatchGroupState_614041(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns high-level aggregated patch compliance state for a patch group.
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
  var valid_614043 = header.getOrDefault("X-Amz-Target")
  valid_614043 = validateParameter(valid_614043, JString, required = true, default = newJString(
      "AmazonSSM.DescribePatchGroupState"))
  if valid_614043 != nil:
    section.add "X-Amz-Target", valid_614043
  var valid_614044 = header.getOrDefault("X-Amz-Signature")
  valid_614044 = validateParameter(valid_614044, JString, required = false,
                                 default = nil)
  if valid_614044 != nil:
    section.add "X-Amz-Signature", valid_614044
  var valid_614045 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614045 = validateParameter(valid_614045, JString, required = false,
                                 default = nil)
  if valid_614045 != nil:
    section.add "X-Amz-Content-Sha256", valid_614045
  var valid_614046 = header.getOrDefault("X-Amz-Date")
  valid_614046 = validateParameter(valid_614046, JString, required = false,
                                 default = nil)
  if valid_614046 != nil:
    section.add "X-Amz-Date", valid_614046
  var valid_614047 = header.getOrDefault("X-Amz-Credential")
  valid_614047 = validateParameter(valid_614047, JString, required = false,
                                 default = nil)
  if valid_614047 != nil:
    section.add "X-Amz-Credential", valid_614047
  var valid_614048 = header.getOrDefault("X-Amz-Security-Token")
  valid_614048 = validateParameter(valid_614048, JString, required = false,
                                 default = nil)
  if valid_614048 != nil:
    section.add "X-Amz-Security-Token", valid_614048
  var valid_614049 = header.getOrDefault("X-Amz-Algorithm")
  valid_614049 = validateParameter(valid_614049, JString, required = false,
                                 default = nil)
  if valid_614049 != nil:
    section.add "X-Amz-Algorithm", valid_614049
  var valid_614050 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614050 = validateParameter(valid_614050, JString, required = false,
                                 default = nil)
  if valid_614050 != nil:
    section.add "X-Amz-SignedHeaders", valid_614050
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614052: Call_DescribePatchGroupState_614040; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns high-level aggregated patch compliance state for a patch group.
  ## 
  let valid = call_614052.validator(path, query, header, formData, body)
  let scheme = call_614052.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614052.url(scheme.get, call_614052.host, call_614052.base,
                         call_614052.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614052, url, valid)

proc call*(call_614053: Call_DescribePatchGroupState_614040; body: JsonNode): Recallable =
  ## describePatchGroupState
  ## Returns high-level aggregated patch compliance state for a patch group.
  ##   body: JObject (required)
  var body_614054 = newJObject()
  if body != nil:
    body_614054 = body
  result = call_614053.call(nil, nil, nil, nil, body_614054)

var describePatchGroupState* = Call_DescribePatchGroupState_614040(
    name: "describePatchGroupState", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribePatchGroupState",
    validator: validate_DescribePatchGroupState_614041, base: "/",
    url: url_DescribePatchGroupState_614042, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePatchGroups_614055 = ref object of OpenApiRestCall_612658
proc url_DescribePatchGroups_614057(protocol: Scheme; host: string; base: string;
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

proc validate_DescribePatchGroups_614056(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Lists all patch groups that have been registered with patch baselines.
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
  var valid_614058 = header.getOrDefault("X-Amz-Target")
  valid_614058 = validateParameter(valid_614058, JString, required = true, default = newJString(
      "AmazonSSM.DescribePatchGroups"))
  if valid_614058 != nil:
    section.add "X-Amz-Target", valid_614058
  var valid_614059 = header.getOrDefault("X-Amz-Signature")
  valid_614059 = validateParameter(valid_614059, JString, required = false,
                                 default = nil)
  if valid_614059 != nil:
    section.add "X-Amz-Signature", valid_614059
  var valid_614060 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614060 = validateParameter(valid_614060, JString, required = false,
                                 default = nil)
  if valid_614060 != nil:
    section.add "X-Amz-Content-Sha256", valid_614060
  var valid_614061 = header.getOrDefault("X-Amz-Date")
  valid_614061 = validateParameter(valid_614061, JString, required = false,
                                 default = nil)
  if valid_614061 != nil:
    section.add "X-Amz-Date", valid_614061
  var valid_614062 = header.getOrDefault("X-Amz-Credential")
  valid_614062 = validateParameter(valid_614062, JString, required = false,
                                 default = nil)
  if valid_614062 != nil:
    section.add "X-Amz-Credential", valid_614062
  var valid_614063 = header.getOrDefault("X-Amz-Security-Token")
  valid_614063 = validateParameter(valid_614063, JString, required = false,
                                 default = nil)
  if valid_614063 != nil:
    section.add "X-Amz-Security-Token", valid_614063
  var valid_614064 = header.getOrDefault("X-Amz-Algorithm")
  valid_614064 = validateParameter(valid_614064, JString, required = false,
                                 default = nil)
  if valid_614064 != nil:
    section.add "X-Amz-Algorithm", valid_614064
  var valid_614065 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614065 = validateParameter(valid_614065, JString, required = false,
                                 default = nil)
  if valid_614065 != nil:
    section.add "X-Amz-SignedHeaders", valid_614065
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614067: Call_DescribePatchGroups_614055; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all patch groups that have been registered with patch baselines.
  ## 
  let valid = call_614067.validator(path, query, header, formData, body)
  let scheme = call_614067.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614067.url(scheme.get, call_614067.host, call_614067.base,
                         call_614067.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614067, url, valid)

proc call*(call_614068: Call_DescribePatchGroups_614055; body: JsonNode): Recallable =
  ## describePatchGroups
  ## Lists all patch groups that have been registered with patch baselines.
  ##   body: JObject (required)
  var body_614069 = newJObject()
  if body != nil:
    body_614069 = body
  result = call_614068.call(nil, nil, nil, nil, body_614069)

var describePatchGroups* = Call_DescribePatchGroups_614055(
    name: "describePatchGroups", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribePatchGroups",
    validator: validate_DescribePatchGroups_614056, base: "/",
    url: url_DescribePatchGroups_614057, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePatchProperties_614070 = ref object of OpenApiRestCall_612658
proc url_DescribePatchProperties_614072(protocol: Scheme; host: string; base: string;
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

proc validate_DescribePatchProperties_614071(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the properties of available patches organized by product, product family, classification, severity, and other properties of available patches. You can use the reported properties in the filters you specify in requests for actions such as <a>CreatePatchBaseline</a>, <a>UpdatePatchBaseline</a>, <a>DescribeAvailablePatches</a>, and <a>DescribePatchBaselines</a>.</p> <p>The following section lists the properties that can be used in filters for each major operating system type:</p> <dl> <dt>WINDOWS</dt> <dd> <p>Valid properties: PRODUCT, PRODUCT_FAMILY, CLASSIFICATION, MSRC_SEVERITY</p> </dd> <dt>AMAZON_LINUX</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>AMAZON_LINUX_2</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>UBUNTU </dt> <dd> <p>Valid properties: PRODUCT, PRIORITY</p> </dd> <dt>REDHAT_ENTERPRISE_LINUX</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>SUSE</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>CENTOS</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> </dl>
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
  var valid_614073 = header.getOrDefault("X-Amz-Target")
  valid_614073 = validateParameter(valid_614073, JString, required = true, default = newJString(
      "AmazonSSM.DescribePatchProperties"))
  if valid_614073 != nil:
    section.add "X-Amz-Target", valid_614073
  var valid_614074 = header.getOrDefault("X-Amz-Signature")
  valid_614074 = validateParameter(valid_614074, JString, required = false,
                                 default = nil)
  if valid_614074 != nil:
    section.add "X-Amz-Signature", valid_614074
  var valid_614075 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614075 = validateParameter(valid_614075, JString, required = false,
                                 default = nil)
  if valid_614075 != nil:
    section.add "X-Amz-Content-Sha256", valid_614075
  var valid_614076 = header.getOrDefault("X-Amz-Date")
  valid_614076 = validateParameter(valid_614076, JString, required = false,
                                 default = nil)
  if valid_614076 != nil:
    section.add "X-Amz-Date", valid_614076
  var valid_614077 = header.getOrDefault("X-Amz-Credential")
  valid_614077 = validateParameter(valid_614077, JString, required = false,
                                 default = nil)
  if valid_614077 != nil:
    section.add "X-Amz-Credential", valid_614077
  var valid_614078 = header.getOrDefault("X-Amz-Security-Token")
  valid_614078 = validateParameter(valid_614078, JString, required = false,
                                 default = nil)
  if valid_614078 != nil:
    section.add "X-Amz-Security-Token", valid_614078
  var valid_614079 = header.getOrDefault("X-Amz-Algorithm")
  valid_614079 = validateParameter(valid_614079, JString, required = false,
                                 default = nil)
  if valid_614079 != nil:
    section.add "X-Amz-Algorithm", valid_614079
  var valid_614080 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614080 = validateParameter(valid_614080, JString, required = false,
                                 default = nil)
  if valid_614080 != nil:
    section.add "X-Amz-SignedHeaders", valid_614080
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614082: Call_DescribePatchProperties_614070; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the properties of available patches organized by product, product family, classification, severity, and other properties of available patches. You can use the reported properties in the filters you specify in requests for actions such as <a>CreatePatchBaseline</a>, <a>UpdatePatchBaseline</a>, <a>DescribeAvailablePatches</a>, and <a>DescribePatchBaselines</a>.</p> <p>The following section lists the properties that can be used in filters for each major operating system type:</p> <dl> <dt>WINDOWS</dt> <dd> <p>Valid properties: PRODUCT, PRODUCT_FAMILY, CLASSIFICATION, MSRC_SEVERITY</p> </dd> <dt>AMAZON_LINUX</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>AMAZON_LINUX_2</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>UBUNTU </dt> <dd> <p>Valid properties: PRODUCT, PRIORITY</p> </dd> <dt>REDHAT_ENTERPRISE_LINUX</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>SUSE</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>CENTOS</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> </dl>
  ## 
  let valid = call_614082.validator(path, query, header, formData, body)
  let scheme = call_614082.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614082.url(scheme.get, call_614082.host, call_614082.base,
                         call_614082.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614082, url, valid)

proc call*(call_614083: Call_DescribePatchProperties_614070; body: JsonNode): Recallable =
  ## describePatchProperties
  ## <p>Lists the properties of available patches organized by product, product family, classification, severity, and other properties of available patches. You can use the reported properties in the filters you specify in requests for actions such as <a>CreatePatchBaseline</a>, <a>UpdatePatchBaseline</a>, <a>DescribeAvailablePatches</a>, and <a>DescribePatchBaselines</a>.</p> <p>The following section lists the properties that can be used in filters for each major operating system type:</p> <dl> <dt>WINDOWS</dt> <dd> <p>Valid properties: PRODUCT, PRODUCT_FAMILY, CLASSIFICATION, MSRC_SEVERITY</p> </dd> <dt>AMAZON_LINUX</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>AMAZON_LINUX_2</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>UBUNTU </dt> <dd> <p>Valid properties: PRODUCT, PRIORITY</p> </dd> <dt>REDHAT_ENTERPRISE_LINUX</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>SUSE</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>CENTOS</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> </dl>
  ##   body: JObject (required)
  var body_614084 = newJObject()
  if body != nil:
    body_614084 = body
  result = call_614083.call(nil, nil, nil, nil, body_614084)

var describePatchProperties* = Call_DescribePatchProperties_614070(
    name: "describePatchProperties", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribePatchProperties",
    validator: validate_DescribePatchProperties_614071, base: "/",
    url: url_DescribePatchProperties_614072, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSessions_614085 = ref object of OpenApiRestCall_612658
proc url_DescribeSessions_614087(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeSessions_614086(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Retrieves a list of all active sessions (both connected and disconnected) or terminated sessions from the past 30 days.
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
  var valid_614088 = header.getOrDefault("X-Amz-Target")
  valid_614088 = validateParameter(valid_614088, JString, required = true, default = newJString(
      "AmazonSSM.DescribeSessions"))
  if valid_614088 != nil:
    section.add "X-Amz-Target", valid_614088
  var valid_614089 = header.getOrDefault("X-Amz-Signature")
  valid_614089 = validateParameter(valid_614089, JString, required = false,
                                 default = nil)
  if valid_614089 != nil:
    section.add "X-Amz-Signature", valid_614089
  var valid_614090 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614090 = validateParameter(valid_614090, JString, required = false,
                                 default = nil)
  if valid_614090 != nil:
    section.add "X-Amz-Content-Sha256", valid_614090
  var valid_614091 = header.getOrDefault("X-Amz-Date")
  valid_614091 = validateParameter(valid_614091, JString, required = false,
                                 default = nil)
  if valid_614091 != nil:
    section.add "X-Amz-Date", valid_614091
  var valid_614092 = header.getOrDefault("X-Amz-Credential")
  valid_614092 = validateParameter(valid_614092, JString, required = false,
                                 default = nil)
  if valid_614092 != nil:
    section.add "X-Amz-Credential", valid_614092
  var valid_614093 = header.getOrDefault("X-Amz-Security-Token")
  valid_614093 = validateParameter(valid_614093, JString, required = false,
                                 default = nil)
  if valid_614093 != nil:
    section.add "X-Amz-Security-Token", valid_614093
  var valid_614094 = header.getOrDefault("X-Amz-Algorithm")
  valid_614094 = validateParameter(valid_614094, JString, required = false,
                                 default = nil)
  if valid_614094 != nil:
    section.add "X-Amz-Algorithm", valid_614094
  var valid_614095 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614095 = validateParameter(valid_614095, JString, required = false,
                                 default = nil)
  if valid_614095 != nil:
    section.add "X-Amz-SignedHeaders", valid_614095
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614097: Call_DescribeSessions_614085; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of all active sessions (both connected and disconnected) or terminated sessions from the past 30 days.
  ## 
  let valid = call_614097.validator(path, query, header, formData, body)
  let scheme = call_614097.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614097.url(scheme.get, call_614097.host, call_614097.base,
                         call_614097.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614097, url, valid)

proc call*(call_614098: Call_DescribeSessions_614085; body: JsonNode): Recallable =
  ## describeSessions
  ## Retrieves a list of all active sessions (both connected and disconnected) or terminated sessions from the past 30 days.
  ##   body: JObject (required)
  var body_614099 = newJObject()
  if body != nil:
    body_614099 = body
  result = call_614098.call(nil, nil, nil, nil, body_614099)

var describeSessions* = Call_DescribeSessions_614085(name: "describeSessions",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeSessions",
    validator: validate_DescribeSessions_614086, base: "/",
    url: url_DescribeSessions_614087, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAutomationExecution_614100 = ref object of OpenApiRestCall_612658
proc url_GetAutomationExecution_614102(protocol: Scheme; host: string; base: string;
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

proc validate_GetAutomationExecution_614101(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get detailed information about a particular Automation execution.
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
  var valid_614103 = header.getOrDefault("X-Amz-Target")
  valid_614103 = validateParameter(valid_614103, JString, required = true, default = newJString(
      "AmazonSSM.GetAutomationExecution"))
  if valid_614103 != nil:
    section.add "X-Amz-Target", valid_614103
  var valid_614104 = header.getOrDefault("X-Amz-Signature")
  valid_614104 = validateParameter(valid_614104, JString, required = false,
                                 default = nil)
  if valid_614104 != nil:
    section.add "X-Amz-Signature", valid_614104
  var valid_614105 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614105 = validateParameter(valid_614105, JString, required = false,
                                 default = nil)
  if valid_614105 != nil:
    section.add "X-Amz-Content-Sha256", valid_614105
  var valid_614106 = header.getOrDefault("X-Amz-Date")
  valid_614106 = validateParameter(valid_614106, JString, required = false,
                                 default = nil)
  if valid_614106 != nil:
    section.add "X-Amz-Date", valid_614106
  var valid_614107 = header.getOrDefault("X-Amz-Credential")
  valid_614107 = validateParameter(valid_614107, JString, required = false,
                                 default = nil)
  if valid_614107 != nil:
    section.add "X-Amz-Credential", valid_614107
  var valid_614108 = header.getOrDefault("X-Amz-Security-Token")
  valid_614108 = validateParameter(valid_614108, JString, required = false,
                                 default = nil)
  if valid_614108 != nil:
    section.add "X-Amz-Security-Token", valid_614108
  var valid_614109 = header.getOrDefault("X-Amz-Algorithm")
  valid_614109 = validateParameter(valid_614109, JString, required = false,
                                 default = nil)
  if valid_614109 != nil:
    section.add "X-Amz-Algorithm", valid_614109
  var valid_614110 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614110 = validateParameter(valid_614110, JString, required = false,
                                 default = nil)
  if valid_614110 != nil:
    section.add "X-Amz-SignedHeaders", valid_614110
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614112: Call_GetAutomationExecution_614100; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get detailed information about a particular Automation execution.
  ## 
  let valid = call_614112.validator(path, query, header, formData, body)
  let scheme = call_614112.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614112.url(scheme.get, call_614112.host, call_614112.base,
                         call_614112.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614112, url, valid)

proc call*(call_614113: Call_GetAutomationExecution_614100; body: JsonNode): Recallable =
  ## getAutomationExecution
  ## Get detailed information about a particular Automation execution.
  ##   body: JObject (required)
  var body_614114 = newJObject()
  if body != nil:
    body_614114 = body
  result = call_614113.call(nil, nil, nil, nil, body_614114)

var getAutomationExecution* = Call_GetAutomationExecution_614100(
    name: "getAutomationExecution", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetAutomationExecution",
    validator: validate_GetAutomationExecution_614101, base: "/",
    url: url_GetAutomationExecution_614102, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCalendarState_614115 = ref object of OpenApiRestCall_612658
proc url_GetCalendarState_614117(protocol: Scheme; host: string; base: string;
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

proc validate_GetCalendarState_614116(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Gets the state of the AWS Systems Manager Change Calendar at an optional, specified time. If you specify a time, <code>GetCalendarState</code> returns the state of the calendar at a specific time, and returns the next time that the Change Calendar state will transition. If you do not specify a time, <code>GetCalendarState</code> assumes the current time. Change Calendar entries have two possible states: <code>OPEN</code> or <code>CLOSED</code>. For more information about Systems Manager Change Calendar, see <a href="https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-change-calendar.html">AWS Systems Manager Change Calendar</a> in the <i>AWS Systems Manager User Guide</i>.
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
  var valid_614118 = header.getOrDefault("X-Amz-Target")
  valid_614118 = validateParameter(valid_614118, JString, required = true, default = newJString(
      "AmazonSSM.GetCalendarState"))
  if valid_614118 != nil:
    section.add "X-Amz-Target", valid_614118
  var valid_614119 = header.getOrDefault("X-Amz-Signature")
  valid_614119 = validateParameter(valid_614119, JString, required = false,
                                 default = nil)
  if valid_614119 != nil:
    section.add "X-Amz-Signature", valid_614119
  var valid_614120 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614120 = validateParameter(valid_614120, JString, required = false,
                                 default = nil)
  if valid_614120 != nil:
    section.add "X-Amz-Content-Sha256", valid_614120
  var valid_614121 = header.getOrDefault("X-Amz-Date")
  valid_614121 = validateParameter(valid_614121, JString, required = false,
                                 default = nil)
  if valid_614121 != nil:
    section.add "X-Amz-Date", valid_614121
  var valid_614122 = header.getOrDefault("X-Amz-Credential")
  valid_614122 = validateParameter(valid_614122, JString, required = false,
                                 default = nil)
  if valid_614122 != nil:
    section.add "X-Amz-Credential", valid_614122
  var valid_614123 = header.getOrDefault("X-Amz-Security-Token")
  valid_614123 = validateParameter(valid_614123, JString, required = false,
                                 default = nil)
  if valid_614123 != nil:
    section.add "X-Amz-Security-Token", valid_614123
  var valid_614124 = header.getOrDefault("X-Amz-Algorithm")
  valid_614124 = validateParameter(valid_614124, JString, required = false,
                                 default = nil)
  if valid_614124 != nil:
    section.add "X-Amz-Algorithm", valid_614124
  var valid_614125 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614125 = validateParameter(valid_614125, JString, required = false,
                                 default = nil)
  if valid_614125 != nil:
    section.add "X-Amz-SignedHeaders", valid_614125
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614127: Call_GetCalendarState_614115; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the state of the AWS Systems Manager Change Calendar at an optional, specified time. If you specify a time, <code>GetCalendarState</code> returns the state of the calendar at a specific time, and returns the next time that the Change Calendar state will transition. If you do not specify a time, <code>GetCalendarState</code> assumes the current time. Change Calendar entries have two possible states: <code>OPEN</code> or <code>CLOSED</code>. For more information about Systems Manager Change Calendar, see <a href="https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-change-calendar.html">AWS Systems Manager Change Calendar</a> in the <i>AWS Systems Manager User Guide</i>.
  ## 
  let valid = call_614127.validator(path, query, header, formData, body)
  let scheme = call_614127.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614127.url(scheme.get, call_614127.host, call_614127.base,
                         call_614127.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614127, url, valid)

proc call*(call_614128: Call_GetCalendarState_614115; body: JsonNode): Recallable =
  ## getCalendarState
  ## Gets the state of the AWS Systems Manager Change Calendar at an optional, specified time. If you specify a time, <code>GetCalendarState</code> returns the state of the calendar at a specific time, and returns the next time that the Change Calendar state will transition. If you do not specify a time, <code>GetCalendarState</code> assumes the current time. Change Calendar entries have two possible states: <code>OPEN</code> or <code>CLOSED</code>. For more information about Systems Manager Change Calendar, see <a href="https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-change-calendar.html">AWS Systems Manager Change Calendar</a> in the <i>AWS Systems Manager User Guide</i>.
  ##   body: JObject (required)
  var body_614129 = newJObject()
  if body != nil:
    body_614129 = body
  result = call_614128.call(nil, nil, nil, nil, body_614129)

var getCalendarState* = Call_GetCalendarState_614115(name: "getCalendarState",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetCalendarState",
    validator: validate_GetCalendarState_614116, base: "/",
    url: url_GetCalendarState_614117, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCommandInvocation_614130 = ref object of OpenApiRestCall_612658
proc url_GetCommandInvocation_614132(protocol: Scheme; host: string; base: string;
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

proc validate_GetCommandInvocation_614131(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns detailed information about command execution for an invocation or plugin. 
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
  var valid_614133 = header.getOrDefault("X-Amz-Target")
  valid_614133 = validateParameter(valid_614133, JString, required = true, default = newJString(
      "AmazonSSM.GetCommandInvocation"))
  if valid_614133 != nil:
    section.add "X-Amz-Target", valid_614133
  var valid_614134 = header.getOrDefault("X-Amz-Signature")
  valid_614134 = validateParameter(valid_614134, JString, required = false,
                                 default = nil)
  if valid_614134 != nil:
    section.add "X-Amz-Signature", valid_614134
  var valid_614135 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614135 = validateParameter(valid_614135, JString, required = false,
                                 default = nil)
  if valid_614135 != nil:
    section.add "X-Amz-Content-Sha256", valid_614135
  var valid_614136 = header.getOrDefault("X-Amz-Date")
  valid_614136 = validateParameter(valid_614136, JString, required = false,
                                 default = nil)
  if valid_614136 != nil:
    section.add "X-Amz-Date", valid_614136
  var valid_614137 = header.getOrDefault("X-Amz-Credential")
  valid_614137 = validateParameter(valid_614137, JString, required = false,
                                 default = nil)
  if valid_614137 != nil:
    section.add "X-Amz-Credential", valid_614137
  var valid_614138 = header.getOrDefault("X-Amz-Security-Token")
  valid_614138 = validateParameter(valid_614138, JString, required = false,
                                 default = nil)
  if valid_614138 != nil:
    section.add "X-Amz-Security-Token", valid_614138
  var valid_614139 = header.getOrDefault("X-Amz-Algorithm")
  valid_614139 = validateParameter(valid_614139, JString, required = false,
                                 default = nil)
  if valid_614139 != nil:
    section.add "X-Amz-Algorithm", valid_614139
  var valid_614140 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614140 = validateParameter(valid_614140, JString, required = false,
                                 default = nil)
  if valid_614140 != nil:
    section.add "X-Amz-SignedHeaders", valid_614140
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614142: Call_GetCommandInvocation_614130; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns detailed information about command execution for an invocation or plugin. 
  ## 
  let valid = call_614142.validator(path, query, header, formData, body)
  let scheme = call_614142.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614142.url(scheme.get, call_614142.host, call_614142.base,
                         call_614142.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614142, url, valid)

proc call*(call_614143: Call_GetCommandInvocation_614130; body: JsonNode): Recallable =
  ## getCommandInvocation
  ## Returns detailed information about command execution for an invocation or plugin. 
  ##   body: JObject (required)
  var body_614144 = newJObject()
  if body != nil:
    body_614144 = body
  result = call_614143.call(nil, nil, nil, nil, body_614144)

var getCommandInvocation* = Call_GetCommandInvocation_614130(
    name: "getCommandInvocation", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetCommandInvocation",
    validator: validate_GetCommandInvocation_614131, base: "/",
    url: url_GetCommandInvocation_614132, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnectionStatus_614145 = ref object of OpenApiRestCall_612658
proc url_GetConnectionStatus_614147(protocol: Scheme; host: string; base: string;
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

proc validate_GetConnectionStatus_614146(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Retrieves the Session Manager connection status for an instance to determine whether it is connected and ready to receive Session Manager connections.
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
  var valid_614148 = header.getOrDefault("X-Amz-Target")
  valid_614148 = validateParameter(valid_614148, JString, required = true, default = newJString(
      "AmazonSSM.GetConnectionStatus"))
  if valid_614148 != nil:
    section.add "X-Amz-Target", valid_614148
  var valid_614149 = header.getOrDefault("X-Amz-Signature")
  valid_614149 = validateParameter(valid_614149, JString, required = false,
                                 default = nil)
  if valid_614149 != nil:
    section.add "X-Amz-Signature", valid_614149
  var valid_614150 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614150 = validateParameter(valid_614150, JString, required = false,
                                 default = nil)
  if valid_614150 != nil:
    section.add "X-Amz-Content-Sha256", valid_614150
  var valid_614151 = header.getOrDefault("X-Amz-Date")
  valid_614151 = validateParameter(valid_614151, JString, required = false,
                                 default = nil)
  if valid_614151 != nil:
    section.add "X-Amz-Date", valid_614151
  var valid_614152 = header.getOrDefault("X-Amz-Credential")
  valid_614152 = validateParameter(valid_614152, JString, required = false,
                                 default = nil)
  if valid_614152 != nil:
    section.add "X-Amz-Credential", valid_614152
  var valid_614153 = header.getOrDefault("X-Amz-Security-Token")
  valid_614153 = validateParameter(valid_614153, JString, required = false,
                                 default = nil)
  if valid_614153 != nil:
    section.add "X-Amz-Security-Token", valid_614153
  var valid_614154 = header.getOrDefault("X-Amz-Algorithm")
  valid_614154 = validateParameter(valid_614154, JString, required = false,
                                 default = nil)
  if valid_614154 != nil:
    section.add "X-Amz-Algorithm", valid_614154
  var valid_614155 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614155 = validateParameter(valid_614155, JString, required = false,
                                 default = nil)
  if valid_614155 != nil:
    section.add "X-Amz-SignedHeaders", valid_614155
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614157: Call_GetConnectionStatus_614145; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the Session Manager connection status for an instance to determine whether it is connected and ready to receive Session Manager connections.
  ## 
  let valid = call_614157.validator(path, query, header, formData, body)
  let scheme = call_614157.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614157.url(scheme.get, call_614157.host, call_614157.base,
                         call_614157.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614157, url, valid)

proc call*(call_614158: Call_GetConnectionStatus_614145; body: JsonNode): Recallable =
  ## getConnectionStatus
  ## Retrieves the Session Manager connection status for an instance to determine whether it is connected and ready to receive Session Manager connections.
  ##   body: JObject (required)
  var body_614159 = newJObject()
  if body != nil:
    body_614159 = body
  result = call_614158.call(nil, nil, nil, nil, body_614159)

var getConnectionStatus* = Call_GetConnectionStatus_614145(
    name: "getConnectionStatus", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetConnectionStatus",
    validator: validate_GetConnectionStatus_614146, base: "/",
    url: url_GetConnectionStatus_614147, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefaultPatchBaseline_614160 = ref object of OpenApiRestCall_612658
proc url_GetDefaultPatchBaseline_614162(protocol: Scheme; host: string; base: string;
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

proc validate_GetDefaultPatchBaseline_614161(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves the default patch baseline. Note that Systems Manager supports creating multiple default patch baselines. For example, you can create a default patch baseline for each operating system.</p> <p>If you do not specify an operating system value, the default patch baseline for Windows is returned.</p>
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
  var valid_614163 = header.getOrDefault("X-Amz-Target")
  valid_614163 = validateParameter(valid_614163, JString, required = true, default = newJString(
      "AmazonSSM.GetDefaultPatchBaseline"))
  if valid_614163 != nil:
    section.add "X-Amz-Target", valid_614163
  var valid_614164 = header.getOrDefault("X-Amz-Signature")
  valid_614164 = validateParameter(valid_614164, JString, required = false,
                                 default = nil)
  if valid_614164 != nil:
    section.add "X-Amz-Signature", valid_614164
  var valid_614165 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614165 = validateParameter(valid_614165, JString, required = false,
                                 default = nil)
  if valid_614165 != nil:
    section.add "X-Amz-Content-Sha256", valid_614165
  var valid_614166 = header.getOrDefault("X-Amz-Date")
  valid_614166 = validateParameter(valid_614166, JString, required = false,
                                 default = nil)
  if valid_614166 != nil:
    section.add "X-Amz-Date", valid_614166
  var valid_614167 = header.getOrDefault("X-Amz-Credential")
  valid_614167 = validateParameter(valid_614167, JString, required = false,
                                 default = nil)
  if valid_614167 != nil:
    section.add "X-Amz-Credential", valid_614167
  var valid_614168 = header.getOrDefault("X-Amz-Security-Token")
  valid_614168 = validateParameter(valid_614168, JString, required = false,
                                 default = nil)
  if valid_614168 != nil:
    section.add "X-Amz-Security-Token", valid_614168
  var valid_614169 = header.getOrDefault("X-Amz-Algorithm")
  valid_614169 = validateParameter(valid_614169, JString, required = false,
                                 default = nil)
  if valid_614169 != nil:
    section.add "X-Amz-Algorithm", valid_614169
  var valid_614170 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614170 = validateParameter(valid_614170, JString, required = false,
                                 default = nil)
  if valid_614170 != nil:
    section.add "X-Amz-SignedHeaders", valid_614170
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614172: Call_GetDefaultPatchBaseline_614160; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the default patch baseline. Note that Systems Manager supports creating multiple default patch baselines. For example, you can create a default patch baseline for each operating system.</p> <p>If you do not specify an operating system value, the default patch baseline for Windows is returned.</p>
  ## 
  let valid = call_614172.validator(path, query, header, formData, body)
  let scheme = call_614172.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614172.url(scheme.get, call_614172.host, call_614172.base,
                         call_614172.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614172, url, valid)

proc call*(call_614173: Call_GetDefaultPatchBaseline_614160; body: JsonNode): Recallable =
  ## getDefaultPatchBaseline
  ## <p>Retrieves the default patch baseline. Note that Systems Manager supports creating multiple default patch baselines. For example, you can create a default patch baseline for each operating system.</p> <p>If you do not specify an operating system value, the default patch baseline for Windows is returned.</p>
  ##   body: JObject (required)
  var body_614174 = newJObject()
  if body != nil:
    body_614174 = body
  result = call_614173.call(nil, nil, nil, nil, body_614174)

var getDefaultPatchBaseline* = Call_GetDefaultPatchBaseline_614160(
    name: "getDefaultPatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetDefaultPatchBaseline",
    validator: validate_GetDefaultPatchBaseline_614161, base: "/",
    url: url_GetDefaultPatchBaseline_614162, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployablePatchSnapshotForInstance_614175 = ref object of OpenApiRestCall_612658
proc url_GetDeployablePatchSnapshotForInstance_614177(protocol: Scheme;
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

proc validate_GetDeployablePatchSnapshotForInstance_614176(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the current snapshot for the patch baseline the instance uses. This API is primarily used by the AWS-RunPatchBaseline Systems Manager document. 
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
  var valid_614178 = header.getOrDefault("X-Amz-Target")
  valid_614178 = validateParameter(valid_614178, JString, required = true, default = newJString(
      "AmazonSSM.GetDeployablePatchSnapshotForInstance"))
  if valid_614178 != nil:
    section.add "X-Amz-Target", valid_614178
  var valid_614179 = header.getOrDefault("X-Amz-Signature")
  valid_614179 = validateParameter(valid_614179, JString, required = false,
                                 default = nil)
  if valid_614179 != nil:
    section.add "X-Amz-Signature", valid_614179
  var valid_614180 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614180 = validateParameter(valid_614180, JString, required = false,
                                 default = nil)
  if valid_614180 != nil:
    section.add "X-Amz-Content-Sha256", valid_614180
  var valid_614181 = header.getOrDefault("X-Amz-Date")
  valid_614181 = validateParameter(valid_614181, JString, required = false,
                                 default = nil)
  if valid_614181 != nil:
    section.add "X-Amz-Date", valid_614181
  var valid_614182 = header.getOrDefault("X-Amz-Credential")
  valid_614182 = validateParameter(valid_614182, JString, required = false,
                                 default = nil)
  if valid_614182 != nil:
    section.add "X-Amz-Credential", valid_614182
  var valid_614183 = header.getOrDefault("X-Amz-Security-Token")
  valid_614183 = validateParameter(valid_614183, JString, required = false,
                                 default = nil)
  if valid_614183 != nil:
    section.add "X-Amz-Security-Token", valid_614183
  var valid_614184 = header.getOrDefault("X-Amz-Algorithm")
  valid_614184 = validateParameter(valid_614184, JString, required = false,
                                 default = nil)
  if valid_614184 != nil:
    section.add "X-Amz-Algorithm", valid_614184
  var valid_614185 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614185 = validateParameter(valid_614185, JString, required = false,
                                 default = nil)
  if valid_614185 != nil:
    section.add "X-Amz-SignedHeaders", valid_614185
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614187: Call_GetDeployablePatchSnapshotForInstance_614175;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the current snapshot for the patch baseline the instance uses. This API is primarily used by the AWS-RunPatchBaseline Systems Manager document. 
  ## 
  let valid = call_614187.validator(path, query, header, formData, body)
  let scheme = call_614187.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614187.url(scheme.get, call_614187.host, call_614187.base,
                         call_614187.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614187, url, valid)

proc call*(call_614188: Call_GetDeployablePatchSnapshotForInstance_614175;
          body: JsonNode): Recallable =
  ## getDeployablePatchSnapshotForInstance
  ## Retrieves the current snapshot for the patch baseline the instance uses. This API is primarily used by the AWS-RunPatchBaseline Systems Manager document. 
  ##   body: JObject (required)
  var body_614189 = newJObject()
  if body != nil:
    body_614189 = body
  result = call_614188.call(nil, nil, nil, nil, body_614189)

var getDeployablePatchSnapshotForInstance* = Call_GetDeployablePatchSnapshotForInstance_614175(
    name: "getDeployablePatchSnapshotForInstance", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetDeployablePatchSnapshotForInstance",
    validator: validate_GetDeployablePatchSnapshotForInstance_614176, base: "/",
    url: url_GetDeployablePatchSnapshotForInstance_614177,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocument_614190 = ref object of OpenApiRestCall_612658
proc url_GetDocument_614192(protocol: Scheme; host: string; base: string;
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

proc validate_GetDocument_614191(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the contents of the specified Systems Manager document.
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
  var valid_614193 = header.getOrDefault("X-Amz-Target")
  valid_614193 = validateParameter(valid_614193, JString, required = true,
                                 default = newJString("AmazonSSM.GetDocument"))
  if valid_614193 != nil:
    section.add "X-Amz-Target", valid_614193
  var valid_614194 = header.getOrDefault("X-Amz-Signature")
  valid_614194 = validateParameter(valid_614194, JString, required = false,
                                 default = nil)
  if valid_614194 != nil:
    section.add "X-Amz-Signature", valid_614194
  var valid_614195 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614195 = validateParameter(valid_614195, JString, required = false,
                                 default = nil)
  if valid_614195 != nil:
    section.add "X-Amz-Content-Sha256", valid_614195
  var valid_614196 = header.getOrDefault("X-Amz-Date")
  valid_614196 = validateParameter(valid_614196, JString, required = false,
                                 default = nil)
  if valid_614196 != nil:
    section.add "X-Amz-Date", valid_614196
  var valid_614197 = header.getOrDefault("X-Amz-Credential")
  valid_614197 = validateParameter(valid_614197, JString, required = false,
                                 default = nil)
  if valid_614197 != nil:
    section.add "X-Amz-Credential", valid_614197
  var valid_614198 = header.getOrDefault("X-Amz-Security-Token")
  valid_614198 = validateParameter(valid_614198, JString, required = false,
                                 default = nil)
  if valid_614198 != nil:
    section.add "X-Amz-Security-Token", valid_614198
  var valid_614199 = header.getOrDefault("X-Amz-Algorithm")
  valid_614199 = validateParameter(valid_614199, JString, required = false,
                                 default = nil)
  if valid_614199 != nil:
    section.add "X-Amz-Algorithm", valid_614199
  var valid_614200 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614200 = validateParameter(valid_614200, JString, required = false,
                                 default = nil)
  if valid_614200 != nil:
    section.add "X-Amz-SignedHeaders", valid_614200
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614202: Call_GetDocument_614190; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the contents of the specified Systems Manager document.
  ## 
  let valid = call_614202.validator(path, query, header, formData, body)
  let scheme = call_614202.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614202.url(scheme.get, call_614202.host, call_614202.base,
                         call_614202.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614202, url, valid)

proc call*(call_614203: Call_GetDocument_614190; body: JsonNode): Recallable =
  ## getDocument
  ## Gets the contents of the specified Systems Manager document.
  ##   body: JObject (required)
  var body_614204 = newJObject()
  if body != nil:
    body_614204 = body
  result = call_614203.call(nil, nil, nil, nil, body_614204)

var getDocument* = Call_GetDocument_614190(name: "getDocument",
                                        meth: HttpMethod.HttpPost,
                                        host: "ssm.amazonaws.com", route: "/#X-Amz-Target=AmazonSSM.GetDocument",
                                        validator: validate_GetDocument_614191,
                                        base: "/", url: url_GetDocument_614192,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInventory_614205 = ref object of OpenApiRestCall_612658
proc url_GetInventory_614207(protocol: Scheme; host: string; base: string;
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

proc validate_GetInventory_614206(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Query inventory information.
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
  var valid_614208 = header.getOrDefault("X-Amz-Target")
  valid_614208 = validateParameter(valid_614208, JString, required = true,
                                 default = newJString("AmazonSSM.GetInventory"))
  if valid_614208 != nil:
    section.add "X-Amz-Target", valid_614208
  var valid_614209 = header.getOrDefault("X-Amz-Signature")
  valid_614209 = validateParameter(valid_614209, JString, required = false,
                                 default = nil)
  if valid_614209 != nil:
    section.add "X-Amz-Signature", valid_614209
  var valid_614210 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614210 = validateParameter(valid_614210, JString, required = false,
                                 default = nil)
  if valid_614210 != nil:
    section.add "X-Amz-Content-Sha256", valid_614210
  var valid_614211 = header.getOrDefault("X-Amz-Date")
  valid_614211 = validateParameter(valid_614211, JString, required = false,
                                 default = nil)
  if valid_614211 != nil:
    section.add "X-Amz-Date", valid_614211
  var valid_614212 = header.getOrDefault("X-Amz-Credential")
  valid_614212 = validateParameter(valid_614212, JString, required = false,
                                 default = nil)
  if valid_614212 != nil:
    section.add "X-Amz-Credential", valid_614212
  var valid_614213 = header.getOrDefault("X-Amz-Security-Token")
  valid_614213 = validateParameter(valid_614213, JString, required = false,
                                 default = nil)
  if valid_614213 != nil:
    section.add "X-Amz-Security-Token", valid_614213
  var valid_614214 = header.getOrDefault("X-Amz-Algorithm")
  valid_614214 = validateParameter(valid_614214, JString, required = false,
                                 default = nil)
  if valid_614214 != nil:
    section.add "X-Amz-Algorithm", valid_614214
  var valid_614215 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614215 = validateParameter(valid_614215, JString, required = false,
                                 default = nil)
  if valid_614215 != nil:
    section.add "X-Amz-SignedHeaders", valid_614215
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614217: Call_GetInventory_614205; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Query inventory information.
  ## 
  let valid = call_614217.validator(path, query, header, formData, body)
  let scheme = call_614217.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614217.url(scheme.get, call_614217.host, call_614217.base,
                         call_614217.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614217, url, valid)

proc call*(call_614218: Call_GetInventory_614205; body: JsonNode): Recallable =
  ## getInventory
  ## Query inventory information.
  ##   body: JObject (required)
  var body_614219 = newJObject()
  if body != nil:
    body_614219 = body
  result = call_614218.call(nil, nil, nil, nil, body_614219)

var getInventory* = Call_GetInventory_614205(name: "getInventory",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetInventory",
    validator: validate_GetInventory_614206, base: "/", url: url_GetInventory_614207,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInventorySchema_614220 = ref object of OpenApiRestCall_612658
proc url_GetInventorySchema_614222(protocol: Scheme; host: string; base: string;
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

proc validate_GetInventorySchema_614221(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Return a list of inventory type names for the account, or return a list of attribute names for a specific Inventory item type. 
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
  var valid_614223 = header.getOrDefault("X-Amz-Target")
  valid_614223 = validateParameter(valid_614223, JString, required = true, default = newJString(
      "AmazonSSM.GetInventorySchema"))
  if valid_614223 != nil:
    section.add "X-Amz-Target", valid_614223
  var valid_614224 = header.getOrDefault("X-Amz-Signature")
  valid_614224 = validateParameter(valid_614224, JString, required = false,
                                 default = nil)
  if valid_614224 != nil:
    section.add "X-Amz-Signature", valid_614224
  var valid_614225 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614225 = validateParameter(valid_614225, JString, required = false,
                                 default = nil)
  if valid_614225 != nil:
    section.add "X-Amz-Content-Sha256", valid_614225
  var valid_614226 = header.getOrDefault("X-Amz-Date")
  valid_614226 = validateParameter(valid_614226, JString, required = false,
                                 default = nil)
  if valid_614226 != nil:
    section.add "X-Amz-Date", valid_614226
  var valid_614227 = header.getOrDefault("X-Amz-Credential")
  valid_614227 = validateParameter(valid_614227, JString, required = false,
                                 default = nil)
  if valid_614227 != nil:
    section.add "X-Amz-Credential", valid_614227
  var valid_614228 = header.getOrDefault("X-Amz-Security-Token")
  valid_614228 = validateParameter(valid_614228, JString, required = false,
                                 default = nil)
  if valid_614228 != nil:
    section.add "X-Amz-Security-Token", valid_614228
  var valid_614229 = header.getOrDefault("X-Amz-Algorithm")
  valid_614229 = validateParameter(valid_614229, JString, required = false,
                                 default = nil)
  if valid_614229 != nil:
    section.add "X-Amz-Algorithm", valid_614229
  var valid_614230 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614230 = validateParameter(valid_614230, JString, required = false,
                                 default = nil)
  if valid_614230 != nil:
    section.add "X-Amz-SignedHeaders", valid_614230
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614232: Call_GetInventorySchema_614220; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Return a list of inventory type names for the account, or return a list of attribute names for a specific Inventory item type. 
  ## 
  let valid = call_614232.validator(path, query, header, formData, body)
  let scheme = call_614232.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614232.url(scheme.get, call_614232.host, call_614232.base,
                         call_614232.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614232, url, valid)

proc call*(call_614233: Call_GetInventorySchema_614220; body: JsonNode): Recallable =
  ## getInventorySchema
  ## Return a list of inventory type names for the account, or return a list of attribute names for a specific Inventory item type. 
  ##   body: JObject (required)
  var body_614234 = newJObject()
  if body != nil:
    body_614234 = body
  result = call_614233.call(nil, nil, nil, nil, body_614234)

var getInventorySchema* = Call_GetInventorySchema_614220(
    name: "getInventorySchema", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetInventorySchema",
    validator: validate_GetInventorySchema_614221, base: "/",
    url: url_GetInventorySchema_614222, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMaintenanceWindow_614235 = ref object of OpenApiRestCall_612658
proc url_GetMaintenanceWindow_614237(protocol: Scheme; host: string; base: string;
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

proc validate_GetMaintenanceWindow_614236(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a maintenance window.
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
  var valid_614238 = header.getOrDefault("X-Amz-Target")
  valid_614238 = validateParameter(valid_614238, JString, required = true, default = newJString(
      "AmazonSSM.GetMaintenanceWindow"))
  if valid_614238 != nil:
    section.add "X-Amz-Target", valid_614238
  var valid_614239 = header.getOrDefault("X-Amz-Signature")
  valid_614239 = validateParameter(valid_614239, JString, required = false,
                                 default = nil)
  if valid_614239 != nil:
    section.add "X-Amz-Signature", valid_614239
  var valid_614240 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614240 = validateParameter(valid_614240, JString, required = false,
                                 default = nil)
  if valid_614240 != nil:
    section.add "X-Amz-Content-Sha256", valid_614240
  var valid_614241 = header.getOrDefault("X-Amz-Date")
  valid_614241 = validateParameter(valid_614241, JString, required = false,
                                 default = nil)
  if valid_614241 != nil:
    section.add "X-Amz-Date", valid_614241
  var valid_614242 = header.getOrDefault("X-Amz-Credential")
  valid_614242 = validateParameter(valid_614242, JString, required = false,
                                 default = nil)
  if valid_614242 != nil:
    section.add "X-Amz-Credential", valid_614242
  var valid_614243 = header.getOrDefault("X-Amz-Security-Token")
  valid_614243 = validateParameter(valid_614243, JString, required = false,
                                 default = nil)
  if valid_614243 != nil:
    section.add "X-Amz-Security-Token", valid_614243
  var valid_614244 = header.getOrDefault("X-Amz-Algorithm")
  valid_614244 = validateParameter(valid_614244, JString, required = false,
                                 default = nil)
  if valid_614244 != nil:
    section.add "X-Amz-Algorithm", valid_614244
  var valid_614245 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614245 = validateParameter(valid_614245, JString, required = false,
                                 default = nil)
  if valid_614245 != nil:
    section.add "X-Amz-SignedHeaders", valid_614245
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614247: Call_GetMaintenanceWindow_614235; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a maintenance window.
  ## 
  let valid = call_614247.validator(path, query, header, formData, body)
  let scheme = call_614247.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614247.url(scheme.get, call_614247.host, call_614247.base,
                         call_614247.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614247, url, valid)

proc call*(call_614248: Call_GetMaintenanceWindow_614235; body: JsonNode): Recallable =
  ## getMaintenanceWindow
  ## Retrieves a maintenance window.
  ##   body: JObject (required)
  var body_614249 = newJObject()
  if body != nil:
    body_614249 = body
  result = call_614248.call(nil, nil, nil, nil, body_614249)

var getMaintenanceWindow* = Call_GetMaintenanceWindow_614235(
    name: "getMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetMaintenanceWindow",
    validator: validate_GetMaintenanceWindow_614236, base: "/",
    url: url_GetMaintenanceWindow_614237, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMaintenanceWindowExecution_614250 = ref object of OpenApiRestCall_612658
proc url_GetMaintenanceWindowExecution_614252(protocol: Scheme; host: string;
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

proc validate_GetMaintenanceWindowExecution_614251(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves details about a specific a maintenance window execution.
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
  var valid_614253 = header.getOrDefault("X-Amz-Target")
  valid_614253 = validateParameter(valid_614253, JString, required = true, default = newJString(
      "AmazonSSM.GetMaintenanceWindowExecution"))
  if valid_614253 != nil:
    section.add "X-Amz-Target", valid_614253
  var valid_614254 = header.getOrDefault("X-Amz-Signature")
  valid_614254 = validateParameter(valid_614254, JString, required = false,
                                 default = nil)
  if valid_614254 != nil:
    section.add "X-Amz-Signature", valid_614254
  var valid_614255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614255 = validateParameter(valid_614255, JString, required = false,
                                 default = nil)
  if valid_614255 != nil:
    section.add "X-Amz-Content-Sha256", valid_614255
  var valid_614256 = header.getOrDefault("X-Amz-Date")
  valid_614256 = validateParameter(valid_614256, JString, required = false,
                                 default = nil)
  if valid_614256 != nil:
    section.add "X-Amz-Date", valid_614256
  var valid_614257 = header.getOrDefault("X-Amz-Credential")
  valid_614257 = validateParameter(valid_614257, JString, required = false,
                                 default = nil)
  if valid_614257 != nil:
    section.add "X-Amz-Credential", valid_614257
  var valid_614258 = header.getOrDefault("X-Amz-Security-Token")
  valid_614258 = validateParameter(valid_614258, JString, required = false,
                                 default = nil)
  if valid_614258 != nil:
    section.add "X-Amz-Security-Token", valid_614258
  var valid_614259 = header.getOrDefault("X-Amz-Algorithm")
  valid_614259 = validateParameter(valid_614259, JString, required = false,
                                 default = nil)
  if valid_614259 != nil:
    section.add "X-Amz-Algorithm", valid_614259
  var valid_614260 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614260 = validateParameter(valid_614260, JString, required = false,
                                 default = nil)
  if valid_614260 != nil:
    section.add "X-Amz-SignedHeaders", valid_614260
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614262: Call_GetMaintenanceWindowExecution_614250; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details about a specific a maintenance window execution.
  ## 
  let valid = call_614262.validator(path, query, header, formData, body)
  let scheme = call_614262.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614262.url(scheme.get, call_614262.host, call_614262.base,
                         call_614262.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614262, url, valid)

proc call*(call_614263: Call_GetMaintenanceWindowExecution_614250; body: JsonNode): Recallable =
  ## getMaintenanceWindowExecution
  ## Retrieves details about a specific a maintenance window execution.
  ##   body: JObject (required)
  var body_614264 = newJObject()
  if body != nil:
    body_614264 = body
  result = call_614263.call(nil, nil, nil, nil, body_614264)

var getMaintenanceWindowExecution* = Call_GetMaintenanceWindowExecution_614250(
    name: "getMaintenanceWindowExecution", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetMaintenanceWindowExecution",
    validator: validate_GetMaintenanceWindowExecution_614251, base: "/",
    url: url_GetMaintenanceWindowExecution_614252,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMaintenanceWindowExecutionTask_614265 = ref object of OpenApiRestCall_612658
proc url_GetMaintenanceWindowExecutionTask_614267(protocol: Scheme; host: string;
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

proc validate_GetMaintenanceWindowExecutionTask_614266(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the details about a specific task run as part of a maintenance window execution.
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
  var valid_614268 = header.getOrDefault("X-Amz-Target")
  valid_614268 = validateParameter(valid_614268, JString, required = true, default = newJString(
      "AmazonSSM.GetMaintenanceWindowExecutionTask"))
  if valid_614268 != nil:
    section.add "X-Amz-Target", valid_614268
  var valid_614269 = header.getOrDefault("X-Amz-Signature")
  valid_614269 = validateParameter(valid_614269, JString, required = false,
                                 default = nil)
  if valid_614269 != nil:
    section.add "X-Amz-Signature", valid_614269
  var valid_614270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614270 = validateParameter(valid_614270, JString, required = false,
                                 default = nil)
  if valid_614270 != nil:
    section.add "X-Amz-Content-Sha256", valid_614270
  var valid_614271 = header.getOrDefault("X-Amz-Date")
  valid_614271 = validateParameter(valid_614271, JString, required = false,
                                 default = nil)
  if valid_614271 != nil:
    section.add "X-Amz-Date", valid_614271
  var valid_614272 = header.getOrDefault("X-Amz-Credential")
  valid_614272 = validateParameter(valid_614272, JString, required = false,
                                 default = nil)
  if valid_614272 != nil:
    section.add "X-Amz-Credential", valid_614272
  var valid_614273 = header.getOrDefault("X-Amz-Security-Token")
  valid_614273 = validateParameter(valid_614273, JString, required = false,
                                 default = nil)
  if valid_614273 != nil:
    section.add "X-Amz-Security-Token", valid_614273
  var valid_614274 = header.getOrDefault("X-Amz-Algorithm")
  valid_614274 = validateParameter(valid_614274, JString, required = false,
                                 default = nil)
  if valid_614274 != nil:
    section.add "X-Amz-Algorithm", valid_614274
  var valid_614275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614275 = validateParameter(valid_614275, JString, required = false,
                                 default = nil)
  if valid_614275 != nil:
    section.add "X-Amz-SignedHeaders", valid_614275
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614277: Call_GetMaintenanceWindowExecutionTask_614265;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the details about a specific task run as part of a maintenance window execution.
  ## 
  let valid = call_614277.validator(path, query, header, formData, body)
  let scheme = call_614277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614277.url(scheme.get, call_614277.host, call_614277.base,
                         call_614277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614277, url, valid)

proc call*(call_614278: Call_GetMaintenanceWindowExecutionTask_614265;
          body: JsonNode): Recallable =
  ## getMaintenanceWindowExecutionTask
  ## Retrieves the details about a specific task run as part of a maintenance window execution.
  ##   body: JObject (required)
  var body_614279 = newJObject()
  if body != nil:
    body_614279 = body
  result = call_614278.call(nil, nil, nil, nil, body_614279)

var getMaintenanceWindowExecutionTask* = Call_GetMaintenanceWindowExecutionTask_614265(
    name: "getMaintenanceWindowExecutionTask", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetMaintenanceWindowExecutionTask",
    validator: validate_GetMaintenanceWindowExecutionTask_614266, base: "/",
    url: url_GetMaintenanceWindowExecutionTask_614267,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMaintenanceWindowExecutionTaskInvocation_614280 = ref object of OpenApiRestCall_612658
proc url_GetMaintenanceWindowExecutionTaskInvocation_614282(protocol: Scheme;
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

proc validate_GetMaintenanceWindowExecutionTaskInvocation_614281(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves information about a specific task running on a specific target.
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
  var valid_614283 = header.getOrDefault("X-Amz-Target")
  valid_614283 = validateParameter(valid_614283, JString, required = true, default = newJString(
      "AmazonSSM.GetMaintenanceWindowExecutionTaskInvocation"))
  if valid_614283 != nil:
    section.add "X-Amz-Target", valid_614283
  var valid_614284 = header.getOrDefault("X-Amz-Signature")
  valid_614284 = validateParameter(valid_614284, JString, required = false,
                                 default = nil)
  if valid_614284 != nil:
    section.add "X-Amz-Signature", valid_614284
  var valid_614285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614285 = validateParameter(valid_614285, JString, required = false,
                                 default = nil)
  if valid_614285 != nil:
    section.add "X-Amz-Content-Sha256", valid_614285
  var valid_614286 = header.getOrDefault("X-Amz-Date")
  valid_614286 = validateParameter(valid_614286, JString, required = false,
                                 default = nil)
  if valid_614286 != nil:
    section.add "X-Amz-Date", valid_614286
  var valid_614287 = header.getOrDefault("X-Amz-Credential")
  valid_614287 = validateParameter(valid_614287, JString, required = false,
                                 default = nil)
  if valid_614287 != nil:
    section.add "X-Amz-Credential", valid_614287
  var valid_614288 = header.getOrDefault("X-Amz-Security-Token")
  valid_614288 = validateParameter(valid_614288, JString, required = false,
                                 default = nil)
  if valid_614288 != nil:
    section.add "X-Amz-Security-Token", valid_614288
  var valid_614289 = header.getOrDefault("X-Amz-Algorithm")
  valid_614289 = validateParameter(valid_614289, JString, required = false,
                                 default = nil)
  if valid_614289 != nil:
    section.add "X-Amz-Algorithm", valid_614289
  var valid_614290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614290 = validateParameter(valid_614290, JString, required = false,
                                 default = nil)
  if valid_614290 != nil:
    section.add "X-Amz-SignedHeaders", valid_614290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614292: Call_GetMaintenanceWindowExecutionTaskInvocation_614280;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves information about a specific task running on a specific target.
  ## 
  let valid = call_614292.validator(path, query, header, formData, body)
  let scheme = call_614292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614292.url(scheme.get, call_614292.host, call_614292.base,
                         call_614292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614292, url, valid)

proc call*(call_614293: Call_GetMaintenanceWindowExecutionTaskInvocation_614280;
          body: JsonNode): Recallable =
  ## getMaintenanceWindowExecutionTaskInvocation
  ## Retrieves information about a specific task running on a specific target.
  ##   body: JObject (required)
  var body_614294 = newJObject()
  if body != nil:
    body_614294 = body
  result = call_614293.call(nil, nil, nil, nil, body_614294)

var getMaintenanceWindowExecutionTaskInvocation* = Call_GetMaintenanceWindowExecutionTaskInvocation_614280(
    name: "getMaintenanceWindowExecutionTaskInvocation",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com", route: "/#X-Amz-Target=AmazonSSM.GetMaintenanceWindowExecutionTaskInvocation",
    validator: validate_GetMaintenanceWindowExecutionTaskInvocation_614281,
    base: "/", url: url_GetMaintenanceWindowExecutionTaskInvocation_614282,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMaintenanceWindowTask_614295 = ref object of OpenApiRestCall_612658
proc url_GetMaintenanceWindowTask_614297(protocol: Scheme; host: string;
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

proc validate_GetMaintenanceWindowTask_614296(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the tasks in a maintenance window.
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
  var valid_614298 = header.getOrDefault("X-Amz-Target")
  valid_614298 = validateParameter(valid_614298, JString, required = true, default = newJString(
      "AmazonSSM.GetMaintenanceWindowTask"))
  if valid_614298 != nil:
    section.add "X-Amz-Target", valid_614298
  var valid_614299 = header.getOrDefault("X-Amz-Signature")
  valid_614299 = validateParameter(valid_614299, JString, required = false,
                                 default = nil)
  if valid_614299 != nil:
    section.add "X-Amz-Signature", valid_614299
  var valid_614300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614300 = validateParameter(valid_614300, JString, required = false,
                                 default = nil)
  if valid_614300 != nil:
    section.add "X-Amz-Content-Sha256", valid_614300
  var valid_614301 = header.getOrDefault("X-Amz-Date")
  valid_614301 = validateParameter(valid_614301, JString, required = false,
                                 default = nil)
  if valid_614301 != nil:
    section.add "X-Amz-Date", valid_614301
  var valid_614302 = header.getOrDefault("X-Amz-Credential")
  valid_614302 = validateParameter(valid_614302, JString, required = false,
                                 default = nil)
  if valid_614302 != nil:
    section.add "X-Amz-Credential", valid_614302
  var valid_614303 = header.getOrDefault("X-Amz-Security-Token")
  valid_614303 = validateParameter(valid_614303, JString, required = false,
                                 default = nil)
  if valid_614303 != nil:
    section.add "X-Amz-Security-Token", valid_614303
  var valid_614304 = header.getOrDefault("X-Amz-Algorithm")
  valid_614304 = validateParameter(valid_614304, JString, required = false,
                                 default = nil)
  if valid_614304 != nil:
    section.add "X-Amz-Algorithm", valid_614304
  var valid_614305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614305 = validateParameter(valid_614305, JString, required = false,
                                 default = nil)
  if valid_614305 != nil:
    section.add "X-Amz-SignedHeaders", valid_614305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614307: Call_GetMaintenanceWindowTask_614295; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tasks in a maintenance window.
  ## 
  let valid = call_614307.validator(path, query, header, formData, body)
  let scheme = call_614307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614307.url(scheme.get, call_614307.host, call_614307.base,
                         call_614307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614307, url, valid)

proc call*(call_614308: Call_GetMaintenanceWindowTask_614295; body: JsonNode): Recallable =
  ## getMaintenanceWindowTask
  ## Lists the tasks in a maintenance window.
  ##   body: JObject (required)
  var body_614309 = newJObject()
  if body != nil:
    body_614309 = body
  result = call_614308.call(nil, nil, nil, nil, body_614309)

var getMaintenanceWindowTask* = Call_GetMaintenanceWindowTask_614295(
    name: "getMaintenanceWindowTask", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetMaintenanceWindowTask",
    validator: validate_GetMaintenanceWindowTask_614296, base: "/",
    url: url_GetMaintenanceWindowTask_614297, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOpsItem_614310 = ref object of OpenApiRestCall_612658
proc url_GetOpsItem_614312(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetOpsItem_614311(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Get information about an OpsItem by using the ID. You must have permission in AWS Identity and Access Management (IAM) to view information about an OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
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
  var valid_614313 = header.getOrDefault("X-Amz-Target")
  valid_614313 = validateParameter(valid_614313, JString, required = true,
                                 default = newJString("AmazonSSM.GetOpsItem"))
  if valid_614313 != nil:
    section.add "X-Amz-Target", valid_614313
  var valid_614314 = header.getOrDefault("X-Amz-Signature")
  valid_614314 = validateParameter(valid_614314, JString, required = false,
                                 default = nil)
  if valid_614314 != nil:
    section.add "X-Amz-Signature", valid_614314
  var valid_614315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614315 = validateParameter(valid_614315, JString, required = false,
                                 default = nil)
  if valid_614315 != nil:
    section.add "X-Amz-Content-Sha256", valid_614315
  var valid_614316 = header.getOrDefault("X-Amz-Date")
  valid_614316 = validateParameter(valid_614316, JString, required = false,
                                 default = nil)
  if valid_614316 != nil:
    section.add "X-Amz-Date", valid_614316
  var valid_614317 = header.getOrDefault("X-Amz-Credential")
  valid_614317 = validateParameter(valid_614317, JString, required = false,
                                 default = nil)
  if valid_614317 != nil:
    section.add "X-Amz-Credential", valid_614317
  var valid_614318 = header.getOrDefault("X-Amz-Security-Token")
  valid_614318 = validateParameter(valid_614318, JString, required = false,
                                 default = nil)
  if valid_614318 != nil:
    section.add "X-Amz-Security-Token", valid_614318
  var valid_614319 = header.getOrDefault("X-Amz-Algorithm")
  valid_614319 = validateParameter(valid_614319, JString, required = false,
                                 default = nil)
  if valid_614319 != nil:
    section.add "X-Amz-Algorithm", valid_614319
  var valid_614320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614320 = validateParameter(valid_614320, JString, required = false,
                                 default = nil)
  if valid_614320 != nil:
    section.add "X-Amz-SignedHeaders", valid_614320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614322: Call_GetOpsItem_614310; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Get information about an OpsItem by using the ID. You must have permission in AWS Identity and Access Management (IAM) to view information about an OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ## 
  let valid = call_614322.validator(path, query, header, formData, body)
  let scheme = call_614322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614322.url(scheme.get, call_614322.host, call_614322.base,
                         call_614322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614322, url, valid)

proc call*(call_614323: Call_GetOpsItem_614310; body: JsonNode): Recallable =
  ## getOpsItem
  ## <p>Get information about an OpsItem by using the ID. You must have permission in AWS Identity and Access Management (IAM) to view information about an OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ##   body: JObject (required)
  var body_614324 = newJObject()
  if body != nil:
    body_614324 = body
  result = call_614323.call(nil, nil, nil, nil, body_614324)

var getOpsItem* = Call_GetOpsItem_614310(name: "getOpsItem",
                                      meth: HttpMethod.HttpPost,
                                      host: "ssm.amazonaws.com", route: "/#X-Amz-Target=AmazonSSM.GetOpsItem",
                                      validator: validate_GetOpsItem_614311,
                                      base: "/", url: url_GetOpsItem_614312,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOpsSummary_614325 = ref object of OpenApiRestCall_612658
proc url_GetOpsSummary_614327(protocol: Scheme; host: string; base: string;
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

proc validate_GetOpsSummary_614326(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## View a summary of OpsItems based on specified filters and aggregators.
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
  var valid_614328 = header.getOrDefault("X-Amz-Target")
  valid_614328 = validateParameter(valid_614328, JString, required = true, default = newJString(
      "AmazonSSM.GetOpsSummary"))
  if valid_614328 != nil:
    section.add "X-Amz-Target", valid_614328
  var valid_614329 = header.getOrDefault("X-Amz-Signature")
  valid_614329 = validateParameter(valid_614329, JString, required = false,
                                 default = nil)
  if valid_614329 != nil:
    section.add "X-Amz-Signature", valid_614329
  var valid_614330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614330 = validateParameter(valid_614330, JString, required = false,
                                 default = nil)
  if valid_614330 != nil:
    section.add "X-Amz-Content-Sha256", valid_614330
  var valid_614331 = header.getOrDefault("X-Amz-Date")
  valid_614331 = validateParameter(valid_614331, JString, required = false,
                                 default = nil)
  if valid_614331 != nil:
    section.add "X-Amz-Date", valid_614331
  var valid_614332 = header.getOrDefault("X-Amz-Credential")
  valid_614332 = validateParameter(valid_614332, JString, required = false,
                                 default = nil)
  if valid_614332 != nil:
    section.add "X-Amz-Credential", valid_614332
  var valid_614333 = header.getOrDefault("X-Amz-Security-Token")
  valid_614333 = validateParameter(valid_614333, JString, required = false,
                                 default = nil)
  if valid_614333 != nil:
    section.add "X-Amz-Security-Token", valid_614333
  var valid_614334 = header.getOrDefault("X-Amz-Algorithm")
  valid_614334 = validateParameter(valid_614334, JString, required = false,
                                 default = nil)
  if valid_614334 != nil:
    section.add "X-Amz-Algorithm", valid_614334
  var valid_614335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614335 = validateParameter(valid_614335, JString, required = false,
                                 default = nil)
  if valid_614335 != nil:
    section.add "X-Amz-SignedHeaders", valid_614335
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614337: Call_GetOpsSummary_614325; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## View a summary of OpsItems based on specified filters and aggregators.
  ## 
  let valid = call_614337.validator(path, query, header, formData, body)
  let scheme = call_614337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614337.url(scheme.get, call_614337.host, call_614337.base,
                         call_614337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614337, url, valid)

proc call*(call_614338: Call_GetOpsSummary_614325; body: JsonNode): Recallable =
  ## getOpsSummary
  ## View a summary of OpsItems based on specified filters and aggregators.
  ##   body: JObject (required)
  var body_614339 = newJObject()
  if body != nil:
    body_614339 = body
  result = call_614338.call(nil, nil, nil, nil, body_614339)

var getOpsSummary* = Call_GetOpsSummary_614325(name: "getOpsSummary",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetOpsSummary",
    validator: validate_GetOpsSummary_614326, base: "/", url: url_GetOpsSummary_614327,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetParameter_614340 = ref object of OpenApiRestCall_612658
proc url_GetParameter_614342(protocol: Scheme; host: string; base: string;
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

proc validate_GetParameter_614341(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Get information about a parameter by using the parameter name. Don't confuse this API action with the <a>GetParameters</a> API action.
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
  var valid_614343 = header.getOrDefault("X-Amz-Target")
  valid_614343 = validateParameter(valid_614343, JString, required = true,
                                 default = newJString("AmazonSSM.GetParameter"))
  if valid_614343 != nil:
    section.add "X-Amz-Target", valid_614343
  var valid_614344 = header.getOrDefault("X-Amz-Signature")
  valid_614344 = validateParameter(valid_614344, JString, required = false,
                                 default = nil)
  if valid_614344 != nil:
    section.add "X-Amz-Signature", valid_614344
  var valid_614345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614345 = validateParameter(valid_614345, JString, required = false,
                                 default = nil)
  if valid_614345 != nil:
    section.add "X-Amz-Content-Sha256", valid_614345
  var valid_614346 = header.getOrDefault("X-Amz-Date")
  valid_614346 = validateParameter(valid_614346, JString, required = false,
                                 default = nil)
  if valid_614346 != nil:
    section.add "X-Amz-Date", valid_614346
  var valid_614347 = header.getOrDefault("X-Amz-Credential")
  valid_614347 = validateParameter(valid_614347, JString, required = false,
                                 default = nil)
  if valid_614347 != nil:
    section.add "X-Amz-Credential", valid_614347
  var valid_614348 = header.getOrDefault("X-Amz-Security-Token")
  valid_614348 = validateParameter(valid_614348, JString, required = false,
                                 default = nil)
  if valid_614348 != nil:
    section.add "X-Amz-Security-Token", valid_614348
  var valid_614349 = header.getOrDefault("X-Amz-Algorithm")
  valid_614349 = validateParameter(valid_614349, JString, required = false,
                                 default = nil)
  if valid_614349 != nil:
    section.add "X-Amz-Algorithm", valid_614349
  var valid_614350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614350 = validateParameter(valid_614350, JString, required = false,
                                 default = nil)
  if valid_614350 != nil:
    section.add "X-Amz-SignedHeaders", valid_614350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614352: Call_GetParameter_614340; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get information about a parameter by using the parameter name. Don't confuse this API action with the <a>GetParameters</a> API action.
  ## 
  let valid = call_614352.validator(path, query, header, formData, body)
  let scheme = call_614352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614352.url(scheme.get, call_614352.host, call_614352.base,
                         call_614352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614352, url, valid)

proc call*(call_614353: Call_GetParameter_614340; body: JsonNode): Recallable =
  ## getParameter
  ## Get information about a parameter by using the parameter name. Don't confuse this API action with the <a>GetParameters</a> API action.
  ##   body: JObject (required)
  var body_614354 = newJObject()
  if body != nil:
    body_614354 = body
  result = call_614353.call(nil, nil, nil, nil, body_614354)

var getParameter* = Call_GetParameter_614340(name: "getParameter",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetParameter",
    validator: validate_GetParameter_614341, base: "/", url: url_GetParameter_614342,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetParameterHistory_614355 = ref object of OpenApiRestCall_612658
proc url_GetParameterHistory_614357(protocol: Scheme; host: string; base: string;
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

proc validate_GetParameterHistory_614356(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Query a list of all parameters used by the AWS account.
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
  var valid_614358 = query.getOrDefault("MaxResults")
  valid_614358 = validateParameter(valid_614358, JString, required = false,
                                 default = nil)
  if valid_614358 != nil:
    section.add "MaxResults", valid_614358
  var valid_614359 = query.getOrDefault("NextToken")
  valid_614359 = validateParameter(valid_614359, JString, required = false,
                                 default = nil)
  if valid_614359 != nil:
    section.add "NextToken", valid_614359
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
  var valid_614360 = header.getOrDefault("X-Amz-Target")
  valid_614360 = validateParameter(valid_614360, JString, required = true, default = newJString(
      "AmazonSSM.GetParameterHistory"))
  if valid_614360 != nil:
    section.add "X-Amz-Target", valid_614360
  var valid_614361 = header.getOrDefault("X-Amz-Signature")
  valid_614361 = validateParameter(valid_614361, JString, required = false,
                                 default = nil)
  if valid_614361 != nil:
    section.add "X-Amz-Signature", valid_614361
  var valid_614362 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614362 = validateParameter(valid_614362, JString, required = false,
                                 default = nil)
  if valid_614362 != nil:
    section.add "X-Amz-Content-Sha256", valid_614362
  var valid_614363 = header.getOrDefault("X-Amz-Date")
  valid_614363 = validateParameter(valid_614363, JString, required = false,
                                 default = nil)
  if valid_614363 != nil:
    section.add "X-Amz-Date", valid_614363
  var valid_614364 = header.getOrDefault("X-Amz-Credential")
  valid_614364 = validateParameter(valid_614364, JString, required = false,
                                 default = nil)
  if valid_614364 != nil:
    section.add "X-Amz-Credential", valid_614364
  var valid_614365 = header.getOrDefault("X-Amz-Security-Token")
  valid_614365 = validateParameter(valid_614365, JString, required = false,
                                 default = nil)
  if valid_614365 != nil:
    section.add "X-Amz-Security-Token", valid_614365
  var valid_614366 = header.getOrDefault("X-Amz-Algorithm")
  valid_614366 = validateParameter(valid_614366, JString, required = false,
                                 default = nil)
  if valid_614366 != nil:
    section.add "X-Amz-Algorithm", valid_614366
  var valid_614367 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614367 = validateParameter(valid_614367, JString, required = false,
                                 default = nil)
  if valid_614367 != nil:
    section.add "X-Amz-SignedHeaders", valid_614367
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614369: Call_GetParameterHistory_614355; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Query a list of all parameters used by the AWS account.
  ## 
  let valid = call_614369.validator(path, query, header, formData, body)
  let scheme = call_614369.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614369.url(scheme.get, call_614369.host, call_614369.base,
                         call_614369.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614369, url, valid)

proc call*(call_614370: Call_GetParameterHistory_614355; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getParameterHistory
  ## Query a list of all parameters used by the AWS account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614371 = newJObject()
  var body_614372 = newJObject()
  add(query_614371, "MaxResults", newJString(MaxResults))
  add(query_614371, "NextToken", newJString(NextToken))
  if body != nil:
    body_614372 = body
  result = call_614370.call(nil, query_614371, nil, nil, body_614372)

var getParameterHistory* = Call_GetParameterHistory_614355(
    name: "getParameterHistory", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetParameterHistory",
    validator: validate_GetParameterHistory_614356, base: "/",
    url: url_GetParameterHistory_614357, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetParameters_614373 = ref object of OpenApiRestCall_612658
proc url_GetParameters_614375(protocol: Scheme; host: string; base: string;
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

proc validate_GetParameters_614374(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Get details of a parameter. Don't confuse this API action with the <a>GetParameter</a> API action.
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
  var valid_614376 = header.getOrDefault("X-Amz-Target")
  valid_614376 = validateParameter(valid_614376, JString, required = true, default = newJString(
      "AmazonSSM.GetParameters"))
  if valid_614376 != nil:
    section.add "X-Amz-Target", valid_614376
  var valid_614377 = header.getOrDefault("X-Amz-Signature")
  valid_614377 = validateParameter(valid_614377, JString, required = false,
                                 default = nil)
  if valid_614377 != nil:
    section.add "X-Amz-Signature", valid_614377
  var valid_614378 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614378 = validateParameter(valid_614378, JString, required = false,
                                 default = nil)
  if valid_614378 != nil:
    section.add "X-Amz-Content-Sha256", valid_614378
  var valid_614379 = header.getOrDefault("X-Amz-Date")
  valid_614379 = validateParameter(valid_614379, JString, required = false,
                                 default = nil)
  if valid_614379 != nil:
    section.add "X-Amz-Date", valid_614379
  var valid_614380 = header.getOrDefault("X-Amz-Credential")
  valid_614380 = validateParameter(valid_614380, JString, required = false,
                                 default = nil)
  if valid_614380 != nil:
    section.add "X-Amz-Credential", valid_614380
  var valid_614381 = header.getOrDefault("X-Amz-Security-Token")
  valid_614381 = validateParameter(valid_614381, JString, required = false,
                                 default = nil)
  if valid_614381 != nil:
    section.add "X-Amz-Security-Token", valid_614381
  var valid_614382 = header.getOrDefault("X-Amz-Algorithm")
  valid_614382 = validateParameter(valid_614382, JString, required = false,
                                 default = nil)
  if valid_614382 != nil:
    section.add "X-Amz-Algorithm", valid_614382
  var valid_614383 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614383 = validateParameter(valid_614383, JString, required = false,
                                 default = nil)
  if valid_614383 != nil:
    section.add "X-Amz-SignedHeaders", valid_614383
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614385: Call_GetParameters_614373; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get details of a parameter. Don't confuse this API action with the <a>GetParameter</a> API action.
  ## 
  let valid = call_614385.validator(path, query, header, formData, body)
  let scheme = call_614385.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614385.url(scheme.get, call_614385.host, call_614385.base,
                         call_614385.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614385, url, valid)

proc call*(call_614386: Call_GetParameters_614373; body: JsonNode): Recallable =
  ## getParameters
  ## Get details of a parameter. Don't confuse this API action with the <a>GetParameter</a> API action.
  ##   body: JObject (required)
  var body_614387 = newJObject()
  if body != nil:
    body_614387 = body
  result = call_614386.call(nil, nil, nil, nil, body_614387)

var getParameters* = Call_GetParameters_614373(name: "getParameters",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetParameters",
    validator: validate_GetParameters_614374, base: "/", url: url_GetParameters_614375,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetParametersByPath_614388 = ref object of OpenApiRestCall_612658
proc url_GetParametersByPath_614390(protocol: Scheme; host: string; base: string;
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

proc validate_GetParametersByPath_614389(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Retrieve information about one or more parameters in a specific hierarchy. </p> <note> <p>Request results are returned on a best-effort basis. If you specify <code>MaxResults</code> in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of <code>MaxResults</code>. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a <code>NextToken</code>. You can specify the <code>NextToken</code> in a subsequent call to get the next set of results.</p> </note>
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
  var valid_614391 = query.getOrDefault("MaxResults")
  valid_614391 = validateParameter(valid_614391, JString, required = false,
                                 default = nil)
  if valid_614391 != nil:
    section.add "MaxResults", valid_614391
  var valid_614392 = query.getOrDefault("NextToken")
  valid_614392 = validateParameter(valid_614392, JString, required = false,
                                 default = nil)
  if valid_614392 != nil:
    section.add "NextToken", valid_614392
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
  var valid_614393 = header.getOrDefault("X-Amz-Target")
  valid_614393 = validateParameter(valid_614393, JString, required = true, default = newJString(
      "AmazonSSM.GetParametersByPath"))
  if valid_614393 != nil:
    section.add "X-Amz-Target", valid_614393
  var valid_614394 = header.getOrDefault("X-Amz-Signature")
  valid_614394 = validateParameter(valid_614394, JString, required = false,
                                 default = nil)
  if valid_614394 != nil:
    section.add "X-Amz-Signature", valid_614394
  var valid_614395 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614395 = validateParameter(valid_614395, JString, required = false,
                                 default = nil)
  if valid_614395 != nil:
    section.add "X-Amz-Content-Sha256", valid_614395
  var valid_614396 = header.getOrDefault("X-Amz-Date")
  valid_614396 = validateParameter(valid_614396, JString, required = false,
                                 default = nil)
  if valid_614396 != nil:
    section.add "X-Amz-Date", valid_614396
  var valid_614397 = header.getOrDefault("X-Amz-Credential")
  valid_614397 = validateParameter(valid_614397, JString, required = false,
                                 default = nil)
  if valid_614397 != nil:
    section.add "X-Amz-Credential", valid_614397
  var valid_614398 = header.getOrDefault("X-Amz-Security-Token")
  valid_614398 = validateParameter(valid_614398, JString, required = false,
                                 default = nil)
  if valid_614398 != nil:
    section.add "X-Amz-Security-Token", valid_614398
  var valid_614399 = header.getOrDefault("X-Amz-Algorithm")
  valid_614399 = validateParameter(valid_614399, JString, required = false,
                                 default = nil)
  if valid_614399 != nil:
    section.add "X-Amz-Algorithm", valid_614399
  var valid_614400 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614400 = validateParameter(valid_614400, JString, required = false,
                                 default = nil)
  if valid_614400 != nil:
    section.add "X-Amz-SignedHeaders", valid_614400
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614402: Call_GetParametersByPath_614388; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieve information about one or more parameters in a specific hierarchy. </p> <note> <p>Request results are returned on a best-effort basis. If you specify <code>MaxResults</code> in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of <code>MaxResults</code>. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a <code>NextToken</code>. You can specify the <code>NextToken</code> in a subsequent call to get the next set of results.</p> </note>
  ## 
  let valid = call_614402.validator(path, query, header, formData, body)
  let scheme = call_614402.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614402.url(scheme.get, call_614402.host, call_614402.base,
                         call_614402.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614402, url, valid)

proc call*(call_614403: Call_GetParametersByPath_614388; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getParametersByPath
  ## <p>Retrieve information about one or more parameters in a specific hierarchy. </p> <note> <p>Request results are returned on a best-effort basis. If you specify <code>MaxResults</code> in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of <code>MaxResults</code>. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a <code>NextToken</code>. You can specify the <code>NextToken</code> in a subsequent call to get the next set of results.</p> </note>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614404 = newJObject()
  var body_614405 = newJObject()
  add(query_614404, "MaxResults", newJString(MaxResults))
  add(query_614404, "NextToken", newJString(NextToken))
  if body != nil:
    body_614405 = body
  result = call_614403.call(nil, query_614404, nil, nil, body_614405)

var getParametersByPath* = Call_GetParametersByPath_614388(
    name: "getParametersByPath", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetParametersByPath",
    validator: validate_GetParametersByPath_614389, base: "/",
    url: url_GetParametersByPath_614390, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPatchBaseline_614406 = ref object of OpenApiRestCall_612658
proc url_GetPatchBaseline_614408(protocol: Scheme; host: string; base: string;
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

proc validate_GetPatchBaseline_614407(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Retrieves information about a patch baseline.
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
  var valid_614409 = header.getOrDefault("X-Amz-Target")
  valid_614409 = validateParameter(valid_614409, JString, required = true, default = newJString(
      "AmazonSSM.GetPatchBaseline"))
  if valid_614409 != nil:
    section.add "X-Amz-Target", valid_614409
  var valid_614410 = header.getOrDefault("X-Amz-Signature")
  valid_614410 = validateParameter(valid_614410, JString, required = false,
                                 default = nil)
  if valid_614410 != nil:
    section.add "X-Amz-Signature", valid_614410
  var valid_614411 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614411 = validateParameter(valid_614411, JString, required = false,
                                 default = nil)
  if valid_614411 != nil:
    section.add "X-Amz-Content-Sha256", valid_614411
  var valid_614412 = header.getOrDefault("X-Amz-Date")
  valid_614412 = validateParameter(valid_614412, JString, required = false,
                                 default = nil)
  if valid_614412 != nil:
    section.add "X-Amz-Date", valid_614412
  var valid_614413 = header.getOrDefault("X-Amz-Credential")
  valid_614413 = validateParameter(valid_614413, JString, required = false,
                                 default = nil)
  if valid_614413 != nil:
    section.add "X-Amz-Credential", valid_614413
  var valid_614414 = header.getOrDefault("X-Amz-Security-Token")
  valid_614414 = validateParameter(valid_614414, JString, required = false,
                                 default = nil)
  if valid_614414 != nil:
    section.add "X-Amz-Security-Token", valid_614414
  var valid_614415 = header.getOrDefault("X-Amz-Algorithm")
  valid_614415 = validateParameter(valid_614415, JString, required = false,
                                 default = nil)
  if valid_614415 != nil:
    section.add "X-Amz-Algorithm", valid_614415
  var valid_614416 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614416 = validateParameter(valid_614416, JString, required = false,
                                 default = nil)
  if valid_614416 != nil:
    section.add "X-Amz-SignedHeaders", valid_614416
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614418: Call_GetPatchBaseline_614406; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a patch baseline.
  ## 
  let valid = call_614418.validator(path, query, header, formData, body)
  let scheme = call_614418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614418.url(scheme.get, call_614418.host, call_614418.base,
                         call_614418.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614418, url, valid)

proc call*(call_614419: Call_GetPatchBaseline_614406; body: JsonNode): Recallable =
  ## getPatchBaseline
  ## Retrieves information about a patch baseline.
  ##   body: JObject (required)
  var body_614420 = newJObject()
  if body != nil:
    body_614420 = body
  result = call_614419.call(nil, nil, nil, nil, body_614420)

var getPatchBaseline* = Call_GetPatchBaseline_614406(name: "getPatchBaseline",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetPatchBaseline",
    validator: validate_GetPatchBaseline_614407, base: "/",
    url: url_GetPatchBaseline_614408, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPatchBaselineForPatchGroup_614421 = ref object of OpenApiRestCall_612658
proc url_GetPatchBaselineForPatchGroup_614423(protocol: Scheme; host: string;
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

proc validate_GetPatchBaselineForPatchGroup_614422(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the patch baseline that should be used for the specified patch group.
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
  var valid_614424 = header.getOrDefault("X-Amz-Target")
  valid_614424 = validateParameter(valid_614424, JString, required = true, default = newJString(
      "AmazonSSM.GetPatchBaselineForPatchGroup"))
  if valid_614424 != nil:
    section.add "X-Amz-Target", valid_614424
  var valid_614425 = header.getOrDefault("X-Amz-Signature")
  valid_614425 = validateParameter(valid_614425, JString, required = false,
                                 default = nil)
  if valid_614425 != nil:
    section.add "X-Amz-Signature", valid_614425
  var valid_614426 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614426 = validateParameter(valid_614426, JString, required = false,
                                 default = nil)
  if valid_614426 != nil:
    section.add "X-Amz-Content-Sha256", valid_614426
  var valid_614427 = header.getOrDefault("X-Amz-Date")
  valid_614427 = validateParameter(valid_614427, JString, required = false,
                                 default = nil)
  if valid_614427 != nil:
    section.add "X-Amz-Date", valid_614427
  var valid_614428 = header.getOrDefault("X-Amz-Credential")
  valid_614428 = validateParameter(valid_614428, JString, required = false,
                                 default = nil)
  if valid_614428 != nil:
    section.add "X-Amz-Credential", valid_614428
  var valid_614429 = header.getOrDefault("X-Amz-Security-Token")
  valid_614429 = validateParameter(valid_614429, JString, required = false,
                                 default = nil)
  if valid_614429 != nil:
    section.add "X-Amz-Security-Token", valid_614429
  var valid_614430 = header.getOrDefault("X-Amz-Algorithm")
  valid_614430 = validateParameter(valid_614430, JString, required = false,
                                 default = nil)
  if valid_614430 != nil:
    section.add "X-Amz-Algorithm", valid_614430
  var valid_614431 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614431 = validateParameter(valid_614431, JString, required = false,
                                 default = nil)
  if valid_614431 != nil:
    section.add "X-Amz-SignedHeaders", valid_614431
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614433: Call_GetPatchBaselineForPatchGroup_614421; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the patch baseline that should be used for the specified patch group.
  ## 
  let valid = call_614433.validator(path, query, header, formData, body)
  let scheme = call_614433.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614433.url(scheme.get, call_614433.host, call_614433.base,
                         call_614433.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614433, url, valid)

proc call*(call_614434: Call_GetPatchBaselineForPatchGroup_614421; body: JsonNode): Recallable =
  ## getPatchBaselineForPatchGroup
  ## Retrieves the patch baseline that should be used for the specified patch group.
  ##   body: JObject (required)
  var body_614435 = newJObject()
  if body != nil:
    body_614435 = body
  result = call_614434.call(nil, nil, nil, nil, body_614435)

var getPatchBaselineForPatchGroup* = Call_GetPatchBaselineForPatchGroup_614421(
    name: "getPatchBaselineForPatchGroup", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetPatchBaselineForPatchGroup",
    validator: validate_GetPatchBaselineForPatchGroup_614422, base: "/",
    url: url_GetPatchBaselineForPatchGroup_614423,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetServiceSetting_614436 = ref object of OpenApiRestCall_612658
proc url_GetServiceSetting_614438(protocol: Scheme; host: string; base: string;
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

proc validate_GetServiceSetting_614437(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>UpdateServiceSetting</a> API action to change the default setting. Or use the <a>ResetServiceSetting</a> to change the value back to the original value defined by the AWS service team.</p> <p>Query the current service setting for the account. </p>
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
  var valid_614439 = header.getOrDefault("X-Amz-Target")
  valid_614439 = validateParameter(valid_614439, JString, required = true, default = newJString(
      "AmazonSSM.GetServiceSetting"))
  if valid_614439 != nil:
    section.add "X-Amz-Target", valid_614439
  var valid_614440 = header.getOrDefault("X-Amz-Signature")
  valid_614440 = validateParameter(valid_614440, JString, required = false,
                                 default = nil)
  if valid_614440 != nil:
    section.add "X-Amz-Signature", valid_614440
  var valid_614441 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614441 = validateParameter(valid_614441, JString, required = false,
                                 default = nil)
  if valid_614441 != nil:
    section.add "X-Amz-Content-Sha256", valid_614441
  var valid_614442 = header.getOrDefault("X-Amz-Date")
  valid_614442 = validateParameter(valid_614442, JString, required = false,
                                 default = nil)
  if valid_614442 != nil:
    section.add "X-Amz-Date", valid_614442
  var valid_614443 = header.getOrDefault("X-Amz-Credential")
  valid_614443 = validateParameter(valid_614443, JString, required = false,
                                 default = nil)
  if valid_614443 != nil:
    section.add "X-Amz-Credential", valid_614443
  var valid_614444 = header.getOrDefault("X-Amz-Security-Token")
  valid_614444 = validateParameter(valid_614444, JString, required = false,
                                 default = nil)
  if valid_614444 != nil:
    section.add "X-Amz-Security-Token", valid_614444
  var valid_614445 = header.getOrDefault("X-Amz-Algorithm")
  valid_614445 = validateParameter(valid_614445, JString, required = false,
                                 default = nil)
  if valid_614445 != nil:
    section.add "X-Amz-Algorithm", valid_614445
  var valid_614446 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614446 = validateParameter(valid_614446, JString, required = false,
                                 default = nil)
  if valid_614446 != nil:
    section.add "X-Amz-SignedHeaders", valid_614446
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614448: Call_GetServiceSetting_614436; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>UpdateServiceSetting</a> API action to change the default setting. Or use the <a>ResetServiceSetting</a> to change the value back to the original value defined by the AWS service team.</p> <p>Query the current service setting for the account. </p>
  ## 
  let valid = call_614448.validator(path, query, header, formData, body)
  let scheme = call_614448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614448.url(scheme.get, call_614448.host, call_614448.base,
                         call_614448.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614448, url, valid)

proc call*(call_614449: Call_GetServiceSetting_614436; body: JsonNode): Recallable =
  ## getServiceSetting
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>UpdateServiceSetting</a> API action to change the default setting. Or use the <a>ResetServiceSetting</a> to change the value back to the original value defined by the AWS service team.</p> <p>Query the current service setting for the account. </p>
  ##   body: JObject (required)
  var body_614450 = newJObject()
  if body != nil:
    body_614450 = body
  result = call_614449.call(nil, nil, nil, nil, body_614450)

var getServiceSetting* = Call_GetServiceSetting_614436(name: "getServiceSetting",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetServiceSetting",
    validator: validate_GetServiceSetting_614437, base: "/",
    url: url_GetServiceSetting_614438, schemes: {Scheme.Https, Scheme.Http})
type
  Call_LabelParameterVersion_614451 = ref object of OpenApiRestCall_612658
proc url_LabelParameterVersion_614453(protocol: Scheme; host: string; base: string;
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

proc validate_LabelParameterVersion_614452(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>A parameter label is a user-defined alias to help you manage different versions of a parameter. When you modify a parameter, Systems Manager automatically saves a new version and increments the version number by one. A label can help you remember the purpose of a parameter when there are multiple versions. </p> <p>Parameter labels have the following requirements and restrictions.</p> <ul> <li> <p>A version of a parameter can have a maximum of 10 labels.</p> </li> <li> <p>You can't attach the same label to different versions of the same parameter. For example, if version 1 has the label Production, then you can't attach Production to version 2.</p> </li> <li> <p>You can move a label from one version of a parameter to another.</p> </li> <li> <p>You can't create a label when you create a new parameter. You must attach a label to a specific version of a parameter.</p> </li> <li> <p>You can't delete a parameter label. If you no longer want to use a parameter label, then you must move it to a different version of a parameter.</p> </li> <li> <p>A label can have a maximum of 100 characters.</p> </li> <li> <p>Labels can contain letters (case sensitive), numbers, periods (.), hyphens (-), or underscores (_).</p> </li> <li> <p>Labels can't begin with a number, "aws," or "ssm" (not case sensitive). If a label fails to meet these requirements, then the label is not associated with a parameter and the system displays it in the list of InvalidLabels.</p> </li> </ul>
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
  var valid_614454 = header.getOrDefault("X-Amz-Target")
  valid_614454 = validateParameter(valid_614454, JString, required = true, default = newJString(
      "AmazonSSM.LabelParameterVersion"))
  if valid_614454 != nil:
    section.add "X-Amz-Target", valid_614454
  var valid_614455 = header.getOrDefault("X-Amz-Signature")
  valid_614455 = validateParameter(valid_614455, JString, required = false,
                                 default = nil)
  if valid_614455 != nil:
    section.add "X-Amz-Signature", valid_614455
  var valid_614456 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614456 = validateParameter(valid_614456, JString, required = false,
                                 default = nil)
  if valid_614456 != nil:
    section.add "X-Amz-Content-Sha256", valid_614456
  var valid_614457 = header.getOrDefault("X-Amz-Date")
  valid_614457 = validateParameter(valid_614457, JString, required = false,
                                 default = nil)
  if valid_614457 != nil:
    section.add "X-Amz-Date", valid_614457
  var valid_614458 = header.getOrDefault("X-Amz-Credential")
  valid_614458 = validateParameter(valid_614458, JString, required = false,
                                 default = nil)
  if valid_614458 != nil:
    section.add "X-Amz-Credential", valid_614458
  var valid_614459 = header.getOrDefault("X-Amz-Security-Token")
  valid_614459 = validateParameter(valid_614459, JString, required = false,
                                 default = nil)
  if valid_614459 != nil:
    section.add "X-Amz-Security-Token", valid_614459
  var valid_614460 = header.getOrDefault("X-Amz-Algorithm")
  valid_614460 = validateParameter(valid_614460, JString, required = false,
                                 default = nil)
  if valid_614460 != nil:
    section.add "X-Amz-Algorithm", valid_614460
  var valid_614461 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614461 = validateParameter(valid_614461, JString, required = false,
                                 default = nil)
  if valid_614461 != nil:
    section.add "X-Amz-SignedHeaders", valid_614461
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614463: Call_LabelParameterVersion_614451; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>A parameter label is a user-defined alias to help you manage different versions of a parameter. When you modify a parameter, Systems Manager automatically saves a new version and increments the version number by one. A label can help you remember the purpose of a parameter when there are multiple versions. </p> <p>Parameter labels have the following requirements and restrictions.</p> <ul> <li> <p>A version of a parameter can have a maximum of 10 labels.</p> </li> <li> <p>You can't attach the same label to different versions of the same parameter. For example, if version 1 has the label Production, then you can't attach Production to version 2.</p> </li> <li> <p>You can move a label from one version of a parameter to another.</p> </li> <li> <p>You can't create a label when you create a new parameter. You must attach a label to a specific version of a parameter.</p> </li> <li> <p>You can't delete a parameter label. If you no longer want to use a parameter label, then you must move it to a different version of a parameter.</p> </li> <li> <p>A label can have a maximum of 100 characters.</p> </li> <li> <p>Labels can contain letters (case sensitive), numbers, periods (.), hyphens (-), or underscores (_).</p> </li> <li> <p>Labels can't begin with a number, "aws," or "ssm" (not case sensitive). If a label fails to meet these requirements, then the label is not associated with a parameter and the system displays it in the list of InvalidLabels.</p> </li> </ul>
  ## 
  let valid = call_614463.validator(path, query, header, formData, body)
  let scheme = call_614463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614463.url(scheme.get, call_614463.host, call_614463.base,
                         call_614463.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614463, url, valid)

proc call*(call_614464: Call_LabelParameterVersion_614451; body: JsonNode): Recallable =
  ## labelParameterVersion
  ## <p>A parameter label is a user-defined alias to help you manage different versions of a parameter. When you modify a parameter, Systems Manager automatically saves a new version and increments the version number by one. A label can help you remember the purpose of a parameter when there are multiple versions. </p> <p>Parameter labels have the following requirements and restrictions.</p> <ul> <li> <p>A version of a parameter can have a maximum of 10 labels.</p> </li> <li> <p>You can't attach the same label to different versions of the same parameter. For example, if version 1 has the label Production, then you can't attach Production to version 2.</p> </li> <li> <p>You can move a label from one version of a parameter to another.</p> </li> <li> <p>You can't create a label when you create a new parameter. You must attach a label to a specific version of a parameter.</p> </li> <li> <p>You can't delete a parameter label. If you no longer want to use a parameter label, then you must move it to a different version of a parameter.</p> </li> <li> <p>A label can have a maximum of 100 characters.</p> </li> <li> <p>Labels can contain letters (case sensitive), numbers, periods (.), hyphens (-), or underscores (_).</p> </li> <li> <p>Labels can't begin with a number, "aws," or "ssm" (not case sensitive). If a label fails to meet these requirements, then the label is not associated with a parameter and the system displays it in the list of InvalidLabels.</p> </li> </ul>
  ##   body: JObject (required)
  var body_614465 = newJObject()
  if body != nil:
    body_614465 = body
  result = call_614464.call(nil, nil, nil, nil, body_614465)

var labelParameterVersion* = Call_LabelParameterVersion_614451(
    name: "labelParameterVersion", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.LabelParameterVersion",
    validator: validate_LabelParameterVersion_614452, base: "/",
    url: url_LabelParameterVersion_614453, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssociationVersions_614466 = ref object of OpenApiRestCall_612658
proc url_ListAssociationVersions_614468(protocol: Scheme; host: string; base: string;
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

proc validate_ListAssociationVersions_614467(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves all versions of an association for a specific association ID.
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
  var valid_614469 = header.getOrDefault("X-Amz-Target")
  valid_614469 = validateParameter(valid_614469, JString, required = true, default = newJString(
      "AmazonSSM.ListAssociationVersions"))
  if valid_614469 != nil:
    section.add "X-Amz-Target", valid_614469
  var valid_614470 = header.getOrDefault("X-Amz-Signature")
  valid_614470 = validateParameter(valid_614470, JString, required = false,
                                 default = nil)
  if valid_614470 != nil:
    section.add "X-Amz-Signature", valid_614470
  var valid_614471 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614471 = validateParameter(valid_614471, JString, required = false,
                                 default = nil)
  if valid_614471 != nil:
    section.add "X-Amz-Content-Sha256", valid_614471
  var valid_614472 = header.getOrDefault("X-Amz-Date")
  valid_614472 = validateParameter(valid_614472, JString, required = false,
                                 default = nil)
  if valid_614472 != nil:
    section.add "X-Amz-Date", valid_614472
  var valid_614473 = header.getOrDefault("X-Amz-Credential")
  valid_614473 = validateParameter(valid_614473, JString, required = false,
                                 default = nil)
  if valid_614473 != nil:
    section.add "X-Amz-Credential", valid_614473
  var valid_614474 = header.getOrDefault("X-Amz-Security-Token")
  valid_614474 = validateParameter(valid_614474, JString, required = false,
                                 default = nil)
  if valid_614474 != nil:
    section.add "X-Amz-Security-Token", valid_614474
  var valid_614475 = header.getOrDefault("X-Amz-Algorithm")
  valid_614475 = validateParameter(valid_614475, JString, required = false,
                                 default = nil)
  if valid_614475 != nil:
    section.add "X-Amz-Algorithm", valid_614475
  var valid_614476 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614476 = validateParameter(valid_614476, JString, required = false,
                                 default = nil)
  if valid_614476 != nil:
    section.add "X-Amz-SignedHeaders", valid_614476
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614478: Call_ListAssociationVersions_614466; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves all versions of an association for a specific association ID.
  ## 
  let valid = call_614478.validator(path, query, header, formData, body)
  let scheme = call_614478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614478.url(scheme.get, call_614478.host, call_614478.base,
                         call_614478.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614478, url, valid)

proc call*(call_614479: Call_ListAssociationVersions_614466; body: JsonNode): Recallable =
  ## listAssociationVersions
  ## Retrieves all versions of an association for a specific association ID.
  ##   body: JObject (required)
  var body_614480 = newJObject()
  if body != nil:
    body_614480 = body
  result = call_614479.call(nil, nil, nil, nil, body_614480)

var listAssociationVersions* = Call_ListAssociationVersions_614466(
    name: "listAssociationVersions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListAssociationVersions",
    validator: validate_ListAssociationVersions_614467, base: "/",
    url: url_ListAssociationVersions_614468, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssociations_614481 = ref object of OpenApiRestCall_612658
proc url_ListAssociations_614483(protocol: Scheme; host: string; base: string;
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

proc validate_ListAssociations_614482(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Returns all State Manager associations in the current AWS account and Region. You can limit the results to a specific State Manager association document or instance by specifying a filter.
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
  var valid_614484 = query.getOrDefault("MaxResults")
  valid_614484 = validateParameter(valid_614484, JString, required = false,
                                 default = nil)
  if valid_614484 != nil:
    section.add "MaxResults", valid_614484
  var valid_614485 = query.getOrDefault("NextToken")
  valid_614485 = validateParameter(valid_614485, JString, required = false,
                                 default = nil)
  if valid_614485 != nil:
    section.add "NextToken", valid_614485
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
  var valid_614486 = header.getOrDefault("X-Amz-Target")
  valid_614486 = validateParameter(valid_614486, JString, required = true, default = newJString(
      "AmazonSSM.ListAssociations"))
  if valid_614486 != nil:
    section.add "X-Amz-Target", valid_614486
  var valid_614487 = header.getOrDefault("X-Amz-Signature")
  valid_614487 = validateParameter(valid_614487, JString, required = false,
                                 default = nil)
  if valid_614487 != nil:
    section.add "X-Amz-Signature", valid_614487
  var valid_614488 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614488 = validateParameter(valid_614488, JString, required = false,
                                 default = nil)
  if valid_614488 != nil:
    section.add "X-Amz-Content-Sha256", valid_614488
  var valid_614489 = header.getOrDefault("X-Amz-Date")
  valid_614489 = validateParameter(valid_614489, JString, required = false,
                                 default = nil)
  if valid_614489 != nil:
    section.add "X-Amz-Date", valid_614489
  var valid_614490 = header.getOrDefault("X-Amz-Credential")
  valid_614490 = validateParameter(valid_614490, JString, required = false,
                                 default = nil)
  if valid_614490 != nil:
    section.add "X-Amz-Credential", valid_614490
  var valid_614491 = header.getOrDefault("X-Amz-Security-Token")
  valid_614491 = validateParameter(valid_614491, JString, required = false,
                                 default = nil)
  if valid_614491 != nil:
    section.add "X-Amz-Security-Token", valid_614491
  var valid_614492 = header.getOrDefault("X-Amz-Algorithm")
  valid_614492 = validateParameter(valid_614492, JString, required = false,
                                 default = nil)
  if valid_614492 != nil:
    section.add "X-Amz-Algorithm", valid_614492
  var valid_614493 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614493 = validateParameter(valid_614493, JString, required = false,
                                 default = nil)
  if valid_614493 != nil:
    section.add "X-Amz-SignedHeaders", valid_614493
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614495: Call_ListAssociations_614481; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all State Manager associations in the current AWS account and Region. You can limit the results to a specific State Manager association document or instance by specifying a filter.
  ## 
  let valid = call_614495.validator(path, query, header, formData, body)
  let scheme = call_614495.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614495.url(scheme.get, call_614495.host, call_614495.base,
                         call_614495.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614495, url, valid)

proc call*(call_614496: Call_ListAssociations_614481; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listAssociations
  ## Returns all State Manager associations in the current AWS account and Region. You can limit the results to a specific State Manager association document or instance by specifying a filter.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614497 = newJObject()
  var body_614498 = newJObject()
  add(query_614497, "MaxResults", newJString(MaxResults))
  add(query_614497, "NextToken", newJString(NextToken))
  if body != nil:
    body_614498 = body
  result = call_614496.call(nil, query_614497, nil, nil, body_614498)

var listAssociations* = Call_ListAssociations_614481(name: "listAssociations",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListAssociations",
    validator: validate_ListAssociations_614482, base: "/",
    url: url_ListAssociations_614483, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCommandInvocations_614499 = ref object of OpenApiRestCall_612658
proc url_ListCommandInvocations_614501(protocol: Scheme; host: string; base: string;
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

proc validate_ListCommandInvocations_614500(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## An invocation is copy of a command sent to a specific instance. A command can apply to one or more instances. A command invocation applies to one instance. For example, if a user runs SendCommand against three instances, then a command invocation is created for each requested instance ID. ListCommandInvocations provide status about command execution.
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
  var valid_614502 = query.getOrDefault("MaxResults")
  valid_614502 = validateParameter(valid_614502, JString, required = false,
                                 default = nil)
  if valid_614502 != nil:
    section.add "MaxResults", valid_614502
  var valid_614503 = query.getOrDefault("NextToken")
  valid_614503 = validateParameter(valid_614503, JString, required = false,
                                 default = nil)
  if valid_614503 != nil:
    section.add "NextToken", valid_614503
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
  var valid_614504 = header.getOrDefault("X-Amz-Target")
  valid_614504 = validateParameter(valid_614504, JString, required = true, default = newJString(
      "AmazonSSM.ListCommandInvocations"))
  if valid_614504 != nil:
    section.add "X-Amz-Target", valid_614504
  var valid_614505 = header.getOrDefault("X-Amz-Signature")
  valid_614505 = validateParameter(valid_614505, JString, required = false,
                                 default = nil)
  if valid_614505 != nil:
    section.add "X-Amz-Signature", valid_614505
  var valid_614506 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614506 = validateParameter(valid_614506, JString, required = false,
                                 default = nil)
  if valid_614506 != nil:
    section.add "X-Amz-Content-Sha256", valid_614506
  var valid_614507 = header.getOrDefault("X-Amz-Date")
  valid_614507 = validateParameter(valid_614507, JString, required = false,
                                 default = nil)
  if valid_614507 != nil:
    section.add "X-Amz-Date", valid_614507
  var valid_614508 = header.getOrDefault("X-Amz-Credential")
  valid_614508 = validateParameter(valid_614508, JString, required = false,
                                 default = nil)
  if valid_614508 != nil:
    section.add "X-Amz-Credential", valid_614508
  var valid_614509 = header.getOrDefault("X-Amz-Security-Token")
  valid_614509 = validateParameter(valid_614509, JString, required = false,
                                 default = nil)
  if valid_614509 != nil:
    section.add "X-Amz-Security-Token", valid_614509
  var valid_614510 = header.getOrDefault("X-Amz-Algorithm")
  valid_614510 = validateParameter(valid_614510, JString, required = false,
                                 default = nil)
  if valid_614510 != nil:
    section.add "X-Amz-Algorithm", valid_614510
  var valid_614511 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614511 = validateParameter(valid_614511, JString, required = false,
                                 default = nil)
  if valid_614511 != nil:
    section.add "X-Amz-SignedHeaders", valid_614511
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614513: Call_ListCommandInvocations_614499; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## An invocation is copy of a command sent to a specific instance. A command can apply to one or more instances. A command invocation applies to one instance. For example, if a user runs SendCommand against three instances, then a command invocation is created for each requested instance ID. ListCommandInvocations provide status about command execution.
  ## 
  let valid = call_614513.validator(path, query, header, formData, body)
  let scheme = call_614513.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614513.url(scheme.get, call_614513.host, call_614513.base,
                         call_614513.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614513, url, valid)

proc call*(call_614514: Call_ListCommandInvocations_614499; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listCommandInvocations
  ## An invocation is copy of a command sent to a specific instance. A command can apply to one or more instances. A command invocation applies to one instance. For example, if a user runs SendCommand against three instances, then a command invocation is created for each requested instance ID. ListCommandInvocations provide status about command execution.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614515 = newJObject()
  var body_614516 = newJObject()
  add(query_614515, "MaxResults", newJString(MaxResults))
  add(query_614515, "NextToken", newJString(NextToken))
  if body != nil:
    body_614516 = body
  result = call_614514.call(nil, query_614515, nil, nil, body_614516)

var listCommandInvocations* = Call_ListCommandInvocations_614499(
    name: "listCommandInvocations", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListCommandInvocations",
    validator: validate_ListCommandInvocations_614500, base: "/",
    url: url_ListCommandInvocations_614501, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCommands_614517 = ref object of OpenApiRestCall_612658
proc url_ListCommands_614519(protocol: Scheme; host: string; base: string;
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

proc validate_ListCommands_614518(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the commands requested by users of the AWS account.
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
  var valid_614520 = query.getOrDefault("MaxResults")
  valid_614520 = validateParameter(valid_614520, JString, required = false,
                                 default = nil)
  if valid_614520 != nil:
    section.add "MaxResults", valid_614520
  var valid_614521 = query.getOrDefault("NextToken")
  valid_614521 = validateParameter(valid_614521, JString, required = false,
                                 default = nil)
  if valid_614521 != nil:
    section.add "NextToken", valid_614521
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
  var valid_614522 = header.getOrDefault("X-Amz-Target")
  valid_614522 = validateParameter(valid_614522, JString, required = true,
                                 default = newJString("AmazonSSM.ListCommands"))
  if valid_614522 != nil:
    section.add "X-Amz-Target", valid_614522
  var valid_614523 = header.getOrDefault("X-Amz-Signature")
  valid_614523 = validateParameter(valid_614523, JString, required = false,
                                 default = nil)
  if valid_614523 != nil:
    section.add "X-Amz-Signature", valid_614523
  var valid_614524 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614524 = validateParameter(valid_614524, JString, required = false,
                                 default = nil)
  if valid_614524 != nil:
    section.add "X-Amz-Content-Sha256", valid_614524
  var valid_614525 = header.getOrDefault("X-Amz-Date")
  valid_614525 = validateParameter(valid_614525, JString, required = false,
                                 default = nil)
  if valid_614525 != nil:
    section.add "X-Amz-Date", valid_614525
  var valid_614526 = header.getOrDefault("X-Amz-Credential")
  valid_614526 = validateParameter(valid_614526, JString, required = false,
                                 default = nil)
  if valid_614526 != nil:
    section.add "X-Amz-Credential", valid_614526
  var valid_614527 = header.getOrDefault("X-Amz-Security-Token")
  valid_614527 = validateParameter(valid_614527, JString, required = false,
                                 default = nil)
  if valid_614527 != nil:
    section.add "X-Amz-Security-Token", valid_614527
  var valid_614528 = header.getOrDefault("X-Amz-Algorithm")
  valid_614528 = validateParameter(valid_614528, JString, required = false,
                                 default = nil)
  if valid_614528 != nil:
    section.add "X-Amz-Algorithm", valid_614528
  var valid_614529 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614529 = validateParameter(valid_614529, JString, required = false,
                                 default = nil)
  if valid_614529 != nil:
    section.add "X-Amz-SignedHeaders", valid_614529
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614531: Call_ListCommands_614517; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the commands requested by users of the AWS account.
  ## 
  let valid = call_614531.validator(path, query, header, formData, body)
  let scheme = call_614531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614531.url(scheme.get, call_614531.host, call_614531.base,
                         call_614531.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614531, url, valid)

proc call*(call_614532: Call_ListCommands_614517; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listCommands
  ## Lists the commands requested by users of the AWS account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614533 = newJObject()
  var body_614534 = newJObject()
  add(query_614533, "MaxResults", newJString(MaxResults))
  add(query_614533, "NextToken", newJString(NextToken))
  if body != nil:
    body_614534 = body
  result = call_614532.call(nil, query_614533, nil, nil, body_614534)

var listCommands* = Call_ListCommands_614517(name: "listCommands",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListCommands",
    validator: validate_ListCommands_614518, base: "/", url: url_ListCommands_614519,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListComplianceItems_614535 = ref object of OpenApiRestCall_612658
proc url_ListComplianceItems_614537(protocol: Scheme; host: string; base: string;
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

proc validate_ListComplianceItems_614536(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## For a specified resource ID, this API action returns a list of compliance statuses for different resource types. Currently, you can only specify one resource ID per call. List results depend on the criteria specified in the filter. 
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
  var valid_614538 = header.getOrDefault("X-Amz-Target")
  valid_614538 = validateParameter(valid_614538, JString, required = true, default = newJString(
      "AmazonSSM.ListComplianceItems"))
  if valid_614538 != nil:
    section.add "X-Amz-Target", valid_614538
  var valid_614539 = header.getOrDefault("X-Amz-Signature")
  valid_614539 = validateParameter(valid_614539, JString, required = false,
                                 default = nil)
  if valid_614539 != nil:
    section.add "X-Amz-Signature", valid_614539
  var valid_614540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614540 = validateParameter(valid_614540, JString, required = false,
                                 default = nil)
  if valid_614540 != nil:
    section.add "X-Amz-Content-Sha256", valid_614540
  var valid_614541 = header.getOrDefault("X-Amz-Date")
  valid_614541 = validateParameter(valid_614541, JString, required = false,
                                 default = nil)
  if valid_614541 != nil:
    section.add "X-Amz-Date", valid_614541
  var valid_614542 = header.getOrDefault("X-Amz-Credential")
  valid_614542 = validateParameter(valid_614542, JString, required = false,
                                 default = nil)
  if valid_614542 != nil:
    section.add "X-Amz-Credential", valid_614542
  var valid_614543 = header.getOrDefault("X-Amz-Security-Token")
  valid_614543 = validateParameter(valid_614543, JString, required = false,
                                 default = nil)
  if valid_614543 != nil:
    section.add "X-Amz-Security-Token", valid_614543
  var valid_614544 = header.getOrDefault("X-Amz-Algorithm")
  valid_614544 = validateParameter(valid_614544, JString, required = false,
                                 default = nil)
  if valid_614544 != nil:
    section.add "X-Amz-Algorithm", valid_614544
  var valid_614545 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614545 = validateParameter(valid_614545, JString, required = false,
                                 default = nil)
  if valid_614545 != nil:
    section.add "X-Amz-SignedHeaders", valid_614545
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614547: Call_ListComplianceItems_614535; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## For a specified resource ID, this API action returns a list of compliance statuses for different resource types. Currently, you can only specify one resource ID per call. List results depend on the criteria specified in the filter. 
  ## 
  let valid = call_614547.validator(path, query, header, formData, body)
  let scheme = call_614547.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614547.url(scheme.get, call_614547.host, call_614547.base,
                         call_614547.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614547, url, valid)

proc call*(call_614548: Call_ListComplianceItems_614535; body: JsonNode): Recallable =
  ## listComplianceItems
  ## For a specified resource ID, this API action returns a list of compliance statuses for different resource types. Currently, you can only specify one resource ID per call. List results depend on the criteria specified in the filter. 
  ##   body: JObject (required)
  var body_614549 = newJObject()
  if body != nil:
    body_614549 = body
  result = call_614548.call(nil, nil, nil, nil, body_614549)

var listComplianceItems* = Call_ListComplianceItems_614535(
    name: "listComplianceItems", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListComplianceItems",
    validator: validate_ListComplianceItems_614536, base: "/",
    url: url_ListComplianceItems_614537, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListComplianceSummaries_614550 = ref object of OpenApiRestCall_612658
proc url_ListComplianceSummaries_614552(protocol: Scheme; host: string; base: string;
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

proc validate_ListComplianceSummaries_614551(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a summary count of compliant and non-compliant resources for a compliance type. For example, this call can return State Manager associations, patches, or custom compliance types according to the filter criteria that you specify. 
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
  var valid_614553 = header.getOrDefault("X-Amz-Target")
  valid_614553 = validateParameter(valid_614553, JString, required = true, default = newJString(
      "AmazonSSM.ListComplianceSummaries"))
  if valid_614553 != nil:
    section.add "X-Amz-Target", valid_614553
  var valid_614554 = header.getOrDefault("X-Amz-Signature")
  valid_614554 = validateParameter(valid_614554, JString, required = false,
                                 default = nil)
  if valid_614554 != nil:
    section.add "X-Amz-Signature", valid_614554
  var valid_614555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614555 = validateParameter(valid_614555, JString, required = false,
                                 default = nil)
  if valid_614555 != nil:
    section.add "X-Amz-Content-Sha256", valid_614555
  var valid_614556 = header.getOrDefault("X-Amz-Date")
  valid_614556 = validateParameter(valid_614556, JString, required = false,
                                 default = nil)
  if valid_614556 != nil:
    section.add "X-Amz-Date", valid_614556
  var valid_614557 = header.getOrDefault("X-Amz-Credential")
  valid_614557 = validateParameter(valid_614557, JString, required = false,
                                 default = nil)
  if valid_614557 != nil:
    section.add "X-Amz-Credential", valid_614557
  var valid_614558 = header.getOrDefault("X-Amz-Security-Token")
  valid_614558 = validateParameter(valid_614558, JString, required = false,
                                 default = nil)
  if valid_614558 != nil:
    section.add "X-Amz-Security-Token", valid_614558
  var valid_614559 = header.getOrDefault("X-Amz-Algorithm")
  valid_614559 = validateParameter(valid_614559, JString, required = false,
                                 default = nil)
  if valid_614559 != nil:
    section.add "X-Amz-Algorithm", valid_614559
  var valid_614560 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614560 = validateParameter(valid_614560, JString, required = false,
                                 default = nil)
  if valid_614560 != nil:
    section.add "X-Amz-SignedHeaders", valid_614560
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614562: Call_ListComplianceSummaries_614550; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a summary count of compliant and non-compliant resources for a compliance type. For example, this call can return State Manager associations, patches, or custom compliance types according to the filter criteria that you specify. 
  ## 
  let valid = call_614562.validator(path, query, header, formData, body)
  let scheme = call_614562.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614562.url(scheme.get, call_614562.host, call_614562.base,
                         call_614562.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614562, url, valid)

proc call*(call_614563: Call_ListComplianceSummaries_614550; body: JsonNode): Recallable =
  ## listComplianceSummaries
  ## Returns a summary count of compliant and non-compliant resources for a compliance type. For example, this call can return State Manager associations, patches, or custom compliance types according to the filter criteria that you specify. 
  ##   body: JObject (required)
  var body_614564 = newJObject()
  if body != nil:
    body_614564 = body
  result = call_614563.call(nil, nil, nil, nil, body_614564)

var listComplianceSummaries* = Call_ListComplianceSummaries_614550(
    name: "listComplianceSummaries", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListComplianceSummaries",
    validator: validate_ListComplianceSummaries_614551, base: "/",
    url: url_ListComplianceSummaries_614552, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDocumentVersions_614565 = ref object of OpenApiRestCall_612658
proc url_ListDocumentVersions_614567(protocol: Scheme; host: string; base: string;
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

proc validate_ListDocumentVersions_614566(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List all versions for a document.
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
  var valid_614568 = header.getOrDefault("X-Amz-Target")
  valid_614568 = validateParameter(valid_614568, JString, required = true, default = newJString(
      "AmazonSSM.ListDocumentVersions"))
  if valid_614568 != nil:
    section.add "X-Amz-Target", valid_614568
  var valid_614569 = header.getOrDefault("X-Amz-Signature")
  valid_614569 = validateParameter(valid_614569, JString, required = false,
                                 default = nil)
  if valid_614569 != nil:
    section.add "X-Amz-Signature", valid_614569
  var valid_614570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614570 = validateParameter(valid_614570, JString, required = false,
                                 default = nil)
  if valid_614570 != nil:
    section.add "X-Amz-Content-Sha256", valid_614570
  var valid_614571 = header.getOrDefault("X-Amz-Date")
  valid_614571 = validateParameter(valid_614571, JString, required = false,
                                 default = nil)
  if valid_614571 != nil:
    section.add "X-Amz-Date", valid_614571
  var valid_614572 = header.getOrDefault("X-Amz-Credential")
  valid_614572 = validateParameter(valid_614572, JString, required = false,
                                 default = nil)
  if valid_614572 != nil:
    section.add "X-Amz-Credential", valid_614572
  var valid_614573 = header.getOrDefault("X-Amz-Security-Token")
  valid_614573 = validateParameter(valid_614573, JString, required = false,
                                 default = nil)
  if valid_614573 != nil:
    section.add "X-Amz-Security-Token", valid_614573
  var valid_614574 = header.getOrDefault("X-Amz-Algorithm")
  valid_614574 = validateParameter(valid_614574, JString, required = false,
                                 default = nil)
  if valid_614574 != nil:
    section.add "X-Amz-Algorithm", valid_614574
  var valid_614575 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614575 = validateParameter(valid_614575, JString, required = false,
                                 default = nil)
  if valid_614575 != nil:
    section.add "X-Amz-SignedHeaders", valid_614575
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614577: Call_ListDocumentVersions_614565; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all versions for a document.
  ## 
  let valid = call_614577.validator(path, query, header, formData, body)
  let scheme = call_614577.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614577.url(scheme.get, call_614577.host, call_614577.base,
                         call_614577.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614577, url, valid)

proc call*(call_614578: Call_ListDocumentVersions_614565; body: JsonNode): Recallable =
  ## listDocumentVersions
  ## List all versions for a document.
  ##   body: JObject (required)
  var body_614579 = newJObject()
  if body != nil:
    body_614579 = body
  result = call_614578.call(nil, nil, nil, nil, body_614579)

var listDocumentVersions* = Call_ListDocumentVersions_614565(
    name: "listDocumentVersions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListDocumentVersions",
    validator: validate_ListDocumentVersions_614566, base: "/",
    url: url_ListDocumentVersions_614567, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDocuments_614580 = ref object of OpenApiRestCall_612658
proc url_ListDocuments_614582(protocol: Scheme; host: string; base: string;
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

proc validate_ListDocuments_614581(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns all Systems Manager (SSM) documents in the current AWS account and Region. You can limit the results of this request by using a filter.
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
  var valid_614583 = query.getOrDefault("MaxResults")
  valid_614583 = validateParameter(valid_614583, JString, required = false,
                                 default = nil)
  if valid_614583 != nil:
    section.add "MaxResults", valid_614583
  var valid_614584 = query.getOrDefault("NextToken")
  valid_614584 = validateParameter(valid_614584, JString, required = false,
                                 default = nil)
  if valid_614584 != nil:
    section.add "NextToken", valid_614584
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
  var valid_614585 = header.getOrDefault("X-Amz-Target")
  valid_614585 = validateParameter(valid_614585, JString, required = true, default = newJString(
      "AmazonSSM.ListDocuments"))
  if valid_614585 != nil:
    section.add "X-Amz-Target", valid_614585
  var valid_614586 = header.getOrDefault("X-Amz-Signature")
  valid_614586 = validateParameter(valid_614586, JString, required = false,
                                 default = nil)
  if valid_614586 != nil:
    section.add "X-Amz-Signature", valid_614586
  var valid_614587 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614587 = validateParameter(valid_614587, JString, required = false,
                                 default = nil)
  if valid_614587 != nil:
    section.add "X-Amz-Content-Sha256", valid_614587
  var valid_614588 = header.getOrDefault("X-Amz-Date")
  valid_614588 = validateParameter(valid_614588, JString, required = false,
                                 default = nil)
  if valid_614588 != nil:
    section.add "X-Amz-Date", valid_614588
  var valid_614589 = header.getOrDefault("X-Amz-Credential")
  valid_614589 = validateParameter(valid_614589, JString, required = false,
                                 default = nil)
  if valid_614589 != nil:
    section.add "X-Amz-Credential", valid_614589
  var valid_614590 = header.getOrDefault("X-Amz-Security-Token")
  valid_614590 = validateParameter(valid_614590, JString, required = false,
                                 default = nil)
  if valid_614590 != nil:
    section.add "X-Amz-Security-Token", valid_614590
  var valid_614591 = header.getOrDefault("X-Amz-Algorithm")
  valid_614591 = validateParameter(valid_614591, JString, required = false,
                                 default = nil)
  if valid_614591 != nil:
    section.add "X-Amz-Algorithm", valid_614591
  var valid_614592 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614592 = validateParameter(valid_614592, JString, required = false,
                                 default = nil)
  if valid_614592 != nil:
    section.add "X-Amz-SignedHeaders", valid_614592
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614594: Call_ListDocuments_614580; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all Systems Manager (SSM) documents in the current AWS account and Region. You can limit the results of this request by using a filter.
  ## 
  let valid = call_614594.validator(path, query, header, formData, body)
  let scheme = call_614594.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614594.url(scheme.get, call_614594.host, call_614594.base,
                         call_614594.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614594, url, valid)

proc call*(call_614595: Call_ListDocuments_614580; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDocuments
  ## Returns all Systems Manager (SSM) documents in the current AWS account and Region. You can limit the results of this request by using a filter.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614596 = newJObject()
  var body_614597 = newJObject()
  add(query_614596, "MaxResults", newJString(MaxResults))
  add(query_614596, "NextToken", newJString(NextToken))
  if body != nil:
    body_614597 = body
  result = call_614595.call(nil, query_614596, nil, nil, body_614597)

var listDocuments* = Call_ListDocuments_614580(name: "listDocuments",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListDocuments",
    validator: validate_ListDocuments_614581, base: "/", url: url_ListDocuments_614582,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInventoryEntries_614598 = ref object of OpenApiRestCall_612658
proc url_ListInventoryEntries_614600(protocol: Scheme; host: string; base: string;
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

proc validate_ListInventoryEntries_614599(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## A list of inventory items returned by the request.
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
  var valid_614601 = header.getOrDefault("X-Amz-Target")
  valid_614601 = validateParameter(valid_614601, JString, required = true, default = newJString(
      "AmazonSSM.ListInventoryEntries"))
  if valid_614601 != nil:
    section.add "X-Amz-Target", valid_614601
  var valid_614602 = header.getOrDefault("X-Amz-Signature")
  valid_614602 = validateParameter(valid_614602, JString, required = false,
                                 default = nil)
  if valid_614602 != nil:
    section.add "X-Amz-Signature", valid_614602
  var valid_614603 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614603 = validateParameter(valid_614603, JString, required = false,
                                 default = nil)
  if valid_614603 != nil:
    section.add "X-Amz-Content-Sha256", valid_614603
  var valid_614604 = header.getOrDefault("X-Amz-Date")
  valid_614604 = validateParameter(valid_614604, JString, required = false,
                                 default = nil)
  if valid_614604 != nil:
    section.add "X-Amz-Date", valid_614604
  var valid_614605 = header.getOrDefault("X-Amz-Credential")
  valid_614605 = validateParameter(valid_614605, JString, required = false,
                                 default = nil)
  if valid_614605 != nil:
    section.add "X-Amz-Credential", valid_614605
  var valid_614606 = header.getOrDefault("X-Amz-Security-Token")
  valid_614606 = validateParameter(valid_614606, JString, required = false,
                                 default = nil)
  if valid_614606 != nil:
    section.add "X-Amz-Security-Token", valid_614606
  var valid_614607 = header.getOrDefault("X-Amz-Algorithm")
  valid_614607 = validateParameter(valid_614607, JString, required = false,
                                 default = nil)
  if valid_614607 != nil:
    section.add "X-Amz-Algorithm", valid_614607
  var valid_614608 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614608 = validateParameter(valid_614608, JString, required = false,
                                 default = nil)
  if valid_614608 != nil:
    section.add "X-Amz-SignedHeaders", valid_614608
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614610: Call_ListInventoryEntries_614598; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## A list of inventory items returned by the request.
  ## 
  let valid = call_614610.validator(path, query, header, formData, body)
  let scheme = call_614610.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614610.url(scheme.get, call_614610.host, call_614610.base,
                         call_614610.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614610, url, valid)

proc call*(call_614611: Call_ListInventoryEntries_614598; body: JsonNode): Recallable =
  ## listInventoryEntries
  ## A list of inventory items returned by the request.
  ##   body: JObject (required)
  var body_614612 = newJObject()
  if body != nil:
    body_614612 = body
  result = call_614611.call(nil, nil, nil, nil, body_614612)

var listInventoryEntries* = Call_ListInventoryEntries_614598(
    name: "listInventoryEntries", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListInventoryEntries",
    validator: validate_ListInventoryEntries_614599, base: "/",
    url: url_ListInventoryEntries_614600, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceComplianceSummaries_614613 = ref object of OpenApiRestCall_612658
proc url_ListResourceComplianceSummaries_614615(protocol: Scheme; host: string;
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

proc validate_ListResourceComplianceSummaries_614614(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a resource-level summary count. The summary includes information about compliant and non-compliant statuses and detailed compliance-item severity counts, according to the filter criteria you specify.
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
  var valid_614616 = header.getOrDefault("X-Amz-Target")
  valid_614616 = validateParameter(valid_614616, JString, required = true, default = newJString(
      "AmazonSSM.ListResourceComplianceSummaries"))
  if valid_614616 != nil:
    section.add "X-Amz-Target", valid_614616
  var valid_614617 = header.getOrDefault("X-Amz-Signature")
  valid_614617 = validateParameter(valid_614617, JString, required = false,
                                 default = nil)
  if valid_614617 != nil:
    section.add "X-Amz-Signature", valid_614617
  var valid_614618 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614618 = validateParameter(valid_614618, JString, required = false,
                                 default = nil)
  if valid_614618 != nil:
    section.add "X-Amz-Content-Sha256", valid_614618
  var valid_614619 = header.getOrDefault("X-Amz-Date")
  valid_614619 = validateParameter(valid_614619, JString, required = false,
                                 default = nil)
  if valid_614619 != nil:
    section.add "X-Amz-Date", valid_614619
  var valid_614620 = header.getOrDefault("X-Amz-Credential")
  valid_614620 = validateParameter(valid_614620, JString, required = false,
                                 default = nil)
  if valid_614620 != nil:
    section.add "X-Amz-Credential", valid_614620
  var valid_614621 = header.getOrDefault("X-Amz-Security-Token")
  valid_614621 = validateParameter(valid_614621, JString, required = false,
                                 default = nil)
  if valid_614621 != nil:
    section.add "X-Amz-Security-Token", valid_614621
  var valid_614622 = header.getOrDefault("X-Amz-Algorithm")
  valid_614622 = validateParameter(valid_614622, JString, required = false,
                                 default = nil)
  if valid_614622 != nil:
    section.add "X-Amz-Algorithm", valid_614622
  var valid_614623 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614623 = validateParameter(valid_614623, JString, required = false,
                                 default = nil)
  if valid_614623 != nil:
    section.add "X-Amz-SignedHeaders", valid_614623
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614625: Call_ListResourceComplianceSummaries_614613;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a resource-level summary count. The summary includes information about compliant and non-compliant statuses and detailed compliance-item severity counts, according to the filter criteria you specify.
  ## 
  let valid = call_614625.validator(path, query, header, formData, body)
  let scheme = call_614625.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614625.url(scheme.get, call_614625.host, call_614625.base,
                         call_614625.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614625, url, valid)

proc call*(call_614626: Call_ListResourceComplianceSummaries_614613; body: JsonNode): Recallable =
  ## listResourceComplianceSummaries
  ## Returns a resource-level summary count. The summary includes information about compliant and non-compliant statuses and detailed compliance-item severity counts, according to the filter criteria you specify.
  ##   body: JObject (required)
  var body_614627 = newJObject()
  if body != nil:
    body_614627 = body
  result = call_614626.call(nil, nil, nil, nil, body_614627)

var listResourceComplianceSummaries* = Call_ListResourceComplianceSummaries_614613(
    name: "listResourceComplianceSummaries", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListResourceComplianceSummaries",
    validator: validate_ListResourceComplianceSummaries_614614, base: "/",
    url: url_ListResourceComplianceSummaries_614615,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceDataSync_614628 = ref object of OpenApiRestCall_612658
proc url_ListResourceDataSync_614630(protocol: Scheme; host: string; base: string;
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

proc validate_ListResourceDataSync_614629(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists your resource data sync configurations. Includes information about the last time a sync attempted to start, the last sync status, and the last time a sync successfully completed.</p> <p>The number of sync configurations might be too large to return using a single call to <code>ListResourceDataSync</code>. You can limit the number of sync configurations returned by using the <code>MaxResults</code> parameter. To determine whether there are more sync configurations to list, check the value of <code>NextToken</code> in the output. If there are more sync configurations to list, you can request them by specifying the <code>NextToken</code> returned in the call to the parameter of a subsequent call. </p>
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
  var valid_614631 = header.getOrDefault("X-Amz-Target")
  valid_614631 = validateParameter(valid_614631, JString, required = true, default = newJString(
      "AmazonSSM.ListResourceDataSync"))
  if valid_614631 != nil:
    section.add "X-Amz-Target", valid_614631
  var valid_614632 = header.getOrDefault("X-Amz-Signature")
  valid_614632 = validateParameter(valid_614632, JString, required = false,
                                 default = nil)
  if valid_614632 != nil:
    section.add "X-Amz-Signature", valid_614632
  var valid_614633 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614633 = validateParameter(valid_614633, JString, required = false,
                                 default = nil)
  if valid_614633 != nil:
    section.add "X-Amz-Content-Sha256", valid_614633
  var valid_614634 = header.getOrDefault("X-Amz-Date")
  valid_614634 = validateParameter(valid_614634, JString, required = false,
                                 default = nil)
  if valid_614634 != nil:
    section.add "X-Amz-Date", valid_614634
  var valid_614635 = header.getOrDefault("X-Amz-Credential")
  valid_614635 = validateParameter(valid_614635, JString, required = false,
                                 default = nil)
  if valid_614635 != nil:
    section.add "X-Amz-Credential", valid_614635
  var valid_614636 = header.getOrDefault("X-Amz-Security-Token")
  valid_614636 = validateParameter(valid_614636, JString, required = false,
                                 default = nil)
  if valid_614636 != nil:
    section.add "X-Amz-Security-Token", valid_614636
  var valid_614637 = header.getOrDefault("X-Amz-Algorithm")
  valid_614637 = validateParameter(valid_614637, JString, required = false,
                                 default = nil)
  if valid_614637 != nil:
    section.add "X-Amz-Algorithm", valid_614637
  var valid_614638 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614638 = validateParameter(valid_614638, JString, required = false,
                                 default = nil)
  if valid_614638 != nil:
    section.add "X-Amz-SignedHeaders", valid_614638
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614640: Call_ListResourceDataSync_614628; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists your resource data sync configurations. Includes information about the last time a sync attempted to start, the last sync status, and the last time a sync successfully completed.</p> <p>The number of sync configurations might be too large to return using a single call to <code>ListResourceDataSync</code>. You can limit the number of sync configurations returned by using the <code>MaxResults</code> parameter. To determine whether there are more sync configurations to list, check the value of <code>NextToken</code> in the output. If there are more sync configurations to list, you can request them by specifying the <code>NextToken</code> returned in the call to the parameter of a subsequent call. </p>
  ## 
  let valid = call_614640.validator(path, query, header, formData, body)
  let scheme = call_614640.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614640.url(scheme.get, call_614640.host, call_614640.base,
                         call_614640.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614640, url, valid)

proc call*(call_614641: Call_ListResourceDataSync_614628; body: JsonNode): Recallable =
  ## listResourceDataSync
  ## <p>Lists your resource data sync configurations. Includes information about the last time a sync attempted to start, the last sync status, and the last time a sync successfully completed.</p> <p>The number of sync configurations might be too large to return using a single call to <code>ListResourceDataSync</code>. You can limit the number of sync configurations returned by using the <code>MaxResults</code> parameter. To determine whether there are more sync configurations to list, check the value of <code>NextToken</code> in the output. If there are more sync configurations to list, you can request them by specifying the <code>NextToken</code> returned in the call to the parameter of a subsequent call. </p>
  ##   body: JObject (required)
  var body_614642 = newJObject()
  if body != nil:
    body_614642 = body
  result = call_614641.call(nil, nil, nil, nil, body_614642)

var listResourceDataSync* = Call_ListResourceDataSync_614628(
    name: "listResourceDataSync", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListResourceDataSync",
    validator: validate_ListResourceDataSync_614629, base: "/",
    url: url_ListResourceDataSync_614630, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_614643 = ref object of OpenApiRestCall_612658
proc url_ListTagsForResource_614645(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_614644(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns a list of the tags assigned to the specified resource.
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
  var valid_614646 = header.getOrDefault("X-Amz-Target")
  valid_614646 = validateParameter(valid_614646, JString, required = true, default = newJString(
      "AmazonSSM.ListTagsForResource"))
  if valid_614646 != nil:
    section.add "X-Amz-Target", valid_614646
  var valid_614647 = header.getOrDefault("X-Amz-Signature")
  valid_614647 = validateParameter(valid_614647, JString, required = false,
                                 default = nil)
  if valid_614647 != nil:
    section.add "X-Amz-Signature", valid_614647
  var valid_614648 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614648 = validateParameter(valid_614648, JString, required = false,
                                 default = nil)
  if valid_614648 != nil:
    section.add "X-Amz-Content-Sha256", valid_614648
  var valid_614649 = header.getOrDefault("X-Amz-Date")
  valid_614649 = validateParameter(valid_614649, JString, required = false,
                                 default = nil)
  if valid_614649 != nil:
    section.add "X-Amz-Date", valid_614649
  var valid_614650 = header.getOrDefault("X-Amz-Credential")
  valid_614650 = validateParameter(valid_614650, JString, required = false,
                                 default = nil)
  if valid_614650 != nil:
    section.add "X-Amz-Credential", valid_614650
  var valid_614651 = header.getOrDefault("X-Amz-Security-Token")
  valid_614651 = validateParameter(valid_614651, JString, required = false,
                                 default = nil)
  if valid_614651 != nil:
    section.add "X-Amz-Security-Token", valid_614651
  var valid_614652 = header.getOrDefault("X-Amz-Algorithm")
  valid_614652 = validateParameter(valid_614652, JString, required = false,
                                 default = nil)
  if valid_614652 != nil:
    section.add "X-Amz-Algorithm", valid_614652
  var valid_614653 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614653 = validateParameter(valid_614653, JString, required = false,
                                 default = nil)
  if valid_614653 != nil:
    section.add "X-Amz-SignedHeaders", valid_614653
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614655: Call_ListTagsForResource_614643; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the tags assigned to the specified resource.
  ## 
  let valid = call_614655.validator(path, query, header, formData, body)
  let scheme = call_614655.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614655.url(scheme.get, call_614655.host, call_614655.base,
                         call_614655.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614655, url, valid)

proc call*(call_614656: Call_ListTagsForResource_614643; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Returns a list of the tags assigned to the specified resource.
  ##   body: JObject (required)
  var body_614657 = newJObject()
  if body != nil:
    body_614657 = body
  result = call_614656.call(nil, nil, nil, nil, body_614657)

var listTagsForResource* = Call_ListTagsForResource_614643(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListTagsForResource",
    validator: validate_ListTagsForResource_614644, base: "/",
    url: url_ListTagsForResource_614645, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyDocumentPermission_614658 = ref object of OpenApiRestCall_612658
proc url_ModifyDocumentPermission_614660(protocol: Scheme; host: string;
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

proc validate_ModifyDocumentPermission_614659(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Shares a Systems Manager document publicly or privately. If you share a document privately, you must specify the AWS user account IDs for those people who can use the document. If you share a document publicly, you must specify <i>All</i> as the account ID.
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
  var valid_614661 = header.getOrDefault("X-Amz-Target")
  valid_614661 = validateParameter(valid_614661, JString, required = true, default = newJString(
      "AmazonSSM.ModifyDocumentPermission"))
  if valid_614661 != nil:
    section.add "X-Amz-Target", valid_614661
  var valid_614662 = header.getOrDefault("X-Amz-Signature")
  valid_614662 = validateParameter(valid_614662, JString, required = false,
                                 default = nil)
  if valid_614662 != nil:
    section.add "X-Amz-Signature", valid_614662
  var valid_614663 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614663 = validateParameter(valid_614663, JString, required = false,
                                 default = nil)
  if valid_614663 != nil:
    section.add "X-Amz-Content-Sha256", valid_614663
  var valid_614664 = header.getOrDefault("X-Amz-Date")
  valid_614664 = validateParameter(valid_614664, JString, required = false,
                                 default = nil)
  if valid_614664 != nil:
    section.add "X-Amz-Date", valid_614664
  var valid_614665 = header.getOrDefault("X-Amz-Credential")
  valid_614665 = validateParameter(valid_614665, JString, required = false,
                                 default = nil)
  if valid_614665 != nil:
    section.add "X-Amz-Credential", valid_614665
  var valid_614666 = header.getOrDefault("X-Amz-Security-Token")
  valid_614666 = validateParameter(valid_614666, JString, required = false,
                                 default = nil)
  if valid_614666 != nil:
    section.add "X-Amz-Security-Token", valid_614666
  var valid_614667 = header.getOrDefault("X-Amz-Algorithm")
  valid_614667 = validateParameter(valid_614667, JString, required = false,
                                 default = nil)
  if valid_614667 != nil:
    section.add "X-Amz-Algorithm", valid_614667
  var valid_614668 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614668 = validateParameter(valid_614668, JString, required = false,
                                 default = nil)
  if valid_614668 != nil:
    section.add "X-Amz-SignedHeaders", valid_614668
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614670: Call_ModifyDocumentPermission_614658; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Shares a Systems Manager document publicly or privately. If you share a document privately, you must specify the AWS user account IDs for those people who can use the document. If you share a document publicly, you must specify <i>All</i> as the account ID.
  ## 
  let valid = call_614670.validator(path, query, header, formData, body)
  let scheme = call_614670.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614670.url(scheme.get, call_614670.host, call_614670.base,
                         call_614670.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614670, url, valid)

proc call*(call_614671: Call_ModifyDocumentPermission_614658; body: JsonNode): Recallable =
  ## modifyDocumentPermission
  ## Shares a Systems Manager document publicly or privately. If you share a document privately, you must specify the AWS user account IDs for those people who can use the document. If you share a document publicly, you must specify <i>All</i> as the account ID.
  ##   body: JObject (required)
  var body_614672 = newJObject()
  if body != nil:
    body_614672 = body
  result = call_614671.call(nil, nil, nil, nil, body_614672)

var modifyDocumentPermission* = Call_ModifyDocumentPermission_614658(
    name: "modifyDocumentPermission", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ModifyDocumentPermission",
    validator: validate_ModifyDocumentPermission_614659, base: "/",
    url: url_ModifyDocumentPermission_614660, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutComplianceItems_614673 = ref object of OpenApiRestCall_612658
proc url_PutComplianceItems_614675(protocol: Scheme; host: string; base: string;
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

proc validate_PutComplianceItems_614674(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Registers a compliance type and other compliance details on a designated resource. This action lets you register custom compliance details with a resource. This call overwrites existing compliance information on the resource, so you must provide a full list of compliance items each time that you send the request.</p> <p>ComplianceType can be one of the following:</p> <ul> <li> <p>ExecutionId: The execution ID when the patch, association, or custom compliance item was applied.</p> </li> <li> <p>ExecutionType: Specify patch, association, or Custom:<code>string</code>.</p> </li> <li> <p>ExecutionTime. The time the patch, association, or custom compliance item was applied to the instance.</p> </li> <li> <p>Id: The patch, association, or custom compliance ID.</p> </li> <li> <p>Title: A title.</p> </li> <li> <p>Status: The status of the compliance item. For example, <code>approved</code> for patches, or <code>Failed</code> for associations.</p> </li> <li> <p>Severity: A patch severity. For example, <code>critical</code>.</p> </li> <li> <p>DocumentName: A SSM document name. For example, AWS-RunPatchBaseline.</p> </li> <li> <p>DocumentVersion: An SSM document version number. For example, 4.</p> </li> <li> <p>Classification: A patch classification. For example, <code>security updates</code>.</p> </li> <li> <p>PatchBaselineId: A patch baseline ID.</p> </li> <li> <p>PatchSeverity: A patch severity. For example, <code>Critical</code>.</p> </li> <li> <p>PatchState: A patch state. For example, <code>InstancesWithFailedPatches</code>.</p> </li> <li> <p>PatchGroup: The name of a patch group.</p> </li> <li> <p>InstalledTime: The time the association, patch, or custom compliance item was applied to the resource. Specify the time by using the following format: yyyy-MM-dd'T'HH:mm:ss'Z'</p> </li> </ul>
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
  var valid_614676 = header.getOrDefault("X-Amz-Target")
  valid_614676 = validateParameter(valid_614676, JString, required = true, default = newJString(
      "AmazonSSM.PutComplianceItems"))
  if valid_614676 != nil:
    section.add "X-Amz-Target", valid_614676
  var valid_614677 = header.getOrDefault("X-Amz-Signature")
  valid_614677 = validateParameter(valid_614677, JString, required = false,
                                 default = nil)
  if valid_614677 != nil:
    section.add "X-Amz-Signature", valid_614677
  var valid_614678 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614678 = validateParameter(valid_614678, JString, required = false,
                                 default = nil)
  if valid_614678 != nil:
    section.add "X-Amz-Content-Sha256", valid_614678
  var valid_614679 = header.getOrDefault("X-Amz-Date")
  valid_614679 = validateParameter(valid_614679, JString, required = false,
                                 default = nil)
  if valid_614679 != nil:
    section.add "X-Amz-Date", valid_614679
  var valid_614680 = header.getOrDefault("X-Amz-Credential")
  valid_614680 = validateParameter(valid_614680, JString, required = false,
                                 default = nil)
  if valid_614680 != nil:
    section.add "X-Amz-Credential", valid_614680
  var valid_614681 = header.getOrDefault("X-Amz-Security-Token")
  valid_614681 = validateParameter(valid_614681, JString, required = false,
                                 default = nil)
  if valid_614681 != nil:
    section.add "X-Amz-Security-Token", valid_614681
  var valid_614682 = header.getOrDefault("X-Amz-Algorithm")
  valid_614682 = validateParameter(valid_614682, JString, required = false,
                                 default = nil)
  if valid_614682 != nil:
    section.add "X-Amz-Algorithm", valid_614682
  var valid_614683 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614683 = validateParameter(valid_614683, JString, required = false,
                                 default = nil)
  if valid_614683 != nil:
    section.add "X-Amz-SignedHeaders", valid_614683
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614685: Call_PutComplianceItems_614673; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Registers a compliance type and other compliance details on a designated resource. This action lets you register custom compliance details with a resource. This call overwrites existing compliance information on the resource, so you must provide a full list of compliance items each time that you send the request.</p> <p>ComplianceType can be one of the following:</p> <ul> <li> <p>ExecutionId: The execution ID when the patch, association, or custom compliance item was applied.</p> </li> <li> <p>ExecutionType: Specify patch, association, or Custom:<code>string</code>.</p> </li> <li> <p>ExecutionTime. The time the patch, association, or custom compliance item was applied to the instance.</p> </li> <li> <p>Id: The patch, association, or custom compliance ID.</p> </li> <li> <p>Title: A title.</p> </li> <li> <p>Status: The status of the compliance item. For example, <code>approved</code> for patches, or <code>Failed</code> for associations.</p> </li> <li> <p>Severity: A patch severity. For example, <code>critical</code>.</p> </li> <li> <p>DocumentName: A SSM document name. For example, AWS-RunPatchBaseline.</p> </li> <li> <p>DocumentVersion: An SSM document version number. For example, 4.</p> </li> <li> <p>Classification: A patch classification. For example, <code>security updates</code>.</p> </li> <li> <p>PatchBaselineId: A patch baseline ID.</p> </li> <li> <p>PatchSeverity: A patch severity. For example, <code>Critical</code>.</p> </li> <li> <p>PatchState: A patch state. For example, <code>InstancesWithFailedPatches</code>.</p> </li> <li> <p>PatchGroup: The name of a patch group.</p> </li> <li> <p>InstalledTime: The time the association, patch, or custom compliance item was applied to the resource. Specify the time by using the following format: yyyy-MM-dd'T'HH:mm:ss'Z'</p> </li> </ul>
  ## 
  let valid = call_614685.validator(path, query, header, formData, body)
  let scheme = call_614685.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614685.url(scheme.get, call_614685.host, call_614685.base,
                         call_614685.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614685, url, valid)

proc call*(call_614686: Call_PutComplianceItems_614673; body: JsonNode): Recallable =
  ## putComplianceItems
  ## <p>Registers a compliance type and other compliance details on a designated resource. This action lets you register custom compliance details with a resource. This call overwrites existing compliance information on the resource, so you must provide a full list of compliance items each time that you send the request.</p> <p>ComplianceType can be one of the following:</p> <ul> <li> <p>ExecutionId: The execution ID when the patch, association, or custom compliance item was applied.</p> </li> <li> <p>ExecutionType: Specify patch, association, or Custom:<code>string</code>.</p> </li> <li> <p>ExecutionTime. The time the patch, association, or custom compliance item was applied to the instance.</p> </li> <li> <p>Id: The patch, association, or custom compliance ID.</p> </li> <li> <p>Title: A title.</p> </li> <li> <p>Status: The status of the compliance item. For example, <code>approved</code> for patches, or <code>Failed</code> for associations.</p> </li> <li> <p>Severity: A patch severity. For example, <code>critical</code>.</p> </li> <li> <p>DocumentName: A SSM document name. For example, AWS-RunPatchBaseline.</p> </li> <li> <p>DocumentVersion: An SSM document version number. For example, 4.</p> </li> <li> <p>Classification: A patch classification. For example, <code>security updates</code>.</p> </li> <li> <p>PatchBaselineId: A patch baseline ID.</p> </li> <li> <p>PatchSeverity: A patch severity. For example, <code>Critical</code>.</p> </li> <li> <p>PatchState: A patch state. For example, <code>InstancesWithFailedPatches</code>.</p> </li> <li> <p>PatchGroup: The name of a patch group.</p> </li> <li> <p>InstalledTime: The time the association, patch, or custom compliance item was applied to the resource. Specify the time by using the following format: yyyy-MM-dd'T'HH:mm:ss'Z'</p> </li> </ul>
  ##   body: JObject (required)
  var body_614687 = newJObject()
  if body != nil:
    body_614687 = body
  result = call_614686.call(nil, nil, nil, nil, body_614687)

var putComplianceItems* = Call_PutComplianceItems_614673(
    name: "putComplianceItems", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.PutComplianceItems",
    validator: validate_PutComplianceItems_614674, base: "/",
    url: url_PutComplianceItems_614675, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutInventory_614688 = ref object of OpenApiRestCall_612658
proc url_PutInventory_614690(protocol: Scheme; host: string; base: string;
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

proc validate_PutInventory_614689(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Bulk update custom inventory items on one more instance. The request adds an inventory item, if it doesn't already exist, or updates an inventory item, if it does exist.
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
  var valid_614691 = header.getOrDefault("X-Amz-Target")
  valid_614691 = validateParameter(valid_614691, JString, required = true,
                                 default = newJString("AmazonSSM.PutInventory"))
  if valid_614691 != nil:
    section.add "X-Amz-Target", valid_614691
  var valid_614692 = header.getOrDefault("X-Amz-Signature")
  valid_614692 = validateParameter(valid_614692, JString, required = false,
                                 default = nil)
  if valid_614692 != nil:
    section.add "X-Amz-Signature", valid_614692
  var valid_614693 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614693 = validateParameter(valid_614693, JString, required = false,
                                 default = nil)
  if valid_614693 != nil:
    section.add "X-Amz-Content-Sha256", valid_614693
  var valid_614694 = header.getOrDefault("X-Amz-Date")
  valid_614694 = validateParameter(valid_614694, JString, required = false,
                                 default = nil)
  if valid_614694 != nil:
    section.add "X-Amz-Date", valid_614694
  var valid_614695 = header.getOrDefault("X-Amz-Credential")
  valid_614695 = validateParameter(valid_614695, JString, required = false,
                                 default = nil)
  if valid_614695 != nil:
    section.add "X-Amz-Credential", valid_614695
  var valid_614696 = header.getOrDefault("X-Amz-Security-Token")
  valid_614696 = validateParameter(valid_614696, JString, required = false,
                                 default = nil)
  if valid_614696 != nil:
    section.add "X-Amz-Security-Token", valid_614696
  var valid_614697 = header.getOrDefault("X-Amz-Algorithm")
  valid_614697 = validateParameter(valid_614697, JString, required = false,
                                 default = nil)
  if valid_614697 != nil:
    section.add "X-Amz-Algorithm", valid_614697
  var valid_614698 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614698 = validateParameter(valid_614698, JString, required = false,
                                 default = nil)
  if valid_614698 != nil:
    section.add "X-Amz-SignedHeaders", valid_614698
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614700: Call_PutInventory_614688; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Bulk update custom inventory items on one more instance. The request adds an inventory item, if it doesn't already exist, or updates an inventory item, if it does exist.
  ## 
  let valid = call_614700.validator(path, query, header, formData, body)
  let scheme = call_614700.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614700.url(scheme.get, call_614700.host, call_614700.base,
                         call_614700.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614700, url, valid)

proc call*(call_614701: Call_PutInventory_614688; body: JsonNode): Recallable =
  ## putInventory
  ## Bulk update custom inventory items on one more instance. The request adds an inventory item, if it doesn't already exist, or updates an inventory item, if it does exist.
  ##   body: JObject (required)
  var body_614702 = newJObject()
  if body != nil:
    body_614702 = body
  result = call_614701.call(nil, nil, nil, nil, body_614702)

var putInventory* = Call_PutInventory_614688(name: "putInventory",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.PutInventory",
    validator: validate_PutInventory_614689, base: "/", url: url_PutInventory_614690,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutParameter_614703 = ref object of OpenApiRestCall_612658
proc url_PutParameter_614705(protocol: Scheme; host: string; base: string;
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

proc validate_PutParameter_614704(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Add a parameter to the system.
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
  var valid_614706 = header.getOrDefault("X-Amz-Target")
  valid_614706 = validateParameter(valid_614706, JString, required = true,
                                 default = newJString("AmazonSSM.PutParameter"))
  if valid_614706 != nil:
    section.add "X-Amz-Target", valid_614706
  var valid_614707 = header.getOrDefault("X-Amz-Signature")
  valid_614707 = validateParameter(valid_614707, JString, required = false,
                                 default = nil)
  if valid_614707 != nil:
    section.add "X-Amz-Signature", valid_614707
  var valid_614708 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614708 = validateParameter(valid_614708, JString, required = false,
                                 default = nil)
  if valid_614708 != nil:
    section.add "X-Amz-Content-Sha256", valid_614708
  var valid_614709 = header.getOrDefault("X-Amz-Date")
  valid_614709 = validateParameter(valid_614709, JString, required = false,
                                 default = nil)
  if valid_614709 != nil:
    section.add "X-Amz-Date", valid_614709
  var valid_614710 = header.getOrDefault("X-Amz-Credential")
  valid_614710 = validateParameter(valid_614710, JString, required = false,
                                 default = nil)
  if valid_614710 != nil:
    section.add "X-Amz-Credential", valid_614710
  var valid_614711 = header.getOrDefault("X-Amz-Security-Token")
  valid_614711 = validateParameter(valid_614711, JString, required = false,
                                 default = nil)
  if valid_614711 != nil:
    section.add "X-Amz-Security-Token", valid_614711
  var valid_614712 = header.getOrDefault("X-Amz-Algorithm")
  valid_614712 = validateParameter(valid_614712, JString, required = false,
                                 default = nil)
  if valid_614712 != nil:
    section.add "X-Amz-Algorithm", valid_614712
  var valid_614713 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614713 = validateParameter(valid_614713, JString, required = false,
                                 default = nil)
  if valid_614713 != nil:
    section.add "X-Amz-SignedHeaders", valid_614713
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614715: Call_PutParameter_614703; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Add a parameter to the system.
  ## 
  let valid = call_614715.validator(path, query, header, formData, body)
  let scheme = call_614715.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614715.url(scheme.get, call_614715.host, call_614715.base,
                         call_614715.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614715, url, valid)

proc call*(call_614716: Call_PutParameter_614703; body: JsonNode): Recallable =
  ## putParameter
  ## Add a parameter to the system.
  ##   body: JObject (required)
  var body_614717 = newJObject()
  if body != nil:
    body_614717 = body
  result = call_614716.call(nil, nil, nil, nil, body_614717)

var putParameter* = Call_PutParameter_614703(name: "putParameter",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.PutParameter",
    validator: validate_PutParameter_614704, base: "/", url: url_PutParameter_614705,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterDefaultPatchBaseline_614718 = ref object of OpenApiRestCall_612658
proc url_RegisterDefaultPatchBaseline_614720(protocol: Scheme; host: string;
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

proc validate_RegisterDefaultPatchBaseline_614719(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Defines the default patch baseline for the relevant operating system.</p> <p>To reset the AWS predefined patch baseline as the default, specify the full patch baseline ARN as the baseline ID value. For example, for CentOS, specify <code>arn:aws:ssm:us-east-2:733109147000:patchbaseline/pb-0574b43a65ea646ed</code> instead of <code>pb-0574b43a65ea646ed</code>.</p>
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
  var valid_614721 = header.getOrDefault("X-Amz-Target")
  valid_614721 = validateParameter(valid_614721, JString, required = true, default = newJString(
      "AmazonSSM.RegisterDefaultPatchBaseline"))
  if valid_614721 != nil:
    section.add "X-Amz-Target", valid_614721
  var valid_614722 = header.getOrDefault("X-Amz-Signature")
  valid_614722 = validateParameter(valid_614722, JString, required = false,
                                 default = nil)
  if valid_614722 != nil:
    section.add "X-Amz-Signature", valid_614722
  var valid_614723 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614723 = validateParameter(valid_614723, JString, required = false,
                                 default = nil)
  if valid_614723 != nil:
    section.add "X-Amz-Content-Sha256", valid_614723
  var valid_614724 = header.getOrDefault("X-Amz-Date")
  valid_614724 = validateParameter(valid_614724, JString, required = false,
                                 default = nil)
  if valid_614724 != nil:
    section.add "X-Amz-Date", valid_614724
  var valid_614725 = header.getOrDefault("X-Amz-Credential")
  valid_614725 = validateParameter(valid_614725, JString, required = false,
                                 default = nil)
  if valid_614725 != nil:
    section.add "X-Amz-Credential", valid_614725
  var valid_614726 = header.getOrDefault("X-Amz-Security-Token")
  valid_614726 = validateParameter(valid_614726, JString, required = false,
                                 default = nil)
  if valid_614726 != nil:
    section.add "X-Amz-Security-Token", valid_614726
  var valid_614727 = header.getOrDefault("X-Amz-Algorithm")
  valid_614727 = validateParameter(valid_614727, JString, required = false,
                                 default = nil)
  if valid_614727 != nil:
    section.add "X-Amz-Algorithm", valid_614727
  var valid_614728 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614728 = validateParameter(valid_614728, JString, required = false,
                                 default = nil)
  if valid_614728 != nil:
    section.add "X-Amz-SignedHeaders", valid_614728
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614730: Call_RegisterDefaultPatchBaseline_614718; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Defines the default patch baseline for the relevant operating system.</p> <p>To reset the AWS predefined patch baseline as the default, specify the full patch baseline ARN as the baseline ID value. For example, for CentOS, specify <code>arn:aws:ssm:us-east-2:733109147000:patchbaseline/pb-0574b43a65ea646ed</code> instead of <code>pb-0574b43a65ea646ed</code>.</p>
  ## 
  let valid = call_614730.validator(path, query, header, formData, body)
  let scheme = call_614730.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614730.url(scheme.get, call_614730.host, call_614730.base,
                         call_614730.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614730, url, valid)

proc call*(call_614731: Call_RegisterDefaultPatchBaseline_614718; body: JsonNode): Recallable =
  ## registerDefaultPatchBaseline
  ## <p>Defines the default patch baseline for the relevant operating system.</p> <p>To reset the AWS predefined patch baseline as the default, specify the full patch baseline ARN as the baseline ID value. For example, for CentOS, specify <code>arn:aws:ssm:us-east-2:733109147000:patchbaseline/pb-0574b43a65ea646ed</code> instead of <code>pb-0574b43a65ea646ed</code>.</p>
  ##   body: JObject (required)
  var body_614732 = newJObject()
  if body != nil:
    body_614732 = body
  result = call_614731.call(nil, nil, nil, nil, body_614732)

var registerDefaultPatchBaseline* = Call_RegisterDefaultPatchBaseline_614718(
    name: "registerDefaultPatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.RegisterDefaultPatchBaseline",
    validator: validate_RegisterDefaultPatchBaseline_614719, base: "/",
    url: url_RegisterDefaultPatchBaseline_614720,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterPatchBaselineForPatchGroup_614733 = ref object of OpenApiRestCall_612658
proc url_RegisterPatchBaselineForPatchGroup_614735(protocol: Scheme; host: string;
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

proc validate_RegisterPatchBaselineForPatchGroup_614734(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Registers a patch baseline for a patch group.
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
  var valid_614736 = header.getOrDefault("X-Amz-Target")
  valid_614736 = validateParameter(valid_614736, JString, required = true, default = newJString(
      "AmazonSSM.RegisterPatchBaselineForPatchGroup"))
  if valid_614736 != nil:
    section.add "X-Amz-Target", valid_614736
  var valid_614737 = header.getOrDefault("X-Amz-Signature")
  valid_614737 = validateParameter(valid_614737, JString, required = false,
                                 default = nil)
  if valid_614737 != nil:
    section.add "X-Amz-Signature", valid_614737
  var valid_614738 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614738 = validateParameter(valid_614738, JString, required = false,
                                 default = nil)
  if valid_614738 != nil:
    section.add "X-Amz-Content-Sha256", valid_614738
  var valid_614739 = header.getOrDefault("X-Amz-Date")
  valid_614739 = validateParameter(valid_614739, JString, required = false,
                                 default = nil)
  if valid_614739 != nil:
    section.add "X-Amz-Date", valid_614739
  var valid_614740 = header.getOrDefault("X-Amz-Credential")
  valid_614740 = validateParameter(valid_614740, JString, required = false,
                                 default = nil)
  if valid_614740 != nil:
    section.add "X-Amz-Credential", valid_614740
  var valid_614741 = header.getOrDefault("X-Amz-Security-Token")
  valid_614741 = validateParameter(valid_614741, JString, required = false,
                                 default = nil)
  if valid_614741 != nil:
    section.add "X-Amz-Security-Token", valid_614741
  var valid_614742 = header.getOrDefault("X-Amz-Algorithm")
  valid_614742 = validateParameter(valid_614742, JString, required = false,
                                 default = nil)
  if valid_614742 != nil:
    section.add "X-Amz-Algorithm", valid_614742
  var valid_614743 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614743 = validateParameter(valid_614743, JString, required = false,
                                 default = nil)
  if valid_614743 != nil:
    section.add "X-Amz-SignedHeaders", valid_614743
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614745: Call_RegisterPatchBaselineForPatchGroup_614733;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Registers a patch baseline for a patch group.
  ## 
  let valid = call_614745.validator(path, query, header, formData, body)
  let scheme = call_614745.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614745.url(scheme.get, call_614745.host, call_614745.base,
                         call_614745.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614745, url, valid)

proc call*(call_614746: Call_RegisterPatchBaselineForPatchGroup_614733;
          body: JsonNode): Recallable =
  ## registerPatchBaselineForPatchGroup
  ## Registers a patch baseline for a patch group.
  ##   body: JObject (required)
  var body_614747 = newJObject()
  if body != nil:
    body_614747 = body
  result = call_614746.call(nil, nil, nil, nil, body_614747)

var registerPatchBaselineForPatchGroup* = Call_RegisterPatchBaselineForPatchGroup_614733(
    name: "registerPatchBaselineForPatchGroup", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.RegisterPatchBaselineForPatchGroup",
    validator: validate_RegisterPatchBaselineForPatchGroup_614734, base: "/",
    url: url_RegisterPatchBaselineForPatchGroup_614735,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterTargetWithMaintenanceWindow_614748 = ref object of OpenApiRestCall_612658
proc url_RegisterTargetWithMaintenanceWindow_614750(protocol: Scheme; host: string;
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

proc validate_RegisterTargetWithMaintenanceWindow_614749(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Registers a target with a maintenance window.
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
  var valid_614751 = header.getOrDefault("X-Amz-Target")
  valid_614751 = validateParameter(valid_614751, JString, required = true, default = newJString(
      "AmazonSSM.RegisterTargetWithMaintenanceWindow"))
  if valid_614751 != nil:
    section.add "X-Amz-Target", valid_614751
  var valid_614752 = header.getOrDefault("X-Amz-Signature")
  valid_614752 = validateParameter(valid_614752, JString, required = false,
                                 default = nil)
  if valid_614752 != nil:
    section.add "X-Amz-Signature", valid_614752
  var valid_614753 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614753 = validateParameter(valid_614753, JString, required = false,
                                 default = nil)
  if valid_614753 != nil:
    section.add "X-Amz-Content-Sha256", valid_614753
  var valid_614754 = header.getOrDefault("X-Amz-Date")
  valid_614754 = validateParameter(valid_614754, JString, required = false,
                                 default = nil)
  if valid_614754 != nil:
    section.add "X-Amz-Date", valid_614754
  var valid_614755 = header.getOrDefault("X-Amz-Credential")
  valid_614755 = validateParameter(valid_614755, JString, required = false,
                                 default = nil)
  if valid_614755 != nil:
    section.add "X-Amz-Credential", valid_614755
  var valid_614756 = header.getOrDefault("X-Amz-Security-Token")
  valid_614756 = validateParameter(valid_614756, JString, required = false,
                                 default = nil)
  if valid_614756 != nil:
    section.add "X-Amz-Security-Token", valid_614756
  var valid_614757 = header.getOrDefault("X-Amz-Algorithm")
  valid_614757 = validateParameter(valid_614757, JString, required = false,
                                 default = nil)
  if valid_614757 != nil:
    section.add "X-Amz-Algorithm", valid_614757
  var valid_614758 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614758 = validateParameter(valid_614758, JString, required = false,
                                 default = nil)
  if valid_614758 != nil:
    section.add "X-Amz-SignedHeaders", valid_614758
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614760: Call_RegisterTargetWithMaintenanceWindow_614748;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Registers a target with a maintenance window.
  ## 
  let valid = call_614760.validator(path, query, header, formData, body)
  let scheme = call_614760.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614760.url(scheme.get, call_614760.host, call_614760.base,
                         call_614760.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614760, url, valid)

proc call*(call_614761: Call_RegisterTargetWithMaintenanceWindow_614748;
          body: JsonNode): Recallable =
  ## registerTargetWithMaintenanceWindow
  ## Registers a target with a maintenance window.
  ##   body: JObject (required)
  var body_614762 = newJObject()
  if body != nil:
    body_614762 = body
  result = call_614761.call(nil, nil, nil, nil, body_614762)

var registerTargetWithMaintenanceWindow* = Call_RegisterTargetWithMaintenanceWindow_614748(
    name: "registerTargetWithMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.RegisterTargetWithMaintenanceWindow",
    validator: validate_RegisterTargetWithMaintenanceWindow_614749, base: "/",
    url: url_RegisterTargetWithMaintenanceWindow_614750,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterTaskWithMaintenanceWindow_614763 = ref object of OpenApiRestCall_612658
proc url_RegisterTaskWithMaintenanceWindow_614765(protocol: Scheme; host: string;
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

proc validate_RegisterTaskWithMaintenanceWindow_614764(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds a new task to a maintenance window.
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
  var valid_614766 = header.getOrDefault("X-Amz-Target")
  valid_614766 = validateParameter(valid_614766, JString, required = true, default = newJString(
      "AmazonSSM.RegisterTaskWithMaintenanceWindow"))
  if valid_614766 != nil:
    section.add "X-Amz-Target", valid_614766
  var valid_614767 = header.getOrDefault("X-Amz-Signature")
  valid_614767 = validateParameter(valid_614767, JString, required = false,
                                 default = nil)
  if valid_614767 != nil:
    section.add "X-Amz-Signature", valid_614767
  var valid_614768 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614768 = validateParameter(valid_614768, JString, required = false,
                                 default = nil)
  if valid_614768 != nil:
    section.add "X-Amz-Content-Sha256", valid_614768
  var valid_614769 = header.getOrDefault("X-Amz-Date")
  valid_614769 = validateParameter(valid_614769, JString, required = false,
                                 default = nil)
  if valid_614769 != nil:
    section.add "X-Amz-Date", valid_614769
  var valid_614770 = header.getOrDefault("X-Amz-Credential")
  valid_614770 = validateParameter(valid_614770, JString, required = false,
                                 default = nil)
  if valid_614770 != nil:
    section.add "X-Amz-Credential", valid_614770
  var valid_614771 = header.getOrDefault("X-Amz-Security-Token")
  valid_614771 = validateParameter(valid_614771, JString, required = false,
                                 default = nil)
  if valid_614771 != nil:
    section.add "X-Amz-Security-Token", valid_614771
  var valid_614772 = header.getOrDefault("X-Amz-Algorithm")
  valid_614772 = validateParameter(valid_614772, JString, required = false,
                                 default = nil)
  if valid_614772 != nil:
    section.add "X-Amz-Algorithm", valid_614772
  var valid_614773 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614773 = validateParameter(valid_614773, JString, required = false,
                                 default = nil)
  if valid_614773 != nil:
    section.add "X-Amz-SignedHeaders", valid_614773
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614775: Call_RegisterTaskWithMaintenanceWindow_614763;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Adds a new task to a maintenance window.
  ## 
  let valid = call_614775.validator(path, query, header, formData, body)
  let scheme = call_614775.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614775.url(scheme.get, call_614775.host, call_614775.base,
                         call_614775.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614775, url, valid)

proc call*(call_614776: Call_RegisterTaskWithMaintenanceWindow_614763;
          body: JsonNode): Recallable =
  ## registerTaskWithMaintenanceWindow
  ## Adds a new task to a maintenance window.
  ##   body: JObject (required)
  var body_614777 = newJObject()
  if body != nil:
    body_614777 = body
  result = call_614776.call(nil, nil, nil, nil, body_614777)

var registerTaskWithMaintenanceWindow* = Call_RegisterTaskWithMaintenanceWindow_614763(
    name: "registerTaskWithMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.RegisterTaskWithMaintenanceWindow",
    validator: validate_RegisterTaskWithMaintenanceWindow_614764, base: "/",
    url: url_RegisterTaskWithMaintenanceWindow_614765,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveTagsFromResource_614778 = ref object of OpenApiRestCall_612658
proc url_RemoveTagsFromResource_614780(protocol: Scheme; host: string; base: string;
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

proc validate_RemoveTagsFromResource_614779(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes tag keys from the specified resource.
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
  var valid_614781 = header.getOrDefault("X-Amz-Target")
  valid_614781 = validateParameter(valid_614781, JString, required = true, default = newJString(
      "AmazonSSM.RemoveTagsFromResource"))
  if valid_614781 != nil:
    section.add "X-Amz-Target", valid_614781
  var valid_614782 = header.getOrDefault("X-Amz-Signature")
  valid_614782 = validateParameter(valid_614782, JString, required = false,
                                 default = nil)
  if valid_614782 != nil:
    section.add "X-Amz-Signature", valid_614782
  var valid_614783 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614783 = validateParameter(valid_614783, JString, required = false,
                                 default = nil)
  if valid_614783 != nil:
    section.add "X-Amz-Content-Sha256", valid_614783
  var valid_614784 = header.getOrDefault("X-Amz-Date")
  valid_614784 = validateParameter(valid_614784, JString, required = false,
                                 default = nil)
  if valid_614784 != nil:
    section.add "X-Amz-Date", valid_614784
  var valid_614785 = header.getOrDefault("X-Amz-Credential")
  valid_614785 = validateParameter(valid_614785, JString, required = false,
                                 default = nil)
  if valid_614785 != nil:
    section.add "X-Amz-Credential", valid_614785
  var valid_614786 = header.getOrDefault("X-Amz-Security-Token")
  valid_614786 = validateParameter(valid_614786, JString, required = false,
                                 default = nil)
  if valid_614786 != nil:
    section.add "X-Amz-Security-Token", valid_614786
  var valid_614787 = header.getOrDefault("X-Amz-Algorithm")
  valid_614787 = validateParameter(valid_614787, JString, required = false,
                                 default = nil)
  if valid_614787 != nil:
    section.add "X-Amz-Algorithm", valid_614787
  var valid_614788 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614788 = validateParameter(valid_614788, JString, required = false,
                                 default = nil)
  if valid_614788 != nil:
    section.add "X-Amz-SignedHeaders", valid_614788
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614790: Call_RemoveTagsFromResource_614778; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tag keys from the specified resource.
  ## 
  let valid = call_614790.validator(path, query, header, formData, body)
  let scheme = call_614790.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614790.url(scheme.get, call_614790.host, call_614790.base,
                         call_614790.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614790, url, valid)

proc call*(call_614791: Call_RemoveTagsFromResource_614778; body: JsonNode): Recallable =
  ## removeTagsFromResource
  ## Removes tag keys from the specified resource.
  ##   body: JObject (required)
  var body_614792 = newJObject()
  if body != nil:
    body_614792 = body
  result = call_614791.call(nil, nil, nil, nil, body_614792)

var removeTagsFromResource* = Call_RemoveTagsFromResource_614778(
    name: "removeTagsFromResource", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.RemoveTagsFromResource",
    validator: validate_RemoveTagsFromResource_614779, base: "/",
    url: url_RemoveTagsFromResource_614780, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResetServiceSetting_614793 = ref object of OpenApiRestCall_612658
proc url_ResetServiceSetting_614795(protocol: Scheme; host: string; base: string;
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

proc validate_ResetServiceSetting_614794(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>GetServiceSetting</a> API action to view the current value. Use the <a>UpdateServiceSetting</a> API action to change the default setting. </p> <p>Reset the service setting for the account to the default value as provisioned by the AWS service team. </p>
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
  var valid_614796 = header.getOrDefault("X-Amz-Target")
  valid_614796 = validateParameter(valid_614796, JString, required = true, default = newJString(
      "AmazonSSM.ResetServiceSetting"))
  if valid_614796 != nil:
    section.add "X-Amz-Target", valid_614796
  var valid_614797 = header.getOrDefault("X-Amz-Signature")
  valid_614797 = validateParameter(valid_614797, JString, required = false,
                                 default = nil)
  if valid_614797 != nil:
    section.add "X-Amz-Signature", valid_614797
  var valid_614798 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614798 = validateParameter(valid_614798, JString, required = false,
                                 default = nil)
  if valid_614798 != nil:
    section.add "X-Amz-Content-Sha256", valid_614798
  var valid_614799 = header.getOrDefault("X-Amz-Date")
  valid_614799 = validateParameter(valid_614799, JString, required = false,
                                 default = nil)
  if valid_614799 != nil:
    section.add "X-Amz-Date", valid_614799
  var valid_614800 = header.getOrDefault("X-Amz-Credential")
  valid_614800 = validateParameter(valid_614800, JString, required = false,
                                 default = nil)
  if valid_614800 != nil:
    section.add "X-Amz-Credential", valid_614800
  var valid_614801 = header.getOrDefault("X-Amz-Security-Token")
  valid_614801 = validateParameter(valid_614801, JString, required = false,
                                 default = nil)
  if valid_614801 != nil:
    section.add "X-Amz-Security-Token", valid_614801
  var valid_614802 = header.getOrDefault("X-Amz-Algorithm")
  valid_614802 = validateParameter(valid_614802, JString, required = false,
                                 default = nil)
  if valid_614802 != nil:
    section.add "X-Amz-Algorithm", valid_614802
  var valid_614803 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614803 = validateParameter(valid_614803, JString, required = false,
                                 default = nil)
  if valid_614803 != nil:
    section.add "X-Amz-SignedHeaders", valid_614803
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614805: Call_ResetServiceSetting_614793; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>GetServiceSetting</a> API action to view the current value. Use the <a>UpdateServiceSetting</a> API action to change the default setting. </p> <p>Reset the service setting for the account to the default value as provisioned by the AWS service team. </p>
  ## 
  let valid = call_614805.validator(path, query, header, formData, body)
  let scheme = call_614805.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614805.url(scheme.get, call_614805.host, call_614805.base,
                         call_614805.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614805, url, valid)

proc call*(call_614806: Call_ResetServiceSetting_614793; body: JsonNode): Recallable =
  ## resetServiceSetting
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>GetServiceSetting</a> API action to view the current value. Use the <a>UpdateServiceSetting</a> API action to change the default setting. </p> <p>Reset the service setting for the account to the default value as provisioned by the AWS service team. </p>
  ##   body: JObject (required)
  var body_614807 = newJObject()
  if body != nil:
    body_614807 = body
  result = call_614806.call(nil, nil, nil, nil, body_614807)

var resetServiceSetting* = Call_ResetServiceSetting_614793(
    name: "resetServiceSetting", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ResetServiceSetting",
    validator: validate_ResetServiceSetting_614794, base: "/",
    url: url_ResetServiceSetting_614795, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResumeSession_614808 = ref object of OpenApiRestCall_612658
proc url_ResumeSession_614810(protocol: Scheme; host: string; base: string;
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

proc validate_ResumeSession_614809(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Reconnects a session to an instance after it has been disconnected. Connections can be resumed for disconnected sessions, but not terminated sessions.</p> <note> <p>This command is primarily for use by client machines to automatically reconnect during intermittent network issues. It is not intended for any other use.</p> </note>
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
  var valid_614811 = header.getOrDefault("X-Amz-Target")
  valid_614811 = validateParameter(valid_614811, JString, required = true, default = newJString(
      "AmazonSSM.ResumeSession"))
  if valid_614811 != nil:
    section.add "X-Amz-Target", valid_614811
  var valid_614812 = header.getOrDefault("X-Amz-Signature")
  valid_614812 = validateParameter(valid_614812, JString, required = false,
                                 default = nil)
  if valid_614812 != nil:
    section.add "X-Amz-Signature", valid_614812
  var valid_614813 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614813 = validateParameter(valid_614813, JString, required = false,
                                 default = nil)
  if valid_614813 != nil:
    section.add "X-Amz-Content-Sha256", valid_614813
  var valid_614814 = header.getOrDefault("X-Amz-Date")
  valid_614814 = validateParameter(valid_614814, JString, required = false,
                                 default = nil)
  if valid_614814 != nil:
    section.add "X-Amz-Date", valid_614814
  var valid_614815 = header.getOrDefault("X-Amz-Credential")
  valid_614815 = validateParameter(valid_614815, JString, required = false,
                                 default = nil)
  if valid_614815 != nil:
    section.add "X-Amz-Credential", valid_614815
  var valid_614816 = header.getOrDefault("X-Amz-Security-Token")
  valid_614816 = validateParameter(valid_614816, JString, required = false,
                                 default = nil)
  if valid_614816 != nil:
    section.add "X-Amz-Security-Token", valid_614816
  var valid_614817 = header.getOrDefault("X-Amz-Algorithm")
  valid_614817 = validateParameter(valid_614817, JString, required = false,
                                 default = nil)
  if valid_614817 != nil:
    section.add "X-Amz-Algorithm", valid_614817
  var valid_614818 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614818 = validateParameter(valid_614818, JString, required = false,
                                 default = nil)
  if valid_614818 != nil:
    section.add "X-Amz-SignedHeaders", valid_614818
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614820: Call_ResumeSession_614808; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Reconnects a session to an instance after it has been disconnected. Connections can be resumed for disconnected sessions, but not terminated sessions.</p> <note> <p>This command is primarily for use by client machines to automatically reconnect during intermittent network issues. It is not intended for any other use.</p> </note>
  ## 
  let valid = call_614820.validator(path, query, header, formData, body)
  let scheme = call_614820.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614820.url(scheme.get, call_614820.host, call_614820.base,
                         call_614820.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614820, url, valid)

proc call*(call_614821: Call_ResumeSession_614808; body: JsonNode): Recallable =
  ## resumeSession
  ## <p>Reconnects a session to an instance after it has been disconnected. Connections can be resumed for disconnected sessions, but not terminated sessions.</p> <note> <p>This command is primarily for use by client machines to automatically reconnect during intermittent network issues. It is not intended for any other use.</p> </note>
  ##   body: JObject (required)
  var body_614822 = newJObject()
  if body != nil:
    body_614822 = body
  result = call_614821.call(nil, nil, nil, nil, body_614822)

var resumeSession* = Call_ResumeSession_614808(name: "resumeSession",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ResumeSession",
    validator: validate_ResumeSession_614809, base: "/", url: url_ResumeSession_614810,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendAutomationSignal_614823 = ref object of OpenApiRestCall_612658
proc url_SendAutomationSignal_614825(protocol: Scheme; host: string; base: string;
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

proc validate_SendAutomationSignal_614824(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Sends a signal to an Automation execution to change the current behavior or status of the execution. 
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
  var valid_614826 = header.getOrDefault("X-Amz-Target")
  valid_614826 = validateParameter(valid_614826, JString, required = true, default = newJString(
      "AmazonSSM.SendAutomationSignal"))
  if valid_614826 != nil:
    section.add "X-Amz-Target", valid_614826
  var valid_614827 = header.getOrDefault("X-Amz-Signature")
  valid_614827 = validateParameter(valid_614827, JString, required = false,
                                 default = nil)
  if valid_614827 != nil:
    section.add "X-Amz-Signature", valid_614827
  var valid_614828 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614828 = validateParameter(valid_614828, JString, required = false,
                                 default = nil)
  if valid_614828 != nil:
    section.add "X-Amz-Content-Sha256", valid_614828
  var valid_614829 = header.getOrDefault("X-Amz-Date")
  valid_614829 = validateParameter(valid_614829, JString, required = false,
                                 default = nil)
  if valid_614829 != nil:
    section.add "X-Amz-Date", valid_614829
  var valid_614830 = header.getOrDefault("X-Amz-Credential")
  valid_614830 = validateParameter(valid_614830, JString, required = false,
                                 default = nil)
  if valid_614830 != nil:
    section.add "X-Amz-Credential", valid_614830
  var valid_614831 = header.getOrDefault("X-Amz-Security-Token")
  valid_614831 = validateParameter(valid_614831, JString, required = false,
                                 default = nil)
  if valid_614831 != nil:
    section.add "X-Amz-Security-Token", valid_614831
  var valid_614832 = header.getOrDefault("X-Amz-Algorithm")
  valid_614832 = validateParameter(valid_614832, JString, required = false,
                                 default = nil)
  if valid_614832 != nil:
    section.add "X-Amz-Algorithm", valid_614832
  var valid_614833 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614833 = validateParameter(valid_614833, JString, required = false,
                                 default = nil)
  if valid_614833 != nil:
    section.add "X-Amz-SignedHeaders", valid_614833
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614835: Call_SendAutomationSignal_614823; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sends a signal to an Automation execution to change the current behavior or status of the execution. 
  ## 
  let valid = call_614835.validator(path, query, header, formData, body)
  let scheme = call_614835.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614835.url(scheme.get, call_614835.host, call_614835.base,
                         call_614835.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614835, url, valid)

proc call*(call_614836: Call_SendAutomationSignal_614823; body: JsonNode): Recallable =
  ## sendAutomationSignal
  ## Sends a signal to an Automation execution to change the current behavior or status of the execution. 
  ##   body: JObject (required)
  var body_614837 = newJObject()
  if body != nil:
    body_614837 = body
  result = call_614836.call(nil, nil, nil, nil, body_614837)

var sendAutomationSignal* = Call_SendAutomationSignal_614823(
    name: "sendAutomationSignal", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.SendAutomationSignal",
    validator: validate_SendAutomationSignal_614824, base: "/",
    url: url_SendAutomationSignal_614825, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendCommand_614838 = ref object of OpenApiRestCall_612658
proc url_SendCommand_614840(protocol: Scheme; host: string; base: string;
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

proc validate_SendCommand_614839(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Runs commands on one or more managed instances.
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
  var valid_614841 = header.getOrDefault("X-Amz-Target")
  valid_614841 = validateParameter(valid_614841, JString, required = true,
                                 default = newJString("AmazonSSM.SendCommand"))
  if valid_614841 != nil:
    section.add "X-Amz-Target", valid_614841
  var valid_614842 = header.getOrDefault("X-Amz-Signature")
  valid_614842 = validateParameter(valid_614842, JString, required = false,
                                 default = nil)
  if valid_614842 != nil:
    section.add "X-Amz-Signature", valid_614842
  var valid_614843 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614843 = validateParameter(valid_614843, JString, required = false,
                                 default = nil)
  if valid_614843 != nil:
    section.add "X-Amz-Content-Sha256", valid_614843
  var valid_614844 = header.getOrDefault("X-Amz-Date")
  valid_614844 = validateParameter(valid_614844, JString, required = false,
                                 default = nil)
  if valid_614844 != nil:
    section.add "X-Amz-Date", valid_614844
  var valid_614845 = header.getOrDefault("X-Amz-Credential")
  valid_614845 = validateParameter(valid_614845, JString, required = false,
                                 default = nil)
  if valid_614845 != nil:
    section.add "X-Amz-Credential", valid_614845
  var valid_614846 = header.getOrDefault("X-Amz-Security-Token")
  valid_614846 = validateParameter(valid_614846, JString, required = false,
                                 default = nil)
  if valid_614846 != nil:
    section.add "X-Amz-Security-Token", valid_614846
  var valid_614847 = header.getOrDefault("X-Amz-Algorithm")
  valid_614847 = validateParameter(valid_614847, JString, required = false,
                                 default = nil)
  if valid_614847 != nil:
    section.add "X-Amz-Algorithm", valid_614847
  var valid_614848 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614848 = validateParameter(valid_614848, JString, required = false,
                                 default = nil)
  if valid_614848 != nil:
    section.add "X-Amz-SignedHeaders", valid_614848
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614850: Call_SendCommand_614838; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Runs commands on one or more managed instances.
  ## 
  let valid = call_614850.validator(path, query, header, formData, body)
  let scheme = call_614850.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614850.url(scheme.get, call_614850.host, call_614850.base,
                         call_614850.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614850, url, valid)

proc call*(call_614851: Call_SendCommand_614838; body: JsonNode): Recallable =
  ## sendCommand
  ## Runs commands on one or more managed instances.
  ##   body: JObject (required)
  var body_614852 = newJObject()
  if body != nil:
    body_614852 = body
  result = call_614851.call(nil, nil, nil, nil, body_614852)

var sendCommand* = Call_SendCommand_614838(name: "sendCommand",
                                        meth: HttpMethod.HttpPost,
                                        host: "ssm.amazonaws.com", route: "/#X-Amz-Target=AmazonSSM.SendCommand",
                                        validator: validate_SendCommand_614839,
                                        base: "/", url: url_SendCommand_614840,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartAssociationsOnce_614853 = ref object of OpenApiRestCall_612658
proc url_StartAssociationsOnce_614855(protocol: Scheme; host: string; base: string;
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

proc validate_StartAssociationsOnce_614854(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Use this API action to run an association immediately and only one time. This action can be helpful when troubleshooting associations.
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
  var valid_614856 = header.getOrDefault("X-Amz-Target")
  valid_614856 = validateParameter(valid_614856, JString, required = true, default = newJString(
      "AmazonSSM.StartAssociationsOnce"))
  if valid_614856 != nil:
    section.add "X-Amz-Target", valid_614856
  var valid_614857 = header.getOrDefault("X-Amz-Signature")
  valid_614857 = validateParameter(valid_614857, JString, required = false,
                                 default = nil)
  if valid_614857 != nil:
    section.add "X-Amz-Signature", valid_614857
  var valid_614858 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614858 = validateParameter(valid_614858, JString, required = false,
                                 default = nil)
  if valid_614858 != nil:
    section.add "X-Amz-Content-Sha256", valid_614858
  var valid_614859 = header.getOrDefault("X-Amz-Date")
  valid_614859 = validateParameter(valid_614859, JString, required = false,
                                 default = nil)
  if valid_614859 != nil:
    section.add "X-Amz-Date", valid_614859
  var valid_614860 = header.getOrDefault("X-Amz-Credential")
  valid_614860 = validateParameter(valid_614860, JString, required = false,
                                 default = nil)
  if valid_614860 != nil:
    section.add "X-Amz-Credential", valid_614860
  var valid_614861 = header.getOrDefault("X-Amz-Security-Token")
  valid_614861 = validateParameter(valid_614861, JString, required = false,
                                 default = nil)
  if valid_614861 != nil:
    section.add "X-Amz-Security-Token", valid_614861
  var valid_614862 = header.getOrDefault("X-Amz-Algorithm")
  valid_614862 = validateParameter(valid_614862, JString, required = false,
                                 default = nil)
  if valid_614862 != nil:
    section.add "X-Amz-Algorithm", valid_614862
  var valid_614863 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614863 = validateParameter(valid_614863, JString, required = false,
                                 default = nil)
  if valid_614863 != nil:
    section.add "X-Amz-SignedHeaders", valid_614863
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614865: Call_StartAssociationsOnce_614853; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Use this API action to run an association immediately and only one time. This action can be helpful when troubleshooting associations.
  ## 
  let valid = call_614865.validator(path, query, header, formData, body)
  let scheme = call_614865.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614865.url(scheme.get, call_614865.host, call_614865.base,
                         call_614865.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614865, url, valid)

proc call*(call_614866: Call_StartAssociationsOnce_614853; body: JsonNode): Recallable =
  ## startAssociationsOnce
  ## Use this API action to run an association immediately and only one time. This action can be helpful when troubleshooting associations.
  ##   body: JObject (required)
  var body_614867 = newJObject()
  if body != nil:
    body_614867 = body
  result = call_614866.call(nil, nil, nil, nil, body_614867)

var startAssociationsOnce* = Call_StartAssociationsOnce_614853(
    name: "startAssociationsOnce", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.StartAssociationsOnce",
    validator: validate_StartAssociationsOnce_614854, base: "/",
    url: url_StartAssociationsOnce_614855, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartAutomationExecution_614868 = ref object of OpenApiRestCall_612658
proc url_StartAutomationExecution_614870(protocol: Scheme; host: string;
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

proc validate_StartAutomationExecution_614869(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Initiates execution of an Automation document.
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
  var valid_614871 = header.getOrDefault("X-Amz-Target")
  valid_614871 = validateParameter(valid_614871, JString, required = true, default = newJString(
      "AmazonSSM.StartAutomationExecution"))
  if valid_614871 != nil:
    section.add "X-Amz-Target", valid_614871
  var valid_614872 = header.getOrDefault("X-Amz-Signature")
  valid_614872 = validateParameter(valid_614872, JString, required = false,
                                 default = nil)
  if valid_614872 != nil:
    section.add "X-Amz-Signature", valid_614872
  var valid_614873 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614873 = validateParameter(valid_614873, JString, required = false,
                                 default = nil)
  if valid_614873 != nil:
    section.add "X-Amz-Content-Sha256", valid_614873
  var valid_614874 = header.getOrDefault("X-Amz-Date")
  valid_614874 = validateParameter(valid_614874, JString, required = false,
                                 default = nil)
  if valid_614874 != nil:
    section.add "X-Amz-Date", valid_614874
  var valid_614875 = header.getOrDefault("X-Amz-Credential")
  valid_614875 = validateParameter(valid_614875, JString, required = false,
                                 default = nil)
  if valid_614875 != nil:
    section.add "X-Amz-Credential", valid_614875
  var valid_614876 = header.getOrDefault("X-Amz-Security-Token")
  valid_614876 = validateParameter(valid_614876, JString, required = false,
                                 default = nil)
  if valid_614876 != nil:
    section.add "X-Amz-Security-Token", valid_614876
  var valid_614877 = header.getOrDefault("X-Amz-Algorithm")
  valid_614877 = validateParameter(valid_614877, JString, required = false,
                                 default = nil)
  if valid_614877 != nil:
    section.add "X-Amz-Algorithm", valid_614877
  var valid_614878 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614878 = validateParameter(valid_614878, JString, required = false,
                                 default = nil)
  if valid_614878 != nil:
    section.add "X-Amz-SignedHeaders", valid_614878
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614880: Call_StartAutomationExecution_614868; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Initiates execution of an Automation document.
  ## 
  let valid = call_614880.validator(path, query, header, formData, body)
  let scheme = call_614880.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614880.url(scheme.get, call_614880.host, call_614880.base,
                         call_614880.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614880, url, valid)

proc call*(call_614881: Call_StartAutomationExecution_614868; body: JsonNode): Recallable =
  ## startAutomationExecution
  ## Initiates execution of an Automation document.
  ##   body: JObject (required)
  var body_614882 = newJObject()
  if body != nil:
    body_614882 = body
  result = call_614881.call(nil, nil, nil, nil, body_614882)

var startAutomationExecution* = Call_StartAutomationExecution_614868(
    name: "startAutomationExecution", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.StartAutomationExecution",
    validator: validate_StartAutomationExecution_614869, base: "/",
    url: url_StartAutomationExecution_614870, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartSession_614883 = ref object of OpenApiRestCall_612658
proc url_StartSession_614885(protocol: Scheme; host: string; base: string;
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

proc validate_StartSession_614884(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Initiates a connection to a target (for example, an instance) for a Session Manager session. Returns a URL and token that can be used to open a WebSocket connection for sending input and receiving outputs.</p> <note> <p>AWS CLI usage: <code>start-session</code> is an interactive command that requires the Session Manager plugin to be installed on the client machine making the call. For information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html"> Install the Session Manager Plugin for the AWS CLI</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>AWS Tools for PowerShell usage: Start-SSMSession is not currently supported by AWS Tools for PowerShell on Windows local machines.</p> </note>
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
  var valid_614886 = header.getOrDefault("X-Amz-Target")
  valid_614886 = validateParameter(valid_614886, JString, required = true,
                                 default = newJString("AmazonSSM.StartSession"))
  if valid_614886 != nil:
    section.add "X-Amz-Target", valid_614886
  var valid_614887 = header.getOrDefault("X-Amz-Signature")
  valid_614887 = validateParameter(valid_614887, JString, required = false,
                                 default = nil)
  if valid_614887 != nil:
    section.add "X-Amz-Signature", valid_614887
  var valid_614888 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614888 = validateParameter(valid_614888, JString, required = false,
                                 default = nil)
  if valid_614888 != nil:
    section.add "X-Amz-Content-Sha256", valid_614888
  var valid_614889 = header.getOrDefault("X-Amz-Date")
  valid_614889 = validateParameter(valid_614889, JString, required = false,
                                 default = nil)
  if valid_614889 != nil:
    section.add "X-Amz-Date", valid_614889
  var valid_614890 = header.getOrDefault("X-Amz-Credential")
  valid_614890 = validateParameter(valid_614890, JString, required = false,
                                 default = nil)
  if valid_614890 != nil:
    section.add "X-Amz-Credential", valid_614890
  var valid_614891 = header.getOrDefault("X-Amz-Security-Token")
  valid_614891 = validateParameter(valid_614891, JString, required = false,
                                 default = nil)
  if valid_614891 != nil:
    section.add "X-Amz-Security-Token", valid_614891
  var valid_614892 = header.getOrDefault("X-Amz-Algorithm")
  valid_614892 = validateParameter(valid_614892, JString, required = false,
                                 default = nil)
  if valid_614892 != nil:
    section.add "X-Amz-Algorithm", valid_614892
  var valid_614893 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614893 = validateParameter(valid_614893, JString, required = false,
                                 default = nil)
  if valid_614893 != nil:
    section.add "X-Amz-SignedHeaders", valid_614893
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614895: Call_StartSession_614883; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates a connection to a target (for example, an instance) for a Session Manager session. Returns a URL and token that can be used to open a WebSocket connection for sending input and receiving outputs.</p> <note> <p>AWS CLI usage: <code>start-session</code> is an interactive command that requires the Session Manager plugin to be installed on the client machine making the call. For information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html"> Install the Session Manager Plugin for the AWS CLI</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>AWS Tools for PowerShell usage: Start-SSMSession is not currently supported by AWS Tools for PowerShell on Windows local machines.</p> </note>
  ## 
  let valid = call_614895.validator(path, query, header, formData, body)
  let scheme = call_614895.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614895.url(scheme.get, call_614895.host, call_614895.base,
                         call_614895.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614895, url, valid)

proc call*(call_614896: Call_StartSession_614883; body: JsonNode): Recallable =
  ## startSession
  ## <p>Initiates a connection to a target (for example, an instance) for a Session Manager session. Returns a URL and token that can be used to open a WebSocket connection for sending input and receiving outputs.</p> <note> <p>AWS CLI usage: <code>start-session</code> is an interactive command that requires the Session Manager plugin to be installed on the client machine making the call. For information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html"> Install the Session Manager Plugin for the AWS CLI</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>AWS Tools for PowerShell usage: Start-SSMSession is not currently supported by AWS Tools for PowerShell on Windows local machines.</p> </note>
  ##   body: JObject (required)
  var body_614897 = newJObject()
  if body != nil:
    body_614897 = body
  result = call_614896.call(nil, nil, nil, nil, body_614897)

var startSession* = Call_StartSession_614883(name: "startSession",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.StartSession",
    validator: validate_StartSession_614884, base: "/", url: url_StartSession_614885,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopAutomationExecution_614898 = ref object of OpenApiRestCall_612658
proc url_StopAutomationExecution_614900(protocol: Scheme; host: string; base: string;
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

proc validate_StopAutomationExecution_614899(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Stop an Automation that is currently running.
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
  var valid_614901 = header.getOrDefault("X-Amz-Target")
  valid_614901 = validateParameter(valid_614901, JString, required = true, default = newJString(
      "AmazonSSM.StopAutomationExecution"))
  if valid_614901 != nil:
    section.add "X-Amz-Target", valid_614901
  var valid_614902 = header.getOrDefault("X-Amz-Signature")
  valid_614902 = validateParameter(valid_614902, JString, required = false,
                                 default = nil)
  if valid_614902 != nil:
    section.add "X-Amz-Signature", valid_614902
  var valid_614903 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614903 = validateParameter(valid_614903, JString, required = false,
                                 default = nil)
  if valid_614903 != nil:
    section.add "X-Amz-Content-Sha256", valid_614903
  var valid_614904 = header.getOrDefault("X-Amz-Date")
  valid_614904 = validateParameter(valid_614904, JString, required = false,
                                 default = nil)
  if valid_614904 != nil:
    section.add "X-Amz-Date", valid_614904
  var valid_614905 = header.getOrDefault("X-Amz-Credential")
  valid_614905 = validateParameter(valid_614905, JString, required = false,
                                 default = nil)
  if valid_614905 != nil:
    section.add "X-Amz-Credential", valid_614905
  var valid_614906 = header.getOrDefault("X-Amz-Security-Token")
  valid_614906 = validateParameter(valid_614906, JString, required = false,
                                 default = nil)
  if valid_614906 != nil:
    section.add "X-Amz-Security-Token", valid_614906
  var valid_614907 = header.getOrDefault("X-Amz-Algorithm")
  valid_614907 = validateParameter(valid_614907, JString, required = false,
                                 default = nil)
  if valid_614907 != nil:
    section.add "X-Amz-Algorithm", valid_614907
  var valid_614908 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614908 = validateParameter(valid_614908, JString, required = false,
                                 default = nil)
  if valid_614908 != nil:
    section.add "X-Amz-SignedHeaders", valid_614908
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614910: Call_StopAutomationExecution_614898; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stop an Automation that is currently running.
  ## 
  let valid = call_614910.validator(path, query, header, formData, body)
  let scheme = call_614910.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614910.url(scheme.get, call_614910.host, call_614910.base,
                         call_614910.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614910, url, valid)

proc call*(call_614911: Call_StopAutomationExecution_614898; body: JsonNode): Recallable =
  ## stopAutomationExecution
  ## Stop an Automation that is currently running.
  ##   body: JObject (required)
  var body_614912 = newJObject()
  if body != nil:
    body_614912 = body
  result = call_614911.call(nil, nil, nil, nil, body_614912)

var stopAutomationExecution* = Call_StopAutomationExecution_614898(
    name: "stopAutomationExecution", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.StopAutomationExecution",
    validator: validate_StopAutomationExecution_614899, base: "/",
    url: url_StopAutomationExecution_614900, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TerminateSession_614913 = ref object of OpenApiRestCall_612658
proc url_TerminateSession_614915(protocol: Scheme; host: string; base: string;
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

proc validate_TerminateSession_614914(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Permanently ends a session and closes the data connection between the Session Manager client and SSM Agent on the instance. A terminated session cannot be resumed.
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
  var valid_614916 = header.getOrDefault("X-Amz-Target")
  valid_614916 = validateParameter(valid_614916, JString, required = true, default = newJString(
      "AmazonSSM.TerminateSession"))
  if valid_614916 != nil:
    section.add "X-Amz-Target", valid_614916
  var valid_614917 = header.getOrDefault("X-Amz-Signature")
  valid_614917 = validateParameter(valid_614917, JString, required = false,
                                 default = nil)
  if valid_614917 != nil:
    section.add "X-Amz-Signature", valid_614917
  var valid_614918 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614918 = validateParameter(valid_614918, JString, required = false,
                                 default = nil)
  if valid_614918 != nil:
    section.add "X-Amz-Content-Sha256", valid_614918
  var valid_614919 = header.getOrDefault("X-Amz-Date")
  valid_614919 = validateParameter(valid_614919, JString, required = false,
                                 default = nil)
  if valid_614919 != nil:
    section.add "X-Amz-Date", valid_614919
  var valid_614920 = header.getOrDefault("X-Amz-Credential")
  valid_614920 = validateParameter(valid_614920, JString, required = false,
                                 default = nil)
  if valid_614920 != nil:
    section.add "X-Amz-Credential", valid_614920
  var valid_614921 = header.getOrDefault("X-Amz-Security-Token")
  valid_614921 = validateParameter(valid_614921, JString, required = false,
                                 default = nil)
  if valid_614921 != nil:
    section.add "X-Amz-Security-Token", valid_614921
  var valid_614922 = header.getOrDefault("X-Amz-Algorithm")
  valid_614922 = validateParameter(valid_614922, JString, required = false,
                                 default = nil)
  if valid_614922 != nil:
    section.add "X-Amz-Algorithm", valid_614922
  var valid_614923 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614923 = validateParameter(valid_614923, JString, required = false,
                                 default = nil)
  if valid_614923 != nil:
    section.add "X-Amz-SignedHeaders", valid_614923
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614925: Call_TerminateSession_614913; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently ends a session and closes the data connection between the Session Manager client and SSM Agent on the instance. A terminated session cannot be resumed.
  ## 
  let valid = call_614925.validator(path, query, header, formData, body)
  let scheme = call_614925.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614925.url(scheme.get, call_614925.host, call_614925.base,
                         call_614925.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614925, url, valid)

proc call*(call_614926: Call_TerminateSession_614913; body: JsonNode): Recallable =
  ## terminateSession
  ## Permanently ends a session and closes the data connection between the Session Manager client and SSM Agent on the instance. A terminated session cannot be resumed.
  ##   body: JObject (required)
  var body_614927 = newJObject()
  if body != nil:
    body_614927 = body
  result = call_614926.call(nil, nil, nil, nil, body_614927)

var terminateSession* = Call_TerminateSession_614913(name: "terminateSession",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.TerminateSession",
    validator: validate_TerminateSession_614914, base: "/",
    url: url_TerminateSession_614915, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAssociation_614928 = ref object of OpenApiRestCall_612658
proc url_UpdateAssociation_614930(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateAssociation_614929(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Updates an association. You can update the association name and version, the document version, schedule, parameters, and Amazon S3 output. </p> <p>In order to call this API action, your IAM user account, group, or role must be configured with permission to call the <a>DescribeAssociation</a> API action. If you don't have permission to call DescribeAssociation, then you receive the following error: <code>An error occurred (AccessDeniedException) when calling the UpdateAssociation operation: User: &lt;user_arn&gt; is not authorized to perform: ssm:DescribeAssociation on resource: &lt;resource_arn&gt;</code> </p> <important> <p>When you update an association, the association immediately runs against the specified targets.</p> </important>
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
  var valid_614931 = header.getOrDefault("X-Amz-Target")
  valid_614931 = validateParameter(valid_614931, JString, required = true, default = newJString(
      "AmazonSSM.UpdateAssociation"))
  if valid_614931 != nil:
    section.add "X-Amz-Target", valid_614931
  var valid_614932 = header.getOrDefault("X-Amz-Signature")
  valid_614932 = validateParameter(valid_614932, JString, required = false,
                                 default = nil)
  if valid_614932 != nil:
    section.add "X-Amz-Signature", valid_614932
  var valid_614933 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614933 = validateParameter(valid_614933, JString, required = false,
                                 default = nil)
  if valid_614933 != nil:
    section.add "X-Amz-Content-Sha256", valid_614933
  var valid_614934 = header.getOrDefault("X-Amz-Date")
  valid_614934 = validateParameter(valid_614934, JString, required = false,
                                 default = nil)
  if valid_614934 != nil:
    section.add "X-Amz-Date", valid_614934
  var valid_614935 = header.getOrDefault("X-Amz-Credential")
  valid_614935 = validateParameter(valid_614935, JString, required = false,
                                 default = nil)
  if valid_614935 != nil:
    section.add "X-Amz-Credential", valid_614935
  var valid_614936 = header.getOrDefault("X-Amz-Security-Token")
  valid_614936 = validateParameter(valid_614936, JString, required = false,
                                 default = nil)
  if valid_614936 != nil:
    section.add "X-Amz-Security-Token", valid_614936
  var valid_614937 = header.getOrDefault("X-Amz-Algorithm")
  valid_614937 = validateParameter(valid_614937, JString, required = false,
                                 default = nil)
  if valid_614937 != nil:
    section.add "X-Amz-Algorithm", valid_614937
  var valid_614938 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614938 = validateParameter(valid_614938, JString, required = false,
                                 default = nil)
  if valid_614938 != nil:
    section.add "X-Amz-SignedHeaders", valid_614938
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614940: Call_UpdateAssociation_614928; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an association. You can update the association name and version, the document version, schedule, parameters, and Amazon S3 output. </p> <p>In order to call this API action, your IAM user account, group, or role must be configured with permission to call the <a>DescribeAssociation</a> API action. If you don't have permission to call DescribeAssociation, then you receive the following error: <code>An error occurred (AccessDeniedException) when calling the UpdateAssociation operation: User: &lt;user_arn&gt; is not authorized to perform: ssm:DescribeAssociation on resource: &lt;resource_arn&gt;</code> </p> <important> <p>When you update an association, the association immediately runs against the specified targets.</p> </important>
  ## 
  let valid = call_614940.validator(path, query, header, formData, body)
  let scheme = call_614940.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614940.url(scheme.get, call_614940.host, call_614940.base,
                         call_614940.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614940, url, valid)

proc call*(call_614941: Call_UpdateAssociation_614928; body: JsonNode): Recallable =
  ## updateAssociation
  ## <p>Updates an association. You can update the association name and version, the document version, schedule, parameters, and Amazon S3 output. </p> <p>In order to call this API action, your IAM user account, group, or role must be configured with permission to call the <a>DescribeAssociation</a> API action. If you don't have permission to call DescribeAssociation, then you receive the following error: <code>An error occurred (AccessDeniedException) when calling the UpdateAssociation operation: User: &lt;user_arn&gt; is not authorized to perform: ssm:DescribeAssociation on resource: &lt;resource_arn&gt;</code> </p> <important> <p>When you update an association, the association immediately runs against the specified targets.</p> </important>
  ##   body: JObject (required)
  var body_614942 = newJObject()
  if body != nil:
    body_614942 = body
  result = call_614941.call(nil, nil, nil, nil, body_614942)

var updateAssociation* = Call_UpdateAssociation_614928(name: "updateAssociation",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateAssociation",
    validator: validate_UpdateAssociation_614929, base: "/",
    url: url_UpdateAssociation_614930, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAssociationStatus_614943 = ref object of OpenApiRestCall_612658
proc url_UpdateAssociationStatus_614945(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateAssociationStatus_614944(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the status of the Systems Manager document associated with the specified instance.
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
  var valid_614946 = header.getOrDefault("X-Amz-Target")
  valid_614946 = validateParameter(valid_614946, JString, required = true, default = newJString(
      "AmazonSSM.UpdateAssociationStatus"))
  if valid_614946 != nil:
    section.add "X-Amz-Target", valid_614946
  var valid_614947 = header.getOrDefault("X-Amz-Signature")
  valid_614947 = validateParameter(valid_614947, JString, required = false,
                                 default = nil)
  if valid_614947 != nil:
    section.add "X-Amz-Signature", valid_614947
  var valid_614948 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614948 = validateParameter(valid_614948, JString, required = false,
                                 default = nil)
  if valid_614948 != nil:
    section.add "X-Amz-Content-Sha256", valid_614948
  var valid_614949 = header.getOrDefault("X-Amz-Date")
  valid_614949 = validateParameter(valid_614949, JString, required = false,
                                 default = nil)
  if valid_614949 != nil:
    section.add "X-Amz-Date", valid_614949
  var valid_614950 = header.getOrDefault("X-Amz-Credential")
  valid_614950 = validateParameter(valid_614950, JString, required = false,
                                 default = nil)
  if valid_614950 != nil:
    section.add "X-Amz-Credential", valid_614950
  var valid_614951 = header.getOrDefault("X-Amz-Security-Token")
  valid_614951 = validateParameter(valid_614951, JString, required = false,
                                 default = nil)
  if valid_614951 != nil:
    section.add "X-Amz-Security-Token", valid_614951
  var valid_614952 = header.getOrDefault("X-Amz-Algorithm")
  valid_614952 = validateParameter(valid_614952, JString, required = false,
                                 default = nil)
  if valid_614952 != nil:
    section.add "X-Amz-Algorithm", valid_614952
  var valid_614953 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614953 = validateParameter(valid_614953, JString, required = false,
                                 default = nil)
  if valid_614953 != nil:
    section.add "X-Amz-SignedHeaders", valid_614953
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614955: Call_UpdateAssociationStatus_614943; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the status of the Systems Manager document associated with the specified instance.
  ## 
  let valid = call_614955.validator(path, query, header, formData, body)
  let scheme = call_614955.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614955.url(scheme.get, call_614955.host, call_614955.base,
                         call_614955.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614955, url, valid)

proc call*(call_614956: Call_UpdateAssociationStatus_614943; body: JsonNode): Recallable =
  ## updateAssociationStatus
  ## Updates the status of the Systems Manager document associated with the specified instance.
  ##   body: JObject (required)
  var body_614957 = newJObject()
  if body != nil:
    body_614957 = body
  result = call_614956.call(nil, nil, nil, nil, body_614957)

var updateAssociationStatus* = Call_UpdateAssociationStatus_614943(
    name: "updateAssociationStatus", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateAssociationStatus",
    validator: validate_UpdateAssociationStatus_614944, base: "/",
    url: url_UpdateAssociationStatus_614945, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocument_614958 = ref object of OpenApiRestCall_612658
proc url_UpdateDocument_614960(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDocument_614959(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Updates one or more values for an SSM document.
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
  var valid_614961 = header.getOrDefault("X-Amz-Target")
  valid_614961 = validateParameter(valid_614961, JString, required = true, default = newJString(
      "AmazonSSM.UpdateDocument"))
  if valid_614961 != nil:
    section.add "X-Amz-Target", valid_614961
  var valid_614962 = header.getOrDefault("X-Amz-Signature")
  valid_614962 = validateParameter(valid_614962, JString, required = false,
                                 default = nil)
  if valid_614962 != nil:
    section.add "X-Amz-Signature", valid_614962
  var valid_614963 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614963 = validateParameter(valid_614963, JString, required = false,
                                 default = nil)
  if valid_614963 != nil:
    section.add "X-Amz-Content-Sha256", valid_614963
  var valid_614964 = header.getOrDefault("X-Amz-Date")
  valid_614964 = validateParameter(valid_614964, JString, required = false,
                                 default = nil)
  if valid_614964 != nil:
    section.add "X-Amz-Date", valid_614964
  var valid_614965 = header.getOrDefault("X-Amz-Credential")
  valid_614965 = validateParameter(valid_614965, JString, required = false,
                                 default = nil)
  if valid_614965 != nil:
    section.add "X-Amz-Credential", valid_614965
  var valid_614966 = header.getOrDefault("X-Amz-Security-Token")
  valid_614966 = validateParameter(valid_614966, JString, required = false,
                                 default = nil)
  if valid_614966 != nil:
    section.add "X-Amz-Security-Token", valid_614966
  var valid_614967 = header.getOrDefault("X-Amz-Algorithm")
  valid_614967 = validateParameter(valid_614967, JString, required = false,
                                 default = nil)
  if valid_614967 != nil:
    section.add "X-Amz-Algorithm", valid_614967
  var valid_614968 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614968 = validateParameter(valid_614968, JString, required = false,
                                 default = nil)
  if valid_614968 != nil:
    section.add "X-Amz-SignedHeaders", valid_614968
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614970: Call_UpdateDocument_614958; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates one or more values for an SSM document.
  ## 
  let valid = call_614970.validator(path, query, header, formData, body)
  let scheme = call_614970.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614970.url(scheme.get, call_614970.host, call_614970.base,
                         call_614970.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614970, url, valid)

proc call*(call_614971: Call_UpdateDocument_614958; body: JsonNode): Recallable =
  ## updateDocument
  ## Updates one or more values for an SSM document.
  ##   body: JObject (required)
  var body_614972 = newJObject()
  if body != nil:
    body_614972 = body
  result = call_614971.call(nil, nil, nil, nil, body_614972)

var updateDocument* = Call_UpdateDocument_614958(name: "updateDocument",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateDocument",
    validator: validate_UpdateDocument_614959, base: "/", url: url_UpdateDocument_614960,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocumentDefaultVersion_614973 = ref object of OpenApiRestCall_612658
proc url_UpdateDocumentDefaultVersion_614975(protocol: Scheme; host: string;
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

proc validate_UpdateDocumentDefaultVersion_614974(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Set the default version of a document. 
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
  var valid_614976 = header.getOrDefault("X-Amz-Target")
  valid_614976 = validateParameter(valid_614976, JString, required = true, default = newJString(
      "AmazonSSM.UpdateDocumentDefaultVersion"))
  if valid_614976 != nil:
    section.add "X-Amz-Target", valid_614976
  var valid_614977 = header.getOrDefault("X-Amz-Signature")
  valid_614977 = validateParameter(valid_614977, JString, required = false,
                                 default = nil)
  if valid_614977 != nil:
    section.add "X-Amz-Signature", valid_614977
  var valid_614978 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614978 = validateParameter(valid_614978, JString, required = false,
                                 default = nil)
  if valid_614978 != nil:
    section.add "X-Amz-Content-Sha256", valid_614978
  var valid_614979 = header.getOrDefault("X-Amz-Date")
  valid_614979 = validateParameter(valid_614979, JString, required = false,
                                 default = nil)
  if valid_614979 != nil:
    section.add "X-Amz-Date", valid_614979
  var valid_614980 = header.getOrDefault("X-Amz-Credential")
  valid_614980 = validateParameter(valid_614980, JString, required = false,
                                 default = nil)
  if valid_614980 != nil:
    section.add "X-Amz-Credential", valid_614980
  var valid_614981 = header.getOrDefault("X-Amz-Security-Token")
  valid_614981 = validateParameter(valid_614981, JString, required = false,
                                 default = nil)
  if valid_614981 != nil:
    section.add "X-Amz-Security-Token", valid_614981
  var valid_614982 = header.getOrDefault("X-Amz-Algorithm")
  valid_614982 = validateParameter(valid_614982, JString, required = false,
                                 default = nil)
  if valid_614982 != nil:
    section.add "X-Amz-Algorithm", valid_614982
  var valid_614983 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614983 = validateParameter(valid_614983, JString, required = false,
                                 default = nil)
  if valid_614983 != nil:
    section.add "X-Amz-SignedHeaders", valid_614983
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614985: Call_UpdateDocumentDefaultVersion_614973; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Set the default version of a document. 
  ## 
  let valid = call_614985.validator(path, query, header, formData, body)
  let scheme = call_614985.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614985.url(scheme.get, call_614985.host, call_614985.base,
                         call_614985.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614985, url, valid)

proc call*(call_614986: Call_UpdateDocumentDefaultVersion_614973; body: JsonNode): Recallable =
  ## updateDocumentDefaultVersion
  ## Set the default version of a document. 
  ##   body: JObject (required)
  var body_614987 = newJObject()
  if body != nil:
    body_614987 = body
  result = call_614986.call(nil, nil, nil, nil, body_614987)

var updateDocumentDefaultVersion* = Call_UpdateDocumentDefaultVersion_614973(
    name: "updateDocumentDefaultVersion", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateDocumentDefaultVersion",
    validator: validate_UpdateDocumentDefaultVersion_614974, base: "/",
    url: url_UpdateDocumentDefaultVersion_614975,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMaintenanceWindow_614988 = ref object of OpenApiRestCall_612658
proc url_UpdateMaintenanceWindow_614990(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateMaintenanceWindow_614989(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates an existing maintenance window. Only specified parameters are modified.</p> <note> <p>The value you specify for <code>Duration</code> determines the specific end time for the maintenance window based on the time it begins. No maintenance window tasks are permitted to start after the resulting endtime minus the number of hours you specify for <code>Cutoff</code>. For example, if the maintenance window starts at 3 PM, the duration is three hours, and the value you specify for <code>Cutoff</code> is one hour, no maintenance window tasks can start after 5 PM.</p> </note>
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
  var valid_614991 = header.getOrDefault("X-Amz-Target")
  valid_614991 = validateParameter(valid_614991, JString, required = true, default = newJString(
      "AmazonSSM.UpdateMaintenanceWindow"))
  if valid_614991 != nil:
    section.add "X-Amz-Target", valid_614991
  var valid_614992 = header.getOrDefault("X-Amz-Signature")
  valid_614992 = validateParameter(valid_614992, JString, required = false,
                                 default = nil)
  if valid_614992 != nil:
    section.add "X-Amz-Signature", valid_614992
  var valid_614993 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614993 = validateParameter(valid_614993, JString, required = false,
                                 default = nil)
  if valid_614993 != nil:
    section.add "X-Amz-Content-Sha256", valid_614993
  var valid_614994 = header.getOrDefault("X-Amz-Date")
  valid_614994 = validateParameter(valid_614994, JString, required = false,
                                 default = nil)
  if valid_614994 != nil:
    section.add "X-Amz-Date", valid_614994
  var valid_614995 = header.getOrDefault("X-Amz-Credential")
  valid_614995 = validateParameter(valid_614995, JString, required = false,
                                 default = nil)
  if valid_614995 != nil:
    section.add "X-Amz-Credential", valid_614995
  var valid_614996 = header.getOrDefault("X-Amz-Security-Token")
  valid_614996 = validateParameter(valid_614996, JString, required = false,
                                 default = nil)
  if valid_614996 != nil:
    section.add "X-Amz-Security-Token", valid_614996
  var valid_614997 = header.getOrDefault("X-Amz-Algorithm")
  valid_614997 = validateParameter(valid_614997, JString, required = false,
                                 default = nil)
  if valid_614997 != nil:
    section.add "X-Amz-Algorithm", valid_614997
  var valid_614998 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614998 = validateParameter(valid_614998, JString, required = false,
                                 default = nil)
  if valid_614998 != nil:
    section.add "X-Amz-SignedHeaders", valid_614998
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_615000: Call_UpdateMaintenanceWindow_614988; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an existing maintenance window. Only specified parameters are modified.</p> <note> <p>The value you specify for <code>Duration</code> determines the specific end time for the maintenance window based on the time it begins. No maintenance window tasks are permitted to start after the resulting endtime minus the number of hours you specify for <code>Cutoff</code>. For example, if the maintenance window starts at 3 PM, the duration is three hours, and the value you specify for <code>Cutoff</code> is one hour, no maintenance window tasks can start after 5 PM.</p> </note>
  ## 
  let valid = call_615000.validator(path, query, header, formData, body)
  let scheme = call_615000.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615000.url(scheme.get, call_615000.host, call_615000.base,
                         call_615000.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615000, url, valid)

proc call*(call_615001: Call_UpdateMaintenanceWindow_614988; body: JsonNode): Recallable =
  ## updateMaintenanceWindow
  ## <p>Updates an existing maintenance window. Only specified parameters are modified.</p> <note> <p>The value you specify for <code>Duration</code> determines the specific end time for the maintenance window based on the time it begins. No maintenance window tasks are permitted to start after the resulting endtime minus the number of hours you specify for <code>Cutoff</code>. For example, if the maintenance window starts at 3 PM, the duration is three hours, and the value you specify for <code>Cutoff</code> is one hour, no maintenance window tasks can start after 5 PM.</p> </note>
  ##   body: JObject (required)
  var body_615002 = newJObject()
  if body != nil:
    body_615002 = body
  result = call_615001.call(nil, nil, nil, nil, body_615002)

var updateMaintenanceWindow* = Call_UpdateMaintenanceWindow_614988(
    name: "updateMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateMaintenanceWindow",
    validator: validate_UpdateMaintenanceWindow_614989, base: "/",
    url: url_UpdateMaintenanceWindow_614990, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMaintenanceWindowTarget_615003 = ref object of OpenApiRestCall_612658
proc url_UpdateMaintenanceWindowTarget_615005(protocol: Scheme; host: string;
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

proc validate_UpdateMaintenanceWindowTarget_615004(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Modifies the target of an existing maintenance window. You can change the following:</p> <ul> <li> <p>Name</p> </li> <li> <p>Description</p> </li> <li> <p>Owner</p> </li> <li> <p>IDs for an ID target</p> </li> <li> <p>Tags for a Tag target</p> </li> <li> <p>From any supported tag type to another. The three supported tag types are ID target, Tag target, and resource group. For more information, see <a>Target</a>.</p> </li> </ul> <note> <p>If a parameter is null, then the corresponding field is not modified.</p> </note>
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
  var valid_615006 = header.getOrDefault("X-Amz-Target")
  valid_615006 = validateParameter(valid_615006, JString, required = true, default = newJString(
      "AmazonSSM.UpdateMaintenanceWindowTarget"))
  if valid_615006 != nil:
    section.add "X-Amz-Target", valid_615006
  var valid_615007 = header.getOrDefault("X-Amz-Signature")
  valid_615007 = validateParameter(valid_615007, JString, required = false,
                                 default = nil)
  if valid_615007 != nil:
    section.add "X-Amz-Signature", valid_615007
  var valid_615008 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615008 = validateParameter(valid_615008, JString, required = false,
                                 default = nil)
  if valid_615008 != nil:
    section.add "X-Amz-Content-Sha256", valid_615008
  var valid_615009 = header.getOrDefault("X-Amz-Date")
  valid_615009 = validateParameter(valid_615009, JString, required = false,
                                 default = nil)
  if valid_615009 != nil:
    section.add "X-Amz-Date", valid_615009
  var valid_615010 = header.getOrDefault("X-Amz-Credential")
  valid_615010 = validateParameter(valid_615010, JString, required = false,
                                 default = nil)
  if valid_615010 != nil:
    section.add "X-Amz-Credential", valid_615010
  var valid_615011 = header.getOrDefault("X-Amz-Security-Token")
  valid_615011 = validateParameter(valid_615011, JString, required = false,
                                 default = nil)
  if valid_615011 != nil:
    section.add "X-Amz-Security-Token", valid_615011
  var valid_615012 = header.getOrDefault("X-Amz-Algorithm")
  valid_615012 = validateParameter(valid_615012, JString, required = false,
                                 default = nil)
  if valid_615012 != nil:
    section.add "X-Amz-Algorithm", valid_615012
  var valid_615013 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615013 = validateParameter(valid_615013, JString, required = false,
                                 default = nil)
  if valid_615013 != nil:
    section.add "X-Amz-SignedHeaders", valid_615013
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_615015: Call_UpdateMaintenanceWindowTarget_615003; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the target of an existing maintenance window. You can change the following:</p> <ul> <li> <p>Name</p> </li> <li> <p>Description</p> </li> <li> <p>Owner</p> </li> <li> <p>IDs for an ID target</p> </li> <li> <p>Tags for a Tag target</p> </li> <li> <p>From any supported tag type to another. The three supported tag types are ID target, Tag target, and resource group. For more information, see <a>Target</a>.</p> </li> </ul> <note> <p>If a parameter is null, then the corresponding field is not modified.</p> </note>
  ## 
  let valid = call_615015.validator(path, query, header, formData, body)
  let scheme = call_615015.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615015.url(scheme.get, call_615015.host, call_615015.base,
                         call_615015.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615015, url, valid)

proc call*(call_615016: Call_UpdateMaintenanceWindowTarget_615003; body: JsonNode): Recallable =
  ## updateMaintenanceWindowTarget
  ## <p>Modifies the target of an existing maintenance window. You can change the following:</p> <ul> <li> <p>Name</p> </li> <li> <p>Description</p> </li> <li> <p>Owner</p> </li> <li> <p>IDs for an ID target</p> </li> <li> <p>Tags for a Tag target</p> </li> <li> <p>From any supported tag type to another. The three supported tag types are ID target, Tag target, and resource group. For more information, see <a>Target</a>.</p> </li> </ul> <note> <p>If a parameter is null, then the corresponding field is not modified.</p> </note>
  ##   body: JObject (required)
  var body_615017 = newJObject()
  if body != nil:
    body_615017 = body
  result = call_615016.call(nil, nil, nil, nil, body_615017)

var updateMaintenanceWindowTarget* = Call_UpdateMaintenanceWindowTarget_615003(
    name: "updateMaintenanceWindowTarget", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateMaintenanceWindowTarget",
    validator: validate_UpdateMaintenanceWindowTarget_615004, base: "/",
    url: url_UpdateMaintenanceWindowTarget_615005,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMaintenanceWindowTask_615018 = ref object of OpenApiRestCall_612658
proc url_UpdateMaintenanceWindowTask_615020(protocol: Scheme; host: string;
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

proc validate_UpdateMaintenanceWindowTask_615019(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Modifies a task assigned to a maintenance window. You can't change the task type, but you can change the following values:</p> <ul> <li> <p>TaskARN. For example, you can change a RUN_COMMAND task from AWS-RunPowerShellScript to AWS-RunShellScript.</p> </li> <li> <p>ServiceRoleArn</p> </li> <li> <p>TaskInvocationParameters</p> </li> <li> <p>Priority</p> </li> <li> <p>MaxConcurrency</p> </li> <li> <p>MaxErrors</p> </li> </ul> <p>If a parameter is null, then the corresponding field is not modified. Also, if you set Replace to true, then all fields required by the <a>RegisterTaskWithMaintenanceWindow</a> action are required for this request. Optional fields that aren't specified are set to null.</p>
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
  var valid_615021 = header.getOrDefault("X-Amz-Target")
  valid_615021 = validateParameter(valid_615021, JString, required = true, default = newJString(
      "AmazonSSM.UpdateMaintenanceWindowTask"))
  if valid_615021 != nil:
    section.add "X-Amz-Target", valid_615021
  var valid_615022 = header.getOrDefault("X-Amz-Signature")
  valid_615022 = validateParameter(valid_615022, JString, required = false,
                                 default = nil)
  if valid_615022 != nil:
    section.add "X-Amz-Signature", valid_615022
  var valid_615023 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615023 = validateParameter(valid_615023, JString, required = false,
                                 default = nil)
  if valid_615023 != nil:
    section.add "X-Amz-Content-Sha256", valid_615023
  var valid_615024 = header.getOrDefault("X-Amz-Date")
  valid_615024 = validateParameter(valid_615024, JString, required = false,
                                 default = nil)
  if valid_615024 != nil:
    section.add "X-Amz-Date", valid_615024
  var valid_615025 = header.getOrDefault("X-Amz-Credential")
  valid_615025 = validateParameter(valid_615025, JString, required = false,
                                 default = nil)
  if valid_615025 != nil:
    section.add "X-Amz-Credential", valid_615025
  var valid_615026 = header.getOrDefault("X-Amz-Security-Token")
  valid_615026 = validateParameter(valid_615026, JString, required = false,
                                 default = nil)
  if valid_615026 != nil:
    section.add "X-Amz-Security-Token", valid_615026
  var valid_615027 = header.getOrDefault("X-Amz-Algorithm")
  valid_615027 = validateParameter(valid_615027, JString, required = false,
                                 default = nil)
  if valid_615027 != nil:
    section.add "X-Amz-Algorithm", valid_615027
  var valid_615028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615028 = validateParameter(valid_615028, JString, required = false,
                                 default = nil)
  if valid_615028 != nil:
    section.add "X-Amz-SignedHeaders", valid_615028
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_615030: Call_UpdateMaintenanceWindowTask_615018; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies a task assigned to a maintenance window. You can't change the task type, but you can change the following values:</p> <ul> <li> <p>TaskARN. For example, you can change a RUN_COMMAND task from AWS-RunPowerShellScript to AWS-RunShellScript.</p> </li> <li> <p>ServiceRoleArn</p> </li> <li> <p>TaskInvocationParameters</p> </li> <li> <p>Priority</p> </li> <li> <p>MaxConcurrency</p> </li> <li> <p>MaxErrors</p> </li> </ul> <p>If a parameter is null, then the corresponding field is not modified. Also, if you set Replace to true, then all fields required by the <a>RegisterTaskWithMaintenanceWindow</a> action are required for this request. Optional fields that aren't specified are set to null.</p>
  ## 
  let valid = call_615030.validator(path, query, header, formData, body)
  let scheme = call_615030.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615030.url(scheme.get, call_615030.host, call_615030.base,
                         call_615030.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615030, url, valid)

proc call*(call_615031: Call_UpdateMaintenanceWindowTask_615018; body: JsonNode): Recallable =
  ## updateMaintenanceWindowTask
  ## <p>Modifies a task assigned to a maintenance window. You can't change the task type, but you can change the following values:</p> <ul> <li> <p>TaskARN. For example, you can change a RUN_COMMAND task from AWS-RunPowerShellScript to AWS-RunShellScript.</p> </li> <li> <p>ServiceRoleArn</p> </li> <li> <p>TaskInvocationParameters</p> </li> <li> <p>Priority</p> </li> <li> <p>MaxConcurrency</p> </li> <li> <p>MaxErrors</p> </li> </ul> <p>If a parameter is null, then the corresponding field is not modified. Also, if you set Replace to true, then all fields required by the <a>RegisterTaskWithMaintenanceWindow</a> action are required for this request. Optional fields that aren't specified are set to null.</p>
  ##   body: JObject (required)
  var body_615032 = newJObject()
  if body != nil:
    body_615032 = body
  result = call_615031.call(nil, nil, nil, nil, body_615032)

var updateMaintenanceWindowTask* = Call_UpdateMaintenanceWindowTask_615018(
    name: "updateMaintenanceWindowTask", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateMaintenanceWindowTask",
    validator: validate_UpdateMaintenanceWindowTask_615019, base: "/",
    url: url_UpdateMaintenanceWindowTask_615020,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateManagedInstanceRole_615033 = ref object of OpenApiRestCall_612658
proc url_UpdateManagedInstanceRole_615035(protocol: Scheme; host: string;
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

proc validate_UpdateManagedInstanceRole_615034(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Assigns or changes an Amazon Identity and Access Management (IAM) role for the managed instance.
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
  var valid_615036 = header.getOrDefault("X-Amz-Target")
  valid_615036 = validateParameter(valid_615036, JString, required = true, default = newJString(
      "AmazonSSM.UpdateManagedInstanceRole"))
  if valid_615036 != nil:
    section.add "X-Amz-Target", valid_615036
  var valid_615037 = header.getOrDefault("X-Amz-Signature")
  valid_615037 = validateParameter(valid_615037, JString, required = false,
                                 default = nil)
  if valid_615037 != nil:
    section.add "X-Amz-Signature", valid_615037
  var valid_615038 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615038 = validateParameter(valid_615038, JString, required = false,
                                 default = nil)
  if valid_615038 != nil:
    section.add "X-Amz-Content-Sha256", valid_615038
  var valid_615039 = header.getOrDefault("X-Amz-Date")
  valid_615039 = validateParameter(valid_615039, JString, required = false,
                                 default = nil)
  if valid_615039 != nil:
    section.add "X-Amz-Date", valid_615039
  var valid_615040 = header.getOrDefault("X-Amz-Credential")
  valid_615040 = validateParameter(valid_615040, JString, required = false,
                                 default = nil)
  if valid_615040 != nil:
    section.add "X-Amz-Credential", valid_615040
  var valid_615041 = header.getOrDefault("X-Amz-Security-Token")
  valid_615041 = validateParameter(valid_615041, JString, required = false,
                                 default = nil)
  if valid_615041 != nil:
    section.add "X-Amz-Security-Token", valid_615041
  var valid_615042 = header.getOrDefault("X-Amz-Algorithm")
  valid_615042 = validateParameter(valid_615042, JString, required = false,
                                 default = nil)
  if valid_615042 != nil:
    section.add "X-Amz-Algorithm", valid_615042
  var valid_615043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615043 = validateParameter(valid_615043, JString, required = false,
                                 default = nil)
  if valid_615043 != nil:
    section.add "X-Amz-SignedHeaders", valid_615043
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_615045: Call_UpdateManagedInstanceRole_615033; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Assigns or changes an Amazon Identity and Access Management (IAM) role for the managed instance.
  ## 
  let valid = call_615045.validator(path, query, header, formData, body)
  let scheme = call_615045.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615045.url(scheme.get, call_615045.host, call_615045.base,
                         call_615045.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615045, url, valid)

proc call*(call_615046: Call_UpdateManagedInstanceRole_615033; body: JsonNode): Recallable =
  ## updateManagedInstanceRole
  ## Assigns or changes an Amazon Identity and Access Management (IAM) role for the managed instance.
  ##   body: JObject (required)
  var body_615047 = newJObject()
  if body != nil:
    body_615047 = body
  result = call_615046.call(nil, nil, nil, nil, body_615047)

var updateManagedInstanceRole* = Call_UpdateManagedInstanceRole_615033(
    name: "updateManagedInstanceRole", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateManagedInstanceRole",
    validator: validate_UpdateManagedInstanceRole_615034, base: "/",
    url: url_UpdateManagedInstanceRole_615035,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateOpsItem_615048 = ref object of OpenApiRestCall_612658
proc url_UpdateOpsItem_615050(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateOpsItem_615049(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Edit or change an OpsItem. You must have permission in AWS Identity and Access Management (IAM) to update an OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
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
  var valid_615051 = header.getOrDefault("X-Amz-Target")
  valid_615051 = validateParameter(valid_615051, JString, required = true, default = newJString(
      "AmazonSSM.UpdateOpsItem"))
  if valid_615051 != nil:
    section.add "X-Amz-Target", valid_615051
  var valid_615052 = header.getOrDefault("X-Amz-Signature")
  valid_615052 = validateParameter(valid_615052, JString, required = false,
                                 default = nil)
  if valid_615052 != nil:
    section.add "X-Amz-Signature", valid_615052
  var valid_615053 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615053 = validateParameter(valid_615053, JString, required = false,
                                 default = nil)
  if valid_615053 != nil:
    section.add "X-Amz-Content-Sha256", valid_615053
  var valid_615054 = header.getOrDefault("X-Amz-Date")
  valid_615054 = validateParameter(valid_615054, JString, required = false,
                                 default = nil)
  if valid_615054 != nil:
    section.add "X-Amz-Date", valid_615054
  var valid_615055 = header.getOrDefault("X-Amz-Credential")
  valid_615055 = validateParameter(valid_615055, JString, required = false,
                                 default = nil)
  if valid_615055 != nil:
    section.add "X-Amz-Credential", valid_615055
  var valid_615056 = header.getOrDefault("X-Amz-Security-Token")
  valid_615056 = validateParameter(valid_615056, JString, required = false,
                                 default = nil)
  if valid_615056 != nil:
    section.add "X-Amz-Security-Token", valid_615056
  var valid_615057 = header.getOrDefault("X-Amz-Algorithm")
  valid_615057 = validateParameter(valid_615057, JString, required = false,
                                 default = nil)
  if valid_615057 != nil:
    section.add "X-Amz-Algorithm", valid_615057
  var valid_615058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615058 = validateParameter(valid_615058, JString, required = false,
                                 default = nil)
  if valid_615058 != nil:
    section.add "X-Amz-SignedHeaders", valid_615058
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_615060: Call_UpdateOpsItem_615048; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Edit or change an OpsItem. You must have permission in AWS Identity and Access Management (IAM) to update an OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ## 
  let valid = call_615060.validator(path, query, header, formData, body)
  let scheme = call_615060.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615060.url(scheme.get, call_615060.host, call_615060.base,
                         call_615060.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615060, url, valid)

proc call*(call_615061: Call_UpdateOpsItem_615048; body: JsonNode): Recallable =
  ## updateOpsItem
  ## <p>Edit or change an OpsItem. You must have permission in AWS Identity and Access Management (IAM) to update an OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ##   body: JObject (required)
  var body_615062 = newJObject()
  if body != nil:
    body_615062 = body
  result = call_615061.call(nil, nil, nil, nil, body_615062)

var updateOpsItem* = Call_UpdateOpsItem_615048(name: "updateOpsItem",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateOpsItem",
    validator: validate_UpdateOpsItem_615049, base: "/", url: url_UpdateOpsItem_615050,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePatchBaseline_615063 = ref object of OpenApiRestCall_612658
proc url_UpdatePatchBaseline_615065(protocol: Scheme; host: string; base: string;
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

proc validate_UpdatePatchBaseline_615064(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Modifies an existing patch baseline. Fields not specified in the request are left unchanged.</p> <note> <p>For information about valid key and value pairs in <code>PatchFilters</code> for each supported operating system type, see <a href="http://docs.aws.amazon.com/systems-manager/latest/APIReference/API_PatchFilter.html">PatchFilter</a>.</p> </note>
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
  var valid_615066 = header.getOrDefault("X-Amz-Target")
  valid_615066 = validateParameter(valid_615066, JString, required = true, default = newJString(
      "AmazonSSM.UpdatePatchBaseline"))
  if valid_615066 != nil:
    section.add "X-Amz-Target", valid_615066
  var valid_615067 = header.getOrDefault("X-Amz-Signature")
  valid_615067 = validateParameter(valid_615067, JString, required = false,
                                 default = nil)
  if valid_615067 != nil:
    section.add "X-Amz-Signature", valid_615067
  var valid_615068 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615068 = validateParameter(valid_615068, JString, required = false,
                                 default = nil)
  if valid_615068 != nil:
    section.add "X-Amz-Content-Sha256", valid_615068
  var valid_615069 = header.getOrDefault("X-Amz-Date")
  valid_615069 = validateParameter(valid_615069, JString, required = false,
                                 default = nil)
  if valid_615069 != nil:
    section.add "X-Amz-Date", valid_615069
  var valid_615070 = header.getOrDefault("X-Amz-Credential")
  valid_615070 = validateParameter(valid_615070, JString, required = false,
                                 default = nil)
  if valid_615070 != nil:
    section.add "X-Amz-Credential", valid_615070
  var valid_615071 = header.getOrDefault("X-Amz-Security-Token")
  valid_615071 = validateParameter(valid_615071, JString, required = false,
                                 default = nil)
  if valid_615071 != nil:
    section.add "X-Amz-Security-Token", valid_615071
  var valid_615072 = header.getOrDefault("X-Amz-Algorithm")
  valid_615072 = validateParameter(valid_615072, JString, required = false,
                                 default = nil)
  if valid_615072 != nil:
    section.add "X-Amz-Algorithm", valid_615072
  var valid_615073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615073 = validateParameter(valid_615073, JString, required = false,
                                 default = nil)
  if valid_615073 != nil:
    section.add "X-Amz-SignedHeaders", valid_615073
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_615075: Call_UpdatePatchBaseline_615063; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies an existing patch baseline. Fields not specified in the request are left unchanged.</p> <note> <p>For information about valid key and value pairs in <code>PatchFilters</code> for each supported operating system type, see <a href="http://docs.aws.amazon.com/systems-manager/latest/APIReference/API_PatchFilter.html">PatchFilter</a>.</p> </note>
  ## 
  let valid = call_615075.validator(path, query, header, formData, body)
  let scheme = call_615075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615075.url(scheme.get, call_615075.host, call_615075.base,
                         call_615075.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615075, url, valid)

proc call*(call_615076: Call_UpdatePatchBaseline_615063; body: JsonNode): Recallable =
  ## updatePatchBaseline
  ## <p>Modifies an existing patch baseline. Fields not specified in the request are left unchanged.</p> <note> <p>For information about valid key and value pairs in <code>PatchFilters</code> for each supported operating system type, see <a href="http://docs.aws.amazon.com/systems-manager/latest/APIReference/API_PatchFilter.html">PatchFilter</a>.</p> </note>
  ##   body: JObject (required)
  var body_615077 = newJObject()
  if body != nil:
    body_615077 = body
  result = call_615076.call(nil, nil, nil, nil, body_615077)

var updatePatchBaseline* = Call_UpdatePatchBaseline_615063(
    name: "updatePatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdatePatchBaseline",
    validator: validate_UpdatePatchBaseline_615064, base: "/",
    url: url_UpdatePatchBaseline_615065, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResourceDataSync_615078 = ref object of OpenApiRestCall_612658
proc url_UpdateResourceDataSync_615080(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateResourceDataSync_615079(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Update a resource data sync. After you create a resource data sync for a Region, you can't change the account options for that sync. For example, if you create a sync in the us-east-2 (Ohio) Region and you choose the Include only the current account option, you can't edit that sync later and choose the Include all accounts from my AWS Organizations configuration option. Instead, you must delete the first resource data sync, and create a new one.
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
  var valid_615081 = header.getOrDefault("X-Amz-Target")
  valid_615081 = validateParameter(valid_615081, JString, required = true, default = newJString(
      "AmazonSSM.UpdateResourceDataSync"))
  if valid_615081 != nil:
    section.add "X-Amz-Target", valid_615081
  var valid_615082 = header.getOrDefault("X-Amz-Signature")
  valid_615082 = validateParameter(valid_615082, JString, required = false,
                                 default = nil)
  if valid_615082 != nil:
    section.add "X-Amz-Signature", valid_615082
  var valid_615083 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615083 = validateParameter(valid_615083, JString, required = false,
                                 default = nil)
  if valid_615083 != nil:
    section.add "X-Amz-Content-Sha256", valid_615083
  var valid_615084 = header.getOrDefault("X-Amz-Date")
  valid_615084 = validateParameter(valid_615084, JString, required = false,
                                 default = nil)
  if valid_615084 != nil:
    section.add "X-Amz-Date", valid_615084
  var valid_615085 = header.getOrDefault("X-Amz-Credential")
  valid_615085 = validateParameter(valid_615085, JString, required = false,
                                 default = nil)
  if valid_615085 != nil:
    section.add "X-Amz-Credential", valid_615085
  var valid_615086 = header.getOrDefault("X-Amz-Security-Token")
  valid_615086 = validateParameter(valid_615086, JString, required = false,
                                 default = nil)
  if valid_615086 != nil:
    section.add "X-Amz-Security-Token", valid_615086
  var valid_615087 = header.getOrDefault("X-Amz-Algorithm")
  valid_615087 = validateParameter(valid_615087, JString, required = false,
                                 default = nil)
  if valid_615087 != nil:
    section.add "X-Amz-Algorithm", valid_615087
  var valid_615088 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615088 = validateParameter(valid_615088, JString, required = false,
                                 default = nil)
  if valid_615088 != nil:
    section.add "X-Amz-SignedHeaders", valid_615088
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_615090: Call_UpdateResourceDataSync_615078; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Update a resource data sync. After you create a resource data sync for a Region, you can't change the account options for that sync. For example, if you create a sync in the us-east-2 (Ohio) Region and you choose the Include only the current account option, you can't edit that sync later and choose the Include all accounts from my AWS Organizations configuration option. Instead, you must delete the first resource data sync, and create a new one.
  ## 
  let valid = call_615090.validator(path, query, header, formData, body)
  let scheme = call_615090.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615090.url(scheme.get, call_615090.host, call_615090.base,
                         call_615090.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615090, url, valid)

proc call*(call_615091: Call_UpdateResourceDataSync_615078; body: JsonNode): Recallable =
  ## updateResourceDataSync
  ## Update a resource data sync. After you create a resource data sync for a Region, you can't change the account options for that sync. For example, if you create a sync in the us-east-2 (Ohio) Region and you choose the Include only the current account option, you can't edit that sync later and choose the Include all accounts from my AWS Organizations configuration option. Instead, you must delete the first resource data sync, and create a new one.
  ##   body: JObject (required)
  var body_615092 = newJObject()
  if body != nil:
    body_615092 = body
  result = call_615091.call(nil, nil, nil, nil, body_615092)

var updateResourceDataSync* = Call_UpdateResourceDataSync_615078(
    name: "updateResourceDataSync", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateResourceDataSync",
    validator: validate_UpdateResourceDataSync_615079, base: "/",
    url: url_UpdateResourceDataSync_615080, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateServiceSetting_615093 = ref object of OpenApiRestCall_612658
proc url_UpdateServiceSetting_615095(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateServiceSetting_615094(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>GetServiceSetting</a> API action to view the current value. Or, use the <a>ResetServiceSetting</a> to change the value back to the original value defined by the AWS service team.</p> <p>Update the service setting for the account. </p>
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
  var valid_615096 = header.getOrDefault("X-Amz-Target")
  valid_615096 = validateParameter(valid_615096, JString, required = true, default = newJString(
      "AmazonSSM.UpdateServiceSetting"))
  if valid_615096 != nil:
    section.add "X-Amz-Target", valid_615096
  var valid_615097 = header.getOrDefault("X-Amz-Signature")
  valid_615097 = validateParameter(valid_615097, JString, required = false,
                                 default = nil)
  if valid_615097 != nil:
    section.add "X-Amz-Signature", valid_615097
  var valid_615098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615098 = validateParameter(valid_615098, JString, required = false,
                                 default = nil)
  if valid_615098 != nil:
    section.add "X-Amz-Content-Sha256", valid_615098
  var valid_615099 = header.getOrDefault("X-Amz-Date")
  valid_615099 = validateParameter(valid_615099, JString, required = false,
                                 default = nil)
  if valid_615099 != nil:
    section.add "X-Amz-Date", valid_615099
  var valid_615100 = header.getOrDefault("X-Amz-Credential")
  valid_615100 = validateParameter(valid_615100, JString, required = false,
                                 default = nil)
  if valid_615100 != nil:
    section.add "X-Amz-Credential", valid_615100
  var valid_615101 = header.getOrDefault("X-Amz-Security-Token")
  valid_615101 = validateParameter(valid_615101, JString, required = false,
                                 default = nil)
  if valid_615101 != nil:
    section.add "X-Amz-Security-Token", valid_615101
  var valid_615102 = header.getOrDefault("X-Amz-Algorithm")
  valid_615102 = validateParameter(valid_615102, JString, required = false,
                                 default = nil)
  if valid_615102 != nil:
    section.add "X-Amz-Algorithm", valid_615102
  var valid_615103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615103 = validateParameter(valid_615103, JString, required = false,
                                 default = nil)
  if valid_615103 != nil:
    section.add "X-Amz-SignedHeaders", valid_615103
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_615105: Call_UpdateServiceSetting_615093; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>GetServiceSetting</a> API action to view the current value. Or, use the <a>ResetServiceSetting</a> to change the value back to the original value defined by the AWS service team.</p> <p>Update the service setting for the account. </p>
  ## 
  let valid = call_615105.validator(path, query, header, formData, body)
  let scheme = call_615105.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615105.url(scheme.get, call_615105.host, call_615105.base,
                         call_615105.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615105, url, valid)

proc call*(call_615106: Call_UpdateServiceSetting_615093; body: JsonNode): Recallable =
  ## updateServiceSetting
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>GetServiceSetting</a> API action to view the current value. Or, use the <a>ResetServiceSetting</a> to change the value back to the original value defined by the AWS service team.</p> <p>Update the service setting for the account. </p>
  ##   body: JObject (required)
  var body_615107 = newJObject()
  if body != nil:
    body_615107 = body
  result = call_615106.call(nil, nil, nil, nil, body_615107)

var updateServiceSetting* = Call_UpdateServiceSetting_615093(
    name: "updateServiceSetting", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateServiceSetting",
    validator: validate_UpdateServiceSetting_615094, base: "/",
    url: url_UpdateServiceSetting_615095, schemes: {Scheme.Https, Scheme.Http})
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
