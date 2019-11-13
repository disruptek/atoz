
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

  OpenApiRestCall_593389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593389): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AddTagsToResource_593727 = ref object of OpenApiRestCall_593389
proc url_AddTagsToResource_593729(protocol: Scheme; host: string; base: string;
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

proc validate_AddTagsToResource_593728(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593854 = header.getOrDefault("X-Amz-Target")
  valid_593854 = validateParameter(valid_593854, JString, required = true, default = newJString(
      "AmazonSSM.AddTagsToResource"))
  if valid_593854 != nil:
    section.add "X-Amz-Target", valid_593854
  var valid_593855 = header.getOrDefault("X-Amz-Signature")
  valid_593855 = validateParameter(valid_593855, JString, required = false,
                                 default = nil)
  if valid_593855 != nil:
    section.add "X-Amz-Signature", valid_593855
  var valid_593856 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593856 = validateParameter(valid_593856, JString, required = false,
                                 default = nil)
  if valid_593856 != nil:
    section.add "X-Amz-Content-Sha256", valid_593856
  var valid_593857 = header.getOrDefault("X-Amz-Date")
  valid_593857 = validateParameter(valid_593857, JString, required = false,
                                 default = nil)
  if valid_593857 != nil:
    section.add "X-Amz-Date", valid_593857
  var valid_593858 = header.getOrDefault("X-Amz-Credential")
  valid_593858 = validateParameter(valid_593858, JString, required = false,
                                 default = nil)
  if valid_593858 != nil:
    section.add "X-Amz-Credential", valid_593858
  var valid_593859 = header.getOrDefault("X-Amz-Security-Token")
  valid_593859 = validateParameter(valid_593859, JString, required = false,
                                 default = nil)
  if valid_593859 != nil:
    section.add "X-Amz-Security-Token", valid_593859
  var valid_593860 = header.getOrDefault("X-Amz-Algorithm")
  valid_593860 = validateParameter(valid_593860, JString, required = false,
                                 default = nil)
  if valid_593860 != nil:
    section.add "X-Amz-Algorithm", valid_593860
  var valid_593861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593861 = validateParameter(valid_593861, JString, required = false,
                                 default = nil)
  if valid_593861 != nil:
    section.add "X-Amz-SignedHeaders", valid_593861
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593885: Call_AddTagsToResource_593727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds or overwrites one or more tags for the specified resource. Tags are metadata that you can assign to your documents, managed instances, maintenance windows, Parameter Store parameters, and patch baselines. Tags enable you to categorize your resources in different ways, for example, by purpose, owner, or environment. Each tag consists of a key and an optional value, both of which you define. For example, you could define a set of tags for your account's managed instances that helps you track each instance's owner and stack level. For example: Key=Owner and Value=DbAdmin, SysAdmin, or Dev. Or Key=Stack and Value=Production, Pre-Production, or Test.</p> <p>Each resource can have a maximum of 50 tags. </p> <p>We recommend that you devise a set of tag keys that meets your needs for each resource type. Using a consistent set of tag keys makes it easier for you to manage your resources. You can search and filter the resources based on the tags you add. Tags don't have any semantic meaning to Amazon EC2 and are interpreted strictly as a string of characters. </p> <p>For more information about tags, see <a href="http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Using_Tags.html">Tagging Your Amazon EC2 Resources</a> in the <i>Amazon EC2 User Guide</i>.</p>
  ## 
  let valid = call_593885.validator(path, query, header, formData, body)
  let scheme = call_593885.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593885.url(scheme.get, call_593885.host, call_593885.base,
                         call_593885.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593885, url, valid)

proc call*(call_593956: Call_AddTagsToResource_593727; body: JsonNode): Recallable =
  ## addTagsToResource
  ## <p>Adds or overwrites one or more tags for the specified resource. Tags are metadata that you can assign to your documents, managed instances, maintenance windows, Parameter Store parameters, and patch baselines. Tags enable you to categorize your resources in different ways, for example, by purpose, owner, or environment. Each tag consists of a key and an optional value, both of which you define. For example, you could define a set of tags for your account's managed instances that helps you track each instance's owner and stack level. For example: Key=Owner and Value=DbAdmin, SysAdmin, or Dev. Or Key=Stack and Value=Production, Pre-Production, or Test.</p> <p>Each resource can have a maximum of 50 tags. </p> <p>We recommend that you devise a set of tag keys that meets your needs for each resource type. Using a consistent set of tag keys makes it easier for you to manage your resources. You can search and filter the resources based on the tags you add. Tags don't have any semantic meaning to Amazon EC2 and are interpreted strictly as a string of characters. </p> <p>For more information about tags, see <a href="http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Using_Tags.html">Tagging Your Amazon EC2 Resources</a> in the <i>Amazon EC2 User Guide</i>.</p>
  ##   body: JObject (required)
  var body_593957 = newJObject()
  if body != nil:
    body_593957 = body
  result = call_593956.call(nil, nil, nil, nil, body_593957)

var addTagsToResource* = Call_AddTagsToResource_593727(name: "addTagsToResource",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.AddTagsToResource",
    validator: validate_AddTagsToResource_593728, base: "/",
    url: url_AddTagsToResource_593729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelCommand_593996 = ref object of OpenApiRestCall_593389
proc url_CancelCommand_593998(protocol: Scheme; host: string; base: string;
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

proc validate_CancelCommand_593997(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593999 = header.getOrDefault("X-Amz-Target")
  valid_593999 = validateParameter(valid_593999, JString, required = true, default = newJString(
      "AmazonSSM.CancelCommand"))
  if valid_593999 != nil:
    section.add "X-Amz-Target", valid_593999
  var valid_594000 = header.getOrDefault("X-Amz-Signature")
  valid_594000 = validateParameter(valid_594000, JString, required = false,
                                 default = nil)
  if valid_594000 != nil:
    section.add "X-Amz-Signature", valid_594000
  var valid_594001 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594001 = validateParameter(valid_594001, JString, required = false,
                                 default = nil)
  if valid_594001 != nil:
    section.add "X-Amz-Content-Sha256", valid_594001
  var valid_594002 = header.getOrDefault("X-Amz-Date")
  valid_594002 = validateParameter(valid_594002, JString, required = false,
                                 default = nil)
  if valid_594002 != nil:
    section.add "X-Amz-Date", valid_594002
  var valid_594003 = header.getOrDefault("X-Amz-Credential")
  valid_594003 = validateParameter(valid_594003, JString, required = false,
                                 default = nil)
  if valid_594003 != nil:
    section.add "X-Amz-Credential", valid_594003
  var valid_594004 = header.getOrDefault("X-Amz-Security-Token")
  valid_594004 = validateParameter(valid_594004, JString, required = false,
                                 default = nil)
  if valid_594004 != nil:
    section.add "X-Amz-Security-Token", valid_594004
  var valid_594005 = header.getOrDefault("X-Amz-Algorithm")
  valid_594005 = validateParameter(valid_594005, JString, required = false,
                                 default = nil)
  if valid_594005 != nil:
    section.add "X-Amz-Algorithm", valid_594005
  var valid_594006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594006 = validateParameter(valid_594006, JString, required = false,
                                 default = nil)
  if valid_594006 != nil:
    section.add "X-Amz-SignedHeaders", valid_594006
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594008: Call_CancelCommand_593996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attempts to cancel the command specified by the Command ID. There is no guarantee that the command will be terminated and the underlying process stopped.
  ## 
  let valid = call_594008.validator(path, query, header, formData, body)
  let scheme = call_594008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594008.url(scheme.get, call_594008.host, call_594008.base,
                         call_594008.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594008, url, valid)

proc call*(call_594009: Call_CancelCommand_593996; body: JsonNode): Recallable =
  ## cancelCommand
  ## Attempts to cancel the command specified by the Command ID. There is no guarantee that the command will be terminated and the underlying process stopped.
  ##   body: JObject (required)
  var body_594010 = newJObject()
  if body != nil:
    body_594010 = body
  result = call_594009.call(nil, nil, nil, nil, body_594010)

var cancelCommand* = Call_CancelCommand_593996(name: "cancelCommand",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CancelCommand",
    validator: validate_CancelCommand_593997, base: "/", url: url_CancelCommand_593998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelMaintenanceWindowExecution_594011 = ref object of OpenApiRestCall_593389
proc url_CancelMaintenanceWindowExecution_594013(protocol: Scheme; host: string;
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

proc validate_CancelMaintenanceWindowExecution_594012(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594014 = header.getOrDefault("X-Amz-Target")
  valid_594014 = validateParameter(valid_594014, JString, required = true, default = newJString(
      "AmazonSSM.CancelMaintenanceWindowExecution"))
  if valid_594014 != nil:
    section.add "X-Amz-Target", valid_594014
  var valid_594015 = header.getOrDefault("X-Amz-Signature")
  valid_594015 = validateParameter(valid_594015, JString, required = false,
                                 default = nil)
  if valid_594015 != nil:
    section.add "X-Amz-Signature", valid_594015
  var valid_594016 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594016 = validateParameter(valid_594016, JString, required = false,
                                 default = nil)
  if valid_594016 != nil:
    section.add "X-Amz-Content-Sha256", valid_594016
  var valid_594017 = header.getOrDefault("X-Amz-Date")
  valid_594017 = validateParameter(valid_594017, JString, required = false,
                                 default = nil)
  if valid_594017 != nil:
    section.add "X-Amz-Date", valid_594017
  var valid_594018 = header.getOrDefault("X-Amz-Credential")
  valid_594018 = validateParameter(valid_594018, JString, required = false,
                                 default = nil)
  if valid_594018 != nil:
    section.add "X-Amz-Credential", valid_594018
  var valid_594019 = header.getOrDefault("X-Amz-Security-Token")
  valid_594019 = validateParameter(valid_594019, JString, required = false,
                                 default = nil)
  if valid_594019 != nil:
    section.add "X-Amz-Security-Token", valid_594019
  var valid_594020 = header.getOrDefault("X-Amz-Algorithm")
  valid_594020 = validateParameter(valid_594020, JString, required = false,
                                 default = nil)
  if valid_594020 != nil:
    section.add "X-Amz-Algorithm", valid_594020
  var valid_594021 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594021 = validateParameter(valid_594021, JString, required = false,
                                 default = nil)
  if valid_594021 != nil:
    section.add "X-Amz-SignedHeaders", valid_594021
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594023: Call_CancelMaintenanceWindowExecution_594011;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Stops a maintenance window execution that is already in progress and cancels any tasks in the window that have not already starting running. (Tasks already in progress will continue to completion.)
  ## 
  let valid = call_594023.validator(path, query, header, formData, body)
  let scheme = call_594023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594023.url(scheme.get, call_594023.host, call_594023.base,
                         call_594023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594023, url, valid)

proc call*(call_594024: Call_CancelMaintenanceWindowExecution_594011;
          body: JsonNode): Recallable =
  ## cancelMaintenanceWindowExecution
  ## Stops a maintenance window execution that is already in progress and cancels any tasks in the window that have not already starting running. (Tasks already in progress will continue to completion.)
  ##   body: JObject (required)
  var body_594025 = newJObject()
  if body != nil:
    body_594025 = body
  result = call_594024.call(nil, nil, nil, nil, body_594025)

var cancelMaintenanceWindowExecution* = Call_CancelMaintenanceWindowExecution_594011(
    name: "cancelMaintenanceWindowExecution", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CancelMaintenanceWindowExecution",
    validator: validate_CancelMaintenanceWindowExecution_594012, base: "/",
    url: url_CancelMaintenanceWindowExecution_594013,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateActivation_594026 = ref object of OpenApiRestCall_593389
proc url_CreateActivation_594028(protocol: Scheme; host: string; base: string;
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

proc validate_CreateActivation_594027(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Registers your on-premises server or virtual machine with Amazon EC2 so that you can manage these resources using Run Command. An on-premises server or virtual machine that has been registered with EC2 is called a managed instance. For more information about activations, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-managedinstances.html">Setting Up AWS Systems Manager for Hybrid Environments</a>.
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594029 = header.getOrDefault("X-Amz-Target")
  valid_594029 = validateParameter(valid_594029, JString, required = true, default = newJString(
      "AmazonSSM.CreateActivation"))
  if valid_594029 != nil:
    section.add "X-Amz-Target", valid_594029
  var valid_594030 = header.getOrDefault("X-Amz-Signature")
  valid_594030 = validateParameter(valid_594030, JString, required = false,
                                 default = nil)
  if valid_594030 != nil:
    section.add "X-Amz-Signature", valid_594030
  var valid_594031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594031 = validateParameter(valid_594031, JString, required = false,
                                 default = nil)
  if valid_594031 != nil:
    section.add "X-Amz-Content-Sha256", valid_594031
  var valid_594032 = header.getOrDefault("X-Amz-Date")
  valid_594032 = validateParameter(valid_594032, JString, required = false,
                                 default = nil)
  if valid_594032 != nil:
    section.add "X-Amz-Date", valid_594032
  var valid_594033 = header.getOrDefault("X-Amz-Credential")
  valid_594033 = validateParameter(valid_594033, JString, required = false,
                                 default = nil)
  if valid_594033 != nil:
    section.add "X-Amz-Credential", valid_594033
  var valid_594034 = header.getOrDefault("X-Amz-Security-Token")
  valid_594034 = validateParameter(valid_594034, JString, required = false,
                                 default = nil)
  if valid_594034 != nil:
    section.add "X-Amz-Security-Token", valid_594034
  var valid_594035 = header.getOrDefault("X-Amz-Algorithm")
  valid_594035 = validateParameter(valid_594035, JString, required = false,
                                 default = nil)
  if valid_594035 != nil:
    section.add "X-Amz-Algorithm", valid_594035
  var valid_594036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594036 = validateParameter(valid_594036, JString, required = false,
                                 default = nil)
  if valid_594036 != nil:
    section.add "X-Amz-SignedHeaders", valid_594036
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594038: Call_CreateActivation_594026; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Registers your on-premises server or virtual machine with Amazon EC2 so that you can manage these resources using Run Command. An on-premises server or virtual machine that has been registered with EC2 is called a managed instance. For more information about activations, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-managedinstances.html">Setting Up AWS Systems Manager for Hybrid Environments</a>.
  ## 
  let valid = call_594038.validator(path, query, header, formData, body)
  let scheme = call_594038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594038.url(scheme.get, call_594038.host, call_594038.base,
                         call_594038.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594038, url, valid)

proc call*(call_594039: Call_CreateActivation_594026; body: JsonNode): Recallable =
  ## createActivation
  ## Registers your on-premises server or virtual machine with Amazon EC2 so that you can manage these resources using Run Command. An on-premises server or virtual machine that has been registered with EC2 is called a managed instance. For more information about activations, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-managedinstances.html">Setting Up AWS Systems Manager for Hybrid Environments</a>.
  ##   body: JObject (required)
  var body_594040 = newJObject()
  if body != nil:
    body_594040 = body
  result = call_594039.call(nil, nil, nil, nil, body_594040)

var createActivation* = Call_CreateActivation_594026(name: "createActivation",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateActivation",
    validator: validate_CreateActivation_594027, base: "/",
    url: url_CreateActivation_594028, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAssociation_594041 = ref object of OpenApiRestCall_593389
proc url_CreateAssociation_594043(protocol: Scheme; host: string; base: string;
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

proc validate_CreateAssociation_594042(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594044 = header.getOrDefault("X-Amz-Target")
  valid_594044 = validateParameter(valid_594044, JString, required = true, default = newJString(
      "AmazonSSM.CreateAssociation"))
  if valid_594044 != nil:
    section.add "X-Amz-Target", valid_594044
  var valid_594045 = header.getOrDefault("X-Amz-Signature")
  valid_594045 = validateParameter(valid_594045, JString, required = false,
                                 default = nil)
  if valid_594045 != nil:
    section.add "X-Amz-Signature", valid_594045
  var valid_594046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594046 = validateParameter(valid_594046, JString, required = false,
                                 default = nil)
  if valid_594046 != nil:
    section.add "X-Amz-Content-Sha256", valid_594046
  var valid_594047 = header.getOrDefault("X-Amz-Date")
  valid_594047 = validateParameter(valid_594047, JString, required = false,
                                 default = nil)
  if valid_594047 != nil:
    section.add "X-Amz-Date", valid_594047
  var valid_594048 = header.getOrDefault("X-Amz-Credential")
  valid_594048 = validateParameter(valid_594048, JString, required = false,
                                 default = nil)
  if valid_594048 != nil:
    section.add "X-Amz-Credential", valid_594048
  var valid_594049 = header.getOrDefault("X-Amz-Security-Token")
  valid_594049 = validateParameter(valid_594049, JString, required = false,
                                 default = nil)
  if valid_594049 != nil:
    section.add "X-Amz-Security-Token", valid_594049
  var valid_594050 = header.getOrDefault("X-Amz-Algorithm")
  valid_594050 = validateParameter(valid_594050, JString, required = false,
                                 default = nil)
  if valid_594050 != nil:
    section.add "X-Amz-Algorithm", valid_594050
  var valid_594051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594051 = validateParameter(valid_594051, JString, required = false,
                                 default = nil)
  if valid_594051 != nil:
    section.add "X-Amz-SignedHeaders", valid_594051
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594053: Call_CreateAssociation_594041; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates the specified Systems Manager document with the specified instances or targets.</p> <p>When you associate a document with one or more instances using instance IDs or tags, SSM Agent running on the instance processes the document and configures the instance as specified.</p> <p>If you associate a document with an instance that already has an associated document, the system returns the AssociationAlreadyExists exception.</p>
  ## 
  let valid = call_594053.validator(path, query, header, formData, body)
  let scheme = call_594053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594053.url(scheme.get, call_594053.host, call_594053.base,
                         call_594053.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594053, url, valid)

proc call*(call_594054: Call_CreateAssociation_594041; body: JsonNode): Recallable =
  ## createAssociation
  ## <p>Associates the specified Systems Manager document with the specified instances or targets.</p> <p>When you associate a document with one or more instances using instance IDs or tags, SSM Agent running on the instance processes the document and configures the instance as specified.</p> <p>If you associate a document with an instance that already has an associated document, the system returns the AssociationAlreadyExists exception.</p>
  ##   body: JObject (required)
  var body_594055 = newJObject()
  if body != nil:
    body_594055 = body
  result = call_594054.call(nil, nil, nil, nil, body_594055)

var createAssociation* = Call_CreateAssociation_594041(name: "createAssociation",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateAssociation",
    validator: validate_CreateAssociation_594042, base: "/",
    url: url_CreateAssociation_594043, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAssociationBatch_594056 = ref object of OpenApiRestCall_593389
proc url_CreateAssociationBatch_594058(protocol: Scheme; host: string; base: string;
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

proc validate_CreateAssociationBatch_594057(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594059 = header.getOrDefault("X-Amz-Target")
  valid_594059 = validateParameter(valid_594059, JString, required = true, default = newJString(
      "AmazonSSM.CreateAssociationBatch"))
  if valid_594059 != nil:
    section.add "X-Amz-Target", valid_594059
  var valid_594060 = header.getOrDefault("X-Amz-Signature")
  valid_594060 = validateParameter(valid_594060, JString, required = false,
                                 default = nil)
  if valid_594060 != nil:
    section.add "X-Amz-Signature", valid_594060
  var valid_594061 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594061 = validateParameter(valid_594061, JString, required = false,
                                 default = nil)
  if valid_594061 != nil:
    section.add "X-Amz-Content-Sha256", valid_594061
  var valid_594062 = header.getOrDefault("X-Amz-Date")
  valid_594062 = validateParameter(valid_594062, JString, required = false,
                                 default = nil)
  if valid_594062 != nil:
    section.add "X-Amz-Date", valid_594062
  var valid_594063 = header.getOrDefault("X-Amz-Credential")
  valid_594063 = validateParameter(valid_594063, JString, required = false,
                                 default = nil)
  if valid_594063 != nil:
    section.add "X-Amz-Credential", valid_594063
  var valid_594064 = header.getOrDefault("X-Amz-Security-Token")
  valid_594064 = validateParameter(valid_594064, JString, required = false,
                                 default = nil)
  if valid_594064 != nil:
    section.add "X-Amz-Security-Token", valid_594064
  var valid_594065 = header.getOrDefault("X-Amz-Algorithm")
  valid_594065 = validateParameter(valid_594065, JString, required = false,
                                 default = nil)
  if valid_594065 != nil:
    section.add "X-Amz-Algorithm", valid_594065
  var valid_594066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594066 = validateParameter(valid_594066, JString, required = false,
                                 default = nil)
  if valid_594066 != nil:
    section.add "X-Amz-SignedHeaders", valid_594066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594068: Call_CreateAssociationBatch_594056; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates the specified Systems Manager document with the specified instances or targets.</p> <p>When you associate a document with one or more instances using instance IDs or tags, SSM Agent running on the instance processes the document and configures the instance as specified.</p> <p>If you associate a document with an instance that already has an associated document, the system returns the AssociationAlreadyExists exception.</p>
  ## 
  let valid = call_594068.validator(path, query, header, formData, body)
  let scheme = call_594068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594068.url(scheme.get, call_594068.host, call_594068.base,
                         call_594068.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594068, url, valid)

proc call*(call_594069: Call_CreateAssociationBatch_594056; body: JsonNode): Recallable =
  ## createAssociationBatch
  ## <p>Associates the specified Systems Manager document with the specified instances or targets.</p> <p>When you associate a document with one or more instances using instance IDs or tags, SSM Agent running on the instance processes the document and configures the instance as specified.</p> <p>If you associate a document with an instance that already has an associated document, the system returns the AssociationAlreadyExists exception.</p>
  ##   body: JObject (required)
  var body_594070 = newJObject()
  if body != nil:
    body_594070 = body
  result = call_594069.call(nil, nil, nil, nil, body_594070)

var createAssociationBatch* = Call_CreateAssociationBatch_594056(
    name: "createAssociationBatch", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateAssociationBatch",
    validator: validate_CreateAssociationBatch_594057, base: "/",
    url: url_CreateAssociationBatch_594058, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDocument_594071 = ref object of OpenApiRestCall_593389
proc url_CreateDocument_594073(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDocument_594072(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594074 = header.getOrDefault("X-Amz-Target")
  valid_594074 = validateParameter(valid_594074, JString, required = true, default = newJString(
      "AmazonSSM.CreateDocument"))
  if valid_594074 != nil:
    section.add "X-Amz-Target", valid_594074
  var valid_594075 = header.getOrDefault("X-Amz-Signature")
  valid_594075 = validateParameter(valid_594075, JString, required = false,
                                 default = nil)
  if valid_594075 != nil:
    section.add "X-Amz-Signature", valid_594075
  var valid_594076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594076 = validateParameter(valid_594076, JString, required = false,
                                 default = nil)
  if valid_594076 != nil:
    section.add "X-Amz-Content-Sha256", valid_594076
  var valid_594077 = header.getOrDefault("X-Amz-Date")
  valid_594077 = validateParameter(valid_594077, JString, required = false,
                                 default = nil)
  if valid_594077 != nil:
    section.add "X-Amz-Date", valid_594077
  var valid_594078 = header.getOrDefault("X-Amz-Credential")
  valid_594078 = validateParameter(valid_594078, JString, required = false,
                                 default = nil)
  if valid_594078 != nil:
    section.add "X-Amz-Credential", valid_594078
  var valid_594079 = header.getOrDefault("X-Amz-Security-Token")
  valid_594079 = validateParameter(valid_594079, JString, required = false,
                                 default = nil)
  if valid_594079 != nil:
    section.add "X-Amz-Security-Token", valid_594079
  var valid_594080 = header.getOrDefault("X-Amz-Algorithm")
  valid_594080 = validateParameter(valid_594080, JString, required = false,
                                 default = nil)
  if valid_594080 != nil:
    section.add "X-Amz-Algorithm", valid_594080
  var valid_594081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594081 = validateParameter(valid_594081, JString, required = false,
                                 default = nil)
  if valid_594081 != nil:
    section.add "X-Amz-SignedHeaders", valid_594081
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594083: Call_CreateDocument_594071; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Systems Manager document.</p> <p>After you create a document, you can use CreateAssociation to associate it with one or more running instances.</p>
  ## 
  let valid = call_594083.validator(path, query, header, formData, body)
  let scheme = call_594083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594083.url(scheme.get, call_594083.host, call_594083.base,
                         call_594083.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594083, url, valid)

proc call*(call_594084: Call_CreateDocument_594071; body: JsonNode): Recallable =
  ## createDocument
  ## <p>Creates a Systems Manager document.</p> <p>After you create a document, you can use CreateAssociation to associate it with one or more running instances.</p>
  ##   body: JObject (required)
  var body_594085 = newJObject()
  if body != nil:
    body_594085 = body
  result = call_594084.call(nil, nil, nil, nil, body_594085)

var createDocument* = Call_CreateDocument_594071(name: "createDocument",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateDocument",
    validator: validate_CreateDocument_594072, base: "/", url: url_CreateDocument_594073,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMaintenanceWindow_594086 = ref object of OpenApiRestCall_593389
proc url_CreateMaintenanceWindow_594088(protocol: Scheme; host: string; base: string;
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

proc validate_CreateMaintenanceWindow_594087(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594089 = header.getOrDefault("X-Amz-Target")
  valid_594089 = validateParameter(valid_594089, JString, required = true, default = newJString(
      "AmazonSSM.CreateMaintenanceWindow"))
  if valid_594089 != nil:
    section.add "X-Amz-Target", valid_594089
  var valid_594090 = header.getOrDefault("X-Amz-Signature")
  valid_594090 = validateParameter(valid_594090, JString, required = false,
                                 default = nil)
  if valid_594090 != nil:
    section.add "X-Amz-Signature", valid_594090
  var valid_594091 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594091 = validateParameter(valid_594091, JString, required = false,
                                 default = nil)
  if valid_594091 != nil:
    section.add "X-Amz-Content-Sha256", valid_594091
  var valid_594092 = header.getOrDefault("X-Amz-Date")
  valid_594092 = validateParameter(valid_594092, JString, required = false,
                                 default = nil)
  if valid_594092 != nil:
    section.add "X-Amz-Date", valid_594092
  var valid_594093 = header.getOrDefault("X-Amz-Credential")
  valid_594093 = validateParameter(valid_594093, JString, required = false,
                                 default = nil)
  if valid_594093 != nil:
    section.add "X-Amz-Credential", valid_594093
  var valid_594094 = header.getOrDefault("X-Amz-Security-Token")
  valid_594094 = validateParameter(valid_594094, JString, required = false,
                                 default = nil)
  if valid_594094 != nil:
    section.add "X-Amz-Security-Token", valid_594094
  var valid_594095 = header.getOrDefault("X-Amz-Algorithm")
  valid_594095 = validateParameter(valid_594095, JString, required = false,
                                 default = nil)
  if valid_594095 != nil:
    section.add "X-Amz-Algorithm", valid_594095
  var valid_594096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594096 = validateParameter(valid_594096, JString, required = false,
                                 default = nil)
  if valid_594096 != nil:
    section.add "X-Amz-SignedHeaders", valid_594096
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594098: Call_CreateMaintenanceWindow_594086; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new maintenance window.</p> <note> <p>The value you specify for <code>Duration</code> determines the specific end time for the maintenance window based on the time it begins. No maintenance window tasks are permitted to start after the resulting endtime minus the number of hours you specify for <code>Cutoff</code>. For example, if the maintenance window starts at 3 PM, the duration is three hours, and the value you specify for <code>Cutoff</code> is one hour, no maintenance window tasks can start after 5 PM.</p> </note>
  ## 
  let valid = call_594098.validator(path, query, header, formData, body)
  let scheme = call_594098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594098.url(scheme.get, call_594098.host, call_594098.base,
                         call_594098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594098, url, valid)

proc call*(call_594099: Call_CreateMaintenanceWindow_594086; body: JsonNode): Recallable =
  ## createMaintenanceWindow
  ## <p>Creates a new maintenance window.</p> <note> <p>The value you specify for <code>Duration</code> determines the specific end time for the maintenance window based on the time it begins. No maintenance window tasks are permitted to start after the resulting endtime minus the number of hours you specify for <code>Cutoff</code>. For example, if the maintenance window starts at 3 PM, the duration is three hours, and the value you specify for <code>Cutoff</code> is one hour, no maintenance window tasks can start after 5 PM.</p> </note>
  ##   body: JObject (required)
  var body_594100 = newJObject()
  if body != nil:
    body_594100 = body
  result = call_594099.call(nil, nil, nil, nil, body_594100)

var createMaintenanceWindow* = Call_CreateMaintenanceWindow_594086(
    name: "createMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateMaintenanceWindow",
    validator: validate_CreateMaintenanceWindow_594087, base: "/",
    url: url_CreateMaintenanceWindow_594088, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateOpsItem_594101 = ref object of OpenApiRestCall_593389
proc url_CreateOpsItem_594103(protocol: Scheme; host: string; base: string;
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

proc validate_CreateOpsItem_594102(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594104 = header.getOrDefault("X-Amz-Target")
  valid_594104 = validateParameter(valid_594104, JString, required = true, default = newJString(
      "AmazonSSM.CreateOpsItem"))
  if valid_594104 != nil:
    section.add "X-Amz-Target", valid_594104
  var valid_594105 = header.getOrDefault("X-Amz-Signature")
  valid_594105 = validateParameter(valid_594105, JString, required = false,
                                 default = nil)
  if valid_594105 != nil:
    section.add "X-Amz-Signature", valid_594105
  var valid_594106 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594106 = validateParameter(valid_594106, JString, required = false,
                                 default = nil)
  if valid_594106 != nil:
    section.add "X-Amz-Content-Sha256", valid_594106
  var valid_594107 = header.getOrDefault("X-Amz-Date")
  valid_594107 = validateParameter(valid_594107, JString, required = false,
                                 default = nil)
  if valid_594107 != nil:
    section.add "X-Amz-Date", valid_594107
  var valid_594108 = header.getOrDefault("X-Amz-Credential")
  valid_594108 = validateParameter(valid_594108, JString, required = false,
                                 default = nil)
  if valid_594108 != nil:
    section.add "X-Amz-Credential", valid_594108
  var valid_594109 = header.getOrDefault("X-Amz-Security-Token")
  valid_594109 = validateParameter(valid_594109, JString, required = false,
                                 default = nil)
  if valid_594109 != nil:
    section.add "X-Amz-Security-Token", valid_594109
  var valid_594110 = header.getOrDefault("X-Amz-Algorithm")
  valid_594110 = validateParameter(valid_594110, JString, required = false,
                                 default = nil)
  if valid_594110 != nil:
    section.add "X-Amz-Algorithm", valid_594110
  var valid_594111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594111 = validateParameter(valid_594111, JString, required = false,
                                 default = nil)
  if valid_594111 != nil:
    section.add "X-Amz-SignedHeaders", valid_594111
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594113: Call_CreateOpsItem_594101; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new OpsItem. You must have permission in AWS Identity and Access Management (IAM) to create a new OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ## 
  let valid = call_594113.validator(path, query, header, formData, body)
  let scheme = call_594113.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594113.url(scheme.get, call_594113.host, call_594113.base,
                         call_594113.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594113, url, valid)

proc call*(call_594114: Call_CreateOpsItem_594101; body: JsonNode): Recallable =
  ## createOpsItem
  ## <p>Creates a new OpsItem. You must have permission in AWS Identity and Access Management (IAM) to create a new OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ##   body: JObject (required)
  var body_594115 = newJObject()
  if body != nil:
    body_594115 = body
  result = call_594114.call(nil, nil, nil, nil, body_594115)

var createOpsItem* = Call_CreateOpsItem_594101(name: "createOpsItem",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateOpsItem",
    validator: validate_CreateOpsItem_594102, base: "/", url: url_CreateOpsItem_594103,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePatchBaseline_594116 = ref object of OpenApiRestCall_593389
proc url_CreatePatchBaseline_594118(protocol: Scheme; host: string; base: string;
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

proc validate_CreatePatchBaseline_594117(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594119 = header.getOrDefault("X-Amz-Target")
  valid_594119 = validateParameter(valid_594119, JString, required = true, default = newJString(
      "AmazonSSM.CreatePatchBaseline"))
  if valid_594119 != nil:
    section.add "X-Amz-Target", valid_594119
  var valid_594120 = header.getOrDefault("X-Amz-Signature")
  valid_594120 = validateParameter(valid_594120, JString, required = false,
                                 default = nil)
  if valid_594120 != nil:
    section.add "X-Amz-Signature", valid_594120
  var valid_594121 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594121 = validateParameter(valid_594121, JString, required = false,
                                 default = nil)
  if valid_594121 != nil:
    section.add "X-Amz-Content-Sha256", valid_594121
  var valid_594122 = header.getOrDefault("X-Amz-Date")
  valid_594122 = validateParameter(valid_594122, JString, required = false,
                                 default = nil)
  if valid_594122 != nil:
    section.add "X-Amz-Date", valid_594122
  var valid_594123 = header.getOrDefault("X-Amz-Credential")
  valid_594123 = validateParameter(valid_594123, JString, required = false,
                                 default = nil)
  if valid_594123 != nil:
    section.add "X-Amz-Credential", valid_594123
  var valid_594124 = header.getOrDefault("X-Amz-Security-Token")
  valid_594124 = validateParameter(valid_594124, JString, required = false,
                                 default = nil)
  if valid_594124 != nil:
    section.add "X-Amz-Security-Token", valid_594124
  var valid_594125 = header.getOrDefault("X-Amz-Algorithm")
  valid_594125 = validateParameter(valid_594125, JString, required = false,
                                 default = nil)
  if valid_594125 != nil:
    section.add "X-Amz-Algorithm", valid_594125
  var valid_594126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594126 = validateParameter(valid_594126, JString, required = false,
                                 default = nil)
  if valid_594126 != nil:
    section.add "X-Amz-SignedHeaders", valid_594126
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594128: Call_CreatePatchBaseline_594116; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a patch baseline.</p> <note> <p>For information about valid key and value pairs in <code>PatchFilters</code> for each supported operating system type, see <a href="http://docs.aws.amazon.com/systems-manager/latest/APIReference/API_PatchFilter.html">PatchFilter</a>.</p> </note>
  ## 
  let valid = call_594128.validator(path, query, header, formData, body)
  let scheme = call_594128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594128.url(scheme.get, call_594128.host, call_594128.base,
                         call_594128.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594128, url, valid)

proc call*(call_594129: Call_CreatePatchBaseline_594116; body: JsonNode): Recallable =
  ## createPatchBaseline
  ## <p>Creates a patch baseline.</p> <note> <p>For information about valid key and value pairs in <code>PatchFilters</code> for each supported operating system type, see <a href="http://docs.aws.amazon.com/systems-manager/latest/APIReference/API_PatchFilter.html">PatchFilter</a>.</p> </note>
  ##   body: JObject (required)
  var body_594130 = newJObject()
  if body != nil:
    body_594130 = body
  result = call_594129.call(nil, nil, nil, nil, body_594130)

var createPatchBaseline* = Call_CreatePatchBaseline_594116(
    name: "createPatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreatePatchBaseline",
    validator: validate_CreatePatchBaseline_594117, base: "/",
    url: url_CreatePatchBaseline_594118, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResourceDataSync_594131 = ref object of OpenApiRestCall_593389
proc url_CreateResourceDataSync_594133(protocol: Scheme; host: string; base: string;
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

proc validate_CreateResourceDataSync_594132(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a resource data sync configuration to a single bucket in Amazon S3. This is an asynchronous operation that returns immediately. After a successful initial sync is completed, the system continuously syncs data to the Amazon S3 bucket. To check the status of the sync, use the <a>ListResourceDataSync</a>.</p> <p>By default, data is not encrypted in Amazon S3. We strongly recommend that you enable encryption in Amazon S3 to ensure secure data storage. We also recommend that you secure access to the Amazon S3 bucket by creating a restrictive bucket policy. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-inventory-datasync.html">Configuring Resource Data Sync for Inventory</a> in the <i>AWS Systems Manager User Guide</i>.</p>
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594134 = header.getOrDefault("X-Amz-Target")
  valid_594134 = validateParameter(valid_594134, JString, required = true, default = newJString(
      "AmazonSSM.CreateResourceDataSync"))
  if valid_594134 != nil:
    section.add "X-Amz-Target", valid_594134
  var valid_594135 = header.getOrDefault("X-Amz-Signature")
  valid_594135 = validateParameter(valid_594135, JString, required = false,
                                 default = nil)
  if valid_594135 != nil:
    section.add "X-Amz-Signature", valid_594135
  var valid_594136 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594136 = validateParameter(valid_594136, JString, required = false,
                                 default = nil)
  if valid_594136 != nil:
    section.add "X-Amz-Content-Sha256", valid_594136
  var valid_594137 = header.getOrDefault("X-Amz-Date")
  valid_594137 = validateParameter(valid_594137, JString, required = false,
                                 default = nil)
  if valid_594137 != nil:
    section.add "X-Amz-Date", valid_594137
  var valid_594138 = header.getOrDefault("X-Amz-Credential")
  valid_594138 = validateParameter(valid_594138, JString, required = false,
                                 default = nil)
  if valid_594138 != nil:
    section.add "X-Amz-Credential", valid_594138
  var valid_594139 = header.getOrDefault("X-Amz-Security-Token")
  valid_594139 = validateParameter(valid_594139, JString, required = false,
                                 default = nil)
  if valid_594139 != nil:
    section.add "X-Amz-Security-Token", valid_594139
  var valid_594140 = header.getOrDefault("X-Amz-Algorithm")
  valid_594140 = validateParameter(valid_594140, JString, required = false,
                                 default = nil)
  if valid_594140 != nil:
    section.add "X-Amz-Algorithm", valid_594140
  var valid_594141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594141 = validateParameter(valid_594141, JString, required = false,
                                 default = nil)
  if valid_594141 != nil:
    section.add "X-Amz-SignedHeaders", valid_594141
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594143: Call_CreateResourceDataSync_594131; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a resource data sync configuration to a single bucket in Amazon S3. This is an asynchronous operation that returns immediately. After a successful initial sync is completed, the system continuously syncs data to the Amazon S3 bucket. To check the status of the sync, use the <a>ListResourceDataSync</a>.</p> <p>By default, data is not encrypted in Amazon S3. We strongly recommend that you enable encryption in Amazon S3 to ensure secure data storage. We also recommend that you secure access to the Amazon S3 bucket by creating a restrictive bucket policy. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-inventory-datasync.html">Configuring Resource Data Sync for Inventory</a> in the <i>AWS Systems Manager User Guide</i>.</p>
  ## 
  let valid = call_594143.validator(path, query, header, formData, body)
  let scheme = call_594143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594143.url(scheme.get, call_594143.host, call_594143.base,
                         call_594143.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594143, url, valid)

proc call*(call_594144: Call_CreateResourceDataSync_594131; body: JsonNode): Recallable =
  ## createResourceDataSync
  ## <p>Creates a resource data sync configuration to a single bucket in Amazon S3. This is an asynchronous operation that returns immediately. After a successful initial sync is completed, the system continuously syncs data to the Amazon S3 bucket. To check the status of the sync, use the <a>ListResourceDataSync</a>.</p> <p>By default, data is not encrypted in Amazon S3. We strongly recommend that you enable encryption in Amazon S3 to ensure secure data storage. We also recommend that you secure access to the Amazon S3 bucket by creating a restrictive bucket policy. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-inventory-datasync.html">Configuring Resource Data Sync for Inventory</a> in the <i>AWS Systems Manager User Guide</i>.</p>
  ##   body: JObject (required)
  var body_594145 = newJObject()
  if body != nil:
    body_594145 = body
  result = call_594144.call(nil, nil, nil, nil, body_594145)

var createResourceDataSync* = Call_CreateResourceDataSync_594131(
    name: "createResourceDataSync", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateResourceDataSync",
    validator: validate_CreateResourceDataSync_594132, base: "/",
    url: url_CreateResourceDataSync_594133, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteActivation_594146 = ref object of OpenApiRestCall_593389
proc url_DeleteActivation_594148(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteActivation_594147(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594149 = header.getOrDefault("X-Amz-Target")
  valid_594149 = validateParameter(valid_594149, JString, required = true, default = newJString(
      "AmazonSSM.DeleteActivation"))
  if valid_594149 != nil:
    section.add "X-Amz-Target", valid_594149
  var valid_594150 = header.getOrDefault("X-Amz-Signature")
  valid_594150 = validateParameter(valid_594150, JString, required = false,
                                 default = nil)
  if valid_594150 != nil:
    section.add "X-Amz-Signature", valid_594150
  var valid_594151 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594151 = validateParameter(valid_594151, JString, required = false,
                                 default = nil)
  if valid_594151 != nil:
    section.add "X-Amz-Content-Sha256", valid_594151
  var valid_594152 = header.getOrDefault("X-Amz-Date")
  valid_594152 = validateParameter(valid_594152, JString, required = false,
                                 default = nil)
  if valid_594152 != nil:
    section.add "X-Amz-Date", valid_594152
  var valid_594153 = header.getOrDefault("X-Amz-Credential")
  valid_594153 = validateParameter(valid_594153, JString, required = false,
                                 default = nil)
  if valid_594153 != nil:
    section.add "X-Amz-Credential", valid_594153
  var valid_594154 = header.getOrDefault("X-Amz-Security-Token")
  valid_594154 = validateParameter(valid_594154, JString, required = false,
                                 default = nil)
  if valid_594154 != nil:
    section.add "X-Amz-Security-Token", valid_594154
  var valid_594155 = header.getOrDefault("X-Amz-Algorithm")
  valid_594155 = validateParameter(valid_594155, JString, required = false,
                                 default = nil)
  if valid_594155 != nil:
    section.add "X-Amz-Algorithm", valid_594155
  var valid_594156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594156 = validateParameter(valid_594156, JString, required = false,
                                 default = nil)
  if valid_594156 != nil:
    section.add "X-Amz-SignedHeaders", valid_594156
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594158: Call_DeleteActivation_594146; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an activation. You are not required to delete an activation. If you delete an activation, you can no longer use it to register additional managed instances. Deleting an activation does not de-register managed instances. You must manually de-register managed instances.
  ## 
  let valid = call_594158.validator(path, query, header, formData, body)
  let scheme = call_594158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594158.url(scheme.get, call_594158.host, call_594158.base,
                         call_594158.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594158, url, valid)

proc call*(call_594159: Call_DeleteActivation_594146; body: JsonNode): Recallable =
  ## deleteActivation
  ## Deletes an activation. You are not required to delete an activation. If you delete an activation, you can no longer use it to register additional managed instances. Deleting an activation does not de-register managed instances. You must manually de-register managed instances.
  ##   body: JObject (required)
  var body_594160 = newJObject()
  if body != nil:
    body_594160 = body
  result = call_594159.call(nil, nil, nil, nil, body_594160)

var deleteActivation* = Call_DeleteActivation_594146(name: "deleteActivation",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteActivation",
    validator: validate_DeleteActivation_594147, base: "/",
    url: url_DeleteActivation_594148, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAssociation_594161 = ref object of OpenApiRestCall_593389
proc url_DeleteAssociation_594163(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAssociation_594162(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594164 = header.getOrDefault("X-Amz-Target")
  valid_594164 = validateParameter(valid_594164, JString, required = true, default = newJString(
      "AmazonSSM.DeleteAssociation"))
  if valid_594164 != nil:
    section.add "X-Amz-Target", valid_594164
  var valid_594165 = header.getOrDefault("X-Amz-Signature")
  valid_594165 = validateParameter(valid_594165, JString, required = false,
                                 default = nil)
  if valid_594165 != nil:
    section.add "X-Amz-Signature", valid_594165
  var valid_594166 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594166 = validateParameter(valid_594166, JString, required = false,
                                 default = nil)
  if valid_594166 != nil:
    section.add "X-Amz-Content-Sha256", valid_594166
  var valid_594167 = header.getOrDefault("X-Amz-Date")
  valid_594167 = validateParameter(valid_594167, JString, required = false,
                                 default = nil)
  if valid_594167 != nil:
    section.add "X-Amz-Date", valid_594167
  var valid_594168 = header.getOrDefault("X-Amz-Credential")
  valid_594168 = validateParameter(valid_594168, JString, required = false,
                                 default = nil)
  if valid_594168 != nil:
    section.add "X-Amz-Credential", valid_594168
  var valid_594169 = header.getOrDefault("X-Amz-Security-Token")
  valid_594169 = validateParameter(valid_594169, JString, required = false,
                                 default = nil)
  if valid_594169 != nil:
    section.add "X-Amz-Security-Token", valid_594169
  var valid_594170 = header.getOrDefault("X-Amz-Algorithm")
  valid_594170 = validateParameter(valid_594170, JString, required = false,
                                 default = nil)
  if valid_594170 != nil:
    section.add "X-Amz-Algorithm", valid_594170
  var valid_594171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594171 = validateParameter(valid_594171, JString, required = false,
                                 default = nil)
  if valid_594171 != nil:
    section.add "X-Amz-SignedHeaders", valid_594171
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594173: Call_DeleteAssociation_594161; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disassociates the specified Systems Manager document from the specified instance.</p> <p>When you disassociate a document from an instance, it does not change the configuration of the instance. To change the configuration state of an instance after you disassociate a document, you must create a new document with the desired configuration and associate it with the instance.</p>
  ## 
  let valid = call_594173.validator(path, query, header, formData, body)
  let scheme = call_594173.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594173.url(scheme.get, call_594173.host, call_594173.base,
                         call_594173.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594173, url, valid)

proc call*(call_594174: Call_DeleteAssociation_594161; body: JsonNode): Recallable =
  ## deleteAssociation
  ## <p>Disassociates the specified Systems Manager document from the specified instance.</p> <p>When you disassociate a document from an instance, it does not change the configuration of the instance. To change the configuration state of an instance after you disassociate a document, you must create a new document with the desired configuration and associate it with the instance.</p>
  ##   body: JObject (required)
  var body_594175 = newJObject()
  if body != nil:
    body_594175 = body
  result = call_594174.call(nil, nil, nil, nil, body_594175)

var deleteAssociation* = Call_DeleteAssociation_594161(name: "deleteAssociation",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteAssociation",
    validator: validate_DeleteAssociation_594162, base: "/",
    url: url_DeleteAssociation_594163, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDocument_594176 = ref object of OpenApiRestCall_593389
proc url_DeleteDocument_594178(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDocument_594177(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594179 = header.getOrDefault("X-Amz-Target")
  valid_594179 = validateParameter(valid_594179, JString, required = true, default = newJString(
      "AmazonSSM.DeleteDocument"))
  if valid_594179 != nil:
    section.add "X-Amz-Target", valid_594179
  var valid_594180 = header.getOrDefault("X-Amz-Signature")
  valid_594180 = validateParameter(valid_594180, JString, required = false,
                                 default = nil)
  if valid_594180 != nil:
    section.add "X-Amz-Signature", valid_594180
  var valid_594181 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594181 = validateParameter(valid_594181, JString, required = false,
                                 default = nil)
  if valid_594181 != nil:
    section.add "X-Amz-Content-Sha256", valid_594181
  var valid_594182 = header.getOrDefault("X-Amz-Date")
  valid_594182 = validateParameter(valid_594182, JString, required = false,
                                 default = nil)
  if valid_594182 != nil:
    section.add "X-Amz-Date", valid_594182
  var valid_594183 = header.getOrDefault("X-Amz-Credential")
  valid_594183 = validateParameter(valid_594183, JString, required = false,
                                 default = nil)
  if valid_594183 != nil:
    section.add "X-Amz-Credential", valid_594183
  var valid_594184 = header.getOrDefault("X-Amz-Security-Token")
  valid_594184 = validateParameter(valid_594184, JString, required = false,
                                 default = nil)
  if valid_594184 != nil:
    section.add "X-Amz-Security-Token", valid_594184
  var valid_594185 = header.getOrDefault("X-Amz-Algorithm")
  valid_594185 = validateParameter(valid_594185, JString, required = false,
                                 default = nil)
  if valid_594185 != nil:
    section.add "X-Amz-Algorithm", valid_594185
  var valid_594186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594186 = validateParameter(valid_594186, JString, required = false,
                                 default = nil)
  if valid_594186 != nil:
    section.add "X-Amz-SignedHeaders", valid_594186
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594188: Call_DeleteDocument_594176; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the Systems Manager document and all instance associations to the document.</p> <p>Before you delete the document, we recommend that you use <a>DeleteAssociation</a> to disassociate all instances that are associated with the document.</p>
  ## 
  let valid = call_594188.validator(path, query, header, formData, body)
  let scheme = call_594188.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594188.url(scheme.get, call_594188.host, call_594188.base,
                         call_594188.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594188, url, valid)

proc call*(call_594189: Call_DeleteDocument_594176; body: JsonNode): Recallable =
  ## deleteDocument
  ## <p>Deletes the Systems Manager document and all instance associations to the document.</p> <p>Before you delete the document, we recommend that you use <a>DeleteAssociation</a> to disassociate all instances that are associated with the document.</p>
  ##   body: JObject (required)
  var body_594190 = newJObject()
  if body != nil:
    body_594190 = body
  result = call_594189.call(nil, nil, nil, nil, body_594190)

var deleteDocument* = Call_DeleteDocument_594176(name: "deleteDocument",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteDocument",
    validator: validate_DeleteDocument_594177, base: "/", url: url_DeleteDocument_594178,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInventory_594191 = ref object of OpenApiRestCall_593389
proc url_DeleteInventory_594193(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteInventory_594192(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594194 = header.getOrDefault("X-Amz-Target")
  valid_594194 = validateParameter(valid_594194, JString, required = true, default = newJString(
      "AmazonSSM.DeleteInventory"))
  if valid_594194 != nil:
    section.add "X-Amz-Target", valid_594194
  var valid_594195 = header.getOrDefault("X-Amz-Signature")
  valid_594195 = validateParameter(valid_594195, JString, required = false,
                                 default = nil)
  if valid_594195 != nil:
    section.add "X-Amz-Signature", valid_594195
  var valid_594196 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594196 = validateParameter(valid_594196, JString, required = false,
                                 default = nil)
  if valid_594196 != nil:
    section.add "X-Amz-Content-Sha256", valid_594196
  var valid_594197 = header.getOrDefault("X-Amz-Date")
  valid_594197 = validateParameter(valid_594197, JString, required = false,
                                 default = nil)
  if valid_594197 != nil:
    section.add "X-Amz-Date", valid_594197
  var valid_594198 = header.getOrDefault("X-Amz-Credential")
  valid_594198 = validateParameter(valid_594198, JString, required = false,
                                 default = nil)
  if valid_594198 != nil:
    section.add "X-Amz-Credential", valid_594198
  var valid_594199 = header.getOrDefault("X-Amz-Security-Token")
  valid_594199 = validateParameter(valid_594199, JString, required = false,
                                 default = nil)
  if valid_594199 != nil:
    section.add "X-Amz-Security-Token", valid_594199
  var valid_594200 = header.getOrDefault("X-Amz-Algorithm")
  valid_594200 = validateParameter(valid_594200, JString, required = false,
                                 default = nil)
  if valid_594200 != nil:
    section.add "X-Amz-Algorithm", valid_594200
  var valid_594201 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594201 = validateParameter(valid_594201, JString, required = false,
                                 default = nil)
  if valid_594201 != nil:
    section.add "X-Amz-SignedHeaders", valid_594201
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594203: Call_DeleteInventory_594191; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a custom inventory type, or the data associated with a custom Inventory type. Deleting a custom inventory type is also referred to as deleting a custom inventory schema.
  ## 
  let valid = call_594203.validator(path, query, header, formData, body)
  let scheme = call_594203.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594203.url(scheme.get, call_594203.host, call_594203.base,
                         call_594203.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594203, url, valid)

proc call*(call_594204: Call_DeleteInventory_594191; body: JsonNode): Recallable =
  ## deleteInventory
  ## Delete a custom inventory type, or the data associated with a custom Inventory type. Deleting a custom inventory type is also referred to as deleting a custom inventory schema.
  ##   body: JObject (required)
  var body_594205 = newJObject()
  if body != nil:
    body_594205 = body
  result = call_594204.call(nil, nil, nil, nil, body_594205)

var deleteInventory* = Call_DeleteInventory_594191(name: "deleteInventory",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteInventory",
    validator: validate_DeleteInventory_594192, base: "/", url: url_DeleteInventory_594193,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMaintenanceWindow_594206 = ref object of OpenApiRestCall_593389
proc url_DeleteMaintenanceWindow_594208(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteMaintenanceWindow_594207(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594209 = header.getOrDefault("X-Amz-Target")
  valid_594209 = validateParameter(valid_594209, JString, required = true, default = newJString(
      "AmazonSSM.DeleteMaintenanceWindow"))
  if valid_594209 != nil:
    section.add "X-Amz-Target", valid_594209
  var valid_594210 = header.getOrDefault("X-Amz-Signature")
  valid_594210 = validateParameter(valid_594210, JString, required = false,
                                 default = nil)
  if valid_594210 != nil:
    section.add "X-Amz-Signature", valid_594210
  var valid_594211 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594211 = validateParameter(valid_594211, JString, required = false,
                                 default = nil)
  if valid_594211 != nil:
    section.add "X-Amz-Content-Sha256", valid_594211
  var valid_594212 = header.getOrDefault("X-Amz-Date")
  valid_594212 = validateParameter(valid_594212, JString, required = false,
                                 default = nil)
  if valid_594212 != nil:
    section.add "X-Amz-Date", valid_594212
  var valid_594213 = header.getOrDefault("X-Amz-Credential")
  valid_594213 = validateParameter(valid_594213, JString, required = false,
                                 default = nil)
  if valid_594213 != nil:
    section.add "X-Amz-Credential", valid_594213
  var valid_594214 = header.getOrDefault("X-Amz-Security-Token")
  valid_594214 = validateParameter(valid_594214, JString, required = false,
                                 default = nil)
  if valid_594214 != nil:
    section.add "X-Amz-Security-Token", valid_594214
  var valid_594215 = header.getOrDefault("X-Amz-Algorithm")
  valid_594215 = validateParameter(valid_594215, JString, required = false,
                                 default = nil)
  if valid_594215 != nil:
    section.add "X-Amz-Algorithm", valid_594215
  var valid_594216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594216 = validateParameter(valid_594216, JString, required = false,
                                 default = nil)
  if valid_594216 != nil:
    section.add "X-Amz-SignedHeaders", valid_594216
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594218: Call_DeleteMaintenanceWindow_594206; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a maintenance window.
  ## 
  let valid = call_594218.validator(path, query, header, formData, body)
  let scheme = call_594218.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594218.url(scheme.get, call_594218.host, call_594218.base,
                         call_594218.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594218, url, valid)

proc call*(call_594219: Call_DeleteMaintenanceWindow_594206; body: JsonNode): Recallable =
  ## deleteMaintenanceWindow
  ## Deletes a maintenance window.
  ##   body: JObject (required)
  var body_594220 = newJObject()
  if body != nil:
    body_594220 = body
  result = call_594219.call(nil, nil, nil, nil, body_594220)

var deleteMaintenanceWindow* = Call_DeleteMaintenanceWindow_594206(
    name: "deleteMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteMaintenanceWindow",
    validator: validate_DeleteMaintenanceWindow_594207, base: "/",
    url: url_DeleteMaintenanceWindow_594208, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteParameter_594221 = ref object of OpenApiRestCall_593389
proc url_DeleteParameter_594223(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteParameter_594222(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594224 = header.getOrDefault("X-Amz-Target")
  valid_594224 = validateParameter(valid_594224, JString, required = true, default = newJString(
      "AmazonSSM.DeleteParameter"))
  if valid_594224 != nil:
    section.add "X-Amz-Target", valid_594224
  var valid_594225 = header.getOrDefault("X-Amz-Signature")
  valid_594225 = validateParameter(valid_594225, JString, required = false,
                                 default = nil)
  if valid_594225 != nil:
    section.add "X-Amz-Signature", valid_594225
  var valid_594226 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594226 = validateParameter(valid_594226, JString, required = false,
                                 default = nil)
  if valid_594226 != nil:
    section.add "X-Amz-Content-Sha256", valid_594226
  var valid_594227 = header.getOrDefault("X-Amz-Date")
  valid_594227 = validateParameter(valid_594227, JString, required = false,
                                 default = nil)
  if valid_594227 != nil:
    section.add "X-Amz-Date", valid_594227
  var valid_594228 = header.getOrDefault("X-Amz-Credential")
  valid_594228 = validateParameter(valid_594228, JString, required = false,
                                 default = nil)
  if valid_594228 != nil:
    section.add "X-Amz-Credential", valid_594228
  var valid_594229 = header.getOrDefault("X-Amz-Security-Token")
  valid_594229 = validateParameter(valid_594229, JString, required = false,
                                 default = nil)
  if valid_594229 != nil:
    section.add "X-Amz-Security-Token", valid_594229
  var valid_594230 = header.getOrDefault("X-Amz-Algorithm")
  valid_594230 = validateParameter(valid_594230, JString, required = false,
                                 default = nil)
  if valid_594230 != nil:
    section.add "X-Amz-Algorithm", valid_594230
  var valid_594231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594231 = validateParameter(valid_594231, JString, required = false,
                                 default = nil)
  if valid_594231 != nil:
    section.add "X-Amz-SignedHeaders", valid_594231
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594233: Call_DeleteParameter_594221; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a parameter from the system.
  ## 
  let valid = call_594233.validator(path, query, header, formData, body)
  let scheme = call_594233.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594233.url(scheme.get, call_594233.host, call_594233.base,
                         call_594233.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594233, url, valid)

proc call*(call_594234: Call_DeleteParameter_594221; body: JsonNode): Recallable =
  ## deleteParameter
  ## Delete a parameter from the system.
  ##   body: JObject (required)
  var body_594235 = newJObject()
  if body != nil:
    body_594235 = body
  result = call_594234.call(nil, nil, nil, nil, body_594235)

var deleteParameter* = Call_DeleteParameter_594221(name: "deleteParameter",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteParameter",
    validator: validate_DeleteParameter_594222, base: "/", url: url_DeleteParameter_594223,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteParameters_594236 = ref object of OpenApiRestCall_593389
proc url_DeleteParameters_594238(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteParameters_594237(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594239 = header.getOrDefault("X-Amz-Target")
  valid_594239 = validateParameter(valid_594239, JString, required = true, default = newJString(
      "AmazonSSM.DeleteParameters"))
  if valid_594239 != nil:
    section.add "X-Amz-Target", valid_594239
  var valid_594240 = header.getOrDefault("X-Amz-Signature")
  valid_594240 = validateParameter(valid_594240, JString, required = false,
                                 default = nil)
  if valid_594240 != nil:
    section.add "X-Amz-Signature", valid_594240
  var valid_594241 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594241 = validateParameter(valid_594241, JString, required = false,
                                 default = nil)
  if valid_594241 != nil:
    section.add "X-Amz-Content-Sha256", valid_594241
  var valid_594242 = header.getOrDefault("X-Amz-Date")
  valid_594242 = validateParameter(valid_594242, JString, required = false,
                                 default = nil)
  if valid_594242 != nil:
    section.add "X-Amz-Date", valid_594242
  var valid_594243 = header.getOrDefault("X-Amz-Credential")
  valid_594243 = validateParameter(valid_594243, JString, required = false,
                                 default = nil)
  if valid_594243 != nil:
    section.add "X-Amz-Credential", valid_594243
  var valid_594244 = header.getOrDefault("X-Amz-Security-Token")
  valid_594244 = validateParameter(valid_594244, JString, required = false,
                                 default = nil)
  if valid_594244 != nil:
    section.add "X-Amz-Security-Token", valid_594244
  var valid_594245 = header.getOrDefault("X-Amz-Algorithm")
  valid_594245 = validateParameter(valid_594245, JString, required = false,
                                 default = nil)
  if valid_594245 != nil:
    section.add "X-Amz-Algorithm", valid_594245
  var valid_594246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594246 = validateParameter(valid_594246, JString, required = false,
                                 default = nil)
  if valid_594246 != nil:
    section.add "X-Amz-SignedHeaders", valid_594246
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594248: Call_DeleteParameters_594236; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a list of parameters.
  ## 
  let valid = call_594248.validator(path, query, header, formData, body)
  let scheme = call_594248.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594248.url(scheme.get, call_594248.host, call_594248.base,
                         call_594248.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594248, url, valid)

proc call*(call_594249: Call_DeleteParameters_594236; body: JsonNode): Recallable =
  ## deleteParameters
  ## Delete a list of parameters.
  ##   body: JObject (required)
  var body_594250 = newJObject()
  if body != nil:
    body_594250 = body
  result = call_594249.call(nil, nil, nil, nil, body_594250)

var deleteParameters* = Call_DeleteParameters_594236(name: "deleteParameters",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteParameters",
    validator: validate_DeleteParameters_594237, base: "/",
    url: url_DeleteParameters_594238, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePatchBaseline_594251 = ref object of OpenApiRestCall_593389
proc url_DeletePatchBaseline_594253(protocol: Scheme; host: string; base: string;
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

proc validate_DeletePatchBaseline_594252(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594254 = header.getOrDefault("X-Amz-Target")
  valid_594254 = validateParameter(valid_594254, JString, required = true, default = newJString(
      "AmazonSSM.DeletePatchBaseline"))
  if valid_594254 != nil:
    section.add "X-Amz-Target", valid_594254
  var valid_594255 = header.getOrDefault("X-Amz-Signature")
  valid_594255 = validateParameter(valid_594255, JString, required = false,
                                 default = nil)
  if valid_594255 != nil:
    section.add "X-Amz-Signature", valid_594255
  var valid_594256 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594256 = validateParameter(valid_594256, JString, required = false,
                                 default = nil)
  if valid_594256 != nil:
    section.add "X-Amz-Content-Sha256", valid_594256
  var valid_594257 = header.getOrDefault("X-Amz-Date")
  valid_594257 = validateParameter(valid_594257, JString, required = false,
                                 default = nil)
  if valid_594257 != nil:
    section.add "X-Amz-Date", valid_594257
  var valid_594258 = header.getOrDefault("X-Amz-Credential")
  valid_594258 = validateParameter(valid_594258, JString, required = false,
                                 default = nil)
  if valid_594258 != nil:
    section.add "X-Amz-Credential", valid_594258
  var valid_594259 = header.getOrDefault("X-Amz-Security-Token")
  valid_594259 = validateParameter(valid_594259, JString, required = false,
                                 default = nil)
  if valid_594259 != nil:
    section.add "X-Amz-Security-Token", valid_594259
  var valid_594260 = header.getOrDefault("X-Amz-Algorithm")
  valid_594260 = validateParameter(valid_594260, JString, required = false,
                                 default = nil)
  if valid_594260 != nil:
    section.add "X-Amz-Algorithm", valid_594260
  var valid_594261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594261 = validateParameter(valid_594261, JString, required = false,
                                 default = nil)
  if valid_594261 != nil:
    section.add "X-Amz-SignedHeaders", valid_594261
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594263: Call_DeletePatchBaseline_594251; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a patch baseline.
  ## 
  let valid = call_594263.validator(path, query, header, formData, body)
  let scheme = call_594263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594263.url(scheme.get, call_594263.host, call_594263.base,
                         call_594263.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594263, url, valid)

proc call*(call_594264: Call_DeletePatchBaseline_594251; body: JsonNode): Recallable =
  ## deletePatchBaseline
  ## Deletes a patch baseline.
  ##   body: JObject (required)
  var body_594265 = newJObject()
  if body != nil:
    body_594265 = body
  result = call_594264.call(nil, nil, nil, nil, body_594265)

var deletePatchBaseline* = Call_DeletePatchBaseline_594251(
    name: "deletePatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeletePatchBaseline",
    validator: validate_DeletePatchBaseline_594252, base: "/",
    url: url_DeletePatchBaseline_594253, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResourceDataSync_594266 = ref object of OpenApiRestCall_593389
proc url_DeleteResourceDataSync_594268(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteResourceDataSync_594267(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a Resource Data Sync configuration. After the configuration is deleted, changes to inventory data on managed instances are no longer synced with the target Amazon S3 bucket. Deleting a sync configuration does not delete data in the target Amazon S3 bucket.
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594269 = header.getOrDefault("X-Amz-Target")
  valid_594269 = validateParameter(valid_594269, JString, required = true, default = newJString(
      "AmazonSSM.DeleteResourceDataSync"))
  if valid_594269 != nil:
    section.add "X-Amz-Target", valid_594269
  var valid_594270 = header.getOrDefault("X-Amz-Signature")
  valid_594270 = validateParameter(valid_594270, JString, required = false,
                                 default = nil)
  if valid_594270 != nil:
    section.add "X-Amz-Signature", valid_594270
  var valid_594271 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594271 = validateParameter(valid_594271, JString, required = false,
                                 default = nil)
  if valid_594271 != nil:
    section.add "X-Amz-Content-Sha256", valid_594271
  var valid_594272 = header.getOrDefault("X-Amz-Date")
  valid_594272 = validateParameter(valid_594272, JString, required = false,
                                 default = nil)
  if valid_594272 != nil:
    section.add "X-Amz-Date", valid_594272
  var valid_594273 = header.getOrDefault("X-Amz-Credential")
  valid_594273 = validateParameter(valid_594273, JString, required = false,
                                 default = nil)
  if valid_594273 != nil:
    section.add "X-Amz-Credential", valid_594273
  var valid_594274 = header.getOrDefault("X-Amz-Security-Token")
  valid_594274 = validateParameter(valid_594274, JString, required = false,
                                 default = nil)
  if valid_594274 != nil:
    section.add "X-Amz-Security-Token", valid_594274
  var valid_594275 = header.getOrDefault("X-Amz-Algorithm")
  valid_594275 = validateParameter(valid_594275, JString, required = false,
                                 default = nil)
  if valid_594275 != nil:
    section.add "X-Amz-Algorithm", valid_594275
  var valid_594276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594276 = validateParameter(valid_594276, JString, required = false,
                                 default = nil)
  if valid_594276 != nil:
    section.add "X-Amz-SignedHeaders", valid_594276
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594278: Call_DeleteResourceDataSync_594266; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Resource Data Sync configuration. After the configuration is deleted, changes to inventory data on managed instances are no longer synced with the target Amazon S3 bucket. Deleting a sync configuration does not delete data in the target Amazon S3 bucket.
  ## 
  let valid = call_594278.validator(path, query, header, formData, body)
  let scheme = call_594278.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594278.url(scheme.get, call_594278.host, call_594278.base,
                         call_594278.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594278, url, valid)

proc call*(call_594279: Call_DeleteResourceDataSync_594266; body: JsonNode): Recallable =
  ## deleteResourceDataSync
  ## Deletes a Resource Data Sync configuration. After the configuration is deleted, changes to inventory data on managed instances are no longer synced with the target Amazon S3 bucket. Deleting a sync configuration does not delete data in the target Amazon S3 bucket.
  ##   body: JObject (required)
  var body_594280 = newJObject()
  if body != nil:
    body_594280 = body
  result = call_594279.call(nil, nil, nil, nil, body_594280)

var deleteResourceDataSync* = Call_DeleteResourceDataSync_594266(
    name: "deleteResourceDataSync", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteResourceDataSync",
    validator: validate_DeleteResourceDataSync_594267, base: "/",
    url: url_DeleteResourceDataSync_594268, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterManagedInstance_594281 = ref object of OpenApiRestCall_593389
proc url_DeregisterManagedInstance_594283(protocol: Scheme; host: string;
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

proc validate_DeregisterManagedInstance_594282(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594284 = header.getOrDefault("X-Amz-Target")
  valid_594284 = validateParameter(valid_594284, JString, required = true, default = newJString(
      "AmazonSSM.DeregisterManagedInstance"))
  if valid_594284 != nil:
    section.add "X-Amz-Target", valid_594284
  var valid_594285 = header.getOrDefault("X-Amz-Signature")
  valid_594285 = validateParameter(valid_594285, JString, required = false,
                                 default = nil)
  if valid_594285 != nil:
    section.add "X-Amz-Signature", valid_594285
  var valid_594286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594286 = validateParameter(valid_594286, JString, required = false,
                                 default = nil)
  if valid_594286 != nil:
    section.add "X-Amz-Content-Sha256", valid_594286
  var valid_594287 = header.getOrDefault("X-Amz-Date")
  valid_594287 = validateParameter(valid_594287, JString, required = false,
                                 default = nil)
  if valid_594287 != nil:
    section.add "X-Amz-Date", valid_594287
  var valid_594288 = header.getOrDefault("X-Amz-Credential")
  valid_594288 = validateParameter(valid_594288, JString, required = false,
                                 default = nil)
  if valid_594288 != nil:
    section.add "X-Amz-Credential", valid_594288
  var valid_594289 = header.getOrDefault("X-Amz-Security-Token")
  valid_594289 = validateParameter(valid_594289, JString, required = false,
                                 default = nil)
  if valid_594289 != nil:
    section.add "X-Amz-Security-Token", valid_594289
  var valid_594290 = header.getOrDefault("X-Amz-Algorithm")
  valid_594290 = validateParameter(valid_594290, JString, required = false,
                                 default = nil)
  if valid_594290 != nil:
    section.add "X-Amz-Algorithm", valid_594290
  var valid_594291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594291 = validateParameter(valid_594291, JString, required = false,
                                 default = nil)
  if valid_594291 != nil:
    section.add "X-Amz-SignedHeaders", valid_594291
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594293: Call_DeregisterManagedInstance_594281; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the server or virtual machine from the list of registered servers. You can reregister the instance again at any time. If you don't plan to use Run Command on the server, we suggest uninstalling SSM Agent first.
  ## 
  let valid = call_594293.validator(path, query, header, formData, body)
  let scheme = call_594293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594293.url(scheme.get, call_594293.host, call_594293.base,
                         call_594293.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594293, url, valid)

proc call*(call_594294: Call_DeregisterManagedInstance_594281; body: JsonNode): Recallable =
  ## deregisterManagedInstance
  ## Removes the server or virtual machine from the list of registered servers. You can reregister the instance again at any time. If you don't plan to use Run Command on the server, we suggest uninstalling SSM Agent first.
  ##   body: JObject (required)
  var body_594295 = newJObject()
  if body != nil:
    body_594295 = body
  result = call_594294.call(nil, nil, nil, nil, body_594295)

var deregisterManagedInstance* = Call_DeregisterManagedInstance_594281(
    name: "deregisterManagedInstance", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeregisterManagedInstance",
    validator: validate_DeregisterManagedInstance_594282, base: "/",
    url: url_DeregisterManagedInstance_594283,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterPatchBaselineForPatchGroup_594296 = ref object of OpenApiRestCall_593389
proc url_DeregisterPatchBaselineForPatchGroup_594298(protocol: Scheme;
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

proc validate_DeregisterPatchBaselineForPatchGroup_594297(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594299 = header.getOrDefault("X-Amz-Target")
  valid_594299 = validateParameter(valid_594299, JString, required = true, default = newJString(
      "AmazonSSM.DeregisterPatchBaselineForPatchGroup"))
  if valid_594299 != nil:
    section.add "X-Amz-Target", valid_594299
  var valid_594300 = header.getOrDefault("X-Amz-Signature")
  valid_594300 = validateParameter(valid_594300, JString, required = false,
                                 default = nil)
  if valid_594300 != nil:
    section.add "X-Amz-Signature", valid_594300
  var valid_594301 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594301 = validateParameter(valid_594301, JString, required = false,
                                 default = nil)
  if valid_594301 != nil:
    section.add "X-Amz-Content-Sha256", valid_594301
  var valid_594302 = header.getOrDefault("X-Amz-Date")
  valid_594302 = validateParameter(valid_594302, JString, required = false,
                                 default = nil)
  if valid_594302 != nil:
    section.add "X-Amz-Date", valid_594302
  var valid_594303 = header.getOrDefault("X-Amz-Credential")
  valid_594303 = validateParameter(valid_594303, JString, required = false,
                                 default = nil)
  if valid_594303 != nil:
    section.add "X-Amz-Credential", valid_594303
  var valid_594304 = header.getOrDefault("X-Amz-Security-Token")
  valid_594304 = validateParameter(valid_594304, JString, required = false,
                                 default = nil)
  if valid_594304 != nil:
    section.add "X-Amz-Security-Token", valid_594304
  var valid_594305 = header.getOrDefault("X-Amz-Algorithm")
  valid_594305 = validateParameter(valid_594305, JString, required = false,
                                 default = nil)
  if valid_594305 != nil:
    section.add "X-Amz-Algorithm", valid_594305
  var valid_594306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594306 = validateParameter(valid_594306, JString, required = false,
                                 default = nil)
  if valid_594306 != nil:
    section.add "X-Amz-SignedHeaders", valid_594306
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594308: Call_DeregisterPatchBaselineForPatchGroup_594296;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Removes a patch group from a patch baseline.
  ## 
  let valid = call_594308.validator(path, query, header, formData, body)
  let scheme = call_594308.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594308.url(scheme.get, call_594308.host, call_594308.base,
                         call_594308.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594308, url, valid)

proc call*(call_594309: Call_DeregisterPatchBaselineForPatchGroup_594296;
          body: JsonNode): Recallable =
  ## deregisterPatchBaselineForPatchGroup
  ## Removes a patch group from a patch baseline.
  ##   body: JObject (required)
  var body_594310 = newJObject()
  if body != nil:
    body_594310 = body
  result = call_594309.call(nil, nil, nil, nil, body_594310)

var deregisterPatchBaselineForPatchGroup* = Call_DeregisterPatchBaselineForPatchGroup_594296(
    name: "deregisterPatchBaselineForPatchGroup", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeregisterPatchBaselineForPatchGroup",
    validator: validate_DeregisterPatchBaselineForPatchGroup_594297, base: "/",
    url: url_DeregisterPatchBaselineForPatchGroup_594298,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterTargetFromMaintenanceWindow_594311 = ref object of OpenApiRestCall_593389
proc url_DeregisterTargetFromMaintenanceWindow_594313(protocol: Scheme;
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

proc validate_DeregisterTargetFromMaintenanceWindow_594312(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594314 = header.getOrDefault("X-Amz-Target")
  valid_594314 = validateParameter(valid_594314, JString, required = true, default = newJString(
      "AmazonSSM.DeregisterTargetFromMaintenanceWindow"))
  if valid_594314 != nil:
    section.add "X-Amz-Target", valid_594314
  var valid_594315 = header.getOrDefault("X-Amz-Signature")
  valid_594315 = validateParameter(valid_594315, JString, required = false,
                                 default = nil)
  if valid_594315 != nil:
    section.add "X-Amz-Signature", valid_594315
  var valid_594316 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594316 = validateParameter(valid_594316, JString, required = false,
                                 default = nil)
  if valid_594316 != nil:
    section.add "X-Amz-Content-Sha256", valid_594316
  var valid_594317 = header.getOrDefault("X-Amz-Date")
  valid_594317 = validateParameter(valid_594317, JString, required = false,
                                 default = nil)
  if valid_594317 != nil:
    section.add "X-Amz-Date", valid_594317
  var valid_594318 = header.getOrDefault("X-Amz-Credential")
  valid_594318 = validateParameter(valid_594318, JString, required = false,
                                 default = nil)
  if valid_594318 != nil:
    section.add "X-Amz-Credential", valid_594318
  var valid_594319 = header.getOrDefault("X-Amz-Security-Token")
  valid_594319 = validateParameter(valid_594319, JString, required = false,
                                 default = nil)
  if valid_594319 != nil:
    section.add "X-Amz-Security-Token", valid_594319
  var valid_594320 = header.getOrDefault("X-Amz-Algorithm")
  valid_594320 = validateParameter(valid_594320, JString, required = false,
                                 default = nil)
  if valid_594320 != nil:
    section.add "X-Amz-Algorithm", valid_594320
  var valid_594321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594321 = validateParameter(valid_594321, JString, required = false,
                                 default = nil)
  if valid_594321 != nil:
    section.add "X-Amz-SignedHeaders", valid_594321
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594323: Call_DeregisterTargetFromMaintenanceWindow_594311;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Removes a target from a maintenance window.
  ## 
  let valid = call_594323.validator(path, query, header, formData, body)
  let scheme = call_594323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594323.url(scheme.get, call_594323.host, call_594323.base,
                         call_594323.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594323, url, valid)

proc call*(call_594324: Call_DeregisterTargetFromMaintenanceWindow_594311;
          body: JsonNode): Recallable =
  ## deregisterTargetFromMaintenanceWindow
  ## Removes a target from a maintenance window.
  ##   body: JObject (required)
  var body_594325 = newJObject()
  if body != nil:
    body_594325 = body
  result = call_594324.call(nil, nil, nil, nil, body_594325)

var deregisterTargetFromMaintenanceWindow* = Call_DeregisterTargetFromMaintenanceWindow_594311(
    name: "deregisterTargetFromMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeregisterTargetFromMaintenanceWindow",
    validator: validate_DeregisterTargetFromMaintenanceWindow_594312, base: "/",
    url: url_DeregisterTargetFromMaintenanceWindow_594313,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterTaskFromMaintenanceWindow_594326 = ref object of OpenApiRestCall_593389
proc url_DeregisterTaskFromMaintenanceWindow_594328(protocol: Scheme; host: string;
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

proc validate_DeregisterTaskFromMaintenanceWindow_594327(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594329 = header.getOrDefault("X-Amz-Target")
  valid_594329 = validateParameter(valid_594329, JString, required = true, default = newJString(
      "AmazonSSM.DeregisterTaskFromMaintenanceWindow"))
  if valid_594329 != nil:
    section.add "X-Amz-Target", valid_594329
  var valid_594330 = header.getOrDefault("X-Amz-Signature")
  valid_594330 = validateParameter(valid_594330, JString, required = false,
                                 default = nil)
  if valid_594330 != nil:
    section.add "X-Amz-Signature", valid_594330
  var valid_594331 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594331 = validateParameter(valid_594331, JString, required = false,
                                 default = nil)
  if valid_594331 != nil:
    section.add "X-Amz-Content-Sha256", valid_594331
  var valid_594332 = header.getOrDefault("X-Amz-Date")
  valid_594332 = validateParameter(valid_594332, JString, required = false,
                                 default = nil)
  if valid_594332 != nil:
    section.add "X-Amz-Date", valid_594332
  var valid_594333 = header.getOrDefault("X-Amz-Credential")
  valid_594333 = validateParameter(valid_594333, JString, required = false,
                                 default = nil)
  if valid_594333 != nil:
    section.add "X-Amz-Credential", valid_594333
  var valid_594334 = header.getOrDefault("X-Amz-Security-Token")
  valid_594334 = validateParameter(valid_594334, JString, required = false,
                                 default = nil)
  if valid_594334 != nil:
    section.add "X-Amz-Security-Token", valid_594334
  var valid_594335 = header.getOrDefault("X-Amz-Algorithm")
  valid_594335 = validateParameter(valid_594335, JString, required = false,
                                 default = nil)
  if valid_594335 != nil:
    section.add "X-Amz-Algorithm", valid_594335
  var valid_594336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594336 = validateParameter(valid_594336, JString, required = false,
                                 default = nil)
  if valid_594336 != nil:
    section.add "X-Amz-SignedHeaders", valid_594336
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594338: Call_DeregisterTaskFromMaintenanceWindow_594326;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Removes a task from a maintenance window.
  ## 
  let valid = call_594338.validator(path, query, header, formData, body)
  let scheme = call_594338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594338.url(scheme.get, call_594338.host, call_594338.base,
                         call_594338.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594338, url, valid)

proc call*(call_594339: Call_DeregisterTaskFromMaintenanceWindow_594326;
          body: JsonNode): Recallable =
  ## deregisterTaskFromMaintenanceWindow
  ## Removes a task from a maintenance window.
  ##   body: JObject (required)
  var body_594340 = newJObject()
  if body != nil:
    body_594340 = body
  result = call_594339.call(nil, nil, nil, nil, body_594340)

var deregisterTaskFromMaintenanceWindow* = Call_DeregisterTaskFromMaintenanceWindow_594326(
    name: "deregisterTaskFromMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeregisterTaskFromMaintenanceWindow",
    validator: validate_DeregisterTaskFromMaintenanceWindow_594327, base: "/",
    url: url_DeregisterTaskFromMaintenanceWindow_594328,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeActivations_594341 = ref object of OpenApiRestCall_593389
proc url_DescribeActivations_594343(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeActivations_594342(path: JsonNode; query: JsonNode;
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
  var valid_594344 = query.getOrDefault("MaxResults")
  valid_594344 = validateParameter(valid_594344, JString, required = false,
                                 default = nil)
  if valid_594344 != nil:
    section.add "MaxResults", valid_594344
  var valid_594345 = query.getOrDefault("NextToken")
  valid_594345 = validateParameter(valid_594345, JString, required = false,
                                 default = nil)
  if valid_594345 != nil:
    section.add "NextToken", valid_594345
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594346 = header.getOrDefault("X-Amz-Target")
  valid_594346 = validateParameter(valid_594346, JString, required = true, default = newJString(
      "AmazonSSM.DescribeActivations"))
  if valid_594346 != nil:
    section.add "X-Amz-Target", valid_594346
  var valid_594347 = header.getOrDefault("X-Amz-Signature")
  valid_594347 = validateParameter(valid_594347, JString, required = false,
                                 default = nil)
  if valid_594347 != nil:
    section.add "X-Amz-Signature", valid_594347
  var valid_594348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594348 = validateParameter(valid_594348, JString, required = false,
                                 default = nil)
  if valid_594348 != nil:
    section.add "X-Amz-Content-Sha256", valid_594348
  var valid_594349 = header.getOrDefault("X-Amz-Date")
  valid_594349 = validateParameter(valid_594349, JString, required = false,
                                 default = nil)
  if valid_594349 != nil:
    section.add "X-Amz-Date", valid_594349
  var valid_594350 = header.getOrDefault("X-Amz-Credential")
  valid_594350 = validateParameter(valid_594350, JString, required = false,
                                 default = nil)
  if valid_594350 != nil:
    section.add "X-Amz-Credential", valid_594350
  var valid_594351 = header.getOrDefault("X-Amz-Security-Token")
  valid_594351 = validateParameter(valid_594351, JString, required = false,
                                 default = nil)
  if valid_594351 != nil:
    section.add "X-Amz-Security-Token", valid_594351
  var valid_594352 = header.getOrDefault("X-Amz-Algorithm")
  valid_594352 = validateParameter(valid_594352, JString, required = false,
                                 default = nil)
  if valid_594352 != nil:
    section.add "X-Amz-Algorithm", valid_594352
  var valid_594353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594353 = validateParameter(valid_594353, JString, required = false,
                                 default = nil)
  if valid_594353 != nil:
    section.add "X-Amz-SignedHeaders", valid_594353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594355: Call_DescribeActivations_594341; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes details about the activation, such as the date and time the activation was created, its expiration date, the IAM role assigned to the instances in the activation, and the number of instances registered by using this activation.
  ## 
  let valid = call_594355.validator(path, query, header, formData, body)
  let scheme = call_594355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594355.url(scheme.get, call_594355.host, call_594355.base,
                         call_594355.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594355, url, valid)

proc call*(call_594356: Call_DescribeActivations_594341; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## describeActivations
  ## Describes details about the activation, such as the date and time the activation was created, its expiration date, the IAM role assigned to the instances in the activation, and the number of instances registered by using this activation.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_594357 = newJObject()
  var body_594358 = newJObject()
  add(query_594357, "MaxResults", newJString(MaxResults))
  add(query_594357, "NextToken", newJString(NextToken))
  if body != nil:
    body_594358 = body
  result = call_594356.call(nil, query_594357, nil, nil, body_594358)

var describeActivations* = Call_DescribeActivations_594341(
    name: "describeActivations", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeActivations",
    validator: validate_DescribeActivations_594342, base: "/",
    url: url_DescribeActivations_594343, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAssociation_594360 = ref object of OpenApiRestCall_593389
proc url_DescribeAssociation_594362(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeAssociation_594361(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594363 = header.getOrDefault("X-Amz-Target")
  valid_594363 = validateParameter(valid_594363, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAssociation"))
  if valid_594363 != nil:
    section.add "X-Amz-Target", valid_594363
  var valid_594364 = header.getOrDefault("X-Amz-Signature")
  valid_594364 = validateParameter(valid_594364, JString, required = false,
                                 default = nil)
  if valid_594364 != nil:
    section.add "X-Amz-Signature", valid_594364
  var valid_594365 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594365 = validateParameter(valid_594365, JString, required = false,
                                 default = nil)
  if valid_594365 != nil:
    section.add "X-Amz-Content-Sha256", valid_594365
  var valid_594366 = header.getOrDefault("X-Amz-Date")
  valid_594366 = validateParameter(valid_594366, JString, required = false,
                                 default = nil)
  if valid_594366 != nil:
    section.add "X-Amz-Date", valid_594366
  var valid_594367 = header.getOrDefault("X-Amz-Credential")
  valid_594367 = validateParameter(valid_594367, JString, required = false,
                                 default = nil)
  if valid_594367 != nil:
    section.add "X-Amz-Credential", valid_594367
  var valid_594368 = header.getOrDefault("X-Amz-Security-Token")
  valid_594368 = validateParameter(valid_594368, JString, required = false,
                                 default = nil)
  if valid_594368 != nil:
    section.add "X-Amz-Security-Token", valid_594368
  var valid_594369 = header.getOrDefault("X-Amz-Algorithm")
  valid_594369 = validateParameter(valid_594369, JString, required = false,
                                 default = nil)
  if valid_594369 != nil:
    section.add "X-Amz-Algorithm", valid_594369
  var valid_594370 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594370 = validateParameter(valid_594370, JString, required = false,
                                 default = nil)
  if valid_594370 != nil:
    section.add "X-Amz-SignedHeaders", valid_594370
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594372: Call_DescribeAssociation_594360; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the association for the specified target or instance. If you created the association by using the <code>Targets</code> parameter, then you must retrieve the association by using the association ID. If you created the association by specifying an instance ID and a Systems Manager document, then you retrieve the association by specifying the document name and the instance ID. 
  ## 
  let valid = call_594372.validator(path, query, header, formData, body)
  let scheme = call_594372.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594372.url(scheme.get, call_594372.host, call_594372.base,
                         call_594372.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594372, url, valid)

proc call*(call_594373: Call_DescribeAssociation_594360; body: JsonNode): Recallable =
  ## describeAssociation
  ## Describes the association for the specified target or instance. If you created the association by using the <code>Targets</code> parameter, then you must retrieve the association by using the association ID. If you created the association by specifying an instance ID and a Systems Manager document, then you retrieve the association by specifying the document name and the instance ID. 
  ##   body: JObject (required)
  var body_594374 = newJObject()
  if body != nil:
    body_594374 = body
  result = call_594373.call(nil, nil, nil, nil, body_594374)

var describeAssociation* = Call_DescribeAssociation_594360(
    name: "describeAssociation", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAssociation",
    validator: validate_DescribeAssociation_594361, base: "/",
    url: url_DescribeAssociation_594362, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAssociationExecutionTargets_594375 = ref object of OpenApiRestCall_593389
proc url_DescribeAssociationExecutionTargets_594377(protocol: Scheme; host: string;
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

proc validate_DescribeAssociationExecutionTargets_594376(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594378 = header.getOrDefault("X-Amz-Target")
  valid_594378 = validateParameter(valid_594378, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAssociationExecutionTargets"))
  if valid_594378 != nil:
    section.add "X-Amz-Target", valid_594378
  var valid_594379 = header.getOrDefault("X-Amz-Signature")
  valid_594379 = validateParameter(valid_594379, JString, required = false,
                                 default = nil)
  if valid_594379 != nil:
    section.add "X-Amz-Signature", valid_594379
  var valid_594380 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594380 = validateParameter(valid_594380, JString, required = false,
                                 default = nil)
  if valid_594380 != nil:
    section.add "X-Amz-Content-Sha256", valid_594380
  var valid_594381 = header.getOrDefault("X-Amz-Date")
  valid_594381 = validateParameter(valid_594381, JString, required = false,
                                 default = nil)
  if valid_594381 != nil:
    section.add "X-Amz-Date", valid_594381
  var valid_594382 = header.getOrDefault("X-Amz-Credential")
  valid_594382 = validateParameter(valid_594382, JString, required = false,
                                 default = nil)
  if valid_594382 != nil:
    section.add "X-Amz-Credential", valid_594382
  var valid_594383 = header.getOrDefault("X-Amz-Security-Token")
  valid_594383 = validateParameter(valid_594383, JString, required = false,
                                 default = nil)
  if valid_594383 != nil:
    section.add "X-Amz-Security-Token", valid_594383
  var valid_594384 = header.getOrDefault("X-Amz-Algorithm")
  valid_594384 = validateParameter(valid_594384, JString, required = false,
                                 default = nil)
  if valid_594384 != nil:
    section.add "X-Amz-Algorithm", valid_594384
  var valid_594385 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594385 = validateParameter(valid_594385, JString, required = false,
                                 default = nil)
  if valid_594385 != nil:
    section.add "X-Amz-SignedHeaders", valid_594385
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594387: Call_DescribeAssociationExecutionTargets_594375;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Use this API action to view information about a specific execution of a specific association.
  ## 
  let valid = call_594387.validator(path, query, header, formData, body)
  let scheme = call_594387.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594387.url(scheme.get, call_594387.host, call_594387.base,
                         call_594387.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594387, url, valid)

proc call*(call_594388: Call_DescribeAssociationExecutionTargets_594375;
          body: JsonNode): Recallable =
  ## describeAssociationExecutionTargets
  ## Use this API action to view information about a specific execution of a specific association.
  ##   body: JObject (required)
  var body_594389 = newJObject()
  if body != nil:
    body_594389 = body
  result = call_594388.call(nil, nil, nil, nil, body_594389)

var describeAssociationExecutionTargets* = Call_DescribeAssociationExecutionTargets_594375(
    name: "describeAssociationExecutionTargets", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAssociationExecutionTargets",
    validator: validate_DescribeAssociationExecutionTargets_594376, base: "/",
    url: url_DescribeAssociationExecutionTargets_594377,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAssociationExecutions_594390 = ref object of OpenApiRestCall_593389
proc url_DescribeAssociationExecutions_594392(protocol: Scheme; host: string;
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

proc validate_DescribeAssociationExecutions_594391(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594393 = header.getOrDefault("X-Amz-Target")
  valid_594393 = validateParameter(valid_594393, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAssociationExecutions"))
  if valid_594393 != nil:
    section.add "X-Amz-Target", valid_594393
  var valid_594394 = header.getOrDefault("X-Amz-Signature")
  valid_594394 = validateParameter(valid_594394, JString, required = false,
                                 default = nil)
  if valid_594394 != nil:
    section.add "X-Amz-Signature", valid_594394
  var valid_594395 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594395 = validateParameter(valid_594395, JString, required = false,
                                 default = nil)
  if valid_594395 != nil:
    section.add "X-Amz-Content-Sha256", valid_594395
  var valid_594396 = header.getOrDefault("X-Amz-Date")
  valid_594396 = validateParameter(valid_594396, JString, required = false,
                                 default = nil)
  if valid_594396 != nil:
    section.add "X-Amz-Date", valid_594396
  var valid_594397 = header.getOrDefault("X-Amz-Credential")
  valid_594397 = validateParameter(valid_594397, JString, required = false,
                                 default = nil)
  if valid_594397 != nil:
    section.add "X-Amz-Credential", valid_594397
  var valid_594398 = header.getOrDefault("X-Amz-Security-Token")
  valid_594398 = validateParameter(valid_594398, JString, required = false,
                                 default = nil)
  if valid_594398 != nil:
    section.add "X-Amz-Security-Token", valid_594398
  var valid_594399 = header.getOrDefault("X-Amz-Algorithm")
  valid_594399 = validateParameter(valid_594399, JString, required = false,
                                 default = nil)
  if valid_594399 != nil:
    section.add "X-Amz-Algorithm", valid_594399
  var valid_594400 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594400 = validateParameter(valid_594400, JString, required = false,
                                 default = nil)
  if valid_594400 != nil:
    section.add "X-Amz-SignedHeaders", valid_594400
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594402: Call_DescribeAssociationExecutions_594390; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Use this API action to view all executions for a specific association ID. 
  ## 
  let valid = call_594402.validator(path, query, header, formData, body)
  let scheme = call_594402.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594402.url(scheme.get, call_594402.host, call_594402.base,
                         call_594402.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594402, url, valid)

proc call*(call_594403: Call_DescribeAssociationExecutions_594390; body: JsonNode): Recallable =
  ## describeAssociationExecutions
  ## Use this API action to view all executions for a specific association ID. 
  ##   body: JObject (required)
  var body_594404 = newJObject()
  if body != nil:
    body_594404 = body
  result = call_594403.call(nil, nil, nil, nil, body_594404)

var describeAssociationExecutions* = Call_DescribeAssociationExecutions_594390(
    name: "describeAssociationExecutions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAssociationExecutions",
    validator: validate_DescribeAssociationExecutions_594391, base: "/",
    url: url_DescribeAssociationExecutions_594392,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAutomationExecutions_594405 = ref object of OpenApiRestCall_593389
proc url_DescribeAutomationExecutions_594407(protocol: Scheme; host: string;
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

proc validate_DescribeAutomationExecutions_594406(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594408 = header.getOrDefault("X-Amz-Target")
  valid_594408 = validateParameter(valid_594408, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAutomationExecutions"))
  if valid_594408 != nil:
    section.add "X-Amz-Target", valid_594408
  var valid_594409 = header.getOrDefault("X-Amz-Signature")
  valid_594409 = validateParameter(valid_594409, JString, required = false,
                                 default = nil)
  if valid_594409 != nil:
    section.add "X-Amz-Signature", valid_594409
  var valid_594410 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594410 = validateParameter(valid_594410, JString, required = false,
                                 default = nil)
  if valid_594410 != nil:
    section.add "X-Amz-Content-Sha256", valid_594410
  var valid_594411 = header.getOrDefault("X-Amz-Date")
  valid_594411 = validateParameter(valid_594411, JString, required = false,
                                 default = nil)
  if valid_594411 != nil:
    section.add "X-Amz-Date", valid_594411
  var valid_594412 = header.getOrDefault("X-Amz-Credential")
  valid_594412 = validateParameter(valid_594412, JString, required = false,
                                 default = nil)
  if valid_594412 != nil:
    section.add "X-Amz-Credential", valid_594412
  var valid_594413 = header.getOrDefault("X-Amz-Security-Token")
  valid_594413 = validateParameter(valid_594413, JString, required = false,
                                 default = nil)
  if valid_594413 != nil:
    section.add "X-Amz-Security-Token", valid_594413
  var valid_594414 = header.getOrDefault("X-Amz-Algorithm")
  valid_594414 = validateParameter(valid_594414, JString, required = false,
                                 default = nil)
  if valid_594414 != nil:
    section.add "X-Amz-Algorithm", valid_594414
  var valid_594415 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594415 = validateParameter(valid_594415, JString, required = false,
                                 default = nil)
  if valid_594415 != nil:
    section.add "X-Amz-SignedHeaders", valid_594415
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594417: Call_DescribeAutomationExecutions_594405; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides details about all active and terminated Automation executions.
  ## 
  let valid = call_594417.validator(path, query, header, formData, body)
  let scheme = call_594417.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594417.url(scheme.get, call_594417.host, call_594417.base,
                         call_594417.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594417, url, valid)

proc call*(call_594418: Call_DescribeAutomationExecutions_594405; body: JsonNode): Recallable =
  ## describeAutomationExecutions
  ## Provides details about all active and terminated Automation executions.
  ##   body: JObject (required)
  var body_594419 = newJObject()
  if body != nil:
    body_594419 = body
  result = call_594418.call(nil, nil, nil, nil, body_594419)

var describeAutomationExecutions* = Call_DescribeAutomationExecutions_594405(
    name: "describeAutomationExecutions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAutomationExecutions",
    validator: validate_DescribeAutomationExecutions_594406, base: "/",
    url: url_DescribeAutomationExecutions_594407,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAutomationStepExecutions_594420 = ref object of OpenApiRestCall_593389
proc url_DescribeAutomationStepExecutions_594422(protocol: Scheme; host: string;
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

proc validate_DescribeAutomationStepExecutions_594421(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594423 = header.getOrDefault("X-Amz-Target")
  valid_594423 = validateParameter(valid_594423, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAutomationStepExecutions"))
  if valid_594423 != nil:
    section.add "X-Amz-Target", valid_594423
  var valid_594424 = header.getOrDefault("X-Amz-Signature")
  valid_594424 = validateParameter(valid_594424, JString, required = false,
                                 default = nil)
  if valid_594424 != nil:
    section.add "X-Amz-Signature", valid_594424
  var valid_594425 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594425 = validateParameter(valid_594425, JString, required = false,
                                 default = nil)
  if valid_594425 != nil:
    section.add "X-Amz-Content-Sha256", valid_594425
  var valid_594426 = header.getOrDefault("X-Amz-Date")
  valid_594426 = validateParameter(valid_594426, JString, required = false,
                                 default = nil)
  if valid_594426 != nil:
    section.add "X-Amz-Date", valid_594426
  var valid_594427 = header.getOrDefault("X-Amz-Credential")
  valid_594427 = validateParameter(valid_594427, JString, required = false,
                                 default = nil)
  if valid_594427 != nil:
    section.add "X-Amz-Credential", valid_594427
  var valid_594428 = header.getOrDefault("X-Amz-Security-Token")
  valid_594428 = validateParameter(valid_594428, JString, required = false,
                                 default = nil)
  if valid_594428 != nil:
    section.add "X-Amz-Security-Token", valid_594428
  var valid_594429 = header.getOrDefault("X-Amz-Algorithm")
  valid_594429 = validateParameter(valid_594429, JString, required = false,
                                 default = nil)
  if valid_594429 != nil:
    section.add "X-Amz-Algorithm", valid_594429
  var valid_594430 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594430 = validateParameter(valid_594430, JString, required = false,
                                 default = nil)
  if valid_594430 != nil:
    section.add "X-Amz-SignedHeaders", valid_594430
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594432: Call_DescribeAutomationStepExecutions_594420;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Information about all active and terminated step executions in an Automation workflow.
  ## 
  let valid = call_594432.validator(path, query, header, formData, body)
  let scheme = call_594432.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594432.url(scheme.get, call_594432.host, call_594432.base,
                         call_594432.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594432, url, valid)

proc call*(call_594433: Call_DescribeAutomationStepExecutions_594420;
          body: JsonNode): Recallable =
  ## describeAutomationStepExecutions
  ## Information about all active and terminated step executions in an Automation workflow.
  ##   body: JObject (required)
  var body_594434 = newJObject()
  if body != nil:
    body_594434 = body
  result = call_594433.call(nil, nil, nil, nil, body_594434)

var describeAutomationStepExecutions* = Call_DescribeAutomationStepExecutions_594420(
    name: "describeAutomationStepExecutions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAutomationStepExecutions",
    validator: validate_DescribeAutomationStepExecutions_594421, base: "/",
    url: url_DescribeAutomationStepExecutions_594422,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAvailablePatches_594435 = ref object of OpenApiRestCall_593389
proc url_DescribeAvailablePatches_594437(protocol: Scheme; host: string;
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

proc validate_DescribeAvailablePatches_594436(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594438 = header.getOrDefault("X-Amz-Target")
  valid_594438 = validateParameter(valid_594438, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAvailablePatches"))
  if valid_594438 != nil:
    section.add "X-Amz-Target", valid_594438
  var valid_594439 = header.getOrDefault("X-Amz-Signature")
  valid_594439 = validateParameter(valid_594439, JString, required = false,
                                 default = nil)
  if valid_594439 != nil:
    section.add "X-Amz-Signature", valid_594439
  var valid_594440 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594440 = validateParameter(valid_594440, JString, required = false,
                                 default = nil)
  if valid_594440 != nil:
    section.add "X-Amz-Content-Sha256", valid_594440
  var valid_594441 = header.getOrDefault("X-Amz-Date")
  valid_594441 = validateParameter(valid_594441, JString, required = false,
                                 default = nil)
  if valid_594441 != nil:
    section.add "X-Amz-Date", valid_594441
  var valid_594442 = header.getOrDefault("X-Amz-Credential")
  valid_594442 = validateParameter(valid_594442, JString, required = false,
                                 default = nil)
  if valid_594442 != nil:
    section.add "X-Amz-Credential", valid_594442
  var valid_594443 = header.getOrDefault("X-Amz-Security-Token")
  valid_594443 = validateParameter(valid_594443, JString, required = false,
                                 default = nil)
  if valid_594443 != nil:
    section.add "X-Amz-Security-Token", valid_594443
  var valid_594444 = header.getOrDefault("X-Amz-Algorithm")
  valid_594444 = validateParameter(valid_594444, JString, required = false,
                                 default = nil)
  if valid_594444 != nil:
    section.add "X-Amz-Algorithm", valid_594444
  var valid_594445 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594445 = validateParameter(valid_594445, JString, required = false,
                                 default = nil)
  if valid_594445 != nil:
    section.add "X-Amz-SignedHeaders", valid_594445
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594447: Call_DescribeAvailablePatches_594435; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all patches eligible to be included in a patch baseline.
  ## 
  let valid = call_594447.validator(path, query, header, formData, body)
  let scheme = call_594447.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594447.url(scheme.get, call_594447.host, call_594447.base,
                         call_594447.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594447, url, valid)

proc call*(call_594448: Call_DescribeAvailablePatches_594435; body: JsonNode): Recallable =
  ## describeAvailablePatches
  ## Lists all patches eligible to be included in a patch baseline.
  ##   body: JObject (required)
  var body_594449 = newJObject()
  if body != nil:
    body_594449 = body
  result = call_594448.call(nil, nil, nil, nil, body_594449)

var describeAvailablePatches* = Call_DescribeAvailablePatches_594435(
    name: "describeAvailablePatches", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAvailablePatches",
    validator: validate_DescribeAvailablePatches_594436, base: "/",
    url: url_DescribeAvailablePatches_594437, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDocument_594450 = ref object of OpenApiRestCall_593389
proc url_DescribeDocument_594452(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeDocument_594451(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594453 = header.getOrDefault("X-Amz-Target")
  valid_594453 = validateParameter(valid_594453, JString, required = true, default = newJString(
      "AmazonSSM.DescribeDocument"))
  if valid_594453 != nil:
    section.add "X-Amz-Target", valid_594453
  var valid_594454 = header.getOrDefault("X-Amz-Signature")
  valid_594454 = validateParameter(valid_594454, JString, required = false,
                                 default = nil)
  if valid_594454 != nil:
    section.add "X-Amz-Signature", valid_594454
  var valid_594455 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594455 = validateParameter(valid_594455, JString, required = false,
                                 default = nil)
  if valid_594455 != nil:
    section.add "X-Amz-Content-Sha256", valid_594455
  var valid_594456 = header.getOrDefault("X-Amz-Date")
  valid_594456 = validateParameter(valid_594456, JString, required = false,
                                 default = nil)
  if valid_594456 != nil:
    section.add "X-Amz-Date", valid_594456
  var valid_594457 = header.getOrDefault("X-Amz-Credential")
  valid_594457 = validateParameter(valid_594457, JString, required = false,
                                 default = nil)
  if valid_594457 != nil:
    section.add "X-Amz-Credential", valid_594457
  var valid_594458 = header.getOrDefault("X-Amz-Security-Token")
  valid_594458 = validateParameter(valid_594458, JString, required = false,
                                 default = nil)
  if valid_594458 != nil:
    section.add "X-Amz-Security-Token", valid_594458
  var valid_594459 = header.getOrDefault("X-Amz-Algorithm")
  valid_594459 = validateParameter(valid_594459, JString, required = false,
                                 default = nil)
  if valid_594459 != nil:
    section.add "X-Amz-Algorithm", valid_594459
  var valid_594460 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594460 = validateParameter(valid_594460, JString, required = false,
                                 default = nil)
  if valid_594460 != nil:
    section.add "X-Amz-SignedHeaders", valid_594460
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594462: Call_DescribeDocument_594450; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified Systems Manager document.
  ## 
  let valid = call_594462.validator(path, query, header, formData, body)
  let scheme = call_594462.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594462.url(scheme.get, call_594462.host, call_594462.base,
                         call_594462.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594462, url, valid)

proc call*(call_594463: Call_DescribeDocument_594450; body: JsonNode): Recallable =
  ## describeDocument
  ## Describes the specified Systems Manager document.
  ##   body: JObject (required)
  var body_594464 = newJObject()
  if body != nil:
    body_594464 = body
  result = call_594463.call(nil, nil, nil, nil, body_594464)

var describeDocument* = Call_DescribeDocument_594450(name: "describeDocument",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeDocument",
    validator: validate_DescribeDocument_594451, base: "/",
    url: url_DescribeDocument_594452, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDocumentPermission_594465 = ref object of OpenApiRestCall_593389
proc url_DescribeDocumentPermission_594467(protocol: Scheme; host: string;
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

proc validate_DescribeDocumentPermission_594466(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594468 = header.getOrDefault("X-Amz-Target")
  valid_594468 = validateParameter(valid_594468, JString, required = true, default = newJString(
      "AmazonSSM.DescribeDocumentPermission"))
  if valid_594468 != nil:
    section.add "X-Amz-Target", valid_594468
  var valid_594469 = header.getOrDefault("X-Amz-Signature")
  valid_594469 = validateParameter(valid_594469, JString, required = false,
                                 default = nil)
  if valid_594469 != nil:
    section.add "X-Amz-Signature", valid_594469
  var valid_594470 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594470 = validateParameter(valid_594470, JString, required = false,
                                 default = nil)
  if valid_594470 != nil:
    section.add "X-Amz-Content-Sha256", valid_594470
  var valid_594471 = header.getOrDefault("X-Amz-Date")
  valid_594471 = validateParameter(valid_594471, JString, required = false,
                                 default = nil)
  if valid_594471 != nil:
    section.add "X-Amz-Date", valid_594471
  var valid_594472 = header.getOrDefault("X-Amz-Credential")
  valid_594472 = validateParameter(valid_594472, JString, required = false,
                                 default = nil)
  if valid_594472 != nil:
    section.add "X-Amz-Credential", valid_594472
  var valid_594473 = header.getOrDefault("X-Amz-Security-Token")
  valid_594473 = validateParameter(valid_594473, JString, required = false,
                                 default = nil)
  if valid_594473 != nil:
    section.add "X-Amz-Security-Token", valid_594473
  var valid_594474 = header.getOrDefault("X-Amz-Algorithm")
  valid_594474 = validateParameter(valid_594474, JString, required = false,
                                 default = nil)
  if valid_594474 != nil:
    section.add "X-Amz-Algorithm", valid_594474
  var valid_594475 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594475 = validateParameter(valid_594475, JString, required = false,
                                 default = nil)
  if valid_594475 != nil:
    section.add "X-Amz-SignedHeaders", valid_594475
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594477: Call_DescribeDocumentPermission_594465; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the permissions for a Systems Manager document. If you created the document, you are the owner. If a document is shared, it can either be shared privately (by specifying a user's AWS account ID) or publicly (<i>All</i>). 
  ## 
  let valid = call_594477.validator(path, query, header, formData, body)
  let scheme = call_594477.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594477.url(scheme.get, call_594477.host, call_594477.base,
                         call_594477.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594477, url, valid)

proc call*(call_594478: Call_DescribeDocumentPermission_594465; body: JsonNode): Recallable =
  ## describeDocumentPermission
  ## Describes the permissions for a Systems Manager document. If you created the document, you are the owner. If a document is shared, it can either be shared privately (by specifying a user's AWS account ID) or publicly (<i>All</i>). 
  ##   body: JObject (required)
  var body_594479 = newJObject()
  if body != nil:
    body_594479 = body
  result = call_594478.call(nil, nil, nil, nil, body_594479)

var describeDocumentPermission* = Call_DescribeDocumentPermission_594465(
    name: "describeDocumentPermission", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeDocumentPermission",
    validator: validate_DescribeDocumentPermission_594466, base: "/",
    url: url_DescribeDocumentPermission_594467,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEffectiveInstanceAssociations_594480 = ref object of OpenApiRestCall_593389
proc url_DescribeEffectiveInstanceAssociations_594482(protocol: Scheme;
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

proc validate_DescribeEffectiveInstanceAssociations_594481(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594483 = header.getOrDefault("X-Amz-Target")
  valid_594483 = validateParameter(valid_594483, JString, required = true, default = newJString(
      "AmazonSSM.DescribeEffectiveInstanceAssociations"))
  if valid_594483 != nil:
    section.add "X-Amz-Target", valid_594483
  var valid_594484 = header.getOrDefault("X-Amz-Signature")
  valid_594484 = validateParameter(valid_594484, JString, required = false,
                                 default = nil)
  if valid_594484 != nil:
    section.add "X-Amz-Signature", valid_594484
  var valid_594485 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594485 = validateParameter(valid_594485, JString, required = false,
                                 default = nil)
  if valid_594485 != nil:
    section.add "X-Amz-Content-Sha256", valid_594485
  var valid_594486 = header.getOrDefault("X-Amz-Date")
  valid_594486 = validateParameter(valid_594486, JString, required = false,
                                 default = nil)
  if valid_594486 != nil:
    section.add "X-Amz-Date", valid_594486
  var valid_594487 = header.getOrDefault("X-Amz-Credential")
  valid_594487 = validateParameter(valid_594487, JString, required = false,
                                 default = nil)
  if valid_594487 != nil:
    section.add "X-Amz-Credential", valid_594487
  var valid_594488 = header.getOrDefault("X-Amz-Security-Token")
  valid_594488 = validateParameter(valid_594488, JString, required = false,
                                 default = nil)
  if valid_594488 != nil:
    section.add "X-Amz-Security-Token", valid_594488
  var valid_594489 = header.getOrDefault("X-Amz-Algorithm")
  valid_594489 = validateParameter(valid_594489, JString, required = false,
                                 default = nil)
  if valid_594489 != nil:
    section.add "X-Amz-Algorithm", valid_594489
  var valid_594490 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594490 = validateParameter(valid_594490, JString, required = false,
                                 default = nil)
  if valid_594490 != nil:
    section.add "X-Amz-SignedHeaders", valid_594490
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594492: Call_DescribeEffectiveInstanceAssociations_594480;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## All associations for the instance(s).
  ## 
  let valid = call_594492.validator(path, query, header, formData, body)
  let scheme = call_594492.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594492.url(scheme.get, call_594492.host, call_594492.base,
                         call_594492.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594492, url, valid)

proc call*(call_594493: Call_DescribeEffectiveInstanceAssociations_594480;
          body: JsonNode): Recallable =
  ## describeEffectiveInstanceAssociations
  ## All associations for the instance(s).
  ##   body: JObject (required)
  var body_594494 = newJObject()
  if body != nil:
    body_594494 = body
  result = call_594493.call(nil, nil, nil, nil, body_594494)

var describeEffectiveInstanceAssociations* = Call_DescribeEffectiveInstanceAssociations_594480(
    name: "describeEffectiveInstanceAssociations", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeEffectiveInstanceAssociations",
    validator: validate_DescribeEffectiveInstanceAssociations_594481, base: "/",
    url: url_DescribeEffectiveInstanceAssociations_594482,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEffectivePatchesForPatchBaseline_594495 = ref object of OpenApiRestCall_593389
proc url_DescribeEffectivePatchesForPatchBaseline_594497(protocol: Scheme;
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

proc validate_DescribeEffectivePatchesForPatchBaseline_594496(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594498 = header.getOrDefault("X-Amz-Target")
  valid_594498 = validateParameter(valid_594498, JString, required = true, default = newJString(
      "AmazonSSM.DescribeEffectivePatchesForPatchBaseline"))
  if valid_594498 != nil:
    section.add "X-Amz-Target", valid_594498
  var valid_594499 = header.getOrDefault("X-Amz-Signature")
  valid_594499 = validateParameter(valid_594499, JString, required = false,
                                 default = nil)
  if valid_594499 != nil:
    section.add "X-Amz-Signature", valid_594499
  var valid_594500 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594500 = validateParameter(valid_594500, JString, required = false,
                                 default = nil)
  if valid_594500 != nil:
    section.add "X-Amz-Content-Sha256", valid_594500
  var valid_594501 = header.getOrDefault("X-Amz-Date")
  valid_594501 = validateParameter(valid_594501, JString, required = false,
                                 default = nil)
  if valid_594501 != nil:
    section.add "X-Amz-Date", valid_594501
  var valid_594502 = header.getOrDefault("X-Amz-Credential")
  valid_594502 = validateParameter(valid_594502, JString, required = false,
                                 default = nil)
  if valid_594502 != nil:
    section.add "X-Amz-Credential", valid_594502
  var valid_594503 = header.getOrDefault("X-Amz-Security-Token")
  valid_594503 = validateParameter(valid_594503, JString, required = false,
                                 default = nil)
  if valid_594503 != nil:
    section.add "X-Amz-Security-Token", valid_594503
  var valid_594504 = header.getOrDefault("X-Amz-Algorithm")
  valid_594504 = validateParameter(valid_594504, JString, required = false,
                                 default = nil)
  if valid_594504 != nil:
    section.add "X-Amz-Algorithm", valid_594504
  var valid_594505 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594505 = validateParameter(valid_594505, JString, required = false,
                                 default = nil)
  if valid_594505 != nil:
    section.add "X-Amz-SignedHeaders", valid_594505
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594507: Call_DescribeEffectivePatchesForPatchBaseline_594495;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the current effective patches (the patch and the approval state) for the specified patch baseline. Note that this API applies only to Windows patch baselines.
  ## 
  let valid = call_594507.validator(path, query, header, formData, body)
  let scheme = call_594507.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594507.url(scheme.get, call_594507.host, call_594507.base,
                         call_594507.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594507, url, valid)

proc call*(call_594508: Call_DescribeEffectivePatchesForPatchBaseline_594495;
          body: JsonNode): Recallable =
  ## describeEffectivePatchesForPatchBaseline
  ## Retrieves the current effective patches (the patch and the approval state) for the specified patch baseline. Note that this API applies only to Windows patch baselines.
  ##   body: JObject (required)
  var body_594509 = newJObject()
  if body != nil:
    body_594509 = body
  result = call_594508.call(nil, nil, nil, nil, body_594509)

var describeEffectivePatchesForPatchBaseline* = Call_DescribeEffectivePatchesForPatchBaseline_594495(
    name: "describeEffectivePatchesForPatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeEffectivePatchesForPatchBaseline",
    validator: validate_DescribeEffectivePatchesForPatchBaseline_594496,
    base: "/", url: url_DescribeEffectivePatchesForPatchBaseline_594497,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInstanceAssociationsStatus_594510 = ref object of OpenApiRestCall_593389
proc url_DescribeInstanceAssociationsStatus_594512(protocol: Scheme; host: string;
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

proc validate_DescribeInstanceAssociationsStatus_594511(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594513 = header.getOrDefault("X-Amz-Target")
  valid_594513 = validateParameter(valid_594513, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInstanceAssociationsStatus"))
  if valid_594513 != nil:
    section.add "X-Amz-Target", valid_594513
  var valid_594514 = header.getOrDefault("X-Amz-Signature")
  valid_594514 = validateParameter(valid_594514, JString, required = false,
                                 default = nil)
  if valid_594514 != nil:
    section.add "X-Amz-Signature", valid_594514
  var valid_594515 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594515 = validateParameter(valid_594515, JString, required = false,
                                 default = nil)
  if valid_594515 != nil:
    section.add "X-Amz-Content-Sha256", valid_594515
  var valid_594516 = header.getOrDefault("X-Amz-Date")
  valid_594516 = validateParameter(valid_594516, JString, required = false,
                                 default = nil)
  if valid_594516 != nil:
    section.add "X-Amz-Date", valid_594516
  var valid_594517 = header.getOrDefault("X-Amz-Credential")
  valid_594517 = validateParameter(valid_594517, JString, required = false,
                                 default = nil)
  if valid_594517 != nil:
    section.add "X-Amz-Credential", valid_594517
  var valid_594518 = header.getOrDefault("X-Amz-Security-Token")
  valid_594518 = validateParameter(valid_594518, JString, required = false,
                                 default = nil)
  if valid_594518 != nil:
    section.add "X-Amz-Security-Token", valid_594518
  var valid_594519 = header.getOrDefault("X-Amz-Algorithm")
  valid_594519 = validateParameter(valid_594519, JString, required = false,
                                 default = nil)
  if valid_594519 != nil:
    section.add "X-Amz-Algorithm", valid_594519
  var valid_594520 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594520 = validateParameter(valid_594520, JString, required = false,
                                 default = nil)
  if valid_594520 != nil:
    section.add "X-Amz-SignedHeaders", valid_594520
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594522: Call_DescribeInstanceAssociationsStatus_594510;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## The status of the associations for the instance(s).
  ## 
  let valid = call_594522.validator(path, query, header, formData, body)
  let scheme = call_594522.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594522.url(scheme.get, call_594522.host, call_594522.base,
                         call_594522.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594522, url, valid)

proc call*(call_594523: Call_DescribeInstanceAssociationsStatus_594510;
          body: JsonNode): Recallable =
  ## describeInstanceAssociationsStatus
  ## The status of the associations for the instance(s).
  ##   body: JObject (required)
  var body_594524 = newJObject()
  if body != nil:
    body_594524 = body
  result = call_594523.call(nil, nil, nil, nil, body_594524)

var describeInstanceAssociationsStatus* = Call_DescribeInstanceAssociationsStatus_594510(
    name: "describeInstanceAssociationsStatus", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInstanceAssociationsStatus",
    validator: validate_DescribeInstanceAssociationsStatus_594511, base: "/",
    url: url_DescribeInstanceAssociationsStatus_594512,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInstanceInformation_594525 = ref object of OpenApiRestCall_593389
proc url_DescribeInstanceInformation_594527(protocol: Scheme; host: string;
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

proc validate_DescribeInstanceInformation_594526(path: JsonNode; query: JsonNode;
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
  var valid_594528 = query.getOrDefault("MaxResults")
  valid_594528 = validateParameter(valid_594528, JString, required = false,
                                 default = nil)
  if valid_594528 != nil:
    section.add "MaxResults", valid_594528
  var valid_594529 = query.getOrDefault("NextToken")
  valid_594529 = validateParameter(valid_594529, JString, required = false,
                                 default = nil)
  if valid_594529 != nil:
    section.add "NextToken", valid_594529
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594530 = header.getOrDefault("X-Amz-Target")
  valid_594530 = validateParameter(valid_594530, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInstanceInformation"))
  if valid_594530 != nil:
    section.add "X-Amz-Target", valid_594530
  var valid_594531 = header.getOrDefault("X-Amz-Signature")
  valid_594531 = validateParameter(valid_594531, JString, required = false,
                                 default = nil)
  if valid_594531 != nil:
    section.add "X-Amz-Signature", valid_594531
  var valid_594532 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594532 = validateParameter(valid_594532, JString, required = false,
                                 default = nil)
  if valid_594532 != nil:
    section.add "X-Amz-Content-Sha256", valid_594532
  var valid_594533 = header.getOrDefault("X-Amz-Date")
  valid_594533 = validateParameter(valid_594533, JString, required = false,
                                 default = nil)
  if valid_594533 != nil:
    section.add "X-Amz-Date", valid_594533
  var valid_594534 = header.getOrDefault("X-Amz-Credential")
  valid_594534 = validateParameter(valid_594534, JString, required = false,
                                 default = nil)
  if valid_594534 != nil:
    section.add "X-Amz-Credential", valid_594534
  var valid_594535 = header.getOrDefault("X-Amz-Security-Token")
  valid_594535 = validateParameter(valid_594535, JString, required = false,
                                 default = nil)
  if valid_594535 != nil:
    section.add "X-Amz-Security-Token", valid_594535
  var valid_594536 = header.getOrDefault("X-Amz-Algorithm")
  valid_594536 = validateParameter(valid_594536, JString, required = false,
                                 default = nil)
  if valid_594536 != nil:
    section.add "X-Amz-Algorithm", valid_594536
  var valid_594537 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594537 = validateParameter(valid_594537, JString, required = false,
                                 default = nil)
  if valid_594537 != nil:
    section.add "X-Amz-SignedHeaders", valid_594537
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594539: Call_DescribeInstanceInformation_594525; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes one or more of your instances. You can use this to get information about instances like the operating system platform, the SSM Agent version (Linux), status etc. If you specify one or more instance IDs, it returns information for those instances. If you do not specify instance IDs, it returns information for all your instances. If you specify an instance ID that is not valid or an instance that you do not own, you receive an error. </p> <note> <p>The IamRole field for this API action is the Amazon Identity and Access Management (IAM) role assigned to on-premises instances. This call does not return the IAM role for Amazon EC2 instances.</p> </note>
  ## 
  let valid = call_594539.validator(path, query, header, formData, body)
  let scheme = call_594539.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594539.url(scheme.get, call_594539.host, call_594539.base,
                         call_594539.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594539, url, valid)

proc call*(call_594540: Call_DescribeInstanceInformation_594525; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## describeInstanceInformation
  ## <p>Describes one or more of your instances. You can use this to get information about instances like the operating system platform, the SSM Agent version (Linux), status etc. If you specify one or more instance IDs, it returns information for those instances. If you do not specify instance IDs, it returns information for all your instances. If you specify an instance ID that is not valid or an instance that you do not own, you receive an error. </p> <note> <p>The IamRole field for this API action is the Amazon Identity and Access Management (IAM) role assigned to on-premises instances. This call does not return the IAM role for Amazon EC2 instances.</p> </note>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_594541 = newJObject()
  var body_594542 = newJObject()
  add(query_594541, "MaxResults", newJString(MaxResults))
  add(query_594541, "NextToken", newJString(NextToken))
  if body != nil:
    body_594542 = body
  result = call_594540.call(nil, query_594541, nil, nil, body_594542)

var describeInstanceInformation* = Call_DescribeInstanceInformation_594525(
    name: "describeInstanceInformation", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInstanceInformation",
    validator: validate_DescribeInstanceInformation_594526, base: "/",
    url: url_DescribeInstanceInformation_594527,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInstancePatchStates_594543 = ref object of OpenApiRestCall_593389
proc url_DescribeInstancePatchStates_594545(protocol: Scheme; host: string;
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

proc validate_DescribeInstancePatchStates_594544(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594546 = header.getOrDefault("X-Amz-Target")
  valid_594546 = validateParameter(valid_594546, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInstancePatchStates"))
  if valid_594546 != nil:
    section.add "X-Amz-Target", valid_594546
  var valid_594547 = header.getOrDefault("X-Amz-Signature")
  valid_594547 = validateParameter(valid_594547, JString, required = false,
                                 default = nil)
  if valid_594547 != nil:
    section.add "X-Amz-Signature", valid_594547
  var valid_594548 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594548 = validateParameter(valid_594548, JString, required = false,
                                 default = nil)
  if valid_594548 != nil:
    section.add "X-Amz-Content-Sha256", valid_594548
  var valid_594549 = header.getOrDefault("X-Amz-Date")
  valid_594549 = validateParameter(valid_594549, JString, required = false,
                                 default = nil)
  if valid_594549 != nil:
    section.add "X-Amz-Date", valid_594549
  var valid_594550 = header.getOrDefault("X-Amz-Credential")
  valid_594550 = validateParameter(valid_594550, JString, required = false,
                                 default = nil)
  if valid_594550 != nil:
    section.add "X-Amz-Credential", valid_594550
  var valid_594551 = header.getOrDefault("X-Amz-Security-Token")
  valid_594551 = validateParameter(valid_594551, JString, required = false,
                                 default = nil)
  if valid_594551 != nil:
    section.add "X-Amz-Security-Token", valid_594551
  var valid_594552 = header.getOrDefault("X-Amz-Algorithm")
  valid_594552 = validateParameter(valid_594552, JString, required = false,
                                 default = nil)
  if valid_594552 != nil:
    section.add "X-Amz-Algorithm", valid_594552
  var valid_594553 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594553 = validateParameter(valid_594553, JString, required = false,
                                 default = nil)
  if valid_594553 != nil:
    section.add "X-Amz-SignedHeaders", valid_594553
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594555: Call_DescribeInstancePatchStates_594543; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the high-level patch state of one or more instances.
  ## 
  let valid = call_594555.validator(path, query, header, formData, body)
  let scheme = call_594555.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594555.url(scheme.get, call_594555.host, call_594555.base,
                         call_594555.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594555, url, valid)

proc call*(call_594556: Call_DescribeInstancePatchStates_594543; body: JsonNode): Recallable =
  ## describeInstancePatchStates
  ## Retrieves the high-level patch state of one or more instances.
  ##   body: JObject (required)
  var body_594557 = newJObject()
  if body != nil:
    body_594557 = body
  result = call_594556.call(nil, nil, nil, nil, body_594557)

var describeInstancePatchStates* = Call_DescribeInstancePatchStates_594543(
    name: "describeInstancePatchStates", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInstancePatchStates",
    validator: validate_DescribeInstancePatchStates_594544, base: "/",
    url: url_DescribeInstancePatchStates_594545,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInstancePatchStatesForPatchGroup_594558 = ref object of OpenApiRestCall_593389
proc url_DescribeInstancePatchStatesForPatchGroup_594560(protocol: Scheme;
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

proc validate_DescribeInstancePatchStatesForPatchGroup_594559(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594561 = header.getOrDefault("X-Amz-Target")
  valid_594561 = validateParameter(valid_594561, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInstancePatchStatesForPatchGroup"))
  if valid_594561 != nil:
    section.add "X-Amz-Target", valid_594561
  var valid_594562 = header.getOrDefault("X-Amz-Signature")
  valid_594562 = validateParameter(valid_594562, JString, required = false,
                                 default = nil)
  if valid_594562 != nil:
    section.add "X-Amz-Signature", valid_594562
  var valid_594563 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594563 = validateParameter(valid_594563, JString, required = false,
                                 default = nil)
  if valid_594563 != nil:
    section.add "X-Amz-Content-Sha256", valid_594563
  var valid_594564 = header.getOrDefault("X-Amz-Date")
  valid_594564 = validateParameter(valid_594564, JString, required = false,
                                 default = nil)
  if valid_594564 != nil:
    section.add "X-Amz-Date", valid_594564
  var valid_594565 = header.getOrDefault("X-Amz-Credential")
  valid_594565 = validateParameter(valid_594565, JString, required = false,
                                 default = nil)
  if valid_594565 != nil:
    section.add "X-Amz-Credential", valid_594565
  var valid_594566 = header.getOrDefault("X-Amz-Security-Token")
  valid_594566 = validateParameter(valid_594566, JString, required = false,
                                 default = nil)
  if valid_594566 != nil:
    section.add "X-Amz-Security-Token", valid_594566
  var valid_594567 = header.getOrDefault("X-Amz-Algorithm")
  valid_594567 = validateParameter(valid_594567, JString, required = false,
                                 default = nil)
  if valid_594567 != nil:
    section.add "X-Amz-Algorithm", valid_594567
  var valid_594568 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594568 = validateParameter(valid_594568, JString, required = false,
                                 default = nil)
  if valid_594568 != nil:
    section.add "X-Amz-SignedHeaders", valid_594568
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594570: Call_DescribeInstancePatchStatesForPatchGroup_594558;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the high-level patch state for the instances in the specified patch group.
  ## 
  let valid = call_594570.validator(path, query, header, formData, body)
  let scheme = call_594570.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594570.url(scheme.get, call_594570.host, call_594570.base,
                         call_594570.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594570, url, valid)

proc call*(call_594571: Call_DescribeInstancePatchStatesForPatchGroup_594558;
          body: JsonNode): Recallable =
  ## describeInstancePatchStatesForPatchGroup
  ## Retrieves the high-level patch state for the instances in the specified patch group.
  ##   body: JObject (required)
  var body_594572 = newJObject()
  if body != nil:
    body_594572 = body
  result = call_594571.call(nil, nil, nil, nil, body_594572)

var describeInstancePatchStatesForPatchGroup* = Call_DescribeInstancePatchStatesForPatchGroup_594558(
    name: "describeInstancePatchStatesForPatchGroup", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInstancePatchStatesForPatchGroup",
    validator: validate_DescribeInstancePatchStatesForPatchGroup_594559,
    base: "/", url: url_DescribeInstancePatchStatesForPatchGroup_594560,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInstancePatches_594573 = ref object of OpenApiRestCall_593389
proc url_DescribeInstancePatches_594575(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeInstancePatches_594574(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594576 = header.getOrDefault("X-Amz-Target")
  valid_594576 = validateParameter(valid_594576, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInstancePatches"))
  if valid_594576 != nil:
    section.add "X-Amz-Target", valid_594576
  var valid_594577 = header.getOrDefault("X-Amz-Signature")
  valid_594577 = validateParameter(valid_594577, JString, required = false,
                                 default = nil)
  if valid_594577 != nil:
    section.add "X-Amz-Signature", valid_594577
  var valid_594578 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594578 = validateParameter(valid_594578, JString, required = false,
                                 default = nil)
  if valid_594578 != nil:
    section.add "X-Amz-Content-Sha256", valid_594578
  var valid_594579 = header.getOrDefault("X-Amz-Date")
  valid_594579 = validateParameter(valid_594579, JString, required = false,
                                 default = nil)
  if valid_594579 != nil:
    section.add "X-Amz-Date", valid_594579
  var valid_594580 = header.getOrDefault("X-Amz-Credential")
  valid_594580 = validateParameter(valid_594580, JString, required = false,
                                 default = nil)
  if valid_594580 != nil:
    section.add "X-Amz-Credential", valid_594580
  var valid_594581 = header.getOrDefault("X-Amz-Security-Token")
  valid_594581 = validateParameter(valid_594581, JString, required = false,
                                 default = nil)
  if valid_594581 != nil:
    section.add "X-Amz-Security-Token", valid_594581
  var valid_594582 = header.getOrDefault("X-Amz-Algorithm")
  valid_594582 = validateParameter(valid_594582, JString, required = false,
                                 default = nil)
  if valid_594582 != nil:
    section.add "X-Amz-Algorithm", valid_594582
  var valid_594583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594583 = validateParameter(valid_594583, JString, required = false,
                                 default = nil)
  if valid_594583 != nil:
    section.add "X-Amz-SignedHeaders", valid_594583
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594585: Call_DescribeInstancePatches_594573; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the patches on the specified instance and their state relative to the patch baseline being used for the instance.
  ## 
  let valid = call_594585.validator(path, query, header, formData, body)
  let scheme = call_594585.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594585.url(scheme.get, call_594585.host, call_594585.base,
                         call_594585.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594585, url, valid)

proc call*(call_594586: Call_DescribeInstancePatches_594573; body: JsonNode): Recallable =
  ## describeInstancePatches
  ## Retrieves information about the patches on the specified instance and their state relative to the patch baseline being used for the instance.
  ##   body: JObject (required)
  var body_594587 = newJObject()
  if body != nil:
    body_594587 = body
  result = call_594586.call(nil, nil, nil, nil, body_594587)

var describeInstancePatches* = Call_DescribeInstancePatches_594573(
    name: "describeInstancePatches", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInstancePatches",
    validator: validate_DescribeInstancePatches_594574, base: "/",
    url: url_DescribeInstancePatches_594575, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInventoryDeletions_594588 = ref object of OpenApiRestCall_593389
proc url_DescribeInventoryDeletions_594590(protocol: Scheme; host: string;
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

proc validate_DescribeInventoryDeletions_594589(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594591 = header.getOrDefault("X-Amz-Target")
  valid_594591 = validateParameter(valid_594591, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInventoryDeletions"))
  if valid_594591 != nil:
    section.add "X-Amz-Target", valid_594591
  var valid_594592 = header.getOrDefault("X-Amz-Signature")
  valid_594592 = validateParameter(valid_594592, JString, required = false,
                                 default = nil)
  if valid_594592 != nil:
    section.add "X-Amz-Signature", valid_594592
  var valid_594593 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594593 = validateParameter(valid_594593, JString, required = false,
                                 default = nil)
  if valid_594593 != nil:
    section.add "X-Amz-Content-Sha256", valid_594593
  var valid_594594 = header.getOrDefault("X-Amz-Date")
  valid_594594 = validateParameter(valid_594594, JString, required = false,
                                 default = nil)
  if valid_594594 != nil:
    section.add "X-Amz-Date", valid_594594
  var valid_594595 = header.getOrDefault("X-Amz-Credential")
  valid_594595 = validateParameter(valid_594595, JString, required = false,
                                 default = nil)
  if valid_594595 != nil:
    section.add "X-Amz-Credential", valid_594595
  var valid_594596 = header.getOrDefault("X-Amz-Security-Token")
  valid_594596 = validateParameter(valid_594596, JString, required = false,
                                 default = nil)
  if valid_594596 != nil:
    section.add "X-Amz-Security-Token", valid_594596
  var valid_594597 = header.getOrDefault("X-Amz-Algorithm")
  valid_594597 = validateParameter(valid_594597, JString, required = false,
                                 default = nil)
  if valid_594597 != nil:
    section.add "X-Amz-Algorithm", valid_594597
  var valid_594598 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594598 = validateParameter(valid_594598, JString, required = false,
                                 default = nil)
  if valid_594598 != nil:
    section.add "X-Amz-SignedHeaders", valid_594598
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594600: Call_DescribeInventoryDeletions_594588; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a specific delete inventory operation.
  ## 
  let valid = call_594600.validator(path, query, header, formData, body)
  let scheme = call_594600.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594600.url(scheme.get, call_594600.host, call_594600.base,
                         call_594600.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594600, url, valid)

proc call*(call_594601: Call_DescribeInventoryDeletions_594588; body: JsonNode): Recallable =
  ## describeInventoryDeletions
  ## Describes a specific delete inventory operation.
  ##   body: JObject (required)
  var body_594602 = newJObject()
  if body != nil:
    body_594602 = body
  result = call_594601.call(nil, nil, nil, nil, body_594602)

var describeInventoryDeletions* = Call_DescribeInventoryDeletions_594588(
    name: "describeInventoryDeletions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInventoryDeletions",
    validator: validate_DescribeInventoryDeletions_594589, base: "/",
    url: url_DescribeInventoryDeletions_594590,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowExecutionTaskInvocations_594603 = ref object of OpenApiRestCall_593389
proc url_DescribeMaintenanceWindowExecutionTaskInvocations_594605(
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

proc validate_DescribeMaintenanceWindowExecutionTaskInvocations_594604(
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594606 = header.getOrDefault("X-Amz-Target")
  valid_594606 = validateParameter(valid_594606, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowExecutionTaskInvocations"))
  if valid_594606 != nil:
    section.add "X-Amz-Target", valid_594606
  var valid_594607 = header.getOrDefault("X-Amz-Signature")
  valid_594607 = validateParameter(valid_594607, JString, required = false,
                                 default = nil)
  if valid_594607 != nil:
    section.add "X-Amz-Signature", valid_594607
  var valid_594608 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594608 = validateParameter(valid_594608, JString, required = false,
                                 default = nil)
  if valid_594608 != nil:
    section.add "X-Amz-Content-Sha256", valid_594608
  var valid_594609 = header.getOrDefault("X-Amz-Date")
  valid_594609 = validateParameter(valid_594609, JString, required = false,
                                 default = nil)
  if valid_594609 != nil:
    section.add "X-Amz-Date", valid_594609
  var valid_594610 = header.getOrDefault("X-Amz-Credential")
  valid_594610 = validateParameter(valid_594610, JString, required = false,
                                 default = nil)
  if valid_594610 != nil:
    section.add "X-Amz-Credential", valid_594610
  var valid_594611 = header.getOrDefault("X-Amz-Security-Token")
  valid_594611 = validateParameter(valid_594611, JString, required = false,
                                 default = nil)
  if valid_594611 != nil:
    section.add "X-Amz-Security-Token", valid_594611
  var valid_594612 = header.getOrDefault("X-Amz-Algorithm")
  valid_594612 = validateParameter(valid_594612, JString, required = false,
                                 default = nil)
  if valid_594612 != nil:
    section.add "X-Amz-Algorithm", valid_594612
  var valid_594613 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594613 = validateParameter(valid_594613, JString, required = false,
                                 default = nil)
  if valid_594613 != nil:
    section.add "X-Amz-SignedHeaders", valid_594613
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594615: Call_DescribeMaintenanceWindowExecutionTaskInvocations_594603;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the individual task executions (one per target) for a particular task run as part of a maintenance window execution.
  ## 
  let valid = call_594615.validator(path, query, header, formData, body)
  let scheme = call_594615.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594615.url(scheme.get, call_594615.host, call_594615.base,
                         call_594615.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594615, url, valid)

proc call*(call_594616: Call_DescribeMaintenanceWindowExecutionTaskInvocations_594603;
          body: JsonNode): Recallable =
  ## describeMaintenanceWindowExecutionTaskInvocations
  ## Retrieves the individual task executions (one per target) for a particular task run as part of a maintenance window execution.
  ##   body: JObject (required)
  var body_594617 = newJObject()
  if body != nil:
    body_594617 = body
  result = call_594616.call(nil, nil, nil, nil, body_594617)

var describeMaintenanceWindowExecutionTaskInvocations* = Call_DescribeMaintenanceWindowExecutionTaskInvocations_594603(
    name: "describeMaintenanceWindowExecutionTaskInvocations",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com", route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowExecutionTaskInvocations",
    validator: validate_DescribeMaintenanceWindowExecutionTaskInvocations_594604,
    base: "/", url: url_DescribeMaintenanceWindowExecutionTaskInvocations_594605,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowExecutionTasks_594618 = ref object of OpenApiRestCall_593389
proc url_DescribeMaintenanceWindowExecutionTasks_594620(protocol: Scheme;
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

proc validate_DescribeMaintenanceWindowExecutionTasks_594619(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594621 = header.getOrDefault("X-Amz-Target")
  valid_594621 = validateParameter(valid_594621, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowExecutionTasks"))
  if valid_594621 != nil:
    section.add "X-Amz-Target", valid_594621
  var valid_594622 = header.getOrDefault("X-Amz-Signature")
  valid_594622 = validateParameter(valid_594622, JString, required = false,
                                 default = nil)
  if valid_594622 != nil:
    section.add "X-Amz-Signature", valid_594622
  var valid_594623 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594623 = validateParameter(valid_594623, JString, required = false,
                                 default = nil)
  if valid_594623 != nil:
    section.add "X-Amz-Content-Sha256", valid_594623
  var valid_594624 = header.getOrDefault("X-Amz-Date")
  valid_594624 = validateParameter(valid_594624, JString, required = false,
                                 default = nil)
  if valid_594624 != nil:
    section.add "X-Amz-Date", valid_594624
  var valid_594625 = header.getOrDefault("X-Amz-Credential")
  valid_594625 = validateParameter(valid_594625, JString, required = false,
                                 default = nil)
  if valid_594625 != nil:
    section.add "X-Amz-Credential", valid_594625
  var valid_594626 = header.getOrDefault("X-Amz-Security-Token")
  valid_594626 = validateParameter(valid_594626, JString, required = false,
                                 default = nil)
  if valid_594626 != nil:
    section.add "X-Amz-Security-Token", valid_594626
  var valid_594627 = header.getOrDefault("X-Amz-Algorithm")
  valid_594627 = validateParameter(valid_594627, JString, required = false,
                                 default = nil)
  if valid_594627 != nil:
    section.add "X-Amz-Algorithm", valid_594627
  var valid_594628 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594628 = validateParameter(valid_594628, JString, required = false,
                                 default = nil)
  if valid_594628 != nil:
    section.add "X-Amz-SignedHeaders", valid_594628
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594630: Call_DescribeMaintenanceWindowExecutionTasks_594618;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## For a given maintenance window execution, lists the tasks that were run.
  ## 
  let valid = call_594630.validator(path, query, header, formData, body)
  let scheme = call_594630.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594630.url(scheme.get, call_594630.host, call_594630.base,
                         call_594630.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594630, url, valid)

proc call*(call_594631: Call_DescribeMaintenanceWindowExecutionTasks_594618;
          body: JsonNode): Recallable =
  ## describeMaintenanceWindowExecutionTasks
  ## For a given maintenance window execution, lists the tasks that were run.
  ##   body: JObject (required)
  var body_594632 = newJObject()
  if body != nil:
    body_594632 = body
  result = call_594631.call(nil, nil, nil, nil, body_594632)

var describeMaintenanceWindowExecutionTasks* = Call_DescribeMaintenanceWindowExecutionTasks_594618(
    name: "describeMaintenanceWindowExecutionTasks", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowExecutionTasks",
    validator: validate_DescribeMaintenanceWindowExecutionTasks_594619, base: "/",
    url: url_DescribeMaintenanceWindowExecutionTasks_594620,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowExecutions_594633 = ref object of OpenApiRestCall_593389
proc url_DescribeMaintenanceWindowExecutions_594635(protocol: Scheme; host: string;
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

proc validate_DescribeMaintenanceWindowExecutions_594634(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594636 = header.getOrDefault("X-Amz-Target")
  valid_594636 = validateParameter(valid_594636, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowExecutions"))
  if valid_594636 != nil:
    section.add "X-Amz-Target", valid_594636
  var valid_594637 = header.getOrDefault("X-Amz-Signature")
  valid_594637 = validateParameter(valid_594637, JString, required = false,
                                 default = nil)
  if valid_594637 != nil:
    section.add "X-Amz-Signature", valid_594637
  var valid_594638 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594638 = validateParameter(valid_594638, JString, required = false,
                                 default = nil)
  if valid_594638 != nil:
    section.add "X-Amz-Content-Sha256", valid_594638
  var valid_594639 = header.getOrDefault("X-Amz-Date")
  valid_594639 = validateParameter(valid_594639, JString, required = false,
                                 default = nil)
  if valid_594639 != nil:
    section.add "X-Amz-Date", valid_594639
  var valid_594640 = header.getOrDefault("X-Amz-Credential")
  valid_594640 = validateParameter(valid_594640, JString, required = false,
                                 default = nil)
  if valid_594640 != nil:
    section.add "X-Amz-Credential", valid_594640
  var valid_594641 = header.getOrDefault("X-Amz-Security-Token")
  valid_594641 = validateParameter(valid_594641, JString, required = false,
                                 default = nil)
  if valid_594641 != nil:
    section.add "X-Amz-Security-Token", valid_594641
  var valid_594642 = header.getOrDefault("X-Amz-Algorithm")
  valid_594642 = validateParameter(valid_594642, JString, required = false,
                                 default = nil)
  if valid_594642 != nil:
    section.add "X-Amz-Algorithm", valid_594642
  var valid_594643 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594643 = validateParameter(valid_594643, JString, required = false,
                                 default = nil)
  if valid_594643 != nil:
    section.add "X-Amz-SignedHeaders", valid_594643
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594645: Call_DescribeMaintenanceWindowExecutions_594633;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the executions of a maintenance window. This includes information about when the maintenance window was scheduled to be active, and information about tasks registered and run with the maintenance window.
  ## 
  let valid = call_594645.validator(path, query, header, formData, body)
  let scheme = call_594645.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594645.url(scheme.get, call_594645.host, call_594645.base,
                         call_594645.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594645, url, valid)

proc call*(call_594646: Call_DescribeMaintenanceWindowExecutions_594633;
          body: JsonNode): Recallable =
  ## describeMaintenanceWindowExecutions
  ## Lists the executions of a maintenance window. This includes information about when the maintenance window was scheduled to be active, and information about tasks registered and run with the maintenance window.
  ##   body: JObject (required)
  var body_594647 = newJObject()
  if body != nil:
    body_594647 = body
  result = call_594646.call(nil, nil, nil, nil, body_594647)

var describeMaintenanceWindowExecutions* = Call_DescribeMaintenanceWindowExecutions_594633(
    name: "describeMaintenanceWindowExecutions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowExecutions",
    validator: validate_DescribeMaintenanceWindowExecutions_594634, base: "/",
    url: url_DescribeMaintenanceWindowExecutions_594635,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowSchedule_594648 = ref object of OpenApiRestCall_593389
proc url_DescribeMaintenanceWindowSchedule_594650(protocol: Scheme; host: string;
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

proc validate_DescribeMaintenanceWindowSchedule_594649(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594651 = header.getOrDefault("X-Amz-Target")
  valid_594651 = validateParameter(valid_594651, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowSchedule"))
  if valid_594651 != nil:
    section.add "X-Amz-Target", valid_594651
  var valid_594652 = header.getOrDefault("X-Amz-Signature")
  valid_594652 = validateParameter(valid_594652, JString, required = false,
                                 default = nil)
  if valid_594652 != nil:
    section.add "X-Amz-Signature", valid_594652
  var valid_594653 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594653 = validateParameter(valid_594653, JString, required = false,
                                 default = nil)
  if valid_594653 != nil:
    section.add "X-Amz-Content-Sha256", valid_594653
  var valid_594654 = header.getOrDefault("X-Amz-Date")
  valid_594654 = validateParameter(valid_594654, JString, required = false,
                                 default = nil)
  if valid_594654 != nil:
    section.add "X-Amz-Date", valid_594654
  var valid_594655 = header.getOrDefault("X-Amz-Credential")
  valid_594655 = validateParameter(valid_594655, JString, required = false,
                                 default = nil)
  if valid_594655 != nil:
    section.add "X-Amz-Credential", valid_594655
  var valid_594656 = header.getOrDefault("X-Amz-Security-Token")
  valid_594656 = validateParameter(valid_594656, JString, required = false,
                                 default = nil)
  if valid_594656 != nil:
    section.add "X-Amz-Security-Token", valid_594656
  var valid_594657 = header.getOrDefault("X-Amz-Algorithm")
  valid_594657 = validateParameter(valid_594657, JString, required = false,
                                 default = nil)
  if valid_594657 != nil:
    section.add "X-Amz-Algorithm", valid_594657
  var valid_594658 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594658 = validateParameter(valid_594658, JString, required = false,
                                 default = nil)
  if valid_594658 != nil:
    section.add "X-Amz-SignedHeaders", valid_594658
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594660: Call_DescribeMaintenanceWindowSchedule_594648;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves information about upcoming executions of a maintenance window.
  ## 
  let valid = call_594660.validator(path, query, header, formData, body)
  let scheme = call_594660.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594660.url(scheme.get, call_594660.host, call_594660.base,
                         call_594660.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594660, url, valid)

proc call*(call_594661: Call_DescribeMaintenanceWindowSchedule_594648;
          body: JsonNode): Recallable =
  ## describeMaintenanceWindowSchedule
  ## Retrieves information about upcoming executions of a maintenance window.
  ##   body: JObject (required)
  var body_594662 = newJObject()
  if body != nil:
    body_594662 = body
  result = call_594661.call(nil, nil, nil, nil, body_594662)

var describeMaintenanceWindowSchedule* = Call_DescribeMaintenanceWindowSchedule_594648(
    name: "describeMaintenanceWindowSchedule", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowSchedule",
    validator: validate_DescribeMaintenanceWindowSchedule_594649, base: "/",
    url: url_DescribeMaintenanceWindowSchedule_594650,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowTargets_594663 = ref object of OpenApiRestCall_593389
proc url_DescribeMaintenanceWindowTargets_594665(protocol: Scheme; host: string;
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

proc validate_DescribeMaintenanceWindowTargets_594664(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594666 = header.getOrDefault("X-Amz-Target")
  valid_594666 = validateParameter(valid_594666, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowTargets"))
  if valid_594666 != nil:
    section.add "X-Amz-Target", valid_594666
  var valid_594667 = header.getOrDefault("X-Amz-Signature")
  valid_594667 = validateParameter(valid_594667, JString, required = false,
                                 default = nil)
  if valid_594667 != nil:
    section.add "X-Amz-Signature", valid_594667
  var valid_594668 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594668 = validateParameter(valid_594668, JString, required = false,
                                 default = nil)
  if valid_594668 != nil:
    section.add "X-Amz-Content-Sha256", valid_594668
  var valid_594669 = header.getOrDefault("X-Amz-Date")
  valid_594669 = validateParameter(valid_594669, JString, required = false,
                                 default = nil)
  if valid_594669 != nil:
    section.add "X-Amz-Date", valid_594669
  var valid_594670 = header.getOrDefault("X-Amz-Credential")
  valid_594670 = validateParameter(valid_594670, JString, required = false,
                                 default = nil)
  if valid_594670 != nil:
    section.add "X-Amz-Credential", valid_594670
  var valid_594671 = header.getOrDefault("X-Amz-Security-Token")
  valid_594671 = validateParameter(valid_594671, JString, required = false,
                                 default = nil)
  if valid_594671 != nil:
    section.add "X-Amz-Security-Token", valid_594671
  var valid_594672 = header.getOrDefault("X-Amz-Algorithm")
  valid_594672 = validateParameter(valid_594672, JString, required = false,
                                 default = nil)
  if valid_594672 != nil:
    section.add "X-Amz-Algorithm", valid_594672
  var valid_594673 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594673 = validateParameter(valid_594673, JString, required = false,
                                 default = nil)
  if valid_594673 != nil:
    section.add "X-Amz-SignedHeaders", valid_594673
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594675: Call_DescribeMaintenanceWindowTargets_594663;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the targets registered with the maintenance window.
  ## 
  let valid = call_594675.validator(path, query, header, formData, body)
  let scheme = call_594675.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594675.url(scheme.get, call_594675.host, call_594675.base,
                         call_594675.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594675, url, valid)

proc call*(call_594676: Call_DescribeMaintenanceWindowTargets_594663;
          body: JsonNode): Recallable =
  ## describeMaintenanceWindowTargets
  ## Lists the targets registered with the maintenance window.
  ##   body: JObject (required)
  var body_594677 = newJObject()
  if body != nil:
    body_594677 = body
  result = call_594676.call(nil, nil, nil, nil, body_594677)

var describeMaintenanceWindowTargets* = Call_DescribeMaintenanceWindowTargets_594663(
    name: "describeMaintenanceWindowTargets", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowTargets",
    validator: validate_DescribeMaintenanceWindowTargets_594664, base: "/",
    url: url_DescribeMaintenanceWindowTargets_594665,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowTasks_594678 = ref object of OpenApiRestCall_593389
proc url_DescribeMaintenanceWindowTasks_594680(protocol: Scheme; host: string;
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

proc validate_DescribeMaintenanceWindowTasks_594679(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594681 = header.getOrDefault("X-Amz-Target")
  valid_594681 = validateParameter(valid_594681, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowTasks"))
  if valid_594681 != nil:
    section.add "X-Amz-Target", valid_594681
  var valid_594682 = header.getOrDefault("X-Amz-Signature")
  valid_594682 = validateParameter(valid_594682, JString, required = false,
                                 default = nil)
  if valid_594682 != nil:
    section.add "X-Amz-Signature", valid_594682
  var valid_594683 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594683 = validateParameter(valid_594683, JString, required = false,
                                 default = nil)
  if valid_594683 != nil:
    section.add "X-Amz-Content-Sha256", valid_594683
  var valid_594684 = header.getOrDefault("X-Amz-Date")
  valid_594684 = validateParameter(valid_594684, JString, required = false,
                                 default = nil)
  if valid_594684 != nil:
    section.add "X-Amz-Date", valid_594684
  var valid_594685 = header.getOrDefault("X-Amz-Credential")
  valid_594685 = validateParameter(valid_594685, JString, required = false,
                                 default = nil)
  if valid_594685 != nil:
    section.add "X-Amz-Credential", valid_594685
  var valid_594686 = header.getOrDefault("X-Amz-Security-Token")
  valid_594686 = validateParameter(valid_594686, JString, required = false,
                                 default = nil)
  if valid_594686 != nil:
    section.add "X-Amz-Security-Token", valid_594686
  var valid_594687 = header.getOrDefault("X-Amz-Algorithm")
  valid_594687 = validateParameter(valid_594687, JString, required = false,
                                 default = nil)
  if valid_594687 != nil:
    section.add "X-Amz-Algorithm", valid_594687
  var valid_594688 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594688 = validateParameter(valid_594688, JString, required = false,
                                 default = nil)
  if valid_594688 != nil:
    section.add "X-Amz-SignedHeaders", valid_594688
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594690: Call_DescribeMaintenanceWindowTasks_594678; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tasks in a maintenance window.
  ## 
  let valid = call_594690.validator(path, query, header, formData, body)
  let scheme = call_594690.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594690.url(scheme.get, call_594690.host, call_594690.base,
                         call_594690.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594690, url, valid)

proc call*(call_594691: Call_DescribeMaintenanceWindowTasks_594678; body: JsonNode): Recallable =
  ## describeMaintenanceWindowTasks
  ## Lists the tasks in a maintenance window.
  ##   body: JObject (required)
  var body_594692 = newJObject()
  if body != nil:
    body_594692 = body
  result = call_594691.call(nil, nil, nil, nil, body_594692)

var describeMaintenanceWindowTasks* = Call_DescribeMaintenanceWindowTasks_594678(
    name: "describeMaintenanceWindowTasks", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowTasks",
    validator: validate_DescribeMaintenanceWindowTasks_594679, base: "/",
    url: url_DescribeMaintenanceWindowTasks_594680,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindows_594693 = ref object of OpenApiRestCall_593389
proc url_DescribeMaintenanceWindows_594695(protocol: Scheme; host: string;
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

proc validate_DescribeMaintenanceWindows_594694(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594696 = header.getOrDefault("X-Amz-Target")
  valid_594696 = validateParameter(valid_594696, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindows"))
  if valid_594696 != nil:
    section.add "X-Amz-Target", valid_594696
  var valid_594697 = header.getOrDefault("X-Amz-Signature")
  valid_594697 = validateParameter(valid_594697, JString, required = false,
                                 default = nil)
  if valid_594697 != nil:
    section.add "X-Amz-Signature", valid_594697
  var valid_594698 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594698 = validateParameter(valid_594698, JString, required = false,
                                 default = nil)
  if valid_594698 != nil:
    section.add "X-Amz-Content-Sha256", valid_594698
  var valid_594699 = header.getOrDefault("X-Amz-Date")
  valid_594699 = validateParameter(valid_594699, JString, required = false,
                                 default = nil)
  if valid_594699 != nil:
    section.add "X-Amz-Date", valid_594699
  var valid_594700 = header.getOrDefault("X-Amz-Credential")
  valid_594700 = validateParameter(valid_594700, JString, required = false,
                                 default = nil)
  if valid_594700 != nil:
    section.add "X-Amz-Credential", valid_594700
  var valid_594701 = header.getOrDefault("X-Amz-Security-Token")
  valid_594701 = validateParameter(valid_594701, JString, required = false,
                                 default = nil)
  if valid_594701 != nil:
    section.add "X-Amz-Security-Token", valid_594701
  var valid_594702 = header.getOrDefault("X-Amz-Algorithm")
  valid_594702 = validateParameter(valid_594702, JString, required = false,
                                 default = nil)
  if valid_594702 != nil:
    section.add "X-Amz-Algorithm", valid_594702
  var valid_594703 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594703 = validateParameter(valid_594703, JString, required = false,
                                 default = nil)
  if valid_594703 != nil:
    section.add "X-Amz-SignedHeaders", valid_594703
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594705: Call_DescribeMaintenanceWindows_594693; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the maintenance windows in an AWS account.
  ## 
  let valid = call_594705.validator(path, query, header, formData, body)
  let scheme = call_594705.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594705.url(scheme.get, call_594705.host, call_594705.base,
                         call_594705.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594705, url, valid)

proc call*(call_594706: Call_DescribeMaintenanceWindows_594693; body: JsonNode): Recallable =
  ## describeMaintenanceWindows
  ## Retrieves the maintenance windows in an AWS account.
  ##   body: JObject (required)
  var body_594707 = newJObject()
  if body != nil:
    body_594707 = body
  result = call_594706.call(nil, nil, nil, nil, body_594707)

var describeMaintenanceWindows* = Call_DescribeMaintenanceWindows_594693(
    name: "describeMaintenanceWindows", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindows",
    validator: validate_DescribeMaintenanceWindows_594694, base: "/",
    url: url_DescribeMaintenanceWindows_594695,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowsForTarget_594708 = ref object of OpenApiRestCall_593389
proc url_DescribeMaintenanceWindowsForTarget_594710(protocol: Scheme; host: string;
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

proc validate_DescribeMaintenanceWindowsForTarget_594709(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594711 = header.getOrDefault("X-Amz-Target")
  valid_594711 = validateParameter(valid_594711, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowsForTarget"))
  if valid_594711 != nil:
    section.add "X-Amz-Target", valid_594711
  var valid_594712 = header.getOrDefault("X-Amz-Signature")
  valid_594712 = validateParameter(valid_594712, JString, required = false,
                                 default = nil)
  if valid_594712 != nil:
    section.add "X-Amz-Signature", valid_594712
  var valid_594713 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594713 = validateParameter(valid_594713, JString, required = false,
                                 default = nil)
  if valid_594713 != nil:
    section.add "X-Amz-Content-Sha256", valid_594713
  var valid_594714 = header.getOrDefault("X-Amz-Date")
  valid_594714 = validateParameter(valid_594714, JString, required = false,
                                 default = nil)
  if valid_594714 != nil:
    section.add "X-Amz-Date", valid_594714
  var valid_594715 = header.getOrDefault("X-Amz-Credential")
  valid_594715 = validateParameter(valid_594715, JString, required = false,
                                 default = nil)
  if valid_594715 != nil:
    section.add "X-Amz-Credential", valid_594715
  var valid_594716 = header.getOrDefault("X-Amz-Security-Token")
  valid_594716 = validateParameter(valid_594716, JString, required = false,
                                 default = nil)
  if valid_594716 != nil:
    section.add "X-Amz-Security-Token", valid_594716
  var valid_594717 = header.getOrDefault("X-Amz-Algorithm")
  valid_594717 = validateParameter(valid_594717, JString, required = false,
                                 default = nil)
  if valid_594717 != nil:
    section.add "X-Amz-Algorithm", valid_594717
  var valid_594718 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594718 = validateParameter(valid_594718, JString, required = false,
                                 default = nil)
  if valid_594718 != nil:
    section.add "X-Amz-SignedHeaders", valid_594718
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594720: Call_DescribeMaintenanceWindowsForTarget_594708;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves information about the maintenance window targets or tasks that an instance is associated with.
  ## 
  let valid = call_594720.validator(path, query, header, formData, body)
  let scheme = call_594720.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594720.url(scheme.get, call_594720.host, call_594720.base,
                         call_594720.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594720, url, valid)

proc call*(call_594721: Call_DescribeMaintenanceWindowsForTarget_594708;
          body: JsonNode): Recallable =
  ## describeMaintenanceWindowsForTarget
  ## Retrieves information about the maintenance window targets or tasks that an instance is associated with.
  ##   body: JObject (required)
  var body_594722 = newJObject()
  if body != nil:
    body_594722 = body
  result = call_594721.call(nil, nil, nil, nil, body_594722)

var describeMaintenanceWindowsForTarget* = Call_DescribeMaintenanceWindowsForTarget_594708(
    name: "describeMaintenanceWindowsForTarget", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowsForTarget",
    validator: validate_DescribeMaintenanceWindowsForTarget_594709, base: "/",
    url: url_DescribeMaintenanceWindowsForTarget_594710,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeOpsItems_594723 = ref object of OpenApiRestCall_593389
proc url_DescribeOpsItems_594725(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeOpsItems_594724(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594726 = header.getOrDefault("X-Amz-Target")
  valid_594726 = validateParameter(valid_594726, JString, required = true, default = newJString(
      "AmazonSSM.DescribeOpsItems"))
  if valid_594726 != nil:
    section.add "X-Amz-Target", valid_594726
  var valid_594727 = header.getOrDefault("X-Amz-Signature")
  valid_594727 = validateParameter(valid_594727, JString, required = false,
                                 default = nil)
  if valid_594727 != nil:
    section.add "X-Amz-Signature", valid_594727
  var valid_594728 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594728 = validateParameter(valid_594728, JString, required = false,
                                 default = nil)
  if valid_594728 != nil:
    section.add "X-Amz-Content-Sha256", valid_594728
  var valid_594729 = header.getOrDefault("X-Amz-Date")
  valid_594729 = validateParameter(valid_594729, JString, required = false,
                                 default = nil)
  if valid_594729 != nil:
    section.add "X-Amz-Date", valid_594729
  var valid_594730 = header.getOrDefault("X-Amz-Credential")
  valid_594730 = validateParameter(valid_594730, JString, required = false,
                                 default = nil)
  if valid_594730 != nil:
    section.add "X-Amz-Credential", valid_594730
  var valid_594731 = header.getOrDefault("X-Amz-Security-Token")
  valid_594731 = validateParameter(valid_594731, JString, required = false,
                                 default = nil)
  if valid_594731 != nil:
    section.add "X-Amz-Security-Token", valid_594731
  var valid_594732 = header.getOrDefault("X-Amz-Algorithm")
  valid_594732 = validateParameter(valid_594732, JString, required = false,
                                 default = nil)
  if valid_594732 != nil:
    section.add "X-Amz-Algorithm", valid_594732
  var valid_594733 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594733 = validateParameter(valid_594733, JString, required = false,
                                 default = nil)
  if valid_594733 != nil:
    section.add "X-Amz-SignedHeaders", valid_594733
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594735: Call_DescribeOpsItems_594723; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Query a set of OpsItems. You must have permission in AWS Identity and Access Management (IAM) to query a list of OpsItems. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ## 
  let valid = call_594735.validator(path, query, header, formData, body)
  let scheme = call_594735.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594735.url(scheme.get, call_594735.host, call_594735.base,
                         call_594735.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594735, url, valid)

proc call*(call_594736: Call_DescribeOpsItems_594723; body: JsonNode): Recallable =
  ## describeOpsItems
  ## <p>Query a set of OpsItems. You must have permission in AWS Identity and Access Management (IAM) to query a list of OpsItems. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ##   body: JObject (required)
  var body_594737 = newJObject()
  if body != nil:
    body_594737 = body
  result = call_594736.call(nil, nil, nil, nil, body_594737)

var describeOpsItems* = Call_DescribeOpsItems_594723(name: "describeOpsItems",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeOpsItems",
    validator: validate_DescribeOpsItems_594724, base: "/",
    url: url_DescribeOpsItems_594725, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeParameters_594738 = ref object of OpenApiRestCall_593389
proc url_DescribeParameters_594740(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeParameters_594739(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Get information about a parameter.</p> <p>Request results are returned on a best-effort basis. If you specify <code>MaxResults</code> in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of <code>MaxResults</code>. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a <code>NextToken</code>. You can specify the <code>NextToken</code> in a subsequent call to get the next set of results.</p>
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
  var valid_594741 = query.getOrDefault("MaxResults")
  valid_594741 = validateParameter(valid_594741, JString, required = false,
                                 default = nil)
  if valid_594741 != nil:
    section.add "MaxResults", valid_594741
  var valid_594742 = query.getOrDefault("NextToken")
  valid_594742 = validateParameter(valid_594742, JString, required = false,
                                 default = nil)
  if valid_594742 != nil:
    section.add "NextToken", valid_594742
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594743 = header.getOrDefault("X-Amz-Target")
  valid_594743 = validateParameter(valid_594743, JString, required = true, default = newJString(
      "AmazonSSM.DescribeParameters"))
  if valid_594743 != nil:
    section.add "X-Amz-Target", valid_594743
  var valid_594744 = header.getOrDefault("X-Amz-Signature")
  valid_594744 = validateParameter(valid_594744, JString, required = false,
                                 default = nil)
  if valid_594744 != nil:
    section.add "X-Amz-Signature", valid_594744
  var valid_594745 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594745 = validateParameter(valid_594745, JString, required = false,
                                 default = nil)
  if valid_594745 != nil:
    section.add "X-Amz-Content-Sha256", valid_594745
  var valid_594746 = header.getOrDefault("X-Amz-Date")
  valid_594746 = validateParameter(valid_594746, JString, required = false,
                                 default = nil)
  if valid_594746 != nil:
    section.add "X-Amz-Date", valid_594746
  var valid_594747 = header.getOrDefault("X-Amz-Credential")
  valid_594747 = validateParameter(valid_594747, JString, required = false,
                                 default = nil)
  if valid_594747 != nil:
    section.add "X-Amz-Credential", valid_594747
  var valid_594748 = header.getOrDefault("X-Amz-Security-Token")
  valid_594748 = validateParameter(valid_594748, JString, required = false,
                                 default = nil)
  if valid_594748 != nil:
    section.add "X-Amz-Security-Token", valid_594748
  var valid_594749 = header.getOrDefault("X-Amz-Algorithm")
  valid_594749 = validateParameter(valid_594749, JString, required = false,
                                 default = nil)
  if valid_594749 != nil:
    section.add "X-Amz-Algorithm", valid_594749
  var valid_594750 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594750 = validateParameter(valid_594750, JString, required = false,
                                 default = nil)
  if valid_594750 != nil:
    section.add "X-Amz-SignedHeaders", valid_594750
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594752: Call_DescribeParameters_594738; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Get information about a parameter.</p> <p>Request results are returned on a best-effort basis. If you specify <code>MaxResults</code> in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of <code>MaxResults</code>. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a <code>NextToken</code>. You can specify the <code>NextToken</code> in a subsequent call to get the next set of results.</p>
  ## 
  let valid = call_594752.validator(path, query, header, formData, body)
  let scheme = call_594752.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594752.url(scheme.get, call_594752.host, call_594752.base,
                         call_594752.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594752, url, valid)

proc call*(call_594753: Call_DescribeParameters_594738; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## describeParameters
  ## <p>Get information about a parameter.</p> <p>Request results are returned on a best-effort basis. If you specify <code>MaxResults</code> in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of <code>MaxResults</code>. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a <code>NextToken</code>. You can specify the <code>NextToken</code> in a subsequent call to get the next set of results.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_594754 = newJObject()
  var body_594755 = newJObject()
  add(query_594754, "MaxResults", newJString(MaxResults))
  add(query_594754, "NextToken", newJString(NextToken))
  if body != nil:
    body_594755 = body
  result = call_594753.call(nil, query_594754, nil, nil, body_594755)

var describeParameters* = Call_DescribeParameters_594738(
    name: "describeParameters", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeParameters",
    validator: validate_DescribeParameters_594739, base: "/",
    url: url_DescribeParameters_594740, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePatchBaselines_594756 = ref object of OpenApiRestCall_593389
proc url_DescribePatchBaselines_594758(protocol: Scheme; host: string; base: string;
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

proc validate_DescribePatchBaselines_594757(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594759 = header.getOrDefault("X-Amz-Target")
  valid_594759 = validateParameter(valid_594759, JString, required = true, default = newJString(
      "AmazonSSM.DescribePatchBaselines"))
  if valid_594759 != nil:
    section.add "X-Amz-Target", valid_594759
  var valid_594760 = header.getOrDefault("X-Amz-Signature")
  valid_594760 = validateParameter(valid_594760, JString, required = false,
                                 default = nil)
  if valid_594760 != nil:
    section.add "X-Amz-Signature", valid_594760
  var valid_594761 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594761 = validateParameter(valid_594761, JString, required = false,
                                 default = nil)
  if valid_594761 != nil:
    section.add "X-Amz-Content-Sha256", valid_594761
  var valid_594762 = header.getOrDefault("X-Amz-Date")
  valid_594762 = validateParameter(valid_594762, JString, required = false,
                                 default = nil)
  if valid_594762 != nil:
    section.add "X-Amz-Date", valid_594762
  var valid_594763 = header.getOrDefault("X-Amz-Credential")
  valid_594763 = validateParameter(valid_594763, JString, required = false,
                                 default = nil)
  if valid_594763 != nil:
    section.add "X-Amz-Credential", valid_594763
  var valid_594764 = header.getOrDefault("X-Amz-Security-Token")
  valid_594764 = validateParameter(valid_594764, JString, required = false,
                                 default = nil)
  if valid_594764 != nil:
    section.add "X-Amz-Security-Token", valid_594764
  var valid_594765 = header.getOrDefault("X-Amz-Algorithm")
  valid_594765 = validateParameter(valid_594765, JString, required = false,
                                 default = nil)
  if valid_594765 != nil:
    section.add "X-Amz-Algorithm", valid_594765
  var valid_594766 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594766 = validateParameter(valid_594766, JString, required = false,
                                 default = nil)
  if valid_594766 != nil:
    section.add "X-Amz-SignedHeaders", valid_594766
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594768: Call_DescribePatchBaselines_594756; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the patch baselines in your AWS account.
  ## 
  let valid = call_594768.validator(path, query, header, formData, body)
  let scheme = call_594768.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594768.url(scheme.get, call_594768.host, call_594768.base,
                         call_594768.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594768, url, valid)

proc call*(call_594769: Call_DescribePatchBaselines_594756; body: JsonNode): Recallable =
  ## describePatchBaselines
  ## Lists the patch baselines in your AWS account.
  ##   body: JObject (required)
  var body_594770 = newJObject()
  if body != nil:
    body_594770 = body
  result = call_594769.call(nil, nil, nil, nil, body_594770)

var describePatchBaselines* = Call_DescribePatchBaselines_594756(
    name: "describePatchBaselines", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribePatchBaselines",
    validator: validate_DescribePatchBaselines_594757, base: "/",
    url: url_DescribePatchBaselines_594758, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePatchGroupState_594771 = ref object of OpenApiRestCall_593389
proc url_DescribePatchGroupState_594773(protocol: Scheme; host: string; base: string;
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

proc validate_DescribePatchGroupState_594772(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594774 = header.getOrDefault("X-Amz-Target")
  valid_594774 = validateParameter(valid_594774, JString, required = true, default = newJString(
      "AmazonSSM.DescribePatchGroupState"))
  if valid_594774 != nil:
    section.add "X-Amz-Target", valid_594774
  var valid_594775 = header.getOrDefault("X-Amz-Signature")
  valid_594775 = validateParameter(valid_594775, JString, required = false,
                                 default = nil)
  if valid_594775 != nil:
    section.add "X-Amz-Signature", valid_594775
  var valid_594776 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594776 = validateParameter(valid_594776, JString, required = false,
                                 default = nil)
  if valid_594776 != nil:
    section.add "X-Amz-Content-Sha256", valid_594776
  var valid_594777 = header.getOrDefault("X-Amz-Date")
  valid_594777 = validateParameter(valid_594777, JString, required = false,
                                 default = nil)
  if valid_594777 != nil:
    section.add "X-Amz-Date", valid_594777
  var valid_594778 = header.getOrDefault("X-Amz-Credential")
  valid_594778 = validateParameter(valid_594778, JString, required = false,
                                 default = nil)
  if valid_594778 != nil:
    section.add "X-Amz-Credential", valid_594778
  var valid_594779 = header.getOrDefault("X-Amz-Security-Token")
  valid_594779 = validateParameter(valid_594779, JString, required = false,
                                 default = nil)
  if valid_594779 != nil:
    section.add "X-Amz-Security-Token", valid_594779
  var valid_594780 = header.getOrDefault("X-Amz-Algorithm")
  valid_594780 = validateParameter(valid_594780, JString, required = false,
                                 default = nil)
  if valid_594780 != nil:
    section.add "X-Amz-Algorithm", valid_594780
  var valid_594781 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594781 = validateParameter(valid_594781, JString, required = false,
                                 default = nil)
  if valid_594781 != nil:
    section.add "X-Amz-SignedHeaders", valid_594781
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594783: Call_DescribePatchGroupState_594771; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns high-level aggregated patch compliance state for a patch group.
  ## 
  let valid = call_594783.validator(path, query, header, formData, body)
  let scheme = call_594783.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594783.url(scheme.get, call_594783.host, call_594783.base,
                         call_594783.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594783, url, valid)

proc call*(call_594784: Call_DescribePatchGroupState_594771; body: JsonNode): Recallable =
  ## describePatchGroupState
  ## Returns high-level aggregated patch compliance state for a patch group.
  ##   body: JObject (required)
  var body_594785 = newJObject()
  if body != nil:
    body_594785 = body
  result = call_594784.call(nil, nil, nil, nil, body_594785)

var describePatchGroupState* = Call_DescribePatchGroupState_594771(
    name: "describePatchGroupState", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribePatchGroupState",
    validator: validate_DescribePatchGroupState_594772, base: "/",
    url: url_DescribePatchGroupState_594773, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePatchGroups_594786 = ref object of OpenApiRestCall_593389
proc url_DescribePatchGroups_594788(protocol: Scheme; host: string; base: string;
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

proc validate_DescribePatchGroups_594787(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594789 = header.getOrDefault("X-Amz-Target")
  valid_594789 = validateParameter(valid_594789, JString, required = true, default = newJString(
      "AmazonSSM.DescribePatchGroups"))
  if valid_594789 != nil:
    section.add "X-Amz-Target", valid_594789
  var valid_594790 = header.getOrDefault("X-Amz-Signature")
  valid_594790 = validateParameter(valid_594790, JString, required = false,
                                 default = nil)
  if valid_594790 != nil:
    section.add "X-Amz-Signature", valid_594790
  var valid_594791 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594791 = validateParameter(valid_594791, JString, required = false,
                                 default = nil)
  if valid_594791 != nil:
    section.add "X-Amz-Content-Sha256", valid_594791
  var valid_594792 = header.getOrDefault("X-Amz-Date")
  valid_594792 = validateParameter(valid_594792, JString, required = false,
                                 default = nil)
  if valid_594792 != nil:
    section.add "X-Amz-Date", valid_594792
  var valid_594793 = header.getOrDefault("X-Amz-Credential")
  valid_594793 = validateParameter(valid_594793, JString, required = false,
                                 default = nil)
  if valid_594793 != nil:
    section.add "X-Amz-Credential", valid_594793
  var valid_594794 = header.getOrDefault("X-Amz-Security-Token")
  valid_594794 = validateParameter(valid_594794, JString, required = false,
                                 default = nil)
  if valid_594794 != nil:
    section.add "X-Amz-Security-Token", valid_594794
  var valid_594795 = header.getOrDefault("X-Amz-Algorithm")
  valid_594795 = validateParameter(valid_594795, JString, required = false,
                                 default = nil)
  if valid_594795 != nil:
    section.add "X-Amz-Algorithm", valid_594795
  var valid_594796 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594796 = validateParameter(valid_594796, JString, required = false,
                                 default = nil)
  if valid_594796 != nil:
    section.add "X-Amz-SignedHeaders", valid_594796
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594798: Call_DescribePatchGroups_594786; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all patch groups that have been registered with patch baselines.
  ## 
  let valid = call_594798.validator(path, query, header, formData, body)
  let scheme = call_594798.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594798.url(scheme.get, call_594798.host, call_594798.base,
                         call_594798.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594798, url, valid)

proc call*(call_594799: Call_DescribePatchGroups_594786; body: JsonNode): Recallable =
  ## describePatchGroups
  ## Lists all patch groups that have been registered with patch baselines.
  ##   body: JObject (required)
  var body_594800 = newJObject()
  if body != nil:
    body_594800 = body
  result = call_594799.call(nil, nil, nil, nil, body_594800)

var describePatchGroups* = Call_DescribePatchGroups_594786(
    name: "describePatchGroups", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribePatchGroups",
    validator: validate_DescribePatchGroups_594787, base: "/",
    url: url_DescribePatchGroups_594788, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePatchProperties_594801 = ref object of OpenApiRestCall_593389
proc url_DescribePatchProperties_594803(protocol: Scheme; host: string; base: string;
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

proc validate_DescribePatchProperties_594802(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594804 = header.getOrDefault("X-Amz-Target")
  valid_594804 = validateParameter(valid_594804, JString, required = true, default = newJString(
      "AmazonSSM.DescribePatchProperties"))
  if valid_594804 != nil:
    section.add "X-Amz-Target", valid_594804
  var valid_594805 = header.getOrDefault("X-Amz-Signature")
  valid_594805 = validateParameter(valid_594805, JString, required = false,
                                 default = nil)
  if valid_594805 != nil:
    section.add "X-Amz-Signature", valid_594805
  var valid_594806 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594806 = validateParameter(valid_594806, JString, required = false,
                                 default = nil)
  if valid_594806 != nil:
    section.add "X-Amz-Content-Sha256", valid_594806
  var valid_594807 = header.getOrDefault("X-Amz-Date")
  valid_594807 = validateParameter(valid_594807, JString, required = false,
                                 default = nil)
  if valid_594807 != nil:
    section.add "X-Amz-Date", valid_594807
  var valid_594808 = header.getOrDefault("X-Amz-Credential")
  valid_594808 = validateParameter(valid_594808, JString, required = false,
                                 default = nil)
  if valid_594808 != nil:
    section.add "X-Amz-Credential", valid_594808
  var valid_594809 = header.getOrDefault("X-Amz-Security-Token")
  valid_594809 = validateParameter(valid_594809, JString, required = false,
                                 default = nil)
  if valid_594809 != nil:
    section.add "X-Amz-Security-Token", valid_594809
  var valid_594810 = header.getOrDefault("X-Amz-Algorithm")
  valid_594810 = validateParameter(valid_594810, JString, required = false,
                                 default = nil)
  if valid_594810 != nil:
    section.add "X-Amz-Algorithm", valid_594810
  var valid_594811 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594811 = validateParameter(valid_594811, JString, required = false,
                                 default = nil)
  if valid_594811 != nil:
    section.add "X-Amz-SignedHeaders", valid_594811
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594813: Call_DescribePatchProperties_594801; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the properties of available patches organized by product, product family, classification, severity, and other properties of available patches. You can use the reported properties in the filters you specify in requests for actions such as <a>CreatePatchBaseline</a>, <a>UpdatePatchBaseline</a>, <a>DescribeAvailablePatches</a>, and <a>DescribePatchBaselines</a>.</p> <p>The following section lists the properties that can be used in filters for each major operating system type:</p> <dl> <dt>WINDOWS</dt> <dd> <p>Valid properties: PRODUCT, PRODUCT_FAMILY, CLASSIFICATION, MSRC_SEVERITY</p> </dd> <dt>AMAZON_LINUX</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>AMAZON_LINUX_2</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>UBUNTU </dt> <dd> <p>Valid properties: PRODUCT, PRIORITY</p> </dd> <dt>REDHAT_ENTERPRISE_LINUX</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>SUSE</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>CENTOS</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> </dl>
  ## 
  let valid = call_594813.validator(path, query, header, formData, body)
  let scheme = call_594813.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594813.url(scheme.get, call_594813.host, call_594813.base,
                         call_594813.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594813, url, valid)

proc call*(call_594814: Call_DescribePatchProperties_594801; body: JsonNode): Recallable =
  ## describePatchProperties
  ## <p>Lists the properties of available patches organized by product, product family, classification, severity, and other properties of available patches. You can use the reported properties in the filters you specify in requests for actions such as <a>CreatePatchBaseline</a>, <a>UpdatePatchBaseline</a>, <a>DescribeAvailablePatches</a>, and <a>DescribePatchBaselines</a>.</p> <p>The following section lists the properties that can be used in filters for each major operating system type:</p> <dl> <dt>WINDOWS</dt> <dd> <p>Valid properties: PRODUCT, PRODUCT_FAMILY, CLASSIFICATION, MSRC_SEVERITY</p> </dd> <dt>AMAZON_LINUX</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>AMAZON_LINUX_2</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>UBUNTU </dt> <dd> <p>Valid properties: PRODUCT, PRIORITY</p> </dd> <dt>REDHAT_ENTERPRISE_LINUX</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>SUSE</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>CENTOS</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> </dl>
  ##   body: JObject (required)
  var body_594815 = newJObject()
  if body != nil:
    body_594815 = body
  result = call_594814.call(nil, nil, nil, nil, body_594815)

var describePatchProperties* = Call_DescribePatchProperties_594801(
    name: "describePatchProperties", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribePatchProperties",
    validator: validate_DescribePatchProperties_594802, base: "/",
    url: url_DescribePatchProperties_594803, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSessions_594816 = ref object of OpenApiRestCall_593389
proc url_DescribeSessions_594818(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeSessions_594817(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594819 = header.getOrDefault("X-Amz-Target")
  valid_594819 = validateParameter(valid_594819, JString, required = true, default = newJString(
      "AmazonSSM.DescribeSessions"))
  if valid_594819 != nil:
    section.add "X-Amz-Target", valid_594819
  var valid_594820 = header.getOrDefault("X-Amz-Signature")
  valid_594820 = validateParameter(valid_594820, JString, required = false,
                                 default = nil)
  if valid_594820 != nil:
    section.add "X-Amz-Signature", valid_594820
  var valid_594821 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594821 = validateParameter(valid_594821, JString, required = false,
                                 default = nil)
  if valid_594821 != nil:
    section.add "X-Amz-Content-Sha256", valid_594821
  var valid_594822 = header.getOrDefault("X-Amz-Date")
  valid_594822 = validateParameter(valid_594822, JString, required = false,
                                 default = nil)
  if valid_594822 != nil:
    section.add "X-Amz-Date", valid_594822
  var valid_594823 = header.getOrDefault("X-Amz-Credential")
  valid_594823 = validateParameter(valid_594823, JString, required = false,
                                 default = nil)
  if valid_594823 != nil:
    section.add "X-Amz-Credential", valid_594823
  var valid_594824 = header.getOrDefault("X-Amz-Security-Token")
  valid_594824 = validateParameter(valid_594824, JString, required = false,
                                 default = nil)
  if valid_594824 != nil:
    section.add "X-Amz-Security-Token", valid_594824
  var valid_594825 = header.getOrDefault("X-Amz-Algorithm")
  valid_594825 = validateParameter(valid_594825, JString, required = false,
                                 default = nil)
  if valid_594825 != nil:
    section.add "X-Amz-Algorithm", valid_594825
  var valid_594826 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594826 = validateParameter(valid_594826, JString, required = false,
                                 default = nil)
  if valid_594826 != nil:
    section.add "X-Amz-SignedHeaders", valid_594826
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594828: Call_DescribeSessions_594816; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of all active sessions (both connected and disconnected) or terminated sessions from the past 30 days.
  ## 
  let valid = call_594828.validator(path, query, header, formData, body)
  let scheme = call_594828.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594828.url(scheme.get, call_594828.host, call_594828.base,
                         call_594828.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594828, url, valid)

proc call*(call_594829: Call_DescribeSessions_594816; body: JsonNode): Recallable =
  ## describeSessions
  ## Retrieves a list of all active sessions (both connected and disconnected) or terminated sessions from the past 30 days.
  ##   body: JObject (required)
  var body_594830 = newJObject()
  if body != nil:
    body_594830 = body
  result = call_594829.call(nil, nil, nil, nil, body_594830)

var describeSessions* = Call_DescribeSessions_594816(name: "describeSessions",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeSessions",
    validator: validate_DescribeSessions_594817, base: "/",
    url: url_DescribeSessions_594818, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAutomationExecution_594831 = ref object of OpenApiRestCall_593389
proc url_GetAutomationExecution_594833(protocol: Scheme; host: string; base: string;
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

proc validate_GetAutomationExecution_594832(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594834 = header.getOrDefault("X-Amz-Target")
  valid_594834 = validateParameter(valid_594834, JString, required = true, default = newJString(
      "AmazonSSM.GetAutomationExecution"))
  if valid_594834 != nil:
    section.add "X-Amz-Target", valid_594834
  var valid_594835 = header.getOrDefault("X-Amz-Signature")
  valid_594835 = validateParameter(valid_594835, JString, required = false,
                                 default = nil)
  if valid_594835 != nil:
    section.add "X-Amz-Signature", valid_594835
  var valid_594836 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594836 = validateParameter(valid_594836, JString, required = false,
                                 default = nil)
  if valid_594836 != nil:
    section.add "X-Amz-Content-Sha256", valid_594836
  var valid_594837 = header.getOrDefault("X-Amz-Date")
  valid_594837 = validateParameter(valid_594837, JString, required = false,
                                 default = nil)
  if valid_594837 != nil:
    section.add "X-Amz-Date", valid_594837
  var valid_594838 = header.getOrDefault("X-Amz-Credential")
  valid_594838 = validateParameter(valid_594838, JString, required = false,
                                 default = nil)
  if valid_594838 != nil:
    section.add "X-Amz-Credential", valid_594838
  var valid_594839 = header.getOrDefault("X-Amz-Security-Token")
  valid_594839 = validateParameter(valid_594839, JString, required = false,
                                 default = nil)
  if valid_594839 != nil:
    section.add "X-Amz-Security-Token", valid_594839
  var valid_594840 = header.getOrDefault("X-Amz-Algorithm")
  valid_594840 = validateParameter(valid_594840, JString, required = false,
                                 default = nil)
  if valid_594840 != nil:
    section.add "X-Amz-Algorithm", valid_594840
  var valid_594841 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594841 = validateParameter(valid_594841, JString, required = false,
                                 default = nil)
  if valid_594841 != nil:
    section.add "X-Amz-SignedHeaders", valid_594841
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594843: Call_GetAutomationExecution_594831; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get detailed information about a particular Automation execution.
  ## 
  let valid = call_594843.validator(path, query, header, formData, body)
  let scheme = call_594843.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594843.url(scheme.get, call_594843.host, call_594843.base,
                         call_594843.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594843, url, valid)

proc call*(call_594844: Call_GetAutomationExecution_594831; body: JsonNode): Recallable =
  ## getAutomationExecution
  ## Get detailed information about a particular Automation execution.
  ##   body: JObject (required)
  var body_594845 = newJObject()
  if body != nil:
    body_594845 = body
  result = call_594844.call(nil, nil, nil, nil, body_594845)

var getAutomationExecution* = Call_GetAutomationExecution_594831(
    name: "getAutomationExecution", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetAutomationExecution",
    validator: validate_GetAutomationExecution_594832, base: "/",
    url: url_GetAutomationExecution_594833, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCommandInvocation_594846 = ref object of OpenApiRestCall_593389
proc url_GetCommandInvocation_594848(protocol: Scheme; host: string; base: string;
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

proc validate_GetCommandInvocation_594847(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594849 = header.getOrDefault("X-Amz-Target")
  valid_594849 = validateParameter(valid_594849, JString, required = true, default = newJString(
      "AmazonSSM.GetCommandInvocation"))
  if valid_594849 != nil:
    section.add "X-Amz-Target", valid_594849
  var valid_594850 = header.getOrDefault("X-Amz-Signature")
  valid_594850 = validateParameter(valid_594850, JString, required = false,
                                 default = nil)
  if valid_594850 != nil:
    section.add "X-Amz-Signature", valid_594850
  var valid_594851 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594851 = validateParameter(valid_594851, JString, required = false,
                                 default = nil)
  if valid_594851 != nil:
    section.add "X-Amz-Content-Sha256", valid_594851
  var valid_594852 = header.getOrDefault("X-Amz-Date")
  valid_594852 = validateParameter(valid_594852, JString, required = false,
                                 default = nil)
  if valid_594852 != nil:
    section.add "X-Amz-Date", valid_594852
  var valid_594853 = header.getOrDefault("X-Amz-Credential")
  valid_594853 = validateParameter(valid_594853, JString, required = false,
                                 default = nil)
  if valid_594853 != nil:
    section.add "X-Amz-Credential", valid_594853
  var valid_594854 = header.getOrDefault("X-Amz-Security-Token")
  valid_594854 = validateParameter(valid_594854, JString, required = false,
                                 default = nil)
  if valid_594854 != nil:
    section.add "X-Amz-Security-Token", valid_594854
  var valid_594855 = header.getOrDefault("X-Amz-Algorithm")
  valid_594855 = validateParameter(valid_594855, JString, required = false,
                                 default = nil)
  if valid_594855 != nil:
    section.add "X-Amz-Algorithm", valid_594855
  var valid_594856 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594856 = validateParameter(valid_594856, JString, required = false,
                                 default = nil)
  if valid_594856 != nil:
    section.add "X-Amz-SignedHeaders", valid_594856
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594858: Call_GetCommandInvocation_594846; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns detailed information about command execution for an invocation or plugin. 
  ## 
  let valid = call_594858.validator(path, query, header, formData, body)
  let scheme = call_594858.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594858.url(scheme.get, call_594858.host, call_594858.base,
                         call_594858.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594858, url, valid)

proc call*(call_594859: Call_GetCommandInvocation_594846; body: JsonNode): Recallable =
  ## getCommandInvocation
  ## Returns detailed information about command execution for an invocation or plugin. 
  ##   body: JObject (required)
  var body_594860 = newJObject()
  if body != nil:
    body_594860 = body
  result = call_594859.call(nil, nil, nil, nil, body_594860)

var getCommandInvocation* = Call_GetCommandInvocation_594846(
    name: "getCommandInvocation", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetCommandInvocation",
    validator: validate_GetCommandInvocation_594847, base: "/",
    url: url_GetCommandInvocation_594848, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnectionStatus_594861 = ref object of OpenApiRestCall_593389
proc url_GetConnectionStatus_594863(protocol: Scheme; host: string; base: string;
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

proc validate_GetConnectionStatus_594862(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594864 = header.getOrDefault("X-Amz-Target")
  valid_594864 = validateParameter(valid_594864, JString, required = true, default = newJString(
      "AmazonSSM.GetConnectionStatus"))
  if valid_594864 != nil:
    section.add "X-Amz-Target", valid_594864
  var valid_594865 = header.getOrDefault("X-Amz-Signature")
  valid_594865 = validateParameter(valid_594865, JString, required = false,
                                 default = nil)
  if valid_594865 != nil:
    section.add "X-Amz-Signature", valid_594865
  var valid_594866 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594866 = validateParameter(valid_594866, JString, required = false,
                                 default = nil)
  if valid_594866 != nil:
    section.add "X-Amz-Content-Sha256", valid_594866
  var valid_594867 = header.getOrDefault("X-Amz-Date")
  valid_594867 = validateParameter(valid_594867, JString, required = false,
                                 default = nil)
  if valid_594867 != nil:
    section.add "X-Amz-Date", valid_594867
  var valid_594868 = header.getOrDefault("X-Amz-Credential")
  valid_594868 = validateParameter(valid_594868, JString, required = false,
                                 default = nil)
  if valid_594868 != nil:
    section.add "X-Amz-Credential", valid_594868
  var valid_594869 = header.getOrDefault("X-Amz-Security-Token")
  valid_594869 = validateParameter(valid_594869, JString, required = false,
                                 default = nil)
  if valid_594869 != nil:
    section.add "X-Amz-Security-Token", valid_594869
  var valid_594870 = header.getOrDefault("X-Amz-Algorithm")
  valid_594870 = validateParameter(valid_594870, JString, required = false,
                                 default = nil)
  if valid_594870 != nil:
    section.add "X-Amz-Algorithm", valid_594870
  var valid_594871 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594871 = validateParameter(valid_594871, JString, required = false,
                                 default = nil)
  if valid_594871 != nil:
    section.add "X-Amz-SignedHeaders", valid_594871
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594873: Call_GetConnectionStatus_594861; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the Session Manager connection status for an instance to determine whether it is connected and ready to receive Session Manager connections.
  ## 
  let valid = call_594873.validator(path, query, header, formData, body)
  let scheme = call_594873.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594873.url(scheme.get, call_594873.host, call_594873.base,
                         call_594873.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594873, url, valid)

proc call*(call_594874: Call_GetConnectionStatus_594861; body: JsonNode): Recallable =
  ## getConnectionStatus
  ## Retrieves the Session Manager connection status for an instance to determine whether it is connected and ready to receive Session Manager connections.
  ##   body: JObject (required)
  var body_594875 = newJObject()
  if body != nil:
    body_594875 = body
  result = call_594874.call(nil, nil, nil, nil, body_594875)

var getConnectionStatus* = Call_GetConnectionStatus_594861(
    name: "getConnectionStatus", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetConnectionStatus",
    validator: validate_GetConnectionStatus_594862, base: "/",
    url: url_GetConnectionStatus_594863, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefaultPatchBaseline_594876 = ref object of OpenApiRestCall_593389
proc url_GetDefaultPatchBaseline_594878(protocol: Scheme; host: string; base: string;
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

proc validate_GetDefaultPatchBaseline_594877(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594879 = header.getOrDefault("X-Amz-Target")
  valid_594879 = validateParameter(valid_594879, JString, required = true, default = newJString(
      "AmazonSSM.GetDefaultPatchBaseline"))
  if valid_594879 != nil:
    section.add "X-Amz-Target", valid_594879
  var valid_594880 = header.getOrDefault("X-Amz-Signature")
  valid_594880 = validateParameter(valid_594880, JString, required = false,
                                 default = nil)
  if valid_594880 != nil:
    section.add "X-Amz-Signature", valid_594880
  var valid_594881 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594881 = validateParameter(valid_594881, JString, required = false,
                                 default = nil)
  if valid_594881 != nil:
    section.add "X-Amz-Content-Sha256", valid_594881
  var valid_594882 = header.getOrDefault("X-Amz-Date")
  valid_594882 = validateParameter(valid_594882, JString, required = false,
                                 default = nil)
  if valid_594882 != nil:
    section.add "X-Amz-Date", valid_594882
  var valid_594883 = header.getOrDefault("X-Amz-Credential")
  valid_594883 = validateParameter(valid_594883, JString, required = false,
                                 default = nil)
  if valid_594883 != nil:
    section.add "X-Amz-Credential", valid_594883
  var valid_594884 = header.getOrDefault("X-Amz-Security-Token")
  valid_594884 = validateParameter(valid_594884, JString, required = false,
                                 default = nil)
  if valid_594884 != nil:
    section.add "X-Amz-Security-Token", valid_594884
  var valid_594885 = header.getOrDefault("X-Amz-Algorithm")
  valid_594885 = validateParameter(valid_594885, JString, required = false,
                                 default = nil)
  if valid_594885 != nil:
    section.add "X-Amz-Algorithm", valid_594885
  var valid_594886 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594886 = validateParameter(valid_594886, JString, required = false,
                                 default = nil)
  if valid_594886 != nil:
    section.add "X-Amz-SignedHeaders", valid_594886
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594888: Call_GetDefaultPatchBaseline_594876; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the default patch baseline. Note that Systems Manager supports creating multiple default patch baselines. For example, you can create a default patch baseline for each operating system.</p> <p>If you do not specify an operating system value, the default patch baseline for Windows is returned.</p>
  ## 
  let valid = call_594888.validator(path, query, header, formData, body)
  let scheme = call_594888.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594888.url(scheme.get, call_594888.host, call_594888.base,
                         call_594888.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594888, url, valid)

proc call*(call_594889: Call_GetDefaultPatchBaseline_594876; body: JsonNode): Recallable =
  ## getDefaultPatchBaseline
  ## <p>Retrieves the default patch baseline. Note that Systems Manager supports creating multiple default patch baselines. For example, you can create a default patch baseline for each operating system.</p> <p>If you do not specify an operating system value, the default patch baseline for Windows is returned.</p>
  ##   body: JObject (required)
  var body_594890 = newJObject()
  if body != nil:
    body_594890 = body
  result = call_594889.call(nil, nil, nil, nil, body_594890)

var getDefaultPatchBaseline* = Call_GetDefaultPatchBaseline_594876(
    name: "getDefaultPatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetDefaultPatchBaseline",
    validator: validate_GetDefaultPatchBaseline_594877, base: "/",
    url: url_GetDefaultPatchBaseline_594878, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployablePatchSnapshotForInstance_594891 = ref object of OpenApiRestCall_593389
proc url_GetDeployablePatchSnapshotForInstance_594893(protocol: Scheme;
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

proc validate_GetDeployablePatchSnapshotForInstance_594892(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594894 = header.getOrDefault("X-Amz-Target")
  valid_594894 = validateParameter(valid_594894, JString, required = true, default = newJString(
      "AmazonSSM.GetDeployablePatchSnapshotForInstance"))
  if valid_594894 != nil:
    section.add "X-Amz-Target", valid_594894
  var valid_594895 = header.getOrDefault("X-Amz-Signature")
  valid_594895 = validateParameter(valid_594895, JString, required = false,
                                 default = nil)
  if valid_594895 != nil:
    section.add "X-Amz-Signature", valid_594895
  var valid_594896 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594896 = validateParameter(valid_594896, JString, required = false,
                                 default = nil)
  if valid_594896 != nil:
    section.add "X-Amz-Content-Sha256", valid_594896
  var valid_594897 = header.getOrDefault("X-Amz-Date")
  valid_594897 = validateParameter(valid_594897, JString, required = false,
                                 default = nil)
  if valid_594897 != nil:
    section.add "X-Amz-Date", valid_594897
  var valid_594898 = header.getOrDefault("X-Amz-Credential")
  valid_594898 = validateParameter(valid_594898, JString, required = false,
                                 default = nil)
  if valid_594898 != nil:
    section.add "X-Amz-Credential", valid_594898
  var valid_594899 = header.getOrDefault("X-Amz-Security-Token")
  valid_594899 = validateParameter(valid_594899, JString, required = false,
                                 default = nil)
  if valid_594899 != nil:
    section.add "X-Amz-Security-Token", valid_594899
  var valid_594900 = header.getOrDefault("X-Amz-Algorithm")
  valid_594900 = validateParameter(valid_594900, JString, required = false,
                                 default = nil)
  if valid_594900 != nil:
    section.add "X-Amz-Algorithm", valid_594900
  var valid_594901 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594901 = validateParameter(valid_594901, JString, required = false,
                                 default = nil)
  if valid_594901 != nil:
    section.add "X-Amz-SignedHeaders", valid_594901
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594903: Call_GetDeployablePatchSnapshotForInstance_594891;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the current snapshot for the patch baseline the instance uses. This API is primarily used by the AWS-RunPatchBaseline Systems Manager document. 
  ## 
  let valid = call_594903.validator(path, query, header, formData, body)
  let scheme = call_594903.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594903.url(scheme.get, call_594903.host, call_594903.base,
                         call_594903.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594903, url, valid)

proc call*(call_594904: Call_GetDeployablePatchSnapshotForInstance_594891;
          body: JsonNode): Recallable =
  ## getDeployablePatchSnapshotForInstance
  ## Retrieves the current snapshot for the patch baseline the instance uses. This API is primarily used by the AWS-RunPatchBaseline Systems Manager document. 
  ##   body: JObject (required)
  var body_594905 = newJObject()
  if body != nil:
    body_594905 = body
  result = call_594904.call(nil, nil, nil, nil, body_594905)

var getDeployablePatchSnapshotForInstance* = Call_GetDeployablePatchSnapshotForInstance_594891(
    name: "getDeployablePatchSnapshotForInstance", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetDeployablePatchSnapshotForInstance",
    validator: validate_GetDeployablePatchSnapshotForInstance_594892, base: "/",
    url: url_GetDeployablePatchSnapshotForInstance_594893,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocument_594906 = ref object of OpenApiRestCall_593389
proc url_GetDocument_594908(protocol: Scheme; host: string; base: string;
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

proc validate_GetDocument_594907(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594909 = header.getOrDefault("X-Amz-Target")
  valid_594909 = validateParameter(valid_594909, JString, required = true,
                                 default = newJString("AmazonSSM.GetDocument"))
  if valid_594909 != nil:
    section.add "X-Amz-Target", valid_594909
  var valid_594910 = header.getOrDefault("X-Amz-Signature")
  valid_594910 = validateParameter(valid_594910, JString, required = false,
                                 default = nil)
  if valid_594910 != nil:
    section.add "X-Amz-Signature", valid_594910
  var valid_594911 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594911 = validateParameter(valid_594911, JString, required = false,
                                 default = nil)
  if valid_594911 != nil:
    section.add "X-Amz-Content-Sha256", valid_594911
  var valid_594912 = header.getOrDefault("X-Amz-Date")
  valid_594912 = validateParameter(valid_594912, JString, required = false,
                                 default = nil)
  if valid_594912 != nil:
    section.add "X-Amz-Date", valid_594912
  var valid_594913 = header.getOrDefault("X-Amz-Credential")
  valid_594913 = validateParameter(valid_594913, JString, required = false,
                                 default = nil)
  if valid_594913 != nil:
    section.add "X-Amz-Credential", valid_594913
  var valid_594914 = header.getOrDefault("X-Amz-Security-Token")
  valid_594914 = validateParameter(valid_594914, JString, required = false,
                                 default = nil)
  if valid_594914 != nil:
    section.add "X-Amz-Security-Token", valid_594914
  var valid_594915 = header.getOrDefault("X-Amz-Algorithm")
  valid_594915 = validateParameter(valid_594915, JString, required = false,
                                 default = nil)
  if valid_594915 != nil:
    section.add "X-Amz-Algorithm", valid_594915
  var valid_594916 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594916 = validateParameter(valid_594916, JString, required = false,
                                 default = nil)
  if valid_594916 != nil:
    section.add "X-Amz-SignedHeaders", valid_594916
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594918: Call_GetDocument_594906; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the contents of the specified Systems Manager document.
  ## 
  let valid = call_594918.validator(path, query, header, formData, body)
  let scheme = call_594918.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594918.url(scheme.get, call_594918.host, call_594918.base,
                         call_594918.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594918, url, valid)

proc call*(call_594919: Call_GetDocument_594906; body: JsonNode): Recallable =
  ## getDocument
  ## Gets the contents of the specified Systems Manager document.
  ##   body: JObject (required)
  var body_594920 = newJObject()
  if body != nil:
    body_594920 = body
  result = call_594919.call(nil, nil, nil, nil, body_594920)

var getDocument* = Call_GetDocument_594906(name: "getDocument",
                                        meth: HttpMethod.HttpPost,
                                        host: "ssm.amazonaws.com", route: "/#X-Amz-Target=AmazonSSM.GetDocument",
                                        validator: validate_GetDocument_594907,
                                        base: "/", url: url_GetDocument_594908,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInventory_594921 = ref object of OpenApiRestCall_593389
proc url_GetInventory_594923(protocol: Scheme; host: string; base: string;
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

proc validate_GetInventory_594922(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594924 = header.getOrDefault("X-Amz-Target")
  valid_594924 = validateParameter(valid_594924, JString, required = true,
                                 default = newJString("AmazonSSM.GetInventory"))
  if valid_594924 != nil:
    section.add "X-Amz-Target", valid_594924
  var valid_594925 = header.getOrDefault("X-Amz-Signature")
  valid_594925 = validateParameter(valid_594925, JString, required = false,
                                 default = nil)
  if valid_594925 != nil:
    section.add "X-Amz-Signature", valid_594925
  var valid_594926 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594926 = validateParameter(valid_594926, JString, required = false,
                                 default = nil)
  if valid_594926 != nil:
    section.add "X-Amz-Content-Sha256", valid_594926
  var valid_594927 = header.getOrDefault("X-Amz-Date")
  valid_594927 = validateParameter(valid_594927, JString, required = false,
                                 default = nil)
  if valid_594927 != nil:
    section.add "X-Amz-Date", valid_594927
  var valid_594928 = header.getOrDefault("X-Amz-Credential")
  valid_594928 = validateParameter(valid_594928, JString, required = false,
                                 default = nil)
  if valid_594928 != nil:
    section.add "X-Amz-Credential", valid_594928
  var valid_594929 = header.getOrDefault("X-Amz-Security-Token")
  valid_594929 = validateParameter(valid_594929, JString, required = false,
                                 default = nil)
  if valid_594929 != nil:
    section.add "X-Amz-Security-Token", valid_594929
  var valid_594930 = header.getOrDefault("X-Amz-Algorithm")
  valid_594930 = validateParameter(valid_594930, JString, required = false,
                                 default = nil)
  if valid_594930 != nil:
    section.add "X-Amz-Algorithm", valid_594930
  var valid_594931 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594931 = validateParameter(valid_594931, JString, required = false,
                                 default = nil)
  if valid_594931 != nil:
    section.add "X-Amz-SignedHeaders", valid_594931
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594933: Call_GetInventory_594921; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Query inventory information.
  ## 
  let valid = call_594933.validator(path, query, header, formData, body)
  let scheme = call_594933.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594933.url(scheme.get, call_594933.host, call_594933.base,
                         call_594933.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594933, url, valid)

proc call*(call_594934: Call_GetInventory_594921; body: JsonNode): Recallable =
  ## getInventory
  ## Query inventory information.
  ##   body: JObject (required)
  var body_594935 = newJObject()
  if body != nil:
    body_594935 = body
  result = call_594934.call(nil, nil, nil, nil, body_594935)

var getInventory* = Call_GetInventory_594921(name: "getInventory",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetInventory",
    validator: validate_GetInventory_594922, base: "/", url: url_GetInventory_594923,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInventorySchema_594936 = ref object of OpenApiRestCall_593389
proc url_GetInventorySchema_594938(protocol: Scheme; host: string; base: string;
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

proc validate_GetInventorySchema_594937(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594939 = header.getOrDefault("X-Amz-Target")
  valid_594939 = validateParameter(valid_594939, JString, required = true, default = newJString(
      "AmazonSSM.GetInventorySchema"))
  if valid_594939 != nil:
    section.add "X-Amz-Target", valid_594939
  var valid_594940 = header.getOrDefault("X-Amz-Signature")
  valid_594940 = validateParameter(valid_594940, JString, required = false,
                                 default = nil)
  if valid_594940 != nil:
    section.add "X-Amz-Signature", valid_594940
  var valid_594941 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594941 = validateParameter(valid_594941, JString, required = false,
                                 default = nil)
  if valid_594941 != nil:
    section.add "X-Amz-Content-Sha256", valid_594941
  var valid_594942 = header.getOrDefault("X-Amz-Date")
  valid_594942 = validateParameter(valid_594942, JString, required = false,
                                 default = nil)
  if valid_594942 != nil:
    section.add "X-Amz-Date", valid_594942
  var valid_594943 = header.getOrDefault("X-Amz-Credential")
  valid_594943 = validateParameter(valid_594943, JString, required = false,
                                 default = nil)
  if valid_594943 != nil:
    section.add "X-Amz-Credential", valid_594943
  var valid_594944 = header.getOrDefault("X-Amz-Security-Token")
  valid_594944 = validateParameter(valid_594944, JString, required = false,
                                 default = nil)
  if valid_594944 != nil:
    section.add "X-Amz-Security-Token", valid_594944
  var valid_594945 = header.getOrDefault("X-Amz-Algorithm")
  valid_594945 = validateParameter(valid_594945, JString, required = false,
                                 default = nil)
  if valid_594945 != nil:
    section.add "X-Amz-Algorithm", valid_594945
  var valid_594946 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594946 = validateParameter(valid_594946, JString, required = false,
                                 default = nil)
  if valid_594946 != nil:
    section.add "X-Amz-SignedHeaders", valid_594946
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594948: Call_GetInventorySchema_594936; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Return a list of inventory type names for the account, or return a list of attribute names for a specific Inventory item type. 
  ## 
  let valid = call_594948.validator(path, query, header, formData, body)
  let scheme = call_594948.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594948.url(scheme.get, call_594948.host, call_594948.base,
                         call_594948.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594948, url, valid)

proc call*(call_594949: Call_GetInventorySchema_594936; body: JsonNode): Recallable =
  ## getInventorySchema
  ## Return a list of inventory type names for the account, or return a list of attribute names for a specific Inventory item type. 
  ##   body: JObject (required)
  var body_594950 = newJObject()
  if body != nil:
    body_594950 = body
  result = call_594949.call(nil, nil, nil, nil, body_594950)

var getInventorySchema* = Call_GetInventorySchema_594936(
    name: "getInventorySchema", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetInventorySchema",
    validator: validate_GetInventorySchema_594937, base: "/",
    url: url_GetInventorySchema_594938, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMaintenanceWindow_594951 = ref object of OpenApiRestCall_593389
proc url_GetMaintenanceWindow_594953(protocol: Scheme; host: string; base: string;
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

proc validate_GetMaintenanceWindow_594952(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594954 = header.getOrDefault("X-Amz-Target")
  valid_594954 = validateParameter(valid_594954, JString, required = true, default = newJString(
      "AmazonSSM.GetMaintenanceWindow"))
  if valid_594954 != nil:
    section.add "X-Amz-Target", valid_594954
  var valid_594955 = header.getOrDefault("X-Amz-Signature")
  valid_594955 = validateParameter(valid_594955, JString, required = false,
                                 default = nil)
  if valid_594955 != nil:
    section.add "X-Amz-Signature", valid_594955
  var valid_594956 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594956 = validateParameter(valid_594956, JString, required = false,
                                 default = nil)
  if valid_594956 != nil:
    section.add "X-Amz-Content-Sha256", valid_594956
  var valid_594957 = header.getOrDefault("X-Amz-Date")
  valid_594957 = validateParameter(valid_594957, JString, required = false,
                                 default = nil)
  if valid_594957 != nil:
    section.add "X-Amz-Date", valid_594957
  var valid_594958 = header.getOrDefault("X-Amz-Credential")
  valid_594958 = validateParameter(valid_594958, JString, required = false,
                                 default = nil)
  if valid_594958 != nil:
    section.add "X-Amz-Credential", valid_594958
  var valid_594959 = header.getOrDefault("X-Amz-Security-Token")
  valid_594959 = validateParameter(valid_594959, JString, required = false,
                                 default = nil)
  if valid_594959 != nil:
    section.add "X-Amz-Security-Token", valid_594959
  var valid_594960 = header.getOrDefault("X-Amz-Algorithm")
  valid_594960 = validateParameter(valid_594960, JString, required = false,
                                 default = nil)
  if valid_594960 != nil:
    section.add "X-Amz-Algorithm", valid_594960
  var valid_594961 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594961 = validateParameter(valid_594961, JString, required = false,
                                 default = nil)
  if valid_594961 != nil:
    section.add "X-Amz-SignedHeaders", valid_594961
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594963: Call_GetMaintenanceWindow_594951; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a maintenance window.
  ## 
  let valid = call_594963.validator(path, query, header, formData, body)
  let scheme = call_594963.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594963.url(scheme.get, call_594963.host, call_594963.base,
                         call_594963.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594963, url, valid)

proc call*(call_594964: Call_GetMaintenanceWindow_594951; body: JsonNode): Recallable =
  ## getMaintenanceWindow
  ## Retrieves a maintenance window.
  ##   body: JObject (required)
  var body_594965 = newJObject()
  if body != nil:
    body_594965 = body
  result = call_594964.call(nil, nil, nil, nil, body_594965)

var getMaintenanceWindow* = Call_GetMaintenanceWindow_594951(
    name: "getMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetMaintenanceWindow",
    validator: validate_GetMaintenanceWindow_594952, base: "/",
    url: url_GetMaintenanceWindow_594953, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMaintenanceWindowExecution_594966 = ref object of OpenApiRestCall_593389
proc url_GetMaintenanceWindowExecution_594968(protocol: Scheme; host: string;
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

proc validate_GetMaintenanceWindowExecution_594967(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594969 = header.getOrDefault("X-Amz-Target")
  valid_594969 = validateParameter(valid_594969, JString, required = true, default = newJString(
      "AmazonSSM.GetMaintenanceWindowExecution"))
  if valid_594969 != nil:
    section.add "X-Amz-Target", valid_594969
  var valid_594970 = header.getOrDefault("X-Amz-Signature")
  valid_594970 = validateParameter(valid_594970, JString, required = false,
                                 default = nil)
  if valid_594970 != nil:
    section.add "X-Amz-Signature", valid_594970
  var valid_594971 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594971 = validateParameter(valid_594971, JString, required = false,
                                 default = nil)
  if valid_594971 != nil:
    section.add "X-Amz-Content-Sha256", valid_594971
  var valid_594972 = header.getOrDefault("X-Amz-Date")
  valid_594972 = validateParameter(valid_594972, JString, required = false,
                                 default = nil)
  if valid_594972 != nil:
    section.add "X-Amz-Date", valid_594972
  var valid_594973 = header.getOrDefault("X-Amz-Credential")
  valid_594973 = validateParameter(valid_594973, JString, required = false,
                                 default = nil)
  if valid_594973 != nil:
    section.add "X-Amz-Credential", valid_594973
  var valid_594974 = header.getOrDefault("X-Amz-Security-Token")
  valid_594974 = validateParameter(valid_594974, JString, required = false,
                                 default = nil)
  if valid_594974 != nil:
    section.add "X-Amz-Security-Token", valid_594974
  var valid_594975 = header.getOrDefault("X-Amz-Algorithm")
  valid_594975 = validateParameter(valid_594975, JString, required = false,
                                 default = nil)
  if valid_594975 != nil:
    section.add "X-Amz-Algorithm", valid_594975
  var valid_594976 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594976 = validateParameter(valid_594976, JString, required = false,
                                 default = nil)
  if valid_594976 != nil:
    section.add "X-Amz-SignedHeaders", valid_594976
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594978: Call_GetMaintenanceWindowExecution_594966; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details about a specific a maintenance window execution.
  ## 
  let valid = call_594978.validator(path, query, header, formData, body)
  let scheme = call_594978.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594978.url(scheme.get, call_594978.host, call_594978.base,
                         call_594978.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594978, url, valid)

proc call*(call_594979: Call_GetMaintenanceWindowExecution_594966; body: JsonNode): Recallable =
  ## getMaintenanceWindowExecution
  ## Retrieves details about a specific a maintenance window execution.
  ##   body: JObject (required)
  var body_594980 = newJObject()
  if body != nil:
    body_594980 = body
  result = call_594979.call(nil, nil, nil, nil, body_594980)

var getMaintenanceWindowExecution* = Call_GetMaintenanceWindowExecution_594966(
    name: "getMaintenanceWindowExecution", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetMaintenanceWindowExecution",
    validator: validate_GetMaintenanceWindowExecution_594967, base: "/",
    url: url_GetMaintenanceWindowExecution_594968,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMaintenanceWindowExecutionTask_594981 = ref object of OpenApiRestCall_593389
proc url_GetMaintenanceWindowExecutionTask_594983(protocol: Scheme; host: string;
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

proc validate_GetMaintenanceWindowExecutionTask_594982(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594984 = header.getOrDefault("X-Amz-Target")
  valid_594984 = validateParameter(valid_594984, JString, required = true, default = newJString(
      "AmazonSSM.GetMaintenanceWindowExecutionTask"))
  if valid_594984 != nil:
    section.add "X-Amz-Target", valid_594984
  var valid_594985 = header.getOrDefault("X-Amz-Signature")
  valid_594985 = validateParameter(valid_594985, JString, required = false,
                                 default = nil)
  if valid_594985 != nil:
    section.add "X-Amz-Signature", valid_594985
  var valid_594986 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594986 = validateParameter(valid_594986, JString, required = false,
                                 default = nil)
  if valid_594986 != nil:
    section.add "X-Amz-Content-Sha256", valid_594986
  var valid_594987 = header.getOrDefault("X-Amz-Date")
  valid_594987 = validateParameter(valid_594987, JString, required = false,
                                 default = nil)
  if valid_594987 != nil:
    section.add "X-Amz-Date", valid_594987
  var valid_594988 = header.getOrDefault("X-Amz-Credential")
  valid_594988 = validateParameter(valid_594988, JString, required = false,
                                 default = nil)
  if valid_594988 != nil:
    section.add "X-Amz-Credential", valid_594988
  var valid_594989 = header.getOrDefault("X-Amz-Security-Token")
  valid_594989 = validateParameter(valid_594989, JString, required = false,
                                 default = nil)
  if valid_594989 != nil:
    section.add "X-Amz-Security-Token", valid_594989
  var valid_594990 = header.getOrDefault("X-Amz-Algorithm")
  valid_594990 = validateParameter(valid_594990, JString, required = false,
                                 default = nil)
  if valid_594990 != nil:
    section.add "X-Amz-Algorithm", valid_594990
  var valid_594991 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594991 = validateParameter(valid_594991, JString, required = false,
                                 default = nil)
  if valid_594991 != nil:
    section.add "X-Amz-SignedHeaders", valid_594991
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594993: Call_GetMaintenanceWindowExecutionTask_594981;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the details about a specific task run as part of a maintenance window execution.
  ## 
  let valid = call_594993.validator(path, query, header, formData, body)
  let scheme = call_594993.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594993.url(scheme.get, call_594993.host, call_594993.base,
                         call_594993.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594993, url, valid)

proc call*(call_594994: Call_GetMaintenanceWindowExecutionTask_594981;
          body: JsonNode): Recallable =
  ## getMaintenanceWindowExecutionTask
  ## Retrieves the details about a specific task run as part of a maintenance window execution.
  ##   body: JObject (required)
  var body_594995 = newJObject()
  if body != nil:
    body_594995 = body
  result = call_594994.call(nil, nil, nil, nil, body_594995)

var getMaintenanceWindowExecutionTask* = Call_GetMaintenanceWindowExecutionTask_594981(
    name: "getMaintenanceWindowExecutionTask", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetMaintenanceWindowExecutionTask",
    validator: validate_GetMaintenanceWindowExecutionTask_594982, base: "/",
    url: url_GetMaintenanceWindowExecutionTask_594983,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMaintenanceWindowExecutionTaskInvocation_594996 = ref object of OpenApiRestCall_593389
proc url_GetMaintenanceWindowExecutionTaskInvocation_594998(protocol: Scheme;
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

proc validate_GetMaintenanceWindowExecutionTaskInvocation_594997(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594999 = header.getOrDefault("X-Amz-Target")
  valid_594999 = validateParameter(valid_594999, JString, required = true, default = newJString(
      "AmazonSSM.GetMaintenanceWindowExecutionTaskInvocation"))
  if valid_594999 != nil:
    section.add "X-Amz-Target", valid_594999
  var valid_595000 = header.getOrDefault("X-Amz-Signature")
  valid_595000 = validateParameter(valid_595000, JString, required = false,
                                 default = nil)
  if valid_595000 != nil:
    section.add "X-Amz-Signature", valid_595000
  var valid_595001 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595001 = validateParameter(valid_595001, JString, required = false,
                                 default = nil)
  if valid_595001 != nil:
    section.add "X-Amz-Content-Sha256", valid_595001
  var valid_595002 = header.getOrDefault("X-Amz-Date")
  valid_595002 = validateParameter(valid_595002, JString, required = false,
                                 default = nil)
  if valid_595002 != nil:
    section.add "X-Amz-Date", valid_595002
  var valid_595003 = header.getOrDefault("X-Amz-Credential")
  valid_595003 = validateParameter(valid_595003, JString, required = false,
                                 default = nil)
  if valid_595003 != nil:
    section.add "X-Amz-Credential", valid_595003
  var valid_595004 = header.getOrDefault("X-Amz-Security-Token")
  valid_595004 = validateParameter(valid_595004, JString, required = false,
                                 default = nil)
  if valid_595004 != nil:
    section.add "X-Amz-Security-Token", valid_595004
  var valid_595005 = header.getOrDefault("X-Amz-Algorithm")
  valid_595005 = validateParameter(valid_595005, JString, required = false,
                                 default = nil)
  if valid_595005 != nil:
    section.add "X-Amz-Algorithm", valid_595005
  var valid_595006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595006 = validateParameter(valid_595006, JString, required = false,
                                 default = nil)
  if valid_595006 != nil:
    section.add "X-Amz-SignedHeaders", valid_595006
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595008: Call_GetMaintenanceWindowExecutionTaskInvocation_594996;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves information about a specific task running on a specific target.
  ## 
  let valid = call_595008.validator(path, query, header, formData, body)
  let scheme = call_595008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595008.url(scheme.get, call_595008.host, call_595008.base,
                         call_595008.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595008, url, valid)

proc call*(call_595009: Call_GetMaintenanceWindowExecutionTaskInvocation_594996;
          body: JsonNode): Recallable =
  ## getMaintenanceWindowExecutionTaskInvocation
  ## Retrieves information about a specific task running on a specific target.
  ##   body: JObject (required)
  var body_595010 = newJObject()
  if body != nil:
    body_595010 = body
  result = call_595009.call(nil, nil, nil, nil, body_595010)

var getMaintenanceWindowExecutionTaskInvocation* = Call_GetMaintenanceWindowExecutionTaskInvocation_594996(
    name: "getMaintenanceWindowExecutionTaskInvocation",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com", route: "/#X-Amz-Target=AmazonSSM.GetMaintenanceWindowExecutionTaskInvocation",
    validator: validate_GetMaintenanceWindowExecutionTaskInvocation_594997,
    base: "/", url: url_GetMaintenanceWindowExecutionTaskInvocation_594998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMaintenanceWindowTask_595011 = ref object of OpenApiRestCall_593389
proc url_GetMaintenanceWindowTask_595013(protocol: Scheme; host: string;
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

proc validate_GetMaintenanceWindowTask_595012(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595014 = header.getOrDefault("X-Amz-Target")
  valid_595014 = validateParameter(valid_595014, JString, required = true, default = newJString(
      "AmazonSSM.GetMaintenanceWindowTask"))
  if valid_595014 != nil:
    section.add "X-Amz-Target", valid_595014
  var valid_595015 = header.getOrDefault("X-Amz-Signature")
  valid_595015 = validateParameter(valid_595015, JString, required = false,
                                 default = nil)
  if valid_595015 != nil:
    section.add "X-Amz-Signature", valid_595015
  var valid_595016 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595016 = validateParameter(valid_595016, JString, required = false,
                                 default = nil)
  if valid_595016 != nil:
    section.add "X-Amz-Content-Sha256", valid_595016
  var valid_595017 = header.getOrDefault("X-Amz-Date")
  valid_595017 = validateParameter(valid_595017, JString, required = false,
                                 default = nil)
  if valid_595017 != nil:
    section.add "X-Amz-Date", valid_595017
  var valid_595018 = header.getOrDefault("X-Amz-Credential")
  valid_595018 = validateParameter(valid_595018, JString, required = false,
                                 default = nil)
  if valid_595018 != nil:
    section.add "X-Amz-Credential", valid_595018
  var valid_595019 = header.getOrDefault("X-Amz-Security-Token")
  valid_595019 = validateParameter(valid_595019, JString, required = false,
                                 default = nil)
  if valid_595019 != nil:
    section.add "X-Amz-Security-Token", valid_595019
  var valid_595020 = header.getOrDefault("X-Amz-Algorithm")
  valid_595020 = validateParameter(valid_595020, JString, required = false,
                                 default = nil)
  if valid_595020 != nil:
    section.add "X-Amz-Algorithm", valid_595020
  var valid_595021 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595021 = validateParameter(valid_595021, JString, required = false,
                                 default = nil)
  if valid_595021 != nil:
    section.add "X-Amz-SignedHeaders", valid_595021
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595023: Call_GetMaintenanceWindowTask_595011; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tasks in a maintenance window.
  ## 
  let valid = call_595023.validator(path, query, header, formData, body)
  let scheme = call_595023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595023.url(scheme.get, call_595023.host, call_595023.base,
                         call_595023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595023, url, valid)

proc call*(call_595024: Call_GetMaintenanceWindowTask_595011; body: JsonNode): Recallable =
  ## getMaintenanceWindowTask
  ## Lists the tasks in a maintenance window.
  ##   body: JObject (required)
  var body_595025 = newJObject()
  if body != nil:
    body_595025 = body
  result = call_595024.call(nil, nil, nil, nil, body_595025)

var getMaintenanceWindowTask* = Call_GetMaintenanceWindowTask_595011(
    name: "getMaintenanceWindowTask", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetMaintenanceWindowTask",
    validator: validate_GetMaintenanceWindowTask_595012, base: "/",
    url: url_GetMaintenanceWindowTask_595013, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOpsItem_595026 = ref object of OpenApiRestCall_593389
proc url_GetOpsItem_595028(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetOpsItem_595027(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595029 = header.getOrDefault("X-Amz-Target")
  valid_595029 = validateParameter(valid_595029, JString, required = true,
                                 default = newJString("AmazonSSM.GetOpsItem"))
  if valid_595029 != nil:
    section.add "X-Amz-Target", valid_595029
  var valid_595030 = header.getOrDefault("X-Amz-Signature")
  valid_595030 = validateParameter(valid_595030, JString, required = false,
                                 default = nil)
  if valid_595030 != nil:
    section.add "X-Amz-Signature", valid_595030
  var valid_595031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595031 = validateParameter(valid_595031, JString, required = false,
                                 default = nil)
  if valid_595031 != nil:
    section.add "X-Amz-Content-Sha256", valid_595031
  var valid_595032 = header.getOrDefault("X-Amz-Date")
  valid_595032 = validateParameter(valid_595032, JString, required = false,
                                 default = nil)
  if valid_595032 != nil:
    section.add "X-Amz-Date", valid_595032
  var valid_595033 = header.getOrDefault("X-Amz-Credential")
  valid_595033 = validateParameter(valid_595033, JString, required = false,
                                 default = nil)
  if valid_595033 != nil:
    section.add "X-Amz-Credential", valid_595033
  var valid_595034 = header.getOrDefault("X-Amz-Security-Token")
  valid_595034 = validateParameter(valid_595034, JString, required = false,
                                 default = nil)
  if valid_595034 != nil:
    section.add "X-Amz-Security-Token", valid_595034
  var valid_595035 = header.getOrDefault("X-Amz-Algorithm")
  valid_595035 = validateParameter(valid_595035, JString, required = false,
                                 default = nil)
  if valid_595035 != nil:
    section.add "X-Amz-Algorithm", valid_595035
  var valid_595036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595036 = validateParameter(valid_595036, JString, required = false,
                                 default = nil)
  if valid_595036 != nil:
    section.add "X-Amz-SignedHeaders", valid_595036
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595038: Call_GetOpsItem_595026; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Get information about an OpsItem by using the ID. You must have permission in AWS Identity and Access Management (IAM) to view information about an OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ## 
  let valid = call_595038.validator(path, query, header, formData, body)
  let scheme = call_595038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595038.url(scheme.get, call_595038.host, call_595038.base,
                         call_595038.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595038, url, valid)

proc call*(call_595039: Call_GetOpsItem_595026; body: JsonNode): Recallable =
  ## getOpsItem
  ## <p>Get information about an OpsItem by using the ID. You must have permission in AWS Identity and Access Management (IAM) to view information about an OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ##   body: JObject (required)
  var body_595040 = newJObject()
  if body != nil:
    body_595040 = body
  result = call_595039.call(nil, nil, nil, nil, body_595040)

var getOpsItem* = Call_GetOpsItem_595026(name: "getOpsItem",
                                      meth: HttpMethod.HttpPost,
                                      host: "ssm.amazonaws.com", route: "/#X-Amz-Target=AmazonSSM.GetOpsItem",
                                      validator: validate_GetOpsItem_595027,
                                      base: "/", url: url_GetOpsItem_595028,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOpsSummary_595041 = ref object of OpenApiRestCall_593389
proc url_GetOpsSummary_595043(protocol: Scheme; host: string; base: string;
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

proc validate_GetOpsSummary_595042(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595044 = header.getOrDefault("X-Amz-Target")
  valid_595044 = validateParameter(valid_595044, JString, required = true, default = newJString(
      "AmazonSSM.GetOpsSummary"))
  if valid_595044 != nil:
    section.add "X-Amz-Target", valid_595044
  var valid_595045 = header.getOrDefault("X-Amz-Signature")
  valid_595045 = validateParameter(valid_595045, JString, required = false,
                                 default = nil)
  if valid_595045 != nil:
    section.add "X-Amz-Signature", valid_595045
  var valid_595046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595046 = validateParameter(valid_595046, JString, required = false,
                                 default = nil)
  if valid_595046 != nil:
    section.add "X-Amz-Content-Sha256", valid_595046
  var valid_595047 = header.getOrDefault("X-Amz-Date")
  valid_595047 = validateParameter(valid_595047, JString, required = false,
                                 default = nil)
  if valid_595047 != nil:
    section.add "X-Amz-Date", valid_595047
  var valid_595048 = header.getOrDefault("X-Amz-Credential")
  valid_595048 = validateParameter(valid_595048, JString, required = false,
                                 default = nil)
  if valid_595048 != nil:
    section.add "X-Amz-Credential", valid_595048
  var valid_595049 = header.getOrDefault("X-Amz-Security-Token")
  valid_595049 = validateParameter(valid_595049, JString, required = false,
                                 default = nil)
  if valid_595049 != nil:
    section.add "X-Amz-Security-Token", valid_595049
  var valid_595050 = header.getOrDefault("X-Amz-Algorithm")
  valid_595050 = validateParameter(valid_595050, JString, required = false,
                                 default = nil)
  if valid_595050 != nil:
    section.add "X-Amz-Algorithm", valid_595050
  var valid_595051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595051 = validateParameter(valid_595051, JString, required = false,
                                 default = nil)
  if valid_595051 != nil:
    section.add "X-Amz-SignedHeaders", valid_595051
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595053: Call_GetOpsSummary_595041; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## View a summary of OpsItems based on specified filters and aggregators.
  ## 
  let valid = call_595053.validator(path, query, header, formData, body)
  let scheme = call_595053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595053.url(scheme.get, call_595053.host, call_595053.base,
                         call_595053.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595053, url, valid)

proc call*(call_595054: Call_GetOpsSummary_595041; body: JsonNode): Recallable =
  ## getOpsSummary
  ## View a summary of OpsItems based on specified filters and aggregators.
  ##   body: JObject (required)
  var body_595055 = newJObject()
  if body != nil:
    body_595055 = body
  result = call_595054.call(nil, nil, nil, nil, body_595055)

var getOpsSummary* = Call_GetOpsSummary_595041(name: "getOpsSummary",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetOpsSummary",
    validator: validate_GetOpsSummary_595042, base: "/", url: url_GetOpsSummary_595043,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetParameter_595056 = ref object of OpenApiRestCall_593389
proc url_GetParameter_595058(protocol: Scheme; host: string; base: string;
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

proc validate_GetParameter_595057(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595059 = header.getOrDefault("X-Amz-Target")
  valid_595059 = validateParameter(valid_595059, JString, required = true,
                                 default = newJString("AmazonSSM.GetParameter"))
  if valid_595059 != nil:
    section.add "X-Amz-Target", valid_595059
  var valid_595060 = header.getOrDefault("X-Amz-Signature")
  valid_595060 = validateParameter(valid_595060, JString, required = false,
                                 default = nil)
  if valid_595060 != nil:
    section.add "X-Amz-Signature", valid_595060
  var valid_595061 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595061 = validateParameter(valid_595061, JString, required = false,
                                 default = nil)
  if valid_595061 != nil:
    section.add "X-Amz-Content-Sha256", valid_595061
  var valid_595062 = header.getOrDefault("X-Amz-Date")
  valid_595062 = validateParameter(valid_595062, JString, required = false,
                                 default = nil)
  if valid_595062 != nil:
    section.add "X-Amz-Date", valid_595062
  var valid_595063 = header.getOrDefault("X-Amz-Credential")
  valid_595063 = validateParameter(valid_595063, JString, required = false,
                                 default = nil)
  if valid_595063 != nil:
    section.add "X-Amz-Credential", valid_595063
  var valid_595064 = header.getOrDefault("X-Amz-Security-Token")
  valid_595064 = validateParameter(valid_595064, JString, required = false,
                                 default = nil)
  if valid_595064 != nil:
    section.add "X-Amz-Security-Token", valid_595064
  var valid_595065 = header.getOrDefault("X-Amz-Algorithm")
  valid_595065 = validateParameter(valid_595065, JString, required = false,
                                 default = nil)
  if valid_595065 != nil:
    section.add "X-Amz-Algorithm", valid_595065
  var valid_595066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595066 = validateParameter(valid_595066, JString, required = false,
                                 default = nil)
  if valid_595066 != nil:
    section.add "X-Amz-SignedHeaders", valid_595066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595068: Call_GetParameter_595056; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get information about a parameter by using the parameter name. Don't confuse this API action with the <a>GetParameters</a> API action.
  ## 
  let valid = call_595068.validator(path, query, header, formData, body)
  let scheme = call_595068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595068.url(scheme.get, call_595068.host, call_595068.base,
                         call_595068.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595068, url, valid)

proc call*(call_595069: Call_GetParameter_595056; body: JsonNode): Recallable =
  ## getParameter
  ## Get information about a parameter by using the parameter name. Don't confuse this API action with the <a>GetParameters</a> API action.
  ##   body: JObject (required)
  var body_595070 = newJObject()
  if body != nil:
    body_595070 = body
  result = call_595069.call(nil, nil, nil, nil, body_595070)

var getParameter* = Call_GetParameter_595056(name: "getParameter",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetParameter",
    validator: validate_GetParameter_595057, base: "/", url: url_GetParameter_595058,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetParameterHistory_595071 = ref object of OpenApiRestCall_593389
proc url_GetParameterHistory_595073(protocol: Scheme; host: string; base: string;
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

proc validate_GetParameterHistory_595072(path: JsonNode; query: JsonNode;
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
  var valid_595074 = query.getOrDefault("MaxResults")
  valid_595074 = validateParameter(valid_595074, JString, required = false,
                                 default = nil)
  if valid_595074 != nil:
    section.add "MaxResults", valid_595074
  var valid_595075 = query.getOrDefault("NextToken")
  valid_595075 = validateParameter(valid_595075, JString, required = false,
                                 default = nil)
  if valid_595075 != nil:
    section.add "NextToken", valid_595075
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595076 = header.getOrDefault("X-Amz-Target")
  valid_595076 = validateParameter(valid_595076, JString, required = true, default = newJString(
      "AmazonSSM.GetParameterHistory"))
  if valid_595076 != nil:
    section.add "X-Amz-Target", valid_595076
  var valid_595077 = header.getOrDefault("X-Amz-Signature")
  valid_595077 = validateParameter(valid_595077, JString, required = false,
                                 default = nil)
  if valid_595077 != nil:
    section.add "X-Amz-Signature", valid_595077
  var valid_595078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595078 = validateParameter(valid_595078, JString, required = false,
                                 default = nil)
  if valid_595078 != nil:
    section.add "X-Amz-Content-Sha256", valid_595078
  var valid_595079 = header.getOrDefault("X-Amz-Date")
  valid_595079 = validateParameter(valid_595079, JString, required = false,
                                 default = nil)
  if valid_595079 != nil:
    section.add "X-Amz-Date", valid_595079
  var valid_595080 = header.getOrDefault("X-Amz-Credential")
  valid_595080 = validateParameter(valid_595080, JString, required = false,
                                 default = nil)
  if valid_595080 != nil:
    section.add "X-Amz-Credential", valid_595080
  var valid_595081 = header.getOrDefault("X-Amz-Security-Token")
  valid_595081 = validateParameter(valid_595081, JString, required = false,
                                 default = nil)
  if valid_595081 != nil:
    section.add "X-Amz-Security-Token", valid_595081
  var valid_595082 = header.getOrDefault("X-Amz-Algorithm")
  valid_595082 = validateParameter(valid_595082, JString, required = false,
                                 default = nil)
  if valid_595082 != nil:
    section.add "X-Amz-Algorithm", valid_595082
  var valid_595083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595083 = validateParameter(valid_595083, JString, required = false,
                                 default = nil)
  if valid_595083 != nil:
    section.add "X-Amz-SignedHeaders", valid_595083
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595085: Call_GetParameterHistory_595071; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Query a list of all parameters used by the AWS account.
  ## 
  let valid = call_595085.validator(path, query, header, formData, body)
  let scheme = call_595085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595085.url(scheme.get, call_595085.host, call_595085.base,
                         call_595085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595085, url, valid)

proc call*(call_595086: Call_GetParameterHistory_595071; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getParameterHistory
  ## Query a list of all parameters used by the AWS account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_595087 = newJObject()
  var body_595088 = newJObject()
  add(query_595087, "MaxResults", newJString(MaxResults))
  add(query_595087, "NextToken", newJString(NextToken))
  if body != nil:
    body_595088 = body
  result = call_595086.call(nil, query_595087, nil, nil, body_595088)

var getParameterHistory* = Call_GetParameterHistory_595071(
    name: "getParameterHistory", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetParameterHistory",
    validator: validate_GetParameterHistory_595072, base: "/",
    url: url_GetParameterHistory_595073, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetParameters_595089 = ref object of OpenApiRestCall_593389
proc url_GetParameters_595091(protocol: Scheme; host: string; base: string;
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

proc validate_GetParameters_595090(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595092 = header.getOrDefault("X-Amz-Target")
  valid_595092 = validateParameter(valid_595092, JString, required = true, default = newJString(
      "AmazonSSM.GetParameters"))
  if valid_595092 != nil:
    section.add "X-Amz-Target", valid_595092
  var valid_595093 = header.getOrDefault("X-Amz-Signature")
  valid_595093 = validateParameter(valid_595093, JString, required = false,
                                 default = nil)
  if valid_595093 != nil:
    section.add "X-Amz-Signature", valid_595093
  var valid_595094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595094 = validateParameter(valid_595094, JString, required = false,
                                 default = nil)
  if valid_595094 != nil:
    section.add "X-Amz-Content-Sha256", valid_595094
  var valid_595095 = header.getOrDefault("X-Amz-Date")
  valid_595095 = validateParameter(valid_595095, JString, required = false,
                                 default = nil)
  if valid_595095 != nil:
    section.add "X-Amz-Date", valid_595095
  var valid_595096 = header.getOrDefault("X-Amz-Credential")
  valid_595096 = validateParameter(valid_595096, JString, required = false,
                                 default = nil)
  if valid_595096 != nil:
    section.add "X-Amz-Credential", valid_595096
  var valid_595097 = header.getOrDefault("X-Amz-Security-Token")
  valid_595097 = validateParameter(valid_595097, JString, required = false,
                                 default = nil)
  if valid_595097 != nil:
    section.add "X-Amz-Security-Token", valid_595097
  var valid_595098 = header.getOrDefault("X-Amz-Algorithm")
  valid_595098 = validateParameter(valid_595098, JString, required = false,
                                 default = nil)
  if valid_595098 != nil:
    section.add "X-Amz-Algorithm", valid_595098
  var valid_595099 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595099 = validateParameter(valid_595099, JString, required = false,
                                 default = nil)
  if valid_595099 != nil:
    section.add "X-Amz-SignedHeaders", valid_595099
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595101: Call_GetParameters_595089; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get details of a parameter. Don't confuse this API action with the <a>GetParameter</a> API action.
  ## 
  let valid = call_595101.validator(path, query, header, formData, body)
  let scheme = call_595101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595101.url(scheme.get, call_595101.host, call_595101.base,
                         call_595101.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595101, url, valid)

proc call*(call_595102: Call_GetParameters_595089; body: JsonNode): Recallable =
  ## getParameters
  ## Get details of a parameter. Don't confuse this API action with the <a>GetParameter</a> API action.
  ##   body: JObject (required)
  var body_595103 = newJObject()
  if body != nil:
    body_595103 = body
  result = call_595102.call(nil, nil, nil, nil, body_595103)

var getParameters* = Call_GetParameters_595089(name: "getParameters",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetParameters",
    validator: validate_GetParameters_595090, base: "/", url: url_GetParameters_595091,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetParametersByPath_595104 = ref object of OpenApiRestCall_593389
proc url_GetParametersByPath_595106(protocol: Scheme; host: string; base: string;
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

proc validate_GetParametersByPath_595105(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Retrieve parameters in a specific hierarchy. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-paramstore-working.html">Working with Systems Manager Parameters</a> in the <i>AWS Systems Manager User Guide</i>. </p> <p>Request results are returned on a best-effort basis. If you specify <code>MaxResults</code> in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of <code>MaxResults</code>. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a <code>NextToken</code>. You can specify the <code>NextToken</code> in a subsequent call to get the next set of results.</p> <note> <p>This API action doesn't support filtering by tags. </p> </note>
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
  var valid_595107 = query.getOrDefault("MaxResults")
  valid_595107 = validateParameter(valid_595107, JString, required = false,
                                 default = nil)
  if valid_595107 != nil:
    section.add "MaxResults", valid_595107
  var valid_595108 = query.getOrDefault("NextToken")
  valid_595108 = validateParameter(valid_595108, JString, required = false,
                                 default = nil)
  if valid_595108 != nil:
    section.add "NextToken", valid_595108
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595109 = header.getOrDefault("X-Amz-Target")
  valid_595109 = validateParameter(valid_595109, JString, required = true, default = newJString(
      "AmazonSSM.GetParametersByPath"))
  if valid_595109 != nil:
    section.add "X-Amz-Target", valid_595109
  var valid_595110 = header.getOrDefault("X-Amz-Signature")
  valid_595110 = validateParameter(valid_595110, JString, required = false,
                                 default = nil)
  if valid_595110 != nil:
    section.add "X-Amz-Signature", valid_595110
  var valid_595111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595111 = validateParameter(valid_595111, JString, required = false,
                                 default = nil)
  if valid_595111 != nil:
    section.add "X-Amz-Content-Sha256", valid_595111
  var valid_595112 = header.getOrDefault("X-Amz-Date")
  valid_595112 = validateParameter(valid_595112, JString, required = false,
                                 default = nil)
  if valid_595112 != nil:
    section.add "X-Amz-Date", valid_595112
  var valid_595113 = header.getOrDefault("X-Amz-Credential")
  valid_595113 = validateParameter(valid_595113, JString, required = false,
                                 default = nil)
  if valid_595113 != nil:
    section.add "X-Amz-Credential", valid_595113
  var valid_595114 = header.getOrDefault("X-Amz-Security-Token")
  valid_595114 = validateParameter(valid_595114, JString, required = false,
                                 default = nil)
  if valid_595114 != nil:
    section.add "X-Amz-Security-Token", valid_595114
  var valid_595115 = header.getOrDefault("X-Amz-Algorithm")
  valid_595115 = validateParameter(valid_595115, JString, required = false,
                                 default = nil)
  if valid_595115 != nil:
    section.add "X-Amz-Algorithm", valid_595115
  var valid_595116 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595116 = validateParameter(valid_595116, JString, required = false,
                                 default = nil)
  if valid_595116 != nil:
    section.add "X-Amz-SignedHeaders", valid_595116
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595118: Call_GetParametersByPath_595104; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieve parameters in a specific hierarchy. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-paramstore-working.html">Working with Systems Manager Parameters</a> in the <i>AWS Systems Manager User Guide</i>. </p> <p>Request results are returned on a best-effort basis. If you specify <code>MaxResults</code> in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of <code>MaxResults</code>. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a <code>NextToken</code>. You can specify the <code>NextToken</code> in a subsequent call to get the next set of results.</p> <note> <p>This API action doesn't support filtering by tags. </p> </note>
  ## 
  let valid = call_595118.validator(path, query, header, formData, body)
  let scheme = call_595118.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595118.url(scheme.get, call_595118.host, call_595118.base,
                         call_595118.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595118, url, valid)

proc call*(call_595119: Call_GetParametersByPath_595104; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getParametersByPath
  ## <p>Retrieve parameters in a specific hierarchy. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-paramstore-working.html">Working with Systems Manager Parameters</a> in the <i>AWS Systems Manager User Guide</i>. </p> <p>Request results are returned on a best-effort basis. If you specify <code>MaxResults</code> in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of <code>MaxResults</code>. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a <code>NextToken</code>. You can specify the <code>NextToken</code> in a subsequent call to get the next set of results.</p> <note> <p>This API action doesn't support filtering by tags. </p> </note>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_595120 = newJObject()
  var body_595121 = newJObject()
  add(query_595120, "MaxResults", newJString(MaxResults))
  add(query_595120, "NextToken", newJString(NextToken))
  if body != nil:
    body_595121 = body
  result = call_595119.call(nil, query_595120, nil, nil, body_595121)

var getParametersByPath* = Call_GetParametersByPath_595104(
    name: "getParametersByPath", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetParametersByPath",
    validator: validate_GetParametersByPath_595105, base: "/",
    url: url_GetParametersByPath_595106, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPatchBaseline_595122 = ref object of OpenApiRestCall_593389
proc url_GetPatchBaseline_595124(protocol: Scheme; host: string; base: string;
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

proc validate_GetPatchBaseline_595123(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595125 = header.getOrDefault("X-Amz-Target")
  valid_595125 = validateParameter(valid_595125, JString, required = true, default = newJString(
      "AmazonSSM.GetPatchBaseline"))
  if valid_595125 != nil:
    section.add "X-Amz-Target", valid_595125
  var valid_595126 = header.getOrDefault("X-Amz-Signature")
  valid_595126 = validateParameter(valid_595126, JString, required = false,
                                 default = nil)
  if valid_595126 != nil:
    section.add "X-Amz-Signature", valid_595126
  var valid_595127 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595127 = validateParameter(valid_595127, JString, required = false,
                                 default = nil)
  if valid_595127 != nil:
    section.add "X-Amz-Content-Sha256", valid_595127
  var valid_595128 = header.getOrDefault("X-Amz-Date")
  valid_595128 = validateParameter(valid_595128, JString, required = false,
                                 default = nil)
  if valid_595128 != nil:
    section.add "X-Amz-Date", valid_595128
  var valid_595129 = header.getOrDefault("X-Amz-Credential")
  valid_595129 = validateParameter(valid_595129, JString, required = false,
                                 default = nil)
  if valid_595129 != nil:
    section.add "X-Amz-Credential", valid_595129
  var valid_595130 = header.getOrDefault("X-Amz-Security-Token")
  valid_595130 = validateParameter(valid_595130, JString, required = false,
                                 default = nil)
  if valid_595130 != nil:
    section.add "X-Amz-Security-Token", valid_595130
  var valid_595131 = header.getOrDefault("X-Amz-Algorithm")
  valid_595131 = validateParameter(valid_595131, JString, required = false,
                                 default = nil)
  if valid_595131 != nil:
    section.add "X-Amz-Algorithm", valid_595131
  var valid_595132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595132 = validateParameter(valid_595132, JString, required = false,
                                 default = nil)
  if valid_595132 != nil:
    section.add "X-Amz-SignedHeaders", valid_595132
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595134: Call_GetPatchBaseline_595122; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a patch baseline.
  ## 
  let valid = call_595134.validator(path, query, header, formData, body)
  let scheme = call_595134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595134.url(scheme.get, call_595134.host, call_595134.base,
                         call_595134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595134, url, valid)

proc call*(call_595135: Call_GetPatchBaseline_595122; body: JsonNode): Recallable =
  ## getPatchBaseline
  ## Retrieves information about a patch baseline.
  ##   body: JObject (required)
  var body_595136 = newJObject()
  if body != nil:
    body_595136 = body
  result = call_595135.call(nil, nil, nil, nil, body_595136)

var getPatchBaseline* = Call_GetPatchBaseline_595122(name: "getPatchBaseline",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetPatchBaseline",
    validator: validate_GetPatchBaseline_595123, base: "/",
    url: url_GetPatchBaseline_595124, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPatchBaselineForPatchGroup_595137 = ref object of OpenApiRestCall_593389
proc url_GetPatchBaselineForPatchGroup_595139(protocol: Scheme; host: string;
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

proc validate_GetPatchBaselineForPatchGroup_595138(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595140 = header.getOrDefault("X-Amz-Target")
  valid_595140 = validateParameter(valid_595140, JString, required = true, default = newJString(
      "AmazonSSM.GetPatchBaselineForPatchGroup"))
  if valid_595140 != nil:
    section.add "X-Amz-Target", valid_595140
  var valid_595141 = header.getOrDefault("X-Amz-Signature")
  valid_595141 = validateParameter(valid_595141, JString, required = false,
                                 default = nil)
  if valid_595141 != nil:
    section.add "X-Amz-Signature", valid_595141
  var valid_595142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595142 = validateParameter(valid_595142, JString, required = false,
                                 default = nil)
  if valid_595142 != nil:
    section.add "X-Amz-Content-Sha256", valid_595142
  var valid_595143 = header.getOrDefault("X-Amz-Date")
  valid_595143 = validateParameter(valid_595143, JString, required = false,
                                 default = nil)
  if valid_595143 != nil:
    section.add "X-Amz-Date", valid_595143
  var valid_595144 = header.getOrDefault("X-Amz-Credential")
  valid_595144 = validateParameter(valid_595144, JString, required = false,
                                 default = nil)
  if valid_595144 != nil:
    section.add "X-Amz-Credential", valid_595144
  var valid_595145 = header.getOrDefault("X-Amz-Security-Token")
  valid_595145 = validateParameter(valid_595145, JString, required = false,
                                 default = nil)
  if valid_595145 != nil:
    section.add "X-Amz-Security-Token", valid_595145
  var valid_595146 = header.getOrDefault("X-Amz-Algorithm")
  valid_595146 = validateParameter(valid_595146, JString, required = false,
                                 default = nil)
  if valid_595146 != nil:
    section.add "X-Amz-Algorithm", valid_595146
  var valid_595147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595147 = validateParameter(valid_595147, JString, required = false,
                                 default = nil)
  if valid_595147 != nil:
    section.add "X-Amz-SignedHeaders", valid_595147
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595149: Call_GetPatchBaselineForPatchGroup_595137; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the patch baseline that should be used for the specified patch group.
  ## 
  let valid = call_595149.validator(path, query, header, formData, body)
  let scheme = call_595149.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595149.url(scheme.get, call_595149.host, call_595149.base,
                         call_595149.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595149, url, valid)

proc call*(call_595150: Call_GetPatchBaselineForPatchGroup_595137; body: JsonNode): Recallable =
  ## getPatchBaselineForPatchGroup
  ## Retrieves the patch baseline that should be used for the specified patch group.
  ##   body: JObject (required)
  var body_595151 = newJObject()
  if body != nil:
    body_595151 = body
  result = call_595150.call(nil, nil, nil, nil, body_595151)

var getPatchBaselineForPatchGroup* = Call_GetPatchBaselineForPatchGroup_595137(
    name: "getPatchBaselineForPatchGroup", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetPatchBaselineForPatchGroup",
    validator: validate_GetPatchBaselineForPatchGroup_595138, base: "/",
    url: url_GetPatchBaselineForPatchGroup_595139,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetServiceSetting_595152 = ref object of OpenApiRestCall_593389
proc url_GetServiceSetting_595154(protocol: Scheme; host: string; base: string;
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

proc validate_GetServiceSetting_595153(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595155 = header.getOrDefault("X-Amz-Target")
  valid_595155 = validateParameter(valid_595155, JString, required = true, default = newJString(
      "AmazonSSM.GetServiceSetting"))
  if valid_595155 != nil:
    section.add "X-Amz-Target", valid_595155
  var valid_595156 = header.getOrDefault("X-Amz-Signature")
  valid_595156 = validateParameter(valid_595156, JString, required = false,
                                 default = nil)
  if valid_595156 != nil:
    section.add "X-Amz-Signature", valid_595156
  var valid_595157 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595157 = validateParameter(valid_595157, JString, required = false,
                                 default = nil)
  if valid_595157 != nil:
    section.add "X-Amz-Content-Sha256", valid_595157
  var valid_595158 = header.getOrDefault("X-Amz-Date")
  valid_595158 = validateParameter(valid_595158, JString, required = false,
                                 default = nil)
  if valid_595158 != nil:
    section.add "X-Amz-Date", valid_595158
  var valid_595159 = header.getOrDefault("X-Amz-Credential")
  valid_595159 = validateParameter(valid_595159, JString, required = false,
                                 default = nil)
  if valid_595159 != nil:
    section.add "X-Amz-Credential", valid_595159
  var valid_595160 = header.getOrDefault("X-Amz-Security-Token")
  valid_595160 = validateParameter(valid_595160, JString, required = false,
                                 default = nil)
  if valid_595160 != nil:
    section.add "X-Amz-Security-Token", valid_595160
  var valid_595161 = header.getOrDefault("X-Amz-Algorithm")
  valid_595161 = validateParameter(valid_595161, JString, required = false,
                                 default = nil)
  if valid_595161 != nil:
    section.add "X-Amz-Algorithm", valid_595161
  var valid_595162 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595162 = validateParameter(valid_595162, JString, required = false,
                                 default = nil)
  if valid_595162 != nil:
    section.add "X-Amz-SignedHeaders", valid_595162
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595164: Call_GetServiceSetting_595152; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>UpdateServiceSetting</a> API action to change the default setting. Or use the <a>ResetServiceSetting</a> to change the value back to the original value defined by the AWS service team.</p> <p>Query the current service setting for the account. </p>
  ## 
  let valid = call_595164.validator(path, query, header, formData, body)
  let scheme = call_595164.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595164.url(scheme.get, call_595164.host, call_595164.base,
                         call_595164.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595164, url, valid)

proc call*(call_595165: Call_GetServiceSetting_595152; body: JsonNode): Recallable =
  ## getServiceSetting
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>UpdateServiceSetting</a> API action to change the default setting. Or use the <a>ResetServiceSetting</a> to change the value back to the original value defined by the AWS service team.</p> <p>Query the current service setting for the account. </p>
  ##   body: JObject (required)
  var body_595166 = newJObject()
  if body != nil:
    body_595166 = body
  result = call_595165.call(nil, nil, nil, nil, body_595166)

var getServiceSetting* = Call_GetServiceSetting_595152(name: "getServiceSetting",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetServiceSetting",
    validator: validate_GetServiceSetting_595153, base: "/",
    url: url_GetServiceSetting_595154, schemes: {Scheme.Https, Scheme.Http})
type
  Call_LabelParameterVersion_595167 = ref object of OpenApiRestCall_593389
proc url_LabelParameterVersion_595169(protocol: Scheme; host: string; base: string;
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

proc validate_LabelParameterVersion_595168(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595170 = header.getOrDefault("X-Amz-Target")
  valid_595170 = validateParameter(valid_595170, JString, required = true, default = newJString(
      "AmazonSSM.LabelParameterVersion"))
  if valid_595170 != nil:
    section.add "X-Amz-Target", valid_595170
  var valid_595171 = header.getOrDefault("X-Amz-Signature")
  valid_595171 = validateParameter(valid_595171, JString, required = false,
                                 default = nil)
  if valid_595171 != nil:
    section.add "X-Amz-Signature", valid_595171
  var valid_595172 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595172 = validateParameter(valid_595172, JString, required = false,
                                 default = nil)
  if valid_595172 != nil:
    section.add "X-Amz-Content-Sha256", valid_595172
  var valid_595173 = header.getOrDefault("X-Amz-Date")
  valid_595173 = validateParameter(valid_595173, JString, required = false,
                                 default = nil)
  if valid_595173 != nil:
    section.add "X-Amz-Date", valid_595173
  var valid_595174 = header.getOrDefault("X-Amz-Credential")
  valid_595174 = validateParameter(valid_595174, JString, required = false,
                                 default = nil)
  if valid_595174 != nil:
    section.add "X-Amz-Credential", valid_595174
  var valid_595175 = header.getOrDefault("X-Amz-Security-Token")
  valid_595175 = validateParameter(valid_595175, JString, required = false,
                                 default = nil)
  if valid_595175 != nil:
    section.add "X-Amz-Security-Token", valid_595175
  var valid_595176 = header.getOrDefault("X-Amz-Algorithm")
  valid_595176 = validateParameter(valid_595176, JString, required = false,
                                 default = nil)
  if valid_595176 != nil:
    section.add "X-Amz-Algorithm", valid_595176
  var valid_595177 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595177 = validateParameter(valid_595177, JString, required = false,
                                 default = nil)
  if valid_595177 != nil:
    section.add "X-Amz-SignedHeaders", valid_595177
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595179: Call_LabelParameterVersion_595167; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>A parameter label is a user-defined alias to help you manage different versions of a parameter. When you modify a parameter, Systems Manager automatically saves a new version and increments the version number by one. A label can help you remember the purpose of a parameter when there are multiple versions. </p> <p>Parameter labels have the following requirements and restrictions.</p> <ul> <li> <p>A version of a parameter can have a maximum of 10 labels.</p> </li> <li> <p>You can't attach the same label to different versions of the same parameter. For example, if version 1 has the label Production, then you can't attach Production to version 2.</p> </li> <li> <p>You can move a label from one version of a parameter to another.</p> </li> <li> <p>You can't create a label when you create a new parameter. You must attach a label to a specific version of a parameter.</p> </li> <li> <p>You can't delete a parameter label. If you no longer want to use a parameter label, then you must move it to a different version of a parameter.</p> </li> <li> <p>A label can have a maximum of 100 characters.</p> </li> <li> <p>Labels can contain letters (case sensitive), numbers, periods (.), hyphens (-), or underscores (_).</p> </li> <li> <p>Labels can't begin with a number, "aws," or "ssm" (not case sensitive). If a label fails to meet these requirements, then the label is not associated with a parameter and the system displays it in the list of InvalidLabels.</p> </li> </ul>
  ## 
  let valid = call_595179.validator(path, query, header, formData, body)
  let scheme = call_595179.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595179.url(scheme.get, call_595179.host, call_595179.base,
                         call_595179.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595179, url, valid)

proc call*(call_595180: Call_LabelParameterVersion_595167; body: JsonNode): Recallable =
  ## labelParameterVersion
  ## <p>A parameter label is a user-defined alias to help you manage different versions of a parameter. When you modify a parameter, Systems Manager automatically saves a new version and increments the version number by one. A label can help you remember the purpose of a parameter when there are multiple versions. </p> <p>Parameter labels have the following requirements and restrictions.</p> <ul> <li> <p>A version of a parameter can have a maximum of 10 labels.</p> </li> <li> <p>You can't attach the same label to different versions of the same parameter. For example, if version 1 has the label Production, then you can't attach Production to version 2.</p> </li> <li> <p>You can move a label from one version of a parameter to another.</p> </li> <li> <p>You can't create a label when you create a new parameter. You must attach a label to a specific version of a parameter.</p> </li> <li> <p>You can't delete a parameter label. If you no longer want to use a parameter label, then you must move it to a different version of a parameter.</p> </li> <li> <p>A label can have a maximum of 100 characters.</p> </li> <li> <p>Labels can contain letters (case sensitive), numbers, periods (.), hyphens (-), or underscores (_).</p> </li> <li> <p>Labels can't begin with a number, "aws," or "ssm" (not case sensitive). If a label fails to meet these requirements, then the label is not associated with a parameter and the system displays it in the list of InvalidLabels.</p> </li> </ul>
  ##   body: JObject (required)
  var body_595181 = newJObject()
  if body != nil:
    body_595181 = body
  result = call_595180.call(nil, nil, nil, nil, body_595181)

var labelParameterVersion* = Call_LabelParameterVersion_595167(
    name: "labelParameterVersion", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.LabelParameterVersion",
    validator: validate_LabelParameterVersion_595168, base: "/",
    url: url_LabelParameterVersion_595169, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssociationVersions_595182 = ref object of OpenApiRestCall_593389
proc url_ListAssociationVersions_595184(protocol: Scheme; host: string; base: string;
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

proc validate_ListAssociationVersions_595183(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595185 = header.getOrDefault("X-Amz-Target")
  valid_595185 = validateParameter(valid_595185, JString, required = true, default = newJString(
      "AmazonSSM.ListAssociationVersions"))
  if valid_595185 != nil:
    section.add "X-Amz-Target", valid_595185
  var valid_595186 = header.getOrDefault("X-Amz-Signature")
  valid_595186 = validateParameter(valid_595186, JString, required = false,
                                 default = nil)
  if valid_595186 != nil:
    section.add "X-Amz-Signature", valid_595186
  var valid_595187 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595187 = validateParameter(valid_595187, JString, required = false,
                                 default = nil)
  if valid_595187 != nil:
    section.add "X-Amz-Content-Sha256", valid_595187
  var valid_595188 = header.getOrDefault("X-Amz-Date")
  valid_595188 = validateParameter(valid_595188, JString, required = false,
                                 default = nil)
  if valid_595188 != nil:
    section.add "X-Amz-Date", valid_595188
  var valid_595189 = header.getOrDefault("X-Amz-Credential")
  valid_595189 = validateParameter(valid_595189, JString, required = false,
                                 default = nil)
  if valid_595189 != nil:
    section.add "X-Amz-Credential", valid_595189
  var valid_595190 = header.getOrDefault("X-Amz-Security-Token")
  valid_595190 = validateParameter(valid_595190, JString, required = false,
                                 default = nil)
  if valid_595190 != nil:
    section.add "X-Amz-Security-Token", valid_595190
  var valid_595191 = header.getOrDefault("X-Amz-Algorithm")
  valid_595191 = validateParameter(valid_595191, JString, required = false,
                                 default = nil)
  if valid_595191 != nil:
    section.add "X-Amz-Algorithm", valid_595191
  var valid_595192 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595192 = validateParameter(valid_595192, JString, required = false,
                                 default = nil)
  if valid_595192 != nil:
    section.add "X-Amz-SignedHeaders", valid_595192
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595194: Call_ListAssociationVersions_595182; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves all versions of an association for a specific association ID.
  ## 
  let valid = call_595194.validator(path, query, header, formData, body)
  let scheme = call_595194.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595194.url(scheme.get, call_595194.host, call_595194.base,
                         call_595194.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595194, url, valid)

proc call*(call_595195: Call_ListAssociationVersions_595182; body: JsonNode): Recallable =
  ## listAssociationVersions
  ## Retrieves all versions of an association for a specific association ID.
  ##   body: JObject (required)
  var body_595196 = newJObject()
  if body != nil:
    body_595196 = body
  result = call_595195.call(nil, nil, nil, nil, body_595196)

var listAssociationVersions* = Call_ListAssociationVersions_595182(
    name: "listAssociationVersions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListAssociationVersions",
    validator: validate_ListAssociationVersions_595183, base: "/",
    url: url_ListAssociationVersions_595184, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssociations_595197 = ref object of OpenApiRestCall_593389
proc url_ListAssociations_595199(protocol: Scheme; host: string; base: string;
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

proc validate_ListAssociations_595198(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Lists the associations for the specified Systems Manager document or instance.
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
  var valid_595200 = query.getOrDefault("MaxResults")
  valid_595200 = validateParameter(valid_595200, JString, required = false,
                                 default = nil)
  if valid_595200 != nil:
    section.add "MaxResults", valid_595200
  var valid_595201 = query.getOrDefault("NextToken")
  valid_595201 = validateParameter(valid_595201, JString, required = false,
                                 default = nil)
  if valid_595201 != nil:
    section.add "NextToken", valid_595201
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595202 = header.getOrDefault("X-Amz-Target")
  valid_595202 = validateParameter(valid_595202, JString, required = true, default = newJString(
      "AmazonSSM.ListAssociations"))
  if valid_595202 != nil:
    section.add "X-Amz-Target", valid_595202
  var valid_595203 = header.getOrDefault("X-Amz-Signature")
  valid_595203 = validateParameter(valid_595203, JString, required = false,
                                 default = nil)
  if valid_595203 != nil:
    section.add "X-Amz-Signature", valid_595203
  var valid_595204 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595204 = validateParameter(valid_595204, JString, required = false,
                                 default = nil)
  if valid_595204 != nil:
    section.add "X-Amz-Content-Sha256", valid_595204
  var valid_595205 = header.getOrDefault("X-Amz-Date")
  valid_595205 = validateParameter(valid_595205, JString, required = false,
                                 default = nil)
  if valid_595205 != nil:
    section.add "X-Amz-Date", valid_595205
  var valid_595206 = header.getOrDefault("X-Amz-Credential")
  valid_595206 = validateParameter(valid_595206, JString, required = false,
                                 default = nil)
  if valid_595206 != nil:
    section.add "X-Amz-Credential", valid_595206
  var valid_595207 = header.getOrDefault("X-Amz-Security-Token")
  valid_595207 = validateParameter(valid_595207, JString, required = false,
                                 default = nil)
  if valid_595207 != nil:
    section.add "X-Amz-Security-Token", valid_595207
  var valid_595208 = header.getOrDefault("X-Amz-Algorithm")
  valid_595208 = validateParameter(valid_595208, JString, required = false,
                                 default = nil)
  if valid_595208 != nil:
    section.add "X-Amz-Algorithm", valid_595208
  var valid_595209 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595209 = validateParameter(valid_595209, JString, required = false,
                                 default = nil)
  if valid_595209 != nil:
    section.add "X-Amz-SignedHeaders", valid_595209
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595211: Call_ListAssociations_595197; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the associations for the specified Systems Manager document or instance.
  ## 
  let valid = call_595211.validator(path, query, header, formData, body)
  let scheme = call_595211.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595211.url(scheme.get, call_595211.host, call_595211.base,
                         call_595211.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595211, url, valid)

proc call*(call_595212: Call_ListAssociations_595197; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listAssociations
  ## Lists the associations for the specified Systems Manager document or instance.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_595213 = newJObject()
  var body_595214 = newJObject()
  add(query_595213, "MaxResults", newJString(MaxResults))
  add(query_595213, "NextToken", newJString(NextToken))
  if body != nil:
    body_595214 = body
  result = call_595212.call(nil, query_595213, nil, nil, body_595214)

var listAssociations* = Call_ListAssociations_595197(name: "listAssociations",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListAssociations",
    validator: validate_ListAssociations_595198, base: "/",
    url: url_ListAssociations_595199, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCommandInvocations_595215 = ref object of OpenApiRestCall_593389
proc url_ListCommandInvocations_595217(protocol: Scheme; host: string; base: string;
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

proc validate_ListCommandInvocations_595216(path: JsonNode; query: JsonNode;
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
  var valid_595218 = query.getOrDefault("MaxResults")
  valid_595218 = validateParameter(valid_595218, JString, required = false,
                                 default = nil)
  if valid_595218 != nil:
    section.add "MaxResults", valid_595218
  var valid_595219 = query.getOrDefault("NextToken")
  valid_595219 = validateParameter(valid_595219, JString, required = false,
                                 default = nil)
  if valid_595219 != nil:
    section.add "NextToken", valid_595219
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595220 = header.getOrDefault("X-Amz-Target")
  valid_595220 = validateParameter(valid_595220, JString, required = true, default = newJString(
      "AmazonSSM.ListCommandInvocations"))
  if valid_595220 != nil:
    section.add "X-Amz-Target", valid_595220
  var valid_595221 = header.getOrDefault("X-Amz-Signature")
  valid_595221 = validateParameter(valid_595221, JString, required = false,
                                 default = nil)
  if valid_595221 != nil:
    section.add "X-Amz-Signature", valid_595221
  var valid_595222 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595222 = validateParameter(valid_595222, JString, required = false,
                                 default = nil)
  if valid_595222 != nil:
    section.add "X-Amz-Content-Sha256", valid_595222
  var valid_595223 = header.getOrDefault("X-Amz-Date")
  valid_595223 = validateParameter(valid_595223, JString, required = false,
                                 default = nil)
  if valid_595223 != nil:
    section.add "X-Amz-Date", valid_595223
  var valid_595224 = header.getOrDefault("X-Amz-Credential")
  valid_595224 = validateParameter(valid_595224, JString, required = false,
                                 default = nil)
  if valid_595224 != nil:
    section.add "X-Amz-Credential", valid_595224
  var valid_595225 = header.getOrDefault("X-Amz-Security-Token")
  valid_595225 = validateParameter(valid_595225, JString, required = false,
                                 default = nil)
  if valid_595225 != nil:
    section.add "X-Amz-Security-Token", valid_595225
  var valid_595226 = header.getOrDefault("X-Amz-Algorithm")
  valid_595226 = validateParameter(valid_595226, JString, required = false,
                                 default = nil)
  if valid_595226 != nil:
    section.add "X-Amz-Algorithm", valid_595226
  var valid_595227 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595227 = validateParameter(valid_595227, JString, required = false,
                                 default = nil)
  if valid_595227 != nil:
    section.add "X-Amz-SignedHeaders", valid_595227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595229: Call_ListCommandInvocations_595215; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## An invocation is copy of a command sent to a specific instance. A command can apply to one or more instances. A command invocation applies to one instance. For example, if a user runs SendCommand against three instances, then a command invocation is created for each requested instance ID. ListCommandInvocations provide status about command execution.
  ## 
  let valid = call_595229.validator(path, query, header, formData, body)
  let scheme = call_595229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595229.url(scheme.get, call_595229.host, call_595229.base,
                         call_595229.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595229, url, valid)

proc call*(call_595230: Call_ListCommandInvocations_595215; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listCommandInvocations
  ## An invocation is copy of a command sent to a specific instance. A command can apply to one or more instances. A command invocation applies to one instance. For example, if a user runs SendCommand against three instances, then a command invocation is created for each requested instance ID. ListCommandInvocations provide status about command execution.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_595231 = newJObject()
  var body_595232 = newJObject()
  add(query_595231, "MaxResults", newJString(MaxResults))
  add(query_595231, "NextToken", newJString(NextToken))
  if body != nil:
    body_595232 = body
  result = call_595230.call(nil, query_595231, nil, nil, body_595232)

var listCommandInvocations* = Call_ListCommandInvocations_595215(
    name: "listCommandInvocations", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListCommandInvocations",
    validator: validate_ListCommandInvocations_595216, base: "/",
    url: url_ListCommandInvocations_595217, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCommands_595233 = ref object of OpenApiRestCall_593389
proc url_ListCommands_595235(protocol: Scheme; host: string; base: string;
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

proc validate_ListCommands_595234(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595236 = query.getOrDefault("MaxResults")
  valid_595236 = validateParameter(valid_595236, JString, required = false,
                                 default = nil)
  if valid_595236 != nil:
    section.add "MaxResults", valid_595236
  var valid_595237 = query.getOrDefault("NextToken")
  valid_595237 = validateParameter(valid_595237, JString, required = false,
                                 default = nil)
  if valid_595237 != nil:
    section.add "NextToken", valid_595237
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595238 = header.getOrDefault("X-Amz-Target")
  valid_595238 = validateParameter(valid_595238, JString, required = true,
                                 default = newJString("AmazonSSM.ListCommands"))
  if valid_595238 != nil:
    section.add "X-Amz-Target", valid_595238
  var valid_595239 = header.getOrDefault("X-Amz-Signature")
  valid_595239 = validateParameter(valid_595239, JString, required = false,
                                 default = nil)
  if valid_595239 != nil:
    section.add "X-Amz-Signature", valid_595239
  var valid_595240 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595240 = validateParameter(valid_595240, JString, required = false,
                                 default = nil)
  if valid_595240 != nil:
    section.add "X-Amz-Content-Sha256", valid_595240
  var valid_595241 = header.getOrDefault("X-Amz-Date")
  valid_595241 = validateParameter(valid_595241, JString, required = false,
                                 default = nil)
  if valid_595241 != nil:
    section.add "X-Amz-Date", valid_595241
  var valid_595242 = header.getOrDefault("X-Amz-Credential")
  valid_595242 = validateParameter(valid_595242, JString, required = false,
                                 default = nil)
  if valid_595242 != nil:
    section.add "X-Amz-Credential", valid_595242
  var valid_595243 = header.getOrDefault("X-Amz-Security-Token")
  valid_595243 = validateParameter(valid_595243, JString, required = false,
                                 default = nil)
  if valid_595243 != nil:
    section.add "X-Amz-Security-Token", valid_595243
  var valid_595244 = header.getOrDefault("X-Amz-Algorithm")
  valid_595244 = validateParameter(valid_595244, JString, required = false,
                                 default = nil)
  if valid_595244 != nil:
    section.add "X-Amz-Algorithm", valid_595244
  var valid_595245 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595245 = validateParameter(valid_595245, JString, required = false,
                                 default = nil)
  if valid_595245 != nil:
    section.add "X-Amz-SignedHeaders", valid_595245
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595247: Call_ListCommands_595233; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the commands requested by users of the AWS account.
  ## 
  let valid = call_595247.validator(path, query, header, formData, body)
  let scheme = call_595247.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595247.url(scheme.get, call_595247.host, call_595247.base,
                         call_595247.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595247, url, valid)

proc call*(call_595248: Call_ListCommands_595233; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listCommands
  ## Lists the commands requested by users of the AWS account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_595249 = newJObject()
  var body_595250 = newJObject()
  add(query_595249, "MaxResults", newJString(MaxResults))
  add(query_595249, "NextToken", newJString(NextToken))
  if body != nil:
    body_595250 = body
  result = call_595248.call(nil, query_595249, nil, nil, body_595250)

var listCommands* = Call_ListCommands_595233(name: "listCommands",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListCommands",
    validator: validate_ListCommands_595234, base: "/", url: url_ListCommands_595235,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListComplianceItems_595251 = ref object of OpenApiRestCall_593389
proc url_ListComplianceItems_595253(protocol: Scheme; host: string; base: string;
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

proc validate_ListComplianceItems_595252(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595254 = header.getOrDefault("X-Amz-Target")
  valid_595254 = validateParameter(valid_595254, JString, required = true, default = newJString(
      "AmazonSSM.ListComplianceItems"))
  if valid_595254 != nil:
    section.add "X-Amz-Target", valid_595254
  var valid_595255 = header.getOrDefault("X-Amz-Signature")
  valid_595255 = validateParameter(valid_595255, JString, required = false,
                                 default = nil)
  if valid_595255 != nil:
    section.add "X-Amz-Signature", valid_595255
  var valid_595256 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595256 = validateParameter(valid_595256, JString, required = false,
                                 default = nil)
  if valid_595256 != nil:
    section.add "X-Amz-Content-Sha256", valid_595256
  var valid_595257 = header.getOrDefault("X-Amz-Date")
  valid_595257 = validateParameter(valid_595257, JString, required = false,
                                 default = nil)
  if valid_595257 != nil:
    section.add "X-Amz-Date", valid_595257
  var valid_595258 = header.getOrDefault("X-Amz-Credential")
  valid_595258 = validateParameter(valid_595258, JString, required = false,
                                 default = nil)
  if valid_595258 != nil:
    section.add "X-Amz-Credential", valid_595258
  var valid_595259 = header.getOrDefault("X-Amz-Security-Token")
  valid_595259 = validateParameter(valid_595259, JString, required = false,
                                 default = nil)
  if valid_595259 != nil:
    section.add "X-Amz-Security-Token", valid_595259
  var valid_595260 = header.getOrDefault("X-Amz-Algorithm")
  valid_595260 = validateParameter(valid_595260, JString, required = false,
                                 default = nil)
  if valid_595260 != nil:
    section.add "X-Amz-Algorithm", valid_595260
  var valid_595261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595261 = validateParameter(valid_595261, JString, required = false,
                                 default = nil)
  if valid_595261 != nil:
    section.add "X-Amz-SignedHeaders", valid_595261
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595263: Call_ListComplianceItems_595251; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## For a specified resource ID, this API action returns a list of compliance statuses for different resource types. Currently, you can only specify one resource ID per call. List results depend on the criteria specified in the filter. 
  ## 
  let valid = call_595263.validator(path, query, header, formData, body)
  let scheme = call_595263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595263.url(scheme.get, call_595263.host, call_595263.base,
                         call_595263.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595263, url, valid)

proc call*(call_595264: Call_ListComplianceItems_595251; body: JsonNode): Recallable =
  ## listComplianceItems
  ## For a specified resource ID, this API action returns a list of compliance statuses for different resource types. Currently, you can only specify one resource ID per call. List results depend on the criteria specified in the filter. 
  ##   body: JObject (required)
  var body_595265 = newJObject()
  if body != nil:
    body_595265 = body
  result = call_595264.call(nil, nil, nil, nil, body_595265)

var listComplianceItems* = Call_ListComplianceItems_595251(
    name: "listComplianceItems", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListComplianceItems",
    validator: validate_ListComplianceItems_595252, base: "/",
    url: url_ListComplianceItems_595253, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListComplianceSummaries_595266 = ref object of OpenApiRestCall_593389
proc url_ListComplianceSummaries_595268(protocol: Scheme; host: string; base: string;
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

proc validate_ListComplianceSummaries_595267(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595269 = header.getOrDefault("X-Amz-Target")
  valid_595269 = validateParameter(valid_595269, JString, required = true, default = newJString(
      "AmazonSSM.ListComplianceSummaries"))
  if valid_595269 != nil:
    section.add "X-Amz-Target", valid_595269
  var valid_595270 = header.getOrDefault("X-Amz-Signature")
  valid_595270 = validateParameter(valid_595270, JString, required = false,
                                 default = nil)
  if valid_595270 != nil:
    section.add "X-Amz-Signature", valid_595270
  var valid_595271 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595271 = validateParameter(valid_595271, JString, required = false,
                                 default = nil)
  if valid_595271 != nil:
    section.add "X-Amz-Content-Sha256", valid_595271
  var valid_595272 = header.getOrDefault("X-Amz-Date")
  valid_595272 = validateParameter(valid_595272, JString, required = false,
                                 default = nil)
  if valid_595272 != nil:
    section.add "X-Amz-Date", valid_595272
  var valid_595273 = header.getOrDefault("X-Amz-Credential")
  valid_595273 = validateParameter(valid_595273, JString, required = false,
                                 default = nil)
  if valid_595273 != nil:
    section.add "X-Amz-Credential", valid_595273
  var valid_595274 = header.getOrDefault("X-Amz-Security-Token")
  valid_595274 = validateParameter(valid_595274, JString, required = false,
                                 default = nil)
  if valid_595274 != nil:
    section.add "X-Amz-Security-Token", valid_595274
  var valid_595275 = header.getOrDefault("X-Amz-Algorithm")
  valid_595275 = validateParameter(valid_595275, JString, required = false,
                                 default = nil)
  if valid_595275 != nil:
    section.add "X-Amz-Algorithm", valid_595275
  var valid_595276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595276 = validateParameter(valid_595276, JString, required = false,
                                 default = nil)
  if valid_595276 != nil:
    section.add "X-Amz-SignedHeaders", valid_595276
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595278: Call_ListComplianceSummaries_595266; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a summary count of compliant and non-compliant resources for a compliance type. For example, this call can return State Manager associations, patches, or custom compliance types according to the filter criteria that you specify. 
  ## 
  let valid = call_595278.validator(path, query, header, formData, body)
  let scheme = call_595278.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595278.url(scheme.get, call_595278.host, call_595278.base,
                         call_595278.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595278, url, valid)

proc call*(call_595279: Call_ListComplianceSummaries_595266; body: JsonNode): Recallable =
  ## listComplianceSummaries
  ## Returns a summary count of compliant and non-compliant resources for a compliance type. For example, this call can return State Manager associations, patches, or custom compliance types according to the filter criteria that you specify. 
  ##   body: JObject (required)
  var body_595280 = newJObject()
  if body != nil:
    body_595280 = body
  result = call_595279.call(nil, nil, nil, nil, body_595280)

var listComplianceSummaries* = Call_ListComplianceSummaries_595266(
    name: "listComplianceSummaries", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListComplianceSummaries",
    validator: validate_ListComplianceSummaries_595267, base: "/",
    url: url_ListComplianceSummaries_595268, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDocumentVersions_595281 = ref object of OpenApiRestCall_593389
proc url_ListDocumentVersions_595283(protocol: Scheme; host: string; base: string;
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

proc validate_ListDocumentVersions_595282(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595284 = header.getOrDefault("X-Amz-Target")
  valid_595284 = validateParameter(valid_595284, JString, required = true, default = newJString(
      "AmazonSSM.ListDocumentVersions"))
  if valid_595284 != nil:
    section.add "X-Amz-Target", valid_595284
  var valid_595285 = header.getOrDefault("X-Amz-Signature")
  valid_595285 = validateParameter(valid_595285, JString, required = false,
                                 default = nil)
  if valid_595285 != nil:
    section.add "X-Amz-Signature", valid_595285
  var valid_595286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595286 = validateParameter(valid_595286, JString, required = false,
                                 default = nil)
  if valid_595286 != nil:
    section.add "X-Amz-Content-Sha256", valid_595286
  var valid_595287 = header.getOrDefault("X-Amz-Date")
  valid_595287 = validateParameter(valid_595287, JString, required = false,
                                 default = nil)
  if valid_595287 != nil:
    section.add "X-Amz-Date", valid_595287
  var valid_595288 = header.getOrDefault("X-Amz-Credential")
  valid_595288 = validateParameter(valid_595288, JString, required = false,
                                 default = nil)
  if valid_595288 != nil:
    section.add "X-Amz-Credential", valid_595288
  var valid_595289 = header.getOrDefault("X-Amz-Security-Token")
  valid_595289 = validateParameter(valid_595289, JString, required = false,
                                 default = nil)
  if valid_595289 != nil:
    section.add "X-Amz-Security-Token", valid_595289
  var valid_595290 = header.getOrDefault("X-Amz-Algorithm")
  valid_595290 = validateParameter(valid_595290, JString, required = false,
                                 default = nil)
  if valid_595290 != nil:
    section.add "X-Amz-Algorithm", valid_595290
  var valid_595291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595291 = validateParameter(valid_595291, JString, required = false,
                                 default = nil)
  if valid_595291 != nil:
    section.add "X-Amz-SignedHeaders", valid_595291
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595293: Call_ListDocumentVersions_595281; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all versions for a document.
  ## 
  let valid = call_595293.validator(path, query, header, formData, body)
  let scheme = call_595293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595293.url(scheme.get, call_595293.host, call_595293.base,
                         call_595293.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595293, url, valid)

proc call*(call_595294: Call_ListDocumentVersions_595281; body: JsonNode): Recallable =
  ## listDocumentVersions
  ## List all versions for a document.
  ##   body: JObject (required)
  var body_595295 = newJObject()
  if body != nil:
    body_595295 = body
  result = call_595294.call(nil, nil, nil, nil, body_595295)

var listDocumentVersions* = Call_ListDocumentVersions_595281(
    name: "listDocumentVersions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListDocumentVersions",
    validator: validate_ListDocumentVersions_595282, base: "/",
    url: url_ListDocumentVersions_595283, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDocuments_595296 = ref object of OpenApiRestCall_593389
proc url_ListDocuments_595298(protocol: Scheme; host: string; base: string;
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

proc validate_ListDocuments_595297(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes one or more of your Systems Manager documents.
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
  var valid_595299 = query.getOrDefault("MaxResults")
  valid_595299 = validateParameter(valid_595299, JString, required = false,
                                 default = nil)
  if valid_595299 != nil:
    section.add "MaxResults", valid_595299
  var valid_595300 = query.getOrDefault("NextToken")
  valid_595300 = validateParameter(valid_595300, JString, required = false,
                                 default = nil)
  if valid_595300 != nil:
    section.add "NextToken", valid_595300
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595301 = header.getOrDefault("X-Amz-Target")
  valid_595301 = validateParameter(valid_595301, JString, required = true, default = newJString(
      "AmazonSSM.ListDocuments"))
  if valid_595301 != nil:
    section.add "X-Amz-Target", valid_595301
  var valid_595302 = header.getOrDefault("X-Amz-Signature")
  valid_595302 = validateParameter(valid_595302, JString, required = false,
                                 default = nil)
  if valid_595302 != nil:
    section.add "X-Amz-Signature", valid_595302
  var valid_595303 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595303 = validateParameter(valid_595303, JString, required = false,
                                 default = nil)
  if valid_595303 != nil:
    section.add "X-Amz-Content-Sha256", valid_595303
  var valid_595304 = header.getOrDefault("X-Amz-Date")
  valid_595304 = validateParameter(valid_595304, JString, required = false,
                                 default = nil)
  if valid_595304 != nil:
    section.add "X-Amz-Date", valid_595304
  var valid_595305 = header.getOrDefault("X-Amz-Credential")
  valid_595305 = validateParameter(valid_595305, JString, required = false,
                                 default = nil)
  if valid_595305 != nil:
    section.add "X-Amz-Credential", valid_595305
  var valid_595306 = header.getOrDefault("X-Amz-Security-Token")
  valid_595306 = validateParameter(valid_595306, JString, required = false,
                                 default = nil)
  if valid_595306 != nil:
    section.add "X-Amz-Security-Token", valid_595306
  var valid_595307 = header.getOrDefault("X-Amz-Algorithm")
  valid_595307 = validateParameter(valid_595307, JString, required = false,
                                 default = nil)
  if valid_595307 != nil:
    section.add "X-Amz-Algorithm", valid_595307
  var valid_595308 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595308 = validateParameter(valid_595308, JString, required = false,
                                 default = nil)
  if valid_595308 != nil:
    section.add "X-Amz-SignedHeaders", valid_595308
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595310: Call_ListDocuments_595296; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes one or more of your Systems Manager documents.
  ## 
  let valid = call_595310.validator(path, query, header, formData, body)
  let scheme = call_595310.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595310.url(scheme.get, call_595310.host, call_595310.base,
                         call_595310.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595310, url, valid)

proc call*(call_595311: Call_ListDocuments_595296; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDocuments
  ## Describes one or more of your Systems Manager documents.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_595312 = newJObject()
  var body_595313 = newJObject()
  add(query_595312, "MaxResults", newJString(MaxResults))
  add(query_595312, "NextToken", newJString(NextToken))
  if body != nil:
    body_595313 = body
  result = call_595311.call(nil, query_595312, nil, nil, body_595313)

var listDocuments* = Call_ListDocuments_595296(name: "listDocuments",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListDocuments",
    validator: validate_ListDocuments_595297, base: "/", url: url_ListDocuments_595298,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInventoryEntries_595314 = ref object of OpenApiRestCall_593389
proc url_ListInventoryEntries_595316(protocol: Scheme; host: string; base: string;
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

proc validate_ListInventoryEntries_595315(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595317 = header.getOrDefault("X-Amz-Target")
  valid_595317 = validateParameter(valid_595317, JString, required = true, default = newJString(
      "AmazonSSM.ListInventoryEntries"))
  if valid_595317 != nil:
    section.add "X-Amz-Target", valid_595317
  var valid_595318 = header.getOrDefault("X-Amz-Signature")
  valid_595318 = validateParameter(valid_595318, JString, required = false,
                                 default = nil)
  if valid_595318 != nil:
    section.add "X-Amz-Signature", valid_595318
  var valid_595319 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595319 = validateParameter(valid_595319, JString, required = false,
                                 default = nil)
  if valid_595319 != nil:
    section.add "X-Amz-Content-Sha256", valid_595319
  var valid_595320 = header.getOrDefault("X-Amz-Date")
  valid_595320 = validateParameter(valid_595320, JString, required = false,
                                 default = nil)
  if valid_595320 != nil:
    section.add "X-Amz-Date", valid_595320
  var valid_595321 = header.getOrDefault("X-Amz-Credential")
  valid_595321 = validateParameter(valid_595321, JString, required = false,
                                 default = nil)
  if valid_595321 != nil:
    section.add "X-Amz-Credential", valid_595321
  var valid_595322 = header.getOrDefault("X-Amz-Security-Token")
  valid_595322 = validateParameter(valid_595322, JString, required = false,
                                 default = nil)
  if valid_595322 != nil:
    section.add "X-Amz-Security-Token", valid_595322
  var valid_595323 = header.getOrDefault("X-Amz-Algorithm")
  valid_595323 = validateParameter(valid_595323, JString, required = false,
                                 default = nil)
  if valid_595323 != nil:
    section.add "X-Amz-Algorithm", valid_595323
  var valid_595324 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595324 = validateParameter(valid_595324, JString, required = false,
                                 default = nil)
  if valid_595324 != nil:
    section.add "X-Amz-SignedHeaders", valid_595324
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595326: Call_ListInventoryEntries_595314; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## A list of inventory items returned by the request.
  ## 
  let valid = call_595326.validator(path, query, header, formData, body)
  let scheme = call_595326.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595326.url(scheme.get, call_595326.host, call_595326.base,
                         call_595326.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595326, url, valid)

proc call*(call_595327: Call_ListInventoryEntries_595314; body: JsonNode): Recallable =
  ## listInventoryEntries
  ## A list of inventory items returned by the request.
  ##   body: JObject (required)
  var body_595328 = newJObject()
  if body != nil:
    body_595328 = body
  result = call_595327.call(nil, nil, nil, nil, body_595328)

var listInventoryEntries* = Call_ListInventoryEntries_595314(
    name: "listInventoryEntries", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListInventoryEntries",
    validator: validate_ListInventoryEntries_595315, base: "/",
    url: url_ListInventoryEntries_595316, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceComplianceSummaries_595329 = ref object of OpenApiRestCall_593389
proc url_ListResourceComplianceSummaries_595331(protocol: Scheme; host: string;
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

proc validate_ListResourceComplianceSummaries_595330(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595332 = header.getOrDefault("X-Amz-Target")
  valid_595332 = validateParameter(valid_595332, JString, required = true, default = newJString(
      "AmazonSSM.ListResourceComplianceSummaries"))
  if valid_595332 != nil:
    section.add "X-Amz-Target", valid_595332
  var valid_595333 = header.getOrDefault("X-Amz-Signature")
  valid_595333 = validateParameter(valid_595333, JString, required = false,
                                 default = nil)
  if valid_595333 != nil:
    section.add "X-Amz-Signature", valid_595333
  var valid_595334 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595334 = validateParameter(valid_595334, JString, required = false,
                                 default = nil)
  if valid_595334 != nil:
    section.add "X-Amz-Content-Sha256", valid_595334
  var valid_595335 = header.getOrDefault("X-Amz-Date")
  valid_595335 = validateParameter(valid_595335, JString, required = false,
                                 default = nil)
  if valid_595335 != nil:
    section.add "X-Amz-Date", valid_595335
  var valid_595336 = header.getOrDefault("X-Amz-Credential")
  valid_595336 = validateParameter(valid_595336, JString, required = false,
                                 default = nil)
  if valid_595336 != nil:
    section.add "X-Amz-Credential", valid_595336
  var valid_595337 = header.getOrDefault("X-Amz-Security-Token")
  valid_595337 = validateParameter(valid_595337, JString, required = false,
                                 default = nil)
  if valid_595337 != nil:
    section.add "X-Amz-Security-Token", valid_595337
  var valid_595338 = header.getOrDefault("X-Amz-Algorithm")
  valid_595338 = validateParameter(valid_595338, JString, required = false,
                                 default = nil)
  if valid_595338 != nil:
    section.add "X-Amz-Algorithm", valid_595338
  var valid_595339 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595339 = validateParameter(valid_595339, JString, required = false,
                                 default = nil)
  if valid_595339 != nil:
    section.add "X-Amz-SignedHeaders", valid_595339
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595341: Call_ListResourceComplianceSummaries_595329;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a resource-level summary count. The summary includes information about compliant and non-compliant statuses and detailed compliance-item severity counts, according to the filter criteria you specify.
  ## 
  let valid = call_595341.validator(path, query, header, formData, body)
  let scheme = call_595341.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595341.url(scheme.get, call_595341.host, call_595341.base,
                         call_595341.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595341, url, valid)

proc call*(call_595342: Call_ListResourceComplianceSummaries_595329; body: JsonNode): Recallable =
  ## listResourceComplianceSummaries
  ## Returns a resource-level summary count. The summary includes information about compliant and non-compliant statuses and detailed compliance-item severity counts, according to the filter criteria you specify.
  ##   body: JObject (required)
  var body_595343 = newJObject()
  if body != nil:
    body_595343 = body
  result = call_595342.call(nil, nil, nil, nil, body_595343)

var listResourceComplianceSummaries* = Call_ListResourceComplianceSummaries_595329(
    name: "listResourceComplianceSummaries", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListResourceComplianceSummaries",
    validator: validate_ListResourceComplianceSummaries_595330, base: "/",
    url: url_ListResourceComplianceSummaries_595331,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceDataSync_595344 = ref object of OpenApiRestCall_593389
proc url_ListResourceDataSync_595346(protocol: Scheme; host: string; base: string;
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

proc validate_ListResourceDataSync_595345(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595347 = header.getOrDefault("X-Amz-Target")
  valid_595347 = validateParameter(valid_595347, JString, required = true, default = newJString(
      "AmazonSSM.ListResourceDataSync"))
  if valid_595347 != nil:
    section.add "X-Amz-Target", valid_595347
  var valid_595348 = header.getOrDefault("X-Amz-Signature")
  valid_595348 = validateParameter(valid_595348, JString, required = false,
                                 default = nil)
  if valid_595348 != nil:
    section.add "X-Amz-Signature", valid_595348
  var valid_595349 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595349 = validateParameter(valid_595349, JString, required = false,
                                 default = nil)
  if valid_595349 != nil:
    section.add "X-Amz-Content-Sha256", valid_595349
  var valid_595350 = header.getOrDefault("X-Amz-Date")
  valid_595350 = validateParameter(valid_595350, JString, required = false,
                                 default = nil)
  if valid_595350 != nil:
    section.add "X-Amz-Date", valid_595350
  var valid_595351 = header.getOrDefault("X-Amz-Credential")
  valid_595351 = validateParameter(valid_595351, JString, required = false,
                                 default = nil)
  if valid_595351 != nil:
    section.add "X-Amz-Credential", valid_595351
  var valid_595352 = header.getOrDefault("X-Amz-Security-Token")
  valid_595352 = validateParameter(valid_595352, JString, required = false,
                                 default = nil)
  if valid_595352 != nil:
    section.add "X-Amz-Security-Token", valid_595352
  var valid_595353 = header.getOrDefault("X-Amz-Algorithm")
  valid_595353 = validateParameter(valid_595353, JString, required = false,
                                 default = nil)
  if valid_595353 != nil:
    section.add "X-Amz-Algorithm", valid_595353
  var valid_595354 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595354 = validateParameter(valid_595354, JString, required = false,
                                 default = nil)
  if valid_595354 != nil:
    section.add "X-Amz-SignedHeaders", valid_595354
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595356: Call_ListResourceDataSync_595344; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists your resource data sync configurations. Includes information about the last time a sync attempted to start, the last sync status, and the last time a sync successfully completed.</p> <p>The number of sync configurations might be too large to return using a single call to <code>ListResourceDataSync</code>. You can limit the number of sync configurations returned by using the <code>MaxResults</code> parameter. To determine whether there are more sync configurations to list, check the value of <code>NextToken</code> in the output. If there are more sync configurations to list, you can request them by specifying the <code>NextToken</code> returned in the call to the parameter of a subsequent call. </p>
  ## 
  let valid = call_595356.validator(path, query, header, formData, body)
  let scheme = call_595356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595356.url(scheme.get, call_595356.host, call_595356.base,
                         call_595356.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595356, url, valid)

proc call*(call_595357: Call_ListResourceDataSync_595344; body: JsonNode): Recallable =
  ## listResourceDataSync
  ## <p>Lists your resource data sync configurations. Includes information about the last time a sync attempted to start, the last sync status, and the last time a sync successfully completed.</p> <p>The number of sync configurations might be too large to return using a single call to <code>ListResourceDataSync</code>. You can limit the number of sync configurations returned by using the <code>MaxResults</code> parameter. To determine whether there are more sync configurations to list, check the value of <code>NextToken</code> in the output. If there are more sync configurations to list, you can request them by specifying the <code>NextToken</code> returned in the call to the parameter of a subsequent call. </p>
  ##   body: JObject (required)
  var body_595358 = newJObject()
  if body != nil:
    body_595358 = body
  result = call_595357.call(nil, nil, nil, nil, body_595358)

var listResourceDataSync* = Call_ListResourceDataSync_595344(
    name: "listResourceDataSync", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListResourceDataSync",
    validator: validate_ListResourceDataSync_595345, base: "/",
    url: url_ListResourceDataSync_595346, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_595359 = ref object of OpenApiRestCall_593389
proc url_ListTagsForResource_595361(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_595360(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595362 = header.getOrDefault("X-Amz-Target")
  valid_595362 = validateParameter(valid_595362, JString, required = true, default = newJString(
      "AmazonSSM.ListTagsForResource"))
  if valid_595362 != nil:
    section.add "X-Amz-Target", valid_595362
  var valid_595363 = header.getOrDefault("X-Amz-Signature")
  valid_595363 = validateParameter(valid_595363, JString, required = false,
                                 default = nil)
  if valid_595363 != nil:
    section.add "X-Amz-Signature", valid_595363
  var valid_595364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595364 = validateParameter(valid_595364, JString, required = false,
                                 default = nil)
  if valid_595364 != nil:
    section.add "X-Amz-Content-Sha256", valid_595364
  var valid_595365 = header.getOrDefault("X-Amz-Date")
  valid_595365 = validateParameter(valid_595365, JString, required = false,
                                 default = nil)
  if valid_595365 != nil:
    section.add "X-Amz-Date", valid_595365
  var valid_595366 = header.getOrDefault("X-Amz-Credential")
  valid_595366 = validateParameter(valid_595366, JString, required = false,
                                 default = nil)
  if valid_595366 != nil:
    section.add "X-Amz-Credential", valid_595366
  var valid_595367 = header.getOrDefault("X-Amz-Security-Token")
  valid_595367 = validateParameter(valid_595367, JString, required = false,
                                 default = nil)
  if valid_595367 != nil:
    section.add "X-Amz-Security-Token", valid_595367
  var valid_595368 = header.getOrDefault("X-Amz-Algorithm")
  valid_595368 = validateParameter(valid_595368, JString, required = false,
                                 default = nil)
  if valid_595368 != nil:
    section.add "X-Amz-Algorithm", valid_595368
  var valid_595369 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595369 = validateParameter(valid_595369, JString, required = false,
                                 default = nil)
  if valid_595369 != nil:
    section.add "X-Amz-SignedHeaders", valid_595369
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595371: Call_ListTagsForResource_595359; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the tags assigned to the specified resource.
  ## 
  let valid = call_595371.validator(path, query, header, formData, body)
  let scheme = call_595371.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595371.url(scheme.get, call_595371.host, call_595371.base,
                         call_595371.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595371, url, valid)

proc call*(call_595372: Call_ListTagsForResource_595359; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Returns a list of the tags assigned to the specified resource.
  ##   body: JObject (required)
  var body_595373 = newJObject()
  if body != nil:
    body_595373 = body
  result = call_595372.call(nil, nil, nil, nil, body_595373)

var listTagsForResource* = Call_ListTagsForResource_595359(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListTagsForResource",
    validator: validate_ListTagsForResource_595360, base: "/",
    url: url_ListTagsForResource_595361, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyDocumentPermission_595374 = ref object of OpenApiRestCall_593389
proc url_ModifyDocumentPermission_595376(protocol: Scheme; host: string;
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

proc validate_ModifyDocumentPermission_595375(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595377 = header.getOrDefault("X-Amz-Target")
  valid_595377 = validateParameter(valid_595377, JString, required = true, default = newJString(
      "AmazonSSM.ModifyDocumentPermission"))
  if valid_595377 != nil:
    section.add "X-Amz-Target", valid_595377
  var valid_595378 = header.getOrDefault("X-Amz-Signature")
  valid_595378 = validateParameter(valid_595378, JString, required = false,
                                 default = nil)
  if valid_595378 != nil:
    section.add "X-Amz-Signature", valid_595378
  var valid_595379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595379 = validateParameter(valid_595379, JString, required = false,
                                 default = nil)
  if valid_595379 != nil:
    section.add "X-Amz-Content-Sha256", valid_595379
  var valid_595380 = header.getOrDefault("X-Amz-Date")
  valid_595380 = validateParameter(valid_595380, JString, required = false,
                                 default = nil)
  if valid_595380 != nil:
    section.add "X-Amz-Date", valid_595380
  var valid_595381 = header.getOrDefault("X-Amz-Credential")
  valid_595381 = validateParameter(valid_595381, JString, required = false,
                                 default = nil)
  if valid_595381 != nil:
    section.add "X-Amz-Credential", valid_595381
  var valid_595382 = header.getOrDefault("X-Amz-Security-Token")
  valid_595382 = validateParameter(valid_595382, JString, required = false,
                                 default = nil)
  if valid_595382 != nil:
    section.add "X-Amz-Security-Token", valid_595382
  var valid_595383 = header.getOrDefault("X-Amz-Algorithm")
  valid_595383 = validateParameter(valid_595383, JString, required = false,
                                 default = nil)
  if valid_595383 != nil:
    section.add "X-Amz-Algorithm", valid_595383
  var valid_595384 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595384 = validateParameter(valid_595384, JString, required = false,
                                 default = nil)
  if valid_595384 != nil:
    section.add "X-Amz-SignedHeaders", valid_595384
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595386: Call_ModifyDocumentPermission_595374; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Shares a Systems Manager document publicly or privately. If you share a document privately, you must specify the AWS user account IDs for those people who can use the document. If you share a document publicly, you must specify <i>All</i> as the account ID.
  ## 
  let valid = call_595386.validator(path, query, header, formData, body)
  let scheme = call_595386.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595386.url(scheme.get, call_595386.host, call_595386.base,
                         call_595386.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595386, url, valid)

proc call*(call_595387: Call_ModifyDocumentPermission_595374; body: JsonNode): Recallable =
  ## modifyDocumentPermission
  ## Shares a Systems Manager document publicly or privately. If you share a document privately, you must specify the AWS user account IDs for those people who can use the document. If you share a document publicly, you must specify <i>All</i> as the account ID.
  ##   body: JObject (required)
  var body_595388 = newJObject()
  if body != nil:
    body_595388 = body
  result = call_595387.call(nil, nil, nil, nil, body_595388)

var modifyDocumentPermission* = Call_ModifyDocumentPermission_595374(
    name: "modifyDocumentPermission", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ModifyDocumentPermission",
    validator: validate_ModifyDocumentPermission_595375, base: "/",
    url: url_ModifyDocumentPermission_595376, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutComplianceItems_595389 = ref object of OpenApiRestCall_593389
proc url_PutComplianceItems_595391(protocol: Scheme; host: string; base: string;
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

proc validate_PutComplianceItems_595390(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595392 = header.getOrDefault("X-Amz-Target")
  valid_595392 = validateParameter(valid_595392, JString, required = true, default = newJString(
      "AmazonSSM.PutComplianceItems"))
  if valid_595392 != nil:
    section.add "X-Amz-Target", valid_595392
  var valid_595393 = header.getOrDefault("X-Amz-Signature")
  valid_595393 = validateParameter(valid_595393, JString, required = false,
                                 default = nil)
  if valid_595393 != nil:
    section.add "X-Amz-Signature", valid_595393
  var valid_595394 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595394 = validateParameter(valid_595394, JString, required = false,
                                 default = nil)
  if valid_595394 != nil:
    section.add "X-Amz-Content-Sha256", valid_595394
  var valid_595395 = header.getOrDefault("X-Amz-Date")
  valid_595395 = validateParameter(valid_595395, JString, required = false,
                                 default = nil)
  if valid_595395 != nil:
    section.add "X-Amz-Date", valid_595395
  var valid_595396 = header.getOrDefault("X-Amz-Credential")
  valid_595396 = validateParameter(valid_595396, JString, required = false,
                                 default = nil)
  if valid_595396 != nil:
    section.add "X-Amz-Credential", valid_595396
  var valid_595397 = header.getOrDefault("X-Amz-Security-Token")
  valid_595397 = validateParameter(valid_595397, JString, required = false,
                                 default = nil)
  if valid_595397 != nil:
    section.add "X-Amz-Security-Token", valid_595397
  var valid_595398 = header.getOrDefault("X-Amz-Algorithm")
  valid_595398 = validateParameter(valid_595398, JString, required = false,
                                 default = nil)
  if valid_595398 != nil:
    section.add "X-Amz-Algorithm", valid_595398
  var valid_595399 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595399 = validateParameter(valid_595399, JString, required = false,
                                 default = nil)
  if valid_595399 != nil:
    section.add "X-Amz-SignedHeaders", valid_595399
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595401: Call_PutComplianceItems_595389; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Registers a compliance type and other compliance details on a designated resource. This action lets you register custom compliance details with a resource. This call overwrites existing compliance information on the resource, so you must provide a full list of compliance items each time that you send the request.</p> <p>ComplianceType can be one of the following:</p> <ul> <li> <p>ExecutionId: The execution ID when the patch, association, or custom compliance item was applied.</p> </li> <li> <p>ExecutionType: Specify patch, association, or Custom:<code>string</code>.</p> </li> <li> <p>ExecutionTime. The time the patch, association, or custom compliance item was applied to the instance.</p> </li> <li> <p>Id: The patch, association, or custom compliance ID.</p> </li> <li> <p>Title: A title.</p> </li> <li> <p>Status: The status of the compliance item. For example, <code>approved</code> for patches, or <code>Failed</code> for associations.</p> </li> <li> <p>Severity: A patch severity. For example, <code>critical</code>.</p> </li> <li> <p>DocumentName: A SSM document name. For example, AWS-RunPatchBaseline.</p> </li> <li> <p>DocumentVersion: An SSM document version number. For example, 4.</p> </li> <li> <p>Classification: A patch classification. For example, <code>security updates</code>.</p> </li> <li> <p>PatchBaselineId: A patch baseline ID.</p> </li> <li> <p>PatchSeverity: A patch severity. For example, <code>Critical</code>.</p> </li> <li> <p>PatchState: A patch state. For example, <code>InstancesWithFailedPatches</code>.</p> </li> <li> <p>PatchGroup: The name of a patch group.</p> </li> <li> <p>InstalledTime: The time the association, patch, or custom compliance item was applied to the resource. Specify the time by using the following format: yyyy-MM-dd'T'HH:mm:ss'Z'</p> </li> </ul>
  ## 
  let valid = call_595401.validator(path, query, header, formData, body)
  let scheme = call_595401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595401.url(scheme.get, call_595401.host, call_595401.base,
                         call_595401.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595401, url, valid)

proc call*(call_595402: Call_PutComplianceItems_595389; body: JsonNode): Recallable =
  ## putComplianceItems
  ## <p>Registers a compliance type and other compliance details on a designated resource. This action lets you register custom compliance details with a resource. This call overwrites existing compliance information on the resource, so you must provide a full list of compliance items each time that you send the request.</p> <p>ComplianceType can be one of the following:</p> <ul> <li> <p>ExecutionId: The execution ID when the patch, association, or custom compliance item was applied.</p> </li> <li> <p>ExecutionType: Specify patch, association, or Custom:<code>string</code>.</p> </li> <li> <p>ExecutionTime. The time the patch, association, or custom compliance item was applied to the instance.</p> </li> <li> <p>Id: The patch, association, or custom compliance ID.</p> </li> <li> <p>Title: A title.</p> </li> <li> <p>Status: The status of the compliance item. For example, <code>approved</code> for patches, or <code>Failed</code> for associations.</p> </li> <li> <p>Severity: A patch severity. For example, <code>critical</code>.</p> </li> <li> <p>DocumentName: A SSM document name. For example, AWS-RunPatchBaseline.</p> </li> <li> <p>DocumentVersion: An SSM document version number. For example, 4.</p> </li> <li> <p>Classification: A patch classification. For example, <code>security updates</code>.</p> </li> <li> <p>PatchBaselineId: A patch baseline ID.</p> </li> <li> <p>PatchSeverity: A patch severity. For example, <code>Critical</code>.</p> </li> <li> <p>PatchState: A patch state. For example, <code>InstancesWithFailedPatches</code>.</p> </li> <li> <p>PatchGroup: The name of a patch group.</p> </li> <li> <p>InstalledTime: The time the association, patch, or custom compliance item was applied to the resource. Specify the time by using the following format: yyyy-MM-dd'T'HH:mm:ss'Z'</p> </li> </ul>
  ##   body: JObject (required)
  var body_595403 = newJObject()
  if body != nil:
    body_595403 = body
  result = call_595402.call(nil, nil, nil, nil, body_595403)

var putComplianceItems* = Call_PutComplianceItems_595389(
    name: "putComplianceItems", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.PutComplianceItems",
    validator: validate_PutComplianceItems_595390, base: "/",
    url: url_PutComplianceItems_595391, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutInventory_595404 = ref object of OpenApiRestCall_593389
proc url_PutInventory_595406(protocol: Scheme; host: string; base: string;
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

proc validate_PutInventory_595405(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595407 = header.getOrDefault("X-Amz-Target")
  valid_595407 = validateParameter(valid_595407, JString, required = true,
                                 default = newJString("AmazonSSM.PutInventory"))
  if valid_595407 != nil:
    section.add "X-Amz-Target", valid_595407
  var valid_595408 = header.getOrDefault("X-Amz-Signature")
  valid_595408 = validateParameter(valid_595408, JString, required = false,
                                 default = nil)
  if valid_595408 != nil:
    section.add "X-Amz-Signature", valid_595408
  var valid_595409 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595409 = validateParameter(valid_595409, JString, required = false,
                                 default = nil)
  if valid_595409 != nil:
    section.add "X-Amz-Content-Sha256", valid_595409
  var valid_595410 = header.getOrDefault("X-Amz-Date")
  valid_595410 = validateParameter(valid_595410, JString, required = false,
                                 default = nil)
  if valid_595410 != nil:
    section.add "X-Amz-Date", valid_595410
  var valid_595411 = header.getOrDefault("X-Amz-Credential")
  valid_595411 = validateParameter(valid_595411, JString, required = false,
                                 default = nil)
  if valid_595411 != nil:
    section.add "X-Amz-Credential", valid_595411
  var valid_595412 = header.getOrDefault("X-Amz-Security-Token")
  valid_595412 = validateParameter(valid_595412, JString, required = false,
                                 default = nil)
  if valid_595412 != nil:
    section.add "X-Amz-Security-Token", valid_595412
  var valid_595413 = header.getOrDefault("X-Amz-Algorithm")
  valid_595413 = validateParameter(valid_595413, JString, required = false,
                                 default = nil)
  if valid_595413 != nil:
    section.add "X-Amz-Algorithm", valid_595413
  var valid_595414 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595414 = validateParameter(valid_595414, JString, required = false,
                                 default = nil)
  if valid_595414 != nil:
    section.add "X-Amz-SignedHeaders", valid_595414
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595416: Call_PutInventory_595404; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Bulk update custom inventory items on one more instance. The request adds an inventory item, if it doesn't already exist, or updates an inventory item, if it does exist.
  ## 
  let valid = call_595416.validator(path, query, header, formData, body)
  let scheme = call_595416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595416.url(scheme.get, call_595416.host, call_595416.base,
                         call_595416.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595416, url, valid)

proc call*(call_595417: Call_PutInventory_595404; body: JsonNode): Recallable =
  ## putInventory
  ## Bulk update custom inventory items on one more instance. The request adds an inventory item, if it doesn't already exist, or updates an inventory item, if it does exist.
  ##   body: JObject (required)
  var body_595418 = newJObject()
  if body != nil:
    body_595418 = body
  result = call_595417.call(nil, nil, nil, nil, body_595418)

var putInventory* = Call_PutInventory_595404(name: "putInventory",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.PutInventory",
    validator: validate_PutInventory_595405, base: "/", url: url_PutInventory_595406,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutParameter_595419 = ref object of OpenApiRestCall_593389
proc url_PutParameter_595421(protocol: Scheme; host: string; base: string;
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

proc validate_PutParameter_595420(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595422 = header.getOrDefault("X-Amz-Target")
  valid_595422 = validateParameter(valid_595422, JString, required = true,
                                 default = newJString("AmazonSSM.PutParameter"))
  if valid_595422 != nil:
    section.add "X-Amz-Target", valid_595422
  var valid_595423 = header.getOrDefault("X-Amz-Signature")
  valid_595423 = validateParameter(valid_595423, JString, required = false,
                                 default = nil)
  if valid_595423 != nil:
    section.add "X-Amz-Signature", valid_595423
  var valid_595424 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595424 = validateParameter(valid_595424, JString, required = false,
                                 default = nil)
  if valid_595424 != nil:
    section.add "X-Amz-Content-Sha256", valid_595424
  var valid_595425 = header.getOrDefault("X-Amz-Date")
  valid_595425 = validateParameter(valid_595425, JString, required = false,
                                 default = nil)
  if valid_595425 != nil:
    section.add "X-Amz-Date", valid_595425
  var valid_595426 = header.getOrDefault("X-Amz-Credential")
  valid_595426 = validateParameter(valid_595426, JString, required = false,
                                 default = nil)
  if valid_595426 != nil:
    section.add "X-Amz-Credential", valid_595426
  var valid_595427 = header.getOrDefault("X-Amz-Security-Token")
  valid_595427 = validateParameter(valid_595427, JString, required = false,
                                 default = nil)
  if valid_595427 != nil:
    section.add "X-Amz-Security-Token", valid_595427
  var valid_595428 = header.getOrDefault("X-Amz-Algorithm")
  valid_595428 = validateParameter(valid_595428, JString, required = false,
                                 default = nil)
  if valid_595428 != nil:
    section.add "X-Amz-Algorithm", valid_595428
  var valid_595429 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595429 = validateParameter(valid_595429, JString, required = false,
                                 default = nil)
  if valid_595429 != nil:
    section.add "X-Amz-SignedHeaders", valid_595429
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595431: Call_PutParameter_595419; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Add a parameter to the system.
  ## 
  let valid = call_595431.validator(path, query, header, formData, body)
  let scheme = call_595431.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595431.url(scheme.get, call_595431.host, call_595431.base,
                         call_595431.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595431, url, valid)

proc call*(call_595432: Call_PutParameter_595419; body: JsonNode): Recallable =
  ## putParameter
  ## Add a parameter to the system.
  ##   body: JObject (required)
  var body_595433 = newJObject()
  if body != nil:
    body_595433 = body
  result = call_595432.call(nil, nil, nil, nil, body_595433)

var putParameter* = Call_PutParameter_595419(name: "putParameter",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.PutParameter",
    validator: validate_PutParameter_595420, base: "/", url: url_PutParameter_595421,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterDefaultPatchBaseline_595434 = ref object of OpenApiRestCall_593389
proc url_RegisterDefaultPatchBaseline_595436(protocol: Scheme; host: string;
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

proc validate_RegisterDefaultPatchBaseline_595435(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595437 = header.getOrDefault("X-Amz-Target")
  valid_595437 = validateParameter(valid_595437, JString, required = true, default = newJString(
      "AmazonSSM.RegisterDefaultPatchBaseline"))
  if valid_595437 != nil:
    section.add "X-Amz-Target", valid_595437
  var valid_595438 = header.getOrDefault("X-Amz-Signature")
  valid_595438 = validateParameter(valid_595438, JString, required = false,
                                 default = nil)
  if valid_595438 != nil:
    section.add "X-Amz-Signature", valid_595438
  var valid_595439 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595439 = validateParameter(valid_595439, JString, required = false,
                                 default = nil)
  if valid_595439 != nil:
    section.add "X-Amz-Content-Sha256", valid_595439
  var valid_595440 = header.getOrDefault("X-Amz-Date")
  valid_595440 = validateParameter(valid_595440, JString, required = false,
                                 default = nil)
  if valid_595440 != nil:
    section.add "X-Amz-Date", valid_595440
  var valid_595441 = header.getOrDefault("X-Amz-Credential")
  valid_595441 = validateParameter(valid_595441, JString, required = false,
                                 default = nil)
  if valid_595441 != nil:
    section.add "X-Amz-Credential", valid_595441
  var valid_595442 = header.getOrDefault("X-Amz-Security-Token")
  valid_595442 = validateParameter(valid_595442, JString, required = false,
                                 default = nil)
  if valid_595442 != nil:
    section.add "X-Amz-Security-Token", valid_595442
  var valid_595443 = header.getOrDefault("X-Amz-Algorithm")
  valid_595443 = validateParameter(valid_595443, JString, required = false,
                                 default = nil)
  if valid_595443 != nil:
    section.add "X-Amz-Algorithm", valid_595443
  var valid_595444 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595444 = validateParameter(valid_595444, JString, required = false,
                                 default = nil)
  if valid_595444 != nil:
    section.add "X-Amz-SignedHeaders", valid_595444
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595446: Call_RegisterDefaultPatchBaseline_595434; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Defines the default patch baseline for the relevant operating system.</p> <p>To reset the AWS predefined patch baseline as the default, specify the full patch baseline ARN as the baseline ID value. For example, for CentOS, specify <code>arn:aws:ssm:us-east-2:733109147000:patchbaseline/pb-0574b43a65ea646ed</code> instead of <code>pb-0574b43a65ea646ed</code>.</p>
  ## 
  let valid = call_595446.validator(path, query, header, formData, body)
  let scheme = call_595446.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595446.url(scheme.get, call_595446.host, call_595446.base,
                         call_595446.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595446, url, valid)

proc call*(call_595447: Call_RegisterDefaultPatchBaseline_595434; body: JsonNode): Recallable =
  ## registerDefaultPatchBaseline
  ## <p>Defines the default patch baseline for the relevant operating system.</p> <p>To reset the AWS predefined patch baseline as the default, specify the full patch baseline ARN as the baseline ID value. For example, for CentOS, specify <code>arn:aws:ssm:us-east-2:733109147000:patchbaseline/pb-0574b43a65ea646ed</code> instead of <code>pb-0574b43a65ea646ed</code>.</p>
  ##   body: JObject (required)
  var body_595448 = newJObject()
  if body != nil:
    body_595448 = body
  result = call_595447.call(nil, nil, nil, nil, body_595448)

var registerDefaultPatchBaseline* = Call_RegisterDefaultPatchBaseline_595434(
    name: "registerDefaultPatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.RegisterDefaultPatchBaseline",
    validator: validate_RegisterDefaultPatchBaseline_595435, base: "/",
    url: url_RegisterDefaultPatchBaseline_595436,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterPatchBaselineForPatchGroup_595449 = ref object of OpenApiRestCall_593389
proc url_RegisterPatchBaselineForPatchGroup_595451(protocol: Scheme; host: string;
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

proc validate_RegisterPatchBaselineForPatchGroup_595450(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595452 = header.getOrDefault("X-Amz-Target")
  valid_595452 = validateParameter(valid_595452, JString, required = true, default = newJString(
      "AmazonSSM.RegisterPatchBaselineForPatchGroup"))
  if valid_595452 != nil:
    section.add "X-Amz-Target", valid_595452
  var valid_595453 = header.getOrDefault("X-Amz-Signature")
  valid_595453 = validateParameter(valid_595453, JString, required = false,
                                 default = nil)
  if valid_595453 != nil:
    section.add "X-Amz-Signature", valid_595453
  var valid_595454 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595454 = validateParameter(valid_595454, JString, required = false,
                                 default = nil)
  if valid_595454 != nil:
    section.add "X-Amz-Content-Sha256", valid_595454
  var valid_595455 = header.getOrDefault("X-Amz-Date")
  valid_595455 = validateParameter(valid_595455, JString, required = false,
                                 default = nil)
  if valid_595455 != nil:
    section.add "X-Amz-Date", valid_595455
  var valid_595456 = header.getOrDefault("X-Amz-Credential")
  valid_595456 = validateParameter(valid_595456, JString, required = false,
                                 default = nil)
  if valid_595456 != nil:
    section.add "X-Amz-Credential", valid_595456
  var valid_595457 = header.getOrDefault("X-Amz-Security-Token")
  valid_595457 = validateParameter(valid_595457, JString, required = false,
                                 default = nil)
  if valid_595457 != nil:
    section.add "X-Amz-Security-Token", valid_595457
  var valid_595458 = header.getOrDefault("X-Amz-Algorithm")
  valid_595458 = validateParameter(valid_595458, JString, required = false,
                                 default = nil)
  if valid_595458 != nil:
    section.add "X-Amz-Algorithm", valid_595458
  var valid_595459 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595459 = validateParameter(valid_595459, JString, required = false,
                                 default = nil)
  if valid_595459 != nil:
    section.add "X-Amz-SignedHeaders", valid_595459
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595461: Call_RegisterPatchBaselineForPatchGroup_595449;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Registers a patch baseline for a patch group.
  ## 
  let valid = call_595461.validator(path, query, header, formData, body)
  let scheme = call_595461.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595461.url(scheme.get, call_595461.host, call_595461.base,
                         call_595461.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595461, url, valid)

proc call*(call_595462: Call_RegisterPatchBaselineForPatchGroup_595449;
          body: JsonNode): Recallable =
  ## registerPatchBaselineForPatchGroup
  ## Registers a patch baseline for a patch group.
  ##   body: JObject (required)
  var body_595463 = newJObject()
  if body != nil:
    body_595463 = body
  result = call_595462.call(nil, nil, nil, nil, body_595463)

var registerPatchBaselineForPatchGroup* = Call_RegisterPatchBaselineForPatchGroup_595449(
    name: "registerPatchBaselineForPatchGroup", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.RegisterPatchBaselineForPatchGroup",
    validator: validate_RegisterPatchBaselineForPatchGroup_595450, base: "/",
    url: url_RegisterPatchBaselineForPatchGroup_595451,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterTargetWithMaintenanceWindow_595464 = ref object of OpenApiRestCall_593389
proc url_RegisterTargetWithMaintenanceWindow_595466(protocol: Scheme; host: string;
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

proc validate_RegisterTargetWithMaintenanceWindow_595465(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595467 = header.getOrDefault("X-Amz-Target")
  valid_595467 = validateParameter(valid_595467, JString, required = true, default = newJString(
      "AmazonSSM.RegisterTargetWithMaintenanceWindow"))
  if valid_595467 != nil:
    section.add "X-Amz-Target", valid_595467
  var valid_595468 = header.getOrDefault("X-Amz-Signature")
  valid_595468 = validateParameter(valid_595468, JString, required = false,
                                 default = nil)
  if valid_595468 != nil:
    section.add "X-Amz-Signature", valid_595468
  var valid_595469 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595469 = validateParameter(valid_595469, JString, required = false,
                                 default = nil)
  if valid_595469 != nil:
    section.add "X-Amz-Content-Sha256", valid_595469
  var valid_595470 = header.getOrDefault("X-Amz-Date")
  valid_595470 = validateParameter(valid_595470, JString, required = false,
                                 default = nil)
  if valid_595470 != nil:
    section.add "X-Amz-Date", valid_595470
  var valid_595471 = header.getOrDefault("X-Amz-Credential")
  valid_595471 = validateParameter(valid_595471, JString, required = false,
                                 default = nil)
  if valid_595471 != nil:
    section.add "X-Amz-Credential", valid_595471
  var valid_595472 = header.getOrDefault("X-Amz-Security-Token")
  valid_595472 = validateParameter(valid_595472, JString, required = false,
                                 default = nil)
  if valid_595472 != nil:
    section.add "X-Amz-Security-Token", valid_595472
  var valid_595473 = header.getOrDefault("X-Amz-Algorithm")
  valid_595473 = validateParameter(valid_595473, JString, required = false,
                                 default = nil)
  if valid_595473 != nil:
    section.add "X-Amz-Algorithm", valid_595473
  var valid_595474 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595474 = validateParameter(valid_595474, JString, required = false,
                                 default = nil)
  if valid_595474 != nil:
    section.add "X-Amz-SignedHeaders", valid_595474
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595476: Call_RegisterTargetWithMaintenanceWindow_595464;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Registers a target with a maintenance window.
  ## 
  let valid = call_595476.validator(path, query, header, formData, body)
  let scheme = call_595476.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595476.url(scheme.get, call_595476.host, call_595476.base,
                         call_595476.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595476, url, valid)

proc call*(call_595477: Call_RegisterTargetWithMaintenanceWindow_595464;
          body: JsonNode): Recallable =
  ## registerTargetWithMaintenanceWindow
  ## Registers a target with a maintenance window.
  ##   body: JObject (required)
  var body_595478 = newJObject()
  if body != nil:
    body_595478 = body
  result = call_595477.call(nil, nil, nil, nil, body_595478)

var registerTargetWithMaintenanceWindow* = Call_RegisterTargetWithMaintenanceWindow_595464(
    name: "registerTargetWithMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.RegisterTargetWithMaintenanceWindow",
    validator: validate_RegisterTargetWithMaintenanceWindow_595465, base: "/",
    url: url_RegisterTargetWithMaintenanceWindow_595466,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterTaskWithMaintenanceWindow_595479 = ref object of OpenApiRestCall_593389
proc url_RegisterTaskWithMaintenanceWindow_595481(protocol: Scheme; host: string;
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

proc validate_RegisterTaskWithMaintenanceWindow_595480(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595482 = header.getOrDefault("X-Amz-Target")
  valid_595482 = validateParameter(valid_595482, JString, required = true, default = newJString(
      "AmazonSSM.RegisterTaskWithMaintenanceWindow"))
  if valid_595482 != nil:
    section.add "X-Amz-Target", valid_595482
  var valid_595483 = header.getOrDefault("X-Amz-Signature")
  valid_595483 = validateParameter(valid_595483, JString, required = false,
                                 default = nil)
  if valid_595483 != nil:
    section.add "X-Amz-Signature", valid_595483
  var valid_595484 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595484 = validateParameter(valid_595484, JString, required = false,
                                 default = nil)
  if valid_595484 != nil:
    section.add "X-Amz-Content-Sha256", valid_595484
  var valid_595485 = header.getOrDefault("X-Amz-Date")
  valid_595485 = validateParameter(valid_595485, JString, required = false,
                                 default = nil)
  if valid_595485 != nil:
    section.add "X-Amz-Date", valid_595485
  var valid_595486 = header.getOrDefault("X-Amz-Credential")
  valid_595486 = validateParameter(valid_595486, JString, required = false,
                                 default = nil)
  if valid_595486 != nil:
    section.add "X-Amz-Credential", valid_595486
  var valid_595487 = header.getOrDefault("X-Amz-Security-Token")
  valid_595487 = validateParameter(valid_595487, JString, required = false,
                                 default = nil)
  if valid_595487 != nil:
    section.add "X-Amz-Security-Token", valid_595487
  var valid_595488 = header.getOrDefault("X-Amz-Algorithm")
  valid_595488 = validateParameter(valid_595488, JString, required = false,
                                 default = nil)
  if valid_595488 != nil:
    section.add "X-Amz-Algorithm", valid_595488
  var valid_595489 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595489 = validateParameter(valid_595489, JString, required = false,
                                 default = nil)
  if valid_595489 != nil:
    section.add "X-Amz-SignedHeaders", valid_595489
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595491: Call_RegisterTaskWithMaintenanceWindow_595479;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Adds a new task to a maintenance window.
  ## 
  let valid = call_595491.validator(path, query, header, formData, body)
  let scheme = call_595491.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595491.url(scheme.get, call_595491.host, call_595491.base,
                         call_595491.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595491, url, valid)

proc call*(call_595492: Call_RegisterTaskWithMaintenanceWindow_595479;
          body: JsonNode): Recallable =
  ## registerTaskWithMaintenanceWindow
  ## Adds a new task to a maintenance window.
  ##   body: JObject (required)
  var body_595493 = newJObject()
  if body != nil:
    body_595493 = body
  result = call_595492.call(nil, nil, nil, nil, body_595493)

var registerTaskWithMaintenanceWindow* = Call_RegisterTaskWithMaintenanceWindow_595479(
    name: "registerTaskWithMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.RegisterTaskWithMaintenanceWindow",
    validator: validate_RegisterTaskWithMaintenanceWindow_595480, base: "/",
    url: url_RegisterTaskWithMaintenanceWindow_595481,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveTagsFromResource_595494 = ref object of OpenApiRestCall_593389
proc url_RemoveTagsFromResource_595496(protocol: Scheme; host: string; base: string;
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

proc validate_RemoveTagsFromResource_595495(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595497 = header.getOrDefault("X-Amz-Target")
  valid_595497 = validateParameter(valid_595497, JString, required = true, default = newJString(
      "AmazonSSM.RemoveTagsFromResource"))
  if valid_595497 != nil:
    section.add "X-Amz-Target", valid_595497
  var valid_595498 = header.getOrDefault("X-Amz-Signature")
  valid_595498 = validateParameter(valid_595498, JString, required = false,
                                 default = nil)
  if valid_595498 != nil:
    section.add "X-Amz-Signature", valid_595498
  var valid_595499 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595499 = validateParameter(valid_595499, JString, required = false,
                                 default = nil)
  if valid_595499 != nil:
    section.add "X-Amz-Content-Sha256", valid_595499
  var valid_595500 = header.getOrDefault("X-Amz-Date")
  valid_595500 = validateParameter(valid_595500, JString, required = false,
                                 default = nil)
  if valid_595500 != nil:
    section.add "X-Amz-Date", valid_595500
  var valid_595501 = header.getOrDefault("X-Amz-Credential")
  valid_595501 = validateParameter(valid_595501, JString, required = false,
                                 default = nil)
  if valid_595501 != nil:
    section.add "X-Amz-Credential", valid_595501
  var valid_595502 = header.getOrDefault("X-Amz-Security-Token")
  valid_595502 = validateParameter(valid_595502, JString, required = false,
                                 default = nil)
  if valid_595502 != nil:
    section.add "X-Amz-Security-Token", valid_595502
  var valid_595503 = header.getOrDefault("X-Amz-Algorithm")
  valid_595503 = validateParameter(valid_595503, JString, required = false,
                                 default = nil)
  if valid_595503 != nil:
    section.add "X-Amz-Algorithm", valid_595503
  var valid_595504 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595504 = validateParameter(valid_595504, JString, required = false,
                                 default = nil)
  if valid_595504 != nil:
    section.add "X-Amz-SignedHeaders", valid_595504
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595506: Call_RemoveTagsFromResource_595494; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tag keys from the specified resource.
  ## 
  let valid = call_595506.validator(path, query, header, formData, body)
  let scheme = call_595506.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595506.url(scheme.get, call_595506.host, call_595506.base,
                         call_595506.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595506, url, valid)

proc call*(call_595507: Call_RemoveTagsFromResource_595494; body: JsonNode): Recallable =
  ## removeTagsFromResource
  ## Removes tag keys from the specified resource.
  ##   body: JObject (required)
  var body_595508 = newJObject()
  if body != nil:
    body_595508 = body
  result = call_595507.call(nil, nil, nil, nil, body_595508)

var removeTagsFromResource* = Call_RemoveTagsFromResource_595494(
    name: "removeTagsFromResource", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.RemoveTagsFromResource",
    validator: validate_RemoveTagsFromResource_595495, base: "/",
    url: url_RemoveTagsFromResource_595496, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResetServiceSetting_595509 = ref object of OpenApiRestCall_593389
proc url_ResetServiceSetting_595511(protocol: Scheme; host: string; base: string;
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

proc validate_ResetServiceSetting_595510(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595512 = header.getOrDefault("X-Amz-Target")
  valid_595512 = validateParameter(valid_595512, JString, required = true, default = newJString(
      "AmazonSSM.ResetServiceSetting"))
  if valid_595512 != nil:
    section.add "X-Amz-Target", valid_595512
  var valid_595513 = header.getOrDefault("X-Amz-Signature")
  valid_595513 = validateParameter(valid_595513, JString, required = false,
                                 default = nil)
  if valid_595513 != nil:
    section.add "X-Amz-Signature", valid_595513
  var valid_595514 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595514 = validateParameter(valid_595514, JString, required = false,
                                 default = nil)
  if valid_595514 != nil:
    section.add "X-Amz-Content-Sha256", valid_595514
  var valid_595515 = header.getOrDefault("X-Amz-Date")
  valid_595515 = validateParameter(valid_595515, JString, required = false,
                                 default = nil)
  if valid_595515 != nil:
    section.add "X-Amz-Date", valid_595515
  var valid_595516 = header.getOrDefault("X-Amz-Credential")
  valid_595516 = validateParameter(valid_595516, JString, required = false,
                                 default = nil)
  if valid_595516 != nil:
    section.add "X-Amz-Credential", valid_595516
  var valid_595517 = header.getOrDefault("X-Amz-Security-Token")
  valid_595517 = validateParameter(valid_595517, JString, required = false,
                                 default = nil)
  if valid_595517 != nil:
    section.add "X-Amz-Security-Token", valid_595517
  var valid_595518 = header.getOrDefault("X-Amz-Algorithm")
  valid_595518 = validateParameter(valid_595518, JString, required = false,
                                 default = nil)
  if valid_595518 != nil:
    section.add "X-Amz-Algorithm", valid_595518
  var valid_595519 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595519 = validateParameter(valid_595519, JString, required = false,
                                 default = nil)
  if valid_595519 != nil:
    section.add "X-Amz-SignedHeaders", valid_595519
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595521: Call_ResetServiceSetting_595509; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>GetServiceSetting</a> API action to view the current value. Use the <a>UpdateServiceSetting</a> API action to change the default setting. </p> <p>Reset the service setting for the account to the default value as provisioned by the AWS service team. </p>
  ## 
  let valid = call_595521.validator(path, query, header, formData, body)
  let scheme = call_595521.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595521.url(scheme.get, call_595521.host, call_595521.base,
                         call_595521.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595521, url, valid)

proc call*(call_595522: Call_ResetServiceSetting_595509; body: JsonNode): Recallable =
  ## resetServiceSetting
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>GetServiceSetting</a> API action to view the current value. Use the <a>UpdateServiceSetting</a> API action to change the default setting. </p> <p>Reset the service setting for the account to the default value as provisioned by the AWS service team. </p>
  ##   body: JObject (required)
  var body_595523 = newJObject()
  if body != nil:
    body_595523 = body
  result = call_595522.call(nil, nil, nil, nil, body_595523)

var resetServiceSetting* = Call_ResetServiceSetting_595509(
    name: "resetServiceSetting", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ResetServiceSetting",
    validator: validate_ResetServiceSetting_595510, base: "/",
    url: url_ResetServiceSetting_595511, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResumeSession_595524 = ref object of OpenApiRestCall_593389
proc url_ResumeSession_595526(protocol: Scheme; host: string; base: string;
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

proc validate_ResumeSession_595525(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595527 = header.getOrDefault("X-Amz-Target")
  valid_595527 = validateParameter(valid_595527, JString, required = true, default = newJString(
      "AmazonSSM.ResumeSession"))
  if valid_595527 != nil:
    section.add "X-Amz-Target", valid_595527
  var valid_595528 = header.getOrDefault("X-Amz-Signature")
  valid_595528 = validateParameter(valid_595528, JString, required = false,
                                 default = nil)
  if valid_595528 != nil:
    section.add "X-Amz-Signature", valid_595528
  var valid_595529 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595529 = validateParameter(valid_595529, JString, required = false,
                                 default = nil)
  if valid_595529 != nil:
    section.add "X-Amz-Content-Sha256", valid_595529
  var valid_595530 = header.getOrDefault("X-Amz-Date")
  valid_595530 = validateParameter(valid_595530, JString, required = false,
                                 default = nil)
  if valid_595530 != nil:
    section.add "X-Amz-Date", valid_595530
  var valid_595531 = header.getOrDefault("X-Amz-Credential")
  valid_595531 = validateParameter(valid_595531, JString, required = false,
                                 default = nil)
  if valid_595531 != nil:
    section.add "X-Amz-Credential", valid_595531
  var valid_595532 = header.getOrDefault("X-Amz-Security-Token")
  valid_595532 = validateParameter(valid_595532, JString, required = false,
                                 default = nil)
  if valid_595532 != nil:
    section.add "X-Amz-Security-Token", valid_595532
  var valid_595533 = header.getOrDefault("X-Amz-Algorithm")
  valid_595533 = validateParameter(valid_595533, JString, required = false,
                                 default = nil)
  if valid_595533 != nil:
    section.add "X-Amz-Algorithm", valid_595533
  var valid_595534 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595534 = validateParameter(valid_595534, JString, required = false,
                                 default = nil)
  if valid_595534 != nil:
    section.add "X-Amz-SignedHeaders", valid_595534
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595536: Call_ResumeSession_595524; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Reconnects a session to an instance after it has been disconnected. Connections can be resumed for disconnected sessions, but not terminated sessions.</p> <note> <p>This command is primarily for use by client machines to automatically reconnect during intermittent network issues. It is not intended for any other use.</p> </note>
  ## 
  let valid = call_595536.validator(path, query, header, formData, body)
  let scheme = call_595536.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595536.url(scheme.get, call_595536.host, call_595536.base,
                         call_595536.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595536, url, valid)

proc call*(call_595537: Call_ResumeSession_595524; body: JsonNode): Recallable =
  ## resumeSession
  ## <p>Reconnects a session to an instance after it has been disconnected. Connections can be resumed for disconnected sessions, but not terminated sessions.</p> <note> <p>This command is primarily for use by client machines to automatically reconnect during intermittent network issues. It is not intended for any other use.</p> </note>
  ##   body: JObject (required)
  var body_595538 = newJObject()
  if body != nil:
    body_595538 = body
  result = call_595537.call(nil, nil, nil, nil, body_595538)

var resumeSession* = Call_ResumeSession_595524(name: "resumeSession",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ResumeSession",
    validator: validate_ResumeSession_595525, base: "/", url: url_ResumeSession_595526,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendAutomationSignal_595539 = ref object of OpenApiRestCall_593389
proc url_SendAutomationSignal_595541(protocol: Scheme; host: string; base: string;
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

proc validate_SendAutomationSignal_595540(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595542 = header.getOrDefault("X-Amz-Target")
  valid_595542 = validateParameter(valid_595542, JString, required = true, default = newJString(
      "AmazonSSM.SendAutomationSignal"))
  if valid_595542 != nil:
    section.add "X-Amz-Target", valid_595542
  var valid_595543 = header.getOrDefault("X-Amz-Signature")
  valid_595543 = validateParameter(valid_595543, JString, required = false,
                                 default = nil)
  if valid_595543 != nil:
    section.add "X-Amz-Signature", valid_595543
  var valid_595544 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595544 = validateParameter(valid_595544, JString, required = false,
                                 default = nil)
  if valid_595544 != nil:
    section.add "X-Amz-Content-Sha256", valid_595544
  var valid_595545 = header.getOrDefault("X-Amz-Date")
  valid_595545 = validateParameter(valid_595545, JString, required = false,
                                 default = nil)
  if valid_595545 != nil:
    section.add "X-Amz-Date", valid_595545
  var valid_595546 = header.getOrDefault("X-Amz-Credential")
  valid_595546 = validateParameter(valid_595546, JString, required = false,
                                 default = nil)
  if valid_595546 != nil:
    section.add "X-Amz-Credential", valid_595546
  var valid_595547 = header.getOrDefault("X-Amz-Security-Token")
  valid_595547 = validateParameter(valid_595547, JString, required = false,
                                 default = nil)
  if valid_595547 != nil:
    section.add "X-Amz-Security-Token", valid_595547
  var valid_595548 = header.getOrDefault("X-Amz-Algorithm")
  valid_595548 = validateParameter(valid_595548, JString, required = false,
                                 default = nil)
  if valid_595548 != nil:
    section.add "X-Amz-Algorithm", valid_595548
  var valid_595549 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595549 = validateParameter(valid_595549, JString, required = false,
                                 default = nil)
  if valid_595549 != nil:
    section.add "X-Amz-SignedHeaders", valid_595549
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595551: Call_SendAutomationSignal_595539; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sends a signal to an Automation execution to change the current behavior or status of the execution. 
  ## 
  let valid = call_595551.validator(path, query, header, formData, body)
  let scheme = call_595551.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595551.url(scheme.get, call_595551.host, call_595551.base,
                         call_595551.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595551, url, valid)

proc call*(call_595552: Call_SendAutomationSignal_595539; body: JsonNode): Recallable =
  ## sendAutomationSignal
  ## Sends a signal to an Automation execution to change the current behavior or status of the execution. 
  ##   body: JObject (required)
  var body_595553 = newJObject()
  if body != nil:
    body_595553 = body
  result = call_595552.call(nil, nil, nil, nil, body_595553)

var sendAutomationSignal* = Call_SendAutomationSignal_595539(
    name: "sendAutomationSignal", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.SendAutomationSignal",
    validator: validate_SendAutomationSignal_595540, base: "/",
    url: url_SendAutomationSignal_595541, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendCommand_595554 = ref object of OpenApiRestCall_593389
proc url_SendCommand_595556(protocol: Scheme; host: string; base: string;
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

proc validate_SendCommand_595555(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595557 = header.getOrDefault("X-Amz-Target")
  valid_595557 = validateParameter(valid_595557, JString, required = true,
                                 default = newJString("AmazonSSM.SendCommand"))
  if valid_595557 != nil:
    section.add "X-Amz-Target", valid_595557
  var valid_595558 = header.getOrDefault("X-Amz-Signature")
  valid_595558 = validateParameter(valid_595558, JString, required = false,
                                 default = nil)
  if valid_595558 != nil:
    section.add "X-Amz-Signature", valid_595558
  var valid_595559 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595559 = validateParameter(valid_595559, JString, required = false,
                                 default = nil)
  if valid_595559 != nil:
    section.add "X-Amz-Content-Sha256", valid_595559
  var valid_595560 = header.getOrDefault("X-Amz-Date")
  valid_595560 = validateParameter(valid_595560, JString, required = false,
                                 default = nil)
  if valid_595560 != nil:
    section.add "X-Amz-Date", valid_595560
  var valid_595561 = header.getOrDefault("X-Amz-Credential")
  valid_595561 = validateParameter(valid_595561, JString, required = false,
                                 default = nil)
  if valid_595561 != nil:
    section.add "X-Amz-Credential", valid_595561
  var valid_595562 = header.getOrDefault("X-Amz-Security-Token")
  valid_595562 = validateParameter(valid_595562, JString, required = false,
                                 default = nil)
  if valid_595562 != nil:
    section.add "X-Amz-Security-Token", valid_595562
  var valid_595563 = header.getOrDefault("X-Amz-Algorithm")
  valid_595563 = validateParameter(valid_595563, JString, required = false,
                                 default = nil)
  if valid_595563 != nil:
    section.add "X-Amz-Algorithm", valid_595563
  var valid_595564 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595564 = validateParameter(valid_595564, JString, required = false,
                                 default = nil)
  if valid_595564 != nil:
    section.add "X-Amz-SignedHeaders", valid_595564
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595566: Call_SendCommand_595554; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Runs commands on one or more managed instances.
  ## 
  let valid = call_595566.validator(path, query, header, formData, body)
  let scheme = call_595566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595566.url(scheme.get, call_595566.host, call_595566.base,
                         call_595566.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595566, url, valid)

proc call*(call_595567: Call_SendCommand_595554; body: JsonNode): Recallable =
  ## sendCommand
  ## Runs commands on one or more managed instances.
  ##   body: JObject (required)
  var body_595568 = newJObject()
  if body != nil:
    body_595568 = body
  result = call_595567.call(nil, nil, nil, nil, body_595568)

var sendCommand* = Call_SendCommand_595554(name: "sendCommand",
                                        meth: HttpMethod.HttpPost,
                                        host: "ssm.amazonaws.com", route: "/#X-Amz-Target=AmazonSSM.SendCommand",
                                        validator: validate_SendCommand_595555,
                                        base: "/", url: url_SendCommand_595556,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartAssociationsOnce_595569 = ref object of OpenApiRestCall_593389
proc url_StartAssociationsOnce_595571(protocol: Scheme; host: string; base: string;
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

proc validate_StartAssociationsOnce_595570(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595572 = header.getOrDefault("X-Amz-Target")
  valid_595572 = validateParameter(valid_595572, JString, required = true, default = newJString(
      "AmazonSSM.StartAssociationsOnce"))
  if valid_595572 != nil:
    section.add "X-Amz-Target", valid_595572
  var valid_595573 = header.getOrDefault("X-Amz-Signature")
  valid_595573 = validateParameter(valid_595573, JString, required = false,
                                 default = nil)
  if valid_595573 != nil:
    section.add "X-Amz-Signature", valid_595573
  var valid_595574 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595574 = validateParameter(valid_595574, JString, required = false,
                                 default = nil)
  if valid_595574 != nil:
    section.add "X-Amz-Content-Sha256", valid_595574
  var valid_595575 = header.getOrDefault("X-Amz-Date")
  valid_595575 = validateParameter(valid_595575, JString, required = false,
                                 default = nil)
  if valid_595575 != nil:
    section.add "X-Amz-Date", valid_595575
  var valid_595576 = header.getOrDefault("X-Amz-Credential")
  valid_595576 = validateParameter(valid_595576, JString, required = false,
                                 default = nil)
  if valid_595576 != nil:
    section.add "X-Amz-Credential", valid_595576
  var valid_595577 = header.getOrDefault("X-Amz-Security-Token")
  valid_595577 = validateParameter(valid_595577, JString, required = false,
                                 default = nil)
  if valid_595577 != nil:
    section.add "X-Amz-Security-Token", valid_595577
  var valid_595578 = header.getOrDefault("X-Amz-Algorithm")
  valid_595578 = validateParameter(valid_595578, JString, required = false,
                                 default = nil)
  if valid_595578 != nil:
    section.add "X-Amz-Algorithm", valid_595578
  var valid_595579 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595579 = validateParameter(valid_595579, JString, required = false,
                                 default = nil)
  if valid_595579 != nil:
    section.add "X-Amz-SignedHeaders", valid_595579
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595581: Call_StartAssociationsOnce_595569; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Use this API action to run an association immediately and only one time. This action can be helpful when troubleshooting associations.
  ## 
  let valid = call_595581.validator(path, query, header, formData, body)
  let scheme = call_595581.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595581.url(scheme.get, call_595581.host, call_595581.base,
                         call_595581.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595581, url, valid)

proc call*(call_595582: Call_StartAssociationsOnce_595569; body: JsonNode): Recallable =
  ## startAssociationsOnce
  ## Use this API action to run an association immediately and only one time. This action can be helpful when troubleshooting associations.
  ##   body: JObject (required)
  var body_595583 = newJObject()
  if body != nil:
    body_595583 = body
  result = call_595582.call(nil, nil, nil, nil, body_595583)

var startAssociationsOnce* = Call_StartAssociationsOnce_595569(
    name: "startAssociationsOnce", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.StartAssociationsOnce",
    validator: validate_StartAssociationsOnce_595570, base: "/",
    url: url_StartAssociationsOnce_595571, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartAutomationExecution_595584 = ref object of OpenApiRestCall_593389
proc url_StartAutomationExecution_595586(protocol: Scheme; host: string;
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

proc validate_StartAutomationExecution_595585(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595587 = header.getOrDefault("X-Amz-Target")
  valid_595587 = validateParameter(valid_595587, JString, required = true, default = newJString(
      "AmazonSSM.StartAutomationExecution"))
  if valid_595587 != nil:
    section.add "X-Amz-Target", valid_595587
  var valid_595588 = header.getOrDefault("X-Amz-Signature")
  valid_595588 = validateParameter(valid_595588, JString, required = false,
                                 default = nil)
  if valid_595588 != nil:
    section.add "X-Amz-Signature", valid_595588
  var valid_595589 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595589 = validateParameter(valid_595589, JString, required = false,
                                 default = nil)
  if valid_595589 != nil:
    section.add "X-Amz-Content-Sha256", valid_595589
  var valid_595590 = header.getOrDefault("X-Amz-Date")
  valid_595590 = validateParameter(valid_595590, JString, required = false,
                                 default = nil)
  if valid_595590 != nil:
    section.add "X-Amz-Date", valid_595590
  var valid_595591 = header.getOrDefault("X-Amz-Credential")
  valid_595591 = validateParameter(valid_595591, JString, required = false,
                                 default = nil)
  if valid_595591 != nil:
    section.add "X-Amz-Credential", valid_595591
  var valid_595592 = header.getOrDefault("X-Amz-Security-Token")
  valid_595592 = validateParameter(valid_595592, JString, required = false,
                                 default = nil)
  if valid_595592 != nil:
    section.add "X-Amz-Security-Token", valid_595592
  var valid_595593 = header.getOrDefault("X-Amz-Algorithm")
  valid_595593 = validateParameter(valid_595593, JString, required = false,
                                 default = nil)
  if valid_595593 != nil:
    section.add "X-Amz-Algorithm", valid_595593
  var valid_595594 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595594 = validateParameter(valid_595594, JString, required = false,
                                 default = nil)
  if valid_595594 != nil:
    section.add "X-Amz-SignedHeaders", valid_595594
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595596: Call_StartAutomationExecution_595584; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Initiates execution of an Automation document.
  ## 
  let valid = call_595596.validator(path, query, header, formData, body)
  let scheme = call_595596.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595596.url(scheme.get, call_595596.host, call_595596.base,
                         call_595596.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595596, url, valid)

proc call*(call_595597: Call_StartAutomationExecution_595584; body: JsonNode): Recallable =
  ## startAutomationExecution
  ## Initiates execution of an Automation document.
  ##   body: JObject (required)
  var body_595598 = newJObject()
  if body != nil:
    body_595598 = body
  result = call_595597.call(nil, nil, nil, nil, body_595598)

var startAutomationExecution* = Call_StartAutomationExecution_595584(
    name: "startAutomationExecution", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.StartAutomationExecution",
    validator: validate_StartAutomationExecution_595585, base: "/",
    url: url_StartAutomationExecution_595586, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartSession_595599 = ref object of OpenApiRestCall_593389
proc url_StartSession_595601(protocol: Scheme; host: string; base: string;
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

proc validate_StartSession_595600(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595602 = header.getOrDefault("X-Amz-Target")
  valid_595602 = validateParameter(valid_595602, JString, required = true,
                                 default = newJString("AmazonSSM.StartSession"))
  if valid_595602 != nil:
    section.add "X-Amz-Target", valid_595602
  var valid_595603 = header.getOrDefault("X-Amz-Signature")
  valid_595603 = validateParameter(valid_595603, JString, required = false,
                                 default = nil)
  if valid_595603 != nil:
    section.add "X-Amz-Signature", valid_595603
  var valid_595604 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595604 = validateParameter(valid_595604, JString, required = false,
                                 default = nil)
  if valid_595604 != nil:
    section.add "X-Amz-Content-Sha256", valid_595604
  var valid_595605 = header.getOrDefault("X-Amz-Date")
  valid_595605 = validateParameter(valid_595605, JString, required = false,
                                 default = nil)
  if valid_595605 != nil:
    section.add "X-Amz-Date", valid_595605
  var valid_595606 = header.getOrDefault("X-Amz-Credential")
  valid_595606 = validateParameter(valid_595606, JString, required = false,
                                 default = nil)
  if valid_595606 != nil:
    section.add "X-Amz-Credential", valid_595606
  var valid_595607 = header.getOrDefault("X-Amz-Security-Token")
  valid_595607 = validateParameter(valid_595607, JString, required = false,
                                 default = nil)
  if valid_595607 != nil:
    section.add "X-Amz-Security-Token", valid_595607
  var valid_595608 = header.getOrDefault("X-Amz-Algorithm")
  valid_595608 = validateParameter(valid_595608, JString, required = false,
                                 default = nil)
  if valid_595608 != nil:
    section.add "X-Amz-Algorithm", valid_595608
  var valid_595609 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595609 = validateParameter(valid_595609, JString, required = false,
                                 default = nil)
  if valid_595609 != nil:
    section.add "X-Amz-SignedHeaders", valid_595609
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595611: Call_StartSession_595599; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates a connection to a target (for example, an instance) for a Session Manager session. Returns a URL and token that can be used to open a WebSocket connection for sending input and receiving outputs.</p> <note> <p>AWS CLI usage: <code>start-session</code> is an interactive command that requires the Session Manager plugin to be installed on the client machine making the call. For information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html"> Install the Session Manager Plugin for the AWS CLI</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>AWS Tools for PowerShell usage: Start-SSMSession is not currently supported by AWS Tools for PowerShell on Windows local machines.</p> </note>
  ## 
  let valid = call_595611.validator(path, query, header, formData, body)
  let scheme = call_595611.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595611.url(scheme.get, call_595611.host, call_595611.base,
                         call_595611.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595611, url, valid)

proc call*(call_595612: Call_StartSession_595599; body: JsonNode): Recallable =
  ## startSession
  ## <p>Initiates a connection to a target (for example, an instance) for a Session Manager session. Returns a URL and token that can be used to open a WebSocket connection for sending input and receiving outputs.</p> <note> <p>AWS CLI usage: <code>start-session</code> is an interactive command that requires the Session Manager plugin to be installed on the client machine making the call. For information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html"> Install the Session Manager Plugin for the AWS CLI</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>AWS Tools for PowerShell usage: Start-SSMSession is not currently supported by AWS Tools for PowerShell on Windows local machines.</p> </note>
  ##   body: JObject (required)
  var body_595613 = newJObject()
  if body != nil:
    body_595613 = body
  result = call_595612.call(nil, nil, nil, nil, body_595613)

var startSession* = Call_StartSession_595599(name: "startSession",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.StartSession",
    validator: validate_StartSession_595600, base: "/", url: url_StartSession_595601,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopAutomationExecution_595614 = ref object of OpenApiRestCall_593389
proc url_StopAutomationExecution_595616(protocol: Scheme; host: string; base: string;
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

proc validate_StopAutomationExecution_595615(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595617 = header.getOrDefault("X-Amz-Target")
  valid_595617 = validateParameter(valid_595617, JString, required = true, default = newJString(
      "AmazonSSM.StopAutomationExecution"))
  if valid_595617 != nil:
    section.add "X-Amz-Target", valid_595617
  var valid_595618 = header.getOrDefault("X-Amz-Signature")
  valid_595618 = validateParameter(valid_595618, JString, required = false,
                                 default = nil)
  if valid_595618 != nil:
    section.add "X-Amz-Signature", valid_595618
  var valid_595619 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595619 = validateParameter(valid_595619, JString, required = false,
                                 default = nil)
  if valid_595619 != nil:
    section.add "X-Amz-Content-Sha256", valid_595619
  var valid_595620 = header.getOrDefault("X-Amz-Date")
  valid_595620 = validateParameter(valid_595620, JString, required = false,
                                 default = nil)
  if valid_595620 != nil:
    section.add "X-Amz-Date", valid_595620
  var valid_595621 = header.getOrDefault("X-Amz-Credential")
  valid_595621 = validateParameter(valid_595621, JString, required = false,
                                 default = nil)
  if valid_595621 != nil:
    section.add "X-Amz-Credential", valid_595621
  var valid_595622 = header.getOrDefault("X-Amz-Security-Token")
  valid_595622 = validateParameter(valid_595622, JString, required = false,
                                 default = nil)
  if valid_595622 != nil:
    section.add "X-Amz-Security-Token", valid_595622
  var valid_595623 = header.getOrDefault("X-Amz-Algorithm")
  valid_595623 = validateParameter(valid_595623, JString, required = false,
                                 default = nil)
  if valid_595623 != nil:
    section.add "X-Amz-Algorithm", valid_595623
  var valid_595624 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595624 = validateParameter(valid_595624, JString, required = false,
                                 default = nil)
  if valid_595624 != nil:
    section.add "X-Amz-SignedHeaders", valid_595624
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595626: Call_StopAutomationExecution_595614; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stop an Automation that is currently running.
  ## 
  let valid = call_595626.validator(path, query, header, formData, body)
  let scheme = call_595626.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595626.url(scheme.get, call_595626.host, call_595626.base,
                         call_595626.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595626, url, valid)

proc call*(call_595627: Call_StopAutomationExecution_595614; body: JsonNode): Recallable =
  ## stopAutomationExecution
  ## Stop an Automation that is currently running.
  ##   body: JObject (required)
  var body_595628 = newJObject()
  if body != nil:
    body_595628 = body
  result = call_595627.call(nil, nil, nil, nil, body_595628)

var stopAutomationExecution* = Call_StopAutomationExecution_595614(
    name: "stopAutomationExecution", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.StopAutomationExecution",
    validator: validate_StopAutomationExecution_595615, base: "/",
    url: url_StopAutomationExecution_595616, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TerminateSession_595629 = ref object of OpenApiRestCall_593389
proc url_TerminateSession_595631(protocol: Scheme; host: string; base: string;
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

proc validate_TerminateSession_595630(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595632 = header.getOrDefault("X-Amz-Target")
  valid_595632 = validateParameter(valid_595632, JString, required = true, default = newJString(
      "AmazonSSM.TerminateSession"))
  if valid_595632 != nil:
    section.add "X-Amz-Target", valid_595632
  var valid_595633 = header.getOrDefault("X-Amz-Signature")
  valid_595633 = validateParameter(valid_595633, JString, required = false,
                                 default = nil)
  if valid_595633 != nil:
    section.add "X-Amz-Signature", valid_595633
  var valid_595634 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595634 = validateParameter(valid_595634, JString, required = false,
                                 default = nil)
  if valid_595634 != nil:
    section.add "X-Amz-Content-Sha256", valid_595634
  var valid_595635 = header.getOrDefault("X-Amz-Date")
  valid_595635 = validateParameter(valid_595635, JString, required = false,
                                 default = nil)
  if valid_595635 != nil:
    section.add "X-Amz-Date", valid_595635
  var valid_595636 = header.getOrDefault("X-Amz-Credential")
  valid_595636 = validateParameter(valid_595636, JString, required = false,
                                 default = nil)
  if valid_595636 != nil:
    section.add "X-Amz-Credential", valid_595636
  var valid_595637 = header.getOrDefault("X-Amz-Security-Token")
  valid_595637 = validateParameter(valid_595637, JString, required = false,
                                 default = nil)
  if valid_595637 != nil:
    section.add "X-Amz-Security-Token", valid_595637
  var valid_595638 = header.getOrDefault("X-Amz-Algorithm")
  valid_595638 = validateParameter(valid_595638, JString, required = false,
                                 default = nil)
  if valid_595638 != nil:
    section.add "X-Amz-Algorithm", valid_595638
  var valid_595639 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595639 = validateParameter(valid_595639, JString, required = false,
                                 default = nil)
  if valid_595639 != nil:
    section.add "X-Amz-SignedHeaders", valid_595639
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595641: Call_TerminateSession_595629; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently ends a session and closes the data connection between the Session Manager client and SSM Agent on the instance. A terminated session cannot be resumed.
  ## 
  let valid = call_595641.validator(path, query, header, formData, body)
  let scheme = call_595641.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595641.url(scheme.get, call_595641.host, call_595641.base,
                         call_595641.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595641, url, valid)

proc call*(call_595642: Call_TerminateSession_595629; body: JsonNode): Recallable =
  ## terminateSession
  ## Permanently ends a session and closes the data connection between the Session Manager client and SSM Agent on the instance. A terminated session cannot be resumed.
  ##   body: JObject (required)
  var body_595643 = newJObject()
  if body != nil:
    body_595643 = body
  result = call_595642.call(nil, nil, nil, nil, body_595643)

var terminateSession* = Call_TerminateSession_595629(name: "terminateSession",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.TerminateSession",
    validator: validate_TerminateSession_595630, base: "/",
    url: url_TerminateSession_595631, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAssociation_595644 = ref object of OpenApiRestCall_593389
proc url_UpdateAssociation_595646(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateAssociation_595645(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595647 = header.getOrDefault("X-Amz-Target")
  valid_595647 = validateParameter(valid_595647, JString, required = true, default = newJString(
      "AmazonSSM.UpdateAssociation"))
  if valid_595647 != nil:
    section.add "X-Amz-Target", valid_595647
  var valid_595648 = header.getOrDefault("X-Amz-Signature")
  valid_595648 = validateParameter(valid_595648, JString, required = false,
                                 default = nil)
  if valid_595648 != nil:
    section.add "X-Amz-Signature", valid_595648
  var valid_595649 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595649 = validateParameter(valid_595649, JString, required = false,
                                 default = nil)
  if valid_595649 != nil:
    section.add "X-Amz-Content-Sha256", valid_595649
  var valid_595650 = header.getOrDefault("X-Amz-Date")
  valid_595650 = validateParameter(valid_595650, JString, required = false,
                                 default = nil)
  if valid_595650 != nil:
    section.add "X-Amz-Date", valid_595650
  var valid_595651 = header.getOrDefault("X-Amz-Credential")
  valid_595651 = validateParameter(valid_595651, JString, required = false,
                                 default = nil)
  if valid_595651 != nil:
    section.add "X-Amz-Credential", valid_595651
  var valid_595652 = header.getOrDefault("X-Amz-Security-Token")
  valid_595652 = validateParameter(valid_595652, JString, required = false,
                                 default = nil)
  if valid_595652 != nil:
    section.add "X-Amz-Security-Token", valid_595652
  var valid_595653 = header.getOrDefault("X-Amz-Algorithm")
  valid_595653 = validateParameter(valid_595653, JString, required = false,
                                 default = nil)
  if valid_595653 != nil:
    section.add "X-Amz-Algorithm", valid_595653
  var valid_595654 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595654 = validateParameter(valid_595654, JString, required = false,
                                 default = nil)
  if valid_595654 != nil:
    section.add "X-Amz-SignedHeaders", valid_595654
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595656: Call_UpdateAssociation_595644; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an association. You can update the association name and version, the document version, schedule, parameters, and Amazon S3 output. </p> <p>In order to call this API action, your IAM user account, group, or role must be configured with permission to call the <a>DescribeAssociation</a> API action. If you don't have permission to call DescribeAssociation, then you receive the following error: <code>An error occurred (AccessDeniedException) when calling the UpdateAssociation operation: User: &lt;user_arn&gt; is not authorized to perform: ssm:DescribeAssociation on resource: &lt;resource_arn&gt;</code> </p> <important> <p>When you update an association, the association immediately runs against the specified targets.</p> </important>
  ## 
  let valid = call_595656.validator(path, query, header, formData, body)
  let scheme = call_595656.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595656.url(scheme.get, call_595656.host, call_595656.base,
                         call_595656.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595656, url, valid)

proc call*(call_595657: Call_UpdateAssociation_595644; body: JsonNode): Recallable =
  ## updateAssociation
  ## <p>Updates an association. You can update the association name and version, the document version, schedule, parameters, and Amazon S3 output. </p> <p>In order to call this API action, your IAM user account, group, or role must be configured with permission to call the <a>DescribeAssociation</a> API action. If you don't have permission to call DescribeAssociation, then you receive the following error: <code>An error occurred (AccessDeniedException) when calling the UpdateAssociation operation: User: &lt;user_arn&gt; is not authorized to perform: ssm:DescribeAssociation on resource: &lt;resource_arn&gt;</code> </p> <important> <p>When you update an association, the association immediately runs against the specified targets.</p> </important>
  ##   body: JObject (required)
  var body_595658 = newJObject()
  if body != nil:
    body_595658 = body
  result = call_595657.call(nil, nil, nil, nil, body_595658)

var updateAssociation* = Call_UpdateAssociation_595644(name: "updateAssociation",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateAssociation",
    validator: validate_UpdateAssociation_595645, base: "/",
    url: url_UpdateAssociation_595646, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAssociationStatus_595659 = ref object of OpenApiRestCall_593389
proc url_UpdateAssociationStatus_595661(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateAssociationStatus_595660(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595662 = header.getOrDefault("X-Amz-Target")
  valid_595662 = validateParameter(valid_595662, JString, required = true, default = newJString(
      "AmazonSSM.UpdateAssociationStatus"))
  if valid_595662 != nil:
    section.add "X-Amz-Target", valid_595662
  var valid_595663 = header.getOrDefault("X-Amz-Signature")
  valid_595663 = validateParameter(valid_595663, JString, required = false,
                                 default = nil)
  if valid_595663 != nil:
    section.add "X-Amz-Signature", valid_595663
  var valid_595664 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595664 = validateParameter(valid_595664, JString, required = false,
                                 default = nil)
  if valid_595664 != nil:
    section.add "X-Amz-Content-Sha256", valid_595664
  var valid_595665 = header.getOrDefault("X-Amz-Date")
  valid_595665 = validateParameter(valid_595665, JString, required = false,
                                 default = nil)
  if valid_595665 != nil:
    section.add "X-Amz-Date", valid_595665
  var valid_595666 = header.getOrDefault("X-Amz-Credential")
  valid_595666 = validateParameter(valid_595666, JString, required = false,
                                 default = nil)
  if valid_595666 != nil:
    section.add "X-Amz-Credential", valid_595666
  var valid_595667 = header.getOrDefault("X-Amz-Security-Token")
  valid_595667 = validateParameter(valid_595667, JString, required = false,
                                 default = nil)
  if valid_595667 != nil:
    section.add "X-Amz-Security-Token", valid_595667
  var valid_595668 = header.getOrDefault("X-Amz-Algorithm")
  valid_595668 = validateParameter(valid_595668, JString, required = false,
                                 default = nil)
  if valid_595668 != nil:
    section.add "X-Amz-Algorithm", valid_595668
  var valid_595669 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595669 = validateParameter(valid_595669, JString, required = false,
                                 default = nil)
  if valid_595669 != nil:
    section.add "X-Amz-SignedHeaders", valid_595669
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595671: Call_UpdateAssociationStatus_595659; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the status of the Systems Manager document associated with the specified instance.
  ## 
  let valid = call_595671.validator(path, query, header, formData, body)
  let scheme = call_595671.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595671.url(scheme.get, call_595671.host, call_595671.base,
                         call_595671.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595671, url, valid)

proc call*(call_595672: Call_UpdateAssociationStatus_595659; body: JsonNode): Recallable =
  ## updateAssociationStatus
  ## Updates the status of the Systems Manager document associated with the specified instance.
  ##   body: JObject (required)
  var body_595673 = newJObject()
  if body != nil:
    body_595673 = body
  result = call_595672.call(nil, nil, nil, nil, body_595673)

var updateAssociationStatus* = Call_UpdateAssociationStatus_595659(
    name: "updateAssociationStatus", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateAssociationStatus",
    validator: validate_UpdateAssociationStatus_595660, base: "/",
    url: url_UpdateAssociationStatus_595661, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocument_595674 = ref object of OpenApiRestCall_593389
proc url_UpdateDocument_595676(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDocument_595675(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595677 = header.getOrDefault("X-Amz-Target")
  valid_595677 = validateParameter(valid_595677, JString, required = true, default = newJString(
      "AmazonSSM.UpdateDocument"))
  if valid_595677 != nil:
    section.add "X-Amz-Target", valid_595677
  var valid_595678 = header.getOrDefault("X-Amz-Signature")
  valid_595678 = validateParameter(valid_595678, JString, required = false,
                                 default = nil)
  if valid_595678 != nil:
    section.add "X-Amz-Signature", valid_595678
  var valid_595679 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595679 = validateParameter(valid_595679, JString, required = false,
                                 default = nil)
  if valid_595679 != nil:
    section.add "X-Amz-Content-Sha256", valid_595679
  var valid_595680 = header.getOrDefault("X-Amz-Date")
  valid_595680 = validateParameter(valid_595680, JString, required = false,
                                 default = nil)
  if valid_595680 != nil:
    section.add "X-Amz-Date", valid_595680
  var valid_595681 = header.getOrDefault("X-Amz-Credential")
  valid_595681 = validateParameter(valid_595681, JString, required = false,
                                 default = nil)
  if valid_595681 != nil:
    section.add "X-Amz-Credential", valid_595681
  var valid_595682 = header.getOrDefault("X-Amz-Security-Token")
  valid_595682 = validateParameter(valid_595682, JString, required = false,
                                 default = nil)
  if valid_595682 != nil:
    section.add "X-Amz-Security-Token", valid_595682
  var valid_595683 = header.getOrDefault("X-Amz-Algorithm")
  valid_595683 = validateParameter(valid_595683, JString, required = false,
                                 default = nil)
  if valid_595683 != nil:
    section.add "X-Amz-Algorithm", valid_595683
  var valid_595684 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595684 = validateParameter(valid_595684, JString, required = false,
                                 default = nil)
  if valid_595684 != nil:
    section.add "X-Amz-SignedHeaders", valid_595684
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595686: Call_UpdateDocument_595674; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates one or more values for an SSM document.
  ## 
  let valid = call_595686.validator(path, query, header, formData, body)
  let scheme = call_595686.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595686.url(scheme.get, call_595686.host, call_595686.base,
                         call_595686.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595686, url, valid)

proc call*(call_595687: Call_UpdateDocument_595674; body: JsonNode): Recallable =
  ## updateDocument
  ## Updates one or more values for an SSM document.
  ##   body: JObject (required)
  var body_595688 = newJObject()
  if body != nil:
    body_595688 = body
  result = call_595687.call(nil, nil, nil, nil, body_595688)

var updateDocument* = Call_UpdateDocument_595674(name: "updateDocument",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateDocument",
    validator: validate_UpdateDocument_595675, base: "/", url: url_UpdateDocument_595676,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocumentDefaultVersion_595689 = ref object of OpenApiRestCall_593389
proc url_UpdateDocumentDefaultVersion_595691(protocol: Scheme; host: string;
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

proc validate_UpdateDocumentDefaultVersion_595690(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595692 = header.getOrDefault("X-Amz-Target")
  valid_595692 = validateParameter(valid_595692, JString, required = true, default = newJString(
      "AmazonSSM.UpdateDocumentDefaultVersion"))
  if valid_595692 != nil:
    section.add "X-Amz-Target", valid_595692
  var valid_595693 = header.getOrDefault("X-Amz-Signature")
  valid_595693 = validateParameter(valid_595693, JString, required = false,
                                 default = nil)
  if valid_595693 != nil:
    section.add "X-Amz-Signature", valid_595693
  var valid_595694 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595694 = validateParameter(valid_595694, JString, required = false,
                                 default = nil)
  if valid_595694 != nil:
    section.add "X-Amz-Content-Sha256", valid_595694
  var valid_595695 = header.getOrDefault("X-Amz-Date")
  valid_595695 = validateParameter(valid_595695, JString, required = false,
                                 default = nil)
  if valid_595695 != nil:
    section.add "X-Amz-Date", valid_595695
  var valid_595696 = header.getOrDefault("X-Amz-Credential")
  valid_595696 = validateParameter(valid_595696, JString, required = false,
                                 default = nil)
  if valid_595696 != nil:
    section.add "X-Amz-Credential", valid_595696
  var valid_595697 = header.getOrDefault("X-Amz-Security-Token")
  valid_595697 = validateParameter(valid_595697, JString, required = false,
                                 default = nil)
  if valid_595697 != nil:
    section.add "X-Amz-Security-Token", valid_595697
  var valid_595698 = header.getOrDefault("X-Amz-Algorithm")
  valid_595698 = validateParameter(valid_595698, JString, required = false,
                                 default = nil)
  if valid_595698 != nil:
    section.add "X-Amz-Algorithm", valid_595698
  var valid_595699 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595699 = validateParameter(valid_595699, JString, required = false,
                                 default = nil)
  if valid_595699 != nil:
    section.add "X-Amz-SignedHeaders", valid_595699
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595701: Call_UpdateDocumentDefaultVersion_595689; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Set the default version of a document. 
  ## 
  let valid = call_595701.validator(path, query, header, formData, body)
  let scheme = call_595701.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595701.url(scheme.get, call_595701.host, call_595701.base,
                         call_595701.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595701, url, valid)

proc call*(call_595702: Call_UpdateDocumentDefaultVersion_595689; body: JsonNode): Recallable =
  ## updateDocumentDefaultVersion
  ## Set the default version of a document. 
  ##   body: JObject (required)
  var body_595703 = newJObject()
  if body != nil:
    body_595703 = body
  result = call_595702.call(nil, nil, nil, nil, body_595703)

var updateDocumentDefaultVersion* = Call_UpdateDocumentDefaultVersion_595689(
    name: "updateDocumentDefaultVersion", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateDocumentDefaultVersion",
    validator: validate_UpdateDocumentDefaultVersion_595690, base: "/",
    url: url_UpdateDocumentDefaultVersion_595691,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMaintenanceWindow_595704 = ref object of OpenApiRestCall_593389
proc url_UpdateMaintenanceWindow_595706(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateMaintenanceWindow_595705(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595707 = header.getOrDefault("X-Amz-Target")
  valid_595707 = validateParameter(valid_595707, JString, required = true, default = newJString(
      "AmazonSSM.UpdateMaintenanceWindow"))
  if valid_595707 != nil:
    section.add "X-Amz-Target", valid_595707
  var valid_595708 = header.getOrDefault("X-Amz-Signature")
  valid_595708 = validateParameter(valid_595708, JString, required = false,
                                 default = nil)
  if valid_595708 != nil:
    section.add "X-Amz-Signature", valid_595708
  var valid_595709 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595709 = validateParameter(valid_595709, JString, required = false,
                                 default = nil)
  if valid_595709 != nil:
    section.add "X-Amz-Content-Sha256", valid_595709
  var valid_595710 = header.getOrDefault("X-Amz-Date")
  valid_595710 = validateParameter(valid_595710, JString, required = false,
                                 default = nil)
  if valid_595710 != nil:
    section.add "X-Amz-Date", valid_595710
  var valid_595711 = header.getOrDefault("X-Amz-Credential")
  valid_595711 = validateParameter(valid_595711, JString, required = false,
                                 default = nil)
  if valid_595711 != nil:
    section.add "X-Amz-Credential", valid_595711
  var valid_595712 = header.getOrDefault("X-Amz-Security-Token")
  valid_595712 = validateParameter(valid_595712, JString, required = false,
                                 default = nil)
  if valid_595712 != nil:
    section.add "X-Amz-Security-Token", valid_595712
  var valid_595713 = header.getOrDefault("X-Amz-Algorithm")
  valid_595713 = validateParameter(valid_595713, JString, required = false,
                                 default = nil)
  if valid_595713 != nil:
    section.add "X-Amz-Algorithm", valid_595713
  var valid_595714 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595714 = validateParameter(valid_595714, JString, required = false,
                                 default = nil)
  if valid_595714 != nil:
    section.add "X-Amz-SignedHeaders", valid_595714
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595716: Call_UpdateMaintenanceWindow_595704; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an existing maintenance window. Only specified parameters are modified.</p> <note> <p>The value you specify for <code>Duration</code> determines the specific end time for the maintenance window based on the time it begins. No maintenance window tasks are permitted to start after the resulting endtime minus the number of hours you specify for <code>Cutoff</code>. For example, if the maintenance window starts at 3 PM, the duration is three hours, and the value you specify for <code>Cutoff</code> is one hour, no maintenance window tasks can start after 5 PM.</p> </note>
  ## 
  let valid = call_595716.validator(path, query, header, formData, body)
  let scheme = call_595716.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595716.url(scheme.get, call_595716.host, call_595716.base,
                         call_595716.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595716, url, valid)

proc call*(call_595717: Call_UpdateMaintenanceWindow_595704; body: JsonNode): Recallable =
  ## updateMaintenanceWindow
  ## <p>Updates an existing maintenance window. Only specified parameters are modified.</p> <note> <p>The value you specify for <code>Duration</code> determines the specific end time for the maintenance window based on the time it begins. No maintenance window tasks are permitted to start after the resulting endtime minus the number of hours you specify for <code>Cutoff</code>. For example, if the maintenance window starts at 3 PM, the duration is three hours, and the value you specify for <code>Cutoff</code> is one hour, no maintenance window tasks can start after 5 PM.</p> </note>
  ##   body: JObject (required)
  var body_595718 = newJObject()
  if body != nil:
    body_595718 = body
  result = call_595717.call(nil, nil, nil, nil, body_595718)

var updateMaintenanceWindow* = Call_UpdateMaintenanceWindow_595704(
    name: "updateMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateMaintenanceWindow",
    validator: validate_UpdateMaintenanceWindow_595705, base: "/",
    url: url_UpdateMaintenanceWindow_595706, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMaintenanceWindowTarget_595719 = ref object of OpenApiRestCall_593389
proc url_UpdateMaintenanceWindowTarget_595721(protocol: Scheme; host: string;
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

proc validate_UpdateMaintenanceWindowTarget_595720(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595722 = header.getOrDefault("X-Amz-Target")
  valid_595722 = validateParameter(valid_595722, JString, required = true, default = newJString(
      "AmazonSSM.UpdateMaintenanceWindowTarget"))
  if valid_595722 != nil:
    section.add "X-Amz-Target", valid_595722
  var valid_595723 = header.getOrDefault("X-Amz-Signature")
  valid_595723 = validateParameter(valid_595723, JString, required = false,
                                 default = nil)
  if valid_595723 != nil:
    section.add "X-Amz-Signature", valid_595723
  var valid_595724 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595724 = validateParameter(valid_595724, JString, required = false,
                                 default = nil)
  if valid_595724 != nil:
    section.add "X-Amz-Content-Sha256", valid_595724
  var valid_595725 = header.getOrDefault("X-Amz-Date")
  valid_595725 = validateParameter(valid_595725, JString, required = false,
                                 default = nil)
  if valid_595725 != nil:
    section.add "X-Amz-Date", valid_595725
  var valid_595726 = header.getOrDefault("X-Amz-Credential")
  valid_595726 = validateParameter(valid_595726, JString, required = false,
                                 default = nil)
  if valid_595726 != nil:
    section.add "X-Amz-Credential", valid_595726
  var valid_595727 = header.getOrDefault("X-Amz-Security-Token")
  valid_595727 = validateParameter(valid_595727, JString, required = false,
                                 default = nil)
  if valid_595727 != nil:
    section.add "X-Amz-Security-Token", valid_595727
  var valid_595728 = header.getOrDefault("X-Amz-Algorithm")
  valid_595728 = validateParameter(valid_595728, JString, required = false,
                                 default = nil)
  if valid_595728 != nil:
    section.add "X-Amz-Algorithm", valid_595728
  var valid_595729 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595729 = validateParameter(valid_595729, JString, required = false,
                                 default = nil)
  if valid_595729 != nil:
    section.add "X-Amz-SignedHeaders", valid_595729
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595731: Call_UpdateMaintenanceWindowTarget_595719; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the target of an existing maintenance window. You can change the following:</p> <ul> <li> <p>Name</p> </li> <li> <p>Description</p> </li> <li> <p>Owner</p> </li> <li> <p>IDs for an ID target</p> </li> <li> <p>Tags for a Tag target</p> </li> <li> <p>From any supported tag type to another. The three supported tag types are ID target, Tag target, and resource group. For more information, see <a>Target</a>.</p> </li> </ul> <note> <p>If a parameter is null, then the corresponding field is not modified.</p> </note>
  ## 
  let valid = call_595731.validator(path, query, header, formData, body)
  let scheme = call_595731.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595731.url(scheme.get, call_595731.host, call_595731.base,
                         call_595731.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595731, url, valid)

proc call*(call_595732: Call_UpdateMaintenanceWindowTarget_595719; body: JsonNode): Recallable =
  ## updateMaintenanceWindowTarget
  ## <p>Modifies the target of an existing maintenance window. You can change the following:</p> <ul> <li> <p>Name</p> </li> <li> <p>Description</p> </li> <li> <p>Owner</p> </li> <li> <p>IDs for an ID target</p> </li> <li> <p>Tags for a Tag target</p> </li> <li> <p>From any supported tag type to another. The three supported tag types are ID target, Tag target, and resource group. For more information, see <a>Target</a>.</p> </li> </ul> <note> <p>If a parameter is null, then the corresponding field is not modified.</p> </note>
  ##   body: JObject (required)
  var body_595733 = newJObject()
  if body != nil:
    body_595733 = body
  result = call_595732.call(nil, nil, nil, nil, body_595733)

var updateMaintenanceWindowTarget* = Call_UpdateMaintenanceWindowTarget_595719(
    name: "updateMaintenanceWindowTarget", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateMaintenanceWindowTarget",
    validator: validate_UpdateMaintenanceWindowTarget_595720, base: "/",
    url: url_UpdateMaintenanceWindowTarget_595721,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMaintenanceWindowTask_595734 = ref object of OpenApiRestCall_593389
proc url_UpdateMaintenanceWindowTask_595736(protocol: Scheme; host: string;
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

proc validate_UpdateMaintenanceWindowTask_595735(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595737 = header.getOrDefault("X-Amz-Target")
  valid_595737 = validateParameter(valid_595737, JString, required = true, default = newJString(
      "AmazonSSM.UpdateMaintenanceWindowTask"))
  if valid_595737 != nil:
    section.add "X-Amz-Target", valid_595737
  var valid_595738 = header.getOrDefault("X-Amz-Signature")
  valid_595738 = validateParameter(valid_595738, JString, required = false,
                                 default = nil)
  if valid_595738 != nil:
    section.add "X-Amz-Signature", valid_595738
  var valid_595739 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595739 = validateParameter(valid_595739, JString, required = false,
                                 default = nil)
  if valid_595739 != nil:
    section.add "X-Amz-Content-Sha256", valid_595739
  var valid_595740 = header.getOrDefault("X-Amz-Date")
  valid_595740 = validateParameter(valid_595740, JString, required = false,
                                 default = nil)
  if valid_595740 != nil:
    section.add "X-Amz-Date", valid_595740
  var valid_595741 = header.getOrDefault("X-Amz-Credential")
  valid_595741 = validateParameter(valid_595741, JString, required = false,
                                 default = nil)
  if valid_595741 != nil:
    section.add "X-Amz-Credential", valid_595741
  var valid_595742 = header.getOrDefault("X-Amz-Security-Token")
  valid_595742 = validateParameter(valid_595742, JString, required = false,
                                 default = nil)
  if valid_595742 != nil:
    section.add "X-Amz-Security-Token", valid_595742
  var valid_595743 = header.getOrDefault("X-Amz-Algorithm")
  valid_595743 = validateParameter(valid_595743, JString, required = false,
                                 default = nil)
  if valid_595743 != nil:
    section.add "X-Amz-Algorithm", valid_595743
  var valid_595744 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595744 = validateParameter(valid_595744, JString, required = false,
                                 default = nil)
  if valid_595744 != nil:
    section.add "X-Amz-SignedHeaders", valid_595744
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595746: Call_UpdateMaintenanceWindowTask_595734; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies a task assigned to a maintenance window. You can't change the task type, but you can change the following values:</p> <ul> <li> <p>TaskARN. For example, you can change a RUN_COMMAND task from AWS-RunPowerShellScript to AWS-RunShellScript.</p> </li> <li> <p>ServiceRoleArn</p> </li> <li> <p>TaskInvocationParameters</p> </li> <li> <p>Priority</p> </li> <li> <p>MaxConcurrency</p> </li> <li> <p>MaxErrors</p> </li> </ul> <p>If a parameter is null, then the corresponding field is not modified. Also, if you set Replace to true, then all fields required by the <a>RegisterTaskWithMaintenanceWindow</a> action are required for this request. Optional fields that aren't specified are set to null.</p>
  ## 
  let valid = call_595746.validator(path, query, header, formData, body)
  let scheme = call_595746.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595746.url(scheme.get, call_595746.host, call_595746.base,
                         call_595746.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595746, url, valid)

proc call*(call_595747: Call_UpdateMaintenanceWindowTask_595734; body: JsonNode): Recallable =
  ## updateMaintenanceWindowTask
  ## <p>Modifies a task assigned to a maintenance window. You can't change the task type, but you can change the following values:</p> <ul> <li> <p>TaskARN. For example, you can change a RUN_COMMAND task from AWS-RunPowerShellScript to AWS-RunShellScript.</p> </li> <li> <p>ServiceRoleArn</p> </li> <li> <p>TaskInvocationParameters</p> </li> <li> <p>Priority</p> </li> <li> <p>MaxConcurrency</p> </li> <li> <p>MaxErrors</p> </li> </ul> <p>If a parameter is null, then the corresponding field is not modified. Also, if you set Replace to true, then all fields required by the <a>RegisterTaskWithMaintenanceWindow</a> action are required for this request. Optional fields that aren't specified are set to null.</p>
  ##   body: JObject (required)
  var body_595748 = newJObject()
  if body != nil:
    body_595748 = body
  result = call_595747.call(nil, nil, nil, nil, body_595748)

var updateMaintenanceWindowTask* = Call_UpdateMaintenanceWindowTask_595734(
    name: "updateMaintenanceWindowTask", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateMaintenanceWindowTask",
    validator: validate_UpdateMaintenanceWindowTask_595735, base: "/",
    url: url_UpdateMaintenanceWindowTask_595736,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateManagedInstanceRole_595749 = ref object of OpenApiRestCall_593389
proc url_UpdateManagedInstanceRole_595751(protocol: Scheme; host: string;
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

proc validate_UpdateManagedInstanceRole_595750(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595752 = header.getOrDefault("X-Amz-Target")
  valid_595752 = validateParameter(valid_595752, JString, required = true, default = newJString(
      "AmazonSSM.UpdateManagedInstanceRole"))
  if valid_595752 != nil:
    section.add "X-Amz-Target", valid_595752
  var valid_595753 = header.getOrDefault("X-Amz-Signature")
  valid_595753 = validateParameter(valid_595753, JString, required = false,
                                 default = nil)
  if valid_595753 != nil:
    section.add "X-Amz-Signature", valid_595753
  var valid_595754 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595754 = validateParameter(valid_595754, JString, required = false,
                                 default = nil)
  if valid_595754 != nil:
    section.add "X-Amz-Content-Sha256", valid_595754
  var valid_595755 = header.getOrDefault("X-Amz-Date")
  valid_595755 = validateParameter(valid_595755, JString, required = false,
                                 default = nil)
  if valid_595755 != nil:
    section.add "X-Amz-Date", valid_595755
  var valid_595756 = header.getOrDefault("X-Amz-Credential")
  valid_595756 = validateParameter(valid_595756, JString, required = false,
                                 default = nil)
  if valid_595756 != nil:
    section.add "X-Amz-Credential", valid_595756
  var valid_595757 = header.getOrDefault("X-Amz-Security-Token")
  valid_595757 = validateParameter(valid_595757, JString, required = false,
                                 default = nil)
  if valid_595757 != nil:
    section.add "X-Amz-Security-Token", valid_595757
  var valid_595758 = header.getOrDefault("X-Amz-Algorithm")
  valid_595758 = validateParameter(valid_595758, JString, required = false,
                                 default = nil)
  if valid_595758 != nil:
    section.add "X-Amz-Algorithm", valid_595758
  var valid_595759 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595759 = validateParameter(valid_595759, JString, required = false,
                                 default = nil)
  if valid_595759 != nil:
    section.add "X-Amz-SignedHeaders", valid_595759
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595761: Call_UpdateManagedInstanceRole_595749; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Assigns or changes an Amazon Identity and Access Management (IAM) role for the managed instance.
  ## 
  let valid = call_595761.validator(path, query, header, formData, body)
  let scheme = call_595761.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595761.url(scheme.get, call_595761.host, call_595761.base,
                         call_595761.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595761, url, valid)

proc call*(call_595762: Call_UpdateManagedInstanceRole_595749; body: JsonNode): Recallable =
  ## updateManagedInstanceRole
  ## Assigns or changes an Amazon Identity and Access Management (IAM) role for the managed instance.
  ##   body: JObject (required)
  var body_595763 = newJObject()
  if body != nil:
    body_595763 = body
  result = call_595762.call(nil, nil, nil, nil, body_595763)

var updateManagedInstanceRole* = Call_UpdateManagedInstanceRole_595749(
    name: "updateManagedInstanceRole", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateManagedInstanceRole",
    validator: validate_UpdateManagedInstanceRole_595750, base: "/",
    url: url_UpdateManagedInstanceRole_595751,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateOpsItem_595764 = ref object of OpenApiRestCall_593389
proc url_UpdateOpsItem_595766(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateOpsItem_595765(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595767 = header.getOrDefault("X-Amz-Target")
  valid_595767 = validateParameter(valid_595767, JString, required = true, default = newJString(
      "AmazonSSM.UpdateOpsItem"))
  if valid_595767 != nil:
    section.add "X-Amz-Target", valid_595767
  var valid_595768 = header.getOrDefault("X-Amz-Signature")
  valid_595768 = validateParameter(valid_595768, JString, required = false,
                                 default = nil)
  if valid_595768 != nil:
    section.add "X-Amz-Signature", valid_595768
  var valid_595769 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595769 = validateParameter(valid_595769, JString, required = false,
                                 default = nil)
  if valid_595769 != nil:
    section.add "X-Amz-Content-Sha256", valid_595769
  var valid_595770 = header.getOrDefault("X-Amz-Date")
  valid_595770 = validateParameter(valid_595770, JString, required = false,
                                 default = nil)
  if valid_595770 != nil:
    section.add "X-Amz-Date", valid_595770
  var valid_595771 = header.getOrDefault("X-Amz-Credential")
  valid_595771 = validateParameter(valid_595771, JString, required = false,
                                 default = nil)
  if valid_595771 != nil:
    section.add "X-Amz-Credential", valid_595771
  var valid_595772 = header.getOrDefault("X-Amz-Security-Token")
  valid_595772 = validateParameter(valid_595772, JString, required = false,
                                 default = nil)
  if valid_595772 != nil:
    section.add "X-Amz-Security-Token", valid_595772
  var valid_595773 = header.getOrDefault("X-Amz-Algorithm")
  valid_595773 = validateParameter(valid_595773, JString, required = false,
                                 default = nil)
  if valid_595773 != nil:
    section.add "X-Amz-Algorithm", valid_595773
  var valid_595774 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595774 = validateParameter(valid_595774, JString, required = false,
                                 default = nil)
  if valid_595774 != nil:
    section.add "X-Amz-SignedHeaders", valid_595774
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595776: Call_UpdateOpsItem_595764; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Edit or change an OpsItem. You must have permission in AWS Identity and Access Management (IAM) to update an OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ## 
  let valid = call_595776.validator(path, query, header, formData, body)
  let scheme = call_595776.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595776.url(scheme.get, call_595776.host, call_595776.base,
                         call_595776.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595776, url, valid)

proc call*(call_595777: Call_UpdateOpsItem_595764; body: JsonNode): Recallable =
  ## updateOpsItem
  ## <p>Edit or change an OpsItem. You must have permission in AWS Identity and Access Management (IAM) to update an OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ##   body: JObject (required)
  var body_595778 = newJObject()
  if body != nil:
    body_595778 = body
  result = call_595777.call(nil, nil, nil, nil, body_595778)

var updateOpsItem* = Call_UpdateOpsItem_595764(name: "updateOpsItem",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateOpsItem",
    validator: validate_UpdateOpsItem_595765, base: "/", url: url_UpdateOpsItem_595766,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePatchBaseline_595779 = ref object of OpenApiRestCall_593389
proc url_UpdatePatchBaseline_595781(protocol: Scheme; host: string; base: string;
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

proc validate_UpdatePatchBaseline_595780(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595782 = header.getOrDefault("X-Amz-Target")
  valid_595782 = validateParameter(valid_595782, JString, required = true, default = newJString(
      "AmazonSSM.UpdatePatchBaseline"))
  if valid_595782 != nil:
    section.add "X-Amz-Target", valid_595782
  var valid_595783 = header.getOrDefault("X-Amz-Signature")
  valid_595783 = validateParameter(valid_595783, JString, required = false,
                                 default = nil)
  if valid_595783 != nil:
    section.add "X-Amz-Signature", valid_595783
  var valid_595784 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595784 = validateParameter(valid_595784, JString, required = false,
                                 default = nil)
  if valid_595784 != nil:
    section.add "X-Amz-Content-Sha256", valid_595784
  var valid_595785 = header.getOrDefault("X-Amz-Date")
  valid_595785 = validateParameter(valid_595785, JString, required = false,
                                 default = nil)
  if valid_595785 != nil:
    section.add "X-Amz-Date", valid_595785
  var valid_595786 = header.getOrDefault("X-Amz-Credential")
  valid_595786 = validateParameter(valid_595786, JString, required = false,
                                 default = nil)
  if valid_595786 != nil:
    section.add "X-Amz-Credential", valid_595786
  var valid_595787 = header.getOrDefault("X-Amz-Security-Token")
  valid_595787 = validateParameter(valid_595787, JString, required = false,
                                 default = nil)
  if valid_595787 != nil:
    section.add "X-Amz-Security-Token", valid_595787
  var valid_595788 = header.getOrDefault("X-Amz-Algorithm")
  valid_595788 = validateParameter(valid_595788, JString, required = false,
                                 default = nil)
  if valid_595788 != nil:
    section.add "X-Amz-Algorithm", valid_595788
  var valid_595789 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595789 = validateParameter(valid_595789, JString, required = false,
                                 default = nil)
  if valid_595789 != nil:
    section.add "X-Amz-SignedHeaders", valid_595789
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595791: Call_UpdatePatchBaseline_595779; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies an existing patch baseline. Fields not specified in the request are left unchanged.</p> <note> <p>For information about valid key and value pairs in <code>PatchFilters</code> for each supported operating system type, see <a href="http://docs.aws.amazon.com/systems-manager/latest/APIReference/API_PatchFilter.html">PatchFilter</a>.</p> </note>
  ## 
  let valid = call_595791.validator(path, query, header, formData, body)
  let scheme = call_595791.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595791.url(scheme.get, call_595791.host, call_595791.base,
                         call_595791.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595791, url, valid)

proc call*(call_595792: Call_UpdatePatchBaseline_595779; body: JsonNode): Recallable =
  ## updatePatchBaseline
  ## <p>Modifies an existing patch baseline. Fields not specified in the request are left unchanged.</p> <note> <p>For information about valid key and value pairs in <code>PatchFilters</code> for each supported operating system type, see <a href="http://docs.aws.amazon.com/systems-manager/latest/APIReference/API_PatchFilter.html">PatchFilter</a>.</p> </note>
  ##   body: JObject (required)
  var body_595793 = newJObject()
  if body != nil:
    body_595793 = body
  result = call_595792.call(nil, nil, nil, nil, body_595793)

var updatePatchBaseline* = Call_UpdatePatchBaseline_595779(
    name: "updatePatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdatePatchBaseline",
    validator: validate_UpdatePatchBaseline_595780, base: "/",
    url: url_UpdatePatchBaseline_595781, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateServiceSetting_595794 = ref object of OpenApiRestCall_593389
proc url_UpdateServiceSetting_595796(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateServiceSetting_595795(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595797 = header.getOrDefault("X-Amz-Target")
  valid_595797 = validateParameter(valid_595797, JString, required = true, default = newJString(
      "AmazonSSM.UpdateServiceSetting"))
  if valid_595797 != nil:
    section.add "X-Amz-Target", valid_595797
  var valid_595798 = header.getOrDefault("X-Amz-Signature")
  valid_595798 = validateParameter(valid_595798, JString, required = false,
                                 default = nil)
  if valid_595798 != nil:
    section.add "X-Amz-Signature", valid_595798
  var valid_595799 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595799 = validateParameter(valid_595799, JString, required = false,
                                 default = nil)
  if valid_595799 != nil:
    section.add "X-Amz-Content-Sha256", valid_595799
  var valid_595800 = header.getOrDefault("X-Amz-Date")
  valid_595800 = validateParameter(valid_595800, JString, required = false,
                                 default = nil)
  if valid_595800 != nil:
    section.add "X-Amz-Date", valid_595800
  var valid_595801 = header.getOrDefault("X-Amz-Credential")
  valid_595801 = validateParameter(valid_595801, JString, required = false,
                                 default = nil)
  if valid_595801 != nil:
    section.add "X-Amz-Credential", valid_595801
  var valid_595802 = header.getOrDefault("X-Amz-Security-Token")
  valid_595802 = validateParameter(valid_595802, JString, required = false,
                                 default = nil)
  if valid_595802 != nil:
    section.add "X-Amz-Security-Token", valid_595802
  var valid_595803 = header.getOrDefault("X-Amz-Algorithm")
  valid_595803 = validateParameter(valid_595803, JString, required = false,
                                 default = nil)
  if valid_595803 != nil:
    section.add "X-Amz-Algorithm", valid_595803
  var valid_595804 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595804 = validateParameter(valid_595804, JString, required = false,
                                 default = nil)
  if valid_595804 != nil:
    section.add "X-Amz-SignedHeaders", valid_595804
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595806: Call_UpdateServiceSetting_595794; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>GetServiceSetting</a> API action to view the current value. Or, use the <a>ResetServiceSetting</a> to change the value back to the original value defined by the AWS service team.</p> <p>Update the service setting for the account. </p>
  ## 
  let valid = call_595806.validator(path, query, header, formData, body)
  let scheme = call_595806.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595806.url(scheme.get, call_595806.host, call_595806.base,
                         call_595806.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595806, url, valid)

proc call*(call_595807: Call_UpdateServiceSetting_595794; body: JsonNode): Recallable =
  ## updateServiceSetting
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>GetServiceSetting</a> API action to view the current value. Or, use the <a>ResetServiceSetting</a> to change the value back to the original value defined by the AWS service team.</p> <p>Update the service setting for the account. </p>
  ##   body: JObject (required)
  var body_595808 = newJObject()
  if body != nil:
    body_595808 = body
  result = call_595807.call(nil, nil, nil, nil, body_595808)

var updateServiceSetting* = Call_UpdateServiceSetting_595794(
    name: "updateServiceSetting", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateServiceSetting",
    validator: validate_UpdateServiceSetting_595795, base: "/",
    url: url_UpdateServiceSetting_595796, schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc sign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", "")
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", "")
    region = os.getEnv("AWS_REGION", "")
  assert secret != "", "need secret key in env"
  assert access != "", "need access key in env"
  assert region != "", "need region in env"
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

method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.sign(input.getOrDefault("query"), SHA256)
