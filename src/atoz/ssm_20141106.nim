
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

  OpenApiRestCall_772597 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_772597](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_772597): Option[Scheme] {.used.} =
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
  result = some(head & remainder.get())

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
  Call_AddTagsToResource_772933 = ref object of OpenApiRestCall_772597
proc url_AddTagsToResource_772935(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AddTagsToResource_772934(path: JsonNode; query: JsonNode;
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
  var valid_773047 = header.getOrDefault("X-Amz-Date")
  valid_773047 = validateParameter(valid_773047, JString, required = false,
                                 default = nil)
  if valid_773047 != nil:
    section.add "X-Amz-Date", valid_773047
  var valid_773048 = header.getOrDefault("X-Amz-Security-Token")
  valid_773048 = validateParameter(valid_773048, JString, required = false,
                                 default = nil)
  if valid_773048 != nil:
    section.add "X-Amz-Security-Token", valid_773048
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773062 = header.getOrDefault("X-Amz-Target")
  valid_773062 = validateParameter(valid_773062, JString, required = true, default = newJString(
      "AmazonSSM.AddTagsToResource"))
  if valid_773062 != nil:
    section.add "X-Amz-Target", valid_773062
  var valid_773063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773063 = validateParameter(valid_773063, JString, required = false,
                                 default = nil)
  if valid_773063 != nil:
    section.add "X-Amz-Content-Sha256", valid_773063
  var valid_773064 = header.getOrDefault("X-Amz-Algorithm")
  valid_773064 = validateParameter(valid_773064, JString, required = false,
                                 default = nil)
  if valid_773064 != nil:
    section.add "X-Amz-Algorithm", valid_773064
  var valid_773065 = header.getOrDefault("X-Amz-Signature")
  valid_773065 = validateParameter(valid_773065, JString, required = false,
                                 default = nil)
  if valid_773065 != nil:
    section.add "X-Amz-Signature", valid_773065
  var valid_773066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773066 = validateParameter(valid_773066, JString, required = false,
                                 default = nil)
  if valid_773066 != nil:
    section.add "X-Amz-SignedHeaders", valid_773066
  var valid_773067 = header.getOrDefault("X-Amz-Credential")
  valid_773067 = validateParameter(valid_773067, JString, required = false,
                                 default = nil)
  if valid_773067 != nil:
    section.add "X-Amz-Credential", valid_773067
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773091: Call_AddTagsToResource_772933; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds or overwrites one or more tags for the specified resource. Tags are metadata that you can assign to your documents, managed instances, maintenance windows, Parameter Store parameters, and patch baselines. Tags enable you to categorize your resources in different ways, for example, by purpose, owner, or environment. Each tag consists of a key and an optional value, both of which you define. For example, you could define a set of tags for your account's managed instances that helps you track each instance's owner and stack level. For example: Key=Owner and Value=DbAdmin, SysAdmin, or Dev. Or Key=Stack and Value=Production, Pre-Production, or Test.</p> <p>Each resource can have a maximum of 50 tags. </p> <p>We recommend that you devise a set of tag keys that meets your needs for each resource type. Using a consistent set of tag keys makes it easier for you to manage your resources. You can search and filter the resources based on the tags you add. Tags don't have any semantic meaning to Amazon EC2 and are interpreted strictly as a string of characters. </p> <p>For more information about tags, see <a href="http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Using_Tags.html">Tagging Your Amazon EC2 Resources</a> in the <i>Amazon EC2 User Guide</i>.</p>
  ## 
  let valid = call_773091.validator(path, query, header, formData, body)
  let scheme = call_773091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773091.url(scheme.get, call_773091.host, call_773091.base,
                         call_773091.route, valid.getOrDefault("path"))
  result = hook(call_773091, url, valid)

proc call*(call_773162: Call_AddTagsToResource_772933; body: JsonNode): Recallable =
  ## addTagsToResource
  ## <p>Adds or overwrites one or more tags for the specified resource. Tags are metadata that you can assign to your documents, managed instances, maintenance windows, Parameter Store parameters, and patch baselines. Tags enable you to categorize your resources in different ways, for example, by purpose, owner, or environment. Each tag consists of a key and an optional value, both of which you define. For example, you could define a set of tags for your account's managed instances that helps you track each instance's owner and stack level. For example: Key=Owner and Value=DbAdmin, SysAdmin, or Dev. Or Key=Stack and Value=Production, Pre-Production, or Test.</p> <p>Each resource can have a maximum of 50 tags. </p> <p>We recommend that you devise a set of tag keys that meets your needs for each resource type. Using a consistent set of tag keys makes it easier for you to manage your resources. You can search and filter the resources based on the tags you add. Tags don't have any semantic meaning to Amazon EC2 and are interpreted strictly as a string of characters. </p> <p>For more information about tags, see <a href="http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Using_Tags.html">Tagging Your Amazon EC2 Resources</a> in the <i>Amazon EC2 User Guide</i>.</p>
  ##   body: JObject (required)
  var body_773163 = newJObject()
  if body != nil:
    body_773163 = body
  result = call_773162.call(nil, nil, nil, nil, body_773163)

var addTagsToResource* = Call_AddTagsToResource_772933(name: "addTagsToResource",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.AddTagsToResource",
    validator: validate_AddTagsToResource_772934, base: "/",
    url: url_AddTagsToResource_772935, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelCommand_773202 = ref object of OpenApiRestCall_772597
proc url_CancelCommand_773204(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CancelCommand_773203(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773205 = header.getOrDefault("X-Amz-Date")
  valid_773205 = validateParameter(valid_773205, JString, required = false,
                                 default = nil)
  if valid_773205 != nil:
    section.add "X-Amz-Date", valid_773205
  var valid_773206 = header.getOrDefault("X-Amz-Security-Token")
  valid_773206 = validateParameter(valid_773206, JString, required = false,
                                 default = nil)
  if valid_773206 != nil:
    section.add "X-Amz-Security-Token", valid_773206
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773207 = header.getOrDefault("X-Amz-Target")
  valid_773207 = validateParameter(valid_773207, JString, required = true, default = newJString(
      "AmazonSSM.CancelCommand"))
  if valid_773207 != nil:
    section.add "X-Amz-Target", valid_773207
  var valid_773208 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773208 = validateParameter(valid_773208, JString, required = false,
                                 default = nil)
  if valid_773208 != nil:
    section.add "X-Amz-Content-Sha256", valid_773208
  var valid_773209 = header.getOrDefault("X-Amz-Algorithm")
  valid_773209 = validateParameter(valid_773209, JString, required = false,
                                 default = nil)
  if valid_773209 != nil:
    section.add "X-Amz-Algorithm", valid_773209
  var valid_773210 = header.getOrDefault("X-Amz-Signature")
  valid_773210 = validateParameter(valid_773210, JString, required = false,
                                 default = nil)
  if valid_773210 != nil:
    section.add "X-Amz-Signature", valid_773210
  var valid_773211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773211 = validateParameter(valid_773211, JString, required = false,
                                 default = nil)
  if valid_773211 != nil:
    section.add "X-Amz-SignedHeaders", valid_773211
  var valid_773212 = header.getOrDefault("X-Amz-Credential")
  valid_773212 = validateParameter(valid_773212, JString, required = false,
                                 default = nil)
  if valid_773212 != nil:
    section.add "X-Amz-Credential", valid_773212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773214: Call_CancelCommand_773202; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attempts to cancel the command specified by the Command ID. There is no guarantee that the command will be terminated and the underlying process stopped.
  ## 
  let valid = call_773214.validator(path, query, header, formData, body)
  let scheme = call_773214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773214.url(scheme.get, call_773214.host, call_773214.base,
                         call_773214.route, valid.getOrDefault("path"))
  result = hook(call_773214, url, valid)

proc call*(call_773215: Call_CancelCommand_773202; body: JsonNode): Recallable =
  ## cancelCommand
  ## Attempts to cancel the command specified by the Command ID. There is no guarantee that the command will be terminated and the underlying process stopped.
  ##   body: JObject (required)
  var body_773216 = newJObject()
  if body != nil:
    body_773216 = body
  result = call_773215.call(nil, nil, nil, nil, body_773216)

var cancelCommand* = Call_CancelCommand_773202(name: "cancelCommand",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CancelCommand",
    validator: validate_CancelCommand_773203, base: "/", url: url_CancelCommand_773204,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelMaintenanceWindowExecution_773217 = ref object of OpenApiRestCall_772597
proc url_CancelMaintenanceWindowExecution_773219(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CancelMaintenanceWindowExecution_773218(path: JsonNode;
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
  var valid_773220 = header.getOrDefault("X-Amz-Date")
  valid_773220 = validateParameter(valid_773220, JString, required = false,
                                 default = nil)
  if valid_773220 != nil:
    section.add "X-Amz-Date", valid_773220
  var valid_773221 = header.getOrDefault("X-Amz-Security-Token")
  valid_773221 = validateParameter(valid_773221, JString, required = false,
                                 default = nil)
  if valid_773221 != nil:
    section.add "X-Amz-Security-Token", valid_773221
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773222 = header.getOrDefault("X-Amz-Target")
  valid_773222 = validateParameter(valid_773222, JString, required = true, default = newJString(
      "AmazonSSM.CancelMaintenanceWindowExecution"))
  if valid_773222 != nil:
    section.add "X-Amz-Target", valid_773222
  var valid_773223 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773223 = validateParameter(valid_773223, JString, required = false,
                                 default = nil)
  if valid_773223 != nil:
    section.add "X-Amz-Content-Sha256", valid_773223
  var valid_773224 = header.getOrDefault("X-Amz-Algorithm")
  valid_773224 = validateParameter(valid_773224, JString, required = false,
                                 default = nil)
  if valid_773224 != nil:
    section.add "X-Amz-Algorithm", valid_773224
  var valid_773225 = header.getOrDefault("X-Amz-Signature")
  valid_773225 = validateParameter(valid_773225, JString, required = false,
                                 default = nil)
  if valid_773225 != nil:
    section.add "X-Amz-Signature", valid_773225
  var valid_773226 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773226 = validateParameter(valid_773226, JString, required = false,
                                 default = nil)
  if valid_773226 != nil:
    section.add "X-Amz-SignedHeaders", valid_773226
  var valid_773227 = header.getOrDefault("X-Amz-Credential")
  valid_773227 = validateParameter(valid_773227, JString, required = false,
                                 default = nil)
  if valid_773227 != nil:
    section.add "X-Amz-Credential", valid_773227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773229: Call_CancelMaintenanceWindowExecution_773217;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Stops a maintenance window execution that is already in progress and cancels any tasks in the window that have not already starting running. (Tasks already in progress will continue to completion.)
  ## 
  let valid = call_773229.validator(path, query, header, formData, body)
  let scheme = call_773229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773229.url(scheme.get, call_773229.host, call_773229.base,
                         call_773229.route, valid.getOrDefault("path"))
  result = hook(call_773229, url, valid)

proc call*(call_773230: Call_CancelMaintenanceWindowExecution_773217;
          body: JsonNode): Recallable =
  ## cancelMaintenanceWindowExecution
  ## Stops a maintenance window execution that is already in progress and cancels any tasks in the window that have not already starting running. (Tasks already in progress will continue to completion.)
  ##   body: JObject (required)
  var body_773231 = newJObject()
  if body != nil:
    body_773231 = body
  result = call_773230.call(nil, nil, nil, nil, body_773231)

var cancelMaintenanceWindowExecution* = Call_CancelMaintenanceWindowExecution_773217(
    name: "cancelMaintenanceWindowExecution", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CancelMaintenanceWindowExecution",
    validator: validate_CancelMaintenanceWindowExecution_773218, base: "/",
    url: url_CancelMaintenanceWindowExecution_773219,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateActivation_773232 = ref object of OpenApiRestCall_772597
proc url_CreateActivation_773234(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateActivation_773233(path: JsonNode; query: JsonNode;
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
  var valid_773235 = header.getOrDefault("X-Amz-Date")
  valid_773235 = validateParameter(valid_773235, JString, required = false,
                                 default = nil)
  if valid_773235 != nil:
    section.add "X-Amz-Date", valid_773235
  var valid_773236 = header.getOrDefault("X-Amz-Security-Token")
  valid_773236 = validateParameter(valid_773236, JString, required = false,
                                 default = nil)
  if valid_773236 != nil:
    section.add "X-Amz-Security-Token", valid_773236
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773237 = header.getOrDefault("X-Amz-Target")
  valid_773237 = validateParameter(valid_773237, JString, required = true, default = newJString(
      "AmazonSSM.CreateActivation"))
  if valid_773237 != nil:
    section.add "X-Amz-Target", valid_773237
  var valid_773238 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773238 = validateParameter(valid_773238, JString, required = false,
                                 default = nil)
  if valid_773238 != nil:
    section.add "X-Amz-Content-Sha256", valid_773238
  var valid_773239 = header.getOrDefault("X-Amz-Algorithm")
  valid_773239 = validateParameter(valid_773239, JString, required = false,
                                 default = nil)
  if valid_773239 != nil:
    section.add "X-Amz-Algorithm", valid_773239
  var valid_773240 = header.getOrDefault("X-Amz-Signature")
  valid_773240 = validateParameter(valid_773240, JString, required = false,
                                 default = nil)
  if valid_773240 != nil:
    section.add "X-Amz-Signature", valid_773240
  var valid_773241 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773241 = validateParameter(valid_773241, JString, required = false,
                                 default = nil)
  if valid_773241 != nil:
    section.add "X-Amz-SignedHeaders", valid_773241
  var valid_773242 = header.getOrDefault("X-Amz-Credential")
  valid_773242 = validateParameter(valid_773242, JString, required = false,
                                 default = nil)
  if valid_773242 != nil:
    section.add "X-Amz-Credential", valid_773242
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773244: Call_CreateActivation_773232; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Registers your on-premises server or virtual machine with Amazon EC2 so that you can manage these resources using Run Command. An on-premises server or virtual machine that has been registered with EC2 is called a managed instance. For more information about activations, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-managedinstances.html">Setting Up AWS Systems Manager for Hybrid Environments</a>.
  ## 
  let valid = call_773244.validator(path, query, header, formData, body)
  let scheme = call_773244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773244.url(scheme.get, call_773244.host, call_773244.base,
                         call_773244.route, valid.getOrDefault("path"))
  result = hook(call_773244, url, valid)

proc call*(call_773245: Call_CreateActivation_773232; body: JsonNode): Recallable =
  ## createActivation
  ## Registers your on-premises server or virtual machine with Amazon EC2 so that you can manage these resources using Run Command. An on-premises server or virtual machine that has been registered with EC2 is called a managed instance. For more information about activations, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-managedinstances.html">Setting Up AWS Systems Manager for Hybrid Environments</a>.
  ##   body: JObject (required)
  var body_773246 = newJObject()
  if body != nil:
    body_773246 = body
  result = call_773245.call(nil, nil, nil, nil, body_773246)

var createActivation* = Call_CreateActivation_773232(name: "createActivation",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateActivation",
    validator: validate_CreateActivation_773233, base: "/",
    url: url_CreateActivation_773234, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAssociation_773247 = ref object of OpenApiRestCall_772597
proc url_CreateAssociation_773249(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateAssociation_773248(path: JsonNode; query: JsonNode;
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
  var valid_773250 = header.getOrDefault("X-Amz-Date")
  valid_773250 = validateParameter(valid_773250, JString, required = false,
                                 default = nil)
  if valid_773250 != nil:
    section.add "X-Amz-Date", valid_773250
  var valid_773251 = header.getOrDefault("X-Amz-Security-Token")
  valid_773251 = validateParameter(valid_773251, JString, required = false,
                                 default = nil)
  if valid_773251 != nil:
    section.add "X-Amz-Security-Token", valid_773251
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773252 = header.getOrDefault("X-Amz-Target")
  valid_773252 = validateParameter(valid_773252, JString, required = true, default = newJString(
      "AmazonSSM.CreateAssociation"))
  if valid_773252 != nil:
    section.add "X-Amz-Target", valid_773252
  var valid_773253 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773253 = validateParameter(valid_773253, JString, required = false,
                                 default = nil)
  if valid_773253 != nil:
    section.add "X-Amz-Content-Sha256", valid_773253
  var valid_773254 = header.getOrDefault("X-Amz-Algorithm")
  valid_773254 = validateParameter(valid_773254, JString, required = false,
                                 default = nil)
  if valid_773254 != nil:
    section.add "X-Amz-Algorithm", valid_773254
  var valid_773255 = header.getOrDefault("X-Amz-Signature")
  valid_773255 = validateParameter(valid_773255, JString, required = false,
                                 default = nil)
  if valid_773255 != nil:
    section.add "X-Amz-Signature", valid_773255
  var valid_773256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773256 = validateParameter(valid_773256, JString, required = false,
                                 default = nil)
  if valid_773256 != nil:
    section.add "X-Amz-SignedHeaders", valid_773256
  var valid_773257 = header.getOrDefault("X-Amz-Credential")
  valid_773257 = validateParameter(valid_773257, JString, required = false,
                                 default = nil)
  if valid_773257 != nil:
    section.add "X-Amz-Credential", valid_773257
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773259: Call_CreateAssociation_773247; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates the specified Systems Manager document with the specified instances or targets.</p> <p>When you associate a document with one or more instances using instance IDs or tags, SSM Agent running on the instance processes the document and configures the instance as specified.</p> <p>If you associate a document with an instance that already has an associated document, the system returns the AssociationAlreadyExists exception.</p>
  ## 
  let valid = call_773259.validator(path, query, header, formData, body)
  let scheme = call_773259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773259.url(scheme.get, call_773259.host, call_773259.base,
                         call_773259.route, valid.getOrDefault("path"))
  result = hook(call_773259, url, valid)

proc call*(call_773260: Call_CreateAssociation_773247; body: JsonNode): Recallable =
  ## createAssociation
  ## <p>Associates the specified Systems Manager document with the specified instances or targets.</p> <p>When you associate a document with one or more instances using instance IDs or tags, SSM Agent running on the instance processes the document and configures the instance as specified.</p> <p>If you associate a document with an instance that already has an associated document, the system returns the AssociationAlreadyExists exception.</p>
  ##   body: JObject (required)
  var body_773261 = newJObject()
  if body != nil:
    body_773261 = body
  result = call_773260.call(nil, nil, nil, nil, body_773261)

var createAssociation* = Call_CreateAssociation_773247(name: "createAssociation",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateAssociation",
    validator: validate_CreateAssociation_773248, base: "/",
    url: url_CreateAssociation_773249, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAssociationBatch_773262 = ref object of OpenApiRestCall_772597
proc url_CreateAssociationBatch_773264(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateAssociationBatch_773263(path: JsonNode; query: JsonNode;
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
  var valid_773265 = header.getOrDefault("X-Amz-Date")
  valid_773265 = validateParameter(valid_773265, JString, required = false,
                                 default = nil)
  if valid_773265 != nil:
    section.add "X-Amz-Date", valid_773265
  var valid_773266 = header.getOrDefault("X-Amz-Security-Token")
  valid_773266 = validateParameter(valid_773266, JString, required = false,
                                 default = nil)
  if valid_773266 != nil:
    section.add "X-Amz-Security-Token", valid_773266
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773267 = header.getOrDefault("X-Amz-Target")
  valid_773267 = validateParameter(valid_773267, JString, required = true, default = newJString(
      "AmazonSSM.CreateAssociationBatch"))
  if valid_773267 != nil:
    section.add "X-Amz-Target", valid_773267
  var valid_773268 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773268 = validateParameter(valid_773268, JString, required = false,
                                 default = nil)
  if valid_773268 != nil:
    section.add "X-Amz-Content-Sha256", valid_773268
  var valid_773269 = header.getOrDefault("X-Amz-Algorithm")
  valid_773269 = validateParameter(valid_773269, JString, required = false,
                                 default = nil)
  if valid_773269 != nil:
    section.add "X-Amz-Algorithm", valid_773269
  var valid_773270 = header.getOrDefault("X-Amz-Signature")
  valid_773270 = validateParameter(valid_773270, JString, required = false,
                                 default = nil)
  if valid_773270 != nil:
    section.add "X-Amz-Signature", valid_773270
  var valid_773271 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773271 = validateParameter(valid_773271, JString, required = false,
                                 default = nil)
  if valid_773271 != nil:
    section.add "X-Amz-SignedHeaders", valid_773271
  var valid_773272 = header.getOrDefault("X-Amz-Credential")
  valid_773272 = validateParameter(valid_773272, JString, required = false,
                                 default = nil)
  if valid_773272 != nil:
    section.add "X-Amz-Credential", valid_773272
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773274: Call_CreateAssociationBatch_773262; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates the specified Systems Manager document with the specified instances or targets.</p> <p>When you associate a document with one or more instances using instance IDs or tags, SSM Agent running on the instance processes the document and configures the instance as specified.</p> <p>If you associate a document with an instance that already has an associated document, the system returns the AssociationAlreadyExists exception.</p>
  ## 
  let valid = call_773274.validator(path, query, header, formData, body)
  let scheme = call_773274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773274.url(scheme.get, call_773274.host, call_773274.base,
                         call_773274.route, valid.getOrDefault("path"))
  result = hook(call_773274, url, valid)

proc call*(call_773275: Call_CreateAssociationBatch_773262; body: JsonNode): Recallable =
  ## createAssociationBatch
  ## <p>Associates the specified Systems Manager document with the specified instances or targets.</p> <p>When you associate a document with one or more instances using instance IDs or tags, SSM Agent running on the instance processes the document and configures the instance as specified.</p> <p>If you associate a document with an instance that already has an associated document, the system returns the AssociationAlreadyExists exception.</p>
  ##   body: JObject (required)
  var body_773276 = newJObject()
  if body != nil:
    body_773276 = body
  result = call_773275.call(nil, nil, nil, nil, body_773276)

var createAssociationBatch* = Call_CreateAssociationBatch_773262(
    name: "createAssociationBatch", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateAssociationBatch",
    validator: validate_CreateAssociationBatch_773263, base: "/",
    url: url_CreateAssociationBatch_773264, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDocument_773277 = ref object of OpenApiRestCall_772597
proc url_CreateDocument_773279(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateDocument_773278(path: JsonNode; query: JsonNode;
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
  var valid_773280 = header.getOrDefault("X-Amz-Date")
  valid_773280 = validateParameter(valid_773280, JString, required = false,
                                 default = nil)
  if valid_773280 != nil:
    section.add "X-Amz-Date", valid_773280
  var valid_773281 = header.getOrDefault("X-Amz-Security-Token")
  valid_773281 = validateParameter(valid_773281, JString, required = false,
                                 default = nil)
  if valid_773281 != nil:
    section.add "X-Amz-Security-Token", valid_773281
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773282 = header.getOrDefault("X-Amz-Target")
  valid_773282 = validateParameter(valid_773282, JString, required = true, default = newJString(
      "AmazonSSM.CreateDocument"))
  if valid_773282 != nil:
    section.add "X-Amz-Target", valid_773282
  var valid_773283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773283 = validateParameter(valid_773283, JString, required = false,
                                 default = nil)
  if valid_773283 != nil:
    section.add "X-Amz-Content-Sha256", valid_773283
  var valid_773284 = header.getOrDefault("X-Amz-Algorithm")
  valid_773284 = validateParameter(valid_773284, JString, required = false,
                                 default = nil)
  if valid_773284 != nil:
    section.add "X-Amz-Algorithm", valid_773284
  var valid_773285 = header.getOrDefault("X-Amz-Signature")
  valid_773285 = validateParameter(valid_773285, JString, required = false,
                                 default = nil)
  if valid_773285 != nil:
    section.add "X-Amz-Signature", valid_773285
  var valid_773286 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773286 = validateParameter(valid_773286, JString, required = false,
                                 default = nil)
  if valid_773286 != nil:
    section.add "X-Amz-SignedHeaders", valid_773286
  var valid_773287 = header.getOrDefault("X-Amz-Credential")
  valid_773287 = validateParameter(valid_773287, JString, required = false,
                                 default = nil)
  if valid_773287 != nil:
    section.add "X-Amz-Credential", valid_773287
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773289: Call_CreateDocument_773277; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Systems Manager document.</p> <p>After you create a document, you can use CreateAssociation to associate it with one or more running instances.</p>
  ## 
  let valid = call_773289.validator(path, query, header, formData, body)
  let scheme = call_773289.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773289.url(scheme.get, call_773289.host, call_773289.base,
                         call_773289.route, valid.getOrDefault("path"))
  result = hook(call_773289, url, valid)

proc call*(call_773290: Call_CreateDocument_773277; body: JsonNode): Recallable =
  ## createDocument
  ## <p>Creates a Systems Manager document.</p> <p>After you create a document, you can use CreateAssociation to associate it with one or more running instances.</p>
  ##   body: JObject (required)
  var body_773291 = newJObject()
  if body != nil:
    body_773291 = body
  result = call_773290.call(nil, nil, nil, nil, body_773291)

var createDocument* = Call_CreateDocument_773277(name: "createDocument",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateDocument",
    validator: validate_CreateDocument_773278, base: "/", url: url_CreateDocument_773279,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMaintenanceWindow_773292 = ref object of OpenApiRestCall_772597
proc url_CreateMaintenanceWindow_773294(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateMaintenanceWindow_773293(path: JsonNode; query: JsonNode;
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
  var valid_773295 = header.getOrDefault("X-Amz-Date")
  valid_773295 = validateParameter(valid_773295, JString, required = false,
                                 default = nil)
  if valid_773295 != nil:
    section.add "X-Amz-Date", valid_773295
  var valid_773296 = header.getOrDefault("X-Amz-Security-Token")
  valid_773296 = validateParameter(valid_773296, JString, required = false,
                                 default = nil)
  if valid_773296 != nil:
    section.add "X-Amz-Security-Token", valid_773296
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773297 = header.getOrDefault("X-Amz-Target")
  valid_773297 = validateParameter(valid_773297, JString, required = true, default = newJString(
      "AmazonSSM.CreateMaintenanceWindow"))
  if valid_773297 != nil:
    section.add "X-Amz-Target", valid_773297
  var valid_773298 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773298 = validateParameter(valid_773298, JString, required = false,
                                 default = nil)
  if valid_773298 != nil:
    section.add "X-Amz-Content-Sha256", valid_773298
  var valid_773299 = header.getOrDefault("X-Amz-Algorithm")
  valid_773299 = validateParameter(valid_773299, JString, required = false,
                                 default = nil)
  if valid_773299 != nil:
    section.add "X-Amz-Algorithm", valid_773299
  var valid_773300 = header.getOrDefault("X-Amz-Signature")
  valid_773300 = validateParameter(valid_773300, JString, required = false,
                                 default = nil)
  if valid_773300 != nil:
    section.add "X-Amz-Signature", valid_773300
  var valid_773301 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773301 = validateParameter(valid_773301, JString, required = false,
                                 default = nil)
  if valid_773301 != nil:
    section.add "X-Amz-SignedHeaders", valid_773301
  var valid_773302 = header.getOrDefault("X-Amz-Credential")
  valid_773302 = validateParameter(valid_773302, JString, required = false,
                                 default = nil)
  if valid_773302 != nil:
    section.add "X-Amz-Credential", valid_773302
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773304: Call_CreateMaintenanceWindow_773292; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new maintenance window.
  ## 
  let valid = call_773304.validator(path, query, header, formData, body)
  let scheme = call_773304.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773304.url(scheme.get, call_773304.host, call_773304.base,
                         call_773304.route, valid.getOrDefault("path"))
  result = hook(call_773304, url, valid)

proc call*(call_773305: Call_CreateMaintenanceWindow_773292; body: JsonNode): Recallable =
  ## createMaintenanceWindow
  ## Creates a new maintenance window.
  ##   body: JObject (required)
  var body_773306 = newJObject()
  if body != nil:
    body_773306 = body
  result = call_773305.call(nil, nil, nil, nil, body_773306)

var createMaintenanceWindow* = Call_CreateMaintenanceWindow_773292(
    name: "createMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateMaintenanceWindow",
    validator: validate_CreateMaintenanceWindow_773293, base: "/",
    url: url_CreateMaintenanceWindow_773294, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateOpsItem_773307 = ref object of OpenApiRestCall_772597
proc url_CreateOpsItem_773309(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateOpsItem_773308(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773310 = header.getOrDefault("X-Amz-Date")
  valid_773310 = validateParameter(valid_773310, JString, required = false,
                                 default = nil)
  if valid_773310 != nil:
    section.add "X-Amz-Date", valid_773310
  var valid_773311 = header.getOrDefault("X-Amz-Security-Token")
  valid_773311 = validateParameter(valid_773311, JString, required = false,
                                 default = nil)
  if valid_773311 != nil:
    section.add "X-Amz-Security-Token", valid_773311
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773312 = header.getOrDefault("X-Amz-Target")
  valid_773312 = validateParameter(valid_773312, JString, required = true, default = newJString(
      "AmazonSSM.CreateOpsItem"))
  if valid_773312 != nil:
    section.add "X-Amz-Target", valid_773312
  var valid_773313 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773313 = validateParameter(valid_773313, JString, required = false,
                                 default = nil)
  if valid_773313 != nil:
    section.add "X-Amz-Content-Sha256", valid_773313
  var valid_773314 = header.getOrDefault("X-Amz-Algorithm")
  valid_773314 = validateParameter(valid_773314, JString, required = false,
                                 default = nil)
  if valid_773314 != nil:
    section.add "X-Amz-Algorithm", valid_773314
  var valid_773315 = header.getOrDefault("X-Amz-Signature")
  valid_773315 = validateParameter(valid_773315, JString, required = false,
                                 default = nil)
  if valid_773315 != nil:
    section.add "X-Amz-Signature", valid_773315
  var valid_773316 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773316 = validateParameter(valid_773316, JString, required = false,
                                 default = nil)
  if valid_773316 != nil:
    section.add "X-Amz-SignedHeaders", valid_773316
  var valid_773317 = header.getOrDefault("X-Amz-Credential")
  valid_773317 = validateParameter(valid_773317, JString, required = false,
                                 default = nil)
  if valid_773317 != nil:
    section.add "X-Amz-Credential", valid_773317
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773319: Call_CreateOpsItem_773307; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new OpsItem. You must have permission in AWS Identity and Access Management (IAM) to create a new OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ## 
  let valid = call_773319.validator(path, query, header, formData, body)
  let scheme = call_773319.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773319.url(scheme.get, call_773319.host, call_773319.base,
                         call_773319.route, valid.getOrDefault("path"))
  result = hook(call_773319, url, valid)

proc call*(call_773320: Call_CreateOpsItem_773307; body: JsonNode): Recallable =
  ## createOpsItem
  ## <p>Creates a new OpsItem. You must have permission in AWS Identity and Access Management (IAM) to create a new OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ##   body: JObject (required)
  var body_773321 = newJObject()
  if body != nil:
    body_773321 = body
  result = call_773320.call(nil, nil, nil, nil, body_773321)

var createOpsItem* = Call_CreateOpsItem_773307(name: "createOpsItem",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateOpsItem",
    validator: validate_CreateOpsItem_773308, base: "/", url: url_CreateOpsItem_773309,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePatchBaseline_773322 = ref object of OpenApiRestCall_772597
proc url_CreatePatchBaseline_773324(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreatePatchBaseline_773323(path: JsonNode; query: JsonNode;
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
  var valid_773325 = header.getOrDefault("X-Amz-Date")
  valid_773325 = validateParameter(valid_773325, JString, required = false,
                                 default = nil)
  if valid_773325 != nil:
    section.add "X-Amz-Date", valid_773325
  var valid_773326 = header.getOrDefault("X-Amz-Security-Token")
  valid_773326 = validateParameter(valid_773326, JString, required = false,
                                 default = nil)
  if valid_773326 != nil:
    section.add "X-Amz-Security-Token", valid_773326
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773327 = header.getOrDefault("X-Amz-Target")
  valid_773327 = validateParameter(valid_773327, JString, required = true, default = newJString(
      "AmazonSSM.CreatePatchBaseline"))
  if valid_773327 != nil:
    section.add "X-Amz-Target", valid_773327
  var valid_773328 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773328 = validateParameter(valid_773328, JString, required = false,
                                 default = nil)
  if valid_773328 != nil:
    section.add "X-Amz-Content-Sha256", valid_773328
  var valid_773329 = header.getOrDefault("X-Amz-Algorithm")
  valid_773329 = validateParameter(valid_773329, JString, required = false,
                                 default = nil)
  if valid_773329 != nil:
    section.add "X-Amz-Algorithm", valid_773329
  var valid_773330 = header.getOrDefault("X-Amz-Signature")
  valid_773330 = validateParameter(valid_773330, JString, required = false,
                                 default = nil)
  if valid_773330 != nil:
    section.add "X-Amz-Signature", valid_773330
  var valid_773331 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773331 = validateParameter(valid_773331, JString, required = false,
                                 default = nil)
  if valid_773331 != nil:
    section.add "X-Amz-SignedHeaders", valid_773331
  var valid_773332 = header.getOrDefault("X-Amz-Credential")
  valid_773332 = validateParameter(valid_773332, JString, required = false,
                                 default = nil)
  if valid_773332 != nil:
    section.add "X-Amz-Credential", valid_773332
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773334: Call_CreatePatchBaseline_773322; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a patch baseline.</p> <note> <p>For information about valid key and value pairs in <code>PatchFilters</code> for each supported operating system type, see <a href="http://docs.aws.amazon.com/systems-manager/latest/APIReference/API_PatchFilter.html">PatchFilter</a>.</p> </note>
  ## 
  let valid = call_773334.validator(path, query, header, formData, body)
  let scheme = call_773334.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773334.url(scheme.get, call_773334.host, call_773334.base,
                         call_773334.route, valid.getOrDefault("path"))
  result = hook(call_773334, url, valid)

proc call*(call_773335: Call_CreatePatchBaseline_773322; body: JsonNode): Recallable =
  ## createPatchBaseline
  ## <p>Creates a patch baseline.</p> <note> <p>For information about valid key and value pairs in <code>PatchFilters</code> for each supported operating system type, see <a href="http://docs.aws.amazon.com/systems-manager/latest/APIReference/API_PatchFilter.html">PatchFilter</a>.</p> </note>
  ##   body: JObject (required)
  var body_773336 = newJObject()
  if body != nil:
    body_773336 = body
  result = call_773335.call(nil, nil, nil, nil, body_773336)

var createPatchBaseline* = Call_CreatePatchBaseline_773322(
    name: "createPatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreatePatchBaseline",
    validator: validate_CreatePatchBaseline_773323, base: "/",
    url: url_CreatePatchBaseline_773324, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResourceDataSync_773337 = ref object of OpenApiRestCall_772597
proc url_CreateResourceDataSync_773339(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateResourceDataSync_773338(path: JsonNode; query: JsonNode;
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
  var valid_773340 = header.getOrDefault("X-Amz-Date")
  valid_773340 = validateParameter(valid_773340, JString, required = false,
                                 default = nil)
  if valid_773340 != nil:
    section.add "X-Amz-Date", valid_773340
  var valid_773341 = header.getOrDefault("X-Amz-Security-Token")
  valid_773341 = validateParameter(valid_773341, JString, required = false,
                                 default = nil)
  if valid_773341 != nil:
    section.add "X-Amz-Security-Token", valid_773341
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773342 = header.getOrDefault("X-Amz-Target")
  valid_773342 = validateParameter(valid_773342, JString, required = true, default = newJString(
      "AmazonSSM.CreateResourceDataSync"))
  if valid_773342 != nil:
    section.add "X-Amz-Target", valid_773342
  var valid_773343 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773343 = validateParameter(valid_773343, JString, required = false,
                                 default = nil)
  if valid_773343 != nil:
    section.add "X-Amz-Content-Sha256", valid_773343
  var valid_773344 = header.getOrDefault("X-Amz-Algorithm")
  valid_773344 = validateParameter(valid_773344, JString, required = false,
                                 default = nil)
  if valid_773344 != nil:
    section.add "X-Amz-Algorithm", valid_773344
  var valid_773345 = header.getOrDefault("X-Amz-Signature")
  valid_773345 = validateParameter(valid_773345, JString, required = false,
                                 default = nil)
  if valid_773345 != nil:
    section.add "X-Amz-Signature", valid_773345
  var valid_773346 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773346 = validateParameter(valid_773346, JString, required = false,
                                 default = nil)
  if valid_773346 != nil:
    section.add "X-Amz-SignedHeaders", valid_773346
  var valid_773347 = header.getOrDefault("X-Amz-Credential")
  valid_773347 = validateParameter(valid_773347, JString, required = false,
                                 default = nil)
  if valid_773347 != nil:
    section.add "X-Amz-Credential", valid_773347
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773349: Call_CreateResourceDataSync_773337; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a resource data sync configuration to a single bucket in Amazon S3. This is an asynchronous operation that returns immediately. After a successful initial sync is completed, the system continuously syncs data to the Amazon S3 bucket. To check the status of the sync, use the <a>ListResourceDataSync</a>.</p> <p>By default, data is not encrypted in Amazon S3. We strongly recommend that you enable encryption in Amazon S3 to ensure secure data storage. We also recommend that you secure access to the Amazon S3 bucket by creating a restrictive bucket policy. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-inventory-datasync.html">Configuring Resource Data Sync for Inventory</a> in the <i>AWS Systems Manager User Guide</i>.</p>
  ## 
  let valid = call_773349.validator(path, query, header, formData, body)
  let scheme = call_773349.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773349.url(scheme.get, call_773349.host, call_773349.base,
                         call_773349.route, valid.getOrDefault("path"))
  result = hook(call_773349, url, valid)

proc call*(call_773350: Call_CreateResourceDataSync_773337; body: JsonNode): Recallable =
  ## createResourceDataSync
  ## <p>Creates a resource data sync configuration to a single bucket in Amazon S3. This is an asynchronous operation that returns immediately. After a successful initial sync is completed, the system continuously syncs data to the Amazon S3 bucket. To check the status of the sync, use the <a>ListResourceDataSync</a>.</p> <p>By default, data is not encrypted in Amazon S3. We strongly recommend that you enable encryption in Amazon S3 to ensure secure data storage. We also recommend that you secure access to the Amazon S3 bucket by creating a restrictive bucket policy. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-inventory-datasync.html">Configuring Resource Data Sync for Inventory</a> in the <i>AWS Systems Manager User Guide</i>.</p>
  ##   body: JObject (required)
  var body_773351 = newJObject()
  if body != nil:
    body_773351 = body
  result = call_773350.call(nil, nil, nil, nil, body_773351)

var createResourceDataSync* = Call_CreateResourceDataSync_773337(
    name: "createResourceDataSync", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateResourceDataSync",
    validator: validate_CreateResourceDataSync_773338, base: "/",
    url: url_CreateResourceDataSync_773339, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteActivation_773352 = ref object of OpenApiRestCall_772597
proc url_DeleteActivation_773354(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteActivation_773353(path: JsonNode; query: JsonNode;
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
  var valid_773355 = header.getOrDefault("X-Amz-Date")
  valid_773355 = validateParameter(valid_773355, JString, required = false,
                                 default = nil)
  if valid_773355 != nil:
    section.add "X-Amz-Date", valid_773355
  var valid_773356 = header.getOrDefault("X-Amz-Security-Token")
  valid_773356 = validateParameter(valid_773356, JString, required = false,
                                 default = nil)
  if valid_773356 != nil:
    section.add "X-Amz-Security-Token", valid_773356
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773357 = header.getOrDefault("X-Amz-Target")
  valid_773357 = validateParameter(valid_773357, JString, required = true, default = newJString(
      "AmazonSSM.DeleteActivation"))
  if valid_773357 != nil:
    section.add "X-Amz-Target", valid_773357
  var valid_773358 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773358 = validateParameter(valid_773358, JString, required = false,
                                 default = nil)
  if valid_773358 != nil:
    section.add "X-Amz-Content-Sha256", valid_773358
  var valid_773359 = header.getOrDefault("X-Amz-Algorithm")
  valid_773359 = validateParameter(valid_773359, JString, required = false,
                                 default = nil)
  if valid_773359 != nil:
    section.add "X-Amz-Algorithm", valid_773359
  var valid_773360 = header.getOrDefault("X-Amz-Signature")
  valid_773360 = validateParameter(valid_773360, JString, required = false,
                                 default = nil)
  if valid_773360 != nil:
    section.add "X-Amz-Signature", valid_773360
  var valid_773361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773361 = validateParameter(valid_773361, JString, required = false,
                                 default = nil)
  if valid_773361 != nil:
    section.add "X-Amz-SignedHeaders", valid_773361
  var valid_773362 = header.getOrDefault("X-Amz-Credential")
  valid_773362 = validateParameter(valid_773362, JString, required = false,
                                 default = nil)
  if valid_773362 != nil:
    section.add "X-Amz-Credential", valid_773362
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773364: Call_DeleteActivation_773352; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an activation. You are not required to delete an activation. If you delete an activation, you can no longer use it to register additional managed instances. Deleting an activation does not de-register managed instances. You must manually de-register managed instances.
  ## 
  let valid = call_773364.validator(path, query, header, formData, body)
  let scheme = call_773364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773364.url(scheme.get, call_773364.host, call_773364.base,
                         call_773364.route, valid.getOrDefault("path"))
  result = hook(call_773364, url, valid)

proc call*(call_773365: Call_DeleteActivation_773352; body: JsonNode): Recallable =
  ## deleteActivation
  ## Deletes an activation. You are not required to delete an activation. If you delete an activation, you can no longer use it to register additional managed instances. Deleting an activation does not de-register managed instances. You must manually de-register managed instances.
  ##   body: JObject (required)
  var body_773366 = newJObject()
  if body != nil:
    body_773366 = body
  result = call_773365.call(nil, nil, nil, nil, body_773366)

var deleteActivation* = Call_DeleteActivation_773352(name: "deleteActivation",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteActivation",
    validator: validate_DeleteActivation_773353, base: "/",
    url: url_DeleteActivation_773354, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAssociation_773367 = ref object of OpenApiRestCall_772597
proc url_DeleteAssociation_773369(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteAssociation_773368(path: JsonNode; query: JsonNode;
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
  var valid_773370 = header.getOrDefault("X-Amz-Date")
  valid_773370 = validateParameter(valid_773370, JString, required = false,
                                 default = nil)
  if valid_773370 != nil:
    section.add "X-Amz-Date", valid_773370
  var valid_773371 = header.getOrDefault("X-Amz-Security-Token")
  valid_773371 = validateParameter(valid_773371, JString, required = false,
                                 default = nil)
  if valid_773371 != nil:
    section.add "X-Amz-Security-Token", valid_773371
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773372 = header.getOrDefault("X-Amz-Target")
  valid_773372 = validateParameter(valid_773372, JString, required = true, default = newJString(
      "AmazonSSM.DeleteAssociation"))
  if valid_773372 != nil:
    section.add "X-Amz-Target", valid_773372
  var valid_773373 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773373 = validateParameter(valid_773373, JString, required = false,
                                 default = nil)
  if valid_773373 != nil:
    section.add "X-Amz-Content-Sha256", valid_773373
  var valid_773374 = header.getOrDefault("X-Amz-Algorithm")
  valid_773374 = validateParameter(valid_773374, JString, required = false,
                                 default = nil)
  if valid_773374 != nil:
    section.add "X-Amz-Algorithm", valid_773374
  var valid_773375 = header.getOrDefault("X-Amz-Signature")
  valid_773375 = validateParameter(valid_773375, JString, required = false,
                                 default = nil)
  if valid_773375 != nil:
    section.add "X-Amz-Signature", valid_773375
  var valid_773376 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773376 = validateParameter(valid_773376, JString, required = false,
                                 default = nil)
  if valid_773376 != nil:
    section.add "X-Amz-SignedHeaders", valid_773376
  var valid_773377 = header.getOrDefault("X-Amz-Credential")
  valid_773377 = validateParameter(valid_773377, JString, required = false,
                                 default = nil)
  if valid_773377 != nil:
    section.add "X-Amz-Credential", valid_773377
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773379: Call_DeleteAssociation_773367; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disassociates the specified Systems Manager document from the specified instance.</p> <p>When you disassociate a document from an instance, it does not change the configuration of the instance. To change the configuration state of an instance after you disassociate a document, you must create a new document with the desired configuration and associate it with the instance.</p>
  ## 
  let valid = call_773379.validator(path, query, header, formData, body)
  let scheme = call_773379.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773379.url(scheme.get, call_773379.host, call_773379.base,
                         call_773379.route, valid.getOrDefault("path"))
  result = hook(call_773379, url, valid)

proc call*(call_773380: Call_DeleteAssociation_773367; body: JsonNode): Recallable =
  ## deleteAssociation
  ## <p>Disassociates the specified Systems Manager document from the specified instance.</p> <p>When you disassociate a document from an instance, it does not change the configuration of the instance. To change the configuration state of an instance after you disassociate a document, you must create a new document with the desired configuration and associate it with the instance.</p>
  ##   body: JObject (required)
  var body_773381 = newJObject()
  if body != nil:
    body_773381 = body
  result = call_773380.call(nil, nil, nil, nil, body_773381)

var deleteAssociation* = Call_DeleteAssociation_773367(name: "deleteAssociation",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteAssociation",
    validator: validate_DeleteAssociation_773368, base: "/",
    url: url_DeleteAssociation_773369, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDocument_773382 = ref object of OpenApiRestCall_772597
proc url_DeleteDocument_773384(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteDocument_773383(path: JsonNode; query: JsonNode;
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
  var valid_773385 = header.getOrDefault("X-Amz-Date")
  valid_773385 = validateParameter(valid_773385, JString, required = false,
                                 default = nil)
  if valid_773385 != nil:
    section.add "X-Amz-Date", valid_773385
  var valid_773386 = header.getOrDefault("X-Amz-Security-Token")
  valid_773386 = validateParameter(valid_773386, JString, required = false,
                                 default = nil)
  if valid_773386 != nil:
    section.add "X-Amz-Security-Token", valid_773386
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773387 = header.getOrDefault("X-Amz-Target")
  valid_773387 = validateParameter(valid_773387, JString, required = true, default = newJString(
      "AmazonSSM.DeleteDocument"))
  if valid_773387 != nil:
    section.add "X-Amz-Target", valid_773387
  var valid_773388 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773388 = validateParameter(valid_773388, JString, required = false,
                                 default = nil)
  if valid_773388 != nil:
    section.add "X-Amz-Content-Sha256", valid_773388
  var valid_773389 = header.getOrDefault("X-Amz-Algorithm")
  valid_773389 = validateParameter(valid_773389, JString, required = false,
                                 default = nil)
  if valid_773389 != nil:
    section.add "X-Amz-Algorithm", valid_773389
  var valid_773390 = header.getOrDefault("X-Amz-Signature")
  valid_773390 = validateParameter(valid_773390, JString, required = false,
                                 default = nil)
  if valid_773390 != nil:
    section.add "X-Amz-Signature", valid_773390
  var valid_773391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773391 = validateParameter(valid_773391, JString, required = false,
                                 default = nil)
  if valid_773391 != nil:
    section.add "X-Amz-SignedHeaders", valid_773391
  var valid_773392 = header.getOrDefault("X-Amz-Credential")
  valid_773392 = validateParameter(valid_773392, JString, required = false,
                                 default = nil)
  if valid_773392 != nil:
    section.add "X-Amz-Credential", valid_773392
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773394: Call_DeleteDocument_773382; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the Systems Manager document and all instance associations to the document.</p> <p>Before you delete the document, we recommend that you use <a>DeleteAssociation</a> to disassociate all instances that are associated with the document.</p>
  ## 
  let valid = call_773394.validator(path, query, header, formData, body)
  let scheme = call_773394.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773394.url(scheme.get, call_773394.host, call_773394.base,
                         call_773394.route, valid.getOrDefault("path"))
  result = hook(call_773394, url, valid)

proc call*(call_773395: Call_DeleteDocument_773382; body: JsonNode): Recallable =
  ## deleteDocument
  ## <p>Deletes the Systems Manager document and all instance associations to the document.</p> <p>Before you delete the document, we recommend that you use <a>DeleteAssociation</a> to disassociate all instances that are associated with the document.</p>
  ##   body: JObject (required)
  var body_773396 = newJObject()
  if body != nil:
    body_773396 = body
  result = call_773395.call(nil, nil, nil, nil, body_773396)

var deleteDocument* = Call_DeleteDocument_773382(name: "deleteDocument",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteDocument",
    validator: validate_DeleteDocument_773383, base: "/", url: url_DeleteDocument_773384,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInventory_773397 = ref object of OpenApiRestCall_772597
proc url_DeleteInventory_773399(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteInventory_773398(path: JsonNode; query: JsonNode;
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
  var valid_773400 = header.getOrDefault("X-Amz-Date")
  valid_773400 = validateParameter(valid_773400, JString, required = false,
                                 default = nil)
  if valid_773400 != nil:
    section.add "X-Amz-Date", valid_773400
  var valid_773401 = header.getOrDefault("X-Amz-Security-Token")
  valid_773401 = validateParameter(valid_773401, JString, required = false,
                                 default = nil)
  if valid_773401 != nil:
    section.add "X-Amz-Security-Token", valid_773401
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773402 = header.getOrDefault("X-Amz-Target")
  valid_773402 = validateParameter(valid_773402, JString, required = true, default = newJString(
      "AmazonSSM.DeleteInventory"))
  if valid_773402 != nil:
    section.add "X-Amz-Target", valid_773402
  var valid_773403 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773403 = validateParameter(valid_773403, JString, required = false,
                                 default = nil)
  if valid_773403 != nil:
    section.add "X-Amz-Content-Sha256", valid_773403
  var valid_773404 = header.getOrDefault("X-Amz-Algorithm")
  valid_773404 = validateParameter(valid_773404, JString, required = false,
                                 default = nil)
  if valid_773404 != nil:
    section.add "X-Amz-Algorithm", valid_773404
  var valid_773405 = header.getOrDefault("X-Amz-Signature")
  valid_773405 = validateParameter(valid_773405, JString, required = false,
                                 default = nil)
  if valid_773405 != nil:
    section.add "X-Amz-Signature", valid_773405
  var valid_773406 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773406 = validateParameter(valid_773406, JString, required = false,
                                 default = nil)
  if valid_773406 != nil:
    section.add "X-Amz-SignedHeaders", valid_773406
  var valid_773407 = header.getOrDefault("X-Amz-Credential")
  valid_773407 = validateParameter(valid_773407, JString, required = false,
                                 default = nil)
  if valid_773407 != nil:
    section.add "X-Amz-Credential", valid_773407
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773409: Call_DeleteInventory_773397; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a custom inventory type, or the data associated with a custom Inventory type. Deleting a custom inventory type is also referred to as deleting a custom inventory schema.
  ## 
  let valid = call_773409.validator(path, query, header, formData, body)
  let scheme = call_773409.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773409.url(scheme.get, call_773409.host, call_773409.base,
                         call_773409.route, valid.getOrDefault("path"))
  result = hook(call_773409, url, valid)

proc call*(call_773410: Call_DeleteInventory_773397; body: JsonNode): Recallable =
  ## deleteInventory
  ## Delete a custom inventory type, or the data associated with a custom Inventory type. Deleting a custom inventory type is also referred to as deleting a custom inventory schema.
  ##   body: JObject (required)
  var body_773411 = newJObject()
  if body != nil:
    body_773411 = body
  result = call_773410.call(nil, nil, nil, nil, body_773411)

var deleteInventory* = Call_DeleteInventory_773397(name: "deleteInventory",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteInventory",
    validator: validate_DeleteInventory_773398, base: "/", url: url_DeleteInventory_773399,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMaintenanceWindow_773412 = ref object of OpenApiRestCall_772597
proc url_DeleteMaintenanceWindow_773414(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteMaintenanceWindow_773413(path: JsonNode; query: JsonNode;
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
  var valid_773415 = header.getOrDefault("X-Amz-Date")
  valid_773415 = validateParameter(valid_773415, JString, required = false,
                                 default = nil)
  if valid_773415 != nil:
    section.add "X-Amz-Date", valid_773415
  var valid_773416 = header.getOrDefault("X-Amz-Security-Token")
  valid_773416 = validateParameter(valid_773416, JString, required = false,
                                 default = nil)
  if valid_773416 != nil:
    section.add "X-Amz-Security-Token", valid_773416
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773417 = header.getOrDefault("X-Amz-Target")
  valid_773417 = validateParameter(valid_773417, JString, required = true, default = newJString(
      "AmazonSSM.DeleteMaintenanceWindow"))
  if valid_773417 != nil:
    section.add "X-Amz-Target", valid_773417
  var valid_773418 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773418 = validateParameter(valid_773418, JString, required = false,
                                 default = nil)
  if valid_773418 != nil:
    section.add "X-Amz-Content-Sha256", valid_773418
  var valid_773419 = header.getOrDefault("X-Amz-Algorithm")
  valid_773419 = validateParameter(valid_773419, JString, required = false,
                                 default = nil)
  if valid_773419 != nil:
    section.add "X-Amz-Algorithm", valid_773419
  var valid_773420 = header.getOrDefault("X-Amz-Signature")
  valid_773420 = validateParameter(valid_773420, JString, required = false,
                                 default = nil)
  if valid_773420 != nil:
    section.add "X-Amz-Signature", valid_773420
  var valid_773421 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773421 = validateParameter(valid_773421, JString, required = false,
                                 default = nil)
  if valid_773421 != nil:
    section.add "X-Amz-SignedHeaders", valid_773421
  var valid_773422 = header.getOrDefault("X-Amz-Credential")
  valid_773422 = validateParameter(valid_773422, JString, required = false,
                                 default = nil)
  if valid_773422 != nil:
    section.add "X-Amz-Credential", valid_773422
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773424: Call_DeleteMaintenanceWindow_773412; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a maintenance window.
  ## 
  let valid = call_773424.validator(path, query, header, formData, body)
  let scheme = call_773424.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773424.url(scheme.get, call_773424.host, call_773424.base,
                         call_773424.route, valid.getOrDefault("path"))
  result = hook(call_773424, url, valid)

proc call*(call_773425: Call_DeleteMaintenanceWindow_773412; body: JsonNode): Recallable =
  ## deleteMaintenanceWindow
  ## Deletes a maintenance window.
  ##   body: JObject (required)
  var body_773426 = newJObject()
  if body != nil:
    body_773426 = body
  result = call_773425.call(nil, nil, nil, nil, body_773426)

var deleteMaintenanceWindow* = Call_DeleteMaintenanceWindow_773412(
    name: "deleteMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteMaintenanceWindow",
    validator: validate_DeleteMaintenanceWindow_773413, base: "/",
    url: url_DeleteMaintenanceWindow_773414, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteParameter_773427 = ref object of OpenApiRestCall_772597
proc url_DeleteParameter_773429(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteParameter_773428(path: JsonNode; query: JsonNode;
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
  var valid_773430 = header.getOrDefault("X-Amz-Date")
  valid_773430 = validateParameter(valid_773430, JString, required = false,
                                 default = nil)
  if valid_773430 != nil:
    section.add "X-Amz-Date", valid_773430
  var valid_773431 = header.getOrDefault("X-Amz-Security-Token")
  valid_773431 = validateParameter(valid_773431, JString, required = false,
                                 default = nil)
  if valid_773431 != nil:
    section.add "X-Amz-Security-Token", valid_773431
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773432 = header.getOrDefault("X-Amz-Target")
  valid_773432 = validateParameter(valid_773432, JString, required = true, default = newJString(
      "AmazonSSM.DeleteParameter"))
  if valid_773432 != nil:
    section.add "X-Amz-Target", valid_773432
  var valid_773433 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773433 = validateParameter(valid_773433, JString, required = false,
                                 default = nil)
  if valid_773433 != nil:
    section.add "X-Amz-Content-Sha256", valid_773433
  var valid_773434 = header.getOrDefault("X-Amz-Algorithm")
  valid_773434 = validateParameter(valid_773434, JString, required = false,
                                 default = nil)
  if valid_773434 != nil:
    section.add "X-Amz-Algorithm", valid_773434
  var valid_773435 = header.getOrDefault("X-Amz-Signature")
  valid_773435 = validateParameter(valid_773435, JString, required = false,
                                 default = nil)
  if valid_773435 != nil:
    section.add "X-Amz-Signature", valid_773435
  var valid_773436 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773436 = validateParameter(valid_773436, JString, required = false,
                                 default = nil)
  if valid_773436 != nil:
    section.add "X-Amz-SignedHeaders", valid_773436
  var valid_773437 = header.getOrDefault("X-Amz-Credential")
  valid_773437 = validateParameter(valid_773437, JString, required = false,
                                 default = nil)
  if valid_773437 != nil:
    section.add "X-Amz-Credential", valid_773437
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773439: Call_DeleteParameter_773427; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a parameter from the system.
  ## 
  let valid = call_773439.validator(path, query, header, formData, body)
  let scheme = call_773439.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773439.url(scheme.get, call_773439.host, call_773439.base,
                         call_773439.route, valid.getOrDefault("path"))
  result = hook(call_773439, url, valid)

proc call*(call_773440: Call_DeleteParameter_773427; body: JsonNode): Recallable =
  ## deleteParameter
  ## Delete a parameter from the system.
  ##   body: JObject (required)
  var body_773441 = newJObject()
  if body != nil:
    body_773441 = body
  result = call_773440.call(nil, nil, nil, nil, body_773441)

var deleteParameter* = Call_DeleteParameter_773427(name: "deleteParameter",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteParameter",
    validator: validate_DeleteParameter_773428, base: "/", url: url_DeleteParameter_773429,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteParameters_773442 = ref object of OpenApiRestCall_772597
proc url_DeleteParameters_773444(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteParameters_773443(path: JsonNode; query: JsonNode;
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
  var valid_773445 = header.getOrDefault("X-Amz-Date")
  valid_773445 = validateParameter(valid_773445, JString, required = false,
                                 default = nil)
  if valid_773445 != nil:
    section.add "X-Amz-Date", valid_773445
  var valid_773446 = header.getOrDefault("X-Amz-Security-Token")
  valid_773446 = validateParameter(valid_773446, JString, required = false,
                                 default = nil)
  if valid_773446 != nil:
    section.add "X-Amz-Security-Token", valid_773446
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773447 = header.getOrDefault("X-Amz-Target")
  valid_773447 = validateParameter(valid_773447, JString, required = true, default = newJString(
      "AmazonSSM.DeleteParameters"))
  if valid_773447 != nil:
    section.add "X-Amz-Target", valid_773447
  var valid_773448 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773448 = validateParameter(valid_773448, JString, required = false,
                                 default = nil)
  if valid_773448 != nil:
    section.add "X-Amz-Content-Sha256", valid_773448
  var valid_773449 = header.getOrDefault("X-Amz-Algorithm")
  valid_773449 = validateParameter(valid_773449, JString, required = false,
                                 default = nil)
  if valid_773449 != nil:
    section.add "X-Amz-Algorithm", valid_773449
  var valid_773450 = header.getOrDefault("X-Amz-Signature")
  valid_773450 = validateParameter(valid_773450, JString, required = false,
                                 default = nil)
  if valid_773450 != nil:
    section.add "X-Amz-Signature", valid_773450
  var valid_773451 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773451 = validateParameter(valid_773451, JString, required = false,
                                 default = nil)
  if valid_773451 != nil:
    section.add "X-Amz-SignedHeaders", valid_773451
  var valid_773452 = header.getOrDefault("X-Amz-Credential")
  valid_773452 = validateParameter(valid_773452, JString, required = false,
                                 default = nil)
  if valid_773452 != nil:
    section.add "X-Amz-Credential", valid_773452
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773454: Call_DeleteParameters_773442; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a list of parameters.
  ## 
  let valid = call_773454.validator(path, query, header, formData, body)
  let scheme = call_773454.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773454.url(scheme.get, call_773454.host, call_773454.base,
                         call_773454.route, valid.getOrDefault("path"))
  result = hook(call_773454, url, valid)

proc call*(call_773455: Call_DeleteParameters_773442; body: JsonNode): Recallable =
  ## deleteParameters
  ## Delete a list of parameters.
  ##   body: JObject (required)
  var body_773456 = newJObject()
  if body != nil:
    body_773456 = body
  result = call_773455.call(nil, nil, nil, nil, body_773456)

var deleteParameters* = Call_DeleteParameters_773442(name: "deleteParameters",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteParameters",
    validator: validate_DeleteParameters_773443, base: "/",
    url: url_DeleteParameters_773444, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePatchBaseline_773457 = ref object of OpenApiRestCall_772597
proc url_DeletePatchBaseline_773459(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeletePatchBaseline_773458(path: JsonNode; query: JsonNode;
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
  var valid_773460 = header.getOrDefault("X-Amz-Date")
  valid_773460 = validateParameter(valid_773460, JString, required = false,
                                 default = nil)
  if valid_773460 != nil:
    section.add "X-Amz-Date", valid_773460
  var valid_773461 = header.getOrDefault("X-Amz-Security-Token")
  valid_773461 = validateParameter(valid_773461, JString, required = false,
                                 default = nil)
  if valid_773461 != nil:
    section.add "X-Amz-Security-Token", valid_773461
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773462 = header.getOrDefault("X-Amz-Target")
  valid_773462 = validateParameter(valid_773462, JString, required = true, default = newJString(
      "AmazonSSM.DeletePatchBaseline"))
  if valid_773462 != nil:
    section.add "X-Amz-Target", valid_773462
  var valid_773463 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773463 = validateParameter(valid_773463, JString, required = false,
                                 default = nil)
  if valid_773463 != nil:
    section.add "X-Amz-Content-Sha256", valid_773463
  var valid_773464 = header.getOrDefault("X-Amz-Algorithm")
  valid_773464 = validateParameter(valid_773464, JString, required = false,
                                 default = nil)
  if valid_773464 != nil:
    section.add "X-Amz-Algorithm", valid_773464
  var valid_773465 = header.getOrDefault("X-Amz-Signature")
  valid_773465 = validateParameter(valid_773465, JString, required = false,
                                 default = nil)
  if valid_773465 != nil:
    section.add "X-Amz-Signature", valid_773465
  var valid_773466 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773466 = validateParameter(valid_773466, JString, required = false,
                                 default = nil)
  if valid_773466 != nil:
    section.add "X-Amz-SignedHeaders", valid_773466
  var valid_773467 = header.getOrDefault("X-Amz-Credential")
  valid_773467 = validateParameter(valid_773467, JString, required = false,
                                 default = nil)
  if valid_773467 != nil:
    section.add "X-Amz-Credential", valid_773467
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773469: Call_DeletePatchBaseline_773457; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a patch baseline.
  ## 
  let valid = call_773469.validator(path, query, header, formData, body)
  let scheme = call_773469.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773469.url(scheme.get, call_773469.host, call_773469.base,
                         call_773469.route, valid.getOrDefault("path"))
  result = hook(call_773469, url, valid)

proc call*(call_773470: Call_DeletePatchBaseline_773457; body: JsonNode): Recallable =
  ## deletePatchBaseline
  ## Deletes a patch baseline.
  ##   body: JObject (required)
  var body_773471 = newJObject()
  if body != nil:
    body_773471 = body
  result = call_773470.call(nil, nil, nil, nil, body_773471)

var deletePatchBaseline* = Call_DeletePatchBaseline_773457(
    name: "deletePatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeletePatchBaseline",
    validator: validate_DeletePatchBaseline_773458, base: "/",
    url: url_DeletePatchBaseline_773459, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResourceDataSync_773472 = ref object of OpenApiRestCall_772597
proc url_DeleteResourceDataSync_773474(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteResourceDataSync_773473(path: JsonNode; query: JsonNode;
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
  var valid_773475 = header.getOrDefault("X-Amz-Date")
  valid_773475 = validateParameter(valid_773475, JString, required = false,
                                 default = nil)
  if valid_773475 != nil:
    section.add "X-Amz-Date", valid_773475
  var valid_773476 = header.getOrDefault("X-Amz-Security-Token")
  valid_773476 = validateParameter(valid_773476, JString, required = false,
                                 default = nil)
  if valid_773476 != nil:
    section.add "X-Amz-Security-Token", valid_773476
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773477 = header.getOrDefault("X-Amz-Target")
  valid_773477 = validateParameter(valid_773477, JString, required = true, default = newJString(
      "AmazonSSM.DeleteResourceDataSync"))
  if valid_773477 != nil:
    section.add "X-Amz-Target", valid_773477
  var valid_773478 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773478 = validateParameter(valid_773478, JString, required = false,
                                 default = nil)
  if valid_773478 != nil:
    section.add "X-Amz-Content-Sha256", valid_773478
  var valid_773479 = header.getOrDefault("X-Amz-Algorithm")
  valid_773479 = validateParameter(valid_773479, JString, required = false,
                                 default = nil)
  if valid_773479 != nil:
    section.add "X-Amz-Algorithm", valid_773479
  var valid_773480 = header.getOrDefault("X-Amz-Signature")
  valid_773480 = validateParameter(valid_773480, JString, required = false,
                                 default = nil)
  if valid_773480 != nil:
    section.add "X-Amz-Signature", valid_773480
  var valid_773481 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773481 = validateParameter(valid_773481, JString, required = false,
                                 default = nil)
  if valid_773481 != nil:
    section.add "X-Amz-SignedHeaders", valid_773481
  var valid_773482 = header.getOrDefault("X-Amz-Credential")
  valid_773482 = validateParameter(valid_773482, JString, required = false,
                                 default = nil)
  if valid_773482 != nil:
    section.add "X-Amz-Credential", valid_773482
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773484: Call_DeleteResourceDataSync_773472; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Resource Data Sync configuration. After the configuration is deleted, changes to inventory data on managed instances are no longer synced with the target Amazon S3 bucket. Deleting a sync configuration does not delete data in the target Amazon S3 bucket.
  ## 
  let valid = call_773484.validator(path, query, header, formData, body)
  let scheme = call_773484.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773484.url(scheme.get, call_773484.host, call_773484.base,
                         call_773484.route, valid.getOrDefault("path"))
  result = hook(call_773484, url, valid)

proc call*(call_773485: Call_DeleteResourceDataSync_773472; body: JsonNode): Recallable =
  ## deleteResourceDataSync
  ## Deletes a Resource Data Sync configuration. After the configuration is deleted, changes to inventory data on managed instances are no longer synced with the target Amazon S3 bucket. Deleting a sync configuration does not delete data in the target Amazon S3 bucket.
  ##   body: JObject (required)
  var body_773486 = newJObject()
  if body != nil:
    body_773486 = body
  result = call_773485.call(nil, nil, nil, nil, body_773486)

var deleteResourceDataSync* = Call_DeleteResourceDataSync_773472(
    name: "deleteResourceDataSync", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteResourceDataSync",
    validator: validate_DeleteResourceDataSync_773473, base: "/",
    url: url_DeleteResourceDataSync_773474, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterManagedInstance_773487 = ref object of OpenApiRestCall_772597
proc url_DeregisterManagedInstance_773489(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeregisterManagedInstance_773488(path: JsonNode; query: JsonNode;
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
  var valid_773490 = header.getOrDefault("X-Amz-Date")
  valid_773490 = validateParameter(valid_773490, JString, required = false,
                                 default = nil)
  if valid_773490 != nil:
    section.add "X-Amz-Date", valid_773490
  var valid_773491 = header.getOrDefault("X-Amz-Security-Token")
  valid_773491 = validateParameter(valid_773491, JString, required = false,
                                 default = nil)
  if valid_773491 != nil:
    section.add "X-Amz-Security-Token", valid_773491
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773492 = header.getOrDefault("X-Amz-Target")
  valid_773492 = validateParameter(valid_773492, JString, required = true, default = newJString(
      "AmazonSSM.DeregisterManagedInstance"))
  if valid_773492 != nil:
    section.add "X-Amz-Target", valid_773492
  var valid_773493 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773493 = validateParameter(valid_773493, JString, required = false,
                                 default = nil)
  if valid_773493 != nil:
    section.add "X-Amz-Content-Sha256", valid_773493
  var valid_773494 = header.getOrDefault("X-Amz-Algorithm")
  valid_773494 = validateParameter(valid_773494, JString, required = false,
                                 default = nil)
  if valid_773494 != nil:
    section.add "X-Amz-Algorithm", valid_773494
  var valid_773495 = header.getOrDefault("X-Amz-Signature")
  valid_773495 = validateParameter(valid_773495, JString, required = false,
                                 default = nil)
  if valid_773495 != nil:
    section.add "X-Amz-Signature", valid_773495
  var valid_773496 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773496 = validateParameter(valid_773496, JString, required = false,
                                 default = nil)
  if valid_773496 != nil:
    section.add "X-Amz-SignedHeaders", valid_773496
  var valid_773497 = header.getOrDefault("X-Amz-Credential")
  valid_773497 = validateParameter(valid_773497, JString, required = false,
                                 default = nil)
  if valid_773497 != nil:
    section.add "X-Amz-Credential", valid_773497
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773499: Call_DeregisterManagedInstance_773487; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the server or virtual machine from the list of registered servers. You can reregister the instance again at any time. If you don't plan to use Run Command on the server, we suggest uninstalling SSM Agent first.
  ## 
  let valid = call_773499.validator(path, query, header, formData, body)
  let scheme = call_773499.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773499.url(scheme.get, call_773499.host, call_773499.base,
                         call_773499.route, valid.getOrDefault("path"))
  result = hook(call_773499, url, valid)

proc call*(call_773500: Call_DeregisterManagedInstance_773487; body: JsonNode): Recallable =
  ## deregisterManagedInstance
  ## Removes the server or virtual machine from the list of registered servers. You can reregister the instance again at any time. If you don't plan to use Run Command on the server, we suggest uninstalling SSM Agent first.
  ##   body: JObject (required)
  var body_773501 = newJObject()
  if body != nil:
    body_773501 = body
  result = call_773500.call(nil, nil, nil, nil, body_773501)

var deregisterManagedInstance* = Call_DeregisterManagedInstance_773487(
    name: "deregisterManagedInstance", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeregisterManagedInstance",
    validator: validate_DeregisterManagedInstance_773488, base: "/",
    url: url_DeregisterManagedInstance_773489,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterPatchBaselineForPatchGroup_773502 = ref object of OpenApiRestCall_772597
proc url_DeregisterPatchBaselineForPatchGroup_773504(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeregisterPatchBaselineForPatchGroup_773503(path: JsonNode;
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
  var valid_773505 = header.getOrDefault("X-Amz-Date")
  valid_773505 = validateParameter(valid_773505, JString, required = false,
                                 default = nil)
  if valid_773505 != nil:
    section.add "X-Amz-Date", valid_773505
  var valid_773506 = header.getOrDefault("X-Amz-Security-Token")
  valid_773506 = validateParameter(valid_773506, JString, required = false,
                                 default = nil)
  if valid_773506 != nil:
    section.add "X-Amz-Security-Token", valid_773506
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773507 = header.getOrDefault("X-Amz-Target")
  valid_773507 = validateParameter(valid_773507, JString, required = true, default = newJString(
      "AmazonSSM.DeregisterPatchBaselineForPatchGroup"))
  if valid_773507 != nil:
    section.add "X-Amz-Target", valid_773507
  var valid_773508 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773508 = validateParameter(valid_773508, JString, required = false,
                                 default = nil)
  if valid_773508 != nil:
    section.add "X-Amz-Content-Sha256", valid_773508
  var valid_773509 = header.getOrDefault("X-Amz-Algorithm")
  valid_773509 = validateParameter(valid_773509, JString, required = false,
                                 default = nil)
  if valid_773509 != nil:
    section.add "X-Amz-Algorithm", valid_773509
  var valid_773510 = header.getOrDefault("X-Amz-Signature")
  valid_773510 = validateParameter(valid_773510, JString, required = false,
                                 default = nil)
  if valid_773510 != nil:
    section.add "X-Amz-Signature", valid_773510
  var valid_773511 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773511 = validateParameter(valid_773511, JString, required = false,
                                 default = nil)
  if valid_773511 != nil:
    section.add "X-Amz-SignedHeaders", valid_773511
  var valid_773512 = header.getOrDefault("X-Amz-Credential")
  valid_773512 = validateParameter(valid_773512, JString, required = false,
                                 default = nil)
  if valid_773512 != nil:
    section.add "X-Amz-Credential", valid_773512
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773514: Call_DeregisterPatchBaselineForPatchGroup_773502;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Removes a patch group from a patch baseline.
  ## 
  let valid = call_773514.validator(path, query, header, formData, body)
  let scheme = call_773514.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773514.url(scheme.get, call_773514.host, call_773514.base,
                         call_773514.route, valid.getOrDefault("path"))
  result = hook(call_773514, url, valid)

proc call*(call_773515: Call_DeregisterPatchBaselineForPatchGroup_773502;
          body: JsonNode): Recallable =
  ## deregisterPatchBaselineForPatchGroup
  ## Removes a patch group from a patch baseline.
  ##   body: JObject (required)
  var body_773516 = newJObject()
  if body != nil:
    body_773516 = body
  result = call_773515.call(nil, nil, nil, nil, body_773516)

var deregisterPatchBaselineForPatchGroup* = Call_DeregisterPatchBaselineForPatchGroup_773502(
    name: "deregisterPatchBaselineForPatchGroup", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeregisterPatchBaselineForPatchGroup",
    validator: validate_DeregisterPatchBaselineForPatchGroup_773503, base: "/",
    url: url_DeregisterPatchBaselineForPatchGroup_773504,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterTargetFromMaintenanceWindow_773517 = ref object of OpenApiRestCall_772597
proc url_DeregisterTargetFromMaintenanceWindow_773519(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeregisterTargetFromMaintenanceWindow_773518(path: JsonNode;
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
  var valid_773520 = header.getOrDefault("X-Amz-Date")
  valid_773520 = validateParameter(valid_773520, JString, required = false,
                                 default = nil)
  if valid_773520 != nil:
    section.add "X-Amz-Date", valid_773520
  var valid_773521 = header.getOrDefault("X-Amz-Security-Token")
  valid_773521 = validateParameter(valid_773521, JString, required = false,
                                 default = nil)
  if valid_773521 != nil:
    section.add "X-Amz-Security-Token", valid_773521
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773522 = header.getOrDefault("X-Amz-Target")
  valid_773522 = validateParameter(valid_773522, JString, required = true, default = newJString(
      "AmazonSSM.DeregisterTargetFromMaintenanceWindow"))
  if valid_773522 != nil:
    section.add "X-Amz-Target", valid_773522
  var valid_773523 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773523 = validateParameter(valid_773523, JString, required = false,
                                 default = nil)
  if valid_773523 != nil:
    section.add "X-Amz-Content-Sha256", valid_773523
  var valid_773524 = header.getOrDefault("X-Amz-Algorithm")
  valid_773524 = validateParameter(valid_773524, JString, required = false,
                                 default = nil)
  if valid_773524 != nil:
    section.add "X-Amz-Algorithm", valid_773524
  var valid_773525 = header.getOrDefault("X-Amz-Signature")
  valid_773525 = validateParameter(valid_773525, JString, required = false,
                                 default = nil)
  if valid_773525 != nil:
    section.add "X-Amz-Signature", valid_773525
  var valid_773526 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773526 = validateParameter(valid_773526, JString, required = false,
                                 default = nil)
  if valid_773526 != nil:
    section.add "X-Amz-SignedHeaders", valid_773526
  var valid_773527 = header.getOrDefault("X-Amz-Credential")
  valid_773527 = validateParameter(valid_773527, JString, required = false,
                                 default = nil)
  if valid_773527 != nil:
    section.add "X-Amz-Credential", valid_773527
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773529: Call_DeregisterTargetFromMaintenanceWindow_773517;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Removes a target from a maintenance window.
  ## 
  let valid = call_773529.validator(path, query, header, formData, body)
  let scheme = call_773529.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773529.url(scheme.get, call_773529.host, call_773529.base,
                         call_773529.route, valid.getOrDefault("path"))
  result = hook(call_773529, url, valid)

proc call*(call_773530: Call_DeregisterTargetFromMaintenanceWindow_773517;
          body: JsonNode): Recallable =
  ## deregisterTargetFromMaintenanceWindow
  ## Removes a target from a maintenance window.
  ##   body: JObject (required)
  var body_773531 = newJObject()
  if body != nil:
    body_773531 = body
  result = call_773530.call(nil, nil, nil, nil, body_773531)

var deregisterTargetFromMaintenanceWindow* = Call_DeregisterTargetFromMaintenanceWindow_773517(
    name: "deregisterTargetFromMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeregisterTargetFromMaintenanceWindow",
    validator: validate_DeregisterTargetFromMaintenanceWindow_773518, base: "/",
    url: url_DeregisterTargetFromMaintenanceWindow_773519,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterTaskFromMaintenanceWindow_773532 = ref object of OpenApiRestCall_772597
proc url_DeregisterTaskFromMaintenanceWindow_773534(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeregisterTaskFromMaintenanceWindow_773533(path: JsonNode;
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
  var valid_773535 = header.getOrDefault("X-Amz-Date")
  valid_773535 = validateParameter(valid_773535, JString, required = false,
                                 default = nil)
  if valid_773535 != nil:
    section.add "X-Amz-Date", valid_773535
  var valid_773536 = header.getOrDefault("X-Amz-Security-Token")
  valid_773536 = validateParameter(valid_773536, JString, required = false,
                                 default = nil)
  if valid_773536 != nil:
    section.add "X-Amz-Security-Token", valid_773536
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773537 = header.getOrDefault("X-Amz-Target")
  valid_773537 = validateParameter(valid_773537, JString, required = true, default = newJString(
      "AmazonSSM.DeregisterTaskFromMaintenanceWindow"))
  if valid_773537 != nil:
    section.add "X-Amz-Target", valid_773537
  var valid_773538 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773538 = validateParameter(valid_773538, JString, required = false,
                                 default = nil)
  if valid_773538 != nil:
    section.add "X-Amz-Content-Sha256", valid_773538
  var valid_773539 = header.getOrDefault("X-Amz-Algorithm")
  valid_773539 = validateParameter(valid_773539, JString, required = false,
                                 default = nil)
  if valid_773539 != nil:
    section.add "X-Amz-Algorithm", valid_773539
  var valid_773540 = header.getOrDefault("X-Amz-Signature")
  valid_773540 = validateParameter(valid_773540, JString, required = false,
                                 default = nil)
  if valid_773540 != nil:
    section.add "X-Amz-Signature", valid_773540
  var valid_773541 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773541 = validateParameter(valid_773541, JString, required = false,
                                 default = nil)
  if valid_773541 != nil:
    section.add "X-Amz-SignedHeaders", valid_773541
  var valid_773542 = header.getOrDefault("X-Amz-Credential")
  valid_773542 = validateParameter(valid_773542, JString, required = false,
                                 default = nil)
  if valid_773542 != nil:
    section.add "X-Amz-Credential", valid_773542
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773544: Call_DeregisterTaskFromMaintenanceWindow_773532;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Removes a task from a maintenance window.
  ## 
  let valid = call_773544.validator(path, query, header, formData, body)
  let scheme = call_773544.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773544.url(scheme.get, call_773544.host, call_773544.base,
                         call_773544.route, valid.getOrDefault("path"))
  result = hook(call_773544, url, valid)

proc call*(call_773545: Call_DeregisterTaskFromMaintenanceWindow_773532;
          body: JsonNode): Recallable =
  ## deregisterTaskFromMaintenanceWindow
  ## Removes a task from a maintenance window.
  ##   body: JObject (required)
  var body_773546 = newJObject()
  if body != nil:
    body_773546 = body
  result = call_773545.call(nil, nil, nil, nil, body_773546)

var deregisterTaskFromMaintenanceWindow* = Call_DeregisterTaskFromMaintenanceWindow_773532(
    name: "deregisterTaskFromMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeregisterTaskFromMaintenanceWindow",
    validator: validate_DeregisterTaskFromMaintenanceWindow_773533, base: "/",
    url: url_DeregisterTaskFromMaintenanceWindow_773534,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeActivations_773547 = ref object of OpenApiRestCall_772597
proc url_DescribeActivations_773549(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeActivations_773548(path: JsonNode; query: JsonNode;
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
  var valid_773550 = query.getOrDefault("NextToken")
  valid_773550 = validateParameter(valid_773550, JString, required = false,
                                 default = nil)
  if valid_773550 != nil:
    section.add "NextToken", valid_773550
  var valid_773551 = query.getOrDefault("MaxResults")
  valid_773551 = validateParameter(valid_773551, JString, required = false,
                                 default = nil)
  if valid_773551 != nil:
    section.add "MaxResults", valid_773551
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
  var valid_773552 = header.getOrDefault("X-Amz-Date")
  valid_773552 = validateParameter(valid_773552, JString, required = false,
                                 default = nil)
  if valid_773552 != nil:
    section.add "X-Amz-Date", valid_773552
  var valid_773553 = header.getOrDefault("X-Amz-Security-Token")
  valid_773553 = validateParameter(valid_773553, JString, required = false,
                                 default = nil)
  if valid_773553 != nil:
    section.add "X-Amz-Security-Token", valid_773553
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773554 = header.getOrDefault("X-Amz-Target")
  valid_773554 = validateParameter(valid_773554, JString, required = true, default = newJString(
      "AmazonSSM.DescribeActivations"))
  if valid_773554 != nil:
    section.add "X-Amz-Target", valid_773554
  var valid_773555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773555 = validateParameter(valid_773555, JString, required = false,
                                 default = nil)
  if valid_773555 != nil:
    section.add "X-Amz-Content-Sha256", valid_773555
  var valid_773556 = header.getOrDefault("X-Amz-Algorithm")
  valid_773556 = validateParameter(valid_773556, JString, required = false,
                                 default = nil)
  if valid_773556 != nil:
    section.add "X-Amz-Algorithm", valid_773556
  var valid_773557 = header.getOrDefault("X-Amz-Signature")
  valid_773557 = validateParameter(valid_773557, JString, required = false,
                                 default = nil)
  if valid_773557 != nil:
    section.add "X-Amz-Signature", valid_773557
  var valid_773558 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773558 = validateParameter(valid_773558, JString, required = false,
                                 default = nil)
  if valid_773558 != nil:
    section.add "X-Amz-SignedHeaders", valid_773558
  var valid_773559 = header.getOrDefault("X-Amz-Credential")
  valid_773559 = validateParameter(valid_773559, JString, required = false,
                                 default = nil)
  if valid_773559 != nil:
    section.add "X-Amz-Credential", valid_773559
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773561: Call_DescribeActivations_773547; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes details about the activation, such as the date and time the activation was created, its expiration date, the IAM role assigned to the instances in the activation, and the number of instances registered by using this activation.
  ## 
  let valid = call_773561.validator(path, query, header, formData, body)
  let scheme = call_773561.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773561.url(scheme.get, call_773561.host, call_773561.base,
                         call_773561.route, valid.getOrDefault("path"))
  result = hook(call_773561, url, valid)

proc call*(call_773562: Call_DescribeActivations_773547; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## describeActivations
  ## Describes details about the activation, such as the date and time the activation was created, its expiration date, the IAM role assigned to the instances in the activation, and the number of instances registered by using this activation.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_773563 = newJObject()
  var body_773564 = newJObject()
  add(query_773563, "NextToken", newJString(NextToken))
  if body != nil:
    body_773564 = body
  add(query_773563, "MaxResults", newJString(MaxResults))
  result = call_773562.call(nil, query_773563, nil, nil, body_773564)

var describeActivations* = Call_DescribeActivations_773547(
    name: "describeActivations", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeActivations",
    validator: validate_DescribeActivations_773548, base: "/",
    url: url_DescribeActivations_773549, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAssociation_773566 = ref object of OpenApiRestCall_772597
proc url_DescribeAssociation_773568(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeAssociation_773567(path: JsonNode; query: JsonNode;
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
  var valid_773569 = header.getOrDefault("X-Amz-Date")
  valid_773569 = validateParameter(valid_773569, JString, required = false,
                                 default = nil)
  if valid_773569 != nil:
    section.add "X-Amz-Date", valid_773569
  var valid_773570 = header.getOrDefault("X-Amz-Security-Token")
  valid_773570 = validateParameter(valid_773570, JString, required = false,
                                 default = nil)
  if valid_773570 != nil:
    section.add "X-Amz-Security-Token", valid_773570
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773571 = header.getOrDefault("X-Amz-Target")
  valid_773571 = validateParameter(valid_773571, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAssociation"))
  if valid_773571 != nil:
    section.add "X-Amz-Target", valid_773571
  var valid_773572 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773572 = validateParameter(valid_773572, JString, required = false,
                                 default = nil)
  if valid_773572 != nil:
    section.add "X-Amz-Content-Sha256", valid_773572
  var valid_773573 = header.getOrDefault("X-Amz-Algorithm")
  valid_773573 = validateParameter(valid_773573, JString, required = false,
                                 default = nil)
  if valid_773573 != nil:
    section.add "X-Amz-Algorithm", valid_773573
  var valid_773574 = header.getOrDefault("X-Amz-Signature")
  valid_773574 = validateParameter(valid_773574, JString, required = false,
                                 default = nil)
  if valid_773574 != nil:
    section.add "X-Amz-Signature", valid_773574
  var valid_773575 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773575 = validateParameter(valid_773575, JString, required = false,
                                 default = nil)
  if valid_773575 != nil:
    section.add "X-Amz-SignedHeaders", valid_773575
  var valid_773576 = header.getOrDefault("X-Amz-Credential")
  valid_773576 = validateParameter(valid_773576, JString, required = false,
                                 default = nil)
  if valid_773576 != nil:
    section.add "X-Amz-Credential", valid_773576
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773578: Call_DescribeAssociation_773566; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the association for the specified target or instance. If you created the association by using the <code>Targets</code> parameter, then you must retrieve the association by using the association ID. If you created the association by specifying an instance ID and a Systems Manager document, then you retrieve the association by specifying the document name and the instance ID. 
  ## 
  let valid = call_773578.validator(path, query, header, formData, body)
  let scheme = call_773578.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773578.url(scheme.get, call_773578.host, call_773578.base,
                         call_773578.route, valid.getOrDefault("path"))
  result = hook(call_773578, url, valid)

proc call*(call_773579: Call_DescribeAssociation_773566; body: JsonNode): Recallable =
  ## describeAssociation
  ## Describes the association for the specified target or instance. If you created the association by using the <code>Targets</code> parameter, then you must retrieve the association by using the association ID. If you created the association by specifying an instance ID and a Systems Manager document, then you retrieve the association by specifying the document name and the instance ID. 
  ##   body: JObject (required)
  var body_773580 = newJObject()
  if body != nil:
    body_773580 = body
  result = call_773579.call(nil, nil, nil, nil, body_773580)

var describeAssociation* = Call_DescribeAssociation_773566(
    name: "describeAssociation", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAssociation",
    validator: validate_DescribeAssociation_773567, base: "/",
    url: url_DescribeAssociation_773568, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAssociationExecutionTargets_773581 = ref object of OpenApiRestCall_772597
proc url_DescribeAssociationExecutionTargets_773583(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeAssociationExecutionTargets_773582(path: JsonNode;
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
  var valid_773584 = header.getOrDefault("X-Amz-Date")
  valid_773584 = validateParameter(valid_773584, JString, required = false,
                                 default = nil)
  if valid_773584 != nil:
    section.add "X-Amz-Date", valid_773584
  var valid_773585 = header.getOrDefault("X-Amz-Security-Token")
  valid_773585 = validateParameter(valid_773585, JString, required = false,
                                 default = nil)
  if valid_773585 != nil:
    section.add "X-Amz-Security-Token", valid_773585
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773586 = header.getOrDefault("X-Amz-Target")
  valid_773586 = validateParameter(valid_773586, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAssociationExecutionTargets"))
  if valid_773586 != nil:
    section.add "X-Amz-Target", valid_773586
  var valid_773587 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773587 = validateParameter(valid_773587, JString, required = false,
                                 default = nil)
  if valid_773587 != nil:
    section.add "X-Amz-Content-Sha256", valid_773587
  var valid_773588 = header.getOrDefault("X-Amz-Algorithm")
  valid_773588 = validateParameter(valid_773588, JString, required = false,
                                 default = nil)
  if valid_773588 != nil:
    section.add "X-Amz-Algorithm", valid_773588
  var valid_773589 = header.getOrDefault("X-Amz-Signature")
  valid_773589 = validateParameter(valid_773589, JString, required = false,
                                 default = nil)
  if valid_773589 != nil:
    section.add "X-Amz-Signature", valid_773589
  var valid_773590 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773590 = validateParameter(valid_773590, JString, required = false,
                                 default = nil)
  if valid_773590 != nil:
    section.add "X-Amz-SignedHeaders", valid_773590
  var valid_773591 = header.getOrDefault("X-Amz-Credential")
  valid_773591 = validateParameter(valid_773591, JString, required = false,
                                 default = nil)
  if valid_773591 != nil:
    section.add "X-Amz-Credential", valid_773591
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773593: Call_DescribeAssociationExecutionTargets_773581;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Use this API action to view information about a specific execution of a specific association.
  ## 
  let valid = call_773593.validator(path, query, header, formData, body)
  let scheme = call_773593.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773593.url(scheme.get, call_773593.host, call_773593.base,
                         call_773593.route, valid.getOrDefault("path"))
  result = hook(call_773593, url, valid)

proc call*(call_773594: Call_DescribeAssociationExecutionTargets_773581;
          body: JsonNode): Recallable =
  ## describeAssociationExecutionTargets
  ## Use this API action to view information about a specific execution of a specific association.
  ##   body: JObject (required)
  var body_773595 = newJObject()
  if body != nil:
    body_773595 = body
  result = call_773594.call(nil, nil, nil, nil, body_773595)

var describeAssociationExecutionTargets* = Call_DescribeAssociationExecutionTargets_773581(
    name: "describeAssociationExecutionTargets", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAssociationExecutionTargets",
    validator: validate_DescribeAssociationExecutionTargets_773582, base: "/",
    url: url_DescribeAssociationExecutionTargets_773583,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAssociationExecutions_773596 = ref object of OpenApiRestCall_772597
proc url_DescribeAssociationExecutions_773598(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeAssociationExecutions_773597(path: JsonNode; query: JsonNode;
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
  var valid_773599 = header.getOrDefault("X-Amz-Date")
  valid_773599 = validateParameter(valid_773599, JString, required = false,
                                 default = nil)
  if valid_773599 != nil:
    section.add "X-Amz-Date", valid_773599
  var valid_773600 = header.getOrDefault("X-Amz-Security-Token")
  valid_773600 = validateParameter(valid_773600, JString, required = false,
                                 default = nil)
  if valid_773600 != nil:
    section.add "X-Amz-Security-Token", valid_773600
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773601 = header.getOrDefault("X-Amz-Target")
  valid_773601 = validateParameter(valid_773601, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAssociationExecutions"))
  if valid_773601 != nil:
    section.add "X-Amz-Target", valid_773601
  var valid_773602 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773602 = validateParameter(valid_773602, JString, required = false,
                                 default = nil)
  if valid_773602 != nil:
    section.add "X-Amz-Content-Sha256", valid_773602
  var valid_773603 = header.getOrDefault("X-Amz-Algorithm")
  valid_773603 = validateParameter(valid_773603, JString, required = false,
                                 default = nil)
  if valid_773603 != nil:
    section.add "X-Amz-Algorithm", valid_773603
  var valid_773604 = header.getOrDefault("X-Amz-Signature")
  valid_773604 = validateParameter(valid_773604, JString, required = false,
                                 default = nil)
  if valid_773604 != nil:
    section.add "X-Amz-Signature", valid_773604
  var valid_773605 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773605 = validateParameter(valid_773605, JString, required = false,
                                 default = nil)
  if valid_773605 != nil:
    section.add "X-Amz-SignedHeaders", valid_773605
  var valid_773606 = header.getOrDefault("X-Amz-Credential")
  valid_773606 = validateParameter(valid_773606, JString, required = false,
                                 default = nil)
  if valid_773606 != nil:
    section.add "X-Amz-Credential", valid_773606
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773608: Call_DescribeAssociationExecutions_773596; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Use this API action to view all executions for a specific association ID. 
  ## 
  let valid = call_773608.validator(path, query, header, formData, body)
  let scheme = call_773608.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773608.url(scheme.get, call_773608.host, call_773608.base,
                         call_773608.route, valid.getOrDefault("path"))
  result = hook(call_773608, url, valid)

proc call*(call_773609: Call_DescribeAssociationExecutions_773596; body: JsonNode): Recallable =
  ## describeAssociationExecutions
  ## Use this API action to view all executions for a specific association ID. 
  ##   body: JObject (required)
  var body_773610 = newJObject()
  if body != nil:
    body_773610 = body
  result = call_773609.call(nil, nil, nil, nil, body_773610)

var describeAssociationExecutions* = Call_DescribeAssociationExecutions_773596(
    name: "describeAssociationExecutions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAssociationExecutions",
    validator: validate_DescribeAssociationExecutions_773597, base: "/",
    url: url_DescribeAssociationExecutions_773598,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAutomationExecutions_773611 = ref object of OpenApiRestCall_772597
proc url_DescribeAutomationExecutions_773613(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeAutomationExecutions_773612(path: JsonNode; query: JsonNode;
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
  var valid_773614 = header.getOrDefault("X-Amz-Date")
  valid_773614 = validateParameter(valid_773614, JString, required = false,
                                 default = nil)
  if valid_773614 != nil:
    section.add "X-Amz-Date", valid_773614
  var valid_773615 = header.getOrDefault("X-Amz-Security-Token")
  valid_773615 = validateParameter(valid_773615, JString, required = false,
                                 default = nil)
  if valid_773615 != nil:
    section.add "X-Amz-Security-Token", valid_773615
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773616 = header.getOrDefault("X-Amz-Target")
  valid_773616 = validateParameter(valid_773616, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAutomationExecutions"))
  if valid_773616 != nil:
    section.add "X-Amz-Target", valid_773616
  var valid_773617 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773617 = validateParameter(valid_773617, JString, required = false,
                                 default = nil)
  if valid_773617 != nil:
    section.add "X-Amz-Content-Sha256", valid_773617
  var valid_773618 = header.getOrDefault("X-Amz-Algorithm")
  valid_773618 = validateParameter(valid_773618, JString, required = false,
                                 default = nil)
  if valid_773618 != nil:
    section.add "X-Amz-Algorithm", valid_773618
  var valid_773619 = header.getOrDefault("X-Amz-Signature")
  valid_773619 = validateParameter(valid_773619, JString, required = false,
                                 default = nil)
  if valid_773619 != nil:
    section.add "X-Amz-Signature", valid_773619
  var valid_773620 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773620 = validateParameter(valid_773620, JString, required = false,
                                 default = nil)
  if valid_773620 != nil:
    section.add "X-Amz-SignedHeaders", valid_773620
  var valid_773621 = header.getOrDefault("X-Amz-Credential")
  valid_773621 = validateParameter(valid_773621, JString, required = false,
                                 default = nil)
  if valid_773621 != nil:
    section.add "X-Amz-Credential", valid_773621
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773623: Call_DescribeAutomationExecutions_773611; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides details about all active and terminated Automation executions.
  ## 
  let valid = call_773623.validator(path, query, header, formData, body)
  let scheme = call_773623.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773623.url(scheme.get, call_773623.host, call_773623.base,
                         call_773623.route, valid.getOrDefault("path"))
  result = hook(call_773623, url, valid)

proc call*(call_773624: Call_DescribeAutomationExecutions_773611; body: JsonNode): Recallable =
  ## describeAutomationExecutions
  ## Provides details about all active and terminated Automation executions.
  ##   body: JObject (required)
  var body_773625 = newJObject()
  if body != nil:
    body_773625 = body
  result = call_773624.call(nil, nil, nil, nil, body_773625)

var describeAutomationExecutions* = Call_DescribeAutomationExecutions_773611(
    name: "describeAutomationExecutions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAutomationExecutions",
    validator: validate_DescribeAutomationExecutions_773612, base: "/",
    url: url_DescribeAutomationExecutions_773613,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAutomationStepExecutions_773626 = ref object of OpenApiRestCall_772597
proc url_DescribeAutomationStepExecutions_773628(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeAutomationStepExecutions_773627(path: JsonNode;
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
  var valid_773629 = header.getOrDefault("X-Amz-Date")
  valid_773629 = validateParameter(valid_773629, JString, required = false,
                                 default = nil)
  if valid_773629 != nil:
    section.add "X-Amz-Date", valid_773629
  var valid_773630 = header.getOrDefault("X-Amz-Security-Token")
  valid_773630 = validateParameter(valid_773630, JString, required = false,
                                 default = nil)
  if valid_773630 != nil:
    section.add "X-Amz-Security-Token", valid_773630
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773631 = header.getOrDefault("X-Amz-Target")
  valid_773631 = validateParameter(valid_773631, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAutomationStepExecutions"))
  if valid_773631 != nil:
    section.add "X-Amz-Target", valid_773631
  var valid_773632 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773632 = validateParameter(valid_773632, JString, required = false,
                                 default = nil)
  if valid_773632 != nil:
    section.add "X-Amz-Content-Sha256", valid_773632
  var valid_773633 = header.getOrDefault("X-Amz-Algorithm")
  valid_773633 = validateParameter(valid_773633, JString, required = false,
                                 default = nil)
  if valid_773633 != nil:
    section.add "X-Amz-Algorithm", valid_773633
  var valid_773634 = header.getOrDefault("X-Amz-Signature")
  valid_773634 = validateParameter(valid_773634, JString, required = false,
                                 default = nil)
  if valid_773634 != nil:
    section.add "X-Amz-Signature", valid_773634
  var valid_773635 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773635 = validateParameter(valid_773635, JString, required = false,
                                 default = nil)
  if valid_773635 != nil:
    section.add "X-Amz-SignedHeaders", valid_773635
  var valid_773636 = header.getOrDefault("X-Amz-Credential")
  valid_773636 = validateParameter(valid_773636, JString, required = false,
                                 default = nil)
  if valid_773636 != nil:
    section.add "X-Amz-Credential", valid_773636
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773638: Call_DescribeAutomationStepExecutions_773626;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Information about all active and terminated step executions in an Automation workflow.
  ## 
  let valid = call_773638.validator(path, query, header, formData, body)
  let scheme = call_773638.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773638.url(scheme.get, call_773638.host, call_773638.base,
                         call_773638.route, valid.getOrDefault("path"))
  result = hook(call_773638, url, valid)

proc call*(call_773639: Call_DescribeAutomationStepExecutions_773626;
          body: JsonNode): Recallable =
  ## describeAutomationStepExecutions
  ## Information about all active and terminated step executions in an Automation workflow.
  ##   body: JObject (required)
  var body_773640 = newJObject()
  if body != nil:
    body_773640 = body
  result = call_773639.call(nil, nil, nil, nil, body_773640)

var describeAutomationStepExecutions* = Call_DescribeAutomationStepExecutions_773626(
    name: "describeAutomationStepExecutions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAutomationStepExecutions",
    validator: validate_DescribeAutomationStepExecutions_773627, base: "/",
    url: url_DescribeAutomationStepExecutions_773628,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAvailablePatches_773641 = ref object of OpenApiRestCall_772597
proc url_DescribeAvailablePatches_773643(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeAvailablePatches_773642(path: JsonNode; query: JsonNode;
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
  var valid_773644 = header.getOrDefault("X-Amz-Date")
  valid_773644 = validateParameter(valid_773644, JString, required = false,
                                 default = nil)
  if valid_773644 != nil:
    section.add "X-Amz-Date", valid_773644
  var valid_773645 = header.getOrDefault("X-Amz-Security-Token")
  valid_773645 = validateParameter(valid_773645, JString, required = false,
                                 default = nil)
  if valid_773645 != nil:
    section.add "X-Amz-Security-Token", valid_773645
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773646 = header.getOrDefault("X-Amz-Target")
  valid_773646 = validateParameter(valid_773646, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAvailablePatches"))
  if valid_773646 != nil:
    section.add "X-Amz-Target", valid_773646
  var valid_773647 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773647 = validateParameter(valid_773647, JString, required = false,
                                 default = nil)
  if valid_773647 != nil:
    section.add "X-Amz-Content-Sha256", valid_773647
  var valid_773648 = header.getOrDefault("X-Amz-Algorithm")
  valid_773648 = validateParameter(valid_773648, JString, required = false,
                                 default = nil)
  if valid_773648 != nil:
    section.add "X-Amz-Algorithm", valid_773648
  var valid_773649 = header.getOrDefault("X-Amz-Signature")
  valid_773649 = validateParameter(valid_773649, JString, required = false,
                                 default = nil)
  if valid_773649 != nil:
    section.add "X-Amz-Signature", valid_773649
  var valid_773650 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773650 = validateParameter(valid_773650, JString, required = false,
                                 default = nil)
  if valid_773650 != nil:
    section.add "X-Amz-SignedHeaders", valid_773650
  var valid_773651 = header.getOrDefault("X-Amz-Credential")
  valid_773651 = validateParameter(valid_773651, JString, required = false,
                                 default = nil)
  if valid_773651 != nil:
    section.add "X-Amz-Credential", valid_773651
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773653: Call_DescribeAvailablePatches_773641; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all patches eligible to be included in a patch baseline.
  ## 
  let valid = call_773653.validator(path, query, header, formData, body)
  let scheme = call_773653.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773653.url(scheme.get, call_773653.host, call_773653.base,
                         call_773653.route, valid.getOrDefault("path"))
  result = hook(call_773653, url, valid)

proc call*(call_773654: Call_DescribeAvailablePatches_773641; body: JsonNode): Recallable =
  ## describeAvailablePatches
  ## Lists all patches eligible to be included in a patch baseline.
  ##   body: JObject (required)
  var body_773655 = newJObject()
  if body != nil:
    body_773655 = body
  result = call_773654.call(nil, nil, nil, nil, body_773655)

var describeAvailablePatches* = Call_DescribeAvailablePatches_773641(
    name: "describeAvailablePatches", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAvailablePatches",
    validator: validate_DescribeAvailablePatches_773642, base: "/",
    url: url_DescribeAvailablePatches_773643, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDocument_773656 = ref object of OpenApiRestCall_772597
proc url_DescribeDocument_773658(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeDocument_773657(path: JsonNode; query: JsonNode;
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
  var valid_773659 = header.getOrDefault("X-Amz-Date")
  valid_773659 = validateParameter(valid_773659, JString, required = false,
                                 default = nil)
  if valid_773659 != nil:
    section.add "X-Amz-Date", valid_773659
  var valid_773660 = header.getOrDefault("X-Amz-Security-Token")
  valid_773660 = validateParameter(valid_773660, JString, required = false,
                                 default = nil)
  if valid_773660 != nil:
    section.add "X-Amz-Security-Token", valid_773660
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773661 = header.getOrDefault("X-Amz-Target")
  valid_773661 = validateParameter(valid_773661, JString, required = true, default = newJString(
      "AmazonSSM.DescribeDocument"))
  if valid_773661 != nil:
    section.add "X-Amz-Target", valid_773661
  var valid_773662 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773662 = validateParameter(valid_773662, JString, required = false,
                                 default = nil)
  if valid_773662 != nil:
    section.add "X-Amz-Content-Sha256", valid_773662
  var valid_773663 = header.getOrDefault("X-Amz-Algorithm")
  valid_773663 = validateParameter(valid_773663, JString, required = false,
                                 default = nil)
  if valid_773663 != nil:
    section.add "X-Amz-Algorithm", valid_773663
  var valid_773664 = header.getOrDefault("X-Amz-Signature")
  valid_773664 = validateParameter(valid_773664, JString, required = false,
                                 default = nil)
  if valid_773664 != nil:
    section.add "X-Amz-Signature", valid_773664
  var valid_773665 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773665 = validateParameter(valid_773665, JString, required = false,
                                 default = nil)
  if valid_773665 != nil:
    section.add "X-Amz-SignedHeaders", valid_773665
  var valid_773666 = header.getOrDefault("X-Amz-Credential")
  valid_773666 = validateParameter(valid_773666, JString, required = false,
                                 default = nil)
  if valid_773666 != nil:
    section.add "X-Amz-Credential", valid_773666
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773668: Call_DescribeDocument_773656; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified Systems Manager document.
  ## 
  let valid = call_773668.validator(path, query, header, formData, body)
  let scheme = call_773668.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773668.url(scheme.get, call_773668.host, call_773668.base,
                         call_773668.route, valid.getOrDefault("path"))
  result = hook(call_773668, url, valid)

proc call*(call_773669: Call_DescribeDocument_773656; body: JsonNode): Recallable =
  ## describeDocument
  ## Describes the specified Systems Manager document.
  ##   body: JObject (required)
  var body_773670 = newJObject()
  if body != nil:
    body_773670 = body
  result = call_773669.call(nil, nil, nil, nil, body_773670)

var describeDocument* = Call_DescribeDocument_773656(name: "describeDocument",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeDocument",
    validator: validate_DescribeDocument_773657, base: "/",
    url: url_DescribeDocument_773658, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDocumentPermission_773671 = ref object of OpenApiRestCall_772597
proc url_DescribeDocumentPermission_773673(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeDocumentPermission_773672(path: JsonNode; query: JsonNode;
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
  var valid_773674 = header.getOrDefault("X-Amz-Date")
  valid_773674 = validateParameter(valid_773674, JString, required = false,
                                 default = nil)
  if valid_773674 != nil:
    section.add "X-Amz-Date", valid_773674
  var valid_773675 = header.getOrDefault("X-Amz-Security-Token")
  valid_773675 = validateParameter(valid_773675, JString, required = false,
                                 default = nil)
  if valid_773675 != nil:
    section.add "X-Amz-Security-Token", valid_773675
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773676 = header.getOrDefault("X-Amz-Target")
  valid_773676 = validateParameter(valid_773676, JString, required = true, default = newJString(
      "AmazonSSM.DescribeDocumentPermission"))
  if valid_773676 != nil:
    section.add "X-Amz-Target", valid_773676
  var valid_773677 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773677 = validateParameter(valid_773677, JString, required = false,
                                 default = nil)
  if valid_773677 != nil:
    section.add "X-Amz-Content-Sha256", valid_773677
  var valid_773678 = header.getOrDefault("X-Amz-Algorithm")
  valid_773678 = validateParameter(valid_773678, JString, required = false,
                                 default = nil)
  if valid_773678 != nil:
    section.add "X-Amz-Algorithm", valid_773678
  var valid_773679 = header.getOrDefault("X-Amz-Signature")
  valid_773679 = validateParameter(valid_773679, JString, required = false,
                                 default = nil)
  if valid_773679 != nil:
    section.add "X-Amz-Signature", valid_773679
  var valid_773680 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773680 = validateParameter(valid_773680, JString, required = false,
                                 default = nil)
  if valid_773680 != nil:
    section.add "X-Amz-SignedHeaders", valid_773680
  var valid_773681 = header.getOrDefault("X-Amz-Credential")
  valid_773681 = validateParameter(valid_773681, JString, required = false,
                                 default = nil)
  if valid_773681 != nil:
    section.add "X-Amz-Credential", valid_773681
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773683: Call_DescribeDocumentPermission_773671; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the permissions for a Systems Manager document. If you created the document, you are the owner. If a document is shared, it can either be shared privately (by specifying a user's AWS account ID) or publicly (<i>All</i>). 
  ## 
  let valid = call_773683.validator(path, query, header, formData, body)
  let scheme = call_773683.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773683.url(scheme.get, call_773683.host, call_773683.base,
                         call_773683.route, valid.getOrDefault("path"))
  result = hook(call_773683, url, valid)

proc call*(call_773684: Call_DescribeDocumentPermission_773671; body: JsonNode): Recallable =
  ## describeDocumentPermission
  ## Describes the permissions for a Systems Manager document. If you created the document, you are the owner. If a document is shared, it can either be shared privately (by specifying a user's AWS account ID) or publicly (<i>All</i>). 
  ##   body: JObject (required)
  var body_773685 = newJObject()
  if body != nil:
    body_773685 = body
  result = call_773684.call(nil, nil, nil, nil, body_773685)

var describeDocumentPermission* = Call_DescribeDocumentPermission_773671(
    name: "describeDocumentPermission", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeDocumentPermission",
    validator: validate_DescribeDocumentPermission_773672, base: "/",
    url: url_DescribeDocumentPermission_773673,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEffectiveInstanceAssociations_773686 = ref object of OpenApiRestCall_772597
proc url_DescribeEffectiveInstanceAssociations_773688(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeEffectiveInstanceAssociations_773687(path: JsonNode;
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
  var valid_773689 = header.getOrDefault("X-Amz-Date")
  valid_773689 = validateParameter(valid_773689, JString, required = false,
                                 default = nil)
  if valid_773689 != nil:
    section.add "X-Amz-Date", valid_773689
  var valid_773690 = header.getOrDefault("X-Amz-Security-Token")
  valid_773690 = validateParameter(valid_773690, JString, required = false,
                                 default = nil)
  if valid_773690 != nil:
    section.add "X-Amz-Security-Token", valid_773690
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773691 = header.getOrDefault("X-Amz-Target")
  valid_773691 = validateParameter(valid_773691, JString, required = true, default = newJString(
      "AmazonSSM.DescribeEffectiveInstanceAssociations"))
  if valid_773691 != nil:
    section.add "X-Amz-Target", valid_773691
  var valid_773692 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773692 = validateParameter(valid_773692, JString, required = false,
                                 default = nil)
  if valid_773692 != nil:
    section.add "X-Amz-Content-Sha256", valid_773692
  var valid_773693 = header.getOrDefault("X-Amz-Algorithm")
  valid_773693 = validateParameter(valid_773693, JString, required = false,
                                 default = nil)
  if valid_773693 != nil:
    section.add "X-Amz-Algorithm", valid_773693
  var valid_773694 = header.getOrDefault("X-Amz-Signature")
  valid_773694 = validateParameter(valid_773694, JString, required = false,
                                 default = nil)
  if valid_773694 != nil:
    section.add "X-Amz-Signature", valid_773694
  var valid_773695 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773695 = validateParameter(valid_773695, JString, required = false,
                                 default = nil)
  if valid_773695 != nil:
    section.add "X-Amz-SignedHeaders", valid_773695
  var valid_773696 = header.getOrDefault("X-Amz-Credential")
  valid_773696 = validateParameter(valid_773696, JString, required = false,
                                 default = nil)
  if valid_773696 != nil:
    section.add "X-Amz-Credential", valid_773696
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773698: Call_DescribeEffectiveInstanceAssociations_773686;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## All associations for the instance(s).
  ## 
  let valid = call_773698.validator(path, query, header, formData, body)
  let scheme = call_773698.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773698.url(scheme.get, call_773698.host, call_773698.base,
                         call_773698.route, valid.getOrDefault("path"))
  result = hook(call_773698, url, valid)

proc call*(call_773699: Call_DescribeEffectiveInstanceAssociations_773686;
          body: JsonNode): Recallable =
  ## describeEffectiveInstanceAssociations
  ## All associations for the instance(s).
  ##   body: JObject (required)
  var body_773700 = newJObject()
  if body != nil:
    body_773700 = body
  result = call_773699.call(nil, nil, nil, nil, body_773700)

var describeEffectiveInstanceAssociations* = Call_DescribeEffectiveInstanceAssociations_773686(
    name: "describeEffectiveInstanceAssociations", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeEffectiveInstanceAssociations",
    validator: validate_DescribeEffectiveInstanceAssociations_773687, base: "/",
    url: url_DescribeEffectiveInstanceAssociations_773688,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEffectivePatchesForPatchBaseline_773701 = ref object of OpenApiRestCall_772597
proc url_DescribeEffectivePatchesForPatchBaseline_773703(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeEffectivePatchesForPatchBaseline_773702(path: JsonNode;
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
  var valid_773704 = header.getOrDefault("X-Amz-Date")
  valid_773704 = validateParameter(valid_773704, JString, required = false,
                                 default = nil)
  if valid_773704 != nil:
    section.add "X-Amz-Date", valid_773704
  var valid_773705 = header.getOrDefault("X-Amz-Security-Token")
  valid_773705 = validateParameter(valid_773705, JString, required = false,
                                 default = nil)
  if valid_773705 != nil:
    section.add "X-Amz-Security-Token", valid_773705
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773706 = header.getOrDefault("X-Amz-Target")
  valid_773706 = validateParameter(valid_773706, JString, required = true, default = newJString(
      "AmazonSSM.DescribeEffectivePatchesForPatchBaseline"))
  if valid_773706 != nil:
    section.add "X-Amz-Target", valid_773706
  var valid_773707 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773707 = validateParameter(valid_773707, JString, required = false,
                                 default = nil)
  if valid_773707 != nil:
    section.add "X-Amz-Content-Sha256", valid_773707
  var valid_773708 = header.getOrDefault("X-Amz-Algorithm")
  valid_773708 = validateParameter(valid_773708, JString, required = false,
                                 default = nil)
  if valid_773708 != nil:
    section.add "X-Amz-Algorithm", valid_773708
  var valid_773709 = header.getOrDefault("X-Amz-Signature")
  valid_773709 = validateParameter(valid_773709, JString, required = false,
                                 default = nil)
  if valid_773709 != nil:
    section.add "X-Amz-Signature", valid_773709
  var valid_773710 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773710 = validateParameter(valid_773710, JString, required = false,
                                 default = nil)
  if valid_773710 != nil:
    section.add "X-Amz-SignedHeaders", valid_773710
  var valid_773711 = header.getOrDefault("X-Amz-Credential")
  valid_773711 = validateParameter(valid_773711, JString, required = false,
                                 default = nil)
  if valid_773711 != nil:
    section.add "X-Amz-Credential", valid_773711
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773713: Call_DescribeEffectivePatchesForPatchBaseline_773701;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the current effective patches (the patch and the approval state) for the specified patch baseline. Note that this API applies only to Windows patch baselines.
  ## 
  let valid = call_773713.validator(path, query, header, formData, body)
  let scheme = call_773713.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773713.url(scheme.get, call_773713.host, call_773713.base,
                         call_773713.route, valid.getOrDefault("path"))
  result = hook(call_773713, url, valid)

proc call*(call_773714: Call_DescribeEffectivePatchesForPatchBaseline_773701;
          body: JsonNode): Recallable =
  ## describeEffectivePatchesForPatchBaseline
  ## Retrieves the current effective patches (the patch and the approval state) for the specified patch baseline. Note that this API applies only to Windows patch baselines.
  ##   body: JObject (required)
  var body_773715 = newJObject()
  if body != nil:
    body_773715 = body
  result = call_773714.call(nil, nil, nil, nil, body_773715)

var describeEffectivePatchesForPatchBaseline* = Call_DescribeEffectivePatchesForPatchBaseline_773701(
    name: "describeEffectivePatchesForPatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeEffectivePatchesForPatchBaseline",
    validator: validate_DescribeEffectivePatchesForPatchBaseline_773702,
    base: "/", url: url_DescribeEffectivePatchesForPatchBaseline_773703,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInstanceAssociationsStatus_773716 = ref object of OpenApiRestCall_772597
proc url_DescribeInstanceAssociationsStatus_773718(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeInstanceAssociationsStatus_773717(path: JsonNode;
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
  var valid_773719 = header.getOrDefault("X-Amz-Date")
  valid_773719 = validateParameter(valid_773719, JString, required = false,
                                 default = nil)
  if valid_773719 != nil:
    section.add "X-Amz-Date", valid_773719
  var valid_773720 = header.getOrDefault("X-Amz-Security-Token")
  valid_773720 = validateParameter(valid_773720, JString, required = false,
                                 default = nil)
  if valid_773720 != nil:
    section.add "X-Amz-Security-Token", valid_773720
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773721 = header.getOrDefault("X-Amz-Target")
  valid_773721 = validateParameter(valid_773721, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInstanceAssociationsStatus"))
  if valid_773721 != nil:
    section.add "X-Amz-Target", valid_773721
  var valid_773722 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773722 = validateParameter(valid_773722, JString, required = false,
                                 default = nil)
  if valid_773722 != nil:
    section.add "X-Amz-Content-Sha256", valid_773722
  var valid_773723 = header.getOrDefault("X-Amz-Algorithm")
  valid_773723 = validateParameter(valid_773723, JString, required = false,
                                 default = nil)
  if valid_773723 != nil:
    section.add "X-Amz-Algorithm", valid_773723
  var valid_773724 = header.getOrDefault("X-Amz-Signature")
  valid_773724 = validateParameter(valid_773724, JString, required = false,
                                 default = nil)
  if valid_773724 != nil:
    section.add "X-Amz-Signature", valid_773724
  var valid_773725 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773725 = validateParameter(valid_773725, JString, required = false,
                                 default = nil)
  if valid_773725 != nil:
    section.add "X-Amz-SignedHeaders", valid_773725
  var valid_773726 = header.getOrDefault("X-Amz-Credential")
  valid_773726 = validateParameter(valid_773726, JString, required = false,
                                 default = nil)
  if valid_773726 != nil:
    section.add "X-Amz-Credential", valid_773726
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773728: Call_DescribeInstanceAssociationsStatus_773716;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## The status of the associations for the instance(s).
  ## 
  let valid = call_773728.validator(path, query, header, formData, body)
  let scheme = call_773728.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773728.url(scheme.get, call_773728.host, call_773728.base,
                         call_773728.route, valid.getOrDefault("path"))
  result = hook(call_773728, url, valid)

proc call*(call_773729: Call_DescribeInstanceAssociationsStatus_773716;
          body: JsonNode): Recallable =
  ## describeInstanceAssociationsStatus
  ## The status of the associations for the instance(s).
  ##   body: JObject (required)
  var body_773730 = newJObject()
  if body != nil:
    body_773730 = body
  result = call_773729.call(nil, nil, nil, nil, body_773730)

var describeInstanceAssociationsStatus* = Call_DescribeInstanceAssociationsStatus_773716(
    name: "describeInstanceAssociationsStatus", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInstanceAssociationsStatus",
    validator: validate_DescribeInstanceAssociationsStatus_773717, base: "/",
    url: url_DescribeInstanceAssociationsStatus_773718,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInstanceInformation_773731 = ref object of OpenApiRestCall_772597
proc url_DescribeInstanceInformation_773733(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeInstanceInformation_773732(path: JsonNode; query: JsonNode;
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
  var valid_773734 = query.getOrDefault("NextToken")
  valid_773734 = validateParameter(valid_773734, JString, required = false,
                                 default = nil)
  if valid_773734 != nil:
    section.add "NextToken", valid_773734
  var valid_773735 = query.getOrDefault("MaxResults")
  valid_773735 = validateParameter(valid_773735, JString, required = false,
                                 default = nil)
  if valid_773735 != nil:
    section.add "MaxResults", valid_773735
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
  var valid_773736 = header.getOrDefault("X-Amz-Date")
  valid_773736 = validateParameter(valid_773736, JString, required = false,
                                 default = nil)
  if valid_773736 != nil:
    section.add "X-Amz-Date", valid_773736
  var valid_773737 = header.getOrDefault("X-Amz-Security-Token")
  valid_773737 = validateParameter(valid_773737, JString, required = false,
                                 default = nil)
  if valid_773737 != nil:
    section.add "X-Amz-Security-Token", valid_773737
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773738 = header.getOrDefault("X-Amz-Target")
  valid_773738 = validateParameter(valid_773738, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInstanceInformation"))
  if valid_773738 != nil:
    section.add "X-Amz-Target", valid_773738
  var valid_773739 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773739 = validateParameter(valid_773739, JString, required = false,
                                 default = nil)
  if valid_773739 != nil:
    section.add "X-Amz-Content-Sha256", valid_773739
  var valid_773740 = header.getOrDefault("X-Amz-Algorithm")
  valid_773740 = validateParameter(valid_773740, JString, required = false,
                                 default = nil)
  if valid_773740 != nil:
    section.add "X-Amz-Algorithm", valid_773740
  var valid_773741 = header.getOrDefault("X-Amz-Signature")
  valid_773741 = validateParameter(valid_773741, JString, required = false,
                                 default = nil)
  if valid_773741 != nil:
    section.add "X-Amz-Signature", valid_773741
  var valid_773742 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773742 = validateParameter(valid_773742, JString, required = false,
                                 default = nil)
  if valid_773742 != nil:
    section.add "X-Amz-SignedHeaders", valid_773742
  var valid_773743 = header.getOrDefault("X-Amz-Credential")
  valid_773743 = validateParameter(valid_773743, JString, required = false,
                                 default = nil)
  if valid_773743 != nil:
    section.add "X-Amz-Credential", valid_773743
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773745: Call_DescribeInstanceInformation_773731; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes one or more of your instances. You can use this to get information about instances like the operating system platform, the SSM Agent version (Linux), status etc. If you specify one or more instance IDs, it returns information for those instances. If you do not specify instance IDs, it returns information for all your instances. If you specify an instance ID that is not valid or an instance that you do not own, you receive an error. </p> <note> <p>The IamRole field for this API action is the Amazon Identity and Access Management (IAM) role assigned to on-premises instances. This call does not return the IAM role for Amazon EC2 instances.</p> </note>
  ## 
  let valid = call_773745.validator(path, query, header, formData, body)
  let scheme = call_773745.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773745.url(scheme.get, call_773745.host, call_773745.base,
                         call_773745.route, valid.getOrDefault("path"))
  result = hook(call_773745, url, valid)

proc call*(call_773746: Call_DescribeInstanceInformation_773731; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## describeInstanceInformation
  ## <p>Describes one or more of your instances. You can use this to get information about instances like the operating system platform, the SSM Agent version (Linux), status etc. If you specify one or more instance IDs, it returns information for those instances. If you do not specify instance IDs, it returns information for all your instances. If you specify an instance ID that is not valid or an instance that you do not own, you receive an error. </p> <note> <p>The IamRole field for this API action is the Amazon Identity and Access Management (IAM) role assigned to on-premises instances. This call does not return the IAM role for Amazon EC2 instances.</p> </note>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_773747 = newJObject()
  var body_773748 = newJObject()
  add(query_773747, "NextToken", newJString(NextToken))
  if body != nil:
    body_773748 = body
  add(query_773747, "MaxResults", newJString(MaxResults))
  result = call_773746.call(nil, query_773747, nil, nil, body_773748)

var describeInstanceInformation* = Call_DescribeInstanceInformation_773731(
    name: "describeInstanceInformation", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInstanceInformation",
    validator: validate_DescribeInstanceInformation_773732, base: "/",
    url: url_DescribeInstanceInformation_773733,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInstancePatchStates_773749 = ref object of OpenApiRestCall_772597
proc url_DescribeInstancePatchStates_773751(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeInstancePatchStates_773750(path: JsonNode; query: JsonNode;
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
  var valid_773752 = header.getOrDefault("X-Amz-Date")
  valid_773752 = validateParameter(valid_773752, JString, required = false,
                                 default = nil)
  if valid_773752 != nil:
    section.add "X-Amz-Date", valid_773752
  var valid_773753 = header.getOrDefault("X-Amz-Security-Token")
  valid_773753 = validateParameter(valid_773753, JString, required = false,
                                 default = nil)
  if valid_773753 != nil:
    section.add "X-Amz-Security-Token", valid_773753
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773754 = header.getOrDefault("X-Amz-Target")
  valid_773754 = validateParameter(valid_773754, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInstancePatchStates"))
  if valid_773754 != nil:
    section.add "X-Amz-Target", valid_773754
  var valid_773755 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773755 = validateParameter(valid_773755, JString, required = false,
                                 default = nil)
  if valid_773755 != nil:
    section.add "X-Amz-Content-Sha256", valid_773755
  var valid_773756 = header.getOrDefault("X-Amz-Algorithm")
  valid_773756 = validateParameter(valid_773756, JString, required = false,
                                 default = nil)
  if valid_773756 != nil:
    section.add "X-Amz-Algorithm", valid_773756
  var valid_773757 = header.getOrDefault("X-Amz-Signature")
  valid_773757 = validateParameter(valid_773757, JString, required = false,
                                 default = nil)
  if valid_773757 != nil:
    section.add "X-Amz-Signature", valid_773757
  var valid_773758 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773758 = validateParameter(valid_773758, JString, required = false,
                                 default = nil)
  if valid_773758 != nil:
    section.add "X-Amz-SignedHeaders", valid_773758
  var valid_773759 = header.getOrDefault("X-Amz-Credential")
  valid_773759 = validateParameter(valid_773759, JString, required = false,
                                 default = nil)
  if valid_773759 != nil:
    section.add "X-Amz-Credential", valid_773759
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773761: Call_DescribeInstancePatchStates_773749; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the high-level patch state of one or more instances.
  ## 
  let valid = call_773761.validator(path, query, header, formData, body)
  let scheme = call_773761.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773761.url(scheme.get, call_773761.host, call_773761.base,
                         call_773761.route, valid.getOrDefault("path"))
  result = hook(call_773761, url, valid)

proc call*(call_773762: Call_DescribeInstancePatchStates_773749; body: JsonNode): Recallable =
  ## describeInstancePatchStates
  ## Retrieves the high-level patch state of one or more instances.
  ##   body: JObject (required)
  var body_773763 = newJObject()
  if body != nil:
    body_773763 = body
  result = call_773762.call(nil, nil, nil, nil, body_773763)

var describeInstancePatchStates* = Call_DescribeInstancePatchStates_773749(
    name: "describeInstancePatchStates", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInstancePatchStates",
    validator: validate_DescribeInstancePatchStates_773750, base: "/",
    url: url_DescribeInstancePatchStates_773751,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInstancePatchStatesForPatchGroup_773764 = ref object of OpenApiRestCall_772597
proc url_DescribeInstancePatchStatesForPatchGroup_773766(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeInstancePatchStatesForPatchGroup_773765(path: JsonNode;
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
  var valid_773767 = header.getOrDefault("X-Amz-Date")
  valid_773767 = validateParameter(valid_773767, JString, required = false,
                                 default = nil)
  if valid_773767 != nil:
    section.add "X-Amz-Date", valid_773767
  var valid_773768 = header.getOrDefault("X-Amz-Security-Token")
  valid_773768 = validateParameter(valid_773768, JString, required = false,
                                 default = nil)
  if valid_773768 != nil:
    section.add "X-Amz-Security-Token", valid_773768
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773769 = header.getOrDefault("X-Amz-Target")
  valid_773769 = validateParameter(valid_773769, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInstancePatchStatesForPatchGroup"))
  if valid_773769 != nil:
    section.add "X-Amz-Target", valid_773769
  var valid_773770 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773770 = validateParameter(valid_773770, JString, required = false,
                                 default = nil)
  if valid_773770 != nil:
    section.add "X-Amz-Content-Sha256", valid_773770
  var valid_773771 = header.getOrDefault("X-Amz-Algorithm")
  valid_773771 = validateParameter(valid_773771, JString, required = false,
                                 default = nil)
  if valid_773771 != nil:
    section.add "X-Amz-Algorithm", valid_773771
  var valid_773772 = header.getOrDefault("X-Amz-Signature")
  valid_773772 = validateParameter(valid_773772, JString, required = false,
                                 default = nil)
  if valid_773772 != nil:
    section.add "X-Amz-Signature", valid_773772
  var valid_773773 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773773 = validateParameter(valid_773773, JString, required = false,
                                 default = nil)
  if valid_773773 != nil:
    section.add "X-Amz-SignedHeaders", valid_773773
  var valid_773774 = header.getOrDefault("X-Amz-Credential")
  valid_773774 = validateParameter(valid_773774, JString, required = false,
                                 default = nil)
  if valid_773774 != nil:
    section.add "X-Amz-Credential", valid_773774
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773776: Call_DescribeInstancePatchStatesForPatchGroup_773764;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the high-level patch state for the instances in the specified patch group.
  ## 
  let valid = call_773776.validator(path, query, header, formData, body)
  let scheme = call_773776.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773776.url(scheme.get, call_773776.host, call_773776.base,
                         call_773776.route, valid.getOrDefault("path"))
  result = hook(call_773776, url, valid)

proc call*(call_773777: Call_DescribeInstancePatchStatesForPatchGroup_773764;
          body: JsonNode): Recallable =
  ## describeInstancePatchStatesForPatchGroup
  ## Retrieves the high-level patch state for the instances in the specified patch group.
  ##   body: JObject (required)
  var body_773778 = newJObject()
  if body != nil:
    body_773778 = body
  result = call_773777.call(nil, nil, nil, nil, body_773778)

var describeInstancePatchStatesForPatchGroup* = Call_DescribeInstancePatchStatesForPatchGroup_773764(
    name: "describeInstancePatchStatesForPatchGroup", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInstancePatchStatesForPatchGroup",
    validator: validate_DescribeInstancePatchStatesForPatchGroup_773765,
    base: "/", url: url_DescribeInstancePatchStatesForPatchGroup_773766,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInstancePatches_773779 = ref object of OpenApiRestCall_772597
proc url_DescribeInstancePatches_773781(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeInstancePatches_773780(path: JsonNode; query: JsonNode;
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
  var valid_773782 = header.getOrDefault("X-Amz-Date")
  valid_773782 = validateParameter(valid_773782, JString, required = false,
                                 default = nil)
  if valid_773782 != nil:
    section.add "X-Amz-Date", valid_773782
  var valid_773783 = header.getOrDefault("X-Amz-Security-Token")
  valid_773783 = validateParameter(valid_773783, JString, required = false,
                                 default = nil)
  if valid_773783 != nil:
    section.add "X-Amz-Security-Token", valid_773783
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773784 = header.getOrDefault("X-Amz-Target")
  valid_773784 = validateParameter(valid_773784, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInstancePatches"))
  if valid_773784 != nil:
    section.add "X-Amz-Target", valid_773784
  var valid_773785 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773785 = validateParameter(valid_773785, JString, required = false,
                                 default = nil)
  if valid_773785 != nil:
    section.add "X-Amz-Content-Sha256", valid_773785
  var valid_773786 = header.getOrDefault("X-Amz-Algorithm")
  valid_773786 = validateParameter(valid_773786, JString, required = false,
                                 default = nil)
  if valid_773786 != nil:
    section.add "X-Amz-Algorithm", valid_773786
  var valid_773787 = header.getOrDefault("X-Amz-Signature")
  valid_773787 = validateParameter(valid_773787, JString, required = false,
                                 default = nil)
  if valid_773787 != nil:
    section.add "X-Amz-Signature", valid_773787
  var valid_773788 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773788 = validateParameter(valid_773788, JString, required = false,
                                 default = nil)
  if valid_773788 != nil:
    section.add "X-Amz-SignedHeaders", valid_773788
  var valid_773789 = header.getOrDefault("X-Amz-Credential")
  valid_773789 = validateParameter(valid_773789, JString, required = false,
                                 default = nil)
  if valid_773789 != nil:
    section.add "X-Amz-Credential", valid_773789
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773791: Call_DescribeInstancePatches_773779; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the patches on the specified instance and their state relative to the patch baseline being used for the instance.
  ## 
  let valid = call_773791.validator(path, query, header, formData, body)
  let scheme = call_773791.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773791.url(scheme.get, call_773791.host, call_773791.base,
                         call_773791.route, valid.getOrDefault("path"))
  result = hook(call_773791, url, valid)

proc call*(call_773792: Call_DescribeInstancePatches_773779; body: JsonNode): Recallable =
  ## describeInstancePatches
  ## Retrieves information about the patches on the specified instance and their state relative to the patch baseline being used for the instance.
  ##   body: JObject (required)
  var body_773793 = newJObject()
  if body != nil:
    body_773793 = body
  result = call_773792.call(nil, nil, nil, nil, body_773793)

var describeInstancePatches* = Call_DescribeInstancePatches_773779(
    name: "describeInstancePatches", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInstancePatches",
    validator: validate_DescribeInstancePatches_773780, base: "/",
    url: url_DescribeInstancePatches_773781, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInventoryDeletions_773794 = ref object of OpenApiRestCall_772597
proc url_DescribeInventoryDeletions_773796(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeInventoryDeletions_773795(path: JsonNode; query: JsonNode;
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
  var valid_773797 = header.getOrDefault("X-Amz-Date")
  valid_773797 = validateParameter(valid_773797, JString, required = false,
                                 default = nil)
  if valid_773797 != nil:
    section.add "X-Amz-Date", valid_773797
  var valid_773798 = header.getOrDefault("X-Amz-Security-Token")
  valid_773798 = validateParameter(valid_773798, JString, required = false,
                                 default = nil)
  if valid_773798 != nil:
    section.add "X-Amz-Security-Token", valid_773798
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773799 = header.getOrDefault("X-Amz-Target")
  valid_773799 = validateParameter(valid_773799, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInventoryDeletions"))
  if valid_773799 != nil:
    section.add "X-Amz-Target", valid_773799
  var valid_773800 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773800 = validateParameter(valid_773800, JString, required = false,
                                 default = nil)
  if valid_773800 != nil:
    section.add "X-Amz-Content-Sha256", valid_773800
  var valid_773801 = header.getOrDefault("X-Amz-Algorithm")
  valid_773801 = validateParameter(valid_773801, JString, required = false,
                                 default = nil)
  if valid_773801 != nil:
    section.add "X-Amz-Algorithm", valid_773801
  var valid_773802 = header.getOrDefault("X-Amz-Signature")
  valid_773802 = validateParameter(valid_773802, JString, required = false,
                                 default = nil)
  if valid_773802 != nil:
    section.add "X-Amz-Signature", valid_773802
  var valid_773803 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773803 = validateParameter(valid_773803, JString, required = false,
                                 default = nil)
  if valid_773803 != nil:
    section.add "X-Amz-SignedHeaders", valid_773803
  var valid_773804 = header.getOrDefault("X-Amz-Credential")
  valid_773804 = validateParameter(valid_773804, JString, required = false,
                                 default = nil)
  if valid_773804 != nil:
    section.add "X-Amz-Credential", valid_773804
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773806: Call_DescribeInventoryDeletions_773794; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a specific delete inventory operation.
  ## 
  let valid = call_773806.validator(path, query, header, formData, body)
  let scheme = call_773806.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773806.url(scheme.get, call_773806.host, call_773806.base,
                         call_773806.route, valid.getOrDefault("path"))
  result = hook(call_773806, url, valid)

proc call*(call_773807: Call_DescribeInventoryDeletions_773794; body: JsonNode): Recallable =
  ## describeInventoryDeletions
  ## Describes a specific delete inventory operation.
  ##   body: JObject (required)
  var body_773808 = newJObject()
  if body != nil:
    body_773808 = body
  result = call_773807.call(nil, nil, nil, nil, body_773808)

var describeInventoryDeletions* = Call_DescribeInventoryDeletions_773794(
    name: "describeInventoryDeletions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInventoryDeletions",
    validator: validate_DescribeInventoryDeletions_773795, base: "/",
    url: url_DescribeInventoryDeletions_773796,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowExecutionTaskInvocations_773809 = ref object of OpenApiRestCall_772597
proc url_DescribeMaintenanceWindowExecutionTaskInvocations_773811(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeMaintenanceWindowExecutionTaskInvocations_773810(
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
  var valid_773812 = header.getOrDefault("X-Amz-Date")
  valid_773812 = validateParameter(valid_773812, JString, required = false,
                                 default = nil)
  if valid_773812 != nil:
    section.add "X-Amz-Date", valid_773812
  var valid_773813 = header.getOrDefault("X-Amz-Security-Token")
  valid_773813 = validateParameter(valid_773813, JString, required = false,
                                 default = nil)
  if valid_773813 != nil:
    section.add "X-Amz-Security-Token", valid_773813
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773814 = header.getOrDefault("X-Amz-Target")
  valid_773814 = validateParameter(valid_773814, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowExecutionTaskInvocations"))
  if valid_773814 != nil:
    section.add "X-Amz-Target", valid_773814
  var valid_773815 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773815 = validateParameter(valid_773815, JString, required = false,
                                 default = nil)
  if valid_773815 != nil:
    section.add "X-Amz-Content-Sha256", valid_773815
  var valid_773816 = header.getOrDefault("X-Amz-Algorithm")
  valid_773816 = validateParameter(valid_773816, JString, required = false,
                                 default = nil)
  if valid_773816 != nil:
    section.add "X-Amz-Algorithm", valid_773816
  var valid_773817 = header.getOrDefault("X-Amz-Signature")
  valid_773817 = validateParameter(valid_773817, JString, required = false,
                                 default = nil)
  if valid_773817 != nil:
    section.add "X-Amz-Signature", valid_773817
  var valid_773818 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773818 = validateParameter(valid_773818, JString, required = false,
                                 default = nil)
  if valid_773818 != nil:
    section.add "X-Amz-SignedHeaders", valid_773818
  var valid_773819 = header.getOrDefault("X-Amz-Credential")
  valid_773819 = validateParameter(valid_773819, JString, required = false,
                                 default = nil)
  if valid_773819 != nil:
    section.add "X-Amz-Credential", valid_773819
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773821: Call_DescribeMaintenanceWindowExecutionTaskInvocations_773809;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the individual task executions (one per target) for a particular task run as part of a maintenance window execution.
  ## 
  let valid = call_773821.validator(path, query, header, formData, body)
  let scheme = call_773821.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773821.url(scheme.get, call_773821.host, call_773821.base,
                         call_773821.route, valid.getOrDefault("path"))
  result = hook(call_773821, url, valid)

proc call*(call_773822: Call_DescribeMaintenanceWindowExecutionTaskInvocations_773809;
          body: JsonNode): Recallable =
  ## describeMaintenanceWindowExecutionTaskInvocations
  ## Retrieves the individual task executions (one per target) for a particular task run as part of a maintenance window execution.
  ##   body: JObject (required)
  var body_773823 = newJObject()
  if body != nil:
    body_773823 = body
  result = call_773822.call(nil, nil, nil, nil, body_773823)

var describeMaintenanceWindowExecutionTaskInvocations* = Call_DescribeMaintenanceWindowExecutionTaskInvocations_773809(
    name: "describeMaintenanceWindowExecutionTaskInvocations",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com", route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowExecutionTaskInvocations",
    validator: validate_DescribeMaintenanceWindowExecutionTaskInvocations_773810,
    base: "/", url: url_DescribeMaintenanceWindowExecutionTaskInvocations_773811,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowExecutionTasks_773824 = ref object of OpenApiRestCall_772597
proc url_DescribeMaintenanceWindowExecutionTasks_773826(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeMaintenanceWindowExecutionTasks_773825(path: JsonNode;
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
  var valid_773827 = header.getOrDefault("X-Amz-Date")
  valid_773827 = validateParameter(valid_773827, JString, required = false,
                                 default = nil)
  if valid_773827 != nil:
    section.add "X-Amz-Date", valid_773827
  var valid_773828 = header.getOrDefault("X-Amz-Security-Token")
  valid_773828 = validateParameter(valid_773828, JString, required = false,
                                 default = nil)
  if valid_773828 != nil:
    section.add "X-Amz-Security-Token", valid_773828
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773829 = header.getOrDefault("X-Amz-Target")
  valid_773829 = validateParameter(valid_773829, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowExecutionTasks"))
  if valid_773829 != nil:
    section.add "X-Amz-Target", valid_773829
  var valid_773830 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773830 = validateParameter(valid_773830, JString, required = false,
                                 default = nil)
  if valid_773830 != nil:
    section.add "X-Amz-Content-Sha256", valid_773830
  var valid_773831 = header.getOrDefault("X-Amz-Algorithm")
  valid_773831 = validateParameter(valid_773831, JString, required = false,
                                 default = nil)
  if valid_773831 != nil:
    section.add "X-Amz-Algorithm", valid_773831
  var valid_773832 = header.getOrDefault("X-Amz-Signature")
  valid_773832 = validateParameter(valid_773832, JString, required = false,
                                 default = nil)
  if valid_773832 != nil:
    section.add "X-Amz-Signature", valid_773832
  var valid_773833 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773833 = validateParameter(valid_773833, JString, required = false,
                                 default = nil)
  if valid_773833 != nil:
    section.add "X-Amz-SignedHeaders", valid_773833
  var valid_773834 = header.getOrDefault("X-Amz-Credential")
  valid_773834 = validateParameter(valid_773834, JString, required = false,
                                 default = nil)
  if valid_773834 != nil:
    section.add "X-Amz-Credential", valid_773834
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773836: Call_DescribeMaintenanceWindowExecutionTasks_773824;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## For a given maintenance window execution, lists the tasks that were run.
  ## 
  let valid = call_773836.validator(path, query, header, formData, body)
  let scheme = call_773836.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773836.url(scheme.get, call_773836.host, call_773836.base,
                         call_773836.route, valid.getOrDefault("path"))
  result = hook(call_773836, url, valid)

proc call*(call_773837: Call_DescribeMaintenanceWindowExecutionTasks_773824;
          body: JsonNode): Recallable =
  ## describeMaintenanceWindowExecutionTasks
  ## For a given maintenance window execution, lists the tasks that were run.
  ##   body: JObject (required)
  var body_773838 = newJObject()
  if body != nil:
    body_773838 = body
  result = call_773837.call(nil, nil, nil, nil, body_773838)

var describeMaintenanceWindowExecutionTasks* = Call_DescribeMaintenanceWindowExecutionTasks_773824(
    name: "describeMaintenanceWindowExecutionTasks", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowExecutionTasks",
    validator: validate_DescribeMaintenanceWindowExecutionTasks_773825, base: "/",
    url: url_DescribeMaintenanceWindowExecutionTasks_773826,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowExecutions_773839 = ref object of OpenApiRestCall_772597
proc url_DescribeMaintenanceWindowExecutions_773841(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeMaintenanceWindowExecutions_773840(path: JsonNode;
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
  var valid_773842 = header.getOrDefault("X-Amz-Date")
  valid_773842 = validateParameter(valid_773842, JString, required = false,
                                 default = nil)
  if valid_773842 != nil:
    section.add "X-Amz-Date", valid_773842
  var valid_773843 = header.getOrDefault("X-Amz-Security-Token")
  valid_773843 = validateParameter(valid_773843, JString, required = false,
                                 default = nil)
  if valid_773843 != nil:
    section.add "X-Amz-Security-Token", valid_773843
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773844 = header.getOrDefault("X-Amz-Target")
  valid_773844 = validateParameter(valid_773844, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowExecutions"))
  if valid_773844 != nil:
    section.add "X-Amz-Target", valid_773844
  var valid_773845 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773845 = validateParameter(valid_773845, JString, required = false,
                                 default = nil)
  if valid_773845 != nil:
    section.add "X-Amz-Content-Sha256", valid_773845
  var valid_773846 = header.getOrDefault("X-Amz-Algorithm")
  valid_773846 = validateParameter(valid_773846, JString, required = false,
                                 default = nil)
  if valid_773846 != nil:
    section.add "X-Amz-Algorithm", valid_773846
  var valid_773847 = header.getOrDefault("X-Amz-Signature")
  valid_773847 = validateParameter(valid_773847, JString, required = false,
                                 default = nil)
  if valid_773847 != nil:
    section.add "X-Amz-Signature", valid_773847
  var valid_773848 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773848 = validateParameter(valid_773848, JString, required = false,
                                 default = nil)
  if valid_773848 != nil:
    section.add "X-Amz-SignedHeaders", valid_773848
  var valid_773849 = header.getOrDefault("X-Amz-Credential")
  valid_773849 = validateParameter(valid_773849, JString, required = false,
                                 default = nil)
  if valid_773849 != nil:
    section.add "X-Amz-Credential", valid_773849
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773851: Call_DescribeMaintenanceWindowExecutions_773839;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the executions of a maintenance window. This includes information about when the maintenance window was scheduled to be active, and information about tasks registered and run with the maintenance window.
  ## 
  let valid = call_773851.validator(path, query, header, formData, body)
  let scheme = call_773851.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773851.url(scheme.get, call_773851.host, call_773851.base,
                         call_773851.route, valid.getOrDefault("path"))
  result = hook(call_773851, url, valid)

proc call*(call_773852: Call_DescribeMaintenanceWindowExecutions_773839;
          body: JsonNode): Recallable =
  ## describeMaintenanceWindowExecutions
  ## Lists the executions of a maintenance window. This includes information about when the maintenance window was scheduled to be active, and information about tasks registered and run with the maintenance window.
  ##   body: JObject (required)
  var body_773853 = newJObject()
  if body != nil:
    body_773853 = body
  result = call_773852.call(nil, nil, nil, nil, body_773853)

var describeMaintenanceWindowExecutions* = Call_DescribeMaintenanceWindowExecutions_773839(
    name: "describeMaintenanceWindowExecutions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowExecutions",
    validator: validate_DescribeMaintenanceWindowExecutions_773840, base: "/",
    url: url_DescribeMaintenanceWindowExecutions_773841,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowSchedule_773854 = ref object of OpenApiRestCall_772597
proc url_DescribeMaintenanceWindowSchedule_773856(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeMaintenanceWindowSchedule_773855(path: JsonNode;
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
  var valid_773857 = header.getOrDefault("X-Amz-Date")
  valid_773857 = validateParameter(valid_773857, JString, required = false,
                                 default = nil)
  if valid_773857 != nil:
    section.add "X-Amz-Date", valid_773857
  var valid_773858 = header.getOrDefault("X-Amz-Security-Token")
  valid_773858 = validateParameter(valid_773858, JString, required = false,
                                 default = nil)
  if valid_773858 != nil:
    section.add "X-Amz-Security-Token", valid_773858
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773859 = header.getOrDefault("X-Amz-Target")
  valid_773859 = validateParameter(valid_773859, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowSchedule"))
  if valid_773859 != nil:
    section.add "X-Amz-Target", valid_773859
  var valid_773860 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773860 = validateParameter(valid_773860, JString, required = false,
                                 default = nil)
  if valid_773860 != nil:
    section.add "X-Amz-Content-Sha256", valid_773860
  var valid_773861 = header.getOrDefault("X-Amz-Algorithm")
  valid_773861 = validateParameter(valid_773861, JString, required = false,
                                 default = nil)
  if valid_773861 != nil:
    section.add "X-Amz-Algorithm", valid_773861
  var valid_773862 = header.getOrDefault("X-Amz-Signature")
  valid_773862 = validateParameter(valid_773862, JString, required = false,
                                 default = nil)
  if valid_773862 != nil:
    section.add "X-Amz-Signature", valid_773862
  var valid_773863 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773863 = validateParameter(valid_773863, JString, required = false,
                                 default = nil)
  if valid_773863 != nil:
    section.add "X-Amz-SignedHeaders", valid_773863
  var valid_773864 = header.getOrDefault("X-Amz-Credential")
  valid_773864 = validateParameter(valid_773864, JString, required = false,
                                 default = nil)
  if valid_773864 != nil:
    section.add "X-Amz-Credential", valid_773864
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773866: Call_DescribeMaintenanceWindowSchedule_773854;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves information about upcoming executions of a maintenance window.
  ## 
  let valid = call_773866.validator(path, query, header, formData, body)
  let scheme = call_773866.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773866.url(scheme.get, call_773866.host, call_773866.base,
                         call_773866.route, valid.getOrDefault("path"))
  result = hook(call_773866, url, valid)

proc call*(call_773867: Call_DescribeMaintenanceWindowSchedule_773854;
          body: JsonNode): Recallable =
  ## describeMaintenanceWindowSchedule
  ## Retrieves information about upcoming executions of a maintenance window.
  ##   body: JObject (required)
  var body_773868 = newJObject()
  if body != nil:
    body_773868 = body
  result = call_773867.call(nil, nil, nil, nil, body_773868)

var describeMaintenanceWindowSchedule* = Call_DescribeMaintenanceWindowSchedule_773854(
    name: "describeMaintenanceWindowSchedule", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowSchedule",
    validator: validate_DescribeMaintenanceWindowSchedule_773855, base: "/",
    url: url_DescribeMaintenanceWindowSchedule_773856,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowTargets_773869 = ref object of OpenApiRestCall_772597
proc url_DescribeMaintenanceWindowTargets_773871(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeMaintenanceWindowTargets_773870(path: JsonNode;
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
  var valid_773872 = header.getOrDefault("X-Amz-Date")
  valid_773872 = validateParameter(valid_773872, JString, required = false,
                                 default = nil)
  if valid_773872 != nil:
    section.add "X-Amz-Date", valid_773872
  var valid_773873 = header.getOrDefault("X-Amz-Security-Token")
  valid_773873 = validateParameter(valid_773873, JString, required = false,
                                 default = nil)
  if valid_773873 != nil:
    section.add "X-Amz-Security-Token", valid_773873
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773874 = header.getOrDefault("X-Amz-Target")
  valid_773874 = validateParameter(valid_773874, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowTargets"))
  if valid_773874 != nil:
    section.add "X-Amz-Target", valid_773874
  var valid_773875 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773875 = validateParameter(valid_773875, JString, required = false,
                                 default = nil)
  if valid_773875 != nil:
    section.add "X-Amz-Content-Sha256", valid_773875
  var valid_773876 = header.getOrDefault("X-Amz-Algorithm")
  valid_773876 = validateParameter(valid_773876, JString, required = false,
                                 default = nil)
  if valid_773876 != nil:
    section.add "X-Amz-Algorithm", valid_773876
  var valid_773877 = header.getOrDefault("X-Amz-Signature")
  valid_773877 = validateParameter(valid_773877, JString, required = false,
                                 default = nil)
  if valid_773877 != nil:
    section.add "X-Amz-Signature", valid_773877
  var valid_773878 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773878 = validateParameter(valid_773878, JString, required = false,
                                 default = nil)
  if valid_773878 != nil:
    section.add "X-Amz-SignedHeaders", valid_773878
  var valid_773879 = header.getOrDefault("X-Amz-Credential")
  valid_773879 = validateParameter(valid_773879, JString, required = false,
                                 default = nil)
  if valid_773879 != nil:
    section.add "X-Amz-Credential", valid_773879
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773881: Call_DescribeMaintenanceWindowTargets_773869;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the targets registered with the maintenance window.
  ## 
  let valid = call_773881.validator(path, query, header, formData, body)
  let scheme = call_773881.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773881.url(scheme.get, call_773881.host, call_773881.base,
                         call_773881.route, valid.getOrDefault("path"))
  result = hook(call_773881, url, valid)

proc call*(call_773882: Call_DescribeMaintenanceWindowTargets_773869;
          body: JsonNode): Recallable =
  ## describeMaintenanceWindowTargets
  ## Lists the targets registered with the maintenance window.
  ##   body: JObject (required)
  var body_773883 = newJObject()
  if body != nil:
    body_773883 = body
  result = call_773882.call(nil, nil, nil, nil, body_773883)

var describeMaintenanceWindowTargets* = Call_DescribeMaintenanceWindowTargets_773869(
    name: "describeMaintenanceWindowTargets", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowTargets",
    validator: validate_DescribeMaintenanceWindowTargets_773870, base: "/",
    url: url_DescribeMaintenanceWindowTargets_773871,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowTasks_773884 = ref object of OpenApiRestCall_772597
proc url_DescribeMaintenanceWindowTasks_773886(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeMaintenanceWindowTasks_773885(path: JsonNode;
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
  var valid_773887 = header.getOrDefault("X-Amz-Date")
  valid_773887 = validateParameter(valid_773887, JString, required = false,
                                 default = nil)
  if valid_773887 != nil:
    section.add "X-Amz-Date", valid_773887
  var valid_773888 = header.getOrDefault("X-Amz-Security-Token")
  valid_773888 = validateParameter(valid_773888, JString, required = false,
                                 default = nil)
  if valid_773888 != nil:
    section.add "X-Amz-Security-Token", valid_773888
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773889 = header.getOrDefault("X-Amz-Target")
  valid_773889 = validateParameter(valid_773889, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowTasks"))
  if valid_773889 != nil:
    section.add "X-Amz-Target", valid_773889
  var valid_773890 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773890 = validateParameter(valid_773890, JString, required = false,
                                 default = nil)
  if valid_773890 != nil:
    section.add "X-Amz-Content-Sha256", valid_773890
  var valid_773891 = header.getOrDefault("X-Amz-Algorithm")
  valid_773891 = validateParameter(valid_773891, JString, required = false,
                                 default = nil)
  if valid_773891 != nil:
    section.add "X-Amz-Algorithm", valid_773891
  var valid_773892 = header.getOrDefault("X-Amz-Signature")
  valid_773892 = validateParameter(valid_773892, JString, required = false,
                                 default = nil)
  if valid_773892 != nil:
    section.add "X-Amz-Signature", valid_773892
  var valid_773893 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773893 = validateParameter(valid_773893, JString, required = false,
                                 default = nil)
  if valid_773893 != nil:
    section.add "X-Amz-SignedHeaders", valid_773893
  var valid_773894 = header.getOrDefault("X-Amz-Credential")
  valid_773894 = validateParameter(valid_773894, JString, required = false,
                                 default = nil)
  if valid_773894 != nil:
    section.add "X-Amz-Credential", valid_773894
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773896: Call_DescribeMaintenanceWindowTasks_773884; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tasks in a maintenance window.
  ## 
  let valid = call_773896.validator(path, query, header, formData, body)
  let scheme = call_773896.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773896.url(scheme.get, call_773896.host, call_773896.base,
                         call_773896.route, valid.getOrDefault("path"))
  result = hook(call_773896, url, valid)

proc call*(call_773897: Call_DescribeMaintenanceWindowTasks_773884; body: JsonNode): Recallable =
  ## describeMaintenanceWindowTasks
  ## Lists the tasks in a maintenance window.
  ##   body: JObject (required)
  var body_773898 = newJObject()
  if body != nil:
    body_773898 = body
  result = call_773897.call(nil, nil, nil, nil, body_773898)

var describeMaintenanceWindowTasks* = Call_DescribeMaintenanceWindowTasks_773884(
    name: "describeMaintenanceWindowTasks", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowTasks",
    validator: validate_DescribeMaintenanceWindowTasks_773885, base: "/",
    url: url_DescribeMaintenanceWindowTasks_773886,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindows_773899 = ref object of OpenApiRestCall_772597
proc url_DescribeMaintenanceWindows_773901(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeMaintenanceWindows_773900(path: JsonNode; query: JsonNode;
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
  var valid_773902 = header.getOrDefault("X-Amz-Date")
  valid_773902 = validateParameter(valid_773902, JString, required = false,
                                 default = nil)
  if valid_773902 != nil:
    section.add "X-Amz-Date", valid_773902
  var valid_773903 = header.getOrDefault("X-Amz-Security-Token")
  valid_773903 = validateParameter(valid_773903, JString, required = false,
                                 default = nil)
  if valid_773903 != nil:
    section.add "X-Amz-Security-Token", valid_773903
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773904 = header.getOrDefault("X-Amz-Target")
  valid_773904 = validateParameter(valid_773904, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindows"))
  if valid_773904 != nil:
    section.add "X-Amz-Target", valid_773904
  var valid_773905 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773905 = validateParameter(valid_773905, JString, required = false,
                                 default = nil)
  if valid_773905 != nil:
    section.add "X-Amz-Content-Sha256", valid_773905
  var valid_773906 = header.getOrDefault("X-Amz-Algorithm")
  valid_773906 = validateParameter(valid_773906, JString, required = false,
                                 default = nil)
  if valid_773906 != nil:
    section.add "X-Amz-Algorithm", valid_773906
  var valid_773907 = header.getOrDefault("X-Amz-Signature")
  valid_773907 = validateParameter(valid_773907, JString, required = false,
                                 default = nil)
  if valid_773907 != nil:
    section.add "X-Amz-Signature", valid_773907
  var valid_773908 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773908 = validateParameter(valid_773908, JString, required = false,
                                 default = nil)
  if valid_773908 != nil:
    section.add "X-Amz-SignedHeaders", valid_773908
  var valid_773909 = header.getOrDefault("X-Amz-Credential")
  valid_773909 = validateParameter(valid_773909, JString, required = false,
                                 default = nil)
  if valid_773909 != nil:
    section.add "X-Amz-Credential", valid_773909
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773911: Call_DescribeMaintenanceWindows_773899; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the maintenance windows in an AWS account.
  ## 
  let valid = call_773911.validator(path, query, header, formData, body)
  let scheme = call_773911.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773911.url(scheme.get, call_773911.host, call_773911.base,
                         call_773911.route, valid.getOrDefault("path"))
  result = hook(call_773911, url, valid)

proc call*(call_773912: Call_DescribeMaintenanceWindows_773899; body: JsonNode): Recallable =
  ## describeMaintenanceWindows
  ## Retrieves the maintenance windows in an AWS account.
  ##   body: JObject (required)
  var body_773913 = newJObject()
  if body != nil:
    body_773913 = body
  result = call_773912.call(nil, nil, nil, nil, body_773913)

var describeMaintenanceWindows* = Call_DescribeMaintenanceWindows_773899(
    name: "describeMaintenanceWindows", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindows",
    validator: validate_DescribeMaintenanceWindows_773900, base: "/",
    url: url_DescribeMaintenanceWindows_773901,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowsForTarget_773914 = ref object of OpenApiRestCall_772597
proc url_DescribeMaintenanceWindowsForTarget_773916(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeMaintenanceWindowsForTarget_773915(path: JsonNode;
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
  var valid_773917 = header.getOrDefault("X-Amz-Date")
  valid_773917 = validateParameter(valid_773917, JString, required = false,
                                 default = nil)
  if valid_773917 != nil:
    section.add "X-Amz-Date", valid_773917
  var valid_773918 = header.getOrDefault("X-Amz-Security-Token")
  valid_773918 = validateParameter(valid_773918, JString, required = false,
                                 default = nil)
  if valid_773918 != nil:
    section.add "X-Amz-Security-Token", valid_773918
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773919 = header.getOrDefault("X-Amz-Target")
  valid_773919 = validateParameter(valid_773919, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowsForTarget"))
  if valid_773919 != nil:
    section.add "X-Amz-Target", valid_773919
  var valid_773920 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773920 = validateParameter(valid_773920, JString, required = false,
                                 default = nil)
  if valid_773920 != nil:
    section.add "X-Amz-Content-Sha256", valid_773920
  var valid_773921 = header.getOrDefault("X-Amz-Algorithm")
  valid_773921 = validateParameter(valid_773921, JString, required = false,
                                 default = nil)
  if valid_773921 != nil:
    section.add "X-Amz-Algorithm", valid_773921
  var valid_773922 = header.getOrDefault("X-Amz-Signature")
  valid_773922 = validateParameter(valid_773922, JString, required = false,
                                 default = nil)
  if valid_773922 != nil:
    section.add "X-Amz-Signature", valid_773922
  var valid_773923 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773923 = validateParameter(valid_773923, JString, required = false,
                                 default = nil)
  if valid_773923 != nil:
    section.add "X-Amz-SignedHeaders", valid_773923
  var valid_773924 = header.getOrDefault("X-Amz-Credential")
  valid_773924 = validateParameter(valid_773924, JString, required = false,
                                 default = nil)
  if valid_773924 != nil:
    section.add "X-Amz-Credential", valid_773924
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773926: Call_DescribeMaintenanceWindowsForTarget_773914;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves information about the maintenance window targets or tasks that an instance is associated with.
  ## 
  let valid = call_773926.validator(path, query, header, formData, body)
  let scheme = call_773926.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773926.url(scheme.get, call_773926.host, call_773926.base,
                         call_773926.route, valid.getOrDefault("path"))
  result = hook(call_773926, url, valid)

proc call*(call_773927: Call_DescribeMaintenanceWindowsForTarget_773914;
          body: JsonNode): Recallable =
  ## describeMaintenanceWindowsForTarget
  ## Retrieves information about the maintenance window targets or tasks that an instance is associated with.
  ##   body: JObject (required)
  var body_773928 = newJObject()
  if body != nil:
    body_773928 = body
  result = call_773927.call(nil, nil, nil, nil, body_773928)

var describeMaintenanceWindowsForTarget* = Call_DescribeMaintenanceWindowsForTarget_773914(
    name: "describeMaintenanceWindowsForTarget", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowsForTarget",
    validator: validate_DescribeMaintenanceWindowsForTarget_773915, base: "/",
    url: url_DescribeMaintenanceWindowsForTarget_773916,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeOpsItems_773929 = ref object of OpenApiRestCall_772597
proc url_DescribeOpsItems_773931(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeOpsItems_773930(path: JsonNode; query: JsonNode;
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
  var valid_773932 = header.getOrDefault("X-Amz-Date")
  valid_773932 = validateParameter(valid_773932, JString, required = false,
                                 default = nil)
  if valid_773932 != nil:
    section.add "X-Amz-Date", valid_773932
  var valid_773933 = header.getOrDefault("X-Amz-Security-Token")
  valid_773933 = validateParameter(valid_773933, JString, required = false,
                                 default = nil)
  if valid_773933 != nil:
    section.add "X-Amz-Security-Token", valid_773933
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773934 = header.getOrDefault("X-Amz-Target")
  valid_773934 = validateParameter(valid_773934, JString, required = true, default = newJString(
      "AmazonSSM.DescribeOpsItems"))
  if valid_773934 != nil:
    section.add "X-Amz-Target", valid_773934
  var valid_773935 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773935 = validateParameter(valid_773935, JString, required = false,
                                 default = nil)
  if valid_773935 != nil:
    section.add "X-Amz-Content-Sha256", valid_773935
  var valid_773936 = header.getOrDefault("X-Amz-Algorithm")
  valid_773936 = validateParameter(valid_773936, JString, required = false,
                                 default = nil)
  if valid_773936 != nil:
    section.add "X-Amz-Algorithm", valid_773936
  var valid_773937 = header.getOrDefault("X-Amz-Signature")
  valid_773937 = validateParameter(valid_773937, JString, required = false,
                                 default = nil)
  if valid_773937 != nil:
    section.add "X-Amz-Signature", valid_773937
  var valid_773938 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773938 = validateParameter(valid_773938, JString, required = false,
                                 default = nil)
  if valid_773938 != nil:
    section.add "X-Amz-SignedHeaders", valid_773938
  var valid_773939 = header.getOrDefault("X-Amz-Credential")
  valid_773939 = validateParameter(valid_773939, JString, required = false,
                                 default = nil)
  if valid_773939 != nil:
    section.add "X-Amz-Credential", valid_773939
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773941: Call_DescribeOpsItems_773929; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Query a set of OpsItems. You must have permission in AWS Identity and Access Management (IAM) to query a list of OpsItems. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ## 
  let valid = call_773941.validator(path, query, header, formData, body)
  let scheme = call_773941.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773941.url(scheme.get, call_773941.host, call_773941.base,
                         call_773941.route, valid.getOrDefault("path"))
  result = hook(call_773941, url, valid)

proc call*(call_773942: Call_DescribeOpsItems_773929; body: JsonNode): Recallable =
  ## describeOpsItems
  ## <p>Query a set of OpsItems. You must have permission in AWS Identity and Access Management (IAM) to query a list of OpsItems. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ##   body: JObject (required)
  var body_773943 = newJObject()
  if body != nil:
    body_773943 = body
  result = call_773942.call(nil, nil, nil, nil, body_773943)

var describeOpsItems* = Call_DescribeOpsItems_773929(name: "describeOpsItems",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeOpsItems",
    validator: validate_DescribeOpsItems_773930, base: "/",
    url: url_DescribeOpsItems_773931, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeParameters_773944 = ref object of OpenApiRestCall_772597
proc url_DescribeParameters_773946(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeParameters_773945(path: JsonNode; query: JsonNode;
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
  var valid_773947 = query.getOrDefault("NextToken")
  valid_773947 = validateParameter(valid_773947, JString, required = false,
                                 default = nil)
  if valid_773947 != nil:
    section.add "NextToken", valid_773947
  var valid_773948 = query.getOrDefault("MaxResults")
  valid_773948 = validateParameter(valid_773948, JString, required = false,
                                 default = nil)
  if valid_773948 != nil:
    section.add "MaxResults", valid_773948
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
  var valid_773949 = header.getOrDefault("X-Amz-Date")
  valid_773949 = validateParameter(valid_773949, JString, required = false,
                                 default = nil)
  if valid_773949 != nil:
    section.add "X-Amz-Date", valid_773949
  var valid_773950 = header.getOrDefault("X-Amz-Security-Token")
  valid_773950 = validateParameter(valid_773950, JString, required = false,
                                 default = nil)
  if valid_773950 != nil:
    section.add "X-Amz-Security-Token", valid_773950
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773951 = header.getOrDefault("X-Amz-Target")
  valid_773951 = validateParameter(valid_773951, JString, required = true, default = newJString(
      "AmazonSSM.DescribeParameters"))
  if valid_773951 != nil:
    section.add "X-Amz-Target", valid_773951
  var valid_773952 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773952 = validateParameter(valid_773952, JString, required = false,
                                 default = nil)
  if valid_773952 != nil:
    section.add "X-Amz-Content-Sha256", valid_773952
  var valid_773953 = header.getOrDefault("X-Amz-Algorithm")
  valid_773953 = validateParameter(valid_773953, JString, required = false,
                                 default = nil)
  if valid_773953 != nil:
    section.add "X-Amz-Algorithm", valid_773953
  var valid_773954 = header.getOrDefault("X-Amz-Signature")
  valid_773954 = validateParameter(valid_773954, JString, required = false,
                                 default = nil)
  if valid_773954 != nil:
    section.add "X-Amz-Signature", valid_773954
  var valid_773955 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773955 = validateParameter(valid_773955, JString, required = false,
                                 default = nil)
  if valid_773955 != nil:
    section.add "X-Amz-SignedHeaders", valid_773955
  var valid_773956 = header.getOrDefault("X-Amz-Credential")
  valid_773956 = validateParameter(valid_773956, JString, required = false,
                                 default = nil)
  if valid_773956 != nil:
    section.add "X-Amz-Credential", valid_773956
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773958: Call_DescribeParameters_773944; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Get information about a parameter.</p> <p>Request results are returned on a best-effort basis. If you specify <code>MaxResults</code> in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of <code>MaxResults</code>. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a <code>NextToken</code>. You can specify the <code>NextToken</code> in a subsequent call to get the next set of results.</p>
  ## 
  let valid = call_773958.validator(path, query, header, formData, body)
  let scheme = call_773958.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773958.url(scheme.get, call_773958.host, call_773958.base,
                         call_773958.route, valid.getOrDefault("path"))
  result = hook(call_773958, url, valid)

proc call*(call_773959: Call_DescribeParameters_773944; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## describeParameters
  ## <p>Get information about a parameter.</p> <p>Request results are returned on a best-effort basis. If you specify <code>MaxResults</code> in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of <code>MaxResults</code>. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a <code>NextToken</code>. You can specify the <code>NextToken</code> in a subsequent call to get the next set of results.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_773960 = newJObject()
  var body_773961 = newJObject()
  add(query_773960, "NextToken", newJString(NextToken))
  if body != nil:
    body_773961 = body
  add(query_773960, "MaxResults", newJString(MaxResults))
  result = call_773959.call(nil, query_773960, nil, nil, body_773961)

var describeParameters* = Call_DescribeParameters_773944(
    name: "describeParameters", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeParameters",
    validator: validate_DescribeParameters_773945, base: "/",
    url: url_DescribeParameters_773946, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePatchBaselines_773962 = ref object of OpenApiRestCall_772597
proc url_DescribePatchBaselines_773964(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribePatchBaselines_773963(path: JsonNode; query: JsonNode;
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
  var valid_773965 = header.getOrDefault("X-Amz-Date")
  valid_773965 = validateParameter(valid_773965, JString, required = false,
                                 default = nil)
  if valid_773965 != nil:
    section.add "X-Amz-Date", valid_773965
  var valid_773966 = header.getOrDefault("X-Amz-Security-Token")
  valid_773966 = validateParameter(valid_773966, JString, required = false,
                                 default = nil)
  if valid_773966 != nil:
    section.add "X-Amz-Security-Token", valid_773966
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773967 = header.getOrDefault("X-Amz-Target")
  valid_773967 = validateParameter(valid_773967, JString, required = true, default = newJString(
      "AmazonSSM.DescribePatchBaselines"))
  if valid_773967 != nil:
    section.add "X-Amz-Target", valid_773967
  var valid_773968 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773968 = validateParameter(valid_773968, JString, required = false,
                                 default = nil)
  if valid_773968 != nil:
    section.add "X-Amz-Content-Sha256", valid_773968
  var valid_773969 = header.getOrDefault("X-Amz-Algorithm")
  valid_773969 = validateParameter(valid_773969, JString, required = false,
                                 default = nil)
  if valid_773969 != nil:
    section.add "X-Amz-Algorithm", valid_773969
  var valid_773970 = header.getOrDefault("X-Amz-Signature")
  valid_773970 = validateParameter(valid_773970, JString, required = false,
                                 default = nil)
  if valid_773970 != nil:
    section.add "X-Amz-Signature", valid_773970
  var valid_773971 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773971 = validateParameter(valid_773971, JString, required = false,
                                 default = nil)
  if valid_773971 != nil:
    section.add "X-Amz-SignedHeaders", valid_773971
  var valid_773972 = header.getOrDefault("X-Amz-Credential")
  valid_773972 = validateParameter(valid_773972, JString, required = false,
                                 default = nil)
  if valid_773972 != nil:
    section.add "X-Amz-Credential", valid_773972
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773974: Call_DescribePatchBaselines_773962; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the patch baselines in your AWS account.
  ## 
  let valid = call_773974.validator(path, query, header, formData, body)
  let scheme = call_773974.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773974.url(scheme.get, call_773974.host, call_773974.base,
                         call_773974.route, valid.getOrDefault("path"))
  result = hook(call_773974, url, valid)

proc call*(call_773975: Call_DescribePatchBaselines_773962; body: JsonNode): Recallable =
  ## describePatchBaselines
  ## Lists the patch baselines in your AWS account.
  ##   body: JObject (required)
  var body_773976 = newJObject()
  if body != nil:
    body_773976 = body
  result = call_773975.call(nil, nil, nil, nil, body_773976)

var describePatchBaselines* = Call_DescribePatchBaselines_773962(
    name: "describePatchBaselines", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribePatchBaselines",
    validator: validate_DescribePatchBaselines_773963, base: "/",
    url: url_DescribePatchBaselines_773964, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePatchGroupState_773977 = ref object of OpenApiRestCall_772597
proc url_DescribePatchGroupState_773979(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribePatchGroupState_773978(path: JsonNode; query: JsonNode;
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
  var valid_773980 = header.getOrDefault("X-Amz-Date")
  valid_773980 = validateParameter(valid_773980, JString, required = false,
                                 default = nil)
  if valid_773980 != nil:
    section.add "X-Amz-Date", valid_773980
  var valid_773981 = header.getOrDefault("X-Amz-Security-Token")
  valid_773981 = validateParameter(valid_773981, JString, required = false,
                                 default = nil)
  if valid_773981 != nil:
    section.add "X-Amz-Security-Token", valid_773981
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773982 = header.getOrDefault("X-Amz-Target")
  valid_773982 = validateParameter(valid_773982, JString, required = true, default = newJString(
      "AmazonSSM.DescribePatchGroupState"))
  if valid_773982 != nil:
    section.add "X-Amz-Target", valid_773982
  var valid_773983 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773983 = validateParameter(valid_773983, JString, required = false,
                                 default = nil)
  if valid_773983 != nil:
    section.add "X-Amz-Content-Sha256", valid_773983
  var valid_773984 = header.getOrDefault("X-Amz-Algorithm")
  valid_773984 = validateParameter(valid_773984, JString, required = false,
                                 default = nil)
  if valid_773984 != nil:
    section.add "X-Amz-Algorithm", valid_773984
  var valid_773985 = header.getOrDefault("X-Amz-Signature")
  valid_773985 = validateParameter(valid_773985, JString, required = false,
                                 default = nil)
  if valid_773985 != nil:
    section.add "X-Amz-Signature", valid_773985
  var valid_773986 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773986 = validateParameter(valid_773986, JString, required = false,
                                 default = nil)
  if valid_773986 != nil:
    section.add "X-Amz-SignedHeaders", valid_773986
  var valid_773987 = header.getOrDefault("X-Amz-Credential")
  valid_773987 = validateParameter(valid_773987, JString, required = false,
                                 default = nil)
  if valid_773987 != nil:
    section.add "X-Amz-Credential", valid_773987
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773989: Call_DescribePatchGroupState_773977; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns high-level aggregated patch compliance state for a patch group.
  ## 
  let valid = call_773989.validator(path, query, header, formData, body)
  let scheme = call_773989.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773989.url(scheme.get, call_773989.host, call_773989.base,
                         call_773989.route, valid.getOrDefault("path"))
  result = hook(call_773989, url, valid)

proc call*(call_773990: Call_DescribePatchGroupState_773977; body: JsonNode): Recallable =
  ## describePatchGroupState
  ## Returns high-level aggregated patch compliance state for a patch group.
  ##   body: JObject (required)
  var body_773991 = newJObject()
  if body != nil:
    body_773991 = body
  result = call_773990.call(nil, nil, nil, nil, body_773991)

var describePatchGroupState* = Call_DescribePatchGroupState_773977(
    name: "describePatchGroupState", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribePatchGroupState",
    validator: validate_DescribePatchGroupState_773978, base: "/",
    url: url_DescribePatchGroupState_773979, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePatchGroups_773992 = ref object of OpenApiRestCall_772597
proc url_DescribePatchGroups_773994(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribePatchGroups_773993(path: JsonNode; query: JsonNode;
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
  var valid_773995 = header.getOrDefault("X-Amz-Date")
  valid_773995 = validateParameter(valid_773995, JString, required = false,
                                 default = nil)
  if valid_773995 != nil:
    section.add "X-Amz-Date", valid_773995
  var valid_773996 = header.getOrDefault("X-Amz-Security-Token")
  valid_773996 = validateParameter(valid_773996, JString, required = false,
                                 default = nil)
  if valid_773996 != nil:
    section.add "X-Amz-Security-Token", valid_773996
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773997 = header.getOrDefault("X-Amz-Target")
  valid_773997 = validateParameter(valid_773997, JString, required = true, default = newJString(
      "AmazonSSM.DescribePatchGroups"))
  if valid_773997 != nil:
    section.add "X-Amz-Target", valid_773997
  var valid_773998 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773998 = validateParameter(valid_773998, JString, required = false,
                                 default = nil)
  if valid_773998 != nil:
    section.add "X-Amz-Content-Sha256", valid_773998
  var valid_773999 = header.getOrDefault("X-Amz-Algorithm")
  valid_773999 = validateParameter(valid_773999, JString, required = false,
                                 default = nil)
  if valid_773999 != nil:
    section.add "X-Amz-Algorithm", valid_773999
  var valid_774000 = header.getOrDefault("X-Amz-Signature")
  valid_774000 = validateParameter(valid_774000, JString, required = false,
                                 default = nil)
  if valid_774000 != nil:
    section.add "X-Amz-Signature", valid_774000
  var valid_774001 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774001 = validateParameter(valid_774001, JString, required = false,
                                 default = nil)
  if valid_774001 != nil:
    section.add "X-Amz-SignedHeaders", valid_774001
  var valid_774002 = header.getOrDefault("X-Amz-Credential")
  valid_774002 = validateParameter(valid_774002, JString, required = false,
                                 default = nil)
  if valid_774002 != nil:
    section.add "X-Amz-Credential", valid_774002
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774004: Call_DescribePatchGroups_773992; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all patch groups that have been registered with patch baselines.
  ## 
  let valid = call_774004.validator(path, query, header, formData, body)
  let scheme = call_774004.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774004.url(scheme.get, call_774004.host, call_774004.base,
                         call_774004.route, valid.getOrDefault("path"))
  result = hook(call_774004, url, valid)

proc call*(call_774005: Call_DescribePatchGroups_773992; body: JsonNode): Recallable =
  ## describePatchGroups
  ## Lists all patch groups that have been registered with patch baselines.
  ##   body: JObject (required)
  var body_774006 = newJObject()
  if body != nil:
    body_774006 = body
  result = call_774005.call(nil, nil, nil, nil, body_774006)

var describePatchGroups* = Call_DescribePatchGroups_773992(
    name: "describePatchGroups", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribePatchGroups",
    validator: validate_DescribePatchGroups_773993, base: "/",
    url: url_DescribePatchGroups_773994, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePatchProperties_774007 = ref object of OpenApiRestCall_772597
proc url_DescribePatchProperties_774009(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribePatchProperties_774008(path: JsonNode; query: JsonNode;
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
  var valid_774010 = header.getOrDefault("X-Amz-Date")
  valid_774010 = validateParameter(valid_774010, JString, required = false,
                                 default = nil)
  if valid_774010 != nil:
    section.add "X-Amz-Date", valid_774010
  var valid_774011 = header.getOrDefault("X-Amz-Security-Token")
  valid_774011 = validateParameter(valid_774011, JString, required = false,
                                 default = nil)
  if valid_774011 != nil:
    section.add "X-Amz-Security-Token", valid_774011
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774012 = header.getOrDefault("X-Amz-Target")
  valid_774012 = validateParameter(valid_774012, JString, required = true, default = newJString(
      "AmazonSSM.DescribePatchProperties"))
  if valid_774012 != nil:
    section.add "X-Amz-Target", valid_774012
  var valid_774013 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774013 = validateParameter(valid_774013, JString, required = false,
                                 default = nil)
  if valid_774013 != nil:
    section.add "X-Amz-Content-Sha256", valid_774013
  var valid_774014 = header.getOrDefault("X-Amz-Algorithm")
  valid_774014 = validateParameter(valid_774014, JString, required = false,
                                 default = nil)
  if valid_774014 != nil:
    section.add "X-Amz-Algorithm", valid_774014
  var valid_774015 = header.getOrDefault("X-Amz-Signature")
  valid_774015 = validateParameter(valid_774015, JString, required = false,
                                 default = nil)
  if valid_774015 != nil:
    section.add "X-Amz-Signature", valid_774015
  var valid_774016 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774016 = validateParameter(valid_774016, JString, required = false,
                                 default = nil)
  if valid_774016 != nil:
    section.add "X-Amz-SignedHeaders", valid_774016
  var valid_774017 = header.getOrDefault("X-Amz-Credential")
  valid_774017 = validateParameter(valid_774017, JString, required = false,
                                 default = nil)
  if valid_774017 != nil:
    section.add "X-Amz-Credential", valid_774017
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774019: Call_DescribePatchProperties_774007; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the properties of available patches organized by product, product family, classification, severity, and other properties of available patches. You can use the reported properties in the filters you specify in requests for actions such as <a>CreatePatchBaseline</a>, <a>UpdatePatchBaseline</a>, <a>DescribeAvailablePatches</a>, and <a>DescribePatchBaselines</a>.</p> <p>The following section lists the properties that can be used in filters for each major operating system type:</p> <dl> <dt>WINDOWS</dt> <dd> <p>Valid properties: PRODUCT, PRODUCT_FAMILY, CLASSIFICATION, MSRC_SEVERITY</p> </dd> <dt>AMAZON_LINUX</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>AMAZON_LINUX_2</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>UBUNTU </dt> <dd> <p>Valid properties: PRODUCT, PRIORITY</p> </dd> <dt>REDHAT_ENTERPRISE_LINUX</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>SUSE</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>CENTOS</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> </dl>
  ## 
  let valid = call_774019.validator(path, query, header, formData, body)
  let scheme = call_774019.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774019.url(scheme.get, call_774019.host, call_774019.base,
                         call_774019.route, valid.getOrDefault("path"))
  result = hook(call_774019, url, valid)

proc call*(call_774020: Call_DescribePatchProperties_774007; body: JsonNode): Recallable =
  ## describePatchProperties
  ## <p>Lists the properties of available patches organized by product, product family, classification, severity, and other properties of available patches. You can use the reported properties in the filters you specify in requests for actions such as <a>CreatePatchBaseline</a>, <a>UpdatePatchBaseline</a>, <a>DescribeAvailablePatches</a>, and <a>DescribePatchBaselines</a>.</p> <p>The following section lists the properties that can be used in filters for each major operating system type:</p> <dl> <dt>WINDOWS</dt> <dd> <p>Valid properties: PRODUCT, PRODUCT_FAMILY, CLASSIFICATION, MSRC_SEVERITY</p> </dd> <dt>AMAZON_LINUX</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>AMAZON_LINUX_2</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>UBUNTU </dt> <dd> <p>Valid properties: PRODUCT, PRIORITY</p> </dd> <dt>REDHAT_ENTERPRISE_LINUX</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>SUSE</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>CENTOS</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> </dl>
  ##   body: JObject (required)
  var body_774021 = newJObject()
  if body != nil:
    body_774021 = body
  result = call_774020.call(nil, nil, nil, nil, body_774021)

var describePatchProperties* = Call_DescribePatchProperties_774007(
    name: "describePatchProperties", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribePatchProperties",
    validator: validate_DescribePatchProperties_774008, base: "/",
    url: url_DescribePatchProperties_774009, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSessions_774022 = ref object of OpenApiRestCall_772597
proc url_DescribeSessions_774024(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeSessions_774023(path: JsonNode; query: JsonNode;
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
  var valid_774025 = header.getOrDefault("X-Amz-Date")
  valid_774025 = validateParameter(valid_774025, JString, required = false,
                                 default = nil)
  if valid_774025 != nil:
    section.add "X-Amz-Date", valid_774025
  var valid_774026 = header.getOrDefault("X-Amz-Security-Token")
  valid_774026 = validateParameter(valid_774026, JString, required = false,
                                 default = nil)
  if valid_774026 != nil:
    section.add "X-Amz-Security-Token", valid_774026
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774027 = header.getOrDefault("X-Amz-Target")
  valid_774027 = validateParameter(valid_774027, JString, required = true, default = newJString(
      "AmazonSSM.DescribeSessions"))
  if valid_774027 != nil:
    section.add "X-Amz-Target", valid_774027
  var valid_774028 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774028 = validateParameter(valid_774028, JString, required = false,
                                 default = nil)
  if valid_774028 != nil:
    section.add "X-Amz-Content-Sha256", valid_774028
  var valid_774029 = header.getOrDefault("X-Amz-Algorithm")
  valid_774029 = validateParameter(valid_774029, JString, required = false,
                                 default = nil)
  if valid_774029 != nil:
    section.add "X-Amz-Algorithm", valid_774029
  var valid_774030 = header.getOrDefault("X-Amz-Signature")
  valid_774030 = validateParameter(valid_774030, JString, required = false,
                                 default = nil)
  if valid_774030 != nil:
    section.add "X-Amz-Signature", valid_774030
  var valid_774031 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774031 = validateParameter(valid_774031, JString, required = false,
                                 default = nil)
  if valid_774031 != nil:
    section.add "X-Amz-SignedHeaders", valid_774031
  var valid_774032 = header.getOrDefault("X-Amz-Credential")
  valid_774032 = validateParameter(valid_774032, JString, required = false,
                                 default = nil)
  if valid_774032 != nil:
    section.add "X-Amz-Credential", valid_774032
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774034: Call_DescribeSessions_774022; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of all active sessions (both connected and disconnected) or terminated sessions from the past 30 days.
  ## 
  let valid = call_774034.validator(path, query, header, formData, body)
  let scheme = call_774034.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774034.url(scheme.get, call_774034.host, call_774034.base,
                         call_774034.route, valid.getOrDefault("path"))
  result = hook(call_774034, url, valid)

proc call*(call_774035: Call_DescribeSessions_774022; body: JsonNode): Recallable =
  ## describeSessions
  ## Retrieves a list of all active sessions (both connected and disconnected) or terminated sessions from the past 30 days.
  ##   body: JObject (required)
  var body_774036 = newJObject()
  if body != nil:
    body_774036 = body
  result = call_774035.call(nil, nil, nil, nil, body_774036)

var describeSessions* = Call_DescribeSessions_774022(name: "describeSessions",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeSessions",
    validator: validate_DescribeSessions_774023, base: "/",
    url: url_DescribeSessions_774024, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAutomationExecution_774037 = ref object of OpenApiRestCall_772597
proc url_GetAutomationExecution_774039(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetAutomationExecution_774038(path: JsonNode; query: JsonNode;
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
  var valid_774040 = header.getOrDefault("X-Amz-Date")
  valid_774040 = validateParameter(valid_774040, JString, required = false,
                                 default = nil)
  if valid_774040 != nil:
    section.add "X-Amz-Date", valid_774040
  var valid_774041 = header.getOrDefault("X-Amz-Security-Token")
  valid_774041 = validateParameter(valid_774041, JString, required = false,
                                 default = nil)
  if valid_774041 != nil:
    section.add "X-Amz-Security-Token", valid_774041
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774042 = header.getOrDefault("X-Amz-Target")
  valid_774042 = validateParameter(valid_774042, JString, required = true, default = newJString(
      "AmazonSSM.GetAutomationExecution"))
  if valid_774042 != nil:
    section.add "X-Amz-Target", valid_774042
  var valid_774043 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774043 = validateParameter(valid_774043, JString, required = false,
                                 default = nil)
  if valid_774043 != nil:
    section.add "X-Amz-Content-Sha256", valid_774043
  var valid_774044 = header.getOrDefault("X-Amz-Algorithm")
  valid_774044 = validateParameter(valid_774044, JString, required = false,
                                 default = nil)
  if valid_774044 != nil:
    section.add "X-Amz-Algorithm", valid_774044
  var valid_774045 = header.getOrDefault("X-Amz-Signature")
  valid_774045 = validateParameter(valid_774045, JString, required = false,
                                 default = nil)
  if valid_774045 != nil:
    section.add "X-Amz-Signature", valid_774045
  var valid_774046 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774046 = validateParameter(valid_774046, JString, required = false,
                                 default = nil)
  if valid_774046 != nil:
    section.add "X-Amz-SignedHeaders", valid_774046
  var valid_774047 = header.getOrDefault("X-Amz-Credential")
  valid_774047 = validateParameter(valid_774047, JString, required = false,
                                 default = nil)
  if valid_774047 != nil:
    section.add "X-Amz-Credential", valid_774047
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774049: Call_GetAutomationExecution_774037; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get detailed information about a particular Automation execution.
  ## 
  let valid = call_774049.validator(path, query, header, formData, body)
  let scheme = call_774049.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774049.url(scheme.get, call_774049.host, call_774049.base,
                         call_774049.route, valid.getOrDefault("path"))
  result = hook(call_774049, url, valid)

proc call*(call_774050: Call_GetAutomationExecution_774037; body: JsonNode): Recallable =
  ## getAutomationExecution
  ## Get detailed information about a particular Automation execution.
  ##   body: JObject (required)
  var body_774051 = newJObject()
  if body != nil:
    body_774051 = body
  result = call_774050.call(nil, nil, nil, nil, body_774051)

var getAutomationExecution* = Call_GetAutomationExecution_774037(
    name: "getAutomationExecution", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetAutomationExecution",
    validator: validate_GetAutomationExecution_774038, base: "/",
    url: url_GetAutomationExecution_774039, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCommandInvocation_774052 = ref object of OpenApiRestCall_772597
proc url_GetCommandInvocation_774054(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCommandInvocation_774053(path: JsonNode; query: JsonNode;
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
  var valid_774055 = header.getOrDefault("X-Amz-Date")
  valid_774055 = validateParameter(valid_774055, JString, required = false,
                                 default = nil)
  if valid_774055 != nil:
    section.add "X-Amz-Date", valid_774055
  var valid_774056 = header.getOrDefault("X-Amz-Security-Token")
  valid_774056 = validateParameter(valid_774056, JString, required = false,
                                 default = nil)
  if valid_774056 != nil:
    section.add "X-Amz-Security-Token", valid_774056
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774057 = header.getOrDefault("X-Amz-Target")
  valid_774057 = validateParameter(valid_774057, JString, required = true, default = newJString(
      "AmazonSSM.GetCommandInvocation"))
  if valid_774057 != nil:
    section.add "X-Amz-Target", valid_774057
  var valid_774058 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774058 = validateParameter(valid_774058, JString, required = false,
                                 default = nil)
  if valid_774058 != nil:
    section.add "X-Amz-Content-Sha256", valid_774058
  var valid_774059 = header.getOrDefault("X-Amz-Algorithm")
  valid_774059 = validateParameter(valid_774059, JString, required = false,
                                 default = nil)
  if valid_774059 != nil:
    section.add "X-Amz-Algorithm", valid_774059
  var valid_774060 = header.getOrDefault("X-Amz-Signature")
  valid_774060 = validateParameter(valid_774060, JString, required = false,
                                 default = nil)
  if valid_774060 != nil:
    section.add "X-Amz-Signature", valid_774060
  var valid_774061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774061 = validateParameter(valid_774061, JString, required = false,
                                 default = nil)
  if valid_774061 != nil:
    section.add "X-Amz-SignedHeaders", valid_774061
  var valid_774062 = header.getOrDefault("X-Amz-Credential")
  valid_774062 = validateParameter(valid_774062, JString, required = false,
                                 default = nil)
  if valid_774062 != nil:
    section.add "X-Amz-Credential", valid_774062
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774064: Call_GetCommandInvocation_774052; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns detailed information about command execution for an invocation or plugin. 
  ## 
  let valid = call_774064.validator(path, query, header, formData, body)
  let scheme = call_774064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774064.url(scheme.get, call_774064.host, call_774064.base,
                         call_774064.route, valid.getOrDefault("path"))
  result = hook(call_774064, url, valid)

proc call*(call_774065: Call_GetCommandInvocation_774052; body: JsonNode): Recallable =
  ## getCommandInvocation
  ## Returns detailed information about command execution for an invocation or plugin. 
  ##   body: JObject (required)
  var body_774066 = newJObject()
  if body != nil:
    body_774066 = body
  result = call_774065.call(nil, nil, nil, nil, body_774066)

var getCommandInvocation* = Call_GetCommandInvocation_774052(
    name: "getCommandInvocation", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetCommandInvocation",
    validator: validate_GetCommandInvocation_774053, base: "/",
    url: url_GetCommandInvocation_774054, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnectionStatus_774067 = ref object of OpenApiRestCall_772597
proc url_GetConnectionStatus_774069(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetConnectionStatus_774068(path: JsonNode; query: JsonNode;
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
  var valid_774070 = header.getOrDefault("X-Amz-Date")
  valid_774070 = validateParameter(valid_774070, JString, required = false,
                                 default = nil)
  if valid_774070 != nil:
    section.add "X-Amz-Date", valid_774070
  var valid_774071 = header.getOrDefault("X-Amz-Security-Token")
  valid_774071 = validateParameter(valid_774071, JString, required = false,
                                 default = nil)
  if valid_774071 != nil:
    section.add "X-Amz-Security-Token", valid_774071
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774072 = header.getOrDefault("X-Amz-Target")
  valid_774072 = validateParameter(valid_774072, JString, required = true, default = newJString(
      "AmazonSSM.GetConnectionStatus"))
  if valid_774072 != nil:
    section.add "X-Amz-Target", valid_774072
  var valid_774073 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774073 = validateParameter(valid_774073, JString, required = false,
                                 default = nil)
  if valid_774073 != nil:
    section.add "X-Amz-Content-Sha256", valid_774073
  var valid_774074 = header.getOrDefault("X-Amz-Algorithm")
  valid_774074 = validateParameter(valid_774074, JString, required = false,
                                 default = nil)
  if valid_774074 != nil:
    section.add "X-Amz-Algorithm", valid_774074
  var valid_774075 = header.getOrDefault("X-Amz-Signature")
  valid_774075 = validateParameter(valid_774075, JString, required = false,
                                 default = nil)
  if valid_774075 != nil:
    section.add "X-Amz-Signature", valid_774075
  var valid_774076 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774076 = validateParameter(valid_774076, JString, required = false,
                                 default = nil)
  if valid_774076 != nil:
    section.add "X-Amz-SignedHeaders", valid_774076
  var valid_774077 = header.getOrDefault("X-Amz-Credential")
  valid_774077 = validateParameter(valid_774077, JString, required = false,
                                 default = nil)
  if valid_774077 != nil:
    section.add "X-Amz-Credential", valid_774077
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774079: Call_GetConnectionStatus_774067; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the Session Manager connection status for an instance to determine whether it is connected and ready to receive Session Manager connections.
  ## 
  let valid = call_774079.validator(path, query, header, formData, body)
  let scheme = call_774079.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774079.url(scheme.get, call_774079.host, call_774079.base,
                         call_774079.route, valid.getOrDefault("path"))
  result = hook(call_774079, url, valid)

proc call*(call_774080: Call_GetConnectionStatus_774067; body: JsonNode): Recallable =
  ## getConnectionStatus
  ## Retrieves the Session Manager connection status for an instance to determine whether it is connected and ready to receive Session Manager connections.
  ##   body: JObject (required)
  var body_774081 = newJObject()
  if body != nil:
    body_774081 = body
  result = call_774080.call(nil, nil, nil, nil, body_774081)

var getConnectionStatus* = Call_GetConnectionStatus_774067(
    name: "getConnectionStatus", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetConnectionStatus",
    validator: validate_GetConnectionStatus_774068, base: "/",
    url: url_GetConnectionStatus_774069, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefaultPatchBaseline_774082 = ref object of OpenApiRestCall_772597
proc url_GetDefaultPatchBaseline_774084(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDefaultPatchBaseline_774083(path: JsonNode; query: JsonNode;
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
  var valid_774085 = header.getOrDefault("X-Amz-Date")
  valid_774085 = validateParameter(valid_774085, JString, required = false,
                                 default = nil)
  if valid_774085 != nil:
    section.add "X-Amz-Date", valid_774085
  var valid_774086 = header.getOrDefault("X-Amz-Security-Token")
  valid_774086 = validateParameter(valid_774086, JString, required = false,
                                 default = nil)
  if valid_774086 != nil:
    section.add "X-Amz-Security-Token", valid_774086
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774087 = header.getOrDefault("X-Amz-Target")
  valid_774087 = validateParameter(valid_774087, JString, required = true, default = newJString(
      "AmazonSSM.GetDefaultPatchBaseline"))
  if valid_774087 != nil:
    section.add "X-Amz-Target", valid_774087
  var valid_774088 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774088 = validateParameter(valid_774088, JString, required = false,
                                 default = nil)
  if valid_774088 != nil:
    section.add "X-Amz-Content-Sha256", valid_774088
  var valid_774089 = header.getOrDefault("X-Amz-Algorithm")
  valid_774089 = validateParameter(valid_774089, JString, required = false,
                                 default = nil)
  if valid_774089 != nil:
    section.add "X-Amz-Algorithm", valid_774089
  var valid_774090 = header.getOrDefault("X-Amz-Signature")
  valid_774090 = validateParameter(valid_774090, JString, required = false,
                                 default = nil)
  if valid_774090 != nil:
    section.add "X-Amz-Signature", valid_774090
  var valid_774091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774091 = validateParameter(valid_774091, JString, required = false,
                                 default = nil)
  if valid_774091 != nil:
    section.add "X-Amz-SignedHeaders", valid_774091
  var valid_774092 = header.getOrDefault("X-Amz-Credential")
  valid_774092 = validateParameter(valid_774092, JString, required = false,
                                 default = nil)
  if valid_774092 != nil:
    section.add "X-Amz-Credential", valid_774092
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774094: Call_GetDefaultPatchBaseline_774082; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the default patch baseline. Note that Systems Manager supports creating multiple default patch baselines. For example, you can create a default patch baseline for each operating system.</p> <p>If you do not specify an operating system value, the default patch baseline for Windows is returned.</p>
  ## 
  let valid = call_774094.validator(path, query, header, formData, body)
  let scheme = call_774094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774094.url(scheme.get, call_774094.host, call_774094.base,
                         call_774094.route, valid.getOrDefault("path"))
  result = hook(call_774094, url, valid)

proc call*(call_774095: Call_GetDefaultPatchBaseline_774082; body: JsonNode): Recallable =
  ## getDefaultPatchBaseline
  ## <p>Retrieves the default patch baseline. Note that Systems Manager supports creating multiple default patch baselines. For example, you can create a default patch baseline for each operating system.</p> <p>If you do not specify an operating system value, the default patch baseline for Windows is returned.</p>
  ##   body: JObject (required)
  var body_774096 = newJObject()
  if body != nil:
    body_774096 = body
  result = call_774095.call(nil, nil, nil, nil, body_774096)

var getDefaultPatchBaseline* = Call_GetDefaultPatchBaseline_774082(
    name: "getDefaultPatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetDefaultPatchBaseline",
    validator: validate_GetDefaultPatchBaseline_774083, base: "/",
    url: url_GetDefaultPatchBaseline_774084, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployablePatchSnapshotForInstance_774097 = ref object of OpenApiRestCall_772597
proc url_GetDeployablePatchSnapshotForInstance_774099(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeployablePatchSnapshotForInstance_774098(path: JsonNode;
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
  var valid_774100 = header.getOrDefault("X-Amz-Date")
  valid_774100 = validateParameter(valid_774100, JString, required = false,
                                 default = nil)
  if valid_774100 != nil:
    section.add "X-Amz-Date", valid_774100
  var valid_774101 = header.getOrDefault("X-Amz-Security-Token")
  valid_774101 = validateParameter(valid_774101, JString, required = false,
                                 default = nil)
  if valid_774101 != nil:
    section.add "X-Amz-Security-Token", valid_774101
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774102 = header.getOrDefault("X-Amz-Target")
  valid_774102 = validateParameter(valid_774102, JString, required = true, default = newJString(
      "AmazonSSM.GetDeployablePatchSnapshotForInstance"))
  if valid_774102 != nil:
    section.add "X-Amz-Target", valid_774102
  var valid_774103 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774103 = validateParameter(valid_774103, JString, required = false,
                                 default = nil)
  if valid_774103 != nil:
    section.add "X-Amz-Content-Sha256", valid_774103
  var valid_774104 = header.getOrDefault("X-Amz-Algorithm")
  valid_774104 = validateParameter(valid_774104, JString, required = false,
                                 default = nil)
  if valid_774104 != nil:
    section.add "X-Amz-Algorithm", valid_774104
  var valid_774105 = header.getOrDefault("X-Amz-Signature")
  valid_774105 = validateParameter(valid_774105, JString, required = false,
                                 default = nil)
  if valid_774105 != nil:
    section.add "X-Amz-Signature", valid_774105
  var valid_774106 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774106 = validateParameter(valid_774106, JString, required = false,
                                 default = nil)
  if valid_774106 != nil:
    section.add "X-Amz-SignedHeaders", valid_774106
  var valid_774107 = header.getOrDefault("X-Amz-Credential")
  valid_774107 = validateParameter(valid_774107, JString, required = false,
                                 default = nil)
  if valid_774107 != nil:
    section.add "X-Amz-Credential", valid_774107
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774109: Call_GetDeployablePatchSnapshotForInstance_774097;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the current snapshot for the patch baseline the instance uses. This API is primarily used by the AWS-RunPatchBaseline Systems Manager document. 
  ## 
  let valid = call_774109.validator(path, query, header, formData, body)
  let scheme = call_774109.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774109.url(scheme.get, call_774109.host, call_774109.base,
                         call_774109.route, valid.getOrDefault("path"))
  result = hook(call_774109, url, valid)

proc call*(call_774110: Call_GetDeployablePatchSnapshotForInstance_774097;
          body: JsonNode): Recallable =
  ## getDeployablePatchSnapshotForInstance
  ## Retrieves the current snapshot for the patch baseline the instance uses. This API is primarily used by the AWS-RunPatchBaseline Systems Manager document. 
  ##   body: JObject (required)
  var body_774111 = newJObject()
  if body != nil:
    body_774111 = body
  result = call_774110.call(nil, nil, nil, nil, body_774111)

var getDeployablePatchSnapshotForInstance* = Call_GetDeployablePatchSnapshotForInstance_774097(
    name: "getDeployablePatchSnapshotForInstance", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetDeployablePatchSnapshotForInstance",
    validator: validate_GetDeployablePatchSnapshotForInstance_774098, base: "/",
    url: url_GetDeployablePatchSnapshotForInstance_774099,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocument_774112 = ref object of OpenApiRestCall_772597
proc url_GetDocument_774114(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDocument_774113(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774115 = header.getOrDefault("X-Amz-Date")
  valid_774115 = validateParameter(valid_774115, JString, required = false,
                                 default = nil)
  if valid_774115 != nil:
    section.add "X-Amz-Date", valid_774115
  var valid_774116 = header.getOrDefault("X-Amz-Security-Token")
  valid_774116 = validateParameter(valid_774116, JString, required = false,
                                 default = nil)
  if valid_774116 != nil:
    section.add "X-Amz-Security-Token", valid_774116
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774117 = header.getOrDefault("X-Amz-Target")
  valid_774117 = validateParameter(valid_774117, JString, required = true,
                                 default = newJString("AmazonSSM.GetDocument"))
  if valid_774117 != nil:
    section.add "X-Amz-Target", valid_774117
  var valid_774118 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774118 = validateParameter(valid_774118, JString, required = false,
                                 default = nil)
  if valid_774118 != nil:
    section.add "X-Amz-Content-Sha256", valid_774118
  var valid_774119 = header.getOrDefault("X-Amz-Algorithm")
  valid_774119 = validateParameter(valid_774119, JString, required = false,
                                 default = nil)
  if valid_774119 != nil:
    section.add "X-Amz-Algorithm", valid_774119
  var valid_774120 = header.getOrDefault("X-Amz-Signature")
  valid_774120 = validateParameter(valid_774120, JString, required = false,
                                 default = nil)
  if valid_774120 != nil:
    section.add "X-Amz-Signature", valid_774120
  var valid_774121 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774121 = validateParameter(valid_774121, JString, required = false,
                                 default = nil)
  if valid_774121 != nil:
    section.add "X-Amz-SignedHeaders", valid_774121
  var valid_774122 = header.getOrDefault("X-Amz-Credential")
  valid_774122 = validateParameter(valid_774122, JString, required = false,
                                 default = nil)
  if valid_774122 != nil:
    section.add "X-Amz-Credential", valid_774122
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774124: Call_GetDocument_774112; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the contents of the specified Systems Manager document.
  ## 
  let valid = call_774124.validator(path, query, header, formData, body)
  let scheme = call_774124.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774124.url(scheme.get, call_774124.host, call_774124.base,
                         call_774124.route, valid.getOrDefault("path"))
  result = hook(call_774124, url, valid)

proc call*(call_774125: Call_GetDocument_774112; body: JsonNode): Recallable =
  ## getDocument
  ## Gets the contents of the specified Systems Manager document.
  ##   body: JObject (required)
  var body_774126 = newJObject()
  if body != nil:
    body_774126 = body
  result = call_774125.call(nil, nil, nil, nil, body_774126)

var getDocument* = Call_GetDocument_774112(name: "getDocument",
                                        meth: HttpMethod.HttpPost,
                                        host: "ssm.amazonaws.com", route: "/#X-Amz-Target=AmazonSSM.GetDocument",
                                        validator: validate_GetDocument_774113,
                                        base: "/", url: url_GetDocument_774114,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInventory_774127 = ref object of OpenApiRestCall_772597
proc url_GetInventory_774129(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetInventory_774128(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774130 = header.getOrDefault("X-Amz-Date")
  valid_774130 = validateParameter(valid_774130, JString, required = false,
                                 default = nil)
  if valid_774130 != nil:
    section.add "X-Amz-Date", valid_774130
  var valid_774131 = header.getOrDefault("X-Amz-Security-Token")
  valid_774131 = validateParameter(valid_774131, JString, required = false,
                                 default = nil)
  if valid_774131 != nil:
    section.add "X-Amz-Security-Token", valid_774131
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774132 = header.getOrDefault("X-Amz-Target")
  valid_774132 = validateParameter(valid_774132, JString, required = true,
                                 default = newJString("AmazonSSM.GetInventory"))
  if valid_774132 != nil:
    section.add "X-Amz-Target", valid_774132
  var valid_774133 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774133 = validateParameter(valid_774133, JString, required = false,
                                 default = nil)
  if valid_774133 != nil:
    section.add "X-Amz-Content-Sha256", valid_774133
  var valid_774134 = header.getOrDefault("X-Amz-Algorithm")
  valid_774134 = validateParameter(valid_774134, JString, required = false,
                                 default = nil)
  if valid_774134 != nil:
    section.add "X-Amz-Algorithm", valid_774134
  var valid_774135 = header.getOrDefault("X-Amz-Signature")
  valid_774135 = validateParameter(valid_774135, JString, required = false,
                                 default = nil)
  if valid_774135 != nil:
    section.add "X-Amz-Signature", valid_774135
  var valid_774136 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774136 = validateParameter(valid_774136, JString, required = false,
                                 default = nil)
  if valid_774136 != nil:
    section.add "X-Amz-SignedHeaders", valid_774136
  var valid_774137 = header.getOrDefault("X-Amz-Credential")
  valid_774137 = validateParameter(valid_774137, JString, required = false,
                                 default = nil)
  if valid_774137 != nil:
    section.add "X-Amz-Credential", valid_774137
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774139: Call_GetInventory_774127; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Query inventory information.
  ## 
  let valid = call_774139.validator(path, query, header, formData, body)
  let scheme = call_774139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774139.url(scheme.get, call_774139.host, call_774139.base,
                         call_774139.route, valid.getOrDefault("path"))
  result = hook(call_774139, url, valid)

proc call*(call_774140: Call_GetInventory_774127; body: JsonNode): Recallable =
  ## getInventory
  ## Query inventory information.
  ##   body: JObject (required)
  var body_774141 = newJObject()
  if body != nil:
    body_774141 = body
  result = call_774140.call(nil, nil, nil, nil, body_774141)

var getInventory* = Call_GetInventory_774127(name: "getInventory",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetInventory",
    validator: validate_GetInventory_774128, base: "/", url: url_GetInventory_774129,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInventorySchema_774142 = ref object of OpenApiRestCall_772597
proc url_GetInventorySchema_774144(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetInventorySchema_774143(path: JsonNode; query: JsonNode;
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
  var valid_774145 = header.getOrDefault("X-Amz-Date")
  valid_774145 = validateParameter(valid_774145, JString, required = false,
                                 default = nil)
  if valid_774145 != nil:
    section.add "X-Amz-Date", valid_774145
  var valid_774146 = header.getOrDefault("X-Amz-Security-Token")
  valid_774146 = validateParameter(valid_774146, JString, required = false,
                                 default = nil)
  if valid_774146 != nil:
    section.add "X-Amz-Security-Token", valid_774146
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774147 = header.getOrDefault("X-Amz-Target")
  valid_774147 = validateParameter(valid_774147, JString, required = true, default = newJString(
      "AmazonSSM.GetInventorySchema"))
  if valid_774147 != nil:
    section.add "X-Amz-Target", valid_774147
  var valid_774148 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774148 = validateParameter(valid_774148, JString, required = false,
                                 default = nil)
  if valid_774148 != nil:
    section.add "X-Amz-Content-Sha256", valid_774148
  var valid_774149 = header.getOrDefault("X-Amz-Algorithm")
  valid_774149 = validateParameter(valid_774149, JString, required = false,
                                 default = nil)
  if valid_774149 != nil:
    section.add "X-Amz-Algorithm", valid_774149
  var valid_774150 = header.getOrDefault("X-Amz-Signature")
  valid_774150 = validateParameter(valid_774150, JString, required = false,
                                 default = nil)
  if valid_774150 != nil:
    section.add "X-Amz-Signature", valid_774150
  var valid_774151 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774151 = validateParameter(valid_774151, JString, required = false,
                                 default = nil)
  if valid_774151 != nil:
    section.add "X-Amz-SignedHeaders", valid_774151
  var valid_774152 = header.getOrDefault("X-Amz-Credential")
  valid_774152 = validateParameter(valid_774152, JString, required = false,
                                 default = nil)
  if valid_774152 != nil:
    section.add "X-Amz-Credential", valid_774152
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774154: Call_GetInventorySchema_774142; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Return a list of inventory type names for the account, or return a list of attribute names for a specific Inventory item type. 
  ## 
  let valid = call_774154.validator(path, query, header, formData, body)
  let scheme = call_774154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774154.url(scheme.get, call_774154.host, call_774154.base,
                         call_774154.route, valid.getOrDefault("path"))
  result = hook(call_774154, url, valid)

proc call*(call_774155: Call_GetInventorySchema_774142; body: JsonNode): Recallable =
  ## getInventorySchema
  ## Return a list of inventory type names for the account, or return a list of attribute names for a specific Inventory item type. 
  ##   body: JObject (required)
  var body_774156 = newJObject()
  if body != nil:
    body_774156 = body
  result = call_774155.call(nil, nil, nil, nil, body_774156)

var getInventorySchema* = Call_GetInventorySchema_774142(
    name: "getInventorySchema", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetInventorySchema",
    validator: validate_GetInventorySchema_774143, base: "/",
    url: url_GetInventorySchema_774144, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMaintenanceWindow_774157 = ref object of OpenApiRestCall_772597
proc url_GetMaintenanceWindow_774159(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetMaintenanceWindow_774158(path: JsonNode; query: JsonNode;
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
  var valid_774160 = header.getOrDefault("X-Amz-Date")
  valid_774160 = validateParameter(valid_774160, JString, required = false,
                                 default = nil)
  if valid_774160 != nil:
    section.add "X-Amz-Date", valid_774160
  var valid_774161 = header.getOrDefault("X-Amz-Security-Token")
  valid_774161 = validateParameter(valid_774161, JString, required = false,
                                 default = nil)
  if valid_774161 != nil:
    section.add "X-Amz-Security-Token", valid_774161
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774162 = header.getOrDefault("X-Amz-Target")
  valid_774162 = validateParameter(valid_774162, JString, required = true, default = newJString(
      "AmazonSSM.GetMaintenanceWindow"))
  if valid_774162 != nil:
    section.add "X-Amz-Target", valid_774162
  var valid_774163 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774163 = validateParameter(valid_774163, JString, required = false,
                                 default = nil)
  if valid_774163 != nil:
    section.add "X-Amz-Content-Sha256", valid_774163
  var valid_774164 = header.getOrDefault("X-Amz-Algorithm")
  valid_774164 = validateParameter(valid_774164, JString, required = false,
                                 default = nil)
  if valid_774164 != nil:
    section.add "X-Amz-Algorithm", valid_774164
  var valid_774165 = header.getOrDefault("X-Amz-Signature")
  valid_774165 = validateParameter(valid_774165, JString, required = false,
                                 default = nil)
  if valid_774165 != nil:
    section.add "X-Amz-Signature", valid_774165
  var valid_774166 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774166 = validateParameter(valid_774166, JString, required = false,
                                 default = nil)
  if valid_774166 != nil:
    section.add "X-Amz-SignedHeaders", valid_774166
  var valid_774167 = header.getOrDefault("X-Amz-Credential")
  valid_774167 = validateParameter(valid_774167, JString, required = false,
                                 default = nil)
  if valid_774167 != nil:
    section.add "X-Amz-Credential", valid_774167
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774169: Call_GetMaintenanceWindow_774157; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a maintenance window.
  ## 
  let valid = call_774169.validator(path, query, header, formData, body)
  let scheme = call_774169.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774169.url(scheme.get, call_774169.host, call_774169.base,
                         call_774169.route, valid.getOrDefault("path"))
  result = hook(call_774169, url, valid)

proc call*(call_774170: Call_GetMaintenanceWindow_774157; body: JsonNode): Recallable =
  ## getMaintenanceWindow
  ## Retrieves a maintenance window.
  ##   body: JObject (required)
  var body_774171 = newJObject()
  if body != nil:
    body_774171 = body
  result = call_774170.call(nil, nil, nil, nil, body_774171)

var getMaintenanceWindow* = Call_GetMaintenanceWindow_774157(
    name: "getMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetMaintenanceWindow",
    validator: validate_GetMaintenanceWindow_774158, base: "/",
    url: url_GetMaintenanceWindow_774159, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMaintenanceWindowExecution_774172 = ref object of OpenApiRestCall_772597
proc url_GetMaintenanceWindowExecution_774174(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetMaintenanceWindowExecution_774173(path: JsonNode; query: JsonNode;
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
  var valid_774175 = header.getOrDefault("X-Amz-Date")
  valid_774175 = validateParameter(valid_774175, JString, required = false,
                                 default = nil)
  if valid_774175 != nil:
    section.add "X-Amz-Date", valid_774175
  var valid_774176 = header.getOrDefault("X-Amz-Security-Token")
  valid_774176 = validateParameter(valid_774176, JString, required = false,
                                 default = nil)
  if valid_774176 != nil:
    section.add "X-Amz-Security-Token", valid_774176
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774177 = header.getOrDefault("X-Amz-Target")
  valid_774177 = validateParameter(valid_774177, JString, required = true, default = newJString(
      "AmazonSSM.GetMaintenanceWindowExecution"))
  if valid_774177 != nil:
    section.add "X-Amz-Target", valid_774177
  var valid_774178 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774178 = validateParameter(valid_774178, JString, required = false,
                                 default = nil)
  if valid_774178 != nil:
    section.add "X-Amz-Content-Sha256", valid_774178
  var valid_774179 = header.getOrDefault("X-Amz-Algorithm")
  valid_774179 = validateParameter(valid_774179, JString, required = false,
                                 default = nil)
  if valid_774179 != nil:
    section.add "X-Amz-Algorithm", valid_774179
  var valid_774180 = header.getOrDefault("X-Amz-Signature")
  valid_774180 = validateParameter(valid_774180, JString, required = false,
                                 default = nil)
  if valid_774180 != nil:
    section.add "X-Amz-Signature", valid_774180
  var valid_774181 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774181 = validateParameter(valid_774181, JString, required = false,
                                 default = nil)
  if valid_774181 != nil:
    section.add "X-Amz-SignedHeaders", valid_774181
  var valid_774182 = header.getOrDefault("X-Amz-Credential")
  valid_774182 = validateParameter(valid_774182, JString, required = false,
                                 default = nil)
  if valid_774182 != nil:
    section.add "X-Amz-Credential", valid_774182
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774184: Call_GetMaintenanceWindowExecution_774172; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details about a specific a maintenance window execution.
  ## 
  let valid = call_774184.validator(path, query, header, formData, body)
  let scheme = call_774184.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774184.url(scheme.get, call_774184.host, call_774184.base,
                         call_774184.route, valid.getOrDefault("path"))
  result = hook(call_774184, url, valid)

proc call*(call_774185: Call_GetMaintenanceWindowExecution_774172; body: JsonNode): Recallable =
  ## getMaintenanceWindowExecution
  ## Retrieves details about a specific a maintenance window execution.
  ##   body: JObject (required)
  var body_774186 = newJObject()
  if body != nil:
    body_774186 = body
  result = call_774185.call(nil, nil, nil, nil, body_774186)

var getMaintenanceWindowExecution* = Call_GetMaintenanceWindowExecution_774172(
    name: "getMaintenanceWindowExecution", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetMaintenanceWindowExecution",
    validator: validate_GetMaintenanceWindowExecution_774173, base: "/",
    url: url_GetMaintenanceWindowExecution_774174,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMaintenanceWindowExecutionTask_774187 = ref object of OpenApiRestCall_772597
proc url_GetMaintenanceWindowExecutionTask_774189(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetMaintenanceWindowExecutionTask_774188(path: JsonNode;
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
  var valid_774190 = header.getOrDefault("X-Amz-Date")
  valid_774190 = validateParameter(valid_774190, JString, required = false,
                                 default = nil)
  if valid_774190 != nil:
    section.add "X-Amz-Date", valid_774190
  var valid_774191 = header.getOrDefault("X-Amz-Security-Token")
  valid_774191 = validateParameter(valid_774191, JString, required = false,
                                 default = nil)
  if valid_774191 != nil:
    section.add "X-Amz-Security-Token", valid_774191
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774192 = header.getOrDefault("X-Amz-Target")
  valid_774192 = validateParameter(valid_774192, JString, required = true, default = newJString(
      "AmazonSSM.GetMaintenanceWindowExecutionTask"))
  if valid_774192 != nil:
    section.add "X-Amz-Target", valid_774192
  var valid_774193 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774193 = validateParameter(valid_774193, JString, required = false,
                                 default = nil)
  if valid_774193 != nil:
    section.add "X-Amz-Content-Sha256", valid_774193
  var valid_774194 = header.getOrDefault("X-Amz-Algorithm")
  valid_774194 = validateParameter(valid_774194, JString, required = false,
                                 default = nil)
  if valid_774194 != nil:
    section.add "X-Amz-Algorithm", valid_774194
  var valid_774195 = header.getOrDefault("X-Amz-Signature")
  valid_774195 = validateParameter(valid_774195, JString, required = false,
                                 default = nil)
  if valid_774195 != nil:
    section.add "X-Amz-Signature", valid_774195
  var valid_774196 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774196 = validateParameter(valid_774196, JString, required = false,
                                 default = nil)
  if valid_774196 != nil:
    section.add "X-Amz-SignedHeaders", valid_774196
  var valid_774197 = header.getOrDefault("X-Amz-Credential")
  valid_774197 = validateParameter(valid_774197, JString, required = false,
                                 default = nil)
  if valid_774197 != nil:
    section.add "X-Amz-Credential", valid_774197
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774199: Call_GetMaintenanceWindowExecutionTask_774187;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the details about a specific task run as part of a maintenance window execution.
  ## 
  let valid = call_774199.validator(path, query, header, formData, body)
  let scheme = call_774199.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774199.url(scheme.get, call_774199.host, call_774199.base,
                         call_774199.route, valid.getOrDefault("path"))
  result = hook(call_774199, url, valid)

proc call*(call_774200: Call_GetMaintenanceWindowExecutionTask_774187;
          body: JsonNode): Recallable =
  ## getMaintenanceWindowExecutionTask
  ## Retrieves the details about a specific task run as part of a maintenance window execution.
  ##   body: JObject (required)
  var body_774201 = newJObject()
  if body != nil:
    body_774201 = body
  result = call_774200.call(nil, nil, nil, nil, body_774201)

var getMaintenanceWindowExecutionTask* = Call_GetMaintenanceWindowExecutionTask_774187(
    name: "getMaintenanceWindowExecutionTask", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetMaintenanceWindowExecutionTask",
    validator: validate_GetMaintenanceWindowExecutionTask_774188, base: "/",
    url: url_GetMaintenanceWindowExecutionTask_774189,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMaintenanceWindowExecutionTaskInvocation_774202 = ref object of OpenApiRestCall_772597
proc url_GetMaintenanceWindowExecutionTaskInvocation_774204(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetMaintenanceWindowExecutionTaskInvocation_774203(path: JsonNode;
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
  var valid_774205 = header.getOrDefault("X-Amz-Date")
  valid_774205 = validateParameter(valid_774205, JString, required = false,
                                 default = nil)
  if valid_774205 != nil:
    section.add "X-Amz-Date", valid_774205
  var valid_774206 = header.getOrDefault("X-Amz-Security-Token")
  valid_774206 = validateParameter(valid_774206, JString, required = false,
                                 default = nil)
  if valid_774206 != nil:
    section.add "X-Amz-Security-Token", valid_774206
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774207 = header.getOrDefault("X-Amz-Target")
  valid_774207 = validateParameter(valid_774207, JString, required = true, default = newJString(
      "AmazonSSM.GetMaintenanceWindowExecutionTaskInvocation"))
  if valid_774207 != nil:
    section.add "X-Amz-Target", valid_774207
  var valid_774208 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774208 = validateParameter(valid_774208, JString, required = false,
                                 default = nil)
  if valid_774208 != nil:
    section.add "X-Amz-Content-Sha256", valid_774208
  var valid_774209 = header.getOrDefault("X-Amz-Algorithm")
  valid_774209 = validateParameter(valid_774209, JString, required = false,
                                 default = nil)
  if valid_774209 != nil:
    section.add "X-Amz-Algorithm", valid_774209
  var valid_774210 = header.getOrDefault("X-Amz-Signature")
  valid_774210 = validateParameter(valid_774210, JString, required = false,
                                 default = nil)
  if valid_774210 != nil:
    section.add "X-Amz-Signature", valid_774210
  var valid_774211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774211 = validateParameter(valid_774211, JString, required = false,
                                 default = nil)
  if valid_774211 != nil:
    section.add "X-Amz-SignedHeaders", valid_774211
  var valid_774212 = header.getOrDefault("X-Amz-Credential")
  valid_774212 = validateParameter(valid_774212, JString, required = false,
                                 default = nil)
  if valid_774212 != nil:
    section.add "X-Amz-Credential", valid_774212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774214: Call_GetMaintenanceWindowExecutionTaskInvocation_774202;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves information about a specific task running on a specific target.
  ## 
  let valid = call_774214.validator(path, query, header, formData, body)
  let scheme = call_774214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774214.url(scheme.get, call_774214.host, call_774214.base,
                         call_774214.route, valid.getOrDefault("path"))
  result = hook(call_774214, url, valid)

proc call*(call_774215: Call_GetMaintenanceWindowExecutionTaskInvocation_774202;
          body: JsonNode): Recallable =
  ## getMaintenanceWindowExecutionTaskInvocation
  ## Retrieves information about a specific task running on a specific target.
  ##   body: JObject (required)
  var body_774216 = newJObject()
  if body != nil:
    body_774216 = body
  result = call_774215.call(nil, nil, nil, nil, body_774216)

var getMaintenanceWindowExecutionTaskInvocation* = Call_GetMaintenanceWindowExecutionTaskInvocation_774202(
    name: "getMaintenanceWindowExecutionTaskInvocation",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com", route: "/#X-Amz-Target=AmazonSSM.GetMaintenanceWindowExecutionTaskInvocation",
    validator: validate_GetMaintenanceWindowExecutionTaskInvocation_774203,
    base: "/", url: url_GetMaintenanceWindowExecutionTaskInvocation_774204,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMaintenanceWindowTask_774217 = ref object of OpenApiRestCall_772597
proc url_GetMaintenanceWindowTask_774219(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetMaintenanceWindowTask_774218(path: JsonNode; query: JsonNode;
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
  var valid_774220 = header.getOrDefault("X-Amz-Date")
  valid_774220 = validateParameter(valid_774220, JString, required = false,
                                 default = nil)
  if valid_774220 != nil:
    section.add "X-Amz-Date", valid_774220
  var valid_774221 = header.getOrDefault("X-Amz-Security-Token")
  valid_774221 = validateParameter(valid_774221, JString, required = false,
                                 default = nil)
  if valid_774221 != nil:
    section.add "X-Amz-Security-Token", valid_774221
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774222 = header.getOrDefault("X-Amz-Target")
  valid_774222 = validateParameter(valid_774222, JString, required = true, default = newJString(
      "AmazonSSM.GetMaintenanceWindowTask"))
  if valid_774222 != nil:
    section.add "X-Amz-Target", valid_774222
  var valid_774223 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774223 = validateParameter(valid_774223, JString, required = false,
                                 default = nil)
  if valid_774223 != nil:
    section.add "X-Amz-Content-Sha256", valid_774223
  var valid_774224 = header.getOrDefault("X-Amz-Algorithm")
  valid_774224 = validateParameter(valid_774224, JString, required = false,
                                 default = nil)
  if valid_774224 != nil:
    section.add "X-Amz-Algorithm", valid_774224
  var valid_774225 = header.getOrDefault("X-Amz-Signature")
  valid_774225 = validateParameter(valid_774225, JString, required = false,
                                 default = nil)
  if valid_774225 != nil:
    section.add "X-Amz-Signature", valid_774225
  var valid_774226 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774226 = validateParameter(valid_774226, JString, required = false,
                                 default = nil)
  if valid_774226 != nil:
    section.add "X-Amz-SignedHeaders", valid_774226
  var valid_774227 = header.getOrDefault("X-Amz-Credential")
  valid_774227 = validateParameter(valid_774227, JString, required = false,
                                 default = nil)
  if valid_774227 != nil:
    section.add "X-Amz-Credential", valid_774227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774229: Call_GetMaintenanceWindowTask_774217; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tasks in a maintenance window.
  ## 
  let valid = call_774229.validator(path, query, header, formData, body)
  let scheme = call_774229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774229.url(scheme.get, call_774229.host, call_774229.base,
                         call_774229.route, valid.getOrDefault("path"))
  result = hook(call_774229, url, valid)

proc call*(call_774230: Call_GetMaintenanceWindowTask_774217; body: JsonNode): Recallable =
  ## getMaintenanceWindowTask
  ## Lists the tasks in a maintenance window.
  ##   body: JObject (required)
  var body_774231 = newJObject()
  if body != nil:
    body_774231 = body
  result = call_774230.call(nil, nil, nil, nil, body_774231)

var getMaintenanceWindowTask* = Call_GetMaintenanceWindowTask_774217(
    name: "getMaintenanceWindowTask", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetMaintenanceWindowTask",
    validator: validate_GetMaintenanceWindowTask_774218, base: "/",
    url: url_GetMaintenanceWindowTask_774219, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOpsItem_774232 = ref object of OpenApiRestCall_772597
proc url_GetOpsItem_774234(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetOpsItem_774233(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774235 = header.getOrDefault("X-Amz-Date")
  valid_774235 = validateParameter(valid_774235, JString, required = false,
                                 default = nil)
  if valid_774235 != nil:
    section.add "X-Amz-Date", valid_774235
  var valid_774236 = header.getOrDefault("X-Amz-Security-Token")
  valid_774236 = validateParameter(valid_774236, JString, required = false,
                                 default = nil)
  if valid_774236 != nil:
    section.add "X-Amz-Security-Token", valid_774236
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774237 = header.getOrDefault("X-Amz-Target")
  valid_774237 = validateParameter(valid_774237, JString, required = true,
                                 default = newJString("AmazonSSM.GetOpsItem"))
  if valid_774237 != nil:
    section.add "X-Amz-Target", valid_774237
  var valid_774238 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774238 = validateParameter(valid_774238, JString, required = false,
                                 default = nil)
  if valid_774238 != nil:
    section.add "X-Amz-Content-Sha256", valid_774238
  var valid_774239 = header.getOrDefault("X-Amz-Algorithm")
  valid_774239 = validateParameter(valid_774239, JString, required = false,
                                 default = nil)
  if valid_774239 != nil:
    section.add "X-Amz-Algorithm", valid_774239
  var valid_774240 = header.getOrDefault("X-Amz-Signature")
  valid_774240 = validateParameter(valid_774240, JString, required = false,
                                 default = nil)
  if valid_774240 != nil:
    section.add "X-Amz-Signature", valid_774240
  var valid_774241 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774241 = validateParameter(valid_774241, JString, required = false,
                                 default = nil)
  if valid_774241 != nil:
    section.add "X-Amz-SignedHeaders", valid_774241
  var valid_774242 = header.getOrDefault("X-Amz-Credential")
  valid_774242 = validateParameter(valid_774242, JString, required = false,
                                 default = nil)
  if valid_774242 != nil:
    section.add "X-Amz-Credential", valid_774242
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774244: Call_GetOpsItem_774232; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Get information about an OpsItem by using the ID. You must have permission in AWS Identity and Access Management (IAM) to view information about an OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ## 
  let valid = call_774244.validator(path, query, header, formData, body)
  let scheme = call_774244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774244.url(scheme.get, call_774244.host, call_774244.base,
                         call_774244.route, valid.getOrDefault("path"))
  result = hook(call_774244, url, valid)

proc call*(call_774245: Call_GetOpsItem_774232; body: JsonNode): Recallable =
  ## getOpsItem
  ## <p>Get information about an OpsItem by using the ID. You must have permission in AWS Identity and Access Management (IAM) to view information about an OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ##   body: JObject (required)
  var body_774246 = newJObject()
  if body != nil:
    body_774246 = body
  result = call_774245.call(nil, nil, nil, nil, body_774246)

var getOpsItem* = Call_GetOpsItem_774232(name: "getOpsItem",
                                      meth: HttpMethod.HttpPost,
                                      host: "ssm.amazonaws.com", route: "/#X-Amz-Target=AmazonSSM.GetOpsItem",
                                      validator: validate_GetOpsItem_774233,
                                      base: "/", url: url_GetOpsItem_774234,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOpsSummary_774247 = ref object of OpenApiRestCall_772597
proc url_GetOpsSummary_774249(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetOpsSummary_774248(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774250 = header.getOrDefault("X-Amz-Date")
  valid_774250 = validateParameter(valid_774250, JString, required = false,
                                 default = nil)
  if valid_774250 != nil:
    section.add "X-Amz-Date", valid_774250
  var valid_774251 = header.getOrDefault("X-Amz-Security-Token")
  valid_774251 = validateParameter(valid_774251, JString, required = false,
                                 default = nil)
  if valid_774251 != nil:
    section.add "X-Amz-Security-Token", valid_774251
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774252 = header.getOrDefault("X-Amz-Target")
  valid_774252 = validateParameter(valid_774252, JString, required = true, default = newJString(
      "AmazonSSM.GetOpsSummary"))
  if valid_774252 != nil:
    section.add "X-Amz-Target", valid_774252
  var valid_774253 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774253 = validateParameter(valid_774253, JString, required = false,
                                 default = nil)
  if valid_774253 != nil:
    section.add "X-Amz-Content-Sha256", valid_774253
  var valid_774254 = header.getOrDefault("X-Amz-Algorithm")
  valid_774254 = validateParameter(valid_774254, JString, required = false,
                                 default = nil)
  if valid_774254 != nil:
    section.add "X-Amz-Algorithm", valid_774254
  var valid_774255 = header.getOrDefault("X-Amz-Signature")
  valid_774255 = validateParameter(valid_774255, JString, required = false,
                                 default = nil)
  if valid_774255 != nil:
    section.add "X-Amz-Signature", valid_774255
  var valid_774256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774256 = validateParameter(valid_774256, JString, required = false,
                                 default = nil)
  if valid_774256 != nil:
    section.add "X-Amz-SignedHeaders", valid_774256
  var valid_774257 = header.getOrDefault("X-Amz-Credential")
  valid_774257 = validateParameter(valid_774257, JString, required = false,
                                 default = nil)
  if valid_774257 != nil:
    section.add "X-Amz-Credential", valid_774257
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774259: Call_GetOpsSummary_774247; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## View a summary of OpsItems based on specified filters and aggregators.
  ## 
  let valid = call_774259.validator(path, query, header, formData, body)
  let scheme = call_774259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774259.url(scheme.get, call_774259.host, call_774259.base,
                         call_774259.route, valid.getOrDefault("path"))
  result = hook(call_774259, url, valid)

proc call*(call_774260: Call_GetOpsSummary_774247; body: JsonNode): Recallable =
  ## getOpsSummary
  ## View a summary of OpsItems based on specified filters and aggregators.
  ##   body: JObject (required)
  var body_774261 = newJObject()
  if body != nil:
    body_774261 = body
  result = call_774260.call(nil, nil, nil, nil, body_774261)

var getOpsSummary* = Call_GetOpsSummary_774247(name: "getOpsSummary",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetOpsSummary",
    validator: validate_GetOpsSummary_774248, base: "/", url: url_GetOpsSummary_774249,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetParameter_774262 = ref object of OpenApiRestCall_772597
proc url_GetParameter_774264(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetParameter_774263(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774265 = header.getOrDefault("X-Amz-Date")
  valid_774265 = validateParameter(valid_774265, JString, required = false,
                                 default = nil)
  if valid_774265 != nil:
    section.add "X-Amz-Date", valid_774265
  var valid_774266 = header.getOrDefault("X-Amz-Security-Token")
  valid_774266 = validateParameter(valid_774266, JString, required = false,
                                 default = nil)
  if valid_774266 != nil:
    section.add "X-Amz-Security-Token", valid_774266
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774267 = header.getOrDefault("X-Amz-Target")
  valid_774267 = validateParameter(valid_774267, JString, required = true,
                                 default = newJString("AmazonSSM.GetParameter"))
  if valid_774267 != nil:
    section.add "X-Amz-Target", valid_774267
  var valid_774268 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774268 = validateParameter(valid_774268, JString, required = false,
                                 default = nil)
  if valid_774268 != nil:
    section.add "X-Amz-Content-Sha256", valid_774268
  var valid_774269 = header.getOrDefault("X-Amz-Algorithm")
  valid_774269 = validateParameter(valid_774269, JString, required = false,
                                 default = nil)
  if valid_774269 != nil:
    section.add "X-Amz-Algorithm", valid_774269
  var valid_774270 = header.getOrDefault("X-Amz-Signature")
  valid_774270 = validateParameter(valid_774270, JString, required = false,
                                 default = nil)
  if valid_774270 != nil:
    section.add "X-Amz-Signature", valid_774270
  var valid_774271 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774271 = validateParameter(valid_774271, JString, required = false,
                                 default = nil)
  if valid_774271 != nil:
    section.add "X-Amz-SignedHeaders", valid_774271
  var valid_774272 = header.getOrDefault("X-Amz-Credential")
  valid_774272 = validateParameter(valid_774272, JString, required = false,
                                 default = nil)
  if valid_774272 != nil:
    section.add "X-Amz-Credential", valid_774272
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774274: Call_GetParameter_774262; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get information about a parameter by using the parameter name. Don't confuse this API action with the <a>GetParameters</a> API action.
  ## 
  let valid = call_774274.validator(path, query, header, formData, body)
  let scheme = call_774274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774274.url(scheme.get, call_774274.host, call_774274.base,
                         call_774274.route, valid.getOrDefault("path"))
  result = hook(call_774274, url, valid)

proc call*(call_774275: Call_GetParameter_774262; body: JsonNode): Recallable =
  ## getParameter
  ## Get information about a parameter by using the parameter name. Don't confuse this API action with the <a>GetParameters</a> API action.
  ##   body: JObject (required)
  var body_774276 = newJObject()
  if body != nil:
    body_774276 = body
  result = call_774275.call(nil, nil, nil, nil, body_774276)

var getParameter* = Call_GetParameter_774262(name: "getParameter",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetParameter",
    validator: validate_GetParameter_774263, base: "/", url: url_GetParameter_774264,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetParameterHistory_774277 = ref object of OpenApiRestCall_772597
proc url_GetParameterHistory_774279(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetParameterHistory_774278(path: JsonNode; query: JsonNode;
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
  var valid_774280 = query.getOrDefault("NextToken")
  valid_774280 = validateParameter(valid_774280, JString, required = false,
                                 default = nil)
  if valid_774280 != nil:
    section.add "NextToken", valid_774280
  var valid_774281 = query.getOrDefault("MaxResults")
  valid_774281 = validateParameter(valid_774281, JString, required = false,
                                 default = nil)
  if valid_774281 != nil:
    section.add "MaxResults", valid_774281
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
  var valid_774282 = header.getOrDefault("X-Amz-Date")
  valid_774282 = validateParameter(valid_774282, JString, required = false,
                                 default = nil)
  if valid_774282 != nil:
    section.add "X-Amz-Date", valid_774282
  var valid_774283 = header.getOrDefault("X-Amz-Security-Token")
  valid_774283 = validateParameter(valid_774283, JString, required = false,
                                 default = nil)
  if valid_774283 != nil:
    section.add "X-Amz-Security-Token", valid_774283
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774284 = header.getOrDefault("X-Amz-Target")
  valid_774284 = validateParameter(valid_774284, JString, required = true, default = newJString(
      "AmazonSSM.GetParameterHistory"))
  if valid_774284 != nil:
    section.add "X-Amz-Target", valid_774284
  var valid_774285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774285 = validateParameter(valid_774285, JString, required = false,
                                 default = nil)
  if valid_774285 != nil:
    section.add "X-Amz-Content-Sha256", valid_774285
  var valid_774286 = header.getOrDefault("X-Amz-Algorithm")
  valid_774286 = validateParameter(valid_774286, JString, required = false,
                                 default = nil)
  if valid_774286 != nil:
    section.add "X-Amz-Algorithm", valid_774286
  var valid_774287 = header.getOrDefault("X-Amz-Signature")
  valid_774287 = validateParameter(valid_774287, JString, required = false,
                                 default = nil)
  if valid_774287 != nil:
    section.add "X-Amz-Signature", valid_774287
  var valid_774288 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774288 = validateParameter(valid_774288, JString, required = false,
                                 default = nil)
  if valid_774288 != nil:
    section.add "X-Amz-SignedHeaders", valid_774288
  var valid_774289 = header.getOrDefault("X-Amz-Credential")
  valid_774289 = validateParameter(valid_774289, JString, required = false,
                                 default = nil)
  if valid_774289 != nil:
    section.add "X-Amz-Credential", valid_774289
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774291: Call_GetParameterHistory_774277; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Query a list of all parameters used by the AWS account.
  ## 
  let valid = call_774291.validator(path, query, header, formData, body)
  let scheme = call_774291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774291.url(scheme.get, call_774291.host, call_774291.base,
                         call_774291.route, valid.getOrDefault("path"))
  result = hook(call_774291, url, valid)

proc call*(call_774292: Call_GetParameterHistory_774277; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getParameterHistory
  ## Query a list of all parameters used by the AWS account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_774293 = newJObject()
  var body_774294 = newJObject()
  add(query_774293, "NextToken", newJString(NextToken))
  if body != nil:
    body_774294 = body
  add(query_774293, "MaxResults", newJString(MaxResults))
  result = call_774292.call(nil, query_774293, nil, nil, body_774294)

var getParameterHistory* = Call_GetParameterHistory_774277(
    name: "getParameterHistory", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetParameterHistory",
    validator: validate_GetParameterHistory_774278, base: "/",
    url: url_GetParameterHistory_774279, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetParameters_774295 = ref object of OpenApiRestCall_772597
proc url_GetParameters_774297(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetParameters_774296(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774298 = header.getOrDefault("X-Amz-Date")
  valid_774298 = validateParameter(valid_774298, JString, required = false,
                                 default = nil)
  if valid_774298 != nil:
    section.add "X-Amz-Date", valid_774298
  var valid_774299 = header.getOrDefault("X-Amz-Security-Token")
  valid_774299 = validateParameter(valid_774299, JString, required = false,
                                 default = nil)
  if valid_774299 != nil:
    section.add "X-Amz-Security-Token", valid_774299
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774300 = header.getOrDefault("X-Amz-Target")
  valid_774300 = validateParameter(valid_774300, JString, required = true, default = newJString(
      "AmazonSSM.GetParameters"))
  if valid_774300 != nil:
    section.add "X-Amz-Target", valid_774300
  var valid_774301 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774301 = validateParameter(valid_774301, JString, required = false,
                                 default = nil)
  if valid_774301 != nil:
    section.add "X-Amz-Content-Sha256", valid_774301
  var valid_774302 = header.getOrDefault("X-Amz-Algorithm")
  valid_774302 = validateParameter(valid_774302, JString, required = false,
                                 default = nil)
  if valid_774302 != nil:
    section.add "X-Amz-Algorithm", valid_774302
  var valid_774303 = header.getOrDefault("X-Amz-Signature")
  valid_774303 = validateParameter(valid_774303, JString, required = false,
                                 default = nil)
  if valid_774303 != nil:
    section.add "X-Amz-Signature", valid_774303
  var valid_774304 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774304 = validateParameter(valid_774304, JString, required = false,
                                 default = nil)
  if valid_774304 != nil:
    section.add "X-Amz-SignedHeaders", valid_774304
  var valid_774305 = header.getOrDefault("X-Amz-Credential")
  valid_774305 = validateParameter(valid_774305, JString, required = false,
                                 default = nil)
  if valid_774305 != nil:
    section.add "X-Amz-Credential", valid_774305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774307: Call_GetParameters_774295; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get details of a parameter. Don't confuse this API action with the <a>GetParameter</a> API action.
  ## 
  let valid = call_774307.validator(path, query, header, formData, body)
  let scheme = call_774307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774307.url(scheme.get, call_774307.host, call_774307.base,
                         call_774307.route, valid.getOrDefault("path"))
  result = hook(call_774307, url, valid)

proc call*(call_774308: Call_GetParameters_774295; body: JsonNode): Recallable =
  ## getParameters
  ## Get details of a parameter. Don't confuse this API action with the <a>GetParameter</a> API action.
  ##   body: JObject (required)
  var body_774309 = newJObject()
  if body != nil:
    body_774309 = body
  result = call_774308.call(nil, nil, nil, nil, body_774309)

var getParameters* = Call_GetParameters_774295(name: "getParameters",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetParameters",
    validator: validate_GetParameters_774296, base: "/", url: url_GetParameters_774297,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetParametersByPath_774310 = ref object of OpenApiRestCall_772597
proc url_GetParametersByPath_774312(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetParametersByPath_774311(path: JsonNode; query: JsonNode;
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
  var valid_774313 = query.getOrDefault("NextToken")
  valid_774313 = validateParameter(valid_774313, JString, required = false,
                                 default = nil)
  if valid_774313 != nil:
    section.add "NextToken", valid_774313
  var valid_774314 = query.getOrDefault("MaxResults")
  valid_774314 = validateParameter(valid_774314, JString, required = false,
                                 default = nil)
  if valid_774314 != nil:
    section.add "MaxResults", valid_774314
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
  var valid_774315 = header.getOrDefault("X-Amz-Date")
  valid_774315 = validateParameter(valid_774315, JString, required = false,
                                 default = nil)
  if valid_774315 != nil:
    section.add "X-Amz-Date", valid_774315
  var valid_774316 = header.getOrDefault("X-Amz-Security-Token")
  valid_774316 = validateParameter(valid_774316, JString, required = false,
                                 default = nil)
  if valid_774316 != nil:
    section.add "X-Amz-Security-Token", valid_774316
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774317 = header.getOrDefault("X-Amz-Target")
  valid_774317 = validateParameter(valid_774317, JString, required = true, default = newJString(
      "AmazonSSM.GetParametersByPath"))
  if valid_774317 != nil:
    section.add "X-Amz-Target", valid_774317
  var valid_774318 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774318 = validateParameter(valid_774318, JString, required = false,
                                 default = nil)
  if valid_774318 != nil:
    section.add "X-Amz-Content-Sha256", valid_774318
  var valid_774319 = header.getOrDefault("X-Amz-Algorithm")
  valid_774319 = validateParameter(valid_774319, JString, required = false,
                                 default = nil)
  if valid_774319 != nil:
    section.add "X-Amz-Algorithm", valid_774319
  var valid_774320 = header.getOrDefault("X-Amz-Signature")
  valid_774320 = validateParameter(valid_774320, JString, required = false,
                                 default = nil)
  if valid_774320 != nil:
    section.add "X-Amz-Signature", valid_774320
  var valid_774321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774321 = validateParameter(valid_774321, JString, required = false,
                                 default = nil)
  if valid_774321 != nil:
    section.add "X-Amz-SignedHeaders", valid_774321
  var valid_774322 = header.getOrDefault("X-Amz-Credential")
  valid_774322 = validateParameter(valid_774322, JString, required = false,
                                 default = nil)
  if valid_774322 != nil:
    section.add "X-Amz-Credential", valid_774322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774324: Call_GetParametersByPath_774310; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieve parameters in a specific hierarchy. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-paramstore-working.html">Working with Systems Manager Parameters</a> in the <i>AWS Systems Manager User Guide</i>. </p> <p>Request results are returned on a best-effort basis. If you specify <code>MaxResults</code> in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of <code>MaxResults</code>. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a <code>NextToken</code>. You can specify the <code>NextToken</code> in a subsequent call to get the next set of results.</p> <note> <p>This API action doesn't support filtering by tags. </p> </note>
  ## 
  let valid = call_774324.validator(path, query, header, formData, body)
  let scheme = call_774324.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774324.url(scheme.get, call_774324.host, call_774324.base,
                         call_774324.route, valid.getOrDefault("path"))
  result = hook(call_774324, url, valid)

proc call*(call_774325: Call_GetParametersByPath_774310; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getParametersByPath
  ## <p>Retrieve parameters in a specific hierarchy. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-paramstore-working.html">Working with Systems Manager Parameters</a> in the <i>AWS Systems Manager User Guide</i>. </p> <p>Request results are returned on a best-effort basis. If you specify <code>MaxResults</code> in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of <code>MaxResults</code>. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a <code>NextToken</code>. You can specify the <code>NextToken</code> in a subsequent call to get the next set of results.</p> <note> <p>This API action doesn't support filtering by tags. </p> </note>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_774326 = newJObject()
  var body_774327 = newJObject()
  add(query_774326, "NextToken", newJString(NextToken))
  if body != nil:
    body_774327 = body
  add(query_774326, "MaxResults", newJString(MaxResults))
  result = call_774325.call(nil, query_774326, nil, nil, body_774327)

var getParametersByPath* = Call_GetParametersByPath_774310(
    name: "getParametersByPath", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetParametersByPath",
    validator: validate_GetParametersByPath_774311, base: "/",
    url: url_GetParametersByPath_774312, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPatchBaseline_774328 = ref object of OpenApiRestCall_772597
proc url_GetPatchBaseline_774330(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetPatchBaseline_774329(path: JsonNode; query: JsonNode;
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
  var valid_774331 = header.getOrDefault("X-Amz-Date")
  valid_774331 = validateParameter(valid_774331, JString, required = false,
                                 default = nil)
  if valid_774331 != nil:
    section.add "X-Amz-Date", valid_774331
  var valid_774332 = header.getOrDefault("X-Amz-Security-Token")
  valid_774332 = validateParameter(valid_774332, JString, required = false,
                                 default = nil)
  if valid_774332 != nil:
    section.add "X-Amz-Security-Token", valid_774332
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774333 = header.getOrDefault("X-Amz-Target")
  valid_774333 = validateParameter(valid_774333, JString, required = true, default = newJString(
      "AmazonSSM.GetPatchBaseline"))
  if valid_774333 != nil:
    section.add "X-Amz-Target", valid_774333
  var valid_774334 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774334 = validateParameter(valid_774334, JString, required = false,
                                 default = nil)
  if valid_774334 != nil:
    section.add "X-Amz-Content-Sha256", valid_774334
  var valid_774335 = header.getOrDefault("X-Amz-Algorithm")
  valid_774335 = validateParameter(valid_774335, JString, required = false,
                                 default = nil)
  if valid_774335 != nil:
    section.add "X-Amz-Algorithm", valid_774335
  var valid_774336 = header.getOrDefault("X-Amz-Signature")
  valid_774336 = validateParameter(valid_774336, JString, required = false,
                                 default = nil)
  if valid_774336 != nil:
    section.add "X-Amz-Signature", valid_774336
  var valid_774337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774337 = validateParameter(valid_774337, JString, required = false,
                                 default = nil)
  if valid_774337 != nil:
    section.add "X-Amz-SignedHeaders", valid_774337
  var valid_774338 = header.getOrDefault("X-Amz-Credential")
  valid_774338 = validateParameter(valid_774338, JString, required = false,
                                 default = nil)
  if valid_774338 != nil:
    section.add "X-Amz-Credential", valid_774338
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774340: Call_GetPatchBaseline_774328; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a patch baseline.
  ## 
  let valid = call_774340.validator(path, query, header, formData, body)
  let scheme = call_774340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774340.url(scheme.get, call_774340.host, call_774340.base,
                         call_774340.route, valid.getOrDefault("path"))
  result = hook(call_774340, url, valid)

proc call*(call_774341: Call_GetPatchBaseline_774328; body: JsonNode): Recallable =
  ## getPatchBaseline
  ## Retrieves information about a patch baseline.
  ##   body: JObject (required)
  var body_774342 = newJObject()
  if body != nil:
    body_774342 = body
  result = call_774341.call(nil, nil, nil, nil, body_774342)

var getPatchBaseline* = Call_GetPatchBaseline_774328(name: "getPatchBaseline",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetPatchBaseline",
    validator: validate_GetPatchBaseline_774329, base: "/",
    url: url_GetPatchBaseline_774330, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPatchBaselineForPatchGroup_774343 = ref object of OpenApiRestCall_772597
proc url_GetPatchBaselineForPatchGroup_774345(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetPatchBaselineForPatchGroup_774344(path: JsonNode; query: JsonNode;
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
  var valid_774346 = header.getOrDefault("X-Amz-Date")
  valid_774346 = validateParameter(valid_774346, JString, required = false,
                                 default = nil)
  if valid_774346 != nil:
    section.add "X-Amz-Date", valid_774346
  var valid_774347 = header.getOrDefault("X-Amz-Security-Token")
  valid_774347 = validateParameter(valid_774347, JString, required = false,
                                 default = nil)
  if valid_774347 != nil:
    section.add "X-Amz-Security-Token", valid_774347
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774348 = header.getOrDefault("X-Amz-Target")
  valid_774348 = validateParameter(valid_774348, JString, required = true, default = newJString(
      "AmazonSSM.GetPatchBaselineForPatchGroup"))
  if valid_774348 != nil:
    section.add "X-Amz-Target", valid_774348
  var valid_774349 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774349 = validateParameter(valid_774349, JString, required = false,
                                 default = nil)
  if valid_774349 != nil:
    section.add "X-Amz-Content-Sha256", valid_774349
  var valid_774350 = header.getOrDefault("X-Amz-Algorithm")
  valid_774350 = validateParameter(valid_774350, JString, required = false,
                                 default = nil)
  if valid_774350 != nil:
    section.add "X-Amz-Algorithm", valid_774350
  var valid_774351 = header.getOrDefault("X-Amz-Signature")
  valid_774351 = validateParameter(valid_774351, JString, required = false,
                                 default = nil)
  if valid_774351 != nil:
    section.add "X-Amz-Signature", valid_774351
  var valid_774352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774352 = validateParameter(valid_774352, JString, required = false,
                                 default = nil)
  if valid_774352 != nil:
    section.add "X-Amz-SignedHeaders", valid_774352
  var valid_774353 = header.getOrDefault("X-Amz-Credential")
  valid_774353 = validateParameter(valid_774353, JString, required = false,
                                 default = nil)
  if valid_774353 != nil:
    section.add "X-Amz-Credential", valid_774353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774355: Call_GetPatchBaselineForPatchGroup_774343; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the patch baseline that should be used for the specified patch group.
  ## 
  let valid = call_774355.validator(path, query, header, formData, body)
  let scheme = call_774355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774355.url(scheme.get, call_774355.host, call_774355.base,
                         call_774355.route, valid.getOrDefault("path"))
  result = hook(call_774355, url, valid)

proc call*(call_774356: Call_GetPatchBaselineForPatchGroup_774343; body: JsonNode): Recallable =
  ## getPatchBaselineForPatchGroup
  ## Retrieves the patch baseline that should be used for the specified patch group.
  ##   body: JObject (required)
  var body_774357 = newJObject()
  if body != nil:
    body_774357 = body
  result = call_774356.call(nil, nil, nil, nil, body_774357)

var getPatchBaselineForPatchGroup* = Call_GetPatchBaselineForPatchGroup_774343(
    name: "getPatchBaselineForPatchGroup", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetPatchBaselineForPatchGroup",
    validator: validate_GetPatchBaselineForPatchGroup_774344, base: "/",
    url: url_GetPatchBaselineForPatchGroup_774345,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetServiceSetting_774358 = ref object of OpenApiRestCall_772597
proc url_GetServiceSetting_774360(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetServiceSetting_774359(path: JsonNode; query: JsonNode;
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
  var valid_774361 = header.getOrDefault("X-Amz-Date")
  valid_774361 = validateParameter(valid_774361, JString, required = false,
                                 default = nil)
  if valid_774361 != nil:
    section.add "X-Amz-Date", valid_774361
  var valid_774362 = header.getOrDefault("X-Amz-Security-Token")
  valid_774362 = validateParameter(valid_774362, JString, required = false,
                                 default = nil)
  if valid_774362 != nil:
    section.add "X-Amz-Security-Token", valid_774362
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774363 = header.getOrDefault("X-Amz-Target")
  valid_774363 = validateParameter(valid_774363, JString, required = true, default = newJString(
      "AmazonSSM.GetServiceSetting"))
  if valid_774363 != nil:
    section.add "X-Amz-Target", valid_774363
  var valid_774364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774364 = validateParameter(valid_774364, JString, required = false,
                                 default = nil)
  if valid_774364 != nil:
    section.add "X-Amz-Content-Sha256", valid_774364
  var valid_774365 = header.getOrDefault("X-Amz-Algorithm")
  valid_774365 = validateParameter(valid_774365, JString, required = false,
                                 default = nil)
  if valid_774365 != nil:
    section.add "X-Amz-Algorithm", valid_774365
  var valid_774366 = header.getOrDefault("X-Amz-Signature")
  valid_774366 = validateParameter(valid_774366, JString, required = false,
                                 default = nil)
  if valid_774366 != nil:
    section.add "X-Amz-Signature", valid_774366
  var valid_774367 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774367 = validateParameter(valid_774367, JString, required = false,
                                 default = nil)
  if valid_774367 != nil:
    section.add "X-Amz-SignedHeaders", valid_774367
  var valid_774368 = header.getOrDefault("X-Amz-Credential")
  valid_774368 = validateParameter(valid_774368, JString, required = false,
                                 default = nil)
  if valid_774368 != nil:
    section.add "X-Amz-Credential", valid_774368
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774370: Call_GetServiceSetting_774358; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>UpdateServiceSetting</a> API action to change the default setting. Or use the <a>ResetServiceSetting</a> to change the value back to the original value defined by the AWS service team.</p> <p>Query the current service setting for the account. </p>
  ## 
  let valid = call_774370.validator(path, query, header, formData, body)
  let scheme = call_774370.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774370.url(scheme.get, call_774370.host, call_774370.base,
                         call_774370.route, valid.getOrDefault("path"))
  result = hook(call_774370, url, valid)

proc call*(call_774371: Call_GetServiceSetting_774358; body: JsonNode): Recallable =
  ## getServiceSetting
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>UpdateServiceSetting</a> API action to change the default setting. Or use the <a>ResetServiceSetting</a> to change the value back to the original value defined by the AWS service team.</p> <p>Query the current service setting for the account. </p>
  ##   body: JObject (required)
  var body_774372 = newJObject()
  if body != nil:
    body_774372 = body
  result = call_774371.call(nil, nil, nil, nil, body_774372)

var getServiceSetting* = Call_GetServiceSetting_774358(name: "getServiceSetting",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetServiceSetting",
    validator: validate_GetServiceSetting_774359, base: "/",
    url: url_GetServiceSetting_774360, schemes: {Scheme.Https, Scheme.Http})
type
  Call_LabelParameterVersion_774373 = ref object of OpenApiRestCall_772597
proc url_LabelParameterVersion_774375(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_LabelParameterVersion_774374(path: JsonNode; query: JsonNode;
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
  var valid_774376 = header.getOrDefault("X-Amz-Date")
  valid_774376 = validateParameter(valid_774376, JString, required = false,
                                 default = nil)
  if valid_774376 != nil:
    section.add "X-Amz-Date", valid_774376
  var valid_774377 = header.getOrDefault("X-Amz-Security-Token")
  valid_774377 = validateParameter(valid_774377, JString, required = false,
                                 default = nil)
  if valid_774377 != nil:
    section.add "X-Amz-Security-Token", valid_774377
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774378 = header.getOrDefault("X-Amz-Target")
  valid_774378 = validateParameter(valid_774378, JString, required = true, default = newJString(
      "AmazonSSM.LabelParameterVersion"))
  if valid_774378 != nil:
    section.add "X-Amz-Target", valid_774378
  var valid_774379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774379 = validateParameter(valid_774379, JString, required = false,
                                 default = nil)
  if valid_774379 != nil:
    section.add "X-Amz-Content-Sha256", valid_774379
  var valid_774380 = header.getOrDefault("X-Amz-Algorithm")
  valid_774380 = validateParameter(valid_774380, JString, required = false,
                                 default = nil)
  if valid_774380 != nil:
    section.add "X-Amz-Algorithm", valid_774380
  var valid_774381 = header.getOrDefault("X-Amz-Signature")
  valid_774381 = validateParameter(valid_774381, JString, required = false,
                                 default = nil)
  if valid_774381 != nil:
    section.add "X-Amz-Signature", valid_774381
  var valid_774382 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774382 = validateParameter(valid_774382, JString, required = false,
                                 default = nil)
  if valid_774382 != nil:
    section.add "X-Amz-SignedHeaders", valid_774382
  var valid_774383 = header.getOrDefault("X-Amz-Credential")
  valid_774383 = validateParameter(valid_774383, JString, required = false,
                                 default = nil)
  if valid_774383 != nil:
    section.add "X-Amz-Credential", valid_774383
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774385: Call_LabelParameterVersion_774373; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>A parameter label is a user-defined alias to help you manage different versions of a parameter. When you modify a parameter, Systems Manager automatically saves a new version and increments the version number by one. A label can help you remember the purpose of a parameter when there are multiple versions. </p> <p>Parameter labels have the following requirements and restrictions.</p> <ul> <li> <p>A version of a parameter can have a maximum of 10 labels.</p> </li> <li> <p>You can't attach the same label to different versions of the same parameter. For example, if version 1 has the label Production, then you can't attach Production to version 2.</p> </li> <li> <p>You can move a label from one version of a parameter to another.</p> </li> <li> <p>You can't create a label when you create a new parameter. You must attach a label to a specific version of a parameter.</p> </li> <li> <p>You can't delete a parameter label. If you no longer want to use a parameter label, then you must move it to a different version of a parameter.</p> </li> <li> <p>A label can have a maximum of 100 characters.</p> </li> <li> <p>Labels can contain letters (case sensitive), numbers, periods (.), hyphens (-), or underscores (_).</p> </li> <li> <p>Labels can't begin with a number, "aws," or "ssm" (not case sensitive). If a label fails to meet these requirements, then the label is not associated with a parameter and the system displays it in the list of InvalidLabels.</p> </li> </ul>
  ## 
  let valid = call_774385.validator(path, query, header, formData, body)
  let scheme = call_774385.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774385.url(scheme.get, call_774385.host, call_774385.base,
                         call_774385.route, valid.getOrDefault("path"))
  result = hook(call_774385, url, valid)

proc call*(call_774386: Call_LabelParameterVersion_774373; body: JsonNode): Recallable =
  ## labelParameterVersion
  ## <p>A parameter label is a user-defined alias to help you manage different versions of a parameter. When you modify a parameter, Systems Manager automatically saves a new version and increments the version number by one. A label can help you remember the purpose of a parameter when there are multiple versions. </p> <p>Parameter labels have the following requirements and restrictions.</p> <ul> <li> <p>A version of a parameter can have a maximum of 10 labels.</p> </li> <li> <p>You can't attach the same label to different versions of the same parameter. For example, if version 1 has the label Production, then you can't attach Production to version 2.</p> </li> <li> <p>You can move a label from one version of a parameter to another.</p> </li> <li> <p>You can't create a label when you create a new parameter. You must attach a label to a specific version of a parameter.</p> </li> <li> <p>You can't delete a parameter label. If you no longer want to use a parameter label, then you must move it to a different version of a parameter.</p> </li> <li> <p>A label can have a maximum of 100 characters.</p> </li> <li> <p>Labels can contain letters (case sensitive), numbers, periods (.), hyphens (-), or underscores (_).</p> </li> <li> <p>Labels can't begin with a number, "aws," or "ssm" (not case sensitive). If a label fails to meet these requirements, then the label is not associated with a parameter and the system displays it in the list of InvalidLabels.</p> </li> </ul>
  ##   body: JObject (required)
  var body_774387 = newJObject()
  if body != nil:
    body_774387 = body
  result = call_774386.call(nil, nil, nil, nil, body_774387)

var labelParameterVersion* = Call_LabelParameterVersion_774373(
    name: "labelParameterVersion", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.LabelParameterVersion",
    validator: validate_LabelParameterVersion_774374, base: "/",
    url: url_LabelParameterVersion_774375, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssociationVersions_774388 = ref object of OpenApiRestCall_772597
proc url_ListAssociationVersions_774390(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListAssociationVersions_774389(path: JsonNode; query: JsonNode;
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
  var valid_774391 = header.getOrDefault("X-Amz-Date")
  valid_774391 = validateParameter(valid_774391, JString, required = false,
                                 default = nil)
  if valid_774391 != nil:
    section.add "X-Amz-Date", valid_774391
  var valid_774392 = header.getOrDefault("X-Amz-Security-Token")
  valid_774392 = validateParameter(valid_774392, JString, required = false,
                                 default = nil)
  if valid_774392 != nil:
    section.add "X-Amz-Security-Token", valid_774392
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774393 = header.getOrDefault("X-Amz-Target")
  valid_774393 = validateParameter(valid_774393, JString, required = true, default = newJString(
      "AmazonSSM.ListAssociationVersions"))
  if valid_774393 != nil:
    section.add "X-Amz-Target", valid_774393
  var valid_774394 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774394 = validateParameter(valid_774394, JString, required = false,
                                 default = nil)
  if valid_774394 != nil:
    section.add "X-Amz-Content-Sha256", valid_774394
  var valid_774395 = header.getOrDefault("X-Amz-Algorithm")
  valid_774395 = validateParameter(valid_774395, JString, required = false,
                                 default = nil)
  if valid_774395 != nil:
    section.add "X-Amz-Algorithm", valid_774395
  var valid_774396 = header.getOrDefault("X-Amz-Signature")
  valid_774396 = validateParameter(valid_774396, JString, required = false,
                                 default = nil)
  if valid_774396 != nil:
    section.add "X-Amz-Signature", valid_774396
  var valid_774397 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774397 = validateParameter(valid_774397, JString, required = false,
                                 default = nil)
  if valid_774397 != nil:
    section.add "X-Amz-SignedHeaders", valid_774397
  var valid_774398 = header.getOrDefault("X-Amz-Credential")
  valid_774398 = validateParameter(valid_774398, JString, required = false,
                                 default = nil)
  if valid_774398 != nil:
    section.add "X-Amz-Credential", valid_774398
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774400: Call_ListAssociationVersions_774388; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves all versions of an association for a specific association ID.
  ## 
  let valid = call_774400.validator(path, query, header, formData, body)
  let scheme = call_774400.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774400.url(scheme.get, call_774400.host, call_774400.base,
                         call_774400.route, valid.getOrDefault("path"))
  result = hook(call_774400, url, valid)

proc call*(call_774401: Call_ListAssociationVersions_774388; body: JsonNode): Recallable =
  ## listAssociationVersions
  ## Retrieves all versions of an association for a specific association ID.
  ##   body: JObject (required)
  var body_774402 = newJObject()
  if body != nil:
    body_774402 = body
  result = call_774401.call(nil, nil, nil, nil, body_774402)

var listAssociationVersions* = Call_ListAssociationVersions_774388(
    name: "listAssociationVersions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListAssociationVersions",
    validator: validate_ListAssociationVersions_774389, base: "/",
    url: url_ListAssociationVersions_774390, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssociations_774403 = ref object of OpenApiRestCall_772597
proc url_ListAssociations_774405(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListAssociations_774404(path: JsonNode; query: JsonNode;
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
  var valid_774406 = query.getOrDefault("NextToken")
  valid_774406 = validateParameter(valid_774406, JString, required = false,
                                 default = nil)
  if valid_774406 != nil:
    section.add "NextToken", valid_774406
  var valid_774407 = query.getOrDefault("MaxResults")
  valid_774407 = validateParameter(valid_774407, JString, required = false,
                                 default = nil)
  if valid_774407 != nil:
    section.add "MaxResults", valid_774407
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
  var valid_774408 = header.getOrDefault("X-Amz-Date")
  valid_774408 = validateParameter(valid_774408, JString, required = false,
                                 default = nil)
  if valid_774408 != nil:
    section.add "X-Amz-Date", valid_774408
  var valid_774409 = header.getOrDefault("X-Amz-Security-Token")
  valid_774409 = validateParameter(valid_774409, JString, required = false,
                                 default = nil)
  if valid_774409 != nil:
    section.add "X-Amz-Security-Token", valid_774409
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774410 = header.getOrDefault("X-Amz-Target")
  valid_774410 = validateParameter(valid_774410, JString, required = true, default = newJString(
      "AmazonSSM.ListAssociations"))
  if valid_774410 != nil:
    section.add "X-Amz-Target", valid_774410
  var valid_774411 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774411 = validateParameter(valid_774411, JString, required = false,
                                 default = nil)
  if valid_774411 != nil:
    section.add "X-Amz-Content-Sha256", valid_774411
  var valid_774412 = header.getOrDefault("X-Amz-Algorithm")
  valid_774412 = validateParameter(valid_774412, JString, required = false,
                                 default = nil)
  if valid_774412 != nil:
    section.add "X-Amz-Algorithm", valid_774412
  var valid_774413 = header.getOrDefault("X-Amz-Signature")
  valid_774413 = validateParameter(valid_774413, JString, required = false,
                                 default = nil)
  if valid_774413 != nil:
    section.add "X-Amz-Signature", valid_774413
  var valid_774414 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774414 = validateParameter(valid_774414, JString, required = false,
                                 default = nil)
  if valid_774414 != nil:
    section.add "X-Amz-SignedHeaders", valid_774414
  var valid_774415 = header.getOrDefault("X-Amz-Credential")
  valid_774415 = validateParameter(valid_774415, JString, required = false,
                                 default = nil)
  if valid_774415 != nil:
    section.add "X-Amz-Credential", valid_774415
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774417: Call_ListAssociations_774403; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the associations for the specified Systems Manager document or instance.
  ## 
  let valid = call_774417.validator(path, query, header, formData, body)
  let scheme = call_774417.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774417.url(scheme.get, call_774417.host, call_774417.base,
                         call_774417.route, valid.getOrDefault("path"))
  result = hook(call_774417, url, valid)

proc call*(call_774418: Call_ListAssociations_774403; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listAssociations
  ## Lists the associations for the specified Systems Manager document or instance.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_774419 = newJObject()
  var body_774420 = newJObject()
  add(query_774419, "NextToken", newJString(NextToken))
  if body != nil:
    body_774420 = body
  add(query_774419, "MaxResults", newJString(MaxResults))
  result = call_774418.call(nil, query_774419, nil, nil, body_774420)

var listAssociations* = Call_ListAssociations_774403(name: "listAssociations",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListAssociations",
    validator: validate_ListAssociations_774404, base: "/",
    url: url_ListAssociations_774405, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCommandInvocations_774421 = ref object of OpenApiRestCall_772597
proc url_ListCommandInvocations_774423(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListCommandInvocations_774422(path: JsonNode; query: JsonNode;
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
  var valid_774424 = query.getOrDefault("NextToken")
  valid_774424 = validateParameter(valid_774424, JString, required = false,
                                 default = nil)
  if valid_774424 != nil:
    section.add "NextToken", valid_774424
  var valid_774425 = query.getOrDefault("MaxResults")
  valid_774425 = validateParameter(valid_774425, JString, required = false,
                                 default = nil)
  if valid_774425 != nil:
    section.add "MaxResults", valid_774425
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
  var valid_774426 = header.getOrDefault("X-Amz-Date")
  valid_774426 = validateParameter(valid_774426, JString, required = false,
                                 default = nil)
  if valid_774426 != nil:
    section.add "X-Amz-Date", valid_774426
  var valid_774427 = header.getOrDefault("X-Amz-Security-Token")
  valid_774427 = validateParameter(valid_774427, JString, required = false,
                                 default = nil)
  if valid_774427 != nil:
    section.add "X-Amz-Security-Token", valid_774427
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774428 = header.getOrDefault("X-Amz-Target")
  valid_774428 = validateParameter(valid_774428, JString, required = true, default = newJString(
      "AmazonSSM.ListCommandInvocations"))
  if valid_774428 != nil:
    section.add "X-Amz-Target", valid_774428
  var valid_774429 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774429 = validateParameter(valid_774429, JString, required = false,
                                 default = nil)
  if valid_774429 != nil:
    section.add "X-Amz-Content-Sha256", valid_774429
  var valid_774430 = header.getOrDefault("X-Amz-Algorithm")
  valid_774430 = validateParameter(valid_774430, JString, required = false,
                                 default = nil)
  if valid_774430 != nil:
    section.add "X-Amz-Algorithm", valid_774430
  var valid_774431 = header.getOrDefault("X-Amz-Signature")
  valid_774431 = validateParameter(valid_774431, JString, required = false,
                                 default = nil)
  if valid_774431 != nil:
    section.add "X-Amz-Signature", valid_774431
  var valid_774432 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774432 = validateParameter(valid_774432, JString, required = false,
                                 default = nil)
  if valid_774432 != nil:
    section.add "X-Amz-SignedHeaders", valid_774432
  var valid_774433 = header.getOrDefault("X-Amz-Credential")
  valid_774433 = validateParameter(valid_774433, JString, required = false,
                                 default = nil)
  if valid_774433 != nil:
    section.add "X-Amz-Credential", valid_774433
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774435: Call_ListCommandInvocations_774421; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## An invocation is copy of a command sent to a specific instance. A command can apply to one or more instances. A command invocation applies to one instance. For example, if a user runs SendCommand against three instances, then a command invocation is created for each requested instance ID. ListCommandInvocations provide status about command execution.
  ## 
  let valid = call_774435.validator(path, query, header, formData, body)
  let scheme = call_774435.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774435.url(scheme.get, call_774435.host, call_774435.base,
                         call_774435.route, valid.getOrDefault("path"))
  result = hook(call_774435, url, valid)

proc call*(call_774436: Call_ListCommandInvocations_774421; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listCommandInvocations
  ## An invocation is copy of a command sent to a specific instance. A command can apply to one or more instances. A command invocation applies to one instance. For example, if a user runs SendCommand against three instances, then a command invocation is created for each requested instance ID. ListCommandInvocations provide status about command execution.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_774437 = newJObject()
  var body_774438 = newJObject()
  add(query_774437, "NextToken", newJString(NextToken))
  if body != nil:
    body_774438 = body
  add(query_774437, "MaxResults", newJString(MaxResults))
  result = call_774436.call(nil, query_774437, nil, nil, body_774438)

var listCommandInvocations* = Call_ListCommandInvocations_774421(
    name: "listCommandInvocations", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListCommandInvocations",
    validator: validate_ListCommandInvocations_774422, base: "/",
    url: url_ListCommandInvocations_774423, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCommands_774439 = ref object of OpenApiRestCall_772597
proc url_ListCommands_774441(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListCommands_774440(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774442 = query.getOrDefault("NextToken")
  valid_774442 = validateParameter(valid_774442, JString, required = false,
                                 default = nil)
  if valid_774442 != nil:
    section.add "NextToken", valid_774442
  var valid_774443 = query.getOrDefault("MaxResults")
  valid_774443 = validateParameter(valid_774443, JString, required = false,
                                 default = nil)
  if valid_774443 != nil:
    section.add "MaxResults", valid_774443
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
  var valid_774444 = header.getOrDefault("X-Amz-Date")
  valid_774444 = validateParameter(valid_774444, JString, required = false,
                                 default = nil)
  if valid_774444 != nil:
    section.add "X-Amz-Date", valid_774444
  var valid_774445 = header.getOrDefault("X-Amz-Security-Token")
  valid_774445 = validateParameter(valid_774445, JString, required = false,
                                 default = nil)
  if valid_774445 != nil:
    section.add "X-Amz-Security-Token", valid_774445
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774446 = header.getOrDefault("X-Amz-Target")
  valid_774446 = validateParameter(valid_774446, JString, required = true,
                                 default = newJString("AmazonSSM.ListCommands"))
  if valid_774446 != nil:
    section.add "X-Amz-Target", valid_774446
  var valid_774447 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774447 = validateParameter(valid_774447, JString, required = false,
                                 default = nil)
  if valid_774447 != nil:
    section.add "X-Amz-Content-Sha256", valid_774447
  var valid_774448 = header.getOrDefault("X-Amz-Algorithm")
  valid_774448 = validateParameter(valid_774448, JString, required = false,
                                 default = nil)
  if valid_774448 != nil:
    section.add "X-Amz-Algorithm", valid_774448
  var valid_774449 = header.getOrDefault("X-Amz-Signature")
  valid_774449 = validateParameter(valid_774449, JString, required = false,
                                 default = nil)
  if valid_774449 != nil:
    section.add "X-Amz-Signature", valid_774449
  var valid_774450 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774450 = validateParameter(valid_774450, JString, required = false,
                                 default = nil)
  if valid_774450 != nil:
    section.add "X-Amz-SignedHeaders", valid_774450
  var valid_774451 = header.getOrDefault("X-Amz-Credential")
  valid_774451 = validateParameter(valid_774451, JString, required = false,
                                 default = nil)
  if valid_774451 != nil:
    section.add "X-Amz-Credential", valid_774451
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774453: Call_ListCommands_774439; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the commands requested by users of the AWS account.
  ## 
  let valid = call_774453.validator(path, query, header, formData, body)
  let scheme = call_774453.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774453.url(scheme.get, call_774453.host, call_774453.base,
                         call_774453.route, valid.getOrDefault("path"))
  result = hook(call_774453, url, valid)

proc call*(call_774454: Call_ListCommands_774439; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listCommands
  ## Lists the commands requested by users of the AWS account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_774455 = newJObject()
  var body_774456 = newJObject()
  add(query_774455, "NextToken", newJString(NextToken))
  if body != nil:
    body_774456 = body
  add(query_774455, "MaxResults", newJString(MaxResults))
  result = call_774454.call(nil, query_774455, nil, nil, body_774456)

var listCommands* = Call_ListCommands_774439(name: "listCommands",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListCommands",
    validator: validate_ListCommands_774440, base: "/", url: url_ListCommands_774441,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListComplianceItems_774457 = ref object of OpenApiRestCall_772597
proc url_ListComplianceItems_774459(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListComplianceItems_774458(path: JsonNode; query: JsonNode;
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
  var valid_774460 = header.getOrDefault("X-Amz-Date")
  valid_774460 = validateParameter(valid_774460, JString, required = false,
                                 default = nil)
  if valid_774460 != nil:
    section.add "X-Amz-Date", valid_774460
  var valid_774461 = header.getOrDefault("X-Amz-Security-Token")
  valid_774461 = validateParameter(valid_774461, JString, required = false,
                                 default = nil)
  if valid_774461 != nil:
    section.add "X-Amz-Security-Token", valid_774461
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774462 = header.getOrDefault("X-Amz-Target")
  valid_774462 = validateParameter(valid_774462, JString, required = true, default = newJString(
      "AmazonSSM.ListComplianceItems"))
  if valid_774462 != nil:
    section.add "X-Amz-Target", valid_774462
  var valid_774463 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774463 = validateParameter(valid_774463, JString, required = false,
                                 default = nil)
  if valid_774463 != nil:
    section.add "X-Amz-Content-Sha256", valid_774463
  var valid_774464 = header.getOrDefault("X-Amz-Algorithm")
  valid_774464 = validateParameter(valid_774464, JString, required = false,
                                 default = nil)
  if valid_774464 != nil:
    section.add "X-Amz-Algorithm", valid_774464
  var valid_774465 = header.getOrDefault("X-Amz-Signature")
  valid_774465 = validateParameter(valid_774465, JString, required = false,
                                 default = nil)
  if valid_774465 != nil:
    section.add "X-Amz-Signature", valid_774465
  var valid_774466 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774466 = validateParameter(valid_774466, JString, required = false,
                                 default = nil)
  if valid_774466 != nil:
    section.add "X-Amz-SignedHeaders", valid_774466
  var valid_774467 = header.getOrDefault("X-Amz-Credential")
  valid_774467 = validateParameter(valid_774467, JString, required = false,
                                 default = nil)
  if valid_774467 != nil:
    section.add "X-Amz-Credential", valid_774467
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774469: Call_ListComplianceItems_774457; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## For a specified resource ID, this API action returns a list of compliance statuses for different resource types. Currently, you can only specify one resource ID per call. List results depend on the criteria specified in the filter. 
  ## 
  let valid = call_774469.validator(path, query, header, formData, body)
  let scheme = call_774469.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774469.url(scheme.get, call_774469.host, call_774469.base,
                         call_774469.route, valid.getOrDefault("path"))
  result = hook(call_774469, url, valid)

proc call*(call_774470: Call_ListComplianceItems_774457; body: JsonNode): Recallable =
  ## listComplianceItems
  ## For a specified resource ID, this API action returns a list of compliance statuses for different resource types. Currently, you can only specify one resource ID per call. List results depend on the criteria specified in the filter. 
  ##   body: JObject (required)
  var body_774471 = newJObject()
  if body != nil:
    body_774471 = body
  result = call_774470.call(nil, nil, nil, nil, body_774471)

var listComplianceItems* = Call_ListComplianceItems_774457(
    name: "listComplianceItems", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListComplianceItems",
    validator: validate_ListComplianceItems_774458, base: "/",
    url: url_ListComplianceItems_774459, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListComplianceSummaries_774472 = ref object of OpenApiRestCall_772597
proc url_ListComplianceSummaries_774474(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListComplianceSummaries_774473(path: JsonNode; query: JsonNode;
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
  var valid_774475 = header.getOrDefault("X-Amz-Date")
  valid_774475 = validateParameter(valid_774475, JString, required = false,
                                 default = nil)
  if valid_774475 != nil:
    section.add "X-Amz-Date", valid_774475
  var valid_774476 = header.getOrDefault("X-Amz-Security-Token")
  valid_774476 = validateParameter(valid_774476, JString, required = false,
                                 default = nil)
  if valid_774476 != nil:
    section.add "X-Amz-Security-Token", valid_774476
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774477 = header.getOrDefault("X-Amz-Target")
  valid_774477 = validateParameter(valid_774477, JString, required = true, default = newJString(
      "AmazonSSM.ListComplianceSummaries"))
  if valid_774477 != nil:
    section.add "X-Amz-Target", valid_774477
  var valid_774478 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774478 = validateParameter(valid_774478, JString, required = false,
                                 default = nil)
  if valid_774478 != nil:
    section.add "X-Amz-Content-Sha256", valid_774478
  var valid_774479 = header.getOrDefault("X-Amz-Algorithm")
  valid_774479 = validateParameter(valid_774479, JString, required = false,
                                 default = nil)
  if valid_774479 != nil:
    section.add "X-Amz-Algorithm", valid_774479
  var valid_774480 = header.getOrDefault("X-Amz-Signature")
  valid_774480 = validateParameter(valid_774480, JString, required = false,
                                 default = nil)
  if valid_774480 != nil:
    section.add "X-Amz-Signature", valid_774480
  var valid_774481 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774481 = validateParameter(valid_774481, JString, required = false,
                                 default = nil)
  if valid_774481 != nil:
    section.add "X-Amz-SignedHeaders", valid_774481
  var valid_774482 = header.getOrDefault("X-Amz-Credential")
  valid_774482 = validateParameter(valid_774482, JString, required = false,
                                 default = nil)
  if valid_774482 != nil:
    section.add "X-Amz-Credential", valid_774482
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774484: Call_ListComplianceSummaries_774472; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a summary count of compliant and non-compliant resources for a compliance type. For example, this call can return State Manager associations, patches, or custom compliance types according to the filter criteria that you specify. 
  ## 
  let valid = call_774484.validator(path, query, header, formData, body)
  let scheme = call_774484.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774484.url(scheme.get, call_774484.host, call_774484.base,
                         call_774484.route, valid.getOrDefault("path"))
  result = hook(call_774484, url, valid)

proc call*(call_774485: Call_ListComplianceSummaries_774472; body: JsonNode): Recallable =
  ## listComplianceSummaries
  ## Returns a summary count of compliant and non-compliant resources for a compliance type. For example, this call can return State Manager associations, patches, or custom compliance types according to the filter criteria that you specify. 
  ##   body: JObject (required)
  var body_774486 = newJObject()
  if body != nil:
    body_774486 = body
  result = call_774485.call(nil, nil, nil, nil, body_774486)

var listComplianceSummaries* = Call_ListComplianceSummaries_774472(
    name: "listComplianceSummaries", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListComplianceSummaries",
    validator: validate_ListComplianceSummaries_774473, base: "/",
    url: url_ListComplianceSummaries_774474, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDocumentVersions_774487 = ref object of OpenApiRestCall_772597
proc url_ListDocumentVersions_774489(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListDocumentVersions_774488(path: JsonNode; query: JsonNode;
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
  var valid_774490 = header.getOrDefault("X-Amz-Date")
  valid_774490 = validateParameter(valid_774490, JString, required = false,
                                 default = nil)
  if valid_774490 != nil:
    section.add "X-Amz-Date", valid_774490
  var valid_774491 = header.getOrDefault("X-Amz-Security-Token")
  valid_774491 = validateParameter(valid_774491, JString, required = false,
                                 default = nil)
  if valid_774491 != nil:
    section.add "X-Amz-Security-Token", valid_774491
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774492 = header.getOrDefault("X-Amz-Target")
  valid_774492 = validateParameter(valid_774492, JString, required = true, default = newJString(
      "AmazonSSM.ListDocumentVersions"))
  if valid_774492 != nil:
    section.add "X-Amz-Target", valid_774492
  var valid_774493 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774493 = validateParameter(valid_774493, JString, required = false,
                                 default = nil)
  if valid_774493 != nil:
    section.add "X-Amz-Content-Sha256", valid_774493
  var valid_774494 = header.getOrDefault("X-Amz-Algorithm")
  valid_774494 = validateParameter(valid_774494, JString, required = false,
                                 default = nil)
  if valid_774494 != nil:
    section.add "X-Amz-Algorithm", valid_774494
  var valid_774495 = header.getOrDefault("X-Amz-Signature")
  valid_774495 = validateParameter(valid_774495, JString, required = false,
                                 default = nil)
  if valid_774495 != nil:
    section.add "X-Amz-Signature", valid_774495
  var valid_774496 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774496 = validateParameter(valid_774496, JString, required = false,
                                 default = nil)
  if valid_774496 != nil:
    section.add "X-Amz-SignedHeaders", valid_774496
  var valid_774497 = header.getOrDefault("X-Amz-Credential")
  valid_774497 = validateParameter(valid_774497, JString, required = false,
                                 default = nil)
  if valid_774497 != nil:
    section.add "X-Amz-Credential", valid_774497
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774499: Call_ListDocumentVersions_774487; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all versions for a document.
  ## 
  let valid = call_774499.validator(path, query, header, formData, body)
  let scheme = call_774499.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774499.url(scheme.get, call_774499.host, call_774499.base,
                         call_774499.route, valid.getOrDefault("path"))
  result = hook(call_774499, url, valid)

proc call*(call_774500: Call_ListDocumentVersions_774487; body: JsonNode): Recallable =
  ## listDocumentVersions
  ## List all versions for a document.
  ##   body: JObject (required)
  var body_774501 = newJObject()
  if body != nil:
    body_774501 = body
  result = call_774500.call(nil, nil, nil, nil, body_774501)

var listDocumentVersions* = Call_ListDocumentVersions_774487(
    name: "listDocumentVersions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListDocumentVersions",
    validator: validate_ListDocumentVersions_774488, base: "/",
    url: url_ListDocumentVersions_774489, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDocuments_774502 = ref object of OpenApiRestCall_772597
proc url_ListDocuments_774504(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListDocuments_774503(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774505 = query.getOrDefault("NextToken")
  valid_774505 = validateParameter(valid_774505, JString, required = false,
                                 default = nil)
  if valid_774505 != nil:
    section.add "NextToken", valid_774505
  var valid_774506 = query.getOrDefault("MaxResults")
  valid_774506 = validateParameter(valid_774506, JString, required = false,
                                 default = nil)
  if valid_774506 != nil:
    section.add "MaxResults", valid_774506
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
  var valid_774507 = header.getOrDefault("X-Amz-Date")
  valid_774507 = validateParameter(valid_774507, JString, required = false,
                                 default = nil)
  if valid_774507 != nil:
    section.add "X-Amz-Date", valid_774507
  var valid_774508 = header.getOrDefault("X-Amz-Security-Token")
  valid_774508 = validateParameter(valid_774508, JString, required = false,
                                 default = nil)
  if valid_774508 != nil:
    section.add "X-Amz-Security-Token", valid_774508
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774509 = header.getOrDefault("X-Amz-Target")
  valid_774509 = validateParameter(valid_774509, JString, required = true, default = newJString(
      "AmazonSSM.ListDocuments"))
  if valid_774509 != nil:
    section.add "X-Amz-Target", valid_774509
  var valid_774510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774510 = validateParameter(valid_774510, JString, required = false,
                                 default = nil)
  if valid_774510 != nil:
    section.add "X-Amz-Content-Sha256", valid_774510
  var valid_774511 = header.getOrDefault("X-Amz-Algorithm")
  valid_774511 = validateParameter(valid_774511, JString, required = false,
                                 default = nil)
  if valid_774511 != nil:
    section.add "X-Amz-Algorithm", valid_774511
  var valid_774512 = header.getOrDefault("X-Amz-Signature")
  valid_774512 = validateParameter(valid_774512, JString, required = false,
                                 default = nil)
  if valid_774512 != nil:
    section.add "X-Amz-Signature", valid_774512
  var valid_774513 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774513 = validateParameter(valid_774513, JString, required = false,
                                 default = nil)
  if valid_774513 != nil:
    section.add "X-Amz-SignedHeaders", valid_774513
  var valid_774514 = header.getOrDefault("X-Amz-Credential")
  valid_774514 = validateParameter(valid_774514, JString, required = false,
                                 default = nil)
  if valid_774514 != nil:
    section.add "X-Amz-Credential", valid_774514
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774516: Call_ListDocuments_774502; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes one or more of your Systems Manager documents.
  ## 
  let valid = call_774516.validator(path, query, header, formData, body)
  let scheme = call_774516.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774516.url(scheme.get, call_774516.host, call_774516.base,
                         call_774516.route, valid.getOrDefault("path"))
  result = hook(call_774516, url, valid)

proc call*(call_774517: Call_ListDocuments_774502; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listDocuments
  ## Describes one or more of your Systems Manager documents.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_774518 = newJObject()
  var body_774519 = newJObject()
  add(query_774518, "NextToken", newJString(NextToken))
  if body != nil:
    body_774519 = body
  add(query_774518, "MaxResults", newJString(MaxResults))
  result = call_774517.call(nil, query_774518, nil, nil, body_774519)

var listDocuments* = Call_ListDocuments_774502(name: "listDocuments",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListDocuments",
    validator: validate_ListDocuments_774503, base: "/", url: url_ListDocuments_774504,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInventoryEntries_774520 = ref object of OpenApiRestCall_772597
proc url_ListInventoryEntries_774522(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListInventoryEntries_774521(path: JsonNode; query: JsonNode;
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
  var valid_774523 = header.getOrDefault("X-Amz-Date")
  valid_774523 = validateParameter(valid_774523, JString, required = false,
                                 default = nil)
  if valid_774523 != nil:
    section.add "X-Amz-Date", valid_774523
  var valid_774524 = header.getOrDefault("X-Amz-Security-Token")
  valid_774524 = validateParameter(valid_774524, JString, required = false,
                                 default = nil)
  if valid_774524 != nil:
    section.add "X-Amz-Security-Token", valid_774524
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774525 = header.getOrDefault("X-Amz-Target")
  valid_774525 = validateParameter(valid_774525, JString, required = true, default = newJString(
      "AmazonSSM.ListInventoryEntries"))
  if valid_774525 != nil:
    section.add "X-Amz-Target", valid_774525
  var valid_774526 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774526 = validateParameter(valid_774526, JString, required = false,
                                 default = nil)
  if valid_774526 != nil:
    section.add "X-Amz-Content-Sha256", valid_774526
  var valid_774527 = header.getOrDefault("X-Amz-Algorithm")
  valid_774527 = validateParameter(valid_774527, JString, required = false,
                                 default = nil)
  if valid_774527 != nil:
    section.add "X-Amz-Algorithm", valid_774527
  var valid_774528 = header.getOrDefault("X-Amz-Signature")
  valid_774528 = validateParameter(valid_774528, JString, required = false,
                                 default = nil)
  if valid_774528 != nil:
    section.add "X-Amz-Signature", valid_774528
  var valid_774529 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774529 = validateParameter(valid_774529, JString, required = false,
                                 default = nil)
  if valid_774529 != nil:
    section.add "X-Amz-SignedHeaders", valid_774529
  var valid_774530 = header.getOrDefault("X-Amz-Credential")
  valid_774530 = validateParameter(valid_774530, JString, required = false,
                                 default = nil)
  if valid_774530 != nil:
    section.add "X-Amz-Credential", valid_774530
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774532: Call_ListInventoryEntries_774520; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## A list of inventory items returned by the request.
  ## 
  let valid = call_774532.validator(path, query, header, formData, body)
  let scheme = call_774532.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774532.url(scheme.get, call_774532.host, call_774532.base,
                         call_774532.route, valid.getOrDefault("path"))
  result = hook(call_774532, url, valid)

proc call*(call_774533: Call_ListInventoryEntries_774520; body: JsonNode): Recallable =
  ## listInventoryEntries
  ## A list of inventory items returned by the request.
  ##   body: JObject (required)
  var body_774534 = newJObject()
  if body != nil:
    body_774534 = body
  result = call_774533.call(nil, nil, nil, nil, body_774534)

var listInventoryEntries* = Call_ListInventoryEntries_774520(
    name: "listInventoryEntries", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListInventoryEntries",
    validator: validate_ListInventoryEntries_774521, base: "/",
    url: url_ListInventoryEntries_774522, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceComplianceSummaries_774535 = ref object of OpenApiRestCall_772597
proc url_ListResourceComplianceSummaries_774537(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListResourceComplianceSummaries_774536(path: JsonNode;
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
  var valid_774538 = header.getOrDefault("X-Amz-Date")
  valid_774538 = validateParameter(valid_774538, JString, required = false,
                                 default = nil)
  if valid_774538 != nil:
    section.add "X-Amz-Date", valid_774538
  var valid_774539 = header.getOrDefault("X-Amz-Security-Token")
  valid_774539 = validateParameter(valid_774539, JString, required = false,
                                 default = nil)
  if valid_774539 != nil:
    section.add "X-Amz-Security-Token", valid_774539
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774540 = header.getOrDefault("X-Amz-Target")
  valid_774540 = validateParameter(valid_774540, JString, required = true, default = newJString(
      "AmazonSSM.ListResourceComplianceSummaries"))
  if valid_774540 != nil:
    section.add "X-Amz-Target", valid_774540
  var valid_774541 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774541 = validateParameter(valid_774541, JString, required = false,
                                 default = nil)
  if valid_774541 != nil:
    section.add "X-Amz-Content-Sha256", valid_774541
  var valid_774542 = header.getOrDefault("X-Amz-Algorithm")
  valid_774542 = validateParameter(valid_774542, JString, required = false,
                                 default = nil)
  if valid_774542 != nil:
    section.add "X-Amz-Algorithm", valid_774542
  var valid_774543 = header.getOrDefault("X-Amz-Signature")
  valid_774543 = validateParameter(valid_774543, JString, required = false,
                                 default = nil)
  if valid_774543 != nil:
    section.add "X-Amz-Signature", valid_774543
  var valid_774544 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774544 = validateParameter(valid_774544, JString, required = false,
                                 default = nil)
  if valid_774544 != nil:
    section.add "X-Amz-SignedHeaders", valid_774544
  var valid_774545 = header.getOrDefault("X-Amz-Credential")
  valid_774545 = validateParameter(valid_774545, JString, required = false,
                                 default = nil)
  if valid_774545 != nil:
    section.add "X-Amz-Credential", valid_774545
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774547: Call_ListResourceComplianceSummaries_774535;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a resource-level summary count. The summary includes information about compliant and non-compliant statuses and detailed compliance-item severity counts, according to the filter criteria you specify.
  ## 
  let valid = call_774547.validator(path, query, header, formData, body)
  let scheme = call_774547.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774547.url(scheme.get, call_774547.host, call_774547.base,
                         call_774547.route, valid.getOrDefault("path"))
  result = hook(call_774547, url, valid)

proc call*(call_774548: Call_ListResourceComplianceSummaries_774535; body: JsonNode): Recallable =
  ## listResourceComplianceSummaries
  ## Returns a resource-level summary count. The summary includes information about compliant and non-compliant statuses and detailed compliance-item severity counts, according to the filter criteria you specify.
  ##   body: JObject (required)
  var body_774549 = newJObject()
  if body != nil:
    body_774549 = body
  result = call_774548.call(nil, nil, nil, nil, body_774549)

var listResourceComplianceSummaries* = Call_ListResourceComplianceSummaries_774535(
    name: "listResourceComplianceSummaries", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListResourceComplianceSummaries",
    validator: validate_ListResourceComplianceSummaries_774536, base: "/",
    url: url_ListResourceComplianceSummaries_774537,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceDataSync_774550 = ref object of OpenApiRestCall_772597
proc url_ListResourceDataSync_774552(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListResourceDataSync_774551(path: JsonNode; query: JsonNode;
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
  var valid_774553 = header.getOrDefault("X-Amz-Date")
  valid_774553 = validateParameter(valid_774553, JString, required = false,
                                 default = nil)
  if valid_774553 != nil:
    section.add "X-Amz-Date", valid_774553
  var valid_774554 = header.getOrDefault("X-Amz-Security-Token")
  valid_774554 = validateParameter(valid_774554, JString, required = false,
                                 default = nil)
  if valid_774554 != nil:
    section.add "X-Amz-Security-Token", valid_774554
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774555 = header.getOrDefault("X-Amz-Target")
  valid_774555 = validateParameter(valid_774555, JString, required = true, default = newJString(
      "AmazonSSM.ListResourceDataSync"))
  if valid_774555 != nil:
    section.add "X-Amz-Target", valid_774555
  var valid_774556 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774556 = validateParameter(valid_774556, JString, required = false,
                                 default = nil)
  if valid_774556 != nil:
    section.add "X-Amz-Content-Sha256", valid_774556
  var valid_774557 = header.getOrDefault("X-Amz-Algorithm")
  valid_774557 = validateParameter(valid_774557, JString, required = false,
                                 default = nil)
  if valid_774557 != nil:
    section.add "X-Amz-Algorithm", valid_774557
  var valid_774558 = header.getOrDefault("X-Amz-Signature")
  valid_774558 = validateParameter(valid_774558, JString, required = false,
                                 default = nil)
  if valid_774558 != nil:
    section.add "X-Amz-Signature", valid_774558
  var valid_774559 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774559 = validateParameter(valid_774559, JString, required = false,
                                 default = nil)
  if valid_774559 != nil:
    section.add "X-Amz-SignedHeaders", valid_774559
  var valid_774560 = header.getOrDefault("X-Amz-Credential")
  valid_774560 = validateParameter(valid_774560, JString, required = false,
                                 default = nil)
  if valid_774560 != nil:
    section.add "X-Amz-Credential", valid_774560
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774562: Call_ListResourceDataSync_774550; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists your resource data sync configurations. Includes information about the last time a sync attempted to start, the last sync status, and the last time a sync successfully completed.</p> <p>The number of sync configurations might be too large to return using a single call to <code>ListResourceDataSync</code>. You can limit the number of sync configurations returned by using the <code>MaxResults</code> parameter. To determine whether there are more sync configurations to list, check the value of <code>NextToken</code> in the output. If there are more sync configurations to list, you can request them by specifying the <code>NextToken</code> returned in the call to the parameter of a subsequent call. </p>
  ## 
  let valid = call_774562.validator(path, query, header, formData, body)
  let scheme = call_774562.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774562.url(scheme.get, call_774562.host, call_774562.base,
                         call_774562.route, valid.getOrDefault("path"))
  result = hook(call_774562, url, valid)

proc call*(call_774563: Call_ListResourceDataSync_774550; body: JsonNode): Recallable =
  ## listResourceDataSync
  ## <p>Lists your resource data sync configurations. Includes information about the last time a sync attempted to start, the last sync status, and the last time a sync successfully completed.</p> <p>The number of sync configurations might be too large to return using a single call to <code>ListResourceDataSync</code>. You can limit the number of sync configurations returned by using the <code>MaxResults</code> parameter. To determine whether there are more sync configurations to list, check the value of <code>NextToken</code> in the output. If there are more sync configurations to list, you can request them by specifying the <code>NextToken</code> returned in the call to the parameter of a subsequent call. </p>
  ##   body: JObject (required)
  var body_774564 = newJObject()
  if body != nil:
    body_774564 = body
  result = call_774563.call(nil, nil, nil, nil, body_774564)

var listResourceDataSync* = Call_ListResourceDataSync_774550(
    name: "listResourceDataSync", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListResourceDataSync",
    validator: validate_ListResourceDataSync_774551, base: "/",
    url: url_ListResourceDataSync_774552, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_774565 = ref object of OpenApiRestCall_772597
proc url_ListTagsForResource_774567(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTagsForResource_774566(path: JsonNode; query: JsonNode;
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
  var valid_774568 = header.getOrDefault("X-Amz-Date")
  valid_774568 = validateParameter(valid_774568, JString, required = false,
                                 default = nil)
  if valid_774568 != nil:
    section.add "X-Amz-Date", valid_774568
  var valid_774569 = header.getOrDefault("X-Amz-Security-Token")
  valid_774569 = validateParameter(valid_774569, JString, required = false,
                                 default = nil)
  if valid_774569 != nil:
    section.add "X-Amz-Security-Token", valid_774569
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774570 = header.getOrDefault("X-Amz-Target")
  valid_774570 = validateParameter(valid_774570, JString, required = true, default = newJString(
      "AmazonSSM.ListTagsForResource"))
  if valid_774570 != nil:
    section.add "X-Amz-Target", valid_774570
  var valid_774571 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774571 = validateParameter(valid_774571, JString, required = false,
                                 default = nil)
  if valid_774571 != nil:
    section.add "X-Amz-Content-Sha256", valid_774571
  var valid_774572 = header.getOrDefault("X-Amz-Algorithm")
  valid_774572 = validateParameter(valid_774572, JString, required = false,
                                 default = nil)
  if valid_774572 != nil:
    section.add "X-Amz-Algorithm", valid_774572
  var valid_774573 = header.getOrDefault("X-Amz-Signature")
  valid_774573 = validateParameter(valid_774573, JString, required = false,
                                 default = nil)
  if valid_774573 != nil:
    section.add "X-Amz-Signature", valid_774573
  var valid_774574 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774574 = validateParameter(valid_774574, JString, required = false,
                                 default = nil)
  if valid_774574 != nil:
    section.add "X-Amz-SignedHeaders", valid_774574
  var valid_774575 = header.getOrDefault("X-Amz-Credential")
  valid_774575 = validateParameter(valid_774575, JString, required = false,
                                 default = nil)
  if valid_774575 != nil:
    section.add "X-Amz-Credential", valid_774575
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774577: Call_ListTagsForResource_774565; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the tags assigned to the specified resource.
  ## 
  let valid = call_774577.validator(path, query, header, formData, body)
  let scheme = call_774577.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774577.url(scheme.get, call_774577.host, call_774577.base,
                         call_774577.route, valid.getOrDefault("path"))
  result = hook(call_774577, url, valid)

proc call*(call_774578: Call_ListTagsForResource_774565; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Returns a list of the tags assigned to the specified resource.
  ##   body: JObject (required)
  var body_774579 = newJObject()
  if body != nil:
    body_774579 = body
  result = call_774578.call(nil, nil, nil, nil, body_774579)

var listTagsForResource* = Call_ListTagsForResource_774565(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListTagsForResource",
    validator: validate_ListTagsForResource_774566, base: "/",
    url: url_ListTagsForResource_774567, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyDocumentPermission_774580 = ref object of OpenApiRestCall_772597
proc url_ModifyDocumentPermission_774582(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ModifyDocumentPermission_774581(path: JsonNode; query: JsonNode;
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
  var valid_774583 = header.getOrDefault("X-Amz-Date")
  valid_774583 = validateParameter(valid_774583, JString, required = false,
                                 default = nil)
  if valid_774583 != nil:
    section.add "X-Amz-Date", valid_774583
  var valid_774584 = header.getOrDefault("X-Amz-Security-Token")
  valid_774584 = validateParameter(valid_774584, JString, required = false,
                                 default = nil)
  if valid_774584 != nil:
    section.add "X-Amz-Security-Token", valid_774584
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774585 = header.getOrDefault("X-Amz-Target")
  valid_774585 = validateParameter(valid_774585, JString, required = true, default = newJString(
      "AmazonSSM.ModifyDocumentPermission"))
  if valid_774585 != nil:
    section.add "X-Amz-Target", valid_774585
  var valid_774586 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774586 = validateParameter(valid_774586, JString, required = false,
                                 default = nil)
  if valid_774586 != nil:
    section.add "X-Amz-Content-Sha256", valid_774586
  var valid_774587 = header.getOrDefault("X-Amz-Algorithm")
  valid_774587 = validateParameter(valid_774587, JString, required = false,
                                 default = nil)
  if valid_774587 != nil:
    section.add "X-Amz-Algorithm", valid_774587
  var valid_774588 = header.getOrDefault("X-Amz-Signature")
  valid_774588 = validateParameter(valid_774588, JString, required = false,
                                 default = nil)
  if valid_774588 != nil:
    section.add "X-Amz-Signature", valid_774588
  var valid_774589 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774589 = validateParameter(valid_774589, JString, required = false,
                                 default = nil)
  if valid_774589 != nil:
    section.add "X-Amz-SignedHeaders", valid_774589
  var valid_774590 = header.getOrDefault("X-Amz-Credential")
  valid_774590 = validateParameter(valid_774590, JString, required = false,
                                 default = nil)
  if valid_774590 != nil:
    section.add "X-Amz-Credential", valid_774590
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774592: Call_ModifyDocumentPermission_774580; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Shares a Systems Manager document publicly or privately. If you share a document privately, you must specify the AWS user account IDs for those people who can use the document. If you share a document publicly, you must specify <i>All</i> as the account ID.
  ## 
  let valid = call_774592.validator(path, query, header, formData, body)
  let scheme = call_774592.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774592.url(scheme.get, call_774592.host, call_774592.base,
                         call_774592.route, valid.getOrDefault("path"))
  result = hook(call_774592, url, valid)

proc call*(call_774593: Call_ModifyDocumentPermission_774580; body: JsonNode): Recallable =
  ## modifyDocumentPermission
  ## Shares a Systems Manager document publicly or privately. If you share a document privately, you must specify the AWS user account IDs for those people who can use the document. If you share a document publicly, you must specify <i>All</i> as the account ID.
  ##   body: JObject (required)
  var body_774594 = newJObject()
  if body != nil:
    body_774594 = body
  result = call_774593.call(nil, nil, nil, nil, body_774594)

var modifyDocumentPermission* = Call_ModifyDocumentPermission_774580(
    name: "modifyDocumentPermission", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ModifyDocumentPermission",
    validator: validate_ModifyDocumentPermission_774581, base: "/",
    url: url_ModifyDocumentPermission_774582, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutComplianceItems_774595 = ref object of OpenApiRestCall_772597
proc url_PutComplianceItems_774597(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutComplianceItems_774596(path: JsonNode; query: JsonNode;
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
  var valid_774598 = header.getOrDefault("X-Amz-Date")
  valid_774598 = validateParameter(valid_774598, JString, required = false,
                                 default = nil)
  if valid_774598 != nil:
    section.add "X-Amz-Date", valid_774598
  var valid_774599 = header.getOrDefault("X-Amz-Security-Token")
  valid_774599 = validateParameter(valid_774599, JString, required = false,
                                 default = nil)
  if valid_774599 != nil:
    section.add "X-Amz-Security-Token", valid_774599
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774600 = header.getOrDefault("X-Amz-Target")
  valid_774600 = validateParameter(valid_774600, JString, required = true, default = newJString(
      "AmazonSSM.PutComplianceItems"))
  if valid_774600 != nil:
    section.add "X-Amz-Target", valid_774600
  var valid_774601 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774601 = validateParameter(valid_774601, JString, required = false,
                                 default = nil)
  if valid_774601 != nil:
    section.add "X-Amz-Content-Sha256", valid_774601
  var valid_774602 = header.getOrDefault("X-Amz-Algorithm")
  valid_774602 = validateParameter(valid_774602, JString, required = false,
                                 default = nil)
  if valid_774602 != nil:
    section.add "X-Amz-Algorithm", valid_774602
  var valid_774603 = header.getOrDefault("X-Amz-Signature")
  valid_774603 = validateParameter(valid_774603, JString, required = false,
                                 default = nil)
  if valid_774603 != nil:
    section.add "X-Amz-Signature", valid_774603
  var valid_774604 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774604 = validateParameter(valid_774604, JString, required = false,
                                 default = nil)
  if valid_774604 != nil:
    section.add "X-Amz-SignedHeaders", valid_774604
  var valid_774605 = header.getOrDefault("X-Amz-Credential")
  valid_774605 = validateParameter(valid_774605, JString, required = false,
                                 default = nil)
  if valid_774605 != nil:
    section.add "X-Amz-Credential", valid_774605
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774607: Call_PutComplianceItems_774595; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Registers a compliance type and other compliance details on a designated resource. This action lets you register custom compliance details with a resource. This call overwrites existing compliance information on the resource, so you must provide a full list of compliance items each time that you send the request.</p> <p>ComplianceType can be one of the following:</p> <ul> <li> <p>ExecutionId: The execution ID when the patch, association, or custom compliance item was applied.</p> </li> <li> <p>ExecutionType: Specify patch, association, or Custom:<code>string</code>.</p> </li> <li> <p>ExecutionTime. The time the patch, association, or custom compliance item was applied to the instance.</p> </li> <li> <p>Id: The patch, association, or custom compliance ID.</p> </li> <li> <p>Title: A title.</p> </li> <li> <p>Status: The status of the compliance item. For example, <code>approved</code> for patches, or <code>Failed</code> for associations.</p> </li> <li> <p>Severity: A patch severity. For example, <code>critical</code>.</p> </li> <li> <p>DocumentName: A SSM document name. For example, AWS-RunPatchBaseline.</p> </li> <li> <p>DocumentVersion: An SSM document version number. For example, 4.</p> </li> <li> <p>Classification: A patch classification. For example, <code>security updates</code>.</p> </li> <li> <p>PatchBaselineId: A patch baseline ID.</p> </li> <li> <p>PatchSeverity: A patch severity. For example, <code>Critical</code>.</p> </li> <li> <p>PatchState: A patch state. For example, <code>InstancesWithFailedPatches</code>.</p> </li> <li> <p>PatchGroup: The name of a patch group.</p> </li> <li> <p>InstalledTime: The time the association, patch, or custom compliance item was applied to the resource. Specify the time by using the following format: yyyy-MM-dd'T'HH:mm:ss'Z'</p> </li> </ul>
  ## 
  let valid = call_774607.validator(path, query, header, formData, body)
  let scheme = call_774607.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774607.url(scheme.get, call_774607.host, call_774607.base,
                         call_774607.route, valid.getOrDefault("path"))
  result = hook(call_774607, url, valid)

proc call*(call_774608: Call_PutComplianceItems_774595; body: JsonNode): Recallable =
  ## putComplianceItems
  ## <p>Registers a compliance type and other compliance details on a designated resource. This action lets you register custom compliance details with a resource. This call overwrites existing compliance information on the resource, so you must provide a full list of compliance items each time that you send the request.</p> <p>ComplianceType can be one of the following:</p> <ul> <li> <p>ExecutionId: The execution ID when the patch, association, or custom compliance item was applied.</p> </li> <li> <p>ExecutionType: Specify patch, association, or Custom:<code>string</code>.</p> </li> <li> <p>ExecutionTime. The time the patch, association, or custom compliance item was applied to the instance.</p> </li> <li> <p>Id: The patch, association, or custom compliance ID.</p> </li> <li> <p>Title: A title.</p> </li> <li> <p>Status: The status of the compliance item. For example, <code>approved</code> for patches, or <code>Failed</code> for associations.</p> </li> <li> <p>Severity: A patch severity. For example, <code>critical</code>.</p> </li> <li> <p>DocumentName: A SSM document name. For example, AWS-RunPatchBaseline.</p> </li> <li> <p>DocumentVersion: An SSM document version number. For example, 4.</p> </li> <li> <p>Classification: A patch classification. For example, <code>security updates</code>.</p> </li> <li> <p>PatchBaselineId: A patch baseline ID.</p> </li> <li> <p>PatchSeverity: A patch severity. For example, <code>Critical</code>.</p> </li> <li> <p>PatchState: A patch state. For example, <code>InstancesWithFailedPatches</code>.</p> </li> <li> <p>PatchGroup: The name of a patch group.</p> </li> <li> <p>InstalledTime: The time the association, patch, or custom compliance item was applied to the resource. Specify the time by using the following format: yyyy-MM-dd'T'HH:mm:ss'Z'</p> </li> </ul>
  ##   body: JObject (required)
  var body_774609 = newJObject()
  if body != nil:
    body_774609 = body
  result = call_774608.call(nil, nil, nil, nil, body_774609)

var putComplianceItems* = Call_PutComplianceItems_774595(
    name: "putComplianceItems", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.PutComplianceItems",
    validator: validate_PutComplianceItems_774596, base: "/",
    url: url_PutComplianceItems_774597, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutInventory_774610 = ref object of OpenApiRestCall_772597
proc url_PutInventory_774612(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutInventory_774611(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774613 = header.getOrDefault("X-Amz-Date")
  valid_774613 = validateParameter(valid_774613, JString, required = false,
                                 default = nil)
  if valid_774613 != nil:
    section.add "X-Amz-Date", valid_774613
  var valid_774614 = header.getOrDefault("X-Amz-Security-Token")
  valid_774614 = validateParameter(valid_774614, JString, required = false,
                                 default = nil)
  if valid_774614 != nil:
    section.add "X-Amz-Security-Token", valid_774614
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774615 = header.getOrDefault("X-Amz-Target")
  valid_774615 = validateParameter(valid_774615, JString, required = true,
                                 default = newJString("AmazonSSM.PutInventory"))
  if valid_774615 != nil:
    section.add "X-Amz-Target", valid_774615
  var valid_774616 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774616 = validateParameter(valid_774616, JString, required = false,
                                 default = nil)
  if valid_774616 != nil:
    section.add "X-Amz-Content-Sha256", valid_774616
  var valid_774617 = header.getOrDefault("X-Amz-Algorithm")
  valid_774617 = validateParameter(valid_774617, JString, required = false,
                                 default = nil)
  if valid_774617 != nil:
    section.add "X-Amz-Algorithm", valid_774617
  var valid_774618 = header.getOrDefault("X-Amz-Signature")
  valid_774618 = validateParameter(valid_774618, JString, required = false,
                                 default = nil)
  if valid_774618 != nil:
    section.add "X-Amz-Signature", valid_774618
  var valid_774619 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774619 = validateParameter(valid_774619, JString, required = false,
                                 default = nil)
  if valid_774619 != nil:
    section.add "X-Amz-SignedHeaders", valid_774619
  var valid_774620 = header.getOrDefault("X-Amz-Credential")
  valid_774620 = validateParameter(valid_774620, JString, required = false,
                                 default = nil)
  if valid_774620 != nil:
    section.add "X-Amz-Credential", valid_774620
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774622: Call_PutInventory_774610; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Bulk update custom inventory items on one more instance. The request adds an inventory item, if it doesn't already exist, or updates an inventory item, if it does exist.
  ## 
  let valid = call_774622.validator(path, query, header, formData, body)
  let scheme = call_774622.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774622.url(scheme.get, call_774622.host, call_774622.base,
                         call_774622.route, valid.getOrDefault("path"))
  result = hook(call_774622, url, valid)

proc call*(call_774623: Call_PutInventory_774610; body: JsonNode): Recallable =
  ## putInventory
  ## Bulk update custom inventory items on one more instance. The request adds an inventory item, if it doesn't already exist, or updates an inventory item, if it does exist.
  ##   body: JObject (required)
  var body_774624 = newJObject()
  if body != nil:
    body_774624 = body
  result = call_774623.call(nil, nil, nil, nil, body_774624)

var putInventory* = Call_PutInventory_774610(name: "putInventory",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.PutInventory",
    validator: validate_PutInventory_774611, base: "/", url: url_PutInventory_774612,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutParameter_774625 = ref object of OpenApiRestCall_772597
proc url_PutParameter_774627(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutParameter_774626(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774628 = header.getOrDefault("X-Amz-Date")
  valid_774628 = validateParameter(valid_774628, JString, required = false,
                                 default = nil)
  if valid_774628 != nil:
    section.add "X-Amz-Date", valid_774628
  var valid_774629 = header.getOrDefault("X-Amz-Security-Token")
  valid_774629 = validateParameter(valid_774629, JString, required = false,
                                 default = nil)
  if valid_774629 != nil:
    section.add "X-Amz-Security-Token", valid_774629
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774630 = header.getOrDefault("X-Amz-Target")
  valid_774630 = validateParameter(valid_774630, JString, required = true,
                                 default = newJString("AmazonSSM.PutParameter"))
  if valid_774630 != nil:
    section.add "X-Amz-Target", valid_774630
  var valid_774631 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774631 = validateParameter(valid_774631, JString, required = false,
                                 default = nil)
  if valid_774631 != nil:
    section.add "X-Amz-Content-Sha256", valid_774631
  var valid_774632 = header.getOrDefault("X-Amz-Algorithm")
  valid_774632 = validateParameter(valid_774632, JString, required = false,
                                 default = nil)
  if valid_774632 != nil:
    section.add "X-Amz-Algorithm", valid_774632
  var valid_774633 = header.getOrDefault("X-Amz-Signature")
  valid_774633 = validateParameter(valid_774633, JString, required = false,
                                 default = nil)
  if valid_774633 != nil:
    section.add "X-Amz-Signature", valid_774633
  var valid_774634 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774634 = validateParameter(valid_774634, JString, required = false,
                                 default = nil)
  if valid_774634 != nil:
    section.add "X-Amz-SignedHeaders", valid_774634
  var valid_774635 = header.getOrDefault("X-Amz-Credential")
  valid_774635 = validateParameter(valid_774635, JString, required = false,
                                 default = nil)
  if valid_774635 != nil:
    section.add "X-Amz-Credential", valid_774635
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774637: Call_PutParameter_774625; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Add a parameter to the system.
  ## 
  let valid = call_774637.validator(path, query, header, formData, body)
  let scheme = call_774637.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774637.url(scheme.get, call_774637.host, call_774637.base,
                         call_774637.route, valid.getOrDefault("path"))
  result = hook(call_774637, url, valid)

proc call*(call_774638: Call_PutParameter_774625; body: JsonNode): Recallable =
  ## putParameter
  ## Add a parameter to the system.
  ##   body: JObject (required)
  var body_774639 = newJObject()
  if body != nil:
    body_774639 = body
  result = call_774638.call(nil, nil, nil, nil, body_774639)

var putParameter* = Call_PutParameter_774625(name: "putParameter",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.PutParameter",
    validator: validate_PutParameter_774626, base: "/", url: url_PutParameter_774627,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterDefaultPatchBaseline_774640 = ref object of OpenApiRestCall_772597
proc url_RegisterDefaultPatchBaseline_774642(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RegisterDefaultPatchBaseline_774641(path: JsonNode; query: JsonNode;
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
  var valid_774643 = header.getOrDefault("X-Amz-Date")
  valid_774643 = validateParameter(valid_774643, JString, required = false,
                                 default = nil)
  if valid_774643 != nil:
    section.add "X-Amz-Date", valid_774643
  var valid_774644 = header.getOrDefault("X-Amz-Security-Token")
  valid_774644 = validateParameter(valid_774644, JString, required = false,
                                 default = nil)
  if valid_774644 != nil:
    section.add "X-Amz-Security-Token", valid_774644
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774645 = header.getOrDefault("X-Amz-Target")
  valid_774645 = validateParameter(valid_774645, JString, required = true, default = newJString(
      "AmazonSSM.RegisterDefaultPatchBaseline"))
  if valid_774645 != nil:
    section.add "X-Amz-Target", valid_774645
  var valid_774646 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774646 = validateParameter(valid_774646, JString, required = false,
                                 default = nil)
  if valid_774646 != nil:
    section.add "X-Amz-Content-Sha256", valid_774646
  var valid_774647 = header.getOrDefault("X-Amz-Algorithm")
  valid_774647 = validateParameter(valid_774647, JString, required = false,
                                 default = nil)
  if valid_774647 != nil:
    section.add "X-Amz-Algorithm", valid_774647
  var valid_774648 = header.getOrDefault("X-Amz-Signature")
  valid_774648 = validateParameter(valid_774648, JString, required = false,
                                 default = nil)
  if valid_774648 != nil:
    section.add "X-Amz-Signature", valid_774648
  var valid_774649 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774649 = validateParameter(valid_774649, JString, required = false,
                                 default = nil)
  if valid_774649 != nil:
    section.add "X-Amz-SignedHeaders", valid_774649
  var valid_774650 = header.getOrDefault("X-Amz-Credential")
  valid_774650 = validateParameter(valid_774650, JString, required = false,
                                 default = nil)
  if valid_774650 != nil:
    section.add "X-Amz-Credential", valid_774650
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774652: Call_RegisterDefaultPatchBaseline_774640; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Defines the default patch baseline for the relevant operating system.</p> <p>To reset the AWS predefined patch baseline as the default, specify the full patch baseline ARN as the baseline ID value. For example, for CentOS, specify <code>arn:aws:ssm:us-east-2:733109147000:patchbaseline/pb-0574b43a65ea646ed</code> instead of <code>pb-0574b43a65ea646ed</code>.</p>
  ## 
  let valid = call_774652.validator(path, query, header, formData, body)
  let scheme = call_774652.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774652.url(scheme.get, call_774652.host, call_774652.base,
                         call_774652.route, valid.getOrDefault("path"))
  result = hook(call_774652, url, valid)

proc call*(call_774653: Call_RegisterDefaultPatchBaseline_774640; body: JsonNode): Recallable =
  ## registerDefaultPatchBaseline
  ## <p>Defines the default patch baseline for the relevant operating system.</p> <p>To reset the AWS predefined patch baseline as the default, specify the full patch baseline ARN as the baseline ID value. For example, for CentOS, specify <code>arn:aws:ssm:us-east-2:733109147000:patchbaseline/pb-0574b43a65ea646ed</code> instead of <code>pb-0574b43a65ea646ed</code>.</p>
  ##   body: JObject (required)
  var body_774654 = newJObject()
  if body != nil:
    body_774654 = body
  result = call_774653.call(nil, nil, nil, nil, body_774654)

var registerDefaultPatchBaseline* = Call_RegisterDefaultPatchBaseline_774640(
    name: "registerDefaultPatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.RegisterDefaultPatchBaseline",
    validator: validate_RegisterDefaultPatchBaseline_774641, base: "/",
    url: url_RegisterDefaultPatchBaseline_774642,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterPatchBaselineForPatchGroup_774655 = ref object of OpenApiRestCall_772597
proc url_RegisterPatchBaselineForPatchGroup_774657(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RegisterPatchBaselineForPatchGroup_774656(path: JsonNode;
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
  var valid_774658 = header.getOrDefault("X-Amz-Date")
  valid_774658 = validateParameter(valid_774658, JString, required = false,
                                 default = nil)
  if valid_774658 != nil:
    section.add "X-Amz-Date", valid_774658
  var valid_774659 = header.getOrDefault("X-Amz-Security-Token")
  valid_774659 = validateParameter(valid_774659, JString, required = false,
                                 default = nil)
  if valid_774659 != nil:
    section.add "X-Amz-Security-Token", valid_774659
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774660 = header.getOrDefault("X-Amz-Target")
  valid_774660 = validateParameter(valid_774660, JString, required = true, default = newJString(
      "AmazonSSM.RegisterPatchBaselineForPatchGroup"))
  if valid_774660 != nil:
    section.add "X-Amz-Target", valid_774660
  var valid_774661 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774661 = validateParameter(valid_774661, JString, required = false,
                                 default = nil)
  if valid_774661 != nil:
    section.add "X-Amz-Content-Sha256", valid_774661
  var valid_774662 = header.getOrDefault("X-Amz-Algorithm")
  valid_774662 = validateParameter(valid_774662, JString, required = false,
                                 default = nil)
  if valid_774662 != nil:
    section.add "X-Amz-Algorithm", valid_774662
  var valid_774663 = header.getOrDefault("X-Amz-Signature")
  valid_774663 = validateParameter(valid_774663, JString, required = false,
                                 default = nil)
  if valid_774663 != nil:
    section.add "X-Amz-Signature", valid_774663
  var valid_774664 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774664 = validateParameter(valid_774664, JString, required = false,
                                 default = nil)
  if valid_774664 != nil:
    section.add "X-Amz-SignedHeaders", valid_774664
  var valid_774665 = header.getOrDefault("X-Amz-Credential")
  valid_774665 = validateParameter(valid_774665, JString, required = false,
                                 default = nil)
  if valid_774665 != nil:
    section.add "X-Amz-Credential", valid_774665
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774667: Call_RegisterPatchBaselineForPatchGroup_774655;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Registers a patch baseline for a patch group.
  ## 
  let valid = call_774667.validator(path, query, header, formData, body)
  let scheme = call_774667.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774667.url(scheme.get, call_774667.host, call_774667.base,
                         call_774667.route, valid.getOrDefault("path"))
  result = hook(call_774667, url, valid)

proc call*(call_774668: Call_RegisterPatchBaselineForPatchGroup_774655;
          body: JsonNode): Recallable =
  ## registerPatchBaselineForPatchGroup
  ## Registers a patch baseline for a patch group.
  ##   body: JObject (required)
  var body_774669 = newJObject()
  if body != nil:
    body_774669 = body
  result = call_774668.call(nil, nil, nil, nil, body_774669)

var registerPatchBaselineForPatchGroup* = Call_RegisterPatchBaselineForPatchGroup_774655(
    name: "registerPatchBaselineForPatchGroup", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.RegisterPatchBaselineForPatchGroup",
    validator: validate_RegisterPatchBaselineForPatchGroup_774656, base: "/",
    url: url_RegisterPatchBaselineForPatchGroup_774657,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterTargetWithMaintenanceWindow_774670 = ref object of OpenApiRestCall_772597
proc url_RegisterTargetWithMaintenanceWindow_774672(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RegisterTargetWithMaintenanceWindow_774671(path: JsonNode;
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
  var valid_774673 = header.getOrDefault("X-Amz-Date")
  valid_774673 = validateParameter(valid_774673, JString, required = false,
                                 default = nil)
  if valid_774673 != nil:
    section.add "X-Amz-Date", valid_774673
  var valid_774674 = header.getOrDefault("X-Amz-Security-Token")
  valid_774674 = validateParameter(valid_774674, JString, required = false,
                                 default = nil)
  if valid_774674 != nil:
    section.add "X-Amz-Security-Token", valid_774674
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774675 = header.getOrDefault("X-Amz-Target")
  valid_774675 = validateParameter(valid_774675, JString, required = true, default = newJString(
      "AmazonSSM.RegisterTargetWithMaintenanceWindow"))
  if valid_774675 != nil:
    section.add "X-Amz-Target", valid_774675
  var valid_774676 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774676 = validateParameter(valid_774676, JString, required = false,
                                 default = nil)
  if valid_774676 != nil:
    section.add "X-Amz-Content-Sha256", valid_774676
  var valid_774677 = header.getOrDefault("X-Amz-Algorithm")
  valid_774677 = validateParameter(valid_774677, JString, required = false,
                                 default = nil)
  if valid_774677 != nil:
    section.add "X-Amz-Algorithm", valid_774677
  var valid_774678 = header.getOrDefault("X-Amz-Signature")
  valid_774678 = validateParameter(valid_774678, JString, required = false,
                                 default = nil)
  if valid_774678 != nil:
    section.add "X-Amz-Signature", valid_774678
  var valid_774679 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774679 = validateParameter(valid_774679, JString, required = false,
                                 default = nil)
  if valid_774679 != nil:
    section.add "X-Amz-SignedHeaders", valid_774679
  var valid_774680 = header.getOrDefault("X-Amz-Credential")
  valid_774680 = validateParameter(valid_774680, JString, required = false,
                                 default = nil)
  if valid_774680 != nil:
    section.add "X-Amz-Credential", valid_774680
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774682: Call_RegisterTargetWithMaintenanceWindow_774670;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Registers a target with a maintenance window.
  ## 
  let valid = call_774682.validator(path, query, header, formData, body)
  let scheme = call_774682.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774682.url(scheme.get, call_774682.host, call_774682.base,
                         call_774682.route, valid.getOrDefault("path"))
  result = hook(call_774682, url, valid)

proc call*(call_774683: Call_RegisterTargetWithMaintenanceWindow_774670;
          body: JsonNode): Recallable =
  ## registerTargetWithMaintenanceWindow
  ## Registers a target with a maintenance window.
  ##   body: JObject (required)
  var body_774684 = newJObject()
  if body != nil:
    body_774684 = body
  result = call_774683.call(nil, nil, nil, nil, body_774684)

var registerTargetWithMaintenanceWindow* = Call_RegisterTargetWithMaintenanceWindow_774670(
    name: "registerTargetWithMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.RegisterTargetWithMaintenanceWindow",
    validator: validate_RegisterTargetWithMaintenanceWindow_774671, base: "/",
    url: url_RegisterTargetWithMaintenanceWindow_774672,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterTaskWithMaintenanceWindow_774685 = ref object of OpenApiRestCall_772597
proc url_RegisterTaskWithMaintenanceWindow_774687(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RegisterTaskWithMaintenanceWindow_774686(path: JsonNode;
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
  var valid_774688 = header.getOrDefault("X-Amz-Date")
  valid_774688 = validateParameter(valid_774688, JString, required = false,
                                 default = nil)
  if valid_774688 != nil:
    section.add "X-Amz-Date", valid_774688
  var valid_774689 = header.getOrDefault("X-Amz-Security-Token")
  valid_774689 = validateParameter(valid_774689, JString, required = false,
                                 default = nil)
  if valid_774689 != nil:
    section.add "X-Amz-Security-Token", valid_774689
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774690 = header.getOrDefault("X-Amz-Target")
  valid_774690 = validateParameter(valid_774690, JString, required = true, default = newJString(
      "AmazonSSM.RegisterTaskWithMaintenanceWindow"))
  if valid_774690 != nil:
    section.add "X-Amz-Target", valid_774690
  var valid_774691 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774691 = validateParameter(valid_774691, JString, required = false,
                                 default = nil)
  if valid_774691 != nil:
    section.add "X-Amz-Content-Sha256", valid_774691
  var valid_774692 = header.getOrDefault("X-Amz-Algorithm")
  valid_774692 = validateParameter(valid_774692, JString, required = false,
                                 default = nil)
  if valid_774692 != nil:
    section.add "X-Amz-Algorithm", valid_774692
  var valid_774693 = header.getOrDefault("X-Amz-Signature")
  valid_774693 = validateParameter(valid_774693, JString, required = false,
                                 default = nil)
  if valid_774693 != nil:
    section.add "X-Amz-Signature", valid_774693
  var valid_774694 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774694 = validateParameter(valid_774694, JString, required = false,
                                 default = nil)
  if valid_774694 != nil:
    section.add "X-Amz-SignedHeaders", valid_774694
  var valid_774695 = header.getOrDefault("X-Amz-Credential")
  valid_774695 = validateParameter(valid_774695, JString, required = false,
                                 default = nil)
  if valid_774695 != nil:
    section.add "X-Amz-Credential", valid_774695
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774697: Call_RegisterTaskWithMaintenanceWindow_774685;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Adds a new task to a maintenance window.
  ## 
  let valid = call_774697.validator(path, query, header, formData, body)
  let scheme = call_774697.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774697.url(scheme.get, call_774697.host, call_774697.base,
                         call_774697.route, valid.getOrDefault("path"))
  result = hook(call_774697, url, valid)

proc call*(call_774698: Call_RegisterTaskWithMaintenanceWindow_774685;
          body: JsonNode): Recallable =
  ## registerTaskWithMaintenanceWindow
  ## Adds a new task to a maintenance window.
  ##   body: JObject (required)
  var body_774699 = newJObject()
  if body != nil:
    body_774699 = body
  result = call_774698.call(nil, nil, nil, nil, body_774699)

var registerTaskWithMaintenanceWindow* = Call_RegisterTaskWithMaintenanceWindow_774685(
    name: "registerTaskWithMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.RegisterTaskWithMaintenanceWindow",
    validator: validate_RegisterTaskWithMaintenanceWindow_774686, base: "/",
    url: url_RegisterTaskWithMaintenanceWindow_774687,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveTagsFromResource_774700 = ref object of OpenApiRestCall_772597
proc url_RemoveTagsFromResource_774702(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RemoveTagsFromResource_774701(path: JsonNode; query: JsonNode;
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
  var valid_774703 = header.getOrDefault("X-Amz-Date")
  valid_774703 = validateParameter(valid_774703, JString, required = false,
                                 default = nil)
  if valid_774703 != nil:
    section.add "X-Amz-Date", valid_774703
  var valid_774704 = header.getOrDefault("X-Amz-Security-Token")
  valid_774704 = validateParameter(valid_774704, JString, required = false,
                                 default = nil)
  if valid_774704 != nil:
    section.add "X-Amz-Security-Token", valid_774704
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774705 = header.getOrDefault("X-Amz-Target")
  valid_774705 = validateParameter(valid_774705, JString, required = true, default = newJString(
      "AmazonSSM.RemoveTagsFromResource"))
  if valid_774705 != nil:
    section.add "X-Amz-Target", valid_774705
  var valid_774706 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774706 = validateParameter(valid_774706, JString, required = false,
                                 default = nil)
  if valid_774706 != nil:
    section.add "X-Amz-Content-Sha256", valid_774706
  var valid_774707 = header.getOrDefault("X-Amz-Algorithm")
  valid_774707 = validateParameter(valid_774707, JString, required = false,
                                 default = nil)
  if valid_774707 != nil:
    section.add "X-Amz-Algorithm", valid_774707
  var valid_774708 = header.getOrDefault("X-Amz-Signature")
  valid_774708 = validateParameter(valid_774708, JString, required = false,
                                 default = nil)
  if valid_774708 != nil:
    section.add "X-Amz-Signature", valid_774708
  var valid_774709 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774709 = validateParameter(valid_774709, JString, required = false,
                                 default = nil)
  if valid_774709 != nil:
    section.add "X-Amz-SignedHeaders", valid_774709
  var valid_774710 = header.getOrDefault("X-Amz-Credential")
  valid_774710 = validateParameter(valid_774710, JString, required = false,
                                 default = nil)
  if valid_774710 != nil:
    section.add "X-Amz-Credential", valid_774710
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774712: Call_RemoveTagsFromResource_774700; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tag keys from the specified resource.
  ## 
  let valid = call_774712.validator(path, query, header, formData, body)
  let scheme = call_774712.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774712.url(scheme.get, call_774712.host, call_774712.base,
                         call_774712.route, valid.getOrDefault("path"))
  result = hook(call_774712, url, valid)

proc call*(call_774713: Call_RemoveTagsFromResource_774700; body: JsonNode): Recallable =
  ## removeTagsFromResource
  ## Removes tag keys from the specified resource.
  ##   body: JObject (required)
  var body_774714 = newJObject()
  if body != nil:
    body_774714 = body
  result = call_774713.call(nil, nil, nil, nil, body_774714)

var removeTagsFromResource* = Call_RemoveTagsFromResource_774700(
    name: "removeTagsFromResource", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.RemoveTagsFromResource",
    validator: validate_RemoveTagsFromResource_774701, base: "/",
    url: url_RemoveTagsFromResource_774702, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResetServiceSetting_774715 = ref object of OpenApiRestCall_772597
proc url_ResetServiceSetting_774717(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ResetServiceSetting_774716(path: JsonNode; query: JsonNode;
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
  var valid_774718 = header.getOrDefault("X-Amz-Date")
  valid_774718 = validateParameter(valid_774718, JString, required = false,
                                 default = nil)
  if valid_774718 != nil:
    section.add "X-Amz-Date", valid_774718
  var valid_774719 = header.getOrDefault("X-Amz-Security-Token")
  valid_774719 = validateParameter(valid_774719, JString, required = false,
                                 default = nil)
  if valid_774719 != nil:
    section.add "X-Amz-Security-Token", valid_774719
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774720 = header.getOrDefault("X-Amz-Target")
  valid_774720 = validateParameter(valid_774720, JString, required = true, default = newJString(
      "AmazonSSM.ResetServiceSetting"))
  if valid_774720 != nil:
    section.add "X-Amz-Target", valid_774720
  var valid_774721 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774721 = validateParameter(valid_774721, JString, required = false,
                                 default = nil)
  if valid_774721 != nil:
    section.add "X-Amz-Content-Sha256", valid_774721
  var valid_774722 = header.getOrDefault("X-Amz-Algorithm")
  valid_774722 = validateParameter(valid_774722, JString, required = false,
                                 default = nil)
  if valid_774722 != nil:
    section.add "X-Amz-Algorithm", valid_774722
  var valid_774723 = header.getOrDefault("X-Amz-Signature")
  valid_774723 = validateParameter(valid_774723, JString, required = false,
                                 default = nil)
  if valid_774723 != nil:
    section.add "X-Amz-Signature", valid_774723
  var valid_774724 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774724 = validateParameter(valid_774724, JString, required = false,
                                 default = nil)
  if valid_774724 != nil:
    section.add "X-Amz-SignedHeaders", valid_774724
  var valid_774725 = header.getOrDefault("X-Amz-Credential")
  valid_774725 = validateParameter(valid_774725, JString, required = false,
                                 default = nil)
  if valid_774725 != nil:
    section.add "X-Amz-Credential", valid_774725
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774727: Call_ResetServiceSetting_774715; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>GetServiceSetting</a> API action to view the current value. Use the <a>UpdateServiceSetting</a> API action to change the default setting. </p> <p>Reset the service setting for the account to the default value as provisioned by the AWS service team. </p>
  ## 
  let valid = call_774727.validator(path, query, header, formData, body)
  let scheme = call_774727.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774727.url(scheme.get, call_774727.host, call_774727.base,
                         call_774727.route, valid.getOrDefault("path"))
  result = hook(call_774727, url, valid)

proc call*(call_774728: Call_ResetServiceSetting_774715; body: JsonNode): Recallable =
  ## resetServiceSetting
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>GetServiceSetting</a> API action to view the current value. Use the <a>UpdateServiceSetting</a> API action to change the default setting. </p> <p>Reset the service setting for the account to the default value as provisioned by the AWS service team. </p>
  ##   body: JObject (required)
  var body_774729 = newJObject()
  if body != nil:
    body_774729 = body
  result = call_774728.call(nil, nil, nil, nil, body_774729)

var resetServiceSetting* = Call_ResetServiceSetting_774715(
    name: "resetServiceSetting", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ResetServiceSetting",
    validator: validate_ResetServiceSetting_774716, base: "/",
    url: url_ResetServiceSetting_774717, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResumeSession_774730 = ref object of OpenApiRestCall_772597
proc url_ResumeSession_774732(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ResumeSession_774731(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774733 = header.getOrDefault("X-Amz-Date")
  valid_774733 = validateParameter(valid_774733, JString, required = false,
                                 default = nil)
  if valid_774733 != nil:
    section.add "X-Amz-Date", valid_774733
  var valid_774734 = header.getOrDefault("X-Amz-Security-Token")
  valid_774734 = validateParameter(valid_774734, JString, required = false,
                                 default = nil)
  if valid_774734 != nil:
    section.add "X-Amz-Security-Token", valid_774734
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774735 = header.getOrDefault("X-Amz-Target")
  valid_774735 = validateParameter(valid_774735, JString, required = true, default = newJString(
      "AmazonSSM.ResumeSession"))
  if valid_774735 != nil:
    section.add "X-Amz-Target", valid_774735
  var valid_774736 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774736 = validateParameter(valid_774736, JString, required = false,
                                 default = nil)
  if valid_774736 != nil:
    section.add "X-Amz-Content-Sha256", valid_774736
  var valid_774737 = header.getOrDefault("X-Amz-Algorithm")
  valid_774737 = validateParameter(valid_774737, JString, required = false,
                                 default = nil)
  if valid_774737 != nil:
    section.add "X-Amz-Algorithm", valid_774737
  var valid_774738 = header.getOrDefault("X-Amz-Signature")
  valid_774738 = validateParameter(valid_774738, JString, required = false,
                                 default = nil)
  if valid_774738 != nil:
    section.add "X-Amz-Signature", valid_774738
  var valid_774739 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774739 = validateParameter(valid_774739, JString, required = false,
                                 default = nil)
  if valid_774739 != nil:
    section.add "X-Amz-SignedHeaders", valid_774739
  var valid_774740 = header.getOrDefault("X-Amz-Credential")
  valid_774740 = validateParameter(valid_774740, JString, required = false,
                                 default = nil)
  if valid_774740 != nil:
    section.add "X-Amz-Credential", valid_774740
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774742: Call_ResumeSession_774730; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Reconnects a session to an instance after it has been disconnected. Connections can be resumed for disconnected sessions, but not terminated sessions.</p> <note> <p>This command is primarily for use by client machines to automatically reconnect during intermittent network issues. It is not intended for any other use.</p> </note>
  ## 
  let valid = call_774742.validator(path, query, header, formData, body)
  let scheme = call_774742.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774742.url(scheme.get, call_774742.host, call_774742.base,
                         call_774742.route, valid.getOrDefault("path"))
  result = hook(call_774742, url, valid)

proc call*(call_774743: Call_ResumeSession_774730; body: JsonNode): Recallable =
  ## resumeSession
  ## <p>Reconnects a session to an instance after it has been disconnected. Connections can be resumed for disconnected sessions, but not terminated sessions.</p> <note> <p>This command is primarily for use by client machines to automatically reconnect during intermittent network issues. It is not intended for any other use.</p> </note>
  ##   body: JObject (required)
  var body_774744 = newJObject()
  if body != nil:
    body_774744 = body
  result = call_774743.call(nil, nil, nil, nil, body_774744)

var resumeSession* = Call_ResumeSession_774730(name: "resumeSession",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ResumeSession",
    validator: validate_ResumeSession_774731, base: "/", url: url_ResumeSession_774732,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendAutomationSignal_774745 = ref object of OpenApiRestCall_772597
proc url_SendAutomationSignal_774747(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_SendAutomationSignal_774746(path: JsonNode; query: JsonNode;
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
  var valid_774748 = header.getOrDefault("X-Amz-Date")
  valid_774748 = validateParameter(valid_774748, JString, required = false,
                                 default = nil)
  if valid_774748 != nil:
    section.add "X-Amz-Date", valid_774748
  var valid_774749 = header.getOrDefault("X-Amz-Security-Token")
  valid_774749 = validateParameter(valid_774749, JString, required = false,
                                 default = nil)
  if valid_774749 != nil:
    section.add "X-Amz-Security-Token", valid_774749
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774750 = header.getOrDefault("X-Amz-Target")
  valid_774750 = validateParameter(valid_774750, JString, required = true, default = newJString(
      "AmazonSSM.SendAutomationSignal"))
  if valid_774750 != nil:
    section.add "X-Amz-Target", valid_774750
  var valid_774751 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774751 = validateParameter(valid_774751, JString, required = false,
                                 default = nil)
  if valid_774751 != nil:
    section.add "X-Amz-Content-Sha256", valid_774751
  var valid_774752 = header.getOrDefault("X-Amz-Algorithm")
  valid_774752 = validateParameter(valid_774752, JString, required = false,
                                 default = nil)
  if valid_774752 != nil:
    section.add "X-Amz-Algorithm", valid_774752
  var valid_774753 = header.getOrDefault("X-Amz-Signature")
  valid_774753 = validateParameter(valid_774753, JString, required = false,
                                 default = nil)
  if valid_774753 != nil:
    section.add "X-Amz-Signature", valid_774753
  var valid_774754 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774754 = validateParameter(valid_774754, JString, required = false,
                                 default = nil)
  if valid_774754 != nil:
    section.add "X-Amz-SignedHeaders", valid_774754
  var valid_774755 = header.getOrDefault("X-Amz-Credential")
  valid_774755 = validateParameter(valid_774755, JString, required = false,
                                 default = nil)
  if valid_774755 != nil:
    section.add "X-Amz-Credential", valid_774755
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774757: Call_SendAutomationSignal_774745; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sends a signal to an Automation execution to change the current behavior or status of the execution. 
  ## 
  let valid = call_774757.validator(path, query, header, formData, body)
  let scheme = call_774757.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774757.url(scheme.get, call_774757.host, call_774757.base,
                         call_774757.route, valid.getOrDefault("path"))
  result = hook(call_774757, url, valid)

proc call*(call_774758: Call_SendAutomationSignal_774745; body: JsonNode): Recallable =
  ## sendAutomationSignal
  ## Sends a signal to an Automation execution to change the current behavior or status of the execution. 
  ##   body: JObject (required)
  var body_774759 = newJObject()
  if body != nil:
    body_774759 = body
  result = call_774758.call(nil, nil, nil, nil, body_774759)

var sendAutomationSignal* = Call_SendAutomationSignal_774745(
    name: "sendAutomationSignal", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.SendAutomationSignal",
    validator: validate_SendAutomationSignal_774746, base: "/",
    url: url_SendAutomationSignal_774747, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendCommand_774760 = ref object of OpenApiRestCall_772597
proc url_SendCommand_774762(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_SendCommand_774761(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774763 = header.getOrDefault("X-Amz-Date")
  valid_774763 = validateParameter(valid_774763, JString, required = false,
                                 default = nil)
  if valid_774763 != nil:
    section.add "X-Amz-Date", valid_774763
  var valid_774764 = header.getOrDefault("X-Amz-Security-Token")
  valid_774764 = validateParameter(valid_774764, JString, required = false,
                                 default = nil)
  if valid_774764 != nil:
    section.add "X-Amz-Security-Token", valid_774764
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774765 = header.getOrDefault("X-Amz-Target")
  valid_774765 = validateParameter(valid_774765, JString, required = true,
                                 default = newJString("AmazonSSM.SendCommand"))
  if valid_774765 != nil:
    section.add "X-Amz-Target", valid_774765
  var valid_774766 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774766 = validateParameter(valid_774766, JString, required = false,
                                 default = nil)
  if valid_774766 != nil:
    section.add "X-Amz-Content-Sha256", valid_774766
  var valid_774767 = header.getOrDefault("X-Amz-Algorithm")
  valid_774767 = validateParameter(valid_774767, JString, required = false,
                                 default = nil)
  if valid_774767 != nil:
    section.add "X-Amz-Algorithm", valid_774767
  var valid_774768 = header.getOrDefault("X-Amz-Signature")
  valid_774768 = validateParameter(valid_774768, JString, required = false,
                                 default = nil)
  if valid_774768 != nil:
    section.add "X-Amz-Signature", valid_774768
  var valid_774769 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774769 = validateParameter(valid_774769, JString, required = false,
                                 default = nil)
  if valid_774769 != nil:
    section.add "X-Amz-SignedHeaders", valid_774769
  var valid_774770 = header.getOrDefault("X-Amz-Credential")
  valid_774770 = validateParameter(valid_774770, JString, required = false,
                                 default = nil)
  if valid_774770 != nil:
    section.add "X-Amz-Credential", valid_774770
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774772: Call_SendCommand_774760; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Runs commands on one or more managed instances.
  ## 
  let valid = call_774772.validator(path, query, header, formData, body)
  let scheme = call_774772.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774772.url(scheme.get, call_774772.host, call_774772.base,
                         call_774772.route, valid.getOrDefault("path"))
  result = hook(call_774772, url, valid)

proc call*(call_774773: Call_SendCommand_774760; body: JsonNode): Recallable =
  ## sendCommand
  ## Runs commands on one or more managed instances.
  ##   body: JObject (required)
  var body_774774 = newJObject()
  if body != nil:
    body_774774 = body
  result = call_774773.call(nil, nil, nil, nil, body_774774)

var sendCommand* = Call_SendCommand_774760(name: "sendCommand",
                                        meth: HttpMethod.HttpPost,
                                        host: "ssm.amazonaws.com", route: "/#X-Amz-Target=AmazonSSM.SendCommand",
                                        validator: validate_SendCommand_774761,
                                        base: "/", url: url_SendCommand_774762,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartAssociationsOnce_774775 = ref object of OpenApiRestCall_772597
proc url_StartAssociationsOnce_774777(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StartAssociationsOnce_774776(path: JsonNode; query: JsonNode;
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
  var valid_774778 = header.getOrDefault("X-Amz-Date")
  valid_774778 = validateParameter(valid_774778, JString, required = false,
                                 default = nil)
  if valid_774778 != nil:
    section.add "X-Amz-Date", valid_774778
  var valid_774779 = header.getOrDefault("X-Amz-Security-Token")
  valid_774779 = validateParameter(valid_774779, JString, required = false,
                                 default = nil)
  if valid_774779 != nil:
    section.add "X-Amz-Security-Token", valid_774779
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774780 = header.getOrDefault("X-Amz-Target")
  valid_774780 = validateParameter(valid_774780, JString, required = true, default = newJString(
      "AmazonSSM.StartAssociationsOnce"))
  if valid_774780 != nil:
    section.add "X-Amz-Target", valid_774780
  var valid_774781 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774781 = validateParameter(valid_774781, JString, required = false,
                                 default = nil)
  if valid_774781 != nil:
    section.add "X-Amz-Content-Sha256", valid_774781
  var valid_774782 = header.getOrDefault("X-Amz-Algorithm")
  valid_774782 = validateParameter(valid_774782, JString, required = false,
                                 default = nil)
  if valid_774782 != nil:
    section.add "X-Amz-Algorithm", valid_774782
  var valid_774783 = header.getOrDefault("X-Amz-Signature")
  valid_774783 = validateParameter(valid_774783, JString, required = false,
                                 default = nil)
  if valid_774783 != nil:
    section.add "X-Amz-Signature", valid_774783
  var valid_774784 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774784 = validateParameter(valid_774784, JString, required = false,
                                 default = nil)
  if valid_774784 != nil:
    section.add "X-Amz-SignedHeaders", valid_774784
  var valid_774785 = header.getOrDefault("X-Amz-Credential")
  valid_774785 = validateParameter(valid_774785, JString, required = false,
                                 default = nil)
  if valid_774785 != nil:
    section.add "X-Amz-Credential", valid_774785
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774787: Call_StartAssociationsOnce_774775; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Use this API action to run an association immediately and only one time. This action can be helpful when troubleshooting associations.
  ## 
  let valid = call_774787.validator(path, query, header, formData, body)
  let scheme = call_774787.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774787.url(scheme.get, call_774787.host, call_774787.base,
                         call_774787.route, valid.getOrDefault("path"))
  result = hook(call_774787, url, valid)

proc call*(call_774788: Call_StartAssociationsOnce_774775; body: JsonNode): Recallable =
  ## startAssociationsOnce
  ## Use this API action to run an association immediately and only one time. This action can be helpful when troubleshooting associations.
  ##   body: JObject (required)
  var body_774789 = newJObject()
  if body != nil:
    body_774789 = body
  result = call_774788.call(nil, nil, nil, nil, body_774789)

var startAssociationsOnce* = Call_StartAssociationsOnce_774775(
    name: "startAssociationsOnce", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.StartAssociationsOnce",
    validator: validate_StartAssociationsOnce_774776, base: "/",
    url: url_StartAssociationsOnce_774777, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartAutomationExecution_774790 = ref object of OpenApiRestCall_772597
proc url_StartAutomationExecution_774792(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StartAutomationExecution_774791(path: JsonNode; query: JsonNode;
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
  var valid_774793 = header.getOrDefault("X-Amz-Date")
  valid_774793 = validateParameter(valid_774793, JString, required = false,
                                 default = nil)
  if valid_774793 != nil:
    section.add "X-Amz-Date", valid_774793
  var valid_774794 = header.getOrDefault("X-Amz-Security-Token")
  valid_774794 = validateParameter(valid_774794, JString, required = false,
                                 default = nil)
  if valid_774794 != nil:
    section.add "X-Amz-Security-Token", valid_774794
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774795 = header.getOrDefault("X-Amz-Target")
  valid_774795 = validateParameter(valid_774795, JString, required = true, default = newJString(
      "AmazonSSM.StartAutomationExecution"))
  if valid_774795 != nil:
    section.add "X-Amz-Target", valid_774795
  var valid_774796 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774796 = validateParameter(valid_774796, JString, required = false,
                                 default = nil)
  if valid_774796 != nil:
    section.add "X-Amz-Content-Sha256", valid_774796
  var valid_774797 = header.getOrDefault("X-Amz-Algorithm")
  valid_774797 = validateParameter(valid_774797, JString, required = false,
                                 default = nil)
  if valid_774797 != nil:
    section.add "X-Amz-Algorithm", valid_774797
  var valid_774798 = header.getOrDefault("X-Amz-Signature")
  valid_774798 = validateParameter(valid_774798, JString, required = false,
                                 default = nil)
  if valid_774798 != nil:
    section.add "X-Amz-Signature", valid_774798
  var valid_774799 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774799 = validateParameter(valid_774799, JString, required = false,
                                 default = nil)
  if valid_774799 != nil:
    section.add "X-Amz-SignedHeaders", valid_774799
  var valid_774800 = header.getOrDefault("X-Amz-Credential")
  valid_774800 = validateParameter(valid_774800, JString, required = false,
                                 default = nil)
  if valid_774800 != nil:
    section.add "X-Amz-Credential", valid_774800
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774802: Call_StartAutomationExecution_774790; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Initiates execution of an Automation document.
  ## 
  let valid = call_774802.validator(path, query, header, formData, body)
  let scheme = call_774802.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774802.url(scheme.get, call_774802.host, call_774802.base,
                         call_774802.route, valid.getOrDefault("path"))
  result = hook(call_774802, url, valid)

proc call*(call_774803: Call_StartAutomationExecution_774790; body: JsonNode): Recallable =
  ## startAutomationExecution
  ## Initiates execution of an Automation document.
  ##   body: JObject (required)
  var body_774804 = newJObject()
  if body != nil:
    body_774804 = body
  result = call_774803.call(nil, nil, nil, nil, body_774804)

var startAutomationExecution* = Call_StartAutomationExecution_774790(
    name: "startAutomationExecution", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.StartAutomationExecution",
    validator: validate_StartAutomationExecution_774791, base: "/",
    url: url_StartAutomationExecution_774792, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartSession_774805 = ref object of OpenApiRestCall_772597
proc url_StartSession_774807(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StartSession_774806(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774808 = header.getOrDefault("X-Amz-Date")
  valid_774808 = validateParameter(valid_774808, JString, required = false,
                                 default = nil)
  if valid_774808 != nil:
    section.add "X-Amz-Date", valid_774808
  var valid_774809 = header.getOrDefault("X-Amz-Security-Token")
  valid_774809 = validateParameter(valid_774809, JString, required = false,
                                 default = nil)
  if valid_774809 != nil:
    section.add "X-Amz-Security-Token", valid_774809
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774810 = header.getOrDefault("X-Amz-Target")
  valid_774810 = validateParameter(valid_774810, JString, required = true,
                                 default = newJString("AmazonSSM.StartSession"))
  if valid_774810 != nil:
    section.add "X-Amz-Target", valid_774810
  var valid_774811 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774811 = validateParameter(valid_774811, JString, required = false,
                                 default = nil)
  if valid_774811 != nil:
    section.add "X-Amz-Content-Sha256", valid_774811
  var valid_774812 = header.getOrDefault("X-Amz-Algorithm")
  valid_774812 = validateParameter(valid_774812, JString, required = false,
                                 default = nil)
  if valid_774812 != nil:
    section.add "X-Amz-Algorithm", valid_774812
  var valid_774813 = header.getOrDefault("X-Amz-Signature")
  valid_774813 = validateParameter(valid_774813, JString, required = false,
                                 default = nil)
  if valid_774813 != nil:
    section.add "X-Amz-Signature", valid_774813
  var valid_774814 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774814 = validateParameter(valid_774814, JString, required = false,
                                 default = nil)
  if valid_774814 != nil:
    section.add "X-Amz-SignedHeaders", valid_774814
  var valid_774815 = header.getOrDefault("X-Amz-Credential")
  valid_774815 = validateParameter(valid_774815, JString, required = false,
                                 default = nil)
  if valid_774815 != nil:
    section.add "X-Amz-Credential", valid_774815
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774817: Call_StartSession_774805; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates a connection to a target (for example, an instance) for a Session Manager session. Returns a URL and token that can be used to open a WebSocket connection for sending input and receiving outputs.</p> <note> <p>AWS CLI usage: <code>start-session</code> is an interactive command that requires the Session Manager plugin to be installed on the client machine making the call. For information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html"> Install the Session Manager Plugin for the AWS CLI</a> in the <i>AWS Systems Manager User Guide</i>.</p> </note>
  ## 
  let valid = call_774817.validator(path, query, header, formData, body)
  let scheme = call_774817.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774817.url(scheme.get, call_774817.host, call_774817.base,
                         call_774817.route, valid.getOrDefault("path"))
  result = hook(call_774817, url, valid)

proc call*(call_774818: Call_StartSession_774805; body: JsonNode): Recallable =
  ## startSession
  ## <p>Initiates a connection to a target (for example, an instance) for a Session Manager session. Returns a URL and token that can be used to open a WebSocket connection for sending input and receiving outputs.</p> <note> <p>AWS CLI usage: <code>start-session</code> is an interactive command that requires the Session Manager plugin to be installed on the client machine making the call. For information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html"> Install the Session Manager Plugin for the AWS CLI</a> in the <i>AWS Systems Manager User Guide</i>.</p> </note>
  ##   body: JObject (required)
  var body_774819 = newJObject()
  if body != nil:
    body_774819 = body
  result = call_774818.call(nil, nil, nil, nil, body_774819)

var startSession* = Call_StartSession_774805(name: "startSession",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.StartSession",
    validator: validate_StartSession_774806, base: "/", url: url_StartSession_774807,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopAutomationExecution_774820 = ref object of OpenApiRestCall_772597
proc url_StopAutomationExecution_774822(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StopAutomationExecution_774821(path: JsonNode; query: JsonNode;
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
  var valid_774823 = header.getOrDefault("X-Amz-Date")
  valid_774823 = validateParameter(valid_774823, JString, required = false,
                                 default = nil)
  if valid_774823 != nil:
    section.add "X-Amz-Date", valid_774823
  var valid_774824 = header.getOrDefault("X-Amz-Security-Token")
  valid_774824 = validateParameter(valid_774824, JString, required = false,
                                 default = nil)
  if valid_774824 != nil:
    section.add "X-Amz-Security-Token", valid_774824
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774825 = header.getOrDefault("X-Amz-Target")
  valid_774825 = validateParameter(valid_774825, JString, required = true, default = newJString(
      "AmazonSSM.StopAutomationExecution"))
  if valid_774825 != nil:
    section.add "X-Amz-Target", valid_774825
  var valid_774826 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774826 = validateParameter(valid_774826, JString, required = false,
                                 default = nil)
  if valid_774826 != nil:
    section.add "X-Amz-Content-Sha256", valid_774826
  var valid_774827 = header.getOrDefault("X-Amz-Algorithm")
  valid_774827 = validateParameter(valid_774827, JString, required = false,
                                 default = nil)
  if valid_774827 != nil:
    section.add "X-Amz-Algorithm", valid_774827
  var valid_774828 = header.getOrDefault("X-Amz-Signature")
  valid_774828 = validateParameter(valid_774828, JString, required = false,
                                 default = nil)
  if valid_774828 != nil:
    section.add "X-Amz-Signature", valid_774828
  var valid_774829 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774829 = validateParameter(valid_774829, JString, required = false,
                                 default = nil)
  if valid_774829 != nil:
    section.add "X-Amz-SignedHeaders", valid_774829
  var valid_774830 = header.getOrDefault("X-Amz-Credential")
  valid_774830 = validateParameter(valid_774830, JString, required = false,
                                 default = nil)
  if valid_774830 != nil:
    section.add "X-Amz-Credential", valid_774830
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774832: Call_StopAutomationExecution_774820; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stop an Automation that is currently running.
  ## 
  let valid = call_774832.validator(path, query, header, formData, body)
  let scheme = call_774832.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774832.url(scheme.get, call_774832.host, call_774832.base,
                         call_774832.route, valid.getOrDefault("path"))
  result = hook(call_774832, url, valid)

proc call*(call_774833: Call_StopAutomationExecution_774820; body: JsonNode): Recallable =
  ## stopAutomationExecution
  ## Stop an Automation that is currently running.
  ##   body: JObject (required)
  var body_774834 = newJObject()
  if body != nil:
    body_774834 = body
  result = call_774833.call(nil, nil, nil, nil, body_774834)

var stopAutomationExecution* = Call_StopAutomationExecution_774820(
    name: "stopAutomationExecution", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.StopAutomationExecution",
    validator: validate_StopAutomationExecution_774821, base: "/",
    url: url_StopAutomationExecution_774822, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TerminateSession_774835 = ref object of OpenApiRestCall_772597
proc url_TerminateSession_774837(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_TerminateSession_774836(path: JsonNode; query: JsonNode;
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
  var valid_774838 = header.getOrDefault("X-Amz-Date")
  valid_774838 = validateParameter(valid_774838, JString, required = false,
                                 default = nil)
  if valid_774838 != nil:
    section.add "X-Amz-Date", valid_774838
  var valid_774839 = header.getOrDefault("X-Amz-Security-Token")
  valid_774839 = validateParameter(valid_774839, JString, required = false,
                                 default = nil)
  if valid_774839 != nil:
    section.add "X-Amz-Security-Token", valid_774839
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774840 = header.getOrDefault("X-Amz-Target")
  valid_774840 = validateParameter(valid_774840, JString, required = true, default = newJString(
      "AmazonSSM.TerminateSession"))
  if valid_774840 != nil:
    section.add "X-Amz-Target", valid_774840
  var valid_774841 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774841 = validateParameter(valid_774841, JString, required = false,
                                 default = nil)
  if valid_774841 != nil:
    section.add "X-Amz-Content-Sha256", valid_774841
  var valid_774842 = header.getOrDefault("X-Amz-Algorithm")
  valid_774842 = validateParameter(valid_774842, JString, required = false,
                                 default = nil)
  if valid_774842 != nil:
    section.add "X-Amz-Algorithm", valid_774842
  var valid_774843 = header.getOrDefault("X-Amz-Signature")
  valid_774843 = validateParameter(valid_774843, JString, required = false,
                                 default = nil)
  if valid_774843 != nil:
    section.add "X-Amz-Signature", valid_774843
  var valid_774844 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774844 = validateParameter(valid_774844, JString, required = false,
                                 default = nil)
  if valid_774844 != nil:
    section.add "X-Amz-SignedHeaders", valid_774844
  var valid_774845 = header.getOrDefault("X-Amz-Credential")
  valid_774845 = validateParameter(valid_774845, JString, required = false,
                                 default = nil)
  if valid_774845 != nil:
    section.add "X-Amz-Credential", valid_774845
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774847: Call_TerminateSession_774835; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently ends a session and closes the data connection between the Session Manager client and SSM Agent on the instance. A terminated session cannot be resumed.
  ## 
  let valid = call_774847.validator(path, query, header, formData, body)
  let scheme = call_774847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774847.url(scheme.get, call_774847.host, call_774847.base,
                         call_774847.route, valid.getOrDefault("path"))
  result = hook(call_774847, url, valid)

proc call*(call_774848: Call_TerminateSession_774835; body: JsonNode): Recallable =
  ## terminateSession
  ## Permanently ends a session and closes the data connection between the Session Manager client and SSM Agent on the instance. A terminated session cannot be resumed.
  ##   body: JObject (required)
  var body_774849 = newJObject()
  if body != nil:
    body_774849 = body
  result = call_774848.call(nil, nil, nil, nil, body_774849)

var terminateSession* = Call_TerminateSession_774835(name: "terminateSession",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.TerminateSession",
    validator: validate_TerminateSession_774836, base: "/",
    url: url_TerminateSession_774837, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAssociation_774850 = ref object of OpenApiRestCall_772597
proc url_UpdateAssociation_774852(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateAssociation_774851(path: JsonNode; query: JsonNode;
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
  var valid_774853 = header.getOrDefault("X-Amz-Date")
  valid_774853 = validateParameter(valid_774853, JString, required = false,
                                 default = nil)
  if valid_774853 != nil:
    section.add "X-Amz-Date", valid_774853
  var valid_774854 = header.getOrDefault("X-Amz-Security-Token")
  valid_774854 = validateParameter(valid_774854, JString, required = false,
                                 default = nil)
  if valid_774854 != nil:
    section.add "X-Amz-Security-Token", valid_774854
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774855 = header.getOrDefault("X-Amz-Target")
  valid_774855 = validateParameter(valid_774855, JString, required = true, default = newJString(
      "AmazonSSM.UpdateAssociation"))
  if valid_774855 != nil:
    section.add "X-Amz-Target", valid_774855
  var valid_774856 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774856 = validateParameter(valid_774856, JString, required = false,
                                 default = nil)
  if valid_774856 != nil:
    section.add "X-Amz-Content-Sha256", valid_774856
  var valid_774857 = header.getOrDefault("X-Amz-Algorithm")
  valid_774857 = validateParameter(valid_774857, JString, required = false,
                                 default = nil)
  if valid_774857 != nil:
    section.add "X-Amz-Algorithm", valid_774857
  var valid_774858 = header.getOrDefault("X-Amz-Signature")
  valid_774858 = validateParameter(valid_774858, JString, required = false,
                                 default = nil)
  if valid_774858 != nil:
    section.add "X-Amz-Signature", valid_774858
  var valid_774859 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774859 = validateParameter(valid_774859, JString, required = false,
                                 default = nil)
  if valid_774859 != nil:
    section.add "X-Amz-SignedHeaders", valid_774859
  var valid_774860 = header.getOrDefault("X-Amz-Credential")
  valid_774860 = validateParameter(valid_774860, JString, required = false,
                                 default = nil)
  if valid_774860 != nil:
    section.add "X-Amz-Credential", valid_774860
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774862: Call_UpdateAssociation_774850; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an association. You can update the association name and version, the document version, schedule, parameters, and Amazon S3 output.</p> <important> <p>When you update an association, the association immediately runs against the specified targets.</p> </important>
  ## 
  let valid = call_774862.validator(path, query, header, formData, body)
  let scheme = call_774862.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774862.url(scheme.get, call_774862.host, call_774862.base,
                         call_774862.route, valid.getOrDefault("path"))
  result = hook(call_774862, url, valid)

proc call*(call_774863: Call_UpdateAssociation_774850; body: JsonNode): Recallable =
  ## updateAssociation
  ## <p>Updates an association. You can update the association name and version, the document version, schedule, parameters, and Amazon S3 output.</p> <important> <p>When you update an association, the association immediately runs against the specified targets.</p> </important>
  ##   body: JObject (required)
  var body_774864 = newJObject()
  if body != nil:
    body_774864 = body
  result = call_774863.call(nil, nil, nil, nil, body_774864)

var updateAssociation* = Call_UpdateAssociation_774850(name: "updateAssociation",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateAssociation",
    validator: validate_UpdateAssociation_774851, base: "/",
    url: url_UpdateAssociation_774852, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAssociationStatus_774865 = ref object of OpenApiRestCall_772597
proc url_UpdateAssociationStatus_774867(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateAssociationStatus_774866(path: JsonNode; query: JsonNode;
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
  var valid_774868 = header.getOrDefault("X-Amz-Date")
  valid_774868 = validateParameter(valid_774868, JString, required = false,
                                 default = nil)
  if valid_774868 != nil:
    section.add "X-Amz-Date", valid_774868
  var valid_774869 = header.getOrDefault("X-Amz-Security-Token")
  valid_774869 = validateParameter(valid_774869, JString, required = false,
                                 default = nil)
  if valid_774869 != nil:
    section.add "X-Amz-Security-Token", valid_774869
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774870 = header.getOrDefault("X-Amz-Target")
  valid_774870 = validateParameter(valid_774870, JString, required = true, default = newJString(
      "AmazonSSM.UpdateAssociationStatus"))
  if valid_774870 != nil:
    section.add "X-Amz-Target", valid_774870
  var valid_774871 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774871 = validateParameter(valid_774871, JString, required = false,
                                 default = nil)
  if valid_774871 != nil:
    section.add "X-Amz-Content-Sha256", valid_774871
  var valid_774872 = header.getOrDefault("X-Amz-Algorithm")
  valid_774872 = validateParameter(valid_774872, JString, required = false,
                                 default = nil)
  if valid_774872 != nil:
    section.add "X-Amz-Algorithm", valid_774872
  var valid_774873 = header.getOrDefault("X-Amz-Signature")
  valid_774873 = validateParameter(valid_774873, JString, required = false,
                                 default = nil)
  if valid_774873 != nil:
    section.add "X-Amz-Signature", valid_774873
  var valid_774874 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774874 = validateParameter(valid_774874, JString, required = false,
                                 default = nil)
  if valid_774874 != nil:
    section.add "X-Amz-SignedHeaders", valid_774874
  var valid_774875 = header.getOrDefault("X-Amz-Credential")
  valid_774875 = validateParameter(valid_774875, JString, required = false,
                                 default = nil)
  if valid_774875 != nil:
    section.add "X-Amz-Credential", valid_774875
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774877: Call_UpdateAssociationStatus_774865; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the status of the Systems Manager document associated with the specified instance.
  ## 
  let valid = call_774877.validator(path, query, header, formData, body)
  let scheme = call_774877.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774877.url(scheme.get, call_774877.host, call_774877.base,
                         call_774877.route, valid.getOrDefault("path"))
  result = hook(call_774877, url, valid)

proc call*(call_774878: Call_UpdateAssociationStatus_774865; body: JsonNode): Recallable =
  ## updateAssociationStatus
  ## Updates the status of the Systems Manager document associated with the specified instance.
  ##   body: JObject (required)
  var body_774879 = newJObject()
  if body != nil:
    body_774879 = body
  result = call_774878.call(nil, nil, nil, nil, body_774879)

var updateAssociationStatus* = Call_UpdateAssociationStatus_774865(
    name: "updateAssociationStatus", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateAssociationStatus",
    validator: validate_UpdateAssociationStatus_774866, base: "/",
    url: url_UpdateAssociationStatus_774867, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocument_774880 = ref object of OpenApiRestCall_772597
proc url_UpdateDocument_774882(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateDocument_774881(path: JsonNode; query: JsonNode;
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
  var valid_774883 = header.getOrDefault("X-Amz-Date")
  valid_774883 = validateParameter(valid_774883, JString, required = false,
                                 default = nil)
  if valid_774883 != nil:
    section.add "X-Amz-Date", valid_774883
  var valid_774884 = header.getOrDefault("X-Amz-Security-Token")
  valid_774884 = validateParameter(valid_774884, JString, required = false,
                                 default = nil)
  if valid_774884 != nil:
    section.add "X-Amz-Security-Token", valid_774884
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774885 = header.getOrDefault("X-Amz-Target")
  valid_774885 = validateParameter(valid_774885, JString, required = true, default = newJString(
      "AmazonSSM.UpdateDocument"))
  if valid_774885 != nil:
    section.add "X-Amz-Target", valid_774885
  var valid_774886 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774886 = validateParameter(valid_774886, JString, required = false,
                                 default = nil)
  if valid_774886 != nil:
    section.add "X-Amz-Content-Sha256", valid_774886
  var valid_774887 = header.getOrDefault("X-Amz-Algorithm")
  valid_774887 = validateParameter(valid_774887, JString, required = false,
                                 default = nil)
  if valid_774887 != nil:
    section.add "X-Amz-Algorithm", valid_774887
  var valid_774888 = header.getOrDefault("X-Amz-Signature")
  valid_774888 = validateParameter(valid_774888, JString, required = false,
                                 default = nil)
  if valid_774888 != nil:
    section.add "X-Amz-Signature", valid_774888
  var valid_774889 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774889 = validateParameter(valid_774889, JString, required = false,
                                 default = nil)
  if valid_774889 != nil:
    section.add "X-Amz-SignedHeaders", valid_774889
  var valid_774890 = header.getOrDefault("X-Amz-Credential")
  valid_774890 = validateParameter(valid_774890, JString, required = false,
                                 default = nil)
  if valid_774890 != nil:
    section.add "X-Amz-Credential", valid_774890
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774892: Call_UpdateDocument_774880; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates one or more values for an SSM document.
  ## 
  let valid = call_774892.validator(path, query, header, formData, body)
  let scheme = call_774892.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774892.url(scheme.get, call_774892.host, call_774892.base,
                         call_774892.route, valid.getOrDefault("path"))
  result = hook(call_774892, url, valid)

proc call*(call_774893: Call_UpdateDocument_774880; body: JsonNode): Recallable =
  ## updateDocument
  ## Updates one or more values for an SSM document.
  ##   body: JObject (required)
  var body_774894 = newJObject()
  if body != nil:
    body_774894 = body
  result = call_774893.call(nil, nil, nil, nil, body_774894)

var updateDocument* = Call_UpdateDocument_774880(name: "updateDocument",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateDocument",
    validator: validate_UpdateDocument_774881, base: "/", url: url_UpdateDocument_774882,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocumentDefaultVersion_774895 = ref object of OpenApiRestCall_772597
proc url_UpdateDocumentDefaultVersion_774897(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateDocumentDefaultVersion_774896(path: JsonNode; query: JsonNode;
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
  var valid_774898 = header.getOrDefault("X-Amz-Date")
  valid_774898 = validateParameter(valid_774898, JString, required = false,
                                 default = nil)
  if valid_774898 != nil:
    section.add "X-Amz-Date", valid_774898
  var valid_774899 = header.getOrDefault("X-Amz-Security-Token")
  valid_774899 = validateParameter(valid_774899, JString, required = false,
                                 default = nil)
  if valid_774899 != nil:
    section.add "X-Amz-Security-Token", valid_774899
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774900 = header.getOrDefault("X-Amz-Target")
  valid_774900 = validateParameter(valid_774900, JString, required = true, default = newJString(
      "AmazonSSM.UpdateDocumentDefaultVersion"))
  if valid_774900 != nil:
    section.add "X-Amz-Target", valid_774900
  var valid_774901 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774901 = validateParameter(valid_774901, JString, required = false,
                                 default = nil)
  if valid_774901 != nil:
    section.add "X-Amz-Content-Sha256", valid_774901
  var valid_774902 = header.getOrDefault("X-Amz-Algorithm")
  valid_774902 = validateParameter(valid_774902, JString, required = false,
                                 default = nil)
  if valid_774902 != nil:
    section.add "X-Amz-Algorithm", valid_774902
  var valid_774903 = header.getOrDefault("X-Amz-Signature")
  valid_774903 = validateParameter(valid_774903, JString, required = false,
                                 default = nil)
  if valid_774903 != nil:
    section.add "X-Amz-Signature", valid_774903
  var valid_774904 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774904 = validateParameter(valid_774904, JString, required = false,
                                 default = nil)
  if valid_774904 != nil:
    section.add "X-Amz-SignedHeaders", valid_774904
  var valid_774905 = header.getOrDefault("X-Amz-Credential")
  valid_774905 = validateParameter(valid_774905, JString, required = false,
                                 default = nil)
  if valid_774905 != nil:
    section.add "X-Amz-Credential", valid_774905
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774907: Call_UpdateDocumentDefaultVersion_774895; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Set the default version of a document. 
  ## 
  let valid = call_774907.validator(path, query, header, formData, body)
  let scheme = call_774907.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774907.url(scheme.get, call_774907.host, call_774907.base,
                         call_774907.route, valid.getOrDefault("path"))
  result = hook(call_774907, url, valid)

proc call*(call_774908: Call_UpdateDocumentDefaultVersion_774895; body: JsonNode): Recallable =
  ## updateDocumentDefaultVersion
  ## Set the default version of a document. 
  ##   body: JObject (required)
  var body_774909 = newJObject()
  if body != nil:
    body_774909 = body
  result = call_774908.call(nil, nil, nil, nil, body_774909)

var updateDocumentDefaultVersion* = Call_UpdateDocumentDefaultVersion_774895(
    name: "updateDocumentDefaultVersion", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateDocumentDefaultVersion",
    validator: validate_UpdateDocumentDefaultVersion_774896, base: "/",
    url: url_UpdateDocumentDefaultVersion_774897,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMaintenanceWindow_774910 = ref object of OpenApiRestCall_772597
proc url_UpdateMaintenanceWindow_774912(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateMaintenanceWindow_774911(path: JsonNode; query: JsonNode;
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
  var valid_774913 = header.getOrDefault("X-Amz-Date")
  valid_774913 = validateParameter(valid_774913, JString, required = false,
                                 default = nil)
  if valid_774913 != nil:
    section.add "X-Amz-Date", valid_774913
  var valid_774914 = header.getOrDefault("X-Amz-Security-Token")
  valid_774914 = validateParameter(valid_774914, JString, required = false,
                                 default = nil)
  if valid_774914 != nil:
    section.add "X-Amz-Security-Token", valid_774914
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774915 = header.getOrDefault("X-Amz-Target")
  valid_774915 = validateParameter(valid_774915, JString, required = true, default = newJString(
      "AmazonSSM.UpdateMaintenanceWindow"))
  if valid_774915 != nil:
    section.add "X-Amz-Target", valid_774915
  var valid_774916 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774916 = validateParameter(valid_774916, JString, required = false,
                                 default = nil)
  if valid_774916 != nil:
    section.add "X-Amz-Content-Sha256", valid_774916
  var valid_774917 = header.getOrDefault("X-Amz-Algorithm")
  valid_774917 = validateParameter(valid_774917, JString, required = false,
                                 default = nil)
  if valid_774917 != nil:
    section.add "X-Amz-Algorithm", valid_774917
  var valid_774918 = header.getOrDefault("X-Amz-Signature")
  valid_774918 = validateParameter(valid_774918, JString, required = false,
                                 default = nil)
  if valid_774918 != nil:
    section.add "X-Amz-Signature", valid_774918
  var valid_774919 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774919 = validateParameter(valid_774919, JString, required = false,
                                 default = nil)
  if valid_774919 != nil:
    section.add "X-Amz-SignedHeaders", valid_774919
  var valid_774920 = header.getOrDefault("X-Amz-Credential")
  valid_774920 = validateParameter(valid_774920, JString, required = false,
                                 default = nil)
  if valid_774920 != nil:
    section.add "X-Amz-Credential", valid_774920
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774922: Call_UpdateMaintenanceWindow_774910; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing maintenance window. Only specified parameters are modified.
  ## 
  let valid = call_774922.validator(path, query, header, formData, body)
  let scheme = call_774922.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774922.url(scheme.get, call_774922.host, call_774922.base,
                         call_774922.route, valid.getOrDefault("path"))
  result = hook(call_774922, url, valid)

proc call*(call_774923: Call_UpdateMaintenanceWindow_774910; body: JsonNode): Recallable =
  ## updateMaintenanceWindow
  ## Updates an existing maintenance window. Only specified parameters are modified.
  ##   body: JObject (required)
  var body_774924 = newJObject()
  if body != nil:
    body_774924 = body
  result = call_774923.call(nil, nil, nil, nil, body_774924)

var updateMaintenanceWindow* = Call_UpdateMaintenanceWindow_774910(
    name: "updateMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateMaintenanceWindow",
    validator: validate_UpdateMaintenanceWindow_774911, base: "/",
    url: url_UpdateMaintenanceWindow_774912, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMaintenanceWindowTarget_774925 = ref object of OpenApiRestCall_772597
proc url_UpdateMaintenanceWindowTarget_774927(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateMaintenanceWindowTarget_774926(path: JsonNode; query: JsonNode;
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
  var valid_774928 = header.getOrDefault("X-Amz-Date")
  valid_774928 = validateParameter(valid_774928, JString, required = false,
                                 default = nil)
  if valid_774928 != nil:
    section.add "X-Amz-Date", valid_774928
  var valid_774929 = header.getOrDefault("X-Amz-Security-Token")
  valid_774929 = validateParameter(valid_774929, JString, required = false,
                                 default = nil)
  if valid_774929 != nil:
    section.add "X-Amz-Security-Token", valid_774929
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774930 = header.getOrDefault("X-Amz-Target")
  valid_774930 = validateParameter(valid_774930, JString, required = true, default = newJString(
      "AmazonSSM.UpdateMaintenanceWindowTarget"))
  if valid_774930 != nil:
    section.add "X-Amz-Target", valid_774930
  var valid_774931 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774931 = validateParameter(valid_774931, JString, required = false,
                                 default = nil)
  if valid_774931 != nil:
    section.add "X-Amz-Content-Sha256", valid_774931
  var valid_774932 = header.getOrDefault("X-Amz-Algorithm")
  valid_774932 = validateParameter(valid_774932, JString, required = false,
                                 default = nil)
  if valid_774932 != nil:
    section.add "X-Amz-Algorithm", valid_774932
  var valid_774933 = header.getOrDefault("X-Amz-Signature")
  valid_774933 = validateParameter(valid_774933, JString, required = false,
                                 default = nil)
  if valid_774933 != nil:
    section.add "X-Amz-Signature", valid_774933
  var valid_774934 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774934 = validateParameter(valid_774934, JString, required = false,
                                 default = nil)
  if valid_774934 != nil:
    section.add "X-Amz-SignedHeaders", valid_774934
  var valid_774935 = header.getOrDefault("X-Amz-Credential")
  valid_774935 = validateParameter(valid_774935, JString, required = false,
                                 default = nil)
  if valid_774935 != nil:
    section.add "X-Amz-Credential", valid_774935
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774937: Call_UpdateMaintenanceWindowTarget_774925; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the target of an existing maintenance window. You can change the following:</p> <ul> <li> <p>Name</p> </li> <li> <p>Description</p> </li> <li> <p>Owner</p> </li> <li> <p>IDs for an ID target</p> </li> <li> <p>Tags for a Tag target</p> </li> <li> <p>From any supported tag type to another. The three supported tag types are ID target, Tag target, and resource group. For more information, see <a>Target</a>.</p> </li> </ul> <note> <p>If a parameter is null, then the corresponding field is not modified.</p> </note>
  ## 
  let valid = call_774937.validator(path, query, header, formData, body)
  let scheme = call_774937.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774937.url(scheme.get, call_774937.host, call_774937.base,
                         call_774937.route, valid.getOrDefault("path"))
  result = hook(call_774937, url, valid)

proc call*(call_774938: Call_UpdateMaintenanceWindowTarget_774925; body: JsonNode): Recallable =
  ## updateMaintenanceWindowTarget
  ## <p>Modifies the target of an existing maintenance window. You can change the following:</p> <ul> <li> <p>Name</p> </li> <li> <p>Description</p> </li> <li> <p>Owner</p> </li> <li> <p>IDs for an ID target</p> </li> <li> <p>Tags for a Tag target</p> </li> <li> <p>From any supported tag type to another. The three supported tag types are ID target, Tag target, and resource group. For more information, see <a>Target</a>.</p> </li> </ul> <note> <p>If a parameter is null, then the corresponding field is not modified.</p> </note>
  ##   body: JObject (required)
  var body_774939 = newJObject()
  if body != nil:
    body_774939 = body
  result = call_774938.call(nil, nil, nil, nil, body_774939)

var updateMaintenanceWindowTarget* = Call_UpdateMaintenanceWindowTarget_774925(
    name: "updateMaintenanceWindowTarget", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateMaintenanceWindowTarget",
    validator: validate_UpdateMaintenanceWindowTarget_774926, base: "/",
    url: url_UpdateMaintenanceWindowTarget_774927,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMaintenanceWindowTask_774940 = ref object of OpenApiRestCall_772597
proc url_UpdateMaintenanceWindowTask_774942(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateMaintenanceWindowTask_774941(path: JsonNode; query: JsonNode;
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
  var valid_774943 = header.getOrDefault("X-Amz-Date")
  valid_774943 = validateParameter(valid_774943, JString, required = false,
                                 default = nil)
  if valid_774943 != nil:
    section.add "X-Amz-Date", valid_774943
  var valid_774944 = header.getOrDefault("X-Amz-Security-Token")
  valid_774944 = validateParameter(valid_774944, JString, required = false,
                                 default = nil)
  if valid_774944 != nil:
    section.add "X-Amz-Security-Token", valid_774944
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774945 = header.getOrDefault("X-Amz-Target")
  valid_774945 = validateParameter(valid_774945, JString, required = true, default = newJString(
      "AmazonSSM.UpdateMaintenanceWindowTask"))
  if valid_774945 != nil:
    section.add "X-Amz-Target", valid_774945
  var valid_774946 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774946 = validateParameter(valid_774946, JString, required = false,
                                 default = nil)
  if valid_774946 != nil:
    section.add "X-Amz-Content-Sha256", valid_774946
  var valid_774947 = header.getOrDefault("X-Amz-Algorithm")
  valid_774947 = validateParameter(valid_774947, JString, required = false,
                                 default = nil)
  if valid_774947 != nil:
    section.add "X-Amz-Algorithm", valid_774947
  var valid_774948 = header.getOrDefault("X-Amz-Signature")
  valid_774948 = validateParameter(valid_774948, JString, required = false,
                                 default = nil)
  if valid_774948 != nil:
    section.add "X-Amz-Signature", valid_774948
  var valid_774949 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774949 = validateParameter(valid_774949, JString, required = false,
                                 default = nil)
  if valid_774949 != nil:
    section.add "X-Amz-SignedHeaders", valid_774949
  var valid_774950 = header.getOrDefault("X-Amz-Credential")
  valid_774950 = validateParameter(valid_774950, JString, required = false,
                                 default = nil)
  if valid_774950 != nil:
    section.add "X-Amz-Credential", valid_774950
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774952: Call_UpdateMaintenanceWindowTask_774940; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies a task assigned to a maintenance window. You can't change the task type, but you can change the following values:</p> <ul> <li> <p>TaskARN. For example, you can change a RUN_COMMAND task from AWS-RunPowerShellScript to AWS-RunShellScript.</p> </li> <li> <p>ServiceRoleArn</p> </li> <li> <p>TaskInvocationParameters</p> </li> <li> <p>Priority</p> </li> <li> <p>MaxConcurrency</p> </li> <li> <p>MaxErrors</p> </li> </ul> <p>If a parameter is null, then the corresponding field is not modified. Also, if you set Replace to true, then all fields required by the <a>RegisterTaskWithMaintenanceWindow</a> action are required for this request. Optional fields that aren't specified are set to null.</p>
  ## 
  let valid = call_774952.validator(path, query, header, formData, body)
  let scheme = call_774952.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774952.url(scheme.get, call_774952.host, call_774952.base,
                         call_774952.route, valid.getOrDefault("path"))
  result = hook(call_774952, url, valid)

proc call*(call_774953: Call_UpdateMaintenanceWindowTask_774940; body: JsonNode): Recallable =
  ## updateMaintenanceWindowTask
  ## <p>Modifies a task assigned to a maintenance window. You can't change the task type, but you can change the following values:</p> <ul> <li> <p>TaskARN. For example, you can change a RUN_COMMAND task from AWS-RunPowerShellScript to AWS-RunShellScript.</p> </li> <li> <p>ServiceRoleArn</p> </li> <li> <p>TaskInvocationParameters</p> </li> <li> <p>Priority</p> </li> <li> <p>MaxConcurrency</p> </li> <li> <p>MaxErrors</p> </li> </ul> <p>If a parameter is null, then the corresponding field is not modified. Also, if you set Replace to true, then all fields required by the <a>RegisterTaskWithMaintenanceWindow</a> action are required for this request. Optional fields that aren't specified are set to null.</p>
  ##   body: JObject (required)
  var body_774954 = newJObject()
  if body != nil:
    body_774954 = body
  result = call_774953.call(nil, nil, nil, nil, body_774954)

var updateMaintenanceWindowTask* = Call_UpdateMaintenanceWindowTask_774940(
    name: "updateMaintenanceWindowTask", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateMaintenanceWindowTask",
    validator: validate_UpdateMaintenanceWindowTask_774941, base: "/",
    url: url_UpdateMaintenanceWindowTask_774942,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateManagedInstanceRole_774955 = ref object of OpenApiRestCall_772597
proc url_UpdateManagedInstanceRole_774957(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateManagedInstanceRole_774956(path: JsonNode; query: JsonNode;
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
  var valid_774958 = header.getOrDefault("X-Amz-Date")
  valid_774958 = validateParameter(valid_774958, JString, required = false,
                                 default = nil)
  if valid_774958 != nil:
    section.add "X-Amz-Date", valid_774958
  var valid_774959 = header.getOrDefault("X-Amz-Security-Token")
  valid_774959 = validateParameter(valid_774959, JString, required = false,
                                 default = nil)
  if valid_774959 != nil:
    section.add "X-Amz-Security-Token", valid_774959
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774960 = header.getOrDefault("X-Amz-Target")
  valid_774960 = validateParameter(valid_774960, JString, required = true, default = newJString(
      "AmazonSSM.UpdateManagedInstanceRole"))
  if valid_774960 != nil:
    section.add "X-Amz-Target", valid_774960
  var valid_774961 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774961 = validateParameter(valid_774961, JString, required = false,
                                 default = nil)
  if valid_774961 != nil:
    section.add "X-Amz-Content-Sha256", valid_774961
  var valid_774962 = header.getOrDefault("X-Amz-Algorithm")
  valid_774962 = validateParameter(valid_774962, JString, required = false,
                                 default = nil)
  if valid_774962 != nil:
    section.add "X-Amz-Algorithm", valid_774962
  var valid_774963 = header.getOrDefault("X-Amz-Signature")
  valid_774963 = validateParameter(valid_774963, JString, required = false,
                                 default = nil)
  if valid_774963 != nil:
    section.add "X-Amz-Signature", valid_774963
  var valid_774964 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774964 = validateParameter(valid_774964, JString, required = false,
                                 default = nil)
  if valid_774964 != nil:
    section.add "X-Amz-SignedHeaders", valid_774964
  var valid_774965 = header.getOrDefault("X-Amz-Credential")
  valid_774965 = validateParameter(valid_774965, JString, required = false,
                                 default = nil)
  if valid_774965 != nil:
    section.add "X-Amz-Credential", valid_774965
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774967: Call_UpdateManagedInstanceRole_774955; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Assigns or changes an Amazon Identity and Access Management (IAM) role for the managed instance.
  ## 
  let valid = call_774967.validator(path, query, header, formData, body)
  let scheme = call_774967.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774967.url(scheme.get, call_774967.host, call_774967.base,
                         call_774967.route, valid.getOrDefault("path"))
  result = hook(call_774967, url, valid)

proc call*(call_774968: Call_UpdateManagedInstanceRole_774955; body: JsonNode): Recallable =
  ## updateManagedInstanceRole
  ## Assigns or changes an Amazon Identity and Access Management (IAM) role for the managed instance.
  ##   body: JObject (required)
  var body_774969 = newJObject()
  if body != nil:
    body_774969 = body
  result = call_774968.call(nil, nil, nil, nil, body_774969)

var updateManagedInstanceRole* = Call_UpdateManagedInstanceRole_774955(
    name: "updateManagedInstanceRole", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateManagedInstanceRole",
    validator: validate_UpdateManagedInstanceRole_774956, base: "/",
    url: url_UpdateManagedInstanceRole_774957,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateOpsItem_774970 = ref object of OpenApiRestCall_772597
proc url_UpdateOpsItem_774972(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateOpsItem_774971(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774973 = header.getOrDefault("X-Amz-Date")
  valid_774973 = validateParameter(valid_774973, JString, required = false,
                                 default = nil)
  if valid_774973 != nil:
    section.add "X-Amz-Date", valid_774973
  var valid_774974 = header.getOrDefault("X-Amz-Security-Token")
  valid_774974 = validateParameter(valid_774974, JString, required = false,
                                 default = nil)
  if valid_774974 != nil:
    section.add "X-Amz-Security-Token", valid_774974
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774975 = header.getOrDefault("X-Amz-Target")
  valid_774975 = validateParameter(valid_774975, JString, required = true, default = newJString(
      "AmazonSSM.UpdateOpsItem"))
  if valid_774975 != nil:
    section.add "X-Amz-Target", valid_774975
  var valid_774976 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774976 = validateParameter(valid_774976, JString, required = false,
                                 default = nil)
  if valid_774976 != nil:
    section.add "X-Amz-Content-Sha256", valid_774976
  var valid_774977 = header.getOrDefault("X-Amz-Algorithm")
  valid_774977 = validateParameter(valid_774977, JString, required = false,
                                 default = nil)
  if valid_774977 != nil:
    section.add "X-Amz-Algorithm", valid_774977
  var valid_774978 = header.getOrDefault("X-Amz-Signature")
  valid_774978 = validateParameter(valid_774978, JString, required = false,
                                 default = nil)
  if valid_774978 != nil:
    section.add "X-Amz-Signature", valid_774978
  var valid_774979 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774979 = validateParameter(valid_774979, JString, required = false,
                                 default = nil)
  if valid_774979 != nil:
    section.add "X-Amz-SignedHeaders", valid_774979
  var valid_774980 = header.getOrDefault("X-Amz-Credential")
  valid_774980 = validateParameter(valid_774980, JString, required = false,
                                 default = nil)
  if valid_774980 != nil:
    section.add "X-Amz-Credential", valid_774980
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774982: Call_UpdateOpsItem_774970; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Edit or change an OpsItem. You must have permission in AWS Identity and Access Management (IAM) to update an OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ## 
  let valid = call_774982.validator(path, query, header, formData, body)
  let scheme = call_774982.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774982.url(scheme.get, call_774982.host, call_774982.base,
                         call_774982.route, valid.getOrDefault("path"))
  result = hook(call_774982, url, valid)

proc call*(call_774983: Call_UpdateOpsItem_774970; body: JsonNode): Recallable =
  ## updateOpsItem
  ## <p>Edit or change an OpsItem. You must have permission in AWS Identity and Access Management (IAM) to update an OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ##   body: JObject (required)
  var body_774984 = newJObject()
  if body != nil:
    body_774984 = body
  result = call_774983.call(nil, nil, nil, nil, body_774984)

var updateOpsItem* = Call_UpdateOpsItem_774970(name: "updateOpsItem",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateOpsItem",
    validator: validate_UpdateOpsItem_774971, base: "/", url: url_UpdateOpsItem_774972,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePatchBaseline_774985 = ref object of OpenApiRestCall_772597
proc url_UpdatePatchBaseline_774987(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdatePatchBaseline_774986(path: JsonNode; query: JsonNode;
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
  var valid_774988 = header.getOrDefault("X-Amz-Date")
  valid_774988 = validateParameter(valid_774988, JString, required = false,
                                 default = nil)
  if valid_774988 != nil:
    section.add "X-Amz-Date", valid_774988
  var valid_774989 = header.getOrDefault("X-Amz-Security-Token")
  valid_774989 = validateParameter(valid_774989, JString, required = false,
                                 default = nil)
  if valid_774989 != nil:
    section.add "X-Amz-Security-Token", valid_774989
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774990 = header.getOrDefault("X-Amz-Target")
  valid_774990 = validateParameter(valid_774990, JString, required = true, default = newJString(
      "AmazonSSM.UpdatePatchBaseline"))
  if valid_774990 != nil:
    section.add "X-Amz-Target", valid_774990
  var valid_774991 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774991 = validateParameter(valid_774991, JString, required = false,
                                 default = nil)
  if valid_774991 != nil:
    section.add "X-Amz-Content-Sha256", valid_774991
  var valid_774992 = header.getOrDefault("X-Amz-Algorithm")
  valid_774992 = validateParameter(valid_774992, JString, required = false,
                                 default = nil)
  if valid_774992 != nil:
    section.add "X-Amz-Algorithm", valid_774992
  var valid_774993 = header.getOrDefault("X-Amz-Signature")
  valid_774993 = validateParameter(valid_774993, JString, required = false,
                                 default = nil)
  if valid_774993 != nil:
    section.add "X-Amz-Signature", valid_774993
  var valid_774994 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774994 = validateParameter(valid_774994, JString, required = false,
                                 default = nil)
  if valid_774994 != nil:
    section.add "X-Amz-SignedHeaders", valid_774994
  var valid_774995 = header.getOrDefault("X-Amz-Credential")
  valid_774995 = validateParameter(valid_774995, JString, required = false,
                                 default = nil)
  if valid_774995 != nil:
    section.add "X-Amz-Credential", valid_774995
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774997: Call_UpdatePatchBaseline_774985; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies an existing patch baseline. Fields not specified in the request are left unchanged.</p> <note> <p>For information about valid key and value pairs in <code>PatchFilters</code> for each supported operating system type, see <a href="http://docs.aws.amazon.com/systems-manager/latest/APIReference/API_PatchFilter.html">PatchFilter</a>.</p> </note>
  ## 
  let valid = call_774997.validator(path, query, header, formData, body)
  let scheme = call_774997.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774997.url(scheme.get, call_774997.host, call_774997.base,
                         call_774997.route, valid.getOrDefault("path"))
  result = hook(call_774997, url, valid)

proc call*(call_774998: Call_UpdatePatchBaseline_774985; body: JsonNode): Recallable =
  ## updatePatchBaseline
  ## <p>Modifies an existing patch baseline. Fields not specified in the request are left unchanged.</p> <note> <p>For information about valid key and value pairs in <code>PatchFilters</code> for each supported operating system type, see <a href="http://docs.aws.amazon.com/systems-manager/latest/APIReference/API_PatchFilter.html">PatchFilter</a>.</p> </note>
  ##   body: JObject (required)
  var body_774999 = newJObject()
  if body != nil:
    body_774999 = body
  result = call_774998.call(nil, nil, nil, nil, body_774999)

var updatePatchBaseline* = Call_UpdatePatchBaseline_774985(
    name: "updatePatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdatePatchBaseline",
    validator: validate_UpdatePatchBaseline_774986, base: "/",
    url: url_UpdatePatchBaseline_774987, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateServiceSetting_775000 = ref object of OpenApiRestCall_772597
proc url_UpdateServiceSetting_775002(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateServiceSetting_775001(path: JsonNode; query: JsonNode;
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
  var valid_775003 = header.getOrDefault("X-Amz-Date")
  valid_775003 = validateParameter(valid_775003, JString, required = false,
                                 default = nil)
  if valid_775003 != nil:
    section.add "X-Amz-Date", valid_775003
  var valid_775004 = header.getOrDefault("X-Amz-Security-Token")
  valid_775004 = validateParameter(valid_775004, JString, required = false,
                                 default = nil)
  if valid_775004 != nil:
    section.add "X-Amz-Security-Token", valid_775004
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_775005 = header.getOrDefault("X-Amz-Target")
  valid_775005 = validateParameter(valid_775005, JString, required = true, default = newJString(
      "AmazonSSM.UpdateServiceSetting"))
  if valid_775005 != nil:
    section.add "X-Amz-Target", valid_775005
  var valid_775006 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775006 = validateParameter(valid_775006, JString, required = false,
                                 default = nil)
  if valid_775006 != nil:
    section.add "X-Amz-Content-Sha256", valid_775006
  var valid_775007 = header.getOrDefault("X-Amz-Algorithm")
  valid_775007 = validateParameter(valid_775007, JString, required = false,
                                 default = nil)
  if valid_775007 != nil:
    section.add "X-Amz-Algorithm", valid_775007
  var valid_775008 = header.getOrDefault("X-Amz-Signature")
  valid_775008 = validateParameter(valid_775008, JString, required = false,
                                 default = nil)
  if valid_775008 != nil:
    section.add "X-Amz-Signature", valid_775008
  var valid_775009 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775009 = validateParameter(valid_775009, JString, required = false,
                                 default = nil)
  if valid_775009 != nil:
    section.add "X-Amz-SignedHeaders", valid_775009
  var valid_775010 = header.getOrDefault("X-Amz-Credential")
  valid_775010 = validateParameter(valid_775010, JString, required = false,
                                 default = nil)
  if valid_775010 != nil:
    section.add "X-Amz-Credential", valid_775010
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_775012: Call_UpdateServiceSetting_775000; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>GetServiceSetting</a> API action to view the current value. Or, use the <a>ResetServiceSetting</a> to change the value back to the original value defined by the AWS service team.</p> <p>Update the service setting for the account. </p>
  ## 
  let valid = call_775012.validator(path, query, header, formData, body)
  let scheme = call_775012.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775012.url(scheme.get, call_775012.host, call_775012.base,
                         call_775012.route, valid.getOrDefault("path"))
  result = hook(call_775012, url, valid)

proc call*(call_775013: Call_UpdateServiceSetting_775000; body: JsonNode): Recallable =
  ## updateServiceSetting
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>GetServiceSetting</a> API action to view the current value. Or, use the <a>ResetServiceSetting</a> to change the value back to the original value defined by the AWS service team.</p> <p>Update the service setting for the account. </p>
  ##   body: JObject (required)
  var body_775014 = newJObject()
  if body != nil:
    body_775014 = body
  result = call_775013.call(nil, nil, nil, nil, body_775014)

var updateServiceSetting* = Call_UpdateServiceSetting_775000(
    name: "updateServiceSetting", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateServiceSetting",
    validator: validate_UpdateServiceSetting_775001, base: "/",
    url: url_UpdateServiceSetting_775002, schemes: {Scheme.Https, Scheme.Http})
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
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
