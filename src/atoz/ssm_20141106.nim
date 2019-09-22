
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode): string

  OpenApiRestCall_602433 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602433](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602433): Option[Scheme] {.used.} =
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
proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] =
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
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_AddTagsToResource_602770 = ref object of OpenApiRestCall_602433
proc url_AddTagsToResource_602772(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AddTagsToResource_602771(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602884 = header.getOrDefault("X-Amz-Date")
  valid_602884 = validateParameter(valid_602884, JString, required = false,
                                 default = nil)
  if valid_602884 != nil:
    section.add "X-Amz-Date", valid_602884
  var valid_602885 = header.getOrDefault("X-Amz-Security-Token")
  valid_602885 = validateParameter(valid_602885, JString, required = false,
                                 default = nil)
  if valid_602885 != nil:
    section.add "X-Amz-Security-Token", valid_602885
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602899 = header.getOrDefault("X-Amz-Target")
  valid_602899 = validateParameter(valid_602899, JString, required = true, default = newJString(
      "AmazonSSM.AddTagsToResource"))
  if valid_602899 != nil:
    section.add "X-Amz-Target", valid_602899
  var valid_602900 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602900 = validateParameter(valid_602900, JString, required = false,
                                 default = nil)
  if valid_602900 != nil:
    section.add "X-Amz-Content-Sha256", valid_602900
  var valid_602901 = header.getOrDefault("X-Amz-Algorithm")
  valid_602901 = validateParameter(valid_602901, JString, required = false,
                                 default = nil)
  if valid_602901 != nil:
    section.add "X-Amz-Algorithm", valid_602901
  var valid_602902 = header.getOrDefault("X-Amz-Signature")
  valid_602902 = validateParameter(valid_602902, JString, required = false,
                                 default = nil)
  if valid_602902 != nil:
    section.add "X-Amz-Signature", valid_602902
  var valid_602903 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602903 = validateParameter(valid_602903, JString, required = false,
                                 default = nil)
  if valid_602903 != nil:
    section.add "X-Amz-SignedHeaders", valid_602903
  var valid_602904 = header.getOrDefault("X-Amz-Credential")
  valid_602904 = validateParameter(valid_602904, JString, required = false,
                                 default = nil)
  if valid_602904 != nil:
    section.add "X-Amz-Credential", valid_602904
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602928: Call_AddTagsToResource_602770; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds or overwrites one or more tags for the specified resource. Tags are metadata that you can assign to your documents, managed instances, maintenance windows, Parameter Store parameters, and patch baselines. Tags enable you to categorize your resources in different ways, for example, by purpose, owner, or environment. Each tag consists of a key and an optional value, both of which you define. For example, you could define a set of tags for your account's managed instances that helps you track each instance's owner and stack level. For example: Key=Owner and Value=DbAdmin, SysAdmin, or Dev. Or Key=Stack and Value=Production, Pre-Production, or Test.</p> <p>Each resource can have a maximum of 50 tags. </p> <p>We recommend that you devise a set of tag keys that meets your needs for each resource type. Using a consistent set of tag keys makes it easier for you to manage your resources. You can search and filter the resources based on the tags you add. Tags don't have any semantic meaning to Amazon EC2 and are interpreted strictly as a string of characters. </p> <p>For more information about tags, see <a href="http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Using_Tags.html">Tagging Your Amazon EC2 Resources</a> in the <i>Amazon EC2 User Guide</i>.</p>
  ## 
  let valid = call_602928.validator(path, query, header, formData, body)
  let scheme = call_602928.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602928.url(scheme.get, call_602928.host, call_602928.base,
                         call_602928.route, valid.getOrDefault("path"))
  result = hook(call_602928, url, valid)

proc call*(call_602999: Call_AddTagsToResource_602770; body: JsonNode): Recallable =
  ## addTagsToResource
  ## <p>Adds or overwrites one or more tags for the specified resource. Tags are metadata that you can assign to your documents, managed instances, maintenance windows, Parameter Store parameters, and patch baselines. Tags enable you to categorize your resources in different ways, for example, by purpose, owner, or environment. Each tag consists of a key and an optional value, both of which you define. For example, you could define a set of tags for your account's managed instances that helps you track each instance's owner and stack level. For example: Key=Owner and Value=DbAdmin, SysAdmin, or Dev. Or Key=Stack and Value=Production, Pre-Production, or Test.</p> <p>Each resource can have a maximum of 50 tags. </p> <p>We recommend that you devise a set of tag keys that meets your needs for each resource type. Using a consistent set of tag keys makes it easier for you to manage your resources. You can search and filter the resources based on the tags you add. Tags don't have any semantic meaning to Amazon EC2 and are interpreted strictly as a string of characters. </p> <p>For more information about tags, see <a href="http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Using_Tags.html">Tagging Your Amazon EC2 Resources</a> in the <i>Amazon EC2 User Guide</i>.</p>
  ##   body: JObject (required)
  var body_603000 = newJObject()
  if body != nil:
    body_603000 = body
  result = call_602999.call(nil, nil, nil, nil, body_603000)

var addTagsToResource* = Call_AddTagsToResource_602770(name: "addTagsToResource",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.AddTagsToResource",
    validator: validate_AddTagsToResource_602771, base: "/",
    url: url_AddTagsToResource_602772, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelCommand_603039 = ref object of OpenApiRestCall_602433
proc url_CancelCommand_603041(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CancelCommand_603040(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603042 = header.getOrDefault("X-Amz-Date")
  valid_603042 = validateParameter(valid_603042, JString, required = false,
                                 default = nil)
  if valid_603042 != nil:
    section.add "X-Amz-Date", valid_603042
  var valid_603043 = header.getOrDefault("X-Amz-Security-Token")
  valid_603043 = validateParameter(valid_603043, JString, required = false,
                                 default = nil)
  if valid_603043 != nil:
    section.add "X-Amz-Security-Token", valid_603043
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603044 = header.getOrDefault("X-Amz-Target")
  valid_603044 = validateParameter(valid_603044, JString, required = true, default = newJString(
      "AmazonSSM.CancelCommand"))
  if valid_603044 != nil:
    section.add "X-Amz-Target", valid_603044
  var valid_603045 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603045 = validateParameter(valid_603045, JString, required = false,
                                 default = nil)
  if valid_603045 != nil:
    section.add "X-Amz-Content-Sha256", valid_603045
  var valid_603046 = header.getOrDefault("X-Amz-Algorithm")
  valid_603046 = validateParameter(valid_603046, JString, required = false,
                                 default = nil)
  if valid_603046 != nil:
    section.add "X-Amz-Algorithm", valid_603046
  var valid_603047 = header.getOrDefault("X-Amz-Signature")
  valid_603047 = validateParameter(valid_603047, JString, required = false,
                                 default = nil)
  if valid_603047 != nil:
    section.add "X-Amz-Signature", valid_603047
  var valid_603048 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603048 = validateParameter(valid_603048, JString, required = false,
                                 default = nil)
  if valid_603048 != nil:
    section.add "X-Amz-SignedHeaders", valid_603048
  var valid_603049 = header.getOrDefault("X-Amz-Credential")
  valid_603049 = validateParameter(valid_603049, JString, required = false,
                                 default = nil)
  if valid_603049 != nil:
    section.add "X-Amz-Credential", valid_603049
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603051: Call_CancelCommand_603039; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attempts to cancel the command specified by the Command ID. There is no guarantee that the command will be terminated and the underlying process stopped.
  ## 
  let valid = call_603051.validator(path, query, header, formData, body)
  let scheme = call_603051.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603051.url(scheme.get, call_603051.host, call_603051.base,
                         call_603051.route, valid.getOrDefault("path"))
  result = hook(call_603051, url, valid)

proc call*(call_603052: Call_CancelCommand_603039; body: JsonNode): Recallable =
  ## cancelCommand
  ## Attempts to cancel the command specified by the Command ID. There is no guarantee that the command will be terminated and the underlying process stopped.
  ##   body: JObject (required)
  var body_603053 = newJObject()
  if body != nil:
    body_603053 = body
  result = call_603052.call(nil, nil, nil, nil, body_603053)

var cancelCommand* = Call_CancelCommand_603039(name: "cancelCommand",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CancelCommand",
    validator: validate_CancelCommand_603040, base: "/", url: url_CancelCommand_603041,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelMaintenanceWindowExecution_603054 = ref object of OpenApiRestCall_602433
proc url_CancelMaintenanceWindowExecution_603056(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CancelMaintenanceWindowExecution_603055(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603057 = header.getOrDefault("X-Amz-Date")
  valid_603057 = validateParameter(valid_603057, JString, required = false,
                                 default = nil)
  if valid_603057 != nil:
    section.add "X-Amz-Date", valid_603057
  var valid_603058 = header.getOrDefault("X-Amz-Security-Token")
  valid_603058 = validateParameter(valid_603058, JString, required = false,
                                 default = nil)
  if valid_603058 != nil:
    section.add "X-Amz-Security-Token", valid_603058
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603059 = header.getOrDefault("X-Amz-Target")
  valid_603059 = validateParameter(valid_603059, JString, required = true, default = newJString(
      "AmazonSSM.CancelMaintenanceWindowExecution"))
  if valid_603059 != nil:
    section.add "X-Amz-Target", valid_603059
  var valid_603060 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603060 = validateParameter(valid_603060, JString, required = false,
                                 default = nil)
  if valid_603060 != nil:
    section.add "X-Amz-Content-Sha256", valid_603060
  var valid_603061 = header.getOrDefault("X-Amz-Algorithm")
  valid_603061 = validateParameter(valid_603061, JString, required = false,
                                 default = nil)
  if valid_603061 != nil:
    section.add "X-Amz-Algorithm", valid_603061
  var valid_603062 = header.getOrDefault("X-Amz-Signature")
  valid_603062 = validateParameter(valid_603062, JString, required = false,
                                 default = nil)
  if valid_603062 != nil:
    section.add "X-Amz-Signature", valid_603062
  var valid_603063 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603063 = validateParameter(valid_603063, JString, required = false,
                                 default = nil)
  if valid_603063 != nil:
    section.add "X-Amz-SignedHeaders", valid_603063
  var valid_603064 = header.getOrDefault("X-Amz-Credential")
  valid_603064 = validateParameter(valid_603064, JString, required = false,
                                 default = nil)
  if valid_603064 != nil:
    section.add "X-Amz-Credential", valid_603064
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603066: Call_CancelMaintenanceWindowExecution_603054;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Stops a maintenance window execution that is already in progress and cancels any tasks in the window that have not already starting running. (Tasks already in progress will continue to completion.)
  ## 
  let valid = call_603066.validator(path, query, header, formData, body)
  let scheme = call_603066.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603066.url(scheme.get, call_603066.host, call_603066.base,
                         call_603066.route, valid.getOrDefault("path"))
  result = hook(call_603066, url, valid)

proc call*(call_603067: Call_CancelMaintenanceWindowExecution_603054;
          body: JsonNode): Recallable =
  ## cancelMaintenanceWindowExecution
  ## Stops a maintenance window execution that is already in progress and cancels any tasks in the window that have not already starting running. (Tasks already in progress will continue to completion.)
  ##   body: JObject (required)
  var body_603068 = newJObject()
  if body != nil:
    body_603068 = body
  result = call_603067.call(nil, nil, nil, nil, body_603068)

var cancelMaintenanceWindowExecution* = Call_CancelMaintenanceWindowExecution_603054(
    name: "cancelMaintenanceWindowExecution", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CancelMaintenanceWindowExecution",
    validator: validate_CancelMaintenanceWindowExecution_603055, base: "/",
    url: url_CancelMaintenanceWindowExecution_603056,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateActivation_603069 = ref object of OpenApiRestCall_602433
proc url_CreateActivation_603071(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateActivation_603070(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603072 = header.getOrDefault("X-Amz-Date")
  valid_603072 = validateParameter(valid_603072, JString, required = false,
                                 default = nil)
  if valid_603072 != nil:
    section.add "X-Amz-Date", valid_603072
  var valid_603073 = header.getOrDefault("X-Amz-Security-Token")
  valid_603073 = validateParameter(valid_603073, JString, required = false,
                                 default = nil)
  if valid_603073 != nil:
    section.add "X-Amz-Security-Token", valid_603073
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603074 = header.getOrDefault("X-Amz-Target")
  valid_603074 = validateParameter(valid_603074, JString, required = true, default = newJString(
      "AmazonSSM.CreateActivation"))
  if valid_603074 != nil:
    section.add "X-Amz-Target", valid_603074
  var valid_603075 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603075 = validateParameter(valid_603075, JString, required = false,
                                 default = nil)
  if valid_603075 != nil:
    section.add "X-Amz-Content-Sha256", valid_603075
  var valid_603076 = header.getOrDefault("X-Amz-Algorithm")
  valid_603076 = validateParameter(valid_603076, JString, required = false,
                                 default = nil)
  if valid_603076 != nil:
    section.add "X-Amz-Algorithm", valid_603076
  var valid_603077 = header.getOrDefault("X-Amz-Signature")
  valid_603077 = validateParameter(valid_603077, JString, required = false,
                                 default = nil)
  if valid_603077 != nil:
    section.add "X-Amz-Signature", valid_603077
  var valid_603078 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603078 = validateParameter(valid_603078, JString, required = false,
                                 default = nil)
  if valid_603078 != nil:
    section.add "X-Amz-SignedHeaders", valid_603078
  var valid_603079 = header.getOrDefault("X-Amz-Credential")
  valid_603079 = validateParameter(valid_603079, JString, required = false,
                                 default = nil)
  if valid_603079 != nil:
    section.add "X-Amz-Credential", valid_603079
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603081: Call_CreateActivation_603069; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Registers your on-premises server or virtual machine with Amazon EC2 so that you can manage these resources using Run Command. An on-premises server or virtual machine that has been registered with EC2 is called a managed instance. For more information about activations, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-managedinstances.html">Setting Up AWS Systems Manager for Hybrid Environments</a>.
  ## 
  let valid = call_603081.validator(path, query, header, formData, body)
  let scheme = call_603081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603081.url(scheme.get, call_603081.host, call_603081.base,
                         call_603081.route, valid.getOrDefault("path"))
  result = hook(call_603081, url, valid)

proc call*(call_603082: Call_CreateActivation_603069; body: JsonNode): Recallable =
  ## createActivation
  ## Registers your on-premises server or virtual machine with Amazon EC2 so that you can manage these resources using Run Command. An on-premises server or virtual machine that has been registered with EC2 is called a managed instance. For more information about activations, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-managedinstances.html">Setting Up AWS Systems Manager for Hybrid Environments</a>.
  ##   body: JObject (required)
  var body_603083 = newJObject()
  if body != nil:
    body_603083 = body
  result = call_603082.call(nil, nil, nil, nil, body_603083)

var createActivation* = Call_CreateActivation_603069(name: "createActivation",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateActivation",
    validator: validate_CreateActivation_603070, base: "/",
    url: url_CreateActivation_603071, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAssociation_603084 = ref object of OpenApiRestCall_602433
proc url_CreateAssociation_603086(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateAssociation_603085(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603087 = header.getOrDefault("X-Amz-Date")
  valid_603087 = validateParameter(valid_603087, JString, required = false,
                                 default = nil)
  if valid_603087 != nil:
    section.add "X-Amz-Date", valid_603087
  var valid_603088 = header.getOrDefault("X-Amz-Security-Token")
  valid_603088 = validateParameter(valid_603088, JString, required = false,
                                 default = nil)
  if valid_603088 != nil:
    section.add "X-Amz-Security-Token", valid_603088
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603089 = header.getOrDefault("X-Amz-Target")
  valid_603089 = validateParameter(valid_603089, JString, required = true, default = newJString(
      "AmazonSSM.CreateAssociation"))
  if valid_603089 != nil:
    section.add "X-Amz-Target", valid_603089
  var valid_603090 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "X-Amz-Content-Sha256", valid_603090
  var valid_603091 = header.getOrDefault("X-Amz-Algorithm")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "X-Amz-Algorithm", valid_603091
  var valid_603092 = header.getOrDefault("X-Amz-Signature")
  valid_603092 = validateParameter(valid_603092, JString, required = false,
                                 default = nil)
  if valid_603092 != nil:
    section.add "X-Amz-Signature", valid_603092
  var valid_603093 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603093 = validateParameter(valid_603093, JString, required = false,
                                 default = nil)
  if valid_603093 != nil:
    section.add "X-Amz-SignedHeaders", valid_603093
  var valid_603094 = header.getOrDefault("X-Amz-Credential")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = nil)
  if valid_603094 != nil:
    section.add "X-Amz-Credential", valid_603094
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603096: Call_CreateAssociation_603084; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates the specified Systems Manager document with the specified instances or targets.</p> <p>When you associate a document with one or more instances using instance IDs or tags, SSM Agent running on the instance processes the document and configures the instance as specified.</p> <p>If you associate a document with an instance that already has an associated document, the system returns the AssociationAlreadyExists exception.</p>
  ## 
  let valid = call_603096.validator(path, query, header, formData, body)
  let scheme = call_603096.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603096.url(scheme.get, call_603096.host, call_603096.base,
                         call_603096.route, valid.getOrDefault("path"))
  result = hook(call_603096, url, valid)

proc call*(call_603097: Call_CreateAssociation_603084; body: JsonNode): Recallable =
  ## createAssociation
  ## <p>Associates the specified Systems Manager document with the specified instances or targets.</p> <p>When you associate a document with one or more instances using instance IDs or tags, SSM Agent running on the instance processes the document and configures the instance as specified.</p> <p>If you associate a document with an instance that already has an associated document, the system returns the AssociationAlreadyExists exception.</p>
  ##   body: JObject (required)
  var body_603098 = newJObject()
  if body != nil:
    body_603098 = body
  result = call_603097.call(nil, nil, nil, nil, body_603098)

var createAssociation* = Call_CreateAssociation_603084(name: "createAssociation",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateAssociation",
    validator: validate_CreateAssociation_603085, base: "/",
    url: url_CreateAssociation_603086, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAssociationBatch_603099 = ref object of OpenApiRestCall_602433
proc url_CreateAssociationBatch_603101(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateAssociationBatch_603100(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603102 = header.getOrDefault("X-Amz-Date")
  valid_603102 = validateParameter(valid_603102, JString, required = false,
                                 default = nil)
  if valid_603102 != nil:
    section.add "X-Amz-Date", valid_603102
  var valid_603103 = header.getOrDefault("X-Amz-Security-Token")
  valid_603103 = validateParameter(valid_603103, JString, required = false,
                                 default = nil)
  if valid_603103 != nil:
    section.add "X-Amz-Security-Token", valid_603103
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603104 = header.getOrDefault("X-Amz-Target")
  valid_603104 = validateParameter(valid_603104, JString, required = true, default = newJString(
      "AmazonSSM.CreateAssociationBatch"))
  if valid_603104 != nil:
    section.add "X-Amz-Target", valid_603104
  var valid_603105 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-Content-Sha256", valid_603105
  var valid_603106 = header.getOrDefault("X-Amz-Algorithm")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-Algorithm", valid_603106
  var valid_603107 = header.getOrDefault("X-Amz-Signature")
  valid_603107 = validateParameter(valid_603107, JString, required = false,
                                 default = nil)
  if valid_603107 != nil:
    section.add "X-Amz-Signature", valid_603107
  var valid_603108 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603108 = validateParameter(valid_603108, JString, required = false,
                                 default = nil)
  if valid_603108 != nil:
    section.add "X-Amz-SignedHeaders", valid_603108
  var valid_603109 = header.getOrDefault("X-Amz-Credential")
  valid_603109 = validateParameter(valid_603109, JString, required = false,
                                 default = nil)
  if valid_603109 != nil:
    section.add "X-Amz-Credential", valid_603109
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603111: Call_CreateAssociationBatch_603099; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates the specified Systems Manager document with the specified instances or targets.</p> <p>When you associate a document with one or more instances using instance IDs or tags, SSM Agent running on the instance processes the document and configures the instance as specified.</p> <p>If you associate a document with an instance that already has an associated document, the system returns the AssociationAlreadyExists exception.</p>
  ## 
  let valid = call_603111.validator(path, query, header, formData, body)
  let scheme = call_603111.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603111.url(scheme.get, call_603111.host, call_603111.base,
                         call_603111.route, valid.getOrDefault("path"))
  result = hook(call_603111, url, valid)

proc call*(call_603112: Call_CreateAssociationBatch_603099; body: JsonNode): Recallable =
  ## createAssociationBatch
  ## <p>Associates the specified Systems Manager document with the specified instances or targets.</p> <p>When you associate a document with one or more instances using instance IDs or tags, SSM Agent running on the instance processes the document and configures the instance as specified.</p> <p>If you associate a document with an instance that already has an associated document, the system returns the AssociationAlreadyExists exception.</p>
  ##   body: JObject (required)
  var body_603113 = newJObject()
  if body != nil:
    body_603113 = body
  result = call_603112.call(nil, nil, nil, nil, body_603113)

var createAssociationBatch* = Call_CreateAssociationBatch_603099(
    name: "createAssociationBatch", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateAssociationBatch",
    validator: validate_CreateAssociationBatch_603100, base: "/",
    url: url_CreateAssociationBatch_603101, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDocument_603114 = ref object of OpenApiRestCall_602433
proc url_CreateDocument_603116(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateDocument_603115(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603117 = header.getOrDefault("X-Amz-Date")
  valid_603117 = validateParameter(valid_603117, JString, required = false,
                                 default = nil)
  if valid_603117 != nil:
    section.add "X-Amz-Date", valid_603117
  var valid_603118 = header.getOrDefault("X-Amz-Security-Token")
  valid_603118 = validateParameter(valid_603118, JString, required = false,
                                 default = nil)
  if valid_603118 != nil:
    section.add "X-Amz-Security-Token", valid_603118
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603119 = header.getOrDefault("X-Amz-Target")
  valid_603119 = validateParameter(valid_603119, JString, required = true, default = newJString(
      "AmazonSSM.CreateDocument"))
  if valid_603119 != nil:
    section.add "X-Amz-Target", valid_603119
  var valid_603120 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "X-Amz-Content-Sha256", valid_603120
  var valid_603121 = header.getOrDefault("X-Amz-Algorithm")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-Algorithm", valid_603121
  var valid_603122 = header.getOrDefault("X-Amz-Signature")
  valid_603122 = validateParameter(valid_603122, JString, required = false,
                                 default = nil)
  if valid_603122 != nil:
    section.add "X-Amz-Signature", valid_603122
  var valid_603123 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603123 = validateParameter(valid_603123, JString, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "X-Amz-SignedHeaders", valid_603123
  var valid_603124 = header.getOrDefault("X-Amz-Credential")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "X-Amz-Credential", valid_603124
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603126: Call_CreateDocument_603114; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Systems Manager document.</p> <p>After you create a document, you can use CreateAssociation to associate it with one or more running instances.</p>
  ## 
  let valid = call_603126.validator(path, query, header, formData, body)
  let scheme = call_603126.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603126.url(scheme.get, call_603126.host, call_603126.base,
                         call_603126.route, valid.getOrDefault("path"))
  result = hook(call_603126, url, valid)

proc call*(call_603127: Call_CreateDocument_603114; body: JsonNode): Recallable =
  ## createDocument
  ## <p>Creates a Systems Manager document.</p> <p>After you create a document, you can use CreateAssociation to associate it with one or more running instances.</p>
  ##   body: JObject (required)
  var body_603128 = newJObject()
  if body != nil:
    body_603128 = body
  result = call_603127.call(nil, nil, nil, nil, body_603128)

var createDocument* = Call_CreateDocument_603114(name: "createDocument",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateDocument",
    validator: validate_CreateDocument_603115, base: "/", url: url_CreateDocument_603116,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMaintenanceWindow_603129 = ref object of OpenApiRestCall_602433
proc url_CreateMaintenanceWindow_603131(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateMaintenanceWindow_603130(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new maintenance window.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603132 = header.getOrDefault("X-Amz-Date")
  valid_603132 = validateParameter(valid_603132, JString, required = false,
                                 default = nil)
  if valid_603132 != nil:
    section.add "X-Amz-Date", valid_603132
  var valid_603133 = header.getOrDefault("X-Amz-Security-Token")
  valid_603133 = validateParameter(valid_603133, JString, required = false,
                                 default = nil)
  if valid_603133 != nil:
    section.add "X-Amz-Security-Token", valid_603133
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603134 = header.getOrDefault("X-Amz-Target")
  valid_603134 = validateParameter(valid_603134, JString, required = true, default = newJString(
      "AmazonSSM.CreateMaintenanceWindow"))
  if valid_603134 != nil:
    section.add "X-Amz-Target", valid_603134
  var valid_603135 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "X-Amz-Content-Sha256", valid_603135
  var valid_603136 = header.getOrDefault("X-Amz-Algorithm")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "X-Amz-Algorithm", valid_603136
  var valid_603137 = header.getOrDefault("X-Amz-Signature")
  valid_603137 = validateParameter(valid_603137, JString, required = false,
                                 default = nil)
  if valid_603137 != nil:
    section.add "X-Amz-Signature", valid_603137
  var valid_603138 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-SignedHeaders", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-Credential")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-Credential", valid_603139
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603141: Call_CreateMaintenanceWindow_603129; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new maintenance window.
  ## 
  let valid = call_603141.validator(path, query, header, formData, body)
  let scheme = call_603141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603141.url(scheme.get, call_603141.host, call_603141.base,
                         call_603141.route, valid.getOrDefault("path"))
  result = hook(call_603141, url, valid)

proc call*(call_603142: Call_CreateMaintenanceWindow_603129; body: JsonNode): Recallable =
  ## createMaintenanceWindow
  ## Creates a new maintenance window.
  ##   body: JObject (required)
  var body_603143 = newJObject()
  if body != nil:
    body_603143 = body
  result = call_603142.call(nil, nil, nil, nil, body_603143)

var createMaintenanceWindow* = Call_CreateMaintenanceWindow_603129(
    name: "createMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateMaintenanceWindow",
    validator: validate_CreateMaintenanceWindow_603130, base: "/",
    url: url_CreateMaintenanceWindow_603131, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateOpsItem_603144 = ref object of OpenApiRestCall_602433
proc url_CreateOpsItem_603146(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateOpsItem_603145(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603147 = header.getOrDefault("X-Amz-Date")
  valid_603147 = validateParameter(valid_603147, JString, required = false,
                                 default = nil)
  if valid_603147 != nil:
    section.add "X-Amz-Date", valid_603147
  var valid_603148 = header.getOrDefault("X-Amz-Security-Token")
  valid_603148 = validateParameter(valid_603148, JString, required = false,
                                 default = nil)
  if valid_603148 != nil:
    section.add "X-Amz-Security-Token", valid_603148
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603149 = header.getOrDefault("X-Amz-Target")
  valid_603149 = validateParameter(valid_603149, JString, required = true, default = newJString(
      "AmazonSSM.CreateOpsItem"))
  if valid_603149 != nil:
    section.add "X-Amz-Target", valid_603149
  var valid_603150 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603150 = validateParameter(valid_603150, JString, required = false,
                                 default = nil)
  if valid_603150 != nil:
    section.add "X-Amz-Content-Sha256", valid_603150
  var valid_603151 = header.getOrDefault("X-Amz-Algorithm")
  valid_603151 = validateParameter(valid_603151, JString, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "X-Amz-Algorithm", valid_603151
  var valid_603152 = header.getOrDefault("X-Amz-Signature")
  valid_603152 = validateParameter(valid_603152, JString, required = false,
                                 default = nil)
  if valid_603152 != nil:
    section.add "X-Amz-Signature", valid_603152
  var valid_603153 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "X-Amz-SignedHeaders", valid_603153
  var valid_603154 = header.getOrDefault("X-Amz-Credential")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "X-Amz-Credential", valid_603154
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603156: Call_CreateOpsItem_603144; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new OpsItem. You must have permission in AWS Identity and Access Management (IAM) to create a new OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ## 
  let valid = call_603156.validator(path, query, header, formData, body)
  let scheme = call_603156.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603156.url(scheme.get, call_603156.host, call_603156.base,
                         call_603156.route, valid.getOrDefault("path"))
  result = hook(call_603156, url, valid)

proc call*(call_603157: Call_CreateOpsItem_603144; body: JsonNode): Recallable =
  ## createOpsItem
  ## <p>Creates a new OpsItem. You must have permission in AWS Identity and Access Management (IAM) to create a new OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ##   body: JObject (required)
  var body_603158 = newJObject()
  if body != nil:
    body_603158 = body
  result = call_603157.call(nil, nil, nil, nil, body_603158)

var createOpsItem* = Call_CreateOpsItem_603144(name: "createOpsItem",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateOpsItem",
    validator: validate_CreateOpsItem_603145, base: "/", url: url_CreateOpsItem_603146,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePatchBaseline_603159 = ref object of OpenApiRestCall_602433
proc url_CreatePatchBaseline_603161(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreatePatchBaseline_603160(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603162 = header.getOrDefault("X-Amz-Date")
  valid_603162 = validateParameter(valid_603162, JString, required = false,
                                 default = nil)
  if valid_603162 != nil:
    section.add "X-Amz-Date", valid_603162
  var valid_603163 = header.getOrDefault("X-Amz-Security-Token")
  valid_603163 = validateParameter(valid_603163, JString, required = false,
                                 default = nil)
  if valid_603163 != nil:
    section.add "X-Amz-Security-Token", valid_603163
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603164 = header.getOrDefault("X-Amz-Target")
  valid_603164 = validateParameter(valid_603164, JString, required = true, default = newJString(
      "AmazonSSM.CreatePatchBaseline"))
  if valid_603164 != nil:
    section.add "X-Amz-Target", valid_603164
  var valid_603165 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603165 = validateParameter(valid_603165, JString, required = false,
                                 default = nil)
  if valid_603165 != nil:
    section.add "X-Amz-Content-Sha256", valid_603165
  var valid_603166 = header.getOrDefault("X-Amz-Algorithm")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "X-Amz-Algorithm", valid_603166
  var valid_603167 = header.getOrDefault("X-Amz-Signature")
  valid_603167 = validateParameter(valid_603167, JString, required = false,
                                 default = nil)
  if valid_603167 != nil:
    section.add "X-Amz-Signature", valid_603167
  var valid_603168 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603168 = validateParameter(valid_603168, JString, required = false,
                                 default = nil)
  if valid_603168 != nil:
    section.add "X-Amz-SignedHeaders", valid_603168
  var valid_603169 = header.getOrDefault("X-Amz-Credential")
  valid_603169 = validateParameter(valid_603169, JString, required = false,
                                 default = nil)
  if valid_603169 != nil:
    section.add "X-Amz-Credential", valid_603169
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603171: Call_CreatePatchBaseline_603159; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a patch baseline.</p> <note> <p>For information about valid key and value pairs in <code>PatchFilters</code> for each supported operating system type, see <a href="http://docs.aws.amazon.com/systems-manager/latest/APIReference/API_PatchFilter.html">PatchFilter</a>.</p> </note>
  ## 
  let valid = call_603171.validator(path, query, header, formData, body)
  let scheme = call_603171.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603171.url(scheme.get, call_603171.host, call_603171.base,
                         call_603171.route, valid.getOrDefault("path"))
  result = hook(call_603171, url, valid)

proc call*(call_603172: Call_CreatePatchBaseline_603159; body: JsonNode): Recallable =
  ## createPatchBaseline
  ## <p>Creates a patch baseline.</p> <note> <p>For information about valid key and value pairs in <code>PatchFilters</code> for each supported operating system type, see <a href="http://docs.aws.amazon.com/systems-manager/latest/APIReference/API_PatchFilter.html">PatchFilter</a>.</p> </note>
  ##   body: JObject (required)
  var body_603173 = newJObject()
  if body != nil:
    body_603173 = body
  result = call_603172.call(nil, nil, nil, nil, body_603173)

var createPatchBaseline* = Call_CreatePatchBaseline_603159(
    name: "createPatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreatePatchBaseline",
    validator: validate_CreatePatchBaseline_603160, base: "/",
    url: url_CreatePatchBaseline_603161, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResourceDataSync_603174 = ref object of OpenApiRestCall_602433
proc url_CreateResourceDataSync_603176(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateResourceDataSync_603175(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603177 = header.getOrDefault("X-Amz-Date")
  valid_603177 = validateParameter(valid_603177, JString, required = false,
                                 default = nil)
  if valid_603177 != nil:
    section.add "X-Amz-Date", valid_603177
  var valid_603178 = header.getOrDefault("X-Amz-Security-Token")
  valid_603178 = validateParameter(valid_603178, JString, required = false,
                                 default = nil)
  if valid_603178 != nil:
    section.add "X-Amz-Security-Token", valid_603178
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603179 = header.getOrDefault("X-Amz-Target")
  valid_603179 = validateParameter(valid_603179, JString, required = true, default = newJString(
      "AmazonSSM.CreateResourceDataSync"))
  if valid_603179 != nil:
    section.add "X-Amz-Target", valid_603179
  var valid_603180 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603180 = validateParameter(valid_603180, JString, required = false,
                                 default = nil)
  if valid_603180 != nil:
    section.add "X-Amz-Content-Sha256", valid_603180
  var valid_603181 = header.getOrDefault("X-Amz-Algorithm")
  valid_603181 = validateParameter(valid_603181, JString, required = false,
                                 default = nil)
  if valid_603181 != nil:
    section.add "X-Amz-Algorithm", valid_603181
  var valid_603182 = header.getOrDefault("X-Amz-Signature")
  valid_603182 = validateParameter(valid_603182, JString, required = false,
                                 default = nil)
  if valid_603182 != nil:
    section.add "X-Amz-Signature", valid_603182
  var valid_603183 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603183 = validateParameter(valid_603183, JString, required = false,
                                 default = nil)
  if valid_603183 != nil:
    section.add "X-Amz-SignedHeaders", valid_603183
  var valid_603184 = header.getOrDefault("X-Amz-Credential")
  valid_603184 = validateParameter(valid_603184, JString, required = false,
                                 default = nil)
  if valid_603184 != nil:
    section.add "X-Amz-Credential", valid_603184
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603186: Call_CreateResourceDataSync_603174; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a resource data sync configuration to a single bucket in Amazon S3. This is an asynchronous operation that returns immediately. After a successful initial sync is completed, the system continuously syncs data to the Amazon S3 bucket. To check the status of the sync, use the <a>ListResourceDataSync</a>.</p> <p>By default, data is not encrypted in Amazon S3. We strongly recommend that you enable encryption in Amazon S3 to ensure secure data storage. We also recommend that you secure access to the Amazon S3 bucket by creating a restrictive bucket policy. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-inventory-datasync.html">Configuring Resource Data Sync for Inventory</a> in the <i>AWS Systems Manager User Guide</i>.</p>
  ## 
  let valid = call_603186.validator(path, query, header, formData, body)
  let scheme = call_603186.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603186.url(scheme.get, call_603186.host, call_603186.base,
                         call_603186.route, valid.getOrDefault("path"))
  result = hook(call_603186, url, valid)

proc call*(call_603187: Call_CreateResourceDataSync_603174; body: JsonNode): Recallable =
  ## createResourceDataSync
  ## <p>Creates a resource data sync configuration to a single bucket in Amazon S3. This is an asynchronous operation that returns immediately. After a successful initial sync is completed, the system continuously syncs data to the Amazon S3 bucket. To check the status of the sync, use the <a>ListResourceDataSync</a>.</p> <p>By default, data is not encrypted in Amazon S3. We strongly recommend that you enable encryption in Amazon S3 to ensure secure data storage. We also recommend that you secure access to the Amazon S3 bucket by creating a restrictive bucket policy. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-inventory-datasync.html">Configuring Resource Data Sync for Inventory</a> in the <i>AWS Systems Manager User Guide</i>.</p>
  ##   body: JObject (required)
  var body_603188 = newJObject()
  if body != nil:
    body_603188 = body
  result = call_603187.call(nil, nil, nil, nil, body_603188)

var createResourceDataSync* = Call_CreateResourceDataSync_603174(
    name: "createResourceDataSync", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateResourceDataSync",
    validator: validate_CreateResourceDataSync_603175, base: "/",
    url: url_CreateResourceDataSync_603176, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteActivation_603189 = ref object of OpenApiRestCall_602433
proc url_DeleteActivation_603191(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteActivation_603190(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603192 = header.getOrDefault("X-Amz-Date")
  valid_603192 = validateParameter(valid_603192, JString, required = false,
                                 default = nil)
  if valid_603192 != nil:
    section.add "X-Amz-Date", valid_603192
  var valid_603193 = header.getOrDefault("X-Amz-Security-Token")
  valid_603193 = validateParameter(valid_603193, JString, required = false,
                                 default = nil)
  if valid_603193 != nil:
    section.add "X-Amz-Security-Token", valid_603193
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603194 = header.getOrDefault("X-Amz-Target")
  valid_603194 = validateParameter(valid_603194, JString, required = true, default = newJString(
      "AmazonSSM.DeleteActivation"))
  if valid_603194 != nil:
    section.add "X-Amz-Target", valid_603194
  var valid_603195 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "X-Amz-Content-Sha256", valid_603195
  var valid_603196 = header.getOrDefault("X-Amz-Algorithm")
  valid_603196 = validateParameter(valid_603196, JString, required = false,
                                 default = nil)
  if valid_603196 != nil:
    section.add "X-Amz-Algorithm", valid_603196
  var valid_603197 = header.getOrDefault("X-Amz-Signature")
  valid_603197 = validateParameter(valid_603197, JString, required = false,
                                 default = nil)
  if valid_603197 != nil:
    section.add "X-Amz-Signature", valid_603197
  var valid_603198 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603198 = validateParameter(valid_603198, JString, required = false,
                                 default = nil)
  if valid_603198 != nil:
    section.add "X-Amz-SignedHeaders", valid_603198
  var valid_603199 = header.getOrDefault("X-Amz-Credential")
  valid_603199 = validateParameter(valid_603199, JString, required = false,
                                 default = nil)
  if valid_603199 != nil:
    section.add "X-Amz-Credential", valid_603199
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603201: Call_DeleteActivation_603189; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an activation. You are not required to delete an activation. If you delete an activation, you can no longer use it to register additional managed instances. Deleting an activation does not de-register managed instances. You must manually de-register managed instances.
  ## 
  let valid = call_603201.validator(path, query, header, formData, body)
  let scheme = call_603201.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603201.url(scheme.get, call_603201.host, call_603201.base,
                         call_603201.route, valid.getOrDefault("path"))
  result = hook(call_603201, url, valid)

proc call*(call_603202: Call_DeleteActivation_603189; body: JsonNode): Recallable =
  ## deleteActivation
  ## Deletes an activation. You are not required to delete an activation. If you delete an activation, you can no longer use it to register additional managed instances. Deleting an activation does not de-register managed instances. You must manually de-register managed instances.
  ##   body: JObject (required)
  var body_603203 = newJObject()
  if body != nil:
    body_603203 = body
  result = call_603202.call(nil, nil, nil, nil, body_603203)

var deleteActivation* = Call_DeleteActivation_603189(name: "deleteActivation",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteActivation",
    validator: validate_DeleteActivation_603190, base: "/",
    url: url_DeleteActivation_603191, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAssociation_603204 = ref object of OpenApiRestCall_602433
proc url_DeleteAssociation_603206(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteAssociation_603205(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603207 = header.getOrDefault("X-Amz-Date")
  valid_603207 = validateParameter(valid_603207, JString, required = false,
                                 default = nil)
  if valid_603207 != nil:
    section.add "X-Amz-Date", valid_603207
  var valid_603208 = header.getOrDefault("X-Amz-Security-Token")
  valid_603208 = validateParameter(valid_603208, JString, required = false,
                                 default = nil)
  if valid_603208 != nil:
    section.add "X-Amz-Security-Token", valid_603208
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603209 = header.getOrDefault("X-Amz-Target")
  valid_603209 = validateParameter(valid_603209, JString, required = true, default = newJString(
      "AmazonSSM.DeleteAssociation"))
  if valid_603209 != nil:
    section.add "X-Amz-Target", valid_603209
  var valid_603210 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603210 = validateParameter(valid_603210, JString, required = false,
                                 default = nil)
  if valid_603210 != nil:
    section.add "X-Amz-Content-Sha256", valid_603210
  var valid_603211 = header.getOrDefault("X-Amz-Algorithm")
  valid_603211 = validateParameter(valid_603211, JString, required = false,
                                 default = nil)
  if valid_603211 != nil:
    section.add "X-Amz-Algorithm", valid_603211
  var valid_603212 = header.getOrDefault("X-Amz-Signature")
  valid_603212 = validateParameter(valid_603212, JString, required = false,
                                 default = nil)
  if valid_603212 != nil:
    section.add "X-Amz-Signature", valid_603212
  var valid_603213 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603213 = validateParameter(valid_603213, JString, required = false,
                                 default = nil)
  if valid_603213 != nil:
    section.add "X-Amz-SignedHeaders", valid_603213
  var valid_603214 = header.getOrDefault("X-Amz-Credential")
  valid_603214 = validateParameter(valid_603214, JString, required = false,
                                 default = nil)
  if valid_603214 != nil:
    section.add "X-Amz-Credential", valid_603214
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603216: Call_DeleteAssociation_603204; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disassociates the specified Systems Manager document from the specified instance.</p> <p>When you disassociate a document from an instance, it does not change the configuration of the instance. To change the configuration state of an instance after you disassociate a document, you must create a new document with the desired configuration and associate it with the instance.</p>
  ## 
  let valid = call_603216.validator(path, query, header, formData, body)
  let scheme = call_603216.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603216.url(scheme.get, call_603216.host, call_603216.base,
                         call_603216.route, valid.getOrDefault("path"))
  result = hook(call_603216, url, valid)

proc call*(call_603217: Call_DeleteAssociation_603204; body: JsonNode): Recallable =
  ## deleteAssociation
  ## <p>Disassociates the specified Systems Manager document from the specified instance.</p> <p>When you disassociate a document from an instance, it does not change the configuration of the instance. To change the configuration state of an instance after you disassociate a document, you must create a new document with the desired configuration and associate it with the instance.</p>
  ##   body: JObject (required)
  var body_603218 = newJObject()
  if body != nil:
    body_603218 = body
  result = call_603217.call(nil, nil, nil, nil, body_603218)

var deleteAssociation* = Call_DeleteAssociation_603204(name: "deleteAssociation",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteAssociation",
    validator: validate_DeleteAssociation_603205, base: "/",
    url: url_DeleteAssociation_603206, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDocument_603219 = ref object of OpenApiRestCall_602433
proc url_DeleteDocument_603221(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteDocument_603220(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603222 = header.getOrDefault("X-Amz-Date")
  valid_603222 = validateParameter(valid_603222, JString, required = false,
                                 default = nil)
  if valid_603222 != nil:
    section.add "X-Amz-Date", valid_603222
  var valid_603223 = header.getOrDefault("X-Amz-Security-Token")
  valid_603223 = validateParameter(valid_603223, JString, required = false,
                                 default = nil)
  if valid_603223 != nil:
    section.add "X-Amz-Security-Token", valid_603223
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603224 = header.getOrDefault("X-Amz-Target")
  valid_603224 = validateParameter(valid_603224, JString, required = true, default = newJString(
      "AmazonSSM.DeleteDocument"))
  if valid_603224 != nil:
    section.add "X-Amz-Target", valid_603224
  var valid_603225 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603225 = validateParameter(valid_603225, JString, required = false,
                                 default = nil)
  if valid_603225 != nil:
    section.add "X-Amz-Content-Sha256", valid_603225
  var valid_603226 = header.getOrDefault("X-Amz-Algorithm")
  valid_603226 = validateParameter(valid_603226, JString, required = false,
                                 default = nil)
  if valid_603226 != nil:
    section.add "X-Amz-Algorithm", valid_603226
  var valid_603227 = header.getOrDefault("X-Amz-Signature")
  valid_603227 = validateParameter(valid_603227, JString, required = false,
                                 default = nil)
  if valid_603227 != nil:
    section.add "X-Amz-Signature", valid_603227
  var valid_603228 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603228 = validateParameter(valid_603228, JString, required = false,
                                 default = nil)
  if valid_603228 != nil:
    section.add "X-Amz-SignedHeaders", valid_603228
  var valid_603229 = header.getOrDefault("X-Amz-Credential")
  valid_603229 = validateParameter(valid_603229, JString, required = false,
                                 default = nil)
  if valid_603229 != nil:
    section.add "X-Amz-Credential", valid_603229
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603231: Call_DeleteDocument_603219; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the Systems Manager document and all instance associations to the document.</p> <p>Before you delete the document, we recommend that you use <a>DeleteAssociation</a> to disassociate all instances that are associated with the document.</p>
  ## 
  let valid = call_603231.validator(path, query, header, formData, body)
  let scheme = call_603231.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603231.url(scheme.get, call_603231.host, call_603231.base,
                         call_603231.route, valid.getOrDefault("path"))
  result = hook(call_603231, url, valid)

proc call*(call_603232: Call_DeleteDocument_603219; body: JsonNode): Recallable =
  ## deleteDocument
  ## <p>Deletes the Systems Manager document and all instance associations to the document.</p> <p>Before you delete the document, we recommend that you use <a>DeleteAssociation</a> to disassociate all instances that are associated with the document.</p>
  ##   body: JObject (required)
  var body_603233 = newJObject()
  if body != nil:
    body_603233 = body
  result = call_603232.call(nil, nil, nil, nil, body_603233)

var deleteDocument* = Call_DeleteDocument_603219(name: "deleteDocument",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteDocument",
    validator: validate_DeleteDocument_603220, base: "/", url: url_DeleteDocument_603221,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInventory_603234 = ref object of OpenApiRestCall_602433
proc url_DeleteInventory_603236(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteInventory_603235(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603237 = header.getOrDefault("X-Amz-Date")
  valid_603237 = validateParameter(valid_603237, JString, required = false,
                                 default = nil)
  if valid_603237 != nil:
    section.add "X-Amz-Date", valid_603237
  var valid_603238 = header.getOrDefault("X-Amz-Security-Token")
  valid_603238 = validateParameter(valid_603238, JString, required = false,
                                 default = nil)
  if valid_603238 != nil:
    section.add "X-Amz-Security-Token", valid_603238
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603239 = header.getOrDefault("X-Amz-Target")
  valid_603239 = validateParameter(valid_603239, JString, required = true, default = newJString(
      "AmazonSSM.DeleteInventory"))
  if valid_603239 != nil:
    section.add "X-Amz-Target", valid_603239
  var valid_603240 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603240 = validateParameter(valid_603240, JString, required = false,
                                 default = nil)
  if valid_603240 != nil:
    section.add "X-Amz-Content-Sha256", valid_603240
  var valid_603241 = header.getOrDefault("X-Amz-Algorithm")
  valid_603241 = validateParameter(valid_603241, JString, required = false,
                                 default = nil)
  if valid_603241 != nil:
    section.add "X-Amz-Algorithm", valid_603241
  var valid_603242 = header.getOrDefault("X-Amz-Signature")
  valid_603242 = validateParameter(valid_603242, JString, required = false,
                                 default = nil)
  if valid_603242 != nil:
    section.add "X-Amz-Signature", valid_603242
  var valid_603243 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603243 = validateParameter(valid_603243, JString, required = false,
                                 default = nil)
  if valid_603243 != nil:
    section.add "X-Amz-SignedHeaders", valid_603243
  var valid_603244 = header.getOrDefault("X-Amz-Credential")
  valid_603244 = validateParameter(valid_603244, JString, required = false,
                                 default = nil)
  if valid_603244 != nil:
    section.add "X-Amz-Credential", valid_603244
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603246: Call_DeleteInventory_603234; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a custom inventory type, or the data associated with a custom Inventory type. Deleting a custom inventory type is also referred to as deleting a custom inventory schema.
  ## 
  let valid = call_603246.validator(path, query, header, formData, body)
  let scheme = call_603246.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603246.url(scheme.get, call_603246.host, call_603246.base,
                         call_603246.route, valid.getOrDefault("path"))
  result = hook(call_603246, url, valid)

proc call*(call_603247: Call_DeleteInventory_603234; body: JsonNode): Recallable =
  ## deleteInventory
  ## Delete a custom inventory type, or the data associated with a custom Inventory type. Deleting a custom inventory type is also referred to as deleting a custom inventory schema.
  ##   body: JObject (required)
  var body_603248 = newJObject()
  if body != nil:
    body_603248 = body
  result = call_603247.call(nil, nil, nil, nil, body_603248)

var deleteInventory* = Call_DeleteInventory_603234(name: "deleteInventory",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteInventory",
    validator: validate_DeleteInventory_603235, base: "/", url: url_DeleteInventory_603236,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMaintenanceWindow_603249 = ref object of OpenApiRestCall_602433
proc url_DeleteMaintenanceWindow_603251(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteMaintenanceWindow_603250(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603252 = header.getOrDefault("X-Amz-Date")
  valid_603252 = validateParameter(valid_603252, JString, required = false,
                                 default = nil)
  if valid_603252 != nil:
    section.add "X-Amz-Date", valid_603252
  var valid_603253 = header.getOrDefault("X-Amz-Security-Token")
  valid_603253 = validateParameter(valid_603253, JString, required = false,
                                 default = nil)
  if valid_603253 != nil:
    section.add "X-Amz-Security-Token", valid_603253
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603254 = header.getOrDefault("X-Amz-Target")
  valid_603254 = validateParameter(valid_603254, JString, required = true, default = newJString(
      "AmazonSSM.DeleteMaintenanceWindow"))
  if valid_603254 != nil:
    section.add "X-Amz-Target", valid_603254
  var valid_603255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603255 = validateParameter(valid_603255, JString, required = false,
                                 default = nil)
  if valid_603255 != nil:
    section.add "X-Amz-Content-Sha256", valid_603255
  var valid_603256 = header.getOrDefault("X-Amz-Algorithm")
  valid_603256 = validateParameter(valid_603256, JString, required = false,
                                 default = nil)
  if valid_603256 != nil:
    section.add "X-Amz-Algorithm", valid_603256
  var valid_603257 = header.getOrDefault("X-Amz-Signature")
  valid_603257 = validateParameter(valid_603257, JString, required = false,
                                 default = nil)
  if valid_603257 != nil:
    section.add "X-Amz-Signature", valid_603257
  var valid_603258 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603258 = validateParameter(valid_603258, JString, required = false,
                                 default = nil)
  if valid_603258 != nil:
    section.add "X-Amz-SignedHeaders", valid_603258
  var valid_603259 = header.getOrDefault("X-Amz-Credential")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "X-Amz-Credential", valid_603259
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603261: Call_DeleteMaintenanceWindow_603249; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a maintenance window.
  ## 
  let valid = call_603261.validator(path, query, header, formData, body)
  let scheme = call_603261.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603261.url(scheme.get, call_603261.host, call_603261.base,
                         call_603261.route, valid.getOrDefault("path"))
  result = hook(call_603261, url, valid)

proc call*(call_603262: Call_DeleteMaintenanceWindow_603249; body: JsonNode): Recallable =
  ## deleteMaintenanceWindow
  ## Deletes a maintenance window.
  ##   body: JObject (required)
  var body_603263 = newJObject()
  if body != nil:
    body_603263 = body
  result = call_603262.call(nil, nil, nil, nil, body_603263)

var deleteMaintenanceWindow* = Call_DeleteMaintenanceWindow_603249(
    name: "deleteMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteMaintenanceWindow",
    validator: validate_DeleteMaintenanceWindow_603250, base: "/",
    url: url_DeleteMaintenanceWindow_603251, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteParameter_603264 = ref object of OpenApiRestCall_602433
proc url_DeleteParameter_603266(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteParameter_603265(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603267 = header.getOrDefault("X-Amz-Date")
  valid_603267 = validateParameter(valid_603267, JString, required = false,
                                 default = nil)
  if valid_603267 != nil:
    section.add "X-Amz-Date", valid_603267
  var valid_603268 = header.getOrDefault("X-Amz-Security-Token")
  valid_603268 = validateParameter(valid_603268, JString, required = false,
                                 default = nil)
  if valid_603268 != nil:
    section.add "X-Amz-Security-Token", valid_603268
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603269 = header.getOrDefault("X-Amz-Target")
  valid_603269 = validateParameter(valid_603269, JString, required = true, default = newJString(
      "AmazonSSM.DeleteParameter"))
  if valid_603269 != nil:
    section.add "X-Amz-Target", valid_603269
  var valid_603270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603270 = validateParameter(valid_603270, JString, required = false,
                                 default = nil)
  if valid_603270 != nil:
    section.add "X-Amz-Content-Sha256", valid_603270
  var valid_603271 = header.getOrDefault("X-Amz-Algorithm")
  valid_603271 = validateParameter(valid_603271, JString, required = false,
                                 default = nil)
  if valid_603271 != nil:
    section.add "X-Amz-Algorithm", valid_603271
  var valid_603272 = header.getOrDefault("X-Amz-Signature")
  valid_603272 = validateParameter(valid_603272, JString, required = false,
                                 default = nil)
  if valid_603272 != nil:
    section.add "X-Amz-Signature", valid_603272
  var valid_603273 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603273 = validateParameter(valid_603273, JString, required = false,
                                 default = nil)
  if valid_603273 != nil:
    section.add "X-Amz-SignedHeaders", valid_603273
  var valid_603274 = header.getOrDefault("X-Amz-Credential")
  valid_603274 = validateParameter(valid_603274, JString, required = false,
                                 default = nil)
  if valid_603274 != nil:
    section.add "X-Amz-Credential", valid_603274
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603276: Call_DeleteParameter_603264; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a parameter from the system.
  ## 
  let valid = call_603276.validator(path, query, header, formData, body)
  let scheme = call_603276.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603276.url(scheme.get, call_603276.host, call_603276.base,
                         call_603276.route, valid.getOrDefault("path"))
  result = hook(call_603276, url, valid)

proc call*(call_603277: Call_DeleteParameter_603264; body: JsonNode): Recallable =
  ## deleteParameter
  ## Delete a parameter from the system.
  ##   body: JObject (required)
  var body_603278 = newJObject()
  if body != nil:
    body_603278 = body
  result = call_603277.call(nil, nil, nil, nil, body_603278)

var deleteParameter* = Call_DeleteParameter_603264(name: "deleteParameter",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteParameter",
    validator: validate_DeleteParameter_603265, base: "/", url: url_DeleteParameter_603266,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteParameters_603279 = ref object of OpenApiRestCall_602433
proc url_DeleteParameters_603281(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteParameters_603280(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603282 = header.getOrDefault("X-Amz-Date")
  valid_603282 = validateParameter(valid_603282, JString, required = false,
                                 default = nil)
  if valid_603282 != nil:
    section.add "X-Amz-Date", valid_603282
  var valid_603283 = header.getOrDefault("X-Amz-Security-Token")
  valid_603283 = validateParameter(valid_603283, JString, required = false,
                                 default = nil)
  if valid_603283 != nil:
    section.add "X-Amz-Security-Token", valid_603283
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603284 = header.getOrDefault("X-Amz-Target")
  valid_603284 = validateParameter(valid_603284, JString, required = true, default = newJString(
      "AmazonSSM.DeleteParameters"))
  if valid_603284 != nil:
    section.add "X-Amz-Target", valid_603284
  var valid_603285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603285 = validateParameter(valid_603285, JString, required = false,
                                 default = nil)
  if valid_603285 != nil:
    section.add "X-Amz-Content-Sha256", valid_603285
  var valid_603286 = header.getOrDefault("X-Amz-Algorithm")
  valid_603286 = validateParameter(valid_603286, JString, required = false,
                                 default = nil)
  if valid_603286 != nil:
    section.add "X-Amz-Algorithm", valid_603286
  var valid_603287 = header.getOrDefault("X-Amz-Signature")
  valid_603287 = validateParameter(valid_603287, JString, required = false,
                                 default = nil)
  if valid_603287 != nil:
    section.add "X-Amz-Signature", valid_603287
  var valid_603288 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603288 = validateParameter(valid_603288, JString, required = false,
                                 default = nil)
  if valid_603288 != nil:
    section.add "X-Amz-SignedHeaders", valid_603288
  var valid_603289 = header.getOrDefault("X-Amz-Credential")
  valid_603289 = validateParameter(valid_603289, JString, required = false,
                                 default = nil)
  if valid_603289 != nil:
    section.add "X-Amz-Credential", valid_603289
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603291: Call_DeleteParameters_603279; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a list of parameters.
  ## 
  let valid = call_603291.validator(path, query, header, formData, body)
  let scheme = call_603291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603291.url(scheme.get, call_603291.host, call_603291.base,
                         call_603291.route, valid.getOrDefault("path"))
  result = hook(call_603291, url, valid)

proc call*(call_603292: Call_DeleteParameters_603279; body: JsonNode): Recallable =
  ## deleteParameters
  ## Delete a list of parameters.
  ##   body: JObject (required)
  var body_603293 = newJObject()
  if body != nil:
    body_603293 = body
  result = call_603292.call(nil, nil, nil, nil, body_603293)

var deleteParameters* = Call_DeleteParameters_603279(name: "deleteParameters",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteParameters",
    validator: validate_DeleteParameters_603280, base: "/",
    url: url_DeleteParameters_603281, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePatchBaseline_603294 = ref object of OpenApiRestCall_602433
proc url_DeletePatchBaseline_603296(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeletePatchBaseline_603295(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603297 = header.getOrDefault("X-Amz-Date")
  valid_603297 = validateParameter(valid_603297, JString, required = false,
                                 default = nil)
  if valid_603297 != nil:
    section.add "X-Amz-Date", valid_603297
  var valid_603298 = header.getOrDefault("X-Amz-Security-Token")
  valid_603298 = validateParameter(valid_603298, JString, required = false,
                                 default = nil)
  if valid_603298 != nil:
    section.add "X-Amz-Security-Token", valid_603298
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603299 = header.getOrDefault("X-Amz-Target")
  valid_603299 = validateParameter(valid_603299, JString, required = true, default = newJString(
      "AmazonSSM.DeletePatchBaseline"))
  if valid_603299 != nil:
    section.add "X-Amz-Target", valid_603299
  var valid_603300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603300 = validateParameter(valid_603300, JString, required = false,
                                 default = nil)
  if valid_603300 != nil:
    section.add "X-Amz-Content-Sha256", valid_603300
  var valid_603301 = header.getOrDefault("X-Amz-Algorithm")
  valid_603301 = validateParameter(valid_603301, JString, required = false,
                                 default = nil)
  if valid_603301 != nil:
    section.add "X-Amz-Algorithm", valid_603301
  var valid_603302 = header.getOrDefault("X-Amz-Signature")
  valid_603302 = validateParameter(valid_603302, JString, required = false,
                                 default = nil)
  if valid_603302 != nil:
    section.add "X-Amz-Signature", valid_603302
  var valid_603303 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603303 = validateParameter(valid_603303, JString, required = false,
                                 default = nil)
  if valid_603303 != nil:
    section.add "X-Amz-SignedHeaders", valid_603303
  var valid_603304 = header.getOrDefault("X-Amz-Credential")
  valid_603304 = validateParameter(valid_603304, JString, required = false,
                                 default = nil)
  if valid_603304 != nil:
    section.add "X-Amz-Credential", valid_603304
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603306: Call_DeletePatchBaseline_603294; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a patch baseline.
  ## 
  let valid = call_603306.validator(path, query, header, formData, body)
  let scheme = call_603306.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603306.url(scheme.get, call_603306.host, call_603306.base,
                         call_603306.route, valid.getOrDefault("path"))
  result = hook(call_603306, url, valid)

proc call*(call_603307: Call_DeletePatchBaseline_603294; body: JsonNode): Recallable =
  ## deletePatchBaseline
  ## Deletes a patch baseline.
  ##   body: JObject (required)
  var body_603308 = newJObject()
  if body != nil:
    body_603308 = body
  result = call_603307.call(nil, nil, nil, nil, body_603308)

var deletePatchBaseline* = Call_DeletePatchBaseline_603294(
    name: "deletePatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeletePatchBaseline",
    validator: validate_DeletePatchBaseline_603295, base: "/",
    url: url_DeletePatchBaseline_603296, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResourceDataSync_603309 = ref object of OpenApiRestCall_602433
proc url_DeleteResourceDataSync_603311(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteResourceDataSync_603310(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603312 = header.getOrDefault("X-Amz-Date")
  valid_603312 = validateParameter(valid_603312, JString, required = false,
                                 default = nil)
  if valid_603312 != nil:
    section.add "X-Amz-Date", valid_603312
  var valid_603313 = header.getOrDefault("X-Amz-Security-Token")
  valid_603313 = validateParameter(valid_603313, JString, required = false,
                                 default = nil)
  if valid_603313 != nil:
    section.add "X-Amz-Security-Token", valid_603313
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603314 = header.getOrDefault("X-Amz-Target")
  valid_603314 = validateParameter(valid_603314, JString, required = true, default = newJString(
      "AmazonSSM.DeleteResourceDataSync"))
  if valid_603314 != nil:
    section.add "X-Amz-Target", valid_603314
  var valid_603315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603315 = validateParameter(valid_603315, JString, required = false,
                                 default = nil)
  if valid_603315 != nil:
    section.add "X-Amz-Content-Sha256", valid_603315
  var valid_603316 = header.getOrDefault("X-Amz-Algorithm")
  valid_603316 = validateParameter(valid_603316, JString, required = false,
                                 default = nil)
  if valid_603316 != nil:
    section.add "X-Amz-Algorithm", valid_603316
  var valid_603317 = header.getOrDefault("X-Amz-Signature")
  valid_603317 = validateParameter(valid_603317, JString, required = false,
                                 default = nil)
  if valid_603317 != nil:
    section.add "X-Amz-Signature", valid_603317
  var valid_603318 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603318 = validateParameter(valid_603318, JString, required = false,
                                 default = nil)
  if valid_603318 != nil:
    section.add "X-Amz-SignedHeaders", valid_603318
  var valid_603319 = header.getOrDefault("X-Amz-Credential")
  valid_603319 = validateParameter(valid_603319, JString, required = false,
                                 default = nil)
  if valid_603319 != nil:
    section.add "X-Amz-Credential", valid_603319
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603321: Call_DeleteResourceDataSync_603309; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Resource Data Sync configuration. After the configuration is deleted, changes to inventory data on managed instances are no longer synced with the target Amazon S3 bucket. Deleting a sync configuration does not delete data in the target Amazon S3 bucket.
  ## 
  let valid = call_603321.validator(path, query, header, formData, body)
  let scheme = call_603321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603321.url(scheme.get, call_603321.host, call_603321.base,
                         call_603321.route, valid.getOrDefault("path"))
  result = hook(call_603321, url, valid)

proc call*(call_603322: Call_DeleteResourceDataSync_603309; body: JsonNode): Recallable =
  ## deleteResourceDataSync
  ## Deletes a Resource Data Sync configuration. After the configuration is deleted, changes to inventory data on managed instances are no longer synced with the target Amazon S3 bucket. Deleting a sync configuration does not delete data in the target Amazon S3 bucket.
  ##   body: JObject (required)
  var body_603323 = newJObject()
  if body != nil:
    body_603323 = body
  result = call_603322.call(nil, nil, nil, nil, body_603323)

var deleteResourceDataSync* = Call_DeleteResourceDataSync_603309(
    name: "deleteResourceDataSync", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteResourceDataSync",
    validator: validate_DeleteResourceDataSync_603310, base: "/",
    url: url_DeleteResourceDataSync_603311, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterManagedInstance_603324 = ref object of OpenApiRestCall_602433
proc url_DeregisterManagedInstance_603326(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeregisterManagedInstance_603325(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603327 = header.getOrDefault("X-Amz-Date")
  valid_603327 = validateParameter(valid_603327, JString, required = false,
                                 default = nil)
  if valid_603327 != nil:
    section.add "X-Amz-Date", valid_603327
  var valid_603328 = header.getOrDefault("X-Amz-Security-Token")
  valid_603328 = validateParameter(valid_603328, JString, required = false,
                                 default = nil)
  if valid_603328 != nil:
    section.add "X-Amz-Security-Token", valid_603328
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603329 = header.getOrDefault("X-Amz-Target")
  valid_603329 = validateParameter(valid_603329, JString, required = true, default = newJString(
      "AmazonSSM.DeregisterManagedInstance"))
  if valid_603329 != nil:
    section.add "X-Amz-Target", valid_603329
  var valid_603330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603330 = validateParameter(valid_603330, JString, required = false,
                                 default = nil)
  if valid_603330 != nil:
    section.add "X-Amz-Content-Sha256", valid_603330
  var valid_603331 = header.getOrDefault("X-Amz-Algorithm")
  valid_603331 = validateParameter(valid_603331, JString, required = false,
                                 default = nil)
  if valid_603331 != nil:
    section.add "X-Amz-Algorithm", valid_603331
  var valid_603332 = header.getOrDefault("X-Amz-Signature")
  valid_603332 = validateParameter(valid_603332, JString, required = false,
                                 default = nil)
  if valid_603332 != nil:
    section.add "X-Amz-Signature", valid_603332
  var valid_603333 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603333 = validateParameter(valid_603333, JString, required = false,
                                 default = nil)
  if valid_603333 != nil:
    section.add "X-Amz-SignedHeaders", valid_603333
  var valid_603334 = header.getOrDefault("X-Amz-Credential")
  valid_603334 = validateParameter(valid_603334, JString, required = false,
                                 default = nil)
  if valid_603334 != nil:
    section.add "X-Amz-Credential", valid_603334
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603336: Call_DeregisterManagedInstance_603324; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the server or virtual machine from the list of registered servers. You can reregister the instance again at any time. If you don't plan to use Run Command on the server, we suggest uninstalling SSM Agent first.
  ## 
  let valid = call_603336.validator(path, query, header, formData, body)
  let scheme = call_603336.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603336.url(scheme.get, call_603336.host, call_603336.base,
                         call_603336.route, valid.getOrDefault("path"))
  result = hook(call_603336, url, valid)

proc call*(call_603337: Call_DeregisterManagedInstance_603324; body: JsonNode): Recallable =
  ## deregisterManagedInstance
  ## Removes the server or virtual machine from the list of registered servers. You can reregister the instance again at any time. If you don't plan to use Run Command on the server, we suggest uninstalling SSM Agent first.
  ##   body: JObject (required)
  var body_603338 = newJObject()
  if body != nil:
    body_603338 = body
  result = call_603337.call(nil, nil, nil, nil, body_603338)

var deregisterManagedInstance* = Call_DeregisterManagedInstance_603324(
    name: "deregisterManagedInstance", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeregisterManagedInstance",
    validator: validate_DeregisterManagedInstance_603325, base: "/",
    url: url_DeregisterManagedInstance_603326,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterPatchBaselineForPatchGroup_603339 = ref object of OpenApiRestCall_602433
proc url_DeregisterPatchBaselineForPatchGroup_603341(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeregisterPatchBaselineForPatchGroup_603340(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603342 = header.getOrDefault("X-Amz-Date")
  valid_603342 = validateParameter(valid_603342, JString, required = false,
                                 default = nil)
  if valid_603342 != nil:
    section.add "X-Amz-Date", valid_603342
  var valid_603343 = header.getOrDefault("X-Amz-Security-Token")
  valid_603343 = validateParameter(valid_603343, JString, required = false,
                                 default = nil)
  if valid_603343 != nil:
    section.add "X-Amz-Security-Token", valid_603343
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603344 = header.getOrDefault("X-Amz-Target")
  valid_603344 = validateParameter(valid_603344, JString, required = true, default = newJString(
      "AmazonSSM.DeregisterPatchBaselineForPatchGroup"))
  if valid_603344 != nil:
    section.add "X-Amz-Target", valid_603344
  var valid_603345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603345 = validateParameter(valid_603345, JString, required = false,
                                 default = nil)
  if valid_603345 != nil:
    section.add "X-Amz-Content-Sha256", valid_603345
  var valid_603346 = header.getOrDefault("X-Amz-Algorithm")
  valid_603346 = validateParameter(valid_603346, JString, required = false,
                                 default = nil)
  if valid_603346 != nil:
    section.add "X-Amz-Algorithm", valid_603346
  var valid_603347 = header.getOrDefault("X-Amz-Signature")
  valid_603347 = validateParameter(valid_603347, JString, required = false,
                                 default = nil)
  if valid_603347 != nil:
    section.add "X-Amz-Signature", valid_603347
  var valid_603348 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603348 = validateParameter(valid_603348, JString, required = false,
                                 default = nil)
  if valid_603348 != nil:
    section.add "X-Amz-SignedHeaders", valid_603348
  var valid_603349 = header.getOrDefault("X-Amz-Credential")
  valid_603349 = validateParameter(valid_603349, JString, required = false,
                                 default = nil)
  if valid_603349 != nil:
    section.add "X-Amz-Credential", valid_603349
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603351: Call_DeregisterPatchBaselineForPatchGroup_603339;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Removes a patch group from a patch baseline.
  ## 
  let valid = call_603351.validator(path, query, header, formData, body)
  let scheme = call_603351.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603351.url(scheme.get, call_603351.host, call_603351.base,
                         call_603351.route, valid.getOrDefault("path"))
  result = hook(call_603351, url, valid)

proc call*(call_603352: Call_DeregisterPatchBaselineForPatchGroup_603339;
          body: JsonNode): Recallable =
  ## deregisterPatchBaselineForPatchGroup
  ## Removes a patch group from a patch baseline.
  ##   body: JObject (required)
  var body_603353 = newJObject()
  if body != nil:
    body_603353 = body
  result = call_603352.call(nil, nil, nil, nil, body_603353)

var deregisterPatchBaselineForPatchGroup* = Call_DeregisterPatchBaselineForPatchGroup_603339(
    name: "deregisterPatchBaselineForPatchGroup", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeregisterPatchBaselineForPatchGroup",
    validator: validate_DeregisterPatchBaselineForPatchGroup_603340, base: "/",
    url: url_DeregisterPatchBaselineForPatchGroup_603341,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterTargetFromMaintenanceWindow_603354 = ref object of OpenApiRestCall_602433
proc url_DeregisterTargetFromMaintenanceWindow_603356(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeregisterTargetFromMaintenanceWindow_603355(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603357 = header.getOrDefault("X-Amz-Date")
  valid_603357 = validateParameter(valid_603357, JString, required = false,
                                 default = nil)
  if valid_603357 != nil:
    section.add "X-Amz-Date", valid_603357
  var valid_603358 = header.getOrDefault("X-Amz-Security-Token")
  valid_603358 = validateParameter(valid_603358, JString, required = false,
                                 default = nil)
  if valid_603358 != nil:
    section.add "X-Amz-Security-Token", valid_603358
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603359 = header.getOrDefault("X-Amz-Target")
  valid_603359 = validateParameter(valid_603359, JString, required = true, default = newJString(
      "AmazonSSM.DeregisterTargetFromMaintenanceWindow"))
  if valid_603359 != nil:
    section.add "X-Amz-Target", valid_603359
  var valid_603360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603360 = validateParameter(valid_603360, JString, required = false,
                                 default = nil)
  if valid_603360 != nil:
    section.add "X-Amz-Content-Sha256", valid_603360
  var valid_603361 = header.getOrDefault("X-Amz-Algorithm")
  valid_603361 = validateParameter(valid_603361, JString, required = false,
                                 default = nil)
  if valid_603361 != nil:
    section.add "X-Amz-Algorithm", valid_603361
  var valid_603362 = header.getOrDefault("X-Amz-Signature")
  valid_603362 = validateParameter(valid_603362, JString, required = false,
                                 default = nil)
  if valid_603362 != nil:
    section.add "X-Amz-Signature", valid_603362
  var valid_603363 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603363 = validateParameter(valid_603363, JString, required = false,
                                 default = nil)
  if valid_603363 != nil:
    section.add "X-Amz-SignedHeaders", valid_603363
  var valid_603364 = header.getOrDefault("X-Amz-Credential")
  valid_603364 = validateParameter(valid_603364, JString, required = false,
                                 default = nil)
  if valid_603364 != nil:
    section.add "X-Amz-Credential", valid_603364
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603366: Call_DeregisterTargetFromMaintenanceWindow_603354;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Removes a target from a maintenance window.
  ## 
  let valid = call_603366.validator(path, query, header, formData, body)
  let scheme = call_603366.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603366.url(scheme.get, call_603366.host, call_603366.base,
                         call_603366.route, valid.getOrDefault("path"))
  result = hook(call_603366, url, valid)

proc call*(call_603367: Call_DeregisterTargetFromMaintenanceWindow_603354;
          body: JsonNode): Recallable =
  ## deregisterTargetFromMaintenanceWindow
  ## Removes a target from a maintenance window.
  ##   body: JObject (required)
  var body_603368 = newJObject()
  if body != nil:
    body_603368 = body
  result = call_603367.call(nil, nil, nil, nil, body_603368)

var deregisterTargetFromMaintenanceWindow* = Call_DeregisterTargetFromMaintenanceWindow_603354(
    name: "deregisterTargetFromMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeregisterTargetFromMaintenanceWindow",
    validator: validate_DeregisterTargetFromMaintenanceWindow_603355, base: "/",
    url: url_DeregisterTargetFromMaintenanceWindow_603356,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterTaskFromMaintenanceWindow_603369 = ref object of OpenApiRestCall_602433
proc url_DeregisterTaskFromMaintenanceWindow_603371(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeregisterTaskFromMaintenanceWindow_603370(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603372 = header.getOrDefault("X-Amz-Date")
  valid_603372 = validateParameter(valid_603372, JString, required = false,
                                 default = nil)
  if valid_603372 != nil:
    section.add "X-Amz-Date", valid_603372
  var valid_603373 = header.getOrDefault("X-Amz-Security-Token")
  valid_603373 = validateParameter(valid_603373, JString, required = false,
                                 default = nil)
  if valid_603373 != nil:
    section.add "X-Amz-Security-Token", valid_603373
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603374 = header.getOrDefault("X-Amz-Target")
  valid_603374 = validateParameter(valid_603374, JString, required = true, default = newJString(
      "AmazonSSM.DeregisterTaskFromMaintenanceWindow"))
  if valid_603374 != nil:
    section.add "X-Amz-Target", valid_603374
  var valid_603375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603375 = validateParameter(valid_603375, JString, required = false,
                                 default = nil)
  if valid_603375 != nil:
    section.add "X-Amz-Content-Sha256", valid_603375
  var valid_603376 = header.getOrDefault("X-Amz-Algorithm")
  valid_603376 = validateParameter(valid_603376, JString, required = false,
                                 default = nil)
  if valid_603376 != nil:
    section.add "X-Amz-Algorithm", valid_603376
  var valid_603377 = header.getOrDefault("X-Amz-Signature")
  valid_603377 = validateParameter(valid_603377, JString, required = false,
                                 default = nil)
  if valid_603377 != nil:
    section.add "X-Amz-Signature", valid_603377
  var valid_603378 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603378 = validateParameter(valid_603378, JString, required = false,
                                 default = nil)
  if valid_603378 != nil:
    section.add "X-Amz-SignedHeaders", valid_603378
  var valid_603379 = header.getOrDefault("X-Amz-Credential")
  valid_603379 = validateParameter(valid_603379, JString, required = false,
                                 default = nil)
  if valid_603379 != nil:
    section.add "X-Amz-Credential", valid_603379
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603381: Call_DeregisterTaskFromMaintenanceWindow_603369;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Removes a task from a maintenance window.
  ## 
  let valid = call_603381.validator(path, query, header, formData, body)
  let scheme = call_603381.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603381.url(scheme.get, call_603381.host, call_603381.base,
                         call_603381.route, valid.getOrDefault("path"))
  result = hook(call_603381, url, valid)

proc call*(call_603382: Call_DeregisterTaskFromMaintenanceWindow_603369;
          body: JsonNode): Recallable =
  ## deregisterTaskFromMaintenanceWindow
  ## Removes a task from a maintenance window.
  ##   body: JObject (required)
  var body_603383 = newJObject()
  if body != nil:
    body_603383 = body
  result = call_603382.call(nil, nil, nil, nil, body_603383)

var deregisterTaskFromMaintenanceWindow* = Call_DeregisterTaskFromMaintenanceWindow_603369(
    name: "deregisterTaskFromMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeregisterTaskFromMaintenanceWindow",
    validator: validate_DeregisterTaskFromMaintenanceWindow_603370, base: "/",
    url: url_DeregisterTaskFromMaintenanceWindow_603371,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeActivations_603384 = ref object of OpenApiRestCall_602433
proc url_DescribeActivations_603386(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeActivations_603385(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Describes details about the activation, such as the date and time the activation was created, its expiration date, the IAM role assigned to the instances in the activation, and the number of instances registered by using this activation.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_603387 = query.getOrDefault("NextToken")
  valid_603387 = validateParameter(valid_603387, JString, required = false,
                                 default = nil)
  if valid_603387 != nil:
    section.add "NextToken", valid_603387
  var valid_603388 = query.getOrDefault("MaxResults")
  valid_603388 = validateParameter(valid_603388, JString, required = false,
                                 default = nil)
  if valid_603388 != nil:
    section.add "MaxResults", valid_603388
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603389 = header.getOrDefault("X-Amz-Date")
  valid_603389 = validateParameter(valid_603389, JString, required = false,
                                 default = nil)
  if valid_603389 != nil:
    section.add "X-Amz-Date", valid_603389
  var valid_603390 = header.getOrDefault("X-Amz-Security-Token")
  valid_603390 = validateParameter(valid_603390, JString, required = false,
                                 default = nil)
  if valid_603390 != nil:
    section.add "X-Amz-Security-Token", valid_603390
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603391 = header.getOrDefault("X-Amz-Target")
  valid_603391 = validateParameter(valid_603391, JString, required = true, default = newJString(
      "AmazonSSM.DescribeActivations"))
  if valid_603391 != nil:
    section.add "X-Amz-Target", valid_603391
  var valid_603392 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603392 = validateParameter(valid_603392, JString, required = false,
                                 default = nil)
  if valid_603392 != nil:
    section.add "X-Amz-Content-Sha256", valid_603392
  var valid_603393 = header.getOrDefault("X-Amz-Algorithm")
  valid_603393 = validateParameter(valid_603393, JString, required = false,
                                 default = nil)
  if valid_603393 != nil:
    section.add "X-Amz-Algorithm", valid_603393
  var valid_603394 = header.getOrDefault("X-Amz-Signature")
  valid_603394 = validateParameter(valid_603394, JString, required = false,
                                 default = nil)
  if valid_603394 != nil:
    section.add "X-Amz-Signature", valid_603394
  var valid_603395 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603395 = validateParameter(valid_603395, JString, required = false,
                                 default = nil)
  if valid_603395 != nil:
    section.add "X-Amz-SignedHeaders", valid_603395
  var valid_603396 = header.getOrDefault("X-Amz-Credential")
  valid_603396 = validateParameter(valid_603396, JString, required = false,
                                 default = nil)
  if valid_603396 != nil:
    section.add "X-Amz-Credential", valid_603396
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603398: Call_DescribeActivations_603384; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes details about the activation, such as the date and time the activation was created, its expiration date, the IAM role assigned to the instances in the activation, and the number of instances registered by using this activation.
  ## 
  let valid = call_603398.validator(path, query, header, formData, body)
  let scheme = call_603398.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603398.url(scheme.get, call_603398.host, call_603398.base,
                         call_603398.route, valid.getOrDefault("path"))
  result = hook(call_603398, url, valid)

proc call*(call_603399: Call_DescribeActivations_603384; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## describeActivations
  ## Describes details about the activation, such as the date and time the activation was created, its expiration date, the IAM role assigned to the instances in the activation, and the number of instances registered by using this activation.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603400 = newJObject()
  var body_603401 = newJObject()
  add(query_603400, "NextToken", newJString(NextToken))
  if body != nil:
    body_603401 = body
  add(query_603400, "MaxResults", newJString(MaxResults))
  result = call_603399.call(nil, query_603400, nil, nil, body_603401)

var describeActivations* = Call_DescribeActivations_603384(
    name: "describeActivations", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeActivations",
    validator: validate_DescribeActivations_603385, base: "/",
    url: url_DescribeActivations_603386, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAssociation_603403 = ref object of OpenApiRestCall_602433
proc url_DescribeAssociation_603405(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeAssociation_603404(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603406 = header.getOrDefault("X-Amz-Date")
  valid_603406 = validateParameter(valid_603406, JString, required = false,
                                 default = nil)
  if valid_603406 != nil:
    section.add "X-Amz-Date", valid_603406
  var valid_603407 = header.getOrDefault("X-Amz-Security-Token")
  valid_603407 = validateParameter(valid_603407, JString, required = false,
                                 default = nil)
  if valid_603407 != nil:
    section.add "X-Amz-Security-Token", valid_603407
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603408 = header.getOrDefault("X-Amz-Target")
  valid_603408 = validateParameter(valid_603408, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAssociation"))
  if valid_603408 != nil:
    section.add "X-Amz-Target", valid_603408
  var valid_603409 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603409 = validateParameter(valid_603409, JString, required = false,
                                 default = nil)
  if valid_603409 != nil:
    section.add "X-Amz-Content-Sha256", valid_603409
  var valid_603410 = header.getOrDefault("X-Amz-Algorithm")
  valid_603410 = validateParameter(valid_603410, JString, required = false,
                                 default = nil)
  if valid_603410 != nil:
    section.add "X-Amz-Algorithm", valid_603410
  var valid_603411 = header.getOrDefault("X-Amz-Signature")
  valid_603411 = validateParameter(valid_603411, JString, required = false,
                                 default = nil)
  if valid_603411 != nil:
    section.add "X-Amz-Signature", valid_603411
  var valid_603412 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603412 = validateParameter(valid_603412, JString, required = false,
                                 default = nil)
  if valid_603412 != nil:
    section.add "X-Amz-SignedHeaders", valid_603412
  var valid_603413 = header.getOrDefault("X-Amz-Credential")
  valid_603413 = validateParameter(valid_603413, JString, required = false,
                                 default = nil)
  if valid_603413 != nil:
    section.add "X-Amz-Credential", valid_603413
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603415: Call_DescribeAssociation_603403; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the association for the specified target or instance. If you created the association by using the <code>Targets</code> parameter, then you must retrieve the association by using the association ID. If you created the association by specifying an instance ID and a Systems Manager document, then you retrieve the association by specifying the document name and the instance ID. 
  ## 
  let valid = call_603415.validator(path, query, header, formData, body)
  let scheme = call_603415.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603415.url(scheme.get, call_603415.host, call_603415.base,
                         call_603415.route, valid.getOrDefault("path"))
  result = hook(call_603415, url, valid)

proc call*(call_603416: Call_DescribeAssociation_603403; body: JsonNode): Recallable =
  ## describeAssociation
  ## Describes the association for the specified target or instance. If you created the association by using the <code>Targets</code> parameter, then you must retrieve the association by using the association ID. If you created the association by specifying an instance ID and a Systems Manager document, then you retrieve the association by specifying the document name and the instance ID. 
  ##   body: JObject (required)
  var body_603417 = newJObject()
  if body != nil:
    body_603417 = body
  result = call_603416.call(nil, nil, nil, nil, body_603417)

var describeAssociation* = Call_DescribeAssociation_603403(
    name: "describeAssociation", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAssociation",
    validator: validate_DescribeAssociation_603404, base: "/",
    url: url_DescribeAssociation_603405, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAssociationExecutionTargets_603418 = ref object of OpenApiRestCall_602433
proc url_DescribeAssociationExecutionTargets_603420(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeAssociationExecutionTargets_603419(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603421 = header.getOrDefault("X-Amz-Date")
  valid_603421 = validateParameter(valid_603421, JString, required = false,
                                 default = nil)
  if valid_603421 != nil:
    section.add "X-Amz-Date", valid_603421
  var valid_603422 = header.getOrDefault("X-Amz-Security-Token")
  valid_603422 = validateParameter(valid_603422, JString, required = false,
                                 default = nil)
  if valid_603422 != nil:
    section.add "X-Amz-Security-Token", valid_603422
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603423 = header.getOrDefault("X-Amz-Target")
  valid_603423 = validateParameter(valid_603423, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAssociationExecutionTargets"))
  if valid_603423 != nil:
    section.add "X-Amz-Target", valid_603423
  var valid_603424 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603424 = validateParameter(valid_603424, JString, required = false,
                                 default = nil)
  if valid_603424 != nil:
    section.add "X-Amz-Content-Sha256", valid_603424
  var valid_603425 = header.getOrDefault("X-Amz-Algorithm")
  valid_603425 = validateParameter(valid_603425, JString, required = false,
                                 default = nil)
  if valid_603425 != nil:
    section.add "X-Amz-Algorithm", valid_603425
  var valid_603426 = header.getOrDefault("X-Amz-Signature")
  valid_603426 = validateParameter(valid_603426, JString, required = false,
                                 default = nil)
  if valid_603426 != nil:
    section.add "X-Amz-Signature", valid_603426
  var valid_603427 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603427 = validateParameter(valid_603427, JString, required = false,
                                 default = nil)
  if valid_603427 != nil:
    section.add "X-Amz-SignedHeaders", valid_603427
  var valid_603428 = header.getOrDefault("X-Amz-Credential")
  valid_603428 = validateParameter(valid_603428, JString, required = false,
                                 default = nil)
  if valid_603428 != nil:
    section.add "X-Amz-Credential", valid_603428
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603430: Call_DescribeAssociationExecutionTargets_603418;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Use this API action to view information about a specific execution of a specific association.
  ## 
  let valid = call_603430.validator(path, query, header, formData, body)
  let scheme = call_603430.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603430.url(scheme.get, call_603430.host, call_603430.base,
                         call_603430.route, valid.getOrDefault("path"))
  result = hook(call_603430, url, valid)

proc call*(call_603431: Call_DescribeAssociationExecutionTargets_603418;
          body: JsonNode): Recallable =
  ## describeAssociationExecutionTargets
  ## Use this API action to view information about a specific execution of a specific association.
  ##   body: JObject (required)
  var body_603432 = newJObject()
  if body != nil:
    body_603432 = body
  result = call_603431.call(nil, nil, nil, nil, body_603432)

var describeAssociationExecutionTargets* = Call_DescribeAssociationExecutionTargets_603418(
    name: "describeAssociationExecutionTargets", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAssociationExecutionTargets",
    validator: validate_DescribeAssociationExecutionTargets_603419, base: "/",
    url: url_DescribeAssociationExecutionTargets_603420,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAssociationExecutions_603433 = ref object of OpenApiRestCall_602433
proc url_DescribeAssociationExecutions_603435(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeAssociationExecutions_603434(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603436 = header.getOrDefault("X-Amz-Date")
  valid_603436 = validateParameter(valid_603436, JString, required = false,
                                 default = nil)
  if valid_603436 != nil:
    section.add "X-Amz-Date", valid_603436
  var valid_603437 = header.getOrDefault("X-Amz-Security-Token")
  valid_603437 = validateParameter(valid_603437, JString, required = false,
                                 default = nil)
  if valid_603437 != nil:
    section.add "X-Amz-Security-Token", valid_603437
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603438 = header.getOrDefault("X-Amz-Target")
  valid_603438 = validateParameter(valid_603438, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAssociationExecutions"))
  if valid_603438 != nil:
    section.add "X-Amz-Target", valid_603438
  var valid_603439 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603439 = validateParameter(valid_603439, JString, required = false,
                                 default = nil)
  if valid_603439 != nil:
    section.add "X-Amz-Content-Sha256", valid_603439
  var valid_603440 = header.getOrDefault("X-Amz-Algorithm")
  valid_603440 = validateParameter(valid_603440, JString, required = false,
                                 default = nil)
  if valid_603440 != nil:
    section.add "X-Amz-Algorithm", valid_603440
  var valid_603441 = header.getOrDefault("X-Amz-Signature")
  valid_603441 = validateParameter(valid_603441, JString, required = false,
                                 default = nil)
  if valid_603441 != nil:
    section.add "X-Amz-Signature", valid_603441
  var valid_603442 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603442 = validateParameter(valid_603442, JString, required = false,
                                 default = nil)
  if valid_603442 != nil:
    section.add "X-Amz-SignedHeaders", valid_603442
  var valid_603443 = header.getOrDefault("X-Amz-Credential")
  valid_603443 = validateParameter(valid_603443, JString, required = false,
                                 default = nil)
  if valid_603443 != nil:
    section.add "X-Amz-Credential", valid_603443
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603445: Call_DescribeAssociationExecutions_603433; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Use this API action to view all executions for a specific association ID. 
  ## 
  let valid = call_603445.validator(path, query, header, formData, body)
  let scheme = call_603445.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603445.url(scheme.get, call_603445.host, call_603445.base,
                         call_603445.route, valid.getOrDefault("path"))
  result = hook(call_603445, url, valid)

proc call*(call_603446: Call_DescribeAssociationExecutions_603433; body: JsonNode): Recallable =
  ## describeAssociationExecutions
  ## Use this API action to view all executions for a specific association ID. 
  ##   body: JObject (required)
  var body_603447 = newJObject()
  if body != nil:
    body_603447 = body
  result = call_603446.call(nil, nil, nil, nil, body_603447)

var describeAssociationExecutions* = Call_DescribeAssociationExecutions_603433(
    name: "describeAssociationExecutions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAssociationExecutions",
    validator: validate_DescribeAssociationExecutions_603434, base: "/",
    url: url_DescribeAssociationExecutions_603435,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAutomationExecutions_603448 = ref object of OpenApiRestCall_602433
proc url_DescribeAutomationExecutions_603450(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeAutomationExecutions_603449(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603451 = header.getOrDefault("X-Amz-Date")
  valid_603451 = validateParameter(valid_603451, JString, required = false,
                                 default = nil)
  if valid_603451 != nil:
    section.add "X-Amz-Date", valid_603451
  var valid_603452 = header.getOrDefault("X-Amz-Security-Token")
  valid_603452 = validateParameter(valid_603452, JString, required = false,
                                 default = nil)
  if valid_603452 != nil:
    section.add "X-Amz-Security-Token", valid_603452
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603453 = header.getOrDefault("X-Amz-Target")
  valid_603453 = validateParameter(valid_603453, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAutomationExecutions"))
  if valid_603453 != nil:
    section.add "X-Amz-Target", valid_603453
  var valid_603454 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603454 = validateParameter(valid_603454, JString, required = false,
                                 default = nil)
  if valid_603454 != nil:
    section.add "X-Amz-Content-Sha256", valid_603454
  var valid_603455 = header.getOrDefault("X-Amz-Algorithm")
  valid_603455 = validateParameter(valid_603455, JString, required = false,
                                 default = nil)
  if valid_603455 != nil:
    section.add "X-Amz-Algorithm", valid_603455
  var valid_603456 = header.getOrDefault("X-Amz-Signature")
  valid_603456 = validateParameter(valid_603456, JString, required = false,
                                 default = nil)
  if valid_603456 != nil:
    section.add "X-Amz-Signature", valid_603456
  var valid_603457 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603457 = validateParameter(valid_603457, JString, required = false,
                                 default = nil)
  if valid_603457 != nil:
    section.add "X-Amz-SignedHeaders", valid_603457
  var valid_603458 = header.getOrDefault("X-Amz-Credential")
  valid_603458 = validateParameter(valid_603458, JString, required = false,
                                 default = nil)
  if valid_603458 != nil:
    section.add "X-Amz-Credential", valid_603458
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603460: Call_DescribeAutomationExecutions_603448; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides details about all active and terminated Automation executions.
  ## 
  let valid = call_603460.validator(path, query, header, formData, body)
  let scheme = call_603460.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603460.url(scheme.get, call_603460.host, call_603460.base,
                         call_603460.route, valid.getOrDefault("path"))
  result = hook(call_603460, url, valid)

proc call*(call_603461: Call_DescribeAutomationExecutions_603448; body: JsonNode): Recallable =
  ## describeAutomationExecutions
  ## Provides details about all active and terminated Automation executions.
  ##   body: JObject (required)
  var body_603462 = newJObject()
  if body != nil:
    body_603462 = body
  result = call_603461.call(nil, nil, nil, nil, body_603462)

var describeAutomationExecutions* = Call_DescribeAutomationExecutions_603448(
    name: "describeAutomationExecutions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAutomationExecutions",
    validator: validate_DescribeAutomationExecutions_603449, base: "/",
    url: url_DescribeAutomationExecutions_603450,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAutomationStepExecutions_603463 = ref object of OpenApiRestCall_602433
proc url_DescribeAutomationStepExecutions_603465(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeAutomationStepExecutions_603464(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603466 = header.getOrDefault("X-Amz-Date")
  valid_603466 = validateParameter(valid_603466, JString, required = false,
                                 default = nil)
  if valid_603466 != nil:
    section.add "X-Amz-Date", valid_603466
  var valid_603467 = header.getOrDefault("X-Amz-Security-Token")
  valid_603467 = validateParameter(valid_603467, JString, required = false,
                                 default = nil)
  if valid_603467 != nil:
    section.add "X-Amz-Security-Token", valid_603467
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603468 = header.getOrDefault("X-Amz-Target")
  valid_603468 = validateParameter(valid_603468, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAutomationStepExecutions"))
  if valid_603468 != nil:
    section.add "X-Amz-Target", valid_603468
  var valid_603469 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603469 = validateParameter(valid_603469, JString, required = false,
                                 default = nil)
  if valid_603469 != nil:
    section.add "X-Amz-Content-Sha256", valid_603469
  var valid_603470 = header.getOrDefault("X-Amz-Algorithm")
  valid_603470 = validateParameter(valid_603470, JString, required = false,
                                 default = nil)
  if valid_603470 != nil:
    section.add "X-Amz-Algorithm", valid_603470
  var valid_603471 = header.getOrDefault("X-Amz-Signature")
  valid_603471 = validateParameter(valid_603471, JString, required = false,
                                 default = nil)
  if valid_603471 != nil:
    section.add "X-Amz-Signature", valid_603471
  var valid_603472 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603472 = validateParameter(valid_603472, JString, required = false,
                                 default = nil)
  if valid_603472 != nil:
    section.add "X-Amz-SignedHeaders", valid_603472
  var valid_603473 = header.getOrDefault("X-Amz-Credential")
  valid_603473 = validateParameter(valid_603473, JString, required = false,
                                 default = nil)
  if valid_603473 != nil:
    section.add "X-Amz-Credential", valid_603473
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603475: Call_DescribeAutomationStepExecutions_603463;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Information about all active and terminated step executions in an Automation workflow.
  ## 
  let valid = call_603475.validator(path, query, header, formData, body)
  let scheme = call_603475.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603475.url(scheme.get, call_603475.host, call_603475.base,
                         call_603475.route, valid.getOrDefault("path"))
  result = hook(call_603475, url, valid)

proc call*(call_603476: Call_DescribeAutomationStepExecutions_603463;
          body: JsonNode): Recallable =
  ## describeAutomationStepExecutions
  ## Information about all active and terminated step executions in an Automation workflow.
  ##   body: JObject (required)
  var body_603477 = newJObject()
  if body != nil:
    body_603477 = body
  result = call_603476.call(nil, nil, nil, nil, body_603477)

var describeAutomationStepExecutions* = Call_DescribeAutomationStepExecutions_603463(
    name: "describeAutomationStepExecutions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAutomationStepExecutions",
    validator: validate_DescribeAutomationStepExecutions_603464, base: "/",
    url: url_DescribeAutomationStepExecutions_603465,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAvailablePatches_603478 = ref object of OpenApiRestCall_602433
proc url_DescribeAvailablePatches_603480(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeAvailablePatches_603479(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603481 = header.getOrDefault("X-Amz-Date")
  valid_603481 = validateParameter(valid_603481, JString, required = false,
                                 default = nil)
  if valid_603481 != nil:
    section.add "X-Amz-Date", valid_603481
  var valid_603482 = header.getOrDefault("X-Amz-Security-Token")
  valid_603482 = validateParameter(valid_603482, JString, required = false,
                                 default = nil)
  if valid_603482 != nil:
    section.add "X-Amz-Security-Token", valid_603482
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603483 = header.getOrDefault("X-Amz-Target")
  valid_603483 = validateParameter(valid_603483, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAvailablePatches"))
  if valid_603483 != nil:
    section.add "X-Amz-Target", valid_603483
  var valid_603484 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603484 = validateParameter(valid_603484, JString, required = false,
                                 default = nil)
  if valid_603484 != nil:
    section.add "X-Amz-Content-Sha256", valid_603484
  var valid_603485 = header.getOrDefault("X-Amz-Algorithm")
  valid_603485 = validateParameter(valid_603485, JString, required = false,
                                 default = nil)
  if valid_603485 != nil:
    section.add "X-Amz-Algorithm", valid_603485
  var valid_603486 = header.getOrDefault("X-Amz-Signature")
  valid_603486 = validateParameter(valid_603486, JString, required = false,
                                 default = nil)
  if valid_603486 != nil:
    section.add "X-Amz-Signature", valid_603486
  var valid_603487 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603487 = validateParameter(valid_603487, JString, required = false,
                                 default = nil)
  if valid_603487 != nil:
    section.add "X-Amz-SignedHeaders", valid_603487
  var valid_603488 = header.getOrDefault("X-Amz-Credential")
  valid_603488 = validateParameter(valid_603488, JString, required = false,
                                 default = nil)
  if valid_603488 != nil:
    section.add "X-Amz-Credential", valid_603488
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603490: Call_DescribeAvailablePatches_603478; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all patches eligible to be included in a patch baseline.
  ## 
  let valid = call_603490.validator(path, query, header, formData, body)
  let scheme = call_603490.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603490.url(scheme.get, call_603490.host, call_603490.base,
                         call_603490.route, valid.getOrDefault("path"))
  result = hook(call_603490, url, valid)

proc call*(call_603491: Call_DescribeAvailablePatches_603478; body: JsonNode): Recallable =
  ## describeAvailablePatches
  ## Lists all patches eligible to be included in a patch baseline.
  ##   body: JObject (required)
  var body_603492 = newJObject()
  if body != nil:
    body_603492 = body
  result = call_603491.call(nil, nil, nil, nil, body_603492)

var describeAvailablePatches* = Call_DescribeAvailablePatches_603478(
    name: "describeAvailablePatches", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAvailablePatches",
    validator: validate_DescribeAvailablePatches_603479, base: "/",
    url: url_DescribeAvailablePatches_603480, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDocument_603493 = ref object of OpenApiRestCall_602433
proc url_DescribeDocument_603495(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeDocument_603494(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603496 = header.getOrDefault("X-Amz-Date")
  valid_603496 = validateParameter(valid_603496, JString, required = false,
                                 default = nil)
  if valid_603496 != nil:
    section.add "X-Amz-Date", valid_603496
  var valid_603497 = header.getOrDefault("X-Amz-Security-Token")
  valid_603497 = validateParameter(valid_603497, JString, required = false,
                                 default = nil)
  if valid_603497 != nil:
    section.add "X-Amz-Security-Token", valid_603497
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603498 = header.getOrDefault("X-Amz-Target")
  valid_603498 = validateParameter(valid_603498, JString, required = true, default = newJString(
      "AmazonSSM.DescribeDocument"))
  if valid_603498 != nil:
    section.add "X-Amz-Target", valid_603498
  var valid_603499 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603499 = validateParameter(valid_603499, JString, required = false,
                                 default = nil)
  if valid_603499 != nil:
    section.add "X-Amz-Content-Sha256", valid_603499
  var valid_603500 = header.getOrDefault("X-Amz-Algorithm")
  valid_603500 = validateParameter(valid_603500, JString, required = false,
                                 default = nil)
  if valid_603500 != nil:
    section.add "X-Amz-Algorithm", valid_603500
  var valid_603501 = header.getOrDefault("X-Amz-Signature")
  valid_603501 = validateParameter(valid_603501, JString, required = false,
                                 default = nil)
  if valid_603501 != nil:
    section.add "X-Amz-Signature", valid_603501
  var valid_603502 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603502 = validateParameter(valid_603502, JString, required = false,
                                 default = nil)
  if valid_603502 != nil:
    section.add "X-Amz-SignedHeaders", valid_603502
  var valid_603503 = header.getOrDefault("X-Amz-Credential")
  valid_603503 = validateParameter(valid_603503, JString, required = false,
                                 default = nil)
  if valid_603503 != nil:
    section.add "X-Amz-Credential", valid_603503
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603505: Call_DescribeDocument_603493; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified Systems Manager document.
  ## 
  let valid = call_603505.validator(path, query, header, formData, body)
  let scheme = call_603505.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603505.url(scheme.get, call_603505.host, call_603505.base,
                         call_603505.route, valid.getOrDefault("path"))
  result = hook(call_603505, url, valid)

proc call*(call_603506: Call_DescribeDocument_603493; body: JsonNode): Recallable =
  ## describeDocument
  ## Describes the specified Systems Manager document.
  ##   body: JObject (required)
  var body_603507 = newJObject()
  if body != nil:
    body_603507 = body
  result = call_603506.call(nil, nil, nil, nil, body_603507)

var describeDocument* = Call_DescribeDocument_603493(name: "describeDocument",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeDocument",
    validator: validate_DescribeDocument_603494, base: "/",
    url: url_DescribeDocument_603495, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDocumentPermission_603508 = ref object of OpenApiRestCall_602433
proc url_DescribeDocumentPermission_603510(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeDocumentPermission_603509(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603511 = header.getOrDefault("X-Amz-Date")
  valid_603511 = validateParameter(valid_603511, JString, required = false,
                                 default = nil)
  if valid_603511 != nil:
    section.add "X-Amz-Date", valid_603511
  var valid_603512 = header.getOrDefault("X-Amz-Security-Token")
  valid_603512 = validateParameter(valid_603512, JString, required = false,
                                 default = nil)
  if valid_603512 != nil:
    section.add "X-Amz-Security-Token", valid_603512
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603513 = header.getOrDefault("X-Amz-Target")
  valid_603513 = validateParameter(valid_603513, JString, required = true, default = newJString(
      "AmazonSSM.DescribeDocumentPermission"))
  if valid_603513 != nil:
    section.add "X-Amz-Target", valid_603513
  var valid_603514 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603514 = validateParameter(valid_603514, JString, required = false,
                                 default = nil)
  if valid_603514 != nil:
    section.add "X-Amz-Content-Sha256", valid_603514
  var valid_603515 = header.getOrDefault("X-Amz-Algorithm")
  valid_603515 = validateParameter(valid_603515, JString, required = false,
                                 default = nil)
  if valid_603515 != nil:
    section.add "X-Amz-Algorithm", valid_603515
  var valid_603516 = header.getOrDefault("X-Amz-Signature")
  valid_603516 = validateParameter(valid_603516, JString, required = false,
                                 default = nil)
  if valid_603516 != nil:
    section.add "X-Amz-Signature", valid_603516
  var valid_603517 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603517 = validateParameter(valid_603517, JString, required = false,
                                 default = nil)
  if valid_603517 != nil:
    section.add "X-Amz-SignedHeaders", valid_603517
  var valid_603518 = header.getOrDefault("X-Amz-Credential")
  valid_603518 = validateParameter(valid_603518, JString, required = false,
                                 default = nil)
  if valid_603518 != nil:
    section.add "X-Amz-Credential", valid_603518
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603520: Call_DescribeDocumentPermission_603508; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the permissions for a Systems Manager document. If you created the document, you are the owner. If a document is shared, it can either be shared privately (by specifying a user's AWS account ID) or publicly (<i>All</i>). 
  ## 
  let valid = call_603520.validator(path, query, header, formData, body)
  let scheme = call_603520.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603520.url(scheme.get, call_603520.host, call_603520.base,
                         call_603520.route, valid.getOrDefault("path"))
  result = hook(call_603520, url, valid)

proc call*(call_603521: Call_DescribeDocumentPermission_603508; body: JsonNode): Recallable =
  ## describeDocumentPermission
  ## Describes the permissions for a Systems Manager document. If you created the document, you are the owner. If a document is shared, it can either be shared privately (by specifying a user's AWS account ID) or publicly (<i>All</i>). 
  ##   body: JObject (required)
  var body_603522 = newJObject()
  if body != nil:
    body_603522 = body
  result = call_603521.call(nil, nil, nil, nil, body_603522)

var describeDocumentPermission* = Call_DescribeDocumentPermission_603508(
    name: "describeDocumentPermission", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeDocumentPermission",
    validator: validate_DescribeDocumentPermission_603509, base: "/",
    url: url_DescribeDocumentPermission_603510,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEffectiveInstanceAssociations_603523 = ref object of OpenApiRestCall_602433
proc url_DescribeEffectiveInstanceAssociations_603525(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeEffectiveInstanceAssociations_603524(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603526 = header.getOrDefault("X-Amz-Date")
  valid_603526 = validateParameter(valid_603526, JString, required = false,
                                 default = nil)
  if valid_603526 != nil:
    section.add "X-Amz-Date", valid_603526
  var valid_603527 = header.getOrDefault("X-Amz-Security-Token")
  valid_603527 = validateParameter(valid_603527, JString, required = false,
                                 default = nil)
  if valid_603527 != nil:
    section.add "X-Amz-Security-Token", valid_603527
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603528 = header.getOrDefault("X-Amz-Target")
  valid_603528 = validateParameter(valid_603528, JString, required = true, default = newJString(
      "AmazonSSM.DescribeEffectiveInstanceAssociations"))
  if valid_603528 != nil:
    section.add "X-Amz-Target", valid_603528
  var valid_603529 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603529 = validateParameter(valid_603529, JString, required = false,
                                 default = nil)
  if valid_603529 != nil:
    section.add "X-Amz-Content-Sha256", valid_603529
  var valid_603530 = header.getOrDefault("X-Amz-Algorithm")
  valid_603530 = validateParameter(valid_603530, JString, required = false,
                                 default = nil)
  if valid_603530 != nil:
    section.add "X-Amz-Algorithm", valid_603530
  var valid_603531 = header.getOrDefault("X-Amz-Signature")
  valid_603531 = validateParameter(valid_603531, JString, required = false,
                                 default = nil)
  if valid_603531 != nil:
    section.add "X-Amz-Signature", valid_603531
  var valid_603532 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603532 = validateParameter(valid_603532, JString, required = false,
                                 default = nil)
  if valid_603532 != nil:
    section.add "X-Amz-SignedHeaders", valid_603532
  var valid_603533 = header.getOrDefault("X-Amz-Credential")
  valid_603533 = validateParameter(valid_603533, JString, required = false,
                                 default = nil)
  if valid_603533 != nil:
    section.add "X-Amz-Credential", valid_603533
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603535: Call_DescribeEffectiveInstanceAssociations_603523;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## All associations for the instance(s).
  ## 
  let valid = call_603535.validator(path, query, header, formData, body)
  let scheme = call_603535.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603535.url(scheme.get, call_603535.host, call_603535.base,
                         call_603535.route, valid.getOrDefault("path"))
  result = hook(call_603535, url, valid)

proc call*(call_603536: Call_DescribeEffectiveInstanceAssociations_603523;
          body: JsonNode): Recallable =
  ## describeEffectiveInstanceAssociations
  ## All associations for the instance(s).
  ##   body: JObject (required)
  var body_603537 = newJObject()
  if body != nil:
    body_603537 = body
  result = call_603536.call(nil, nil, nil, nil, body_603537)

var describeEffectiveInstanceAssociations* = Call_DescribeEffectiveInstanceAssociations_603523(
    name: "describeEffectiveInstanceAssociations", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeEffectiveInstanceAssociations",
    validator: validate_DescribeEffectiveInstanceAssociations_603524, base: "/",
    url: url_DescribeEffectiveInstanceAssociations_603525,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEffectivePatchesForPatchBaseline_603538 = ref object of OpenApiRestCall_602433
proc url_DescribeEffectivePatchesForPatchBaseline_603540(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeEffectivePatchesForPatchBaseline_603539(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603541 = header.getOrDefault("X-Amz-Date")
  valid_603541 = validateParameter(valid_603541, JString, required = false,
                                 default = nil)
  if valid_603541 != nil:
    section.add "X-Amz-Date", valid_603541
  var valid_603542 = header.getOrDefault("X-Amz-Security-Token")
  valid_603542 = validateParameter(valid_603542, JString, required = false,
                                 default = nil)
  if valid_603542 != nil:
    section.add "X-Amz-Security-Token", valid_603542
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603543 = header.getOrDefault("X-Amz-Target")
  valid_603543 = validateParameter(valid_603543, JString, required = true, default = newJString(
      "AmazonSSM.DescribeEffectivePatchesForPatchBaseline"))
  if valid_603543 != nil:
    section.add "X-Amz-Target", valid_603543
  var valid_603544 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603544 = validateParameter(valid_603544, JString, required = false,
                                 default = nil)
  if valid_603544 != nil:
    section.add "X-Amz-Content-Sha256", valid_603544
  var valid_603545 = header.getOrDefault("X-Amz-Algorithm")
  valid_603545 = validateParameter(valid_603545, JString, required = false,
                                 default = nil)
  if valid_603545 != nil:
    section.add "X-Amz-Algorithm", valid_603545
  var valid_603546 = header.getOrDefault("X-Amz-Signature")
  valid_603546 = validateParameter(valid_603546, JString, required = false,
                                 default = nil)
  if valid_603546 != nil:
    section.add "X-Amz-Signature", valid_603546
  var valid_603547 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603547 = validateParameter(valid_603547, JString, required = false,
                                 default = nil)
  if valid_603547 != nil:
    section.add "X-Amz-SignedHeaders", valid_603547
  var valid_603548 = header.getOrDefault("X-Amz-Credential")
  valid_603548 = validateParameter(valid_603548, JString, required = false,
                                 default = nil)
  if valid_603548 != nil:
    section.add "X-Amz-Credential", valid_603548
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603550: Call_DescribeEffectivePatchesForPatchBaseline_603538;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the current effective patches (the patch and the approval state) for the specified patch baseline. Note that this API applies only to Windows patch baselines.
  ## 
  let valid = call_603550.validator(path, query, header, formData, body)
  let scheme = call_603550.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603550.url(scheme.get, call_603550.host, call_603550.base,
                         call_603550.route, valid.getOrDefault("path"))
  result = hook(call_603550, url, valid)

proc call*(call_603551: Call_DescribeEffectivePatchesForPatchBaseline_603538;
          body: JsonNode): Recallable =
  ## describeEffectivePatchesForPatchBaseline
  ## Retrieves the current effective patches (the patch and the approval state) for the specified patch baseline. Note that this API applies only to Windows patch baselines.
  ##   body: JObject (required)
  var body_603552 = newJObject()
  if body != nil:
    body_603552 = body
  result = call_603551.call(nil, nil, nil, nil, body_603552)

var describeEffectivePatchesForPatchBaseline* = Call_DescribeEffectivePatchesForPatchBaseline_603538(
    name: "describeEffectivePatchesForPatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeEffectivePatchesForPatchBaseline",
    validator: validate_DescribeEffectivePatchesForPatchBaseline_603539,
    base: "/", url: url_DescribeEffectivePatchesForPatchBaseline_603540,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInstanceAssociationsStatus_603553 = ref object of OpenApiRestCall_602433
proc url_DescribeInstanceAssociationsStatus_603555(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeInstanceAssociationsStatus_603554(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603556 = header.getOrDefault("X-Amz-Date")
  valid_603556 = validateParameter(valid_603556, JString, required = false,
                                 default = nil)
  if valid_603556 != nil:
    section.add "X-Amz-Date", valid_603556
  var valid_603557 = header.getOrDefault("X-Amz-Security-Token")
  valid_603557 = validateParameter(valid_603557, JString, required = false,
                                 default = nil)
  if valid_603557 != nil:
    section.add "X-Amz-Security-Token", valid_603557
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603558 = header.getOrDefault("X-Amz-Target")
  valid_603558 = validateParameter(valid_603558, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInstanceAssociationsStatus"))
  if valid_603558 != nil:
    section.add "X-Amz-Target", valid_603558
  var valid_603559 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603559 = validateParameter(valid_603559, JString, required = false,
                                 default = nil)
  if valid_603559 != nil:
    section.add "X-Amz-Content-Sha256", valid_603559
  var valid_603560 = header.getOrDefault("X-Amz-Algorithm")
  valid_603560 = validateParameter(valid_603560, JString, required = false,
                                 default = nil)
  if valid_603560 != nil:
    section.add "X-Amz-Algorithm", valid_603560
  var valid_603561 = header.getOrDefault("X-Amz-Signature")
  valid_603561 = validateParameter(valid_603561, JString, required = false,
                                 default = nil)
  if valid_603561 != nil:
    section.add "X-Amz-Signature", valid_603561
  var valid_603562 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603562 = validateParameter(valid_603562, JString, required = false,
                                 default = nil)
  if valid_603562 != nil:
    section.add "X-Amz-SignedHeaders", valid_603562
  var valid_603563 = header.getOrDefault("X-Amz-Credential")
  valid_603563 = validateParameter(valid_603563, JString, required = false,
                                 default = nil)
  if valid_603563 != nil:
    section.add "X-Amz-Credential", valid_603563
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603565: Call_DescribeInstanceAssociationsStatus_603553;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## The status of the associations for the instance(s).
  ## 
  let valid = call_603565.validator(path, query, header, formData, body)
  let scheme = call_603565.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603565.url(scheme.get, call_603565.host, call_603565.base,
                         call_603565.route, valid.getOrDefault("path"))
  result = hook(call_603565, url, valid)

proc call*(call_603566: Call_DescribeInstanceAssociationsStatus_603553;
          body: JsonNode): Recallable =
  ## describeInstanceAssociationsStatus
  ## The status of the associations for the instance(s).
  ##   body: JObject (required)
  var body_603567 = newJObject()
  if body != nil:
    body_603567 = body
  result = call_603566.call(nil, nil, nil, nil, body_603567)

var describeInstanceAssociationsStatus* = Call_DescribeInstanceAssociationsStatus_603553(
    name: "describeInstanceAssociationsStatus", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInstanceAssociationsStatus",
    validator: validate_DescribeInstanceAssociationsStatus_603554, base: "/",
    url: url_DescribeInstanceAssociationsStatus_603555,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInstanceInformation_603568 = ref object of OpenApiRestCall_602433
proc url_DescribeInstanceInformation_603570(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeInstanceInformation_603569(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes one or more of your instances. You can use this to get information about instances like the operating system platform, the SSM Agent version (Linux), status etc. If you specify one or more instance IDs, it returns information for those instances. If you do not specify instance IDs, it returns information for all your instances. If you specify an instance ID that is not valid or an instance that you do not own, you receive an error. </p> <note> <p>The IamRole field for this API action is the Amazon Identity and Access Management (IAM) role assigned to on-premises instances. This call does not return the IAM role for Amazon EC2 instances.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_603571 = query.getOrDefault("NextToken")
  valid_603571 = validateParameter(valid_603571, JString, required = false,
                                 default = nil)
  if valid_603571 != nil:
    section.add "NextToken", valid_603571
  var valid_603572 = query.getOrDefault("MaxResults")
  valid_603572 = validateParameter(valid_603572, JString, required = false,
                                 default = nil)
  if valid_603572 != nil:
    section.add "MaxResults", valid_603572
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603573 = header.getOrDefault("X-Amz-Date")
  valid_603573 = validateParameter(valid_603573, JString, required = false,
                                 default = nil)
  if valid_603573 != nil:
    section.add "X-Amz-Date", valid_603573
  var valid_603574 = header.getOrDefault("X-Amz-Security-Token")
  valid_603574 = validateParameter(valid_603574, JString, required = false,
                                 default = nil)
  if valid_603574 != nil:
    section.add "X-Amz-Security-Token", valid_603574
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603575 = header.getOrDefault("X-Amz-Target")
  valid_603575 = validateParameter(valid_603575, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInstanceInformation"))
  if valid_603575 != nil:
    section.add "X-Amz-Target", valid_603575
  var valid_603576 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603576 = validateParameter(valid_603576, JString, required = false,
                                 default = nil)
  if valid_603576 != nil:
    section.add "X-Amz-Content-Sha256", valid_603576
  var valid_603577 = header.getOrDefault("X-Amz-Algorithm")
  valid_603577 = validateParameter(valid_603577, JString, required = false,
                                 default = nil)
  if valid_603577 != nil:
    section.add "X-Amz-Algorithm", valid_603577
  var valid_603578 = header.getOrDefault("X-Amz-Signature")
  valid_603578 = validateParameter(valid_603578, JString, required = false,
                                 default = nil)
  if valid_603578 != nil:
    section.add "X-Amz-Signature", valid_603578
  var valid_603579 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603579 = validateParameter(valid_603579, JString, required = false,
                                 default = nil)
  if valid_603579 != nil:
    section.add "X-Amz-SignedHeaders", valid_603579
  var valid_603580 = header.getOrDefault("X-Amz-Credential")
  valid_603580 = validateParameter(valid_603580, JString, required = false,
                                 default = nil)
  if valid_603580 != nil:
    section.add "X-Amz-Credential", valid_603580
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603582: Call_DescribeInstanceInformation_603568; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes one or more of your instances. You can use this to get information about instances like the operating system platform, the SSM Agent version (Linux), status etc. If you specify one or more instance IDs, it returns information for those instances. If you do not specify instance IDs, it returns information for all your instances. If you specify an instance ID that is not valid or an instance that you do not own, you receive an error. </p> <note> <p>The IamRole field for this API action is the Amazon Identity and Access Management (IAM) role assigned to on-premises instances. This call does not return the IAM role for Amazon EC2 instances.</p> </note>
  ## 
  let valid = call_603582.validator(path, query, header, formData, body)
  let scheme = call_603582.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603582.url(scheme.get, call_603582.host, call_603582.base,
                         call_603582.route, valid.getOrDefault("path"))
  result = hook(call_603582, url, valid)

proc call*(call_603583: Call_DescribeInstanceInformation_603568; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## describeInstanceInformation
  ## <p>Describes one or more of your instances. You can use this to get information about instances like the operating system platform, the SSM Agent version (Linux), status etc. If you specify one or more instance IDs, it returns information for those instances. If you do not specify instance IDs, it returns information for all your instances. If you specify an instance ID that is not valid or an instance that you do not own, you receive an error. </p> <note> <p>The IamRole field for this API action is the Amazon Identity and Access Management (IAM) role assigned to on-premises instances. This call does not return the IAM role for Amazon EC2 instances.</p> </note>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603584 = newJObject()
  var body_603585 = newJObject()
  add(query_603584, "NextToken", newJString(NextToken))
  if body != nil:
    body_603585 = body
  add(query_603584, "MaxResults", newJString(MaxResults))
  result = call_603583.call(nil, query_603584, nil, nil, body_603585)

var describeInstanceInformation* = Call_DescribeInstanceInformation_603568(
    name: "describeInstanceInformation", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInstanceInformation",
    validator: validate_DescribeInstanceInformation_603569, base: "/",
    url: url_DescribeInstanceInformation_603570,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInstancePatchStates_603586 = ref object of OpenApiRestCall_602433
proc url_DescribeInstancePatchStates_603588(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeInstancePatchStates_603587(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603589 = header.getOrDefault("X-Amz-Date")
  valid_603589 = validateParameter(valid_603589, JString, required = false,
                                 default = nil)
  if valid_603589 != nil:
    section.add "X-Amz-Date", valid_603589
  var valid_603590 = header.getOrDefault("X-Amz-Security-Token")
  valid_603590 = validateParameter(valid_603590, JString, required = false,
                                 default = nil)
  if valid_603590 != nil:
    section.add "X-Amz-Security-Token", valid_603590
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603591 = header.getOrDefault("X-Amz-Target")
  valid_603591 = validateParameter(valid_603591, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInstancePatchStates"))
  if valid_603591 != nil:
    section.add "X-Amz-Target", valid_603591
  var valid_603592 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603592 = validateParameter(valid_603592, JString, required = false,
                                 default = nil)
  if valid_603592 != nil:
    section.add "X-Amz-Content-Sha256", valid_603592
  var valid_603593 = header.getOrDefault("X-Amz-Algorithm")
  valid_603593 = validateParameter(valid_603593, JString, required = false,
                                 default = nil)
  if valid_603593 != nil:
    section.add "X-Amz-Algorithm", valid_603593
  var valid_603594 = header.getOrDefault("X-Amz-Signature")
  valid_603594 = validateParameter(valid_603594, JString, required = false,
                                 default = nil)
  if valid_603594 != nil:
    section.add "X-Amz-Signature", valid_603594
  var valid_603595 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603595 = validateParameter(valid_603595, JString, required = false,
                                 default = nil)
  if valid_603595 != nil:
    section.add "X-Amz-SignedHeaders", valid_603595
  var valid_603596 = header.getOrDefault("X-Amz-Credential")
  valid_603596 = validateParameter(valid_603596, JString, required = false,
                                 default = nil)
  if valid_603596 != nil:
    section.add "X-Amz-Credential", valid_603596
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603598: Call_DescribeInstancePatchStates_603586; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the high-level patch state of one or more instances.
  ## 
  let valid = call_603598.validator(path, query, header, formData, body)
  let scheme = call_603598.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603598.url(scheme.get, call_603598.host, call_603598.base,
                         call_603598.route, valid.getOrDefault("path"))
  result = hook(call_603598, url, valid)

proc call*(call_603599: Call_DescribeInstancePatchStates_603586; body: JsonNode): Recallable =
  ## describeInstancePatchStates
  ## Retrieves the high-level patch state of one or more instances.
  ##   body: JObject (required)
  var body_603600 = newJObject()
  if body != nil:
    body_603600 = body
  result = call_603599.call(nil, nil, nil, nil, body_603600)

var describeInstancePatchStates* = Call_DescribeInstancePatchStates_603586(
    name: "describeInstancePatchStates", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInstancePatchStates",
    validator: validate_DescribeInstancePatchStates_603587, base: "/",
    url: url_DescribeInstancePatchStates_603588,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInstancePatchStatesForPatchGroup_603601 = ref object of OpenApiRestCall_602433
proc url_DescribeInstancePatchStatesForPatchGroup_603603(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeInstancePatchStatesForPatchGroup_603602(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603604 = header.getOrDefault("X-Amz-Date")
  valid_603604 = validateParameter(valid_603604, JString, required = false,
                                 default = nil)
  if valid_603604 != nil:
    section.add "X-Amz-Date", valid_603604
  var valid_603605 = header.getOrDefault("X-Amz-Security-Token")
  valid_603605 = validateParameter(valid_603605, JString, required = false,
                                 default = nil)
  if valid_603605 != nil:
    section.add "X-Amz-Security-Token", valid_603605
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603606 = header.getOrDefault("X-Amz-Target")
  valid_603606 = validateParameter(valid_603606, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInstancePatchStatesForPatchGroup"))
  if valid_603606 != nil:
    section.add "X-Amz-Target", valid_603606
  var valid_603607 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603607 = validateParameter(valid_603607, JString, required = false,
                                 default = nil)
  if valid_603607 != nil:
    section.add "X-Amz-Content-Sha256", valid_603607
  var valid_603608 = header.getOrDefault("X-Amz-Algorithm")
  valid_603608 = validateParameter(valid_603608, JString, required = false,
                                 default = nil)
  if valid_603608 != nil:
    section.add "X-Amz-Algorithm", valid_603608
  var valid_603609 = header.getOrDefault("X-Amz-Signature")
  valid_603609 = validateParameter(valid_603609, JString, required = false,
                                 default = nil)
  if valid_603609 != nil:
    section.add "X-Amz-Signature", valid_603609
  var valid_603610 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603610 = validateParameter(valid_603610, JString, required = false,
                                 default = nil)
  if valid_603610 != nil:
    section.add "X-Amz-SignedHeaders", valid_603610
  var valid_603611 = header.getOrDefault("X-Amz-Credential")
  valid_603611 = validateParameter(valid_603611, JString, required = false,
                                 default = nil)
  if valid_603611 != nil:
    section.add "X-Amz-Credential", valid_603611
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603613: Call_DescribeInstancePatchStatesForPatchGroup_603601;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the high-level patch state for the instances in the specified patch group.
  ## 
  let valid = call_603613.validator(path, query, header, formData, body)
  let scheme = call_603613.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603613.url(scheme.get, call_603613.host, call_603613.base,
                         call_603613.route, valid.getOrDefault("path"))
  result = hook(call_603613, url, valid)

proc call*(call_603614: Call_DescribeInstancePatchStatesForPatchGroup_603601;
          body: JsonNode): Recallable =
  ## describeInstancePatchStatesForPatchGroup
  ## Retrieves the high-level patch state for the instances in the specified patch group.
  ##   body: JObject (required)
  var body_603615 = newJObject()
  if body != nil:
    body_603615 = body
  result = call_603614.call(nil, nil, nil, nil, body_603615)

var describeInstancePatchStatesForPatchGroup* = Call_DescribeInstancePatchStatesForPatchGroup_603601(
    name: "describeInstancePatchStatesForPatchGroup", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInstancePatchStatesForPatchGroup",
    validator: validate_DescribeInstancePatchStatesForPatchGroup_603602,
    base: "/", url: url_DescribeInstancePatchStatesForPatchGroup_603603,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInstancePatches_603616 = ref object of OpenApiRestCall_602433
proc url_DescribeInstancePatches_603618(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeInstancePatches_603617(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603619 = header.getOrDefault("X-Amz-Date")
  valid_603619 = validateParameter(valid_603619, JString, required = false,
                                 default = nil)
  if valid_603619 != nil:
    section.add "X-Amz-Date", valid_603619
  var valid_603620 = header.getOrDefault("X-Amz-Security-Token")
  valid_603620 = validateParameter(valid_603620, JString, required = false,
                                 default = nil)
  if valid_603620 != nil:
    section.add "X-Amz-Security-Token", valid_603620
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603621 = header.getOrDefault("X-Amz-Target")
  valid_603621 = validateParameter(valid_603621, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInstancePatches"))
  if valid_603621 != nil:
    section.add "X-Amz-Target", valid_603621
  var valid_603622 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603622 = validateParameter(valid_603622, JString, required = false,
                                 default = nil)
  if valid_603622 != nil:
    section.add "X-Amz-Content-Sha256", valid_603622
  var valid_603623 = header.getOrDefault("X-Amz-Algorithm")
  valid_603623 = validateParameter(valid_603623, JString, required = false,
                                 default = nil)
  if valid_603623 != nil:
    section.add "X-Amz-Algorithm", valid_603623
  var valid_603624 = header.getOrDefault("X-Amz-Signature")
  valid_603624 = validateParameter(valid_603624, JString, required = false,
                                 default = nil)
  if valid_603624 != nil:
    section.add "X-Amz-Signature", valid_603624
  var valid_603625 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603625 = validateParameter(valid_603625, JString, required = false,
                                 default = nil)
  if valid_603625 != nil:
    section.add "X-Amz-SignedHeaders", valid_603625
  var valid_603626 = header.getOrDefault("X-Amz-Credential")
  valid_603626 = validateParameter(valid_603626, JString, required = false,
                                 default = nil)
  if valid_603626 != nil:
    section.add "X-Amz-Credential", valid_603626
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603628: Call_DescribeInstancePatches_603616; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the patches on the specified instance and their state relative to the patch baseline being used for the instance.
  ## 
  let valid = call_603628.validator(path, query, header, formData, body)
  let scheme = call_603628.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603628.url(scheme.get, call_603628.host, call_603628.base,
                         call_603628.route, valid.getOrDefault("path"))
  result = hook(call_603628, url, valid)

proc call*(call_603629: Call_DescribeInstancePatches_603616; body: JsonNode): Recallable =
  ## describeInstancePatches
  ## Retrieves information about the patches on the specified instance and their state relative to the patch baseline being used for the instance.
  ##   body: JObject (required)
  var body_603630 = newJObject()
  if body != nil:
    body_603630 = body
  result = call_603629.call(nil, nil, nil, nil, body_603630)

var describeInstancePatches* = Call_DescribeInstancePatches_603616(
    name: "describeInstancePatches", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInstancePatches",
    validator: validate_DescribeInstancePatches_603617, base: "/",
    url: url_DescribeInstancePatches_603618, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInventoryDeletions_603631 = ref object of OpenApiRestCall_602433
proc url_DescribeInventoryDeletions_603633(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeInventoryDeletions_603632(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603634 = header.getOrDefault("X-Amz-Date")
  valid_603634 = validateParameter(valid_603634, JString, required = false,
                                 default = nil)
  if valid_603634 != nil:
    section.add "X-Amz-Date", valid_603634
  var valid_603635 = header.getOrDefault("X-Amz-Security-Token")
  valid_603635 = validateParameter(valid_603635, JString, required = false,
                                 default = nil)
  if valid_603635 != nil:
    section.add "X-Amz-Security-Token", valid_603635
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603636 = header.getOrDefault("X-Amz-Target")
  valid_603636 = validateParameter(valid_603636, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInventoryDeletions"))
  if valid_603636 != nil:
    section.add "X-Amz-Target", valid_603636
  var valid_603637 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603637 = validateParameter(valid_603637, JString, required = false,
                                 default = nil)
  if valid_603637 != nil:
    section.add "X-Amz-Content-Sha256", valid_603637
  var valid_603638 = header.getOrDefault("X-Amz-Algorithm")
  valid_603638 = validateParameter(valid_603638, JString, required = false,
                                 default = nil)
  if valid_603638 != nil:
    section.add "X-Amz-Algorithm", valid_603638
  var valid_603639 = header.getOrDefault("X-Amz-Signature")
  valid_603639 = validateParameter(valid_603639, JString, required = false,
                                 default = nil)
  if valid_603639 != nil:
    section.add "X-Amz-Signature", valid_603639
  var valid_603640 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603640 = validateParameter(valid_603640, JString, required = false,
                                 default = nil)
  if valid_603640 != nil:
    section.add "X-Amz-SignedHeaders", valid_603640
  var valid_603641 = header.getOrDefault("X-Amz-Credential")
  valid_603641 = validateParameter(valid_603641, JString, required = false,
                                 default = nil)
  if valid_603641 != nil:
    section.add "X-Amz-Credential", valid_603641
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603643: Call_DescribeInventoryDeletions_603631; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a specific delete inventory operation.
  ## 
  let valid = call_603643.validator(path, query, header, formData, body)
  let scheme = call_603643.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603643.url(scheme.get, call_603643.host, call_603643.base,
                         call_603643.route, valid.getOrDefault("path"))
  result = hook(call_603643, url, valid)

proc call*(call_603644: Call_DescribeInventoryDeletions_603631; body: JsonNode): Recallable =
  ## describeInventoryDeletions
  ## Describes a specific delete inventory operation.
  ##   body: JObject (required)
  var body_603645 = newJObject()
  if body != nil:
    body_603645 = body
  result = call_603644.call(nil, nil, nil, nil, body_603645)

var describeInventoryDeletions* = Call_DescribeInventoryDeletions_603631(
    name: "describeInventoryDeletions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInventoryDeletions",
    validator: validate_DescribeInventoryDeletions_603632, base: "/",
    url: url_DescribeInventoryDeletions_603633,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowExecutionTaskInvocations_603646 = ref object of OpenApiRestCall_602433
proc url_DescribeMaintenanceWindowExecutionTaskInvocations_603648(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeMaintenanceWindowExecutionTaskInvocations_603647(
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603649 = header.getOrDefault("X-Amz-Date")
  valid_603649 = validateParameter(valid_603649, JString, required = false,
                                 default = nil)
  if valid_603649 != nil:
    section.add "X-Amz-Date", valid_603649
  var valid_603650 = header.getOrDefault("X-Amz-Security-Token")
  valid_603650 = validateParameter(valid_603650, JString, required = false,
                                 default = nil)
  if valid_603650 != nil:
    section.add "X-Amz-Security-Token", valid_603650
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603651 = header.getOrDefault("X-Amz-Target")
  valid_603651 = validateParameter(valid_603651, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowExecutionTaskInvocations"))
  if valid_603651 != nil:
    section.add "X-Amz-Target", valid_603651
  var valid_603652 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603652 = validateParameter(valid_603652, JString, required = false,
                                 default = nil)
  if valid_603652 != nil:
    section.add "X-Amz-Content-Sha256", valid_603652
  var valid_603653 = header.getOrDefault("X-Amz-Algorithm")
  valid_603653 = validateParameter(valid_603653, JString, required = false,
                                 default = nil)
  if valid_603653 != nil:
    section.add "X-Amz-Algorithm", valid_603653
  var valid_603654 = header.getOrDefault("X-Amz-Signature")
  valid_603654 = validateParameter(valid_603654, JString, required = false,
                                 default = nil)
  if valid_603654 != nil:
    section.add "X-Amz-Signature", valid_603654
  var valid_603655 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603655 = validateParameter(valid_603655, JString, required = false,
                                 default = nil)
  if valid_603655 != nil:
    section.add "X-Amz-SignedHeaders", valid_603655
  var valid_603656 = header.getOrDefault("X-Amz-Credential")
  valid_603656 = validateParameter(valid_603656, JString, required = false,
                                 default = nil)
  if valid_603656 != nil:
    section.add "X-Amz-Credential", valid_603656
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603658: Call_DescribeMaintenanceWindowExecutionTaskInvocations_603646;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the individual task executions (one per target) for a particular task run as part of a maintenance window execution.
  ## 
  let valid = call_603658.validator(path, query, header, formData, body)
  let scheme = call_603658.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603658.url(scheme.get, call_603658.host, call_603658.base,
                         call_603658.route, valid.getOrDefault("path"))
  result = hook(call_603658, url, valid)

proc call*(call_603659: Call_DescribeMaintenanceWindowExecutionTaskInvocations_603646;
          body: JsonNode): Recallable =
  ## describeMaintenanceWindowExecutionTaskInvocations
  ## Retrieves the individual task executions (one per target) for a particular task run as part of a maintenance window execution.
  ##   body: JObject (required)
  var body_603660 = newJObject()
  if body != nil:
    body_603660 = body
  result = call_603659.call(nil, nil, nil, nil, body_603660)

var describeMaintenanceWindowExecutionTaskInvocations* = Call_DescribeMaintenanceWindowExecutionTaskInvocations_603646(
    name: "describeMaintenanceWindowExecutionTaskInvocations",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com", route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowExecutionTaskInvocations",
    validator: validate_DescribeMaintenanceWindowExecutionTaskInvocations_603647,
    base: "/", url: url_DescribeMaintenanceWindowExecutionTaskInvocations_603648,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowExecutionTasks_603661 = ref object of OpenApiRestCall_602433
proc url_DescribeMaintenanceWindowExecutionTasks_603663(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeMaintenanceWindowExecutionTasks_603662(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603664 = header.getOrDefault("X-Amz-Date")
  valid_603664 = validateParameter(valid_603664, JString, required = false,
                                 default = nil)
  if valid_603664 != nil:
    section.add "X-Amz-Date", valid_603664
  var valid_603665 = header.getOrDefault("X-Amz-Security-Token")
  valid_603665 = validateParameter(valid_603665, JString, required = false,
                                 default = nil)
  if valid_603665 != nil:
    section.add "X-Amz-Security-Token", valid_603665
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603666 = header.getOrDefault("X-Amz-Target")
  valid_603666 = validateParameter(valid_603666, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowExecutionTasks"))
  if valid_603666 != nil:
    section.add "X-Amz-Target", valid_603666
  var valid_603667 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603667 = validateParameter(valid_603667, JString, required = false,
                                 default = nil)
  if valid_603667 != nil:
    section.add "X-Amz-Content-Sha256", valid_603667
  var valid_603668 = header.getOrDefault("X-Amz-Algorithm")
  valid_603668 = validateParameter(valid_603668, JString, required = false,
                                 default = nil)
  if valid_603668 != nil:
    section.add "X-Amz-Algorithm", valid_603668
  var valid_603669 = header.getOrDefault("X-Amz-Signature")
  valid_603669 = validateParameter(valid_603669, JString, required = false,
                                 default = nil)
  if valid_603669 != nil:
    section.add "X-Amz-Signature", valid_603669
  var valid_603670 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603670 = validateParameter(valid_603670, JString, required = false,
                                 default = nil)
  if valid_603670 != nil:
    section.add "X-Amz-SignedHeaders", valid_603670
  var valid_603671 = header.getOrDefault("X-Amz-Credential")
  valid_603671 = validateParameter(valid_603671, JString, required = false,
                                 default = nil)
  if valid_603671 != nil:
    section.add "X-Amz-Credential", valid_603671
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603673: Call_DescribeMaintenanceWindowExecutionTasks_603661;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## For a given maintenance window execution, lists the tasks that were run.
  ## 
  let valid = call_603673.validator(path, query, header, formData, body)
  let scheme = call_603673.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603673.url(scheme.get, call_603673.host, call_603673.base,
                         call_603673.route, valid.getOrDefault("path"))
  result = hook(call_603673, url, valid)

proc call*(call_603674: Call_DescribeMaintenanceWindowExecutionTasks_603661;
          body: JsonNode): Recallable =
  ## describeMaintenanceWindowExecutionTasks
  ## For a given maintenance window execution, lists the tasks that were run.
  ##   body: JObject (required)
  var body_603675 = newJObject()
  if body != nil:
    body_603675 = body
  result = call_603674.call(nil, nil, nil, nil, body_603675)

var describeMaintenanceWindowExecutionTasks* = Call_DescribeMaintenanceWindowExecutionTasks_603661(
    name: "describeMaintenanceWindowExecutionTasks", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowExecutionTasks",
    validator: validate_DescribeMaintenanceWindowExecutionTasks_603662, base: "/",
    url: url_DescribeMaintenanceWindowExecutionTasks_603663,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowExecutions_603676 = ref object of OpenApiRestCall_602433
proc url_DescribeMaintenanceWindowExecutions_603678(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeMaintenanceWindowExecutions_603677(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603679 = header.getOrDefault("X-Amz-Date")
  valid_603679 = validateParameter(valid_603679, JString, required = false,
                                 default = nil)
  if valid_603679 != nil:
    section.add "X-Amz-Date", valid_603679
  var valid_603680 = header.getOrDefault("X-Amz-Security-Token")
  valid_603680 = validateParameter(valid_603680, JString, required = false,
                                 default = nil)
  if valid_603680 != nil:
    section.add "X-Amz-Security-Token", valid_603680
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603681 = header.getOrDefault("X-Amz-Target")
  valid_603681 = validateParameter(valid_603681, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowExecutions"))
  if valid_603681 != nil:
    section.add "X-Amz-Target", valid_603681
  var valid_603682 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603682 = validateParameter(valid_603682, JString, required = false,
                                 default = nil)
  if valid_603682 != nil:
    section.add "X-Amz-Content-Sha256", valid_603682
  var valid_603683 = header.getOrDefault("X-Amz-Algorithm")
  valid_603683 = validateParameter(valid_603683, JString, required = false,
                                 default = nil)
  if valid_603683 != nil:
    section.add "X-Amz-Algorithm", valid_603683
  var valid_603684 = header.getOrDefault("X-Amz-Signature")
  valid_603684 = validateParameter(valid_603684, JString, required = false,
                                 default = nil)
  if valid_603684 != nil:
    section.add "X-Amz-Signature", valid_603684
  var valid_603685 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603685 = validateParameter(valid_603685, JString, required = false,
                                 default = nil)
  if valid_603685 != nil:
    section.add "X-Amz-SignedHeaders", valid_603685
  var valid_603686 = header.getOrDefault("X-Amz-Credential")
  valid_603686 = validateParameter(valid_603686, JString, required = false,
                                 default = nil)
  if valid_603686 != nil:
    section.add "X-Amz-Credential", valid_603686
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603688: Call_DescribeMaintenanceWindowExecutions_603676;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the executions of a maintenance window. This includes information about when the maintenance window was scheduled to be active, and information about tasks registered and run with the maintenance window.
  ## 
  let valid = call_603688.validator(path, query, header, formData, body)
  let scheme = call_603688.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603688.url(scheme.get, call_603688.host, call_603688.base,
                         call_603688.route, valid.getOrDefault("path"))
  result = hook(call_603688, url, valid)

proc call*(call_603689: Call_DescribeMaintenanceWindowExecutions_603676;
          body: JsonNode): Recallable =
  ## describeMaintenanceWindowExecutions
  ## Lists the executions of a maintenance window. This includes information about when the maintenance window was scheduled to be active, and information about tasks registered and run with the maintenance window.
  ##   body: JObject (required)
  var body_603690 = newJObject()
  if body != nil:
    body_603690 = body
  result = call_603689.call(nil, nil, nil, nil, body_603690)

var describeMaintenanceWindowExecutions* = Call_DescribeMaintenanceWindowExecutions_603676(
    name: "describeMaintenanceWindowExecutions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowExecutions",
    validator: validate_DescribeMaintenanceWindowExecutions_603677, base: "/",
    url: url_DescribeMaintenanceWindowExecutions_603678,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowSchedule_603691 = ref object of OpenApiRestCall_602433
proc url_DescribeMaintenanceWindowSchedule_603693(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeMaintenanceWindowSchedule_603692(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603694 = header.getOrDefault("X-Amz-Date")
  valid_603694 = validateParameter(valid_603694, JString, required = false,
                                 default = nil)
  if valid_603694 != nil:
    section.add "X-Amz-Date", valid_603694
  var valid_603695 = header.getOrDefault("X-Amz-Security-Token")
  valid_603695 = validateParameter(valid_603695, JString, required = false,
                                 default = nil)
  if valid_603695 != nil:
    section.add "X-Amz-Security-Token", valid_603695
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603696 = header.getOrDefault("X-Amz-Target")
  valid_603696 = validateParameter(valid_603696, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowSchedule"))
  if valid_603696 != nil:
    section.add "X-Amz-Target", valid_603696
  var valid_603697 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603697 = validateParameter(valid_603697, JString, required = false,
                                 default = nil)
  if valid_603697 != nil:
    section.add "X-Amz-Content-Sha256", valid_603697
  var valid_603698 = header.getOrDefault("X-Amz-Algorithm")
  valid_603698 = validateParameter(valid_603698, JString, required = false,
                                 default = nil)
  if valid_603698 != nil:
    section.add "X-Amz-Algorithm", valid_603698
  var valid_603699 = header.getOrDefault("X-Amz-Signature")
  valid_603699 = validateParameter(valid_603699, JString, required = false,
                                 default = nil)
  if valid_603699 != nil:
    section.add "X-Amz-Signature", valid_603699
  var valid_603700 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603700 = validateParameter(valid_603700, JString, required = false,
                                 default = nil)
  if valid_603700 != nil:
    section.add "X-Amz-SignedHeaders", valid_603700
  var valid_603701 = header.getOrDefault("X-Amz-Credential")
  valid_603701 = validateParameter(valid_603701, JString, required = false,
                                 default = nil)
  if valid_603701 != nil:
    section.add "X-Amz-Credential", valid_603701
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603703: Call_DescribeMaintenanceWindowSchedule_603691;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves information about upcoming executions of a maintenance window.
  ## 
  let valid = call_603703.validator(path, query, header, formData, body)
  let scheme = call_603703.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603703.url(scheme.get, call_603703.host, call_603703.base,
                         call_603703.route, valid.getOrDefault("path"))
  result = hook(call_603703, url, valid)

proc call*(call_603704: Call_DescribeMaintenanceWindowSchedule_603691;
          body: JsonNode): Recallable =
  ## describeMaintenanceWindowSchedule
  ## Retrieves information about upcoming executions of a maintenance window.
  ##   body: JObject (required)
  var body_603705 = newJObject()
  if body != nil:
    body_603705 = body
  result = call_603704.call(nil, nil, nil, nil, body_603705)

var describeMaintenanceWindowSchedule* = Call_DescribeMaintenanceWindowSchedule_603691(
    name: "describeMaintenanceWindowSchedule", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowSchedule",
    validator: validate_DescribeMaintenanceWindowSchedule_603692, base: "/",
    url: url_DescribeMaintenanceWindowSchedule_603693,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowTargets_603706 = ref object of OpenApiRestCall_602433
proc url_DescribeMaintenanceWindowTargets_603708(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeMaintenanceWindowTargets_603707(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603709 = header.getOrDefault("X-Amz-Date")
  valid_603709 = validateParameter(valid_603709, JString, required = false,
                                 default = nil)
  if valid_603709 != nil:
    section.add "X-Amz-Date", valid_603709
  var valid_603710 = header.getOrDefault("X-Amz-Security-Token")
  valid_603710 = validateParameter(valid_603710, JString, required = false,
                                 default = nil)
  if valid_603710 != nil:
    section.add "X-Amz-Security-Token", valid_603710
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603711 = header.getOrDefault("X-Amz-Target")
  valid_603711 = validateParameter(valid_603711, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowTargets"))
  if valid_603711 != nil:
    section.add "X-Amz-Target", valid_603711
  var valid_603712 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603712 = validateParameter(valid_603712, JString, required = false,
                                 default = nil)
  if valid_603712 != nil:
    section.add "X-Amz-Content-Sha256", valid_603712
  var valid_603713 = header.getOrDefault("X-Amz-Algorithm")
  valid_603713 = validateParameter(valid_603713, JString, required = false,
                                 default = nil)
  if valid_603713 != nil:
    section.add "X-Amz-Algorithm", valid_603713
  var valid_603714 = header.getOrDefault("X-Amz-Signature")
  valid_603714 = validateParameter(valid_603714, JString, required = false,
                                 default = nil)
  if valid_603714 != nil:
    section.add "X-Amz-Signature", valid_603714
  var valid_603715 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603715 = validateParameter(valid_603715, JString, required = false,
                                 default = nil)
  if valid_603715 != nil:
    section.add "X-Amz-SignedHeaders", valid_603715
  var valid_603716 = header.getOrDefault("X-Amz-Credential")
  valid_603716 = validateParameter(valid_603716, JString, required = false,
                                 default = nil)
  if valid_603716 != nil:
    section.add "X-Amz-Credential", valid_603716
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603718: Call_DescribeMaintenanceWindowTargets_603706;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the targets registered with the maintenance window.
  ## 
  let valid = call_603718.validator(path, query, header, formData, body)
  let scheme = call_603718.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603718.url(scheme.get, call_603718.host, call_603718.base,
                         call_603718.route, valid.getOrDefault("path"))
  result = hook(call_603718, url, valid)

proc call*(call_603719: Call_DescribeMaintenanceWindowTargets_603706;
          body: JsonNode): Recallable =
  ## describeMaintenanceWindowTargets
  ## Lists the targets registered with the maintenance window.
  ##   body: JObject (required)
  var body_603720 = newJObject()
  if body != nil:
    body_603720 = body
  result = call_603719.call(nil, nil, nil, nil, body_603720)

var describeMaintenanceWindowTargets* = Call_DescribeMaintenanceWindowTargets_603706(
    name: "describeMaintenanceWindowTargets", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowTargets",
    validator: validate_DescribeMaintenanceWindowTargets_603707, base: "/",
    url: url_DescribeMaintenanceWindowTargets_603708,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowTasks_603721 = ref object of OpenApiRestCall_602433
proc url_DescribeMaintenanceWindowTasks_603723(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeMaintenanceWindowTasks_603722(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603724 = header.getOrDefault("X-Amz-Date")
  valid_603724 = validateParameter(valid_603724, JString, required = false,
                                 default = nil)
  if valid_603724 != nil:
    section.add "X-Amz-Date", valid_603724
  var valid_603725 = header.getOrDefault("X-Amz-Security-Token")
  valid_603725 = validateParameter(valid_603725, JString, required = false,
                                 default = nil)
  if valid_603725 != nil:
    section.add "X-Amz-Security-Token", valid_603725
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603726 = header.getOrDefault("X-Amz-Target")
  valid_603726 = validateParameter(valid_603726, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowTasks"))
  if valid_603726 != nil:
    section.add "X-Amz-Target", valid_603726
  var valid_603727 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603727 = validateParameter(valid_603727, JString, required = false,
                                 default = nil)
  if valid_603727 != nil:
    section.add "X-Amz-Content-Sha256", valid_603727
  var valid_603728 = header.getOrDefault("X-Amz-Algorithm")
  valid_603728 = validateParameter(valid_603728, JString, required = false,
                                 default = nil)
  if valid_603728 != nil:
    section.add "X-Amz-Algorithm", valid_603728
  var valid_603729 = header.getOrDefault("X-Amz-Signature")
  valid_603729 = validateParameter(valid_603729, JString, required = false,
                                 default = nil)
  if valid_603729 != nil:
    section.add "X-Amz-Signature", valid_603729
  var valid_603730 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603730 = validateParameter(valid_603730, JString, required = false,
                                 default = nil)
  if valid_603730 != nil:
    section.add "X-Amz-SignedHeaders", valid_603730
  var valid_603731 = header.getOrDefault("X-Amz-Credential")
  valid_603731 = validateParameter(valid_603731, JString, required = false,
                                 default = nil)
  if valid_603731 != nil:
    section.add "X-Amz-Credential", valid_603731
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603733: Call_DescribeMaintenanceWindowTasks_603721; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tasks in a maintenance window.
  ## 
  let valid = call_603733.validator(path, query, header, formData, body)
  let scheme = call_603733.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603733.url(scheme.get, call_603733.host, call_603733.base,
                         call_603733.route, valid.getOrDefault("path"))
  result = hook(call_603733, url, valid)

proc call*(call_603734: Call_DescribeMaintenanceWindowTasks_603721; body: JsonNode): Recallable =
  ## describeMaintenanceWindowTasks
  ## Lists the tasks in a maintenance window.
  ##   body: JObject (required)
  var body_603735 = newJObject()
  if body != nil:
    body_603735 = body
  result = call_603734.call(nil, nil, nil, nil, body_603735)

var describeMaintenanceWindowTasks* = Call_DescribeMaintenanceWindowTasks_603721(
    name: "describeMaintenanceWindowTasks", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowTasks",
    validator: validate_DescribeMaintenanceWindowTasks_603722, base: "/",
    url: url_DescribeMaintenanceWindowTasks_603723,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindows_603736 = ref object of OpenApiRestCall_602433
proc url_DescribeMaintenanceWindows_603738(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeMaintenanceWindows_603737(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603739 = header.getOrDefault("X-Amz-Date")
  valid_603739 = validateParameter(valid_603739, JString, required = false,
                                 default = nil)
  if valid_603739 != nil:
    section.add "X-Amz-Date", valid_603739
  var valid_603740 = header.getOrDefault("X-Amz-Security-Token")
  valid_603740 = validateParameter(valid_603740, JString, required = false,
                                 default = nil)
  if valid_603740 != nil:
    section.add "X-Amz-Security-Token", valid_603740
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603741 = header.getOrDefault("X-Amz-Target")
  valid_603741 = validateParameter(valid_603741, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindows"))
  if valid_603741 != nil:
    section.add "X-Amz-Target", valid_603741
  var valid_603742 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603742 = validateParameter(valid_603742, JString, required = false,
                                 default = nil)
  if valid_603742 != nil:
    section.add "X-Amz-Content-Sha256", valid_603742
  var valid_603743 = header.getOrDefault("X-Amz-Algorithm")
  valid_603743 = validateParameter(valid_603743, JString, required = false,
                                 default = nil)
  if valid_603743 != nil:
    section.add "X-Amz-Algorithm", valid_603743
  var valid_603744 = header.getOrDefault("X-Amz-Signature")
  valid_603744 = validateParameter(valid_603744, JString, required = false,
                                 default = nil)
  if valid_603744 != nil:
    section.add "X-Amz-Signature", valid_603744
  var valid_603745 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603745 = validateParameter(valid_603745, JString, required = false,
                                 default = nil)
  if valid_603745 != nil:
    section.add "X-Amz-SignedHeaders", valid_603745
  var valid_603746 = header.getOrDefault("X-Amz-Credential")
  valid_603746 = validateParameter(valid_603746, JString, required = false,
                                 default = nil)
  if valid_603746 != nil:
    section.add "X-Amz-Credential", valid_603746
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603748: Call_DescribeMaintenanceWindows_603736; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the maintenance windows in an AWS account.
  ## 
  let valid = call_603748.validator(path, query, header, formData, body)
  let scheme = call_603748.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603748.url(scheme.get, call_603748.host, call_603748.base,
                         call_603748.route, valid.getOrDefault("path"))
  result = hook(call_603748, url, valid)

proc call*(call_603749: Call_DescribeMaintenanceWindows_603736; body: JsonNode): Recallable =
  ## describeMaintenanceWindows
  ## Retrieves the maintenance windows in an AWS account.
  ##   body: JObject (required)
  var body_603750 = newJObject()
  if body != nil:
    body_603750 = body
  result = call_603749.call(nil, nil, nil, nil, body_603750)

var describeMaintenanceWindows* = Call_DescribeMaintenanceWindows_603736(
    name: "describeMaintenanceWindows", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindows",
    validator: validate_DescribeMaintenanceWindows_603737, base: "/",
    url: url_DescribeMaintenanceWindows_603738,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowsForTarget_603751 = ref object of OpenApiRestCall_602433
proc url_DescribeMaintenanceWindowsForTarget_603753(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeMaintenanceWindowsForTarget_603752(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603754 = header.getOrDefault("X-Amz-Date")
  valid_603754 = validateParameter(valid_603754, JString, required = false,
                                 default = nil)
  if valid_603754 != nil:
    section.add "X-Amz-Date", valid_603754
  var valid_603755 = header.getOrDefault("X-Amz-Security-Token")
  valid_603755 = validateParameter(valid_603755, JString, required = false,
                                 default = nil)
  if valid_603755 != nil:
    section.add "X-Amz-Security-Token", valid_603755
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603756 = header.getOrDefault("X-Amz-Target")
  valid_603756 = validateParameter(valid_603756, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowsForTarget"))
  if valid_603756 != nil:
    section.add "X-Amz-Target", valid_603756
  var valid_603757 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603757 = validateParameter(valid_603757, JString, required = false,
                                 default = nil)
  if valid_603757 != nil:
    section.add "X-Amz-Content-Sha256", valid_603757
  var valid_603758 = header.getOrDefault("X-Amz-Algorithm")
  valid_603758 = validateParameter(valid_603758, JString, required = false,
                                 default = nil)
  if valid_603758 != nil:
    section.add "X-Amz-Algorithm", valid_603758
  var valid_603759 = header.getOrDefault("X-Amz-Signature")
  valid_603759 = validateParameter(valid_603759, JString, required = false,
                                 default = nil)
  if valid_603759 != nil:
    section.add "X-Amz-Signature", valid_603759
  var valid_603760 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603760 = validateParameter(valid_603760, JString, required = false,
                                 default = nil)
  if valid_603760 != nil:
    section.add "X-Amz-SignedHeaders", valid_603760
  var valid_603761 = header.getOrDefault("X-Amz-Credential")
  valid_603761 = validateParameter(valid_603761, JString, required = false,
                                 default = nil)
  if valid_603761 != nil:
    section.add "X-Amz-Credential", valid_603761
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603763: Call_DescribeMaintenanceWindowsForTarget_603751;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves information about the maintenance window targets or tasks that an instance is associated with.
  ## 
  let valid = call_603763.validator(path, query, header, formData, body)
  let scheme = call_603763.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603763.url(scheme.get, call_603763.host, call_603763.base,
                         call_603763.route, valid.getOrDefault("path"))
  result = hook(call_603763, url, valid)

proc call*(call_603764: Call_DescribeMaintenanceWindowsForTarget_603751;
          body: JsonNode): Recallable =
  ## describeMaintenanceWindowsForTarget
  ## Retrieves information about the maintenance window targets or tasks that an instance is associated with.
  ##   body: JObject (required)
  var body_603765 = newJObject()
  if body != nil:
    body_603765 = body
  result = call_603764.call(nil, nil, nil, nil, body_603765)

var describeMaintenanceWindowsForTarget* = Call_DescribeMaintenanceWindowsForTarget_603751(
    name: "describeMaintenanceWindowsForTarget", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowsForTarget",
    validator: validate_DescribeMaintenanceWindowsForTarget_603752, base: "/",
    url: url_DescribeMaintenanceWindowsForTarget_603753,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeOpsItems_603766 = ref object of OpenApiRestCall_602433
proc url_DescribeOpsItems_603768(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeOpsItems_603767(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603769 = header.getOrDefault("X-Amz-Date")
  valid_603769 = validateParameter(valid_603769, JString, required = false,
                                 default = nil)
  if valid_603769 != nil:
    section.add "X-Amz-Date", valid_603769
  var valid_603770 = header.getOrDefault("X-Amz-Security-Token")
  valid_603770 = validateParameter(valid_603770, JString, required = false,
                                 default = nil)
  if valid_603770 != nil:
    section.add "X-Amz-Security-Token", valid_603770
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603771 = header.getOrDefault("X-Amz-Target")
  valid_603771 = validateParameter(valid_603771, JString, required = true, default = newJString(
      "AmazonSSM.DescribeOpsItems"))
  if valid_603771 != nil:
    section.add "X-Amz-Target", valid_603771
  var valid_603772 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603772 = validateParameter(valid_603772, JString, required = false,
                                 default = nil)
  if valid_603772 != nil:
    section.add "X-Amz-Content-Sha256", valid_603772
  var valid_603773 = header.getOrDefault("X-Amz-Algorithm")
  valid_603773 = validateParameter(valid_603773, JString, required = false,
                                 default = nil)
  if valid_603773 != nil:
    section.add "X-Amz-Algorithm", valid_603773
  var valid_603774 = header.getOrDefault("X-Amz-Signature")
  valid_603774 = validateParameter(valid_603774, JString, required = false,
                                 default = nil)
  if valid_603774 != nil:
    section.add "X-Amz-Signature", valid_603774
  var valid_603775 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603775 = validateParameter(valid_603775, JString, required = false,
                                 default = nil)
  if valid_603775 != nil:
    section.add "X-Amz-SignedHeaders", valid_603775
  var valid_603776 = header.getOrDefault("X-Amz-Credential")
  valid_603776 = validateParameter(valid_603776, JString, required = false,
                                 default = nil)
  if valid_603776 != nil:
    section.add "X-Amz-Credential", valid_603776
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603778: Call_DescribeOpsItems_603766; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Query a set of OpsItems. You must have permission in AWS Identity and Access Management (IAM) to query a list of OpsItems. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ## 
  let valid = call_603778.validator(path, query, header, formData, body)
  let scheme = call_603778.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603778.url(scheme.get, call_603778.host, call_603778.base,
                         call_603778.route, valid.getOrDefault("path"))
  result = hook(call_603778, url, valid)

proc call*(call_603779: Call_DescribeOpsItems_603766; body: JsonNode): Recallable =
  ## describeOpsItems
  ## <p>Query a set of OpsItems. You must have permission in AWS Identity and Access Management (IAM) to query a list of OpsItems. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ##   body: JObject (required)
  var body_603780 = newJObject()
  if body != nil:
    body_603780 = body
  result = call_603779.call(nil, nil, nil, nil, body_603780)

var describeOpsItems* = Call_DescribeOpsItems_603766(name: "describeOpsItems",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeOpsItems",
    validator: validate_DescribeOpsItems_603767, base: "/",
    url: url_DescribeOpsItems_603768, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeParameters_603781 = ref object of OpenApiRestCall_602433
proc url_DescribeParameters_603783(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeParameters_603782(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Get information about a parameter.</p> <p>Request results are returned on a best-effort basis. If you specify <code>MaxResults</code> in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of <code>MaxResults</code>. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a <code>NextToken</code>. You can specify the <code>NextToken</code> in a subsequent call to get the next set of results.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_603784 = query.getOrDefault("NextToken")
  valid_603784 = validateParameter(valid_603784, JString, required = false,
                                 default = nil)
  if valid_603784 != nil:
    section.add "NextToken", valid_603784
  var valid_603785 = query.getOrDefault("MaxResults")
  valid_603785 = validateParameter(valid_603785, JString, required = false,
                                 default = nil)
  if valid_603785 != nil:
    section.add "MaxResults", valid_603785
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603786 = header.getOrDefault("X-Amz-Date")
  valid_603786 = validateParameter(valid_603786, JString, required = false,
                                 default = nil)
  if valid_603786 != nil:
    section.add "X-Amz-Date", valid_603786
  var valid_603787 = header.getOrDefault("X-Amz-Security-Token")
  valid_603787 = validateParameter(valid_603787, JString, required = false,
                                 default = nil)
  if valid_603787 != nil:
    section.add "X-Amz-Security-Token", valid_603787
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603788 = header.getOrDefault("X-Amz-Target")
  valid_603788 = validateParameter(valid_603788, JString, required = true, default = newJString(
      "AmazonSSM.DescribeParameters"))
  if valid_603788 != nil:
    section.add "X-Amz-Target", valid_603788
  var valid_603789 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603789 = validateParameter(valid_603789, JString, required = false,
                                 default = nil)
  if valid_603789 != nil:
    section.add "X-Amz-Content-Sha256", valid_603789
  var valid_603790 = header.getOrDefault("X-Amz-Algorithm")
  valid_603790 = validateParameter(valid_603790, JString, required = false,
                                 default = nil)
  if valid_603790 != nil:
    section.add "X-Amz-Algorithm", valid_603790
  var valid_603791 = header.getOrDefault("X-Amz-Signature")
  valid_603791 = validateParameter(valid_603791, JString, required = false,
                                 default = nil)
  if valid_603791 != nil:
    section.add "X-Amz-Signature", valid_603791
  var valid_603792 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603792 = validateParameter(valid_603792, JString, required = false,
                                 default = nil)
  if valid_603792 != nil:
    section.add "X-Amz-SignedHeaders", valid_603792
  var valid_603793 = header.getOrDefault("X-Amz-Credential")
  valid_603793 = validateParameter(valid_603793, JString, required = false,
                                 default = nil)
  if valid_603793 != nil:
    section.add "X-Amz-Credential", valid_603793
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603795: Call_DescribeParameters_603781; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Get information about a parameter.</p> <p>Request results are returned on a best-effort basis. If you specify <code>MaxResults</code> in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of <code>MaxResults</code>. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a <code>NextToken</code>. You can specify the <code>NextToken</code> in a subsequent call to get the next set of results.</p>
  ## 
  let valid = call_603795.validator(path, query, header, formData, body)
  let scheme = call_603795.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603795.url(scheme.get, call_603795.host, call_603795.base,
                         call_603795.route, valid.getOrDefault("path"))
  result = hook(call_603795, url, valid)

proc call*(call_603796: Call_DescribeParameters_603781; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## describeParameters
  ## <p>Get information about a parameter.</p> <p>Request results are returned on a best-effort basis. If you specify <code>MaxResults</code> in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of <code>MaxResults</code>. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a <code>NextToken</code>. You can specify the <code>NextToken</code> in a subsequent call to get the next set of results.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603797 = newJObject()
  var body_603798 = newJObject()
  add(query_603797, "NextToken", newJString(NextToken))
  if body != nil:
    body_603798 = body
  add(query_603797, "MaxResults", newJString(MaxResults))
  result = call_603796.call(nil, query_603797, nil, nil, body_603798)

var describeParameters* = Call_DescribeParameters_603781(
    name: "describeParameters", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeParameters",
    validator: validate_DescribeParameters_603782, base: "/",
    url: url_DescribeParameters_603783, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePatchBaselines_603799 = ref object of OpenApiRestCall_602433
proc url_DescribePatchBaselines_603801(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribePatchBaselines_603800(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603802 = header.getOrDefault("X-Amz-Date")
  valid_603802 = validateParameter(valid_603802, JString, required = false,
                                 default = nil)
  if valid_603802 != nil:
    section.add "X-Amz-Date", valid_603802
  var valid_603803 = header.getOrDefault("X-Amz-Security-Token")
  valid_603803 = validateParameter(valid_603803, JString, required = false,
                                 default = nil)
  if valid_603803 != nil:
    section.add "X-Amz-Security-Token", valid_603803
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603804 = header.getOrDefault("X-Amz-Target")
  valid_603804 = validateParameter(valid_603804, JString, required = true, default = newJString(
      "AmazonSSM.DescribePatchBaselines"))
  if valid_603804 != nil:
    section.add "X-Amz-Target", valid_603804
  var valid_603805 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603805 = validateParameter(valid_603805, JString, required = false,
                                 default = nil)
  if valid_603805 != nil:
    section.add "X-Amz-Content-Sha256", valid_603805
  var valid_603806 = header.getOrDefault("X-Amz-Algorithm")
  valid_603806 = validateParameter(valid_603806, JString, required = false,
                                 default = nil)
  if valid_603806 != nil:
    section.add "X-Amz-Algorithm", valid_603806
  var valid_603807 = header.getOrDefault("X-Amz-Signature")
  valid_603807 = validateParameter(valid_603807, JString, required = false,
                                 default = nil)
  if valid_603807 != nil:
    section.add "X-Amz-Signature", valid_603807
  var valid_603808 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603808 = validateParameter(valid_603808, JString, required = false,
                                 default = nil)
  if valid_603808 != nil:
    section.add "X-Amz-SignedHeaders", valid_603808
  var valid_603809 = header.getOrDefault("X-Amz-Credential")
  valid_603809 = validateParameter(valid_603809, JString, required = false,
                                 default = nil)
  if valid_603809 != nil:
    section.add "X-Amz-Credential", valid_603809
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603811: Call_DescribePatchBaselines_603799; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the patch baselines in your AWS account.
  ## 
  let valid = call_603811.validator(path, query, header, formData, body)
  let scheme = call_603811.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603811.url(scheme.get, call_603811.host, call_603811.base,
                         call_603811.route, valid.getOrDefault("path"))
  result = hook(call_603811, url, valid)

proc call*(call_603812: Call_DescribePatchBaselines_603799; body: JsonNode): Recallable =
  ## describePatchBaselines
  ## Lists the patch baselines in your AWS account.
  ##   body: JObject (required)
  var body_603813 = newJObject()
  if body != nil:
    body_603813 = body
  result = call_603812.call(nil, nil, nil, nil, body_603813)

var describePatchBaselines* = Call_DescribePatchBaselines_603799(
    name: "describePatchBaselines", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribePatchBaselines",
    validator: validate_DescribePatchBaselines_603800, base: "/",
    url: url_DescribePatchBaselines_603801, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePatchGroupState_603814 = ref object of OpenApiRestCall_602433
proc url_DescribePatchGroupState_603816(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribePatchGroupState_603815(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603817 = header.getOrDefault("X-Amz-Date")
  valid_603817 = validateParameter(valid_603817, JString, required = false,
                                 default = nil)
  if valid_603817 != nil:
    section.add "X-Amz-Date", valid_603817
  var valid_603818 = header.getOrDefault("X-Amz-Security-Token")
  valid_603818 = validateParameter(valid_603818, JString, required = false,
                                 default = nil)
  if valid_603818 != nil:
    section.add "X-Amz-Security-Token", valid_603818
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603819 = header.getOrDefault("X-Amz-Target")
  valid_603819 = validateParameter(valid_603819, JString, required = true, default = newJString(
      "AmazonSSM.DescribePatchGroupState"))
  if valid_603819 != nil:
    section.add "X-Amz-Target", valid_603819
  var valid_603820 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603820 = validateParameter(valid_603820, JString, required = false,
                                 default = nil)
  if valid_603820 != nil:
    section.add "X-Amz-Content-Sha256", valid_603820
  var valid_603821 = header.getOrDefault("X-Amz-Algorithm")
  valid_603821 = validateParameter(valid_603821, JString, required = false,
                                 default = nil)
  if valid_603821 != nil:
    section.add "X-Amz-Algorithm", valid_603821
  var valid_603822 = header.getOrDefault("X-Amz-Signature")
  valid_603822 = validateParameter(valid_603822, JString, required = false,
                                 default = nil)
  if valid_603822 != nil:
    section.add "X-Amz-Signature", valid_603822
  var valid_603823 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603823 = validateParameter(valid_603823, JString, required = false,
                                 default = nil)
  if valid_603823 != nil:
    section.add "X-Amz-SignedHeaders", valid_603823
  var valid_603824 = header.getOrDefault("X-Amz-Credential")
  valid_603824 = validateParameter(valid_603824, JString, required = false,
                                 default = nil)
  if valid_603824 != nil:
    section.add "X-Amz-Credential", valid_603824
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603826: Call_DescribePatchGroupState_603814; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns high-level aggregated patch compliance state for a patch group.
  ## 
  let valid = call_603826.validator(path, query, header, formData, body)
  let scheme = call_603826.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603826.url(scheme.get, call_603826.host, call_603826.base,
                         call_603826.route, valid.getOrDefault("path"))
  result = hook(call_603826, url, valid)

proc call*(call_603827: Call_DescribePatchGroupState_603814; body: JsonNode): Recallable =
  ## describePatchGroupState
  ## Returns high-level aggregated patch compliance state for a patch group.
  ##   body: JObject (required)
  var body_603828 = newJObject()
  if body != nil:
    body_603828 = body
  result = call_603827.call(nil, nil, nil, nil, body_603828)

var describePatchGroupState* = Call_DescribePatchGroupState_603814(
    name: "describePatchGroupState", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribePatchGroupState",
    validator: validate_DescribePatchGroupState_603815, base: "/",
    url: url_DescribePatchGroupState_603816, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePatchGroups_603829 = ref object of OpenApiRestCall_602433
proc url_DescribePatchGroups_603831(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribePatchGroups_603830(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603832 = header.getOrDefault("X-Amz-Date")
  valid_603832 = validateParameter(valid_603832, JString, required = false,
                                 default = nil)
  if valid_603832 != nil:
    section.add "X-Amz-Date", valid_603832
  var valid_603833 = header.getOrDefault("X-Amz-Security-Token")
  valid_603833 = validateParameter(valid_603833, JString, required = false,
                                 default = nil)
  if valid_603833 != nil:
    section.add "X-Amz-Security-Token", valid_603833
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603834 = header.getOrDefault("X-Amz-Target")
  valid_603834 = validateParameter(valid_603834, JString, required = true, default = newJString(
      "AmazonSSM.DescribePatchGroups"))
  if valid_603834 != nil:
    section.add "X-Amz-Target", valid_603834
  var valid_603835 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603835 = validateParameter(valid_603835, JString, required = false,
                                 default = nil)
  if valid_603835 != nil:
    section.add "X-Amz-Content-Sha256", valid_603835
  var valid_603836 = header.getOrDefault("X-Amz-Algorithm")
  valid_603836 = validateParameter(valid_603836, JString, required = false,
                                 default = nil)
  if valid_603836 != nil:
    section.add "X-Amz-Algorithm", valid_603836
  var valid_603837 = header.getOrDefault("X-Amz-Signature")
  valid_603837 = validateParameter(valid_603837, JString, required = false,
                                 default = nil)
  if valid_603837 != nil:
    section.add "X-Amz-Signature", valid_603837
  var valid_603838 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603838 = validateParameter(valid_603838, JString, required = false,
                                 default = nil)
  if valid_603838 != nil:
    section.add "X-Amz-SignedHeaders", valid_603838
  var valid_603839 = header.getOrDefault("X-Amz-Credential")
  valid_603839 = validateParameter(valid_603839, JString, required = false,
                                 default = nil)
  if valid_603839 != nil:
    section.add "X-Amz-Credential", valid_603839
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603841: Call_DescribePatchGroups_603829; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all patch groups that have been registered with patch baselines.
  ## 
  let valid = call_603841.validator(path, query, header, formData, body)
  let scheme = call_603841.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603841.url(scheme.get, call_603841.host, call_603841.base,
                         call_603841.route, valid.getOrDefault("path"))
  result = hook(call_603841, url, valid)

proc call*(call_603842: Call_DescribePatchGroups_603829; body: JsonNode): Recallable =
  ## describePatchGroups
  ## Lists all patch groups that have been registered with patch baselines.
  ##   body: JObject (required)
  var body_603843 = newJObject()
  if body != nil:
    body_603843 = body
  result = call_603842.call(nil, nil, nil, nil, body_603843)

var describePatchGroups* = Call_DescribePatchGroups_603829(
    name: "describePatchGroups", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribePatchGroups",
    validator: validate_DescribePatchGroups_603830, base: "/",
    url: url_DescribePatchGroups_603831, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePatchProperties_603844 = ref object of OpenApiRestCall_602433
proc url_DescribePatchProperties_603846(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribePatchProperties_603845(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603847 = header.getOrDefault("X-Amz-Date")
  valid_603847 = validateParameter(valid_603847, JString, required = false,
                                 default = nil)
  if valid_603847 != nil:
    section.add "X-Amz-Date", valid_603847
  var valid_603848 = header.getOrDefault("X-Amz-Security-Token")
  valid_603848 = validateParameter(valid_603848, JString, required = false,
                                 default = nil)
  if valid_603848 != nil:
    section.add "X-Amz-Security-Token", valid_603848
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603849 = header.getOrDefault("X-Amz-Target")
  valid_603849 = validateParameter(valid_603849, JString, required = true, default = newJString(
      "AmazonSSM.DescribePatchProperties"))
  if valid_603849 != nil:
    section.add "X-Amz-Target", valid_603849
  var valid_603850 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603850 = validateParameter(valid_603850, JString, required = false,
                                 default = nil)
  if valid_603850 != nil:
    section.add "X-Amz-Content-Sha256", valid_603850
  var valid_603851 = header.getOrDefault("X-Amz-Algorithm")
  valid_603851 = validateParameter(valid_603851, JString, required = false,
                                 default = nil)
  if valid_603851 != nil:
    section.add "X-Amz-Algorithm", valid_603851
  var valid_603852 = header.getOrDefault("X-Amz-Signature")
  valid_603852 = validateParameter(valid_603852, JString, required = false,
                                 default = nil)
  if valid_603852 != nil:
    section.add "X-Amz-Signature", valid_603852
  var valid_603853 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603853 = validateParameter(valid_603853, JString, required = false,
                                 default = nil)
  if valid_603853 != nil:
    section.add "X-Amz-SignedHeaders", valid_603853
  var valid_603854 = header.getOrDefault("X-Amz-Credential")
  valid_603854 = validateParameter(valid_603854, JString, required = false,
                                 default = nil)
  if valid_603854 != nil:
    section.add "X-Amz-Credential", valid_603854
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603856: Call_DescribePatchProperties_603844; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the properties of available patches organized by product, product family, classification, severity, and other properties of available patches. You can use the reported properties in the filters you specify in requests for actions such as <a>CreatePatchBaseline</a>, <a>UpdatePatchBaseline</a>, <a>DescribeAvailablePatches</a>, and <a>DescribePatchBaselines</a>.</p> <p>The following section lists the properties that can be used in filters for each major operating system type:</p> <dl> <dt>WINDOWS</dt> <dd> <p>Valid properties: PRODUCT, PRODUCT_FAMILY, CLASSIFICATION, MSRC_SEVERITY</p> </dd> <dt>AMAZON_LINUX</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>AMAZON_LINUX_2</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>UBUNTU </dt> <dd> <p>Valid properties: PRODUCT, PRIORITY</p> </dd> <dt>REDHAT_ENTERPRISE_LINUX</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>SUSE</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>CENTOS</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> </dl>
  ## 
  let valid = call_603856.validator(path, query, header, formData, body)
  let scheme = call_603856.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603856.url(scheme.get, call_603856.host, call_603856.base,
                         call_603856.route, valid.getOrDefault("path"))
  result = hook(call_603856, url, valid)

proc call*(call_603857: Call_DescribePatchProperties_603844; body: JsonNode): Recallable =
  ## describePatchProperties
  ## <p>Lists the properties of available patches organized by product, product family, classification, severity, and other properties of available patches. You can use the reported properties in the filters you specify in requests for actions such as <a>CreatePatchBaseline</a>, <a>UpdatePatchBaseline</a>, <a>DescribeAvailablePatches</a>, and <a>DescribePatchBaselines</a>.</p> <p>The following section lists the properties that can be used in filters for each major operating system type:</p> <dl> <dt>WINDOWS</dt> <dd> <p>Valid properties: PRODUCT, PRODUCT_FAMILY, CLASSIFICATION, MSRC_SEVERITY</p> </dd> <dt>AMAZON_LINUX</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>AMAZON_LINUX_2</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>UBUNTU </dt> <dd> <p>Valid properties: PRODUCT, PRIORITY</p> </dd> <dt>REDHAT_ENTERPRISE_LINUX</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>SUSE</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>CENTOS</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> </dl>
  ##   body: JObject (required)
  var body_603858 = newJObject()
  if body != nil:
    body_603858 = body
  result = call_603857.call(nil, nil, nil, nil, body_603858)

var describePatchProperties* = Call_DescribePatchProperties_603844(
    name: "describePatchProperties", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribePatchProperties",
    validator: validate_DescribePatchProperties_603845, base: "/",
    url: url_DescribePatchProperties_603846, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSessions_603859 = ref object of OpenApiRestCall_602433
proc url_DescribeSessions_603861(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeSessions_603860(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603862 = header.getOrDefault("X-Amz-Date")
  valid_603862 = validateParameter(valid_603862, JString, required = false,
                                 default = nil)
  if valid_603862 != nil:
    section.add "X-Amz-Date", valid_603862
  var valid_603863 = header.getOrDefault("X-Amz-Security-Token")
  valid_603863 = validateParameter(valid_603863, JString, required = false,
                                 default = nil)
  if valid_603863 != nil:
    section.add "X-Amz-Security-Token", valid_603863
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603864 = header.getOrDefault("X-Amz-Target")
  valid_603864 = validateParameter(valid_603864, JString, required = true, default = newJString(
      "AmazonSSM.DescribeSessions"))
  if valid_603864 != nil:
    section.add "X-Amz-Target", valid_603864
  var valid_603865 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603865 = validateParameter(valid_603865, JString, required = false,
                                 default = nil)
  if valid_603865 != nil:
    section.add "X-Amz-Content-Sha256", valid_603865
  var valid_603866 = header.getOrDefault("X-Amz-Algorithm")
  valid_603866 = validateParameter(valid_603866, JString, required = false,
                                 default = nil)
  if valid_603866 != nil:
    section.add "X-Amz-Algorithm", valid_603866
  var valid_603867 = header.getOrDefault("X-Amz-Signature")
  valid_603867 = validateParameter(valid_603867, JString, required = false,
                                 default = nil)
  if valid_603867 != nil:
    section.add "X-Amz-Signature", valid_603867
  var valid_603868 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603868 = validateParameter(valid_603868, JString, required = false,
                                 default = nil)
  if valid_603868 != nil:
    section.add "X-Amz-SignedHeaders", valid_603868
  var valid_603869 = header.getOrDefault("X-Amz-Credential")
  valid_603869 = validateParameter(valid_603869, JString, required = false,
                                 default = nil)
  if valid_603869 != nil:
    section.add "X-Amz-Credential", valid_603869
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603871: Call_DescribeSessions_603859; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of all active sessions (both connected and disconnected) or terminated sessions from the past 30 days.
  ## 
  let valid = call_603871.validator(path, query, header, formData, body)
  let scheme = call_603871.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603871.url(scheme.get, call_603871.host, call_603871.base,
                         call_603871.route, valid.getOrDefault("path"))
  result = hook(call_603871, url, valid)

proc call*(call_603872: Call_DescribeSessions_603859; body: JsonNode): Recallable =
  ## describeSessions
  ## Retrieves a list of all active sessions (both connected and disconnected) or terminated sessions from the past 30 days.
  ##   body: JObject (required)
  var body_603873 = newJObject()
  if body != nil:
    body_603873 = body
  result = call_603872.call(nil, nil, nil, nil, body_603873)

var describeSessions* = Call_DescribeSessions_603859(name: "describeSessions",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeSessions",
    validator: validate_DescribeSessions_603860, base: "/",
    url: url_DescribeSessions_603861, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAutomationExecution_603874 = ref object of OpenApiRestCall_602433
proc url_GetAutomationExecution_603876(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetAutomationExecution_603875(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603877 = header.getOrDefault("X-Amz-Date")
  valid_603877 = validateParameter(valid_603877, JString, required = false,
                                 default = nil)
  if valid_603877 != nil:
    section.add "X-Amz-Date", valid_603877
  var valid_603878 = header.getOrDefault("X-Amz-Security-Token")
  valid_603878 = validateParameter(valid_603878, JString, required = false,
                                 default = nil)
  if valid_603878 != nil:
    section.add "X-Amz-Security-Token", valid_603878
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603879 = header.getOrDefault("X-Amz-Target")
  valid_603879 = validateParameter(valid_603879, JString, required = true, default = newJString(
      "AmazonSSM.GetAutomationExecution"))
  if valid_603879 != nil:
    section.add "X-Amz-Target", valid_603879
  var valid_603880 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603880 = validateParameter(valid_603880, JString, required = false,
                                 default = nil)
  if valid_603880 != nil:
    section.add "X-Amz-Content-Sha256", valid_603880
  var valid_603881 = header.getOrDefault("X-Amz-Algorithm")
  valid_603881 = validateParameter(valid_603881, JString, required = false,
                                 default = nil)
  if valid_603881 != nil:
    section.add "X-Amz-Algorithm", valid_603881
  var valid_603882 = header.getOrDefault("X-Amz-Signature")
  valid_603882 = validateParameter(valid_603882, JString, required = false,
                                 default = nil)
  if valid_603882 != nil:
    section.add "X-Amz-Signature", valid_603882
  var valid_603883 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603883 = validateParameter(valid_603883, JString, required = false,
                                 default = nil)
  if valid_603883 != nil:
    section.add "X-Amz-SignedHeaders", valid_603883
  var valid_603884 = header.getOrDefault("X-Amz-Credential")
  valid_603884 = validateParameter(valid_603884, JString, required = false,
                                 default = nil)
  if valid_603884 != nil:
    section.add "X-Amz-Credential", valid_603884
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603886: Call_GetAutomationExecution_603874; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get detailed information about a particular Automation execution.
  ## 
  let valid = call_603886.validator(path, query, header, formData, body)
  let scheme = call_603886.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603886.url(scheme.get, call_603886.host, call_603886.base,
                         call_603886.route, valid.getOrDefault("path"))
  result = hook(call_603886, url, valid)

proc call*(call_603887: Call_GetAutomationExecution_603874; body: JsonNode): Recallable =
  ## getAutomationExecution
  ## Get detailed information about a particular Automation execution.
  ##   body: JObject (required)
  var body_603888 = newJObject()
  if body != nil:
    body_603888 = body
  result = call_603887.call(nil, nil, nil, nil, body_603888)

var getAutomationExecution* = Call_GetAutomationExecution_603874(
    name: "getAutomationExecution", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetAutomationExecution",
    validator: validate_GetAutomationExecution_603875, base: "/",
    url: url_GetAutomationExecution_603876, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCommandInvocation_603889 = ref object of OpenApiRestCall_602433
proc url_GetCommandInvocation_603891(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCommandInvocation_603890(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603892 = header.getOrDefault("X-Amz-Date")
  valid_603892 = validateParameter(valid_603892, JString, required = false,
                                 default = nil)
  if valid_603892 != nil:
    section.add "X-Amz-Date", valid_603892
  var valid_603893 = header.getOrDefault("X-Amz-Security-Token")
  valid_603893 = validateParameter(valid_603893, JString, required = false,
                                 default = nil)
  if valid_603893 != nil:
    section.add "X-Amz-Security-Token", valid_603893
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603894 = header.getOrDefault("X-Amz-Target")
  valid_603894 = validateParameter(valid_603894, JString, required = true, default = newJString(
      "AmazonSSM.GetCommandInvocation"))
  if valid_603894 != nil:
    section.add "X-Amz-Target", valid_603894
  var valid_603895 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603895 = validateParameter(valid_603895, JString, required = false,
                                 default = nil)
  if valid_603895 != nil:
    section.add "X-Amz-Content-Sha256", valid_603895
  var valid_603896 = header.getOrDefault("X-Amz-Algorithm")
  valid_603896 = validateParameter(valid_603896, JString, required = false,
                                 default = nil)
  if valid_603896 != nil:
    section.add "X-Amz-Algorithm", valid_603896
  var valid_603897 = header.getOrDefault("X-Amz-Signature")
  valid_603897 = validateParameter(valid_603897, JString, required = false,
                                 default = nil)
  if valid_603897 != nil:
    section.add "X-Amz-Signature", valid_603897
  var valid_603898 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603898 = validateParameter(valid_603898, JString, required = false,
                                 default = nil)
  if valid_603898 != nil:
    section.add "X-Amz-SignedHeaders", valid_603898
  var valid_603899 = header.getOrDefault("X-Amz-Credential")
  valid_603899 = validateParameter(valid_603899, JString, required = false,
                                 default = nil)
  if valid_603899 != nil:
    section.add "X-Amz-Credential", valid_603899
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603901: Call_GetCommandInvocation_603889; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns detailed information about command execution for an invocation or plugin. 
  ## 
  let valid = call_603901.validator(path, query, header, formData, body)
  let scheme = call_603901.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603901.url(scheme.get, call_603901.host, call_603901.base,
                         call_603901.route, valid.getOrDefault("path"))
  result = hook(call_603901, url, valid)

proc call*(call_603902: Call_GetCommandInvocation_603889; body: JsonNode): Recallable =
  ## getCommandInvocation
  ## Returns detailed information about command execution for an invocation or plugin. 
  ##   body: JObject (required)
  var body_603903 = newJObject()
  if body != nil:
    body_603903 = body
  result = call_603902.call(nil, nil, nil, nil, body_603903)

var getCommandInvocation* = Call_GetCommandInvocation_603889(
    name: "getCommandInvocation", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetCommandInvocation",
    validator: validate_GetCommandInvocation_603890, base: "/",
    url: url_GetCommandInvocation_603891, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnectionStatus_603904 = ref object of OpenApiRestCall_602433
proc url_GetConnectionStatus_603906(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetConnectionStatus_603905(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603907 = header.getOrDefault("X-Amz-Date")
  valid_603907 = validateParameter(valid_603907, JString, required = false,
                                 default = nil)
  if valid_603907 != nil:
    section.add "X-Amz-Date", valid_603907
  var valid_603908 = header.getOrDefault("X-Amz-Security-Token")
  valid_603908 = validateParameter(valid_603908, JString, required = false,
                                 default = nil)
  if valid_603908 != nil:
    section.add "X-Amz-Security-Token", valid_603908
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603909 = header.getOrDefault("X-Amz-Target")
  valid_603909 = validateParameter(valid_603909, JString, required = true, default = newJString(
      "AmazonSSM.GetConnectionStatus"))
  if valid_603909 != nil:
    section.add "X-Amz-Target", valid_603909
  var valid_603910 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603910 = validateParameter(valid_603910, JString, required = false,
                                 default = nil)
  if valid_603910 != nil:
    section.add "X-Amz-Content-Sha256", valid_603910
  var valid_603911 = header.getOrDefault("X-Amz-Algorithm")
  valid_603911 = validateParameter(valid_603911, JString, required = false,
                                 default = nil)
  if valid_603911 != nil:
    section.add "X-Amz-Algorithm", valid_603911
  var valid_603912 = header.getOrDefault("X-Amz-Signature")
  valid_603912 = validateParameter(valid_603912, JString, required = false,
                                 default = nil)
  if valid_603912 != nil:
    section.add "X-Amz-Signature", valid_603912
  var valid_603913 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603913 = validateParameter(valid_603913, JString, required = false,
                                 default = nil)
  if valid_603913 != nil:
    section.add "X-Amz-SignedHeaders", valid_603913
  var valid_603914 = header.getOrDefault("X-Amz-Credential")
  valid_603914 = validateParameter(valid_603914, JString, required = false,
                                 default = nil)
  if valid_603914 != nil:
    section.add "X-Amz-Credential", valid_603914
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603916: Call_GetConnectionStatus_603904; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the Session Manager connection status for an instance to determine whether it is connected and ready to receive Session Manager connections.
  ## 
  let valid = call_603916.validator(path, query, header, formData, body)
  let scheme = call_603916.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603916.url(scheme.get, call_603916.host, call_603916.base,
                         call_603916.route, valid.getOrDefault("path"))
  result = hook(call_603916, url, valid)

proc call*(call_603917: Call_GetConnectionStatus_603904; body: JsonNode): Recallable =
  ## getConnectionStatus
  ## Retrieves the Session Manager connection status for an instance to determine whether it is connected and ready to receive Session Manager connections.
  ##   body: JObject (required)
  var body_603918 = newJObject()
  if body != nil:
    body_603918 = body
  result = call_603917.call(nil, nil, nil, nil, body_603918)

var getConnectionStatus* = Call_GetConnectionStatus_603904(
    name: "getConnectionStatus", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetConnectionStatus",
    validator: validate_GetConnectionStatus_603905, base: "/",
    url: url_GetConnectionStatus_603906, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefaultPatchBaseline_603919 = ref object of OpenApiRestCall_602433
proc url_GetDefaultPatchBaseline_603921(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDefaultPatchBaseline_603920(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603922 = header.getOrDefault("X-Amz-Date")
  valid_603922 = validateParameter(valid_603922, JString, required = false,
                                 default = nil)
  if valid_603922 != nil:
    section.add "X-Amz-Date", valid_603922
  var valid_603923 = header.getOrDefault("X-Amz-Security-Token")
  valid_603923 = validateParameter(valid_603923, JString, required = false,
                                 default = nil)
  if valid_603923 != nil:
    section.add "X-Amz-Security-Token", valid_603923
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603924 = header.getOrDefault("X-Amz-Target")
  valid_603924 = validateParameter(valid_603924, JString, required = true, default = newJString(
      "AmazonSSM.GetDefaultPatchBaseline"))
  if valid_603924 != nil:
    section.add "X-Amz-Target", valid_603924
  var valid_603925 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603925 = validateParameter(valid_603925, JString, required = false,
                                 default = nil)
  if valid_603925 != nil:
    section.add "X-Amz-Content-Sha256", valid_603925
  var valid_603926 = header.getOrDefault("X-Amz-Algorithm")
  valid_603926 = validateParameter(valid_603926, JString, required = false,
                                 default = nil)
  if valid_603926 != nil:
    section.add "X-Amz-Algorithm", valid_603926
  var valid_603927 = header.getOrDefault("X-Amz-Signature")
  valid_603927 = validateParameter(valid_603927, JString, required = false,
                                 default = nil)
  if valid_603927 != nil:
    section.add "X-Amz-Signature", valid_603927
  var valid_603928 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603928 = validateParameter(valid_603928, JString, required = false,
                                 default = nil)
  if valid_603928 != nil:
    section.add "X-Amz-SignedHeaders", valid_603928
  var valid_603929 = header.getOrDefault("X-Amz-Credential")
  valid_603929 = validateParameter(valid_603929, JString, required = false,
                                 default = nil)
  if valid_603929 != nil:
    section.add "X-Amz-Credential", valid_603929
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603931: Call_GetDefaultPatchBaseline_603919; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the default patch baseline. Note that Systems Manager supports creating multiple default patch baselines. For example, you can create a default patch baseline for each operating system.</p> <p>If you do not specify an operating system value, the default patch baseline for Windows is returned.</p>
  ## 
  let valid = call_603931.validator(path, query, header, formData, body)
  let scheme = call_603931.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603931.url(scheme.get, call_603931.host, call_603931.base,
                         call_603931.route, valid.getOrDefault("path"))
  result = hook(call_603931, url, valid)

proc call*(call_603932: Call_GetDefaultPatchBaseline_603919; body: JsonNode): Recallable =
  ## getDefaultPatchBaseline
  ## <p>Retrieves the default patch baseline. Note that Systems Manager supports creating multiple default patch baselines. For example, you can create a default patch baseline for each operating system.</p> <p>If you do not specify an operating system value, the default patch baseline for Windows is returned.</p>
  ##   body: JObject (required)
  var body_603933 = newJObject()
  if body != nil:
    body_603933 = body
  result = call_603932.call(nil, nil, nil, nil, body_603933)

var getDefaultPatchBaseline* = Call_GetDefaultPatchBaseline_603919(
    name: "getDefaultPatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetDefaultPatchBaseline",
    validator: validate_GetDefaultPatchBaseline_603920, base: "/",
    url: url_GetDefaultPatchBaseline_603921, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployablePatchSnapshotForInstance_603934 = ref object of OpenApiRestCall_602433
proc url_GetDeployablePatchSnapshotForInstance_603936(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeployablePatchSnapshotForInstance_603935(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603937 = header.getOrDefault("X-Amz-Date")
  valid_603937 = validateParameter(valid_603937, JString, required = false,
                                 default = nil)
  if valid_603937 != nil:
    section.add "X-Amz-Date", valid_603937
  var valid_603938 = header.getOrDefault("X-Amz-Security-Token")
  valid_603938 = validateParameter(valid_603938, JString, required = false,
                                 default = nil)
  if valid_603938 != nil:
    section.add "X-Amz-Security-Token", valid_603938
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603939 = header.getOrDefault("X-Amz-Target")
  valid_603939 = validateParameter(valid_603939, JString, required = true, default = newJString(
      "AmazonSSM.GetDeployablePatchSnapshotForInstance"))
  if valid_603939 != nil:
    section.add "X-Amz-Target", valid_603939
  var valid_603940 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603940 = validateParameter(valid_603940, JString, required = false,
                                 default = nil)
  if valid_603940 != nil:
    section.add "X-Amz-Content-Sha256", valid_603940
  var valid_603941 = header.getOrDefault("X-Amz-Algorithm")
  valid_603941 = validateParameter(valid_603941, JString, required = false,
                                 default = nil)
  if valid_603941 != nil:
    section.add "X-Amz-Algorithm", valid_603941
  var valid_603942 = header.getOrDefault("X-Amz-Signature")
  valid_603942 = validateParameter(valid_603942, JString, required = false,
                                 default = nil)
  if valid_603942 != nil:
    section.add "X-Amz-Signature", valid_603942
  var valid_603943 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603943 = validateParameter(valid_603943, JString, required = false,
                                 default = nil)
  if valid_603943 != nil:
    section.add "X-Amz-SignedHeaders", valid_603943
  var valid_603944 = header.getOrDefault("X-Amz-Credential")
  valid_603944 = validateParameter(valid_603944, JString, required = false,
                                 default = nil)
  if valid_603944 != nil:
    section.add "X-Amz-Credential", valid_603944
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603946: Call_GetDeployablePatchSnapshotForInstance_603934;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the current snapshot for the patch baseline the instance uses. This API is primarily used by the AWS-RunPatchBaseline Systems Manager document. 
  ## 
  let valid = call_603946.validator(path, query, header, formData, body)
  let scheme = call_603946.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603946.url(scheme.get, call_603946.host, call_603946.base,
                         call_603946.route, valid.getOrDefault("path"))
  result = hook(call_603946, url, valid)

proc call*(call_603947: Call_GetDeployablePatchSnapshotForInstance_603934;
          body: JsonNode): Recallable =
  ## getDeployablePatchSnapshotForInstance
  ## Retrieves the current snapshot for the patch baseline the instance uses. This API is primarily used by the AWS-RunPatchBaseline Systems Manager document. 
  ##   body: JObject (required)
  var body_603948 = newJObject()
  if body != nil:
    body_603948 = body
  result = call_603947.call(nil, nil, nil, nil, body_603948)

var getDeployablePatchSnapshotForInstance* = Call_GetDeployablePatchSnapshotForInstance_603934(
    name: "getDeployablePatchSnapshotForInstance", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetDeployablePatchSnapshotForInstance",
    validator: validate_GetDeployablePatchSnapshotForInstance_603935, base: "/",
    url: url_GetDeployablePatchSnapshotForInstance_603936,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocument_603949 = ref object of OpenApiRestCall_602433
proc url_GetDocument_603951(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDocument_603950(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603952 = header.getOrDefault("X-Amz-Date")
  valid_603952 = validateParameter(valid_603952, JString, required = false,
                                 default = nil)
  if valid_603952 != nil:
    section.add "X-Amz-Date", valid_603952
  var valid_603953 = header.getOrDefault("X-Amz-Security-Token")
  valid_603953 = validateParameter(valid_603953, JString, required = false,
                                 default = nil)
  if valid_603953 != nil:
    section.add "X-Amz-Security-Token", valid_603953
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603954 = header.getOrDefault("X-Amz-Target")
  valid_603954 = validateParameter(valid_603954, JString, required = true,
                                 default = newJString("AmazonSSM.GetDocument"))
  if valid_603954 != nil:
    section.add "X-Amz-Target", valid_603954
  var valid_603955 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603955 = validateParameter(valid_603955, JString, required = false,
                                 default = nil)
  if valid_603955 != nil:
    section.add "X-Amz-Content-Sha256", valid_603955
  var valid_603956 = header.getOrDefault("X-Amz-Algorithm")
  valid_603956 = validateParameter(valid_603956, JString, required = false,
                                 default = nil)
  if valid_603956 != nil:
    section.add "X-Amz-Algorithm", valid_603956
  var valid_603957 = header.getOrDefault("X-Amz-Signature")
  valid_603957 = validateParameter(valid_603957, JString, required = false,
                                 default = nil)
  if valid_603957 != nil:
    section.add "X-Amz-Signature", valid_603957
  var valid_603958 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603958 = validateParameter(valid_603958, JString, required = false,
                                 default = nil)
  if valid_603958 != nil:
    section.add "X-Amz-SignedHeaders", valid_603958
  var valid_603959 = header.getOrDefault("X-Amz-Credential")
  valid_603959 = validateParameter(valid_603959, JString, required = false,
                                 default = nil)
  if valid_603959 != nil:
    section.add "X-Amz-Credential", valid_603959
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603961: Call_GetDocument_603949; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the contents of the specified Systems Manager document.
  ## 
  let valid = call_603961.validator(path, query, header, formData, body)
  let scheme = call_603961.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603961.url(scheme.get, call_603961.host, call_603961.base,
                         call_603961.route, valid.getOrDefault("path"))
  result = hook(call_603961, url, valid)

proc call*(call_603962: Call_GetDocument_603949; body: JsonNode): Recallable =
  ## getDocument
  ## Gets the contents of the specified Systems Manager document.
  ##   body: JObject (required)
  var body_603963 = newJObject()
  if body != nil:
    body_603963 = body
  result = call_603962.call(nil, nil, nil, nil, body_603963)

var getDocument* = Call_GetDocument_603949(name: "getDocument",
                                        meth: HttpMethod.HttpPost,
                                        host: "ssm.amazonaws.com", route: "/#X-Amz-Target=AmazonSSM.GetDocument",
                                        validator: validate_GetDocument_603950,
                                        base: "/", url: url_GetDocument_603951,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInventory_603964 = ref object of OpenApiRestCall_602433
proc url_GetInventory_603966(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetInventory_603965(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603967 = header.getOrDefault("X-Amz-Date")
  valid_603967 = validateParameter(valid_603967, JString, required = false,
                                 default = nil)
  if valid_603967 != nil:
    section.add "X-Amz-Date", valid_603967
  var valid_603968 = header.getOrDefault("X-Amz-Security-Token")
  valid_603968 = validateParameter(valid_603968, JString, required = false,
                                 default = nil)
  if valid_603968 != nil:
    section.add "X-Amz-Security-Token", valid_603968
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603969 = header.getOrDefault("X-Amz-Target")
  valid_603969 = validateParameter(valid_603969, JString, required = true,
                                 default = newJString("AmazonSSM.GetInventory"))
  if valid_603969 != nil:
    section.add "X-Amz-Target", valid_603969
  var valid_603970 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603970 = validateParameter(valid_603970, JString, required = false,
                                 default = nil)
  if valid_603970 != nil:
    section.add "X-Amz-Content-Sha256", valid_603970
  var valid_603971 = header.getOrDefault("X-Amz-Algorithm")
  valid_603971 = validateParameter(valid_603971, JString, required = false,
                                 default = nil)
  if valid_603971 != nil:
    section.add "X-Amz-Algorithm", valid_603971
  var valid_603972 = header.getOrDefault("X-Amz-Signature")
  valid_603972 = validateParameter(valid_603972, JString, required = false,
                                 default = nil)
  if valid_603972 != nil:
    section.add "X-Amz-Signature", valid_603972
  var valid_603973 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603973 = validateParameter(valid_603973, JString, required = false,
                                 default = nil)
  if valid_603973 != nil:
    section.add "X-Amz-SignedHeaders", valid_603973
  var valid_603974 = header.getOrDefault("X-Amz-Credential")
  valid_603974 = validateParameter(valid_603974, JString, required = false,
                                 default = nil)
  if valid_603974 != nil:
    section.add "X-Amz-Credential", valid_603974
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603976: Call_GetInventory_603964; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Query inventory information.
  ## 
  let valid = call_603976.validator(path, query, header, formData, body)
  let scheme = call_603976.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603976.url(scheme.get, call_603976.host, call_603976.base,
                         call_603976.route, valid.getOrDefault("path"))
  result = hook(call_603976, url, valid)

proc call*(call_603977: Call_GetInventory_603964; body: JsonNode): Recallable =
  ## getInventory
  ## Query inventory information.
  ##   body: JObject (required)
  var body_603978 = newJObject()
  if body != nil:
    body_603978 = body
  result = call_603977.call(nil, nil, nil, nil, body_603978)

var getInventory* = Call_GetInventory_603964(name: "getInventory",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetInventory",
    validator: validate_GetInventory_603965, base: "/", url: url_GetInventory_603966,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInventorySchema_603979 = ref object of OpenApiRestCall_602433
proc url_GetInventorySchema_603981(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetInventorySchema_603980(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603982 = header.getOrDefault("X-Amz-Date")
  valid_603982 = validateParameter(valid_603982, JString, required = false,
                                 default = nil)
  if valid_603982 != nil:
    section.add "X-Amz-Date", valid_603982
  var valid_603983 = header.getOrDefault("X-Amz-Security-Token")
  valid_603983 = validateParameter(valid_603983, JString, required = false,
                                 default = nil)
  if valid_603983 != nil:
    section.add "X-Amz-Security-Token", valid_603983
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603984 = header.getOrDefault("X-Amz-Target")
  valid_603984 = validateParameter(valid_603984, JString, required = true, default = newJString(
      "AmazonSSM.GetInventorySchema"))
  if valid_603984 != nil:
    section.add "X-Amz-Target", valid_603984
  var valid_603985 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603985 = validateParameter(valid_603985, JString, required = false,
                                 default = nil)
  if valid_603985 != nil:
    section.add "X-Amz-Content-Sha256", valid_603985
  var valid_603986 = header.getOrDefault("X-Amz-Algorithm")
  valid_603986 = validateParameter(valid_603986, JString, required = false,
                                 default = nil)
  if valid_603986 != nil:
    section.add "X-Amz-Algorithm", valid_603986
  var valid_603987 = header.getOrDefault("X-Amz-Signature")
  valid_603987 = validateParameter(valid_603987, JString, required = false,
                                 default = nil)
  if valid_603987 != nil:
    section.add "X-Amz-Signature", valid_603987
  var valid_603988 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603988 = validateParameter(valid_603988, JString, required = false,
                                 default = nil)
  if valid_603988 != nil:
    section.add "X-Amz-SignedHeaders", valid_603988
  var valid_603989 = header.getOrDefault("X-Amz-Credential")
  valid_603989 = validateParameter(valid_603989, JString, required = false,
                                 default = nil)
  if valid_603989 != nil:
    section.add "X-Amz-Credential", valid_603989
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603991: Call_GetInventorySchema_603979; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Return a list of inventory type names for the account, or return a list of attribute names for a specific Inventory item type. 
  ## 
  let valid = call_603991.validator(path, query, header, formData, body)
  let scheme = call_603991.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603991.url(scheme.get, call_603991.host, call_603991.base,
                         call_603991.route, valid.getOrDefault("path"))
  result = hook(call_603991, url, valid)

proc call*(call_603992: Call_GetInventorySchema_603979; body: JsonNode): Recallable =
  ## getInventorySchema
  ## Return a list of inventory type names for the account, or return a list of attribute names for a specific Inventory item type. 
  ##   body: JObject (required)
  var body_603993 = newJObject()
  if body != nil:
    body_603993 = body
  result = call_603992.call(nil, nil, nil, nil, body_603993)

var getInventorySchema* = Call_GetInventorySchema_603979(
    name: "getInventorySchema", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetInventorySchema",
    validator: validate_GetInventorySchema_603980, base: "/",
    url: url_GetInventorySchema_603981, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMaintenanceWindow_603994 = ref object of OpenApiRestCall_602433
proc url_GetMaintenanceWindow_603996(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetMaintenanceWindow_603995(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603997 = header.getOrDefault("X-Amz-Date")
  valid_603997 = validateParameter(valid_603997, JString, required = false,
                                 default = nil)
  if valid_603997 != nil:
    section.add "X-Amz-Date", valid_603997
  var valid_603998 = header.getOrDefault("X-Amz-Security-Token")
  valid_603998 = validateParameter(valid_603998, JString, required = false,
                                 default = nil)
  if valid_603998 != nil:
    section.add "X-Amz-Security-Token", valid_603998
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603999 = header.getOrDefault("X-Amz-Target")
  valid_603999 = validateParameter(valid_603999, JString, required = true, default = newJString(
      "AmazonSSM.GetMaintenanceWindow"))
  if valid_603999 != nil:
    section.add "X-Amz-Target", valid_603999
  var valid_604000 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604000 = validateParameter(valid_604000, JString, required = false,
                                 default = nil)
  if valid_604000 != nil:
    section.add "X-Amz-Content-Sha256", valid_604000
  var valid_604001 = header.getOrDefault("X-Amz-Algorithm")
  valid_604001 = validateParameter(valid_604001, JString, required = false,
                                 default = nil)
  if valid_604001 != nil:
    section.add "X-Amz-Algorithm", valid_604001
  var valid_604002 = header.getOrDefault("X-Amz-Signature")
  valid_604002 = validateParameter(valid_604002, JString, required = false,
                                 default = nil)
  if valid_604002 != nil:
    section.add "X-Amz-Signature", valid_604002
  var valid_604003 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604003 = validateParameter(valid_604003, JString, required = false,
                                 default = nil)
  if valid_604003 != nil:
    section.add "X-Amz-SignedHeaders", valid_604003
  var valid_604004 = header.getOrDefault("X-Amz-Credential")
  valid_604004 = validateParameter(valid_604004, JString, required = false,
                                 default = nil)
  if valid_604004 != nil:
    section.add "X-Amz-Credential", valid_604004
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604006: Call_GetMaintenanceWindow_603994; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a maintenance window.
  ## 
  let valid = call_604006.validator(path, query, header, formData, body)
  let scheme = call_604006.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604006.url(scheme.get, call_604006.host, call_604006.base,
                         call_604006.route, valid.getOrDefault("path"))
  result = hook(call_604006, url, valid)

proc call*(call_604007: Call_GetMaintenanceWindow_603994; body: JsonNode): Recallable =
  ## getMaintenanceWindow
  ## Retrieves a maintenance window.
  ##   body: JObject (required)
  var body_604008 = newJObject()
  if body != nil:
    body_604008 = body
  result = call_604007.call(nil, nil, nil, nil, body_604008)

var getMaintenanceWindow* = Call_GetMaintenanceWindow_603994(
    name: "getMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetMaintenanceWindow",
    validator: validate_GetMaintenanceWindow_603995, base: "/",
    url: url_GetMaintenanceWindow_603996, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMaintenanceWindowExecution_604009 = ref object of OpenApiRestCall_602433
proc url_GetMaintenanceWindowExecution_604011(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetMaintenanceWindowExecution_604010(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604012 = header.getOrDefault("X-Amz-Date")
  valid_604012 = validateParameter(valid_604012, JString, required = false,
                                 default = nil)
  if valid_604012 != nil:
    section.add "X-Amz-Date", valid_604012
  var valid_604013 = header.getOrDefault("X-Amz-Security-Token")
  valid_604013 = validateParameter(valid_604013, JString, required = false,
                                 default = nil)
  if valid_604013 != nil:
    section.add "X-Amz-Security-Token", valid_604013
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604014 = header.getOrDefault("X-Amz-Target")
  valid_604014 = validateParameter(valid_604014, JString, required = true, default = newJString(
      "AmazonSSM.GetMaintenanceWindowExecution"))
  if valid_604014 != nil:
    section.add "X-Amz-Target", valid_604014
  var valid_604015 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604015 = validateParameter(valid_604015, JString, required = false,
                                 default = nil)
  if valid_604015 != nil:
    section.add "X-Amz-Content-Sha256", valid_604015
  var valid_604016 = header.getOrDefault("X-Amz-Algorithm")
  valid_604016 = validateParameter(valid_604016, JString, required = false,
                                 default = nil)
  if valid_604016 != nil:
    section.add "X-Amz-Algorithm", valid_604016
  var valid_604017 = header.getOrDefault("X-Amz-Signature")
  valid_604017 = validateParameter(valid_604017, JString, required = false,
                                 default = nil)
  if valid_604017 != nil:
    section.add "X-Amz-Signature", valid_604017
  var valid_604018 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604018 = validateParameter(valid_604018, JString, required = false,
                                 default = nil)
  if valid_604018 != nil:
    section.add "X-Amz-SignedHeaders", valid_604018
  var valid_604019 = header.getOrDefault("X-Amz-Credential")
  valid_604019 = validateParameter(valid_604019, JString, required = false,
                                 default = nil)
  if valid_604019 != nil:
    section.add "X-Amz-Credential", valid_604019
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604021: Call_GetMaintenanceWindowExecution_604009; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details about a specific a maintenance window execution.
  ## 
  let valid = call_604021.validator(path, query, header, formData, body)
  let scheme = call_604021.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604021.url(scheme.get, call_604021.host, call_604021.base,
                         call_604021.route, valid.getOrDefault("path"))
  result = hook(call_604021, url, valid)

proc call*(call_604022: Call_GetMaintenanceWindowExecution_604009; body: JsonNode): Recallable =
  ## getMaintenanceWindowExecution
  ## Retrieves details about a specific a maintenance window execution.
  ##   body: JObject (required)
  var body_604023 = newJObject()
  if body != nil:
    body_604023 = body
  result = call_604022.call(nil, nil, nil, nil, body_604023)

var getMaintenanceWindowExecution* = Call_GetMaintenanceWindowExecution_604009(
    name: "getMaintenanceWindowExecution", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetMaintenanceWindowExecution",
    validator: validate_GetMaintenanceWindowExecution_604010, base: "/",
    url: url_GetMaintenanceWindowExecution_604011,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMaintenanceWindowExecutionTask_604024 = ref object of OpenApiRestCall_602433
proc url_GetMaintenanceWindowExecutionTask_604026(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetMaintenanceWindowExecutionTask_604025(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604027 = header.getOrDefault("X-Amz-Date")
  valid_604027 = validateParameter(valid_604027, JString, required = false,
                                 default = nil)
  if valid_604027 != nil:
    section.add "X-Amz-Date", valid_604027
  var valid_604028 = header.getOrDefault("X-Amz-Security-Token")
  valid_604028 = validateParameter(valid_604028, JString, required = false,
                                 default = nil)
  if valid_604028 != nil:
    section.add "X-Amz-Security-Token", valid_604028
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604029 = header.getOrDefault("X-Amz-Target")
  valid_604029 = validateParameter(valid_604029, JString, required = true, default = newJString(
      "AmazonSSM.GetMaintenanceWindowExecutionTask"))
  if valid_604029 != nil:
    section.add "X-Amz-Target", valid_604029
  var valid_604030 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604030 = validateParameter(valid_604030, JString, required = false,
                                 default = nil)
  if valid_604030 != nil:
    section.add "X-Amz-Content-Sha256", valid_604030
  var valid_604031 = header.getOrDefault("X-Amz-Algorithm")
  valid_604031 = validateParameter(valid_604031, JString, required = false,
                                 default = nil)
  if valid_604031 != nil:
    section.add "X-Amz-Algorithm", valid_604031
  var valid_604032 = header.getOrDefault("X-Amz-Signature")
  valid_604032 = validateParameter(valid_604032, JString, required = false,
                                 default = nil)
  if valid_604032 != nil:
    section.add "X-Amz-Signature", valid_604032
  var valid_604033 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604033 = validateParameter(valid_604033, JString, required = false,
                                 default = nil)
  if valid_604033 != nil:
    section.add "X-Amz-SignedHeaders", valid_604033
  var valid_604034 = header.getOrDefault("X-Amz-Credential")
  valid_604034 = validateParameter(valid_604034, JString, required = false,
                                 default = nil)
  if valid_604034 != nil:
    section.add "X-Amz-Credential", valid_604034
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604036: Call_GetMaintenanceWindowExecutionTask_604024;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the details about a specific task run as part of a maintenance window execution.
  ## 
  let valid = call_604036.validator(path, query, header, formData, body)
  let scheme = call_604036.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604036.url(scheme.get, call_604036.host, call_604036.base,
                         call_604036.route, valid.getOrDefault("path"))
  result = hook(call_604036, url, valid)

proc call*(call_604037: Call_GetMaintenanceWindowExecutionTask_604024;
          body: JsonNode): Recallable =
  ## getMaintenanceWindowExecutionTask
  ## Retrieves the details about a specific task run as part of a maintenance window execution.
  ##   body: JObject (required)
  var body_604038 = newJObject()
  if body != nil:
    body_604038 = body
  result = call_604037.call(nil, nil, nil, nil, body_604038)

var getMaintenanceWindowExecutionTask* = Call_GetMaintenanceWindowExecutionTask_604024(
    name: "getMaintenanceWindowExecutionTask", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetMaintenanceWindowExecutionTask",
    validator: validate_GetMaintenanceWindowExecutionTask_604025, base: "/",
    url: url_GetMaintenanceWindowExecutionTask_604026,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMaintenanceWindowExecutionTaskInvocation_604039 = ref object of OpenApiRestCall_602433
proc url_GetMaintenanceWindowExecutionTaskInvocation_604041(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetMaintenanceWindowExecutionTaskInvocation_604040(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604042 = header.getOrDefault("X-Amz-Date")
  valid_604042 = validateParameter(valid_604042, JString, required = false,
                                 default = nil)
  if valid_604042 != nil:
    section.add "X-Amz-Date", valid_604042
  var valid_604043 = header.getOrDefault("X-Amz-Security-Token")
  valid_604043 = validateParameter(valid_604043, JString, required = false,
                                 default = nil)
  if valid_604043 != nil:
    section.add "X-Amz-Security-Token", valid_604043
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604044 = header.getOrDefault("X-Amz-Target")
  valid_604044 = validateParameter(valid_604044, JString, required = true, default = newJString(
      "AmazonSSM.GetMaintenanceWindowExecutionTaskInvocation"))
  if valid_604044 != nil:
    section.add "X-Amz-Target", valid_604044
  var valid_604045 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604045 = validateParameter(valid_604045, JString, required = false,
                                 default = nil)
  if valid_604045 != nil:
    section.add "X-Amz-Content-Sha256", valid_604045
  var valid_604046 = header.getOrDefault("X-Amz-Algorithm")
  valid_604046 = validateParameter(valid_604046, JString, required = false,
                                 default = nil)
  if valid_604046 != nil:
    section.add "X-Amz-Algorithm", valid_604046
  var valid_604047 = header.getOrDefault("X-Amz-Signature")
  valid_604047 = validateParameter(valid_604047, JString, required = false,
                                 default = nil)
  if valid_604047 != nil:
    section.add "X-Amz-Signature", valid_604047
  var valid_604048 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604048 = validateParameter(valid_604048, JString, required = false,
                                 default = nil)
  if valid_604048 != nil:
    section.add "X-Amz-SignedHeaders", valid_604048
  var valid_604049 = header.getOrDefault("X-Amz-Credential")
  valid_604049 = validateParameter(valid_604049, JString, required = false,
                                 default = nil)
  if valid_604049 != nil:
    section.add "X-Amz-Credential", valid_604049
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604051: Call_GetMaintenanceWindowExecutionTaskInvocation_604039;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves information about a specific task running on a specific target.
  ## 
  let valid = call_604051.validator(path, query, header, formData, body)
  let scheme = call_604051.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604051.url(scheme.get, call_604051.host, call_604051.base,
                         call_604051.route, valid.getOrDefault("path"))
  result = hook(call_604051, url, valid)

proc call*(call_604052: Call_GetMaintenanceWindowExecutionTaskInvocation_604039;
          body: JsonNode): Recallable =
  ## getMaintenanceWindowExecutionTaskInvocation
  ## Retrieves information about a specific task running on a specific target.
  ##   body: JObject (required)
  var body_604053 = newJObject()
  if body != nil:
    body_604053 = body
  result = call_604052.call(nil, nil, nil, nil, body_604053)

var getMaintenanceWindowExecutionTaskInvocation* = Call_GetMaintenanceWindowExecutionTaskInvocation_604039(
    name: "getMaintenanceWindowExecutionTaskInvocation",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com", route: "/#X-Amz-Target=AmazonSSM.GetMaintenanceWindowExecutionTaskInvocation",
    validator: validate_GetMaintenanceWindowExecutionTaskInvocation_604040,
    base: "/", url: url_GetMaintenanceWindowExecutionTaskInvocation_604041,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMaintenanceWindowTask_604054 = ref object of OpenApiRestCall_602433
proc url_GetMaintenanceWindowTask_604056(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetMaintenanceWindowTask_604055(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604057 = header.getOrDefault("X-Amz-Date")
  valid_604057 = validateParameter(valid_604057, JString, required = false,
                                 default = nil)
  if valid_604057 != nil:
    section.add "X-Amz-Date", valid_604057
  var valid_604058 = header.getOrDefault("X-Amz-Security-Token")
  valid_604058 = validateParameter(valid_604058, JString, required = false,
                                 default = nil)
  if valid_604058 != nil:
    section.add "X-Amz-Security-Token", valid_604058
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604059 = header.getOrDefault("X-Amz-Target")
  valid_604059 = validateParameter(valid_604059, JString, required = true, default = newJString(
      "AmazonSSM.GetMaintenanceWindowTask"))
  if valid_604059 != nil:
    section.add "X-Amz-Target", valid_604059
  var valid_604060 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604060 = validateParameter(valid_604060, JString, required = false,
                                 default = nil)
  if valid_604060 != nil:
    section.add "X-Amz-Content-Sha256", valid_604060
  var valid_604061 = header.getOrDefault("X-Amz-Algorithm")
  valid_604061 = validateParameter(valid_604061, JString, required = false,
                                 default = nil)
  if valid_604061 != nil:
    section.add "X-Amz-Algorithm", valid_604061
  var valid_604062 = header.getOrDefault("X-Amz-Signature")
  valid_604062 = validateParameter(valid_604062, JString, required = false,
                                 default = nil)
  if valid_604062 != nil:
    section.add "X-Amz-Signature", valid_604062
  var valid_604063 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604063 = validateParameter(valid_604063, JString, required = false,
                                 default = nil)
  if valid_604063 != nil:
    section.add "X-Amz-SignedHeaders", valid_604063
  var valid_604064 = header.getOrDefault("X-Amz-Credential")
  valid_604064 = validateParameter(valid_604064, JString, required = false,
                                 default = nil)
  if valid_604064 != nil:
    section.add "X-Amz-Credential", valid_604064
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604066: Call_GetMaintenanceWindowTask_604054; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tasks in a maintenance window.
  ## 
  let valid = call_604066.validator(path, query, header, formData, body)
  let scheme = call_604066.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604066.url(scheme.get, call_604066.host, call_604066.base,
                         call_604066.route, valid.getOrDefault("path"))
  result = hook(call_604066, url, valid)

proc call*(call_604067: Call_GetMaintenanceWindowTask_604054; body: JsonNode): Recallable =
  ## getMaintenanceWindowTask
  ## Lists the tasks in a maintenance window.
  ##   body: JObject (required)
  var body_604068 = newJObject()
  if body != nil:
    body_604068 = body
  result = call_604067.call(nil, nil, nil, nil, body_604068)

var getMaintenanceWindowTask* = Call_GetMaintenanceWindowTask_604054(
    name: "getMaintenanceWindowTask", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetMaintenanceWindowTask",
    validator: validate_GetMaintenanceWindowTask_604055, base: "/",
    url: url_GetMaintenanceWindowTask_604056, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOpsItem_604069 = ref object of OpenApiRestCall_602433
proc url_GetOpsItem_604071(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetOpsItem_604070(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604072 = header.getOrDefault("X-Amz-Date")
  valid_604072 = validateParameter(valid_604072, JString, required = false,
                                 default = nil)
  if valid_604072 != nil:
    section.add "X-Amz-Date", valid_604072
  var valid_604073 = header.getOrDefault("X-Amz-Security-Token")
  valid_604073 = validateParameter(valid_604073, JString, required = false,
                                 default = nil)
  if valid_604073 != nil:
    section.add "X-Amz-Security-Token", valid_604073
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604074 = header.getOrDefault("X-Amz-Target")
  valid_604074 = validateParameter(valid_604074, JString, required = true,
                                 default = newJString("AmazonSSM.GetOpsItem"))
  if valid_604074 != nil:
    section.add "X-Amz-Target", valid_604074
  var valid_604075 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604075 = validateParameter(valid_604075, JString, required = false,
                                 default = nil)
  if valid_604075 != nil:
    section.add "X-Amz-Content-Sha256", valid_604075
  var valid_604076 = header.getOrDefault("X-Amz-Algorithm")
  valid_604076 = validateParameter(valid_604076, JString, required = false,
                                 default = nil)
  if valid_604076 != nil:
    section.add "X-Amz-Algorithm", valid_604076
  var valid_604077 = header.getOrDefault("X-Amz-Signature")
  valid_604077 = validateParameter(valid_604077, JString, required = false,
                                 default = nil)
  if valid_604077 != nil:
    section.add "X-Amz-Signature", valid_604077
  var valid_604078 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604078 = validateParameter(valid_604078, JString, required = false,
                                 default = nil)
  if valid_604078 != nil:
    section.add "X-Amz-SignedHeaders", valid_604078
  var valid_604079 = header.getOrDefault("X-Amz-Credential")
  valid_604079 = validateParameter(valid_604079, JString, required = false,
                                 default = nil)
  if valid_604079 != nil:
    section.add "X-Amz-Credential", valid_604079
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604081: Call_GetOpsItem_604069; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Get information about an OpsItem by using the ID. You must have permission in AWS Identity and Access Management (IAM) to view information about an OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ## 
  let valid = call_604081.validator(path, query, header, formData, body)
  let scheme = call_604081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604081.url(scheme.get, call_604081.host, call_604081.base,
                         call_604081.route, valid.getOrDefault("path"))
  result = hook(call_604081, url, valid)

proc call*(call_604082: Call_GetOpsItem_604069; body: JsonNode): Recallable =
  ## getOpsItem
  ## <p>Get information about an OpsItem by using the ID. You must have permission in AWS Identity and Access Management (IAM) to view information about an OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ##   body: JObject (required)
  var body_604083 = newJObject()
  if body != nil:
    body_604083 = body
  result = call_604082.call(nil, nil, nil, nil, body_604083)

var getOpsItem* = Call_GetOpsItem_604069(name: "getOpsItem",
                                      meth: HttpMethod.HttpPost,
                                      host: "ssm.amazonaws.com", route: "/#X-Amz-Target=AmazonSSM.GetOpsItem",
                                      validator: validate_GetOpsItem_604070,
                                      base: "/", url: url_GetOpsItem_604071,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOpsSummary_604084 = ref object of OpenApiRestCall_602433
proc url_GetOpsSummary_604086(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetOpsSummary_604085(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604087 = header.getOrDefault("X-Amz-Date")
  valid_604087 = validateParameter(valid_604087, JString, required = false,
                                 default = nil)
  if valid_604087 != nil:
    section.add "X-Amz-Date", valid_604087
  var valid_604088 = header.getOrDefault("X-Amz-Security-Token")
  valid_604088 = validateParameter(valid_604088, JString, required = false,
                                 default = nil)
  if valid_604088 != nil:
    section.add "X-Amz-Security-Token", valid_604088
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604089 = header.getOrDefault("X-Amz-Target")
  valid_604089 = validateParameter(valid_604089, JString, required = true, default = newJString(
      "AmazonSSM.GetOpsSummary"))
  if valid_604089 != nil:
    section.add "X-Amz-Target", valid_604089
  var valid_604090 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604090 = validateParameter(valid_604090, JString, required = false,
                                 default = nil)
  if valid_604090 != nil:
    section.add "X-Amz-Content-Sha256", valid_604090
  var valid_604091 = header.getOrDefault("X-Amz-Algorithm")
  valid_604091 = validateParameter(valid_604091, JString, required = false,
                                 default = nil)
  if valid_604091 != nil:
    section.add "X-Amz-Algorithm", valid_604091
  var valid_604092 = header.getOrDefault("X-Amz-Signature")
  valid_604092 = validateParameter(valid_604092, JString, required = false,
                                 default = nil)
  if valid_604092 != nil:
    section.add "X-Amz-Signature", valid_604092
  var valid_604093 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604093 = validateParameter(valid_604093, JString, required = false,
                                 default = nil)
  if valid_604093 != nil:
    section.add "X-Amz-SignedHeaders", valid_604093
  var valid_604094 = header.getOrDefault("X-Amz-Credential")
  valid_604094 = validateParameter(valid_604094, JString, required = false,
                                 default = nil)
  if valid_604094 != nil:
    section.add "X-Amz-Credential", valid_604094
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604096: Call_GetOpsSummary_604084; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## View a summary of OpsItems based on specified filters and aggregators.
  ## 
  let valid = call_604096.validator(path, query, header, formData, body)
  let scheme = call_604096.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604096.url(scheme.get, call_604096.host, call_604096.base,
                         call_604096.route, valid.getOrDefault("path"))
  result = hook(call_604096, url, valid)

proc call*(call_604097: Call_GetOpsSummary_604084; body: JsonNode): Recallable =
  ## getOpsSummary
  ## View a summary of OpsItems based on specified filters and aggregators.
  ##   body: JObject (required)
  var body_604098 = newJObject()
  if body != nil:
    body_604098 = body
  result = call_604097.call(nil, nil, nil, nil, body_604098)

var getOpsSummary* = Call_GetOpsSummary_604084(name: "getOpsSummary",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetOpsSummary",
    validator: validate_GetOpsSummary_604085, base: "/", url: url_GetOpsSummary_604086,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetParameter_604099 = ref object of OpenApiRestCall_602433
proc url_GetParameter_604101(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetParameter_604100(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604102 = header.getOrDefault("X-Amz-Date")
  valid_604102 = validateParameter(valid_604102, JString, required = false,
                                 default = nil)
  if valid_604102 != nil:
    section.add "X-Amz-Date", valid_604102
  var valid_604103 = header.getOrDefault("X-Amz-Security-Token")
  valid_604103 = validateParameter(valid_604103, JString, required = false,
                                 default = nil)
  if valid_604103 != nil:
    section.add "X-Amz-Security-Token", valid_604103
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604104 = header.getOrDefault("X-Amz-Target")
  valid_604104 = validateParameter(valid_604104, JString, required = true,
                                 default = newJString("AmazonSSM.GetParameter"))
  if valid_604104 != nil:
    section.add "X-Amz-Target", valid_604104
  var valid_604105 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604105 = validateParameter(valid_604105, JString, required = false,
                                 default = nil)
  if valid_604105 != nil:
    section.add "X-Amz-Content-Sha256", valid_604105
  var valid_604106 = header.getOrDefault("X-Amz-Algorithm")
  valid_604106 = validateParameter(valid_604106, JString, required = false,
                                 default = nil)
  if valid_604106 != nil:
    section.add "X-Amz-Algorithm", valid_604106
  var valid_604107 = header.getOrDefault("X-Amz-Signature")
  valid_604107 = validateParameter(valid_604107, JString, required = false,
                                 default = nil)
  if valid_604107 != nil:
    section.add "X-Amz-Signature", valid_604107
  var valid_604108 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604108 = validateParameter(valid_604108, JString, required = false,
                                 default = nil)
  if valid_604108 != nil:
    section.add "X-Amz-SignedHeaders", valid_604108
  var valid_604109 = header.getOrDefault("X-Amz-Credential")
  valid_604109 = validateParameter(valid_604109, JString, required = false,
                                 default = nil)
  if valid_604109 != nil:
    section.add "X-Amz-Credential", valid_604109
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604111: Call_GetParameter_604099; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get information about a parameter by using the parameter name. Don't confuse this API action with the <a>GetParameters</a> API action.
  ## 
  let valid = call_604111.validator(path, query, header, formData, body)
  let scheme = call_604111.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604111.url(scheme.get, call_604111.host, call_604111.base,
                         call_604111.route, valid.getOrDefault("path"))
  result = hook(call_604111, url, valid)

proc call*(call_604112: Call_GetParameter_604099; body: JsonNode): Recallable =
  ## getParameter
  ## Get information about a parameter by using the parameter name. Don't confuse this API action with the <a>GetParameters</a> API action.
  ##   body: JObject (required)
  var body_604113 = newJObject()
  if body != nil:
    body_604113 = body
  result = call_604112.call(nil, nil, nil, nil, body_604113)

var getParameter* = Call_GetParameter_604099(name: "getParameter",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetParameter",
    validator: validate_GetParameter_604100, base: "/", url: url_GetParameter_604101,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetParameterHistory_604114 = ref object of OpenApiRestCall_602433
proc url_GetParameterHistory_604116(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetParameterHistory_604115(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Query a list of all parameters used by the AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_604117 = query.getOrDefault("NextToken")
  valid_604117 = validateParameter(valid_604117, JString, required = false,
                                 default = nil)
  if valid_604117 != nil:
    section.add "NextToken", valid_604117
  var valid_604118 = query.getOrDefault("MaxResults")
  valid_604118 = validateParameter(valid_604118, JString, required = false,
                                 default = nil)
  if valid_604118 != nil:
    section.add "MaxResults", valid_604118
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604119 = header.getOrDefault("X-Amz-Date")
  valid_604119 = validateParameter(valid_604119, JString, required = false,
                                 default = nil)
  if valid_604119 != nil:
    section.add "X-Amz-Date", valid_604119
  var valid_604120 = header.getOrDefault("X-Amz-Security-Token")
  valid_604120 = validateParameter(valid_604120, JString, required = false,
                                 default = nil)
  if valid_604120 != nil:
    section.add "X-Amz-Security-Token", valid_604120
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604121 = header.getOrDefault("X-Amz-Target")
  valid_604121 = validateParameter(valid_604121, JString, required = true, default = newJString(
      "AmazonSSM.GetParameterHistory"))
  if valid_604121 != nil:
    section.add "X-Amz-Target", valid_604121
  var valid_604122 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604122 = validateParameter(valid_604122, JString, required = false,
                                 default = nil)
  if valid_604122 != nil:
    section.add "X-Amz-Content-Sha256", valid_604122
  var valid_604123 = header.getOrDefault("X-Amz-Algorithm")
  valid_604123 = validateParameter(valid_604123, JString, required = false,
                                 default = nil)
  if valid_604123 != nil:
    section.add "X-Amz-Algorithm", valid_604123
  var valid_604124 = header.getOrDefault("X-Amz-Signature")
  valid_604124 = validateParameter(valid_604124, JString, required = false,
                                 default = nil)
  if valid_604124 != nil:
    section.add "X-Amz-Signature", valid_604124
  var valid_604125 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604125 = validateParameter(valid_604125, JString, required = false,
                                 default = nil)
  if valid_604125 != nil:
    section.add "X-Amz-SignedHeaders", valid_604125
  var valid_604126 = header.getOrDefault("X-Amz-Credential")
  valid_604126 = validateParameter(valid_604126, JString, required = false,
                                 default = nil)
  if valid_604126 != nil:
    section.add "X-Amz-Credential", valid_604126
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604128: Call_GetParameterHistory_604114; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Query a list of all parameters used by the AWS account.
  ## 
  let valid = call_604128.validator(path, query, header, formData, body)
  let scheme = call_604128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604128.url(scheme.get, call_604128.host, call_604128.base,
                         call_604128.route, valid.getOrDefault("path"))
  result = hook(call_604128, url, valid)

proc call*(call_604129: Call_GetParameterHistory_604114; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getParameterHistory
  ## Query a list of all parameters used by the AWS account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_604130 = newJObject()
  var body_604131 = newJObject()
  add(query_604130, "NextToken", newJString(NextToken))
  if body != nil:
    body_604131 = body
  add(query_604130, "MaxResults", newJString(MaxResults))
  result = call_604129.call(nil, query_604130, nil, nil, body_604131)

var getParameterHistory* = Call_GetParameterHistory_604114(
    name: "getParameterHistory", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetParameterHistory",
    validator: validate_GetParameterHistory_604115, base: "/",
    url: url_GetParameterHistory_604116, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetParameters_604132 = ref object of OpenApiRestCall_602433
proc url_GetParameters_604134(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetParameters_604133(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604135 = header.getOrDefault("X-Amz-Date")
  valid_604135 = validateParameter(valid_604135, JString, required = false,
                                 default = nil)
  if valid_604135 != nil:
    section.add "X-Amz-Date", valid_604135
  var valid_604136 = header.getOrDefault("X-Amz-Security-Token")
  valid_604136 = validateParameter(valid_604136, JString, required = false,
                                 default = nil)
  if valid_604136 != nil:
    section.add "X-Amz-Security-Token", valid_604136
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604137 = header.getOrDefault("X-Amz-Target")
  valid_604137 = validateParameter(valid_604137, JString, required = true, default = newJString(
      "AmazonSSM.GetParameters"))
  if valid_604137 != nil:
    section.add "X-Amz-Target", valid_604137
  var valid_604138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604138 = validateParameter(valid_604138, JString, required = false,
                                 default = nil)
  if valid_604138 != nil:
    section.add "X-Amz-Content-Sha256", valid_604138
  var valid_604139 = header.getOrDefault("X-Amz-Algorithm")
  valid_604139 = validateParameter(valid_604139, JString, required = false,
                                 default = nil)
  if valid_604139 != nil:
    section.add "X-Amz-Algorithm", valid_604139
  var valid_604140 = header.getOrDefault("X-Amz-Signature")
  valid_604140 = validateParameter(valid_604140, JString, required = false,
                                 default = nil)
  if valid_604140 != nil:
    section.add "X-Amz-Signature", valid_604140
  var valid_604141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604141 = validateParameter(valid_604141, JString, required = false,
                                 default = nil)
  if valid_604141 != nil:
    section.add "X-Amz-SignedHeaders", valid_604141
  var valid_604142 = header.getOrDefault("X-Amz-Credential")
  valid_604142 = validateParameter(valid_604142, JString, required = false,
                                 default = nil)
  if valid_604142 != nil:
    section.add "X-Amz-Credential", valid_604142
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604144: Call_GetParameters_604132; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get details of a parameter. Don't confuse this API action with the <a>GetParameter</a> API action.
  ## 
  let valid = call_604144.validator(path, query, header, formData, body)
  let scheme = call_604144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604144.url(scheme.get, call_604144.host, call_604144.base,
                         call_604144.route, valid.getOrDefault("path"))
  result = hook(call_604144, url, valid)

proc call*(call_604145: Call_GetParameters_604132; body: JsonNode): Recallable =
  ## getParameters
  ## Get details of a parameter. Don't confuse this API action with the <a>GetParameter</a> API action.
  ##   body: JObject (required)
  var body_604146 = newJObject()
  if body != nil:
    body_604146 = body
  result = call_604145.call(nil, nil, nil, nil, body_604146)

var getParameters* = Call_GetParameters_604132(name: "getParameters",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetParameters",
    validator: validate_GetParameters_604133, base: "/", url: url_GetParameters_604134,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetParametersByPath_604147 = ref object of OpenApiRestCall_602433
proc url_GetParametersByPath_604149(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetParametersByPath_604148(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Retrieve parameters in a specific hierarchy. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-paramstore-working.html">Working with Systems Manager Parameters</a> in the <i>AWS Systems Manager User Guide</i>. </p> <p>Request results are returned on a best-effort basis. If you specify <code>MaxResults</code> in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of <code>MaxResults</code>. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a <code>NextToken</code>. You can specify the <code>NextToken</code> in a subsequent call to get the next set of results.</p> <note> <p>This API action doesn't support filtering by tags. </p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_604150 = query.getOrDefault("NextToken")
  valid_604150 = validateParameter(valid_604150, JString, required = false,
                                 default = nil)
  if valid_604150 != nil:
    section.add "NextToken", valid_604150
  var valid_604151 = query.getOrDefault("MaxResults")
  valid_604151 = validateParameter(valid_604151, JString, required = false,
                                 default = nil)
  if valid_604151 != nil:
    section.add "MaxResults", valid_604151
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604152 = header.getOrDefault("X-Amz-Date")
  valid_604152 = validateParameter(valid_604152, JString, required = false,
                                 default = nil)
  if valid_604152 != nil:
    section.add "X-Amz-Date", valid_604152
  var valid_604153 = header.getOrDefault("X-Amz-Security-Token")
  valid_604153 = validateParameter(valid_604153, JString, required = false,
                                 default = nil)
  if valid_604153 != nil:
    section.add "X-Amz-Security-Token", valid_604153
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604154 = header.getOrDefault("X-Amz-Target")
  valid_604154 = validateParameter(valid_604154, JString, required = true, default = newJString(
      "AmazonSSM.GetParametersByPath"))
  if valid_604154 != nil:
    section.add "X-Amz-Target", valid_604154
  var valid_604155 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604155 = validateParameter(valid_604155, JString, required = false,
                                 default = nil)
  if valid_604155 != nil:
    section.add "X-Amz-Content-Sha256", valid_604155
  var valid_604156 = header.getOrDefault("X-Amz-Algorithm")
  valid_604156 = validateParameter(valid_604156, JString, required = false,
                                 default = nil)
  if valid_604156 != nil:
    section.add "X-Amz-Algorithm", valid_604156
  var valid_604157 = header.getOrDefault("X-Amz-Signature")
  valid_604157 = validateParameter(valid_604157, JString, required = false,
                                 default = nil)
  if valid_604157 != nil:
    section.add "X-Amz-Signature", valid_604157
  var valid_604158 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604158 = validateParameter(valid_604158, JString, required = false,
                                 default = nil)
  if valid_604158 != nil:
    section.add "X-Amz-SignedHeaders", valid_604158
  var valid_604159 = header.getOrDefault("X-Amz-Credential")
  valid_604159 = validateParameter(valid_604159, JString, required = false,
                                 default = nil)
  if valid_604159 != nil:
    section.add "X-Amz-Credential", valid_604159
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604161: Call_GetParametersByPath_604147; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieve parameters in a specific hierarchy. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-paramstore-working.html">Working with Systems Manager Parameters</a> in the <i>AWS Systems Manager User Guide</i>. </p> <p>Request results are returned on a best-effort basis. If you specify <code>MaxResults</code> in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of <code>MaxResults</code>. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a <code>NextToken</code>. You can specify the <code>NextToken</code> in a subsequent call to get the next set of results.</p> <note> <p>This API action doesn't support filtering by tags. </p> </note>
  ## 
  let valid = call_604161.validator(path, query, header, formData, body)
  let scheme = call_604161.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604161.url(scheme.get, call_604161.host, call_604161.base,
                         call_604161.route, valid.getOrDefault("path"))
  result = hook(call_604161, url, valid)

proc call*(call_604162: Call_GetParametersByPath_604147; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getParametersByPath
  ## <p>Retrieve parameters in a specific hierarchy. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-paramstore-working.html">Working with Systems Manager Parameters</a> in the <i>AWS Systems Manager User Guide</i>. </p> <p>Request results are returned on a best-effort basis. If you specify <code>MaxResults</code> in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of <code>MaxResults</code>. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a <code>NextToken</code>. You can specify the <code>NextToken</code> in a subsequent call to get the next set of results.</p> <note> <p>This API action doesn't support filtering by tags. </p> </note>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_604163 = newJObject()
  var body_604164 = newJObject()
  add(query_604163, "NextToken", newJString(NextToken))
  if body != nil:
    body_604164 = body
  add(query_604163, "MaxResults", newJString(MaxResults))
  result = call_604162.call(nil, query_604163, nil, nil, body_604164)

var getParametersByPath* = Call_GetParametersByPath_604147(
    name: "getParametersByPath", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetParametersByPath",
    validator: validate_GetParametersByPath_604148, base: "/",
    url: url_GetParametersByPath_604149, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPatchBaseline_604165 = ref object of OpenApiRestCall_602433
proc url_GetPatchBaseline_604167(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetPatchBaseline_604166(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604168 = header.getOrDefault("X-Amz-Date")
  valid_604168 = validateParameter(valid_604168, JString, required = false,
                                 default = nil)
  if valid_604168 != nil:
    section.add "X-Amz-Date", valid_604168
  var valid_604169 = header.getOrDefault("X-Amz-Security-Token")
  valid_604169 = validateParameter(valid_604169, JString, required = false,
                                 default = nil)
  if valid_604169 != nil:
    section.add "X-Amz-Security-Token", valid_604169
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604170 = header.getOrDefault("X-Amz-Target")
  valid_604170 = validateParameter(valid_604170, JString, required = true, default = newJString(
      "AmazonSSM.GetPatchBaseline"))
  if valid_604170 != nil:
    section.add "X-Amz-Target", valid_604170
  var valid_604171 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604171 = validateParameter(valid_604171, JString, required = false,
                                 default = nil)
  if valid_604171 != nil:
    section.add "X-Amz-Content-Sha256", valid_604171
  var valid_604172 = header.getOrDefault("X-Amz-Algorithm")
  valid_604172 = validateParameter(valid_604172, JString, required = false,
                                 default = nil)
  if valid_604172 != nil:
    section.add "X-Amz-Algorithm", valid_604172
  var valid_604173 = header.getOrDefault("X-Amz-Signature")
  valid_604173 = validateParameter(valid_604173, JString, required = false,
                                 default = nil)
  if valid_604173 != nil:
    section.add "X-Amz-Signature", valid_604173
  var valid_604174 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604174 = validateParameter(valid_604174, JString, required = false,
                                 default = nil)
  if valid_604174 != nil:
    section.add "X-Amz-SignedHeaders", valid_604174
  var valid_604175 = header.getOrDefault("X-Amz-Credential")
  valid_604175 = validateParameter(valid_604175, JString, required = false,
                                 default = nil)
  if valid_604175 != nil:
    section.add "X-Amz-Credential", valid_604175
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604177: Call_GetPatchBaseline_604165; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a patch baseline.
  ## 
  let valid = call_604177.validator(path, query, header, formData, body)
  let scheme = call_604177.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604177.url(scheme.get, call_604177.host, call_604177.base,
                         call_604177.route, valid.getOrDefault("path"))
  result = hook(call_604177, url, valid)

proc call*(call_604178: Call_GetPatchBaseline_604165; body: JsonNode): Recallable =
  ## getPatchBaseline
  ## Retrieves information about a patch baseline.
  ##   body: JObject (required)
  var body_604179 = newJObject()
  if body != nil:
    body_604179 = body
  result = call_604178.call(nil, nil, nil, nil, body_604179)

var getPatchBaseline* = Call_GetPatchBaseline_604165(name: "getPatchBaseline",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetPatchBaseline",
    validator: validate_GetPatchBaseline_604166, base: "/",
    url: url_GetPatchBaseline_604167, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPatchBaselineForPatchGroup_604180 = ref object of OpenApiRestCall_602433
proc url_GetPatchBaselineForPatchGroup_604182(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetPatchBaselineForPatchGroup_604181(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604183 = header.getOrDefault("X-Amz-Date")
  valid_604183 = validateParameter(valid_604183, JString, required = false,
                                 default = nil)
  if valid_604183 != nil:
    section.add "X-Amz-Date", valid_604183
  var valid_604184 = header.getOrDefault("X-Amz-Security-Token")
  valid_604184 = validateParameter(valid_604184, JString, required = false,
                                 default = nil)
  if valid_604184 != nil:
    section.add "X-Amz-Security-Token", valid_604184
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604185 = header.getOrDefault("X-Amz-Target")
  valid_604185 = validateParameter(valid_604185, JString, required = true, default = newJString(
      "AmazonSSM.GetPatchBaselineForPatchGroup"))
  if valid_604185 != nil:
    section.add "X-Amz-Target", valid_604185
  var valid_604186 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604186 = validateParameter(valid_604186, JString, required = false,
                                 default = nil)
  if valid_604186 != nil:
    section.add "X-Amz-Content-Sha256", valid_604186
  var valid_604187 = header.getOrDefault("X-Amz-Algorithm")
  valid_604187 = validateParameter(valid_604187, JString, required = false,
                                 default = nil)
  if valid_604187 != nil:
    section.add "X-Amz-Algorithm", valid_604187
  var valid_604188 = header.getOrDefault("X-Amz-Signature")
  valid_604188 = validateParameter(valid_604188, JString, required = false,
                                 default = nil)
  if valid_604188 != nil:
    section.add "X-Amz-Signature", valid_604188
  var valid_604189 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604189 = validateParameter(valid_604189, JString, required = false,
                                 default = nil)
  if valid_604189 != nil:
    section.add "X-Amz-SignedHeaders", valid_604189
  var valid_604190 = header.getOrDefault("X-Amz-Credential")
  valid_604190 = validateParameter(valid_604190, JString, required = false,
                                 default = nil)
  if valid_604190 != nil:
    section.add "X-Amz-Credential", valid_604190
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604192: Call_GetPatchBaselineForPatchGroup_604180; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the patch baseline that should be used for the specified patch group.
  ## 
  let valid = call_604192.validator(path, query, header, formData, body)
  let scheme = call_604192.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604192.url(scheme.get, call_604192.host, call_604192.base,
                         call_604192.route, valid.getOrDefault("path"))
  result = hook(call_604192, url, valid)

proc call*(call_604193: Call_GetPatchBaselineForPatchGroup_604180; body: JsonNode): Recallable =
  ## getPatchBaselineForPatchGroup
  ## Retrieves the patch baseline that should be used for the specified patch group.
  ##   body: JObject (required)
  var body_604194 = newJObject()
  if body != nil:
    body_604194 = body
  result = call_604193.call(nil, nil, nil, nil, body_604194)

var getPatchBaselineForPatchGroup* = Call_GetPatchBaselineForPatchGroup_604180(
    name: "getPatchBaselineForPatchGroup", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetPatchBaselineForPatchGroup",
    validator: validate_GetPatchBaselineForPatchGroup_604181, base: "/",
    url: url_GetPatchBaselineForPatchGroup_604182,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetServiceSetting_604195 = ref object of OpenApiRestCall_602433
proc url_GetServiceSetting_604197(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetServiceSetting_604196(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604198 = header.getOrDefault("X-Amz-Date")
  valid_604198 = validateParameter(valid_604198, JString, required = false,
                                 default = nil)
  if valid_604198 != nil:
    section.add "X-Amz-Date", valid_604198
  var valid_604199 = header.getOrDefault("X-Amz-Security-Token")
  valid_604199 = validateParameter(valid_604199, JString, required = false,
                                 default = nil)
  if valid_604199 != nil:
    section.add "X-Amz-Security-Token", valid_604199
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604200 = header.getOrDefault("X-Amz-Target")
  valid_604200 = validateParameter(valid_604200, JString, required = true, default = newJString(
      "AmazonSSM.GetServiceSetting"))
  if valid_604200 != nil:
    section.add "X-Amz-Target", valid_604200
  var valid_604201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604201 = validateParameter(valid_604201, JString, required = false,
                                 default = nil)
  if valid_604201 != nil:
    section.add "X-Amz-Content-Sha256", valid_604201
  var valid_604202 = header.getOrDefault("X-Amz-Algorithm")
  valid_604202 = validateParameter(valid_604202, JString, required = false,
                                 default = nil)
  if valid_604202 != nil:
    section.add "X-Amz-Algorithm", valid_604202
  var valid_604203 = header.getOrDefault("X-Amz-Signature")
  valid_604203 = validateParameter(valid_604203, JString, required = false,
                                 default = nil)
  if valid_604203 != nil:
    section.add "X-Amz-Signature", valid_604203
  var valid_604204 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604204 = validateParameter(valid_604204, JString, required = false,
                                 default = nil)
  if valid_604204 != nil:
    section.add "X-Amz-SignedHeaders", valid_604204
  var valid_604205 = header.getOrDefault("X-Amz-Credential")
  valid_604205 = validateParameter(valid_604205, JString, required = false,
                                 default = nil)
  if valid_604205 != nil:
    section.add "X-Amz-Credential", valid_604205
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604207: Call_GetServiceSetting_604195; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>UpdateServiceSetting</a> API action to change the default setting. Or use the <a>ResetServiceSetting</a> to change the value back to the original value defined by the AWS service team.</p> <p>Query the current service setting for the account. </p>
  ## 
  let valid = call_604207.validator(path, query, header, formData, body)
  let scheme = call_604207.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604207.url(scheme.get, call_604207.host, call_604207.base,
                         call_604207.route, valid.getOrDefault("path"))
  result = hook(call_604207, url, valid)

proc call*(call_604208: Call_GetServiceSetting_604195; body: JsonNode): Recallable =
  ## getServiceSetting
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>UpdateServiceSetting</a> API action to change the default setting. Or use the <a>ResetServiceSetting</a> to change the value back to the original value defined by the AWS service team.</p> <p>Query the current service setting for the account. </p>
  ##   body: JObject (required)
  var body_604209 = newJObject()
  if body != nil:
    body_604209 = body
  result = call_604208.call(nil, nil, nil, nil, body_604209)

var getServiceSetting* = Call_GetServiceSetting_604195(name: "getServiceSetting",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetServiceSetting",
    validator: validate_GetServiceSetting_604196, base: "/",
    url: url_GetServiceSetting_604197, schemes: {Scheme.Https, Scheme.Http})
type
  Call_LabelParameterVersion_604210 = ref object of OpenApiRestCall_602433
proc url_LabelParameterVersion_604212(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_LabelParameterVersion_604211(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604213 = header.getOrDefault("X-Amz-Date")
  valid_604213 = validateParameter(valid_604213, JString, required = false,
                                 default = nil)
  if valid_604213 != nil:
    section.add "X-Amz-Date", valid_604213
  var valid_604214 = header.getOrDefault("X-Amz-Security-Token")
  valid_604214 = validateParameter(valid_604214, JString, required = false,
                                 default = nil)
  if valid_604214 != nil:
    section.add "X-Amz-Security-Token", valid_604214
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604215 = header.getOrDefault("X-Amz-Target")
  valid_604215 = validateParameter(valid_604215, JString, required = true, default = newJString(
      "AmazonSSM.LabelParameterVersion"))
  if valid_604215 != nil:
    section.add "X-Amz-Target", valid_604215
  var valid_604216 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604216 = validateParameter(valid_604216, JString, required = false,
                                 default = nil)
  if valid_604216 != nil:
    section.add "X-Amz-Content-Sha256", valid_604216
  var valid_604217 = header.getOrDefault("X-Amz-Algorithm")
  valid_604217 = validateParameter(valid_604217, JString, required = false,
                                 default = nil)
  if valid_604217 != nil:
    section.add "X-Amz-Algorithm", valid_604217
  var valid_604218 = header.getOrDefault("X-Amz-Signature")
  valid_604218 = validateParameter(valid_604218, JString, required = false,
                                 default = nil)
  if valid_604218 != nil:
    section.add "X-Amz-Signature", valid_604218
  var valid_604219 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604219 = validateParameter(valid_604219, JString, required = false,
                                 default = nil)
  if valid_604219 != nil:
    section.add "X-Amz-SignedHeaders", valid_604219
  var valid_604220 = header.getOrDefault("X-Amz-Credential")
  valid_604220 = validateParameter(valid_604220, JString, required = false,
                                 default = nil)
  if valid_604220 != nil:
    section.add "X-Amz-Credential", valid_604220
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604222: Call_LabelParameterVersion_604210; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>A parameter label is a user-defined alias to help you manage different versions of a parameter. When you modify a parameter, Systems Manager automatically saves a new version and increments the version number by one. A label can help you remember the purpose of a parameter when there are multiple versions. </p> <p>Parameter labels have the following requirements and restrictions.</p> <ul> <li> <p>A version of a parameter can have a maximum of 10 labels.</p> </li> <li> <p>You can't attach the same label to different versions of the same parameter. For example, if version 1 has the label Production, then you can't attach Production to version 2.</p> </li> <li> <p>You can move a label from one version of a parameter to another.</p> </li> <li> <p>You can't create a label when you create a new parameter. You must attach a label to a specific version of a parameter.</p> </li> <li> <p>You can't delete a parameter label. If you no longer want to use a parameter label, then you must move it to a different version of a parameter.</p> </li> <li> <p>A label can have a maximum of 100 characters.</p> </li> <li> <p>Labels can contain letters (case sensitive), numbers, periods (.), hyphens (-), or underscores (_).</p> </li> <li> <p>Labels can't begin with a number, "aws," or "ssm" (not case sensitive). If a label fails to meet these requirements, then the label is not associated with a parameter and the system displays it in the list of InvalidLabels.</p> </li> </ul>
  ## 
  let valid = call_604222.validator(path, query, header, formData, body)
  let scheme = call_604222.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604222.url(scheme.get, call_604222.host, call_604222.base,
                         call_604222.route, valid.getOrDefault("path"))
  result = hook(call_604222, url, valid)

proc call*(call_604223: Call_LabelParameterVersion_604210; body: JsonNode): Recallable =
  ## labelParameterVersion
  ## <p>A parameter label is a user-defined alias to help you manage different versions of a parameter. When you modify a parameter, Systems Manager automatically saves a new version and increments the version number by one. A label can help you remember the purpose of a parameter when there are multiple versions. </p> <p>Parameter labels have the following requirements and restrictions.</p> <ul> <li> <p>A version of a parameter can have a maximum of 10 labels.</p> </li> <li> <p>You can't attach the same label to different versions of the same parameter. For example, if version 1 has the label Production, then you can't attach Production to version 2.</p> </li> <li> <p>You can move a label from one version of a parameter to another.</p> </li> <li> <p>You can't create a label when you create a new parameter. You must attach a label to a specific version of a parameter.</p> </li> <li> <p>You can't delete a parameter label. If you no longer want to use a parameter label, then you must move it to a different version of a parameter.</p> </li> <li> <p>A label can have a maximum of 100 characters.</p> </li> <li> <p>Labels can contain letters (case sensitive), numbers, periods (.), hyphens (-), or underscores (_).</p> </li> <li> <p>Labels can't begin with a number, "aws," or "ssm" (not case sensitive). If a label fails to meet these requirements, then the label is not associated with a parameter and the system displays it in the list of InvalidLabels.</p> </li> </ul>
  ##   body: JObject (required)
  var body_604224 = newJObject()
  if body != nil:
    body_604224 = body
  result = call_604223.call(nil, nil, nil, nil, body_604224)

var labelParameterVersion* = Call_LabelParameterVersion_604210(
    name: "labelParameterVersion", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.LabelParameterVersion",
    validator: validate_LabelParameterVersion_604211, base: "/",
    url: url_LabelParameterVersion_604212, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssociationVersions_604225 = ref object of OpenApiRestCall_602433
proc url_ListAssociationVersions_604227(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListAssociationVersions_604226(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604228 = header.getOrDefault("X-Amz-Date")
  valid_604228 = validateParameter(valid_604228, JString, required = false,
                                 default = nil)
  if valid_604228 != nil:
    section.add "X-Amz-Date", valid_604228
  var valid_604229 = header.getOrDefault("X-Amz-Security-Token")
  valid_604229 = validateParameter(valid_604229, JString, required = false,
                                 default = nil)
  if valid_604229 != nil:
    section.add "X-Amz-Security-Token", valid_604229
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604230 = header.getOrDefault("X-Amz-Target")
  valid_604230 = validateParameter(valid_604230, JString, required = true, default = newJString(
      "AmazonSSM.ListAssociationVersions"))
  if valid_604230 != nil:
    section.add "X-Amz-Target", valid_604230
  var valid_604231 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604231 = validateParameter(valid_604231, JString, required = false,
                                 default = nil)
  if valid_604231 != nil:
    section.add "X-Amz-Content-Sha256", valid_604231
  var valid_604232 = header.getOrDefault("X-Amz-Algorithm")
  valid_604232 = validateParameter(valid_604232, JString, required = false,
                                 default = nil)
  if valid_604232 != nil:
    section.add "X-Amz-Algorithm", valid_604232
  var valid_604233 = header.getOrDefault("X-Amz-Signature")
  valid_604233 = validateParameter(valid_604233, JString, required = false,
                                 default = nil)
  if valid_604233 != nil:
    section.add "X-Amz-Signature", valid_604233
  var valid_604234 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604234 = validateParameter(valid_604234, JString, required = false,
                                 default = nil)
  if valid_604234 != nil:
    section.add "X-Amz-SignedHeaders", valid_604234
  var valid_604235 = header.getOrDefault("X-Amz-Credential")
  valid_604235 = validateParameter(valid_604235, JString, required = false,
                                 default = nil)
  if valid_604235 != nil:
    section.add "X-Amz-Credential", valid_604235
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604237: Call_ListAssociationVersions_604225; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves all versions of an association for a specific association ID.
  ## 
  let valid = call_604237.validator(path, query, header, formData, body)
  let scheme = call_604237.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604237.url(scheme.get, call_604237.host, call_604237.base,
                         call_604237.route, valid.getOrDefault("path"))
  result = hook(call_604237, url, valid)

proc call*(call_604238: Call_ListAssociationVersions_604225; body: JsonNode): Recallable =
  ## listAssociationVersions
  ## Retrieves all versions of an association for a specific association ID.
  ##   body: JObject (required)
  var body_604239 = newJObject()
  if body != nil:
    body_604239 = body
  result = call_604238.call(nil, nil, nil, nil, body_604239)

var listAssociationVersions* = Call_ListAssociationVersions_604225(
    name: "listAssociationVersions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListAssociationVersions",
    validator: validate_ListAssociationVersions_604226, base: "/",
    url: url_ListAssociationVersions_604227, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssociations_604240 = ref object of OpenApiRestCall_602433
proc url_ListAssociations_604242(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListAssociations_604241(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Lists the associations for the specified Systems Manager document or instance.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_604243 = query.getOrDefault("NextToken")
  valid_604243 = validateParameter(valid_604243, JString, required = false,
                                 default = nil)
  if valid_604243 != nil:
    section.add "NextToken", valid_604243
  var valid_604244 = query.getOrDefault("MaxResults")
  valid_604244 = validateParameter(valid_604244, JString, required = false,
                                 default = nil)
  if valid_604244 != nil:
    section.add "MaxResults", valid_604244
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604245 = header.getOrDefault("X-Amz-Date")
  valid_604245 = validateParameter(valid_604245, JString, required = false,
                                 default = nil)
  if valid_604245 != nil:
    section.add "X-Amz-Date", valid_604245
  var valid_604246 = header.getOrDefault("X-Amz-Security-Token")
  valid_604246 = validateParameter(valid_604246, JString, required = false,
                                 default = nil)
  if valid_604246 != nil:
    section.add "X-Amz-Security-Token", valid_604246
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604247 = header.getOrDefault("X-Amz-Target")
  valid_604247 = validateParameter(valid_604247, JString, required = true, default = newJString(
      "AmazonSSM.ListAssociations"))
  if valid_604247 != nil:
    section.add "X-Amz-Target", valid_604247
  var valid_604248 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604248 = validateParameter(valid_604248, JString, required = false,
                                 default = nil)
  if valid_604248 != nil:
    section.add "X-Amz-Content-Sha256", valid_604248
  var valid_604249 = header.getOrDefault("X-Amz-Algorithm")
  valid_604249 = validateParameter(valid_604249, JString, required = false,
                                 default = nil)
  if valid_604249 != nil:
    section.add "X-Amz-Algorithm", valid_604249
  var valid_604250 = header.getOrDefault("X-Amz-Signature")
  valid_604250 = validateParameter(valid_604250, JString, required = false,
                                 default = nil)
  if valid_604250 != nil:
    section.add "X-Amz-Signature", valid_604250
  var valid_604251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604251 = validateParameter(valid_604251, JString, required = false,
                                 default = nil)
  if valid_604251 != nil:
    section.add "X-Amz-SignedHeaders", valid_604251
  var valid_604252 = header.getOrDefault("X-Amz-Credential")
  valid_604252 = validateParameter(valid_604252, JString, required = false,
                                 default = nil)
  if valid_604252 != nil:
    section.add "X-Amz-Credential", valid_604252
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604254: Call_ListAssociations_604240; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the associations for the specified Systems Manager document or instance.
  ## 
  let valid = call_604254.validator(path, query, header, formData, body)
  let scheme = call_604254.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604254.url(scheme.get, call_604254.host, call_604254.base,
                         call_604254.route, valid.getOrDefault("path"))
  result = hook(call_604254, url, valid)

proc call*(call_604255: Call_ListAssociations_604240; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listAssociations
  ## Lists the associations for the specified Systems Manager document or instance.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_604256 = newJObject()
  var body_604257 = newJObject()
  add(query_604256, "NextToken", newJString(NextToken))
  if body != nil:
    body_604257 = body
  add(query_604256, "MaxResults", newJString(MaxResults))
  result = call_604255.call(nil, query_604256, nil, nil, body_604257)

var listAssociations* = Call_ListAssociations_604240(name: "listAssociations",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListAssociations",
    validator: validate_ListAssociations_604241, base: "/",
    url: url_ListAssociations_604242, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCommandInvocations_604258 = ref object of OpenApiRestCall_602433
proc url_ListCommandInvocations_604260(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListCommandInvocations_604259(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## An invocation is copy of a command sent to a specific instance. A command can apply to one or more instances. A command invocation applies to one instance. For example, if a user runs SendCommand against three instances, then a command invocation is created for each requested instance ID. ListCommandInvocations provide status about command execution.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_604261 = query.getOrDefault("NextToken")
  valid_604261 = validateParameter(valid_604261, JString, required = false,
                                 default = nil)
  if valid_604261 != nil:
    section.add "NextToken", valid_604261
  var valid_604262 = query.getOrDefault("MaxResults")
  valid_604262 = validateParameter(valid_604262, JString, required = false,
                                 default = nil)
  if valid_604262 != nil:
    section.add "MaxResults", valid_604262
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604263 = header.getOrDefault("X-Amz-Date")
  valid_604263 = validateParameter(valid_604263, JString, required = false,
                                 default = nil)
  if valid_604263 != nil:
    section.add "X-Amz-Date", valid_604263
  var valid_604264 = header.getOrDefault("X-Amz-Security-Token")
  valid_604264 = validateParameter(valid_604264, JString, required = false,
                                 default = nil)
  if valid_604264 != nil:
    section.add "X-Amz-Security-Token", valid_604264
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604265 = header.getOrDefault("X-Amz-Target")
  valid_604265 = validateParameter(valid_604265, JString, required = true, default = newJString(
      "AmazonSSM.ListCommandInvocations"))
  if valid_604265 != nil:
    section.add "X-Amz-Target", valid_604265
  var valid_604266 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604266 = validateParameter(valid_604266, JString, required = false,
                                 default = nil)
  if valid_604266 != nil:
    section.add "X-Amz-Content-Sha256", valid_604266
  var valid_604267 = header.getOrDefault("X-Amz-Algorithm")
  valid_604267 = validateParameter(valid_604267, JString, required = false,
                                 default = nil)
  if valid_604267 != nil:
    section.add "X-Amz-Algorithm", valid_604267
  var valid_604268 = header.getOrDefault("X-Amz-Signature")
  valid_604268 = validateParameter(valid_604268, JString, required = false,
                                 default = nil)
  if valid_604268 != nil:
    section.add "X-Amz-Signature", valid_604268
  var valid_604269 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604269 = validateParameter(valid_604269, JString, required = false,
                                 default = nil)
  if valid_604269 != nil:
    section.add "X-Amz-SignedHeaders", valid_604269
  var valid_604270 = header.getOrDefault("X-Amz-Credential")
  valid_604270 = validateParameter(valid_604270, JString, required = false,
                                 default = nil)
  if valid_604270 != nil:
    section.add "X-Amz-Credential", valid_604270
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604272: Call_ListCommandInvocations_604258; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## An invocation is copy of a command sent to a specific instance. A command can apply to one or more instances. A command invocation applies to one instance. For example, if a user runs SendCommand against three instances, then a command invocation is created for each requested instance ID. ListCommandInvocations provide status about command execution.
  ## 
  let valid = call_604272.validator(path, query, header, formData, body)
  let scheme = call_604272.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604272.url(scheme.get, call_604272.host, call_604272.base,
                         call_604272.route, valid.getOrDefault("path"))
  result = hook(call_604272, url, valid)

proc call*(call_604273: Call_ListCommandInvocations_604258; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listCommandInvocations
  ## An invocation is copy of a command sent to a specific instance. A command can apply to one or more instances. A command invocation applies to one instance. For example, if a user runs SendCommand against three instances, then a command invocation is created for each requested instance ID. ListCommandInvocations provide status about command execution.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_604274 = newJObject()
  var body_604275 = newJObject()
  add(query_604274, "NextToken", newJString(NextToken))
  if body != nil:
    body_604275 = body
  add(query_604274, "MaxResults", newJString(MaxResults))
  result = call_604273.call(nil, query_604274, nil, nil, body_604275)

var listCommandInvocations* = Call_ListCommandInvocations_604258(
    name: "listCommandInvocations", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListCommandInvocations",
    validator: validate_ListCommandInvocations_604259, base: "/",
    url: url_ListCommandInvocations_604260, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCommands_604276 = ref object of OpenApiRestCall_602433
proc url_ListCommands_604278(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListCommands_604277(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the commands requested by users of the AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_604279 = query.getOrDefault("NextToken")
  valid_604279 = validateParameter(valid_604279, JString, required = false,
                                 default = nil)
  if valid_604279 != nil:
    section.add "NextToken", valid_604279
  var valid_604280 = query.getOrDefault("MaxResults")
  valid_604280 = validateParameter(valid_604280, JString, required = false,
                                 default = nil)
  if valid_604280 != nil:
    section.add "MaxResults", valid_604280
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604281 = header.getOrDefault("X-Amz-Date")
  valid_604281 = validateParameter(valid_604281, JString, required = false,
                                 default = nil)
  if valid_604281 != nil:
    section.add "X-Amz-Date", valid_604281
  var valid_604282 = header.getOrDefault("X-Amz-Security-Token")
  valid_604282 = validateParameter(valid_604282, JString, required = false,
                                 default = nil)
  if valid_604282 != nil:
    section.add "X-Amz-Security-Token", valid_604282
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604283 = header.getOrDefault("X-Amz-Target")
  valid_604283 = validateParameter(valid_604283, JString, required = true,
                                 default = newJString("AmazonSSM.ListCommands"))
  if valid_604283 != nil:
    section.add "X-Amz-Target", valid_604283
  var valid_604284 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604284 = validateParameter(valid_604284, JString, required = false,
                                 default = nil)
  if valid_604284 != nil:
    section.add "X-Amz-Content-Sha256", valid_604284
  var valid_604285 = header.getOrDefault("X-Amz-Algorithm")
  valid_604285 = validateParameter(valid_604285, JString, required = false,
                                 default = nil)
  if valid_604285 != nil:
    section.add "X-Amz-Algorithm", valid_604285
  var valid_604286 = header.getOrDefault("X-Amz-Signature")
  valid_604286 = validateParameter(valid_604286, JString, required = false,
                                 default = nil)
  if valid_604286 != nil:
    section.add "X-Amz-Signature", valid_604286
  var valid_604287 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604287 = validateParameter(valid_604287, JString, required = false,
                                 default = nil)
  if valid_604287 != nil:
    section.add "X-Amz-SignedHeaders", valid_604287
  var valid_604288 = header.getOrDefault("X-Amz-Credential")
  valid_604288 = validateParameter(valid_604288, JString, required = false,
                                 default = nil)
  if valid_604288 != nil:
    section.add "X-Amz-Credential", valid_604288
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604290: Call_ListCommands_604276; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the commands requested by users of the AWS account.
  ## 
  let valid = call_604290.validator(path, query, header, formData, body)
  let scheme = call_604290.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604290.url(scheme.get, call_604290.host, call_604290.base,
                         call_604290.route, valid.getOrDefault("path"))
  result = hook(call_604290, url, valid)

proc call*(call_604291: Call_ListCommands_604276; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listCommands
  ## Lists the commands requested by users of the AWS account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_604292 = newJObject()
  var body_604293 = newJObject()
  add(query_604292, "NextToken", newJString(NextToken))
  if body != nil:
    body_604293 = body
  add(query_604292, "MaxResults", newJString(MaxResults))
  result = call_604291.call(nil, query_604292, nil, nil, body_604293)

var listCommands* = Call_ListCommands_604276(name: "listCommands",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListCommands",
    validator: validate_ListCommands_604277, base: "/", url: url_ListCommands_604278,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListComplianceItems_604294 = ref object of OpenApiRestCall_602433
proc url_ListComplianceItems_604296(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListComplianceItems_604295(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604297 = header.getOrDefault("X-Amz-Date")
  valid_604297 = validateParameter(valid_604297, JString, required = false,
                                 default = nil)
  if valid_604297 != nil:
    section.add "X-Amz-Date", valid_604297
  var valid_604298 = header.getOrDefault("X-Amz-Security-Token")
  valid_604298 = validateParameter(valid_604298, JString, required = false,
                                 default = nil)
  if valid_604298 != nil:
    section.add "X-Amz-Security-Token", valid_604298
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604299 = header.getOrDefault("X-Amz-Target")
  valid_604299 = validateParameter(valid_604299, JString, required = true, default = newJString(
      "AmazonSSM.ListComplianceItems"))
  if valid_604299 != nil:
    section.add "X-Amz-Target", valid_604299
  var valid_604300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604300 = validateParameter(valid_604300, JString, required = false,
                                 default = nil)
  if valid_604300 != nil:
    section.add "X-Amz-Content-Sha256", valid_604300
  var valid_604301 = header.getOrDefault("X-Amz-Algorithm")
  valid_604301 = validateParameter(valid_604301, JString, required = false,
                                 default = nil)
  if valid_604301 != nil:
    section.add "X-Amz-Algorithm", valid_604301
  var valid_604302 = header.getOrDefault("X-Amz-Signature")
  valid_604302 = validateParameter(valid_604302, JString, required = false,
                                 default = nil)
  if valid_604302 != nil:
    section.add "X-Amz-Signature", valid_604302
  var valid_604303 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604303 = validateParameter(valid_604303, JString, required = false,
                                 default = nil)
  if valid_604303 != nil:
    section.add "X-Amz-SignedHeaders", valid_604303
  var valid_604304 = header.getOrDefault("X-Amz-Credential")
  valid_604304 = validateParameter(valid_604304, JString, required = false,
                                 default = nil)
  if valid_604304 != nil:
    section.add "X-Amz-Credential", valid_604304
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604306: Call_ListComplianceItems_604294; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## For a specified resource ID, this API action returns a list of compliance statuses for different resource types. Currently, you can only specify one resource ID per call. List results depend on the criteria specified in the filter. 
  ## 
  let valid = call_604306.validator(path, query, header, formData, body)
  let scheme = call_604306.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604306.url(scheme.get, call_604306.host, call_604306.base,
                         call_604306.route, valid.getOrDefault("path"))
  result = hook(call_604306, url, valid)

proc call*(call_604307: Call_ListComplianceItems_604294; body: JsonNode): Recallable =
  ## listComplianceItems
  ## For a specified resource ID, this API action returns a list of compliance statuses for different resource types. Currently, you can only specify one resource ID per call. List results depend on the criteria specified in the filter. 
  ##   body: JObject (required)
  var body_604308 = newJObject()
  if body != nil:
    body_604308 = body
  result = call_604307.call(nil, nil, nil, nil, body_604308)

var listComplianceItems* = Call_ListComplianceItems_604294(
    name: "listComplianceItems", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListComplianceItems",
    validator: validate_ListComplianceItems_604295, base: "/",
    url: url_ListComplianceItems_604296, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListComplianceSummaries_604309 = ref object of OpenApiRestCall_602433
proc url_ListComplianceSummaries_604311(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListComplianceSummaries_604310(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604312 = header.getOrDefault("X-Amz-Date")
  valid_604312 = validateParameter(valid_604312, JString, required = false,
                                 default = nil)
  if valid_604312 != nil:
    section.add "X-Amz-Date", valid_604312
  var valid_604313 = header.getOrDefault("X-Amz-Security-Token")
  valid_604313 = validateParameter(valid_604313, JString, required = false,
                                 default = nil)
  if valid_604313 != nil:
    section.add "X-Amz-Security-Token", valid_604313
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604314 = header.getOrDefault("X-Amz-Target")
  valid_604314 = validateParameter(valid_604314, JString, required = true, default = newJString(
      "AmazonSSM.ListComplianceSummaries"))
  if valid_604314 != nil:
    section.add "X-Amz-Target", valid_604314
  var valid_604315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604315 = validateParameter(valid_604315, JString, required = false,
                                 default = nil)
  if valid_604315 != nil:
    section.add "X-Amz-Content-Sha256", valid_604315
  var valid_604316 = header.getOrDefault("X-Amz-Algorithm")
  valid_604316 = validateParameter(valid_604316, JString, required = false,
                                 default = nil)
  if valid_604316 != nil:
    section.add "X-Amz-Algorithm", valid_604316
  var valid_604317 = header.getOrDefault("X-Amz-Signature")
  valid_604317 = validateParameter(valid_604317, JString, required = false,
                                 default = nil)
  if valid_604317 != nil:
    section.add "X-Amz-Signature", valid_604317
  var valid_604318 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604318 = validateParameter(valid_604318, JString, required = false,
                                 default = nil)
  if valid_604318 != nil:
    section.add "X-Amz-SignedHeaders", valid_604318
  var valid_604319 = header.getOrDefault("X-Amz-Credential")
  valid_604319 = validateParameter(valid_604319, JString, required = false,
                                 default = nil)
  if valid_604319 != nil:
    section.add "X-Amz-Credential", valid_604319
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604321: Call_ListComplianceSummaries_604309; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a summary count of compliant and non-compliant resources for a compliance type. For example, this call can return State Manager associations, patches, or custom compliance types according to the filter criteria that you specify. 
  ## 
  let valid = call_604321.validator(path, query, header, formData, body)
  let scheme = call_604321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604321.url(scheme.get, call_604321.host, call_604321.base,
                         call_604321.route, valid.getOrDefault("path"))
  result = hook(call_604321, url, valid)

proc call*(call_604322: Call_ListComplianceSummaries_604309; body: JsonNode): Recallable =
  ## listComplianceSummaries
  ## Returns a summary count of compliant and non-compliant resources for a compliance type. For example, this call can return State Manager associations, patches, or custom compliance types according to the filter criteria that you specify. 
  ##   body: JObject (required)
  var body_604323 = newJObject()
  if body != nil:
    body_604323 = body
  result = call_604322.call(nil, nil, nil, nil, body_604323)

var listComplianceSummaries* = Call_ListComplianceSummaries_604309(
    name: "listComplianceSummaries", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListComplianceSummaries",
    validator: validate_ListComplianceSummaries_604310, base: "/",
    url: url_ListComplianceSummaries_604311, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDocumentVersions_604324 = ref object of OpenApiRestCall_602433
proc url_ListDocumentVersions_604326(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListDocumentVersions_604325(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604327 = header.getOrDefault("X-Amz-Date")
  valid_604327 = validateParameter(valid_604327, JString, required = false,
                                 default = nil)
  if valid_604327 != nil:
    section.add "X-Amz-Date", valid_604327
  var valid_604328 = header.getOrDefault("X-Amz-Security-Token")
  valid_604328 = validateParameter(valid_604328, JString, required = false,
                                 default = nil)
  if valid_604328 != nil:
    section.add "X-Amz-Security-Token", valid_604328
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604329 = header.getOrDefault("X-Amz-Target")
  valid_604329 = validateParameter(valid_604329, JString, required = true, default = newJString(
      "AmazonSSM.ListDocumentVersions"))
  if valid_604329 != nil:
    section.add "X-Amz-Target", valid_604329
  var valid_604330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604330 = validateParameter(valid_604330, JString, required = false,
                                 default = nil)
  if valid_604330 != nil:
    section.add "X-Amz-Content-Sha256", valid_604330
  var valid_604331 = header.getOrDefault("X-Amz-Algorithm")
  valid_604331 = validateParameter(valid_604331, JString, required = false,
                                 default = nil)
  if valid_604331 != nil:
    section.add "X-Amz-Algorithm", valid_604331
  var valid_604332 = header.getOrDefault("X-Amz-Signature")
  valid_604332 = validateParameter(valid_604332, JString, required = false,
                                 default = nil)
  if valid_604332 != nil:
    section.add "X-Amz-Signature", valid_604332
  var valid_604333 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604333 = validateParameter(valid_604333, JString, required = false,
                                 default = nil)
  if valid_604333 != nil:
    section.add "X-Amz-SignedHeaders", valid_604333
  var valid_604334 = header.getOrDefault("X-Amz-Credential")
  valid_604334 = validateParameter(valid_604334, JString, required = false,
                                 default = nil)
  if valid_604334 != nil:
    section.add "X-Amz-Credential", valid_604334
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604336: Call_ListDocumentVersions_604324; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all versions for a document.
  ## 
  let valid = call_604336.validator(path, query, header, formData, body)
  let scheme = call_604336.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604336.url(scheme.get, call_604336.host, call_604336.base,
                         call_604336.route, valid.getOrDefault("path"))
  result = hook(call_604336, url, valid)

proc call*(call_604337: Call_ListDocumentVersions_604324; body: JsonNode): Recallable =
  ## listDocumentVersions
  ## List all versions for a document.
  ##   body: JObject (required)
  var body_604338 = newJObject()
  if body != nil:
    body_604338 = body
  result = call_604337.call(nil, nil, nil, nil, body_604338)

var listDocumentVersions* = Call_ListDocumentVersions_604324(
    name: "listDocumentVersions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListDocumentVersions",
    validator: validate_ListDocumentVersions_604325, base: "/",
    url: url_ListDocumentVersions_604326, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDocuments_604339 = ref object of OpenApiRestCall_602433
proc url_ListDocuments_604341(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListDocuments_604340(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes one or more of your Systems Manager documents.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_604342 = query.getOrDefault("NextToken")
  valid_604342 = validateParameter(valid_604342, JString, required = false,
                                 default = nil)
  if valid_604342 != nil:
    section.add "NextToken", valid_604342
  var valid_604343 = query.getOrDefault("MaxResults")
  valid_604343 = validateParameter(valid_604343, JString, required = false,
                                 default = nil)
  if valid_604343 != nil:
    section.add "MaxResults", valid_604343
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604344 = header.getOrDefault("X-Amz-Date")
  valid_604344 = validateParameter(valid_604344, JString, required = false,
                                 default = nil)
  if valid_604344 != nil:
    section.add "X-Amz-Date", valid_604344
  var valid_604345 = header.getOrDefault("X-Amz-Security-Token")
  valid_604345 = validateParameter(valid_604345, JString, required = false,
                                 default = nil)
  if valid_604345 != nil:
    section.add "X-Amz-Security-Token", valid_604345
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604346 = header.getOrDefault("X-Amz-Target")
  valid_604346 = validateParameter(valid_604346, JString, required = true, default = newJString(
      "AmazonSSM.ListDocuments"))
  if valid_604346 != nil:
    section.add "X-Amz-Target", valid_604346
  var valid_604347 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604347 = validateParameter(valid_604347, JString, required = false,
                                 default = nil)
  if valid_604347 != nil:
    section.add "X-Amz-Content-Sha256", valid_604347
  var valid_604348 = header.getOrDefault("X-Amz-Algorithm")
  valid_604348 = validateParameter(valid_604348, JString, required = false,
                                 default = nil)
  if valid_604348 != nil:
    section.add "X-Amz-Algorithm", valid_604348
  var valid_604349 = header.getOrDefault("X-Amz-Signature")
  valid_604349 = validateParameter(valid_604349, JString, required = false,
                                 default = nil)
  if valid_604349 != nil:
    section.add "X-Amz-Signature", valid_604349
  var valid_604350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604350 = validateParameter(valid_604350, JString, required = false,
                                 default = nil)
  if valid_604350 != nil:
    section.add "X-Amz-SignedHeaders", valid_604350
  var valid_604351 = header.getOrDefault("X-Amz-Credential")
  valid_604351 = validateParameter(valid_604351, JString, required = false,
                                 default = nil)
  if valid_604351 != nil:
    section.add "X-Amz-Credential", valid_604351
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604353: Call_ListDocuments_604339; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes one or more of your Systems Manager documents.
  ## 
  let valid = call_604353.validator(path, query, header, formData, body)
  let scheme = call_604353.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604353.url(scheme.get, call_604353.host, call_604353.base,
                         call_604353.route, valid.getOrDefault("path"))
  result = hook(call_604353, url, valid)

proc call*(call_604354: Call_ListDocuments_604339; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listDocuments
  ## Describes one or more of your Systems Manager documents.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_604355 = newJObject()
  var body_604356 = newJObject()
  add(query_604355, "NextToken", newJString(NextToken))
  if body != nil:
    body_604356 = body
  add(query_604355, "MaxResults", newJString(MaxResults))
  result = call_604354.call(nil, query_604355, nil, nil, body_604356)

var listDocuments* = Call_ListDocuments_604339(name: "listDocuments",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListDocuments",
    validator: validate_ListDocuments_604340, base: "/", url: url_ListDocuments_604341,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInventoryEntries_604357 = ref object of OpenApiRestCall_602433
proc url_ListInventoryEntries_604359(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListInventoryEntries_604358(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604360 = header.getOrDefault("X-Amz-Date")
  valid_604360 = validateParameter(valid_604360, JString, required = false,
                                 default = nil)
  if valid_604360 != nil:
    section.add "X-Amz-Date", valid_604360
  var valid_604361 = header.getOrDefault("X-Amz-Security-Token")
  valid_604361 = validateParameter(valid_604361, JString, required = false,
                                 default = nil)
  if valid_604361 != nil:
    section.add "X-Amz-Security-Token", valid_604361
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604362 = header.getOrDefault("X-Amz-Target")
  valid_604362 = validateParameter(valid_604362, JString, required = true, default = newJString(
      "AmazonSSM.ListInventoryEntries"))
  if valid_604362 != nil:
    section.add "X-Amz-Target", valid_604362
  var valid_604363 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604363 = validateParameter(valid_604363, JString, required = false,
                                 default = nil)
  if valid_604363 != nil:
    section.add "X-Amz-Content-Sha256", valid_604363
  var valid_604364 = header.getOrDefault("X-Amz-Algorithm")
  valid_604364 = validateParameter(valid_604364, JString, required = false,
                                 default = nil)
  if valid_604364 != nil:
    section.add "X-Amz-Algorithm", valid_604364
  var valid_604365 = header.getOrDefault("X-Amz-Signature")
  valid_604365 = validateParameter(valid_604365, JString, required = false,
                                 default = nil)
  if valid_604365 != nil:
    section.add "X-Amz-Signature", valid_604365
  var valid_604366 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604366 = validateParameter(valid_604366, JString, required = false,
                                 default = nil)
  if valid_604366 != nil:
    section.add "X-Amz-SignedHeaders", valid_604366
  var valid_604367 = header.getOrDefault("X-Amz-Credential")
  valid_604367 = validateParameter(valid_604367, JString, required = false,
                                 default = nil)
  if valid_604367 != nil:
    section.add "X-Amz-Credential", valid_604367
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604369: Call_ListInventoryEntries_604357; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## A list of inventory items returned by the request.
  ## 
  let valid = call_604369.validator(path, query, header, formData, body)
  let scheme = call_604369.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604369.url(scheme.get, call_604369.host, call_604369.base,
                         call_604369.route, valid.getOrDefault("path"))
  result = hook(call_604369, url, valid)

proc call*(call_604370: Call_ListInventoryEntries_604357; body: JsonNode): Recallable =
  ## listInventoryEntries
  ## A list of inventory items returned by the request.
  ##   body: JObject (required)
  var body_604371 = newJObject()
  if body != nil:
    body_604371 = body
  result = call_604370.call(nil, nil, nil, nil, body_604371)

var listInventoryEntries* = Call_ListInventoryEntries_604357(
    name: "listInventoryEntries", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListInventoryEntries",
    validator: validate_ListInventoryEntries_604358, base: "/",
    url: url_ListInventoryEntries_604359, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceComplianceSummaries_604372 = ref object of OpenApiRestCall_602433
proc url_ListResourceComplianceSummaries_604374(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListResourceComplianceSummaries_604373(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604375 = header.getOrDefault("X-Amz-Date")
  valid_604375 = validateParameter(valid_604375, JString, required = false,
                                 default = nil)
  if valid_604375 != nil:
    section.add "X-Amz-Date", valid_604375
  var valid_604376 = header.getOrDefault("X-Amz-Security-Token")
  valid_604376 = validateParameter(valid_604376, JString, required = false,
                                 default = nil)
  if valid_604376 != nil:
    section.add "X-Amz-Security-Token", valid_604376
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604377 = header.getOrDefault("X-Amz-Target")
  valid_604377 = validateParameter(valid_604377, JString, required = true, default = newJString(
      "AmazonSSM.ListResourceComplianceSummaries"))
  if valid_604377 != nil:
    section.add "X-Amz-Target", valid_604377
  var valid_604378 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604378 = validateParameter(valid_604378, JString, required = false,
                                 default = nil)
  if valid_604378 != nil:
    section.add "X-Amz-Content-Sha256", valid_604378
  var valid_604379 = header.getOrDefault("X-Amz-Algorithm")
  valid_604379 = validateParameter(valid_604379, JString, required = false,
                                 default = nil)
  if valid_604379 != nil:
    section.add "X-Amz-Algorithm", valid_604379
  var valid_604380 = header.getOrDefault("X-Amz-Signature")
  valid_604380 = validateParameter(valid_604380, JString, required = false,
                                 default = nil)
  if valid_604380 != nil:
    section.add "X-Amz-Signature", valid_604380
  var valid_604381 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604381 = validateParameter(valid_604381, JString, required = false,
                                 default = nil)
  if valid_604381 != nil:
    section.add "X-Amz-SignedHeaders", valid_604381
  var valid_604382 = header.getOrDefault("X-Amz-Credential")
  valid_604382 = validateParameter(valid_604382, JString, required = false,
                                 default = nil)
  if valid_604382 != nil:
    section.add "X-Amz-Credential", valid_604382
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604384: Call_ListResourceComplianceSummaries_604372;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a resource-level summary count. The summary includes information about compliant and non-compliant statuses and detailed compliance-item severity counts, according to the filter criteria you specify.
  ## 
  let valid = call_604384.validator(path, query, header, formData, body)
  let scheme = call_604384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604384.url(scheme.get, call_604384.host, call_604384.base,
                         call_604384.route, valid.getOrDefault("path"))
  result = hook(call_604384, url, valid)

proc call*(call_604385: Call_ListResourceComplianceSummaries_604372; body: JsonNode): Recallable =
  ## listResourceComplianceSummaries
  ## Returns a resource-level summary count. The summary includes information about compliant and non-compliant statuses and detailed compliance-item severity counts, according to the filter criteria you specify.
  ##   body: JObject (required)
  var body_604386 = newJObject()
  if body != nil:
    body_604386 = body
  result = call_604385.call(nil, nil, nil, nil, body_604386)

var listResourceComplianceSummaries* = Call_ListResourceComplianceSummaries_604372(
    name: "listResourceComplianceSummaries", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListResourceComplianceSummaries",
    validator: validate_ListResourceComplianceSummaries_604373, base: "/",
    url: url_ListResourceComplianceSummaries_604374,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceDataSync_604387 = ref object of OpenApiRestCall_602433
proc url_ListResourceDataSync_604389(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListResourceDataSync_604388(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604390 = header.getOrDefault("X-Amz-Date")
  valid_604390 = validateParameter(valid_604390, JString, required = false,
                                 default = nil)
  if valid_604390 != nil:
    section.add "X-Amz-Date", valid_604390
  var valid_604391 = header.getOrDefault("X-Amz-Security-Token")
  valid_604391 = validateParameter(valid_604391, JString, required = false,
                                 default = nil)
  if valid_604391 != nil:
    section.add "X-Amz-Security-Token", valid_604391
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604392 = header.getOrDefault("X-Amz-Target")
  valid_604392 = validateParameter(valid_604392, JString, required = true, default = newJString(
      "AmazonSSM.ListResourceDataSync"))
  if valid_604392 != nil:
    section.add "X-Amz-Target", valid_604392
  var valid_604393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604393 = validateParameter(valid_604393, JString, required = false,
                                 default = nil)
  if valid_604393 != nil:
    section.add "X-Amz-Content-Sha256", valid_604393
  var valid_604394 = header.getOrDefault("X-Amz-Algorithm")
  valid_604394 = validateParameter(valid_604394, JString, required = false,
                                 default = nil)
  if valid_604394 != nil:
    section.add "X-Amz-Algorithm", valid_604394
  var valid_604395 = header.getOrDefault("X-Amz-Signature")
  valid_604395 = validateParameter(valid_604395, JString, required = false,
                                 default = nil)
  if valid_604395 != nil:
    section.add "X-Amz-Signature", valid_604395
  var valid_604396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604396 = validateParameter(valid_604396, JString, required = false,
                                 default = nil)
  if valid_604396 != nil:
    section.add "X-Amz-SignedHeaders", valid_604396
  var valid_604397 = header.getOrDefault("X-Amz-Credential")
  valid_604397 = validateParameter(valid_604397, JString, required = false,
                                 default = nil)
  if valid_604397 != nil:
    section.add "X-Amz-Credential", valid_604397
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604399: Call_ListResourceDataSync_604387; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists your resource data sync configurations. Includes information about the last time a sync attempted to start, the last sync status, and the last time a sync successfully completed.</p> <p>The number of sync configurations might be too large to return using a single call to <code>ListResourceDataSync</code>. You can limit the number of sync configurations returned by using the <code>MaxResults</code> parameter. To determine whether there are more sync configurations to list, check the value of <code>NextToken</code> in the output. If there are more sync configurations to list, you can request them by specifying the <code>NextToken</code> returned in the call to the parameter of a subsequent call. </p>
  ## 
  let valid = call_604399.validator(path, query, header, formData, body)
  let scheme = call_604399.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604399.url(scheme.get, call_604399.host, call_604399.base,
                         call_604399.route, valid.getOrDefault("path"))
  result = hook(call_604399, url, valid)

proc call*(call_604400: Call_ListResourceDataSync_604387; body: JsonNode): Recallable =
  ## listResourceDataSync
  ## <p>Lists your resource data sync configurations. Includes information about the last time a sync attempted to start, the last sync status, and the last time a sync successfully completed.</p> <p>The number of sync configurations might be too large to return using a single call to <code>ListResourceDataSync</code>. You can limit the number of sync configurations returned by using the <code>MaxResults</code> parameter. To determine whether there are more sync configurations to list, check the value of <code>NextToken</code> in the output. If there are more sync configurations to list, you can request them by specifying the <code>NextToken</code> returned in the call to the parameter of a subsequent call. </p>
  ##   body: JObject (required)
  var body_604401 = newJObject()
  if body != nil:
    body_604401 = body
  result = call_604400.call(nil, nil, nil, nil, body_604401)

var listResourceDataSync* = Call_ListResourceDataSync_604387(
    name: "listResourceDataSync", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListResourceDataSync",
    validator: validate_ListResourceDataSync_604388, base: "/",
    url: url_ListResourceDataSync_604389, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_604402 = ref object of OpenApiRestCall_602433
proc url_ListTagsForResource_604404(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTagsForResource_604403(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604405 = header.getOrDefault("X-Amz-Date")
  valid_604405 = validateParameter(valid_604405, JString, required = false,
                                 default = nil)
  if valid_604405 != nil:
    section.add "X-Amz-Date", valid_604405
  var valid_604406 = header.getOrDefault("X-Amz-Security-Token")
  valid_604406 = validateParameter(valid_604406, JString, required = false,
                                 default = nil)
  if valid_604406 != nil:
    section.add "X-Amz-Security-Token", valid_604406
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604407 = header.getOrDefault("X-Amz-Target")
  valid_604407 = validateParameter(valid_604407, JString, required = true, default = newJString(
      "AmazonSSM.ListTagsForResource"))
  if valid_604407 != nil:
    section.add "X-Amz-Target", valid_604407
  var valid_604408 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604408 = validateParameter(valid_604408, JString, required = false,
                                 default = nil)
  if valid_604408 != nil:
    section.add "X-Amz-Content-Sha256", valid_604408
  var valid_604409 = header.getOrDefault("X-Amz-Algorithm")
  valid_604409 = validateParameter(valid_604409, JString, required = false,
                                 default = nil)
  if valid_604409 != nil:
    section.add "X-Amz-Algorithm", valid_604409
  var valid_604410 = header.getOrDefault("X-Amz-Signature")
  valid_604410 = validateParameter(valid_604410, JString, required = false,
                                 default = nil)
  if valid_604410 != nil:
    section.add "X-Amz-Signature", valid_604410
  var valid_604411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604411 = validateParameter(valid_604411, JString, required = false,
                                 default = nil)
  if valid_604411 != nil:
    section.add "X-Amz-SignedHeaders", valid_604411
  var valid_604412 = header.getOrDefault("X-Amz-Credential")
  valid_604412 = validateParameter(valid_604412, JString, required = false,
                                 default = nil)
  if valid_604412 != nil:
    section.add "X-Amz-Credential", valid_604412
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604414: Call_ListTagsForResource_604402; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the tags assigned to the specified resource.
  ## 
  let valid = call_604414.validator(path, query, header, formData, body)
  let scheme = call_604414.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604414.url(scheme.get, call_604414.host, call_604414.base,
                         call_604414.route, valid.getOrDefault("path"))
  result = hook(call_604414, url, valid)

proc call*(call_604415: Call_ListTagsForResource_604402; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Returns a list of the tags assigned to the specified resource.
  ##   body: JObject (required)
  var body_604416 = newJObject()
  if body != nil:
    body_604416 = body
  result = call_604415.call(nil, nil, nil, nil, body_604416)

var listTagsForResource* = Call_ListTagsForResource_604402(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListTagsForResource",
    validator: validate_ListTagsForResource_604403, base: "/",
    url: url_ListTagsForResource_604404, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyDocumentPermission_604417 = ref object of OpenApiRestCall_602433
proc url_ModifyDocumentPermission_604419(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ModifyDocumentPermission_604418(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604420 = header.getOrDefault("X-Amz-Date")
  valid_604420 = validateParameter(valid_604420, JString, required = false,
                                 default = nil)
  if valid_604420 != nil:
    section.add "X-Amz-Date", valid_604420
  var valid_604421 = header.getOrDefault("X-Amz-Security-Token")
  valid_604421 = validateParameter(valid_604421, JString, required = false,
                                 default = nil)
  if valid_604421 != nil:
    section.add "X-Amz-Security-Token", valid_604421
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604422 = header.getOrDefault("X-Amz-Target")
  valid_604422 = validateParameter(valid_604422, JString, required = true, default = newJString(
      "AmazonSSM.ModifyDocumentPermission"))
  if valid_604422 != nil:
    section.add "X-Amz-Target", valid_604422
  var valid_604423 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604423 = validateParameter(valid_604423, JString, required = false,
                                 default = nil)
  if valid_604423 != nil:
    section.add "X-Amz-Content-Sha256", valid_604423
  var valid_604424 = header.getOrDefault("X-Amz-Algorithm")
  valid_604424 = validateParameter(valid_604424, JString, required = false,
                                 default = nil)
  if valid_604424 != nil:
    section.add "X-Amz-Algorithm", valid_604424
  var valid_604425 = header.getOrDefault("X-Amz-Signature")
  valid_604425 = validateParameter(valid_604425, JString, required = false,
                                 default = nil)
  if valid_604425 != nil:
    section.add "X-Amz-Signature", valid_604425
  var valid_604426 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604426 = validateParameter(valid_604426, JString, required = false,
                                 default = nil)
  if valid_604426 != nil:
    section.add "X-Amz-SignedHeaders", valid_604426
  var valid_604427 = header.getOrDefault("X-Amz-Credential")
  valid_604427 = validateParameter(valid_604427, JString, required = false,
                                 default = nil)
  if valid_604427 != nil:
    section.add "X-Amz-Credential", valid_604427
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604429: Call_ModifyDocumentPermission_604417; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Shares a Systems Manager document publicly or privately. If you share a document privately, you must specify the AWS user account IDs for those people who can use the document. If you share a document publicly, you must specify <i>All</i> as the account ID.
  ## 
  let valid = call_604429.validator(path, query, header, formData, body)
  let scheme = call_604429.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604429.url(scheme.get, call_604429.host, call_604429.base,
                         call_604429.route, valid.getOrDefault("path"))
  result = hook(call_604429, url, valid)

proc call*(call_604430: Call_ModifyDocumentPermission_604417; body: JsonNode): Recallable =
  ## modifyDocumentPermission
  ## Shares a Systems Manager document publicly or privately. If you share a document privately, you must specify the AWS user account IDs for those people who can use the document. If you share a document publicly, you must specify <i>All</i> as the account ID.
  ##   body: JObject (required)
  var body_604431 = newJObject()
  if body != nil:
    body_604431 = body
  result = call_604430.call(nil, nil, nil, nil, body_604431)

var modifyDocumentPermission* = Call_ModifyDocumentPermission_604417(
    name: "modifyDocumentPermission", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ModifyDocumentPermission",
    validator: validate_ModifyDocumentPermission_604418, base: "/",
    url: url_ModifyDocumentPermission_604419, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutComplianceItems_604432 = ref object of OpenApiRestCall_602433
proc url_PutComplianceItems_604434(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutComplianceItems_604433(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604435 = header.getOrDefault("X-Amz-Date")
  valid_604435 = validateParameter(valid_604435, JString, required = false,
                                 default = nil)
  if valid_604435 != nil:
    section.add "X-Amz-Date", valid_604435
  var valid_604436 = header.getOrDefault("X-Amz-Security-Token")
  valid_604436 = validateParameter(valid_604436, JString, required = false,
                                 default = nil)
  if valid_604436 != nil:
    section.add "X-Amz-Security-Token", valid_604436
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604437 = header.getOrDefault("X-Amz-Target")
  valid_604437 = validateParameter(valid_604437, JString, required = true, default = newJString(
      "AmazonSSM.PutComplianceItems"))
  if valid_604437 != nil:
    section.add "X-Amz-Target", valid_604437
  var valid_604438 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604438 = validateParameter(valid_604438, JString, required = false,
                                 default = nil)
  if valid_604438 != nil:
    section.add "X-Amz-Content-Sha256", valid_604438
  var valid_604439 = header.getOrDefault("X-Amz-Algorithm")
  valid_604439 = validateParameter(valid_604439, JString, required = false,
                                 default = nil)
  if valid_604439 != nil:
    section.add "X-Amz-Algorithm", valid_604439
  var valid_604440 = header.getOrDefault("X-Amz-Signature")
  valid_604440 = validateParameter(valid_604440, JString, required = false,
                                 default = nil)
  if valid_604440 != nil:
    section.add "X-Amz-Signature", valid_604440
  var valid_604441 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604441 = validateParameter(valid_604441, JString, required = false,
                                 default = nil)
  if valid_604441 != nil:
    section.add "X-Amz-SignedHeaders", valid_604441
  var valid_604442 = header.getOrDefault("X-Amz-Credential")
  valid_604442 = validateParameter(valid_604442, JString, required = false,
                                 default = nil)
  if valid_604442 != nil:
    section.add "X-Amz-Credential", valid_604442
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604444: Call_PutComplianceItems_604432; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Registers a compliance type and other compliance details on a designated resource. This action lets you register custom compliance details with a resource. This call overwrites existing compliance information on the resource, so you must provide a full list of compliance items each time that you send the request.</p> <p>ComplianceType can be one of the following:</p> <ul> <li> <p>ExecutionId: The execution ID when the patch, association, or custom compliance item was applied.</p> </li> <li> <p>ExecutionType: Specify patch, association, or Custom:<code>string</code>.</p> </li> <li> <p>ExecutionTime. The time the patch, association, or custom compliance item was applied to the instance.</p> </li> <li> <p>Id: The patch, association, or custom compliance ID.</p> </li> <li> <p>Title: A title.</p> </li> <li> <p>Status: The status of the compliance item. For example, <code>approved</code> for patches, or <code>Failed</code> for associations.</p> </li> <li> <p>Severity: A patch severity. For example, <code>critical</code>.</p> </li> <li> <p>DocumentName: A SSM document name. For example, AWS-RunPatchBaseline.</p> </li> <li> <p>DocumentVersion: An SSM document version number. For example, 4.</p> </li> <li> <p>Classification: A patch classification. For example, <code>security updates</code>.</p> </li> <li> <p>PatchBaselineId: A patch baseline ID.</p> </li> <li> <p>PatchSeverity: A patch severity. For example, <code>Critical</code>.</p> </li> <li> <p>PatchState: A patch state. For example, <code>InstancesWithFailedPatches</code>.</p> </li> <li> <p>PatchGroup: The name of a patch group.</p> </li> <li> <p>InstalledTime: The time the association, patch, or custom compliance item was applied to the resource. Specify the time by using the following format: yyyy-MM-dd'T'HH:mm:ss'Z'</p> </li> </ul>
  ## 
  let valid = call_604444.validator(path, query, header, formData, body)
  let scheme = call_604444.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604444.url(scheme.get, call_604444.host, call_604444.base,
                         call_604444.route, valid.getOrDefault("path"))
  result = hook(call_604444, url, valid)

proc call*(call_604445: Call_PutComplianceItems_604432; body: JsonNode): Recallable =
  ## putComplianceItems
  ## <p>Registers a compliance type and other compliance details on a designated resource. This action lets you register custom compliance details with a resource. This call overwrites existing compliance information on the resource, so you must provide a full list of compliance items each time that you send the request.</p> <p>ComplianceType can be one of the following:</p> <ul> <li> <p>ExecutionId: The execution ID when the patch, association, or custom compliance item was applied.</p> </li> <li> <p>ExecutionType: Specify patch, association, or Custom:<code>string</code>.</p> </li> <li> <p>ExecutionTime. The time the patch, association, or custom compliance item was applied to the instance.</p> </li> <li> <p>Id: The patch, association, or custom compliance ID.</p> </li> <li> <p>Title: A title.</p> </li> <li> <p>Status: The status of the compliance item. For example, <code>approved</code> for patches, or <code>Failed</code> for associations.</p> </li> <li> <p>Severity: A patch severity. For example, <code>critical</code>.</p> </li> <li> <p>DocumentName: A SSM document name. For example, AWS-RunPatchBaseline.</p> </li> <li> <p>DocumentVersion: An SSM document version number. For example, 4.</p> </li> <li> <p>Classification: A patch classification. For example, <code>security updates</code>.</p> </li> <li> <p>PatchBaselineId: A patch baseline ID.</p> </li> <li> <p>PatchSeverity: A patch severity. For example, <code>Critical</code>.</p> </li> <li> <p>PatchState: A patch state. For example, <code>InstancesWithFailedPatches</code>.</p> </li> <li> <p>PatchGroup: The name of a patch group.</p> </li> <li> <p>InstalledTime: The time the association, patch, or custom compliance item was applied to the resource. Specify the time by using the following format: yyyy-MM-dd'T'HH:mm:ss'Z'</p> </li> </ul>
  ##   body: JObject (required)
  var body_604446 = newJObject()
  if body != nil:
    body_604446 = body
  result = call_604445.call(nil, nil, nil, nil, body_604446)

var putComplianceItems* = Call_PutComplianceItems_604432(
    name: "putComplianceItems", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.PutComplianceItems",
    validator: validate_PutComplianceItems_604433, base: "/",
    url: url_PutComplianceItems_604434, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutInventory_604447 = ref object of OpenApiRestCall_602433
proc url_PutInventory_604449(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutInventory_604448(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604450 = header.getOrDefault("X-Amz-Date")
  valid_604450 = validateParameter(valid_604450, JString, required = false,
                                 default = nil)
  if valid_604450 != nil:
    section.add "X-Amz-Date", valid_604450
  var valid_604451 = header.getOrDefault("X-Amz-Security-Token")
  valid_604451 = validateParameter(valid_604451, JString, required = false,
                                 default = nil)
  if valid_604451 != nil:
    section.add "X-Amz-Security-Token", valid_604451
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604452 = header.getOrDefault("X-Amz-Target")
  valid_604452 = validateParameter(valid_604452, JString, required = true,
                                 default = newJString("AmazonSSM.PutInventory"))
  if valid_604452 != nil:
    section.add "X-Amz-Target", valid_604452
  var valid_604453 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604453 = validateParameter(valid_604453, JString, required = false,
                                 default = nil)
  if valid_604453 != nil:
    section.add "X-Amz-Content-Sha256", valid_604453
  var valid_604454 = header.getOrDefault("X-Amz-Algorithm")
  valid_604454 = validateParameter(valid_604454, JString, required = false,
                                 default = nil)
  if valid_604454 != nil:
    section.add "X-Amz-Algorithm", valid_604454
  var valid_604455 = header.getOrDefault("X-Amz-Signature")
  valid_604455 = validateParameter(valid_604455, JString, required = false,
                                 default = nil)
  if valid_604455 != nil:
    section.add "X-Amz-Signature", valid_604455
  var valid_604456 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604456 = validateParameter(valid_604456, JString, required = false,
                                 default = nil)
  if valid_604456 != nil:
    section.add "X-Amz-SignedHeaders", valid_604456
  var valid_604457 = header.getOrDefault("X-Amz-Credential")
  valid_604457 = validateParameter(valid_604457, JString, required = false,
                                 default = nil)
  if valid_604457 != nil:
    section.add "X-Amz-Credential", valid_604457
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604459: Call_PutInventory_604447; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Bulk update custom inventory items on one more instance. The request adds an inventory item, if it doesn't already exist, or updates an inventory item, if it does exist.
  ## 
  let valid = call_604459.validator(path, query, header, formData, body)
  let scheme = call_604459.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604459.url(scheme.get, call_604459.host, call_604459.base,
                         call_604459.route, valid.getOrDefault("path"))
  result = hook(call_604459, url, valid)

proc call*(call_604460: Call_PutInventory_604447; body: JsonNode): Recallable =
  ## putInventory
  ## Bulk update custom inventory items on one more instance. The request adds an inventory item, if it doesn't already exist, or updates an inventory item, if it does exist.
  ##   body: JObject (required)
  var body_604461 = newJObject()
  if body != nil:
    body_604461 = body
  result = call_604460.call(nil, nil, nil, nil, body_604461)

var putInventory* = Call_PutInventory_604447(name: "putInventory",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.PutInventory",
    validator: validate_PutInventory_604448, base: "/", url: url_PutInventory_604449,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutParameter_604462 = ref object of OpenApiRestCall_602433
proc url_PutParameter_604464(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutParameter_604463(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604465 = header.getOrDefault("X-Amz-Date")
  valid_604465 = validateParameter(valid_604465, JString, required = false,
                                 default = nil)
  if valid_604465 != nil:
    section.add "X-Amz-Date", valid_604465
  var valid_604466 = header.getOrDefault("X-Amz-Security-Token")
  valid_604466 = validateParameter(valid_604466, JString, required = false,
                                 default = nil)
  if valid_604466 != nil:
    section.add "X-Amz-Security-Token", valid_604466
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604467 = header.getOrDefault("X-Amz-Target")
  valid_604467 = validateParameter(valid_604467, JString, required = true,
                                 default = newJString("AmazonSSM.PutParameter"))
  if valid_604467 != nil:
    section.add "X-Amz-Target", valid_604467
  var valid_604468 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604468 = validateParameter(valid_604468, JString, required = false,
                                 default = nil)
  if valid_604468 != nil:
    section.add "X-Amz-Content-Sha256", valid_604468
  var valid_604469 = header.getOrDefault("X-Amz-Algorithm")
  valid_604469 = validateParameter(valid_604469, JString, required = false,
                                 default = nil)
  if valid_604469 != nil:
    section.add "X-Amz-Algorithm", valid_604469
  var valid_604470 = header.getOrDefault("X-Amz-Signature")
  valid_604470 = validateParameter(valid_604470, JString, required = false,
                                 default = nil)
  if valid_604470 != nil:
    section.add "X-Amz-Signature", valid_604470
  var valid_604471 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604471 = validateParameter(valid_604471, JString, required = false,
                                 default = nil)
  if valid_604471 != nil:
    section.add "X-Amz-SignedHeaders", valid_604471
  var valid_604472 = header.getOrDefault("X-Amz-Credential")
  valid_604472 = validateParameter(valid_604472, JString, required = false,
                                 default = nil)
  if valid_604472 != nil:
    section.add "X-Amz-Credential", valid_604472
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604474: Call_PutParameter_604462; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Add a parameter to the system.
  ## 
  let valid = call_604474.validator(path, query, header, formData, body)
  let scheme = call_604474.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604474.url(scheme.get, call_604474.host, call_604474.base,
                         call_604474.route, valid.getOrDefault("path"))
  result = hook(call_604474, url, valid)

proc call*(call_604475: Call_PutParameter_604462; body: JsonNode): Recallable =
  ## putParameter
  ## Add a parameter to the system.
  ##   body: JObject (required)
  var body_604476 = newJObject()
  if body != nil:
    body_604476 = body
  result = call_604475.call(nil, nil, nil, nil, body_604476)

var putParameter* = Call_PutParameter_604462(name: "putParameter",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.PutParameter",
    validator: validate_PutParameter_604463, base: "/", url: url_PutParameter_604464,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterDefaultPatchBaseline_604477 = ref object of OpenApiRestCall_602433
proc url_RegisterDefaultPatchBaseline_604479(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RegisterDefaultPatchBaseline_604478(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604480 = header.getOrDefault("X-Amz-Date")
  valid_604480 = validateParameter(valid_604480, JString, required = false,
                                 default = nil)
  if valid_604480 != nil:
    section.add "X-Amz-Date", valid_604480
  var valid_604481 = header.getOrDefault("X-Amz-Security-Token")
  valid_604481 = validateParameter(valid_604481, JString, required = false,
                                 default = nil)
  if valid_604481 != nil:
    section.add "X-Amz-Security-Token", valid_604481
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604482 = header.getOrDefault("X-Amz-Target")
  valid_604482 = validateParameter(valid_604482, JString, required = true, default = newJString(
      "AmazonSSM.RegisterDefaultPatchBaseline"))
  if valid_604482 != nil:
    section.add "X-Amz-Target", valid_604482
  var valid_604483 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604483 = validateParameter(valid_604483, JString, required = false,
                                 default = nil)
  if valid_604483 != nil:
    section.add "X-Amz-Content-Sha256", valid_604483
  var valid_604484 = header.getOrDefault("X-Amz-Algorithm")
  valid_604484 = validateParameter(valid_604484, JString, required = false,
                                 default = nil)
  if valid_604484 != nil:
    section.add "X-Amz-Algorithm", valid_604484
  var valid_604485 = header.getOrDefault("X-Amz-Signature")
  valid_604485 = validateParameter(valid_604485, JString, required = false,
                                 default = nil)
  if valid_604485 != nil:
    section.add "X-Amz-Signature", valid_604485
  var valid_604486 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604486 = validateParameter(valid_604486, JString, required = false,
                                 default = nil)
  if valid_604486 != nil:
    section.add "X-Amz-SignedHeaders", valid_604486
  var valid_604487 = header.getOrDefault("X-Amz-Credential")
  valid_604487 = validateParameter(valid_604487, JString, required = false,
                                 default = nil)
  if valid_604487 != nil:
    section.add "X-Amz-Credential", valid_604487
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604489: Call_RegisterDefaultPatchBaseline_604477; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Defines the default patch baseline for the relevant operating system.</p> <p>To reset the AWS predefined patch baseline as the default, specify the full patch baseline ARN as the baseline ID value. For example, for CentOS, specify <code>arn:aws:ssm:us-east-2:733109147000:patchbaseline/pb-0574b43a65ea646ed</code> instead of <code>pb-0574b43a65ea646ed</code>.</p>
  ## 
  let valid = call_604489.validator(path, query, header, formData, body)
  let scheme = call_604489.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604489.url(scheme.get, call_604489.host, call_604489.base,
                         call_604489.route, valid.getOrDefault("path"))
  result = hook(call_604489, url, valid)

proc call*(call_604490: Call_RegisterDefaultPatchBaseline_604477; body: JsonNode): Recallable =
  ## registerDefaultPatchBaseline
  ## <p>Defines the default patch baseline for the relevant operating system.</p> <p>To reset the AWS predefined patch baseline as the default, specify the full patch baseline ARN as the baseline ID value. For example, for CentOS, specify <code>arn:aws:ssm:us-east-2:733109147000:patchbaseline/pb-0574b43a65ea646ed</code> instead of <code>pb-0574b43a65ea646ed</code>.</p>
  ##   body: JObject (required)
  var body_604491 = newJObject()
  if body != nil:
    body_604491 = body
  result = call_604490.call(nil, nil, nil, nil, body_604491)

var registerDefaultPatchBaseline* = Call_RegisterDefaultPatchBaseline_604477(
    name: "registerDefaultPatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.RegisterDefaultPatchBaseline",
    validator: validate_RegisterDefaultPatchBaseline_604478, base: "/",
    url: url_RegisterDefaultPatchBaseline_604479,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterPatchBaselineForPatchGroup_604492 = ref object of OpenApiRestCall_602433
proc url_RegisterPatchBaselineForPatchGroup_604494(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RegisterPatchBaselineForPatchGroup_604493(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604495 = header.getOrDefault("X-Amz-Date")
  valid_604495 = validateParameter(valid_604495, JString, required = false,
                                 default = nil)
  if valid_604495 != nil:
    section.add "X-Amz-Date", valid_604495
  var valid_604496 = header.getOrDefault("X-Amz-Security-Token")
  valid_604496 = validateParameter(valid_604496, JString, required = false,
                                 default = nil)
  if valid_604496 != nil:
    section.add "X-Amz-Security-Token", valid_604496
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604497 = header.getOrDefault("X-Amz-Target")
  valid_604497 = validateParameter(valid_604497, JString, required = true, default = newJString(
      "AmazonSSM.RegisterPatchBaselineForPatchGroup"))
  if valid_604497 != nil:
    section.add "X-Amz-Target", valid_604497
  var valid_604498 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604498 = validateParameter(valid_604498, JString, required = false,
                                 default = nil)
  if valid_604498 != nil:
    section.add "X-Amz-Content-Sha256", valid_604498
  var valid_604499 = header.getOrDefault("X-Amz-Algorithm")
  valid_604499 = validateParameter(valid_604499, JString, required = false,
                                 default = nil)
  if valid_604499 != nil:
    section.add "X-Amz-Algorithm", valid_604499
  var valid_604500 = header.getOrDefault("X-Amz-Signature")
  valid_604500 = validateParameter(valid_604500, JString, required = false,
                                 default = nil)
  if valid_604500 != nil:
    section.add "X-Amz-Signature", valid_604500
  var valid_604501 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604501 = validateParameter(valid_604501, JString, required = false,
                                 default = nil)
  if valid_604501 != nil:
    section.add "X-Amz-SignedHeaders", valid_604501
  var valid_604502 = header.getOrDefault("X-Amz-Credential")
  valid_604502 = validateParameter(valid_604502, JString, required = false,
                                 default = nil)
  if valid_604502 != nil:
    section.add "X-Amz-Credential", valid_604502
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604504: Call_RegisterPatchBaselineForPatchGroup_604492;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Registers a patch baseline for a patch group.
  ## 
  let valid = call_604504.validator(path, query, header, formData, body)
  let scheme = call_604504.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604504.url(scheme.get, call_604504.host, call_604504.base,
                         call_604504.route, valid.getOrDefault("path"))
  result = hook(call_604504, url, valid)

proc call*(call_604505: Call_RegisterPatchBaselineForPatchGroup_604492;
          body: JsonNode): Recallable =
  ## registerPatchBaselineForPatchGroup
  ## Registers a patch baseline for a patch group.
  ##   body: JObject (required)
  var body_604506 = newJObject()
  if body != nil:
    body_604506 = body
  result = call_604505.call(nil, nil, nil, nil, body_604506)

var registerPatchBaselineForPatchGroup* = Call_RegisterPatchBaselineForPatchGroup_604492(
    name: "registerPatchBaselineForPatchGroup", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.RegisterPatchBaselineForPatchGroup",
    validator: validate_RegisterPatchBaselineForPatchGroup_604493, base: "/",
    url: url_RegisterPatchBaselineForPatchGroup_604494,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterTargetWithMaintenanceWindow_604507 = ref object of OpenApiRestCall_602433
proc url_RegisterTargetWithMaintenanceWindow_604509(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RegisterTargetWithMaintenanceWindow_604508(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604510 = header.getOrDefault("X-Amz-Date")
  valid_604510 = validateParameter(valid_604510, JString, required = false,
                                 default = nil)
  if valid_604510 != nil:
    section.add "X-Amz-Date", valid_604510
  var valid_604511 = header.getOrDefault("X-Amz-Security-Token")
  valid_604511 = validateParameter(valid_604511, JString, required = false,
                                 default = nil)
  if valid_604511 != nil:
    section.add "X-Amz-Security-Token", valid_604511
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604512 = header.getOrDefault("X-Amz-Target")
  valid_604512 = validateParameter(valid_604512, JString, required = true, default = newJString(
      "AmazonSSM.RegisterTargetWithMaintenanceWindow"))
  if valid_604512 != nil:
    section.add "X-Amz-Target", valid_604512
  var valid_604513 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604513 = validateParameter(valid_604513, JString, required = false,
                                 default = nil)
  if valid_604513 != nil:
    section.add "X-Amz-Content-Sha256", valid_604513
  var valid_604514 = header.getOrDefault("X-Amz-Algorithm")
  valid_604514 = validateParameter(valid_604514, JString, required = false,
                                 default = nil)
  if valid_604514 != nil:
    section.add "X-Amz-Algorithm", valid_604514
  var valid_604515 = header.getOrDefault("X-Amz-Signature")
  valid_604515 = validateParameter(valid_604515, JString, required = false,
                                 default = nil)
  if valid_604515 != nil:
    section.add "X-Amz-Signature", valid_604515
  var valid_604516 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604516 = validateParameter(valid_604516, JString, required = false,
                                 default = nil)
  if valid_604516 != nil:
    section.add "X-Amz-SignedHeaders", valid_604516
  var valid_604517 = header.getOrDefault("X-Amz-Credential")
  valid_604517 = validateParameter(valid_604517, JString, required = false,
                                 default = nil)
  if valid_604517 != nil:
    section.add "X-Amz-Credential", valid_604517
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604519: Call_RegisterTargetWithMaintenanceWindow_604507;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Registers a target with a maintenance window.
  ## 
  let valid = call_604519.validator(path, query, header, formData, body)
  let scheme = call_604519.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604519.url(scheme.get, call_604519.host, call_604519.base,
                         call_604519.route, valid.getOrDefault("path"))
  result = hook(call_604519, url, valid)

proc call*(call_604520: Call_RegisterTargetWithMaintenanceWindow_604507;
          body: JsonNode): Recallable =
  ## registerTargetWithMaintenanceWindow
  ## Registers a target with a maintenance window.
  ##   body: JObject (required)
  var body_604521 = newJObject()
  if body != nil:
    body_604521 = body
  result = call_604520.call(nil, nil, nil, nil, body_604521)

var registerTargetWithMaintenanceWindow* = Call_RegisterTargetWithMaintenanceWindow_604507(
    name: "registerTargetWithMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.RegisterTargetWithMaintenanceWindow",
    validator: validate_RegisterTargetWithMaintenanceWindow_604508, base: "/",
    url: url_RegisterTargetWithMaintenanceWindow_604509,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterTaskWithMaintenanceWindow_604522 = ref object of OpenApiRestCall_602433
proc url_RegisterTaskWithMaintenanceWindow_604524(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RegisterTaskWithMaintenanceWindow_604523(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604525 = header.getOrDefault("X-Amz-Date")
  valid_604525 = validateParameter(valid_604525, JString, required = false,
                                 default = nil)
  if valid_604525 != nil:
    section.add "X-Amz-Date", valid_604525
  var valid_604526 = header.getOrDefault("X-Amz-Security-Token")
  valid_604526 = validateParameter(valid_604526, JString, required = false,
                                 default = nil)
  if valid_604526 != nil:
    section.add "X-Amz-Security-Token", valid_604526
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604527 = header.getOrDefault("X-Amz-Target")
  valid_604527 = validateParameter(valid_604527, JString, required = true, default = newJString(
      "AmazonSSM.RegisterTaskWithMaintenanceWindow"))
  if valid_604527 != nil:
    section.add "X-Amz-Target", valid_604527
  var valid_604528 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604528 = validateParameter(valid_604528, JString, required = false,
                                 default = nil)
  if valid_604528 != nil:
    section.add "X-Amz-Content-Sha256", valid_604528
  var valid_604529 = header.getOrDefault("X-Amz-Algorithm")
  valid_604529 = validateParameter(valid_604529, JString, required = false,
                                 default = nil)
  if valid_604529 != nil:
    section.add "X-Amz-Algorithm", valid_604529
  var valid_604530 = header.getOrDefault("X-Amz-Signature")
  valid_604530 = validateParameter(valid_604530, JString, required = false,
                                 default = nil)
  if valid_604530 != nil:
    section.add "X-Amz-Signature", valid_604530
  var valid_604531 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604531 = validateParameter(valid_604531, JString, required = false,
                                 default = nil)
  if valid_604531 != nil:
    section.add "X-Amz-SignedHeaders", valid_604531
  var valid_604532 = header.getOrDefault("X-Amz-Credential")
  valid_604532 = validateParameter(valid_604532, JString, required = false,
                                 default = nil)
  if valid_604532 != nil:
    section.add "X-Amz-Credential", valid_604532
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604534: Call_RegisterTaskWithMaintenanceWindow_604522;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Adds a new task to a maintenance window.
  ## 
  let valid = call_604534.validator(path, query, header, formData, body)
  let scheme = call_604534.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604534.url(scheme.get, call_604534.host, call_604534.base,
                         call_604534.route, valid.getOrDefault("path"))
  result = hook(call_604534, url, valid)

proc call*(call_604535: Call_RegisterTaskWithMaintenanceWindow_604522;
          body: JsonNode): Recallable =
  ## registerTaskWithMaintenanceWindow
  ## Adds a new task to a maintenance window.
  ##   body: JObject (required)
  var body_604536 = newJObject()
  if body != nil:
    body_604536 = body
  result = call_604535.call(nil, nil, nil, nil, body_604536)

var registerTaskWithMaintenanceWindow* = Call_RegisterTaskWithMaintenanceWindow_604522(
    name: "registerTaskWithMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.RegisterTaskWithMaintenanceWindow",
    validator: validate_RegisterTaskWithMaintenanceWindow_604523, base: "/",
    url: url_RegisterTaskWithMaintenanceWindow_604524,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveTagsFromResource_604537 = ref object of OpenApiRestCall_602433
proc url_RemoveTagsFromResource_604539(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RemoveTagsFromResource_604538(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604540 = header.getOrDefault("X-Amz-Date")
  valid_604540 = validateParameter(valid_604540, JString, required = false,
                                 default = nil)
  if valid_604540 != nil:
    section.add "X-Amz-Date", valid_604540
  var valid_604541 = header.getOrDefault("X-Amz-Security-Token")
  valid_604541 = validateParameter(valid_604541, JString, required = false,
                                 default = nil)
  if valid_604541 != nil:
    section.add "X-Amz-Security-Token", valid_604541
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604542 = header.getOrDefault("X-Amz-Target")
  valid_604542 = validateParameter(valid_604542, JString, required = true, default = newJString(
      "AmazonSSM.RemoveTagsFromResource"))
  if valid_604542 != nil:
    section.add "X-Amz-Target", valid_604542
  var valid_604543 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604543 = validateParameter(valid_604543, JString, required = false,
                                 default = nil)
  if valid_604543 != nil:
    section.add "X-Amz-Content-Sha256", valid_604543
  var valid_604544 = header.getOrDefault("X-Amz-Algorithm")
  valid_604544 = validateParameter(valid_604544, JString, required = false,
                                 default = nil)
  if valid_604544 != nil:
    section.add "X-Amz-Algorithm", valid_604544
  var valid_604545 = header.getOrDefault("X-Amz-Signature")
  valid_604545 = validateParameter(valid_604545, JString, required = false,
                                 default = nil)
  if valid_604545 != nil:
    section.add "X-Amz-Signature", valid_604545
  var valid_604546 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604546 = validateParameter(valid_604546, JString, required = false,
                                 default = nil)
  if valid_604546 != nil:
    section.add "X-Amz-SignedHeaders", valid_604546
  var valid_604547 = header.getOrDefault("X-Amz-Credential")
  valid_604547 = validateParameter(valid_604547, JString, required = false,
                                 default = nil)
  if valid_604547 != nil:
    section.add "X-Amz-Credential", valid_604547
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604549: Call_RemoveTagsFromResource_604537; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tag keys from the specified resource.
  ## 
  let valid = call_604549.validator(path, query, header, formData, body)
  let scheme = call_604549.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604549.url(scheme.get, call_604549.host, call_604549.base,
                         call_604549.route, valid.getOrDefault("path"))
  result = hook(call_604549, url, valid)

proc call*(call_604550: Call_RemoveTagsFromResource_604537; body: JsonNode): Recallable =
  ## removeTagsFromResource
  ## Removes tag keys from the specified resource.
  ##   body: JObject (required)
  var body_604551 = newJObject()
  if body != nil:
    body_604551 = body
  result = call_604550.call(nil, nil, nil, nil, body_604551)

var removeTagsFromResource* = Call_RemoveTagsFromResource_604537(
    name: "removeTagsFromResource", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.RemoveTagsFromResource",
    validator: validate_RemoveTagsFromResource_604538, base: "/",
    url: url_RemoveTagsFromResource_604539, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResetServiceSetting_604552 = ref object of OpenApiRestCall_602433
proc url_ResetServiceSetting_604554(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ResetServiceSetting_604553(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604555 = header.getOrDefault("X-Amz-Date")
  valid_604555 = validateParameter(valid_604555, JString, required = false,
                                 default = nil)
  if valid_604555 != nil:
    section.add "X-Amz-Date", valid_604555
  var valid_604556 = header.getOrDefault("X-Amz-Security-Token")
  valid_604556 = validateParameter(valid_604556, JString, required = false,
                                 default = nil)
  if valid_604556 != nil:
    section.add "X-Amz-Security-Token", valid_604556
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604557 = header.getOrDefault("X-Amz-Target")
  valid_604557 = validateParameter(valid_604557, JString, required = true, default = newJString(
      "AmazonSSM.ResetServiceSetting"))
  if valid_604557 != nil:
    section.add "X-Amz-Target", valid_604557
  var valid_604558 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604558 = validateParameter(valid_604558, JString, required = false,
                                 default = nil)
  if valid_604558 != nil:
    section.add "X-Amz-Content-Sha256", valid_604558
  var valid_604559 = header.getOrDefault("X-Amz-Algorithm")
  valid_604559 = validateParameter(valid_604559, JString, required = false,
                                 default = nil)
  if valid_604559 != nil:
    section.add "X-Amz-Algorithm", valid_604559
  var valid_604560 = header.getOrDefault("X-Amz-Signature")
  valid_604560 = validateParameter(valid_604560, JString, required = false,
                                 default = nil)
  if valid_604560 != nil:
    section.add "X-Amz-Signature", valid_604560
  var valid_604561 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604561 = validateParameter(valid_604561, JString, required = false,
                                 default = nil)
  if valid_604561 != nil:
    section.add "X-Amz-SignedHeaders", valid_604561
  var valid_604562 = header.getOrDefault("X-Amz-Credential")
  valid_604562 = validateParameter(valid_604562, JString, required = false,
                                 default = nil)
  if valid_604562 != nil:
    section.add "X-Amz-Credential", valid_604562
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604564: Call_ResetServiceSetting_604552; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>GetServiceSetting</a> API action to view the current value. Use the <a>UpdateServiceSetting</a> API action to change the default setting. </p> <p>Reset the service setting for the account to the default value as provisioned by the AWS service team. </p>
  ## 
  let valid = call_604564.validator(path, query, header, formData, body)
  let scheme = call_604564.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604564.url(scheme.get, call_604564.host, call_604564.base,
                         call_604564.route, valid.getOrDefault("path"))
  result = hook(call_604564, url, valid)

proc call*(call_604565: Call_ResetServiceSetting_604552; body: JsonNode): Recallable =
  ## resetServiceSetting
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>GetServiceSetting</a> API action to view the current value. Use the <a>UpdateServiceSetting</a> API action to change the default setting. </p> <p>Reset the service setting for the account to the default value as provisioned by the AWS service team. </p>
  ##   body: JObject (required)
  var body_604566 = newJObject()
  if body != nil:
    body_604566 = body
  result = call_604565.call(nil, nil, nil, nil, body_604566)

var resetServiceSetting* = Call_ResetServiceSetting_604552(
    name: "resetServiceSetting", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ResetServiceSetting",
    validator: validate_ResetServiceSetting_604553, base: "/",
    url: url_ResetServiceSetting_604554, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResumeSession_604567 = ref object of OpenApiRestCall_602433
proc url_ResumeSession_604569(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ResumeSession_604568(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604570 = header.getOrDefault("X-Amz-Date")
  valid_604570 = validateParameter(valid_604570, JString, required = false,
                                 default = nil)
  if valid_604570 != nil:
    section.add "X-Amz-Date", valid_604570
  var valid_604571 = header.getOrDefault("X-Amz-Security-Token")
  valid_604571 = validateParameter(valid_604571, JString, required = false,
                                 default = nil)
  if valid_604571 != nil:
    section.add "X-Amz-Security-Token", valid_604571
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604572 = header.getOrDefault("X-Amz-Target")
  valid_604572 = validateParameter(valid_604572, JString, required = true, default = newJString(
      "AmazonSSM.ResumeSession"))
  if valid_604572 != nil:
    section.add "X-Amz-Target", valid_604572
  var valid_604573 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604573 = validateParameter(valid_604573, JString, required = false,
                                 default = nil)
  if valid_604573 != nil:
    section.add "X-Amz-Content-Sha256", valid_604573
  var valid_604574 = header.getOrDefault("X-Amz-Algorithm")
  valid_604574 = validateParameter(valid_604574, JString, required = false,
                                 default = nil)
  if valid_604574 != nil:
    section.add "X-Amz-Algorithm", valid_604574
  var valid_604575 = header.getOrDefault("X-Amz-Signature")
  valid_604575 = validateParameter(valid_604575, JString, required = false,
                                 default = nil)
  if valid_604575 != nil:
    section.add "X-Amz-Signature", valid_604575
  var valid_604576 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604576 = validateParameter(valid_604576, JString, required = false,
                                 default = nil)
  if valid_604576 != nil:
    section.add "X-Amz-SignedHeaders", valid_604576
  var valid_604577 = header.getOrDefault("X-Amz-Credential")
  valid_604577 = validateParameter(valid_604577, JString, required = false,
                                 default = nil)
  if valid_604577 != nil:
    section.add "X-Amz-Credential", valid_604577
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604579: Call_ResumeSession_604567; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Reconnects a session to an instance after it has been disconnected. Connections can be resumed for disconnected sessions, but not terminated sessions.</p> <note> <p>This command is primarily for use by client machines to automatically reconnect during intermittent network issues. It is not intended for any other use.</p> </note>
  ## 
  let valid = call_604579.validator(path, query, header, formData, body)
  let scheme = call_604579.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604579.url(scheme.get, call_604579.host, call_604579.base,
                         call_604579.route, valid.getOrDefault("path"))
  result = hook(call_604579, url, valid)

proc call*(call_604580: Call_ResumeSession_604567; body: JsonNode): Recallable =
  ## resumeSession
  ## <p>Reconnects a session to an instance after it has been disconnected. Connections can be resumed for disconnected sessions, but not terminated sessions.</p> <note> <p>This command is primarily for use by client machines to automatically reconnect during intermittent network issues. It is not intended for any other use.</p> </note>
  ##   body: JObject (required)
  var body_604581 = newJObject()
  if body != nil:
    body_604581 = body
  result = call_604580.call(nil, nil, nil, nil, body_604581)

var resumeSession* = Call_ResumeSession_604567(name: "resumeSession",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ResumeSession",
    validator: validate_ResumeSession_604568, base: "/", url: url_ResumeSession_604569,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendAutomationSignal_604582 = ref object of OpenApiRestCall_602433
proc url_SendAutomationSignal_604584(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_SendAutomationSignal_604583(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604585 = header.getOrDefault("X-Amz-Date")
  valid_604585 = validateParameter(valid_604585, JString, required = false,
                                 default = nil)
  if valid_604585 != nil:
    section.add "X-Amz-Date", valid_604585
  var valid_604586 = header.getOrDefault("X-Amz-Security-Token")
  valid_604586 = validateParameter(valid_604586, JString, required = false,
                                 default = nil)
  if valid_604586 != nil:
    section.add "X-Amz-Security-Token", valid_604586
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604587 = header.getOrDefault("X-Amz-Target")
  valid_604587 = validateParameter(valid_604587, JString, required = true, default = newJString(
      "AmazonSSM.SendAutomationSignal"))
  if valid_604587 != nil:
    section.add "X-Amz-Target", valid_604587
  var valid_604588 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604588 = validateParameter(valid_604588, JString, required = false,
                                 default = nil)
  if valid_604588 != nil:
    section.add "X-Amz-Content-Sha256", valid_604588
  var valid_604589 = header.getOrDefault("X-Amz-Algorithm")
  valid_604589 = validateParameter(valid_604589, JString, required = false,
                                 default = nil)
  if valid_604589 != nil:
    section.add "X-Amz-Algorithm", valid_604589
  var valid_604590 = header.getOrDefault("X-Amz-Signature")
  valid_604590 = validateParameter(valid_604590, JString, required = false,
                                 default = nil)
  if valid_604590 != nil:
    section.add "X-Amz-Signature", valid_604590
  var valid_604591 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604591 = validateParameter(valid_604591, JString, required = false,
                                 default = nil)
  if valid_604591 != nil:
    section.add "X-Amz-SignedHeaders", valid_604591
  var valid_604592 = header.getOrDefault("X-Amz-Credential")
  valid_604592 = validateParameter(valid_604592, JString, required = false,
                                 default = nil)
  if valid_604592 != nil:
    section.add "X-Amz-Credential", valid_604592
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604594: Call_SendAutomationSignal_604582; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sends a signal to an Automation execution to change the current behavior or status of the execution. 
  ## 
  let valid = call_604594.validator(path, query, header, formData, body)
  let scheme = call_604594.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604594.url(scheme.get, call_604594.host, call_604594.base,
                         call_604594.route, valid.getOrDefault("path"))
  result = hook(call_604594, url, valid)

proc call*(call_604595: Call_SendAutomationSignal_604582; body: JsonNode): Recallable =
  ## sendAutomationSignal
  ## Sends a signal to an Automation execution to change the current behavior or status of the execution. 
  ##   body: JObject (required)
  var body_604596 = newJObject()
  if body != nil:
    body_604596 = body
  result = call_604595.call(nil, nil, nil, nil, body_604596)

var sendAutomationSignal* = Call_SendAutomationSignal_604582(
    name: "sendAutomationSignal", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.SendAutomationSignal",
    validator: validate_SendAutomationSignal_604583, base: "/",
    url: url_SendAutomationSignal_604584, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendCommand_604597 = ref object of OpenApiRestCall_602433
proc url_SendCommand_604599(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_SendCommand_604598(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604600 = header.getOrDefault("X-Amz-Date")
  valid_604600 = validateParameter(valid_604600, JString, required = false,
                                 default = nil)
  if valid_604600 != nil:
    section.add "X-Amz-Date", valid_604600
  var valid_604601 = header.getOrDefault("X-Amz-Security-Token")
  valid_604601 = validateParameter(valid_604601, JString, required = false,
                                 default = nil)
  if valid_604601 != nil:
    section.add "X-Amz-Security-Token", valid_604601
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604602 = header.getOrDefault("X-Amz-Target")
  valid_604602 = validateParameter(valid_604602, JString, required = true,
                                 default = newJString("AmazonSSM.SendCommand"))
  if valid_604602 != nil:
    section.add "X-Amz-Target", valid_604602
  var valid_604603 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604603 = validateParameter(valid_604603, JString, required = false,
                                 default = nil)
  if valid_604603 != nil:
    section.add "X-Amz-Content-Sha256", valid_604603
  var valid_604604 = header.getOrDefault("X-Amz-Algorithm")
  valid_604604 = validateParameter(valid_604604, JString, required = false,
                                 default = nil)
  if valid_604604 != nil:
    section.add "X-Amz-Algorithm", valid_604604
  var valid_604605 = header.getOrDefault("X-Amz-Signature")
  valid_604605 = validateParameter(valid_604605, JString, required = false,
                                 default = nil)
  if valid_604605 != nil:
    section.add "X-Amz-Signature", valid_604605
  var valid_604606 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604606 = validateParameter(valid_604606, JString, required = false,
                                 default = nil)
  if valid_604606 != nil:
    section.add "X-Amz-SignedHeaders", valid_604606
  var valid_604607 = header.getOrDefault("X-Amz-Credential")
  valid_604607 = validateParameter(valid_604607, JString, required = false,
                                 default = nil)
  if valid_604607 != nil:
    section.add "X-Amz-Credential", valid_604607
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604609: Call_SendCommand_604597; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Runs commands on one or more managed instances.
  ## 
  let valid = call_604609.validator(path, query, header, formData, body)
  let scheme = call_604609.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604609.url(scheme.get, call_604609.host, call_604609.base,
                         call_604609.route, valid.getOrDefault("path"))
  result = hook(call_604609, url, valid)

proc call*(call_604610: Call_SendCommand_604597; body: JsonNode): Recallable =
  ## sendCommand
  ## Runs commands on one or more managed instances.
  ##   body: JObject (required)
  var body_604611 = newJObject()
  if body != nil:
    body_604611 = body
  result = call_604610.call(nil, nil, nil, nil, body_604611)

var sendCommand* = Call_SendCommand_604597(name: "sendCommand",
                                        meth: HttpMethod.HttpPost,
                                        host: "ssm.amazonaws.com", route: "/#X-Amz-Target=AmazonSSM.SendCommand",
                                        validator: validate_SendCommand_604598,
                                        base: "/", url: url_SendCommand_604599,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartAssociationsOnce_604612 = ref object of OpenApiRestCall_602433
proc url_StartAssociationsOnce_604614(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StartAssociationsOnce_604613(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604615 = header.getOrDefault("X-Amz-Date")
  valid_604615 = validateParameter(valid_604615, JString, required = false,
                                 default = nil)
  if valid_604615 != nil:
    section.add "X-Amz-Date", valid_604615
  var valid_604616 = header.getOrDefault("X-Amz-Security-Token")
  valid_604616 = validateParameter(valid_604616, JString, required = false,
                                 default = nil)
  if valid_604616 != nil:
    section.add "X-Amz-Security-Token", valid_604616
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604617 = header.getOrDefault("X-Amz-Target")
  valid_604617 = validateParameter(valid_604617, JString, required = true, default = newJString(
      "AmazonSSM.StartAssociationsOnce"))
  if valid_604617 != nil:
    section.add "X-Amz-Target", valid_604617
  var valid_604618 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604618 = validateParameter(valid_604618, JString, required = false,
                                 default = nil)
  if valid_604618 != nil:
    section.add "X-Amz-Content-Sha256", valid_604618
  var valid_604619 = header.getOrDefault("X-Amz-Algorithm")
  valid_604619 = validateParameter(valid_604619, JString, required = false,
                                 default = nil)
  if valid_604619 != nil:
    section.add "X-Amz-Algorithm", valid_604619
  var valid_604620 = header.getOrDefault("X-Amz-Signature")
  valid_604620 = validateParameter(valid_604620, JString, required = false,
                                 default = nil)
  if valid_604620 != nil:
    section.add "X-Amz-Signature", valid_604620
  var valid_604621 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604621 = validateParameter(valid_604621, JString, required = false,
                                 default = nil)
  if valid_604621 != nil:
    section.add "X-Amz-SignedHeaders", valid_604621
  var valid_604622 = header.getOrDefault("X-Amz-Credential")
  valid_604622 = validateParameter(valid_604622, JString, required = false,
                                 default = nil)
  if valid_604622 != nil:
    section.add "X-Amz-Credential", valid_604622
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604624: Call_StartAssociationsOnce_604612; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Use this API action to run an association immediately and only one time. This action can be helpful when troubleshooting associations.
  ## 
  let valid = call_604624.validator(path, query, header, formData, body)
  let scheme = call_604624.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604624.url(scheme.get, call_604624.host, call_604624.base,
                         call_604624.route, valid.getOrDefault("path"))
  result = hook(call_604624, url, valid)

proc call*(call_604625: Call_StartAssociationsOnce_604612; body: JsonNode): Recallable =
  ## startAssociationsOnce
  ## Use this API action to run an association immediately and only one time. This action can be helpful when troubleshooting associations.
  ##   body: JObject (required)
  var body_604626 = newJObject()
  if body != nil:
    body_604626 = body
  result = call_604625.call(nil, nil, nil, nil, body_604626)

var startAssociationsOnce* = Call_StartAssociationsOnce_604612(
    name: "startAssociationsOnce", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.StartAssociationsOnce",
    validator: validate_StartAssociationsOnce_604613, base: "/",
    url: url_StartAssociationsOnce_604614, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartAutomationExecution_604627 = ref object of OpenApiRestCall_602433
proc url_StartAutomationExecution_604629(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StartAutomationExecution_604628(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604630 = header.getOrDefault("X-Amz-Date")
  valid_604630 = validateParameter(valid_604630, JString, required = false,
                                 default = nil)
  if valid_604630 != nil:
    section.add "X-Amz-Date", valid_604630
  var valid_604631 = header.getOrDefault("X-Amz-Security-Token")
  valid_604631 = validateParameter(valid_604631, JString, required = false,
                                 default = nil)
  if valid_604631 != nil:
    section.add "X-Amz-Security-Token", valid_604631
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604632 = header.getOrDefault("X-Amz-Target")
  valid_604632 = validateParameter(valid_604632, JString, required = true, default = newJString(
      "AmazonSSM.StartAutomationExecution"))
  if valid_604632 != nil:
    section.add "X-Amz-Target", valid_604632
  var valid_604633 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604633 = validateParameter(valid_604633, JString, required = false,
                                 default = nil)
  if valid_604633 != nil:
    section.add "X-Amz-Content-Sha256", valid_604633
  var valid_604634 = header.getOrDefault("X-Amz-Algorithm")
  valid_604634 = validateParameter(valid_604634, JString, required = false,
                                 default = nil)
  if valid_604634 != nil:
    section.add "X-Amz-Algorithm", valid_604634
  var valid_604635 = header.getOrDefault("X-Amz-Signature")
  valid_604635 = validateParameter(valid_604635, JString, required = false,
                                 default = nil)
  if valid_604635 != nil:
    section.add "X-Amz-Signature", valid_604635
  var valid_604636 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604636 = validateParameter(valid_604636, JString, required = false,
                                 default = nil)
  if valid_604636 != nil:
    section.add "X-Amz-SignedHeaders", valid_604636
  var valid_604637 = header.getOrDefault("X-Amz-Credential")
  valid_604637 = validateParameter(valid_604637, JString, required = false,
                                 default = nil)
  if valid_604637 != nil:
    section.add "X-Amz-Credential", valid_604637
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604639: Call_StartAutomationExecution_604627; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Initiates execution of an Automation document.
  ## 
  let valid = call_604639.validator(path, query, header, formData, body)
  let scheme = call_604639.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604639.url(scheme.get, call_604639.host, call_604639.base,
                         call_604639.route, valid.getOrDefault("path"))
  result = hook(call_604639, url, valid)

proc call*(call_604640: Call_StartAutomationExecution_604627; body: JsonNode): Recallable =
  ## startAutomationExecution
  ## Initiates execution of an Automation document.
  ##   body: JObject (required)
  var body_604641 = newJObject()
  if body != nil:
    body_604641 = body
  result = call_604640.call(nil, nil, nil, nil, body_604641)

var startAutomationExecution* = Call_StartAutomationExecution_604627(
    name: "startAutomationExecution", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.StartAutomationExecution",
    validator: validate_StartAutomationExecution_604628, base: "/",
    url: url_StartAutomationExecution_604629, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartSession_604642 = ref object of OpenApiRestCall_602433
proc url_StartSession_604644(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StartSession_604643(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Initiates a connection to a target (for example, an instance) for a Session Manager session. Returns a URL and token that can be used to open a WebSocket connection for sending input and receiving outputs.</p> <note> <p>AWS CLI usage: <code>start-session</code> is an interactive command that requires the Session Manager plugin to be installed on the client machine making the call. For information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html"> Install the Session Manager Plugin for the AWS CLI</a> in the <i>AWS Systems Manager User Guide</i>.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604645 = header.getOrDefault("X-Amz-Date")
  valid_604645 = validateParameter(valid_604645, JString, required = false,
                                 default = nil)
  if valid_604645 != nil:
    section.add "X-Amz-Date", valid_604645
  var valid_604646 = header.getOrDefault("X-Amz-Security-Token")
  valid_604646 = validateParameter(valid_604646, JString, required = false,
                                 default = nil)
  if valid_604646 != nil:
    section.add "X-Amz-Security-Token", valid_604646
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604647 = header.getOrDefault("X-Amz-Target")
  valid_604647 = validateParameter(valid_604647, JString, required = true,
                                 default = newJString("AmazonSSM.StartSession"))
  if valid_604647 != nil:
    section.add "X-Amz-Target", valid_604647
  var valid_604648 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604648 = validateParameter(valid_604648, JString, required = false,
                                 default = nil)
  if valid_604648 != nil:
    section.add "X-Amz-Content-Sha256", valid_604648
  var valid_604649 = header.getOrDefault("X-Amz-Algorithm")
  valid_604649 = validateParameter(valid_604649, JString, required = false,
                                 default = nil)
  if valid_604649 != nil:
    section.add "X-Amz-Algorithm", valid_604649
  var valid_604650 = header.getOrDefault("X-Amz-Signature")
  valid_604650 = validateParameter(valid_604650, JString, required = false,
                                 default = nil)
  if valid_604650 != nil:
    section.add "X-Amz-Signature", valid_604650
  var valid_604651 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604651 = validateParameter(valid_604651, JString, required = false,
                                 default = nil)
  if valid_604651 != nil:
    section.add "X-Amz-SignedHeaders", valid_604651
  var valid_604652 = header.getOrDefault("X-Amz-Credential")
  valid_604652 = validateParameter(valid_604652, JString, required = false,
                                 default = nil)
  if valid_604652 != nil:
    section.add "X-Amz-Credential", valid_604652
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604654: Call_StartSession_604642; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates a connection to a target (for example, an instance) for a Session Manager session. Returns a URL and token that can be used to open a WebSocket connection for sending input and receiving outputs.</p> <note> <p>AWS CLI usage: <code>start-session</code> is an interactive command that requires the Session Manager plugin to be installed on the client machine making the call. For information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html"> Install the Session Manager Plugin for the AWS CLI</a> in the <i>AWS Systems Manager User Guide</i>.</p> </note>
  ## 
  let valid = call_604654.validator(path, query, header, formData, body)
  let scheme = call_604654.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604654.url(scheme.get, call_604654.host, call_604654.base,
                         call_604654.route, valid.getOrDefault("path"))
  result = hook(call_604654, url, valid)

proc call*(call_604655: Call_StartSession_604642; body: JsonNode): Recallable =
  ## startSession
  ## <p>Initiates a connection to a target (for example, an instance) for a Session Manager session. Returns a URL and token that can be used to open a WebSocket connection for sending input and receiving outputs.</p> <note> <p>AWS CLI usage: <code>start-session</code> is an interactive command that requires the Session Manager plugin to be installed on the client machine making the call. For information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html"> Install the Session Manager Plugin for the AWS CLI</a> in the <i>AWS Systems Manager User Guide</i>.</p> </note>
  ##   body: JObject (required)
  var body_604656 = newJObject()
  if body != nil:
    body_604656 = body
  result = call_604655.call(nil, nil, nil, nil, body_604656)

var startSession* = Call_StartSession_604642(name: "startSession",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.StartSession",
    validator: validate_StartSession_604643, base: "/", url: url_StartSession_604644,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopAutomationExecution_604657 = ref object of OpenApiRestCall_602433
proc url_StopAutomationExecution_604659(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StopAutomationExecution_604658(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604660 = header.getOrDefault("X-Amz-Date")
  valid_604660 = validateParameter(valid_604660, JString, required = false,
                                 default = nil)
  if valid_604660 != nil:
    section.add "X-Amz-Date", valid_604660
  var valid_604661 = header.getOrDefault("X-Amz-Security-Token")
  valid_604661 = validateParameter(valid_604661, JString, required = false,
                                 default = nil)
  if valid_604661 != nil:
    section.add "X-Amz-Security-Token", valid_604661
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604662 = header.getOrDefault("X-Amz-Target")
  valid_604662 = validateParameter(valid_604662, JString, required = true, default = newJString(
      "AmazonSSM.StopAutomationExecution"))
  if valid_604662 != nil:
    section.add "X-Amz-Target", valid_604662
  var valid_604663 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604663 = validateParameter(valid_604663, JString, required = false,
                                 default = nil)
  if valid_604663 != nil:
    section.add "X-Amz-Content-Sha256", valid_604663
  var valid_604664 = header.getOrDefault("X-Amz-Algorithm")
  valid_604664 = validateParameter(valid_604664, JString, required = false,
                                 default = nil)
  if valid_604664 != nil:
    section.add "X-Amz-Algorithm", valid_604664
  var valid_604665 = header.getOrDefault("X-Amz-Signature")
  valid_604665 = validateParameter(valid_604665, JString, required = false,
                                 default = nil)
  if valid_604665 != nil:
    section.add "X-Amz-Signature", valid_604665
  var valid_604666 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604666 = validateParameter(valid_604666, JString, required = false,
                                 default = nil)
  if valid_604666 != nil:
    section.add "X-Amz-SignedHeaders", valid_604666
  var valid_604667 = header.getOrDefault("X-Amz-Credential")
  valid_604667 = validateParameter(valid_604667, JString, required = false,
                                 default = nil)
  if valid_604667 != nil:
    section.add "X-Amz-Credential", valid_604667
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604669: Call_StopAutomationExecution_604657; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stop an Automation that is currently running.
  ## 
  let valid = call_604669.validator(path, query, header, formData, body)
  let scheme = call_604669.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604669.url(scheme.get, call_604669.host, call_604669.base,
                         call_604669.route, valid.getOrDefault("path"))
  result = hook(call_604669, url, valid)

proc call*(call_604670: Call_StopAutomationExecution_604657; body: JsonNode): Recallable =
  ## stopAutomationExecution
  ## Stop an Automation that is currently running.
  ##   body: JObject (required)
  var body_604671 = newJObject()
  if body != nil:
    body_604671 = body
  result = call_604670.call(nil, nil, nil, nil, body_604671)

var stopAutomationExecution* = Call_StopAutomationExecution_604657(
    name: "stopAutomationExecution", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.StopAutomationExecution",
    validator: validate_StopAutomationExecution_604658, base: "/",
    url: url_StopAutomationExecution_604659, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TerminateSession_604672 = ref object of OpenApiRestCall_602433
proc url_TerminateSession_604674(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_TerminateSession_604673(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604675 = header.getOrDefault("X-Amz-Date")
  valid_604675 = validateParameter(valid_604675, JString, required = false,
                                 default = nil)
  if valid_604675 != nil:
    section.add "X-Amz-Date", valid_604675
  var valid_604676 = header.getOrDefault("X-Amz-Security-Token")
  valid_604676 = validateParameter(valid_604676, JString, required = false,
                                 default = nil)
  if valid_604676 != nil:
    section.add "X-Amz-Security-Token", valid_604676
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604677 = header.getOrDefault("X-Amz-Target")
  valid_604677 = validateParameter(valid_604677, JString, required = true, default = newJString(
      "AmazonSSM.TerminateSession"))
  if valid_604677 != nil:
    section.add "X-Amz-Target", valid_604677
  var valid_604678 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604678 = validateParameter(valid_604678, JString, required = false,
                                 default = nil)
  if valid_604678 != nil:
    section.add "X-Amz-Content-Sha256", valid_604678
  var valid_604679 = header.getOrDefault("X-Amz-Algorithm")
  valid_604679 = validateParameter(valid_604679, JString, required = false,
                                 default = nil)
  if valid_604679 != nil:
    section.add "X-Amz-Algorithm", valid_604679
  var valid_604680 = header.getOrDefault("X-Amz-Signature")
  valid_604680 = validateParameter(valid_604680, JString, required = false,
                                 default = nil)
  if valid_604680 != nil:
    section.add "X-Amz-Signature", valid_604680
  var valid_604681 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604681 = validateParameter(valid_604681, JString, required = false,
                                 default = nil)
  if valid_604681 != nil:
    section.add "X-Amz-SignedHeaders", valid_604681
  var valid_604682 = header.getOrDefault("X-Amz-Credential")
  valid_604682 = validateParameter(valid_604682, JString, required = false,
                                 default = nil)
  if valid_604682 != nil:
    section.add "X-Amz-Credential", valid_604682
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604684: Call_TerminateSession_604672; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently ends a session and closes the data connection between the Session Manager client and SSM Agent on the instance. A terminated session cannot be resumed.
  ## 
  let valid = call_604684.validator(path, query, header, formData, body)
  let scheme = call_604684.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604684.url(scheme.get, call_604684.host, call_604684.base,
                         call_604684.route, valid.getOrDefault("path"))
  result = hook(call_604684, url, valid)

proc call*(call_604685: Call_TerminateSession_604672; body: JsonNode): Recallable =
  ## terminateSession
  ## Permanently ends a session and closes the data connection between the Session Manager client and SSM Agent on the instance. A terminated session cannot be resumed.
  ##   body: JObject (required)
  var body_604686 = newJObject()
  if body != nil:
    body_604686 = body
  result = call_604685.call(nil, nil, nil, nil, body_604686)

var terminateSession* = Call_TerminateSession_604672(name: "terminateSession",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.TerminateSession",
    validator: validate_TerminateSession_604673, base: "/",
    url: url_TerminateSession_604674, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAssociation_604687 = ref object of OpenApiRestCall_602433
proc url_UpdateAssociation_604689(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateAssociation_604688(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Updates an association. You can update the association name and version, the document version, schedule, parameters, and Amazon S3 output.</p> <important> <p>When you update an association, the association immediately runs against the specified targets.</p> </important>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604690 = header.getOrDefault("X-Amz-Date")
  valid_604690 = validateParameter(valid_604690, JString, required = false,
                                 default = nil)
  if valid_604690 != nil:
    section.add "X-Amz-Date", valid_604690
  var valid_604691 = header.getOrDefault("X-Amz-Security-Token")
  valid_604691 = validateParameter(valid_604691, JString, required = false,
                                 default = nil)
  if valid_604691 != nil:
    section.add "X-Amz-Security-Token", valid_604691
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604692 = header.getOrDefault("X-Amz-Target")
  valid_604692 = validateParameter(valid_604692, JString, required = true, default = newJString(
      "AmazonSSM.UpdateAssociation"))
  if valid_604692 != nil:
    section.add "X-Amz-Target", valid_604692
  var valid_604693 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604693 = validateParameter(valid_604693, JString, required = false,
                                 default = nil)
  if valid_604693 != nil:
    section.add "X-Amz-Content-Sha256", valid_604693
  var valid_604694 = header.getOrDefault("X-Amz-Algorithm")
  valid_604694 = validateParameter(valid_604694, JString, required = false,
                                 default = nil)
  if valid_604694 != nil:
    section.add "X-Amz-Algorithm", valid_604694
  var valid_604695 = header.getOrDefault("X-Amz-Signature")
  valid_604695 = validateParameter(valid_604695, JString, required = false,
                                 default = nil)
  if valid_604695 != nil:
    section.add "X-Amz-Signature", valid_604695
  var valid_604696 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604696 = validateParameter(valid_604696, JString, required = false,
                                 default = nil)
  if valid_604696 != nil:
    section.add "X-Amz-SignedHeaders", valid_604696
  var valid_604697 = header.getOrDefault("X-Amz-Credential")
  valid_604697 = validateParameter(valid_604697, JString, required = false,
                                 default = nil)
  if valid_604697 != nil:
    section.add "X-Amz-Credential", valid_604697
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604699: Call_UpdateAssociation_604687; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an association. You can update the association name and version, the document version, schedule, parameters, and Amazon S3 output.</p> <important> <p>When you update an association, the association immediately runs against the specified targets.</p> </important>
  ## 
  let valid = call_604699.validator(path, query, header, formData, body)
  let scheme = call_604699.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604699.url(scheme.get, call_604699.host, call_604699.base,
                         call_604699.route, valid.getOrDefault("path"))
  result = hook(call_604699, url, valid)

proc call*(call_604700: Call_UpdateAssociation_604687; body: JsonNode): Recallable =
  ## updateAssociation
  ## <p>Updates an association. You can update the association name and version, the document version, schedule, parameters, and Amazon S3 output.</p> <important> <p>When you update an association, the association immediately runs against the specified targets.</p> </important>
  ##   body: JObject (required)
  var body_604701 = newJObject()
  if body != nil:
    body_604701 = body
  result = call_604700.call(nil, nil, nil, nil, body_604701)

var updateAssociation* = Call_UpdateAssociation_604687(name: "updateAssociation",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateAssociation",
    validator: validate_UpdateAssociation_604688, base: "/",
    url: url_UpdateAssociation_604689, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAssociationStatus_604702 = ref object of OpenApiRestCall_602433
proc url_UpdateAssociationStatus_604704(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateAssociationStatus_604703(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604705 = header.getOrDefault("X-Amz-Date")
  valid_604705 = validateParameter(valid_604705, JString, required = false,
                                 default = nil)
  if valid_604705 != nil:
    section.add "X-Amz-Date", valid_604705
  var valid_604706 = header.getOrDefault("X-Amz-Security-Token")
  valid_604706 = validateParameter(valid_604706, JString, required = false,
                                 default = nil)
  if valid_604706 != nil:
    section.add "X-Amz-Security-Token", valid_604706
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604707 = header.getOrDefault("X-Amz-Target")
  valid_604707 = validateParameter(valid_604707, JString, required = true, default = newJString(
      "AmazonSSM.UpdateAssociationStatus"))
  if valid_604707 != nil:
    section.add "X-Amz-Target", valid_604707
  var valid_604708 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604708 = validateParameter(valid_604708, JString, required = false,
                                 default = nil)
  if valid_604708 != nil:
    section.add "X-Amz-Content-Sha256", valid_604708
  var valid_604709 = header.getOrDefault("X-Amz-Algorithm")
  valid_604709 = validateParameter(valid_604709, JString, required = false,
                                 default = nil)
  if valid_604709 != nil:
    section.add "X-Amz-Algorithm", valid_604709
  var valid_604710 = header.getOrDefault("X-Amz-Signature")
  valid_604710 = validateParameter(valid_604710, JString, required = false,
                                 default = nil)
  if valid_604710 != nil:
    section.add "X-Amz-Signature", valid_604710
  var valid_604711 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604711 = validateParameter(valid_604711, JString, required = false,
                                 default = nil)
  if valid_604711 != nil:
    section.add "X-Amz-SignedHeaders", valid_604711
  var valid_604712 = header.getOrDefault("X-Amz-Credential")
  valid_604712 = validateParameter(valid_604712, JString, required = false,
                                 default = nil)
  if valid_604712 != nil:
    section.add "X-Amz-Credential", valid_604712
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604714: Call_UpdateAssociationStatus_604702; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the status of the Systems Manager document associated with the specified instance.
  ## 
  let valid = call_604714.validator(path, query, header, formData, body)
  let scheme = call_604714.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604714.url(scheme.get, call_604714.host, call_604714.base,
                         call_604714.route, valid.getOrDefault("path"))
  result = hook(call_604714, url, valid)

proc call*(call_604715: Call_UpdateAssociationStatus_604702; body: JsonNode): Recallable =
  ## updateAssociationStatus
  ## Updates the status of the Systems Manager document associated with the specified instance.
  ##   body: JObject (required)
  var body_604716 = newJObject()
  if body != nil:
    body_604716 = body
  result = call_604715.call(nil, nil, nil, nil, body_604716)

var updateAssociationStatus* = Call_UpdateAssociationStatus_604702(
    name: "updateAssociationStatus", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateAssociationStatus",
    validator: validate_UpdateAssociationStatus_604703, base: "/",
    url: url_UpdateAssociationStatus_604704, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocument_604717 = ref object of OpenApiRestCall_602433
proc url_UpdateDocument_604719(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateDocument_604718(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604720 = header.getOrDefault("X-Amz-Date")
  valid_604720 = validateParameter(valid_604720, JString, required = false,
                                 default = nil)
  if valid_604720 != nil:
    section.add "X-Amz-Date", valid_604720
  var valid_604721 = header.getOrDefault("X-Amz-Security-Token")
  valid_604721 = validateParameter(valid_604721, JString, required = false,
                                 default = nil)
  if valid_604721 != nil:
    section.add "X-Amz-Security-Token", valid_604721
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604722 = header.getOrDefault("X-Amz-Target")
  valid_604722 = validateParameter(valid_604722, JString, required = true, default = newJString(
      "AmazonSSM.UpdateDocument"))
  if valid_604722 != nil:
    section.add "X-Amz-Target", valid_604722
  var valid_604723 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604723 = validateParameter(valid_604723, JString, required = false,
                                 default = nil)
  if valid_604723 != nil:
    section.add "X-Amz-Content-Sha256", valid_604723
  var valid_604724 = header.getOrDefault("X-Amz-Algorithm")
  valid_604724 = validateParameter(valid_604724, JString, required = false,
                                 default = nil)
  if valid_604724 != nil:
    section.add "X-Amz-Algorithm", valid_604724
  var valid_604725 = header.getOrDefault("X-Amz-Signature")
  valid_604725 = validateParameter(valid_604725, JString, required = false,
                                 default = nil)
  if valid_604725 != nil:
    section.add "X-Amz-Signature", valid_604725
  var valid_604726 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604726 = validateParameter(valid_604726, JString, required = false,
                                 default = nil)
  if valid_604726 != nil:
    section.add "X-Amz-SignedHeaders", valid_604726
  var valid_604727 = header.getOrDefault("X-Amz-Credential")
  valid_604727 = validateParameter(valid_604727, JString, required = false,
                                 default = nil)
  if valid_604727 != nil:
    section.add "X-Amz-Credential", valid_604727
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604729: Call_UpdateDocument_604717; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates one or more values for an SSM document.
  ## 
  let valid = call_604729.validator(path, query, header, formData, body)
  let scheme = call_604729.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604729.url(scheme.get, call_604729.host, call_604729.base,
                         call_604729.route, valid.getOrDefault("path"))
  result = hook(call_604729, url, valid)

proc call*(call_604730: Call_UpdateDocument_604717; body: JsonNode): Recallable =
  ## updateDocument
  ## Updates one or more values for an SSM document.
  ##   body: JObject (required)
  var body_604731 = newJObject()
  if body != nil:
    body_604731 = body
  result = call_604730.call(nil, nil, nil, nil, body_604731)

var updateDocument* = Call_UpdateDocument_604717(name: "updateDocument",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateDocument",
    validator: validate_UpdateDocument_604718, base: "/", url: url_UpdateDocument_604719,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocumentDefaultVersion_604732 = ref object of OpenApiRestCall_602433
proc url_UpdateDocumentDefaultVersion_604734(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateDocumentDefaultVersion_604733(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604735 = header.getOrDefault("X-Amz-Date")
  valid_604735 = validateParameter(valid_604735, JString, required = false,
                                 default = nil)
  if valid_604735 != nil:
    section.add "X-Amz-Date", valid_604735
  var valid_604736 = header.getOrDefault("X-Amz-Security-Token")
  valid_604736 = validateParameter(valid_604736, JString, required = false,
                                 default = nil)
  if valid_604736 != nil:
    section.add "X-Amz-Security-Token", valid_604736
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604737 = header.getOrDefault("X-Amz-Target")
  valid_604737 = validateParameter(valid_604737, JString, required = true, default = newJString(
      "AmazonSSM.UpdateDocumentDefaultVersion"))
  if valid_604737 != nil:
    section.add "X-Amz-Target", valid_604737
  var valid_604738 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604738 = validateParameter(valid_604738, JString, required = false,
                                 default = nil)
  if valid_604738 != nil:
    section.add "X-Amz-Content-Sha256", valid_604738
  var valid_604739 = header.getOrDefault("X-Amz-Algorithm")
  valid_604739 = validateParameter(valid_604739, JString, required = false,
                                 default = nil)
  if valid_604739 != nil:
    section.add "X-Amz-Algorithm", valid_604739
  var valid_604740 = header.getOrDefault("X-Amz-Signature")
  valid_604740 = validateParameter(valid_604740, JString, required = false,
                                 default = nil)
  if valid_604740 != nil:
    section.add "X-Amz-Signature", valid_604740
  var valid_604741 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604741 = validateParameter(valid_604741, JString, required = false,
                                 default = nil)
  if valid_604741 != nil:
    section.add "X-Amz-SignedHeaders", valid_604741
  var valid_604742 = header.getOrDefault("X-Amz-Credential")
  valid_604742 = validateParameter(valid_604742, JString, required = false,
                                 default = nil)
  if valid_604742 != nil:
    section.add "X-Amz-Credential", valid_604742
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604744: Call_UpdateDocumentDefaultVersion_604732; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Set the default version of a document. 
  ## 
  let valid = call_604744.validator(path, query, header, formData, body)
  let scheme = call_604744.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604744.url(scheme.get, call_604744.host, call_604744.base,
                         call_604744.route, valid.getOrDefault("path"))
  result = hook(call_604744, url, valid)

proc call*(call_604745: Call_UpdateDocumentDefaultVersion_604732; body: JsonNode): Recallable =
  ## updateDocumentDefaultVersion
  ## Set the default version of a document. 
  ##   body: JObject (required)
  var body_604746 = newJObject()
  if body != nil:
    body_604746 = body
  result = call_604745.call(nil, nil, nil, nil, body_604746)

var updateDocumentDefaultVersion* = Call_UpdateDocumentDefaultVersion_604732(
    name: "updateDocumentDefaultVersion", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateDocumentDefaultVersion",
    validator: validate_UpdateDocumentDefaultVersion_604733, base: "/",
    url: url_UpdateDocumentDefaultVersion_604734,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMaintenanceWindow_604747 = ref object of OpenApiRestCall_602433
proc url_UpdateMaintenanceWindow_604749(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateMaintenanceWindow_604748(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an existing maintenance window. Only specified parameters are modified.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604750 = header.getOrDefault("X-Amz-Date")
  valid_604750 = validateParameter(valid_604750, JString, required = false,
                                 default = nil)
  if valid_604750 != nil:
    section.add "X-Amz-Date", valid_604750
  var valid_604751 = header.getOrDefault("X-Amz-Security-Token")
  valid_604751 = validateParameter(valid_604751, JString, required = false,
                                 default = nil)
  if valid_604751 != nil:
    section.add "X-Amz-Security-Token", valid_604751
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604752 = header.getOrDefault("X-Amz-Target")
  valid_604752 = validateParameter(valid_604752, JString, required = true, default = newJString(
      "AmazonSSM.UpdateMaintenanceWindow"))
  if valid_604752 != nil:
    section.add "X-Amz-Target", valid_604752
  var valid_604753 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604753 = validateParameter(valid_604753, JString, required = false,
                                 default = nil)
  if valid_604753 != nil:
    section.add "X-Amz-Content-Sha256", valid_604753
  var valid_604754 = header.getOrDefault("X-Amz-Algorithm")
  valid_604754 = validateParameter(valid_604754, JString, required = false,
                                 default = nil)
  if valid_604754 != nil:
    section.add "X-Amz-Algorithm", valid_604754
  var valid_604755 = header.getOrDefault("X-Amz-Signature")
  valid_604755 = validateParameter(valid_604755, JString, required = false,
                                 default = nil)
  if valid_604755 != nil:
    section.add "X-Amz-Signature", valid_604755
  var valid_604756 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604756 = validateParameter(valid_604756, JString, required = false,
                                 default = nil)
  if valid_604756 != nil:
    section.add "X-Amz-SignedHeaders", valid_604756
  var valid_604757 = header.getOrDefault("X-Amz-Credential")
  valid_604757 = validateParameter(valid_604757, JString, required = false,
                                 default = nil)
  if valid_604757 != nil:
    section.add "X-Amz-Credential", valid_604757
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604759: Call_UpdateMaintenanceWindow_604747; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing maintenance window. Only specified parameters are modified.
  ## 
  let valid = call_604759.validator(path, query, header, formData, body)
  let scheme = call_604759.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604759.url(scheme.get, call_604759.host, call_604759.base,
                         call_604759.route, valid.getOrDefault("path"))
  result = hook(call_604759, url, valid)

proc call*(call_604760: Call_UpdateMaintenanceWindow_604747; body: JsonNode): Recallable =
  ## updateMaintenanceWindow
  ## Updates an existing maintenance window. Only specified parameters are modified.
  ##   body: JObject (required)
  var body_604761 = newJObject()
  if body != nil:
    body_604761 = body
  result = call_604760.call(nil, nil, nil, nil, body_604761)

var updateMaintenanceWindow* = Call_UpdateMaintenanceWindow_604747(
    name: "updateMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateMaintenanceWindow",
    validator: validate_UpdateMaintenanceWindow_604748, base: "/",
    url: url_UpdateMaintenanceWindow_604749, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMaintenanceWindowTarget_604762 = ref object of OpenApiRestCall_602433
proc url_UpdateMaintenanceWindowTarget_604764(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateMaintenanceWindowTarget_604763(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604765 = header.getOrDefault("X-Amz-Date")
  valid_604765 = validateParameter(valid_604765, JString, required = false,
                                 default = nil)
  if valid_604765 != nil:
    section.add "X-Amz-Date", valid_604765
  var valid_604766 = header.getOrDefault("X-Amz-Security-Token")
  valid_604766 = validateParameter(valid_604766, JString, required = false,
                                 default = nil)
  if valid_604766 != nil:
    section.add "X-Amz-Security-Token", valid_604766
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604767 = header.getOrDefault("X-Amz-Target")
  valid_604767 = validateParameter(valid_604767, JString, required = true, default = newJString(
      "AmazonSSM.UpdateMaintenanceWindowTarget"))
  if valid_604767 != nil:
    section.add "X-Amz-Target", valid_604767
  var valid_604768 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604768 = validateParameter(valid_604768, JString, required = false,
                                 default = nil)
  if valid_604768 != nil:
    section.add "X-Amz-Content-Sha256", valid_604768
  var valid_604769 = header.getOrDefault("X-Amz-Algorithm")
  valid_604769 = validateParameter(valid_604769, JString, required = false,
                                 default = nil)
  if valid_604769 != nil:
    section.add "X-Amz-Algorithm", valid_604769
  var valid_604770 = header.getOrDefault("X-Amz-Signature")
  valid_604770 = validateParameter(valid_604770, JString, required = false,
                                 default = nil)
  if valid_604770 != nil:
    section.add "X-Amz-Signature", valid_604770
  var valid_604771 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604771 = validateParameter(valid_604771, JString, required = false,
                                 default = nil)
  if valid_604771 != nil:
    section.add "X-Amz-SignedHeaders", valid_604771
  var valid_604772 = header.getOrDefault("X-Amz-Credential")
  valid_604772 = validateParameter(valid_604772, JString, required = false,
                                 default = nil)
  if valid_604772 != nil:
    section.add "X-Amz-Credential", valid_604772
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604774: Call_UpdateMaintenanceWindowTarget_604762; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the target of an existing maintenance window. You can change the following:</p> <ul> <li> <p>Name</p> </li> <li> <p>Description</p> </li> <li> <p>Owner</p> </li> <li> <p>IDs for an ID target</p> </li> <li> <p>Tags for a Tag target</p> </li> <li> <p>From any supported tag type to another. The three supported tag types are ID target, Tag target, and resource group. For more information, see <a>Target</a>.</p> </li> </ul> <note> <p>If a parameter is null, then the corresponding field is not modified.</p> </note>
  ## 
  let valid = call_604774.validator(path, query, header, formData, body)
  let scheme = call_604774.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604774.url(scheme.get, call_604774.host, call_604774.base,
                         call_604774.route, valid.getOrDefault("path"))
  result = hook(call_604774, url, valid)

proc call*(call_604775: Call_UpdateMaintenanceWindowTarget_604762; body: JsonNode): Recallable =
  ## updateMaintenanceWindowTarget
  ## <p>Modifies the target of an existing maintenance window. You can change the following:</p> <ul> <li> <p>Name</p> </li> <li> <p>Description</p> </li> <li> <p>Owner</p> </li> <li> <p>IDs for an ID target</p> </li> <li> <p>Tags for a Tag target</p> </li> <li> <p>From any supported tag type to another. The three supported tag types are ID target, Tag target, and resource group. For more information, see <a>Target</a>.</p> </li> </ul> <note> <p>If a parameter is null, then the corresponding field is not modified.</p> </note>
  ##   body: JObject (required)
  var body_604776 = newJObject()
  if body != nil:
    body_604776 = body
  result = call_604775.call(nil, nil, nil, nil, body_604776)

var updateMaintenanceWindowTarget* = Call_UpdateMaintenanceWindowTarget_604762(
    name: "updateMaintenanceWindowTarget", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateMaintenanceWindowTarget",
    validator: validate_UpdateMaintenanceWindowTarget_604763, base: "/",
    url: url_UpdateMaintenanceWindowTarget_604764,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMaintenanceWindowTask_604777 = ref object of OpenApiRestCall_602433
proc url_UpdateMaintenanceWindowTask_604779(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateMaintenanceWindowTask_604778(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604780 = header.getOrDefault("X-Amz-Date")
  valid_604780 = validateParameter(valid_604780, JString, required = false,
                                 default = nil)
  if valid_604780 != nil:
    section.add "X-Amz-Date", valid_604780
  var valid_604781 = header.getOrDefault("X-Amz-Security-Token")
  valid_604781 = validateParameter(valid_604781, JString, required = false,
                                 default = nil)
  if valid_604781 != nil:
    section.add "X-Amz-Security-Token", valid_604781
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604782 = header.getOrDefault("X-Amz-Target")
  valid_604782 = validateParameter(valid_604782, JString, required = true, default = newJString(
      "AmazonSSM.UpdateMaintenanceWindowTask"))
  if valid_604782 != nil:
    section.add "X-Amz-Target", valid_604782
  var valid_604783 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604783 = validateParameter(valid_604783, JString, required = false,
                                 default = nil)
  if valid_604783 != nil:
    section.add "X-Amz-Content-Sha256", valid_604783
  var valid_604784 = header.getOrDefault("X-Amz-Algorithm")
  valid_604784 = validateParameter(valid_604784, JString, required = false,
                                 default = nil)
  if valid_604784 != nil:
    section.add "X-Amz-Algorithm", valid_604784
  var valid_604785 = header.getOrDefault("X-Amz-Signature")
  valid_604785 = validateParameter(valid_604785, JString, required = false,
                                 default = nil)
  if valid_604785 != nil:
    section.add "X-Amz-Signature", valid_604785
  var valid_604786 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604786 = validateParameter(valid_604786, JString, required = false,
                                 default = nil)
  if valid_604786 != nil:
    section.add "X-Amz-SignedHeaders", valid_604786
  var valid_604787 = header.getOrDefault("X-Amz-Credential")
  valid_604787 = validateParameter(valid_604787, JString, required = false,
                                 default = nil)
  if valid_604787 != nil:
    section.add "X-Amz-Credential", valid_604787
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604789: Call_UpdateMaintenanceWindowTask_604777; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies a task assigned to a maintenance window. You can't change the task type, but you can change the following values:</p> <ul> <li> <p>TaskARN. For example, you can change a RUN_COMMAND task from AWS-RunPowerShellScript to AWS-RunShellScript.</p> </li> <li> <p>ServiceRoleArn</p> </li> <li> <p>TaskInvocationParameters</p> </li> <li> <p>Priority</p> </li> <li> <p>MaxConcurrency</p> </li> <li> <p>MaxErrors</p> </li> </ul> <p>If a parameter is null, then the corresponding field is not modified. Also, if you set Replace to true, then all fields required by the <a>RegisterTaskWithMaintenanceWindow</a> action are required for this request. Optional fields that aren't specified are set to null.</p>
  ## 
  let valid = call_604789.validator(path, query, header, formData, body)
  let scheme = call_604789.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604789.url(scheme.get, call_604789.host, call_604789.base,
                         call_604789.route, valid.getOrDefault("path"))
  result = hook(call_604789, url, valid)

proc call*(call_604790: Call_UpdateMaintenanceWindowTask_604777; body: JsonNode): Recallable =
  ## updateMaintenanceWindowTask
  ## <p>Modifies a task assigned to a maintenance window. You can't change the task type, but you can change the following values:</p> <ul> <li> <p>TaskARN. For example, you can change a RUN_COMMAND task from AWS-RunPowerShellScript to AWS-RunShellScript.</p> </li> <li> <p>ServiceRoleArn</p> </li> <li> <p>TaskInvocationParameters</p> </li> <li> <p>Priority</p> </li> <li> <p>MaxConcurrency</p> </li> <li> <p>MaxErrors</p> </li> </ul> <p>If a parameter is null, then the corresponding field is not modified. Also, if you set Replace to true, then all fields required by the <a>RegisterTaskWithMaintenanceWindow</a> action are required for this request. Optional fields that aren't specified are set to null.</p>
  ##   body: JObject (required)
  var body_604791 = newJObject()
  if body != nil:
    body_604791 = body
  result = call_604790.call(nil, nil, nil, nil, body_604791)

var updateMaintenanceWindowTask* = Call_UpdateMaintenanceWindowTask_604777(
    name: "updateMaintenanceWindowTask", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateMaintenanceWindowTask",
    validator: validate_UpdateMaintenanceWindowTask_604778, base: "/",
    url: url_UpdateMaintenanceWindowTask_604779,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateManagedInstanceRole_604792 = ref object of OpenApiRestCall_602433
proc url_UpdateManagedInstanceRole_604794(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateManagedInstanceRole_604793(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604795 = header.getOrDefault("X-Amz-Date")
  valid_604795 = validateParameter(valid_604795, JString, required = false,
                                 default = nil)
  if valid_604795 != nil:
    section.add "X-Amz-Date", valid_604795
  var valid_604796 = header.getOrDefault("X-Amz-Security-Token")
  valid_604796 = validateParameter(valid_604796, JString, required = false,
                                 default = nil)
  if valid_604796 != nil:
    section.add "X-Amz-Security-Token", valid_604796
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604797 = header.getOrDefault("X-Amz-Target")
  valid_604797 = validateParameter(valid_604797, JString, required = true, default = newJString(
      "AmazonSSM.UpdateManagedInstanceRole"))
  if valid_604797 != nil:
    section.add "X-Amz-Target", valid_604797
  var valid_604798 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604798 = validateParameter(valid_604798, JString, required = false,
                                 default = nil)
  if valid_604798 != nil:
    section.add "X-Amz-Content-Sha256", valid_604798
  var valid_604799 = header.getOrDefault("X-Amz-Algorithm")
  valid_604799 = validateParameter(valid_604799, JString, required = false,
                                 default = nil)
  if valid_604799 != nil:
    section.add "X-Amz-Algorithm", valid_604799
  var valid_604800 = header.getOrDefault("X-Amz-Signature")
  valid_604800 = validateParameter(valid_604800, JString, required = false,
                                 default = nil)
  if valid_604800 != nil:
    section.add "X-Amz-Signature", valid_604800
  var valid_604801 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604801 = validateParameter(valid_604801, JString, required = false,
                                 default = nil)
  if valid_604801 != nil:
    section.add "X-Amz-SignedHeaders", valid_604801
  var valid_604802 = header.getOrDefault("X-Amz-Credential")
  valid_604802 = validateParameter(valid_604802, JString, required = false,
                                 default = nil)
  if valid_604802 != nil:
    section.add "X-Amz-Credential", valid_604802
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604804: Call_UpdateManagedInstanceRole_604792; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Assigns or changes an Amazon Identity and Access Management (IAM) role for the managed instance.
  ## 
  let valid = call_604804.validator(path, query, header, formData, body)
  let scheme = call_604804.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604804.url(scheme.get, call_604804.host, call_604804.base,
                         call_604804.route, valid.getOrDefault("path"))
  result = hook(call_604804, url, valid)

proc call*(call_604805: Call_UpdateManagedInstanceRole_604792; body: JsonNode): Recallable =
  ## updateManagedInstanceRole
  ## Assigns or changes an Amazon Identity and Access Management (IAM) role for the managed instance.
  ##   body: JObject (required)
  var body_604806 = newJObject()
  if body != nil:
    body_604806 = body
  result = call_604805.call(nil, nil, nil, nil, body_604806)

var updateManagedInstanceRole* = Call_UpdateManagedInstanceRole_604792(
    name: "updateManagedInstanceRole", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateManagedInstanceRole",
    validator: validate_UpdateManagedInstanceRole_604793, base: "/",
    url: url_UpdateManagedInstanceRole_604794,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateOpsItem_604807 = ref object of OpenApiRestCall_602433
proc url_UpdateOpsItem_604809(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateOpsItem_604808(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604810 = header.getOrDefault("X-Amz-Date")
  valid_604810 = validateParameter(valid_604810, JString, required = false,
                                 default = nil)
  if valid_604810 != nil:
    section.add "X-Amz-Date", valid_604810
  var valid_604811 = header.getOrDefault("X-Amz-Security-Token")
  valid_604811 = validateParameter(valid_604811, JString, required = false,
                                 default = nil)
  if valid_604811 != nil:
    section.add "X-Amz-Security-Token", valid_604811
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604812 = header.getOrDefault("X-Amz-Target")
  valid_604812 = validateParameter(valid_604812, JString, required = true, default = newJString(
      "AmazonSSM.UpdateOpsItem"))
  if valid_604812 != nil:
    section.add "X-Amz-Target", valid_604812
  var valid_604813 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604813 = validateParameter(valid_604813, JString, required = false,
                                 default = nil)
  if valid_604813 != nil:
    section.add "X-Amz-Content-Sha256", valid_604813
  var valid_604814 = header.getOrDefault("X-Amz-Algorithm")
  valid_604814 = validateParameter(valid_604814, JString, required = false,
                                 default = nil)
  if valid_604814 != nil:
    section.add "X-Amz-Algorithm", valid_604814
  var valid_604815 = header.getOrDefault("X-Amz-Signature")
  valid_604815 = validateParameter(valid_604815, JString, required = false,
                                 default = nil)
  if valid_604815 != nil:
    section.add "X-Amz-Signature", valid_604815
  var valid_604816 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604816 = validateParameter(valid_604816, JString, required = false,
                                 default = nil)
  if valid_604816 != nil:
    section.add "X-Amz-SignedHeaders", valid_604816
  var valid_604817 = header.getOrDefault("X-Amz-Credential")
  valid_604817 = validateParameter(valid_604817, JString, required = false,
                                 default = nil)
  if valid_604817 != nil:
    section.add "X-Amz-Credential", valid_604817
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604819: Call_UpdateOpsItem_604807; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Edit or change an OpsItem. You must have permission in AWS Identity and Access Management (IAM) to update an OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ## 
  let valid = call_604819.validator(path, query, header, formData, body)
  let scheme = call_604819.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604819.url(scheme.get, call_604819.host, call_604819.base,
                         call_604819.route, valid.getOrDefault("path"))
  result = hook(call_604819, url, valid)

proc call*(call_604820: Call_UpdateOpsItem_604807; body: JsonNode): Recallable =
  ## updateOpsItem
  ## <p>Edit or change an OpsItem. You must have permission in AWS Identity and Access Management (IAM) to update an OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ##   body: JObject (required)
  var body_604821 = newJObject()
  if body != nil:
    body_604821 = body
  result = call_604820.call(nil, nil, nil, nil, body_604821)

var updateOpsItem* = Call_UpdateOpsItem_604807(name: "updateOpsItem",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateOpsItem",
    validator: validate_UpdateOpsItem_604808, base: "/", url: url_UpdateOpsItem_604809,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePatchBaseline_604822 = ref object of OpenApiRestCall_602433
proc url_UpdatePatchBaseline_604824(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdatePatchBaseline_604823(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604825 = header.getOrDefault("X-Amz-Date")
  valid_604825 = validateParameter(valid_604825, JString, required = false,
                                 default = nil)
  if valid_604825 != nil:
    section.add "X-Amz-Date", valid_604825
  var valid_604826 = header.getOrDefault("X-Amz-Security-Token")
  valid_604826 = validateParameter(valid_604826, JString, required = false,
                                 default = nil)
  if valid_604826 != nil:
    section.add "X-Amz-Security-Token", valid_604826
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604827 = header.getOrDefault("X-Amz-Target")
  valid_604827 = validateParameter(valid_604827, JString, required = true, default = newJString(
      "AmazonSSM.UpdatePatchBaseline"))
  if valid_604827 != nil:
    section.add "X-Amz-Target", valid_604827
  var valid_604828 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604828 = validateParameter(valid_604828, JString, required = false,
                                 default = nil)
  if valid_604828 != nil:
    section.add "X-Amz-Content-Sha256", valid_604828
  var valid_604829 = header.getOrDefault("X-Amz-Algorithm")
  valid_604829 = validateParameter(valid_604829, JString, required = false,
                                 default = nil)
  if valid_604829 != nil:
    section.add "X-Amz-Algorithm", valid_604829
  var valid_604830 = header.getOrDefault("X-Amz-Signature")
  valid_604830 = validateParameter(valid_604830, JString, required = false,
                                 default = nil)
  if valid_604830 != nil:
    section.add "X-Amz-Signature", valid_604830
  var valid_604831 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604831 = validateParameter(valid_604831, JString, required = false,
                                 default = nil)
  if valid_604831 != nil:
    section.add "X-Amz-SignedHeaders", valid_604831
  var valid_604832 = header.getOrDefault("X-Amz-Credential")
  valid_604832 = validateParameter(valid_604832, JString, required = false,
                                 default = nil)
  if valid_604832 != nil:
    section.add "X-Amz-Credential", valid_604832
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604834: Call_UpdatePatchBaseline_604822; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies an existing patch baseline. Fields not specified in the request are left unchanged.</p> <note> <p>For information about valid key and value pairs in <code>PatchFilters</code> for each supported operating system type, see <a href="http://docs.aws.amazon.com/systems-manager/latest/APIReference/API_PatchFilter.html">PatchFilter</a>.</p> </note>
  ## 
  let valid = call_604834.validator(path, query, header, formData, body)
  let scheme = call_604834.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604834.url(scheme.get, call_604834.host, call_604834.base,
                         call_604834.route, valid.getOrDefault("path"))
  result = hook(call_604834, url, valid)

proc call*(call_604835: Call_UpdatePatchBaseline_604822; body: JsonNode): Recallable =
  ## updatePatchBaseline
  ## <p>Modifies an existing patch baseline. Fields not specified in the request are left unchanged.</p> <note> <p>For information about valid key and value pairs in <code>PatchFilters</code> for each supported operating system type, see <a href="http://docs.aws.amazon.com/systems-manager/latest/APIReference/API_PatchFilter.html">PatchFilter</a>.</p> </note>
  ##   body: JObject (required)
  var body_604836 = newJObject()
  if body != nil:
    body_604836 = body
  result = call_604835.call(nil, nil, nil, nil, body_604836)

var updatePatchBaseline* = Call_UpdatePatchBaseline_604822(
    name: "updatePatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdatePatchBaseline",
    validator: validate_UpdatePatchBaseline_604823, base: "/",
    url: url_UpdatePatchBaseline_604824, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateServiceSetting_604837 = ref object of OpenApiRestCall_602433
proc url_UpdateServiceSetting_604839(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateServiceSetting_604838(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604840 = header.getOrDefault("X-Amz-Date")
  valid_604840 = validateParameter(valid_604840, JString, required = false,
                                 default = nil)
  if valid_604840 != nil:
    section.add "X-Amz-Date", valid_604840
  var valid_604841 = header.getOrDefault("X-Amz-Security-Token")
  valid_604841 = validateParameter(valid_604841, JString, required = false,
                                 default = nil)
  if valid_604841 != nil:
    section.add "X-Amz-Security-Token", valid_604841
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604842 = header.getOrDefault("X-Amz-Target")
  valid_604842 = validateParameter(valid_604842, JString, required = true, default = newJString(
      "AmazonSSM.UpdateServiceSetting"))
  if valid_604842 != nil:
    section.add "X-Amz-Target", valid_604842
  var valid_604843 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604843 = validateParameter(valid_604843, JString, required = false,
                                 default = nil)
  if valid_604843 != nil:
    section.add "X-Amz-Content-Sha256", valid_604843
  var valid_604844 = header.getOrDefault("X-Amz-Algorithm")
  valid_604844 = validateParameter(valid_604844, JString, required = false,
                                 default = nil)
  if valid_604844 != nil:
    section.add "X-Amz-Algorithm", valid_604844
  var valid_604845 = header.getOrDefault("X-Amz-Signature")
  valid_604845 = validateParameter(valid_604845, JString, required = false,
                                 default = nil)
  if valid_604845 != nil:
    section.add "X-Amz-Signature", valid_604845
  var valid_604846 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604846 = validateParameter(valid_604846, JString, required = false,
                                 default = nil)
  if valid_604846 != nil:
    section.add "X-Amz-SignedHeaders", valid_604846
  var valid_604847 = header.getOrDefault("X-Amz-Credential")
  valid_604847 = validateParameter(valid_604847, JString, required = false,
                                 default = nil)
  if valid_604847 != nil:
    section.add "X-Amz-Credential", valid_604847
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604849: Call_UpdateServiceSetting_604837; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>GetServiceSetting</a> API action to view the current value. Or, use the <a>ResetServiceSetting</a> to change the value back to the original value defined by the AWS service team.</p> <p>Update the service setting for the account. </p>
  ## 
  let valid = call_604849.validator(path, query, header, formData, body)
  let scheme = call_604849.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604849.url(scheme.get, call_604849.host, call_604849.base,
                         call_604849.route, valid.getOrDefault("path"))
  result = hook(call_604849, url, valid)

proc call*(call_604850: Call_UpdateServiceSetting_604837; body: JsonNode): Recallable =
  ## updateServiceSetting
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>GetServiceSetting</a> API action to view the current value. Or, use the <a>ResetServiceSetting</a> to change the value back to the original value defined by the AWS service team.</p> <p>Update the service setting for the account. </p>
  ##   body: JObject (required)
  var body_604851 = newJObject()
  if body != nil:
    body_604851 = body
  result = call_604850.call(nil, nil, nil, nil, body_604851)

var updateServiceSetting* = Call_UpdateServiceSetting_604837(
    name: "updateServiceSetting", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateServiceSetting",
    validator: validate_UpdateServiceSetting_604838, base: "/",
    url: url_UpdateServiceSetting_604839, schemes: {Scheme.Https, Scheme.Http})
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

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
