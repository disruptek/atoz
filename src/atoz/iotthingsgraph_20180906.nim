
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS IoT Things Graph
## version: 2018-09-06
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS IoT Things Graph</fullname> <p>AWS IoT Things Graph provides an integrated set of tools that enable developers to connect devices and services that use different standards, such as units of measure and communication protocols. AWS IoT Things Graph makes it possible to build IoT applications with little to no code by connecting devices and services and defining how they interact at an abstract level.</p> <p>For more information about how AWS IoT Things Graph works, see the <a href="https://docs.aws.amazon.com/thingsgraph/latest/ug/iot-tg-whatis.html">User Guide</a>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/iotthingsgraph/
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

  OpenApiRestCall_605589 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605589](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605589): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "iotthingsgraph.ap-northeast-1.amazonaws.com", "ap-southeast-1": "iotthingsgraph.ap-southeast-1.amazonaws.com", "us-west-2": "iotthingsgraph.us-west-2.amazonaws.com", "eu-west-2": "iotthingsgraph.eu-west-2.amazonaws.com", "ap-northeast-3": "iotthingsgraph.ap-northeast-3.amazonaws.com", "eu-central-1": "iotthingsgraph.eu-central-1.amazonaws.com", "us-east-2": "iotthingsgraph.us-east-2.amazonaws.com", "us-east-1": "iotthingsgraph.us-east-1.amazonaws.com", "cn-northwest-1": "iotthingsgraph.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "iotthingsgraph.ap-south-1.amazonaws.com", "eu-north-1": "iotthingsgraph.eu-north-1.amazonaws.com", "ap-northeast-2": "iotthingsgraph.ap-northeast-2.amazonaws.com", "us-west-1": "iotthingsgraph.us-west-1.amazonaws.com", "us-gov-east-1": "iotthingsgraph.us-gov-east-1.amazonaws.com", "eu-west-3": "iotthingsgraph.eu-west-3.amazonaws.com", "cn-north-1": "iotthingsgraph.cn-north-1.amazonaws.com.cn", "sa-east-1": "iotthingsgraph.sa-east-1.amazonaws.com", "eu-west-1": "iotthingsgraph.eu-west-1.amazonaws.com", "us-gov-west-1": "iotthingsgraph.us-gov-west-1.amazonaws.com", "ap-southeast-2": "iotthingsgraph.ap-southeast-2.amazonaws.com", "ca-central-1": "iotthingsgraph.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "iotthingsgraph.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "iotthingsgraph.ap-southeast-1.amazonaws.com",
      "us-west-2": "iotthingsgraph.us-west-2.amazonaws.com",
      "eu-west-2": "iotthingsgraph.eu-west-2.amazonaws.com",
      "ap-northeast-3": "iotthingsgraph.ap-northeast-3.amazonaws.com",
      "eu-central-1": "iotthingsgraph.eu-central-1.amazonaws.com",
      "us-east-2": "iotthingsgraph.us-east-2.amazonaws.com",
      "us-east-1": "iotthingsgraph.us-east-1.amazonaws.com",
      "cn-northwest-1": "iotthingsgraph.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "iotthingsgraph.ap-south-1.amazonaws.com",
      "eu-north-1": "iotthingsgraph.eu-north-1.amazonaws.com",
      "ap-northeast-2": "iotthingsgraph.ap-northeast-2.amazonaws.com",
      "us-west-1": "iotthingsgraph.us-west-1.amazonaws.com",
      "us-gov-east-1": "iotthingsgraph.us-gov-east-1.amazonaws.com",
      "eu-west-3": "iotthingsgraph.eu-west-3.amazonaws.com",
      "cn-north-1": "iotthingsgraph.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "iotthingsgraph.sa-east-1.amazonaws.com",
      "eu-west-1": "iotthingsgraph.eu-west-1.amazonaws.com",
      "us-gov-west-1": "iotthingsgraph.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "iotthingsgraph.ap-southeast-2.amazonaws.com",
      "ca-central-1": "iotthingsgraph.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "iotthingsgraph"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AssociateEntityToThing_605927 = ref object of OpenApiRestCall_605589
