
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

  OpenApiRestCall_597389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_597389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_597389): Option[Scheme] {.used.} =
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
  Call_AddTagsToResource_597727 = ref object of OpenApiRestCall_597389
proc url_AddTagsToResource_597729(protocol: Scheme; host: string; base: string;
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

proc validate_AddTagsToResource_597728(path: JsonNode; query: JsonNode;
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
  var valid_597854 = header.getOrDefault("X-Amz-Target")
  valid_597854 = validateParameter(valid_597854, JString, required = true, default = newJString(
      "AmazonSSM.AddTagsToResource"))
  if valid_597854 != nil:
    section.add "X-Amz-Target", valid_597854
  var valid_597855 = header.getOrDefault("X-Amz-Signature")
  valid_597855 = validateParameter(valid_597855, JString, required = false,
                                 default = nil)
  if valid_597855 != nil:
    section.add "X-Amz-Signature", valid_597855
  var valid_597856 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_597856 = validateParameter(valid_597856, JString, required = false,
                                 default = nil)
  if valid_597856 != nil:
    section.add "X-Amz-Content-Sha256", valid_597856
  var valid_597857 = header.getOrDefault("X-Amz-Date")
  valid_597857 = validateParameter(valid_597857, JString, required = false,
                                 default = nil)
  if valid_597857 != nil:
    section.add "X-Amz-Date", valid_597857
  var valid_597858 = header.getOrDefault("X-Amz-Credential")
  valid_597858 = validateParameter(valid_597858, JString, required = false,
                                 default = nil)
  if valid_597858 != nil:
    section.add "X-Amz-Credential", valid_597858
  var valid_597859 = header.getOrDefault("X-Amz-Security-Token")
  valid_597859 = validateParameter(valid_597859, JString, required = false,
                                 default = nil)
  if valid_597859 != nil:
    section.add "X-Amz-Security-Token", valid_597859
  var valid_597860 = header.getOrDefault("X-Amz-Algorithm")
  valid_597860 = validateParameter(valid_597860, JString, required = false,
                                 default = nil)
  if valid_597860 != nil:
    section.add "X-Amz-Algorithm", valid_597860
  var valid_597861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_597861 = validateParameter(valid_597861, JString, required = false,
                                 default = nil)
  if valid_597861 != nil:
    section.add "X-Amz-SignedHeaders", valid_597861
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_597885: Call_AddTagsToResource_597727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds or overwrites one or more tags for the specified resource. Tags are metadata that you can assign to your documents, managed instances, maintenance windows, Parameter Store parameters, and patch baselines. Tags enable you to categorize your resources in different ways, for example, by purpose, owner, or environment. Each tag consists of a key and an optional value, both of which you define. For example, you could define a set of tags for your account's managed instances that helps you track each instance's owner and stack level. For example: Key=Owner and Value=DbAdmin, SysAdmin, or Dev. Or Key=Stack and Value=Production, Pre-Production, or Test.</p> <p>Each resource can have a maximum of 50 tags. </p> <p>We recommend that you devise a set of tag keys that meets your needs for each resource type. Using a consistent set of tag keys makes it easier for you to manage your resources. You can search and filter the resources based on the tags you add. Tags don't have any semantic meaning to Amazon EC2 and are interpreted strictly as a string of characters. </p> <p>For more information about tags, see <a href="http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Using_Tags.html">Tagging Your Amazon EC2 Resources</a> in the <i>Amazon EC2 User Guide</i>.</p>
  ## 
  let valid = call_597885.validator(path, query, header, formData, body)
  let scheme = call_597885.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_597885.url(scheme.get, call_597885.host, call_597885.base,
                         call_597885.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_597885, url, valid)

proc call*(call_597956: Call_AddTagsToResource_597727; body: JsonNode): Recallable =
  ## addTagsToResource
  ## <p>Adds or overwrites one or more tags for the specified resource. Tags are metadata that you can assign to your documents, managed instances, maintenance windows, Parameter Store parameters, and patch baselines. Tags enable you to categorize your resources in different ways, for example, by purpose, owner, or environment. Each tag consists of a key and an optional value, both of which you define. For example, you could define a set of tags for your account's managed instances that helps you track each instance's owner and stack level. For example: Key=Owner and Value=DbAdmin, SysAdmin, or Dev. Or Key=Stack and Value=Production, Pre-Production, or Test.</p> <p>Each resource can have a maximum of 50 tags. </p> <p>We recommend that you devise a set of tag keys that meets your needs for each resource type. Using a consistent set of tag keys makes it easier for you to manage your resources. You can search and filter the resources based on the tags you add. Tags don't have any semantic meaning to Amazon EC2 and are interpreted strictly as a string of characters. </p> <p>For more information about tags, see <a href="http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Using_Tags.html">Tagging Your Amazon EC2 Resources</a> in the <i>Amazon EC2 User Guide</i>.</p>
  ##   body: JObject (required)
  var body_597957 = newJObject()
  if body != nil:
    body_597957 = body
  result = call_597956.call(nil, nil, nil, nil, body_597957)

var addTagsToResource* = Call_AddTagsToResource_597727(name: "addTagsToResource",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.AddTagsToResource",
    validator: validate_AddTagsToResource_597728, base: "/",
    url: url_AddTagsToResource_597729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelCommand_597996 = ref object of OpenApiRestCall_597389
proc url_CancelCommand_597998(protocol: Scheme; host: string; base: string;
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

proc validate_CancelCommand_597997(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_597999 = header.getOrDefault("X-Amz-Target")
  valid_597999 = validateParameter(valid_597999, JString, required = true, default = newJString(
      "AmazonSSM.CancelCommand"))
  if valid_597999 != nil:
    section.add "X-Amz-Target", valid_597999
  var valid_598000 = header.getOrDefault("X-Amz-Signature")
  valid_598000 = validateParameter(valid_598000, JString, required = false,
                                 default = nil)
  if valid_598000 != nil:
    section.add "X-Amz-Signature", valid_598000
  var valid_598001 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598001 = validateParameter(valid_598001, JString, required = false,
                                 default = nil)
  if valid_598001 != nil:
    section.add "X-Amz-Content-Sha256", valid_598001
  var valid_598002 = header.getOrDefault("X-Amz-Date")
  valid_598002 = validateParameter(valid_598002, JString, required = false,
                                 default = nil)
  if valid_598002 != nil:
    section.add "X-Amz-Date", valid_598002
  var valid_598003 = header.getOrDefault("X-Amz-Credential")
  valid_598003 = validateParameter(valid_598003, JString, required = false,
                                 default = nil)
  if valid_598003 != nil:
    section.add "X-Amz-Credential", valid_598003
  var valid_598004 = header.getOrDefault("X-Amz-Security-Token")
  valid_598004 = validateParameter(valid_598004, JString, required = false,
                                 default = nil)
  if valid_598004 != nil:
    section.add "X-Amz-Security-Token", valid_598004
  var valid_598005 = header.getOrDefault("X-Amz-Algorithm")
  valid_598005 = validateParameter(valid_598005, JString, required = false,
                                 default = nil)
  if valid_598005 != nil:
    section.add "X-Amz-Algorithm", valid_598005
  var valid_598006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598006 = validateParameter(valid_598006, JString, required = false,
                                 default = nil)
  if valid_598006 != nil:
    section.add "X-Amz-SignedHeaders", valid_598006
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598008: Call_CancelCommand_597996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attempts to cancel the command specified by the Command ID. There is no guarantee that the command will be terminated and the underlying process stopped.
  ## 
  let valid = call_598008.validator(path, query, header, formData, body)
  let scheme = call_598008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598008.url(scheme.get, call_598008.host, call_598008.base,
                         call_598008.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598008, url, valid)

proc call*(call_598009: Call_CancelCommand_597996; body: JsonNode): Recallable =
  ## cancelCommand
  ## Attempts to cancel the command specified by the Command ID. There is no guarantee that the command will be terminated and the underlying process stopped.
  ##   body: JObject (required)
  var body_598010 = newJObject()
  if body != nil:
    body_598010 = body
  result = call_598009.call(nil, nil, nil, nil, body_598010)

var cancelCommand* = Call_CancelCommand_597996(name: "cancelCommand",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CancelCommand",
    validator: validate_CancelCommand_597997, base: "/", url: url_CancelCommand_597998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelMaintenanceWindowExecution_598011 = ref object of OpenApiRestCall_597389
proc url_CancelMaintenanceWindowExecution_598013(protocol: Scheme; host: string;
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

proc validate_CancelMaintenanceWindowExecution_598012(path: JsonNode;
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
  var valid_598014 = header.getOrDefault("X-Amz-Target")
  valid_598014 = validateParameter(valid_598014, JString, required = true, default = newJString(
      "AmazonSSM.CancelMaintenanceWindowExecution"))
  if valid_598014 != nil:
    section.add "X-Amz-Target", valid_598014
  var valid_598015 = header.getOrDefault("X-Amz-Signature")
  valid_598015 = validateParameter(valid_598015, JString, required = false,
                                 default = nil)
  if valid_598015 != nil:
    section.add "X-Amz-Signature", valid_598015
  var valid_598016 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598016 = validateParameter(valid_598016, JString, required = false,
                                 default = nil)
  if valid_598016 != nil:
    section.add "X-Amz-Content-Sha256", valid_598016
  var valid_598017 = header.getOrDefault("X-Amz-Date")
  valid_598017 = validateParameter(valid_598017, JString, required = false,
                                 default = nil)
  if valid_598017 != nil:
    section.add "X-Amz-Date", valid_598017
  var valid_598018 = header.getOrDefault("X-Amz-Credential")
  valid_598018 = validateParameter(valid_598018, JString, required = false,
                                 default = nil)
  if valid_598018 != nil:
    section.add "X-Amz-Credential", valid_598018
  var valid_598019 = header.getOrDefault("X-Amz-Security-Token")
  valid_598019 = validateParameter(valid_598019, JString, required = false,
                                 default = nil)
  if valid_598019 != nil:
    section.add "X-Amz-Security-Token", valid_598019
  var valid_598020 = header.getOrDefault("X-Amz-Algorithm")
  valid_598020 = validateParameter(valid_598020, JString, required = false,
                                 default = nil)
  if valid_598020 != nil:
    section.add "X-Amz-Algorithm", valid_598020
  var valid_598021 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598021 = validateParameter(valid_598021, JString, required = false,
                                 default = nil)
  if valid_598021 != nil:
    section.add "X-Amz-SignedHeaders", valid_598021
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598023: Call_CancelMaintenanceWindowExecution_598011;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Stops a maintenance window execution that is already in progress and cancels any tasks in the window that have not already starting running. (Tasks already in progress will continue to completion.)
  ## 
  let valid = call_598023.validator(path, query, header, formData, body)
  let scheme = call_598023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598023.url(scheme.get, call_598023.host, call_598023.base,
                         call_598023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598023, url, valid)

proc call*(call_598024: Call_CancelMaintenanceWindowExecution_598011;
          body: JsonNode): Recallable =
  ## cancelMaintenanceWindowExecution
  ## Stops a maintenance window execution that is already in progress and cancels any tasks in the window that have not already starting running. (Tasks already in progress will continue to completion.)
  ##   body: JObject (required)
  var body_598025 = newJObject()
  if body != nil:
    body_598025 = body
  result = call_598024.call(nil, nil, nil, nil, body_598025)

var cancelMaintenanceWindowExecution* = Call_CancelMaintenanceWindowExecution_598011(
    name: "cancelMaintenanceWindowExecution", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CancelMaintenanceWindowExecution",
    validator: validate_CancelMaintenanceWindowExecution_598012, base: "/",
    url: url_CancelMaintenanceWindowExecution_598013,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateActivation_598026 = ref object of OpenApiRestCall_597389
proc url_CreateActivation_598028(protocol: Scheme; host: string; base: string;
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

proc validate_CreateActivation_598027(path: JsonNode; query: JsonNode;
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
  var valid_598029 = header.getOrDefault("X-Amz-Target")
  valid_598029 = validateParameter(valid_598029, JString, required = true, default = newJString(
      "AmazonSSM.CreateActivation"))
  if valid_598029 != nil:
    section.add "X-Amz-Target", valid_598029
  var valid_598030 = header.getOrDefault("X-Amz-Signature")
  valid_598030 = validateParameter(valid_598030, JString, required = false,
                                 default = nil)
  if valid_598030 != nil:
    section.add "X-Amz-Signature", valid_598030
  var valid_598031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598031 = validateParameter(valid_598031, JString, required = false,
                                 default = nil)
  if valid_598031 != nil:
    section.add "X-Amz-Content-Sha256", valid_598031
  var valid_598032 = header.getOrDefault("X-Amz-Date")
  valid_598032 = validateParameter(valid_598032, JString, required = false,
                                 default = nil)
  if valid_598032 != nil:
    section.add "X-Amz-Date", valid_598032
  var valid_598033 = header.getOrDefault("X-Amz-Credential")
  valid_598033 = validateParameter(valid_598033, JString, required = false,
                                 default = nil)
  if valid_598033 != nil:
    section.add "X-Amz-Credential", valid_598033
  var valid_598034 = header.getOrDefault("X-Amz-Security-Token")
  valid_598034 = validateParameter(valid_598034, JString, required = false,
                                 default = nil)
  if valid_598034 != nil:
    section.add "X-Amz-Security-Token", valid_598034
  var valid_598035 = header.getOrDefault("X-Amz-Algorithm")
  valid_598035 = validateParameter(valid_598035, JString, required = false,
                                 default = nil)
  if valid_598035 != nil:
    section.add "X-Amz-Algorithm", valid_598035
  var valid_598036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598036 = validateParameter(valid_598036, JString, required = false,
                                 default = nil)
  if valid_598036 != nil:
    section.add "X-Amz-SignedHeaders", valid_598036
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598038: Call_CreateActivation_598026; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Registers your on-premises server or virtual machine with Amazon EC2 so that you can manage these resources using Run Command. An on-premises server or virtual machine that has been registered with EC2 is called a managed instance. For more information about activations, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-managedinstances.html">Setting Up AWS Systems Manager for Hybrid Environments</a>.
  ## 
  let valid = call_598038.validator(path, query, header, formData, body)
  let scheme = call_598038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598038.url(scheme.get, call_598038.host, call_598038.base,
                         call_598038.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598038, url, valid)

proc call*(call_598039: Call_CreateActivation_598026; body: JsonNode): Recallable =
  ## createActivation
  ## Registers your on-premises server or virtual machine with Amazon EC2 so that you can manage these resources using Run Command. An on-premises server or virtual machine that has been registered with EC2 is called a managed instance. For more information about activations, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-managedinstances.html">Setting Up AWS Systems Manager for Hybrid Environments</a>.
  ##   body: JObject (required)
  var body_598040 = newJObject()
  if body != nil:
    body_598040 = body
  result = call_598039.call(nil, nil, nil, nil, body_598040)

var createActivation* = Call_CreateActivation_598026(name: "createActivation",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateActivation",
    validator: validate_CreateActivation_598027, base: "/",
    url: url_CreateActivation_598028, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAssociation_598041 = ref object of OpenApiRestCall_597389
proc url_CreateAssociation_598043(protocol: Scheme; host: string; base: string;
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

proc validate_CreateAssociation_598042(path: JsonNode; query: JsonNode;
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
  var valid_598044 = header.getOrDefault("X-Amz-Target")
  valid_598044 = validateParameter(valid_598044, JString, required = true, default = newJString(
      "AmazonSSM.CreateAssociation"))
  if valid_598044 != nil:
    section.add "X-Amz-Target", valid_598044
  var valid_598045 = header.getOrDefault("X-Amz-Signature")
  valid_598045 = validateParameter(valid_598045, JString, required = false,
                                 default = nil)
  if valid_598045 != nil:
    section.add "X-Amz-Signature", valid_598045
  var valid_598046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598046 = validateParameter(valid_598046, JString, required = false,
                                 default = nil)
  if valid_598046 != nil:
    section.add "X-Amz-Content-Sha256", valid_598046
  var valid_598047 = header.getOrDefault("X-Amz-Date")
  valid_598047 = validateParameter(valid_598047, JString, required = false,
                                 default = nil)
  if valid_598047 != nil:
    section.add "X-Amz-Date", valid_598047
  var valid_598048 = header.getOrDefault("X-Amz-Credential")
  valid_598048 = validateParameter(valid_598048, JString, required = false,
                                 default = nil)
  if valid_598048 != nil:
    section.add "X-Amz-Credential", valid_598048
  var valid_598049 = header.getOrDefault("X-Amz-Security-Token")
  valid_598049 = validateParameter(valid_598049, JString, required = false,
                                 default = nil)
  if valid_598049 != nil:
    section.add "X-Amz-Security-Token", valid_598049
  var valid_598050 = header.getOrDefault("X-Amz-Algorithm")
  valid_598050 = validateParameter(valid_598050, JString, required = false,
                                 default = nil)
  if valid_598050 != nil:
    section.add "X-Amz-Algorithm", valid_598050
  var valid_598051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598051 = validateParameter(valid_598051, JString, required = false,
                                 default = nil)
  if valid_598051 != nil:
    section.add "X-Amz-SignedHeaders", valid_598051
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598053: Call_CreateAssociation_598041; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates the specified Systems Manager document with the specified instances or targets.</p> <p>When you associate a document with one or more instances using instance IDs or tags, SSM Agent running on the instance processes the document and configures the instance as specified.</p> <p>If you associate a document with an instance that already has an associated document, the system returns the AssociationAlreadyExists exception.</p>
  ## 
  let valid = call_598053.validator(path, query, header, formData, body)
  let scheme = call_598053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598053.url(scheme.get, call_598053.host, call_598053.base,
                         call_598053.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598053, url, valid)

proc call*(call_598054: Call_CreateAssociation_598041; body: JsonNode): Recallable =
  ## createAssociation
  ## <p>Associates the specified Systems Manager document with the specified instances or targets.</p> <p>When you associate a document with one or more instances using instance IDs or tags, SSM Agent running on the instance processes the document and configures the instance as specified.</p> <p>If you associate a document with an instance that already has an associated document, the system returns the AssociationAlreadyExists exception.</p>
  ##   body: JObject (required)
  var body_598055 = newJObject()
  if body != nil:
    body_598055 = body
  result = call_598054.call(nil, nil, nil, nil, body_598055)

var createAssociation* = Call_CreateAssociation_598041(name: "createAssociation",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateAssociation",
    validator: validate_CreateAssociation_598042, base: "/",
    url: url_CreateAssociation_598043, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAssociationBatch_598056 = ref object of OpenApiRestCall_597389
proc url_CreateAssociationBatch_598058(protocol: Scheme; host: string; base: string;
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

proc validate_CreateAssociationBatch_598057(path: JsonNode; query: JsonNode;
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
  var valid_598059 = header.getOrDefault("X-Amz-Target")
  valid_598059 = validateParameter(valid_598059, JString, required = true, default = newJString(
      "AmazonSSM.CreateAssociationBatch"))
  if valid_598059 != nil:
    section.add "X-Amz-Target", valid_598059
  var valid_598060 = header.getOrDefault("X-Amz-Signature")
  valid_598060 = validateParameter(valid_598060, JString, required = false,
                                 default = nil)
  if valid_598060 != nil:
    section.add "X-Amz-Signature", valid_598060
  var valid_598061 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598061 = validateParameter(valid_598061, JString, required = false,
                                 default = nil)
  if valid_598061 != nil:
    section.add "X-Amz-Content-Sha256", valid_598061
  var valid_598062 = header.getOrDefault("X-Amz-Date")
  valid_598062 = validateParameter(valid_598062, JString, required = false,
                                 default = nil)
  if valid_598062 != nil:
    section.add "X-Amz-Date", valid_598062
  var valid_598063 = header.getOrDefault("X-Amz-Credential")
  valid_598063 = validateParameter(valid_598063, JString, required = false,
                                 default = nil)
  if valid_598063 != nil:
    section.add "X-Amz-Credential", valid_598063
  var valid_598064 = header.getOrDefault("X-Amz-Security-Token")
  valid_598064 = validateParameter(valid_598064, JString, required = false,
                                 default = nil)
  if valid_598064 != nil:
    section.add "X-Amz-Security-Token", valid_598064
  var valid_598065 = header.getOrDefault("X-Amz-Algorithm")
  valid_598065 = validateParameter(valid_598065, JString, required = false,
                                 default = nil)
  if valid_598065 != nil:
    section.add "X-Amz-Algorithm", valid_598065
  var valid_598066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598066 = validateParameter(valid_598066, JString, required = false,
                                 default = nil)
  if valid_598066 != nil:
    section.add "X-Amz-SignedHeaders", valid_598066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598068: Call_CreateAssociationBatch_598056; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates the specified Systems Manager document with the specified instances or targets.</p> <p>When you associate a document with one or more instances using instance IDs or tags, SSM Agent running on the instance processes the document and configures the instance as specified.</p> <p>If you associate a document with an instance that already has an associated document, the system returns the AssociationAlreadyExists exception.</p>
  ## 
  let valid = call_598068.validator(path, query, header, formData, body)
  let scheme = call_598068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598068.url(scheme.get, call_598068.host, call_598068.base,
                         call_598068.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598068, url, valid)

proc call*(call_598069: Call_CreateAssociationBatch_598056; body: JsonNode): Recallable =
  ## createAssociationBatch
  ## <p>Associates the specified Systems Manager document with the specified instances or targets.</p> <p>When you associate a document with one or more instances using instance IDs or tags, SSM Agent running on the instance processes the document and configures the instance as specified.</p> <p>If you associate a document with an instance that already has an associated document, the system returns the AssociationAlreadyExists exception.</p>
  ##   body: JObject (required)
  var body_598070 = newJObject()
  if body != nil:
    body_598070 = body
  result = call_598069.call(nil, nil, nil, nil, body_598070)

var createAssociationBatch* = Call_CreateAssociationBatch_598056(
    name: "createAssociationBatch", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateAssociationBatch",
    validator: validate_CreateAssociationBatch_598057, base: "/",
    url: url_CreateAssociationBatch_598058, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDocument_598071 = ref object of OpenApiRestCall_597389
proc url_CreateDocument_598073(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDocument_598072(path: JsonNode; query: JsonNode;
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
  var valid_598074 = header.getOrDefault("X-Amz-Target")
  valid_598074 = validateParameter(valid_598074, JString, required = true, default = newJString(
      "AmazonSSM.CreateDocument"))
  if valid_598074 != nil:
    section.add "X-Amz-Target", valid_598074
  var valid_598075 = header.getOrDefault("X-Amz-Signature")
  valid_598075 = validateParameter(valid_598075, JString, required = false,
                                 default = nil)
  if valid_598075 != nil:
    section.add "X-Amz-Signature", valid_598075
  var valid_598076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598076 = validateParameter(valid_598076, JString, required = false,
                                 default = nil)
  if valid_598076 != nil:
    section.add "X-Amz-Content-Sha256", valid_598076
  var valid_598077 = header.getOrDefault("X-Amz-Date")
  valid_598077 = validateParameter(valid_598077, JString, required = false,
                                 default = nil)
  if valid_598077 != nil:
    section.add "X-Amz-Date", valid_598077
  var valid_598078 = header.getOrDefault("X-Amz-Credential")
  valid_598078 = validateParameter(valid_598078, JString, required = false,
                                 default = nil)
  if valid_598078 != nil:
    section.add "X-Amz-Credential", valid_598078
  var valid_598079 = header.getOrDefault("X-Amz-Security-Token")
  valid_598079 = validateParameter(valid_598079, JString, required = false,
                                 default = nil)
  if valid_598079 != nil:
    section.add "X-Amz-Security-Token", valid_598079
  var valid_598080 = header.getOrDefault("X-Amz-Algorithm")
  valid_598080 = validateParameter(valid_598080, JString, required = false,
                                 default = nil)
  if valid_598080 != nil:
    section.add "X-Amz-Algorithm", valid_598080
  var valid_598081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598081 = validateParameter(valid_598081, JString, required = false,
                                 default = nil)
  if valid_598081 != nil:
    section.add "X-Amz-SignedHeaders", valid_598081
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598083: Call_CreateDocument_598071; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Systems Manager document.</p> <p>After you create a document, you can use CreateAssociation to associate it with one or more running instances.</p>
  ## 
  let valid = call_598083.validator(path, query, header, formData, body)
  let scheme = call_598083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598083.url(scheme.get, call_598083.host, call_598083.base,
                         call_598083.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598083, url, valid)

proc call*(call_598084: Call_CreateDocument_598071; body: JsonNode): Recallable =
  ## createDocument
  ## <p>Creates a Systems Manager document.</p> <p>After you create a document, you can use CreateAssociation to associate it with one or more running instances.</p>
  ##   body: JObject (required)
  var body_598085 = newJObject()
  if body != nil:
    body_598085 = body
  result = call_598084.call(nil, nil, nil, nil, body_598085)

var createDocument* = Call_CreateDocument_598071(name: "createDocument",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateDocument",
    validator: validate_CreateDocument_598072, base: "/", url: url_CreateDocument_598073,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMaintenanceWindow_598086 = ref object of OpenApiRestCall_597389
proc url_CreateMaintenanceWindow_598088(protocol: Scheme; host: string; base: string;
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

proc validate_CreateMaintenanceWindow_598087(path: JsonNode; query: JsonNode;
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
  var valid_598089 = header.getOrDefault("X-Amz-Target")
  valid_598089 = validateParameter(valid_598089, JString, required = true, default = newJString(
      "AmazonSSM.CreateMaintenanceWindow"))
  if valid_598089 != nil:
    section.add "X-Amz-Target", valid_598089
  var valid_598090 = header.getOrDefault("X-Amz-Signature")
  valid_598090 = validateParameter(valid_598090, JString, required = false,
                                 default = nil)
  if valid_598090 != nil:
    section.add "X-Amz-Signature", valid_598090
  var valid_598091 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598091 = validateParameter(valid_598091, JString, required = false,
                                 default = nil)
  if valid_598091 != nil:
    section.add "X-Amz-Content-Sha256", valid_598091
  var valid_598092 = header.getOrDefault("X-Amz-Date")
  valid_598092 = validateParameter(valid_598092, JString, required = false,
                                 default = nil)
  if valid_598092 != nil:
    section.add "X-Amz-Date", valid_598092
  var valid_598093 = header.getOrDefault("X-Amz-Credential")
  valid_598093 = validateParameter(valid_598093, JString, required = false,
                                 default = nil)
  if valid_598093 != nil:
    section.add "X-Amz-Credential", valid_598093
  var valid_598094 = header.getOrDefault("X-Amz-Security-Token")
  valid_598094 = validateParameter(valid_598094, JString, required = false,
                                 default = nil)
  if valid_598094 != nil:
    section.add "X-Amz-Security-Token", valid_598094
  var valid_598095 = header.getOrDefault("X-Amz-Algorithm")
  valid_598095 = validateParameter(valid_598095, JString, required = false,
                                 default = nil)
  if valid_598095 != nil:
    section.add "X-Amz-Algorithm", valid_598095
  var valid_598096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598096 = validateParameter(valid_598096, JString, required = false,
                                 default = nil)
  if valid_598096 != nil:
    section.add "X-Amz-SignedHeaders", valid_598096
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598098: Call_CreateMaintenanceWindow_598086; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new maintenance window.</p> <note> <p>The value you specify for <code>Duration</code> determines the specific end time for the maintenance window based on the time it begins. No maintenance window tasks are permitted to start after the resulting endtime minus the number of hours you specify for <code>Cutoff</code>. For example, if the maintenance window starts at 3 PM, the duration is three hours, and the value you specify for <code>Cutoff</code> is one hour, no maintenance window tasks can start after 5 PM.</p> </note>
  ## 
  let valid = call_598098.validator(path, query, header, formData, body)
  let scheme = call_598098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598098.url(scheme.get, call_598098.host, call_598098.base,
                         call_598098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598098, url, valid)

proc call*(call_598099: Call_CreateMaintenanceWindow_598086; body: JsonNode): Recallable =
  ## createMaintenanceWindow
  ## <p>Creates a new maintenance window.</p> <note> <p>The value you specify for <code>Duration</code> determines the specific end time for the maintenance window based on the time it begins. No maintenance window tasks are permitted to start after the resulting endtime minus the number of hours you specify for <code>Cutoff</code>. For example, if the maintenance window starts at 3 PM, the duration is three hours, and the value you specify for <code>Cutoff</code> is one hour, no maintenance window tasks can start after 5 PM.</p> </note>
  ##   body: JObject (required)
  var body_598100 = newJObject()
  if body != nil:
    body_598100 = body
  result = call_598099.call(nil, nil, nil, nil, body_598100)

var createMaintenanceWindow* = Call_CreateMaintenanceWindow_598086(
    name: "createMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateMaintenanceWindow",
    validator: validate_CreateMaintenanceWindow_598087, base: "/",
    url: url_CreateMaintenanceWindow_598088, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateOpsItem_598101 = ref object of OpenApiRestCall_597389
proc url_CreateOpsItem_598103(protocol: Scheme; host: string; base: string;
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

proc validate_CreateOpsItem_598102(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598104 = header.getOrDefault("X-Amz-Target")
  valid_598104 = validateParameter(valid_598104, JString, required = true, default = newJString(
      "AmazonSSM.CreateOpsItem"))
  if valid_598104 != nil:
    section.add "X-Amz-Target", valid_598104
  var valid_598105 = header.getOrDefault("X-Amz-Signature")
  valid_598105 = validateParameter(valid_598105, JString, required = false,
                                 default = nil)
  if valid_598105 != nil:
    section.add "X-Amz-Signature", valid_598105
  var valid_598106 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598106 = validateParameter(valid_598106, JString, required = false,
                                 default = nil)
  if valid_598106 != nil:
    section.add "X-Amz-Content-Sha256", valid_598106
  var valid_598107 = header.getOrDefault("X-Amz-Date")
  valid_598107 = validateParameter(valid_598107, JString, required = false,
                                 default = nil)
  if valid_598107 != nil:
    section.add "X-Amz-Date", valid_598107
  var valid_598108 = header.getOrDefault("X-Amz-Credential")
  valid_598108 = validateParameter(valid_598108, JString, required = false,
                                 default = nil)
  if valid_598108 != nil:
    section.add "X-Amz-Credential", valid_598108
  var valid_598109 = header.getOrDefault("X-Amz-Security-Token")
  valid_598109 = validateParameter(valid_598109, JString, required = false,
                                 default = nil)
  if valid_598109 != nil:
    section.add "X-Amz-Security-Token", valid_598109
  var valid_598110 = header.getOrDefault("X-Amz-Algorithm")
  valid_598110 = validateParameter(valid_598110, JString, required = false,
                                 default = nil)
  if valid_598110 != nil:
    section.add "X-Amz-Algorithm", valid_598110
  var valid_598111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598111 = validateParameter(valid_598111, JString, required = false,
                                 default = nil)
  if valid_598111 != nil:
    section.add "X-Amz-SignedHeaders", valid_598111
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598113: Call_CreateOpsItem_598101; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new OpsItem. You must have permission in AWS Identity and Access Management (IAM) to create a new OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ## 
  let valid = call_598113.validator(path, query, header, formData, body)
  let scheme = call_598113.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598113.url(scheme.get, call_598113.host, call_598113.base,
                         call_598113.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598113, url, valid)

proc call*(call_598114: Call_CreateOpsItem_598101; body: JsonNode): Recallable =
  ## createOpsItem
  ## <p>Creates a new OpsItem. You must have permission in AWS Identity and Access Management (IAM) to create a new OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ##   body: JObject (required)
  var body_598115 = newJObject()
  if body != nil:
    body_598115 = body
  result = call_598114.call(nil, nil, nil, nil, body_598115)

var createOpsItem* = Call_CreateOpsItem_598101(name: "createOpsItem",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateOpsItem",
    validator: validate_CreateOpsItem_598102, base: "/", url: url_CreateOpsItem_598103,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePatchBaseline_598116 = ref object of OpenApiRestCall_597389
proc url_CreatePatchBaseline_598118(protocol: Scheme; host: string; base: string;
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

proc validate_CreatePatchBaseline_598117(path: JsonNode; query: JsonNode;
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
  var valid_598119 = header.getOrDefault("X-Amz-Target")
  valid_598119 = validateParameter(valid_598119, JString, required = true, default = newJString(
      "AmazonSSM.CreatePatchBaseline"))
  if valid_598119 != nil:
    section.add "X-Amz-Target", valid_598119
  var valid_598120 = header.getOrDefault("X-Amz-Signature")
  valid_598120 = validateParameter(valid_598120, JString, required = false,
                                 default = nil)
  if valid_598120 != nil:
    section.add "X-Amz-Signature", valid_598120
  var valid_598121 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598121 = validateParameter(valid_598121, JString, required = false,
                                 default = nil)
  if valid_598121 != nil:
    section.add "X-Amz-Content-Sha256", valid_598121
  var valid_598122 = header.getOrDefault("X-Amz-Date")
  valid_598122 = validateParameter(valid_598122, JString, required = false,
                                 default = nil)
  if valid_598122 != nil:
    section.add "X-Amz-Date", valid_598122
  var valid_598123 = header.getOrDefault("X-Amz-Credential")
  valid_598123 = validateParameter(valid_598123, JString, required = false,
                                 default = nil)
  if valid_598123 != nil:
    section.add "X-Amz-Credential", valid_598123
  var valid_598124 = header.getOrDefault("X-Amz-Security-Token")
  valid_598124 = validateParameter(valid_598124, JString, required = false,
                                 default = nil)
  if valid_598124 != nil:
    section.add "X-Amz-Security-Token", valid_598124
  var valid_598125 = header.getOrDefault("X-Amz-Algorithm")
  valid_598125 = validateParameter(valid_598125, JString, required = false,
                                 default = nil)
  if valid_598125 != nil:
    section.add "X-Amz-Algorithm", valid_598125
  var valid_598126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598126 = validateParameter(valid_598126, JString, required = false,
                                 default = nil)
  if valid_598126 != nil:
    section.add "X-Amz-SignedHeaders", valid_598126
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598128: Call_CreatePatchBaseline_598116; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a patch baseline.</p> <note> <p>For information about valid key and value pairs in <code>PatchFilters</code> for each supported operating system type, see <a href="http://docs.aws.amazon.com/systems-manager/latest/APIReference/API_PatchFilter.html">PatchFilter</a>.</p> </note>
  ## 
  let valid = call_598128.validator(path, query, header, formData, body)
  let scheme = call_598128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598128.url(scheme.get, call_598128.host, call_598128.base,
                         call_598128.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598128, url, valid)

proc call*(call_598129: Call_CreatePatchBaseline_598116; body: JsonNode): Recallable =
  ## createPatchBaseline
  ## <p>Creates a patch baseline.</p> <note> <p>For information about valid key and value pairs in <code>PatchFilters</code> for each supported operating system type, see <a href="http://docs.aws.amazon.com/systems-manager/latest/APIReference/API_PatchFilter.html">PatchFilter</a>.</p> </note>
  ##   body: JObject (required)
  var body_598130 = newJObject()
  if body != nil:
    body_598130 = body
  result = call_598129.call(nil, nil, nil, nil, body_598130)

var createPatchBaseline* = Call_CreatePatchBaseline_598116(
    name: "createPatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreatePatchBaseline",
    validator: validate_CreatePatchBaseline_598117, base: "/",
    url: url_CreatePatchBaseline_598118, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResourceDataSync_598131 = ref object of OpenApiRestCall_597389
proc url_CreateResourceDataSync_598133(protocol: Scheme; host: string; base: string;
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

proc validate_CreateResourceDataSync_598132(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>A resource data sync helps you view data from multiple sources in a single location. Systems Manager offers two types of resource data sync: <code>SyncToDestination</code> and <code>SyncFromSource</code>.</p> <p>You can configure Systems Manager Inventory to use the <code>SyncToDestination</code> type to synchronize Inventory data from multiple AWS Regions to a single Amazon S3 bucket. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-inventory-datasync.html">Configuring Resource Data Sync for Inventory</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>You can configure Systems Manager Explorer to use the <code>SyncToDestination</code> type to synchronize operational work items (OpsItems) and operational data (OpsData) from multiple AWS Regions to a single Amazon S3 bucket. You can also configure Explorer to use the <code>SyncFromSource</code> type. This type synchronizes OpsItems and OpsData from multiple AWS accounts and Regions by using AWS Organizations. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/Explorer-resource-data-sync.html">Setting Up Explorer to Display Data from Multiple Accounts and Regions</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>A resource data sync is an asynchronous operation that returns immediately. After a successful initial sync is completed, the system continuously syncs data. To check the status of a sync, use the <a>ListResourceDataSync</a>.</p> <note> <p>By default, data is not encrypted in Amazon S3. We strongly recommend that you enable encryption in Amazon S3 to ensure secure data storage. We also recommend that you secure access to the Amazon S3 bucket by creating a restrictive bucket policy. </p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_598134 = header.getOrDefault("X-Amz-Target")
  valid_598134 = validateParameter(valid_598134, JString, required = true, default = newJString(
      "AmazonSSM.CreateResourceDataSync"))
  if valid_598134 != nil:
    section.add "X-Amz-Target", valid_598134
  var valid_598135 = header.getOrDefault("X-Amz-Signature")
  valid_598135 = validateParameter(valid_598135, JString, required = false,
                                 default = nil)
  if valid_598135 != nil:
    section.add "X-Amz-Signature", valid_598135
  var valid_598136 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598136 = validateParameter(valid_598136, JString, required = false,
                                 default = nil)
  if valid_598136 != nil:
    section.add "X-Amz-Content-Sha256", valid_598136
  var valid_598137 = header.getOrDefault("X-Amz-Date")
  valid_598137 = validateParameter(valid_598137, JString, required = false,
                                 default = nil)
  if valid_598137 != nil:
    section.add "X-Amz-Date", valid_598137
  var valid_598138 = header.getOrDefault("X-Amz-Credential")
  valid_598138 = validateParameter(valid_598138, JString, required = false,
                                 default = nil)
  if valid_598138 != nil:
    section.add "X-Amz-Credential", valid_598138
  var valid_598139 = header.getOrDefault("X-Amz-Security-Token")
  valid_598139 = validateParameter(valid_598139, JString, required = false,
                                 default = nil)
  if valid_598139 != nil:
    section.add "X-Amz-Security-Token", valid_598139
  var valid_598140 = header.getOrDefault("X-Amz-Algorithm")
  valid_598140 = validateParameter(valid_598140, JString, required = false,
                                 default = nil)
  if valid_598140 != nil:
    section.add "X-Amz-Algorithm", valid_598140
  var valid_598141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598141 = validateParameter(valid_598141, JString, required = false,
                                 default = nil)
  if valid_598141 != nil:
    section.add "X-Amz-SignedHeaders", valid_598141
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598143: Call_CreateResourceDataSync_598131; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>A resource data sync helps you view data from multiple sources in a single location. Systems Manager offers two types of resource data sync: <code>SyncToDestination</code> and <code>SyncFromSource</code>.</p> <p>You can configure Systems Manager Inventory to use the <code>SyncToDestination</code> type to synchronize Inventory data from multiple AWS Regions to a single Amazon S3 bucket. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-inventory-datasync.html">Configuring Resource Data Sync for Inventory</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>You can configure Systems Manager Explorer to use the <code>SyncToDestination</code> type to synchronize operational work items (OpsItems) and operational data (OpsData) from multiple AWS Regions to a single Amazon S3 bucket. You can also configure Explorer to use the <code>SyncFromSource</code> type. This type synchronizes OpsItems and OpsData from multiple AWS accounts and Regions by using AWS Organizations. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/Explorer-resource-data-sync.html">Setting Up Explorer to Display Data from Multiple Accounts and Regions</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>A resource data sync is an asynchronous operation that returns immediately. After a successful initial sync is completed, the system continuously syncs data. To check the status of a sync, use the <a>ListResourceDataSync</a>.</p> <note> <p>By default, data is not encrypted in Amazon S3. We strongly recommend that you enable encryption in Amazon S3 to ensure secure data storage. We also recommend that you secure access to the Amazon S3 bucket by creating a restrictive bucket policy. </p> </note>
  ## 
  let valid = call_598143.validator(path, query, header, formData, body)
  let scheme = call_598143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598143.url(scheme.get, call_598143.host, call_598143.base,
                         call_598143.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598143, url, valid)

proc call*(call_598144: Call_CreateResourceDataSync_598131; body: JsonNode): Recallable =
  ## createResourceDataSync
  ## <p>A resource data sync helps you view data from multiple sources in a single location. Systems Manager offers two types of resource data sync: <code>SyncToDestination</code> and <code>SyncFromSource</code>.</p> <p>You can configure Systems Manager Inventory to use the <code>SyncToDestination</code> type to synchronize Inventory data from multiple AWS Regions to a single Amazon S3 bucket. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-inventory-datasync.html">Configuring Resource Data Sync for Inventory</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>You can configure Systems Manager Explorer to use the <code>SyncToDestination</code> type to synchronize operational work items (OpsItems) and operational data (OpsData) from multiple AWS Regions to a single Amazon S3 bucket. You can also configure Explorer to use the <code>SyncFromSource</code> type. This type synchronizes OpsItems and OpsData from multiple AWS accounts and Regions by using AWS Organizations. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/Explorer-resource-data-sync.html">Setting Up Explorer to Display Data from Multiple Accounts and Regions</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>A resource data sync is an asynchronous operation that returns immediately. After a successful initial sync is completed, the system continuously syncs data. To check the status of a sync, use the <a>ListResourceDataSync</a>.</p> <note> <p>By default, data is not encrypted in Amazon S3. We strongly recommend that you enable encryption in Amazon S3 to ensure secure data storage. We also recommend that you secure access to the Amazon S3 bucket by creating a restrictive bucket policy. </p> </note>
  ##   body: JObject (required)
  var body_598145 = newJObject()
  if body != nil:
    body_598145 = body
  result = call_598144.call(nil, nil, nil, nil, body_598145)

var createResourceDataSync* = Call_CreateResourceDataSync_598131(
    name: "createResourceDataSync", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateResourceDataSync",
    validator: validate_CreateResourceDataSync_598132, base: "/",
    url: url_CreateResourceDataSync_598133, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteActivation_598146 = ref object of OpenApiRestCall_597389
proc url_DeleteActivation_598148(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteActivation_598147(path: JsonNode; query: JsonNode;
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
  var valid_598149 = header.getOrDefault("X-Amz-Target")
  valid_598149 = validateParameter(valid_598149, JString, required = true, default = newJString(
      "AmazonSSM.DeleteActivation"))
  if valid_598149 != nil:
    section.add "X-Amz-Target", valid_598149
  var valid_598150 = header.getOrDefault("X-Amz-Signature")
  valid_598150 = validateParameter(valid_598150, JString, required = false,
                                 default = nil)
  if valid_598150 != nil:
    section.add "X-Amz-Signature", valid_598150
  var valid_598151 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598151 = validateParameter(valid_598151, JString, required = false,
                                 default = nil)
  if valid_598151 != nil:
    section.add "X-Amz-Content-Sha256", valid_598151
  var valid_598152 = header.getOrDefault("X-Amz-Date")
  valid_598152 = validateParameter(valid_598152, JString, required = false,
                                 default = nil)
  if valid_598152 != nil:
    section.add "X-Amz-Date", valid_598152
  var valid_598153 = header.getOrDefault("X-Amz-Credential")
  valid_598153 = validateParameter(valid_598153, JString, required = false,
                                 default = nil)
  if valid_598153 != nil:
    section.add "X-Amz-Credential", valid_598153
  var valid_598154 = header.getOrDefault("X-Amz-Security-Token")
  valid_598154 = validateParameter(valid_598154, JString, required = false,
                                 default = nil)
  if valid_598154 != nil:
    section.add "X-Amz-Security-Token", valid_598154
  var valid_598155 = header.getOrDefault("X-Amz-Algorithm")
  valid_598155 = validateParameter(valid_598155, JString, required = false,
                                 default = nil)
  if valid_598155 != nil:
    section.add "X-Amz-Algorithm", valid_598155
  var valid_598156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598156 = validateParameter(valid_598156, JString, required = false,
                                 default = nil)
  if valid_598156 != nil:
    section.add "X-Amz-SignedHeaders", valid_598156
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598158: Call_DeleteActivation_598146; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an activation. You are not required to delete an activation. If you delete an activation, you can no longer use it to register additional managed instances. Deleting an activation does not de-register managed instances. You must manually de-register managed instances.
  ## 
  let valid = call_598158.validator(path, query, header, formData, body)
  let scheme = call_598158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598158.url(scheme.get, call_598158.host, call_598158.base,
                         call_598158.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598158, url, valid)

proc call*(call_598159: Call_DeleteActivation_598146; body: JsonNode): Recallable =
  ## deleteActivation
  ## Deletes an activation. You are not required to delete an activation. If you delete an activation, you can no longer use it to register additional managed instances. Deleting an activation does not de-register managed instances. You must manually de-register managed instances.
  ##   body: JObject (required)
  var body_598160 = newJObject()
  if body != nil:
    body_598160 = body
  result = call_598159.call(nil, nil, nil, nil, body_598160)

var deleteActivation* = Call_DeleteActivation_598146(name: "deleteActivation",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteActivation",
    validator: validate_DeleteActivation_598147, base: "/",
    url: url_DeleteActivation_598148, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAssociation_598161 = ref object of OpenApiRestCall_597389
proc url_DeleteAssociation_598163(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAssociation_598162(path: JsonNode; query: JsonNode;
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
  var valid_598164 = header.getOrDefault("X-Amz-Target")
  valid_598164 = validateParameter(valid_598164, JString, required = true, default = newJString(
      "AmazonSSM.DeleteAssociation"))
  if valid_598164 != nil:
    section.add "X-Amz-Target", valid_598164
  var valid_598165 = header.getOrDefault("X-Amz-Signature")
  valid_598165 = validateParameter(valid_598165, JString, required = false,
                                 default = nil)
  if valid_598165 != nil:
    section.add "X-Amz-Signature", valid_598165
  var valid_598166 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598166 = validateParameter(valid_598166, JString, required = false,
                                 default = nil)
  if valid_598166 != nil:
    section.add "X-Amz-Content-Sha256", valid_598166
  var valid_598167 = header.getOrDefault("X-Amz-Date")
  valid_598167 = validateParameter(valid_598167, JString, required = false,
                                 default = nil)
  if valid_598167 != nil:
    section.add "X-Amz-Date", valid_598167
  var valid_598168 = header.getOrDefault("X-Amz-Credential")
  valid_598168 = validateParameter(valid_598168, JString, required = false,
                                 default = nil)
  if valid_598168 != nil:
    section.add "X-Amz-Credential", valid_598168
  var valid_598169 = header.getOrDefault("X-Amz-Security-Token")
  valid_598169 = validateParameter(valid_598169, JString, required = false,
                                 default = nil)
  if valid_598169 != nil:
    section.add "X-Amz-Security-Token", valid_598169
  var valid_598170 = header.getOrDefault("X-Amz-Algorithm")
  valid_598170 = validateParameter(valid_598170, JString, required = false,
                                 default = nil)
  if valid_598170 != nil:
    section.add "X-Amz-Algorithm", valid_598170
  var valid_598171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598171 = validateParameter(valid_598171, JString, required = false,
                                 default = nil)
  if valid_598171 != nil:
    section.add "X-Amz-SignedHeaders", valid_598171
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598173: Call_DeleteAssociation_598161; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disassociates the specified Systems Manager document from the specified instance.</p> <p>When you disassociate a document from an instance, it does not change the configuration of the instance. To change the configuration state of an instance after you disassociate a document, you must create a new document with the desired configuration and associate it with the instance.</p>
  ## 
  let valid = call_598173.validator(path, query, header, formData, body)
  let scheme = call_598173.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598173.url(scheme.get, call_598173.host, call_598173.base,
                         call_598173.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598173, url, valid)

proc call*(call_598174: Call_DeleteAssociation_598161; body: JsonNode): Recallable =
  ## deleteAssociation
  ## <p>Disassociates the specified Systems Manager document from the specified instance.</p> <p>When you disassociate a document from an instance, it does not change the configuration of the instance. To change the configuration state of an instance after you disassociate a document, you must create a new document with the desired configuration and associate it with the instance.</p>
  ##   body: JObject (required)
  var body_598175 = newJObject()
  if body != nil:
    body_598175 = body
  result = call_598174.call(nil, nil, nil, nil, body_598175)

var deleteAssociation* = Call_DeleteAssociation_598161(name: "deleteAssociation",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteAssociation",
    validator: validate_DeleteAssociation_598162, base: "/",
    url: url_DeleteAssociation_598163, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDocument_598176 = ref object of OpenApiRestCall_597389
proc url_DeleteDocument_598178(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDocument_598177(path: JsonNode; query: JsonNode;
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
  var valid_598179 = header.getOrDefault("X-Amz-Target")
  valid_598179 = validateParameter(valid_598179, JString, required = true, default = newJString(
      "AmazonSSM.DeleteDocument"))
  if valid_598179 != nil:
    section.add "X-Amz-Target", valid_598179
  var valid_598180 = header.getOrDefault("X-Amz-Signature")
  valid_598180 = validateParameter(valid_598180, JString, required = false,
                                 default = nil)
  if valid_598180 != nil:
    section.add "X-Amz-Signature", valid_598180
  var valid_598181 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598181 = validateParameter(valid_598181, JString, required = false,
                                 default = nil)
  if valid_598181 != nil:
    section.add "X-Amz-Content-Sha256", valid_598181
  var valid_598182 = header.getOrDefault("X-Amz-Date")
  valid_598182 = validateParameter(valid_598182, JString, required = false,
                                 default = nil)
  if valid_598182 != nil:
    section.add "X-Amz-Date", valid_598182
  var valid_598183 = header.getOrDefault("X-Amz-Credential")
  valid_598183 = validateParameter(valid_598183, JString, required = false,
                                 default = nil)
  if valid_598183 != nil:
    section.add "X-Amz-Credential", valid_598183
  var valid_598184 = header.getOrDefault("X-Amz-Security-Token")
  valid_598184 = validateParameter(valid_598184, JString, required = false,
                                 default = nil)
  if valid_598184 != nil:
    section.add "X-Amz-Security-Token", valid_598184
  var valid_598185 = header.getOrDefault("X-Amz-Algorithm")
  valid_598185 = validateParameter(valid_598185, JString, required = false,
                                 default = nil)
  if valid_598185 != nil:
    section.add "X-Amz-Algorithm", valid_598185
  var valid_598186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598186 = validateParameter(valid_598186, JString, required = false,
                                 default = nil)
  if valid_598186 != nil:
    section.add "X-Amz-SignedHeaders", valid_598186
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598188: Call_DeleteDocument_598176; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the Systems Manager document and all instance associations to the document.</p> <p>Before you delete the document, we recommend that you use <a>DeleteAssociation</a> to disassociate all instances that are associated with the document.</p>
  ## 
  let valid = call_598188.validator(path, query, header, formData, body)
  let scheme = call_598188.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598188.url(scheme.get, call_598188.host, call_598188.base,
                         call_598188.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598188, url, valid)

proc call*(call_598189: Call_DeleteDocument_598176; body: JsonNode): Recallable =
  ## deleteDocument
  ## <p>Deletes the Systems Manager document and all instance associations to the document.</p> <p>Before you delete the document, we recommend that you use <a>DeleteAssociation</a> to disassociate all instances that are associated with the document.</p>
  ##   body: JObject (required)
  var body_598190 = newJObject()
  if body != nil:
    body_598190 = body
  result = call_598189.call(nil, nil, nil, nil, body_598190)

var deleteDocument* = Call_DeleteDocument_598176(name: "deleteDocument",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteDocument",
    validator: validate_DeleteDocument_598177, base: "/", url: url_DeleteDocument_598178,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInventory_598191 = ref object of OpenApiRestCall_597389
proc url_DeleteInventory_598193(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteInventory_598192(path: JsonNode; query: JsonNode;
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
  var valid_598194 = header.getOrDefault("X-Amz-Target")
  valid_598194 = validateParameter(valid_598194, JString, required = true, default = newJString(
      "AmazonSSM.DeleteInventory"))
  if valid_598194 != nil:
    section.add "X-Amz-Target", valid_598194
  var valid_598195 = header.getOrDefault("X-Amz-Signature")
  valid_598195 = validateParameter(valid_598195, JString, required = false,
                                 default = nil)
  if valid_598195 != nil:
    section.add "X-Amz-Signature", valid_598195
  var valid_598196 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598196 = validateParameter(valid_598196, JString, required = false,
                                 default = nil)
  if valid_598196 != nil:
    section.add "X-Amz-Content-Sha256", valid_598196
  var valid_598197 = header.getOrDefault("X-Amz-Date")
  valid_598197 = validateParameter(valid_598197, JString, required = false,
                                 default = nil)
  if valid_598197 != nil:
    section.add "X-Amz-Date", valid_598197
  var valid_598198 = header.getOrDefault("X-Amz-Credential")
  valid_598198 = validateParameter(valid_598198, JString, required = false,
                                 default = nil)
  if valid_598198 != nil:
    section.add "X-Amz-Credential", valid_598198
  var valid_598199 = header.getOrDefault("X-Amz-Security-Token")
  valid_598199 = validateParameter(valid_598199, JString, required = false,
                                 default = nil)
  if valid_598199 != nil:
    section.add "X-Amz-Security-Token", valid_598199
  var valid_598200 = header.getOrDefault("X-Amz-Algorithm")
  valid_598200 = validateParameter(valid_598200, JString, required = false,
                                 default = nil)
  if valid_598200 != nil:
    section.add "X-Amz-Algorithm", valid_598200
  var valid_598201 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598201 = validateParameter(valid_598201, JString, required = false,
                                 default = nil)
  if valid_598201 != nil:
    section.add "X-Amz-SignedHeaders", valid_598201
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598203: Call_DeleteInventory_598191; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a custom inventory type, or the data associated with a custom Inventory type. Deleting a custom inventory type is also referred to as deleting a custom inventory schema.
  ## 
  let valid = call_598203.validator(path, query, header, formData, body)
  let scheme = call_598203.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598203.url(scheme.get, call_598203.host, call_598203.base,
                         call_598203.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598203, url, valid)

proc call*(call_598204: Call_DeleteInventory_598191; body: JsonNode): Recallable =
  ## deleteInventory
  ## Delete a custom inventory type, or the data associated with a custom Inventory type. Deleting a custom inventory type is also referred to as deleting a custom inventory schema.
  ##   body: JObject (required)
  var body_598205 = newJObject()
  if body != nil:
    body_598205 = body
  result = call_598204.call(nil, nil, nil, nil, body_598205)

var deleteInventory* = Call_DeleteInventory_598191(name: "deleteInventory",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteInventory",
    validator: validate_DeleteInventory_598192, base: "/", url: url_DeleteInventory_598193,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMaintenanceWindow_598206 = ref object of OpenApiRestCall_597389
proc url_DeleteMaintenanceWindow_598208(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteMaintenanceWindow_598207(path: JsonNode; query: JsonNode;
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
  var valid_598209 = header.getOrDefault("X-Amz-Target")
  valid_598209 = validateParameter(valid_598209, JString, required = true, default = newJString(
      "AmazonSSM.DeleteMaintenanceWindow"))
  if valid_598209 != nil:
    section.add "X-Amz-Target", valid_598209
  var valid_598210 = header.getOrDefault("X-Amz-Signature")
  valid_598210 = validateParameter(valid_598210, JString, required = false,
                                 default = nil)
  if valid_598210 != nil:
    section.add "X-Amz-Signature", valid_598210
  var valid_598211 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598211 = validateParameter(valid_598211, JString, required = false,
                                 default = nil)
  if valid_598211 != nil:
    section.add "X-Amz-Content-Sha256", valid_598211
  var valid_598212 = header.getOrDefault("X-Amz-Date")
  valid_598212 = validateParameter(valid_598212, JString, required = false,
                                 default = nil)
  if valid_598212 != nil:
    section.add "X-Amz-Date", valid_598212
  var valid_598213 = header.getOrDefault("X-Amz-Credential")
  valid_598213 = validateParameter(valid_598213, JString, required = false,
                                 default = nil)
  if valid_598213 != nil:
    section.add "X-Amz-Credential", valid_598213
  var valid_598214 = header.getOrDefault("X-Amz-Security-Token")
  valid_598214 = validateParameter(valid_598214, JString, required = false,
                                 default = nil)
  if valid_598214 != nil:
    section.add "X-Amz-Security-Token", valid_598214
  var valid_598215 = header.getOrDefault("X-Amz-Algorithm")
  valid_598215 = validateParameter(valid_598215, JString, required = false,
                                 default = nil)
  if valid_598215 != nil:
    section.add "X-Amz-Algorithm", valid_598215
  var valid_598216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598216 = validateParameter(valid_598216, JString, required = false,
                                 default = nil)
  if valid_598216 != nil:
    section.add "X-Amz-SignedHeaders", valid_598216
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598218: Call_DeleteMaintenanceWindow_598206; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a maintenance window.
  ## 
  let valid = call_598218.validator(path, query, header, formData, body)
  let scheme = call_598218.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598218.url(scheme.get, call_598218.host, call_598218.base,
                         call_598218.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598218, url, valid)

proc call*(call_598219: Call_DeleteMaintenanceWindow_598206; body: JsonNode): Recallable =
  ## deleteMaintenanceWindow
  ## Deletes a maintenance window.
  ##   body: JObject (required)
  var body_598220 = newJObject()
  if body != nil:
    body_598220 = body
  result = call_598219.call(nil, nil, nil, nil, body_598220)

var deleteMaintenanceWindow* = Call_DeleteMaintenanceWindow_598206(
    name: "deleteMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteMaintenanceWindow",
    validator: validate_DeleteMaintenanceWindow_598207, base: "/",
    url: url_DeleteMaintenanceWindow_598208, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteParameter_598221 = ref object of OpenApiRestCall_597389
proc url_DeleteParameter_598223(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteParameter_598222(path: JsonNode; query: JsonNode;
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
  var valid_598224 = header.getOrDefault("X-Amz-Target")
  valid_598224 = validateParameter(valid_598224, JString, required = true, default = newJString(
      "AmazonSSM.DeleteParameter"))
  if valid_598224 != nil:
    section.add "X-Amz-Target", valid_598224
  var valid_598225 = header.getOrDefault("X-Amz-Signature")
  valid_598225 = validateParameter(valid_598225, JString, required = false,
                                 default = nil)
  if valid_598225 != nil:
    section.add "X-Amz-Signature", valid_598225
  var valid_598226 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598226 = validateParameter(valid_598226, JString, required = false,
                                 default = nil)
  if valid_598226 != nil:
    section.add "X-Amz-Content-Sha256", valid_598226
  var valid_598227 = header.getOrDefault("X-Amz-Date")
  valid_598227 = validateParameter(valid_598227, JString, required = false,
                                 default = nil)
  if valid_598227 != nil:
    section.add "X-Amz-Date", valid_598227
  var valid_598228 = header.getOrDefault("X-Amz-Credential")
  valid_598228 = validateParameter(valid_598228, JString, required = false,
                                 default = nil)
  if valid_598228 != nil:
    section.add "X-Amz-Credential", valid_598228
  var valid_598229 = header.getOrDefault("X-Amz-Security-Token")
  valid_598229 = validateParameter(valid_598229, JString, required = false,
                                 default = nil)
  if valid_598229 != nil:
    section.add "X-Amz-Security-Token", valid_598229
  var valid_598230 = header.getOrDefault("X-Amz-Algorithm")
  valid_598230 = validateParameter(valid_598230, JString, required = false,
                                 default = nil)
  if valid_598230 != nil:
    section.add "X-Amz-Algorithm", valid_598230
  var valid_598231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598231 = validateParameter(valid_598231, JString, required = false,
                                 default = nil)
  if valid_598231 != nil:
    section.add "X-Amz-SignedHeaders", valid_598231
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598233: Call_DeleteParameter_598221; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a parameter from the system.
  ## 
  let valid = call_598233.validator(path, query, header, formData, body)
  let scheme = call_598233.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598233.url(scheme.get, call_598233.host, call_598233.base,
                         call_598233.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598233, url, valid)

proc call*(call_598234: Call_DeleteParameter_598221; body: JsonNode): Recallable =
  ## deleteParameter
  ## Delete a parameter from the system.
  ##   body: JObject (required)
  var body_598235 = newJObject()
  if body != nil:
    body_598235 = body
  result = call_598234.call(nil, nil, nil, nil, body_598235)

var deleteParameter* = Call_DeleteParameter_598221(name: "deleteParameter",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteParameter",
    validator: validate_DeleteParameter_598222, base: "/", url: url_DeleteParameter_598223,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteParameters_598236 = ref object of OpenApiRestCall_597389
proc url_DeleteParameters_598238(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteParameters_598237(path: JsonNode; query: JsonNode;
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
  var valid_598239 = header.getOrDefault("X-Amz-Target")
  valid_598239 = validateParameter(valid_598239, JString, required = true, default = newJString(
      "AmazonSSM.DeleteParameters"))
  if valid_598239 != nil:
    section.add "X-Amz-Target", valid_598239
  var valid_598240 = header.getOrDefault("X-Amz-Signature")
  valid_598240 = validateParameter(valid_598240, JString, required = false,
                                 default = nil)
  if valid_598240 != nil:
    section.add "X-Amz-Signature", valid_598240
  var valid_598241 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598241 = validateParameter(valid_598241, JString, required = false,
                                 default = nil)
  if valid_598241 != nil:
    section.add "X-Amz-Content-Sha256", valid_598241
  var valid_598242 = header.getOrDefault("X-Amz-Date")
  valid_598242 = validateParameter(valid_598242, JString, required = false,
                                 default = nil)
  if valid_598242 != nil:
    section.add "X-Amz-Date", valid_598242
  var valid_598243 = header.getOrDefault("X-Amz-Credential")
  valid_598243 = validateParameter(valid_598243, JString, required = false,
                                 default = nil)
  if valid_598243 != nil:
    section.add "X-Amz-Credential", valid_598243
  var valid_598244 = header.getOrDefault("X-Amz-Security-Token")
  valid_598244 = validateParameter(valid_598244, JString, required = false,
                                 default = nil)
  if valid_598244 != nil:
    section.add "X-Amz-Security-Token", valid_598244
  var valid_598245 = header.getOrDefault("X-Amz-Algorithm")
  valid_598245 = validateParameter(valid_598245, JString, required = false,
                                 default = nil)
  if valid_598245 != nil:
    section.add "X-Amz-Algorithm", valid_598245
  var valid_598246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598246 = validateParameter(valid_598246, JString, required = false,
                                 default = nil)
  if valid_598246 != nil:
    section.add "X-Amz-SignedHeaders", valid_598246
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598248: Call_DeleteParameters_598236; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a list of parameters.
  ## 
  let valid = call_598248.validator(path, query, header, formData, body)
  let scheme = call_598248.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598248.url(scheme.get, call_598248.host, call_598248.base,
                         call_598248.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598248, url, valid)

proc call*(call_598249: Call_DeleteParameters_598236; body: JsonNode): Recallable =
  ## deleteParameters
  ## Delete a list of parameters.
  ##   body: JObject (required)
  var body_598250 = newJObject()
  if body != nil:
    body_598250 = body
  result = call_598249.call(nil, nil, nil, nil, body_598250)

var deleteParameters* = Call_DeleteParameters_598236(name: "deleteParameters",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteParameters",
    validator: validate_DeleteParameters_598237, base: "/",
    url: url_DeleteParameters_598238, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePatchBaseline_598251 = ref object of OpenApiRestCall_597389
proc url_DeletePatchBaseline_598253(protocol: Scheme; host: string; base: string;
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

proc validate_DeletePatchBaseline_598252(path: JsonNode; query: JsonNode;
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
  var valid_598254 = header.getOrDefault("X-Amz-Target")
  valid_598254 = validateParameter(valid_598254, JString, required = true, default = newJString(
      "AmazonSSM.DeletePatchBaseline"))
  if valid_598254 != nil:
    section.add "X-Amz-Target", valid_598254
  var valid_598255 = header.getOrDefault("X-Amz-Signature")
  valid_598255 = validateParameter(valid_598255, JString, required = false,
                                 default = nil)
  if valid_598255 != nil:
    section.add "X-Amz-Signature", valid_598255
  var valid_598256 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598256 = validateParameter(valid_598256, JString, required = false,
                                 default = nil)
  if valid_598256 != nil:
    section.add "X-Amz-Content-Sha256", valid_598256
  var valid_598257 = header.getOrDefault("X-Amz-Date")
  valid_598257 = validateParameter(valid_598257, JString, required = false,
                                 default = nil)
  if valid_598257 != nil:
    section.add "X-Amz-Date", valid_598257
  var valid_598258 = header.getOrDefault("X-Amz-Credential")
  valid_598258 = validateParameter(valid_598258, JString, required = false,
                                 default = nil)
  if valid_598258 != nil:
    section.add "X-Amz-Credential", valid_598258
  var valid_598259 = header.getOrDefault("X-Amz-Security-Token")
  valid_598259 = validateParameter(valid_598259, JString, required = false,
                                 default = nil)
  if valid_598259 != nil:
    section.add "X-Amz-Security-Token", valid_598259
  var valid_598260 = header.getOrDefault("X-Amz-Algorithm")
  valid_598260 = validateParameter(valid_598260, JString, required = false,
                                 default = nil)
  if valid_598260 != nil:
    section.add "X-Amz-Algorithm", valid_598260
  var valid_598261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598261 = validateParameter(valid_598261, JString, required = false,
                                 default = nil)
  if valid_598261 != nil:
    section.add "X-Amz-SignedHeaders", valid_598261
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598263: Call_DeletePatchBaseline_598251; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a patch baseline.
  ## 
  let valid = call_598263.validator(path, query, header, formData, body)
  let scheme = call_598263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598263.url(scheme.get, call_598263.host, call_598263.base,
                         call_598263.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598263, url, valid)

proc call*(call_598264: Call_DeletePatchBaseline_598251; body: JsonNode): Recallable =
  ## deletePatchBaseline
  ## Deletes a patch baseline.
  ##   body: JObject (required)
  var body_598265 = newJObject()
  if body != nil:
    body_598265 = body
  result = call_598264.call(nil, nil, nil, nil, body_598265)

var deletePatchBaseline* = Call_DeletePatchBaseline_598251(
    name: "deletePatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeletePatchBaseline",
    validator: validate_DeletePatchBaseline_598252, base: "/",
    url: url_DeletePatchBaseline_598253, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResourceDataSync_598266 = ref object of OpenApiRestCall_597389
proc url_DeleteResourceDataSync_598268(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteResourceDataSync_598267(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598269 = header.getOrDefault("X-Amz-Target")
  valid_598269 = validateParameter(valid_598269, JString, required = true, default = newJString(
      "AmazonSSM.DeleteResourceDataSync"))
  if valid_598269 != nil:
    section.add "X-Amz-Target", valid_598269
  var valid_598270 = header.getOrDefault("X-Amz-Signature")
  valid_598270 = validateParameter(valid_598270, JString, required = false,
                                 default = nil)
  if valid_598270 != nil:
    section.add "X-Amz-Signature", valid_598270
  var valid_598271 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598271 = validateParameter(valid_598271, JString, required = false,
                                 default = nil)
  if valid_598271 != nil:
    section.add "X-Amz-Content-Sha256", valid_598271
  var valid_598272 = header.getOrDefault("X-Amz-Date")
  valid_598272 = validateParameter(valid_598272, JString, required = false,
                                 default = nil)
  if valid_598272 != nil:
    section.add "X-Amz-Date", valid_598272
  var valid_598273 = header.getOrDefault("X-Amz-Credential")
  valid_598273 = validateParameter(valid_598273, JString, required = false,
                                 default = nil)
  if valid_598273 != nil:
    section.add "X-Amz-Credential", valid_598273
  var valid_598274 = header.getOrDefault("X-Amz-Security-Token")
  valid_598274 = validateParameter(valid_598274, JString, required = false,
                                 default = nil)
  if valid_598274 != nil:
    section.add "X-Amz-Security-Token", valid_598274
  var valid_598275 = header.getOrDefault("X-Amz-Algorithm")
  valid_598275 = validateParameter(valid_598275, JString, required = false,
                                 default = nil)
  if valid_598275 != nil:
    section.add "X-Amz-Algorithm", valid_598275
  var valid_598276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598276 = validateParameter(valid_598276, JString, required = false,
                                 default = nil)
  if valid_598276 != nil:
    section.add "X-Amz-SignedHeaders", valid_598276
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598278: Call_DeleteResourceDataSync_598266; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Resource Data Sync configuration. After the configuration is deleted, changes to data on managed instances are no longer synced to or from the target. Deleting a sync configuration does not delete data.
  ## 
  let valid = call_598278.validator(path, query, header, formData, body)
  let scheme = call_598278.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598278.url(scheme.get, call_598278.host, call_598278.base,
                         call_598278.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598278, url, valid)

proc call*(call_598279: Call_DeleteResourceDataSync_598266; body: JsonNode): Recallable =
  ## deleteResourceDataSync
  ## Deletes a Resource Data Sync configuration. After the configuration is deleted, changes to data on managed instances are no longer synced to or from the target. Deleting a sync configuration does not delete data.
  ##   body: JObject (required)
  var body_598280 = newJObject()
  if body != nil:
    body_598280 = body
  result = call_598279.call(nil, nil, nil, nil, body_598280)

var deleteResourceDataSync* = Call_DeleteResourceDataSync_598266(
    name: "deleteResourceDataSync", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteResourceDataSync",
    validator: validate_DeleteResourceDataSync_598267, base: "/",
    url: url_DeleteResourceDataSync_598268, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterManagedInstance_598281 = ref object of OpenApiRestCall_597389
proc url_DeregisterManagedInstance_598283(protocol: Scheme; host: string;
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

proc validate_DeregisterManagedInstance_598282(path: JsonNode; query: JsonNode;
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
  var valid_598284 = header.getOrDefault("X-Amz-Target")
  valid_598284 = validateParameter(valid_598284, JString, required = true, default = newJString(
      "AmazonSSM.DeregisterManagedInstance"))
  if valid_598284 != nil:
    section.add "X-Amz-Target", valid_598284
  var valid_598285 = header.getOrDefault("X-Amz-Signature")
  valid_598285 = validateParameter(valid_598285, JString, required = false,
                                 default = nil)
  if valid_598285 != nil:
    section.add "X-Amz-Signature", valid_598285
  var valid_598286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598286 = validateParameter(valid_598286, JString, required = false,
                                 default = nil)
  if valid_598286 != nil:
    section.add "X-Amz-Content-Sha256", valid_598286
  var valid_598287 = header.getOrDefault("X-Amz-Date")
  valid_598287 = validateParameter(valid_598287, JString, required = false,
                                 default = nil)
  if valid_598287 != nil:
    section.add "X-Amz-Date", valid_598287
  var valid_598288 = header.getOrDefault("X-Amz-Credential")
  valid_598288 = validateParameter(valid_598288, JString, required = false,
                                 default = nil)
  if valid_598288 != nil:
    section.add "X-Amz-Credential", valid_598288
  var valid_598289 = header.getOrDefault("X-Amz-Security-Token")
  valid_598289 = validateParameter(valid_598289, JString, required = false,
                                 default = nil)
  if valid_598289 != nil:
    section.add "X-Amz-Security-Token", valid_598289
  var valid_598290 = header.getOrDefault("X-Amz-Algorithm")
  valid_598290 = validateParameter(valid_598290, JString, required = false,
                                 default = nil)
  if valid_598290 != nil:
    section.add "X-Amz-Algorithm", valid_598290
  var valid_598291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598291 = validateParameter(valid_598291, JString, required = false,
                                 default = nil)
  if valid_598291 != nil:
    section.add "X-Amz-SignedHeaders", valid_598291
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598293: Call_DeregisterManagedInstance_598281; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the server or virtual machine from the list of registered servers. You can reregister the instance again at any time. If you don't plan to use Run Command on the server, we suggest uninstalling SSM Agent first.
  ## 
  let valid = call_598293.validator(path, query, header, formData, body)
  let scheme = call_598293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598293.url(scheme.get, call_598293.host, call_598293.base,
                         call_598293.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598293, url, valid)

proc call*(call_598294: Call_DeregisterManagedInstance_598281; body: JsonNode): Recallable =
  ## deregisterManagedInstance
  ## Removes the server or virtual machine from the list of registered servers. You can reregister the instance again at any time. If you don't plan to use Run Command on the server, we suggest uninstalling SSM Agent first.
  ##   body: JObject (required)
  var body_598295 = newJObject()
  if body != nil:
    body_598295 = body
  result = call_598294.call(nil, nil, nil, nil, body_598295)

var deregisterManagedInstance* = Call_DeregisterManagedInstance_598281(
    name: "deregisterManagedInstance", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeregisterManagedInstance",
    validator: validate_DeregisterManagedInstance_598282, base: "/",
    url: url_DeregisterManagedInstance_598283,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterPatchBaselineForPatchGroup_598296 = ref object of OpenApiRestCall_597389
proc url_DeregisterPatchBaselineForPatchGroup_598298(protocol: Scheme;
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

proc validate_DeregisterPatchBaselineForPatchGroup_598297(path: JsonNode;
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
  var valid_598299 = header.getOrDefault("X-Amz-Target")
  valid_598299 = validateParameter(valid_598299, JString, required = true, default = newJString(
      "AmazonSSM.DeregisterPatchBaselineForPatchGroup"))
  if valid_598299 != nil:
    section.add "X-Amz-Target", valid_598299
  var valid_598300 = header.getOrDefault("X-Amz-Signature")
  valid_598300 = validateParameter(valid_598300, JString, required = false,
                                 default = nil)
  if valid_598300 != nil:
    section.add "X-Amz-Signature", valid_598300
  var valid_598301 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598301 = validateParameter(valid_598301, JString, required = false,
                                 default = nil)
  if valid_598301 != nil:
    section.add "X-Amz-Content-Sha256", valid_598301
  var valid_598302 = header.getOrDefault("X-Amz-Date")
  valid_598302 = validateParameter(valid_598302, JString, required = false,
                                 default = nil)
  if valid_598302 != nil:
    section.add "X-Amz-Date", valid_598302
  var valid_598303 = header.getOrDefault("X-Amz-Credential")
  valid_598303 = validateParameter(valid_598303, JString, required = false,
                                 default = nil)
  if valid_598303 != nil:
    section.add "X-Amz-Credential", valid_598303
  var valid_598304 = header.getOrDefault("X-Amz-Security-Token")
  valid_598304 = validateParameter(valid_598304, JString, required = false,
                                 default = nil)
  if valid_598304 != nil:
    section.add "X-Amz-Security-Token", valid_598304
  var valid_598305 = header.getOrDefault("X-Amz-Algorithm")
  valid_598305 = validateParameter(valid_598305, JString, required = false,
                                 default = nil)
  if valid_598305 != nil:
    section.add "X-Amz-Algorithm", valid_598305
  var valid_598306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598306 = validateParameter(valid_598306, JString, required = false,
                                 default = nil)
  if valid_598306 != nil:
    section.add "X-Amz-SignedHeaders", valid_598306
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598308: Call_DeregisterPatchBaselineForPatchGroup_598296;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Removes a patch group from a patch baseline.
  ## 
  let valid = call_598308.validator(path, query, header, formData, body)
  let scheme = call_598308.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598308.url(scheme.get, call_598308.host, call_598308.base,
                         call_598308.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598308, url, valid)

proc call*(call_598309: Call_DeregisterPatchBaselineForPatchGroup_598296;
          body: JsonNode): Recallable =
  ## deregisterPatchBaselineForPatchGroup
  ## Removes a patch group from a patch baseline.
  ##   body: JObject (required)
  var body_598310 = newJObject()
  if body != nil:
    body_598310 = body
  result = call_598309.call(nil, nil, nil, nil, body_598310)

var deregisterPatchBaselineForPatchGroup* = Call_DeregisterPatchBaselineForPatchGroup_598296(
    name: "deregisterPatchBaselineForPatchGroup", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeregisterPatchBaselineForPatchGroup",
    validator: validate_DeregisterPatchBaselineForPatchGroup_598297, base: "/",
    url: url_DeregisterPatchBaselineForPatchGroup_598298,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterTargetFromMaintenanceWindow_598311 = ref object of OpenApiRestCall_597389
proc url_DeregisterTargetFromMaintenanceWindow_598313(protocol: Scheme;
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

proc validate_DeregisterTargetFromMaintenanceWindow_598312(path: JsonNode;
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
  var valid_598314 = header.getOrDefault("X-Amz-Target")
  valid_598314 = validateParameter(valid_598314, JString, required = true, default = newJString(
      "AmazonSSM.DeregisterTargetFromMaintenanceWindow"))
  if valid_598314 != nil:
    section.add "X-Amz-Target", valid_598314
  var valid_598315 = header.getOrDefault("X-Amz-Signature")
  valid_598315 = validateParameter(valid_598315, JString, required = false,
                                 default = nil)
  if valid_598315 != nil:
    section.add "X-Amz-Signature", valid_598315
  var valid_598316 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598316 = validateParameter(valid_598316, JString, required = false,
                                 default = nil)
  if valid_598316 != nil:
    section.add "X-Amz-Content-Sha256", valid_598316
  var valid_598317 = header.getOrDefault("X-Amz-Date")
  valid_598317 = validateParameter(valid_598317, JString, required = false,
                                 default = nil)
  if valid_598317 != nil:
    section.add "X-Amz-Date", valid_598317
  var valid_598318 = header.getOrDefault("X-Amz-Credential")
  valid_598318 = validateParameter(valid_598318, JString, required = false,
                                 default = nil)
  if valid_598318 != nil:
    section.add "X-Amz-Credential", valid_598318
  var valid_598319 = header.getOrDefault("X-Amz-Security-Token")
  valid_598319 = validateParameter(valid_598319, JString, required = false,
                                 default = nil)
  if valid_598319 != nil:
    section.add "X-Amz-Security-Token", valid_598319
  var valid_598320 = header.getOrDefault("X-Amz-Algorithm")
  valid_598320 = validateParameter(valid_598320, JString, required = false,
                                 default = nil)
  if valid_598320 != nil:
    section.add "X-Amz-Algorithm", valid_598320
  var valid_598321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598321 = validateParameter(valid_598321, JString, required = false,
                                 default = nil)
  if valid_598321 != nil:
    section.add "X-Amz-SignedHeaders", valid_598321
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598323: Call_DeregisterTargetFromMaintenanceWindow_598311;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Removes a target from a maintenance window.
  ## 
  let valid = call_598323.validator(path, query, header, formData, body)
  let scheme = call_598323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598323.url(scheme.get, call_598323.host, call_598323.base,
                         call_598323.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598323, url, valid)

proc call*(call_598324: Call_DeregisterTargetFromMaintenanceWindow_598311;
          body: JsonNode): Recallable =
  ## deregisterTargetFromMaintenanceWindow
  ## Removes a target from a maintenance window.
  ##   body: JObject (required)
  var body_598325 = newJObject()
  if body != nil:
    body_598325 = body
  result = call_598324.call(nil, nil, nil, nil, body_598325)

var deregisterTargetFromMaintenanceWindow* = Call_DeregisterTargetFromMaintenanceWindow_598311(
    name: "deregisterTargetFromMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeregisterTargetFromMaintenanceWindow",
    validator: validate_DeregisterTargetFromMaintenanceWindow_598312, base: "/",
    url: url_DeregisterTargetFromMaintenanceWindow_598313,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterTaskFromMaintenanceWindow_598326 = ref object of OpenApiRestCall_597389
proc url_DeregisterTaskFromMaintenanceWindow_598328(protocol: Scheme; host: string;
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

proc validate_DeregisterTaskFromMaintenanceWindow_598327(path: JsonNode;
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
  var valid_598329 = header.getOrDefault("X-Amz-Target")
  valid_598329 = validateParameter(valid_598329, JString, required = true, default = newJString(
      "AmazonSSM.DeregisterTaskFromMaintenanceWindow"))
  if valid_598329 != nil:
    section.add "X-Amz-Target", valid_598329
  var valid_598330 = header.getOrDefault("X-Amz-Signature")
  valid_598330 = validateParameter(valid_598330, JString, required = false,
                                 default = nil)
  if valid_598330 != nil:
    section.add "X-Amz-Signature", valid_598330
  var valid_598331 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598331 = validateParameter(valid_598331, JString, required = false,
                                 default = nil)
  if valid_598331 != nil:
    section.add "X-Amz-Content-Sha256", valid_598331
  var valid_598332 = header.getOrDefault("X-Amz-Date")
  valid_598332 = validateParameter(valid_598332, JString, required = false,
                                 default = nil)
  if valid_598332 != nil:
    section.add "X-Amz-Date", valid_598332
  var valid_598333 = header.getOrDefault("X-Amz-Credential")
  valid_598333 = validateParameter(valid_598333, JString, required = false,
                                 default = nil)
  if valid_598333 != nil:
    section.add "X-Amz-Credential", valid_598333
  var valid_598334 = header.getOrDefault("X-Amz-Security-Token")
  valid_598334 = validateParameter(valid_598334, JString, required = false,
                                 default = nil)
  if valid_598334 != nil:
    section.add "X-Amz-Security-Token", valid_598334
  var valid_598335 = header.getOrDefault("X-Amz-Algorithm")
  valid_598335 = validateParameter(valid_598335, JString, required = false,
                                 default = nil)
  if valid_598335 != nil:
    section.add "X-Amz-Algorithm", valid_598335
  var valid_598336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598336 = validateParameter(valid_598336, JString, required = false,
                                 default = nil)
  if valid_598336 != nil:
    section.add "X-Amz-SignedHeaders", valid_598336
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598338: Call_DeregisterTaskFromMaintenanceWindow_598326;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Removes a task from a maintenance window.
  ## 
  let valid = call_598338.validator(path, query, header, formData, body)
  let scheme = call_598338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598338.url(scheme.get, call_598338.host, call_598338.base,
                         call_598338.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598338, url, valid)

proc call*(call_598339: Call_DeregisterTaskFromMaintenanceWindow_598326;
          body: JsonNode): Recallable =
  ## deregisterTaskFromMaintenanceWindow
  ## Removes a task from a maintenance window.
  ##   body: JObject (required)
  var body_598340 = newJObject()
  if body != nil:
    body_598340 = body
  result = call_598339.call(nil, nil, nil, nil, body_598340)

var deregisterTaskFromMaintenanceWindow* = Call_DeregisterTaskFromMaintenanceWindow_598326(
    name: "deregisterTaskFromMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeregisterTaskFromMaintenanceWindow",
    validator: validate_DeregisterTaskFromMaintenanceWindow_598327, base: "/",
    url: url_DeregisterTaskFromMaintenanceWindow_598328,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeActivations_598341 = ref object of OpenApiRestCall_597389
proc url_DescribeActivations_598343(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeActivations_598342(path: JsonNode; query: JsonNode;
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
  var valid_598344 = query.getOrDefault("MaxResults")
  valid_598344 = validateParameter(valid_598344, JString, required = false,
                                 default = nil)
  if valid_598344 != nil:
    section.add "MaxResults", valid_598344
  var valid_598345 = query.getOrDefault("NextToken")
  valid_598345 = validateParameter(valid_598345, JString, required = false,
                                 default = nil)
  if valid_598345 != nil:
    section.add "NextToken", valid_598345
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_598346 = header.getOrDefault("X-Amz-Target")
  valid_598346 = validateParameter(valid_598346, JString, required = true, default = newJString(
      "AmazonSSM.DescribeActivations"))
  if valid_598346 != nil:
    section.add "X-Amz-Target", valid_598346
  var valid_598347 = header.getOrDefault("X-Amz-Signature")
  valid_598347 = validateParameter(valid_598347, JString, required = false,
                                 default = nil)
  if valid_598347 != nil:
    section.add "X-Amz-Signature", valid_598347
  var valid_598348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598348 = validateParameter(valid_598348, JString, required = false,
                                 default = nil)
  if valid_598348 != nil:
    section.add "X-Amz-Content-Sha256", valid_598348
  var valid_598349 = header.getOrDefault("X-Amz-Date")
  valid_598349 = validateParameter(valid_598349, JString, required = false,
                                 default = nil)
  if valid_598349 != nil:
    section.add "X-Amz-Date", valid_598349
  var valid_598350 = header.getOrDefault("X-Amz-Credential")
  valid_598350 = validateParameter(valid_598350, JString, required = false,
                                 default = nil)
  if valid_598350 != nil:
    section.add "X-Amz-Credential", valid_598350
  var valid_598351 = header.getOrDefault("X-Amz-Security-Token")
  valid_598351 = validateParameter(valid_598351, JString, required = false,
                                 default = nil)
  if valid_598351 != nil:
    section.add "X-Amz-Security-Token", valid_598351
  var valid_598352 = header.getOrDefault("X-Amz-Algorithm")
  valid_598352 = validateParameter(valid_598352, JString, required = false,
                                 default = nil)
  if valid_598352 != nil:
    section.add "X-Amz-Algorithm", valid_598352
  var valid_598353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598353 = validateParameter(valid_598353, JString, required = false,
                                 default = nil)
  if valid_598353 != nil:
    section.add "X-Amz-SignedHeaders", valid_598353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598355: Call_DescribeActivations_598341; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes details about the activation, such as the date and time the activation was created, its expiration date, the IAM role assigned to the instances in the activation, and the number of instances registered by using this activation.
  ## 
  let valid = call_598355.validator(path, query, header, formData, body)
  let scheme = call_598355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598355.url(scheme.get, call_598355.host, call_598355.base,
                         call_598355.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598355, url, valid)

proc call*(call_598356: Call_DescribeActivations_598341; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## describeActivations
  ## Describes details about the activation, such as the date and time the activation was created, its expiration date, the IAM role assigned to the instances in the activation, and the number of instances registered by using this activation.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_598357 = newJObject()
  var body_598358 = newJObject()
  add(query_598357, "MaxResults", newJString(MaxResults))
  add(query_598357, "NextToken", newJString(NextToken))
  if body != nil:
    body_598358 = body
  result = call_598356.call(nil, query_598357, nil, nil, body_598358)

var describeActivations* = Call_DescribeActivations_598341(
    name: "describeActivations", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeActivations",
    validator: validate_DescribeActivations_598342, base: "/",
    url: url_DescribeActivations_598343, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAssociation_598360 = ref object of OpenApiRestCall_597389
proc url_DescribeAssociation_598362(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeAssociation_598361(path: JsonNode; query: JsonNode;
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
  var valid_598363 = header.getOrDefault("X-Amz-Target")
  valid_598363 = validateParameter(valid_598363, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAssociation"))
  if valid_598363 != nil:
    section.add "X-Amz-Target", valid_598363
  var valid_598364 = header.getOrDefault("X-Amz-Signature")
  valid_598364 = validateParameter(valid_598364, JString, required = false,
                                 default = nil)
  if valid_598364 != nil:
    section.add "X-Amz-Signature", valid_598364
  var valid_598365 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598365 = validateParameter(valid_598365, JString, required = false,
                                 default = nil)
  if valid_598365 != nil:
    section.add "X-Amz-Content-Sha256", valid_598365
  var valid_598366 = header.getOrDefault("X-Amz-Date")
  valid_598366 = validateParameter(valid_598366, JString, required = false,
                                 default = nil)
  if valid_598366 != nil:
    section.add "X-Amz-Date", valid_598366
  var valid_598367 = header.getOrDefault("X-Amz-Credential")
  valid_598367 = validateParameter(valid_598367, JString, required = false,
                                 default = nil)
  if valid_598367 != nil:
    section.add "X-Amz-Credential", valid_598367
  var valid_598368 = header.getOrDefault("X-Amz-Security-Token")
  valid_598368 = validateParameter(valid_598368, JString, required = false,
                                 default = nil)
  if valid_598368 != nil:
    section.add "X-Amz-Security-Token", valid_598368
  var valid_598369 = header.getOrDefault("X-Amz-Algorithm")
  valid_598369 = validateParameter(valid_598369, JString, required = false,
                                 default = nil)
  if valid_598369 != nil:
    section.add "X-Amz-Algorithm", valid_598369
  var valid_598370 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598370 = validateParameter(valid_598370, JString, required = false,
                                 default = nil)
  if valid_598370 != nil:
    section.add "X-Amz-SignedHeaders", valid_598370
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598372: Call_DescribeAssociation_598360; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the association for the specified target or instance. If you created the association by using the <code>Targets</code> parameter, then you must retrieve the association by using the association ID. If you created the association by specifying an instance ID and a Systems Manager document, then you retrieve the association by specifying the document name and the instance ID. 
  ## 
  let valid = call_598372.validator(path, query, header, formData, body)
  let scheme = call_598372.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598372.url(scheme.get, call_598372.host, call_598372.base,
                         call_598372.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598372, url, valid)

proc call*(call_598373: Call_DescribeAssociation_598360; body: JsonNode): Recallable =
  ## describeAssociation
  ## Describes the association for the specified target or instance. If you created the association by using the <code>Targets</code> parameter, then you must retrieve the association by using the association ID. If you created the association by specifying an instance ID and a Systems Manager document, then you retrieve the association by specifying the document name and the instance ID. 
  ##   body: JObject (required)
  var body_598374 = newJObject()
  if body != nil:
    body_598374 = body
  result = call_598373.call(nil, nil, nil, nil, body_598374)

var describeAssociation* = Call_DescribeAssociation_598360(
    name: "describeAssociation", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAssociation",
    validator: validate_DescribeAssociation_598361, base: "/",
    url: url_DescribeAssociation_598362, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAssociationExecutionTargets_598375 = ref object of OpenApiRestCall_597389
proc url_DescribeAssociationExecutionTargets_598377(protocol: Scheme; host: string;
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

proc validate_DescribeAssociationExecutionTargets_598376(path: JsonNode;
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
  var valid_598378 = header.getOrDefault("X-Amz-Target")
  valid_598378 = validateParameter(valid_598378, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAssociationExecutionTargets"))
  if valid_598378 != nil:
    section.add "X-Amz-Target", valid_598378
  var valid_598379 = header.getOrDefault("X-Amz-Signature")
  valid_598379 = validateParameter(valid_598379, JString, required = false,
                                 default = nil)
  if valid_598379 != nil:
    section.add "X-Amz-Signature", valid_598379
  var valid_598380 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598380 = validateParameter(valid_598380, JString, required = false,
                                 default = nil)
  if valid_598380 != nil:
    section.add "X-Amz-Content-Sha256", valid_598380
  var valid_598381 = header.getOrDefault("X-Amz-Date")
  valid_598381 = validateParameter(valid_598381, JString, required = false,
                                 default = nil)
  if valid_598381 != nil:
    section.add "X-Amz-Date", valid_598381
  var valid_598382 = header.getOrDefault("X-Amz-Credential")
  valid_598382 = validateParameter(valid_598382, JString, required = false,
                                 default = nil)
  if valid_598382 != nil:
    section.add "X-Amz-Credential", valid_598382
  var valid_598383 = header.getOrDefault("X-Amz-Security-Token")
  valid_598383 = validateParameter(valid_598383, JString, required = false,
                                 default = nil)
  if valid_598383 != nil:
    section.add "X-Amz-Security-Token", valid_598383
  var valid_598384 = header.getOrDefault("X-Amz-Algorithm")
  valid_598384 = validateParameter(valid_598384, JString, required = false,
                                 default = nil)
  if valid_598384 != nil:
    section.add "X-Amz-Algorithm", valid_598384
  var valid_598385 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598385 = validateParameter(valid_598385, JString, required = false,
                                 default = nil)
  if valid_598385 != nil:
    section.add "X-Amz-SignedHeaders", valid_598385
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598387: Call_DescribeAssociationExecutionTargets_598375;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Use this API action to view information about a specific execution of a specific association.
  ## 
  let valid = call_598387.validator(path, query, header, formData, body)
  let scheme = call_598387.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598387.url(scheme.get, call_598387.host, call_598387.base,
                         call_598387.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598387, url, valid)

proc call*(call_598388: Call_DescribeAssociationExecutionTargets_598375;
          body: JsonNode): Recallable =
  ## describeAssociationExecutionTargets
  ## Use this API action to view information about a specific execution of a specific association.
  ##   body: JObject (required)
  var body_598389 = newJObject()
  if body != nil:
    body_598389 = body
  result = call_598388.call(nil, nil, nil, nil, body_598389)

var describeAssociationExecutionTargets* = Call_DescribeAssociationExecutionTargets_598375(
    name: "describeAssociationExecutionTargets", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAssociationExecutionTargets",
    validator: validate_DescribeAssociationExecutionTargets_598376, base: "/",
    url: url_DescribeAssociationExecutionTargets_598377,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAssociationExecutions_598390 = ref object of OpenApiRestCall_597389
proc url_DescribeAssociationExecutions_598392(protocol: Scheme; host: string;
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

proc validate_DescribeAssociationExecutions_598391(path: JsonNode; query: JsonNode;
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
  var valid_598393 = header.getOrDefault("X-Amz-Target")
  valid_598393 = validateParameter(valid_598393, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAssociationExecutions"))
  if valid_598393 != nil:
    section.add "X-Amz-Target", valid_598393
  var valid_598394 = header.getOrDefault("X-Amz-Signature")
  valid_598394 = validateParameter(valid_598394, JString, required = false,
                                 default = nil)
  if valid_598394 != nil:
    section.add "X-Amz-Signature", valid_598394
  var valid_598395 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598395 = validateParameter(valid_598395, JString, required = false,
                                 default = nil)
  if valid_598395 != nil:
    section.add "X-Amz-Content-Sha256", valid_598395
  var valid_598396 = header.getOrDefault("X-Amz-Date")
  valid_598396 = validateParameter(valid_598396, JString, required = false,
                                 default = nil)
  if valid_598396 != nil:
    section.add "X-Amz-Date", valid_598396
  var valid_598397 = header.getOrDefault("X-Amz-Credential")
  valid_598397 = validateParameter(valid_598397, JString, required = false,
                                 default = nil)
  if valid_598397 != nil:
    section.add "X-Amz-Credential", valid_598397
  var valid_598398 = header.getOrDefault("X-Amz-Security-Token")
  valid_598398 = validateParameter(valid_598398, JString, required = false,
                                 default = nil)
  if valid_598398 != nil:
    section.add "X-Amz-Security-Token", valid_598398
  var valid_598399 = header.getOrDefault("X-Amz-Algorithm")
  valid_598399 = validateParameter(valid_598399, JString, required = false,
                                 default = nil)
  if valid_598399 != nil:
    section.add "X-Amz-Algorithm", valid_598399
  var valid_598400 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598400 = validateParameter(valid_598400, JString, required = false,
                                 default = nil)
  if valid_598400 != nil:
    section.add "X-Amz-SignedHeaders", valid_598400
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598402: Call_DescribeAssociationExecutions_598390; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Use this API action to view all executions for a specific association ID. 
  ## 
  let valid = call_598402.validator(path, query, header, formData, body)
  let scheme = call_598402.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598402.url(scheme.get, call_598402.host, call_598402.base,
                         call_598402.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598402, url, valid)

proc call*(call_598403: Call_DescribeAssociationExecutions_598390; body: JsonNode): Recallable =
  ## describeAssociationExecutions
  ## Use this API action to view all executions for a specific association ID. 
  ##   body: JObject (required)
  var body_598404 = newJObject()
  if body != nil:
    body_598404 = body
  result = call_598403.call(nil, nil, nil, nil, body_598404)

var describeAssociationExecutions* = Call_DescribeAssociationExecutions_598390(
    name: "describeAssociationExecutions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAssociationExecutions",
    validator: validate_DescribeAssociationExecutions_598391, base: "/",
    url: url_DescribeAssociationExecutions_598392,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAutomationExecutions_598405 = ref object of OpenApiRestCall_597389
proc url_DescribeAutomationExecutions_598407(protocol: Scheme; host: string;
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

proc validate_DescribeAutomationExecutions_598406(path: JsonNode; query: JsonNode;
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
  var valid_598408 = header.getOrDefault("X-Amz-Target")
  valid_598408 = validateParameter(valid_598408, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAutomationExecutions"))
  if valid_598408 != nil:
    section.add "X-Amz-Target", valid_598408
  var valid_598409 = header.getOrDefault("X-Amz-Signature")
  valid_598409 = validateParameter(valid_598409, JString, required = false,
                                 default = nil)
  if valid_598409 != nil:
    section.add "X-Amz-Signature", valid_598409
  var valid_598410 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598410 = validateParameter(valid_598410, JString, required = false,
                                 default = nil)
  if valid_598410 != nil:
    section.add "X-Amz-Content-Sha256", valid_598410
  var valid_598411 = header.getOrDefault("X-Amz-Date")
  valid_598411 = validateParameter(valid_598411, JString, required = false,
                                 default = nil)
  if valid_598411 != nil:
    section.add "X-Amz-Date", valid_598411
  var valid_598412 = header.getOrDefault("X-Amz-Credential")
  valid_598412 = validateParameter(valid_598412, JString, required = false,
                                 default = nil)
  if valid_598412 != nil:
    section.add "X-Amz-Credential", valid_598412
  var valid_598413 = header.getOrDefault("X-Amz-Security-Token")
  valid_598413 = validateParameter(valid_598413, JString, required = false,
                                 default = nil)
  if valid_598413 != nil:
    section.add "X-Amz-Security-Token", valid_598413
  var valid_598414 = header.getOrDefault("X-Amz-Algorithm")
  valid_598414 = validateParameter(valid_598414, JString, required = false,
                                 default = nil)
  if valid_598414 != nil:
    section.add "X-Amz-Algorithm", valid_598414
  var valid_598415 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598415 = validateParameter(valid_598415, JString, required = false,
                                 default = nil)
  if valid_598415 != nil:
    section.add "X-Amz-SignedHeaders", valid_598415
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598417: Call_DescribeAutomationExecutions_598405; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides details about all active and terminated Automation executions.
  ## 
  let valid = call_598417.validator(path, query, header, formData, body)
  let scheme = call_598417.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598417.url(scheme.get, call_598417.host, call_598417.base,
                         call_598417.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598417, url, valid)

proc call*(call_598418: Call_DescribeAutomationExecutions_598405; body: JsonNode): Recallable =
  ## describeAutomationExecutions
  ## Provides details about all active and terminated Automation executions.
  ##   body: JObject (required)
  var body_598419 = newJObject()
  if body != nil:
    body_598419 = body
  result = call_598418.call(nil, nil, nil, nil, body_598419)

var describeAutomationExecutions* = Call_DescribeAutomationExecutions_598405(
    name: "describeAutomationExecutions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAutomationExecutions",
    validator: validate_DescribeAutomationExecutions_598406, base: "/",
    url: url_DescribeAutomationExecutions_598407,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAutomationStepExecutions_598420 = ref object of OpenApiRestCall_597389
proc url_DescribeAutomationStepExecutions_598422(protocol: Scheme; host: string;
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

proc validate_DescribeAutomationStepExecutions_598421(path: JsonNode;
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
  var valid_598423 = header.getOrDefault("X-Amz-Target")
  valid_598423 = validateParameter(valid_598423, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAutomationStepExecutions"))
  if valid_598423 != nil:
    section.add "X-Amz-Target", valid_598423
  var valid_598424 = header.getOrDefault("X-Amz-Signature")
  valid_598424 = validateParameter(valid_598424, JString, required = false,
                                 default = nil)
  if valid_598424 != nil:
    section.add "X-Amz-Signature", valid_598424
  var valid_598425 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598425 = validateParameter(valid_598425, JString, required = false,
                                 default = nil)
  if valid_598425 != nil:
    section.add "X-Amz-Content-Sha256", valid_598425
  var valid_598426 = header.getOrDefault("X-Amz-Date")
  valid_598426 = validateParameter(valid_598426, JString, required = false,
                                 default = nil)
  if valid_598426 != nil:
    section.add "X-Amz-Date", valid_598426
  var valid_598427 = header.getOrDefault("X-Amz-Credential")
  valid_598427 = validateParameter(valid_598427, JString, required = false,
                                 default = nil)
  if valid_598427 != nil:
    section.add "X-Amz-Credential", valid_598427
  var valid_598428 = header.getOrDefault("X-Amz-Security-Token")
  valid_598428 = validateParameter(valid_598428, JString, required = false,
                                 default = nil)
  if valid_598428 != nil:
    section.add "X-Amz-Security-Token", valid_598428
  var valid_598429 = header.getOrDefault("X-Amz-Algorithm")
  valid_598429 = validateParameter(valid_598429, JString, required = false,
                                 default = nil)
  if valid_598429 != nil:
    section.add "X-Amz-Algorithm", valid_598429
  var valid_598430 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598430 = validateParameter(valid_598430, JString, required = false,
                                 default = nil)
  if valid_598430 != nil:
    section.add "X-Amz-SignedHeaders", valid_598430
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598432: Call_DescribeAutomationStepExecutions_598420;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Information about all active and terminated step executions in an Automation workflow.
  ## 
  let valid = call_598432.validator(path, query, header, formData, body)
  let scheme = call_598432.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598432.url(scheme.get, call_598432.host, call_598432.base,
                         call_598432.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598432, url, valid)

proc call*(call_598433: Call_DescribeAutomationStepExecutions_598420;
          body: JsonNode): Recallable =
  ## describeAutomationStepExecutions
  ## Information about all active and terminated step executions in an Automation workflow.
  ##   body: JObject (required)
  var body_598434 = newJObject()
  if body != nil:
    body_598434 = body
  result = call_598433.call(nil, nil, nil, nil, body_598434)

var describeAutomationStepExecutions* = Call_DescribeAutomationStepExecutions_598420(
    name: "describeAutomationStepExecutions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAutomationStepExecutions",
    validator: validate_DescribeAutomationStepExecutions_598421, base: "/",
    url: url_DescribeAutomationStepExecutions_598422,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAvailablePatches_598435 = ref object of OpenApiRestCall_597389
proc url_DescribeAvailablePatches_598437(protocol: Scheme; host: string;
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

proc validate_DescribeAvailablePatches_598436(path: JsonNode; query: JsonNode;
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
  var valid_598438 = header.getOrDefault("X-Amz-Target")
  valid_598438 = validateParameter(valid_598438, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAvailablePatches"))
  if valid_598438 != nil:
    section.add "X-Amz-Target", valid_598438
  var valid_598439 = header.getOrDefault("X-Amz-Signature")
  valid_598439 = validateParameter(valid_598439, JString, required = false,
                                 default = nil)
  if valid_598439 != nil:
    section.add "X-Amz-Signature", valid_598439
  var valid_598440 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598440 = validateParameter(valid_598440, JString, required = false,
                                 default = nil)
  if valid_598440 != nil:
    section.add "X-Amz-Content-Sha256", valid_598440
  var valid_598441 = header.getOrDefault("X-Amz-Date")
  valid_598441 = validateParameter(valid_598441, JString, required = false,
                                 default = nil)
  if valid_598441 != nil:
    section.add "X-Amz-Date", valid_598441
  var valid_598442 = header.getOrDefault("X-Amz-Credential")
  valid_598442 = validateParameter(valid_598442, JString, required = false,
                                 default = nil)
  if valid_598442 != nil:
    section.add "X-Amz-Credential", valid_598442
  var valid_598443 = header.getOrDefault("X-Amz-Security-Token")
  valid_598443 = validateParameter(valid_598443, JString, required = false,
                                 default = nil)
  if valid_598443 != nil:
    section.add "X-Amz-Security-Token", valid_598443
  var valid_598444 = header.getOrDefault("X-Amz-Algorithm")
  valid_598444 = validateParameter(valid_598444, JString, required = false,
                                 default = nil)
  if valid_598444 != nil:
    section.add "X-Amz-Algorithm", valid_598444
  var valid_598445 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598445 = validateParameter(valid_598445, JString, required = false,
                                 default = nil)
  if valid_598445 != nil:
    section.add "X-Amz-SignedHeaders", valid_598445
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598447: Call_DescribeAvailablePatches_598435; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all patches eligible to be included in a patch baseline.
  ## 
  let valid = call_598447.validator(path, query, header, formData, body)
  let scheme = call_598447.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598447.url(scheme.get, call_598447.host, call_598447.base,
                         call_598447.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598447, url, valid)

proc call*(call_598448: Call_DescribeAvailablePatches_598435; body: JsonNode): Recallable =
  ## describeAvailablePatches
  ## Lists all patches eligible to be included in a patch baseline.
  ##   body: JObject (required)
  var body_598449 = newJObject()
  if body != nil:
    body_598449 = body
  result = call_598448.call(nil, nil, nil, nil, body_598449)

var describeAvailablePatches* = Call_DescribeAvailablePatches_598435(
    name: "describeAvailablePatches", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAvailablePatches",
    validator: validate_DescribeAvailablePatches_598436, base: "/",
    url: url_DescribeAvailablePatches_598437, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDocument_598450 = ref object of OpenApiRestCall_597389
proc url_DescribeDocument_598452(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeDocument_598451(path: JsonNode; query: JsonNode;
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
  var valid_598453 = header.getOrDefault("X-Amz-Target")
  valid_598453 = validateParameter(valid_598453, JString, required = true, default = newJString(
      "AmazonSSM.DescribeDocument"))
  if valid_598453 != nil:
    section.add "X-Amz-Target", valid_598453
  var valid_598454 = header.getOrDefault("X-Amz-Signature")
  valid_598454 = validateParameter(valid_598454, JString, required = false,
                                 default = nil)
  if valid_598454 != nil:
    section.add "X-Amz-Signature", valid_598454
  var valid_598455 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598455 = validateParameter(valid_598455, JString, required = false,
                                 default = nil)
  if valid_598455 != nil:
    section.add "X-Amz-Content-Sha256", valid_598455
  var valid_598456 = header.getOrDefault("X-Amz-Date")
  valid_598456 = validateParameter(valid_598456, JString, required = false,
                                 default = nil)
  if valid_598456 != nil:
    section.add "X-Amz-Date", valid_598456
  var valid_598457 = header.getOrDefault("X-Amz-Credential")
  valid_598457 = validateParameter(valid_598457, JString, required = false,
                                 default = nil)
  if valid_598457 != nil:
    section.add "X-Amz-Credential", valid_598457
  var valid_598458 = header.getOrDefault("X-Amz-Security-Token")
  valid_598458 = validateParameter(valid_598458, JString, required = false,
                                 default = nil)
  if valid_598458 != nil:
    section.add "X-Amz-Security-Token", valid_598458
  var valid_598459 = header.getOrDefault("X-Amz-Algorithm")
  valid_598459 = validateParameter(valid_598459, JString, required = false,
                                 default = nil)
  if valid_598459 != nil:
    section.add "X-Amz-Algorithm", valid_598459
  var valid_598460 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598460 = validateParameter(valid_598460, JString, required = false,
                                 default = nil)
  if valid_598460 != nil:
    section.add "X-Amz-SignedHeaders", valid_598460
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598462: Call_DescribeDocument_598450; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified Systems Manager document.
  ## 
  let valid = call_598462.validator(path, query, header, formData, body)
  let scheme = call_598462.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598462.url(scheme.get, call_598462.host, call_598462.base,
                         call_598462.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598462, url, valid)

proc call*(call_598463: Call_DescribeDocument_598450; body: JsonNode): Recallable =
  ## describeDocument
  ## Describes the specified Systems Manager document.
  ##   body: JObject (required)
  var body_598464 = newJObject()
  if body != nil:
    body_598464 = body
  result = call_598463.call(nil, nil, nil, nil, body_598464)

var describeDocument* = Call_DescribeDocument_598450(name: "describeDocument",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeDocument",
    validator: validate_DescribeDocument_598451, base: "/",
    url: url_DescribeDocument_598452, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDocumentPermission_598465 = ref object of OpenApiRestCall_597389
proc url_DescribeDocumentPermission_598467(protocol: Scheme; host: string;
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

proc validate_DescribeDocumentPermission_598466(path: JsonNode; query: JsonNode;
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
  var valid_598468 = header.getOrDefault("X-Amz-Target")
  valid_598468 = validateParameter(valid_598468, JString, required = true, default = newJString(
      "AmazonSSM.DescribeDocumentPermission"))
  if valid_598468 != nil:
    section.add "X-Amz-Target", valid_598468
  var valid_598469 = header.getOrDefault("X-Amz-Signature")
  valid_598469 = validateParameter(valid_598469, JString, required = false,
                                 default = nil)
  if valid_598469 != nil:
    section.add "X-Amz-Signature", valid_598469
  var valid_598470 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598470 = validateParameter(valid_598470, JString, required = false,
                                 default = nil)
  if valid_598470 != nil:
    section.add "X-Amz-Content-Sha256", valid_598470
  var valid_598471 = header.getOrDefault("X-Amz-Date")
  valid_598471 = validateParameter(valid_598471, JString, required = false,
                                 default = nil)
  if valid_598471 != nil:
    section.add "X-Amz-Date", valid_598471
  var valid_598472 = header.getOrDefault("X-Amz-Credential")
  valid_598472 = validateParameter(valid_598472, JString, required = false,
                                 default = nil)
  if valid_598472 != nil:
    section.add "X-Amz-Credential", valid_598472
  var valid_598473 = header.getOrDefault("X-Amz-Security-Token")
  valid_598473 = validateParameter(valid_598473, JString, required = false,
                                 default = nil)
  if valid_598473 != nil:
    section.add "X-Amz-Security-Token", valid_598473
  var valid_598474 = header.getOrDefault("X-Amz-Algorithm")
  valid_598474 = validateParameter(valid_598474, JString, required = false,
                                 default = nil)
  if valid_598474 != nil:
    section.add "X-Amz-Algorithm", valid_598474
  var valid_598475 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598475 = validateParameter(valid_598475, JString, required = false,
                                 default = nil)
  if valid_598475 != nil:
    section.add "X-Amz-SignedHeaders", valid_598475
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598477: Call_DescribeDocumentPermission_598465; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the permissions for a Systems Manager document. If you created the document, you are the owner. If a document is shared, it can either be shared privately (by specifying a user's AWS account ID) or publicly (<i>All</i>). 
  ## 
  let valid = call_598477.validator(path, query, header, formData, body)
  let scheme = call_598477.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598477.url(scheme.get, call_598477.host, call_598477.base,
                         call_598477.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598477, url, valid)

proc call*(call_598478: Call_DescribeDocumentPermission_598465; body: JsonNode): Recallable =
  ## describeDocumentPermission
  ## Describes the permissions for a Systems Manager document. If you created the document, you are the owner. If a document is shared, it can either be shared privately (by specifying a user's AWS account ID) or publicly (<i>All</i>). 
  ##   body: JObject (required)
  var body_598479 = newJObject()
  if body != nil:
    body_598479 = body
  result = call_598478.call(nil, nil, nil, nil, body_598479)

var describeDocumentPermission* = Call_DescribeDocumentPermission_598465(
    name: "describeDocumentPermission", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeDocumentPermission",
    validator: validate_DescribeDocumentPermission_598466, base: "/",
    url: url_DescribeDocumentPermission_598467,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEffectiveInstanceAssociations_598480 = ref object of OpenApiRestCall_597389
proc url_DescribeEffectiveInstanceAssociations_598482(protocol: Scheme;
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

proc validate_DescribeEffectiveInstanceAssociations_598481(path: JsonNode;
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
  var valid_598483 = header.getOrDefault("X-Amz-Target")
  valid_598483 = validateParameter(valid_598483, JString, required = true, default = newJString(
      "AmazonSSM.DescribeEffectiveInstanceAssociations"))
  if valid_598483 != nil:
    section.add "X-Amz-Target", valid_598483
  var valid_598484 = header.getOrDefault("X-Amz-Signature")
  valid_598484 = validateParameter(valid_598484, JString, required = false,
                                 default = nil)
  if valid_598484 != nil:
    section.add "X-Amz-Signature", valid_598484
  var valid_598485 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598485 = validateParameter(valid_598485, JString, required = false,
                                 default = nil)
  if valid_598485 != nil:
    section.add "X-Amz-Content-Sha256", valid_598485
  var valid_598486 = header.getOrDefault("X-Amz-Date")
  valid_598486 = validateParameter(valid_598486, JString, required = false,
                                 default = nil)
  if valid_598486 != nil:
    section.add "X-Amz-Date", valid_598486
  var valid_598487 = header.getOrDefault("X-Amz-Credential")
  valid_598487 = validateParameter(valid_598487, JString, required = false,
                                 default = nil)
  if valid_598487 != nil:
    section.add "X-Amz-Credential", valid_598487
  var valid_598488 = header.getOrDefault("X-Amz-Security-Token")
  valid_598488 = validateParameter(valid_598488, JString, required = false,
                                 default = nil)
  if valid_598488 != nil:
    section.add "X-Amz-Security-Token", valid_598488
  var valid_598489 = header.getOrDefault("X-Amz-Algorithm")
  valid_598489 = validateParameter(valid_598489, JString, required = false,
                                 default = nil)
  if valid_598489 != nil:
    section.add "X-Amz-Algorithm", valid_598489
  var valid_598490 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598490 = validateParameter(valid_598490, JString, required = false,
                                 default = nil)
  if valid_598490 != nil:
    section.add "X-Amz-SignedHeaders", valid_598490
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598492: Call_DescribeEffectiveInstanceAssociations_598480;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## All associations for the instance(s).
  ## 
  let valid = call_598492.validator(path, query, header, formData, body)
  let scheme = call_598492.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598492.url(scheme.get, call_598492.host, call_598492.base,
                         call_598492.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598492, url, valid)

proc call*(call_598493: Call_DescribeEffectiveInstanceAssociations_598480;
          body: JsonNode): Recallable =
  ## describeEffectiveInstanceAssociations
  ## All associations for the instance(s).
  ##   body: JObject (required)
  var body_598494 = newJObject()
  if body != nil:
    body_598494 = body
  result = call_598493.call(nil, nil, nil, nil, body_598494)

var describeEffectiveInstanceAssociations* = Call_DescribeEffectiveInstanceAssociations_598480(
    name: "describeEffectiveInstanceAssociations", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeEffectiveInstanceAssociations",
    validator: validate_DescribeEffectiveInstanceAssociations_598481, base: "/",
    url: url_DescribeEffectiveInstanceAssociations_598482,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEffectivePatchesForPatchBaseline_598495 = ref object of OpenApiRestCall_597389
proc url_DescribeEffectivePatchesForPatchBaseline_598497(protocol: Scheme;
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

proc validate_DescribeEffectivePatchesForPatchBaseline_598496(path: JsonNode;
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
  var valid_598498 = header.getOrDefault("X-Amz-Target")
  valid_598498 = validateParameter(valid_598498, JString, required = true, default = newJString(
      "AmazonSSM.DescribeEffectivePatchesForPatchBaseline"))
  if valid_598498 != nil:
    section.add "X-Amz-Target", valid_598498
  var valid_598499 = header.getOrDefault("X-Amz-Signature")
  valid_598499 = validateParameter(valid_598499, JString, required = false,
                                 default = nil)
  if valid_598499 != nil:
    section.add "X-Amz-Signature", valid_598499
  var valid_598500 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598500 = validateParameter(valid_598500, JString, required = false,
                                 default = nil)
  if valid_598500 != nil:
    section.add "X-Amz-Content-Sha256", valid_598500
  var valid_598501 = header.getOrDefault("X-Amz-Date")
  valid_598501 = validateParameter(valid_598501, JString, required = false,
                                 default = nil)
  if valid_598501 != nil:
    section.add "X-Amz-Date", valid_598501
  var valid_598502 = header.getOrDefault("X-Amz-Credential")
  valid_598502 = validateParameter(valid_598502, JString, required = false,
                                 default = nil)
  if valid_598502 != nil:
    section.add "X-Amz-Credential", valid_598502
  var valid_598503 = header.getOrDefault("X-Amz-Security-Token")
  valid_598503 = validateParameter(valid_598503, JString, required = false,
                                 default = nil)
  if valid_598503 != nil:
    section.add "X-Amz-Security-Token", valid_598503
  var valid_598504 = header.getOrDefault("X-Amz-Algorithm")
  valid_598504 = validateParameter(valid_598504, JString, required = false,
                                 default = nil)
  if valid_598504 != nil:
    section.add "X-Amz-Algorithm", valid_598504
  var valid_598505 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598505 = validateParameter(valid_598505, JString, required = false,
                                 default = nil)
  if valid_598505 != nil:
    section.add "X-Amz-SignedHeaders", valid_598505
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598507: Call_DescribeEffectivePatchesForPatchBaseline_598495;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the current effective patches (the patch and the approval state) for the specified patch baseline. Note that this API applies only to Windows patch baselines.
  ## 
  let valid = call_598507.validator(path, query, header, formData, body)
  let scheme = call_598507.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598507.url(scheme.get, call_598507.host, call_598507.base,
                         call_598507.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598507, url, valid)

proc call*(call_598508: Call_DescribeEffectivePatchesForPatchBaseline_598495;
          body: JsonNode): Recallable =
  ## describeEffectivePatchesForPatchBaseline
  ## Retrieves the current effective patches (the patch and the approval state) for the specified patch baseline. Note that this API applies only to Windows patch baselines.
  ##   body: JObject (required)
  var body_598509 = newJObject()
  if body != nil:
    body_598509 = body
  result = call_598508.call(nil, nil, nil, nil, body_598509)

var describeEffectivePatchesForPatchBaseline* = Call_DescribeEffectivePatchesForPatchBaseline_598495(
    name: "describeEffectivePatchesForPatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeEffectivePatchesForPatchBaseline",
    validator: validate_DescribeEffectivePatchesForPatchBaseline_598496,
    base: "/", url: url_DescribeEffectivePatchesForPatchBaseline_598497,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInstanceAssociationsStatus_598510 = ref object of OpenApiRestCall_597389
proc url_DescribeInstanceAssociationsStatus_598512(protocol: Scheme; host: string;
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

proc validate_DescribeInstanceAssociationsStatus_598511(path: JsonNode;
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
  var valid_598513 = header.getOrDefault("X-Amz-Target")
  valid_598513 = validateParameter(valid_598513, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInstanceAssociationsStatus"))
  if valid_598513 != nil:
    section.add "X-Amz-Target", valid_598513
  var valid_598514 = header.getOrDefault("X-Amz-Signature")
  valid_598514 = validateParameter(valid_598514, JString, required = false,
                                 default = nil)
  if valid_598514 != nil:
    section.add "X-Amz-Signature", valid_598514
  var valid_598515 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598515 = validateParameter(valid_598515, JString, required = false,
                                 default = nil)
  if valid_598515 != nil:
    section.add "X-Amz-Content-Sha256", valid_598515
  var valid_598516 = header.getOrDefault("X-Amz-Date")
  valid_598516 = validateParameter(valid_598516, JString, required = false,
                                 default = nil)
  if valid_598516 != nil:
    section.add "X-Amz-Date", valid_598516
  var valid_598517 = header.getOrDefault("X-Amz-Credential")
  valid_598517 = validateParameter(valid_598517, JString, required = false,
                                 default = nil)
  if valid_598517 != nil:
    section.add "X-Amz-Credential", valid_598517
  var valid_598518 = header.getOrDefault("X-Amz-Security-Token")
  valid_598518 = validateParameter(valid_598518, JString, required = false,
                                 default = nil)
  if valid_598518 != nil:
    section.add "X-Amz-Security-Token", valid_598518
  var valid_598519 = header.getOrDefault("X-Amz-Algorithm")
  valid_598519 = validateParameter(valid_598519, JString, required = false,
                                 default = nil)
  if valid_598519 != nil:
    section.add "X-Amz-Algorithm", valid_598519
  var valid_598520 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598520 = validateParameter(valid_598520, JString, required = false,
                                 default = nil)
  if valid_598520 != nil:
    section.add "X-Amz-SignedHeaders", valid_598520
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598522: Call_DescribeInstanceAssociationsStatus_598510;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## The status of the associations for the instance(s).
  ## 
  let valid = call_598522.validator(path, query, header, formData, body)
  let scheme = call_598522.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598522.url(scheme.get, call_598522.host, call_598522.base,
                         call_598522.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598522, url, valid)

proc call*(call_598523: Call_DescribeInstanceAssociationsStatus_598510;
          body: JsonNode): Recallable =
  ## describeInstanceAssociationsStatus
  ## The status of the associations for the instance(s).
  ##   body: JObject (required)
  var body_598524 = newJObject()
  if body != nil:
    body_598524 = body
  result = call_598523.call(nil, nil, nil, nil, body_598524)

var describeInstanceAssociationsStatus* = Call_DescribeInstanceAssociationsStatus_598510(
    name: "describeInstanceAssociationsStatus", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInstanceAssociationsStatus",
    validator: validate_DescribeInstanceAssociationsStatus_598511, base: "/",
    url: url_DescribeInstanceAssociationsStatus_598512,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInstanceInformation_598525 = ref object of OpenApiRestCall_597389
proc url_DescribeInstanceInformation_598527(protocol: Scheme; host: string;
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

proc validate_DescribeInstanceInformation_598526(path: JsonNode; query: JsonNode;
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
  var valid_598528 = query.getOrDefault("MaxResults")
  valid_598528 = validateParameter(valid_598528, JString, required = false,
                                 default = nil)
  if valid_598528 != nil:
    section.add "MaxResults", valid_598528
  var valid_598529 = query.getOrDefault("NextToken")
  valid_598529 = validateParameter(valid_598529, JString, required = false,
                                 default = nil)
  if valid_598529 != nil:
    section.add "NextToken", valid_598529
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_598530 = header.getOrDefault("X-Amz-Target")
  valid_598530 = validateParameter(valid_598530, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInstanceInformation"))
  if valid_598530 != nil:
    section.add "X-Amz-Target", valid_598530
  var valid_598531 = header.getOrDefault("X-Amz-Signature")
  valid_598531 = validateParameter(valid_598531, JString, required = false,
                                 default = nil)
  if valid_598531 != nil:
    section.add "X-Amz-Signature", valid_598531
  var valid_598532 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598532 = validateParameter(valid_598532, JString, required = false,
                                 default = nil)
  if valid_598532 != nil:
    section.add "X-Amz-Content-Sha256", valid_598532
  var valid_598533 = header.getOrDefault("X-Amz-Date")
  valid_598533 = validateParameter(valid_598533, JString, required = false,
                                 default = nil)
  if valid_598533 != nil:
    section.add "X-Amz-Date", valid_598533
  var valid_598534 = header.getOrDefault("X-Amz-Credential")
  valid_598534 = validateParameter(valid_598534, JString, required = false,
                                 default = nil)
  if valid_598534 != nil:
    section.add "X-Amz-Credential", valid_598534
  var valid_598535 = header.getOrDefault("X-Amz-Security-Token")
  valid_598535 = validateParameter(valid_598535, JString, required = false,
                                 default = nil)
  if valid_598535 != nil:
    section.add "X-Amz-Security-Token", valid_598535
  var valid_598536 = header.getOrDefault("X-Amz-Algorithm")
  valid_598536 = validateParameter(valid_598536, JString, required = false,
                                 default = nil)
  if valid_598536 != nil:
    section.add "X-Amz-Algorithm", valid_598536
  var valid_598537 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598537 = validateParameter(valid_598537, JString, required = false,
                                 default = nil)
  if valid_598537 != nil:
    section.add "X-Amz-SignedHeaders", valid_598537
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598539: Call_DescribeInstanceInformation_598525; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes one or more of your instances. You can use this to get information about instances like the operating system platform, the SSM Agent version (Linux), status etc. If you specify one or more instance IDs, it returns information for those instances. If you do not specify instance IDs, it returns information for all your instances. If you specify an instance ID that is not valid or an instance that you do not own, you receive an error. </p> <note> <p>The IamRole field for this API action is the Amazon Identity and Access Management (IAM) role assigned to on-premises instances. This call does not return the IAM role for Amazon EC2 instances.</p> </note>
  ## 
  let valid = call_598539.validator(path, query, header, formData, body)
  let scheme = call_598539.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598539.url(scheme.get, call_598539.host, call_598539.base,
                         call_598539.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598539, url, valid)

proc call*(call_598540: Call_DescribeInstanceInformation_598525; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## describeInstanceInformation
  ## <p>Describes one or more of your instances. You can use this to get information about instances like the operating system platform, the SSM Agent version (Linux), status etc. If you specify one or more instance IDs, it returns information for those instances. If you do not specify instance IDs, it returns information for all your instances. If you specify an instance ID that is not valid or an instance that you do not own, you receive an error. </p> <note> <p>The IamRole field for this API action is the Amazon Identity and Access Management (IAM) role assigned to on-premises instances. This call does not return the IAM role for Amazon EC2 instances.</p> </note>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_598541 = newJObject()
  var body_598542 = newJObject()
  add(query_598541, "MaxResults", newJString(MaxResults))
  add(query_598541, "NextToken", newJString(NextToken))
  if body != nil:
    body_598542 = body
  result = call_598540.call(nil, query_598541, nil, nil, body_598542)

var describeInstanceInformation* = Call_DescribeInstanceInformation_598525(
    name: "describeInstanceInformation", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInstanceInformation",
    validator: validate_DescribeInstanceInformation_598526, base: "/",
    url: url_DescribeInstanceInformation_598527,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInstancePatchStates_598543 = ref object of OpenApiRestCall_597389
proc url_DescribeInstancePatchStates_598545(protocol: Scheme; host: string;
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

proc validate_DescribeInstancePatchStates_598544(path: JsonNode; query: JsonNode;
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
  var valid_598546 = header.getOrDefault("X-Amz-Target")
  valid_598546 = validateParameter(valid_598546, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInstancePatchStates"))
  if valid_598546 != nil:
    section.add "X-Amz-Target", valid_598546
  var valid_598547 = header.getOrDefault("X-Amz-Signature")
  valid_598547 = validateParameter(valid_598547, JString, required = false,
                                 default = nil)
  if valid_598547 != nil:
    section.add "X-Amz-Signature", valid_598547
  var valid_598548 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598548 = validateParameter(valid_598548, JString, required = false,
                                 default = nil)
  if valid_598548 != nil:
    section.add "X-Amz-Content-Sha256", valid_598548
  var valid_598549 = header.getOrDefault("X-Amz-Date")
  valid_598549 = validateParameter(valid_598549, JString, required = false,
                                 default = nil)
  if valid_598549 != nil:
    section.add "X-Amz-Date", valid_598549
  var valid_598550 = header.getOrDefault("X-Amz-Credential")
  valid_598550 = validateParameter(valid_598550, JString, required = false,
                                 default = nil)
  if valid_598550 != nil:
    section.add "X-Amz-Credential", valid_598550
  var valid_598551 = header.getOrDefault("X-Amz-Security-Token")
  valid_598551 = validateParameter(valid_598551, JString, required = false,
                                 default = nil)
  if valid_598551 != nil:
    section.add "X-Amz-Security-Token", valid_598551
  var valid_598552 = header.getOrDefault("X-Amz-Algorithm")
  valid_598552 = validateParameter(valid_598552, JString, required = false,
                                 default = nil)
  if valid_598552 != nil:
    section.add "X-Amz-Algorithm", valid_598552
  var valid_598553 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598553 = validateParameter(valid_598553, JString, required = false,
                                 default = nil)
  if valid_598553 != nil:
    section.add "X-Amz-SignedHeaders", valid_598553
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598555: Call_DescribeInstancePatchStates_598543; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the high-level patch state of one or more instances.
  ## 
  let valid = call_598555.validator(path, query, header, formData, body)
  let scheme = call_598555.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598555.url(scheme.get, call_598555.host, call_598555.base,
                         call_598555.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598555, url, valid)

proc call*(call_598556: Call_DescribeInstancePatchStates_598543; body: JsonNode): Recallable =
  ## describeInstancePatchStates
  ## Retrieves the high-level patch state of one or more instances.
  ##   body: JObject (required)
  var body_598557 = newJObject()
  if body != nil:
    body_598557 = body
  result = call_598556.call(nil, nil, nil, nil, body_598557)

var describeInstancePatchStates* = Call_DescribeInstancePatchStates_598543(
    name: "describeInstancePatchStates", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInstancePatchStates",
    validator: validate_DescribeInstancePatchStates_598544, base: "/",
    url: url_DescribeInstancePatchStates_598545,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInstancePatchStatesForPatchGroup_598558 = ref object of OpenApiRestCall_597389
proc url_DescribeInstancePatchStatesForPatchGroup_598560(protocol: Scheme;
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

proc validate_DescribeInstancePatchStatesForPatchGroup_598559(path: JsonNode;
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
  var valid_598561 = header.getOrDefault("X-Amz-Target")
  valid_598561 = validateParameter(valid_598561, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInstancePatchStatesForPatchGroup"))
  if valid_598561 != nil:
    section.add "X-Amz-Target", valid_598561
  var valid_598562 = header.getOrDefault("X-Amz-Signature")
  valid_598562 = validateParameter(valid_598562, JString, required = false,
                                 default = nil)
  if valid_598562 != nil:
    section.add "X-Amz-Signature", valid_598562
  var valid_598563 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598563 = validateParameter(valid_598563, JString, required = false,
                                 default = nil)
  if valid_598563 != nil:
    section.add "X-Amz-Content-Sha256", valid_598563
  var valid_598564 = header.getOrDefault("X-Amz-Date")
  valid_598564 = validateParameter(valid_598564, JString, required = false,
                                 default = nil)
  if valid_598564 != nil:
    section.add "X-Amz-Date", valid_598564
  var valid_598565 = header.getOrDefault("X-Amz-Credential")
  valid_598565 = validateParameter(valid_598565, JString, required = false,
                                 default = nil)
  if valid_598565 != nil:
    section.add "X-Amz-Credential", valid_598565
  var valid_598566 = header.getOrDefault("X-Amz-Security-Token")
  valid_598566 = validateParameter(valid_598566, JString, required = false,
                                 default = nil)
  if valid_598566 != nil:
    section.add "X-Amz-Security-Token", valid_598566
  var valid_598567 = header.getOrDefault("X-Amz-Algorithm")
  valid_598567 = validateParameter(valid_598567, JString, required = false,
                                 default = nil)
  if valid_598567 != nil:
    section.add "X-Amz-Algorithm", valid_598567
  var valid_598568 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598568 = validateParameter(valid_598568, JString, required = false,
                                 default = nil)
  if valid_598568 != nil:
    section.add "X-Amz-SignedHeaders", valid_598568
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598570: Call_DescribeInstancePatchStatesForPatchGroup_598558;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the high-level patch state for the instances in the specified patch group.
  ## 
  let valid = call_598570.validator(path, query, header, formData, body)
  let scheme = call_598570.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598570.url(scheme.get, call_598570.host, call_598570.base,
                         call_598570.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598570, url, valid)

proc call*(call_598571: Call_DescribeInstancePatchStatesForPatchGroup_598558;
          body: JsonNode): Recallable =
  ## describeInstancePatchStatesForPatchGroup
  ## Retrieves the high-level patch state for the instances in the specified patch group.
  ##   body: JObject (required)
  var body_598572 = newJObject()
  if body != nil:
    body_598572 = body
  result = call_598571.call(nil, nil, nil, nil, body_598572)

var describeInstancePatchStatesForPatchGroup* = Call_DescribeInstancePatchStatesForPatchGroup_598558(
    name: "describeInstancePatchStatesForPatchGroup", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInstancePatchStatesForPatchGroup",
    validator: validate_DescribeInstancePatchStatesForPatchGroup_598559,
    base: "/", url: url_DescribeInstancePatchStatesForPatchGroup_598560,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInstancePatches_598573 = ref object of OpenApiRestCall_597389
proc url_DescribeInstancePatches_598575(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeInstancePatches_598574(path: JsonNode; query: JsonNode;
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
  var valid_598576 = header.getOrDefault("X-Amz-Target")
  valid_598576 = validateParameter(valid_598576, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInstancePatches"))
  if valid_598576 != nil:
    section.add "X-Amz-Target", valid_598576
  var valid_598577 = header.getOrDefault("X-Amz-Signature")
  valid_598577 = validateParameter(valid_598577, JString, required = false,
                                 default = nil)
  if valid_598577 != nil:
    section.add "X-Amz-Signature", valid_598577
  var valid_598578 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598578 = validateParameter(valid_598578, JString, required = false,
                                 default = nil)
  if valid_598578 != nil:
    section.add "X-Amz-Content-Sha256", valid_598578
  var valid_598579 = header.getOrDefault("X-Amz-Date")
  valid_598579 = validateParameter(valid_598579, JString, required = false,
                                 default = nil)
  if valid_598579 != nil:
    section.add "X-Amz-Date", valid_598579
  var valid_598580 = header.getOrDefault("X-Amz-Credential")
  valid_598580 = validateParameter(valid_598580, JString, required = false,
                                 default = nil)
  if valid_598580 != nil:
    section.add "X-Amz-Credential", valid_598580
  var valid_598581 = header.getOrDefault("X-Amz-Security-Token")
  valid_598581 = validateParameter(valid_598581, JString, required = false,
                                 default = nil)
  if valid_598581 != nil:
    section.add "X-Amz-Security-Token", valid_598581
  var valid_598582 = header.getOrDefault("X-Amz-Algorithm")
  valid_598582 = validateParameter(valid_598582, JString, required = false,
                                 default = nil)
  if valid_598582 != nil:
    section.add "X-Amz-Algorithm", valid_598582
  var valid_598583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598583 = validateParameter(valid_598583, JString, required = false,
                                 default = nil)
  if valid_598583 != nil:
    section.add "X-Amz-SignedHeaders", valid_598583
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598585: Call_DescribeInstancePatches_598573; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the patches on the specified instance and their state relative to the patch baseline being used for the instance.
  ## 
  let valid = call_598585.validator(path, query, header, formData, body)
  let scheme = call_598585.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598585.url(scheme.get, call_598585.host, call_598585.base,
                         call_598585.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598585, url, valid)

proc call*(call_598586: Call_DescribeInstancePatches_598573; body: JsonNode): Recallable =
  ## describeInstancePatches
  ## Retrieves information about the patches on the specified instance and their state relative to the patch baseline being used for the instance.
  ##   body: JObject (required)
  var body_598587 = newJObject()
  if body != nil:
    body_598587 = body
  result = call_598586.call(nil, nil, nil, nil, body_598587)

var describeInstancePatches* = Call_DescribeInstancePatches_598573(
    name: "describeInstancePatches", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInstancePatches",
    validator: validate_DescribeInstancePatches_598574, base: "/",
    url: url_DescribeInstancePatches_598575, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInventoryDeletions_598588 = ref object of OpenApiRestCall_597389
proc url_DescribeInventoryDeletions_598590(protocol: Scheme; host: string;
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

proc validate_DescribeInventoryDeletions_598589(path: JsonNode; query: JsonNode;
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
  var valid_598591 = header.getOrDefault("X-Amz-Target")
  valid_598591 = validateParameter(valid_598591, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInventoryDeletions"))
  if valid_598591 != nil:
    section.add "X-Amz-Target", valid_598591
  var valid_598592 = header.getOrDefault("X-Amz-Signature")
  valid_598592 = validateParameter(valid_598592, JString, required = false,
                                 default = nil)
  if valid_598592 != nil:
    section.add "X-Amz-Signature", valid_598592
  var valid_598593 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598593 = validateParameter(valid_598593, JString, required = false,
                                 default = nil)
  if valid_598593 != nil:
    section.add "X-Amz-Content-Sha256", valid_598593
  var valid_598594 = header.getOrDefault("X-Amz-Date")
  valid_598594 = validateParameter(valid_598594, JString, required = false,
                                 default = nil)
  if valid_598594 != nil:
    section.add "X-Amz-Date", valid_598594
  var valid_598595 = header.getOrDefault("X-Amz-Credential")
  valid_598595 = validateParameter(valid_598595, JString, required = false,
                                 default = nil)
  if valid_598595 != nil:
    section.add "X-Amz-Credential", valid_598595
  var valid_598596 = header.getOrDefault("X-Amz-Security-Token")
  valid_598596 = validateParameter(valid_598596, JString, required = false,
                                 default = nil)
  if valid_598596 != nil:
    section.add "X-Amz-Security-Token", valid_598596
  var valid_598597 = header.getOrDefault("X-Amz-Algorithm")
  valid_598597 = validateParameter(valid_598597, JString, required = false,
                                 default = nil)
  if valid_598597 != nil:
    section.add "X-Amz-Algorithm", valid_598597
  var valid_598598 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598598 = validateParameter(valid_598598, JString, required = false,
                                 default = nil)
  if valid_598598 != nil:
    section.add "X-Amz-SignedHeaders", valid_598598
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598600: Call_DescribeInventoryDeletions_598588; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a specific delete inventory operation.
  ## 
  let valid = call_598600.validator(path, query, header, formData, body)
  let scheme = call_598600.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598600.url(scheme.get, call_598600.host, call_598600.base,
                         call_598600.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598600, url, valid)

proc call*(call_598601: Call_DescribeInventoryDeletions_598588; body: JsonNode): Recallable =
  ## describeInventoryDeletions
  ## Describes a specific delete inventory operation.
  ##   body: JObject (required)
  var body_598602 = newJObject()
  if body != nil:
    body_598602 = body
  result = call_598601.call(nil, nil, nil, nil, body_598602)

var describeInventoryDeletions* = Call_DescribeInventoryDeletions_598588(
    name: "describeInventoryDeletions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInventoryDeletions",
    validator: validate_DescribeInventoryDeletions_598589, base: "/",
    url: url_DescribeInventoryDeletions_598590,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowExecutionTaskInvocations_598603 = ref object of OpenApiRestCall_597389
proc url_DescribeMaintenanceWindowExecutionTaskInvocations_598605(
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

proc validate_DescribeMaintenanceWindowExecutionTaskInvocations_598604(
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
  var valid_598606 = header.getOrDefault("X-Amz-Target")
  valid_598606 = validateParameter(valid_598606, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowExecutionTaskInvocations"))
  if valid_598606 != nil:
    section.add "X-Amz-Target", valid_598606
  var valid_598607 = header.getOrDefault("X-Amz-Signature")
  valid_598607 = validateParameter(valid_598607, JString, required = false,
                                 default = nil)
  if valid_598607 != nil:
    section.add "X-Amz-Signature", valid_598607
  var valid_598608 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598608 = validateParameter(valid_598608, JString, required = false,
                                 default = nil)
  if valid_598608 != nil:
    section.add "X-Amz-Content-Sha256", valid_598608
  var valid_598609 = header.getOrDefault("X-Amz-Date")
  valid_598609 = validateParameter(valid_598609, JString, required = false,
                                 default = nil)
  if valid_598609 != nil:
    section.add "X-Amz-Date", valid_598609
  var valid_598610 = header.getOrDefault("X-Amz-Credential")
  valid_598610 = validateParameter(valid_598610, JString, required = false,
                                 default = nil)
  if valid_598610 != nil:
    section.add "X-Amz-Credential", valid_598610
  var valid_598611 = header.getOrDefault("X-Amz-Security-Token")
  valid_598611 = validateParameter(valid_598611, JString, required = false,
                                 default = nil)
  if valid_598611 != nil:
    section.add "X-Amz-Security-Token", valid_598611
  var valid_598612 = header.getOrDefault("X-Amz-Algorithm")
  valid_598612 = validateParameter(valid_598612, JString, required = false,
                                 default = nil)
  if valid_598612 != nil:
    section.add "X-Amz-Algorithm", valid_598612
  var valid_598613 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598613 = validateParameter(valid_598613, JString, required = false,
                                 default = nil)
  if valid_598613 != nil:
    section.add "X-Amz-SignedHeaders", valid_598613
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598615: Call_DescribeMaintenanceWindowExecutionTaskInvocations_598603;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the individual task executions (one per target) for a particular task run as part of a maintenance window execution.
  ## 
  let valid = call_598615.validator(path, query, header, formData, body)
  let scheme = call_598615.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598615.url(scheme.get, call_598615.host, call_598615.base,
                         call_598615.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598615, url, valid)

proc call*(call_598616: Call_DescribeMaintenanceWindowExecutionTaskInvocations_598603;
          body: JsonNode): Recallable =
  ## describeMaintenanceWindowExecutionTaskInvocations
  ## Retrieves the individual task executions (one per target) for a particular task run as part of a maintenance window execution.
  ##   body: JObject (required)
  var body_598617 = newJObject()
  if body != nil:
    body_598617 = body
  result = call_598616.call(nil, nil, nil, nil, body_598617)

var describeMaintenanceWindowExecutionTaskInvocations* = Call_DescribeMaintenanceWindowExecutionTaskInvocations_598603(
    name: "describeMaintenanceWindowExecutionTaskInvocations",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com", route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowExecutionTaskInvocations",
    validator: validate_DescribeMaintenanceWindowExecutionTaskInvocations_598604,
    base: "/", url: url_DescribeMaintenanceWindowExecutionTaskInvocations_598605,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowExecutionTasks_598618 = ref object of OpenApiRestCall_597389
proc url_DescribeMaintenanceWindowExecutionTasks_598620(protocol: Scheme;
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

proc validate_DescribeMaintenanceWindowExecutionTasks_598619(path: JsonNode;
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
  var valid_598621 = header.getOrDefault("X-Amz-Target")
  valid_598621 = validateParameter(valid_598621, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowExecutionTasks"))
  if valid_598621 != nil:
    section.add "X-Amz-Target", valid_598621
  var valid_598622 = header.getOrDefault("X-Amz-Signature")
  valid_598622 = validateParameter(valid_598622, JString, required = false,
                                 default = nil)
  if valid_598622 != nil:
    section.add "X-Amz-Signature", valid_598622
  var valid_598623 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598623 = validateParameter(valid_598623, JString, required = false,
                                 default = nil)
  if valid_598623 != nil:
    section.add "X-Amz-Content-Sha256", valid_598623
  var valid_598624 = header.getOrDefault("X-Amz-Date")
  valid_598624 = validateParameter(valid_598624, JString, required = false,
                                 default = nil)
  if valid_598624 != nil:
    section.add "X-Amz-Date", valid_598624
  var valid_598625 = header.getOrDefault("X-Amz-Credential")
  valid_598625 = validateParameter(valid_598625, JString, required = false,
                                 default = nil)
  if valid_598625 != nil:
    section.add "X-Amz-Credential", valid_598625
  var valid_598626 = header.getOrDefault("X-Amz-Security-Token")
  valid_598626 = validateParameter(valid_598626, JString, required = false,
                                 default = nil)
  if valid_598626 != nil:
    section.add "X-Amz-Security-Token", valid_598626
  var valid_598627 = header.getOrDefault("X-Amz-Algorithm")
  valid_598627 = validateParameter(valid_598627, JString, required = false,
                                 default = nil)
  if valid_598627 != nil:
    section.add "X-Amz-Algorithm", valid_598627
  var valid_598628 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598628 = validateParameter(valid_598628, JString, required = false,
                                 default = nil)
  if valid_598628 != nil:
    section.add "X-Amz-SignedHeaders", valid_598628
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598630: Call_DescribeMaintenanceWindowExecutionTasks_598618;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## For a given maintenance window execution, lists the tasks that were run.
  ## 
  let valid = call_598630.validator(path, query, header, formData, body)
  let scheme = call_598630.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598630.url(scheme.get, call_598630.host, call_598630.base,
                         call_598630.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598630, url, valid)

proc call*(call_598631: Call_DescribeMaintenanceWindowExecutionTasks_598618;
          body: JsonNode): Recallable =
  ## describeMaintenanceWindowExecutionTasks
  ## For a given maintenance window execution, lists the tasks that were run.
  ##   body: JObject (required)
  var body_598632 = newJObject()
  if body != nil:
    body_598632 = body
  result = call_598631.call(nil, nil, nil, nil, body_598632)

var describeMaintenanceWindowExecutionTasks* = Call_DescribeMaintenanceWindowExecutionTasks_598618(
    name: "describeMaintenanceWindowExecutionTasks", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowExecutionTasks",
    validator: validate_DescribeMaintenanceWindowExecutionTasks_598619, base: "/",
    url: url_DescribeMaintenanceWindowExecutionTasks_598620,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowExecutions_598633 = ref object of OpenApiRestCall_597389
proc url_DescribeMaintenanceWindowExecutions_598635(protocol: Scheme; host: string;
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

proc validate_DescribeMaintenanceWindowExecutions_598634(path: JsonNode;
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
  var valid_598636 = header.getOrDefault("X-Amz-Target")
  valid_598636 = validateParameter(valid_598636, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowExecutions"))
  if valid_598636 != nil:
    section.add "X-Amz-Target", valid_598636
  var valid_598637 = header.getOrDefault("X-Amz-Signature")
  valid_598637 = validateParameter(valid_598637, JString, required = false,
                                 default = nil)
  if valid_598637 != nil:
    section.add "X-Amz-Signature", valid_598637
  var valid_598638 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598638 = validateParameter(valid_598638, JString, required = false,
                                 default = nil)
  if valid_598638 != nil:
    section.add "X-Amz-Content-Sha256", valid_598638
  var valid_598639 = header.getOrDefault("X-Amz-Date")
  valid_598639 = validateParameter(valid_598639, JString, required = false,
                                 default = nil)
  if valid_598639 != nil:
    section.add "X-Amz-Date", valid_598639
  var valid_598640 = header.getOrDefault("X-Amz-Credential")
  valid_598640 = validateParameter(valid_598640, JString, required = false,
                                 default = nil)
  if valid_598640 != nil:
    section.add "X-Amz-Credential", valid_598640
  var valid_598641 = header.getOrDefault("X-Amz-Security-Token")
  valid_598641 = validateParameter(valid_598641, JString, required = false,
                                 default = nil)
  if valid_598641 != nil:
    section.add "X-Amz-Security-Token", valid_598641
  var valid_598642 = header.getOrDefault("X-Amz-Algorithm")
  valid_598642 = validateParameter(valid_598642, JString, required = false,
                                 default = nil)
  if valid_598642 != nil:
    section.add "X-Amz-Algorithm", valid_598642
  var valid_598643 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598643 = validateParameter(valid_598643, JString, required = false,
                                 default = nil)
  if valid_598643 != nil:
    section.add "X-Amz-SignedHeaders", valid_598643
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598645: Call_DescribeMaintenanceWindowExecutions_598633;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the executions of a maintenance window. This includes information about when the maintenance window was scheduled to be active, and information about tasks registered and run with the maintenance window.
  ## 
  let valid = call_598645.validator(path, query, header, formData, body)
  let scheme = call_598645.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598645.url(scheme.get, call_598645.host, call_598645.base,
                         call_598645.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598645, url, valid)

proc call*(call_598646: Call_DescribeMaintenanceWindowExecutions_598633;
          body: JsonNode): Recallable =
  ## describeMaintenanceWindowExecutions
  ## Lists the executions of a maintenance window. This includes information about when the maintenance window was scheduled to be active, and information about tasks registered and run with the maintenance window.
  ##   body: JObject (required)
  var body_598647 = newJObject()
  if body != nil:
    body_598647 = body
  result = call_598646.call(nil, nil, nil, nil, body_598647)

var describeMaintenanceWindowExecutions* = Call_DescribeMaintenanceWindowExecutions_598633(
    name: "describeMaintenanceWindowExecutions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowExecutions",
    validator: validate_DescribeMaintenanceWindowExecutions_598634, base: "/",
    url: url_DescribeMaintenanceWindowExecutions_598635,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowSchedule_598648 = ref object of OpenApiRestCall_597389
proc url_DescribeMaintenanceWindowSchedule_598650(protocol: Scheme; host: string;
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

proc validate_DescribeMaintenanceWindowSchedule_598649(path: JsonNode;
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
  var valid_598651 = header.getOrDefault("X-Amz-Target")
  valid_598651 = validateParameter(valid_598651, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowSchedule"))
  if valid_598651 != nil:
    section.add "X-Amz-Target", valid_598651
  var valid_598652 = header.getOrDefault("X-Amz-Signature")
  valid_598652 = validateParameter(valid_598652, JString, required = false,
                                 default = nil)
  if valid_598652 != nil:
    section.add "X-Amz-Signature", valid_598652
  var valid_598653 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598653 = validateParameter(valid_598653, JString, required = false,
                                 default = nil)
  if valid_598653 != nil:
    section.add "X-Amz-Content-Sha256", valid_598653
  var valid_598654 = header.getOrDefault("X-Amz-Date")
  valid_598654 = validateParameter(valid_598654, JString, required = false,
                                 default = nil)
  if valid_598654 != nil:
    section.add "X-Amz-Date", valid_598654
  var valid_598655 = header.getOrDefault("X-Amz-Credential")
  valid_598655 = validateParameter(valid_598655, JString, required = false,
                                 default = nil)
  if valid_598655 != nil:
    section.add "X-Amz-Credential", valid_598655
  var valid_598656 = header.getOrDefault("X-Amz-Security-Token")
  valid_598656 = validateParameter(valid_598656, JString, required = false,
                                 default = nil)
  if valid_598656 != nil:
    section.add "X-Amz-Security-Token", valid_598656
  var valid_598657 = header.getOrDefault("X-Amz-Algorithm")
  valid_598657 = validateParameter(valid_598657, JString, required = false,
                                 default = nil)
  if valid_598657 != nil:
    section.add "X-Amz-Algorithm", valid_598657
  var valid_598658 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598658 = validateParameter(valid_598658, JString, required = false,
                                 default = nil)
  if valid_598658 != nil:
    section.add "X-Amz-SignedHeaders", valid_598658
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598660: Call_DescribeMaintenanceWindowSchedule_598648;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves information about upcoming executions of a maintenance window.
  ## 
  let valid = call_598660.validator(path, query, header, formData, body)
  let scheme = call_598660.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598660.url(scheme.get, call_598660.host, call_598660.base,
                         call_598660.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598660, url, valid)

proc call*(call_598661: Call_DescribeMaintenanceWindowSchedule_598648;
          body: JsonNode): Recallable =
  ## describeMaintenanceWindowSchedule
  ## Retrieves information about upcoming executions of a maintenance window.
  ##   body: JObject (required)
  var body_598662 = newJObject()
  if body != nil:
    body_598662 = body
  result = call_598661.call(nil, nil, nil, nil, body_598662)

var describeMaintenanceWindowSchedule* = Call_DescribeMaintenanceWindowSchedule_598648(
    name: "describeMaintenanceWindowSchedule", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowSchedule",
    validator: validate_DescribeMaintenanceWindowSchedule_598649, base: "/",
    url: url_DescribeMaintenanceWindowSchedule_598650,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowTargets_598663 = ref object of OpenApiRestCall_597389
proc url_DescribeMaintenanceWindowTargets_598665(protocol: Scheme; host: string;
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

proc validate_DescribeMaintenanceWindowTargets_598664(path: JsonNode;
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
  var valid_598666 = header.getOrDefault("X-Amz-Target")
  valid_598666 = validateParameter(valid_598666, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowTargets"))
  if valid_598666 != nil:
    section.add "X-Amz-Target", valid_598666
  var valid_598667 = header.getOrDefault("X-Amz-Signature")
  valid_598667 = validateParameter(valid_598667, JString, required = false,
                                 default = nil)
  if valid_598667 != nil:
    section.add "X-Amz-Signature", valid_598667
  var valid_598668 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598668 = validateParameter(valid_598668, JString, required = false,
                                 default = nil)
  if valid_598668 != nil:
    section.add "X-Amz-Content-Sha256", valid_598668
  var valid_598669 = header.getOrDefault("X-Amz-Date")
  valid_598669 = validateParameter(valid_598669, JString, required = false,
                                 default = nil)
  if valid_598669 != nil:
    section.add "X-Amz-Date", valid_598669
  var valid_598670 = header.getOrDefault("X-Amz-Credential")
  valid_598670 = validateParameter(valid_598670, JString, required = false,
                                 default = nil)
  if valid_598670 != nil:
    section.add "X-Amz-Credential", valid_598670
  var valid_598671 = header.getOrDefault("X-Amz-Security-Token")
  valid_598671 = validateParameter(valid_598671, JString, required = false,
                                 default = nil)
  if valid_598671 != nil:
    section.add "X-Amz-Security-Token", valid_598671
  var valid_598672 = header.getOrDefault("X-Amz-Algorithm")
  valid_598672 = validateParameter(valid_598672, JString, required = false,
                                 default = nil)
  if valid_598672 != nil:
    section.add "X-Amz-Algorithm", valid_598672
  var valid_598673 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598673 = validateParameter(valid_598673, JString, required = false,
                                 default = nil)
  if valid_598673 != nil:
    section.add "X-Amz-SignedHeaders", valid_598673
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598675: Call_DescribeMaintenanceWindowTargets_598663;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the targets registered with the maintenance window.
  ## 
  let valid = call_598675.validator(path, query, header, formData, body)
  let scheme = call_598675.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598675.url(scheme.get, call_598675.host, call_598675.base,
                         call_598675.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598675, url, valid)

proc call*(call_598676: Call_DescribeMaintenanceWindowTargets_598663;
          body: JsonNode): Recallable =
  ## describeMaintenanceWindowTargets
  ## Lists the targets registered with the maintenance window.
  ##   body: JObject (required)
  var body_598677 = newJObject()
  if body != nil:
    body_598677 = body
  result = call_598676.call(nil, nil, nil, nil, body_598677)

var describeMaintenanceWindowTargets* = Call_DescribeMaintenanceWindowTargets_598663(
    name: "describeMaintenanceWindowTargets", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowTargets",
    validator: validate_DescribeMaintenanceWindowTargets_598664, base: "/",
    url: url_DescribeMaintenanceWindowTargets_598665,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowTasks_598678 = ref object of OpenApiRestCall_597389
proc url_DescribeMaintenanceWindowTasks_598680(protocol: Scheme; host: string;
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

proc validate_DescribeMaintenanceWindowTasks_598679(path: JsonNode;
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
  var valid_598681 = header.getOrDefault("X-Amz-Target")
  valid_598681 = validateParameter(valid_598681, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowTasks"))
  if valid_598681 != nil:
    section.add "X-Amz-Target", valid_598681
  var valid_598682 = header.getOrDefault("X-Amz-Signature")
  valid_598682 = validateParameter(valid_598682, JString, required = false,
                                 default = nil)
  if valid_598682 != nil:
    section.add "X-Amz-Signature", valid_598682
  var valid_598683 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598683 = validateParameter(valid_598683, JString, required = false,
                                 default = nil)
  if valid_598683 != nil:
    section.add "X-Amz-Content-Sha256", valid_598683
  var valid_598684 = header.getOrDefault("X-Amz-Date")
  valid_598684 = validateParameter(valid_598684, JString, required = false,
                                 default = nil)
  if valid_598684 != nil:
    section.add "X-Amz-Date", valid_598684
  var valid_598685 = header.getOrDefault("X-Amz-Credential")
  valid_598685 = validateParameter(valid_598685, JString, required = false,
                                 default = nil)
  if valid_598685 != nil:
    section.add "X-Amz-Credential", valid_598685
  var valid_598686 = header.getOrDefault("X-Amz-Security-Token")
  valid_598686 = validateParameter(valid_598686, JString, required = false,
                                 default = nil)
  if valid_598686 != nil:
    section.add "X-Amz-Security-Token", valid_598686
  var valid_598687 = header.getOrDefault("X-Amz-Algorithm")
  valid_598687 = validateParameter(valid_598687, JString, required = false,
                                 default = nil)
  if valid_598687 != nil:
    section.add "X-Amz-Algorithm", valid_598687
  var valid_598688 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598688 = validateParameter(valid_598688, JString, required = false,
                                 default = nil)
  if valid_598688 != nil:
    section.add "X-Amz-SignedHeaders", valid_598688
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598690: Call_DescribeMaintenanceWindowTasks_598678; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tasks in a maintenance window.
  ## 
  let valid = call_598690.validator(path, query, header, formData, body)
  let scheme = call_598690.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598690.url(scheme.get, call_598690.host, call_598690.base,
                         call_598690.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598690, url, valid)

proc call*(call_598691: Call_DescribeMaintenanceWindowTasks_598678; body: JsonNode): Recallable =
  ## describeMaintenanceWindowTasks
  ## Lists the tasks in a maintenance window.
  ##   body: JObject (required)
  var body_598692 = newJObject()
  if body != nil:
    body_598692 = body
  result = call_598691.call(nil, nil, nil, nil, body_598692)

var describeMaintenanceWindowTasks* = Call_DescribeMaintenanceWindowTasks_598678(
    name: "describeMaintenanceWindowTasks", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowTasks",
    validator: validate_DescribeMaintenanceWindowTasks_598679, base: "/",
    url: url_DescribeMaintenanceWindowTasks_598680,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindows_598693 = ref object of OpenApiRestCall_597389
proc url_DescribeMaintenanceWindows_598695(protocol: Scheme; host: string;
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

proc validate_DescribeMaintenanceWindows_598694(path: JsonNode; query: JsonNode;
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
  var valid_598696 = header.getOrDefault("X-Amz-Target")
  valid_598696 = validateParameter(valid_598696, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindows"))
  if valid_598696 != nil:
    section.add "X-Amz-Target", valid_598696
  var valid_598697 = header.getOrDefault("X-Amz-Signature")
  valid_598697 = validateParameter(valid_598697, JString, required = false,
                                 default = nil)
  if valid_598697 != nil:
    section.add "X-Amz-Signature", valid_598697
  var valid_598698 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598698 = validateParameter(valid_598698, JString, required = false,
                                 default = nil)
  if valid_598698 != nil:
    section.add "X-Amz-Content-Sha256", valid_598698
  var valid_598699 = header.getOrDefault("X-Amz-Date")
  valid_598699 = validateParameter(valid_598699, JString, required = false,
                                 default = nil)
  if valid_598699 != nil:
    section.add "X-Amz-Date", valid_598699
  var valid_598700 = header.getOrDefault("X-Amz-Credential")
  valid_598700 = validateParameter(valid_598700, JString, required = false,
                                 default = nil)
  if valid_598700 != nil:
    section.add "X-Amz-Credential", valid_598700
  var valid_598701 = header.getOrDefault("X-Amz-Security-Token")
  valid_598701 = validateParameter(valid_598701, JString, required = false,
                                 default = nil)
  if valid_598701 != nil:
    section.add "X-Amz-Security-Token", valid_598701
  var valid_598702 = header.getOrDefault("X-Amz-Algorithm")
  valid_598702 = validateParameter(valid_598702, JString, required = false,
                                 default = nil)
  if valid_598702 != nil:
    section.add "X-Amz-Algorithm", valid_598702
  var valid_598703 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598703 = validateParameter(valid_598703, JString, required = false,
                                 default = nil)
  if valid_598703 != nil:
    section.add "X-Amz-SignedHeaders", valid_598703
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598705: Call_DescribeMaintenanceWindows_598693; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the maintenance windows in an AWS account.
  ## 
  let valid = call_598705.validator(path, query, header, formData, body)
  let scheme = call_598705.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598705.url(scheme.get, call_598705.host, call_598705.base,
                         call_598705.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598705, url, valid)

proc call*(call_598706: Call_DescribeMaintenanceWindows_598693; body: JsonNode): Recallable =
  ## describeMaintenanceWindows
  ## Retrieves the maintenance windows in an AWS account.
  ##   body: JObject (required)
  var body_598707 = newJObject()
  if body != nil:
    body_598707 = body
  result = call_598706.call(nil, nil, nil, nil, body_598707)

var describeMaintenanceWindows* = Call_DescribeMaintenanceWindows_598693(
    name: "describeMaintenanceWindows", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindows",
    validator: validate_DescribeMaintenanceWindows_598694, base: "/",
    url: url_DescribeMaintenanceWindows_598695,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowsForTarget_598708 = ref object of OpenApiRestCall_597389
proc url_DescribeMaintenanceWindowsForTarget_598710(protocol: Scheme; host: string;
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

proc validate_DescribeMaintenanceWindowsForTarget_598709(path: JsonNode;
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
  var valid_598711 = header.getOrDefault("X-Amz-Target")
  valid_598711 = validateParameter(valid_598711, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowsForTarget"))
  if valid_598711 != nil:
    section.add "X-Amz-Target", valid_598711
  var valid_598712 = header.getOrDefault("X-Amz-Signature")
  valid_598712 = validateParameter(valid_598712, JString, required = false,
                                 default = nil)
  if valid_598712 != nil:
    section.add "X-Amz-Signature", valid_598712
  var valid_598713 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598713 = validateParameter(valid_598713, JString, required = false,
                                 default = nil)
  if valid_598713 != nil:
    section.add "X-Amz-Content-Sha256", valid_598713
  var valid_598714 = header.getOrDefault("X-Amz-Date")
  valid_598714 = validateParameter(valid_598714, JString, required = false,
                                 default = nil)
  if valid_598714 != nil:
    section.add "X-Amz-Date", valid_598714
  var valid_598715 = header.getOrDefault("X-Amz-Credential")
  valid_598715 = validateParameter(valid_598715, JString, required = false,
                                 default = nil)
  if valid_598715 != nil:
    section.add "X-Amz-Credential", valid_598715
  var valid_598716 = header.getOrDefault("X-Amz-Security-Token")
  valid_598716 = validateParameter(valid_598716, JString, required = false,
                                 default = nil)
  if valid_598716 != nil:
    section.add "X-Amz-Security-Token", valid_598716
  var valid_598717 = header.getOrDefault("X-Amz-Algorithm")
  valid_598717 = validateParameter(valid_598717, JString, required = false,
                                 default = nil)
  if valid_598717 != nil:
    section.add "X-Amz-Algorithm", valid_598717
  var valid_598718 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598718 = validateParameter(valid_598718, JString, required = false,
                                 default = nil)
  if valid_598718 != nil:
    section.add "X-Amz-SignedHeaders", valid_598718
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598720: Call_DescribeMaintenanceWindowsForTarget_598708;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves information about the maintenance window targets or tasks that an instance is associated with.
  ## 
  let valid = call_598720.validator(path, query, header, formData, body)
  let scheme = call_598720.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598720.url(scheme.get, call_598720.host, call_598720.base,
                         call_598720.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598720, url, valid)

proc call*(call_598721: Call_DescribeMaintenanceWindowsForTarget_598708;
          body: JsonNode): Recallable =
  ## describeMaintenanceWindowsForTarget
  ## Retrieves information about the maintenance window targets or tasks that an instance is associated with.
  ##   body: JObject (required)
  var body_598722 = newJObject()
  if body != nil:
    body_598722 = body
  result = call_598721.call(nil, nil, nil, nil, body_598722)

var describeMaintenanceWindowsForTarget* = Call_DescribeMaintenanceWindowsForTarget_598708(
    name: "describeMaintenanceWindowsForTarget", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowsForTarget",
    validator: validate_DescribeMaintenanceWindowsForTarget_598709, base: "/",
    url: url_DescribeMaintenanceWindowsForTarget_598710,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeOpsItems_598723 = ref object of OpenApiRestCall_597389
proc url_DescribeOpsItems_598725(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeOpsItems_598724(path: JsonNode; query: JsonNode;
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
  var valid_598726 = header.getOrDefault("X-Amz-Target")
  valid_598726 = validateParameter(valid_598726, JString, required = true, default = newJString(
      "AmazonSSM.DescribeOpsItems"))
  if valid_598726 != nil:
    section.add "X-Amz-Target", valid_598726
  var valid_598727 = header.getOrDefault("X-Amz-Signature")
  valid_598727 = validateParameter(valid_598727, JString, required = false,
                                 default = nil)
  if valid_598727 != nil:
    section.add "X-Amz-Signature", valid_598727
  var valid_598728 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598728 = validateParameter(valid_598728, JString, required = false,
                                 default = nil)
  if valid_598728 != nil:
    section.add "X-Amz-Content-Sha256", valid_598728
  var valid_598729 = header.getOrDefault("X-Amz-Date")
  valid_598729 = validateParameter(valid_598729, JString, required = false,
                                 default = nil)
  if valid_598729 != nil:
    section.add "X-Amz-Date", valid_598729
  var valid_598730 = header.getOrDefault("X-Amz-Credential")
  valid_598730 = validateParameter(valid_598730, JString, required = false,
                                 default = nil)
  if valid_598730 != nil:
    section.add "X-Amz-Credential", valid_598730
  var valid_598731 = header.getOrDefault("X-Amz-Security-Token")
  valid_598731 = validateParameter(valid_598731, JString, required = false,
                                 default = nil)
  if valid_598731 != nil:
    section.add "X-Amz-Security-Token", valid_598731
  var valid_598732 = header.getOrDefault("X-Amz-Algorithm")
  valid_598732 = validateParameter(valid_598732, JString, required = false,
                                 default = nil)
  if valid_598732 != nil:
    section.add "X-Amz-Algorithm", valid_598732
  var valid_598733 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598733 = validateParameter(valid_598733, JString, required = false,
                                 default = nil)
  if valid_598733 != nil:
    section.add "X-Amz-SignedHeaders", valid_598733
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598735: Call_DescribeOpsItems_598723; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Query a set of OpsItems. You must have permission in AWS Identity and Access Management (IAM) to query a list of OpsItems. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ## 
  let valid = call_598735.validator(path, query, header, formData, body)
  let scheme = call_598735.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598735.url(scheme.get, call_598735.host, call_598735.base,
                         call_598735.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598735, url, valid)

proc call*(call_598736: Call_DescribeOpsItems_598723; body: JsonNode): Recallable =
  ## describeOpsItems
  ## <p>Query a set of OpsItems. You must have permission in AWS Identity and Access Management (IAM) to query a list of OpsItems. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ##   body: JObject (required)
  var body_598737 = newJObject()
  if body != nil:
    body_598737 = body
  result = call_598736.call(nil, nil, nil, nil, body_598737)

var describeOpsItems* = Call_DescribeOpsItems_598723(name: "describeOpsItems",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeOpsItems",
    validator: validate_DescribeOpsItems_598724, base: "/",
    url: url_DescribeOpsItems_598725, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeParameters_598738 = ref object of OpenApiRestCall_597389
proc url_DescribeParameters_598740(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeParameters_598739(path: JsonNode; query: JsonNode;
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
  var valid_598741 = query.getOrDefault("MaxResults")
  valid_598741 = validateParameter(valid_598741, JString, required = false,
                                 default = nil)
  if valid_598741 != nil:
    section.add "MaxResults", valid_598741
  var valid_598742 = query.getOrDefault("NextToken")
  valid_598742 = validateParameter(valid_598742, JString, required = false,
                                 default = nil)
  if valid_598742 != nil:
    section.add "NextToken", valid_598742
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_598743 = header.getOrDefault("X-Amz-Target")
  valid_598743 = validateParameter(valid_598743, JString, required = true, default = newJString(
      "AmazonSSM.DescribeParameters"))
  if valid_598743 != nil:
    section.add "X-Amz-Target", valid_598743
  var valid_598744 = header.getOrDefault("X-Amz-Signature")
  valid_598744 = validateParameter(valid_598744, JString, required = false,
                                 default = nil)
  if valid_598744 != nil:
    section.add "X-Amz-Signature", valid_598744
  var valid_598745 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598745 = validateParameter(valid_598745, JString, required = false,
                                 default = nil)
  if valid_598745 != nil:
    section.add "X-Amz-Content-Sha256", valid_598745
  var valid_598746 = header.getOrDefault("X-Amz-Date")
  valid_598746 = validateParameter(valid_598746, JString, required = false,
                                 default = nil)
  if valid_598746 != nil:
    section.add "X-Amz-Date", valid_598746
  var valid_598747 = header.getOrDefault("X-Amz-Credential")
  valid_598747 = validateParameter(valid_598747, JString, required = false,
                                 default = nil)
  if valid_598747 != nil:
    section.add "X-Amz-Credential", valid_598747
  var valid_598748 = header.getOrDefault("X-Amz-Security-Token")
  valid_598748 = validateParameter(valid_598748, JString, required = false,
                                 default = nil)
  if valid_598748 != nil:
    section.add "X-Amz-Security-Token", valid_598748
  var valid_598749 = header.getOrDefault("X-Amz-Algorithm")
  valid_598749 = validateParameter(valid_598749, JString, required = false,
                                 default = nil)
  if valid_598749 != nil:
    section.add "X-Amz-Algorithm", valid_598749
  var valid_598750 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598750 = validateParameter(valid_598750, JString, required = false,
                                 default = nil)
  if valid_598750 != nil:
    section.add "X-Amz-SignedHeaders", valid_598750
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598752: Call_DescribeParameters_598738; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Get information about a parameter.</p> <note> <p>Request results are returned on a best-effort basis. If you specify <code>MaxResults</code> in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of <code>MaxResults</code>. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a <code>NextToken</code>. You can specify the <code>NextToken</code> in a subsequent call to get the next set of results.</p> </note>
  ## 
  let valid = call_598752.validator(path, query, header, formData, body)
  let scheme = call_598752.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598752.url(scheme.get, call_598752.host, call_598752.base,
                         call_598752.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598752, url, valid)

proc call*(call_598753: Call_DescribeParameters_598738; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## describeParameters
  ## <p>Get information about a parameter.</p> <note> <p>Request results are returned on a best-effort basis. If you specify <code>MaxResults</code> in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of <code>MaxResults</code>. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a <code>NextToken</code>. You can specify the <code>NextToken</code> in a subsequent call to get the next set of results.</p> </note>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_598754 = newJObject()
  var body_598755 = newJObject()
  add(query_598754, "MaxResults", newJString(MaxResults))
  add(query_598754, "NextToken", newJString(NextToken))
  if body != nil:
    body_598755 = body
  result = call_598753.call(nil, query_598754, nil, nil, body_598755)

var describeParameters* = Call_DescribeParameters_598738(
    name: "describeParameters", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeParameters",
    validator: validate_DescribeParameters_598739, base: "/",
    url: url_DescribeParameters_598740, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePatchBaselines_598756 = ref object of OpenApiRestCall_597389
proc url_DescribePatchBaselines_598758(protocol: Scheme; host: string; base: string;
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

proc validate_DescribePatchBaselines_598757(path: JsonNode; query: JsonNode;
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
  var valid_598759 = header.getOrDefault("X-Amz-Target")
  valid_598759 = validateParameter(valid_598759, JString, required = true, default = newJString(
      "AmazonSSM.DescribePatchBaselines"))
  if valid_598759 != nil:
    section.add "X-Amz-Target", valid_598759
  var valid_598760 = header.getOrDefault("X-Amz-Signature")
  valid_598760 = validateParameter(valid_598760, JString, required = false,
                                 default = nil)
  if valid_598760 != nil:
    section.add "X-Amz-Signature", valid_598760
  var valid_598761 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598761 = validateParameter(valid_598761, JString, required = false,
                                 default = nil)
  if valid_598761 != nil:
    section.add "X-Amz-Content-Sha256", valid_598761
  var valid_598762 = header.getOrDefault("X-Amz-Date")
  valid_598762 = validateParameter(valid_598762, JString, required = false,
                                 default = nil)
  if valid_598762 != nil:
    section.add "X-Amz-Date", valid_598762
  var valid_598763 = header.getOrDefault("X-Amz-Credential")
  valid_598763 = validateParameter(valid_598763, JString, required = false,
                                 default = nil)
  if valid_598763 != nil:
    section.add "X-Amz-Credential", valid_598763
  var valid_598764 = header.getOrDefault("X-Amz-Security-Token")
  valid_598764 = validateParameter(valid_598764, JString, required = false,
                                 default = nil)
  if valid_598764 != nil:
    section.add "X-Amz-Security-Token", valid_598764
  var valid_598765 = header.getOrDefault("X-Amz-Algorithm")
  valid_598765 = validateParameter(valid_598765, JString, required = false,
                                 default = nil)
  if valid_598765 != nil:
    section.add "X-Amz-Algorithm", valid_598765
  var valid_598766 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598766 = validateParameter(valid_598766, JString, required = false,
                                 default = nil)
  if valid_598766 != nil:
    section.add "X-Amz-SignedHeaders", valid_598766
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598768: Call_DescribePatchBaselines_598756; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the patch baselines in your AWS account.
  ## 
  let valid = call_598768.validator(path, query, header, formData, body)
  let scheme = call_598768.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598768.url(scheme.get, call_598768.host, call_598768.base,
                         call_598768.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598768, url, valid)

proc call*(call_598769: Call_DescribePatchBaselines_598756; body: JsonNode): Recallable =
  ## describePatchBaselines
  ## Lists the patch baselines in your AWS account.
  ##   body: JObject (required)
  var body_598770 = newJObject()
  if body != nil:
    body_598770 = body
  result = call_598769.call(nil, nil, nil, nil, body_598770)

var describePatchBaselines* = Call_DescribePatchBaselines_598756(
    name: "describePatchBaselines", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribePatchBaselines",
    validator: validate_DescribePatchBaselines_598757, base: "/",
    url: url_DescribePatchBaselines_598758, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePatchGroupState_598771 = ref object of OpenApiRestCall_597389
proc url_DescribePatchGroupState_598773(protocol: Scheme; host: string; base: string;
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

proc validate_DescribePatchGroupState_598772(path: JsonNode; query: JsonNode;
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
  var valid_598774 = header.getOrDefault("X-Amz-Target")
  valid_598774 = validateParameter(valid_598774, JString, required = true, default = newJString(
      "AmazonSSM.DescribePatchGroupState"))
  if valid_598774 != nil:
    section.add "X-Amz-Target", valid_598774
  var valid_598775 = header.getOrDefault("X-Amz-Signature")
  valid_598775 = validateParameter(valid_598775, JString, required = false,
                                 default = nil)
  if valid_598775 != nil:
    section.add "X-Amz-Signature", valid_598775
  var valid_598776 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598776 = validateParameter(valid_598776, JString, required = false,
                                 default = nil)
  if valid_598776 != nil:
    section.add "X-Amz-Content-Sha256", valid_598776
  var valid_598777 = header.getOrDefault("X-Amz-Date")
  valid_598777 = validateParameter(valid_598777, JString, required = false,
                                 default = nil)
  if valid_598777 != nil:
    section.add "X-Amz-Date", valid_598777
  var valid_598778 = header.getOrDefault("X-Amz-Credential")
  valid_598778 = validateParameter(valid_598778, JString, required = false,
                                 default = nil)
  if valid_598778 != nil:
    section.add "X-Amz-Credential", valid_598778
  var valid_598779 = header.getOrDefault("X-Amz-Security-Token")
  valid_598779 = validateParameter(valid_598779, JString, required = false,
                                 default = nil)
  if valid_598779 != nil:
    section.add "X-Amz-Security-Token", valid_598779
  var valid_598780 = header.getOrDefault("X-Amz-Algorithm")
  valid_598780 = validateParameter(valid_598780, JString, required = false,
                                 default = nil)
  if valid_598780 != nil:
    section.add "X-Amz-Algorithm", valid_598780
  var valid_598781 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598781 = validateParameter(valid_598781, JString, required = false,
                                 default = nil)
  if valid_598781 != nil:
    section.add "X-Amz-SignedHeaders", valid_598781
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598783: Call_DescribePatchGroupState_598771; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns high-level aggregated patch compliance state for a patch group.
  ## 
  let valid = call_598783.validator(path, query, header, formData, body)
  let scheme = call_598783.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598783.url(scheme.get, call_598783.host, call_598783.base,
                         call_598783.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598783, url, valid)

proc call*(call_598784: Call_DescribePatchGroupState_598771; body: JsonNode): Recallable =
  ## describePatchGroupState
  ## Returns high-level aggregated patch compliance state for a patch group.
  ##   body: JObject (required)
  var body_598785 = newJObject()
  if body != nil:
    body_598785 = body
  result = call_598784.call(nil, nil, nil, nil, body_598785)

var describePatchGroupState* = Call_DescribePatchGroupState_598771(
    name: "describePatchGroupState", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribePatchGroupState",
    validator: validate_DescribePatchGroupState_598772, base: "/",
    url: url_DescribePatchGroupState_598773, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePatchGroups_598786 = ref object of OpenApiRestCall_597389
proc url_DescribePatchGroups_598788(protocol: Scheme; host: string; base: string;
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

proc validate_DescribePatchGroups_598787(path: JsonNode; query: JsonNode;
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
  var valid_598789 = header.getOrDefault("X-Amz-Target")
  valid_598789 = validateParameter(valid_598789, JString, required = true, default = newJString(
      "AmazonSSM.DescribePatchGroups"))
  if valid_598789 != nil:
    section.add "X-Amz-Target", valid_598789
  var valid_598790 = header.getOrDefault("X-Amz-Signature")
  valid_598790 = validateParameter(valid_598790, JString, required = false,
                                 default = nil)
  if valid_598790 != nil:
    section.add "X-Amz-Signature", valid_598790
  var valid_598791 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598791 = validateParameter(valid_598791, JString, required = false,
                                 default = nil)
  if valid_598791 != nil:
    section.add "X-Amz-Content-Sha256", valid_598791
  var valid_598792 = header.getOrDefault("X-Amz-Date")
  valid_598792 = validateParameter(valid_598792, JString, required = false,
                                 default = nil)
  if valid_598792 != nil:
    section.add "X-Amz-Date", valid_598792
  var valid_598793 = header.getOrDefault("X-Amz-Credential")
  valid_598793 = validateParameter(valid_598793, JString, required = false,
                                 default = nil)
  if valid_598793 != nil:
    section.add "X-Amz-Credential", valid_598793
  var valid_598794 = header.getOrDefault("X-Amz-Security-Token")
  valid_598794 = validateParameter(valid_598794, JString, required = false,
                                 default = nil)
  if valid_598794 != nil:
    section.add "X-Amz-Security-Token", valid_598794
  var valid_598795 = header.getOrDefault("X-Amz-Algorithm")
  valid_598795 = validateParameter(valid_598795, JString, required = false,
                                 default = nil)
  if valid_598795 != nil:
    section.add "X-Amz-Algorithm", valid_598795
  var valid_598796 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598796 = validateParameter(valid_598796, JString, required = false,
                                 default = nil)
  if valid_598796 != nil:
    section.add "X-Amz-SignedHeaders", valid_598796
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598798: Call_DescribePatchGroups_598786; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all patch groups that have been registered with patch baselines.
  ## 
  let valid = call_598798.validator(path, query, header, formData, body)
  let scheme = call_598798.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598798.url(scheme.get, call_598798.host, call_598798.base,
                         call_598798.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598798, url, valid)

proc call*(call_598799: Call_DescribePatchGroups_598786; body: JsonNode): Recallable =
  ## describePatchGroups
  ## Lists all patch groups that have been registered with patch baselines.
  ##   body: JObject (required)
  var body_598800 = newJObject()
  if body != nil:
    body_598800 = body
  result = call_598799.call(nil, nil, nil, nil, body_598800)

var describePatchGroups* = Call_DescribePatchGroups_598786(
    name: "describePatchGroups", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribePatchGroups",
    validator: validate_DescribePatchGroups_598787, base: "/",
    url: url_DescribePatchGroups_598788, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePatchProperties_598801 = ref object of OpenApiRestCall_597389
proc url_DescribePatchProperties_598803(protocol: Scheme; host: string; base: string;
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

proc validate_DescribePatchProperties_598802(path: JsonNode; query: JsonNode;
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
  var valid_598804 = header.getOrDefault("X-Amz-Target")
  valid_598804 = validateParameter(valid_598804, JString, required = true, default = newJString(
      "AmazonSSM.DescribePatchProperties"))
  if valid_598804 != nil:
    section.add "X-Amz-Target", valid_598804
  var valid_598805 = header.getOrDefault("X-Amz-Signature")
  valid_598805 = validateParameter(valid_598805, JString, required = false,
                                 default = nil)
  if valid_598805 != nil:
    section.add "X-Amz-Signature", valid_598805
  var valid_598806 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598806 = validateParameter(valid_598806, JString, required = false,
                                 default = nil)
  if valid_598806 != nil:
    section.add "X-Amz-Content-Sha256", valid_598806
  var valid_598807 = header.getOrDefault("X-Amz-Date")
  valid_598807 = validateParameter(valid_598807, JString, required = false,
                                 default = nil)
  if valid_598807 != nil:
    section.add "X-Amz-Date", valid_598807
  var valid_598808 = header.getOrDefault("X-Amz-Credential")
  valid_598808 = validateParameter(valid_598808, JString, required = false,
                                 default = nil)
  if valid_598808 != nil:
    section.add "X-Amz-Credential", valid_598808
  var valid_598809 = header.getOrDefault("X-Amz-Security-Token")
  valid_598809 = validateParameter(valid_598809, JString, required = false,
                                 default = nil)
  if valid_598809 != nil:
    section.add "X-Amz-Security-Token", valid_598809
  var valid_598810 = header.getOrDefault("X-Amz-Algorithm")
  valid_598810 = validateParameter(valid_598810, JString, required = false,
                                 default = nil)
  if valid_598810 != nil:
    section.add "X-Amz-Algorithm", valid_598810
  var valid_598811 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598811 = validateParameter(valid_598811, JString, required = false,
                                 default = nil)
  if valid_598811 != nil:
    section.add "X-Amz-SignedHeaders", valid_598811
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598813: Call_DescribePatchProperties_598801; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the properties of available patches organized by product, product family, classification, severity, and other properties of available patches. You can use the reported properties in the filters you specify in requests for actions such as <a>CreatePatchBaseline</a>, <a>UpdatePatchBaseline</a>, <a>DescribeAvailablePatches</a>, and <a>DescribePatchBaselines</a>.</p> <p>The following section lists the properties that can be used in filters for each major operating system type:</p> <dl> <dt>WINDOWS</dt> <dd> <p>Valid properties: PRODUCT, PRODUCT_FAMILY, CLASSIFICATION, MSRC_SEVERITY</p> </dd> <dt>AMAZON_LINUX</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>AMAZON_LINUX_2</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>UBUNTU </dt> <dd> <p>Valid properties: PRODUCT, PRIORITY</p> </dd> <dt>REDHAT_ENTERPRISE_LINUX</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>SUSE</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>CENTOS</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> </dl>
  ## 
  let valid = call_598813.validator(path, query, header, formData, body)
  let scheme = call_598813.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598813.url(scheme.get, call_598813.host, call_598813.base,
                         call_598813.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598813, url, valid)

proc call*(call_598814: Call_DescribePatchProperties_598801; body: JsonNode): Recallable =
  ## describePatchProperties
  ## <p>Lists the properties of available patches organized by product, product family, classification, severity, and other properties of available patches. You can use the reported properties in the filters you specify in requests for actions such as <a>CreatePatchBaseline</a>, <a>UpdatePatchBaseline</a>, <a>DescribeAvailablePatches</a>, and <a>DescribePatchBaselines</a>.</p> <p>The following section lists the properties that can be used in filters for each major operating system type:</p> <dl> <dt>WINDOWS</dt> <dd> <p>Valid properties: PRODUCT, PRODUCT_FAMILY, CLASSIFICATION, MSRC_SEVERITY</p> </dd> <dt>AMAZON_LINUX</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>AMAZON_LINUX_2</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>UBUNTU </dt> <dd> <p>Valid properties: PRODUCT, PRIORITY</p> </dd> <dt>REDHAT_ENTERPRISE_LINUX</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>SUSE</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>CENTOS</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> </dl>
  ##   body: JObject (required)
  var body_598815 = newJObject()
  if body != nil:
    body_598815 = body
  result = call_598814.call(nil, nil, nil, nil, body_598815)

var describePatchProperties* = Call_DescribePatchProperties_598801(
    name: "describePatchProperties", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribePatchProperties",
    validator: validate_DescribePatchProperties_598802, base: "/",
    url: url_DescribePatchProperties_598803, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSessions_598816 = ref object of OpenApiRestCall_597389
proc url_DescribeSessions_598818(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeSessions_598817(path: JsonNode; query: JsonNode;
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
  var valid_598819 = header.getOrDefault("X-Amz-Target")
  valid_598819 = validateParameter(valid_598819, JString, required = true, default = newJString(
      "AmazonSSM.DescribeSessions"))
  if valid_598819 != nil:
    section.add "X-Amz-Target", valid_598819
  var valid_598820 = header.getOrDefault("X-Amz-Signature")
  valid_598820 = validateParameter(valid_598820, JString, required = false,
                                 default = nil)
  if valid_598820 != nil:
    section.add "X-Amz-Signature", valid_598820
  var valid_598821 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598821 = validateParameter(valid_598821, JString, required = false,
                                 default = nil)
  if valid_598821 != nil:
    section.add "X-Amz-Content-Sha256", valid_598821
  var valid_598822 = header.getOrDefault("X-Amz-Date")
  valid_598822 = validateParameter(valid_598822, JString, required = false,
                                 default = nil)
  if valid_598822 != nil:
    section.add "X-Amz-Date", valid_598822
  var valid_598823 = header.getOrDefault("X-Amz-Credential")
  valid_598823 = validateParameter(valid_598823, JString, required = false,
                                 default = nil)
  if valid_598823 != nil:
    section.add "X-Amz-Credential", valid_598823
  var valid_598824 = header.getOrDefault("X-Amz-Security-Token")
  valid_598824 = validateParameter(valid_598824, JString, required = false,
                                 default = nil)
  if valid_598824 != nil:
    section.add "X-Amz-Security-Token", valid_598824
  var valid_598825 = header.getOrDefault("X-Amz-Algorithm")
  valid_598825 = validateParameter(valid_598825, JString, required = false,
                                 default = nil)
  if valid_598825 != nil:
    section.add "X-Amz-Algorithm", valid_598825
  var valid_598826 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598826 = validateParameter(valid_598826, JString, required = false,
                                 default = nil)
  if valid_598826 != nil:
    section.add "X-Amz-SignedHeaders", valid_598826
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598828: Call_DescribeSessions_598816; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of all active sessions (both connected and disconnected) or terminated sessions from the past 30 days.
  ## 
  let valid = call_598828.validator(path, query, header, formData, body)
  let scheme = call_598828.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598828.url(scheme.get, call_598828.host, call_598828.base,
                         call_598828.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598828, url, valid)

proc call*(call_598829: Call_DescribeSessions_598816; body: JsonNode): Recallable =
  ## describeSessions
  ## Retrieves a list of all active sessions (both connected and disconnected) or terminated sessions from the past 30 days.
  ##   body: JObject (required)
  var body_598830 = newJObject()
  if body != nil:
    body_598830 = body
  result = call_598829.call(nil, nil, nil, nil, body_598830)

var describeSessions* = Call_DescribeSessions_598816(name: "describeSessions",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeSessions",
    validator: validate_DescribeSessions_598817, base: "/",
    url: url_DescribeSessions_598818, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAutomationExecution_598831 = ref object of OpenApiRestCall_597389
proc url_GetAutomationExecution_598833(protocol: Scheme; host: string; base: string;
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

proc validate_GetAutomationExecution_598832(path: JsonNode; query: JsonNode;
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
  var valid_598834 = header.getOrDefault("X-Amz-Target")
  valid_598834 = validateParameter(valid_598834, JString, required = true, default = newJString(
      "AmazonSSM.GetAutomationExecution"))
  if valid_598834 != nil:
    section.add "X-Amz-Target", valid_598834
  var valid_598835 = header.getOrDefault("X-Amz-Signature")
  valid_598835 = validateParameter(valid_598835, JString, required = false,
                                 default = nil)
  if valid_598835 != nil:
    section.add "X-Amz-Signature", valid_598835
  var valid_598836 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598836 = validateParameter(valid_598836, JString, required = false,
                                 default = nil)
  if valid_598836 != nil:
    section.add "X-Amz-Content-Sha256", valid_598836
  var valid_598837 = header.getOrDefault("X-Amz-Date")
  valid_598837 = validateParameter(valid_598837, JString, required = false,
                                 default = nil)
  if valid_598837 != nil:
    section.add "X-Amz-Date", valid_598837
  var valid_598838 = header.getOrDefault("X-Amz-Credential")
  valid_598838 = validateParameter(valid_598838, JString, required = false,
                                 default = nil)
  if valid_598838 != nil:
    section.add "X-Amz-Credential", valid_598838
  var valid_598839 = header.getOrDefault("X-Amz-Security-Token")
  valid_598839 = validateParameter(valid_598839, JString, required = false,
                                 default = nil)
  if valid_598839 != nil:
    section.add "X-Amz-Security-Token", valid_598839
  var valid_598840 = header.getOrDefault("X-Amz-Algorithm")
  valid_598840 = validateParameter(valid_598840, JString, required = false,
                                 default = nil)
  if valid_598840 != nil:
    section.add "X-Amz-Algorithm", valid_598840
  var valid_598841 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598841 = validateParameter(valid_598841, JString, required = false,
                                 default = nil)
  if valid_598841 != nil:
    section.add "X-Amz-SignedHeaders", valid_598841
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598843: Call_GetAutomationExecution_598831; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get detailed information about a particular Automation execution.
  ## 
  let valid = call_598843.validator(path, query, header, formData, body)
  let scheme = call_598843.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598843.url(scheme.get, call_598843.host, call_598843.base,
                         call_598843.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598843, url, valid)

proc call*(call_598844: Call_GetAutomationExecution_598831; body: JsonNode): Recallable =
  ## getAutomationExecution
  ## Get detailed information about a particular Automation execution.
  ##   body: JObject (required)
  var body_598845 = newJObject()
  if body != nil:
    body_598845 = body
  result = call_598844.call(nil, nil, nil, nil, body_598845)

var getAutomationExecution* = Call_GetAutomationExecution_598831(
    name: "getAutomationExecution", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetAutomationExecution",
    validator: validate_GetAutomationExecution_598832, base: "/",
    url: url_GetAutomationExecution_598833, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCalendarState_598846 = ref object of OpenApiRestCall_597389
proc url_GetCalendarState_598848(protocol: Scheme; host: string; base: string;
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

proc validate_GetCalendarState_598847(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598849 = header.getOrDefault("X-Amz-Target")
  valid_598849 = validateParameter(valid_598849, JString, required = true, default = newJString(
      "AmazonSSM.GetCalendarState"))
  if valid_598849 != nil:
    section.add "X-Amz-Target", valid_598849
  var valid_598850 = header.getOrDefault("X-Amz-Signature")
  valid_598850 = validateParameter(valid_598850, JString, required = false,
                                 default = nil)
  if valid_598850 != nil:
    section.add "X-Amz-Signature", valid_598850
  var valid_598851 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598851 = validateParameter(valid_598851, JString, required = false,
                                 default = nil)
  if valid_598851 != nil:
    section.add "X-Amz-Content-Sha256", valid_598851
  var valid_598852 = header.getOrDefault("X-Amz-Date")
  valid_598852 = validateParameter(valid_598852, JString, required = false,
                                 default = nil)
  if valid_598852 != nil:
    section.add "X-Amz-Date", valid_598852
  var valid_598853 = header.getOrDefault("X-Amz-Credential")
  valid_598853 = validateParameter(valid_598853, JString, required = false,
                                 default = nil)
  if valid_598853 != nil:
    section.add "X-Amz-Credential", valid_598853
  var valid_598854 = header.getOrDefault("X-Amz-Security-Token")
  valid_598854 = validateParameter(valid_598854, JString, required = false,
                                 default = nil)
  if valid_598854 != nil:
    section.add "X-Amz-Security-Token", valid_598854
  var valid_598855 = header.getOrDefault("X-Amz-Algorithm")
  valid_598855 = validateParameter(valid_598855, JString, required = false,
                                 default = nil)
  if valid_598855 != nil:
    section.add "X-Amz-Algorithm", valid_598855
  var valid_598856 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598856 = validateParameter(valid_598856, JString, required = false,
                                 default = nil)
  if valid_598856 != nil:
    section.add "X-Amz-SignedHeaders", valid_598856
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598858: Call_GetCalendarState_598846; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the state of the AWS Systems Manager Change Calendar at an optional, specified time. If you specify a time, <code>GetCalendarState</code> returns the state of the calendar at a specific time, and returns the next time that the Change Calendar state will transition. If you do not specify a time, <code>GetCalendarState</code> assumes the current time. Change Calendar entries have two possible states: <code>OPEN</code> or <code>CLOSED</code>. For more information about Systems Manager Change Calendar, see <a href="https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-change-calendar.html">AWS Systems Manager Change Calendar</a> in the <i>AWS Systems Manager User Guide</i>.
  ## 
  let valid = call_598858.validator(path, query, header, formData, body)
  let scheme = call_598858.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598858.url(scheme.get, call_598858.host, call_598858.base,
                         call_598858.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598858, url, valid)

proc call*(call_598859: Call_GetCalendarState_598846; body: JsonNode): Recallable =
  ## getCalendarState
  ## Gets the state of the AWS Systems Manager Change Calendar at an optional, specified time. If you specify a time, <code>GetCalendarState</code> returns the state of the calendar at a specific time, and returns the next time that the Change Calendar state will transition. If you do not specify a time, <code>GetCalendarState</code> assumes the current time. Change Calendar entries have two possible states: <code>OPEN</code> or <code>CLOSED</code>. For more information about Systems Manager Change Calendar, see <a href="https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-change-calendar.html">AWS Systems Manager Change Calendar</a> in the <i>AWS Systems Manager User Guide</i>.
  ##   body: JObject (required)
  var body_598860 = newJObject()
  if body != nil:
    body_598860 = body
  result = call_598859.call(nil, nil, nil, nil, body_598860)

var getCalendarState* = Call_GetCalendarState_598846(name: "getCalendarState",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetCalendarState",
    validator: validate_GetCalendarState_598847, base: "/",
    url: url_GetCalendarState_598848, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCommandInvocation_598861 = ref object of OpenApiRestCall_597389
proc url_GetCommandInvocation_598863(protocol: Scheme; host: string; base: string;
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

proc validate_GetCommandInvocation_598862(path: JsonNode; query: JsonNode;
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
  var valid_598864 = header.getOrDefault("X-Amz-Target")
  valid_598864 = validateParameter(valid_598864, JString, required = true, default = newJString(
      "AmazonSSM.GetCommandInvocation"))
  if valid_598864 != nil:
    section.add "X-Amz-Target", valid_598864
  var valid_598865 = header.getOrDefault("X-Amz-Signature")
  valid_598865 = validateParameter(valid_598865, JString, required = false,
                                 default = nil)
  if valid_598865 != nil:
    section.add "X-Amz-Signature", valid_598865
  var valid_598866 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598866 = validateParameter(valid_598866, JString, required = false,
                                 default = nil)
  if valid_598866 != nil:
    section.add "X-Amz-Content-Sha256", valid_598866
  var valid_598867 = header.getOrDefault("X-Amz-Date")
  valid_598867 = validateParameter(valid_598867, JString, required = false,
                                 default = nil)
  if valid_598867 != nil:
    section.add "X-Amz-Date", valid_598867
  var valid_598868 = header.getOrDefault("X-Amz-Credential")
  valid_598868 = validateParameter(valid_598868, JString, required = false,
                                 default = nil)
  if valid_598868 != nil:
    section.add "X-Amz-Credential", valid_598868
  var valid_598869 = header.getOrDefault("X-Amz-Security-Token")
  valid_598869 = validateParameter(valid_598869, JString, required = false,
                                 default = nil)
  if valid_598869 != nil:
    section.add "X-Amz-Security-Token", valid_598869
  var valid_598870 = header.getOrDefault("X-Amz-Algorithm")
  valid_598870 = validateParameter(valid_598870, JString, required = false,
                                 default = nil)
  if valid_598870 != nil:
    section.add "X-Amz-Algorithm", valid_598870
  var valid_598871 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598871 = validateParameter(valid_598871, JString, required = false,
                                 default = nil)
  if valid_598871 != nil:
    section.add "X-Amz-SignedHeaders", valid_598871
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598873: Call_GetCommandInvocation_598861; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns detailed information about command execution for an invocation or plugin. 
  ## 
  let valid = call_598873.validator(path, query, header, formData, body)
  let scheme = call_598873.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598873.url(scheme.get, call_598873.host, call_598873.base,
                         call_598873.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598873, url, valid)

proc call*(call_598874: Call_GetCommandInvocation_598861; body: JsonNode): Recallable =
  ## getCommandInvocation
  ## Returns detailed information about command execution for an invocation or plugin. 
  ##   body: JObject (required)
  var body_598875 = newJObject()
  if body != nil:
    body_598875 = body
  result = call_598874.call(nil, nil, nil, nil, body_598875)

var getCommandInvocation* = Call_GetCommandInvocation_598861(
    name: "getCommandInvocation", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetCommandInvocation",
    validator: validate_GetCommandInvocation_598862, base: "/",
    url: url_GetCommandInvocation_598863, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnectionStatus_598876 = ref object of OpenApiRestCall_597389
proc url_GetConnectionStatus_598878(protocol: Scheme; host: string; base: string;
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

proc validate_GetConnectionStatus_598877(path: JsonNode; query: JsonNode;
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
  var valid_598879 = header.getOrDefault("X-Amz-Target")
  valid_598879 = validateParameter(valid_598879, JString, required = true, default = newJString(
      "AmazonSSM.GetConnectionStatus"))
  if valid_598879 != nil:
    section.add "X-Amz-Target", valid_598879
  var valid_598880 = header.getOrDefault("X-Amz-Signature")
  valid_598880 = validateParameter(valid_598880, JString, required = false,
                                 default = nil)
  if valid_598880 != nil:
    section.add "X-Amz-Signature", valid_598880
  var valid_598881 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598881 = validateParameter(valid_598881, JString, required = false,
                                 default = nil)
  if valid_598881 != nil:
    section.add "X-Amz-Content-Sha256", valid_598881
  var valid_598882 = header.getOrDefault("X-Amz-Date")
  valid_598882 = validateParameter(valid_598882, JString, required = false,
                                 default = nil)
  if valid_598882 != nil:
    section.add "X-Amz-Date", valid_598882
  var valid_598883 = header.getOrDefault("X-Amz-Credential")
  valid_598883 = validateParameter(valid_598883, JString, required = false,
                                 default = nil)
  if valid_598883 != nil:
    section.add "X-Amz-Credential", valid_598883
  var valid_598884 = header.getOrDefault("X-Amz-Security-Token")
  valid_598884 = validateParameter(valid_598884, JString, required = false,
                                 default = nil)
  if valid_598884 != nil:
    section.add "X-Amz-Security-Token", valid_598884
  var valid_598885 = header.getOrDefault("X-Amz-Algorithm")
  valid_598885 = validateParameter(valid_598885, JString, required = false,
                                 default = nil)
  if valid_598885 != nil:
    section.add "X-Amz-Algorithm", valid_598885
  var valid_598886 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598886 = validateParameter(valid_598886, JString, required = false,
                                 default = nil)
  if valid_598886 != nil:
    section.add "X-Amz-SignedHeaders", valid_598886
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598888: Call_GetConnectionStatus_598876; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the Session Manager connection status for an instance to determine whether it is connected and ready to receive Session Manager connections.
  ## 
  let valid = call_598888.validator(path, query, header, formData, body)
  let scheme = call_598888.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598888.url(scheme.get, call_598888.host, call_598888.base,
                         call_598888.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598888, url, valid)

proc call*(call_598889: Call_GetConnectionStatus_598876; body: JsonNode): Recallable =
  ## getConnectionStatus
  ## Retrieves the Session Manager connection status for an instance to determine whether it is connected and ready to receive Session Manager connections.
  ##   body: JObject (required)
  var body_598890 = newJObject()
  if body != nil:
    body_598890 = body
  result = call_598889.call(nil, nil, nil, nil, body_598890)

var getConnectionStatus* = Call_GetConnectionStatus_598876(
    name: "getConnectionStatus", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetConnectionStatus",
    validator: validate_GetConnectionStatus_598877, base: "/",
    url: url_GetConnectionStatus_598878, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefaultPatchBaseline_598891 = ref object of OpenApiRestCall_597389
proc url_GetDefaultPatchBaseline_598893(protocol: Scheme; host: string; base: string;
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

proc validate_GetDefaultPatchBaseline_598892(path: JsonNode; query: JsonNode;
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
  var valid_598894 = header.getOrDefault("X-Amz-Target")
  valid_598894 = validateParameter(valid_598894, JString, required = true, default = newJString(
      "AmazonSSM.GetDefaultPatchBaseline"))
  if valid_598894 != nil:
    section.add "X-Amz-Target", valid_598894
  var valid_598895 = header.getOrDefault("X-Amz-Signature")
  valid_598895 = validateParameter(valid_598895, JString, required = false,
                                 default = nil)
  if valid_598895 != nil:
    section.add "X-Amz-Signature", valid_598895
  var valid_598896 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598896 = validateParameter(valid_598896, JString, required = false,
                                 default = nil)
  if valid_598896 != nil:
    section.add "X-Amz-Content-Sha256", valid_598896
  var valid_598897 = header.getOrDefault("X-Amz-Date")
  valid_598897 = validateParameter(valid_598897, JString, required = false,
                                 default = nil)
  if valid_598897 != nil:
    section.add "X-Amz-Date", valid_598897
  var valid_598898 = header.getOrDefault("X-Amz-Credential")
  valid_598898 = validateParameter(valid_598898, JString, required = false,
                                 default = nil)
  if valid_598898 != nil:
    section.add "X-Amz-Credential", valid_598898
  var valid_598899 = header.getOrDefault("X-Amz-Security-Token")
  valid_598899 = validateParameter(valid_598899, JString, required = false,
                                 default = nil)
  if valid_598899 != nil:
    section.add "X-Amz-Security-Token", valid_598899
  var valid_598900 = header.getOrDefault("X-Amz-Algorithm")
  valid_598900 = validateParameter(valid_598900, JString, required = false,
                                 default = nil)
  if valid_598900 != nil:
    section.add "X-Amz-Algorithm", valid_598900
  var valid_598901 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598901 = validateParameter(valid_598901, JString, required = false,
                                 default = nil)
  if valid_598901 != nil:
    section.add "X-Amz-SignedHeaders", valid_598901
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598903: Call_GetDefaultPatchBaseline_598891; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the default patch baseline. Note that Systems Manager supports creating multiple default patch baselines. For example, you can create a default patch baseline for each operating system.</p> <p>If you do not specify an operating system value, the default patch baseline for Windows is returned.</p>
  ## 
  let valid = call_598903.validator(path, query, header, formData, body)
  let scheme = call_598903.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598903.url(scheme.get, call_598903.host, call_598903.base,
                         call_598903.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598903, url, valid)

proc call*(call_598904: Call_GetDefaultPatchBaseline_598891; body: JsonNode): Recallable =
  ## getDefaultPatchBaseline
  ## <p>Retrieves the default patch baseline. Note that Systems Manager supports creating multiple default patch baselines. For example, you can create a default patch baseline for each operating system.</p> <p>If you do not specify an operating system value, the default patch baseline for Windows is returned.</p>
  ##   body: JObject (required)
  var body_598905 = newJObject()
  if body != nil:
    body_598905 = body
  result = call_598904.call(nil, nil, nil, nil, body_598905)

var getDefaultPatchBaseline* = Call_GetDefaultPatchBaseline_598891(
    name: "getDefaultPatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetDefaultPatchBaseline",
    validator: validate_GetDefaultPatchBaseline_598892, base: "/",
    url: url_GetDefaultPatchBaseline_598893, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployablePatchSnapshotForInstance_598906 = ref object of OpenApiRestCall_597389
proc url_GetDeployablePatchSnapshotForInstance_598908(protocol: Scheme;
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

proc validate_GetDeployablePatchSnapshotForInstance_598907(path: JsonNode;
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
  var valid_598909 = header.getOrDefault("X-Amz-Target")
  valid_598909 = validateParameter(valid_598909, JString, required = true, default = newJString(
      "AmazonSSM.GetDeployablePatchSnapshotForInstance"))
  if valid_598909 != nil:
    section.add "X-Amz-Target", valid_598909
  var valid_598910 = header.getOrDefault("X-Amz-Signature")
  valid_598910 = validateParameter(valid_598910, JString, required = false,
                                 default = nil)
  if valid_598910 != nil:
    section.add "X-Amz-Signature", valid_598910
  var valid_598911 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598911 = validateParameter(valid_598911, JString, required = false,
                                 default = nil)
  if valid_598911 != nil:
    section.add "X-Amz-Content-Sha256", valid_598911
  var valid_598912 = header.getOrDefault("X-Amz-Date")
  valid_598912 = validateParameter(valid_598912, JString, required = false,
                                 default = nil)
  if valid_598912 != nil:
    section.add "X-Amz-Date", valid_598912
  var valid_598913 = header.getOrDefault("X-Amz-Credential")
  valid_598913 = validateParameter(valid_598913, JString, required = false,
                                 default = nil)
  if valid_598913 != nil:
    section.add "X-Amz-Credential", valid_598913
  var valid_598914 = header.getOrDefault("X-Amz-Security-Token")
  valid_598914 = validateParameter(valid_598914, JString, required = false,
                                 default = nil)
  if valid_598914 != nil:
    section.add "X-Amz-Security-Token", valid_598914
  var valid_598915 = header.getOrDefault("X-Amz-Algorithm")
  valid_598915 = validateParameter(valid_598915, JString, required = false,
                                 default = nil)
  if valid_598915 != nil:
    section.add "X-Amz-Algorithm", valid_598915
  var valid_598916 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598916 = validateParameter(valid_598916, JString, required = false,
                                 default = nil)
  if valid_598916 != nil:
    section.add "X-Amz-SignedHeaders", valid_598916
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598918: Call_GetDeployablePatchSnapshotForInstance_598906;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the current snapshot for the patch baseline the instance uses. This API is primarily used by the AWS-RunPatchBaseline Systems Manager document. 
  ## 
  let valid = call_598918.validator(path, query, header, formData, body)
  let scheme = call_598918.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598918.url(scheme.get, call_598918.host, call_598918.base,
                         call_598918.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598918, url, valid)

proc call*(call_598919: Call_GetDeployablePatchSnapshotForInstance_598906;
          body: JsonNode): Recallable =
  ## getDeployablePatchSnapshotForInstance
  ## Retrieves the current snapshot for the patch baseline the instance uses. This API is primarily used by the AWS-RunPatchBaseline Systems Manager document. 
  ##   body: JObject (required)
  var body_598920 = newJObject()
  if body != nil:
    body_598920 = body
  result = call_598919.call(nil, nil, nil, nil, body_598920)

var getDeployablePatchSnapshotForInstance* = Call_GetDeployablePatchSnapshotForInstance_598906(
    name: "getDeployablePatchSnapshotForInstance", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetDeployablePatchSnapshotForInstance",
    validator: validate_GetDeployablePatchSnapshotForInstance_598907, base: "/",
    url: url_GetDeployablePatchSnapshotForInstance_598908,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocument_598921 = ref object of OpenApiRestCall_597389
proc url_GetDocument_598923(protocol: Scheme; host: string; base: string;
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

proc validate_GetDocument_598922(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598924 = header.getOrDefault("X-Amz-Target")
  valid_598924 = validateParameter(valid_598924, JString, required = true,
                                 default = newJString("AmazonSSM.GetDocument"))
  if valid_598924 != nil:
    section.add "X-Amz-Target", valid_598924
  var valid_598925 = header.getOrDefault("X-Amz-Signature")
  valid_598925 = validateParameter(valid_598925, JString, required = false,
                                 default = nil)
  if valid_598925 != nil:
    section.add "X-Amz-Signature", valid_598925
  var valid_598926 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598926 = validateParameter(valid_598926, JString, required = false,
                                 default = nil)
  if valid_598926 != nil:
    section.add "X-Amz-Content-Sha256", valid_598926
  var valid_598927 = header.getOrDefault("X-Amz-Date")
  valid_598927 = validateParameter(valid_598927, JString, required = false,
                                 default = nil)
  if valid_598927 != nil:
    section.add "X-Amz-Date", valid_598927
  var valid_598928 = header.getOrDefault("X-Amz-Credential")
  valid_598928 = validateParameter(valid_598928, JString, required = false,
                                 default = nil)
  if valid_598928 != nil:
    section.add "X-Amz-Credential", valid_598928
  var valid_598929 = header.getOrDefault("X-Amz-Security-Token")
  valid_598929 = validateParameter(valid_598929, JString, required = false,
                                 default = nil)
  if valid_598929 != nil:
    section.add "X-Amz-Security-Token", valid_598929
  var valid_598930 = header.getOrDefault("X-Amz-Algorithm")
  valid_598930 = validateParameter(valid_598930, JString, required = false,
                                 default = nil)
  if valid_598930 != nil:
    section.add "X-Amz-Algorithm", valid_598930
  var valid_598931 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598931 = validateParameter(valid_598931, JString, required = false,
                                 default = nil)
  if valid_598931 != nil:
    section.add "X-Amz-SignedHeaders", valid_598931
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598933: Call_GetDocument_598921; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the contents of the specified Systems Manager document.
  ## 
  let valid = call_598933.validator(path, query, header, formData, body)
  let scheme = call_598933.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598933.url(scheme.get, call_598933.host, call_598933.base,
                         call_598933.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598933, url, valid)

proc call*(call_598934: Call_GetDocument_598921; body: JsonNode): Recallable =
  ## getDocument
  ## Gets the contents of the specified Systems Manager document.
  ##   body: JObject (required)
  var body_598935 = newJObject()
  if body != nil:
    body_598935 = body
  result = call_598934.call(nil, nil, nil, nil, body_598935)

var getDocument* = Call_GetDocument_598921(name: "getDocument",
                                        meth: HttpMethod.HttpPost,
                                        host: "ssm.amazonaws.com", route: "/#X-Amz-Target=AmazonSSM.GetDocument",
                                        validator: validate_GetDocument_598922,
                                        base: "/", url: url_GetDocument_598923,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInventory_598936 = ref object of OpenApiRestCall_597389
proc url_GetInventory_598938(protocol: Scheme; host: string; base: string;
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

proc validate_GetInventory_598937(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598939 = header.getOrDefault("X-Amz-Target")
  valid_598939 = validateParameter(valid_598939, JString, required = true,
                                 default = newJString("AmazonSSM.GetInventory"))
  if valid_598939 != nil:
    section.add "X-Amz-Target", valid_598939
  var valid_598940 = header.getOrDefault("X-Amz-Signature")
  valid_598940 = validateParameter(valid_598940, JString, required = false,
                                 default = nil)
  if valid_598940 != nil:
    section.add "X-Amz-Signature", valid_598940
  var valid_598941 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598941 = validateParameter(valid_598941, JString, required = false,
                                 default = nil)
  if valid_598941 != nil:
    section.add "X-Amz-Content-Sha256", valid_598941
  var valid_598942 = header.getOrDefault("X-Amz-Date")
  valid_598942 = validateParameter(valid_598942, JString, required = false,
                                 default = nil)
  if valid_598942 != nil:
    section.add "X-Amz-Date", valid_598942
  var valid_598943 = header.getOrDefault("X-Amz-Credential")
  valid_598943 = validateParameter(valid_598943, JString, required = false,
                                 default = nil)
  if valid_598943 != nil:
    section.add "X-Amz-Credential", valid_598943
  var valid_598944 = header.getOrDefault("X-Amz-Security-Token")
  valid_598944 = validateParameter(valid_598944, JString, required = false,
                                 default = nil)
  if valid_598944 != nil:
    section.add "X-Amz-Security-Token", valid_598944
  var valid_598945 = header.getOrDefault("X-Amz-Algorithm")
  valid_598945 = validateParameter(valid_598945, JString, required = false,
                                 default = nil)
  if valid_598945 != nil:
    section.add "X-Amz-Algorithm", valid_598945
  var valid_598946 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598946 = validateParameter(valid_598946, JString, required = false,
                                 default = nil)
  if valid_598946 != nil:
    section.add "X-Amz-SignedHeaders", valid_598946
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598948: Call_GetInventory_598936; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Query inventory information.
  ## 
  let valid = call_598948.validator(path, query, header, formData, body)
  let scheme = call_598948.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598948.url(scheme.get, call_598948.host, call_598948.base,
                         call_598948.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598948, url, valid)

proc call*(call_598949: Call_GetInventory_598936; body: JsonNode): Recallable =
  ## getInventory
  ## Query inventory information.
  ##   body: JObject (required)
  var body_598950 = newJObject()
  if body != nil:
    body_598950 = body
  result = call_598949.call(nil, nil, nil, nil, body_598950)

var getInventory* = Call_GetInventory_598936(name: "getInventory",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetInventory",
    validator: validate_GetInventory_598937, base: "/", url: url_GetInventory_598938,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInventorySchema_598951 = ref object of OpenApiRestCall_597389
proc url_GetInventorySchema_598953(protocol: Scheme; host: string; base: string;
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

proc validate_GetInventorySchema_598952(path: JsonNode; query: JsonNode;
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
  var valid_598954 = header.getOrDefault("X-Amz-Target")
  valid_598954 = validateParameter(valid_598954, JString, required = true, default = newJString(
      "AmazonSSM.GetInventorySchema"))
  if valid_598954 != nil:
    section.add "X-Amz-Target", valid_598954
  var valid_598955 = header.getOrDefault("X-Amz-Signature")
  valid_598955 = validateParameter(valid_598955, JString, required = false,
                                 default = nil)
  if valid_598955 != nil:
    section.add "X-Amz-Signature", valid_598955
  var valid_598956 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598956 = validateParameter(valid_598956, JString, required = false,
                                 default = nil)
  if valid_598956 != nil:
    section.add "X-Amz-Content-Sha256", valid_598956
  var valid_598957 = header.getOrDefault("X-Amz-Date")
  valid_598957 = validateParameter(valid_598957, JString, required = false,
                                 default = nil)
  if valid_598957 != nil:
    section.add "X-Amz-Date", valid_598957
  var valid_598958 = header.getOrDefault("X-Amz-Credential")
  valid_598958 = validateParameter(valid_598958, JString, required = false,
                                 default = nil)
  if valid_598958 != nil:
    section.add "X-Amz-Credential", valid_598958
  var valid_598959 = header.getOrDefault("X-Amz-Security-Token")
  valid_598959 = validateParameter(valid_598959, JString, required = false,
                                 default = nil)
  if valid_598959 != nil:
    section.add "X-Amz-Security-Token", valid_598959
  var valid_598960 = header.getOrDefault("X-Amz-Algorithm")
  valid_598960 = validateParameter(valid_598960, JString, required = false,
                                 default = nil)
  if valid_598960 != nil:
    section.add "X-Amz-Algorithm", valid_598960
  var valid_598961 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598961 = validateParameter(valid_598961, JString, required = false,
                                 default = nil)
  if valid_598961 != nil:
    section.add "X-Amz-SignedHeaders", valid_598961
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598963: Call_GetInventorySchema_598951; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Return a list of inventory type names for the account, or return a list of attribute names for a specific Inventory item type. 
  ## 
  let valid = call_598963.validator(path, query, header, formData, body)
  let scheme = call_598963.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598963.url(scheme.get, call_598963.host, call_598963.base,
                         call_598963.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598963, url, valid)

proc call*(call_598964: Call_GetInventorySchema_598951; body: JsonNode): Recallable =
  ## getInventorySchema
  ## Return a list of inventory type names for the account, or return a list of attribute names for a specific Inventory item type. 
  ##   body: JObject (required)
  var body_598965 = newJObject()
  if body != nil:
    body_598965 = body
  result = call_598964.call(nil, nil, nil, nil, body_598965)

var getInventorySchema* = Call_GetInventorySchema_598951(
    name: "getInventorySchema", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetInventorySchema",
    validator: validate_GetInventorySchema_598952, base: "/",
    url: url_GetInventorySchema_598953, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMaintenanceWindow_598966 = ref object of OpenApiRestCall_597389
proc url_GetMaintenanceWindow_598968(protocol: Scheme; host: string; base: string;
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

proc validate_GetMaintenanceWindow_598967(path: JsonNode; query: JsonNode;
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
  var valid_598969 = header.getOrDefault("X-Amz-Target")
  valid_598969 = validateParameter(valid_598969, JString, required = true, default = newJString(
      "AmazonSSM.GetMaintenanceWindow"))
  if valid_598969 != nil:
    section.add "X-Amz-Target", valid_598969
  var valid_598970 = header.getOrDefault("X-Amz-Signature")
  valid_598970 = validateParameter(valid_598970, JString, required = false,
                                 default = nil)
  if valid_598970 != nil:
    section.add "X-Amz-Signature", valid_598970
  var valid_598971 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598971 = validateParameter(valid_598971, JString, required = false,
                                 default = nil)
  if valid_598971 != nil:
    section.add "X-Amz-Content-Sha256", valid_598971
  var valid_598972 = header.getOrDefault("X-Amz-Date")
  valid_598972 = validateParameter(valid_598972, JString, required = false,
                                 default = nil)
  if valid_598972 != nil:
    section.add "X-Amz-Date", valid_598972
  var valid_598973 = header.getOrDefault("X-Amz-Credential")
  valid_598973 = validateParameter(valid_598973, JString, required = false,
                                 default = nil)
  if valid_598973 != nil:
    section.add "X-Amz-Credential", valid_598973
  var valid_598974 = header.getOrDefault("X-Amz-Security-Token")
  valid_598974 = validateParameter(valid_598974, JString, required = false,
                                 default = nil)
  if valid_598974 != nil:
    section.add "X-Amz-Security-Token", valid_598974
  var valid_598975 = header.getOrDefault("X-Amz-Algorithm")
  valid_598975 = validateParameter(valid_598975, JString, required = false,
                                 default = nil)
  if valid_598975 != nil:
    section.add "X-Amz-Algorithm", valid_598975
  var valid_598976 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598976 = validateParameter(valid_598976, JString, required = false,
                                 default = nil)
  if valid_598976 != nil:
    section.add "X-Amz-SignedHeaders", valid_598976
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598978: Call_GetMaintenanceWindow_598966; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a maintenance window.
  ## 
  let valid = call_598978.validator(path, query, header, formData, body)
  let scheme = call_598978.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598978.url(scheme.get, call_598978.host, call_598978.base,
                         call_598978.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598978, url, valid)

proc call*(call_598979: Call_GetMaintenanceWindow_598966; body: JsonNode): Recallable =
  ## getMaintenanceWindow
  ## Retrieves a maintenance window.
  ##   body: JObject (required)
  var body_598980 = newJObject()
  if body != nil:
    body_598980 = body
  result = call_598979.call(nil, nil, nil, nil, body_598980)

var getMaintenanceWindow* = Call_GetMaintenanceWindow_598966(
    name: "getMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetMaintenanceWindow",
    validator: validate_GetMaintenanceWindow_598967, base: "/",
    url: url_GetMaintenanceWindow_598968, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMaintenanceWindowExecution_598981 = ref object of OpenApiRestCall_597389
proc url_GetMaintenanceWindowExecution_598983(protocol: Scheme; host: string;
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

proc validate_GetMaintenanceWindowExecution_598982(path: JsonNode; query: JsonNode;
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
  var valid_598984 = header.getOrDefault("X-Amz-Target")
  valid_598984 = validateParameter(valid_598984, JString, required = true, default = newJString(
      "AmazonSSM.GetMaintenanceWindowExecution"))
  if valid_598984 != nil:
    section.add "X-Amz-Target", valid_598984
  var valid_598985 = header.getOrDefault("X-Amz-Signature")
  valid_598985 = validateParameter(valid_598985, JString, required = false,
                                 default = nil)
  if valid_598985 != nil:
    section.add "X-Amz-Signature", valid_598985
  var valid_598986 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598986 = validateParameter(valid_598986, JString, required = false,
                                 default = nil)
  if valid_598986 != nil:
    section.add "X-Amz-Content-Sha256", valid_598986
  var valid_598987 = header.getOrDefault("X-Amz-Date")
  valid_598987 = validateParameter(valid_598987, JString, required = false,
                                 default = nil)
  if valid_598987 != nil:
    section.add "X-Amz-Date", valid_598987
  var valid_598988 = header.getOrDefault("X-Amz-Credential")
  valid_598988 = validateParameter(valid_598988, JString, required = false,
                                 default = nil)
  if valid_598988 != nil:
    section.add "X-Amz-Credential", valid_598988
  var valid_598989 = header.getOrDefault("X-Amz-Security-Token")
  valid_598989 = validateParameter(valid_598989, JString, required = false,
                                 default = nil)
  if valid_598989 != nil:
    section.add "X-Amz-Security-Token", valid_598989
  var valid_598990 = header.getOrDefault("X-Amz-Algorithm")
  valid_598990 = validateParameter(valid_598990, JString, required = false,
                                 default = nil)
  if valid_598990 != nil:
    section.add "X-Amz-Algorithm", valid_598990
  var valid_598991 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598991 = validateParameter(valid_598991, JString, required = false,
                                 default = nil)
  if valid_598991 != nil:
    section.add "X-Amz-SignedHeaders", valid_598991
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598993: Call_GetMaintenanceWindowExecution_598981; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details about a specific a maintenance window execution.
  ## 
  let valid = call_598993.validator(path, query, header, formData, body)
  let scheme = call_598993.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598993.url(scheme.get, call_598993.host, call_598993.base,
                         call_598993.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598993, url, valid)

proc call*(call_598994: Call_GetMaintenanceWindowExecution_598981; body: JsonNode): Recallable =
  ## getMaintenanceWindowExecution
  ## Retrieves details about a specific a maintenance window execution.
  ##   body: JObject (required)
  var body_598995 = newJObject()
  if body != nil:
    body_598995 = body
  result = call_598994.call(nil, nil, nil, nil, body_598995)

var getMaintenanceWindowExecution* = Call_GetMaintenanceWindowExecution_598981(
    name: "getMaintenanceWindowExecution", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetMaintenanceWindowExecution",
    validator: validate_GetMaintenanceWindowExecution_598982, base: "/",
    url: url_GetMaintenanceWindowExecution_598983,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMaintenanceWindowExecutionTask_598996 = ref object of OpenApiRestCall_597389
proc url_GetMaintenanceWindowExecutionTask_598998(protocol: Scheme; host: string;
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

proc validate_GetMaintenanceWindowExecutionTask_598997(path: JsonNode;
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
  var valid_598999 = header.getOrDefault("X-Amz-Target")
  valid_598999 = validateParameter(valid_598999, JString, required = true, default = newJString(
      "AmazonSSM.GetMaintenanceWindowExecutionTask"))
  if valid_598999 != nil:
    section.add "X-Amz-Target", valid_598999
  var valid_599000 = header.getOrDefault("X-Amz-Signature")
  valid_599000 = validateParameter(valid_599000, JString, required = false,
                                 default = nil)
  if valid_599000 != nil:
    section.add "X-Amz-Signature", valid_599000
  var valid_599001 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599001 = validateParameter(valid_599001, JString, required = false,
                                 default = nil)
  if valid_599001 != nil:
    section.add "X-Amz-Content-Sha256", valid_599001
  var valid_599002 = header.getOrDefault("X-Amz-Date")
  valid_599002 = validateParameter(valid_599002, JString, required = false,
                                 default = nil)
  if valid_599002 != nil:
    section.add "X-Amz-Date", valid_599002
  var valid_599003 = header.getOrDefault("X-Amz-Credential")
  valid_599003 = validateParameter(valid_599003, JString, required = false,
                                 default = nil)
  if valid_599003 != nil:
    section.add "X-Amz-Credential", valid_599003
  var valid_599004 = header.getOrDefault("X-Amz-Security-Token")
  valid_599004 = validateParameter(valid_599004, JString, required = false,
                                 default = nil)
  if valid_599004 != nil:
    section.add "X-Amz-Security-Token", valid_599004
  var valid_599005 = header.getOrDefault("X-Amz-Algorithm")
  valid_599005 = validateParameter(valid_599005, JString, required = false,
                                 default = nil)
  if valid_599005 != nil:
    section.add "X-Amz-Algorithm", valid_599005
  var valid_599006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599006 = validateParameter(valid_599006, JString, required = false,
                                 default = nil)
  if valid_599006 != nil:
    section.add "X-Amz-SignedHeaders", valid_599006
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599008: Call_GetMaintenanceWindowExecutionTask_598996;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the details about a specific task run as part of a maintenance window execution.
  ## 
  let valid = call_599008.validator(path, query, header, formData, body)
  let scheme = call_599008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599008.url(scheme.get, call_599008.host, call_599008.base,
                         call_599008.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599008, url, valid)

proc call*(call_599009: Call_GetMaintenanceWindowExecutionTask_598996;
          body: JsonNode): Recallable =
  ## getMaintenanceWindowExecutionTask
  ## Retrieves the details about a specific task run as part of a maintenance window execution.
  ##   body: JObject (required)
  var body_599010 = newJObject()
  if body != nil:
    body_599010 = body
  result = call_599009.call(nil, nil, nil, nil, body_599010)

var getMaintenanceWindowExecutionTask* = Call_GetMaintenanceWindowExecutionTask_598996(
    name: "getMaintenanceWindowExecutionTask", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetMaintenanceWindowExecutionTask",
    validator: validate_GetMaintenanceWindowExecutionTask_598997, base: "/",
    url: url_GetMaintenanceWindowExecutionTask_598998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMaintenanceWindowExecutionTaskInvocation_599011 = ref object of OpenApiRestCall_597389
proc url_GetMaintenanceWindowExecutionTaskInvocation_599013(protocol: Scheme;
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

proc validate_GetMaintenanceWindowExecutionTaskInvocation_599012(path: JsonNode;
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
  var valid_599014 = header.getOrDefault("X-Amz-Target")
  valid_599014 = validateParameter(valid_599014, JString, required = true, default = newJString(
      "AmazonSSM.GetMaintenanceWindowExecutionTaskInvocation"))
  if valid_599014 != nil:
    section.add "X-Amz-Target", valid_599014
  var valid_599015 = header.getOrDefault("X-Amz-Signature")
  valid_599015 = validateParameter(valid_599015, JString, required = false,
                                 default = nil)
  if valid_599015 != nil:
    section.add "X-Amz-Signature", valid_599015
  var valid_599016 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599016 = validateParameter(valid_599016, JString, required = false,
                                 default = nil)
  if valid_599016 != nil:
    section.add "X-Amz-Content-Sha256", valid_599016
  var valid_599017 = header.getOrDefault("X-Amz-Date")
  valid_599017 = validateParameter(valid_599017, JString, required = false,
                                 default = nil)
  if valid_599017 != nil:
    section.add "X-Amz-Date", valid_599017
  var valid_599018 = header.getOrDefault("X-Amz-Credential")
  valid_599018 = validateParameter(valid_599018, JString, required = false,
                                 default = nil)
  if valid_599018 != nil:
    section.add "X-Amz-Credential", valid_599018
  var valid_599019 = header.getOrDefault("X-Amz-Security-Token")
  valid_599019 = validateParameter(valid_599019, JString, required = false,
                                 default = nil)
  if valid_599019 != nil:
    section.add "X-Amz-Security-Token", valid_599019
  var valid_599020 = header.getOrDefault("X-Amz-Algorithm")
  valid_599020 = validateParameter(valid_599020, JString, required = false,
                                 default = nil)
  if valid_599020 != nil:
    section.add "X-Amz-Algorithm", valid_599020
  var valid_599021 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599021 = validateParameter(valid_599021, JString, required = false,
                                 default = nil)
  if valid_599021 != nil:
    section.add "X-Amz-SignedHeaders", valid_599021
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599023: Call_GetMaintenanceWindowExecutionTaskInvocation_599011;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves information about a specific task running on a specific target.
  ## 
  let valid = call_599023.validator(path, query, header, formData, body)
  let scheme = call_599023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599023.url(scheme.get, call_599023.host, call_599023.base,
                         call_599023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599023, url, valid)

proc call*(call_599024: Call_GetMaintenanceWindowExecutionTaskInvocation_599011;
          body: JsonNode): Recallable =
  ## getMaintenanceWindowExecutionTaskInvocation
  ## Retrieves information about a specific task running on a specific target.
  ##   body: JObject (required)
  var body_599025 = newJObject()
  if body != nil:
    body_599025 = body
  result = call_599024.call(nil, nil, nil, nil, body_599025)

var getMaintenanceWindowExecutionTaskInvocation* = Call_GetMaintenanceWindowExecutionTaskInvocation_599011(
    name: "getMaintenanceWindowExecutionTaskInvocation",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com", route: "/#X-Amz-Target=AmazonSSM.GetMaintenanceWindowExecutionTaskInvocation",
    validator: validate_GetMaintenanceWindowExecutionTaskInvocation_599012,
    base: "/", url: url_GetMaintenanceWindowExecutionTaskInvocation_599013,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMaintenanceWindowTask_599026 = ref object of OpenApiRestCall_597389
proc url_GetMaintenanceWindowTask_599028(protocol: Scheme; host: string;
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

proc validate_GetMaintenanceWindowTask_599027(path: JsonNode; query: JsonNode;
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
  var valid_599029 = header.getOrDefault("X-Amz-Target")
  valid_599029 = validateParameter(valid_599029, JString, required = true, default = newJString(
      "AmazonSSM.GetMaintenanceWindowTask"))
  if valid_599029 != nil:
    section.add "X-Amz-Target", valid_599029
  var valid_599030 = header.getOrDefault("X-Amz-Signature")
  valid_599030 = validateParameter(valid_599030, JString, required = false,
                                 default = nil)
  if valid_599030 != nil:
    section.add "X-Amz-Signature", valid_599030
  var valid_599031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599031 = validateParameter(valid_599031, JString, required = false,
                                 default = nil)
  if valid_599031 != nil:
    section.add "X-Amz-Content-Sha256", valid_599031
  var valid_599032 = header.getOrDefault("X-Amz-Date")
  valid_599032 = validateParameter(valid_599032, JString, required = false,
                                 default = nil)
  if valid_599032 != nil:
    section.add "X-Amz-Date", valid_599032
  var valid_599033 = header.getOrDefault("X-Amz-Credential")
  valid_599033 = validateParameter(valid_599033, JString, required = false,
                                 default = nil)
  if valid_599033 != nil:
    section.add "X-Amz-Credential", valid_599033
  var valid_599034 = header.getOrDefault("X-Amz-Security-Token")
  valid_599034 = validateParameter(valid_599034, JString, required = false,
                                 default = nil)
  if valid_599034 != nil:
    section.add "X-Amz-Security-Token", valid_599034
  var valid_599035 = header.getOrDefault("X-Amz-Algorithm")
  valid_599035 = validateParameter(valid_599035, JString, required = false,
                                 default = nil)
  if valid_599035 != nil:
    section.add "X-Amz-Algorithm", valid_599035
  var valid_599036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599036 = validateParameter(valid_599036, JString, required = false,
                                 default = nil)
  if valid_599036 != nil:
    section.add "X-Amz-SignedHeaders", valid_599036
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599038: Call_GetMaintenanceWindowTask_599026; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tasks in a maintenance window.
  ## 
  let valid = call_599038.validator(path, query, header, formData, body)
  let scheme = call_599038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599038.url(scheme.get, call_599038.host, call_599038.base,
                         call_599038.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599038, url, valid)

proc call*(call_599039: Call_GetMaintenanceWindowTask_599026; body: JsonNode): Recallable =
  ## getMaintenanceWindowTask
  ## Lists the tasks in a maintenance window.
  ##   body: JObject (required)
  var body_599040 = newJObject()
  if body != nil:
    body_599040 = body
  result = call_599039.call(nil, nil, nil, nil, body_599040)

var getMaintenanceWindowTask* = Call_GetMaintenanceWindowTask_599026(
    name: "getMaintenanceWindowTask", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetMaintenanceWindowTask",
    validator: validate_GetMaintenanceWindowTask_599027, base: "/",
    url: url_GetMaintenanceWindowTask_599028, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOpsItem_599041 = ref object of OpenApiRestCall_597389
proc url_GetOpsItem_599043(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetOpsItem_599042(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_599044 = header.getOrDefault("X-Amz-Target")
  valid_599044 = validateParameter(valid_599044, JString, required = true,
                                 default = newJString("AmazonSSM.GetOpsItem"))
  if valid_599044 != nil:
    section.add "X-Amz-Target", valid_599044
  var valid_599045 = header.getOrDefault("X-Amz-Signature")
  valid_599045 = validateParameter(valid_599045, JString, required = false,
                                 default = nil)
  if valid_599045 != nil:
    section.add "X-Amz-Signature", valid_599045
  var valid_599046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599046 = validateParameter(valid_599046, JString, required = false,
                                 default = nil)
  if valid_599046 != nil:
    section.add "X-Amz-Content-Sha256", valid_599046
  var valid_599047 = header.getOrDefault("X-Amz-Date")
  valid_599047 = validateParameter(valid_599047, JString, required = false,
                                 default = nil)
  if valid_599047 != nil:
    section.add "X-Amz-Date", valid_599047
  var valid_599048 = header.getOrDefault("X-Amz-Credential")
  valid_599048 = validateParameter(valid_599048, JString, required = false,
                                 default = nil)
  if valid_599048 != nil:
    section.add "X-Amz-Credential", valid_599048
  var valid_599049 = header.getOrDefault("X-Amz-Security-Token")
  valid_599049 = validateParameter(valid_599049, JString, required = false,
                                 default = nil)
  if valid_599049 != nil:
    section.add "X-Amz-Security-Token", valid_599049
  var valid_599050 = header.getOrDefault("X-Amz-Algorithm")
  valid_599050 = validateParameter(valid_599050, JString, required = false,
                                 default = nil)
  if valid_599050 != nil:
    section.add "X-Amz-Algorithm", valid_599050
  var valid_599051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599051 = validateParameter(valid_599051, JString, required = false,
                                 default = nil)
  if valid_599051 != nil:
    section.add "X-Amz-SignedHeaders", valid_599051
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599053: Call_GetOpsItem_599041; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Get information about an OpsItem by using the ID. You must have permission in AWS Identity and Access Management (IAM) to view information about an OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ## 
  let valid = call_599053.validator(path, query, header, formData, body)
  let scheme = call_599053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599053.url(scheme.get, call_599053.host, call_599053.base,
                         call_599053.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599053, url, valid)

proc call*(call_599054: Call_GetOpsItem_599041; body: JsonNode): Recallable =
  ## getOpsItem
  ## <p>Get information about an OpsItem by using the ID. You must have permission in AWS Identity and Access Management (IAM) to view information about an OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ##   body: JObject (required)
  var body_599055 = newJObject()
  if body != nil:
    body_599055 = body
  result = call_599054.call(nil, nil, nil, nil, body_599055)

var getOpsItem* = Call_GetOpsItem_599041(name: "getOpsItem",
                                      meth: HttpMethod.HttpPost,
                                      host: "ssm.amazonaws.com", route: "/#X-Amz-Target=AmazonSSM.GetOpsItem",
                                      validator: validate_GetOpsItem_599042,
                                      base: "/", url: url_GetOpsItem_599043,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOpsSummary_599056 = ref object of OpenApiRestCall_597389
proc url_GetOpsSummary_599058(protocol: Scheme; host: string; base: string;
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

proc validate_GetOpsSummary_599057(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_599059 = header.getOrDefault("X-Amz-Target")
  valid_599059 = validateParameter(valid_599059, JString, required = true, default = newJString(
      "AmazonSSM.GetOpsSummary"))
  if valid_599059 != nil:
    section.add "X-Amz-Target", valid_599059
  var valid_599060 = header.getOrDefault("X-Amz-Signature")
  valid_599060 = validateParameter(valid_599060, JString, required = false,
                                 default = nil)
  if valid_599060 != nil:
    section.add "X-Amz-Signature", valid_599060
  var valid_599061 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599061 = validateParameter(valid_599061, JString, required = false,
                                 default = nil)
  if valid_599061 != nil:
    section.add "X-Amz-Content-Sha256", valid_599061
  var valid_599062 = header.getOrDefault("X-Amz-Date")
  valid_599062 = validateParameter(valid_599062, JString, required = false,
                                 default = nil)
  if valid_599062 != nil:
    section.add "X-Amz-Date", valid_599062
  var valid_599063 = header.getOrDefault("X-Amz-Credential")
  valid_599063 = validateParameter(valid_599063, JString, required = false,
                                 default = nil)
  if valid_599063 != nil:
    section.add "X-Amz-Credential", valid_599063
  var valid_599064 = header.getOrDefault("X-Amz-Security-Token")
  valid_599064 = validateParameter(valid_599064, JString, required = false,
                                 default = nil)
  if valid_599064 != nil:
    section.add "X-Amz-Security-Token", valid_599064
  var valid_599065 = header.getOrDefault("X-Amz-Algorithm")
  valid_599065 = validateParameter(valid_599065, JString, required = false,
                                 default = nil)
  if valid_599065 != nil:
    section.add "X-Amz-Algorithm", valid_599065
  var valid_599066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599066 = validateParameter(valid_599066, JString, required = false,
                                 default = nil)
  if valid_599066 != nil:
    section.add "X-Amz-SignedHeaders", valid_599066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599068: Call_GetOpsSummary_599056; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## View a summary of OpsItems based on specified filters and aggregators.
  ## 
  let valid = call_599068.validator(path, query, header, formData, body)
  let scheme = call_599068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599068.url(scheme.get, call_599068.host, call_599068.base,
                         call_599068.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599068, url, valid)

proc call*(call_599069: Call_GetOpsSummary_599056; body: JsonNode): Recallable =
  ## getOpsSummary
  ## View a summary of OpsItems based on specified filters and aggregators.
  ##   body: JObject (required)
  var body_599070 = newJObject()
  if body != nil:
    body_599070 = body
  result = call_599069.call(nil, nil, nil, nil, body_599070)

var getOpsSummary* = Call_GetOpsSummary_599056(name: "getOpsSummary",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetOpsSummary",
    validator: validate_GetOpsSummary_599057, base: "/", url: url_GetOpsSummary_599058,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetParameter_599071 = ref object of OpenApiRestCall_597389
proc url_GetParameter_599073(protocol: Scheme; host: string; base: string;
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

proc validate_GetParameter_599072(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_599074 = header.getOrDefault("X-Amz-Target")
  valid_599074 = validateParameter(valid_599074, JString, required = true,
                                 default = newJString("AmazonSSM.GetParameter"))
  if valid_599074 != nil:
    section.add "X-Amz-Target", valid_599074
  var valid_599075 = header.getOrDefault("X-Amz-Signature")
  valid_599075 = validateParameter(valid_599075, JString, required = false,
                                 default = nil)
  if valid_599075 != nil:
    section.add "X-Amz-Signature", valid_599075
  var valid_599076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599076 = validateParameter(valid_599076, JString, required = false,
                                 default = nil)
  if valid_599076 != nil:
    section.add "X-Amz-Content-Sha256", valid_599076
  var valid_599077 = header.getOrDefault("X-Amz-Date")
  valid_599077 = validateParameter(valid_599077, JString, required = false,
                                 default = nil)
  if valid_599077 != nil:
    section.add "X-Amz-Date", valid_599077
  var valid_599078 = header.getOrDefault("X-Amz-Credential")
  valid_599078 = validateParameter(valid_599078, JString, required = false,
                                 default = nil)
  if valid_599078 != nil:
    section.add "X-Amz-Credential", valid_599078
  var valid_599079 = header.getOrDefault("X-Amz-Security-Token")
  valid_599079 = validateParameter(valid_599079, JString, required = false,
                                 default = nil)
  if valid_599079 != nil:
    section.add "X-Amz-Security-Token", valid_599079
  var valid_599080 = header.getOrDefault("X-Amz-Algorithm")
  valid_599080 = validateParameter(valid_599080, JString, required = false,
                                 default = nil)
  if valid_599080 != nil:
    section.add "X-Amz-Algorithm", valid_599080
  var valid_599081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599081 = validateParameter(valid_599081, JString, required = false,
                                 default = nil)
  if valid_599081 != nil:
    section.add "X-Amz-SignedHeaders", valid_599081
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599083: Call_GetParameter_599071; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get information about a parameter by using the parameter name. Don't confuse this API action with the <a>GetParameters</a> API action.
  ## 
  let valid = call_599083.validator(path, query, header, formData, body)
  let scheme = call_599083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599083.url(scheme.get, call_599083.host, call_599083.base,
                         call_599083.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599083, url, valid)

proc call*(call_599084: Call_GetParameter_599071; body: JsonNode): Recallable =
  ## getParameter
  ## Get information about a parameter by using the parameter name. Don't confuse this API action with the <a>GetParameters</a> API action.
  ##   body: JObject (required)
  var body_599085 = newJObject()
  if body != nil:
    body_599085 = body
  result = call_599084.call(nil, nil, nil, nil, body_599085)

var getParameter* = Call_GetParameter_599071(name: "getParameter",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetParameter",
    validator: validate_GetParameter_599072, base: "/", url: url_GetParameter_599073,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetParameterHistory_599086 = ref object of OpenApiRestCall_597389
proc url_GetParameterHistory_599088(protocol: Scheme; host: string; base: string;
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

proc validate_GetParameterHistory_599087(path: JsonNode; query: JsonNode;
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
  var valid_599089 = query.getOrDefault("MaxResults")
  valid_599089 = validateParameter(valid_599089, JString, required = false,
                                 default = nil)
  if valid_599089 != nil:
    section.add "MaxResults", valid_599089
  var valid_599090 = query.getOrDefault("NextToken")
  valid_599090 = validateParameter(valid_599090, JString, required = false,
                                 default = nil)
  if valid_599090 != nil:
    section.add "NextToken", valid_599090
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_599091 = header.getOrDefault("X-Amz-Target")
  valid_599091 = validateParameter(valid_599091, JString, required = true, default = newJString(
      "AmazonSSM.GetParameterHistory"))
  if valid_599091 != nil:
    section.add "X-Amz-Target", valid_599091
  var valid_599092 = header.getOrDefault("X-Amz-Signature")
  valid_599092 = validateParameter(valid_599092, JString, required = false,
                                 default = nil)
  if valid_599092 != nil:
    section.add "X-Amz-Signature", valid_599092
  var valid_599093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599093 = validateParameter(valid_599093, JString, required = false,
                                 default = nil)
  if valid_599093 != nil:
    section.add "X-Amz-Content-Sha256", valid_599093
  var valid_599094 = header.getOrDefault("X-Amz-Date")
  valid_599094 = validateParameter(valid_599094, JString, required = false,
                                 default = nil)
  if valid_599094 != nil:
    section.add "X-Amz-Date", valid_599094
  var valid_599095 = header.getOrDefault("X-Amz-Credential")
  valid_599095 = validateParameter(valid_599095, JString, required = false,
                                 default = nil)
  if valid_599095 != nil:
    section.add "X-Amz-Credential", valid_599095
  var valid_599096 = header.getOrDefault("X-Amz-Security-Token")
  valid_599096 = validateParameter(valid_599096, JString, required = false,
                                 default = nil)
  if valid_599096 != nil:
    section.add "X-Amz-Security-Token", valid_599096
  var valid_599097 = header.getOrDefault("X-Amz-Algorithm")
  valid_599097 = validateParameter(valid_599097, JString, required = false,
                                 default = nil)
  if valid_599097 != nil:
    section.add "X-Amz-Algorithm", valid_599097
  var valid_599098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599098 = validateParameter(valid_599098, JString, required = false,
                                 default = nil)
  if valid_599098 != nil:
    section.add "X-Amz-SignedHeaders", valid_599098
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599100: Call_GetParameterHistory_599086; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Query a list of all parameters used by the AWS account.
  ## 
  let valid = call_599100.validator(path, query, header, formData, body)
  let scheme = call_599100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599100.url(scheme.get, call_599100.host, call_599100.base,
                         call_599100.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599100, url, valid)

proc call*(call_599101: Call_GetParameterHistory_599086; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getParameterHistory
  ## Query a list of all parameters used by the AWS account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_599102 = newJObject()
  var body_599103 = newJObject()
  add(query_599102, "MaxResults", newJString(MaxResults))
  add(query_599102, "NextToken", newJString(NextToken))
  if body != nil:
    body_599103 = body
  result = call_599101.call(nil, query_599102, nil, nil, body_599103)

var getParameterHistory* = Call_GetParameterHistory_599086(
    name: "getParameterHistory", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetParameterHistory",
    validator: validate_GetParameterHistory_599087, base: "/",
    url: url_GetParameterHistory_599088, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetParameters_599104 = ref object of OpenApiRestCall_597389
proc url_GetParameters_599106(protocol: Scheme; host: string; base: string;
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

proc validate_GetParameters_599105(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_599107 = header.getOrDefault("X-Amz-Target")
  valid_599107 = validateParameter(valid_599107, JString, required = true, default = newJString(
      "AmazonSSM.GetParameters"))
  if valid_599107 != nil:
    section.add "X-Amz-Target", valid_599107
  var valid_599108 = header.getOrDefault("X-Amz-Signature")
  valid_599108 = validateParameter(valid_599108, JString, required = false,
                                 default = nil)
  if valid_599108 != nil:
    section.add "X-Amz-Signature", valid_599108
  var valid_599109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599109 = validateParameter(valid_599109, JString, required = false,
                                 default = nil)
  if valid_599109 != nil:
    section.add "X-Amz-Content-Sha256", valid_599109
  var valid_599110 = header.getOrDefault("X-Amz-Date")
  valid_599110 = validateParameter(valid_599110, JString, required = false,
                                 default = nil)
  if valid_599110 != nil:
    section.add "X-Amz-Date", valid_599110
  var valid_599111 = header.getOrDefault("X-Amz-Credential")
  valid_599111 = validateParameter(valid_599111, JString, required = false,
                                 default = nil)
  if valid_599111 != nil:
    section.add "X-Amz-Credential", valid_599111
  var valid_599112 = header.getOrDefault("X-Amz-Security-Token")
  valid_599112 = validateParameter(valid_599112, JString, required = false,
                                 default = nil)
  if valid_599112 != nil:
    section.add "X-Amz-Security-Token", valid_599112
  var valid_599113 = header.getOrDefault("X-Amz-Algorithm")
  valid_599113 = validateParameter(valid_599113, JString, required = false,
                                 default = nil)
  if valid_599113 != nil:
    section.add "X-Amz-Algorithm", valid_599113
  var valid_599114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599114 = validateParameter(valid_599114, JString, required = false,
                                 default = nil)
  if valid_599114 != nil:
    section.add "X-Amz-SignedHeaders", valid_599114
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599116: Call_GetParameters_599104; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get details of a parameter. Don't confuse this API action with the <a>GetParameter</a> API action.
  ## 
  let valid = call_599116.validator(path, query, header, formData, body)
  let scheme = call_599116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599116.url(scheme.get, call_599116.host, call_599116.base,
                         call_599116.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599116, url, valid)

proc call*(call_599117: Call_GetParameters_599104; body: JsonNode): Recallable =
  ## getParameters
  ## Get details of a parameter. Don't confuse this API action with the <a>GetParameter</a> API action.
  ##   body: JObject (required)
  var body_599118 = newJObject()
  if body != nil:
    body_599118 = body
  result = call_599117.call(nil, nil, nil, nil, body_599118)

var getParameters* = Call_GetParameters_599104(name: "getParameters",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetParameters",
    validator: validate_GetParameters_599105, base: "/", url: url_GetParameters_599106,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetParametersByPath_599119 = ref object of OpenApiRestCall_597389
proc url_GetParametersByPath_599121(protocol: Scheme; host: string; base: string;
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

proc validate_GetParametersByPath_599120(path: JsonNode; query: JsonNode;
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
  var valid_599122 = query.getOrDefault("MaxResults")
  valid_599122 = validateParameter(valid_599122, JString, required = false,
                                 default = nil)
  if valid_599122 != nil:
    section.add "MaxResults", valid_599122
  var valid_599123 = query.getOrDefault("NextToken")
  valid_599123 = validateParameter(valid_599123, JString, required = false,
                                 default = nil)
  if valid_599123 != nil:
    section.add "NextToken", valid_599123
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_599124 = header.getOrDefault("X-Amz-Target")
  valid_599124 = validateParameter(valid_599124, JString, required = true, default = newJString(
      "AmazonSSM.GetParametersByPath"))
  if valid_599124 != nil:
    section.add "X-Amz-Target", valid_599124
  var valid_599125 = header.getOrDefault("X-Amz-Signature")
  valid_599125 = validateParameter(valid_599125, JString, required = false,
                                 default = nil)
  if valid_599125 != nil:
    section.add "X-Amz-Signature", valid_599125
  var valid_599126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599126 = validateParameter(valid_599126, JString, required = false,
                                 default = nil)
  if valid_599126 != nil:
    section.add "X-Amz-Content-Sha256", valid_599126
  var valid_599127 = header.getOrDefault("X-Amz-Date")
  valid_599127 = validateParameter(valid_599127, JString, required = false,
                                 default = nil)
  if valid_599127 != nil:
    section.add "X-Amz-Date", valid_599127
  var valid_599128 = header.getOrDefault("X-Amz-Credential")
  valid_599128 = validateParameter(valid_599128, JString, required = false,
                                 default = nil)
  if valid_599128 != nil:
    section.add "X-Amz-Credential", valid_599128
  var valid_599129 = header.getOrDefault("X-Amz-Security-Token")
  valid_599129 = validateParameter(valid_599129, JString, required = false,
                                 default = nil)
  if valid_599129 != nil:
    section.add "X-Amz-Security-Token", valid_599129
  var valid_599130 = header.getOrDefault("X-Amz-Algorithm")
  valid_599130 = validateParameter(valid_599130, JString, required = false,
                                 default = nil)
  if valid_599130 != nil:
    section.add "X-Amz-Algorithm", valid_599130
  var valid_599131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599131 = validateParameter(valid_599131, JString, required = false,
                                 default = nil)
  if valid_599131 != nil:
    section.add "X-Amz-SignedHeaders", valid_599131
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599133: Call_GetParametersByPath_599119; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieve information about one or more parameters in a specific hierarchy. </p> <note> <p>Request results are returned on a best-effort basis. If you specify <code>MaxResults</code> in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of <code>MaxResults</code>. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a <code>NextToken</code>. You can specify the <code>NextToken</code> in a subsequent call to get the next set of results.</p> </note>
  ## 
  let valid = call_599133.validator(path, query, header, formData, body)
  let scheme = call_599133.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599133.url(scheme.get, call_599133.host, call_599133.base,
                         call_599133.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599133, url, valid)

proc call*(call_599134: Call_GetParametersByPath_599119; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getParametersByPath
  ## <p>Retrieve information about one or more parameters in a specific hierarchy. </p> <note> <p>Request results are returned on a best-effort basis. If you specify <code>MaxResults</code> in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of <code>MaxResults</code>. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a <code>NextToken</code>. You can specify the <code>NextToken</code> in a subsequent call to get the next set of results.</p> </note>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_599135 = newJObject()
  var body_599136 = newJObject()
  add(query_599135, "MaxResults", newJString(MaxResults))
  add(query_599135, "NextToken", newJString(NextToken))
  if body != nil:
    body_599136 = body
  result = call_599134.call(nil, query_599135, nil, nil, body_599136)

var getParametersByPath* = Call_GetParametersByPath_599119(
    name: "getParametersByPath", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetParametersByPath",
    validator: validate_GetParametersByPath_599120, base: "/",
    url: url_GetParametersByPath_599121, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPatchBaseline_599137 = ref object of OpenApiRestCall_597389
proc url_GetPatchBaseline_599139(protocol: Scheme; host: string; base: string;
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

proc validate_GetPatchBaseline_599138(path: JsonNode; query: JsonNode;
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
  var valid_599140 = header.getOrDefault("X-Amz-Target")
  valid_599140 = validateParameter(valid_599140, JString, required = true, default = newJString(
      "AmazonSSM.GetPatchBaseline"))
  if valid_599140 != nil:
    section.add "X-Amz-Target", valid_599140
  var valid_599141 = header.getOrDefault("X-Amz-Signature")
  valid_599141 = validateParameter(valid_599141, JString, required = false,
                                 default = nil)
  if valid_599141 != nil:
    section.add "X-Amz-Signature", valid_599141
  var valid_599142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599142 = validateParameter(valid_599142, JString, required = false,
                                 default = nil)
  if valid_599142 != nil:
    section.add "X-Amz-Content-Sha256", valid_599142
  var valid_599143 = header.getOrDefault("X-Amz-Date")
  valid_599143 = validateParameter(valid_599143, JString, required = false,
                                 default = nil)
  if valid_599143 != nil:
    section.add "X-Amz-Date", valid_599143
  var valid_599144 = header.getOrDefault("X-Amz-Credential")
  valid_599144 = validateParameter(valid_599144, JString, required = false,
                                 default = nil)
  if valid_599144 != nil:
    section.add "X-Amz-Credential", valid_599144
  var valid_599145 = header.getOrDefault("X-Amz-Security-Token")
  valid_599145 = validateParameter(valid_599145, JString, required = false,
                                 default = nil)
  if valid_599145 != nil:
    section.add "X-Amz-Security-Token", valid_599145
  var valid_599146 = header.getOrDefault("X-Amz-Algorithm")
  valid_599146 = validateParameter(valid_599146, JString, required = false,
                                 default = nil)
  if valid_599146 != nil:
    section.add "X-Amz-Algorithm", valid_599146
  var valid_599147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599147 = validateParameter(valid_599147, JString, required = false,
                                 default = nil)
  if valid_599147 != nil:
    section.add "X-Amz-SignedHeaders", valid_599147
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599149: Call_GetPatchBaseline_599137; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a patch baseline.
  ## 
  let valid = call_599149.validator(path, query, header, formData, body)
  let scheme = call_599149.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599149.url(scheme.get, call_599149.host, call_599149.base,
                         call_599149.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599149, url, valid)

proc call*(call_599150: Call_GetPatchBaseline_599137; body: JsonNode): Recallable =
  ## getPatchBaseline
  ## Retrieves information about a patch baseline.
  ##   body: JObject (required)
  var body_599151 = newJObject()
  if body != nil:
    body_599151 = body
  result = call_599150.call(nil, nil, nil, nil, body_599151)

var getPatchBaseline* = Call_GetPatchBaseline_599137(name: "getPatchBaseline",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetPatchBaseline",
    validator: validate_GetPatchBaseline_599138, base: "/",
    url: url_GetPatchBaseline_599139, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPatchBaselineForPatchGroup_599152 = ref object of OpenApiRestCall_597389
proc url_GetPatchBaselineForPatchGroup_599154(protocol: Scheme; host: string;
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

proc validate_GetPatchBaselineForPatchGroup_599153(path: JsonNode; query: JsonNode;
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
  var valid_599155 = header.getOrDefault("X-Amz-Target")
  valid_599155 = validateParameter(valid_599155, JString, required = true, default = newJString(
      "AmazonSSM.GetPatchBaselineForPatchGroup"))
  if valid_599155 != nil:
    section.add "X-Amz-Target", valid_599155
  var valid_599156 = header.getOrDefault("X-Amz-Signature")
  valid_599156 = validateParameter(valid_599156, JString, required = false,
                                 default = nil)
  if valid_599156 != nil:
    section.add "X-Amz-Signature", valid_599156
  var valid_599157 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599157 = validateParameter(valid_599157, JString, required = false,
                                 default = nil)
  if valid_599157 != nil:
    section.add "X-Amz-Content-Sha256", valid_599157
  var valid_599158 = header.getOrDefault("X-Amz-Date")
  valid_599158 = validateParameter(valid_599158, JString, required = false,
                                 default = nil)
  if valid_599158 != nil:
    section.add "X-Amz-Date", valid_599158
  var valid_599159 = header.getOrDefault("X-Amz-Credential")
  valid_599159 = validateParameter(valid_599159, JString, required = false,
                                 default = nil)
  if valid_599159 != nil:
    section.add "X-Amz-Credential", valid_599159
  var valid_599160 = header.getOrDefault("X-Amz-Security-Token")
  valid_599160 = validateParameter(valid_599160, JString, required = false,
                                 default = nil)
  if valid_599160 != nil:
    section.add "X-Amz-Security-Token", valid_599160
  var valid_599161 = header.getOrDefault("X-Amz-Algorithm")
  valid_599161 = validateParameter(valid_599161, JString, required = false,
                                 default = nil)
  if valid_599161 != nil:
    section.add "X-Amz-Algorithm", valid_599161
  var valid_599162 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599162 = validateParameter(valid_599162, JString, required = false,
                                 default = nil)
  if valid_599162 != nil:
    section.add "X-Amz-SignedHeaders", valid_599162
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599164: Call_GetPatchBaselineForPatchGroup_599152; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the patch baseline that should be used for the specified patch group.
  ## 
  let valid = call_599164.validator(path, query, header, formData, body)
  let scheme = call_599164.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599164.url(scheme.get, call_599164.host, call_599164.base,
                         call_599164.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599164, url, valid)

proc call*(call_599165: Call_GetPatchBaselineForPatchGroup_599152; body: JsonNode): Recallable =
  ## getPatchBaselineForPatchGroup
  ## Retrieves the patch baseline that should be used for the specified patch group.
  ##   body: JObject (required)
  var body_599166 = newJObject()
  if body != nil:
    body_599166 = body
  result = call_599165.call(nil, nil, nil, nil, body_599166)

var getPatchBaselineForPatchGroup* = Call_GetPatchBaselineForPatchGroup_599152(
    name: "getPatchBaselineForPatchGroup", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetPatchBaselineForPatchGroup",
    validator: validate_GetPatchBaselineForPatchGroup_599153, base: "/",
    url: url_GetPatchBaselineForPatchGroup_599154,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetServiceSetting_599167 = ref object of OpenApiRestCall_597389
proc url_GetServiceSetting_599169(protocol: Scheme; host: string; base: string;
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

proc validate_GetServiceSetting_599168(path: JsonNode; query: JsonNode;
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
  var valid_599170 = header.getOrDefault("X-Amz-Target")
  valid_599170 = validateParameter(valid_599170, JString, required = true, default = newJString(
      "AmazonSSM.GetServiceSetting"))
  if valid_599170 != nil:
    section.add "X-Amz-Target", valid_599170
  var valid_599171 = header.getOrDefault("X-Amz-Signature")
  valid_599171 = validateParameter(valid_599171, JString, required = false,
                                 default = nil)
  if valid_599171 != nil:
    section.add "X-Amz-Signature", valid_599171
  var valid_599172 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599172 = validateParameter(valid_599172, JString, required = false,
                                 default = nil)
  if valid_599172 != nil:
    section.add "X-Amz-Content-Sha256", valid_599172
  var valid_599173 = header.getOrDefault("X-Amz-Date")
  valid_599173 = validateParameter(valid_599173, JString, required = false,
                                 default = nil)
  if valid_599173 != nil:
    section.add "X-Amz-Date", valid_599173
  var valid_599174 = header.getOrDefault("X-Amz-Credential")
  valid_599174 = validateParameter(valid_599174, JString, required = false,
                                 default = nil)
  if valid_599174 != nil:
    section.add "X-Amz-Credential", valid_599174
  var valid_599175 = header.getOrDefault("X-Amz-Security-Token")
  valid_599175 = validateParameter(valid_599175, JString, required = false,
                                 default = nil)
  if valid_599175 != nil:
    section.add "X-Amz-Security-Token", valid_599175
  var valid_599176 = header.getOrDefault("X-Amz-Algorithm")
  valid_599176 = validateParameter(valid_599176, JString, required = false,
                                 default = nil)
  if valid_599176 != nil:
    section.add "X-Amz-Algorithm", valid_599176
  var valid_599177 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599177 = validateParameter(valid_599177, JString, required = false,
                                 default = nil)
  if valid_599177 != nil:
    section.add "X-Amz-SignedHeaders", valid_599177
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599179: Call_GetServiceSetting_599167; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>UpdateServiceSetting</a> API action to change the default setting. Or use the <a>ResetServiceSetting</a> to change the value back to the original value defined by the AWS service team.</p> <p>Query the current service setting for the account. </p>
  ## 
  let valid = call_599179.validator(path, query, header, formData, body)
  let scheme = call_599179.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599179.url(scheme.get, call_599179.host, call_599179.base,
                         call_599179.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599179, url, valid)

proc call*(call_599180: Call_GetServiceSetting_599167; body: JsonNode): Recallable =
  ## getServiceSetting
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>UpdateServiceSetting</a> API action to change the default setting. Or use the <a>ResetServiceSetting</a> to change the value back to the original value defined by the AWS service team.</p> <p>Query the current service setting for the account. </p>
  ##   body: JObject (required)
  var body_599181 = newJObject()
  if body != nil:
    body_599181 = body
  result = call_599180.call(nil, nil, nil, nil, body_599181)

var getServiceSetting* = Call_GetServiceSetting_599167(name: "getServiceSetting",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetServiceSetting",
    validator: validate_GetServiceSetting_599168, base: "/",
    url: url_GetServiceSetting_599169, schemes: {Scheme.Https, Scheme.Http})
type
  Call_LabelParameterVersion_599182 = ref object of OpenApiRestCall_597389
proc url_LabelParameterVersion_599184(protocol: Scheme; host: string; base: string;
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

proc validate_LabelParameterVersion_599183(path: JsonNode; query: JsonNode;
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
  var valid_599185 = header.getOrDefault("X-Amz-Target")
  valid_599185 = validateParameter(valid_599185, JString, required = true, default = newJString(
      "AmazonSSM.LabelParameterVersion"))
  if valid_599185 != nil:
    section.add "X-Amz-Target", valid_599185
  var valid_599186 = header.getOrDefault("X-Amz-Signature")
  valid_599186 = validateParameter(valid_599186, JString, required = false,
                                 default = nil)
  if valid_599186 != nil:
    section.add "X-Amz-Signature", valid_599186
  var valid_599187 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599187 = validateParameter(valid_599187, JString, required = false,
                                 default = nil)
  if valid_599187 != nil:
    section.add "X-Amz-Content-Sha256", valid_599187
  var valid_599188 = header.getOrDefault("X-Amz-Date")
  valid_599188 = validateParameter(valid_599188, JString, required = false,
                                 default = nil)
  if valid_599188 != nil:
    section.add "X-Amz-Date", valid_599188
  var valid_599189 = header.getOrDefault("X-Amz-Credential")
  valid_599189 = validateParameter(valid_599189, JString, required = false,
                                 default = nil)
  if valid_599189 != nil:
    section.add "X-Amz-Credential", valid_599189
  var valid_599190 = header.getOrDefault("X-Amz-Security-Token")
  valid_599190 = validateParameter(valid_599190, JString, required = false,
                                 default = nil)
  if valid_599190 != nil:
    section.add "X-Amz-Security-Token", valid_599190
  var valid_599191 = header.getOrDefault("X-Amz-Algorithm")
  valid_599191 = validateParameter(valid_599191, JString, required = false,
                                 default = nil)
  if valid_599191 != nil:
    section.add "X-Amz-Algorithm", valid_599191
  var valid_599192 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599192 = validateParameter(valid_599192, JString, required = false,
                                 default = nil)
  if valid_599192 != nil:
    section.add "X-Amz-SignedHeaders", valid_599192
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599194: Call_LabelParameterVersion_599182; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>A parameter label is a user-defined alias to help you manage different versions of a parameter. When you modify a parameter, Systems Manager automatically saves a new version and increments the version number by one. A label can help you remember the purpose of a parameter when there are multiple versions. </p> <p>Parameter labels have the following requirements and restrictions.</p> <ul> <li> <p>A version of a parameter can have a maximum of 10 labels.</p> </li> <li> <p>You can't attach the same label to different versions of the same parameter. For example, if version 1 has the label Production, then you can't attach Production to version 2.</p> </li> <li> <p>You can move a label from one version of a parameter to another.</p> </li> <li> <p>You can't create a label when you create a new parameter. You must attach a label to a specific version of a parameter.</p> </li> <li> <p>You can't delete a parameter label. If you no longer want to use a parameter label, then you must move it to a different version of a parameter.</p> </li> <li> <p>A label can have a maximum of 100 characters.</p> </li> <li> <p>Labels can contain letters (case sensitive), numbers, periods (.), hyphens (-), or underscores (_).</p> </li> <li> <p>Labels can't begin with a number, "aws," or "ssm" (not case sensitive). If a label fails to meet these requirements, then the label is not associated with a parameter and the system displays it in the list of InvalidLabels.</p> </li> </ul>
  ## 
  let valid = call_599194.validator(path, query, header, formData, body)
  let scheme = call_599194.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599194.url(scheme.get, call_599194.host, call_599194.base,
                         call_599194.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599194, url, valid)

proc call*(call_599195: Call_LabelParameterVersion_599182; body: JsonNode): Recallable =
  ## labelParameterVersion
  ## <p>A parameter label is a user-defined alias to help you manage different versions of a parameter. When you modify a parameter, Systems Manager automatically saves a new version and increments the version number by one. A label can help you remember the purpose of a parameter when there are multiple versions. </p> <p>Parameter labels have the following requirements and restrictions.</p> <ul> <li> <p>A version of a parameter can have a maximum of 10 labels.</p> </li> <li> <p>You can't attach the same label to different versions of the same parameter. For example, if version 1 has the label Production, then you can't attach Production to version 2.</p> </li> <li> <p>You can move a label from one version of a parameter to another.</p> </li> <li> <p>You can't create a label when you create a new parameter. You must attach a label to a specific version of a parameter.</p> </li> <li> <p>You can't delete a parameter label. If you no longer want to use a parameter label, then you must move it to a different version of a parameter.</p> </li> <li> <p>A label can have a maximum of 100 characters.</p> </li> <li> <p>Labels can contain letters (case sensitive), numbers, periods (.), hyphens (-), or underscores (_).</p> </li> <li> <p>Labels can't begin with a number, "aws," or "ssm" (not case sensitive). If a label fails to meet these requirements, then the label is not associated with a parameter and the system displays it in the list of InvalidLabels.</p> </li> </ul>
  ##   body: JObject (required)
  var body_599196 = newJObject()
  if body != nil:
    body_599196 = body
  result = call_599195.call(nil, nil, nil, nil, body_599196)

var labelParameterVersion* = Call_LabelParameterVersion_599182(
    name: "labelParameterVersion", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.LabelParameterVersion",
    validator: validate_LabelParameterVersion_599183, base: "/",
    url: url_LabelParameterVersion_599184, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssociationVersions_599197 = ref object of OpenApiRestCall_597389
proc url_ListAssociationVersions_599199(protocol: Scheme; host: string; base: string;
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

proc validate_ListAssociationVersions_599198(path: JsonNode; query: JsonNode;
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
  var valid_599200 = header.getOrDefault("X-Amz-Target")
  valid_599200 = validateParameter(valid_599200, JString, required = true, default = newJString(
      "AmazonSSM.ListAssociationVersions"))
  if valid_599200 != nil:
    section.add "X-Amz-Target", valid_599200
  var valid_599201 = header.getOrDefault("X-Amz-Signature")
  valid_599201 = validateParameter(valid_599201, JString, required = false,
                                 default = nil)
  if valid_599201 != nil:
    section.add "X-Amz-Signature", valid_599201
  var valid_599202 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599202 = validateParameter(valid_599202, JString, required = false,
                                 default = nil)
  if valid_599202 != nil:
    section.add "X-Amz-Content-Sha256", valid_599202
  var valid_599203 = header.getOrDefault("X-Amz-Date")
  valid_599203 = validateParameter(valid_599203, JString, required = false,
                                 default = nil)
  if valid_599203 != nil:
    section.add "X-Amz-Date", valid_599203
  var valid_599204 = header.getOrDefault("X-Amz-Credential")
  valid_599204 = validateParameter(valid_599204, JString, required = false,
                                 default = nil)
  if valid_599204 != nil:
    section.add "X-Amz-Credential", valid_599204
  var valid_599205 = header.getOrDefault("X-Amz-Security-Token")
  valid_599205 = validateParameter(valid_599205, JString, required = false,
                                 default = nil)
  if valid_599205 != nil:
    section.add "X-Amz-Security-Token", valid_599205
  var valid_599206 = header.getOrDefault("X-Amz-Algorithm")
  valid_599206 = validateParameter(valid_599206, JString, required = false,
                                 default = nil)
  if valid_599206 != nil:
    section.add "X-Amz-Algorithm", valid_599206
  var valid_599207 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599207 = validateParameter(valid_599207, JString, required = false,
                                 default = nil)
  if valid_599207 != nil:
    section.add "X-Amz-SignedHeaders", valid_599207
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599209: Call_ListAssociationVersions_599197; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves all versions of an association for a specific association ID.
  ## 
  let valid = call_599209.validator(path, query, header, formData, body)
  let scheme = call_599209.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599209.url(scheme.get, call_599209.host, call_599209.base,
                         call_599209.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599209, url, valid)

proc call*(call_599210: Call_ListAssociationVersions_599197; body: JsonNode): Recallable =
  ## listAssociationVersions
  ## Retrieves all versions of an association for a specific association ID.
  ##   body: JObject (required)
  var body_599211 = newJObject()
  if body != nil:
    body_599211 = body
  result = call_599210.call(nil, nil, nil, nil, body_599211)

var listAssociationVersions* = Call_ListAssociationVersions_599197(
    name: "listAssociationVersions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListAssociationVersions",
    validator: validate_ListAssociationVersions_599198, base: "/",
    url: url_ListAssociationVersions_599199, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssociations_599212 = ref object of OpenApiRestCall_597389
proc url_ListAssociations_599214(protocol: Scheme; host: string; base: string;
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

proc validate_ListAssociations_599213(path: JsonNode; query: JsonNode;
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
  var valid_599215 = query.getOrDefault("MaxResults")
  valid_599215 = validateParameter(valid_599215, JString, required = false,
                                 default = nil)
  if valid_599215 != nil:
    section.add "MaxResults", valid_599215
  var valid_599216 = query.getOrDefault("NextToken")
  valid_599216 = validateParameter(valid_599216, JString, required = false,
                                 default = nil)
  if valid_599216 != nil:
    section.add "NextToken", valid_599216
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_599217 = header.getOrDefault("X-Amz-Target")
  valid_599217 = validateParameter(valid_599217, JString, required = true, default = newJString(
      "AmazonSSM.ListAssociations"))
  if valid_599217 != nil:
    section.add "X-Amz-Target", valid_599217
  var valid_599218 = header.getOrDefault("X-Amz-Signature")
  valid_599218 = validateParameter(valid_599218, JString, required = false,
                                 default = nil)
  if valid_599218 != nil:
    section.add "X-Amz-Signature", valid_599218
  var valid_599219 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599219 = validateParameter(valid_599219, JString, required = false,
                                 default = nil)
  if valid_599219 != nil:
    section.add "X-Amz-Content-Sha256", valid_599219
  var valid_599220 = header.getOrDefault("X-Amz-Date")
  valid_599220 = validateParameter(valid_599220, JString, required = false,
                                 default = nil)
  if valid_599220 != nil:
    section.add "X-Amz-Date", valid_599220
  var valid_599221 = header.getOrDefault("X-Amz-Credential")
  valid_599221 = validateParameter(valid_599221, JString, required = false,
                                 default = nil)
  if valid_599221 != nil:
    section.add "X-Amz-Credential", valid_599221
  var valid_599222 = header.getOrDefault("X-Amz-Security-Token")
  valid_599222 = validateParameter(valid_599222, JString, required = false,
                                 default = nil)
  if valid_599222 != nil:
    section.add "X-Amz-Security-Token", valid_599222
  var valid_599223 = header.getOrDefault("X-Amz-Algorithm")
  valid_599223 = validateParameter(valid_599223, JString, required = false,
                                 default = nil)
  if valid_599223 != nil:
    section.add "X-Amz-Algorithm", valid_599223
  var valid_599224 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599224 = validateParameter(valid_599224, JString, required = false,
                                 default = nil)
  if valid_599224 != nil:
    section.add "X-Amz-SignedHeaders", valid_599224
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599226: Call_ListAssociations_599212; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the associations for the specified Systems Manager document or instance.
  ## 
  let valid = call_599226.validator(path, query, header, formData, body)
  let scheme = call_599226.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599226.url(scheme.get, call_599226.host, call_599226.base,
                         call_599226.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599226, url, valid)

proc call*(call_599227: Call_ListAssociations_599212; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listAssociations
  ## Lists the associations for the specified Systems Manager document or instance.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_599228 = newJObject()
  var body_599229 = newJObject()
  add(query_599228, "MaxResults", newJString(MaxResults))
  add(query_599228, "NextToken", newJString(NextToken))
  if body != nil:
    body_599229 = body
  result = call_599227.call(nil, query_599228, nil, nil, body_599229)

var listAssociations* = Call_ListAssociations_599212(name: "listAssociations",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListAssociations",
    validator: validate_ListAssociations_599213, base: "/",
    url: url_ListAssociations_599214, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCommandInvocations_599230 = ref object of OpenApiRestCall_597389
proc url_ListCommandInvocations_599232(protocol: Scheme; host: string; base: string;
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

proc validate_ListCommandInvocations_599231(path: JsonNode; query: JsonNode;
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
  var valid_599233 = query.getOrDefault("MaxResults")
  valid_599233 = validateParameter(valid_599233, JString, required = false,
                                 default = nil)
  if valid_599233 != nil:
    section.add "MaxResults", valid_599233
  var valid_599234 = query.getOrDefault("NextToken")
  valid_599234 = validateParameter(valid_599234, JString, required = false,
                                 default = nil)
  if valid_599234 != nil:
    section.add "NextToken", valid_599234
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_599235 = header.getOrDefault("X-Amz-Target")
  valid_599235 = validateParameter(valid_599235, JString, required = true, default = newJString(
      "AmazonSSM.ListCommandInvocations"))
  if valid_599235 != nil:
    section.add "X-Amz-Target", valid_599235
  var valid_599236 = header.getOrDefault("X-Amz-Signature")
  valid_599236 = validateParameter(valid_599236, JString, required = false,
                                 default = nil)
  if valid_599236 != nil:
    section.add "X-Amz-Signature", valid_599236
  var valid_599237 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599237 = validateParameter(valid_599237, JString, required = false,
                                 default = nil)
  if valid_599237 != nil:
    section.add "X-Amz-Content-Sha256", valid_599237
  var valid_599238 = header.getOrDefault("X-Amz-Date")
  valid_599238 = validateParameter(valid_599238, JString, required = false,
                                 default = nil)
  if valid_599238 != nil:
    section.add "X-Amz-Date", valid_599238
  var valid_599239 = header.getOrDefault("X-Amz-Credential")
  valid_599239 = validateParameter(valid_599239, JString, required = false,
                                 default = nil)
  if valid_599239 != nil:
    section.add "X-Amz-Credential", valid_599239
  var valid_599240 = header.getOrDefault("X-Amz-Security-Token")
  valid_599240 = validateParameter(valid_599240, JString, required = false,
                                 default = nil)
  if valid_599240 != nil:
    section.add "X-Amz-Security-Token", valid_599240
  var valid_599241 = header.getOrDefault("X-Amz-Algorithm")
  valid_599241 = validateParameter(valid_599241, JString, required = false,
                                 default = nil)
  if valid_599241 != nil:
    section.add "X-Amz-Algorithm", valid_599241
  var valid_599242 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599242 = validateParameter(valid_599242, JString, required = false,
                                 default = nil)
  if valid_599242 != nil:
    section.add "X-Amz-SignedHeaders", valid_599242
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599244: Call_ListCommandInvocations_599230; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## An invocation is copy of a command sent to a specific instance. A command can apply to one or more instances. A command invocation applies to one instance. For example, if a user runs SendCommand against three instances, then a command invocation is created for each requested instance ID. ListCommandInvocations provide status about command execution.
  ## 
  let valid = call_599244.validator(path, query, header, formData, body)
  let scheme = call_599244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599244.url(scheme.get, call_599244.host, call_599244.base,
                         call_599244.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599244, url, valid)

proc call*(call_599245: Call_ListCommandInvocations_599230; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listCommandInvocations
  ## An invocation is copy of a command sent to a specific instance. A command can apply to one or more instances. A command invocation applies to one instance. For example, if a user runs SendCommand against three instances, then a command invocation is created for each requested instance ID. ListCommandInvocations provide status about command execution.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_599246 = newJObject()
  var body_599247 = newJObject()
  add(query_599246, "MaxResults", newJString(MaxResults))
  add(query_599246, "NextToken", newJString(NextToken))
  if body != nil:
    body_599247 = body
  result = call_599245.call(nil, query_599246, nil, nil, body_599247)

var listCommandInvocations* = Call_ListCommandInvocations_599230(
    name: "listCommandInvocations", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListCommandInvocations",
    validator: validate_ListCommandInvocations_599231, base: "/",
    url: url_ListCommandInvocations_599232, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCommands_599248 = ref object of OpenApiRestCall_597389
proc url_ListCommands_599250(protocol: Scheme; host: string; base: string;
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

proc validate_ListCommands_599249(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_599251 = query.getOrDefault("MaxResults")
  valid_599251 = validateParameter(valid_599251, JString, required = false,
                                 default = nil)
  if valid_599251 != nil:
    section.add "MaxResults", valid_599251
  var valid_599252 = query.getOrDefault("NextToken")
  valid_599252 = validateParameter(valid_599252, JString, required = false,
                                 default = nil)
  if valid_599252 != nil:
    section.add "NextToken", valid_599252
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_599253 = header.getOrDefault("X-Amz-Target")
  valid_599253 = validateParameter(valid_599253, JString, required = true,
                                 default = newJString("AmazonSSM.ListCommands"))
  if valid_599253 != nil:
    section.add "X-Amz-Target", valid_599253
  var valid_599254 = header.getOrDefault("X-Amz-Signature")
  valid_599254 = validateParameter(valid_599254, JString, required = false,
                                 default = nil)
  if valid_599254 != nil:
    section.add "X-Amz-Signature", valid_599254
  var valid_599255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599255 = validateParameter(valid_599255, JString, required = false,
                                 default = nil)
  if valid_599255 != nil:
    section.add "X-Amz-Content-Sha256", valid_599255
  var valid_599256 = header.getOrDefault("X-Amz-Date")
  valid_599256 = validateParameter(valid_599256, JString, required = false,
                                 default = nil)
  if valid_599256 != nil:
    section.add "X-Amz-Date", valid_599256
  var valid_599257 = header.getOrDefault("X-Amz-Credential")
  valid_599257 = validateParameter(valid_599257, JString, required = false,
                                 default = nil)
  if valid_599257 != nil:
    section.add "X-Amz-Credential", valid_599257
  var valid_599258 = header.getOrDefault("X-Amz-Security-Token")
  valid_599258 = validateParameter(valid_599258, JString, required = false,
                                 default = nil)
  if valid_599258 != nil:
    section.add "X-Amz-Security-Token", valid_599258
  var valid_599259 = header.getOrDefault("X-Amz-Algorithm")
  valid_599259 = validateParameter(valid_599259, JString, required = false,
                                 default = nil)
  if valid_599259 != nil:
    section.add "X-Amz-Algorithm", valid_599259
  var valid_599260 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599260 = validateParameter(valid_599260, JString, required = false,
                                 default = nil)
  if valid_599260 != nil:
    section.add "X-Amz-SignedHeaders", valid_599260
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599262: Call_ListCommands_599248; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the commands requested by users of the AWS account.
  ## 
  let valid = call_599262.validator(path, query, header, formData, body)
  let scheme = call_599262.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599262.url(scheme.get, call_599262.host, call_599262.base,
                         call_599262.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599262, url, valid)

proc call*(call_599263: Call_ListCommands_599248; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listCommands
  ## Lists the commands requested by users of the AWS account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_599264 = newJObject()
  var body_599265 = newJObject()
  add(query_599264, "MaxResults", newJString(MaxResults))
  add(query_599264, "NextToken", newJString(NextToken))
  if body != nil:
    body_599265 = body
  result = call_599263.call(nil, query_599264, nil, nil, body_599265)

var listCommands* = Call_ListCommands_599248(name: "listCommands",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListCommands",
    validator: validate_ListCommands_599249, base: "/", url: url_ListCommands_599250,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListComplianceItems_599266 = ref object of OpenApiRestCall_597389
proc url_ListComplianceItems_599268(protocol: Scheme; host: string; base: string;
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

proc validate_ListComplianceItems_599267(path: JsonNode; query: JsonNode;
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
  var valid_599269 = header.getOrDefault("X-Amz-Target")
  valid_599269 = validateParameter(valid_599269, JString, required = true, default = newJString(
      "AmazonSSM.ListComplianceItems"))
  if valid_599269 != nil:
    section.add "X-Amz-Target", valid_599269
  var valid_599270 = header.getOrDefault("X-Amz-Signature")
  valid_599270 = validateParameter(valid_599270, JString, required = false,
                                 default = nil)
  if valid_599270 != nil:
    section.add "X-Amz-Signature", valid_599270
  var valid_599271 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599271 = validateParameter(valid_599271, JString, required = false,
                                 default = nil)
  if valid_599271 != nil:
    section.add "X-Amz-Content-Sha256", valid_599271
  var valid_599272 = header.getOrDefault("X-Amz-Date")
  valid_599272 = validateParameter(valid_599272, JString, required = false,
                                 default = nil)
  if valid_599272 != nil:
    section.add "X-Amz-Date", valid_599272
  var valid_599273 = header.getOrDefault("X-Amz-Credential")
  valid_599273 = validateParameter(valid_599273, JString, required = false,
                                 default = nil)
  if valid_599273 != nil:
    section.add "X-Amz-Credential", valid_599273
  var valid_599274 = header.getOrDefault("X-Amz-Security-Token")
  valid_599274 = validateParameter(valid_599274, JString, required = false,
                                 default = nil)
  if valid_599274 != nil:
    section.add "X-Amz-Security-Token", valid_599274
  var valid_599275 = header.getOrDefault("X-Amz-Algorithm")
  valid_599275 = validateParameter(valid_599275, JString, required = false,
                                 default = nil)
  if valid_599275 != nil:
    section.add "X-Amz-Algorithm", valid_599275
  var valid_599276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599276 = validateParameter(valid_599276, JString, required = false,
                                 default = nil)
  if valid_599276 != nil:
    section.add "X-Amz-SignedHeaders", valid_599276
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599278: Call_ListComplianceItems_599266; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## For a specified resource ID, this API action returns a list of compliance statuses for different resource types. Currently, you can only specify one resource ID per call. List results depend on the criteria specified in the filter. 
  ## 
  let valid = call_599278.validator(path, query, header, formData, body)
  let scheme = call_599278.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599278.url(scheme.get, call_599278.host, call_599278.base,
                         call_599278.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599278, url, valid)

proc call*(call_599279: Call_ListComplianceItems_599266; body: JsonNode): Recallable =
  ## listComplianceItems
  ## For a specified resource ID, this API action returns a list of compliance statuses for different resource types. Currently, you can only specify one resource ID per call. List results depend on the criteria specified in the filter. 
  ##   body: JObject (required)
  var body_599280 = newJObject()
  if body != nil:
    body_599280 = body
  result = call_599279.call(nil, nil, nil, nil, body_599280)

var listComplianceItems* = Call_ListComplianceItems_599266(
    name: "listComplianceItems", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListComplianceItems",
    validator: validate_ListComplianceItems_599267, base: "/",
    url: url_ListComplianceItems_599268, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListComplianceSummaries_599281 = ref object of OpenApiRestCall_597389
proc url_ListComplianceSummaries_599283(protocol: Scheme; host: string; base: string;
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

proc validate_ListComplianceSummaries_599282(path: JsonNode; query: JsonNode;
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
  var valid_599284 = header.getOrDefault("X-Amz-Target")
  valid_599284 = validateParameter(valid_599284, JString, required = true, default = newJString(
      "AmazonSSM.ListComplianceSummaries"))
  if valid_599284 != nil:
    section.add "X-Amz-Target", valid_599284
  var valid_599285 = header.getOrDefault("X-Amz-Signature")
  valid_599285 = validateParameter(valid_599285, JString, required = false,
                                 default = nil)
  if valid_599285 != nil:
    section.add "X-Amz-Signature", valid_599285
  var valid_599286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599286 = validateParameter(valid_599286, JString, required = false,
                                 default = nil)
  if valid_599286 != nil:
    section.add "X-Amz-Content-Sha256", valid_599286
  var valid_599287 = header.getOrDefault("X-Amz-Date")
  valid_599287 = validateParameter(valid_599287, JString, required = false,
                                 default = nil)
  if valid_599287 != nil:
    section.add "X-Amz-Date", valid_599287
  var valid_599288 = header.getOrDefault("X-Amz-Credential")
  valid_599288 = validateParameter(valid_599288, JString, required = false,
                                 default = nil)
  if valid_599288 != nil:
    section.add "X-Amz-Credential", valid_599288
  var valid_599289 = header.getOrDefault("X-Amz-Security-Token")
  valid_599289 = validateParameter(valid_599289, JString, required = false,
                                 default = nil)
  if valid_599289 != nil:
    section.add "X-Amz-Security-Token", valid_599289
  var valid_599290 = header.getOrDefault("X-Amz-Algorithm")
  valid_599290 = validateParameter(valid_599290, JString, required = false,
                                 default = nil)
  if valid_599290 != nil:
    section.add "X-Amz-Algorithm", valid_599290
  var valid_599291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599291 = validateParameter(valid_599291, JString, required = false,
                                 default = nil)
  if valid_599291 != nil:
    section.add "X-Amz-SignedHeaders", valid_599291
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599293: Call_ListComplianceSummaries_599281; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a summary count of compliant and non-compliant resources for a compliance type. For example, this call can return State Manager associations, patches, or custom compliance types according to the filter criteria that you specify. 
  ## 
  let valid = call_599293.validator(path, query, header, formData, body)
  let scheme = call_599293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599293.url(scheme.get, call_599293.host, call_599293.base,
                         call_599293.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599293, url, valid)

proc call*(call_599294: Call_ListComplianceSummaries_599281; body: JsonNode): Recallable =
  ## listComplianceSummaries
  ## Returns a summary count of compliant and non-compliant resources for a compliance type. For example, this call can return State Manager associations, patches, or custom compliance types according to the filter criteria that you specify. 
  ##   body: JObject (required)
  var body_599295 = newJObject()
  if body != nil:
    body_599295 = body
  result = call_599294.call(nil, nil, nil, nil, body_599295)

var listComplianceSummaries* = Call_ListComplianceSummaries_599281(
    name: "listComplianceSummaries", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListComplianceSummaries",
    validator: validate_ListComplianceSummaries_599282, base: "/",
    url: url_ListComplianceSummaries_599283, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDocumentVersions_599296 = ref object of OpenApiRestCall_597389
proc url_ListDocumentVersions_599298(protocol: Scheme; host: string; base: string;
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

proc validate_ListDocumentVersions_599297(path: JsonNode; query: JsonNode;
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
  var valid_599299 = header.getOrDefault("X-Amz-Target")
  valid_599299 = validateParameter(valid_599299, JString, required = true, default = newJString(
      "AmazonSSM.ListDocumentVersions"))
  if valid_599299 != nil:
    section.add "X-Amz-Target", valid_599299
  var valid_599300 = header.getOrDefault("X-Amz-Signature")
  valid_599300 = validateParameter(valid_599300, JString, required = false,
                                 default = nil)
  if valid_599300 != nil:
    section.add "X-Amz-Signature", valid_599300
  var valid_599301 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599301 = validateParameter(valid_599301, JString, required = false,
                                 default = nil)
  if valid_599301 != nil:
    section.add "X-Amz-Content-Sha256", valid_599301
  var valid_599302 = header.getOrDefault("X-Amz-Date")
  valid_599302 = validateParameter(valid_599302, JString, required = false,
                                 default = nil)
  if valid_599302 != nil:
    section.add "X-Amz-Date", valid_599302
  var valid_599303 = header.getOrDefault("X-Amz-Credential")
  valid_599303 = validateParameter(valid_599303, JString, required = false,
                                 default = nil)
  if valid_599303 != nil:
    section.add "X-Amz-Credential", valid_599303
  var valid_599304 = header.getOrDefault("X-Amz-Security-Token")
  valid_599304 = validateParameter(valid_599304, JString, required = false,
                                 default = nil)
  if valid_599304 != nil:
    section.add "X-Amz-Security-Token", valid_599304
  var valid_599305 = header.getOrDefault("X-Amz-Algorithm")
  valid_599305 = validateParameter(valid_599305, JString, required = false,
                                 default = nil)
  if valid_599305 != nil:
    section.add "X-Amz-Algorithm", valid_599305
  var valid_599306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599306 = validateParameter(valid_599306, JString, required = false,
                                 default = nil)
  if valid_599306 != nil:
    section.add "X-Amz-SignedHeaders", valid_599306
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599308: Call_ListDocumentVersions_599296; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all versions for a document.
  ## 
  let valid = call_599308.validator(path, query, header, formData, body)
  let scheme = call_599308.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599308.url(scheme.get, call_599308.host, call_599308.base,
                         call_599308.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599308, url, valid)

proc call*(call_599309: Call_ListDocumentVersions_599296; body: JsonNode): Recallable =
  ## listDocumentVersions
  ## List all versions for a document.
  ##   body: JObject (required)
  var body_599310 = newJObject()
  if body != nil:
    body_599310 = body
  result = call_599309.call(nil, nil, nil, nil, body_599310)

var listDocumentVersions* = Call_ListDocumentVersions_599296(
    name: "listDocumentVersions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListDocumentVersions",
    validator: validate_ListDocumentVersions_599297, base: "/",
    url: url_ListDocumentVersions_599298, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDocuments_599311 = ref object of OpenApiRestCall_597389
proc url_ListDocuments_599313(protocol: Scheme; host: string; base: string;
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

proc validate_ListDocuments_599312(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_599314 = query.getOrDefault("MaxResults")
  valid_599314 = validateParameter(valid_599314, JString, required = false,
                                 default = nil)
  if valid_599314 != nil:
    section.add "MaxResults", valid_599314
  var valid_599315 = query.getOrDefault("NextToken")
  valid_599315 = validateParameter(valid_599315, JString, required = false,
                                 default = nil)
  if valid_599315 != nil:
    section.add "NextToken", valid_599315
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_599316 = header.getOrDefault("X-Amz-Target")
  valid_599316 = validateParameter(valid_599316, JString, required = true, default = newJString(
      "AmazonSSM.ListDocuments"))
  if valid_599316 != nil:
    section.add "X-Amz-Target", valid_599316
  var valid_599317 = header.getOrDefault("X-Amz-Signature")
  valid_599317 = validateParameter(valid_599317, JString, required = false,
                                 default = nil)
  if valid_599317 != nil:
    section.add "X-Amz-Signature", valid_599317
  var valid_599318 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599318 = validateParameter(valid_599318, JString, required = false,
                                 default = nil)
  if valid_599318 != nil:
    section.add "X-Amz-Content-Sha256", valid_599318
  var valid_599319 = header.getOrDefault("X-Amz-Date")
  valid_599319 = validateParameter(valid_599319, JString, required = false,
                                 default = nil)
  if valid_599319 != nil:
    section.add "X-Amz-Date", valid_599319
  var valid_599320 = header.getOrDefault("X-Amz-Credential")
  valid_599320 = validateParameter(valid_599320, JString, required = false,
                                 default = nil)
  if valid_599320 != nil:
    section.add "X-Amz-Credential", valid_599320
  var valid_599321 = header.getOrDefault("X-Amz-Security-Token")
  valid_599321 = validateParameter(valid_599321, JString, required = false,
                                 default = nil)
  if valid_599321 != nil:
    section.add "X-Amz-Security-Token", valid_599321
  var valid_599322 = header.getOrDefault("X-Amz-Algorithm")
  valid_599322 = validateParameter(valid_599322, JString, required = false,
                                 default = nil)
  if valid_599322 != nil:
    section.add "X-Amz-Algorithm", valid_599322
  var valid_599323 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599323 = validateParameter(valid_599323, JString, required = false,
                                 default = nil)
  if valid_599323 != nil:
    section.add "X-Amz-SignedHeaders", valid_599323
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599325: Call_ListDocuments_599311; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes one or more of your Systems Manager documents.
  ## 
  let valid = call_599325.validator(path, query, header, formData, body)
  let scheme = call_599325.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599325.url(scheme.get, call_599325.host, call_599325.base,
                         call_599325.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599325, url, valid)

proc call*(call_599326: Call_ListDocuments_599311; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDocuments
  ## Describes one or more of your Systems Manager documents.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_599327 = newJObject()
  var body_599328 = newJObject()
  add(query_599327, "MaxResults", newJString(MaxResults))
  add(query_599327, "NextToken", newJString(NextToken))
  if body != nil:
    body_599328 = body
  result = call_599326.call(nil, query_599327, nil, nil, body_599328)

var listDocuments* = Call_ListDocuments_599311(name: "listDocuments",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListDocuments",
    validator: validate_ListDocuments_599312, base: "/", url: url_ListDocuments_599313,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInventoryEntries_599329 = ref object of OpenApiRestCall_597389
proc url_ListInventoryEntries_599331(protocol: Scheme; host: string; base: string;
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

proc validate_ListInventoryEntries_599330(path: JsonNode; query: JsonNode;
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
  var valid_599332 = header.getOrDefault("X-Amz-Target")
  valid_599332 = validateParameter(valid_599332, JString, required = true, default = newJString(
      "AmazonSSM.ListInventoryEntries"))
  if valid_599332 != nil:
    section.add "X-Amz-Target", valid_599332
  var valid_599333 = header.getOrDefault("X-Amz-Signature")
  valid_599333 = validateParameter(valid_599333, JString, required = false,
                                 default = nil)
  if valid_599333 != nil:
    section.add "X-Amz-Signature", valid_599333
  var valid_599334 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599334 = validateParameter(valid_599334, JString, required = false,
                                 default = nil)
  if valid_599334 != nil:
    section.add "X-Amz-Content-Sha256", valid_599334
  var valid_599335 = header.getOrDefault("X-Amz-Date")
  valid_599335 = validateParameter(valid_599335, JString, required = false,
                                 default = nil)
  if valid_599335 != nil:
    section.add "X-Amz-Date", valid_599335
  var valid_599336 = header.getOrDefault("X-Amz-Credential")
  valid_599336 = validateParameter(valid_599336, JString, required = false,
                                 default = nil)
  if valid_599336 != nil:
    section.add "X-Amz-Credential", valid_599336
  var valid_599337 = header.getOrDefault("X-Amz-Security-Token")
  valid_599337 = validateParameter(valid_599337, JString, required = false,
                                 default = nil)
  if valid_599337 != nil:
    section.add "X-Amz-Security-Token", valid_599337
  var valid_599338 = header.getOrDefault("X-Amz-Algorithm")
  valid_599338 = validateParameter(valid_599338, JString, required = false,
                                 default = nil)
  if valid_599338 != nil:
    section.add "X-Amz-Algorithm", valid_599338
  var valid_599339 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599339 = validateParameter(valid_599339, JString, required = false,
                                 default = nil)
  if valid_599339 != nil:
    section.add "X-Amz-SignedHeaders", valid_599339
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599341: Call_ListInventoryEntries_599329; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## A list of inventory items returned by the request.
  ## 
  let valid = call_599341.validator(path, query, header, formData, body)
  let scheme = call_599341.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599341.url(scheme.get, call_599341.host, call_599341.base,
                         call_599341.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599341, url, valid)

proc call*(call_599342: Call_ListInventoryEntries_599329; body: JsonNode): Recallable =
  ## listInventoryEntries
  ## A list of inventory items returned by the request.
  ##   body: JObject (required)
  var body_599343 = newJObject()
  if body != nil:
    body_599343 = body
  result = call_599342.call(nil, nil, nil, nil, body_599343)

var listInventoryEntries* = Call_ListInventoryEntries_599329(
    name: "listInventoryEntries", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListInventoryEntries",
    validator: validate_ListInventoryEntries_599330, base: "/",
    url: url_ListInventoryEntries_599331, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceComplianceSummaries_599344 = ref object of OpenApiRestCall_597389
proc url_ListResourceComplianceSummaries_599346(protocol: Scheme; host: string;
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

proc validate_ListResourceComplianceSummaries_599345(path: JsonNode;
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
  var valid_599347 = header.getOrDefault("X-Amz-Target")
  valid_599347 = validateParameter(valid_599347, JString, required = true, default = newJString(
      "AmazonSSM.ListResourceComplianceSummaries"))
  if valid_599347 != nil:
    section.add "X-Amz-Target", valid_599347
  var valid_599348 = header.getOrDefault("X-Amz-Signature")
  valid_599348 = validateParameter(valid_599348, JString, required = false,
                                 default = nil)
  if valid_599348 != nil:
    section.add "X-Amz-Signature", valid_599348
  var valid_599349 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599349 = validateParameter(valid_599349, JString, required = false,
                                 default = nil)
  if valid_599349 != nil:
    section.add "X-Amz-Content-Sha256", valid_599349
  var valid_599350 = header.getOrDefault("X-Amz-Date")
  valid_599350 = validateParameter(valid_599350, JString, required = false,
                                 default = nil)
  if valid_599350 != nil:
    section.add "X-Amz-Date", valid_599350
  var valid_599351 = header.getOrDefault("X-Amz-Credential")
  valid_599351 = validateParameter(valid_599351, JString, required = false,
                                 default = nil)
  if valid_599351 != nil:
    section.add "X-Amz-Credential", valid_599351
  var valid_599352 = header.getOrDefault("X-Amz-Security-Token")
  valid_599352 = validateParameter(valid_599352, JString, required = false,
                                 default = nil)
  if valid_599352 != nil:
    section.add "X-Amz-Security-Token", valid_599352
  var valid_599353 = header.getOrDefault("X-Amz-Algorithm")
  valid_599353 = validateParameter(valid_599353, JString, required = false,
                                 default = nil)
  if valid_599353 != nil:
    section.add "X-Amz-Algorithm", valid_599353
  var valid_599354 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599354 = validateParameter(valid_599354, JString, required = false,
                                 default = nil)
  if valid_599354 != nil:
    section.add "X-Amz-SignedHeaders", valid_599354
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599356: Call_ListResourceComplianceSummaries_599344;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a resource-level summary count. The summary includes information about compliant and non-compliant statuses and detailed compliance-item severity counts, according to the filter criteria you specify.
  ## 
  let valid = call_599356.validator(path, query, header, formData, body)
  let scheme = call_599356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599356.url(scheme.get, call_599356.host, call_599356.base,
                         call_599356.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599356, url, valid)

proc call*(call_599357: Call_ListResourceComplianceSummaries_599344; body: JsonNode): Recallable =
  ## listResourceComplianceSummaries
  ## Returns a resource-level summary count. The summary includes information about compliant and non-compliant statuses and detailed compliance-item severity counts, according to the filter criteria you specify.
  ##   body: JObject (required)
  var body_599358 = newJObject()
  if body != nil:
    body_599358 = body
  result = call_599357.call(nil, nil, nil, nil, body_599358)

var listResourceComplianceSummaries* = Call_ListResourceComplianceSummaries_599344(
    name: "listResourceComplianceSummaries", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListResourceComplianceSummaries",
    validator: validate_ListResourceComplianceSummaries_599345, base: "/",
    url: url_ListResourceComplianceSummaries_599346,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceDataSync_599359 = ref object of OpenApiRestCall_597389
proc url_ListResourceDataSync_599361(protocol: Scheme; host: string; base: string;
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

proc validate_ListResourceDataSync_599360(path: JsonNode; query: JsonNode;
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
  var valid_599362 = header.getOrDefault("X-Amz-Target")
  valid_599362 = validateParameter(valid_599362, JString, required = true, default = newJString(
      "AmazonSSM.ListResourceDataSync"))
  if valid_599362 != nil:
    section.add "X-Amz-Target", valid_599362
  var valid_599363 = header.getOrDefault("X-Amz-Signature")
  valid_599363 = validateParameter(valid_599363, JString, required = false,
                                 default = nil)
  if valid_599363 != nil:
    section.add "X-Amz-Signature", valid_599363
  var valid_599364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599364 = validateParameter(valid_599364, JString, required = false,
                                 default = nil)
  if valid_599364 != nil:
    section.add "X-Amz-Content-Sha256", valid_599364
  var valid_599365 = header.getOrDefault("X-Amz-Date")
  valid_599365 = validateParameter(valid_599365, JString, required = false,
                                 default = nil)
  if valid_599365 != nil:
    section.add "X-Amz-Date", valid_599365
  var valid_599366 = header.getOrDefault("X-Amz-Credential")
  valid_599366 = validateParameter(valid_599366, JString, required = false,
                                 default = nil)
  if valid_599366 != nil:
    section.add "X-Amz-Credential", valid_599366
  var valid_599367 = header.getOrDefault("X-Amz-Security-Token")
  valid_599367 = validateParameter(valid_599367, JString, required = false,
                                 default = nil)
  if valid_599367 != nil:
    section.add "X-Amz-Security-Token", valid_599367
  var valid_599368 = header.getOrDefault("X-Amz-Algorithm")
  valid_599368 = validateParameter(valid_599368, JString, required = false,
                                 default = nil)
  if valid_599368 != nil:
    section.add "X-Amz-Algorithm", valid_599368
  var valid_599369 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599369 = validateParameter(valid_599369, JString, required = false,
                                 default = nil)
  if valid_599369 != nil:
    section.add "X-Amz-SignedHeaders", valid_599369
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599371: Call_ListResourceDataSync_599359; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists your resource data sync configurations. Includes information about the last time a sync attempted to start, the last sync status, and the last time a sync successfully completed.</p> <p>The number of sync configurations might be too large to return using a single call to <code>ListResourceDataSync</code>. You can limit the number of sync configurations returned by using the <code>MaxResults</code> parameter. To determine whether there are more sync configurations to list, check the value of <code>NextToken</code> in the output. If there are more sync configurations to list, you can request them by specifying the <code>NextToken</code> returned in the call to the parameter of a subsequent call. </p>
  ## 
  let valid = call_599371.validator(path, query, header, formData, body)
  let scheme = call_599371.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599371.url(scheme.get, call_599371.host, call_599371.base,
                         call_599371.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599371, url, valid)

proc call*(call_599372: Call_ListResourceDataSync_599359; body: JsonNode): Recallable =
  ## listResourceDataSync
  ## <p>Lists your resource data sync configurations. Includes information about the last time a sync attempted to start, the last sync status, and the last time a sync successfully completed.</p> <p>The number of sync configurations might be too large to return using a single call to <code>ListResourceDataSync</code>. You can limit the number of sync configurations returned by using the <code>MaxResults</code> parameter. To determine whether there are more sync configurations to list, check the value of <code>NextToken</code> in the output. If there are more sync configurations to list, you can request them by specifying the <code>NextToken</code> returned in the call to the parameter of a subsequent call. </p>
  ##   body: JObject (required)
  var body_599373 = newJObject()
  if body != nil:
    body_599373 = body
  result = call_599372.call(nil, nil, nil, nil, body_599373)

var listResourceDataSync* = Call_ListResourceDataSync_599359(
    name: "listResourceDataSync", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListResourceDataSync",
    validator: validate_ListResourceDataSync_599360, base: "/",
    url: url_ListResourceDataSync_599361, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_599374 = ref object of OpenApiRestCall_597389
proc url_ListTagsForResource_599376(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_599375(path: JsonNode; query: JsonNode;
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
  var valid_599377 = header.getOrDefault("X-Amz-Target")
  valid_599377 = validateParameter(valid_599377, JString, required = true, default = newJString(
      "AmazonSSM.ListTagsForResource"))
  if valid_599377 != nil:
    section.add "X-Amz-Target", valid_599377
  var valid_599378 = header.getOrDefault("X-Amz-Signature")
  valid_599378 = validateParameter(valid_599378, JString, required = false,
                                 default = nil)
  if valid_599378 != nil:
    section.add "X-Amz-Signature", valid_599378
  var valid_599379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599379 = validateParameter(valid_599379, JString, required = false,
                                 default = nil)
  if valid_599379 != nil:
    section.add "X-Amz-Content-Sha256", valid_599379
  var valid_599380 = header.getOrDefault("X-Amz-Date")
  valid_599380 = validateParameter(valid_599380, JString, required = false,
                                 default = nil)
  if valid_599380 != nil:
    section.add "X-Amz-Date", valid_599380
  var valid_599381 = header.getOrDefault("X-Amz-Credential")
  valid_599381 = validateParameter(valid_599381, JString, required = false,
                                 default = nil)
  if valid_599381 != nil:
    section.add "X-Amz-Credential", valid_599381
  var valid_599382 = header.getOrDefault("X-Amz-Security-Token")
  valid_599382 = validateParameter(valid_599382, JString, required = false,
                                 default = nil)
  if valid_599382 != nil:
    section.add "X-Amz-Security-Token", valid_599382
  var valid_599383 = header.getOrDefault("X-Amz-Algorithm")
  valid_599383 = validateParameter(valid_599383, JString, required = false,
                                 default = nil)
  if valid_599383 != nil:
    section.add "X-Amz-Algorithm", valid_599383
  var valid_599384 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599384 = validateParameter(valid_599384, JString, required = false,
                                 default = nil)
  if valid_599384 != nil:
    section.add "X-Amz-SignedHeaders", valid_599384
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599386: Call_ListTagsForResource_599374; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the tags assigned to the specified resource.
  ## 
  let valid = call_599386.validator(path, query, header, formData, body)
  let scheme = call_599386.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599386.url(scheme.get, call_599386.host, call_599386.base,
                         call_599386.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599386, url, valid)

proc call*(call_599387: Call_ListTagsForResource_599374; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Returns a list of the tags assigned to the specified resource.
  ##   body: JObject (required)
  var body_599388 = newJObject()
  if body != nil:
    body_599388 = body
  result = call_599387.call(nil, nil, nil, nil, body_599388)

var listTagsForResource* = Call_ListTagsForResource_599374(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListTagsForResource",
    validator: validate_ListTagsForResource_599375, base: "/",
    url: url_ListTagsForResource_599376, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyDocumentPermission_599389 = ref object of OpenApiRestCall_597389
proc url_ModifyDocumentPermission_599391(protocol: Scheme; host: string;
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

proc validate_ModifyDocumentPermission_599390(path: JsonNode; query: JsonNode;
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
  var valid_599392 = header.getOrDefault("X-Amz-Target")
  valid_599392 = validateParameter(valid_599392, JString, required = true, default = newJString(
      "AmazonSSM.ModifyDocumentPermission"))
  if valid_599392 != nil:
    section.add "X-Amz-Target", valid_599392
  var valid_599393 = header.getOrDefault("X-Amz-Signature")
  valid_599393 = validateParameter(valid_599393, JString, required = false,
                                 default = nil)
  if valid_599393 != nil:
    section.add "X-Amz-Signature", valid_599393
  var valid_599394 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599394 = validateParameter(valid_599394, JString, required = false,
                                 default = nil)
  if valid_599394 != nil:
    section.add "X-Amz-Content-Sha256", valid_599394
  var valid_599395 = header.getOrDefault("X-Amz-Date")
  valid_599395 = validateParameter(valid_599395, JString, required = false,
                                 default = nil)
  if valid_599395 != nil:
    section.add "X-Amz-Date", valid_599395
  var valid_599396 = header.getOrDefault("X-Amz-Credential")
  valid_599396 = validateParameter(valid_599396, JString, required = false,
                                 default = nil)
  if valid_599396 != nil:
    section.add "X-Amz-Credential", valid_599396
  var valid_599397 = header.getOrDefault("X-Amz-Security-Token")
  valid_599397 = validateParameter(valid_599397, JString, required = false,
                                 default = nil)
  if valid_599397 != nil:
    section.add "X-Amz-Security-Token", valid_599397
  var valid_599398 = header.getOrDefault("X-Amz-Algorithm")
  valid_599398 = validateParameter(valid_599398, JString, required = false,
                                 default = nil)
  if valid_599398 != nil:
    section.add "X-Amz-Algorithm", valid_599398
  var valid_599399 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599399 = validateParameter(valid_599399, JString, required = false,
                                 default = nil)
  if valid_599399 != nil:
    section.add "X-Amz-SignedHeaders", valid_599399
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599401: Call_ModifyDocumentPermission_599389; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Shares a Systems Manager document publicly or privately. If you share a document privately, you must specify the AWS user account IDs for those people who can use the document. If you share a document publicly, you must specify <i>All</i> as the account ID.
  ## 
  let valid = call_599401.validator(path, query, header, formData, body)
  let scheme = call_599401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599401.url(scheme.get, call_599401.host, call_599401.base,
                         call_599401.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599401, url, valid)

proc call*(call_599402: Call_ModifyDocumentPermission_599389; body: JsonNode): Recallable =
  ## modifyDocumentPermission
  ## Shares a Systems Manager document publicly or privately. If you share a document privately, you must specify the AWS user account IDs for those people who can use the document. If you share a document publicly, you must specify <i>All</i> as the account ID.
  ##   body: JObject (required)
  var body_599403 = newJObject()
  if body != nil:
    body_599403 = body
  result = call_599402.call(nil, nil, nil, nil, body_599403)

var modifyDocumentPermission* = Call_ModifyDocumentPermission_599389(
    name: "modifyDocumentPermission", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ModifyDocumentPermission",
    validator: validate_ModifyDocumentPermission_599390, base: "/",
    url: url_ModifyDocumentPermission_599391, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutComplianceItems_599404 = ref object of OpenApiRestCall_597389
proc url_PutComplianceItems_599406(protocol: Scheme; host: string; base: string;
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

proc validate_PutComplianceItems_599405(path: JsonNode; query: JsonNode;
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
  var valid_599407 = header.getOrDefault("X-Amz-Target")
  valid_599407 = validateParameter(valid_599407, JString, required = true, default = newJString(
      "AmazonSSM.PutComplianceItems"))
  if valid_599407 != nil:
    section.add "X-Amz-Target", valid_599407
  var valid_599408 = header.getOrDefault("X-Amz-Signature")
  valid_599408 = validateParameter(valid_599408, JString, required = false,
                                 default = nil)
  if valid_599408 != nil:
    section.add "X-Amz-Signature", valid_599408
  var valid_599409 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599409 = validateParameter(valid_599409, JString, required = false,
                                 default = nil)
  if valid_599409 != nil:
    section.add "X-Amz-Content-Sha256", valid_599409
  var valid_599410 = header.getOrDefault("X-Amz-Date")
  valid_599410 = validateParameter(valid_599410, JString, required = false,
                                 default = nil)
  if valid_599410 != nil:
    section.add "X-Amz-Date", valid_599410
  var valid_599411 = header.getOrDefault("X-Amz-Credential")
  valid_599411 = validateParameter(valid_599411, JString, required = false,
                                 default = nil)
  if valid_599411 != nil:
    section.add "X-Amz-Credential", valid_599411
  var valid_599412 = header.getOrDefault("X-Amz-Security-Token")
  valid_599412 = validateParameter(valid_599412, JString, required = false,
                                 default = nil)
  if valid_599412 != nil:
    section.add "X-Amz-Security-Token", valid_599412
  var valid_599413 = header.getOrDefault("X-Amz-Algorithm")
  valid_599413 = validateParameter(valid_599413, JString, required = false,
                                 default = nil)
  if valid_599413 != nil:
    section.add "X-Amz-Algorithm", valid_599413
  var valid_599414 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599414 = validateParameter(valid_599414, JString, required = false,
                                 default = nil)
  if valid_599414 != nil:
    section.add "X-Amz-SignedHeaders", valid_599414
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599416: Call_PutComplianceItems_599404; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Registers a compliance type and other compliance details on a designated resource. This action lets you register custom compliance details with a resource. This call overwrites existing compliance information on the resource, so you must provide a full list of compliance items each time that you send the request.</p> <p>ComplianceType can be one of the following:</p> <ul> <li> <p>ExecutionId: The execution ID when the patch, association, or custom compliance item was applied.</p> </li> <li> <p>ExecutionType: Specify patch, association, or Custom:<code>string</code>.</p> </li> <li> <p>ExecutionTime. The time the patch, association, or custom compliance item was applied to the instance.</p> </li> <li> <p>Id: The patch, association, or custom compliance ID.</p> </li> <li> <p>Title: A title.</p> </li> <li> <p>Status: The status of the compliance item. For example, <code>approved</code> for patches, or <code>Failed</code> for associations.</p> </li> <li> <p>Severity: A patch severity. For example, <code>critical</code>.</p> </li> <li> <p>DocumentName: A SSM document name. For example, AWS-RunPatchBaseline.</p> </li> <li> <p>DocumentVersion: An SSM document version number. For example, 4.</p> </li> <li> <p>Classification: A patch classification. For example, <code>security updates</code>.</p> </li> <li> <p>PatchBaselineId: A patch baseline ID.</p> </li> <li> <p>PatchSeverity: A patch severity. For example, <code>Critical</code>.</p> </li> <li> <p>PatchState: A patch state. For example, <code>InstancesWithFailedPatches</code>.</p> </li> <li> <p>PatchGroup: The name of a patch group.</p> </li> <li> <p>InstalledTime: The time the association, patch, or custom compliance item was applied to the resource. Specify the time by using the following format: yyyy-MM-dd'T'HH:mm:ss'Z'</p> </li> </ul>
  ## 
  let valid = call_599416.validator(path, query, header, formData, body)
  let scheme = call_599416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599416.url(scheme.get, call_599416.host, call_599416.base,
                         call_599416.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599416, url, valid)

proc call*(call_599417: Call_PutComplianceItems_599404; body: JsonNode): Recallable =
  ## putComplianceItems
  ## <p>Registers a compliance type and other compliance details on a designated resource. This action lets you register custom compliance details with a resource. This call overwrites existing compliance information on the resource, so you must provide a full list of compliance items each time that you send the request.</p> <p>ComplianceType can be one of the following:</p> <ul> <li> <p>ExecutionId: The execution ID when the patch, association, or custom compliance item was applied.</p> </li> <li> <p>ExecutionType: Specify patch, association, or Custom:<code>string</code>.</p> </li> <li> <p>ExecutionTime. The time the patch, association, or custom compliance item was applied to the instance.</p> </li> <li> <p>Id: The patch, association, or custom compliance ID.</p> </li> <li> <p>Title: A title.</p> </li> <li> <p>Status: The status of the compliance item. For example, <code>approved</code> for patches, or <code>Failed</code> for associations.</p> </li> <li> <p>Severity: A patch severity. For example, <code>critical</code>.</p> </li> <li> <p>DocumentName: A SSM document name. For example, AWS-RunPatchBaseline.</p> </li> <li> <p>DocumentVersion: An SSM document version number. For example, 4.</p> </li> <li> <p>Classification: A patch classification. For example, <code>security updates</code>.</p> </li> <li> <p>PatchBaselineId: A patch baseline ID.</p> </li> <li> <p>PatchSeverity: A patch severity. For example, <code>Critical</code>.</p> </li> <li> <p>PatchState: A patch state. For example, <code>InstancesWithFailedPatches</code>.</p> </li> <li> <p>PatchGroup: The name of a patch group.</p> </li> <li> <p>InstalledTime: The time the association, patch, or custom compliance item was applied to the resource. Specify the time by using the following format: yyyy-MM-dd'T'HH:mm:ss'Z'</p> </li> </ul>
  ##   body: JObject (required)
  var body_599418 = newJObject()
  if body != nil:
    body_599418 = body
  result = call_599417.call(nil, nil, nil, nil, body_599418)

var putComplianceItems* = Call_PutComplianceItems_599404(
    name: "putComplianceItems", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.PutComplianceItems",
    validator: validate_PutComplianceItems_599405, base: "/",
    url: url_PutComplianceItems_599406, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutInventory_599419 = ref object of OpenApiRestCall_597389
proc url_PutInventory_599421(protocol: Scheme; host: string; base: string;
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

proc validate_PutInventory_599420(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_599422 = header.getOrDefault("X-Amz-Target")
  valid_599422 = validateParameter(valid_599422, JString, required = true,
                                 default = newJString("AmazonSSM.PutInventory"))
  if valid_599422 != nil:
    section.add "X-Amz-Target", valid_599422
  var valid_599423 = header.getOrDefault("X-Amz-Signature")
  valid_599423 = validateParameter(valid_599423, JString, required = false,
                                 default = nil)
  if valid_599423 != nil:
    section.add "X-Amz-Signature", valid_599423
  var valid_599424 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599424 = validateParameter(valid_599424, JString, required = false,
                                 default = nil)
  if valid_599424 != nil:
    section.add "X-Amz-Content-Sha256", valid_599424
  var valid_599425 = header.getOrDefault("X-Amz-Date")
  valid_599425 = validateParameter(valid_599425, JString, required = false,
                                 default = nil)
  if valid_599425 != nil:
    section.add "X-Amz-Date", valid_599425
  var valid_599426 = header.getOrDefault("X-Amz-Credential")
  valid_599426 = validateParameter(valid_599426, JString, required = false,
                                 default = nil)
  if valid_599426 != nil:
    section.add "X-Amz-Credential", valid_599426
  var valid_599427 = header.getOrDefault("X-Amz-Security-Token")
  valid_599427 = validateParameter(valid_599427, JString, required = false,
                                 default = nil)
  if valid_599427 != nil:
    section.add "X-Amz-Security-Token", valid_599427
  var valid_599428 = header.getOrDefault("X-Amz-Algorithm")
  valid_599428 = validateParameter(valid_599428, JString, required = false,
                                 default = nil)
  if valid_599428 != nil:
    section.add "X-Amz-Algorithm", valid_599428
  var valid_599429 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599429 = validateParameter(valid_599429, JString, required = false,
                                 default = nil)
  if valid_599429 != nil:
    section.add "X-Amz-SignedHeaders", valid_599429
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599431: Call_PutInventory_599419; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Bulk update custom inventory items on one more instance. The request adds an inventory item, if it doesn't already exist, or updates an inventory item, if it does exist.
  ## 
  let valid = call_599431.validator(path, query, header, formData, body)
  let scheme = call_599431.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599431.url(scheme.get, call_599431.host, call_599431.base,
                         call_599431.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599431, url, valid)

proc call*(call_599432: Call_PutInventory_599419; body: JsonNode): Recallable =
  ## putInventory
  ## Bulk update custom inventory items on one more instance. The request adds an inventory item, if it doesn't already exist, or updates an inventory item, if it does exist.
  ##   body: JObject (required)
  var body_599433 = newJObject()
  if body != nil:
    body_599433 = body
  result = call_599432.call(nil, nil, nil, nil, body_599433)

var putInventory* = Call_PutInventory_599419(name: "putInventory",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.PutInventory",
    validator: validate_PutInventory_599420, base: "/", url: url_PutInventory_599421,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutParameter_599434 = ref object of OpenApiRestCall_597389
proc url_PutParameter_599436(protocol: Scheme; host: string; base: string;
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

proc validate_PutParameter_599435(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_599437 = header.getOrDefault("X-Amz-Target")
  valid_599437 = validateParameter(valid_599437, JString, required = true,
                                 default = newJString("AmazonSSM.PutParameter"))
  if valid_599437 != nil:
    section.add "X-Amz-Target", valid_599437
  var valid_599438 = header.getOrDefault("X-Amz-Signature")
  valid_599438 = validateParameter(valid_599438, JString, required = false,
                                 default = nil)
  if valid_599438 != nil:
    section.add "X-Amz-Signature", valid_599438
  var valid_599439 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599439 = validateParameter(valid_599439, JString, required = false,
                                 default = nil)
  if valid_599439 != nil:
    section.add "X-Amz-Content-Sha256", valid_599439
  var valid_599440 = header.getOrDefault("X-Amz-Date")
  valid_599440 = validateParameter(valid_599440, JString, required = false,
                                 default = nil)
  if valid_599440 != nil:
    section.add "X-Amz-Date", valid_599440
  var valid_599441 = header.getOrDefault("X-Amz-Credential")
  valid_599441 = validateParameter(valid_599441, JString, required = false,
                                 default = nil)
  if valid_599441 != nil:
    section.add "X-Amz-Credential", valid_599441
  var valid_599442 = header.getOrDefault("X-Amz-Security-Token")
  valid_599442 = validateParameter(valid_599442, JString, required = false,
                                 default = nil)
  if valid_599442 != nil:
    section.add "X-Amz-Security-Token", valid_599442
  var valid_599443 = header.getOrDefault("X-Amz-Algorithm")
  valid_599443 = validateParameter(valid_599443, JString, required = false,
                                 default = nil)
  if valid_599443 != nil:
    section.add "X-Amz-Algorithm", valid_599443
  var valid_599444 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599444 = validateParameter(valid_599444, JString, required = false,
                                 default = nil)
  if valid_599444 != nil:
    section.add "X-Amz-SignedHeaders", valid_599444
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599446: Call_PutParameter_599434; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Add a parameter to the system.
  ## 
  let valid = call_599446.validator(path, query, header, formData, body)
  let scheme = call_599446.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599446.url(scheme.get, call_599446.host, call_599446.base,
                         call_599446.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599446, url, valid)

proc call*(call_599447: Call_PutParameter_599434; body: JsonNode): Recallable =
  ## putParameter
  ## Add a parameter to the system.
  ##   body: JObject (required)
  var body_599448 = newJObject()
  if body != nil:
    body_599448 = body
  result = call_599447.call(nil, nil, nil, nil, body_599448)

var putParameter* = Call_PutParameter_599434(name: "putParameter",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.PutParameter",
    validator: validate_PutParameter_599435, base: "/", url: url_PutParameter_599436,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterDefaultPatchBaseline_599449 = ref object of OpenApiRestCall_597389
proc url_RegisterDefaultPatchBaseline_599451(protocol: Scheme; host: string;
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

proc validate_RegisterDefaultPatchBaseline_599450(path: JsonNode; query: JsonNode;
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
  var valid_599452 = header.getOrDefault("X-Amz-Target")
  valid_599452 = validateParameter(valid_599452, JString, required = true, default = newJString(
      "AmazonSSM.RegisterDefaultPatchBaseline"))
  if valid_599452 != nil:
    section.add "X-Amz-Target", valid_599452
  var valid_599453 = header.getOrDefault("X-Amz-Signature")
  valid_599453 = validateParameter(valid_599453, JString, required = false,
                                 default = nil)
  if valid_599453 != nil:
    section.add "X-Amz-Signature", valid_599453
  var valid_599454 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599454 = validateParameter(valid_599454, JString, required = false,
                                 default = nil)
  if valid_599454 != nil:
    section.add "X-Amz-Content-Sha256", valid_599454
  var valid_599455 = header.getOrDefault("X-Amz-Date")
  valid_599455 = validateParameter(valid_599455, JString, required = false,
                                 default = nil)
  if valid_599455 != nil:
    section.add "X-Amz-Date", valid_599455
  var valid_599456 = header.getOrDefault("X-Amz-Credential")
  valid_599456 = validateParameter(valid_599456, JString, required = false,
                                 default = nil)
  if valid_599456 != nil:
    section.add "X-Amz-Credential", valid_599456
  var valid_599457 = header.getOrDefault("X-Amz-Security-Token")
  valid_599457 = validateParameter(valid_599457, JString, required = false,
                                 default = nil)
  if valid_599457 != nil:
    section.add "X-Amz-Security-Token", valid_599457
  var valid_599458 = header.getOrDefault("X-Amz-Algorithm")
  valid_599458 = validateParameter(valid_599458, JString, required = false,
                                 default = nil)
  if valid_599458 != nil:
    section.add "X-Amz-Algorithm", valid_599458
  var valid_599459 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599459 = validateParameter(valid_599459, JString, required = false,
                                 default = nil)
  if valid_599459 != nil:
    section.add "X-Amz-SignedHeaders", valid_599459
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599461: Call_RegisterDefaultPatchBaseline_599449; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Defines the default patch baseline for the relevant operating system.</p> <p>To reset the AWS predefined patch baseline as the default, specify the full patch baseline ARN as the baseline ID value. For example, for CentOS, specify <code>arn:aws:ssm:us-east-2:733109147000:patchbaseline/pb-0574b43a65ea646ed</code> instead of <code>pb-0574b43a65ea646ed</code>.</p>
  ## 
  let valid = call_599461.validator(path, query, header, formData, body)
  let scheme = call_599461.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599461.url(scheme.get, call_599461.host, call_599461.base,
                         call_599461.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599461, url, valid)

proc call*(call_599462: Call_RegisterDefaultPatchBaseline_599449; body: JsonNode): Recallable =
  ## registerDefaultPatchBaseline
  ## <p>Defines the default patch baseline for the relevant operating system.</p> <p>To reset the AWS predefined patch baseline as the default, specify the full patch baseline ARN as the baseline ID value. For example, for CentOS, specify <code>arn:aws:ssm:us-east-2:733109147000:patchbaseline/pb-0574b43a65ea646ed</code> instead of <code>pb-0574b43a65ea646ed</code>.</p>
  ##   body: JObject (required)
  var body_599463 = newJObject()
  if body != nil:
    body_599463 = body
  result = call_599462.call(nil, nil, nil, nil, body_599463)

var registerDefaultPatchBaseline* = Call_RegisterDefaultPatchBaseline_599449(
    name: "registerDefaultPatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.RegisterDefaultPatchBaseline",
    validator: validate_RegisterDefaultPatchBaseline_599450, base: "/",
    url: url_RegisterDefaultPatchBaseline_599451,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterPatchBaselineForPatchGroup_599464 = ref object of OpenApiRestCall_597389
proc url_RegisterPatchBaselineForPatchGroup_599466(protocol: Scheme; host: string;
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

proc validate_RegisterPatchBaselineForPatchGroup_599465(path: JsonNode;
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
  var valid_599467 = header.getOrDefault("X-Amz-Target")
  valid_599467 = validateParameter(valid_599467, JString, required = true, default = newJString(
      "AmazonSSM.RegisterPatchBaselineForPatchGroup"))
  if valid_599467 != nil:
    section.add "X-Amz-Target", valid_599467
  var valid_599468 = header.getOrDefault("X-Amz-Signature")
  valid_599468 = validateParameter(valid_599468, JString, required = false,
                                 default = nil)
  if valid_599468 != nil:
    section.add "X-Amz-Signature", valid_599468
  var valid_599469 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599469 = validateParameter(valid_599469, JString, required = false,
                                 default = nil)
  if valid_599469 != nil:
    section.add "X-Amz-Content-Sha256", valid_599469
  var valid_599470 = header.getOrDefault("X-Amz-Date")
  valid_599470 = validateParameter(valid_599470, JString, required = false,
                                 default = nil)
  if valid_599470 != nil:
    section.add "X-Amz-Date", valid_599470
  var valid_599471 = header.getOrDefault("X-Amz-Credential")
  valid_599471 = validateParameter(valid_599471, JString, required = false,
                                 default = nil)
  if valid_599471 != nil:
    section.add "X-Amz-Credential", valid_599471
  var valid_599472 = header.getOrDefault("X-Amz-Security-Token")
  valid_599472 = validateParameter(valid_599472, JString, required = false,
                                 default = nil)
  if valid_599472 != nil:
    section.add "X-Amz-Security-Token", valid_599472
  var valid_599473 = header.getOrDefault("X-Amz-Algorithm")
  valid_599473 = validateParameter(valid_599473, JString, required = false,
                                 default = nil)
  if valid_599473 != nil:
    section.add "X-Amz-Algorithm", valid_599473
  var valid_599474 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599474 = validateParameter(valid_599474, JString, required = false,
                                 default = nil)
  if valid_599474 != nil:
    section.add "X-Amz-SignedHeaders", valid_599474
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599476: Call_RegisterPatchBaselineForPatchGroup_599464;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Registers a patch baseline for a patch group.
  ## 
  let valid = call_599476.validator(path, query, header, formData, body)
  let scheme = call_599476.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599476.url(scheme.get, call_599476.host, call_599476.base,
                         call_599476.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599476, url, valid)

proc call*(call_599477: Call_RegisterPatchBaselineForPatchGroup_599464;
          body: JsonNode): Recallable =
  ## registerPatchBaselineForPatchGroup
  ## Registers a patch baseline for a patch group.
  ##   body: JObject (required)
  var body_599478 = newJObject()
  if body != nil:
    body_599478 = body
  result = call_599477.call(nil, nil, nil, nil, body_599478)

var registerPatchBaselineForPatchGroup* = Call_RegisterPatchBaselineForPatchGroup_599464(
    name: "registerPatchBaselineForPatchGroup", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.RegisterPatchBaselineForPatchGroup",
    validator: validate_RegisterPatchBaselineForPatchGroup_599465, base: "/",
    url: url_RegisterPatchBaselineForPatchGroup_599466,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterTargetWithMaintenanceWindow_599479 = ref object of OpenApiRestCall_597389
proc url_RegisterTargetWithMaintenanceWindow_599481(protocol: Scheme; host: string;
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

proc validate_RegisterTargetWithMaintenanceWindow_599480(path: JsonNode;
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
  var valid_599482 = header.getOrDefault("X-Amz-Target")
  valid_599482 = validateParameter(valid_599482, JString, required = true, default = newJString(
      "AmazonSSM.RegisterTargetWithMaintenanceWindow"))
  if valid_599482 != nil:
    section.add "X-Amz-Target", valid_599482
  var valid_599483 = header.getOrDefault("X-Amz-Signature")
  valid_599483 = validateParameter(valid_599483, JString, required = false,
                                 default = nil)
  if valid_599483 != nil:
    section.add "X-Amz-Signature", valid_599483
  var valid_599484 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599484 = validateParameter(valid_599484, JString, required = false,
                                 default = nil)
  if valid_599484 != nil:
    section.add "X-Amz-Content-Sha256", valid_599484
  var valid_599485 = header.getOrDefault("X-Amz-Date")
  valid_599485 = validateParameter(valid_599485, JString, required = false,
                                 default = nil)
  if valid_599485 != nil:
    section.add "X-Amz-Date", valid_599485
  var valid_599486 = header.getOrDefault("X-Amz-Credential")
  valid_599486 = validateParameter(valid_599486, JString, required = false,
                                 default = nil)
  if valid_599486 != nil:
    section.add "X-Amz-Credential", valid_599486
  var valid_599487 = header.getOrDefault("X-Amz-Security-Token")
  valid_599487 = validateParameter(valid_599487, JString, required = false,
                                 default = nil)
  if valid_599487 != nil:
    section.add "X-Amz-Security-Token", valid_599487
  var valid_599488 = header.getOrDefault("X-Amz-Algorithm")
  valid_599488 = validateParameter(valid_599488, JString, required = false,
                                 default = nil)
  if valid_599488 != nil:
    section.add "X-Amz-Algorithm", valid_599488
  var valid_599489 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599489 = validateParameter(valid_599489, JString, required = false,
                                 default = nil)
  if valid_599489 != nil:
    section.add "X-Amz-SignedHeaders", valid_599489
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599491: Call_RegisterTargetWithMaintenanceWindow_599479;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Registers a target with a maintenance window.
  ## 
  let valid = call_599491.validator(path, query, header, formData, body)
  let scheme = call_599491.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599491.url(scheme.get, call_599491.host, call_599491.base,
                         call_599491.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599491, url, valid)

proc call*(call_599492: Call_RegisterTargetWithMaintenanceWindow_599479;
          body: JsonNode): Recallable =
  ## registerTargetWithMaintenanceWindow
  ## Registers a target with a maintenance window.
  ##   body: JObject (required)
  var body_599493 = newJObject()
  if body != nil:
    body_599493 = body
  result = call_599492.call(nil, nil, nil, nil, body_599493)

var registerTargetWithMaintenanceWindow* = Call_RegisterTargetWithMaintenanceWindow_599479(
    name: "registerTargetWithMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.RegisterTargetWithMaintenanceWindow",
    validator: validate_RegisterTargetWithMaintenanceWindow_599480, base: "/",
    url: url_RegisterTargetWithMaintenanceWindow_599481,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterTaskWithMaintenanceWindow_599494 = ref object of OpenApiRestCall_597389
proc url_RegisterTaskWithMaintenanceWindow_599496(protocol: Scheme; host: string;
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

proc validate_RegisterTaskWithMaintenanceWindow_599495(path: JsonNode;
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
  var valid_599497 = header.getOrDefault("X-Amz-Target")
  valid_599497 = validateParameter(valid_599497, JString, required = true, default = newJString(
      "AmazonSSM.RegisterTaskWithMaintenanceWindow"))
  if valid_599497 != nil:
    section.add "X-Amz-Target", valid_599497
  var valid_599498 = header.getOrDefault("X-Amz-Signature")
  valid_599498 = validateParameter(valid_599498, JString, required = false,
                                 default = nil)
  if valid_599498 != nil:
    section.add "X-Amz-Signature", valid_599498
  var valid_599499 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599499 = validateParameter(valid_599499, JString, required = false,
                                 default = nil)
  if valid_599499 != nil:
    section.add "X-Amz-Content-Sha256", valid_599499
  var valid_599500 = header.getOrDefault("X-Amz-Date")
  valid_599500 = validateParameter(valid_599500, JString, required = false,
                                 default = nil)
  if valid_599500 != nil:
    section.add "X-Amz-Date", valid_599500
  var valid_599501 = header.getOrDefault("X-Amz-Credential")
  valid_599501 = validateParameter(valid_599501, JString, required = false,
                                 default = nil)
  if valid_599501 != nil:
    section.add "X-Amz-Credential", valid_599501
  var valid_599502 = header.getOrDefault("X-Amz-Security-Token")
  valid_599502 = validateParameter(valid_599502, JString, required = false,
                                 default = nil)
  if valid_599502 != nil:
    section.add "X-Amz-Security-Token", valid_599502
  var valid_599503 = header.getOrDefault("X-Amz-Algorithm")
  valid_599503 = validateParameter(valid_599503, JString, required = false,
                                 default = nil)
  if valid_599503 != nil:
    section.add "X-Amz-Algorithm", valid_599503
  var valid_599504 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599504 = validateParameter(valid_599504, JString, required = false,
                                 default = nil)
  if valid_599504 != nil:
    section.add "X-Amz-SignedHeaders", valid_599504
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599506: Call_RegisterTaskWithMaintenanceWindow_599494;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Adds a new task to a maintenance window.
  ## 
  let valid = call_599506.validator(path, query, header, formData, body)
  let scheme = call_599506.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599506.url(scheme.get, call_599506.host, call_599506.base,
                         call_599506.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599506, url, valid)

proc call*(call_599507: Call_RegisterTaskWithMaintenanceWindow_599494;
          body: JsonNode): Recallable =
  ## registerTaskWithMaintenanceWindow
  ## Adds a new task to a maintenance window.
  ##   body: JObject (required)
  var body_599508 = newJObject()
  if body != nil:
    body_599508 = body
  result = call_599507.call(nil, nil, nil, nil, body_599508)

var registerTaskWithMaintenanceWindow* = Call_RegisterTaskWithMaintenanceWindow_599494(
    name: "registerTaskWithMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.RegisterTaskWithMaintenanceWindow",
    validator: validate_RegisterTaskWithMaintenanceWindow_599495, base: "/",
    url: url_RegisterTaskWithMaintenanceWindow_599496,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveTagsFromResource_599509 = ref object of OpenApiRestCall_597389
proc url_RemoveTagsFromResource_599511(protocol: Scheme; host: string; base: string;
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

proc validate_RemoveTagsFromResource_599510(path: JsonNode; query: JsonNode;
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
  var valid_599512 = header.getOrDefault("X-Amz-Target")
  valid_599512 = validateParameter(valid_599512, JString, required = true, default = newJString(
      "AmazonSSM.RemoveTagsFromResource"))
  if valid_599512 != nil:
    section.add "X-Amz-Target", valid_599512
  var valid_599513 = header.getOrDefault("X-Amz-Signature")
  valid_599513 = validateParameter(valid_599513, JString, required = false,
                                 default = nil)
  if valid_599513 != nil:
    section.add "X-Amz-Signature", valid_599513
  var valid_599514 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599514 = validateParameter(valid_599514, JString, required = false,
                                 default = nil)
  if valid_599514 != nil:
    section.add "X-Amz-Content-Sha256", valid_599514
  var valid_599515 = header.getOrDefault("X-Amz-Date")
  valid_599515 = validateParameter(valid_599515, JString, required = false,
                                 default = nil)
  if valid_599515 != nil:
    section.add "X-Amz-Date", valid_599515
  var valid_599516 = header.getOrDefault("X-Amz-Credential")
  valid_599516 = validateParameter(valid_599516, JString, required = false,
                                 default = nil)
  if valid_599516 != nil:
    section.add "X-Amz-Credential", valid_599516
  var valid_599517 = header.getOrDefault("X-Amz-Security-Token")
  valid_599517 = validateParameter(valid_599517, JString, required = false,
                                 default = nil)
  if valid_599517 != nil:
    section.add "X-Amz-Security-Token", valid_599517
  var valid_599518 = header.getOrDefault("X-Amz-Algorithm")
  valid_599518 = validateParameter(valid_599518, JString, required = false,
                                 default = nil)
  if valid_599518 != nil:
    section.add "X-Amz-Algorithm", valid_599518
  var valid_599519 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599519 = validateParameter(valid_599519, JString, required = false,
                                 default = nil)
  if valid_599519 != nil:
    section.add "X-Amz-SignedHeaders", valid_599519
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599521: Call_RemoveTagsFromResource_599509; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tag keys from the specified resource.
  ## 
  let valid = call_599521.validator(path, query, header, formData, body)
  let scheme = call_599521.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599521.url(scheme.get, call_599521.host, call_599521.base,
                         call_599521.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599521, url, valid)

proc call*(call_599522: Call_RemoveTagsFromResource_599509; body: JsonNode): Recallable =
  ## removeTagsFromResource
  ## Removes tag keys from the specified resource.
  ##   body: JObject (required)
  var body_599523 = newJObject()
  if body != nil:
    body_599523 = body
  result = call_599522.call(nil, nil, nil, nil, body_599523)

var removeTagsFromResource* = Call_RemoveTagsFromResource_599509(
    name: "removeTagsFromResource", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.RemoveTagsFromResource",
    validator: validate_RemoveTagsFromResource_599510, base: "/",
    url: url_RemoveTagsFromResource_599511, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResetServiceSetting_599524 = ref object of OpenApiRestCall_597389
proc url_ResetServiceSetting_599526(protocol: Scheme; host: string; base: string;
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

proc validate_ResetServiceSetting_599525(path: JsonNode; query: JsonNode;
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
  var valid_599527 = header.getOrDefault("X-Amz-Target")
  valid_599527 = validateParameter(valid_599527, JString, required = true, default = newJString(
      "AmazonSSM.ResetServiceSetting"))
  if valid_599527 != nil:
    section.add "X-Amz-Target", valid_599527
  var valid_599528 = header.getOrDefault("X-Amz-Signature")
  valid_599528 = validateParameter(valid_599528, JString, required = false,
                                 default = nil)
  if valid_599528 != nil:
    section.add "X-Amz-Signature", valid_599528
  var valid_599529 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599529 = validateParameter(valid_599529, JString, required = false,
                                 default = nil)
  if valid_599529 != nil:
    section.add "X-Amz-Content-Sha256", valid_599529
  var valid_599530 = header.getOrDefault("X-Amz-Date")
  valid_599530 = validateParameter(valid_599530, JString, required = false,
                                 default = nil)
  if valid_599530 != nil:
    section.add "X-Amz-Date", valid_599530
  var valid_599531 = header.getOrDefault("X-Amz-Credential")
  valid_599531 = validateParameter(valid_599531, JString, required = false,
                                 default = nil)
  if valid_599531 != nil:
    section.add "X-Amz-Credential", valid_599531
  var valid_599532 = header.getOrDefault("X-Amz-Security-Token")
  valid_599532 = validateParameter(valid_599532, JString, required = false,
                                 default = nil)
  if valid_599532 != nil:
    section.add "X-Amz-Security-Token", valid_599532
  var valid_599533 = header.getOrDefault("X-Amz-Algorithm")
  valid_599533 = validateParameter(valid_599533, JString, required = false,
                                 default = nil)
  if valid_599533 != nil:
    section.add "X-Amz-Algorithm", valid_599533
  var valid_599534 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599534 = validateParameter(valid_599534, JString, required = false,
                                 default = nil)
  if valid_599534 != nil:
    section.add "X-Amz-SignedHeaders", valid_599534
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599536: Call_ResetServiceSetting_599524; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>GetServiceSetting</a> API action to view the current value. Use the <a>UpdateServiceSetting</a> API action to change the default setting. </p> <p>Reset the service setting for the account to the default value as provisioned by the AWS service team. </p>
  ## 
  let valid = call_599536.validator(path, query, header, formData, body)
  let scheme = call_599536.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599536.url(scheme.get, call_599536.host, call_599536.base,
                         call_599536.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599536, url, valid)

proc call*(call_599537: Call_ResetServiceSetting_599524; body: JsonNode): Recallable =
  ## resetServiceSetting
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>GetServiceSetting</a> API action to view the current value. Use the <a>UpdateServiceSetting</a> API action to change the default setting. </p> <p>Reset the service setting for the account to the default value as provisioned by the AWS service team. </p>
  ##   body: JObject (required)
  var body_599538 = newJObject()
  if body != nil:
    body_599538 = body
  result = call_599537.call(nil, nil, nil, nil, body_599538)

var resetServiceSetting* = Call_ResetServiceSetting_599524(
    name: "resetServiceSetting", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ResetServiceSetting",
    validator: validate_ResetServiceSetting_599525, base: "/",
    url: url_ResetServiceSetting_599526, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResumeSession_599539 = ref object of OpenApiRestCall_597389
proc url_ResumeSession_599541(protocol: Scheme; host: string; base: string;
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

proc validate_ResumeSession_599540(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_599542 = header.getOrDefault("X-Amz-Target")
  valid_599542 = validateParameter(valid_599542, JString, required = true, default = newJString(
      "AmazonSSM.ResumeSession"))
  if valid_599542 != nil:
    section.add "X-Amz-Target", valid_599542
  var valid_599543 = header.getOrDefault("X-Amz-Signature")
  valid_599543 = validateParameter(valid_599543, JString, required = false,
                                 default = nil)
  if valid_599543 != nil:
    section.add "X-Amz-Signature", valid_599543
  var valid_599544 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599544 = validateParameter(valid_599544, JString, required = false,
                                 default = nil)
  if valid_599544 != nil:
    section.add "X-Amz-Content-Sha256", valid_599544
  var valid_599545 = header.getOrDefault("X-Amz-Date")
  valid_599545 = validateParameter(valid_599545, JString, required = false,
                                 default = nil)
  if valid_599545 != nil:
    section.add "X-Amz-Date", valid_599545
  var valid_599546 = header.getOrDefault("X-Amz-Credential")
  valid_599546 = validateParameter(valid_599546, JString, required = false,
                                 default = nil)
  if valid_599546 != nil:
    section.add "X-Amz-Credential", valid_599546
  var valid_599547 = header.getOrDefault("X-Amz-Security-Token")
  valid_599547 = validateParameter(valid_599547, JString, required = false,
                                 default = nil)
  if valid_599547 != nil:
    section.add "X-Amz-Security-Token", valid_599547
  var valid_599548 = header.getOrDefault("X-Amz-Algorithm")
  valid_599548 = validateParameter(valid_599548, JString, required = false,
                                 default = nil)
  if valid_599548 != nil:
    section.add "X-Amz-Algorithm", valid_599548
  var valid_599549 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599549 = validateParameter(valid_599549, JString, required = false,
                                 default = nil)
  if valid_599549 != nil:
    section.add "X-Amz-SignedHeaders", valid_599549
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599551: Call_ResumeSession_599539; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Reconnects a session to an instance after it has been disconnected. Connections can be resumed for disconnected sessions, but not terminated sessions.</p> <note> <p>This command is primarily for use by client machines to automatically reconnect during intermittent network issues. It is not intended for any other use.</p> </note>
  ## 
  let valid = call_599551.validator(path, query, header, formData, body)
  let scheme = call_599551.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599551.url(scheme.get, call_599551.host, call_599551.base,
                         call_599551.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599551, url, valid)

proc call*(call_599552: Call_ResumeSession_599539; body: JsonNode): Recallable =
  ## resumeSession
  ## <p>Reconnects a session to an instance after it has been disconnected. Connections can be resumed for disconnected sessions, but not terminated sessions.</p> <note> <p>This command is primarily for use by client machines to automatically reconnect during intermittent network issues. It is not intended for any other use.</p> </note>
  ##   body: JObject (required)
  var body_599553 = newJObject()
  if body != nil:
    body_599553 = body
  result = call_599552.call(nil, nil, nil, nil, body_599553)

var resumeSession* = Call_ResumeSession_599539(name: "resumeSession",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ResumeSession",
    validator: validate_ResumeSession_599540, base: "/", url: url_ResumeSession_599541,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendAutomationSignal_599554 = ref object of OpenApiRestCall_597389
proc url_SendAutomationSignal_599556(protocol: Scheme; host: string; base: string;
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

proc validate_SendAutomationSignal_599555(path: JsonNode; query: JsonNode;
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
  var valid_599557 = header.getOrDefault("X-Amz-Target")
  valid_599557 = validateParameter(valid_599557, JString, required = true, default = newJString(
      "AmazonSSM.SendAutomationSignal"))
  if valid_599557 != nil:
    section.add "X-Amz-Target", valid_599557
  var valid_599558 = header.getOrDefault("X-Amz-Signature")
  valid_599558 = validateParameter(valid_599558, JString, required = false,
                                 default = nil)
  if valid_599558 != nil:
    section.add "X-Amz-Signature", valid_599558
  var valid_599559 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599559 = validateParameter(valid_599559, JString, required = false,
                                 default = nil)
  if valid_599559 != nil:
    section.add "X-Amz-Content-Sha256", valid_599559
  var valid_599560 = header.getOrDefault("X-Amz-Date")
  valid_599560 = validateParameter(valid_599560, JString, required = false,
                                 default = nil)
  if valid_599560 != nil:
    section.add "X-Amz-Date", valid_599560
  var valid_599561 = header.getOrDefault("X-Amz-Credential")
  valid_599561 = validateParameter(valid_599561, JString, required = false,
                                 default = nil)
  if valid_599561 != nil:
    section.add "X-Amz-Credential", valid_599561
  var valid_599562 = header.getOrDefault("X-Amz-Security-Token")
  valid_599562 = validateParameter(valid_599562, JString, required = false,
                                 default = nil)
  if valid_599562 != nil:
    section.add "X-Amz-Security-Token", valid_599562
  var valid_599563 = header.getOrDefault("X-Amz-Algorithm")
  valid_599563 = validateParameter(valid_599563, JString, required = false,
                                 default = nil)
  if valid_599563 != nil:
    section.add "X-Amz-Algorithm", valid_599563
  var valid_599564 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599564 = validateParameter(valid_599564, JString, required = false,
                                 default = nil)
  if valid_599564 != nil:
    section.add "X-Amz-SignedHeaders", valid_599564
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599566: Call_SendAutomationSignal_599554; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sends a signal to an Automation execution to change the current behavior or status of the execution. 
  ## 
  let valid = call_599566.validator(path, query, header, formData, body)
  let scheme = call_599566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599566.url(scheme.get, call_599566.host, call_599566.base,
                         call_599566.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599566, url, valid)

proc call*(call_599567: Call_SendAutomationSignal_599554; body: JsonNode): Recallable =
  ## sendAutomationSignal
  ## Sends a signal to an Automation execution to change the current behavior or status of the execution. 
  ##   body: JObject (required)
  var body_599568 = newJObject()
  if body != nil:
    body_599568 = body
  result = call_599567.call(nil, nil, nil, nil, body_599568)

var sendAutomationSignal* = Call_SendAutomationSignal_599554(
    name: "sendAutomationSignal", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.SendAutomationSignal",
    validator: validate_SendAutomationSignal_599555, base: "/",
    url: url_SendAutomationSignal_599556, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendCommand_599569 = ref object of OpenApiRestCall_597389
proc url_SendCommand_599571(protocol: Scheme; host: string; base: string;
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

proc validate_SendCommand_599570(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_599572 = header.getOrDefault("X-Amz-Target")
  valid_599572 = validateParameter(valid_599572, JString, required = true,
                                 default = newJString("AmazonSSM.SendCommand"))
  if valid_599572 != nil:
    section.add "X-Amz-Target", valid_599572
  var valid_599573 = header.getOrDefault("X-Amz-Signature")
  valid_599573 = validateParameter(valid_599573, JString, required = false,
                                 default = nil)
  if valid_599573 != nil:
    section.add "X-Amz-Signature", valid_599573
  var valid_599574 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599574 = validateParameter(valid_599574, JString, required = false,
                                 default = nil)
  if valid_599574 != nil:
    section.add "X-Amz-Content-Sha256", valid_599574
  var valid_599575 = header.getOrDefault("X-Amz-Date")
  valid_599575 = validateParameter(valid_599575, JString, required = false,
                                 default = nil)
  if valid_599575 != nil:
    section.add "X-Amz-Date", valid_599575
  var valid_599576 = header.getOrDefault("X-Amz-Credential")
  valid_599576 = validateParameter(valid_599576, JString, required = false,
                                 default = nil)
  if valid_599576 != nil:
    section.add "X-Amz-Credential", valid_599576
  var valid_599577 = header.getOrDefault("X-Amz-Security-Token")
  valid_599577 = validateParameter(valid_599577, JString, required = false,
                                 default = nil)
  if valid_599577 != nil:
    section.add "X-Amz-Security-Token", valid_599577
  var valid_599578 = header.getOrDefault("X-Amz-Algorithm")
  valid_599578 = validateParameter(valid_599578, JString, required = false,
                                 default = nil)
  if valid_599578 != nil:
    section.add "X-Amz-Algorithm", valid_599578
  var valid_599579 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599579 = validateParameter(valid_599579, JString, required = false,
                                 default = nil)
  if valid_599579 != nil:
    section.add "X-Amz-SignedHeaders", valid_599579
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599581: Call_SendCommand_599569; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Runs commands on one or more managed instances.
  ## 
  let valid = call_599581.validator(path, query, header, formData, body)
  let scheme = call_599581.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599581.url(scheme.get, call_599581.host, call_599581.base,
                         call_599581.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599581, url, valid)

proc call*(call_599582: Call_SendCommand_599569; body: JsonNode): Recallable =
  ## sendCommand
  ## Runs commands on one or more managed instances.
  ##   body: JObject (required)
  var body_599583 = newJObject()
  if body != nil:
    body_599583 = body
  result = call_599582.call(nil, nil, nil, nil, body_599583)

var sendCommand* = Call_SendCommand_599569(name: "sendCommand",
                                        meth: HttpMethod.HttpPost,
                                        host: "ssm.amazonaws.com", route: "/#X-Amz-Target=AmazonSSM.SendCommand",
                                        validator: validate_SendCommand_599570,
                                        base: "/", url: url_SendCommand_599571,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartAssociationsOnce_599584 = ref object of OpenApiRestCall_597389
proc url_StartAssociationsOnce_599586(protocol: Scheme; host: string; base: string;
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

proc validate_StartAssociationsOnce_599585(path: JsonNode; query: JsonNode;
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
  var valid_599587 = header.getOrDefault("X-Amz-Target")
  valid_599587 = validateParameter(valid_599587, JString, required = true, default = newJString(
      "AmazonSSM.StartAssociationsOnce"))
  if valid_599587 != nil:
    section.add "X-Amz-Target", valid_599587
  var valid_599588 = header.getOrDefault("X-Amz-Signature")
  valid_599588 = validateParameter(valid_599588, JString, required = false,
                                 default = nil)
  if valid_599588 != nil:
    section.add "X-Amz-Signature", valid_599588
  var valid_599589 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599589 = validateParameter(valid_599589, JString, required = false,
                                 default = nil)
  if valid_599589 != nil:
    section.add "X-Amz-Content-Sha256", valid_599589
  var valid_599590 = header.getOrDefault("X-Amz-Date")
  valid_599590 = validateParameter(valid_599590, JString, required = false,
                                 default = nil)
  if valid_599590 != nil:
    section.add "X-Amz-Date", valid_599590
  var valid_599591 = header.getOrDefault("X-Amz-Credential")
  valid_599591 = validateParameter(valid_599591, JString, required = false,
                                 default = nil)
  if valid_599591 != nil:
    section.add "X-Amz-Credential", valid_599591
  var valid_599592 = header.getOrDefault("X-Amz-Security-Token")
  valid_599592 = validateParameter(valid_599592, JString, required = false,
                                 default = nil)
  if valid_599592 != nil:
    section.add "X-Amz-Security-Token", valid_599592
  var valid_599593 = header.getOrDefault("X-Amz-Algorithm")
  valid_599593 = validateParameter(valid_599593, JString, required = false,
                                 default = nil)
  if valid_599593 != nil:
    section.add "X-Amz-Algorithm", valid_599593
  var valid_599594 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599594 = validateParameter(valid_599594, JString, required = false,
                                 default = nil)
  if valid_599594 != nil:
    section.add "X-Amz-SignedHeaders", valid_599594
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599596: Call_StartAssociationsOnce_599584; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Use this API action to run an association immediately and only one time. This action can be helpful when troubleshooting associations.
  ## 
  let valid = call_599596.validator(path, query, header, formData, body)
  let scheme = call_599596.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599596.url(scheme.get, call_599596.host, call_599596.base,
                         call_599596.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599596, url, valid)

proc call*(call_599597: Call_StartAssociationsOnce_599584; body: JsonNode): Recallable =
  ## startAssociationsOnce
  ## Use this API action to run an association immediately and only one time. This action can be helpful when troubleshooting associations.
  ##   body: JObject (required)
  var body_599598 = newJObject()
  if body != nil:
    body_599598 = body
  result = call_599597.call(nil, nil, nil, nil, body_599598)

var startAssociationsOnce* = Call_StartAssociationsOnce_599584(
    name: "startAssociationsOnce", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.StartAssociationsOnce",
    validator: validate_StartAssociationsOnce_599585, base: "/",
    url: url_StartAssociationsOnce_599586, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartAutomationExecution_599599 = ref object of OpenApiRestCall_597389
proc url_StartAutomationExecution_599601(protocol: Scheme; host: string;
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

proc validate_StartAutomationExecution_599600(path: JsonNode; query: JsonNode;
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
  var valid_599602 = header.getOrDefault("X-Amz-Target")
  valid_599602 = validateParameter(valid_599602, JString, required = true, default = newJString(
      "AmazonSSM.StartAutomationExecution"))
  if valid_599602 != nil:
    section.add "X-Amz-Target", valid_599602
  var valid_599603 = header.getOrDefault("X-Amz-Signature")
  valid_599603 = validateParameter(valid_599603, JString, required = false,
                                 default = nil)
  if valid_599603 != nil:
    section.add "X-Amz-Signature", valid_599603
  var valid_599604 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599604 = validateParameter(valid_599604, JString, required = false,
                                 default = nil)
  if valid_599604 != nil:
    section.add "X-Amz-Content-Sha256", valid_599604
  var valid_599605 = header.getOrDefault("X-Amz-Date")
  valid_599605 = validateParameter(valid_599605, JString, required = false,
                                 default = nil)
  if valid_599605 != nil:
    section.add "X-Amz-Date", valid_599605
  var valid_599606 = header.getOrDefault("X-Amz-Credential")
  valid_599606 = validateParameter(valid_599606, JString, required = false,
                                 default = nil)
  if valid_599606 != nil:
    section.add "X-Amz-Credential", valid_599606
  var valid_599607 = header.getOrDefault("X-Amz-Security-Token")
  valid_599607 = validateParameter(valid_599607, JString, required = false,
                                 default = nil)
  if valid_599607 != nil:
    section.add "X-Amz-Security-Token", valid_599607
  var valid_599608 = header.getOrDefault("X-Amz-Algorithm")
  valid_599608 = validateParameter(valid_599608, JString, required = false,
                                 default = nil)
  if valid_599608 != nil:
    section.add "X-Amz-Algorithm", valid_599608
  var valid_599609 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599609 = validateParameter(valid_599609, JString, required = false,
                                 default = nil)
  if valid_599609 != nil:
    section.add "X-Amz-SignedHeaders", valid_599609
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599611: Call_StartAutomationExecution_599599; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Initiates execution of an Automation document.
  ## 
  let valid = call_599611.validator(path, query, header, formData, body)
  let scheme = call_599611.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599611.url(scheme.get, call_599611.host, call_599611.base,
                         call_599611.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599611, url, valid)

proc call*(call_599612: Call_StartAutomationExecution_599599; body: JsonNode): Recallable =
  ## startAutomationExecution
  ## Initiates execution of an Automation document.
  ##   body: JObject (required)
  var body_599613 = newJObject()
  if body != nil:
    body_599613 = body
  result = call_599612.call(nil, nil, nil, nil, body_599613)

var startAutomationExecution* = Call_StartAutomationExecution_599599(
    name: "startAutomationExecution", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.StartAutomationExecution",
    validator: validate_StartAutomationExecution_599600, base: "/",
    url: url_StartAutomationExecution_599601, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartSession_599614 = ref object of OpenApiRestCall_597389
proc url_StartSession_599616(protocol: Scheme; host: string; base: string;
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

proc validate_StartSession_599615(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_599617 = header.getOrDefault("X-Amz-Target")
  valid_599617 = validateParameter(valid_599617, JString, required = true,
                                 default = newJString("AmazonSSM.StartSession"))
  if valid_599617 != nil:
    section.add "X-Amz-Target", valid_599617
  var valid_599618 = header.getOrDefault("X-Amz-Signature")
  valid_599618 = validateParameter(valid_599618, JString, required = false,
                                 default = nil)
  if valid_599618 != nil:
    section.add "X-Amz-Signature", valid_599618
  var valid_599619 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599619 = validateParameter(valid_599619, JString, required = false,
                                 default = nil)
  if valid_599619 != nil:
    section.add "X-Amz-Content-Sha256", valid_599619
  var valid_599620 = header.getOrDefault("X-Amz-Date")
  valid_599620 = validateParameter(valid_599620, JString, required = false,
                                 default = nil)
  if valid_599620 != nil:
    section.add "X-Amz-Date", valid_599620
  var valid_599621 = header.getOrDefault("X-Amz-Credential")
  valid_599621 = validateParameter(valid_599621, JString, required = false,
                                 default = nil)
  if valid_599621 != nil:
    section.add "X-Amz-Credential", valid_599621
  var valid_599622 = header.getOrDefault("X-Amz-Security-Token")
  valid_599622 = validateParameter(valid_599622, JString, required = false,
                                 default = nil)
  if valid_599622 != nil:
    section.add "X-Amz-Security-Token", valid_599622
  var valid_599623 = header.getOrDefault("X-Amz-Algorithm")
  valid_599623 = validateParameter(valid_599623, JString, required = false,
                                 default = nil)
  if valid_599623 != nil:
    section.add "X-Amz-Algorithm", valid_599623
  var valid_599624 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599624 = validateParameter(valid_599624, JString, required = false,
                                 default = nil)
  if valid_599624 != nil:
    section.add "X-Amz-SignedHeaders", valid_599624
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599626: Call_StartSession_599614; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates a connection to a target (for example, an instance) for a Session Manager session. Returns a URL and token that can be used to open a WebSocket connection for sending input and receiving outputs.</p> <note> <p>AWS CLI usage: <code>start-session</code> is an interactive command that requires the Session Manager plugin to be installed on the client machine making the call. For information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html"> Install the Session Manager Plugin for the AWS CLI</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>AWS Tools for PowerShell usage: Start-SSMSession is not currently supported by AWS Tools for PowerShell on Windows local machines.</p> </note>
  ## 
  let valid = call_599626.validator(path, query, header, formData, body)
  let scheme = call_599626.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599626.url(scheme.get, call_599626.host, call_599626.base,
                         call_599626.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599626, url, valid)

proc call*(call_599627: Call_StartSession_599614; body: JsonNode): Recallable =
  ## startSession
  ## <p>Initiates a connection to a target (for example, an instance) for a Session Manager session. Returns a URL and token that can be used to open a WebSocket connection for sending input and receiving outputs.</p> <note> <p>AWS CLI usage: <code>start-session</code> is an interactive command that requires the Session Manager plugin to be installed on the client machine making the call. For information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html"> Install the Session Manager Plugin for the AWS CLI</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>AWS Tools for PowerShell usage: Start-SSMSession is not currently supported by AWS Tools for PowerShell on Windows local machines.</p> </note>
  ##   body: JObject (required)
  var body_599628 = newJObject()
  if body != nil:
    body_599628 = body
  result = call_599627.call(nil, nil, nil, nil, body_599628)

var startSession* = Call_StartSession_599614(name: "startSession",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.StartSession",
    validator: validate_StartSession_599615, base: "/", url: url_StartSession_599616,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopAutomationExecution_599629 = ref object of OpenApiRestCall_597389
proc url_StopAutomationExecution_599631(protocol: Scheme; host: string; base: string;
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

proc validate_StopAutomationExecution_599630(path: JsonNode; query: JsonNode;
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
  var valid_599632 = header.getOrDefault("X-Amz-Target")
  valid_599632 = validateParameter(valid_599632, JString, required = true, default = newJString(
      "AmazonSSM.StopAutomationExecution"))
  if valid_599632 != nil:
    section.add "X-Amz-Target", valid_599632
  var valid_599633 = header.getOrDefault("X-Amz-Signature")
  valid_599633 = validateParameter(valid_599633, JString, required = false,
                                 default = nil)
  if valid_599633 != nil:
    section.add "X-Amz-Signature", valid_599633
  var valid_599634 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599634 = validateParameter(valid_599634, JString, required = false,
                                 default = nil)
  if valid_599634 != nil:
    section.add "X-Amz-Content-Sha256", valid_599634
  var valid_599635 = header.getOrDefault("X-Amz-Date")
  valid_599635 = validateParameter(valid_599635, JString, required = false,
                                 default = nil)
  if valid_599635 != nil:
    section.add "X-Amz-Date", valid_599635
  var valid_599636 = header.getOrDefault("X-Amz-Credential")
  valid_599636 = validateParameter(valid_599636, JString, required = false,
                                 default = nil)
  if valid_599636 != nil:
    section.add "X-Amz-Credential", valid_599636
  var valid_599637 = header.getOrDefault("X-Amz-Security-Token")
  valid_599637 = validateParameter(valid_599637, JString, required = false,
                                 default = nil)
  if valid_599637 != nil:
    section.add "X-Amz-Security-Token", valid_599637
  var valid_599638 = header.getOrDefault("X-Amz-Algorithm")
  valid_599638 = validateParameter(valid_599638, JString, required = false,
                                 default = nil)
  if valid_599638 != nil:
    section.add "X-Amz-Algorithm", valid_599638
  var valid_599639 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599639 = validateParameter(valid_599639, JString, required = false,
                                 default = nil)
  if valid_599639 != nil:
    section.add "X-Amz-SignedHeaders", valid_599639
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599641: Call_StopAutomationExecution_599629; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stop an Automation that is currently running.
  ## 
  let valid = call_599641.validator(path, query, header, formData, body)
  let scheme = call_599641.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599641.url(scheme.get, call_599641.host, call_599641.base,
                         call_599641.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599641, url, valid)

proc call*(call_599642: Call_StopAutomationExecution_599629; body: JsonNode): Recallable =
  ## stopAutomationExecution
  ## Stop an Automation that is currently running.
  ##   body: JObject (required)
  var body_599643 = newJObject()
  if body != nil:
    body_599643 = body
  result = call_599642.call(nil, nil, nil, nil, body_599643)

var stopAutomationExecution* = Call_StopAutomationExecution_599629(
    name: "stopAutomationExecution", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.StopAutomationExecution",
    validator: validate_StopAutomationExecution_599630, base: "/",
    url: url_StopAutomationExecution_599631, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TerminateSession_599644 = ref object of OpenApiRestCall_597389
proc url_TerminateSession_599646(protocol: Scheme; host: string; base: string;
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

proc validate_TerminateSession_599645(path: JsonNode; query: JsonNode;
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
  var valid_599647 = header.getOrDefault("X-Amz-Target")
  valid_599647 = validateParameter(valid_599647, JString, required = true, default = newJString(
      "AmazonSSM.TerminateSession"))
  if valid_599647 != nil:
    section.add "X-Amz-Target", valid_599647
  var valid_599648 = header.getOrDefault("X-Amz-Signature")
  valid_599648 = validateParameter(valid_599648, JString, required = false,
                                 default = nil)
  if valid_599648 != nil:
    section.add "X-Amz-Signature", valid_599648
  var valid_599649 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599649 = validateParameter(valid_599649, JString, required = false,
                                 default = nil)
  if valid_599649 != nil:
    section.add "X-Amz-Content-Sha256", valid_599649
  var valid_599650 = header.getOrDefault("X-Amz-Date")
  valid_599650 = validateParameter(valid_599650, JString, required = false,
                                 default = nil)
  if valid_599650 != nil:
    section.add "X-Amz-Date", valid_599650
  var valid_599651 = header.getOrDefault("X-Amz-Credential")
  valid_599651 = validateParameter(valid_599651, JString, required = false,
                                 default = nil)
  if valid_599651 != nil:
    section.add "X-Amz-Credential", valid_599651
  var valid_599652 = header.getOrDefault("X-Amz-Security-Token")
  valid_599652 = validateParameter(valid_599652, JString, required = false,
                                 default = nil)
  if valid_599652 != nil:
    section.add "X-Amz-Security-Token", valid_599652
  var valid_599653 = header.getOrDefault("X-Amz-Algorithm")
  valid_599653 = validateParameter(valid_599653, JString, required = false,
                                 default = nil)
  if valid_599653 != nil:
    section.add "X-Amz-Algorithm", valid_599653
  var valid_599654 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599654 = validateParameter(valid_599654, JString, required = false,
                                 default = nil)
  if valid_599654 != nil:
    section.add "X-Amz-SignedHeaders", valid_599654
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599656: Call_TerminateSession_599644; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently ends a session and closes the data connection between the Session Manager client and SSM Agent on the instance. A terminated session cannot be resumed.
  ## 
  let valid = call_599656.validator(path, query, header, formData, body)
  let scheme = call_599656.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599656.url(scheme.get, call_599656.host, call_599656.base,
                         call_599656.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599656, url, valid)

proc call*(call_599657: Call_TerminateSession_599644; body: JsonNode): Recallable =
  ## terminateSession
  ## Permanently ends a session and closes the data connection between the Session Manager client and SSM Agent on the instance. A terminated session cannot be resumed.
  ##   body: JObject (required)
  var body_599658 = newJObject()
  if body != nil:
    body_599658 = body
  result = call_599657.call(nil, nil, nil, nil, body_599658)

var terminateSession* = Call_TerminateSession_599644(name: "terminateSession",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.TerminateSession",
    validator: validate_TerminateSession_599645, base: "/",
    url: url_TerminateSession_599646, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAssociation_599659 = ref object of OpenApiRestCall_597389
proc url_UpdateAssociation_599661(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateAssociation_599660(path: JsonNode; query: JsonNode;
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
  var valid_599662 = header.getOrDefault("X-Amz-Target")
  valid_599662 = validateParameter(valid_599662, JString, required = true, default = newJString(
      "AmazonSSM.UpdateAssociation"))
  if valid_599662 != nil:
    section.add "X-Amz-Target", valid_599662
  var valid_599663 = header.getOrDefault("X-Amz-Signature")
  valid_599663 = validateParameter(valid_599663, JString, required = false,
                                 default = nil)
  if valid_599663 != nil:
    section.add "X-Amz-Signature", valid_599663
  var valid_599664 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599664 = validateParameter(valid_599664, JString, required = false,
                                 default = nil)
  if valid_599664 != nil:
    section.add "X-Amz-Content-Sha256", valid_599664
  var valid_599665 = header.getOrDefault("X-Amz-Date")
  valid_599665 = validateParameter(valid_599665, JString, required = false,
                                 default = nil)
  if valid_599665 != nil:
    section.add "X-Amz-Date", valid_599665
  var valid_599666 = header.getOrDefault("X-Amz-Credential")
  valid_599666 = validateParameter(valid_599666, JString, required = false,
                                 default = nil)
  if valid_599666 != nil:
    section.add "X-Amz-Credential", valid_599666
  var valid_599667 = header.getOrDefault("X-Amz-Security-Token")
  valid_599667 = validateParameter(valid_599667, JString, required = false,
                                 default = nil)
  if valid_599667 != nil:
    section.add "X-Amz-Security-Token", valid_599667
  var valid_599668 = header.getOrDefault("X-Amz-Algorithm")
  valid_599668 = validateParameter(valid_599668, JString, required = false,
                                 default = nil)
  if valid_599668 != nil:
    section.add "X-Amz-Algorithm", valid_599668
  var valid_599669 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599669 = validateParameter(valid_599669, JString, required = false,
                                 default = nil)
  if valid_599669 != nil:
    section.add "X-Amz-SignedHeaders", valid_599669
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599671: Call_UpdateAssociation_599659; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an association. You can update the association name and version, the document version, schedule, parameters, and Amazon S3 output. </p> <p>In order to call this API action, your IAM user account, group, or role must be configured with permission to call the <a>DescribeAssociation</a> API action. If you don't have permission to call DescribeAssociation, then you receive the following error: <code>An error occurred (AccessDeniedException) when calling the UpdateAssociation operation: User: &lt;user_arn&gt; is not authorized to perform: ssm:DescribeAssociation on resource: &lt;resource_arn&gt;</code> </p> <important> <p>When you update an association, the association immediately runs against the specified targets.</p> </important>
  ## 
  let valid = call_599671.validator(path, query, header, formData, body)
  let scheme = call_599671.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599671.url(scheme.get, call_599671.host, call_599671.base,
                         call_599671.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599671, url, valid)

proc call*(call_599672: Call_UpdateAssociation_599659; body: JsonNode): Recallable =
  ## updateAssociation
  ## <p>Updates an association. You can update the association name and version, the document version, schedule, parameters, and Amazon S3 output. </p> <p>In order to call this API action, your IAM user account, group, or role must be configured with permission to call the <a>DescribeAssociation</a> API action. If you don't have permission to call DescribeAssociation, then you receive the following error: <code>An error occurred (AccessDeniedException) when calling the UpdateAssociation operation: User: &lt;user_arn&gt; is not authorized to perform: ssm:DescribeAssociation on resource: &lt;resource_arn&gt;</code> </p> <important> <p>When you update an association, the association immediately runs against the specified targets.</p> </important>
  ##   body: JObject (required)
  var body_599673 = newJObject()
  if body != nil:
    body_599673 = body
  result = call_599672.call(nil, nil, nil, nil, body_599673)

var updateAssociation* = Call_UpdateAssociation_599659(name: "updateAssociation",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateAssociation",
    validator: validate_UpdateAssociation_599660, base: "/",
    url: url_UpdateAssociation_599661, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAssociationStatus_599674 = ref object of OpenApiRestCall_597389
proc url_UpdateAssociationStatus_599676(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateAssociationStatus_599675(path: JsonNode; query: JsonNode;
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
  var valid_599677 = header.getOrDefault("X-Amz-Target")
  valid_599677 = validateParameter(valid_599677, JString, required = true, default = newJString(
      "AmazonSSM.UpdateAssociationStatus"))
  if valid_599677 != nil:
    section.add "X-Amz-Target", valid_599677
  var valid_599678 = header.getOrDefault("X-Amz-Signature")
  valid_599678 = validateParameter(valid_599678, JString, required = false,
                                 default = nil)
  if valid_599678 != nil:
    section.add "X-Amz-Signature", valid_599678
  var valid_599679 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599679 = validateParameter(valid_599679, JString, required = false,
                                 default = nil)
  if valid_599679 != nil:
    section.add "X-Amz-Content-Sha256", valid_599679
  var valid_599680 = header.getOrDefault("X-Amz-Date")
  valid_599680 = validateParameter(valid_599680, JString, required = false,
                                 default = nil)
  if valid_599680 != nil:
    section.add "X-Amz-Date", valid_599680
  var valid_599681 = header.getOrDefault("X-Amz-Credential")
  valid_599681 = validateParameter(valid_599681, JString, required = false,
                                 default = nil)
  if valid_599681 != nil:
    section.add "X-Amz-Credential", valid_599681
  var valid_599682 = header.getOrDefault("X-Amz-Security-Token")
  valid_599682 = validateParameter(valid_599682, JString, required = false,
                                 default = nil)
  if valid_599682 != nil:
    section.add "X-Amz-Security-Token", valid_599682
  var valid_599683 = header.getOrDefault("X-Amz-Algorithm")
  valid_599683 = validateParameter(valid_599683, JString, required = false,
                                 default = nil)
  if valid_599683 != nil:
    section.add "X-Amz-Algorithm", valid_599683
  var valid_599684 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599684 = validateParameter(valid_599684, JString, required = false,
                                 default = nil)
  if valid_599684 != nil:
    section.add "X-Amz-SignedHeaders", valid_599684
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599686: Call_UpdateAssociationStatus_599674; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the status of the Systems Manager document associated with the specified instance.
  ## 
  let valid = call_599686.validator(path, query, header, formData, body)
  let scheme = call_599686.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599686.url(scheme.get, call_599686.host, call_599686.base,
                         call_599686.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599686, url, valid)

proc call*(call_599687: Call_UpdateAssociationStatus_599674; body: JsonNode): Recallable =
  ## updateAssociationStatus
  ## Updates the status of the Systems Manager document associated with the specified instance.
  ##   body: JObject (required)
  var body_599688 = newJObject()
  if body != nil:
    body_599688 = body
  result = call_599687.call(nil, nil, nil, nil, body_599688)

var updateAssociationStatus* = Call_UpdateAssociationStatus_599674(
    name: "updateAssociationStatus", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateAssociationStatus",
    validator: validate_UpdateAssociationStatus_599675, base: "/",
    url: url_UpdateAssociationStatus_599676, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocument_599689 = ref object of OpenApiRestCall_597389
proc url_UpdateDocument_599691(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDocument_599690(path: JsonNode; query: JsonNode;
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
  var valid_599692 = header.getOrDefault("X-Amz-Target")
  valid_599692 = validateParameter(valid_599692, JString, required = true, default = newJString(
      "AmazonSSM.UpdateDocument"))
  if valid_599692 != nil:
    section.add "X-Amz-Target", valid_599692
  var valid_599693 = header.getOrDefault("X-Amz-Signature")
  valid_599693 = validateParameter(valid_599693, JString, required = false,
                                 default = nil)
  if valid_599693 != nil:
    section.add "X-Amz-Signature", valid_599693
  var valid_599694 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599694 = validateParameter(valid_599694, JString, required = false,
                                 default = nil)
  if valid_599694 != nil:
    section.add "X-Amz-Content-Sha256", valid_599694
  var valid_599695 = header.getOrDefault("X-Amz-Date")
  valid_599695 = validateParameter(valid_599695, JString, required = false,
                                 default = nil)
  if valid_599695 != nil:
    section.add "X-Amz-Date", valid_599695
  var valid_599696 = header.getOrDefault("X-Amz-Credential")
  valid_599696 = validateParameter(valid_599696, JString, required = false,
                                 default = nil)
  if valid_599696 != nil:
    section.add "X-Amz-Credential", valid_599696
  var valid_599697 = header.getOrDefault("X-Amz-Security-Token")
  valid_599697 = validateParameter(valid_599697, JString, required = false,
                                 default = nil)
  if valid_599697 != nil:
    section.add "X-Amz-Security-Token", valid_599697
  var valid_599698 = header.getOrDefault("X-Amz-Algorithm")
  valid_599698 = validateParameter(valid_599698, JString, required = false,
                                 default = nil)
  if valid_599698 != nil:
    section.add "X-Amz-Algorithm", valid_599698
  var valid_599699 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599699 = validateParameter(valid_599699, JString, required = false,
                                 default = nil)
  if valid_599699 != nil:
    section.add "X-Amz-SignedHeaders", valid_599699
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599701: Call_UpdateDocument_599689; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates one or more values for an SSM document.
  ## 
  let valid = call_599701.validator(path, query, header, formData, body)
  let scheme = call_599701.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599701.url(scheme.get, call_599701.host, call_599701.base,
                         call_599701.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599701, url, valid)

proc call*(call_599702: Call_UpdateDocument_599689; body: JsonNode): Recallable =
  ## updateDocument
  ## Updates one or more values for an SSM document.
  ##   body: JObject (required)
  var body_599703 = newJObject()
  if body != nil:
    body_599703 = body
  result = call_599702.call(nil, nil, nil, nil, body_599703)

var updateDocument* = Call_UpdateDocument_599689(name: "updateDocument",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateDocument",
    validator: validate_UpdateDocument_599690, base: "/", url: url_UpdateDocument_599691,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocumentDefaultVersion_599704 = ref object of OpenApiRestCall_597389
proc url_UpdateDocumentDefaultVersion_599706(protocol: Scheme; host: string;
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

proc validate_UpdateDocumentDefaultVersion_599705(path: JsonNode; query: JsonNode;
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
  var valid_599707 = header.getOrDefault("X-Amz-Target")
  valid_599707 = validateParameter(valid_599707, JString, required = true, default = newJString(
      "AmazonSSM.UpdateDocumentDefaultVersion"))
  if valid_599707 != nil:
    section.add "X-Amz-Target", valid_599707
  var valid_599708 = header.getOrDefault("X-Amz-Signature")
  valid_599708 = validateParameter(valid_599708, JString, required = false,
                                 default = nil)
  if valid_599708 != nil:
    section.add "X-Amz-Signature", valid_599708
  var valid_599709 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599709 = validateParameter(valid_599709, JString, required = false,
                                 default = nil)
  if valid_599709 != nil:
    section.add "X-Amz-Content-Sha256", valid_599709
  var valid_599710 = header.getOrDefault("X-Amz-Date")
  valid_599710 = validateParameter(valid_599710, JString, required = false,
                                 default = nil)
  if valid_599710 != nil:
    section.add "X-Amz-Date", valid_599710
  var valid_599711 = header.getOrDefault("X-Amz-Credential")
  valid_599711 = validateParameter(valid_599711, JString, required = false,
                                 default = nil)
  if valid_599711 != nil:
    section.add "X-Amz-Credential", valid_599711
  var valid_599712 = header.getOrDefault("X-Amz-Security-Token")
  valid_599712 = validateParameter(valid_599712, JString, required = false,
                                 default = nil)
  if valid_599712 != nil:
    section.add "X-Amz-Security-Token", valid_599712
  var valid_599713 = header.getOrDefault("X-Amz-Algorithm")
  valid_599713 = validateParameter(valid_599713, JString, required = false,
                                 default = nil)
  if valid_599713 != nil:
    section.add "X-Amz-Algorithm", valid_599713
  var valid_599714 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599714 = validateParameter(valid_599714, JString, required = false,
                                 default = nil)
  if valid_599714 != nil:
    section.add "X-Amz-SignedHeaders", valid_599714
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599716: Call_UpdateDocumentDefaultVersion_599704; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Set the default version of a document. 
  ## 
  let valid = call_599716.validator(path, query, header, formData, body)
  let scheme = call_599716.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599716.url(scheme.get, call_599716.host, call_599716.base,
                         call_599716.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599716, url, valid)

proc call*(call_599717: Call_UpdateDocumentDefaultVersion_599704; body: JsonNode): Recallable =
  ## updateDocumentDefaultVersion
  ## Set the default version of a document. 
  ##   body: JObject (required)
  var body_599718 = newJObject()
  if body != nil:
    body_599718 = body
  result = call_599717.call(nil, nil, nil, nil, body_599718)

var updateDocumentDefaultVersion* = Call_UpdateDocumentDefaultVersion_599704(
    name: "updateDocumentDefaultVersion", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateDocumentDefaultVersion",
    validator: validate_UpdateDocumentDefaultVersion_599705, base: "/",
    url: url_UpdateDocumentDefaultVersion_599706,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMaintenanceWindow_599719 = ref object of OpenApiRestCall_597389
proc url_UpdateMaintenanceWindow_599721(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateMaintenanceWindow_599720(path: JsonNode; query: JsonNode;
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
  var valid_599722 = header.getOrDefault("X-Amz-Target")
  valid_599722 = validateParameter(valid_599722, JString, required = true, default = newJString(
      "AmazonSSM.UpdateMaintenanceWindow"))
  if valid_599722 != nil:
    section.add "X-Amz-Target", valid_599722
  var valid_599723 = header.getOrDefault("X-Amz-Signature")
  valid_599723 = validateParameter(valid_599723, JString, required = false,
                                 default = nil)
  if valid_599723 != nil:
    section.add "X-Amz-Signature", valid_599723
  var valid_599724 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599724 = validateParameter(valid_599724, JString, required = false,
                                 default = nil)
  if valid_599724 != nil:
    section.add "X-Amz-Content-Sha256", valid_599724
  var valid_599725 = header.getOrDefault("X-Amz-Date")
  valid_599725 = validateParameter(valid_599725, JString, required = false,
                                 default = nil)
  if valid_599725 != nil:
    section.add "X-Amz-Date", valid_599725
  var valid_599726 = header.getOrDefault("X-Amz-Credential")
  valid_599726 = validateParameter(valid_599726, JString, required = false,
                                 default = nil)
  if valid_599726 != nil:
    section.add "X-Amz-Credential", valid_599726
  var valid_599727 = header.getOrDefault("X-Amz-Security-Token")
  valid_599727 = validateParameter(valid_599727, JString, required = false,
                                 default = nil)
  if valid_599727 != nil:
    section.add "X-Amz-Security-Token", valid_599727
  var valid_599728 = header.getOrDefault("X-Amz-Algorithm")
  valid_599728 = validateParameter(valid_599728, JString, required = false,
                                 default = nil)
  if valid_599728 != nil:
    section.add "X-Amz-Algorithm", valid_599728
  var valid_599729 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599729 = validateParameter(valid_599729, JString, required = false,
                                 default = nil)
  if valid_599729 != nil:
    section.add "X-Amz-SignedHeaders", valid_599729
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599731: Call_UpdateMaintenanceWindow_599719; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an existing maintenance window. Only specified parameters are modified.</p> <note> <p>The value you specify for <code>Duration</code> determines the specific end time for the maintenance window based on the time it begins. No maintenance window tasks are permitted to start after the resulting endtime minus the number of hours you specify for <code>Cutoff</code>. For example, if the maintenance window starts at 3 PM, the duration is three hours, and the value you specify for <code>Cutoff</code> is one hour, no maintenance window tasks can start after 5 PM.</p> </note>
  ## 
  let valid = call_599731.validator(path, query, header, formData, body)
  let scheme = call_599731.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599731.url(scheme.get, call_599731.host, call_599731.base,
                         call_599731.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599731, url, valid)

proc call*(call_599732: Call_UpdateMaintenanceWindow_599719; body: JsonNode): Recallable =
  ## updateMaintenanceWindow
  ## <p>Updates an existing maintenance window. Only specified parameters are modified.</p> <note> <p>The value you specify for <code>Duration</code> determines the specific end time for the maintenance window based on the time it begins. No maintenance window tasks are permitted to start after the resulting endtime minus the number of hours you specify for <code>Cutoff</code>. For example, if the maintenance window starts at 3 PM, the duration is three hours, and the value you specify for <code>Cutoff</code> is one hour, no maintenance window tasks can start after 5 PM.</p> </note>
  ##   body: JObject (required)
  var body_599733 = newJObject()
  if body != nil:
    body_599733 = body
  result = call_599732.call(nil, nil, nil, nil, body_599733)

var updateMaintenanceWindow* = Call_UpdateMaintenanceWindow_599719(
    name: "updateMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateMaintenanceWindow",
    validator: validate_UpdateMaintenanceWindow_599720, base: "/",
    url: url_UpdateMaintenanceWindow_599721, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMaintenanceWindowTarget_599734 = ref object of OpenApiRestCall_597389
proc url_UpdateMaintenanceWindowTarget_599736(protocol: Scheme; host: string;
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

proc validate_UpdateMaintenanceWindowTarget_599735(path: JsonNode; query: JsonNode;
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
  var valid_599737 = header.getOrDefault("X-Amz-Target")
  valid_599737 = validateParameter(valid_599737, JString, required = true, default = newJString(
      "AmazonSSM.UpdateMaintenanceWindowTarget"))
  if valid_599737 != nil:
    section.add "X-Amz-Target", valid_599737
  var valid_599738 = header.getOrDefault("X-Amz-Signature")
  valid_599738 = validateParameter(valid_599738, JString, required = false,
                                 default = nil)
  if valid_599738 != nil:
    section.add "X-Amz-Signature", valid_599738
  var valid_599739 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599739 = validateParameter(valid_599739, JString, required = false,
                                 default = nil)
  if valid_599739 != nil:
    section.add "X-Amz-Content-Sha256", valid_599739
  var valid_599740 = header.getOrDefault("X-Amz-Date")
  valid_599740 = validateParameter(valid_599740, JString, required = false,
                                 default = nil)
  if valid_599740 != nil:
    section.add "X-Amz-Date", valid_599740
  var valid_599741 = header.getOrDefault("X-Amz-Credential")
  valid_599741 = validateParameter(valid_599741, JString, required = false,
                                 default = nil)
  if valid_599741 != nil:
    section.add "X-Amz-Credential", valid_599741
  var valid_599742 = header.getOrDefault("X-Amz-Security-Token")
  valid_599742 = validateParameter(valid_599742, JString, required = false,
                                 default = nil)
  if valid_599742 != nil:
    section.add "X-Amz-Security-Token", valid_599742
  var valid_599743 = header.getOrDefault("X-Amz-Algorithm")
  valid_599743 = validateParameter(valid_599743, JString, required = false,
                                 default = nil)
  if valid_599743 != nil:
    section.add "X-Amz-Algorithm", valid_599743
  var valid_599744 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599744 = validateParameter(valid_599744, JString, required = false,
                                 default = nil)
  if valid_599744 != nil:
    section.add "X-Amz-SignedHeaders", valid_599744
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599746: Call_UpdateMaintenanceWindowTarget_599734; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the target of an existing maintenance window. You can change the following:</p> <ul> <li> <p>Name</p> </li> <li> <p>Description</p> </li> <li> <p>Owner</p> </li> <li> <p>IDs for an ID target</p> </li> <li> <p>Tags for a Tag target</p> </li> <li> <p>From any supported tag type to another. The three supported tag types are ID target, Tag target, and resource group. For more information, see <a>Target</a>.</p> </li> </ul> <note> <p>If a parameter is null, then the corresponding field is not modified.</p> </note>
  ## 
  let valid = call_599746.validator(path, query, header, formData, body)
  let scheme = call_599746.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599746.url(scheme.get, call_599746.host, call_599746.base,
                         call_599746.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599746, url, valid)

proc call*(call_599747: Call_UpdateMaintenanceWindowTarget_599734; body: JsonNode): Recallable =
  ## updateMaintenanceWindowTarget
  ## <p>Modifies the target of an existing maintenance window. You can change the following:</p> <ul> <li> <p>Name</p> </li> <li> <p>Description</p> </li> <li> <p>Owner</p> </li> <li> <p>IDs for an ID target</p> </li> <li> <p>Tags for a Tag target</p> </li> <li> <p>From any supported tag type to another. The three supported tag types are ID target, Tag target, and resource group. For more information, see <a>Target</a>.</p> </li> </ul> <note> <p>If a parameter is null, then the corresponding field is not modified.</p> </note>
  ##   body: JObject (required)
  var body_599748 = newJObject()
  if body != nil:
    body_599748 = body
  result = call_599747.call(nil, nil, nil, nil, body_599748)

var updateMaintenanceWindowTarget* = Call_UpdateMaintenanceWindowTarget_599734(
    name: "updateMaintenanceWindowTarget", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateMaintenanceWindowTarget",
    validator: validate_UpdateMaintenanceWindowTarget_599735, base: "/",
    url: url_UpdateMaintenanceWindowTarget_599736,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMaintenanceWindowTask_599749 = ref object of OpenApiRestCall_597389
proc url_UpdateMaintenanceWindowTask_599751(protocol: Scheme; host: string;
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

proc validate_UpdateMaintenanceWindowTask_599750(path: JsonNode; query: JsonNode;
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
  var valid_599752 = header.getOrDefault("X-Amz-Target")
  valid_599752 = validateParameter(valid_599752, JString, required = true, default = newJString(
      "AmazonSSM.UpdateMaintenanceWindowTask"))
  if valid_599752 != nil:
    section.add "X-Amz-Target", valid_599752
  var valid_599753 = header.getOrDefault("X-Amz-Signature")
  valid_599753 = validateParameter(valid_599753, JString, required = false,
                                 default = nil)
  if valid_599753 != nil:
    section.add "X-Amz-Signature", valid_599753
  var valid_599754 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599754 = validateParameter(valid_599754, JString, required = false,
                                 default = nil)
  if valid_599754 != nil:
    section.add "X-Amz-Content-Sha256", valid_599754
  var valid_599755 = header.getOrDefault("X-Amz-Date")
  valid_599755 = validateParameter(valid_599755, JString, required = false,
                                 default = nil)
  if valid_599755 != nil:
    section.add "X-Amz-Date", valid_599755
  var valid_599756 = header.getOrDefault("X-Amz-Credential")
  valid_599756 = validateParameter(valid_599756, JString, required = false,
                                 default = nil)
  if valid_599756 != nil:
    section.add "X-Amz-Credential", valid_599756
  var valid_599757 = header.getOrDefault("X-Amz-Security-Token")
  valid_599757 = validateParameter(valid_599757, JString, required = false,
                                 default = nil)
  if valid_599757 != nil:
    section.add "X-Amz-Security-Token", valid_599757
  var valid_599758 = header.getOrDefault("X-Amz-Algorithm")
  valid_599758 = validateParameter(valid_599758, JString, required = false,
                                 default = nil)
  if valid_599758 != nil:
    section.add "X-Amz-Algorithm", valid_599758
  var valid_599759 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599759 = validateParameter(valid_599759, JString, required = false,
                                 default = nil)
  if valid_599759 != nil:
    section.add "X-Amz-SignedHeaders", valid_599759
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599761: Call_UpdateMaintenanceWindowTask_599749; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies a task assigned to a maintenance window. You can't change the task type, but you can change the following values:</p> <ul> <li> <p>TaskARN. For example, you can change a RUN_COMMAND task from AWS-RunPowerShellScript to AWS-RunShellScript.</p> </li> <li> <p>ServiceRoleArn</p> </li> <li> <p>TaskInvocationParameters</p> </li> <li> <p>Priority</p> </li> <li> <p>MaxConcurrency</p> </li> <li> <p>MaxErrors</p> </li> </ul> <p>If a parameter is null, then the corresponding field is not modified. Also, if you set Replace to true, then all fields required by the <a>RegisterTaskWithMaintenanceWindow</a> action are required for this request. Optional fields that aren't specified are set to null.</p>
  ## 
  let valid = call_599761.validator(path, query, header, formData, body)
  let scheme = call_599761.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599761.url(scheme.get, call_599761.host, call_599761.base,
                         call_599761.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599761, url, valid)

proc call*(call_599762: Call_UpdateMaintenanceWindowTask_599749; body: JsonNode): Recallable =
  ## updateMaintenanceWindowTask
  ## <p>Modifies a task assigned to a maintenance window. You can't change the task type, but you can change the following values:</p> <ul> <li> <p>TaskARN. For example, you can change a RUN_COMMAND task from AWS-RunPowerShellScript to AWS-RunShellScript.</p> </li> <li> <p>ServiceRoleArn</p> </li> <li> <p>TaskInvocationParameters</p> </li> <li> <p>Priority</p> </li> <li> <p>MaxConcurrency</p> </li> <li> <p>MaxErrors</p> </li> </ul> <p>If a parameter is null, then the corresponding field is not modified. Also, if you set Replace to true, then all fields required by the <a>RegisterTaskWithMaintenanceWindow</a> action are required for this request. Optional fields that aren't specified are set to null.</p>
  ##   body: JObject (required)
  var body_599763 = newJObject()
  if body != nil:
    body_599763 = body
  result = call_599762.call(nil, nil, nil, nil, body_599763)

var updateMaintenanceWindowTask* = Call_UpdateMaintenanceWindowTask_599749(
    name: "updateMaintenanceWindowTask", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateMaintenanceWindowTask",
    validator: validate_UpdateMaintenanceWindowTask_599750, base: "/",
    url: url_UpdateMaintenanceWindowTask_599751,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateManagedInstanceRole_599764 = ref object of OpenApiRestCall_597389
proc url_UpdateManagedInstanceRole_599766(protocol: Scheme; host: string;
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

proc validate_UpdateManagedInstanceRole_599765(path: JsonNode; query: JsonNode;
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
  var valid_599767 = header.getOrDefault("X-Amz-Target")
  valid_599767 = validateParameter(valid_599767, JString, required = true, default = newJString(
      "AmazonSSM.UpdateManagedInstanceRole"))
  if valid_599767 != nil:
    section.add "X-Amz-Target", valid_599767
  var valid_599768 = header.getOrDefault("X-Amz-Signature")
  valid_599768 = validateParameter(valid_599768, JString, required = false,
                                 default = nil)
  if valid_599768 != nil:
    section.add "X-Amz-Signature", valid_599768
  var valid_599769 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599769 = validateParameter(valid_599769, JString, required = false,
                                 default = nil)
  if valid_599769 != nil:
    section.add "X-Amz-Content-Sha256", valid_599769
  var valid_599770 = header.getOrDefault("X-Amz-Date")
  valid_599770 = validateParameter(valid_599770, JString, required = false,
                                 default = nil)
  if valid_599770 != nil:
    section.add "X-Amz-Date", valid_599770
  var valid_599771 = header.getOrDefault("X-Amz-Credential")
  valid_599771 = validateParameter(valid_599771, JString, required = false,
                                 default = nil)
  if valid_599771 != nil:
    section.add "X-Amz-Credential", valid_599771
  var valid_599772 = header.getOrDefault("X-Amz-Security-Token")
  valid_599772 = validateParameter(valid_599772, JString, required = false,
                                 default = nil)
  if valid_599772 != nil:
    section.add "X-Amz-Security-Token", valid_599772
  var valid_599773 = header.getOrDefault("X-Amz-Algorithm")
  valid_599773 = validateParameter(valid_599773, JString, required = false,
                                 default = nil)
  if valid_599773 != nil:
    section.add "X-Amz-Algorithm", valid_599773
  var valid_599774 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599774 = validateParameter(valid_599774, JString, required = false,
                                 default = nil)
  if valid_599774 != nil:
    section.add "X-Amz-SignedHeaders", valid_599774
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599776: Call_UpdateManagedInstanceRole_599764; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Assigns or changes an Amazon Identity and Access Management (IAM) role for the managed instance.
  ## 
  let valid = call_599776.validator(path, query, header, formData, body)
  let scheme = call_599776.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599776.url(scheme.get, call_599776.host, call_599776.base,
                         call_599776.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599776, url, valid)

proc call*(call_599777: Call_UpdateManagedInstanceRole_599764; body: JsonNode): Recallable =
  ## updateManagedInstanceRole
  ## Assigns or changes an Amazon Identity and Access Management (IAM) role for the managed instance.
  ##   body: JObject (required)
  var body_599778 = newJObject()
  if body != nil:
    body_599778 = body
  result = call_599777.call(nil, nil, nil, nil, body_599778)

var updateManagedInstanceRole* = Call_UpdateManagedInstanceRole_599764(
    name: "updateManagedInstanceRole", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateManagedInstanceRole",
    validator: validate_UpdateManagedInstanceRole_599765, base: "/",
    url: url_UpdateManagedInstanceRole_599766,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateOpsItem_599779 = ref object of OpenApiRestCall_597389
proc url_UpdateOpsItem_599781(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateOpsItem_599780(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_599782 = header.getOrDefault("X-Amz-Target")
  valid_599782 = validateParameter(valid_599782, JString, required = true, default = newJString(
      "AmazonSSM.UpdateOpsItem"))
  if valid_599782 != nil:
    section.add "X-Amz-Target", valid_599782
  var valid_599783 = header.getOrDefault("X-Amz-Signature")
  valid_599783 = validateParameter(valid_599783, JString, required = false,
                                 default = nil)
  if valid_599783 != nil:
    section.add "X-Amz-Signature", valid_599783
  var valid_599784 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599784 = validateParameter(valid_599784, JString, required = false,
                                 default = nil)
  if valid_599784 != nil:
    section.add "X-Amz-Content-Sha256", valid_599784
  var valid_599785 = header.getOrDefault("X-Amz-Date")
  valid_599785 = validateParameter(valid_599785, JString, required = false,
                                 default = nil)
  if valid_599785 != nil:
    section.add "X-Amz-Date", valid_599785
  var valid_599786 = header.getOrDefault("X-Amz-Credential")
  valid_599786 = validateParameter(valid_599786, JString, required = false,
                                 default = nil)
  if valid_599786 != nil:
    section.add "X-Amz-Credential", valid_599786
  var valid_599787 = header.getOrDefault("X-Amz-Security-Token")
  valid_599787 = validateParameter(valid_599787, JString, required = false,
                                 default = nil)
  if valid_599787 != nil:
    section.add "X-Amz-Security-Token", valid_599787
  var valid_599788 = header.getOrDefault("X-Amz-Algorithm")
  valid_599788 = validateParameter(valid_599788, JString, required = false,
                                 default = nil)
  if valid_599788 != nil:
    section.add "X-Amz-Algorithm", valid_599788
  var valid_599789 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599789 = validateParameter(valid_599789, JString, required = false,
                                 default = nil)
  if valid_599789 != nil:
    section.add "X-Amz-SignedHeaders", valid_599789
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599791: Call_UpdateOpsItem_599779; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Edit or change an OpsItem. You must have permission in AWS Identity and Access Management (IAM) to update an OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ## 
  let valid = call_599791.validator(path, query, header, formData, body)
  let scheme = call_599791.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599791.url(scheme.get, call_599791.host, call_599791.base,
                         call_599791.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599791, url, valid)

proc call*(call_599792: Call_UpdateOpsItem_599779; body: JsonNode): Recallable =
  ## updateOpsItem
  ## <p>Edit or change an OpsItem. You must have permission in AWS Identity and Access Management (IAM) to update an OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ##   body: JObject (required)
  var body_599793 = newJObject()
  if body != nil:
    body_599793 = body
  result = call_599792.call(nil, nil, nil, nil, body_599793)

var updateOpsItem* = Call_UpdateOpsItem_599779(name: "updateOpsItem",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateOpsItem",
    validator: validate_UpdateOpsItem_599780, base: "/", url: url_UpdateOpsItem_599781,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePatchBaseline_599794 = ref object of OpenApiRestCall_597389
proc url_UpdatePatchBaseline_599796(protocol: Scheme; host: string; base: string;
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

proc validate_UpdatePatchBaseline_599795(path: JsonNode; query: JsonNode;
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
  var valid_599797 = header.getOrDefault("X-Amz-Target")
  valid_599797 = validateParameter(valid_599797, JString, required = true, default = newJString(
      "AmazonSSM.UpdatePatchBaseline"))
  if valid_599797 != nil:
    section.add "X-Amz-Target", valid_599797
  var valid_599798 = header.getOrDefault("X-Amz-Signature")
  valid_599798 = validateParameter(valid_599798, JString, required = false,
                                 default = nil)
  if valid_599798 != nil:
    section.add "X-Amz-Signature", valid_599798
  var valid_599799 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599799 = validateParameter(valid_599799, JString, required = false,
                                 default = nil)
  if valid_599799 != nil:
    section.add "X-Amz-Content-Sha256", valid_599799
  var valid_599800 = header.getOrDefault("X-Amz-Date")
  valid_599800 = validateParameter(valid_599800, JString, required = false,
                                 default = nil)
  if valid_599800 != nil:
    section.add "X-Amz-Date", valid_599800
  var valid_599801 = header.getOrDefault("X-Amz-Credential")
  valid_599801 = validateParameter(valid_599801, JString, required = false,
                                 default = nil)
  if valid_599801 != nil:
    section.add "X-Amz-Credential", valid_599801
  var valid_599802 = header.getOrDefault("X-Amz-Security-Token")
  valid_599802 = validateParameter(valid_599802, JString, required = false,
                                 default = nil)
  if valid_599802 != nil:
    section.add "X-Amz-Security-Token", valid_599802
  var valid_599803 = header.getOrDefault("X-Amz-Algorithm")
  valid_599803 = validateParameter(valid_599803, JString, required = false,
                                 default = nil)
  if valid_599803 != nil:
    section.add "X-Amz-Algorithm", valid_599803
  var valid_599804 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599804 = validateParameter(valid_599804, JString, required = false,
                                 default = nil)
  if valid_599804 != nil:
    section.add "X-Amz-SignedHeaders", valid_599804
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599806: Call_UpdatePatchBaseline_599794; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies an existing patch baseline. Fields not specified in the request are left unchanged.</p> <note> <p>For information about valid key and value pairs in <code>PatchFilters</code> for each supported operating system type, see <a href="http://docs.aws.amazon.com/systems-manager/latest/APIReference/API_PatchFilter.html">PatchFilter</a>.</p> </note>
  ## 
  let valid = call_599806.validator(path, query, header, formData, body)
  let scheme = call_599806.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599806.url(scheme.get, call_599806.host, call_599806.base,
                         call_599806.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599806, url, valid)

proc call*(call_599807: Call_UpdatePatchBaseline_599794; body: JsonNode): Recallable =
  ## updatePatchBaseline
  ## <p>Modifies an existing patch baseline. Fields not specified in the request are left unchanged.</p> <note> <p>For information about valid key and value pairs in <code>PatchFilters</code> for each supported operating system type, see <a href="http://docs.aws.amazon.com/systems-manager/latest/APIReference/API_PatchFilter.html">PatchFilter</a>.</p> </note>
  ##   body: JObject (required)
  var body_599808 = newJObject()
  if body != nil:
    body_599808 = body
  result = call_599807.call(nil, nil, nil, nil, body_599808)

var updatePatchBaseline* = Call_UpdatePatchBaseline_599794(
    name: "updatePatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdatePatchBaseline",
    validator: validate_UpdatePatchBaseline_599795, base: "/",
    url: url_UpdatePatchBaseline_599796, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResourceDataSync_599809 = ref object of OpenApiRestCall_597389
proc url_UpdateResourceDataSync_599811(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateResourceDataSync_599810(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599812 = header.getOrDefault("X-Amz-Target")
  valid_599812 = validateParameter(valid_599812, JString, required = true, default = newJString(
      "AmazonSSM.UpdateResourceDataSync"))
  if valid_599812 != nil:
    section.add "X-Amz-Target", valid_599812
  var valid_599813 = header.getOrDefault("X-Amz-Signature")
  valid_599813 = validateParameter(valid_599813, JString, required = false,
                                 default = nil)
  if valid_599813 != nil:
    section.add "X-Amz-Signature", valid_599813
  var valid_599814 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599814 = validateParameter(valid_599814, JString, required = false,
                                 default = nil)
  if valid_599814 != nil:
    section.add "X-Amz-Content-Sha256", valid_599814
  var valid_599815 = header.getOrDefault("X-Amz-Date")
  valid_599815 = validateParameter(valid_599815, JString, required = false,
                                 default = nil)
  if valid_599815 != nil:
    section.add "X-Amz-Date", valid_599815
  var valid_599816 = header.getOrDefault("X-Amz-Credential")
  valid_599816 = validateParameter(valid_599816, JString, required = false,
                                 default = nil)
  if valid_599816 != nil:
    section.add "X-Amz-Credential", valid_599816
  var valid_599817 = header.getOrDefault("X-Amz-Security-Token")
  valid_599817 = validateParameter(valid_599817, JString, required = false,
                                 default = nil)
  if valid_599817 != nil:
    section.add "X-Amz-Security-Token", valid_599817
  var valid_599818 = header.getOrDefault("X-Amz-Algorithm")
  valid_599818 = validateParameter(valid_599818, JString, required = false,
                                 default = nil)
  if valid_599818 != nil:
    section.add "X-Amz-Algorithm", valid_599818
  var valid_599819 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599819 = validateParameter(valid_599819, JString, required = false,
                                 default = nil)
  if valid_599819 != nil:
    section.add "X-Amz-SignedHeaders", valid_599819
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599821: Call_UpdateResourceDataSync_599809; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Update a resource data sync. After you create a resource data sync for a Region, you can't change the account options for that sync. For example, if you create a sync in the us-east-2 (Ohio) Region and you choose the Include only the current account option, you can't edit that sync later and choose the Include all accounts from my AWS Organizations configuration option. Instead, you must delete the first resource data sync, and create a new one.
  ## 
  let valid = call_599821.validator(path, query, header, formData, body)
  let scheme = call_599821.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599821.url(scheme.get, call_599821.host, call_599821.base,
                         call_599821.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599821, url, valid)

proc call*(call_599822: Call_UpdateResourceDataSync_599809; body: JsonNode): Recallable =
  ## updateResourceDataSync
  ## Update a resource data sync. After you create a resource data sync for a Region, you can't change the account options for that sync. For example, if you create a sync in the us-east-2 (Ohio) Region and you choose the Include only the current account option, you can't edit that sync later and choose the Include all accounts from my AWS Organizations configuration option. Instead, you must delete the first resource data sync, and create a new one.
  ##   body: JObject (required)
  var body_599823 = newJObject()
  if body != nil:
    body_599823 = body
  result = call_599822.call(nil, nil, nil, nil, body_599823)

var updateResourceDataSync* = Call_UpdateResourceDataSync_599809(
    name: "updateResourceDataSync", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateResourceDataSync",
    validator: validate_UpdateResourceDataSync_599810, base: "/",
    url: url_UpdateResourceDataSync_599811, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateServiceSetting_599824 = ref object of OpenApiRestCall_597389
proc url_UpdateServiceSetting_599826(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateServiceSetting_599825(path: JsonNode; query: JsonNode;
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
  var valid_599827 = header.getOrDefault("X-Amz-Target")
  valid_599827 = validateParameter(valid_599827, JString, required = true, default = newJString(
      "AmazonSSM.UpdateServiceSetting"))
  if valid_599827 != nil:
    section.add "X-Amz-Target", valid_599827
  var valid_599828 = header.getOrDefault("X-Amz-Signature")
  valid_599828 = validateParameter(valid_599828, JString, required = false,
                                 default = nil)
  if valid_599828 != nil:
    section.add "X-Amz-Signature", valid_599828
  var valid_599829 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599829 = validateParameter(valid_599829, JString, required = false,
                                 default = nil)
  if valid_599829 != nil:
    section.add "X-Amz-Content-Sha256", valid_599829
  var valid_599830 = header.getOrDefault("X-Amz-Date")
  valid_599830 = validateParameter(valid_599830, JString, required = false,
                                 default = nil)
  if valid_599830 != nil:
    section.add "X-Amz-Date", valid_599830
  var valid_599831 = header.getOrDefault("X-Amz-Credential")
  valid_599831 = validateParameter(valid_599831, JString, required = false,
                                 default = nil)
  if valid_599831 != nil:
    section.add "X-Amz-Credential", valid_599831
  var valid_599832 = header.getOrDefault("X-Amz-Security-Token")
  valid_599832 = validateParameter(valid_599832, JString, required = false,
                                 default = nil)
  if valid_599832 != nil:
    section.add "X-Amz-Security-Token", valid_599832
  var valid_599833 = header.getOrDefault("X-Amz-Algorithm")
  valid_599833 = validateParameter(valid_599833, JString, required = false,
                                 default = nil)
  if valid_599833 != nil:
    section.add "X-Amz-Algorithm", valid_599833
  var valid_599834 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599834 = validateParameter(valid_599834, JString, required = false,
                                 default = nil)
  if valid_599834 != nil:
    section.add "X-Amz-SignedHeaders", valid_599834
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599836: Call_UpdateServiceSetting_599824; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>GetServiceSetting</a> API action to view the current value. Or, use the <a>ResetServiceSetting</a> to change the value back to the original value defined by the AWS service team.</p> <p>Update the service setting for the account. </p>
  ## 
  let valid = call_599836.validator(path, query, header, formData, body)
  let scheme = call_599836.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599836.url(scheme.get, call_599836.host, call_599836.base,
                         call_599836.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599836, url, valid)

proc call*(call_599837: Call_UpdateServiceSetting_599824; body: JsonNode): Recallable =
  ## updateServiceSetting
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>GetServiceSetting</a> API action to view the current value. Or, use the <a>ResetServiceSetting</a> to change the value back to the original value defined by the AWS service team.</p> <p>Update the service setting for the account. </p>
  ##   body: JObject (required)
  var body_599838 = newJObject()
  if body != nil:
    body_599838 = body
  result = call_599837.call(nil, nil, nil, nil, body_599838)

var updateServiceSetting* = Call_UpdateServiceSetting_599824(
    name: "updateServiceSetting", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateServiceSetting",
    validator: validate_UpdateServiceSetting_599825, base: "/",
    url: url_UpdateServiceSetting_599826, schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.atozSign(input.getOrDefault("query"), SHA256)