proc url_AssociateEntityToThing_605929(protocol: Scheme; host: string; base: string;
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

proc validate_AssociateEntityToThing_605928(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Associates a device with a concrete thing that is in the user's registry.</p> <p>A thing can be associated with only one device at a time. If you associate a thing with a new device id, its previous association will be removed.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_606054 = header.getOrDefault("X-Amz-Target")
  valid_606054 = validateParameter(valid_606054, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.AssociateEntityToThing"))
  if valid_606054 != nil:
    section.add "X-Amz-Target", valid_606054
  var valid_606055 = header.getOrDefault("X-Amz-Signature")
  valid_606055 = validateParameter(valid_606055, JString, required = false,
                                 default = nil)
  if valid_606055 != nil:
    section.add "X-Amz-Signature", valid_606055
  var valid_606056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606056 = validateParameter(valid_606056, JString, required = false,
                                 default = nil)
  if valid_606056 != nil:
    section.add "X-Amz-Content-Sha256", valid_606056
  var valid_606057 = header.getOrDefault("X-Amz-Date")
  valid_606057 = validateParameter(valid_606057, JString, required = false,
                                 default = nil)
  if valid_606057 != nil:
    section.add "X-Amz-Date", valid_606057
  var valid_606058 = header.getOrDefault("X-Amz-Credential")
  valid_606058 = validateParameter(valid_606058, JString, required = false,
                                 default = nil)
  if valid_606058 != nil:
    section.add "X-Amz-Credential", valid_606058
  var valid_606059 = header.getOrDefault("X-Amz-Security-Token")
  valid_606059 = validateParameter(valid_606059, JString, required = false,
                                 default = nil)
  if valid_606059 != nil:
    section.add "X-Amz-Security-Token", valid_606059
  var valid_606060 = header.getOrDefault("X-Amz-Algorithm")
  valid_606060 = validateParameter(valid_606060, JString, required = false,
                                 default = nil)
  if valid_606060 != nil:
    section.add "X-Amz-Algorithm", valid_606060
  var valid_606061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606061 = validateParameter(valid_606061, JString, required = false,
                                 default = nil)
  if valid_606061 != nil:
    section.add "X-Amz-SignedHeaders", valid_606061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606085: Call_AssociateEntityToThing_605927; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates a device with a concrete thing that is in the user's registry.</p> <p>A thing can be associated with only one device at a time. If you associate a thing with a new device id, its previous association will be removed.</p>
  ## 
  let valid = call_606085.validator(path, query, header, formData, body)
  let scheme = call_606085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606085.url(scheme.get, call_606085.host, call_606085.base,
                         call_606085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606085, url, valid)

proc call*(call_606156: Call_AssociateEntityToThing_605927; body: JsonNode): Recallable =
  ## associateEntityToThing
  ## <p>Associates a device with a concrete thing that is in the user's registry.</p> <p>A thing can be associated with only one device at a time. If you associate a thing with a new device id, its previous association will be removed.</p>
  ##   body: JObject (required)
  var body_606157 = newJObject()
  if body != nil:
    body_606157 = body
  result = call_606156.call(nil, nil, nil, nil, body_606157)

var associateEntityToThing* = Call_AssociateEntityToThing_605927(
    name: "associateEntityToThing", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com", route: "/#X-Amz-Target=IotThingsGraphFrontEndService.AssociateEntityToThing",
    validator: validate_AssociateEntityToThing_605928, base: "/",
    url: url_AssociateEntityToThing_605929, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFlowTemplate_606196 = ref object of OpenApiRestCall_605589
proc url_CreateFlowTemplate_606198(protocol: Scheme; host: string; base: string;
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

proc validate_CreateFlowTemplate_606197(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Creates a workflow template. Workflows can be created only in the user's namespace. (The public namespace contains only entities.) The workflow can contain only entities in the specified namespace. The workflow is validated against the entities in the latest version of the user's namespace unless another namespace version is specified in the request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_606199 = header.getOrDefault("X-Amz-Target")
  valid_606199 = validateParameter(valid_606199, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.CreateFlowTemplate"))
  if valid_606199 != nil:
    section.add "X-Amz-Target", valid_606199
  var valid_606200 = header.getOrDefault("X-Amz-Signature")
  valid_606200 = validateParameter(valid_606200, JString, required = false,
                                 default = nil)
  if valid_606200 != nil:
    section.add "X-Amz-Signature", valid_606200
  var valid_606201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606201 = validateParameter(valid_606201, JString, required = false,
                                 default = nil)
  if valid_606201 != nil:
    section.add "X-Amz-Content-Sha256", valid_606201
  var valid_606202 = header.getOrDefault("X-Amz-Date")
  valid_606202 = validateParameter(valid_606202, JString, required = false,
                                 default = nil)
  if valid_606202 != nil:
    section.add "X-Amz-Date", valid_606202
  var valid_606203 = header.getOrDefault("X-Amz-Credential")
  valid_606203 = validateParameter(valid_606203, JString, required = false,
                                 default = nil)
  if valid_606203 != nil:
    section.add "X-Amz-Credential", valid_606203
  var valid_606204 = header.getOrDefault("X-Amz-Security-Token")
  valid_606204 = validateParameter(valid_606204, JString, required = false,
                                 default = nil)
  if valid_606204 != nil:
    section.add "X-Amz-Security-Token", valid_606204
  var valid_606205 = header.getOrDefault("X-Amz-Algorithm")
  valid_606205 = validateParameter(valid_606205, JString, required = false,
                                 default = nil)
  if valid_606205 != nil:
    section.add "X-Amz-Algorithm", valid_606205
  var valid_606206 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606206 = validateParameter(valid_606206, JString, required = false,
                                 default = nil)
  if valid_606206 != nil:
    section.add "X-Amz-SignedHeaders", valid_606206
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606208: Call_CreateFlowTemplate_606196; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a workflow template. Workflows can be created only in the user's namespace. (The public namespace contains only entities.) The workflow can contain only entities in the specified namespace. The workflow is validated against the entities in the latest version of the user's namespace unless another namespace version is specified in the request.
  ## 
  let valid = call_606208.validator(path, query, header, formData, body)
  let scheme = call_606208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606208.url(scheme.get, call_606208.host, call_606208.base,
                         call_606208.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606208, url, valid)

proc call*(call_606209: Call_CreateFlowTemplate_606196; body: JsonNode): Recallable =
  ## createFlowTemplate
  ## Creates a workflow template. Workflows can be created only in the user's namespace. (The public namespace contains only entities.) The workflow can contain only entities in the specified namespace. The workflow is validated against the entities in the latest version of the user's namespace unless another namespace version is specified in the request.
  ##   body: JObject (required)
  var body_606210 = newJObject()
  if body != nil:
    body_606210 = body
  result = call_606209.call(nil, nil, nil, nil, body_606210)

var createFlowTemplate* = Call_CreateFlowTemplate_606196(
    name: "createFlowTemplate", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.CreateFlowTemplate",
    validator: validate_CreateFlowTemplate_606197, base: "/",
    url: url_CreateFlowTemplate_606198, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSystemInstance_606211 = ref object of OpenApiRestCall_605589
proc url_CreateSystemInstance_606213(protocol: Scheme; host: string; base: string;
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

proc validate_CreateSystemInstance_606212(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a system instance. </p> <p>This action validates the system instance, prepares the deployment-related resources. For Greengrass deployments, it updates the Greengrass group that is specified by the <code>greengrassGroupName</code> parameter. It also adds a file to the S3 bucket specified by the <code>s3BucketName</code> parameter. You need to call <code>DeploySystemInstance</code> after running this action.</p> <p>For Greengrass deployments, since this action modifies and adds resources to a Greengrass group and an S3 bucket on the caller's behalf, the calling identity must have write permissions to both the specified Greengrass group and S3 bucket. Otherwise, the call will fail with an authorization error.</p> <p>For cloud deployments, this action requires a <code>flowActionsRoleArn</code> value. This is an IAM role that has permissions to access AWS services, such as AWS Lambda and AWS IoT, that the flow uses when it executes.</p> <p>If the definition document doesn't specify a version of the user's namespace, the latest version will be used by default.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_606214 = header.getOrDefault("X-Amz-Target")
  valid_606214 = validateParameter(valid_606214, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.CreateSystemInstance"))
  if valid_606214 != nil:
    section.add "X-Amz-Target", valid_606214
  var valid_606215 = header.getOrDefault("X-Amz-Signature")
  valid_606215 = validateParameter(valid_606215, JString, required = false,
                                 default = nil)
  if valid_606215 != nil:
    section.add "X-Amz-Signature", valid_606215
  var valid_606216 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606216 = validateParameter(valid_606216, JString, required = false,
                                 default = nil)
  if valid_606216 != nil:
    section.add "X-Amz-Content-Sha256", valid_606216
  var valid_606217 = header.getOrDefault("X-Amz-Date")
  valid_606217 = validateParameter(valid_606217, JString, required = false,
                                 default = nil)
  if valid_606217 != nil:
    section.add "X-Amz-Date", valid_606217
  var valid_606218 = header.getOrDefault("X-Amz-Credential")
  valid_606218 = validateParameter(valid_606218, JString, required = false,
                                 default = nil)
  if valid_606218 != nil:
    section.add "X-Amz-Credential", valid_606218
  var valid_606219 = header.getOrDefault("X-Amz-Security-Token")
  valid_606219 = validateParameter(valid_606219, JString, required = false,
                                 default = nil)
  if valid_606219 != nil:
    section.add "X-Amz-Security-Token", valid_606219
  var valid_606220 = header.getOrDefault("X-Amz-Algorithm")
  valid_606220 = validateParameter(valid_606220, JString, required = false,
                                 default = nil)
  if valid_606220 != nil:
    section.add "X-Amz-Algorithm", valid_606220
  var valid_606221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606221 = validateParameter(valid_606221, JString, required = false,
                                 default = nil)
  if valid_606221 != nil:
    section.add "X-Amz-SignedHeaders", valid_606221
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606223: Call_CreateSystemInstance_606211; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a system instance. </p> <p>This action validates the system instance, prepares the deployment-related resources. For Greengrass deployments, it updates the Greengrass group that is specified by the <code>greengrassGroupName</code> parameter. It also adds a file to the S3 bucket specified by the <code>s3BucketName</code> parameter. You need to call <code>DeploySystemInstance</code> after running this action.</p> <p>For Greengrass deployments, since this action modifies and adds resources to a Greengrass group and an S3 bucket on the caller's behalf, the calling identity must have write permissions to both the specified Greengrass group and S3 bucket. Otherwise, the call will fail with an authorization error.</p> <p>For cloud deployments, this action requires a <code>flowActionsRoleArn</code> value. This is an IAM role that has permissions to access AWS services, such as AWS Lambda and AWS IoT, that the flow uses when it executes.</p> <p>If the definition document doesn't specify a version of the user's namespace, the latest version will be used by default.</p>
  ## 
  let valid = call_606223.validator(path, query, header, formData, body)
  let scheme = call_606223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606223.url(scheme.get, call_606223.host, call_606223.base,
                         call_606223.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606223, url, valid)

proc call*(call_606224: Call_CreateSystemInstance_606211; body: JsonNode): Recallable =
  ## createSystemInstance
  ## <p>Creates a system instance. </p> <p>This action validates the system instance, prepares the deployment-related resources. For Greengrass deployments, it updates the Greengrass group that is specified by the <code>greengrassGroupName</code> parameter. It also adds a file to the S3 bucket specified by the <code>s3BucketName</code> parameter. You need to call <code>DeploySystemInstance</code> after running this action.</p> <p>For Greengrass deployments, since this action modifies and adds resources to a Greengrass group and an S3 bucket on the caller's behalf, the calling identity must have write permissions to both the specified Greengrass group and S3 bucket. Otherwise, the call will fail with an authorization error.</p> <p>For cloud deployments, this action requires a <code>flowActionsRoleArn</code> value. This is an IAM role that has permissions to access AWS services, such as AWS Lambda and AWS IoT, that the flow uses when it executes.</p> <p>If the definition document doesn't specify a version of the user's namespace, the latest version will be used by default.</p>
  ##   body: JObject (required)
  var body_606225 = newJObject()
  if body != nil:
    body_606225 = body
  result = call_606224.call(nil, nil, nil, nil, body_606225)

var createSystemInstance* = Call_CreateSystemInstance_606211(
    name: "createSystemInstance", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.CreateSystemInstance",
    validator: validate_CreateSystemInstance_606212, base: "/",
    url: url_CreateSystemInstance_606213, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSystemTemplate_606226 = ref object of OpenApiRestCall_605589
proc url_CreateSystemTemplate_606228(protocol: Scheme; host: string; base: string;
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

proc validate_CreateSystemTemplate_606227(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a system. The system is validated against the entities in the latest version of the user's namespace unless another namespace version is specified in the request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_606229 = header.getOrDefault("X-Amz-Target")
  valid_606229 = validateParameter(valid_606229, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.CreateSystemTemplate"))
  if valid_606229 != nil:
    section.add "X-Amz-Target", valid_606229
  var valid_606230 = header.getOrDefault("X-Amz-Signature")
  valid_606230 = validateParameter(valid_606230, JString, required = false,
                                 default = nil)
  if valid_606230 != nil:
    section.add "X-Amz-Signature", valid_606230
  var valid_606231 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606231 = validateParameter(valid_606231, JString, required = false,
                                 default = nil)
  if valid_606231 != nil:
    section.add "X-Amz-Content-Sha256", valid_606231
  var valid_606232 = header.getOrDefault("X-Amz-Date")
  valid_606232 = validateParameter(valid_606232, JString, required = false,
                                 default = nil)
  if valid_606232 != nil:
    section.add "X-Amz-Date", valid_606232
  var valid_606233 = header.getOrDefault("X-Amz-Credential")
  valid_606233 = validateParameter(valid_606233, JString, required = false,
                                 default = nil)
  if valid_606233 != nil:
    section.add "X-Amz-Credential", valid_606233
  var valid_606234 = header.getOrDefault("X-Amz-Security-Token")
  valid_606234 = validateParameter(valid_606234, JString, required = false,
                                 default = nil)
  if valid_606234 != nil:
    section.add "X-Amz-Security-Token", valid_606234
  var valid_606235 = header.getOrDefault("X-Amz-Algorithm")
  valid_606235 = validateParameter(valid_606235, JString, required = false,
                                 default = nil)
  if valid_606235 != nil:
    section.add "X-Amz-Algorithm", valid_606235
  var valid_606236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606236 = validateParameter(valid_606236, JString, required = false,
                                 default = nil)
  if valid_606236 != nil:
    section.add "X-Amz-SignedHeaders", valid_606236
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606238: Call_CreateSystemTemplate_606226; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a system. The system is validated against the entities in the latest version of the user's namespace unless another namespace version is specified in the request.
  ## 
  let valid = call_606238.validator(path, query, header, formData, body)
  let scheme = call_606238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606238.url(scheme.get, call_606238.host, call_606238.base,
                         call_606238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606238, url, valid)

proc call*(call_606239: Call_CreateSystemTemplate_606226; body: JsonNode): Recallable =
  ## createSystemTemplate
  ## Creates a system. The system is validated against the entities in the latest version of the user's namespace unless another namespace version is specified in the request.
  ##   body: JObject (required)
  var body_606240 = newJObject()
  if body != nil:
    body_606240 = body
  result = call_606239.call(nil, nil, nil, nil, body_606240)

var createSystemTemplate* = Call_CreateSystemTemplate_606226(
    name: "createSystemTemplate", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.CreateSystemTemplate",
    validator: validate_CreateSystemTemplate_606227, base: "/",
    url: url_CreateSystemTemplate_606228, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFlowTemplate_606241 = ref object of OpenApiRestCall_605589
proc url_DeleteFlowTemplate_606243(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteFlowTemplate_606242(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Deletes a workflow. Any new system or deployment that contains this workflow will fail to update or deploy. Existing deployments that contain the workflow will continue to run (since they use a snapshot of the workflow taken at the time of deployment).
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_606244 = header.getOrDefault("X-Amz-Target")
  valid_606244 = validateParameter(valid_606244, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.DeleteFlowTemplate"))
  if valid_606244 != nil:
    section.add "X-Amz-Target", valid_606244
  var valid_606245 = header.getOrDefault("X-Amz-Signature")
  valid_606245 = validateParameter(valid_606245, JString, required = false,
                                 default = nil)
  if valid_606245 != nil:
    section.add "X-Amz-Signature", valid_606245
  var valid_606246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606246 = validateParameter(valid_606246, JString, required = false,
                                 default = nil)
  if valid_606246 != nil:
    section.add "X-Amz-Content-Sha256", valid_606246
  var valid_606247 = header.getOrDefault("X-Amz-Date")
  valid_606247 = validateParameter(valid_606247, JString, required = false,
                                 default = nil)
  if valid_606247 != nil:
    section.add "X-Amz-Date", valid_606247
  var valid_606248 = header.getOrDefault("X-Amz-Credential")
  valid_606248 = validateParameter(valid_606248, JString, required = false,
                                 default = nil)
  if valid_606248 != nil:
    section.add "X-Amz-Credential", valid_606248
  var valid_606249 = header.getOrDefault("X-Amz-Security-Token")
  valid_606249 = validateParameter(valid_606249, JString, required = false,
                                 default = nil)
  if valid_606249 != nil:
    section.add "X-Amz-Security-Token", valid_606249
  var valid_606250 = header.getOrDefault("X-Amz-Algorithm")
  valid_606250 = validateParameter(valid_606250, JString, required = false,
                                 default = nil)
  if valid_606250 != nil:
    section.add "X-Amz-Algorithm", valid_606250
  var valid_606251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606251 = validateParameter(valid_606251, JString, required = false,
                                 default = nil)
  if valid_606251 != nil:
    section.add "X-Amz-SignedHeaders", valid_606251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606253: Call_DeleteFlowTemplate_606241; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a workflow. Any new system or deployment that contains this workflow will fail to update or deploy. Existing deployments that contain the workflow will continue to run (since they use a snapshot of the workflow taken at the time of deployment).
  ## 
  let valid = call_606253.validator(path, query, header, formData, body)
  let scheme = call_606253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606253.url(scheme.get, call_606253.host, call_606253.base,
                         call_606253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606253, url, valid)

proc call*(call_606254: Call_DeleteFlowTemplate_606241; body: JsonNode): Recallable =
  ## deleteFlowTemplate
  ## Deletes a workflow. Any new system or deployment that contains this workflow will fail to update or deploy. Existing deployments that contain the workflow will continue to run (since they use a snapshot of the workflow taken at the time of deployment).
  ##   body: JObject (required)
  var body_606255 = newJObject()
  if body != nil:
    body_606255 = body
  result = call_606254.call(nil, nil, nil, nil, body_606255)

var deleteFlowTemplate* = Call_DeleteFlowTemplate_606241(
    name: "deleteFlowTemplate", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.DeleteFlowTemplate",
    validator: validate_DeleteFlowTemplate_606242, base: "/",
    url: url_DeleteFlowTemplate_606243, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNamespace_606256 = ref object of OpenApiRestCall_605589
proc url_DeleteNamespace_606258(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteNamespace_606257(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Deletes the specified namespace. This action deletes all of the entities in the namespace. Delete the systems and flows that use entities in the namespace before performing this action.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_606259 = header.getOrDefault("X-Amz-Target")
  valid_606259 = validateParameter(valid_606259, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.DeleteNamespace"))
  if valid_606259 != nil:
    section.add "X-Amz-Target", valid_606259
  var valid_606260 = header.getOrDefault("X-Amz-Signature")
  valid_606260 = validateParameter(valid_606260, JString, required = false,
                                 default = nil)
  if valid_606260 != nil:
    section.add "X-Amz-Signature", valid_606260
  var valid_606261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606261 = validateParameter(valid_606261, JString, required = false,
                                 default = nil)
  if valid_606261 != nil:
    section.add "X-Amz-Content-Sha256", valid_606261
  var valid_606262 = header.getOrDefault("X-Amz-Date")
  valid_606262 = validateParameter(valid_606262, JString, required = false,
                                 default = nil)
  if valid_606262 != nil:
    section.add "X-Amz-Date", valid_606262
  var valid_606263 = header.getOrDefault("X-Amz-Credential")
  valid_606263 = validateParameter(valid_606263, JString, required = false,
                                 default = nil)
  if valid_606263 != nil:
    section.add "X-Amz-Credential", valid_606263
  var valid_606264 = header.getOrDefault("X-Amz-Security-Token")
  valid_606264 = validateParameter(valid_606264, JString, required = false,
                                 default = nil)
  if valid_606264 != nil:
    section.add "X-Amz-Security-Token", valid_606264
  var valid_606265 = header.getOrDefault("X-Amz-Algorithm")
  valid_606265 = validateParameter(valid_606265, JString, required = false,
                                 default = nil)
  if valid_606265 != nil:
    section.add "X-Amz-Algorithm", valid_606265
  var valid_606266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606266 = validateParameter(valid_606266, JString, required = false,
                                 default = nil)
  if valid_606266 != nil:
    section.add "X-Amz-SignedHeaders", valid_606266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606268: Call_DeleteNamespace_606256; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified namespace. This action deletes all of the entities in the namespace. Delete the systems and flows that use entities in the namespace before performing this action.
  ## 
  let valid = call_606268.validator(path, query, header, formData, body)
  let scheme = call_606268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606268.url(scheme.get, call_606268.host, call_606268.base,
                         call_606268.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606268, url, valid)

proc call*(call_606269: Call_DeleteNamespace_606256; body: JsonNode): Recallable =
  ## deleteNamespace
  ## Deletes the specified namespace. This action deletes all of the entities in the namespace. Delete the systems and flows that use entities in the namespace before performing this action.
  ##   body: JObject (required)
  var body_606270 = newJObject()
  if body != nil:
    body_606270 = body
  result = call_606269.call(nil, nil, nil, nil, body_606270)

var deleteNamespace* = Call_DeleteNamespace_606256(name: "deleteNamespace",
    meth: HttpMethod.HttpPost, host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.DeleteNamespace",
    validator: validate_DeleteNamespace_606257, base: "/", url: url_DeleteNamespace_606258,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSystemInstance_606271 = ref object of OpenApiRestCall_605589
proc url_DeleteSystemInstance_606273(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSystemInstance_606272(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes a system instance. Only system instances that have never been deployed, or that have been undeployed can be deleted.</p> <p>Users can create a new system instance that has the same ID as a deleted system instance.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_606274 = header.getOrDefault("X-Amz-Target")
  valid_606274 = validateParameter(valid_606274, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.DeleteSystemInstance"))
  if valid_606274 != nil:
    section.add "X-Amz-Target", valid_606274
  var valid_606275 = header.getOrDefault("X-Amz-Signature")
  valid_606275 = validateParameter(valid_606275, JString, required = false,
                                 default = nil)
  if valid_606275 != nil:
    section.add "X-Amz-Signature", valid_606275
  var valid_606276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606276 = validateParameter(valid_606276, JString, required = false,
                                 default = nil)
  if valid_606276 != nil:
    section.add "X-Amz-Content-Sha256", valid_606276
  var valid_606277 = header.getOrDefault("X-Amz-Date")
  valid_606277 = validateParameter(valid_606277, JString, required = false,
                                 default = nil)
  if valid_606277 != nil:
    section.add "X-Amz-Date", valid_606277
  var valid_606278 = header.getOrDefault("X-Amz-Credential")
  valid_606278 = validateParameter(valid_606278, JString, required = false,
                                 default = nil)
  if valid_606278 != nil:
    section.add "X-Amz-Credential", valid_606278
  var valid_606279 = header.getOrDefault("X-Amz-Security-Token")
  valid_606279 = validateParameter(valid_606279, JString, required = false,
                                 default = nil)
  if valid_606279 != nil:
    section.add "X-Amz-Security-Token", valid_606279
  var valid_606280 = header.getOrDefault("X-Amz-Algorithm")
  valid_606280 = validateParameter(valid_606280, JString, required = false,
                                 default = nil)
  if valid_606280 != nil:
    section.add "X-Amz-Algorithm", valid_606280
  var valid_606281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606281 = validateParameter(valid_606281, JString, required = false,
                                 default = nil)
  if valid_606281 != nil:
    section.add "X-Amz-SignedHeaders", valid_606281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606283: Call_DeleteSystemInstance_606271; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a system instance. Only system instances that have never been deployed, or that have been undeployed can be deleted.</p> <p>Users can create a new system instance that has the same ID as a deleted system instance.</p>
  ## 
  let valid = call_606283.validator(path, query, header, formData, body)
  let scheme = call_606283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606283.url(scheme.get, call_606283.host, call_606283.base,
                         call_606283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606283, url, valid)

proc call*(call_606284: Call_DeleteSystemInstance_606271; body: JsonNode): Recallable =
  ## deleteSystemInstance
  ## <p>Deletes a system instance. Only system instances that have never been deployed, or that have been undeployed can be deleted.</p> <p>Users can create a new system instance that has the same ID as a deleted system instance.</p>
  ##   body: JObject (required)
  var body_606285 = newJObject()
  if body != nil:
    body_606285 = body
  result = call_606284.call(nil, nil, nil, nil, body_606285)

var deleteSystemInstance* = Call_DeleteSystemInstance_606271(
    name: "deleteSystemInstance", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.DeleteSystemInstance",
    validator: validate_DeleteSystemInstance_606272, base: "/",
    url: url_DeleteSystemInstance_606273, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSystemTemplate_606286 = ref object of OpenApiRestCall_605589
proc url_DeleteSystemTemplate_606288(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSystemTemplate_606287(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a system. New deployments can't contain the system after its deletion. Existing deployments that contain the system will continue to work because they use a snapshot of the system that is taken when it is deployed.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_606289 = header.getOrDefault("X-Amz-Target")
  valid_606289 = validateParameter(valid_606289, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.DeleteSystemTemplate"))
  if valid_606289 != nil:
    section.add "X-Amz-Target", valid_606289
  var valid_606290 = header.getOrDefault("X-Amz-Signature")
  valid_606290 = validateParameter(valid_606290, JString, required = false,
                                 default = nil)
  if valid_606290 != nil:
    section.add "X-Amz-Signature", valid_606290
  var valid_606291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606291 = validateParameter(valid_606291, JString, required = false,
                                 default = nil)
  if valid_606291 != nil:
    section.add "X-Amz-Content-Sha256", valid_606291
  var valid_606292 = header.getOrDefault("X-Amz-Date")
  valid_606292 = validateParameter(valid_606292, JString, required = false,
                                 default = nil)
  if valid_606292 != nil:
    section.add "X-Amz-Date", valid_606292
  var valid_606293 = header.getOrDefault("X-Amz-Credential")
  valid_606293 = validateParameter(valid_606293, JString, required = false,
                                 default = nil)
  if valid_606293 != nil:
    section.add "X-Amz-Credential", valid_606293
  var valid_606294 = header.getOrDefault("X-Amz-Security-Token")
  valid_606294 = validateParameter(valid_606294, JString, required = false,
                                 default = nil)
  if valid_606294 != nil:
    section.add "X-Amz-Security-Token", valid_606294
  var valid_606295 = header.getOrDefault("X-Amz-Algorithm")
  valid_606295 = validateParameter(valid_606295, JString, required = false,
                                 default = nil)
  if valid_606295 != nil:
    section.add "X-Amz-Algorithm", valid_606295
  var valid_606296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606296 = validateParameter(valid_606296, JString, required = false,
                                 default = nil)
  if valid_606296 != nil:
    section.add "X-Amz-SignedHeaders", valid_606296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606298: Call_DeleteSystemTemplate_606286; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a system. New deployments can't contain the system after its deletion. Existing deployments that contain the system will continue to work because they use a snapshot of the system that is taken when it is deployed.
  ## 
  let valid = call_606298.validator(path, query, header, formData, body)
  let scheme = call_606298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606298.url(scheme.get, call_606298.host, call_606298.base,
                         call_606298.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606298, url, valid)

proc call*(call_606299: Call_DeleteSystemTemplate_606286; body: JsonNode): Recallable =
  ## deleteSystemTemplate
  ## Deletes a system. New deployments can't contain the system after its deletion. Existing deployments that contain the system will continue to work because they use a snapshot of the system that is taken when it is deployed.
  ##   body: JObject (required)
  var body_606300 = newJObject()
  if body != nil:
    body_606300 = body
  result = call_606299.call(nil, nil, nil, nil, body_606300)

var deleteSystemTemplate* = Call_DeleteSystemTemplate_606286(
    name: "deleteSystemTemplate", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.DeleteSystemTemplate",
    validator: validate_DeleteSystemTemplate_606287, base: "/",
    url: url_DeleteSystemTemplate_606288, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeploySystemInstance_606301 = ref object of OpenApiRestCall_605589
proc url_DeploySystemInstance_606303(protocol: Scheme; host: string; base: string;
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

proc validate_DeploySystemInstance_606302(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> <b>Greengrass and Cloud Deployments</b> </p> <p>Deploys the system instance to the target specified in <code>CreateSystemInstance</code>. </p> <p> <b>Greengrass Deployments</b> </p> <p>If the system or any workflows and entities have been updated before this action is called, then the deployment will create a new Amazon Simple Storage Service resource file and then deploy it.</p> <p>Since this action creates a Greengrass deployment on the caller's behalf, the calling identity must have write permissions to the specified Greengrass group. Otherwise, the call will fail with an authorization error.</p> <p>For information about the artifacts that get added to your Greengrass core device when you use this API, see <a href="https://docs.aws.amazon.com/thingsgraph/latest/ug/iot-tg-greengrass.html">AWS IoT Things Graph and AWS IoT Greengrass</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_606304 = header.getOrDefault("X-Amz-Target")
  valid_606304 = validateParameter(valid_606304, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.DeploySystemInstance"))
  if valid_606304 != nil:
    section.add "X-Amz-Target", valid_606304
  var valid_606305 = header.getOrDefault("X-Amz-Signature")
  valid_606305 = validateParameter(valid_606305, JString, required = false,
                                 default = nil)
  if valid_606305 != nil:
    section.add "X-Amz-Signature", valid_606305
  var valid_606306 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606306 = validateParameter(valid_606306, JString, required = false,
                                 default = nil)
  if valid_606306 != nil:
    section.add "X-Amz-Content-Sha256", valid_606306
  var valid_606307 = header.getOrDefault("X-Amz-Date")
  valid_606307 = validateParameter(valid_606307, JString, required = false,
                                 default = nil)
  if valid_606307 != nil:
    section.add "X-Amz-Date", valid_606307
  var valid_606308 = header.getOrDefault("X-Amz-Credential")
  valid_606308 = validateParameter(valid_606308, JString, required = false,
                                 default = nil)
  if valid_606308 != nil:
    section.add "X-Amz-Credential", valid_606308
  var valid_606309 = header.getOrDefault("X-Amz-Security-Token")
  valid_606309 = validateParameter(valid_606309, JString, required = false,
                                 default = nil)
  if valid_606309 != nil:
    section.add "X-Amz-Security-Token", valid_606309
  var valid_606310 = header.getOrDefault("X-Amz-Algorithm")
  valid_606310 = validateParameter(valid_606310, JString, required = false,
                                 default = nil)
  if valid_606310 != nil:
    section.add "X-Amz-Algorithm", valid_606310
  var valid_606311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606311 = validateParameter(valid_606311, JString, required = false,
                                 default = nil)
  if valid_606311 != nil:
    section.add "X-Amz-SignedHeaders", valid_606311
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606313: Call_DeploySystemInstance_606301; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> <b>Greengrass and Cloud Deployments</b> </p> <p>Deploys the system instance to the target specified in <code>CreateSystemInstance</code>. </p> <p> <b>Greengrass Deployments</b> </p> <p>If the system or any workflows and entities have been updated before this action is called, then the deployment will create a new Amazon Simple Storage Service resource file and then deploy it.</p> <p>Since this action creates a Greengrass deployment on the caller's behalf, the calling identity must have write permissions to the specified Greengrass group. Otherwise, the call will fail with an authorization error.</p> <p>For information about the artifacts that get added to your Greengrass core device when you use this API, see <a href="https://docs.aws.amazon.com/thingsgraph/latest/ug/iot-tg-greengrass.html">AWS IoT Things Graph and AWS IoT Greengrass</a>.</p>
  ## 
  let valid = call_606313.validator(path, query, header, formData, body)
  let scheme = call_606313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606313.url(scheme.get, call_606313.host, call_606313.base,
                         call_606313.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606313, url, valid)

proc call*(call_606314: Call_DeploySystemInstance_606301; body: JsonNode): Recallable =
  ## deploySystemInstance
  ## <p> <b>Greengrass and Cloud Deployments</b> </p> <p>Deploys the system instance to the target specified in <code>CreateSystemInstance</code>. </p> <p> <b>Greengrass Deployments</b> </p> <p>If the system or any workflows and entities have been updated before this action is called, then the deployment will create a new Amazon Simple Storage Service resource file and then deploy it.</p> <p>Since this action creates a Greengrass deployment on the caller's behalf, the calling identity must have write permissions to the specified Greengrass group. Otherwise, the call will fail with an authorization error.</p> <p>For information about the artifacts that get added to your Greengrass core device when you use this API, see <a href="https://docs.aws.amazon.com/thingsgraph/latest/ug/iot-tg-greengrass.html">AWS IoT Things Graph and AWS IoT Greengrass</a>.</p>
  ##   body: JObject (required)
  var body_606315 = newJObject()
  if body != nil:
    body_606315 = body
  result = call_606314.call(nil, nil, nil, nil, body_606315)

var deploySystemInstance* = Call_DeploySystemInstance_606301(
    name: "deploySystemInstance", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.DeploySystemInstance",
    validator: validate_DeploySystemInstance_606302, base: "/",
    url: url_DeploySystemInstance_606303, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeprecateFlowTemplate_606316 = ref object of OpenApiRestCall_605589
proc url_DeprecateFlowTemplate_606318(protocol: Scheme; host: string; base: string;
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

proc validate_DeprecateFlowTemplate_606317(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deprecates the specified workflow. This action marks the workflow for deletion. Deprecated flows can't be deployed, but existing deployments will continue to run.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_606319 = header.getOrDefault("X-Amz-Target")
  valid_606319 = validateParameter(valid_606319, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.DeprecateFlowTemplate"))
  if valid_606319 != nil:
    section.add "X-Amz-Target", valid_606319
  var valid_606320 = header.getOrDefault("X-Amz-Signature")
  valid_606320 = validateParameter(valid_606320, JString, required = false,
                                 default = nil)
  if valid_606320 != nil:
    section.add "X-Amz-Signature", valid_606320
  var valid_606321 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606321 = validateParameter(valid_606321, JString, required = false,
                                 default = nil)
  if valid_606321 != nil:
    section.add "X-Amz-Content-Sha256", valid_606321
  var valid_606322 = header.getOrDefault("X-Amz-Date")
  valid_606322 = validateParameter(valid_606322, JString, required = false,
                                 default = nil)
  if valid_606322 != nil:
    section.add "X-Amz-Date", valid_606322
  var valid_606323 = header.getOrDefault("X-Amz-Credential")
  valid_606323 = validateParameter(valid_606323, JString, required = false,
                                 default = nil)
  if valid_606323 != nil:
    section.add "X-Amz-Credential", valid_606323
  var valid_606324 = header.getOrDefault("X-Amz-Security-Token")
  valid_606324 = validateParameter(valid_606324, JString, required = false,
                                 default = nil)
  if valid_606324 != nil:
    section.add "X-Amz-Security-Token", valid_606324
  var valid_606325 = header.getOrDefault("X-Amz-Algorithm")
  valid_606325 = validateParameter(valid_606325, JString, required = false,
                                 default = nil)
  if valid_606325 != nil:
    section.add "X-Amz-Algorithm", valid_606325
  var valid_606326 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606326 = validateParameter(valid_606326, JString, required = false,
                                 default = nil)
  if valid_606326 != nil:
    section.add "X-Amz-SignedHeaders", valid_606326
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606328: Call_DeprecateFlowTemplate_606316; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deprecates the specified workflow. This action marks the workflow for deletion. Deprecated flows can't be deployed, but existing deployments will continue to run.
  ## 
  let valid = call_606328.validator(path, query, header, formData, body)
  let scheme = call_606328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606328.url(scheme.get, call_606328.host, call_606328.base,
                         call_606328.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606328, url, valid)

proc call*(call_606329: Call_DeprecateFlowTemplate_606316; body: JsonNode): Recallable =
  ## deprecateFlowTemplate
  ## Deprecates the specified workflow. This action marks the workflow for deletion. Deprecated flows can't be deployed, but existing deployments will continue to run.
  ##   body: JObject (required)
  var body_606330 = newJObject()
  if body != nil:
    body_606330 = body
  result = call_606329.call(nil, nil, nil, nil, body_606330)

var deprecateFlowTemplate* = Call_DeprecateFlowTemplate_606316(
    name: "deprecateFlowTemplate", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com", route: "/#X-Amz-Target=IotThingsGraphFrontEndService.DeprecateFlowTemplate",
    validator: validate_DeprecateFlowTemplate_606317, base: "/",
    url: url_DeprecateFlowTemplate_606318, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeprecateSystemTemplate_606331 = ref object of OpenApiRestCall_605589
proc url_DeprecateSystemTemplate_606333(protocol: Scheme; host: string; base: string;
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

proc validate_DeprecateSystemTemplate_606332(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deprecates the specified system.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_606334 = header.getOrDefault("X-Amz-Target")
  valid_606334 = validateParameter(valid_606334, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.DeprecateSystemTemplate"))
  if valid_606334 != nil:
    section.add "X-Amz-Target", valid_606334
  var valid_606335 = header.getOrDefault("X-Amz-Signature")
  valid_606335 = validateParameter(valid_606335, JString, required = false,
                                 default = nil)
  if valid_606335 != nil:
    section.add "X-Amz-Signature", valid_606335
  var valid_606336 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606336 = validateParameter(valid_606336, JString, required = false,
                                 default = nil)
  if valid_606336 != nil:
    section.add "X-Amz-Content-Sha256", valid_606336
  var valid_606337 = header.getOrDefault("X-Amz-Date")
  valid_606337 = validateParameter(valid_606337, JString, required = false,
                                 default = nil)
  if valid_606337 != nil:
    section.add "X-Amz-Date", valid_606337
  var valid_606338 = header.getOrDefault("X-Amz-Credential")
  valid_606338 = validateParameter(valid_606338, JString, required = false,
                                 default = nil)
  if valid_606338 != nil:
    section.add "X-Amz-Credential", valid_606338
  var valid_606339 = header.getOrDefault("X-Amz-Security-Token")
  valid_606339 = validateParameter(valid_606339, JString, required = false,
                                 default = nil)
  if valid_606339 != nil:
    section.add "X-Amz-Security-Token", valid_606339
  var valid_606340 = header.getOrDefault("X-Amz-Algorithm")
  valid_606340 = validateParameter(valid_606340, JString, required = false,
                                 default = nil)
  if valid_606340 != nil:
    section.add "X-Amz-Algorithm", valid_606340
  var valid_606341 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606341 = validateParameter(valid_606341, JString, required = false,
                                 default = nil)
  if valid_606341 != nil:
    section.add "X-Amz-SignedHeaders", valid_606341
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606343: Call_DeprecateSystemTemplate_606331; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deprecates the specified system.
  ## 
  let valid = call_606343.validator(path, query, header, formData, body)
  let scheme = call_606343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606343.url(scheme.get, call_606343.host, call_606343.base,
                         call_606343.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606343, url, valid)

proc call*(call_606344: Call_DeprecateSystemTemplate_606331; body: JsonNode): Recallable =
  ## deprecateSystemTemplate
  ## Deprecates the specified system.
  ##   body: JObject (required)
  var body_606345 = newJObject()
  if body != nil:
    body_606345 = body
  result = call_606344.call(nil, nil, nil, nil, body_606345)

var deprecateSystemTemplate* = Call_DeprecateSystemTemplate_606331(
    name: "deprecateSystemTemplate", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com", route: "/#X-Amz-Target=IotThingsGraphFrontEndService.DeprecateSystemTemplate",
    validator: validate_DeprecateSystemTemplate_606332, base: "/",
    url: url_DeprecateSystemTemplate_606333, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeNamespace_606346 = ref object of OpenApiRestCall_605589
proc url_DescribeNamespace_606348(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeNamespace_606347(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Gets the latest version of the user's namespace and the public version that it is tracking.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_606349 = header.getOrDefault("X-Amz-Target")
  valid_606349 = validateParameter(valid_606349, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.DescribeNamespace"))
  if valid_606349 != nil:
    section.add "X-Amz-Target", valid_606349
  var valid_606350 = header.getOrDefault("X-Amz-Signature")
  valid_606350 = validateParameter(valid_606350, JString, required = false,
                                 default = nil)
  if valid_606350 != nil:
    section.add "X-Amz-Signature", valid_606350
  var valid_606351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606351 = validateParameter(valid_606351, JString, required = false,
                                 default = nil)
  if valid_606351 != nil:
    section.add "X-Amz-Content-Sha256", valid_606351
  var valid_606352 = header.getOrDefault("X-Amz-Date")
  valid_606352 = validateParameter(valid_606352, JString, required = false,
                                 default = nil)
  if valid_606352 != nil:
    section.add "X-Amz-Date", valid_606352
  var valid_606353 = header.getOrDefault("X-Amz-Credential")
  valid_606353 = validateParameter(valid_606353, JString, required = false,
                                 default = nil)
  if valid_606353 != nil:
    section.add "X-Amz-Credential", valid_606353
  var valid_606354 = header.getOrDefault("X-Amz-Security-Token")
  valid_606354 = validateParameter(valid_606354, JString, required = false,
                                 default = nil)
  if valid_606354 != nil:
    section.add "X-Amz-Security-Token", valid_606354
  var valid_606355 = header.getOrDefault("X-Amz-Algorithm")
  valid_606355 = validateParameter(valid_606355, JString, required = false,
                                 default = nil)
  if valid_606355 != nil:
    section.add "X-Amz-Algorithm", valid_606355
  var valid_606356 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606356 = validateParameter(valid_606356, JString, required = false,
                                 default = nil)
  if valid_606356 != nil:
    section.add "X-Amz-SignedHeaders", valid_606356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606358: Call_DescribeNamespace_606346; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the latest version of the user's namespace and the public version that it is tracking.
  ## 
  let valid = call_606358.validator(path, query, header, formData, body)
  let scheme = call_606358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606358.url(scheme.get, call_606358.host, call_606358.base,
                         call_606358.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606358, url, valid)

proc call*(call_606359: Call_DescribeNamespace_606346; body: JsonNode): Recallable =
  ## describeNamespace
  ## Gets the latest version of the user's namespace and the public version that it is tracking.
  ##   body: JObject (required)
  var body_606360 = newJObject()
  if body != nil:
    body_606360 = body
  result = call_606359.call(nil, nil, nil, nil, body_606360)

var describeNamespace* = Call_DescribeNamespace_606346(name: "describeNamespace",
    meth: HttpMethod.HttpPost, host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.DescribeNamespace",
    validator: validate_DescribeNamespace_606347, base: "/",
    url: url_DescribeNamespace_606348, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DissociateEntityFromThing_606361 = ref object of OpenApiRestCall_605589
proc url_DissociateEntityFromThing_606363(protocol: Scheme; host: string;
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

proc validate_DissociateEntityFromThing_606362(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Dissociates a device entity from a concrete thing. The action takes only the type of the entity that you need to dissociate because only one entity of a particular type can be associated with a thing.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_606364 = header.getOrDefault("X-Amz-Target")
  valid_606364 = validateParameter(valid_606364, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.DissociateEntityFromThing"))
  if valid_606364 != nil:
    section.add "X-Amz-Target", valid_606364
  var valid_606365 = header.getOrDefault("X-Amz-Signature")
  valid_606365 = validateParameter(valid_606365, JString, required = false,
                                 default = nil)
  if valid_606365 != nil:
    section.add "X-Amz-Signature", valid_606365
  var valid_606366 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606366 = validateParameter(valid_606366, JString, required = false,
                                 default = nil)
  if valid_606366 != nil:
    section.add "X-Amz-Content-Sha256", valid_606366
  var valid_606367 = header.getOrDefault("X-Amz-Date")
  valid_606367 = validateParameter(valid_606367, JString, required = false,
                                 default = nil)
  if valid_606367 != nil:
    section.add "X-Amz-Date", valid_606367
  var valid_606368 = header.getOrDefault("X-Amz-Credential")
  valid_606368 = validateParameter(valid_606368, JString, required = false,
                                 default = nil)
  if valid_606368 != nil:
    section.add "X-Amz-Credential", valid_606368
  var valid_606369 = header.getOrDefault("X-Amz-Security-Token")
  valid_606369 = validateParameter(valid_606369, JString, required = false,
                                 default = nil)
  if valid_606369 != nil:
    section.add "X-Amz-Security-Token", valid_606369
  var valid_606370 = header.getOrDefault("X-Amz-Algorithm")
  valid_606370 = validateParameter(valid_606370, JString, required = false,
                                 default = nil)
  if valid_606370 != nil:
    section.add "X-Amz-Algorithm", valid_606370
  var valid_606371 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606371 = validateParameter(valid_606371, JString, required = false,
                                 default = nil)
  if valid_606371 != nil:
    section.add "X-Amz-SignedHeaders", valid_606371
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606373: Call_DissociateEntityFromThing_606361; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Dissociates a device entity from a concrete thing. The action takes only the type of the entity that you need to dissociate because only one entity of a particular type can be associated with a thing.
  ## 
  let valid = call_606373.validator(path, query, header, formData, body)
  let scheme = call_606373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606373.url(scheme.get, call_606373.host, call_606373.base,
                         call_606373.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606373, url, valid)

proc call*(call_606374: Call_DissociateEntityFromThing_606361; body: JsonNode): Recallable =
  ## dissociateEntityFromThing
  ## Dissociates a device entity from a concrete thing. The action takes only the type of the entity that you need to dissociate because only one entity of a particular type can be associated with a thing.
  ##   body: JObject (required)
  var body_606375 = newJObject()
  if body != nil:
    body_606375 = body
  result = call_606374.call(nil, nil, nil, nil, body_606375)

var dissociateEntityFromThing* = Call_DissociateEntityFromThing_606361(
    name: "dissociateEntityFromThing", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com", route: "/#X-Amz-Target=IotThingsGraphFrontEndService.DissociateEntityFromThing",
    validator: validate_DissociateEntityFromThing_606362, base: "/",
    url: url_DissociateEntityFromThing_606363,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEntities_606376 = ref object of OpenApiRestCall_605589
proc url_GetEntities_606378(protocol: Scheme; host: string; base: string;
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

proc validate_GetEntities_606377(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets definitions of the specified entities. Uses the latest version of the user's namespace by default. This API returns the following TDM entities.</p> <ul> <li> <p>Properties</p> </li> <li> <p>States</p> </li> <li> <p>Events</p> </li> <li> <p>Actions</p> </li> <li> <p>Capabilities</p> </li> <li> <p>Mappings</p> </li> <li> <p>Devices</p> </li> <li> <p>Device Models</p> </li> <li> <p>Services</p> </li> </ul> <p>This action doesn't return definitions for systems, flows, and deployments.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_606379 = header.getOrDefault("X-Amz-Target")
  valid_606379 = validateParameter(valid_606379, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.GetEntities"))
  if valid_606379 != nil:
    section.add "X-Amz-Target", valid_606379
  var valid_606380 = header.getOrDefault("X-Amz-Signature")
  valid_606380 = validateParameter(valid_606380, JString, required = false,
                                 default = nil)
  if valid_606380 != nil:
    section.add "X-Amz-Signature", valid_606380
  var valid_606381 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606381 = validateParameter(valid_606381, JString, required = false,
                                 default = nil)
  if valid_606381 != nil:
    section.add "X-Amz-Content-Sha256", valid_606381
  var valid_606382 = header.getOrDefault("X-Amz-Date")
  valid_606382 = validateParameter(valid_606382, JString, required = false,
                                 default = nil)
  if valid_606382 != nil:
    section.add "X-Amz-Date", valid_606382
  var valid_606383 = header.getOrDefault("X-Amz-Credential")
  valid_606383 = validateParameter(valid_606383, JString, required = false,
                                 default = nil)
  if valid_606383 != nil:
    section.add "X-Amz-Credential", valid_606383
  var valid_606384 = header.getOrDefault("X-Amz-Security-Token")
  valid_606384 = validateParameter(valid_606384, JString, required = false,
                                 default = nil)
  if valid_606384 != nil:
    section.add "X-Amz-Security-Token", valid_606384
  var valid_606385 = header.getOrDefault("X-Amz-Algorithm")
  valid_606385 = validateParameter(valid_606385, JString, required = false,
                                 default = nil)
  if valid_606385 != nil:
    section.add "X-Amz-Algorithm", valid_606385
  var valid_606386 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606386 = validateParameter(valid_606386, JString, required = false,
                                 default = nil)
  if valid_606386 != nil:
    section.add "X-Amz-SignedHeaders", valid_606386
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606388: Call_GetEntities_606376; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets definitions of the specified entities. Uses the latest version of the user's namespace by default. This API returns the following TDM entities.</p> <ul> <li> <p>Properties</p> </li> <li> <p>States</p> </li> <li> <p>Events</p> </li> <li> <p>Actions</p> </li> <li> <p>Capabilities</p> </li> <li> <p>Mappings</p> </li> <li> <p>Devices</p> </li> <li> <p>Device Models</p> </li> <li> <p>Services</p> </li> </ul> <p>This action doesn't return definitions for systems, flows, and deployments.</p>
  ## 
  let valid = call_606388.validator(path, query, header, formData, body)
  let scheme = call_606388.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606388.url(scheme.get, call_606388.host, call_606388.base,
                         call_606388.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606388, url, valid)

proc call*(call_606389: Call_GetEntities_606376; body: JsonNode): Recallable =
  ## getEntities
  ## <p>Gets definitions of the specified entities. Uses the latest version of the user's namespace by default. This API returns the following TDM entities.</p> <ul> <li> <p>Properties</p> </li> <li> <p>States</p> </li> <li> <p>Events</p> </li> <li> <p>Actions</p> </li> <li> <p>Capabilities</p> </li> <li> <p>Mappings</p> </li> <li> <p>Devices</p> </li> <li> <p>Device Models</p> </li> <li> <p>Services</p> </li> </ul> <p>This action doesn't return definitions for systems, flows, and deployments.</p>
  ##   body: JObject (required)
  var body_606390 = newJObject()
  if body != nil:
    body_606390 = body
  result = call_606389.call(nil, nil, nil, nil, body_606390)

var getEntities* = Call_GetEntities_606376(name: "getEntities",
                                        meth: HttpMethod.HttpPost,
                                        host: "iotthingsgraph.amazonaws.com", route: "/#X-Amz-Target=IotThingsGraphFrontEndService.GetEntities",
                                        validator: validate_GetEntities_606377,
                                        base: "/", url: url_GetEntities_606378,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFlowTemplate_606391 = ref object of OpenApiRestCall_605589
proc url_GetFlowTemplate_606393(protocol: Scheme; host: string; base: string;
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

proc validate_GetFlowTemplate_606392(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Gets the latest version of the <code>DefinitionDocument</code> and <code>FlowTemplateSummary</code> for the specified workflow.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_606394 = header.getOrDefault("X-Amz-Target")
  valid_606394 = validateParameter(valid_606394, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.GetFlowTemplate"))
  if valid_606394 != nil:
    section.add "X-Amz-Target", valid_606394
  var valid_606395 = header.getOrDefault("X-Amz-Signature")
  valid_606395 = validateParameter(valid_606395, JString, required = false,
                                 default = nil)
  if valid_606395 != nil:
    section.add "X-Amz-Signature", valid_606395
  var valid_606396 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606396 = validateParameter(valid_606396, JString, required = false,
                                 default = nil)
  if valid_606396 != nil:
    section.add "X-Amz-Content-Sha256", valid_606396
  var valid_606397 = header.getOrDefault("X-Amz-Date")
  valid_606397 = validateParameter(valid_606397, JString, required = false,
                                 default = nil)
  if valid_606397 != nil:
    section.add "X-Amz-Date", valid_606397
  var valid_606398 = header.getOrDefault("X-Amz-Credential")
  valid_606398 = validateParameter(valid_606398, JString, required = false,
                                 default = nil)
  if valid_606398 != nil:
    section.add "X-Amz-Credential", valid_606398
  var valid_606399 = header.getOrDefault("X-Amz-Security-Token")
  valid_606399 = validateParameter(valid_606399, JString, required = false,
                                 default = nil)
  if valid_606399 != nil:
    section.add "X-Amz-Security-Token", valid_606399
  var valid_606400 = header.getOrDefault("X-Amz-Algorithm")
  valid_606400 = validateParameter(valid_606400, JString, required = false,
                                 default = nil)
  if valid_606400 != nil:
    section.add "X-Amz-Algorithm", valid_606400
  var valid_606401 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606401 = validateParameter(valid_606401, JString, required = false,
                                 default = nil)
  if valid_606401 != nil:
    section.add "X-Amz-SignedHeaders", valid_606401
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606403: Call_GetFlowTemplate_606391; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the latest version of the <code>DefinitionDocument</code> and <code>FlowTemplateSummary</code> for the specified workflow.
  ## 
  let valid = call_606403.validator(path, query, header, formData, body)
  let scheme = call_606403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606403.url(scheme.get, call_606403.host, call_606403.base,
                         call_606403.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606403, url, valid)

proc call*(call_606404: Call_GetFlowTemplate_606391; body: JsonNode): Recallable =
  ## getFlowTemplate
  ## Gets the latest version of the <code>DefinitionDocument</code> and <code>FlowTemplateSummary</code> for the specified workflow.
  ##   body: JObject (required)
  var body_606405 = newJObject()
  if body != nil:
    body_606405 = body
  result = call_606404.call(nil, nil, nil, nil, body_606405)

var getFlowTemplate* = Call_GetFlowTemplate_606391(name: "getFlowTemplate",
    meth: HttpMethod.HttpPost, host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.GetFlowTemplate",
    validator: validate_GetFlowTemplate_606392, base: "/", url: url_GetFlowTemplate_606393,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFlowTemplateRevisions_606406 = ref object of OpenApiRestCall_605589
proc url_GetFlowTemplateRevisions_606408(protocol: Scheme; host: string;
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

proc validate_GetFlowTemplateRevisions_606407(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets revisions of the specified workflow. Only the last 100 revisions are stored. If the workflow has been deprecated, this action will return revisions that occurred before the deprecation. This action won't work for workflows that have been deleted.
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
  var valid_606409 = query.getOrDefault("nextToken")
  valid_606409 = validateParameter(valid_606409, JString, required = false,
                                 default = nil)
  if valid_606409 != nil:
    section.add "nextToken", valid_606409
  var valid_606410 = query.getOrDefault("maxResults")
  valid_606410 = validateParameter(valid_606410, JString, required = false,
                                 default = nil)
  if valid_606410 != nil:
    section.add "maxResults", valid_606410
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_606411 = header.getOrDefault("X-Amz-Target")
  valid_606411 = validateParameter(valid_606411, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.GetFlowTemplateRevisions"))
  if valid_606411 != nil:
    section.add "X-Amz-Target", valid_606411
  var valid_606412 = header.getOrDefault("X-Amz-Signature")
  valid_606412 = validateParameter(valid_606412, JString, required = false,
                                 default = nil)
  if valid_606412 != nil:
    section.add "X-Amz-Signature", valid_606412
  var valid_606413 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606413 = validateParameter(valid_606413, JString, required = false,
                                 default = nil)
  if valid_606413 != nil:
    section.add "X-Amz-Content-Sha256", valid_606413
  var valid_606414 = header.getOrDefault("X-Amz-Date")
  valid_606414 = validateParameter(valid_606414, JString, required = false,
                                 default = nil)
  if valid_606414 != nil:
    section.add "X-Amz-Date", valid_606414
  var valid_606415 = header.getOrDefault("X-Amz-Credential")
  valid_606415 = validateParameter(valid_606415, JString, required = false,
                                 default = nil)
  if valid_606415 != nil:
    section.add "X-Amz-Credential", valid_606415
  var valid_606416 = header.getOrDefault("X-Amz-Security-Token")
  valid_606416 = validateParameter(valid_606416, JString, required = false,
                                 default = nil)
  if valid_606416 != nil:
    section.add "X-Amz-Security-Token", valid_606416
  var valid_606417 = header.getOrDefault("X-Amz-Algorithm")
  valid_606417 = validateParameter(valid_606417, JString, required = false,
                                 default = nil)
  if valid_606417 != nil:
    section.add "X-Amz-Algorithm", valid_606417
  var valid_606418 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606418 = validateParameter(valid_606418, JString, required = false,
                                 default = nil)
  if valid_606418 != nil:
    section.add "X-Amz-SignedHeaders", valid_606418
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606420: Call_GetFlowTemplateRevisions_606406; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets revisions of the specified workflow. Only the last 100 revisions are stored. If the workflow has been deprecated, this action will return revisions that occurred before the deprecation. This action won't work for workflows that have been deleted.
  ## 
  let valid = call_606420.validator(path, query, header, formData, body)
  let scheme = call_606420.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606420.url(scheme.get, call_606420.host, call_606420.base,
                         call_606420.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606420, url, valid)

proc call*(call_606421: Call_GetFlowTemplateRevisions_606406; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getFlowTemplateRevisions
  ## Gets revisions of the specified workflow. Only the last 100 revisions are stored. If the workflow has been deprecated, this action will return revisions that occurred before the deprecation. This action won't work for workflows that have been deleted.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606422 = newJObject()
  var body_606423 = newJObject()
  add(query_606422, "nextToken", newJString(nextToken))
  if body != nil:
    body_606423 = body
  add(query_606422, "maxResults", newJString(maxResults))
  result = call_606421.call(nil, query_606422, nil, nil, body_606423)

var getFlowTemplateRevisions* = Call_GetFlowTemplateRevisions_606406(
    name: "getFlowTemplateRevisions", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com", route: "/#X-Amz-Target=IotThingsGraphFrontEndService.GetFlowTemplateRevisions",
    validator: validate_GetFlowTemplateRevisions_606407, base: "/",
    url: url_GetFlowTemplateRevisions_606408, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetNamespaceDeletionStatus_606425 = ref object of OpenApiRestCall_605589
proc url_GetNamespaceDeletionStatus_606427(protocol: Scheme; host: string;
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

proc validate_GetNamespaceDeletionStatus_606426(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the status of a namespace deletion task.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_606428 = header.getOrDefault("X-Amz-Target")
  valid_606428 = validateParameter(valid_606428, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.GetNamespaceDeletionStatus"))
  if valid_606428 != nil:
    section.add "X-Amz-Target", valid_606428
  var valid_606429 = header.getOrDefault("X-Amz-Signature")
  valid_606429 = validateParameter(valid_606429, JString, required = false,
                                 default = nil)
  if valid_606429 != nil:
    section.add "X-Amz-Signature", valid_606429
  var valid_606430 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606430 = validateParameter(valid_606430, JString, required = false,
                                 default = nil)
  if valid_606430 != nil:
    section.add "X-Amz-Content-Sha256", valid_606430
  var valid_606431 = header.getOrDefault("X-Amz-Date")
  valid_606431 = validateParameter(valid_606431, JString, required = false,
                                 default = nil)
  if valid_606431 != nil:
    section.add "X-Amz-Date", valid_606431
  var valid_606432 = header.getOrDefault("X-Amz-Credential")
  valid_606432 = validateParameter(valid_606432, JString, required = false,
                                 default = nil)
  if valid_606432 != nil:
    section.add "X-Amz-Credential", valid_606432
  var valid_606433 = header.getOrDefault("X-Amz-Security-Token")
  valid_606433 = validateParameter(valid_606433, JString, required = false,
                                 default = nil)
  if valid_606433 != nil:
    section.add "X-Amz-Security-Token", valid_606433
  var valid_606434 = header.getOrDefault("X-Amz-Algorithm")
  valid_606434 = validateParameter(valid_606434, JString, required = false,
                                 default = nil)
  if valid_606434 != nil:
    section.add "X-Amz-Algorithm", valid_606434
  var valid_606435 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606435 = validateParameter(valid_606435, JString, required = false,
                                 default = nil)
  if valid_606435 != nil:
    section.add "X-Amz-SignedHeaders", valid_606435
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606437: Call_GetNamespaceDeletionStatus_606425; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the status of a namespace deletion task.
  ## 
  let valid = call_606437.validator(path, query, header, formData, body)
  let scheme = call_606437.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606437.url(scheme.get, call_606437.host, call_606437.base,
                         call_606437.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606437, url, valid)

proc call*(call_606438: Call_GetNamespaceDeletionStatus_606425; body: JsonNode): Recallable =
  ## getNamespaceDeletionStatus
  ## Gets the status of a namespace deletion task.
  ##   body: JObject (required)
  var body_606439 = newJObject()
  if body != nil:
    body_606439 = body
  result = call_606438.call(nil, nil, nil, nil, body_606439)

var getNamespaceDeletionStatus* = Call_GetNamespaceDeletionStatus_606425(
    name: "getNamespaceDeletionStatus", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com", route: "/#X-Amz-Target=IotThingsGraphFrontEndService.GetNamespaceDeletionStatus",
    validator: validate_GetNamespaceDeletionStatus_606426, base: "/",
    url: url_GetNamespaceDeletionStatus_606427,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSystemInstance_606440 = ref object of OpenApiRestCall_605589
proc url_GetSystemInstance_606442(protocol: Scheme; host: string; base: string;
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

proc validate_GetSystemInstance_606441(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Gets a system instance.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_606443 = header.getOrDefault("X-Amz-Target")
  valid_606443 = validateParameter(valid_606443, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.GetSystemInstance"))
  if valid_606443 != nil:
    section.add "X-Amz-Target", valid_606443
  var valid_606444 = header.getOrDefault("X-Amz-Signature")
  valid_606444 = validateParameter(valid_606444, JString, required = false,
                                 default = nil)
  if valid_606444 != nil:
    section.add "X-Amz-Signature", valid_606444
  var valid_606445 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606445 = validateParameter(valid_606445, JString, required = false,
                                 default = nil)
  if valid_606445 != nil:
    section.add "X-Amz-Content-Sha256", valid_606445
  var valid_606446 = header.getOrDefault("X-Amz-Date")
  valid_606446 = validateParameter(valid_606446, JString, required = false,
                                 default = nil)
  if valid_606446 != nil:
    section.add "X-Amz-Date", valid_606446
  var valid_606447 = header.getOrDefault("X-Amz-Credential")
  valid_606447 = validateParameter(valid_606447, JString, required = false,
                                 default = nil)
  if valid_606447 != nil:
    section.add "X-Amz-Credential", valid_606447
  var valid_606448 = header.getOrDefault("X-Amz-Security-Token")
  valid_606448 = validateParameter(valid_606448, JString, required = false,
                                 default = nil)
  if valid_606448 != nil:
    section.add "X-Amz-Security-Token", valid_606448
  var valid_606449 = header.getOrDefault("X-Amz-Algorithm")
  valid_606449 = validateParameter(valid_606449, JString, required = false,
                                 default = nil)
  if valid_606449 != nil:
    section.add "X-Amz-Algorithm", valid_606449
  var valid_606450 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606450 = validateParameter(valid_606450, JString, required = false,
                                 default = nil)
  if valid_606450 != nil:
    section.add "X-Amz-SignedHeaders", valid_606450
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606452: Call_GetSystemInstance_606440; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a system instance.
  ## 
  let valid = call_606452.validator(path, query, header, formData, body)
  let scheme = call_606452.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606452.url(scheme.get, call_606452.host, call_606452.base,
                         call_606452.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606452, url, valid)

proc call*(call_606453: Call_GetSystemInstance_606440; body: JsonNode): Recallable =
  ## getSystemInstance
  ## Gets a system instance.
  ##   body: JObject (required)
  var body_606454 = newJObject()
  if body != nil:
    body_606454 = body
  result = call_606453.call(nil, nil, nil, nil, body_606454)

var getSystemInstance* = Call_GetSystemInstance_606440(name: "getSystemInstance",
    meth: HttpMethod.HttpPost, host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.GetSystemInstance",
    validator: validate_GetSystemInstance_606441, base: "/",
    url: url_GetSystemInstance_606442, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSystemTemplate_606455 = ref object of OpenApiRestCall_605589
proc url_GetSystemTemplate_606457(protocol: Scheme; host: string; base: string;
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

proc validate_GetSystemTemplate_606456(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Gets a system.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_606458 = header.getOrDefault("X-Amz-Target")
  valid_606458 = validateParameter(valid_606458, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.GetSystemTemplate"))
  if valid_606458 != nil:
    section.add "X-Amz-Target", valid_606458
  var valid_606459 = header.getOrDefault("X-Amz-Signature")
  valid_606459 = validateParameter(valid_606459, JString, required = false,
                                 default = nil)
  if valid_606459 != nil:
    section.add "X-Amz-Signature", valid_606459
  var valid_606460 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606460 = validateParameter(valid_606460, JString, required = false,
                                 default = nil)
  if valid_606460 != nil:
    section.add "X-Amz-Content-Sha256", valid_606460
  var valid_606461 = header.getOrDefault("X-Amz-Date")
  valid_606461 = validateParameter(valid_606461, JString, required = false,
                                 default = nil)
  if valid_606461 != nil:
    section.add "X-Amz-Date", valid_606461
  var valid_606462 = header.getOrDefault("X-Amz-Credential")
  valid_606462 = validateParameter(valid_606462, JString, required = false,
                                 default = nil)
  if valid_606462 != nil:
    section.add "X-Amz-Credential", valid_606462
  var valid_606463 = header.getOrDefault("X-Amz-Security-Token")
  valid_606463 = validateParameter(valid_606463, JString, required = false,
                                 default = nil)
  if valid_606463 != nil:
    section.add "X-Amz-Security-Token", valid_606463
  var valid_606464 = header.getOrDefault("X-Amz-Algorithm")
  valid_606464 = validateParameter(valid_606464, JString, required = false,
                                 default = nil)
  if valid_606464 != nil:
    section.add "X-Amz-Algorithm", valid_606464
  var valid_606465 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606465 = validateParameter(valid_606465, JString, required = false,
                                 default = nil)
  if valid_606465 != nil:
    section.add "X-Amz-SignedHeaders", valid_606465
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606467: Call_GetSystemTemplate_606455; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a system.
  ## 
  let valid = call_606467.validator(path, query, header, formData, body)
  let scheme = call_606467.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606467.url(scheme.get, call_606467.host, call_606467.base,
                         call_606467.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606467, url, valid)

proc call*(call_606468: Call_GetSystemTemplate_606455; body: JsonNode): Recallable =
  ## getSystemTemplate
  ## Gets a system.
  ##   body: JObject (required)
  var body_606469 = newJObject()
  if body != nil:
    body_606469 = body
  result = call_606468.call(nil, nil, nil, nil, body_606469)

var getSystemTemplate* = Call_GetSystemTemplate_606455(name: "getSystemTemplate",
    meth: HttpMethod.HttpPost, host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.GetSystemTemplate",
    validator: validate_GetSystemTemplate_606456, base: "/",
    url: url_GetSystemTemplate_606457, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSystemTemplateRevisions_606470 = ref object of OpenApiRestCall_605589
proc url_GetSystemTemplateRevisions_606472(protocol: Scheme; host: string;
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

proc validate_GetSystemTemplateRevisions_606471(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets revisions made to the specified system template. Only the previous 100 revisions are stored. If the system has been deprecated, this action will return the revisions that occurred before its deprecation. This action won't work with systems that have been deleted.
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
  var valid_606473 = query.getOrDefault("nextToken")
  valid_606473 = validateParameter(valid_606473, JString, required = false,
                                 default = nil)
  if valid_606473 != nil:
    section.add "nextToken", valid_606473
  var valid_606474 = query.getOrDefault("maxResults")
  valid_606474 = validateParameter(valid_606474, JString, required = false,
                                 default = nil)
  if valid_606474 != nil:
    section.add "maxResults", valid_606474
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_606475 = header.getOrDefault("X-Amz-Target")
  valid_606475 = validateParameter(valid_606475, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.GetSystemTemplateRevisions"))
  if valid_606475 != nil:
    section.add "X-Amz-Target", valid_606475
  var valid_606476 = header.getOrDefault("X-Amz-Signature")
  valid_606476 = validateParameter(valid_606476, JString, required = false,
                                 default = nil)
  if valid_606476 != nil:
    section.add "X-Amz-Signature", valid_606476
  var valid_606477 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606477 = validateParameter(valid_606477, JString, required = false,
                                 default = nil)
  if valid_606477 != nil:
    section.add "X-Amz-Content-Sha256", valid_606477
  var valid_606478 = header.getOrDefault("X-Amz-Date")
  valid_606478 = validateParameter(valid_606478, JString, required = false,
                                 default = nil)
  if valid_606478 != nil:
    section.add "X-Amz-Date", valid_606478
  var valid_606479 = header.getOrDefault("X-Amz-Credential")
  valid_606479 = validateParameter(valid_606479, JString, required = false,
                                 default = nil)
  if valid_606479 != nil:
    section.add "X-Amz-Credential", valid_606479
  var valid_606480 = header.getOrDefault("X-Amz-Security-Token")
  valid_606480 = validateParameter(valid_606480, JString, required = false,
                                 default = nil)
  if valid_606480 != nil:
    section.add "X-Amz-Security-Token", valid_606480
  var valid_606481 = header.getOrDefault("X-Amz-Algorithm")
  valid_606481 = validateParameter(valid_606481, JString, required = false,
                                 default = nil)
  if valid_606481 != nil:
    section.add "X-Amz-Algorithm", valid_606481
  var valid_606482 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606482 = validateParameter(valid_606482, JString, required = false,
                                 default = nil)
  if valid_606482 != nil:
    section.add "X-Amz-SignedHeaders", valid_606482
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606484: Call_GetSystemTemplateRevisions_606470; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets revisions made to the specified system template. Only the previous 100 revisions are stored. If the system has been deprecated, this action will return the revisions that occurred before its deprecation. This action won't work with systems that have been deleted.
  ## 
  let valid = call_606484.validator(path, query, header, formData, body)
  let scheme = call_606484.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606484.url(scheme.get, call_606484.host, call_606484.base,
                         call_606484.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606484, url, valid)

proc call*(call_606485: Call_GetSystemTemplateRevisions_606470; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getSystemTemplateRevisions
  ## Gets revisions made to the specified system template. Only the previous 100 revisions are stored. If the system has been deprecated, this action will return the revisions that occurred before its deprecation. This action won't work with systems that have been deleted.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606486 = newJObject()
  var body_606487 = newJObject()
  add(query_606486, "nextToken", newJString(nextToken))
  if body != nil:
    body_606487 = body
  add(query_606486, "maxResults", newJString(maxResults))
  result = call_606485.call(nil, query_606486, nil, nil, body_606487)

var getSystemTemplateRevisions* = Call_GetSystemTemplateRevisions_606470(
    name: "getSystemTemplateRevisions", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com", route: "/#X-Amz-Target=IotThingsGraphFrontEndService.GetSystemTemplateRevisions",
    validator: validate_GetSystemTemplateRevisions_606471, base: "/",
    url: url_GetSystemTemplateRevisions_606472,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUploadStatus_606488 = ref object of OpenApiRestCall_605589
proc url_GetUploadStatus_606490(protocol: Scheme; host: string; base: string;
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

proc validate_GetUploadStatus_606489(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Gets the status of the specified upload.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_606491 = header.getOrDefault("X-Amz-Target")
  valid_606491 = validateParameter(valid_606491, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.GetUploadStatus"))
  if valid_606491 != nil:
    section.add "X-Amz-Target", valid_606491
  var valid_606492 = header.getOrDefault("X-Amz-Signature")
  valid_606492 = validateParameter(valid_606492, JString, required = false,
                                 default = nil)
  if valid_606492 != nil:
    section.add "X-Amz-Signature", valid_606492
  var valid_606493 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606493 = validateParameter(valid_606493, JString, required = false,
                                 default = nil)
  if valid_606493 != nil:
    section.add "X-Amz-Content-Sha256", valid_606493
  var valid_606494 = header.getOrDefault("X-Amz-Date")
  valid_606494 = validateParameter(valid_606494, JString, required = false,
                                 default = nil)
  if valid_606494 != nil:
    section.add "X-Amz-Date", valid_606494
  var valid_606495 = header.getOrDefault("X-Amz-Credential")
  valid_606495 = validateParameter(valid_606495, JString, required = false,
                                 default = nil)
  if valid_606495 != nil:
    section.add "X-Amz-Credential", valid_606495
  var valid_606496 = header.getOrDefault("X-Amz-Security-Token")
  valid_606496 = validateParameter(valid_606496, JString, required = false,
                                 default = nil)
  if valid_606496 != nil:
    section.add "X-Amz-Security-Token", valid_606496
  var valid_606497 = header.getOrDefault("X-Amz-Algorithm")
  valid_606497 = validateParameter(valid_606497, JString, required = false,
                                 default = nil)
  if valid_606497 != nil:
    section.add "X-Amz-Algorithm", valid_606497
  var valid_606498 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606498 = validateParameter(valid_606498, JString, required = false,
                                 default = nil)
  if valid_606498 != nil:
    section.add "X-Amz-SignedHeaders", valid_606498
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606500: Call_GetUploadStatus_606488; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the status of the specified upload.
  ## 
  let valid = call_606500.validator(path, query, header, formData, body)
  let scheme = call_606500.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606500.url(scheme.get, call_606500.host, call_606500.base,
                         call_606500.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606500, url, valid)

proc call*(call_606501: Call_GetUploadStatus_606488; body: JsonNode): Recallable =
  ## getUploadStatus
  ## Gets the status of the specified upload.
  ##   body: JObject (required)
  var body_606502 = newJObject()
  if body != nil:
    body_606502 = body
  result = call_606501.call(nil, nil, nil, nil, body_606502)

var getUploadStatus* = Call_GetUploadStatus_606488(name: "getUploadStatus",
    meth: HttpMethod.HttpPost, host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.GetUploadStatus",
    validator: validate_GetUploadStatus_606489, base: "/", url: url_GetUploadStatus_606490,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFlowExecutionMessages_606503 = ref object of OpenApiRestCall_605589
proc url_ListFlowExecutionMessages_606505(protocol: Scheme; host: string;
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

proc validate_ListFlowExecutionMessages_606504(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of objects that contain information about events in a flow execution.
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
  var valid_606506 = query.getOrDefault("nextToken")
  valid_606506 = validateParameter(valid_606506, JString, required = false,
                                 default = nil)
  if valid_606506 != nil:
    section.add "nextToken", valid_606506
  var valid_606507 = query.getOrDefault("maxResults")
  valid_606507 = validateParameter(valid_606507, JString, required = false,
                                 default = nil)
  if valid_606507 != nil:
    section.add "maxResults", valid_606507
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_606508 = header.getOrDefault("X-Amz-Target")
  valid_606508 = validateParameter(valid_606508, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.ListFlowExecutionMessages"))
  if valid_606508 != nil:
    section.add "X-Amz-Target", valid_606508
  var valid_606509 = header.getOrDefault("X-Amz-Signature")
  valid_606509 = validateParameter(valid_606509, JString, required = false,
                                 default = nil)
  if valid_606509 != nil:
    section.add "X-Amz-Signature", valid_606509
  var valid_606510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606510 = validateParameter(valid_606510, JString, required = false,
                                 default = nil)
  if valid_606510 != nil:
    section.add "X-Amz-Content-Sha256", valid_606510
  var valid_606511 = header.getOrDefault("X-Amz-Date")
  valid_606511 = validateParameter(valid_606511, JString, required = false,
                                 default = nil)
  if valid_606511 != nil:
    section.add "X-Amz-Date", valid_606511
  var valid_606512 = header.getOrDefault("X-Amz-Credential")
  valid_606512 = validateParameter(valid_606512, JString, required = false,
                                 default = nil)
  if valid_606512 != nil:
    section.add "X-Amz-Credential", valid_606512
  var valid_606513 = header.getOrDefault("X-Amz-Security-Token")
  valid_606513 = validateParameter(valid_606513, JString, required = false,
                                 default = nil)
  if valid_606513 != nil:
    section.add "X-Amz-Security-Token", valid_606513
  var valid_606514 = header.getOrDefault("X-Amz-Algorithm")
  valid_606514 = validateParameter(valid_606514, JString, required = false,
                                 default = nil)
  if valid_606514 != nil:
    section.add "X-Amz-Algorithm", valid_606514
  var valid_606515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606515 = validateParameter(valid_606515, JString, required = false,
                                 default = nil)
  if valid_606515 != nil:
    section.add "X-Amz-SignedHeaders", valid_606515
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606517: Call_ListFlowExecutionMessages_606503; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of objects that contain information about events in a flow execution.
  ## 
  let valid = call_606517.validator(path, query, header, formData, body)
  let scheme = call_606517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606517.url(scheme.get, call_606517.host, call_606517.base,
                         call_606517.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606517, url, valid)

proc call*(call_606518: Call_ListFlowExecutionMessages_606503; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listFlowExecutionMessages
  ## Returns a list of objects that contain information about events in a flow execution.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606519 = newJObject()
  var body_606520 = newJObject()
  add(query_606519, "nextToken", newJString(nextToken))
  if body != nil:
    body_606520 = body
  add(query_606519, "maxResults", newJString(maxResults))
  result = call_606518.call(nil, query_606519, nil, nil, body_606520)

var listFlowExecutionMessages* = Call_ListFlowExecutionMessages_606503(
    name: "listFlowExecutionMessages", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com", route: "/#X-Amz-Target=IotThingsGraphFrontEndService.ListFlowExecutionMessages",
    validator: validate_ListFlowExecutionMessages_606504, base: "/",
    url: url_ListFlowExecutionMessages_606505,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_606521 = ref object of OpenApiRestCall_605589
proc url_ListTagsForResource_606523(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_606522(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Lists all tags on an AWS IoT Things Graph resource.
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
  var valid_606524 = query.getOrDefault("nextToken")
  valid_606524 = validateParameter(valid_606524, JString, required = false,
                                 default = nil)
  if valid_606524 != nil:
    section.add "nextToken", valid_606524
  var valid_606525 = query.getOrDefault("maxResults")
  valid_606525 = validateParameter(valid_606525, JString, required = false,
                                 default = nil)
  if valid_606525 != nil:
    section.add "maxResults", valid_606525
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_606526 = header.getOrDefault("X-Amz-Target")
  valid_606526 = validateParameter(valid_606526, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.ListTagsForResource"))
  if valid_606526 != nil:
    section.add "X-Amz-Target", valid_606526
  var valid_606527 = header.getOrDefault("X-Amz-Signature")
  valid_606527 = validateParameter(valid_606527, JString, required = false,
                                 default = nil)
  if valid_606527 != nil:
    section.add "X-Amz-Signature", valid_606527
  var valid_606528 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606528 = validateParameter(valid_606528, JString, required = false,
                                 default = nil)
  if valid_606528 != nil:
    section.add "X-Amz-Content-Sha256", valid_606528
  var valid_606529 = header.getOrDefault("X-Amz-Date")
  valid_606529 = validateParameter(valid_606529, JString, required = false,
                                 default = nil)
  if valid_606529 != nil:
    section.add "X-Amz-Date", valid_606529
  var valid_606530 = header.getOrDefault("X-Amz-Credential")
  valid_606530 = validateParameter(valid_606530, JString, required = false,
                                 default = nil)
  if valid_606530 != nil:
    section.add "X-Amz-Credential", valid_606530
  var valid_606531 = header.getOrDefault("X-Amz-Security-Token")
  valid_606531 = validateParameter(valid_606531, JString, required = false,
                                 default = nil)
  if valid_606531 != nil:
    section.add "X-Amz-Security-Token", valid_606531
  var valid_606532 = header.getOrDefault("X-Amz-Algorithm")
  valid_606532 = validateParameter(valid_606532, JString, required = false,
                                 default = nil)
  if valid_606532 != nil:
    section.add "X-Amz-Algorithm", valid_606532
  var valid_606533 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606533 = validateParameter(valid_606533, JString, required = false,
                                 default = nil)
  if valid_606533 != nil:
    section.add "X-Amz-SignedHeaders", valid_606533
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606535: Call_ListTagsForResource_606521; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all tags on an AWS IoT Things Graph resource.
  ## 
  let valid = call_606535.validator(path, query, header, formData, body)
  let scheme = call_606535.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606535.url(scheme.get, call_606535.host, call_606535.base,
                         call_606535.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606535, url, valid)

proc call*(call_606536: Call_ListTagsForResource_606521; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listTagsForResource
  ## Lists all tags on an AWS IoT Things Graph resource.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606537 = newJObject()
  var body_606538 = newJObject()
  add(query_606537, "nextToken", newJString(nextToken))
  if body != nil:
    body_606538 = body
  add(query_606537, "maxResults", newJString(maxResults))
  result = call_606536.call(nil, query_606537, nil, nil, body_606538)

var listTagsForResource* = Call_ListTagsForResource_606521(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.ListTagsForResource",
    validator: validate_ListTagsForResource_606522, base: "/",
    url: url_ListTagsForResource_606523, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchEntities_606539 = ref object of OpenApiRestCall_605589
proc url_SearchEntities_606541(protocol: Scheme; host: string; base: string;
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

proc validate_SearchEntities_606540(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Searches for entities of the specified type. You can search for entities in your namespace and the public namespace that you're tracking.
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
  var valid_606542 = query.getOrDefault("nextToken")
  valid_606542 = validateParameter(valid_606542, JString, required = false,
                                 default = nil)
  if valid_606542 != nil:
    section.add "nextToken", valid_606542
  var valid_606543 = query.getOrDefault("maxResults")
  valid_606543 = validateParameter(valid_606543, JString, required = false,
                                 default = nil)
  if valid_606543 != nil:
    section.add "maxResults", valid_606543
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_606544 = header.getOrDefault("X-Amz-Target")
  valid_606544 = validateParameter(valid_606544, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.SearchEntities"))
  if valid_606544 != nil:
    section.add "X-Amz-Target", valid_606544
  var valid_606545 = header.getOrDefault("X-Amz-Signature")
  valid_606545 = validateParameter(valid_606545, JString, required = false,
                                 default = nil)
  if valid_606545 != nil:
    section.add "X-Amz-Signature", valid_606545
  var valid_606546 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606546 = validateParameter(valid_606546, JString, required = false,
                                 default = nil)
  if valid_606546 != nil:
    section.add "X-Amz-Content-Sha256", valid_606546
  var valid_606547 = header.getOrDefault("X-Amz-Date")
  valid_606547 = validateParameter(valid_606547, JString, required = false,
                                 default = nil)
  if valid_606547 != nil:
    section.add "X-Amz-Date", valid_606547
  var valid_606548 = header.getOrDefault("X-Amz-Credential")
  valid_606548 = validateParameter(valid_606548, JString, required = false,
                                 default = nil)
  if valid_606548 != nil:
    section.add "X-Amz-Credential", valid_606548
  var valid_606549 = header.getOrDefault("X-Amz-Security-Token")
  valid_606549 = validateParameter(valid_606549, JString, required = false,
                                 default = nil)
  if valid_606549 != nil:
    section.add "X-Amz-Security-Token", valid_606549
  var valid_606550 = header.getOrDefault("X-Amz-Algorithm")
  valid_606550 = validateParameter(valid_606550, JString, required = false,
                                 default = nil)
  if valid_606550 != nil:
    section.add "X-Amz-Algorithm", valid_606550
  var valid_606551 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606551 = validateParameter(valid_606551, JString, required = false,
                                 default = nil)
  if valid_606551 != nil:
    section.add "X-Amz-SignedHeaders", valid_606551
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606553: Call_SearchEntities_606539; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches for entities of the specified type. You can search for entities in your namespace and the public namespace that you're tracking.
  ## 
  let valid = call_606553.validator(path, query, header, formData, body)
  let scheme = call_606553.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606553.url(scheme.get, call_606553.host, call_606553.base,
                         call_606553.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606553, url, valid)

proc call*(call_606554: Call_SearchEntities_606539; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## searchEntities
  ## Searches for entities of the specified type. You can search for entities in your namespace and the public namespace that you're tracking.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606555 = newJObject()
  var body_606556 = newJObject()
  add(query_606555, "nextToken", newJString(nextToken))
  if body != nil:
    body_606556 = body
  add(query_606555, "maxResults", newJString(maxResults))
  result = call_606554.call(nil, query_606555, nil, nil, body_606556)

var searchEntities* = Call_SearchEntities_606539(name: "searchEntities",
    meth: HttpMethod.HttpPost, host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.SearchEntities",
    validator: validate_SearchEntities_606540, base: "/", url: url_SearchEntities_606541,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchFlowExecutions_606557 = ref object of OpenApiRestCall_605589
proc url_SearchFlowExecutions_606559(protocol: Scheme; host: string; base: string;
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

proc validate_SearchFlowExecutions_606558(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Searches for AWS IoT Things Graph workflow execution instances.
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
  var valid_606560 = query.getOrDefault("nextToken")
  valid_606560 = validateParameter(valid_606560, JString, required = false,
                                 default = nil)
  if valid_606560 != nil:
    section.add "nextToken", valid_606560
  var valid_606561 = query.getOrDefault("maxResults")
  valid_606561 = validateParameter(valid_606561, JString, required = false,
                                 default = nil)
  if valid_606561 != nil:
    section.add "maxResults", valid_606561
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_606562 = header.getOrDefault("X-Amz-Target")
  valid_606562 = validateParameter(valid_606562, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.SearchFlowExecutions"))
  if valid_606562 != nil:
    section.add "X-Amz-Target", valid_606562
  var valid_606563 = header.getOrDefault("X-Amz-Signature")
  valid_606563 = validateParameter(valid_606563, JString, required = false,
                                 default = nil)
  if valid_606563 != nil:
    section.add "X-Amz-Signature", valid_606563
  var valid_606564 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606564 = validateParameter(valid_606564, JString, required = false,
                                 default = nil)
  if valid_606564 != nil:
    section.add "X-Amz-Content-Sha256", valid_606564
  var valid_606565 = header.getOrDefault("X-Amz-Date")
  valid_606565 = validateParameter(valid_606565, JString, required = false,
                                 default = nil)
  if valid_606565 != nil:
    section.add "X-Amz-Date", valid_606565
  var valid_606566 = header.getOrDefault("X-Amz-Credential")
  valid_606566 = validateParameter(valid_606566, JString, required = false,
                                 default = nil)
  if valid_606566 != nil:
    section.add "X-Amz-Credential", valid_606566
  var valid_606567 = header.getOrDefault("X-Amz-Security-Token")
  valid_606567 = validateParameter(valid_606567, JString, required = false,
                                 default = nil)
  if valid_606567 != nil:
    section.add "X-Amz-Security-Token", valid_606567
  var valid_606568 = header.getOrDefault("X-Amz-Algorithm")
  valid_606568 = validateParameter(valid_606568, JString, required = false,
                                 default = nil)
  if valid_606568 != nil:
    section.add "X-Amz-Algorithm", valid_606568
  var valid_606569 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606569 = validateParameter(valid_606569, JString, required = false,
                                 default = nil)
  if valid_606569 != nil:
    section.add "X-Amz-SignedHeaders", valid_606569
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606571: Call_SearchFlowExecutions_606557; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches for AWS IoT Things Graph workflow execution instances.
  ## 
  let valid = call_606571.validator(path, query, header, formData, body)
  let scheme = call_606571.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606571.url(scheme.get, call_606571.host, call_606571.base,
                         call_606571.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606571, url, valid)

proc call*(call_606572: Call_SearchFlowExecutions_606557; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## searchFlowExecutions
  ## Searches for AWS IoT Things Graph workflow execution instances.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606573 = newJObject()
  var body_606574 = newJObject()
  add(query_606573, "nextToken", newJString(nextToken))
  if body != nil:
    body_606574 = body
  add(query_606573, "maxResults", newJString(maxResults))
  result = call_606572.call(nil, query_606573, nil, nil, body_606574)

var searchFlowExecutions* = Call_SearchFlowExecutions_606557(
    name: "searchFlowExecutions", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.SearchFlowExecutions",
    validator: validate_SearchFlowExecutions_606558, base: "/",
    url: url_SearchFlowExecutions_606559, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchFlowTemplates_606575 = ref object of OpenApiRestCall_605589
proc url_SearchFlowTemplates_606577(protocol: Scheme; host: string; base: string;
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

proc validate_SearchFlowTemplates_606576(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Searches for summary information about workflows.
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
  var valid_606578 = query.getOrDefault("nextToken")
  valid_606578 = validateParameter(valid_606578, JString, required = false,
                                 default = nil)
  if valid_606578 != nil:
    section.add "nextToken", valid_606578
  var valid_606579 = query.getOrDefault("maxResults")
  valid_606579 = validateParameter(valid_606579, JString, required = false,
                                 default = nil)
  if valid_606579 != nil:
    section.add "maxResults", valid_606579
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_606580 = header.getOrDefault("X-Amz-Target")
  valid_606580 = validateParameter(valid_606580, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.SearchFlowTemplates"))
  if valid_606580 != nil:
    section.add "X-Amz-Target", valid_606580
  var valid_606581 = header.getOrDefault("X-Amz-Signature")
  valid_606581 = validateParameter(valid_606581, JString, required = false,
                                 default = nil)
  if valid_606581 != nil:
    section.add "X-Amz-Signature", valid_606581
  var valid_606582 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606582 = validateParameter(valid_606582, JString, required = false,
                                 default = nil)
  if valid_606582 != nil:
    section.add "X-Amz-Content-Sha256", valid_606582
  var valid_606583 = header.getOrDefault("X-Amz-Date")
  valid_606583 = validateParameter(valid_606583, JString, required = false,
                                 default = nil)
  if valid_606583 != nil:
    section.add "X-Amz-Date", valid_606583
  var valid_606584 = header.getOrDefault("X-Amz-Credential")
  valid_606584 = validateParameter(valid_606584, JString, required = false,
                                 default = nil)
  if valid_606584 != nil:
    section.add "X-Amz-Credential", valid_606584
  var valid_606585 = header.getOrDefault("X-Amz-Security-Token")
  valid_606585 = validateParameter(valid_606585, JString, required = false,
                                 default = nil)
  if valid_606585 != nil:
    section.add "X-Amz-Security-Token", valid_606585
  var valid_606586 = header.getOrDefault("X-Amz-Algorithm")
  valid_606586 = validateParameter(valid_606586, JString, required = false,
                                 default = nil)
  if valid_606586 != nil:
    section.add "X-Amz-Algorithm", valid_606586
  var valid_606587 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606587 = validateParameter(valid_606587, JString, required = false,
                                 default = nil)
  if valid_606587 != nil:
    section.add "X-Amz-SignedHeaders", valid_606587
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606589: Call_SearchFlowTemplates_606575; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches for summary information about workflows.
  ## 
  let valid = call_606589.validator(path, query, header, formData, body)
  let scheme = call_606589.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606589.url(scheme.get, call_606589.host, call_606589.base,
                         call_606589.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606589, url, valid)

proc call*(call_606590: Call_SearchFlowTemplates_606575; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## searchFlowTemplates
  ## Searches for summary information about workflows.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606591 = newJObject()
  var body_606592 = newJObject()
  add(query_606591, "nextToken", newJString(nextToken))
  if body != nil:
    body_606592 = body
  add(query_606591, "maxResults", newJString(maxResults))
  result = call_606590.call(nil, query_606591, nil, nil, body_606592)

var searchFlowTemplates* = Call_SearchFlowTemplates_606575(
    name: "searchFlowTemplates", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.SearchFlowTemplates",
    validator: validate_SearchFlowTemplates_606576, base: "/",
    url: url_SearchFlowTemplates_606577, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchSystemInstances_606593 = ref object of OpenApiRestCall_605589
proc url_SearchSystemInstances_606595(protocol: Scheme; host: string; base: string;
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

proc validate_SearchSystemInstances_606594(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Searches for system instances in the user's account.
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
  var valid_606596 = query.getOrDefault("nextToken")
  valid_606596 = validateParameter(valid_606596, JString, required = false,
                                 default = nil)
  if valid_606596 != nil:
    section.add "nextToken", valid_606596
  var valid_606597 = query.getOrDefault("maxResults")
  valid_606597 = validateParameter(valid_606597, JString, required = false,
                                 default = nil)
  if valid_606597 != nil:
    section.add "maxResults", valid_606597
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_606598 = header.getOrDefault("X-Amz-Target")
  valid_606598 = validateParameter(valid_606598, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.SearchSystemInstances"))
  if valid_606598 != nil:
    section.add "X-Amz-Target", valid_606598
  var valid_606599 = header.getOrDefault("X-Amz-Signature")
  valid_606599 = validateParameter(valid_606599, JString, required = false,
                                 default = nil)
  if valid_606599 != nil:
    section.add "X-Amz-Signature", valid_606599
  var valid_606600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606600 = validateParameter(valid_606600, JString, required = false,
                                 default = nil)
  if valid_606600 != nil:
    section.add "X-Amz-Content-Sha256", valid_606600
  var valid_606601 = header.getOrDefault("X-Amz-Date")
  valid_606601 = validateParameter(valid_606601, JString, required = false,
                                 default = nil)
  if valid_606601 != nil:
    section.add "X-Amz-Date", valid_606601
  var valid_606602 = header.getOrDefault("X-Amz-Credential")
  valid_606602 = validateParameter(valid_606602, JString, required = false,
                                 default = nil)
  if valid_606602 != nil:
    section.add "X-Amz-Credential", valid_606602
  var valid_606603 = header.getOrDefault("X-Amz-Security-Token")
  valid_606603 = validateParameter(valid_606603, JString, required = false,
                                 default = nil)
  if valid_606603 != nil:
    section.add "X-Amz-Security-Token", valid_606603
  var valid_606604 = header.getOrDefault("X-Amz-Algorithm")
  valid_606604 = validateParameter(valid_606604, JString, required = false,
                                 default = nil)
  if valid_606604 != nil:
    section.add "X-Amz-Algorithm", valid_606604
  var valid_606605 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606605 = validateParameter(valid_606605, JString, required = false,
                                 default = nil)
  if valid_606605 != nil:
    section.add "X-Amz-SignedHeaders", valid_606605
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606607: Call_SearchSystemInstances_606593; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches for system instances in the user's account.
  ## 
  let valid = call_606607.validator(path, query, header, formData, body)
  let scheme = call_606607.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606607.url(scheme.get, call_606607.host, call_606607.base,
                         call_606607.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606607, url, valid)

proc call*(call_606608: Call_SearchSystemInstances_606593; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## searchSystemInstances
  ## Searches for system instances in the user's account.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606609 = newJObject()
  var body_606610 = newJObject()
  add(query_606609, "nextToken", newJString(nextToken))
  if body != nil:
    body_606610 = body
  add(query_606609, "maxResults", newJString(maxResults))
  result = call_606608.call(nil, query_606609, nil, nil, body_606610)

var searchSystemInstances* = Call_SearchSystemInstances_606593(
    name: "searchSystemInstances", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com", route: "/#X-Amz-Target=IotThingsGraphFrontEndService.SearchSystemInstances",
    validator: validate_SearchSystemInstances_606594, base: "/",
    url: url_SearchSystemInstances_606595, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchSystemTemplates_606611 = ref object of OpenApiRestCall_605589
proc url_SearchSystemTemplates_606613(protocol: Scheme; host: string; base: string;
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

proc validate_SearchSystemTemplates_606612(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Searches for summary information about systems in the user's account. You can filter by the ID of a workflow to return only systems that use the specified workflow.
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
  var valid_606614 = query.getOrDefault("nextToken")
  valid_606614 = validateParameter(valid_606614, JString, required = false,
                                 default = nil)
  if valid_606614 != nil:
    section.add "nextToken", valid_606614
  var valid_606615 = query.getOrDefault("maxResults")
  valid_606615 = validateParameter(valid_606615, JString, required = false,
                                 default = nil)
  if valid_606615 != nil:
    section.add "maxResults", valid_606615
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_606616 = header.getOrDefault("X-Amz-Target")
  valid_606616 = validateParameter(valid_606616, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.SearchSystemTemplates"))
  if valid_606616 != nil:
    section.add "X-Amz-Target", valid_606616
  var valid_606617 = header.getOrDefault("X-Amz-Signature")
  valid_606617 = validateParameter(valid_606617, JString, required = false,
                                 default = nil)
  if valid_606617 != nil:
    section.add "X-Amz-Signature", valid_606617
  var valid_606618 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606618 = validateParameter(valid_606618, JString, required = false,
                                 default = nil)
  if valid_606618 != nil:
    section.add "X-Amz-Content-Sha256", valid_606618
  var valid_606619 = header.getOrDefault("X-Amz-Date")
  valid_606619 = validateParameter(valid_606619, JString, required = false,
                                 default = nil)
  if valid_606619 != nil:
    section.add "X-Amz-Date", valid_606619
  var valid_606620 = header.getOrDefault("X-Amz-Credential")
  valid_606620 = validateParameter(valid_606620, JString, required = false,
                                 default = nil)
  if valid_606620 != nil:
    section.add "X-Amz-Credential", valid_606620
  var valid_606621 = header.getOrDefault("X-Amz-Security-Token")
  valid_606621 = validateParameter(valid_606621, JString, required = false,
                                 default = nil)
  if valid_606621 != nil:
    section.add "X-Amz-Security-Token", valid_606621
  var valid_606622 = header.getOrDefault("X-Amz-Algorithm")
  valid_606622 = validateParameter(valid_606622, JString, required = false,
                                 default = nil)
  if valid_606622 != nil:
    section.add "X-Amz-Algorithm", valid_606622
  var valid_606623 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606623 = validateParameter(valid_606623, JString, required = false,
                                 default = nil)
  if valid_606623 != nil:
    section.add "X-Amz-SignedHeaders", valid_606623
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606625: Call_SearchSystemTemplates_606611; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches for summary information about systems in the user's account. You can filter by the ID of a workflow to return only systems that use the specified workflow.
  ## 
  let valid = call_606625.validator(path, query, header, formData, body)
  let scheme = call_606625.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606625.url(scheme.get, call_606625.host, call_606625.base,
                         call_606625.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606625, url, valid)

proc call*(call_606626: Call_SearchSystemTemplates_606611; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## searchSystemTemplates
  ## Searches for summary information about systems in the user's account. You can filter by the ID of a workflow to return only systems that use the specified workflow.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606627 = newJObject()
  var body_606628 = newJObject()
  add(query_606627, "nextToken", newJString(nextToken))
  if body != nil:
    body_606628 = body
  add(query_606627, "maxResults", newJString(maxResults))
  result = call_606626.call(nil, query_606627, nil, nil, body_606628)

var searchSystemTemplates* = Call_SearchSystemTemplates_606611(
    name: "searchSystemTemplates", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com", route: "/#X-Amz-Target=IotThingsGraphFrontEndService.SearchSystemTemplates",
    validator: validate_SearchSystemTemplates_606612, base: "/",
    url: url_SearchSystemTemplates_606613, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchThings_606629 = ref object of OpenApiRestCall_605589
proc url_SearchThings_606631(protocol: Scheme; host: string; base: string;
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

proc validate_SearchThings_606630(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Searches for things associated with the specified entity. You can search by both device and device model.</p> <p>For example, if two different devices, camera1 and camera2, implement the camera device model, the user can associate thing1 to camera1 and thing2 to camera2. <code>SearchThings(camera2)</code> will return only thing2, but <code>SearchThings(camera)</code> will return both thing1 and thing2.</p> <p>This action searches for exact matches and doesn't perform partial text matching.</p>
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
  var valid_606632 = query.getOrDefault("nextToken")
  valid_606632 = validateParameter(valid_606632, JString, required = false,
                                 default = nil)
  if valid_606632 != nil:
    section.add "nextToken", valid_606632
  var valid_606633 = query.getOrDefault("maxResults")
  valid_606633 = validateParameter(valid_606633, JString, required = false,
                                 default = nil)
  if valid_606633 != nil:
    section.add "maxResults", valid_606633
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_606634 = header.getOrDefault("X-Amz-Target")
  valid_606634 = validateParameter(valid_606634, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.SearchThings"))
  if valid_606634 != nil:
    section.add "X-Amz-Target", valid_606634
  var valid_606635 = header.getOrDefault("X-Amz-Signature")
  valid_606635 = validateParameter(valid_606635, JString, required = false,
                                 default = nil)
  if valid_606635 != nil:
    section.add "X-Amz-Signature", valid_606635
  var valid_606636 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606636 = validateParameter(valid_606636, JString, required = false,
                                 default = nil)
  if valid_606636 != nil:
    section.add "X-Amz-Content-Sha256", valid_606636
  var valid_606637 = header.getOrDefault("X-Amz-Date")
  valid_606637 = validateParameter(valid_606637, JString, required = false,
                                 default = nil)
  if valid_606637 != nil:
    section.add "X-Amz-Date", valid_606637
  var valid_606638 = header.getOrDefault("X-Amz-Credential")
  valid_606638 = validateParameter(valid_606638, JString, required = false,
                                 default = nil)
  if valid_606638 != nil:
    section.add "X-Amz-Credential", valid_606638
  var valid_606639 = header.getOrDefault("X-Amz-Security-Token")
  valid_606639 = validateParameter(valid_606639, JString, required = false,
                                 default = nil)
  if valid_606639 != nil:
    section.add "X-Amz-Security-Token", valid_606639
  var valid_606640 = header.getOrDefault("X-Amz-Algorithm")
  valid_606640 = validateParameter(valid_606640, JString, required = false,
                                 default = nil)
  if valid_606640 != nil:
    section.add "X-Amz-Algorithm", valid_606640
  var valid_606641 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606641 = validateParameter(valid_606641, JString, required = false,
                                 default = nil)
  if valid_606641 != nil:
    section.add "X-Amz-SignedHeaders", valid_606641
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606643: Call_SearchThings_606629; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Searches for things associated with the specified entity. You can search by both device and device model.</p> <p>For example, if two different devices, camera1 and camera2, implement the camera device model, the user can associate thing1 to camera1 and thing2 to camera2. <code>SearchThings(camera2)</code> will return only thing2, but <code>SearchThings(camera)</code> will return both thing1 and thing2.</p> <p>This action searches for exact matches and doesn't perform partial text matching.</p>
  ## 
  let valid = call_606643.validator(path, query, header, formData, body)
  let scheme = call_606643.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606643.url(scheme.get, call_606643.host, call_606643.base,
                         call_606643.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606643, url, valid)

proc call*(call_606644: Call_SearchThings_606629; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## searchThings
  ## <p>Searches for things associated with the specified entity. You can search by both device and device model.</p> <p>For example, if two different devices, camera1 and camera2, implement the camera device model, the user can associate thing1 to camera1 and thing2 to camera2. <code>SearchThings(camera2)</code> will return only thing2, but <code>SearchThings(camera)</code> will return both thing1 and thing2.</p> <p>This action searches for exact matches and doesn't perform partial text matching.</p>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606645 = newJObject()
  var body_606646 = newJObject()
  add(query_606645, "nextToken", newJString(nextToken))
  if body != nil:
    body_606646 = body
  add(query_606645, "maxResults", newJString(maxResults))
  result = call_606644.call(nil, query_606645, nil, nil, body_606646)

var searchThings* = Call_SearchThings_606629(name: "searchThings",
    meth: HttpMethod.HttpPost, host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.SearchThings",
    validator: validate_SearchThings_606630, base: "/", url: url_SearchThings_606631,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_606647 = ref object of OpenApiRestCall_605589
proc url_TagResource_606649(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_606648(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a tag for the specified resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_606650 = header.getOrDefault("X-Amz-Target")
  valid_606650 = validateParameter(valid_606650, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.TagResource"))
  if valid_606650 != nil:
    section.add "X-Amz-Target", valid_606650
  var valid_606651 = header.getOrDefault("X-Amz-Signature")
  valid_606651 = validateParameter(valid_606651, JString, required = false,
                                 default = nil)
  if valid_606651 != nil:
    section.add "X-Amz-Signature", valid_606651
  var valid_606652 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606652 = validateParameter(valid_606652, JString, required = false,
                                 default = nil)
  if valid_606652 != nil:
    section.add "X-Amz-Content-Sha256", valid_606652
  var valid_606653 = header.getOrDefault("X-Amz-Date")
  valid_606653 = validateParameter(valid_606653, JString, required = false,
                                 default = nil)
  if valid_606653 != nil:
    section.add "X-Amz-Date", valid_606653
  var valid_606654 = header.getOrDefault("X-Amz-Credential")
  valid_606654 = validateParameter(valid_606654, JString, required = false,
                                 default = nil)
  if valid_606654 != nil:
    section.add "X-Amz-Credential", valid_606654
  var valid_606655 = header.getOrDefault("X-Amz-Security-Token")
  valid_606655 = validateParameter(valid_606655, JString, required = false,
                                 default = nil)
  if valid_606655 != nil:
    section.add "X-Amz-Security-Token", valid_606655
  var valid_606656 = header.getOrDefault("X-Amz-Algorithm")
  valid_606656 = validateParameter(valid_606656, JString, required = false,
                                 default = nil)
  if valid_606656 != nil:
    section.add "X-Amz-Algorithm", valid_606656
  var valid_606657 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606657 = validateParameter(valid_606657, JString, required = false,
                                 default = nil)
  if valid_606657 != nil:
    section.add "X-Amz-SignedHeaders", valid_606657
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606659: Call_TagResource_606647; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a tag for the specified resource.
  ## 
  let valid = call_606659.validator(path, query, header, formData, body)
  let scheme = call_606659.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606659.url(scheme.get, call_606659.host, call_606659.base,
                         call_606659.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606659, url, valid)

proc call*(call_606660: Call_TagResource_606647; body: JsonNode): Recallable =
  ## tagResource
  ## Creates a tag for the specified resource.
  ##   body: JObject (required)
  var body_606661 = newJObject()
  if body != nil:
    body_606661 = body
  result = call_606660.call(nil, nil, nil, nil, body_606661)

var tagResource* = Call_TagResource_606647(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "iotthingsgraph.amazonaws.com", route: "/#X-Amz-Target=IotThingsGraphFrontEndService.TagResource",
                                        validator: validate_TagResource_606648,
                                        base: "/", url: url_TagResource_606649,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UndeploySystemInstance_606662 = ref object of OpenApiRestCall_605589
proc url_UndeploySystemInstance_606664(protocol: Scheme; host: string; base: string;
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

proc validate_UndeploySystemInstance_606663(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes a system instance from its target (Cloud or Greengrass).
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_606665 = header.getOrDefault("X-Amz-Target")
  valid_606665 = validateParameter(valid_606665, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.UndeploySystemInstance"))
  if valid_606665 != nil:
    section.add "X-Amz-Target", valid_606665
  var valid_606666 = header.getOrDefault("X-Amz-Signature")
  valid_606666 = validateParameter(valid_606666, JString, required = false,
                                 default = nil)
  if valid_606666 != nil:
    section.add "X-Amz-Signature", valid_606666
  var valid_606667 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606667 = validateParameter(valid_606667, JString, required = false,
                                 default = nil)
  if valid_606667 != nil:
    section.add "X-Amz-Content-Sha256", valid_606667
  var valid_606668 = header.getOrDefault("X-Amz-Date")
  valid_606668 = validateParameter(valid_606668, JString, required = false,
                                 default = nil)
  if valid_606668 != nil:
    section.add "X-Amz-Date", valid_606668
  var valid_606669 = header.getOrDefault("X-Amz-Credential")
  valid_606669 = validateParameter(valid_606669, JString, required = false,
                                 default = nil)
  if valid_606669 != nil:
    section.add "X-Amz-Credential", valid_606669
  var valid_606670 = header.getOrDefault("X-Amz-Security-Token")
  valid_606670 = validateParameter(valid_606670, JString, required = false,
                                 default = nil)
  if valid_606670 != nil:
    section.add "X-Amz-Security-Token", valid_606670
  var valid_606671 = header.getOrDefault("X-Amz-Algorithm")
  valid_606671 = validateParameter(valid_606671, JString, required = false,
                                 default = nil)
  if valid_606671 != nil:
    section.add "X-Amz-Algorithm", valid_606671
  var valid_606672 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606672 = validateParameter(valid_606672, JString, required = false,
                                 default = nil)
  if valid_606672 != nil:
    section.add "X-Amz-SignedHeaders", valid_606672
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606674: Call_UndeploySystemInstance_606662; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a system instance from its target (Cloud or Greengrass).
  ## 
  let valid = call_606674.validator(path, query, header, formData, body)
  let scheme = call_606674.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606674.url(scheme.get, call_606674.host, call_606674.base,
                         call_606674.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606674, url, valid)

proc call*(call_606675: Call_UndeploySystemInstance_606662; body: JsonNode): Recallable =
  ## undeploySystemInstance
  ## Removes a system instance from its target (Cloud or Greengrass).
  ##   body: JObject (required)
  var body_606676 = newJObject()
  if body != nil:
    body_606676 = body
  result = call_606675.call(nil, nil, nil, nil, body_606676)

var undeploySystemInstance* = Call_UndeploySystemInstance_606662(
    name: "undeploySystemInstance", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com", route: "/#X-Amz-Target=IotThingsGraphFrontEndService.UndeploySystemInstance",
    validator: validate_UndeploySystemInstance_606663, base: "/",
    url: url_UndeploySystemInstance_606664, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_606677 = ref object of OpenApiRestCall_605589
proc url_UntagResource_606679(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_606678(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes a tag from the specified resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_606680 = header.getOrDefault("X-Amz-Target")
  valid_606680 = validateParameter(valid_606680, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.UntagResource"))
  if valid_606680 != nil:
    section.add "X-Amz-Target", valid_606680
  var valid_606681 = header.getOrDefault("X-Amz-Signature")
  valid_606681 = validateParameter(valid_606681, JString, required = false,
                                 default = nil)
  if valid_606681 != nil:
    section.add "X-Amz-Signature", valid_606681
  var valid_606682 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606682 = validateParameter(valid_606682, JString, required = false,
                                 default = nil)
  if valid_606682 != nil:
    section.add "X-Amz-Content-Sha256", valid_606682
  var valid_606683 = header.getOrDefault("X-Amz-Date")
  valid_606683 = validateParameter(valid_606683, JString, required = false,
                                 default = nil)
  if valid_606683 != nil:
    section.add "X-Amz-Date", valid_606683
  var valid_606684 = header.getOrDefault("X-Amz-Credential")
  valid_606684 = validateParameter(valid_606684, JString, required = false,
                                 default = nil)
  if valid_606684 != nil:
    section.add "X-Amz-Credential", valid_606684
  var valid_606685 = header.getOrDefault("X-Amz-Security-Token")
  valid_606685 = validateParameter(valid_606685, JString, required = false,
                                 default = nil)
  if valid_606685 != nil:
    section.add "X-Amz-Security-Token", valid_606685
  var valid_606686 = header.getOrDefault("X-Amz-Algorithm")
  valid_606686 = validateParameter(valid_606686, JString, required = false,
                                 default = nil)
  if valid_606686 != nil:
    section.add "X-Amz-Algorithm", valid_606686
  var valid_606687 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606687 = validateParameter(valid_606687, JString, required = false,
                                 default = nil)
  if valid_606687 != nil:
    section.add "X-Amz-SignedHeaders", valid_606687
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606689: Call_UntagResource_606677; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a tag from the specified resource.
  ## 
  let valid = call_606689.validator(path, query, header, formData, body)
  let scheme = call_606689.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606689.url(scheme.get, call_606689.host, call_606689.base,
                         call_606689.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606689, url, valid)

proc call*(call_606690: Call_UntagResource_606677; body: JsonNode): Recallable =
  ## untagResource
  ## Removes a tag from the specified resource.
  ##   body: JObject (required)
  var body_606691 = newJObject()
  if body != nil:
    body_606691 = body
  result = call_606690.call(nil, nil, nil, nil, body_606691)

var untagResource* = Call_UntagResource_606677(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.UntagResource",
    validator: validate_UntagResource_606678, base: "/", url: url_UntagResource_606679,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFlowTemplate_606692 = ref object of OpenApiRestCall_605589
proc url_UpdateFlowTemplate_606694(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateFlowTemplate_606693(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Updates the specified workflow. All deployed systems and system instances that use the workflow will see the changes in the flow when it is redeployed. If you don't want this behavior, copy the workflow (creating a new workflow with a different ID), and update the copy. The workflow can contain only entities in the specified namespace. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_606695 = header.getOrDefault("X-Amz-Target")
  valid_606695 = validateParameter(valid_606695, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.UpdateFlowTemplate"))
  if valid_606695 != nil:
    section.add "X-Amz-Target", valid_606695
  var valid_606696 = header.getOrDefault("X-Amz-Signature")
  valid_606696 = validateParameter(valid_606696, JString, required = false,
                                 default = nil)
  if valid_606696 != nil:
    section.add "X-Amz-Signature", valid_606696
  var valid_606697 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606697 = validateParameter(valid_606697, JString, required = false,
                                 default = nil)
  if valid_606697 != nil:
    section.add "X-Amz-Content-Sha256", valid_606697
  var valid_606698 = header.getOrDefault("X-Amz-Date")
  valid_606698 = validateParameter(valid_606698, JString, required = false,
                                 default = nil)
  if valid_606698 != nil:
    section.add "X-Amz-Date", valid_606698
  var valid_606699 = header.getOrDefault("X-Amz-Credential")
  valid_606699 = validateParameter(valid_606699, JString, required = false,
                                 default = nil)
  if valid_606699 != nil:
    section.add "X-Amz-Credential", valid_606699
  var valid_606700 = header.getOrDefault("X-Amz-Security-Token")
  valid_606700 = validateParameter(valid_606700, JString, required = false,
                                 default = nil)
  if valid_606700 != nil:
    section.add "X-Amz-Security-Token", valid_606700
  var valid_606701 = header.getOrDefault("X-Amz-Algorithm")
  valid_606701 = validateParameter(valid_606701, JString, required = false,
                                 default = nil)
  if valid_606701 != nil:
    section.add "X-Amz-Algorithm", valid_606701
  var valid_606702 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606702 = validateParameter(valid_606702, JString, required = false,
                                 default = nil)
  if valid_606702 != nil:
    section.add "X-Amz-SignedHeaders", valid_606702
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606704: Call_UpdateFlowTemplate_606692; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified workflow. All deployed systems and system instances that use the workflow will see the changes in the flow when it is redeployed. If you don't want this behavior, copy the workflow (creating a new workflow with a different ID), and update the copy. The workflow can contain only entities in the specified namespace. 
  ## 
  let valid = call_606704.validator(path, query, header, formData, body)
  let scheme = call_606704.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606704.url(scheme.get, call_606704.host, call_606704.base,
                         call_606704.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606704, url, valid)

proc call*(call_606705: Call_UpdateFlowTemplate_606692; body: JsonNode): Recallable =
  ## updateFlowTemplate
  ## Updates the specified workflow. All deployed systems and system instances that use the workflow will see the changes in the flow when it is redeployed. If you don't want this behavior, copy the workflow (creating a new workflow with a different ID), and update the copy. The workflow can contain only entities in the specified namespace. 
  ##   body: JObject (required)
  var body_606706 = newJObject()
  if body != nil:
    body_606706 = body
  result = call_606705.call(nil, nil, nil, nil, body_606706)

var updateFlowTemplate* = Call_UpdateFlowTemplate_606692(
    name: "updateFlowTemplate", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.UpdateFlowTemplate",
    validator: validate_UpdateFlowTemplate_606693, base: "/",
    url: url_UpdateFlowTemplate_606694, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSystemTemplate_606707 = ref object of OpenApiRestCall_605589
proc url_UpdateSystemTemplate_606709(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateSystemTemplate_606708(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the specified system. You don't need to run this action after updating a workflow. Any deployment that uses the system will see the changes in the system when it is redeployed.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_606710 = header.getOrDefault("X-Amz-Target")
  valid_606710 = validateParameter(valid_606710, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.UpdateSystemTemplate"))
  if valid_606710 != nil:
    section.add "X-Amz-Target", valid_606710
  var valid_606711 = header.getOrDefault("X-Amz-Signature")
  valid_606711 = validateParameter(valid_606711, JString, required = false,
                                 default = nil)
  if valid_606711 != nil:
    section.add "X-Amz-Signature", valid_606711
  var valid_606712 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606712 = validateParameter(valid_606712, JString, required = false,
                                 default = nil)
  if valid_606712 != nil:
    section.add "X-Amz-Content-Sha256", valid_606712
  var valid_606713 = header.getOrDefault("X-Amz-Date")
  valid_606713 = validateParameter(valid_606713, JString, required = false,
                                 default = nil)
  if valid_606713 != nil:
    section.add "X-Amz-Date", valid_606713
  var valid_606714 = header.getOrDefault("X-Amz-Credential")
  valid_606714 = validateParameter(valid_606714, JString, required = false,
                                 default = nil)
  if valid_606714 != nil:
    section.add "X-Amz-Credential", valid_606714
  var valid_606715 = header.getOrDefault("X-Amz-Security-Token")
  valid_606715 = validateParameter(valid_606715, JString, required = false,
                                 default = nil)
  if valid_606715 != nil:
    section.add "X-Amz-Security-Token", valid_606715
  var valid_606716 = header.getOrDefault("X-Amz-Algorithm")
  valid_606716 = validateParameter(valid_606716, JString, required = false,
                                 default = nil)
  if valid_606716 != nil:
    section.add "X-Amz-Algorithm", valid_606716
  var valid_606717 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606717 = validateParameter(valid_606717, JString, required = false,
                                 default = nil)
  if valid_606717 != nil:
    section.add "X-Amz-SignedHeaders", valid_606717
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606719: Call_UpdateSystemTemplate_606707; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified system. You don't need to run this action after updating a workflow. Any deployment that uses the system will see the changes in the system when it is redeployed.
  ## 
  let valid = call_606719.validator(path, query, header, formData, body)
  let scheme = call_606719.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606719.url(scheme.get, call_606719.host, call_606719.base,
                         call_606719.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606719, url, valid)

proc call*(call_606720: Call_UpdateSystemTemplate_606707; body: JsonNode): Recallable =
  ## updateSystemTemplate
  ## Updates the specified system. You don't need to run this action after updating a workflow. Any deployment that uses the system will see the changes in the system when it is redeployed.
  ##   body: JObject (required)
  var body_606721 = newJObject()
  if body != nil:
    body_606721 = body
  result = call_606720.call(nil, nil, nil, nil, body_606721)

var updateSystemTemplate* = Call_UpdateSystemTemplate_606707(
    name: "updateSystemTemplate", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.UpdateSystemTemplate",
    validator: validate_UpdateSystemTemplate_606708, base: "/",
    url: url_UpdateSystemTemplate_606709, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UploadEntityDefinitions_606722 = ref object of OpenApiRestCall_605589
proc url_UploadEntityDefinitions_606724(protocol: Scheme; host: string; base: string;
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

proc validate_UploadEntityDefinitions_606723(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Asynchronously uploads one or more entity definitions to the user's namespace. The <code>document</code> parameter is required if <code>syncWithPublicNamespace</code> and <code>deleteExistingEntites</code> are false. If the <code>syncWithPublicNamespace</code> parameter is set to <code>true</code>, the user's namespace will synchronize with the latest version of the public namespace. If <code>deprecateExistingEntities</code> is set to true, all entities in the latest version will be deleted before the new <code>DefinitionDocument</code> is uploaded.</p> <p>When a user uploads entity definitions for the first time, the service creates a new namespace for the user. The new namespace tracks the public namespace. Currently users can have only one namespace. The namespace version increments whenever a user uploads entity definitions that are backwards-incompatible and whenever a user sets the <code>syncWithPublicNamespace</code> parameter or the <code>deprecateExistingEntities</code> parameter to <code>true</code>.</p> <p>The IDs for all of the entities should be in URN format. Each entity must be in the user's namespace. Users can't create entities in the public namespace, but entity definitions can refer to entities in the public namespace.</p> <p>Valid entities are <code>Device</code>, <code>DeviceModel</code>, <code>Service</code>, <code>Capability</code>, <code>State</code>, <code>Action</code>, <code>Event</code>, <code>Property</code>, <code>Mapping</code>, <code>Enum</code>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_606725 = header.getOrDefault("X-Amz-Target")
  valid_606725 = validateParameter(valid_606725, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.UploadEntityDefinitions"))
  if valid_606725 != nil:
    section.add "X-Amz-Target", valid_606725
  var valid_606726 = header.getOrDefault("X-Amz-Signature")
  valid_606726 = validateParameter(valid_606726, JString, required = false,
                                 default = nil)
  if valid_606726 != nil:
    section.add "X-Amz-Signature", valid_606726
  var valid_606727 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606727 = validateParameter(valid_606727, JString, required = false,
                                 default = nil)
  if valid_606727 != nil:
    section.add "X-Amz-Content-Sha256", valid_606727
  var valid_606728 = header.getOrDefault("X-Amz-Date")
  valid_606728 = validateParameter(valid_606728, JString, required = false,
                                 default = nil)
  if valid_606728 != nil:
    section.add "X-Amz-Date", valid_606728
  var valid_606729 = header.getOrDefault("X-Amz-Credential")
  valid_606729 = validateParameter(valid_606729, JString, required = false,
                                 default = nil)
  if valid_606729 != nil:
    section.add "X-Amz-Credential", valid_606729
  var valid_606730 = header.getOrDefault("X-Amz-Security-Token")
  valid_606730 = validateParameter(valid_606730, JString, required = false,
                                 default = nil)
  if valid_606730 != nil:
    section.add "X-Amz-Security-Token", valid_606730
  var valid_606731 = header.getOrDefault("X-Amz-Algorithm")
  valid_606731 = validateParameter(valid_606731, JString, required = false,
                                 default = nil)
  if valid_606731 != nil:
    section.add "X-Amz-Algorithm", valid_606731
  var valid_606732 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606732 = validateParameter(valid_606732, JString, required = false,
                                 default = nil)
  if valid_606732 != nil:
    section.add "X-Amz-SignedHeaders", valid_606732
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606734: Call_UploadEntityDefinitions_606722; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Asynchronously uploads one or more entity definitions to the user's namespace. The <code>document</code> parameter is required if <code>syncWithPublicNamespace</code> and <code>deleteExistingEntites</code> are false. If the <code>syncWithPublicNamespace</code> parameter is set to <code>true</code>, the user's namespace will synchronize with the latest version of the public namespace. If <code>deprecateExistingEntities</code> is set to true, all entities in the latest version will be deleted before the new <code>DefinitionDocument</code> is uploaded.</p> <p>When a user uploads entity definitions for the first time, the service creates a new namespace for the user. The new namespace tracks the public namespace. Currently users can have only one namespace. The namespace version increments whenever a user uploads entity definitions that are backwards-incompatible and whenever a user sets the <code>syncWithPublicNamespace</code> parameter or the <code>deprecateExistingEntities</code> parameter to <code>true</code>.</p> <p>The IDs for all of the entities should be in URN format. Each entity must be in the user's namespace. Users can't create entities in the public namespace, but entity definitions can refer to entities in the public namespace.</p> <p>Valid entities are <code>Device</code>, <code>DeviceModel</code>, <code>Service</code>, <code>Capability</code>, <code>State</code>, <code>Action</code>, <code>Event</code>, <code>Property</code>, <code>Mapping</code>, <code>Enum</code>. </p>
  ## 
  let valid = call_606734.validator(path, query, header, formData, body)
  let scheme = call_606734.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606734.url(scheme.get, call_606734.host, call_606734.base,
                         call_606734.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606734, url, valid)

proc call*(call_606735: Call_UploadEntityDefinitions_606722; body: JsonNode): Recallable =
  ## uploadEntityDefinitions
  ## <p>Asynchronously uploads one or more entity definitions to the user's namespace. The <code>document</code> parameter is required if <code>syncWithPublicNamespace</code> and <code>deleteExistingEntites</code> are false. If the <code>syncWithPublicNamespace</code> parameter is set to <code>true</code>, the user's namespace will synchronize with the latest version of the public namespace. If <code>deprecateExistingEntities</code> is set to true, all entities in the latest version will be deleted before the new <code>DefinitionDocument</code> is uploaded.</p> <p>When a user uploads entity definitions for the first time, the service creates a new namespace for the user. The new namespace tracks the public namespace. Currently users can have only one namespace. The namespace version increments whenever a user uploads entity definitions that are backwards-incompatible and whenever a user sets the <code>syncWithPublicNamespace</code> parameter or the <code>deprecateExistingEntities</code> parameter to <code>true</code>.</p> <p>The IDs for all of the entities should be in URN format. Each entity must be in the user's namespace. Users can't create entities in the public namespace, but entity definitions can refer to entities in the public namespace.</p> <p>Valid entities are <code>Device</code>, <code>DeviceModel</code>, <code>Service</code>, <code>Capability</code>, <code>State</code>, <code>Action</code>, <code>Event</code>, <code>Property</code>, <code>Mapping</code>, <code>Enum</code>. </p>
  ##   body: JObject (required)
  var body_606736 = newJObject()
  if body != nil:
    body_606736 = body
  result = call_606735.call(nil, nil, nil, nil, body_606736)

var uploadEntityDefinitions* = Call_UploadEntityDefinitions_606722(
    name: "uploadEntityDefinitions", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com", route: "/#X-Amz-Target=IotThingsGraphFrontEndService.UploadEntityDefinitions",
    validator: validate_UploadEntityDefinitions_606723, base: "/",
    url: url_UploadEntityDefinitions_606724, schemes: {Scheme.Https, Scheme.Http})
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
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
