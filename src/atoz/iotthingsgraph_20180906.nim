
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

  OpenApiRestCall_599368 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599368](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599368): Option[Scheme] {.used.} =
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
  Call_AssociateEntityToThing_599705 = ref object of OpenApiRestCall_599368
proc url_AssociateEntityToThing_599707(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateEntityToThing_599706(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599819 = header.getOrDefault("X-Amz-Date")
  valid_599819 = validateParameter(valid_599819, JString, required = false,
                                 default = nil)
  if valid_599819 != nil:
    section.add "X-Amz-Date", valid_599819
  var valid_599820 = header.getOrDefault("X-Amz-Security-Token")
  valid_599820 = validateParameter(valid_599820, JString, required = false,
                                 default = nil)
  if valid_599820 != nil:
    section.add "X-Amz-Security-Token", valid_599820
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599834 = header.getOrDefault("X-Amz-Target")
  valid_599834 = validateParameter(valid_599834, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.AssociateEntityToThing"))
  if valid_599834 != nil:
    section.add "X-Amz-Target", valid_599834
  var valid_599835 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599835 = validateParameter(valid_599835, JString, required = false,
                                 default = nil)
  if valid_599835 != nil:
    section.add "X-Amz-Content-Sha256", valid_599835
  var valid_599836 = header.getOrDefault("X-Amz-Algorithm")
  valid_599836 = validateParameter(valid_599836, JString, required = false,
                                 default = nil)
  if valid_599836 != nil:
    section.add "X-Amz-Algorithm", valid_599836
  var valid_599837 = header.getOrDefault("X-Amz-Signature")
  valid_599837 = validateParameter(valid_599837, JString, required = false,
                                 default = nil)
  if valid_599837 != nil:
    section.add "X-Amz-Signature", valid_599837
  var valid_599838 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599838 = validateParameter(valid_599838, JString, required = false,
                                 default = nil)
  if valid_599838 != nil:
    section.add "X-Amz-SignedHeaders", valid_599838
  var valid_599839 = header.getOrDefault("X-Amz-Credential")
  valid_599839 = validateParameter(valid_599839, JString, required = false,
                                 default = nil)
  if valid_599839 != nil:
    section.add "X-Amz-Credential", valid_599839
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599863: Call_AssociateEntityToThing_599705; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates a device with a concrete thing that is in the user's registry.</p> <p>A thing can be associated with only one device at a time. If you associate a thing with a new device id, its previous association will be removed.</p>
  ## 
  let valid = call_599863.validator(path, query, header, formData, body)
  let scheme = call_599863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599863.url(scheme.get, call_599863.host, call_599863.base,
                         call_599863.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599863, url, valid)

proc call*(call_599934: Call_AssociateEntityToThing_599705; body: JsonNode): Recallable =
  ## associateEntityToThing
  ## <p>Associates a device with a concrete thing that is in the user's registry.</p> <p>A thing can be associated with only one device at a time. If you associate a thing with a new device id, its previous association will be removed.</p>
  ##   body: JObject (required)
  var body_599935 = newJObject()
  if body != nil:
    body_599935 = body
  result = call_599934.call(nil, nil, nil, nil, body_599935)

var associateEntityToThing* = Call_AssociateEntityToThing_599705(
    name: "associateEntityToThing", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com", route: "/#X-Amz-Target=IotThingsGraphFrontEndService.AssociateEntityToThing",
    validator: validate_AssociateEntityToThing_599706, base: "/",
    url: url_AssociateEntityToThing_599707, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFlowTemplate_599974 = ref object of OpenApiRestCall_599368
proc url_CreateFlowTemplate_599976(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateFlowTemplate_599975(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599977 = header.getOrDefault("X-Amz-Date")
  valid_599977 = validateParameter(valid_599977, JString, required = false,
                                 default = nil)
  if valid_599977 != nil:
    section.add "X-Amz-Date", valid_599977
  var valid_599978 = header.getOrDefault("X-Amz-Security-Token")
  valid_599978 = validateParameter(valid_599978, JString, required = false,
                                 default = nil)
  if valid_599978 != nil:
    section.add "X-Amz-Security-Token", valid_599978
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599979 = header.getOrDefault("X-Amz-Target")
  valid_599979 = validateParameter(valid_599979, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.CreateFlowTemplate"))
  if valid_599979 != nil:
    section.add "X-Amz-Target", valid_599979
  var valid_599980 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599980 = validateParameter(valid_599980, JString, required = false,
                                 default = nil)
  if valid_599980 != nil:
    section.add "X-Amz-Content-Sha256", valid_599980
  var valid_599981 = header.getOrDefault("X-Amz-Algorithm")
  valid_599981 = validateParameter(valid_599981, JString, required = false,
                                 default = nil)
  if valid_599981 != nil:
    section.add "X-Amz-Algorithm", valid_599981
  var valid_599982 = header.getOrDefault("X-Amz-Signature")
  valid_599982 = validateParameter(valid_599982, JString, required = false,
                                 default = nil)
  if valid_599982 != nil:
    section.add "X-Amz-Signature", valid_599982
  var valid_599983 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599983 = validateParameter(valid_599983, JString, required = false,
                                 default = nil)
  if valid_599983 != nil:
    section.add "X-Amz-SignedHeaders", valid_599983
  var valid_599984 = header.getOrDefault("X-Amz-Credential")
  valid_599984 = validateParameter(valid_599984, JString, required = false,
                                 default = nil)
  if valid_599984 != nil:
    section.add "X-Amz-Credential", valid_599984
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599986: Call_CreateFlowTemplate_599974; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a workflow template. Workflows can be created only in the user's namespace. (The public namespace contains only entities.) The workflow can contain only entities in the specified namespace. The workflow is validated against the entities in the latest version of the user's namespace unless another namespace version is specified in the request.
  ## 
  let valid = call_599986.validator(path, query, header, formData, body)
  let scheme = call_599986.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599986.url(scheme.get, call_599986.host, call_599986.base,
                         call_599986.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599986, url, valid)

proc call*(call_599987: Call_CreateFlowTemplate_599974; body: JsonNode): Recallable =
  ## createFlowTemplate
  ## Creates a workflow template. Workflows can be created only in the user's namespace. (The public namespace contains only entities.) The workflow can contain only entities in the specified namespace. The workflow is validated against the entities in the latest version of the user's namespace unless another namespace version is specified in the request.
  ##   body: JObject (required)
  var body_599988 = newJObject()
  if body != nil:
    body_599988 = body
  result = call_599987.call(nil, nil, nil, nil, body_599988)

var createFlowTemplate* = Call_CreateFlowTemplate_599974(
    name: "createFlowTemplate", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.CreateFlowTemplate",
    validator: validate_CreateFlowTemplate_599975, base: "/",
    url: url_CreateFlowTemplate_599976, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSystemInstance_599989 = ref object of OpenApiRestCall_599368
proc url_CreateSystemInstance_599991(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateSystemInstance_599990(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599992 = header.getOrDefault("X-Amz-Date")
  valid_599992 = validateParameter(valid_599992, JString, required = false,
                                 default = nil)
  if valid_599992 != nil:
    section.add "X-Amz-Date", valid_599992
  var valid_599993 = header.getOrDefault("X-Amz-Security-Token")
  valid_599993 = validateParameter(valid_599993, JString, required = false,
                                 default = nil)
  if valid_599993 != nil:
    section.add "X-Amz-Security-Token", valid_599993
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599994 = header.getOrDefault("X-Amz-Target")
  valid_599994 = validateParameter(valid_599994, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.CreateSystemInstance"))
  if valid_599994 != nil:
    section.add "X-Amz-Target", valid_599994
  var valid_599995 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599995 = validateParameter(valid_599995, JString, required = false,
                                 default = nil)
  if valid_599995 != nil:
    section.add "X-Amz-Content-Sha256", valid_599995
  var valid_599996 = header.getOrDefault("X-Amz-Algorithm")
  valid_599996 = validateParameter(valid_599996, JString, required = false,
                                 default = nil)
  if valid_599996 != nil:
    section.add "X-Amz-Algorithm", valid_599996
  var valid_599997 = header.getOrDefault("X-Amz-Signature")
  valid_599997 = validateParameter(valid_599997, JString, required = false,
                                 default = nil)
  if valid_599997 != nil:
    section.add "X-Amz-Signature", valid_599997
  var valid_599998 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599998 = validateParameter(valid_599998, JString, required = false,
                                 default = nil)
  if valid_599998 != nil:
    section.add "X-Amz-SignedHeaders", valid_599998
  var valid_599999 = header.getOrDefault("X-Amz-Credential")
  valid_599999 = validateParameter(valid_599999, JString, required = false,
                                 default = nil)
  if valid_599999 != nil:
    section.add "X-Amz-Credential", valid_599999
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600001: Call_CreateSystemInstance_599989; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a system instance. </p> <p>This action validates the system instance, prepares the deployment-related resources. For Greengrass deployments, it updates the Greengrass group that is specified by the <code>greengrassGroupName</code> parameter. It also adds a file to the S3 bucket specified by the <code>s3BucketName</code> parameter. You need to call <code>DeploySystemInstance</code> after running this action.</p> <p>For Greengrass deployments, since this action modifies and adds resources to a Greengrass group and an S3 bucket on the caller's behalf, the calling identity must have write permissions to both the specified Greengrass group and S3 bucket. Otherwise, the call will fail with an authorization error.</p> <p>For cloud deployments, this action requires a <code>flowActionsRoleArn</code> value. This is an IAM role that has permissions to access AWS services, such as AWS Lambda and AWS IoT, that the flow uses when it executes.</p> <p>If the definition document doesn't specify a version of the user's namespace, the latest version will be used by default.</p>
  ## 
  let valid = call_600001.validator(path, query, header, formData, body)
  let scheme = call_600001.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600001.url(scheme.get, call_600001.host, call_600001.base,
                         call_600001.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600001, url, valid)

proc call*(call_600002: Call_CreateSystemInstance_599989; body: JsonNode): Recallable =
  ## createSystemInstance
  ## <p>Creates a system instance. </p> <p>This action validates the system instance, prepares the deployment-related resources. For Greengrass deployments, it updates the Greengrass group that is specified by the <code>greengrassGroupName</code> parameter. It also adds a file to the S3 bucket specified by the <code>s3BucketName</code> parameter. You need to call <code>DeploySystemInstance</code> after running this action.</p> <p>For Greengrass deployments, since this action modifies and adds resources to a Greengrass group and an S3 bucket on the caller's behalf, the calling identity must have write permissions to both the specified Greengrass group and S3 bucket. Otherwise, the call will fail with an authorization error.</p> <p>For cloud deployments, this action requires a <code>flowActionsRoleArn</code> value. This is an IAM role that has permissions to access AWS services, such as AWS Lambda and AWS IoT, that the flow uses when it executes.</p> <p>If the definition document doesn't specify a version of the user's namespace, the latest version will be used by default.</p>
  ##   body: JObject (required)
  var body_600003 = newJObject()
  if body != nil:
    body_600003 = body
  result = call_600002.call(nil, nil, nil, nil, body_600003)

var createSystemInstance* = Call_CreateSystemInstance_599989(
    name: "createSystemInstance", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.CreateSystemInstance",
    validator: validate_CreateSystemInstance_599990, base: "/",
    url: url_CreateSystemInstance_599991, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSystemTemplate_600004 = ref object of OpenApiRestCall_599368
proc url_CreateSystemTemplate_600006(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateSystemTemplate_600005(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600007 = header.getOrDefault("X-Amz-Date")
  valid_600007 = validateParameter(valid_600007, JString, required = false,
                                 default = nil)
  if valid_600007 != nil:
    section.add "X-Amz-Date", valid_600007
  var valid_600008 = header.getOrDefault("X-Amz-Security-Token")
  valid_600008 = validateParameter(valid_600008, JString, required = false,
                                 default = nil)
  if valid_600008 != nil:
    section.add "X-Amz-Security-Token", valid_600008
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600009 = header.getOrDefault("X-Amz-Target")
  valid_600009 = validateParameter(valid_600009, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.CreateSystemTemplate"))
  if valid_600009 != nil:
    section.add "X-Amz-Target", valid_600009
  var valid_600010 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600010 = validateParameter(valid_600010, JString, required = false,
                                 default = nil)
  if valid_600010 != nil:
    section.add "X-Amz-Content-Sha256", valid_600010
  var valid_600011 = header.getOrDefault("X-Amz-Algorithm")
  valid_600011 = validateParameter(valid_600011, JString, required = false,
                                 default = nil)
  if valid_600011 != nil:
    section.add "X-Amz-Algorithm", valid_600011
  var valid_600012 = header.getOrDefault("X-Amz-Signature")
  valid_600012 = validateParameter(valid_600012, JString, required = false,
                                 default = nil)
  if valid_600012 != nil:
    section.add "X-Amz-Signature", valid_600012
  var valid_600013 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600013 = validateParameter(valid_600013, JString, required = false,
                                 default = nil)
  if valid_600013 != nil:
    section.add "X-Amz-SignedHeaders", valid_600013
  var valid_600014 = header.getOrDefault("X-Amz-Credential")
  valid_600014 = validateParameter(valid_600014, JString, required = false,
                                 default = nil)
  if valid_600014 != nil:
    section.add "X-Amz-Credential", valid_600014
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600016: Call_CreateSystemTemplate_600004; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a system. The system is validated against the entities in the latest version of the user's namespace unless another namespace version is specified in the request.
  ## 
  let valid = call_600016.validator(path, query, header, formData, body)
  let scheme = call_600016.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600016.url(scheme.get, call_600016.host, call_600016.base,
                         call_600016.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600016, url, valid)

proc call*(call_600017: Call_CreateSystemTemplate_600004; body: JsonNode): Recallable =
  ## createSystemTemplate
  ## Creates a system. The system is validated against the entities in the latest version of the user's namespace unless another namespace version is specified in the request.
  ##   body: JObject (required)
  var body_600018 = newJObject()
  if body != nil:
    body_600018 = body
  result = call_600017.call(nil, nil, nil, nil, body_600018)

var createSystemTemplate* = Call_CreateSystemTemplate_600004(
    name: "createSystemTemplate", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.CreateSystemTemplate",
    validator: validate_CreateSystemTemplate_600005, base: "/",
    url: url_CreateSystemTemplate_600006, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFlowTemplate_600019 = ref object of OpenApiRestCall_599368
proc url_DeleteFlowTemplate_600021(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteFlowTemplate_600020(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600022 = header.getOrDefault("X-Amz-Date")
  valid_600022 = validateParameter(valid_600022, JString, required = false,
                                 default = nil)
  if valid_600022 != nil:
    section.add "X-Amz-Date", valid_600022
  var valid_600023 = header.getOrDefault("X-Amz-Security-Token")
  valid_600023 = validateParameter(valid_600023, JString, required = false,
                                 default = nil)
  if valid_600023 != nil:
    section.add "X-Amz-Security-Token", valid_600023
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600024 = header.getOrDefault("X-Amz-Target")
  valid_600024 = validateParameter(valid_600024, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.DeleteFlowTemplate"))
  if valid_600024 != nil:
    section.add "X-Amz-Target", valid_600024
  var valid_600025 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600025 = validateParameter(valid_600025, JString, required = false,
                                 default = nil)
  if valid_600025 != nil:
    section.add "X-Amz-Content-Sha256", valid_600025
  var valid_600026 = header.getOrDefault("X-Amz-Algorithm")
  valid_600026 = validateParameter(valid_600026, JString, required = false,
                                 default = nil)
  if valid_600026 != nil:
    section.add "X-Amz-Algorithm", valid_600026
  var valid_600027 = header.getOrDefault("X-Amz-Signature")
  valid_600027 = validateParameter(valid_600027, JString, required = false,
                                 default = nil)
  if valid_600027 != nil:
    section.add "X-Amz-Signature", valid_600027
  var valid_600028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600028 = validateParameter(valid_600028, JString, required = false,
                                 default = nil)
  if valid_600028 != nil:
    section.add "X-Amz-SignedHeaders", valid_600028
  var valid_600029 = header.getOrDefault("X-Amz-Credential")
  valid_600029 = validateParameter(valid_600029, JString, required = false,
                                 default = nil)
  if valid_600029 != nil:
    section.add "X-Amz-Credential", valid_600029
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600031: Call_DeleteFlowTemplate_600019; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a workflow. Any new system or deployment that contains this workflow will fail to update or deploy. Existing deployments that contain the workflow will continue to run (since they use a snapshot of the workflow taken at the time of deployment).
  ## 
  let valid = call_600031.validator(path, query, header, formData, body)
  let scheme = call_600031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600031.url(scheme.get, call_600031.host, call_600031.base,
                         call_600031.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600031, url, valid)

proc call*(call_600032: Call_DeleteFlowTemplate_600019; body: JsonNode): Recallable =
  ## deleteFlowTemplate
  ## Deletes a workflow. Any new system or deployment that contains this workflow will fail to update or deploy. Existing deployments that contain the workflow will continue to run (since they use a snapshot of the workflow taken at the time of deployment).
  ##   body: JObject (required)
  var body_600033 = newJObject()
  if body != nil:
    body_600033 = body
  result = call_600032.call(nil, nil, nil, nil, body_600033)

var deleteFlowTemplate* = Call_DeleteFlowTemplate_600019(
    name: "deleteFlowTemplate", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.DeleteFlowTemplate",
    validator: validate_DeleteFlowTemplate_600020, base: "/",
    url: url_DeleteFlowTemplate_600021, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNamespace_600034 = ref object of OpenApiRestCall_599368
proc url_DeleteNamespace_600036(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteNamespace_600035(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600037 = header.getOrDefault("X-Amz-Date")
  valid_600037 = validateParameter(valid_600037, JString, required = false,
                                 default = nil)
  if valid_600037 != nil:
    section.add "X-Amz-Date", valid_600037
  var valid_600038 = header.getOrDefault("X-Amz-Security-Token")
  valid_600038 = validateParameter(valid_600038, JString, required = false,
                                 default = nil)
  if valid_600038 != nil:
    section.add "X-Amz-Security-Token", valid_600038
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600039 = header.getOrDefault("X-Amz-Target")
  valid_600039 = validateParameter(valid_600039, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.DeleteNamespace"))
  if valid_600039 != nil:
    section.add "X-Amz-Target", valid_600039
  var valid_600040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600040 = validateParameter(valid_600040, JString, required = false,
                                 default = nil)
  if valid_600040 != nil:
    section.add "X-Amz-Content-Sha256", valid_600040
  var valid_600041 = header.getOrDefault("X-Amz-Algorithm")
  valid_600041 = validateParameter(valid_600041, JString, required = false,
                                 default = nil)
  if valid_600041 != nil:
    section.add "X-Amz-Algorithm", valid_600041
  var valid_600042 = header.getOrDefault("X-Amz-Signature")
  valid_600042 = validateParameter(valid_600042, JString, required = false,
                                 default = nil)
  if valid_600042 != nil:
    section.add "X-Amz-Signature", valid_600042
  var valid_600043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600043 = validateParameter(valid_600043, JString, required = false,
                                 default = nil)
  if valid_600043 != nil:
    section.add "X-Amz-SignedHeaders", valid_600043
  var valid_600044 = header.getOrDefault("X-Amz-Credential")
  valid_600044 = validateParameter(valid_600044, JString, required = false,
                                 default = nil)
  if valid_600044 != nil:
    section.add "X-Amz-Credential", valid_600044
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600046: Call_DeleteNamespace_600034; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified namespace. This action deletes all of the entities in the namespace. Delete the systems and flows that use entities in the namespace before performing this action.
  ## 
  let valid = call_600046.validator(path, query, header, formData, body)
  let scheme = call_600046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600046.url(scheme.get, call_600046.host, call_600046.base,
                         call_600046.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600046, url, valid)

proc call*(call_600047: Call_DeleteNamespace_600034; body: JsonNode): Recallable =
  ## deleteNamespace
  ## Deletes the specified namespace. This action deletes all of the entities in the namespace. Delete the systems and flows that use entities in the namespace before performing this action.
  ##   body: JObject (required)
  var body_600048 = newJObject()
  if body != nil:
    body_600048 = body
  result = call_600047.call(nil, nil, nil, nil, body_600048)

var deleteNamespace* = Call_DeleteNamespace_600034(name: "deleteNamespace",
    meth: HttpMethod.HttpPost, host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.DeleteNamespace",
    validator: validate_DeleteNamespace_600035, base: "/", url: url_DeleteNamespace_600036,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSystemInstance_600049 = ref object of OpenApiRestCall_599368
proc url_DeleteSystemInstance_600051(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteSystemInstance_600050(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600052 = header.getOrDefault("X-Amz-Date")
  valid_600052 = validateParameter(valid_600052, JString, required = false,
                                 default = nil)
  if valid_600052 != nil:
    section.add "X-Amz-Date", valid_600052
  var valid_600053 = header.getOrDefault("X-Amz-Security-Token")
  valid_600053 = validateParameter(valid_600053, JString, required = false,
                                 default = nil)
  if valid_600053 != nil:
    section.add "X-Amz-Security-Token", valid_600053
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600054 = header.getOrDefault("X-Amz-Target")
  valid_600054 = validateParameter(valid_600054, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.DeleteSystemInstance"))
  if valid_600054 != nil:
    section.add "X-Amz-Target", valid_600054
  var valid_600055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600055 = validateParameter(valid_600055, JString, required = false,
                                 default = nil)
  if valid_600055 != nil:
    section.add "X-Amz-Content-Sha256", valid_600055
  var valid_600056 = header.getOrDefault("X-Amz-Algorithm")
  valid_600056 = validateParameter(valid_600056, JString, required = false,
                                 default = nil)
  if valid_600056 != nil:
    section.add "X-Amz-Algorithm", valid_600056
  var valid_600057 = header.getOrDefault("X-Amz-Signature")
  valid_600057 = validateParameter(valid_600057, JString, required = false,
                                 default = nil)
  if valid_600057 != nil:
    section.add "X-Amz-Signature", valid_600057
  var valid_600058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600058 = validateParameter(valid_600058, JString, required = false,
                                 default = nil)
  if valid_600058 != nil:
    section.add "X-Amz-SignedHeaders", valid_600058
  var valid_600059 = header.getOrDefault("X-Amz-Credential")
  valid_600059 = validateParameter(valid_600059, JString, required = false,
                                 default = nil)
  if valid_600059 != nil:
    section.add "X-Amz-Credential", valid_600059
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600061: Call_DeleteSystemInstance_600049; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a system instance. Only system instances that have never been deployed, or that have been undeployed can be deleted.</p> <p>Users can create a new system instance that has the same ID as a deleted system instance.</p>
  ## 
  let valid = call_600061.validator(path, query, header, formData, body)
  let scheme = call_600061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600061.url(scheme.get, call_600061.host, call_600061.base,
                         call_600061.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600061, url, valid)

proc call*(call_600062: Call_DeleteSystemInstance_600049; body: JsonNode): Recallable =
  ## deleteSystemInstance
  ## <p>Deletes a system instance. Only system instances that have never been deployed, or that have been undeployed can be deleted.</p> <p>Users can create a new system instance that has the same ID as a deleted system instance.</p>
  ##   body: JObject (required)
  var body_600063 = newJObject()
  if body != nil:
    body_600063 = body
  result = call_600062.call(nil, nil, nil, nil, body_600063)

var deleteSystemInstance* = Call_DeleteSystemInstance_600049(
    name: "deleteSystemInstance", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.DeleteSystemInstance",
    validator: validate_DeleteSystemInstance_600050, base: "/",
    url: url_DeleteSystemInstance_600051, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSystemTemplate_600064 = ref object of OpenApiRestCall_599368
proc url_DeleteSystemTemplate_600066(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteSystemTemplate_600065(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600067 = header.getOrDefault("X-Amz-Date")
  valid_600067 = validateParameter(valid_600067, JString, required = false,
                                 default = nil)
  if valid_600067 != nil:
    section.add "X-Amz-Date", valid_600067
  var valid_600068 = header.getOrDefault("X-Amz-Security-Token")
  valid_600068 = validateParameter(valid_600068, JString, required = false,
                                 default = nil)
  if valid_600068 != nil:
    section.add "X-Amz-Security-Token", valid_600068
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600069 = header.getOrDefault("X-Amz-Target")
  valid_600069 = validateParameter(valid_600069, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.DeleteSystemTemplate"))
  if valid_600069 != nil:
    section.add "X-Amz-Target", valid_600069
  var valid_600070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600070 = validateParameter(valid_600070, JString, required = false,
                                 default = nil)
  if valid_600070 != nil:
    section.add "X-Amz-Content-Sha256", valid_600070
  var valid_600071 = header.getOrDefault("X-Amz-Algorithm")
  valid_600071 = validateParameter(valid_600071, JString, required = false,
                                 default = nil)
  if valid_600071 != nil:
    section.add "X-Amz-Algorithm", valid_600071
  var valid_600072 = header.getOrDefault("X-Amz-Signature")
  valid_600072 = validateParameter(valid_600072, JString, required = false,
                                 default = nil)
  if valid_600072 != nil:
    section.add "X-Amz-Signature", valid_600072
  var valid_600073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600073 = validateParameter(valid_600073, JString, required = false,
                                 default = nil)
  if valid_600073 != nil:
    section.add "X-Amz-SignedHeaders", valid_600073
  var valid_600074 = header.getOrDefault("X-Amz-Credential")
  valid_600074 = validateParameter(valid_600074, JString, required = false,
                                 default = nil)
  if valid_600074 != nil:
    section.add "X-Amz-Credential", valid_600074
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600076: Call_DeleteSystemTemplate_600064; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a system. New deployments can't contain the system after its deletion. Existing deployments that contain the system will continue to work because they use a snapshot of the system that is taken when it is deployed.
  ## 
  let valid = call_600076.validator(path, query, header, formData, body)
  let scheme = call_600076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600076.url(scheme.get, call_600076.host, call_600076.base,
                         call_600076.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600076, url, valid)

proc call*(call_600077: Call_DeleteSystemTemplate_600064; body: JsonNode): Recallable =
  ## deleteSystemTemplate
  ## Deletes a system. New deployments can't contain the system after its deletion. Existing deployments that contain the system will continue to work because they use a snapshot of the system that is taken when it is deployed.
  ##   body: JObject (required)
  var body_600078 = newJObject()
  if body != nil:
    body_600078 = body
  result = call_600077.call(nil, nil, nil, nil, body_600078)

var deleteSystemTemplate* = Call_DeleteSystemTemplate_600064(
    name: "deleteSystemTemplate", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.DeleteSystemTemplate",
    validator: validate_DeleteSystemTemplate_600065, base: "/",
    url: url_DeleteSystemTemplate_600066, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeploySystemInstance_600079 = ref object of OpenApiRestCall_599368
proc url_DeploySystemInstance_600081(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeploySystemInstance_600080(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600082 = header.getOrDefault("X-Amz-Date")
  valid_600082 = validateParameter(valid_600082, JString, required = false,
                                 default = nil)
  if valid_600082 != nil:
    section.add "X-Amz-Date", valid_600082
  var valid_600083 = header.getOrDefault("X-Amz-Security-Token")
  valid_600083 = validateParameter(valid_600083, JString, required = false,
                                 default = nil)
  if valid_600083 != nil:
    section.add "X-Amz-Security-Token", valid_600083
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600084 = header.getOrDefault("X-Amz-Target")
  valid_600084 = validateParameter(valid_600084, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.DeploySystemInstance"))
  if valid_600084 != nil:
    section.add "X-Amz-Target", valid_600084
  var valid_600085 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600085 = validateParameter(valid_600085, JString, required = false,
                                 default = nil)
  if valid_600085 != nil:
    section.add "X-Amz-Content-Sha256", valid_600085
  var valid_600086 = header.getOrDefault("X-Amz-Algorithm")
  valid_600086 = validateParameter(valid_600086, JString, required = false,
                                 default = nil)
  if valid_600086 != nil:
    section.add "X-Amz-Algorithm", valid_600086
  var valid_600087 = header.getOrDefault("X-Amz-Signature")
  valid_600087 = validateParameter(valid_600087, JString, required = false,
                                 default = nil)
  if valid_600087 != nil:
    section.add "X-Amz-Signature", valid_600087
  var valid_600088 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600088 = validateParameter(valid_600088, JString, required = false,
                                 default = nil)
  if valid_600088 != nil:
    section.add "X-Amz-SignedHeaders", valid_600088
  var valid_600089 = header.getOrDefault("X-Amz-Credential")
  valid_600089 = validateParameter(valid_600089, JString, required = false,
                                 default = nil)
  if valid_600089 != nil:
    section.add "X-Amz-Credential", valid_600089
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600091: Call_DeploySystemInstance_600079; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> <b>Greengrass and Cloud Deployments</b> </p> <p>Deploys the system instance to the target specified in <code>CreateSystemInstance</code>. </p> <p> <b>Greengrass Deployments</b> </p> <p>If the system or any workflows and entities have been updated before this action is called, then the deployment will create a new Amazon Simple Storage Service resource file and then deploy it.</p> <p>Since this action creates a Greengrass deployment on the caller's behalf, the calling identity must have write permissions to the specified Greengrass group. Otherwise, the call will fail with an authorization error.</p> <p>For information about the artifacts that get added to your Greengrass core device when you use this API, see <a href="https://docs.aws.amazon.com/thingsgraph/latest/ug/iot-tg-greengrass.html">AWS IoT Things Graph and AWS IoT Greengrass</a>.</p>
  ## 
  let valid = call_600091.validator(path, query, header, formData, body)
  let scheme = call_600091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600091.url(scheme.get, call_600091.host, call_600091.base,
                         call_600091.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600091, url, valid)

proc call*(call_600092: Call_DeploySystemInstance_600079; body: JsonNode): Recallable =
  ## deploySystemInstance
  ## <p> <b>Greengrass and Cloud Deployments</b> </p> <p>Deploys the system instance to the target specified in <code>CreateSystemInstance</code>. </p> <p> <b>Greengrass Deployments</b> </p> <p>If the system or any workflows and entities have been updated before this action is called, then the deployment will create a new Amazon Simple Storage Service resource file and then deploy it.</p> <p>Since this action creates a Greengrass deployment on the caller's behalf, the calling identity must have write permissions to the specified Greengrass group. Otherwise, the call will fail with an authorization error.</p> <p>For information about the artifacts that get added to your Greengrass core device when you use this API, see <a href="https://docs.aws.amazon.com/thingsgraph/latest/ug/iot-tg-greengrass.html">AWS IoT Things Graph and AWS IoT Greengrass</a>.</p>
  ##   body: JObject (required)
  var body_600093 = newJObject()
  if body != nil:
    body_600093 = body
  result = call_600092.call(nil, nil, nil, nil, body_600093)

var deploySystemInstance* = Call_DeploySystemInstance_600079(
    name: "deploySystemInstance", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.DeploySystemInstance",
    validator: validate_DeploySystemInstance_600080, base: "/",
    url: url_DeploySystemInstance_600081, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeprecateFlowTemplate_600094 = ref object of OpenApiRestCall_599368
proc url_DeprecateFlowTemplate_600096(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeprecateFlowTemplate_600095(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600097 = header.getOrDefault("X-Amz-Date")
  valid_600097 = validateParameter(valid_600097, JString, required = false,
                                 default = nil)
  if valid_600097 != nil:
    section.add "X-Amz-Date", valid_600097
  var valid_600098 = header.getOrDefault("X-Amz-Security-Token")
  valid_600098 = validateParameter(valid_600098, JString, required = false,
                                 default = nil)
  if valid_600098 != nil:
    section.add "X-Amz-Security-Token", valid_600098
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600099 = header.getOrDefault("X-Amz-Target")
  valid_600099 = validateParameter(valid_600099, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.DeprecateFlowTemplate"))
  if valid_600099 != nil:
    section.add "X-Amz-Target", valid_600099
  var valid_600100 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600100 = validateParameter(valid_600100, JString, required = false,
                                 default = nil)
  if valid_600100 != nil:
    section.add "X-Amz-Content-Sha256", valid_600100
  var valid_600101 = header.getOrDefault("X-Amz-Algorithm")
  valid_600101 = validateParameter(valid_600101, JString, required = false,
                                 default = nil)
  if valid_600101 != nil:
    section.add "X-Amz-Algorithm", valid_600101
  var valid_600102 = header.getOrDefault("X-Amz-Signature")
  valid_600102 = validateParameter(valid_600102, JString, required = false,
                                 default = nil)
  if valid_600102 != nil:
    section.add "X-Amz-Signature", valid_600102
  var valid_600103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600103 = validateParameter(valid_600103, JString, required = false,
                                 default = nil)
  if valid_600103 != nil:
    section.add "X-Amz-SignedHeaders", valid_600103
  var valid_600104 = header.getOrDefault("X-Amz-Credential")
  valid_600104 = validateParameter(valid_600104, JString, required = false,
                                 default = nil)
  if valid_600104 != nil:
    section.add "X-Amz-Credential", valid_600104
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600106: Call_DeprecateFlowTemplate_600094; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deprecates the specified workflow. This action marks the workflow for deletion. Deprecated flows can't be deployed, but existing deployments will continue to run.
  ## 
  let valid = call_600106.validator(path, query, header, formData, body)
  let scheme = call_600106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600106.url(scheme.get, call_600106.host, call_600106.base,
                         call_600106.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600106, url, valid)

proc call*(call_600107: Call_DeprecateFlowTemplate_600094; body: JsonNode): Recallable =
  ## deprecateFlowTemplate
  ## Deprecates the specified workflow. This action marks the workflow for deletion. Deprecated flows can't be deployed, but existing deployments will continue to run.
  ##   body: JObject (required)
  var body_600108 = newJObject()
  if body != nil:
    body_600108 = body
  result = call_600107.call(nil, nil, nil, nil, body_600108)

var deprecateFlowTemplate* = Call_DeprecateFlowTemplate_600094(
    name: "deprecateFlowTemplate", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com", route: "/#X-Amz-Target=IotThingsGraphFrontEndService.DeprecateFlowTemplate",
    validator: validate_DeprecateFlowTemplate_600095, base: "/",
    url: url_DeprecateFlowTemplate_600096, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeprecateSystemTemplate_600109 = ref object of OpenApiRestCall_599368
proc url_DeprecateSystemTemplate_600111(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeprecateSystemTemplate_600110(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600112 = header.getOrDefault("X-Amz-Date")
  valid_600112 = validateParameter(valid_600112, JString, required = false,
                                 default = nil)
  if valid_600112 != nil:
    section.add "X-Amz-Date", valid_600112
  var valid_600113 = header.getOrDefault("X-Amz-Security-Token")
  valid_600113 = validateParameter(valid_600113, JString, required = false,
                                 default = nil)
  if valid_600113 != nil:
    section.add "X-Amz-Security-Token", valid_600113
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600114 = header.getOrDefault("X-Amz-Target")
  valid_600114 = validateParameter(valid_600114, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.DeprecateSystemTemplate"))
  if valid_600114 != nil:
    section.add "X-Amz-Target", valid_600114
  var valid_600115 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600115 = validateParameter(valid_600115, JString, required = false,
                                 default = nil)
  if valid_600115 != nil:
    section.add "X-Amz-Content-Sha256", valid_600115
  var valid_600116 = header.getOrDefault("X-Amz-Algorithm")
  valid_600116 = validateParameter(valid_600116, JString, required = false,
                                 default = nil)
  if valid_600116 != nil:
    section.add "X-Amz-Algorithm", valid_600116
  var valid_600117 = header.getOrDefault("X-Amz-Signature")
  valid_600117 = validateParameter(valid_600117, JString, required = false,
                                 default = nil)
  if valid_600117 != nil:
    section.add "X-Amz-Signature", valid_600117
  var valid_600118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600118 = validateParameter(valid_600118, JString, required = false,
                                 default = nil)
  if valid_600118 != nil:
    section.add "X-Amz-SignedHeaders", valid_600118
  var valid_600119 = header.getOrDefault("X-Amz-Credential")
  valid_600119 = validateParameter(valid_600119, JString, required = false,
                                 default = nil)
  if valid_600119 != nil:
    section.add "X-Amz-Credential", valid_600119
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600121: Call_DeprecateSystemTemplate_600109; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deprecates the specified system.
  ## 
  let valid = call_600121.validator(path, query, header, formData, body)
  let scheme = call_600121.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600121.url(scheme.get, call_600121.host, call_600121.base,
                         call_600121.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600121, url, valid)

proc call*(call_600122: Call_DeprecateSystemTemplate_600109; body: JsonNode): Recallable =
  ## deprecateSystemTemplate
  ## Deprecates the specified system.
  ##   body: JObject (required)
  var body_600123 = newJObject()
  if body != nil:
    body_600123 = body
  result = call_600122.call(nil, nil, nil, nil, body_600123)

var deprecateSystemTemplate* = Call_DeprecateSystemTemplate_600109(
    name: "deprecateSystemTemplate", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com", route: "/#X-Amz-Target=IotThingsGraphFrontEndService.DeprecateSystemTemplate",
    validator: validate_DeprecateSystemTemplate_600110, base: "/",
    url: url_DeprecateSystemTemplate_600111, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeNamespace_600124 = ref object of OpenApiRestCall_599368
proc url_DescribeNamespace_600126(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeNamespace_600125(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600127 = header.getOrDefault("X-Amz-Date")
  valid_600127 = validateParameter(valid_600127, JString, required = false,
                                 default = nil)
  if valid_600127 != nil:
    section.add "X-Amz-Date", valid_600127
  var valid_600128 = header.getOrDefault("X-Amz-Security-Token")
  valid_600128 = validateParameter(valid_600128, JString, required = false,
                                 default = nil)
  if valid_600128 != nil:
    section.add "X-Amz-Security-Token", valid_600128
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600129 = header.getOrDefault("X-Amz-Target")
  valid_600129 = validateParameter(valid_600129, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.DescribeNamespace"))
  if valid_600129 != nil:
    section.add "X-Amz-Target", valid_600129
  var valid_600130 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600130 = validateParameter(valid_600130, JString, required = false,
                                 default = nil)
  if valid_600130 != nil:
    section.add "X-Amz-Content-Sha256", valid_600130
  var valid_600131 = header.getOrDefault("X-Amz-Algorithm")
  valid_600131 = validateParameter(valid_600131, JString, required = false,
                                 default = nil)
  if valid_600131 != nil:
    section.add "X-Amz-Algorithm", valid_600131
  var valid_600132 = header.getOrDefault("X-Amz-Signature")
  valid_600132 = validateParameter(valid_600132, JString, required = false,
                                 default = nil)
  if valid_600132 != nil:
    section.add "X-Amz-Signature", valid_600132
  var valid_600133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600133 = validateParameter(valid_600133, JString, required = false,
                                 default = nil)
  if valid_600133 != nil:
    section.add "X-Amz-SignedHeaders", valid_600133
  var valid_600134 = header.getOrDefault("X-Amz-Credential")
  valid_600134 = validateParameter(valid_600134, JString, required = false,
                                 default = nil)
  if valid_600134 != nil:
    section.add "X-Amz-Credential", valid_600134
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600136: Call_DescribeNamespace_600124; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the latest version of the user's namespace and the public version that it is tracking.
  ## 
  let valid = call_600136.validator(path, query, header, formData, body)
  let scheme = call_600136.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600136.url(scheme.get, call_600136.host, call_600136.base,
                         call_600136.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600136, url, valid)

proc call*(call_600137: Call_DescribeNamespace_600124; body: JsonNode): Recallable =
  ## describeNamespace
  ## Gets the latest version of the user's namespace and the public version that it is tracking.
  ##   body: JObject (required)
  var body_600138 = newJObject()
  if body != nil:
    body_600138 = body
  result = call_600137.call(nil, nil, nil, nil, body_600138)

var describeNamespace* = Call_DescribeNamespace_600124(name: "describeNamespace",
    meth: HttpMethod.HttpPost, host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.DescribeNamespace",
    validator: validate_DescribeNamespace_600125, base: "/",
    url: url_DescribeNamespace_600126, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DissociateEntityFromThing_600139 = ref object of OpenApiRestCall_599368
proc url_DissociateEntityFromThing_600141(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DissociateEntityFromThing_600140(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600142 = header.getOrDefault("X-Amz-Date")
  valid_600142 = validateParameter(valid_600142, JString, required = false,
                                 default = nil)
  if valid_600142 != nil:
    section.add "X-Amz-Date", valid_600142
  var valid_600143 = header.getOrDefault("X-Amz-Security-Token")
  valid_600143 = validateParameter(valid_600143, JString, required = false,
                                 default = nil)
  if valid_600143 != nil:
    section.add "X-Amz-Security-Token", valid_600143
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600144 = header.getOrDefault("X-Amz-Target")
  valid_600144 = validateParameter(valid_600144, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.DissociateEntityFromThing"))
  if valid_600144 != nil:
    section.add "X-Amz-Target", valid_600144
  var valid_600145 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600145 = validateParameter(valid_600145, JString, required = false,
                                 default = nil)
  if valid_600145 != nil:
    section.add "X-Amz-Content-Sha256", valid_600145
  var valid_600146 = header.getOrDefault("X-Amz-Algorithm")
  valid_600146 = validateParameter(valid_600146, JString, required = false,
                                 default = nil)
  if valid_600146 != nil:
    section.add "X-Amz-Algorithm", valid_600146
  var valid_600147 = header.getOrDefault("X-Amz-Signature")
  valid_600147 = validateParameter(valid_600147, JString, required = false,
                                 default = nil)
  if valid_600147 != nil:
    section.add "X-Amz-Signature", valid_600147
  var valid_600148 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600148 = validateParameter(valid_600148, JString, required = false,
                                 default = nil)
  if valid_600148 != nil:
    section.add "X-Amz-SignedHeaders", valid_600148
  var valid_600149 = header.getOrDefault("X-Amz-Credential")
  valid_600149 = validateParameter(valid_600149, JString, required = false,
                                 default = nil)
  if valid_600149 != nil:
    section.add "X-Amz-Credential", valid_600149
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600151: Call_DissociateEntityFromThing_600139; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Dissociates a device entity from a concrete thing. The action takes only the type of the entity that you need to dissociate because only one entity of a particular type can be associated with a thing.
  ## 
  let valid = call_600151.validator(path, query, header, formData, body)
  let scheme = call_600151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600151.url(scheme.get, call_600151.host, call_600151.base,
                         call_600151.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600151, url, valid)

proc call*(call_600152: Call_DissociateEntityFromThing_600139; body: JsonNode): Recallable =
  ## dissociateEntityFromThing
  ## Dissociates a device entity from a concrete thing. The action takes only the type of the entity that you need to dissociate because only one entity of a particular type can be associated with a thing.
  ##   body: JObject (required)
  var body_600153 = newJObject()
  if body != nil:
    body_600153 = body
  result = call_600152.call(nil, nil, nil, nil, body_600153)

var dissociateEntityFromThing* = Call_DissociateEntityFromThing_600139(
    name: "dissociateEntityFromThing", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com", route: "/#X-Amz-Target=IotThingsGraphFrontEndService.DissociateEntityFromThing",
    validator: validate_DissociateEntityFromThing_600140, base: "/",
    url: url_DissociateEntityFromThing_600141,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEntities_600154 = ref object of OpenApiRestCall_599368
proc url_GetEntities_600156(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetEntities_600155(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600157 = header.getOrDefault("X-Amz-Date")
  valid_600157 = validateParameter(valid_600157, JString, required = false,
                                 default = nil)
  if valid_600157 != nil:
    section.add "X-Amz-Date", valid_600157
  var valid_600158 = header.getOrDefault("X-Amz-Security-Token")
  valid_600158 = validateParameter(valid_600158, JString, required = false,
                                 default = nil)
  if valid_600158 != nil:
    section.add "X-Amz-Security-Token", valid_600158
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600159 = header.getOrDefault("X-Amz-Target")
  valid_600159 = validateParameter(valid_600159, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.GetEntities"))
  if valid_600159 != nil:
    section.add "X-Amz-Target", valid_600159
  var valid_600160 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600160 = validateParameter(valid_600160, JString, required = false,
                                 default = nil)
  if valid_600160 != nil:
    section.add "X-Amz-Content-Sha256", valid_600160
  var valid_600161 = header.getOrDefault("X-Amz-Algorithm")
  valid_600161 = validateParameter(valid_600161, JString, required = false,
                                 default = nil)
  if valid_600161 != nil:
    section.add "X-Amz-Algorithm", valid_600161
  var valid_600162 = header.getOrDefault("X-Amz-Signature")
  valid_600162 = validateParameter(valid_600162, JString, required = false,
                                 default = nil)
  if valid_600162 != nil:
    section.add "X-Amz-Signature", valid_600162
  var valid_600163 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600163 = validateParameter(valid_600163, JString, required = false,
                                 default = nil)
  if valid_600163 != nil:
    section.add "X-Amz-SignedHeaders", valid_600163
  var valid_600164 = header.getOrDefault("X-Amz-Credential")
  valid_600164 = validateParameter(valid_600164, JString, required = false,
                                 default = nil)
  if valid_600164 != nil:
    section.add "X-Amz-Credential", valid_600164
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600166: Call_GetEntities_600154; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets definitions of the specified entities. Uses the latest version of the user's namespace by default. This API returns the following TDM entities.</p> <ul> <li> <p>Properties</p> </li> <li> <p>States</p> </li> <li> <p>Events</p> </li> <li> <p>Actions</p> </li> <li> <p>Capabilities</p> </li> <li> <p>Mappings</p> </li> <li> <p>Devices</p> </li> <li> <p>Device Models</p> </li> <li> <p>Services</p> </li> </ul> <p>This action doesn't return definitions for systems, flows, and deployments.</p>
  ## 
  let valid = call_600166.validator(path, query, header, formData, body)
  let scheme = call_600166.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600166.url(scheme.get, call_600166.host, call_600166.base,
                         call_600166.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600166, url, valid)

proc call*(call_600167: Call_GetEntities_600154; body: JsonNode): Recallable =
  ## getEntities
  ## <p>Gets definitions of the specified entities. Uses the latest version of the user's namespace by default. This API returns the following TDM entities.</p> <ul> <li> <p>Properties</p> </li> <li> <p>States</p> </li> <li> <p>Events</p> </li> <li> <p>Actions</p> </li> <li> <p>Capabilities</p> </li> <li> <p>Mappings</p> </li> <li> <p>Devices</p> </li> <li> <p>Device Models</p> </li> <li> <p>Services</p> </li> </ul> <p>This action doesn't return definitions for systems, flows, and deployments.</p>
  ##   body: JObject (required)
  var body_600168 = newJObject()
  if body != nil:
    body_600168 = body
  result = call_600167.call(nil, nil, nil, nil, body_600168)

var getEntities* = Call_GetEntities_600154(name: "getEntities",
                                        meth: HttpMethod.HttpPost,
                                        host: "iotthingsgraph.amazonaws.com", route: "/#X-Amz-Target=IotThingsGraphFrontEndService.GetEntities",
                                        validator: validate_GetEntities_600155,
                                        base: "/", url: url_GetEntities_600156,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFlowTemplate_600169 = ref object of OpenApiRestCall_599368
proc url_GetFlowTemplate_600171(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetFlowTemplate_600170(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600172 = header.getOrDefault("X-Amz-Date")
  valid_600172 = validateParameter(valid_600172, JString, required = false,
                                 default = nil)
  if valid_600172 != nil:
    section.add "X-Amz-Date", valid_600172
  var valid_600173 = header.getOrDefault("X-Amz-Security-Token")
  valid_600173 = validateParameter(valid_600173, JString, required = false,
                                 default = nil)
  if valid_600173 != nil:
    section.add "X-Amz-Security-Token", valid_600173
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600174 = header.getOrDefault("X-Amz-Target")
  valid_600174 = validateParameter(valid_600174, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.GetFlowTemplate"))
  if valid_600174 != nil:
    section.add "X-Amz-Target", valid_600174
  var valid_600175 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600175 = validateParameter(valid_600175, JString, required = false,
                                 default = nil)
  if valid_600175 != nil:
    section.add "X-Amz-Content-Sha256", valid_600175
  var valid_600176 = header.getOrDefault("X-Amz-Algorithm")
  valid_600176 = validateParameter(valid_600176, JString, required = false,
                                 default = nil)
  if valid_600176 != nil:
    section.add "X-Amz-Algorithm", valid_600176
  var valid_600177 = header.getOrDefault("X-Amz-Signature")
  valid_600177 = validateParameter(valid_600177, JString, required = false,
                                 default = nil)
  if valid_600177 != nil:
    section.add "X-Amz-Signature", valid_600177
  var valid_600178 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600178 = validateParameter(valid_600178, JString, required = false,
                                 default = nil)
  if valid_600178 != nil:
    section.add "X-Amz-SignedHeaders", valid_600178
  var valid_600179 = header.getOrDefault("X-Amz-Credential")
  valid_600179 = validateParameter(valid_600179, JString, required = false,
                                 default = nil)
  if valid_600179 != nil:
    section.add "X-Amz-Credential", valid_600179
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600181: Call_GetFlowTemplate_600169; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the latest version of the <code>DefinitionDocument</code> and <code>FlowTemplateSummary</code> for the specified workflow.
  ## 
  let valid = call_600181.validator(path, query, header, formData, body)
  let scheme = call_600181.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600181.url(scheme.get, call_600181.host, call_600181.base,
                         call_600181.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600181, url, valid)

proc call*(call_600182: Call_GetFlowTemplate_600169; body: JsonNode): Recallable =
  ## getFlowTemplate
  ## Gets the latest version of the <code>DefinitionDocument</code> and <code>FlowTemplateSummary</code> for the specified workflow.
  ##   body: JObject (required)
  var body_600183 = newJObject()
  if body != nil:
    body_600183 = body
  result = call_600182.call(nil, nil, nil, nil, body_600183)

var getFlowTemplate* = Call_GetFlowTemplate_600169(name: "getFlowTemplate",
    meth: HttpMethod.HttpPost, host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.GetFlowTemplate",
    validator: validate_GetFlowTemplate_600170, base: "/", url: url_GetFlowTemplate_600171,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFlowTemplateRevisions_600184 = ref object of OpenApiRestCall_599368
proc url_GetFlowTemplateRevisions_600186(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetFlowTemplateRevisions_600185(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets revisions of the specified workflow. Only the last 100 revisions are stored. If the workflow has been deprecated, this action will return revisions that occurred before the deprecation. This action won't work for workflows that have been deleted.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_600187 = query.getOrDefault("maxResults")
  valid_600187 = validateParameter(valid_600187, JString, required = false,
                                 default = nil)
  if valid_600187 != nil:
    section.add "maxResults", valid_600187
  var valid_600188 = query.getOrDefault("nextToken")
  valid_600188 = validateParameter(valid_600188, JString, required = false,
                                 default = nil)
  if valid_600188 != nil:
    section.add "nextToken", valid_600188
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
  var valid_600189 = header.getOrDefault("X-Amz-Date")
  valid_600189 = validateParameter(valid_600189, JString, required = false,
                                 default = nil)
  if valid_600189 != nil:
    section.add "X-Amz-Date", valid_600189
  var valid_600190 = header.getOrDefault("X-Amz-Security-Token")
  valid_600190 = validateParameter(valid_600190, JString, required = false,
                                 default = nil)
  if valid_600190 != nil:
    section.add "X-Amz-Security-Token", valid_600190
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600191 = header.getOrDefault("X-Amz-Target")
  valid_600191 = validateParameter(valid_600191, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.GetFlowTemplateRevisions"))
  if valid_600191 != nil:
    section.add "X-Amz-Target", valid_600191
  var valid_600192 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600192 = validateParameter(valid_600192, JString, required = false,
                                 default = nil)
  if valid_600192 != nil:
    section.add "X-Amz-Content-Sha256", valid_600192
  var valid_600193 = header.getOrDefault("X-Amz-Algorithm")
  valid_600193 = validateParameter(valid_600193, JString, required = false,
                                 default = nil)
  if valid_600193 != nil:
    section.add "X-Amz-Algorithm", valid_600193
  var valid_600194 = header.getOrDefault("X-Amz-Signature")
  valid_600194 = validateParameter(valid_600194, JString, required = false,
                                 default = nil)
  if valid_600194 != nil:
    section.add "X-Amz-Signature", valid_600194
  var valid_600195 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600195 = validateParameter(valid_600195, JString, required = false,
                                 default = nil)
  if valid_600195 != nil:
    section.add "X-Amz-SignedHeaders", valid_600195
  var valid_600196 = header.getOrDefault("X-Amz-Credential")
  valid_600196 = validateParameter(valid_600196, JString, required = false,
                                 default = nil)
  if valid_600196 != nil:
    section.add "X-Amz-Credential", valid_600196
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600198: Call_GetFlowTemplateRevisions_600184; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets revisions of the specified workflow. Only the last 100 revisions are stored. If the workflow has been deprecated, this action will return revisions that occurred before the deprecation. This action won't work for workflows that have been deleted.
  ## 
  let valid = call_600198.validator(path, query, header, formData, body)
  let scheme = call_600198.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600198.url(scheme.get, call_600198.host, call_600198.base,
                         call_600198.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600198, url, valid)

proc call*(call_600199: Call_GetFlowTemplateRevisions_600184; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getFlowTemplateRevisions
  ## Gets revisions of the specified workflow. Only the last 100 revisions are stored. If the workflow has been deprecated, this action will return revisions that occurred before the deprecation. This action won't work for workflows that have been deleted.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600200 = newJObject()
  var body_600201 = newJObject()
  add(query_600200, "maxResults", newJString(maxResults))
  add(query_600200, "nextToken", newJString(nextToken))
  if body != nil:
    body_600201 = body
  result = call_600199.call(nil, query_600200, nil, nil, body_600201)

var getFlowTemplateRevisions* = Call_GetFlowTemplateRevisions_600184(
    name: "getFlowTemplateRevisions", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com", route: "/#X-Amz-Target=IotThingsGraphFrontEndService.GetFlowTemplateRevisions",
    validator: validate_GetFlowTemplateRevisions_600185, base: "/",
    url: url_GetFlowTemplateRevisions_600186, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetNamespaceDeletionStatus_600203 = ref object of OpenApiRestCall_599368
proc url_GetNamespaceDeletionStatus_600205(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetNamespaceDeletionStatus_600204(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600206 = header.getOrDefault("X-Amz-Date")
  valid_600206 = validateParameter(valid_600206, JString, required = false,
                                 default = nil)
  if valid_600206 != nil:
    section.add "X-Amz-Date", valid_600206
  var valid_600207 = header.getOrDefault("X-Amz-Security-Token")
  valid_600207 = validateParameter(valid_600207, JString, required = false,
                                 default = nil)
  if valid_600207 != nil:
    section.add "X-Amz-Security-Token", valid_600207
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600208 = header.getOrDefault("X-Amz-Target")
  valid_600208 = validateParameter(valid_600208, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.GetNamespaceDeletionStatus"))
  if valid_600208 != nil:
    section.add "X-Amz-Target", valid_600208
  var valid_600209 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600209 = validateParameter(valid_600209, JString, required = false,
                                 default = nil)
  if valid_600209 != nil:
    section.add "X-Amz-Content-Sha256", valid_600209
  var valid_600210 = header.getOrDefault("X-Amz-Algorithm")
  valid_600210 = validateParameter(valid_600210, JString, required = false,
                                 default = nil)
  if valid_600210 != nil:
    section.add "X-Amz-Algorithm", valid_600210
  var valid_600211 = header.getOrDefault("X-Amz-Signature")
  valid_600211 = validateParameter(valid_600211, JString, required = false,
                                 default = nil)
  if valid_600211 != nil:
    section.add "X-Amz-Signature", valid_600211
  var valid_600212 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600212 = validateParameter(valid_600212, JString, required = false,
                                 default = nil)
  if valid_600212 != nil:
    section.add "X-Amz-SignedHeaders", valid_600212
  var valid_600213 = header.getOrDefault("X-Amz-Credential")
  valid_600213 = validateParameter(valid_600213, JString, required = false,
                                 default = nil)
  if valid_600213 != nil:
    section.add "X-Amz-Credential", valid_600213
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600215: Call_GetNamespaceDeletionStatus_600203; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the status of a namespace deletion task.
  ## 
  let valid = call_600215.validator(path, query, header, formData, body)
  let scheme = call_600215.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600215.url(scheme.get, call_600215.host, call_600215.base,
                         call_600215.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600215, url, valid)

proc call*(call_600216: Call_GetNamespaceDeletionStatus_600203; body: JsonNode): Recallable =
  ## getNamespaceDeletionStatus
  ## Gets the status of a namespace deletion task.
  ##   body: JObject (required)
  var body_600217 = newJObject()
  if body != nil:
    body_600217 = body
  result = call_600216.call(nil, nil, nil, nil, body_600217)

var getNamespaceDeletionStatus* = Call_GetNamespaceDeletionStatus_600203(
    name: "getNamespaceDeletionStatus", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com", route: "/#X-Amz-Target=IotThingsGraphFrontEndService.GetNamespaceDeletionStatus",
    validator: validate_GetNamespaceDeletionStatus_600204, base: "/",
    url: url_GetNamespaceDeletionStatus_600205,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSystemInstance_600218 = ref object of OpenApiRestCall_599368
proc url_GetSystemInstance_600220(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSystemInstance_600219(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600221 = header.getOrDefault("X-Amz-Date")
  valid_600221 = validateParameter(valid_600221, JString, required = false,
                                 default = nil)
  if valid_600221 != nil:
    section.add "X-Amz-Date", valid_600221
  var valid_600222 = header.getOrDefault("X-Amz-Security-Token")
  valid_600222 = validateParameter(valid_600222, JString, required = false,
                                 default = nil)
  if valid_600222 != nil:
    section.add "X-Amz-Security-Token", valid_600222
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600223 = header.getOrDefault("X-Amz-Target")
  valid_600223 = validateParameter(valid_600223, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.GetSystemInstance"))
  if valid_600223 != nil:
    section.add "X-Amz-Target", valid_600223
  var valid_600224 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600224 = validateParameter(valid_600224, JString, required = false,
                                 default = nil)
  if valid_600224 != nil:
    section.add "X-Amz-Content-Sha256", valid_600224
  var valid_600225 = header.getOrDefault("X-Amz-Algorithm")
  valid_600225 = validateParameter(valid_600225, JString, required = false,
                                 default = nil)
  if valid_600225 != nil:
    section.add "X-Amz-Algorithm", valid_600225
  var valid_600226 = header.getOrDefault("X-Amz-Signature")
  valid_600226 = validateParameter(valid_600226, JString, required = false,
                                 default = nil)
  if valid_600226 != nil:
    section.add "X-Amz-Signature", valid_600226
  var valid_600227 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600227 = validateParameter(valid_600227, JString, required = false,
                                 default = nil)
  if valid_600227 != nil:
    section.add "X-Amz-SignedHeaders", valid_600227
  var valid_600228 = header.getOrDefault("X-Amz-Credential")
  valid_600228 = validateParameter(valid_600228, JString, required = false,
                                 default = nil)
  if valid_600228 != nil:
    section.add "X-Amz-Credential", valid_600228
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600230: Call_GetSystemInstance_600218; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a system instance.
  ## 
  let valid = call_600230.validator(path, query, header, formData, body)
  let scheme = call_600230.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600230.url(scheme.get, call_600230.host, call_600230.base,
                         call_600230.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600230, url, valid)

proc call*(call_600231: Call_GetSystemInstance_600218; body: JsonNode): Recallable =
  ## getSystemInstance
  ## Gets a system instance.
  ##   body: JObject (required)
  var body_600232 = newJObject()
  if body != nil:
    body_600232 = body
  result = call_600231.call(nil, nil, nil, nil, body_600232)

var getSystemInstance* = Call_GetSystemInstance_600218(name: "getSystemInstance",
    meth: HttpMethod.HttpPost, host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.GetSystemInstance",
    validator: validate_GetSystemInstance_600219, base: "/",
    url: url_GetSystemInstance_600220, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSystemTemplate_600233 = ref object of OpenApiRestCall_599368
proc url_GetSystemTemplate_600235(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSystemTemplate_600234(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600236 = header.getOrDefault("X-Amz-Date")
  valid_600236 = validateParameter(valid_600236, JString, required = false,
                                 default = nil)
  if valid_600236 != nil:
    section.add "X-Amz-Date", valid_600236
  var valid_600237 = header.getOrDefault("X-Amz-Security-Token")
  valid_600237 = validateParameter(valid_600237, JString, required = false,
                                 default = nil)
  if valid_600237 != nil:
    section.add "X-Amz-Security-Token", valid_600237
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600238 = header.getOrDefault("X-Amz-Target")
  valid_600238 = validateParameter(valid_600238, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.GetSystemTemplate"))
  if valid_600238 != nil:
    section.add "X-Amz-Target", valid_600238
  var valid_600239 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600239 = validateParameter(valid_600239, JString, required = false,
                                 default = nil)
  if valid_600239 != nil:
    section.add "X-Amz-Content-Sha256", valid_600239
  var valid_600240 = header.getOrDefault("X-Amz-Algorithm")
  valid_600240 = validateParameter(valid_600240, JString, required = false,
                                 default = nil)
  if valid_600240 != nil:
    section.add "X-Amz-Algorithm", valid_600240
  var valid_600241 = header.getOrDefault("X-Amz-Signature")
  valid_600241 = validateParameter(valid_600241, JString, required = false,
                                 default = nil)
  if valid_600241 != nil:
    section.add "X-Amz-Signature", valid_600241
  var valid_600242 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600242 = validateParameter(valid_600242, JString, required = false,
                                 default = nil)
  if valid_600242 != nil:
    section.add "X-Amz-SignedHeaders", valid_600242
  var valid_600243 = header.getOrDefault("X-Amz-Credential")
  valid_600243 = validateParameter(valid_600243, JString, required = false,
                                 default = nil)
  if valid_600243 != nil:
    section.add "X-Amz-Credential", valid_600243
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600245: Call_GetSystemTemplate_600233; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a system.
  ## 
  let valid = call_600245.validator(path, query, header, formData, body)
  let scheme = call_600245.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600245.url(scheme.get, call_600245.host, call_600245.base,
                         call_600245.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600245, url, valid)

proc call*(call_600246: Call_GetSystemTemplate_600233; body: JsonNode): Recallable =
  ## getSystemTemplate
  ## Gets a system.
  ##   body: JObject (required)
  var body_600247 = newJObject()
  if body != nil:
    body_600247 = body
  result = call_600246.call(nil, nil, nil, nil, body_600247)

var getSystemTemplate* = Call_GetSystemTemplate_600233(name: "getSystemTemplate",
    meth: HttpMethod.HttpPost, host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.GetSystemTemplate",
    validator: validate_GetSystemTemplate_600234, base: "/",
    url: url_GetSystemTemplate_600235, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSystemTemplateRevisions_600248 = ref object of OpenApiRestCall_599368
proc url_GetSystemTemplateRevisions_600250(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSystemTemplateRevisions_600249(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets revisions made to the specified system template. Only the previous 100 revisions are stored. If the system has been deprecated, this action will return the revisions that occurred before its deprecation. This action won't work with systems that have been deleted.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_600251 = query.getOrDefault("maxResults")
  valid_600251 = validateParameter(valid_600251, JString, required = false,
                                 default = nil)
  if valid_600251 != nil:
    section.add "maxResults", valid_600251
  var valid_600252 = query.getOrDefault("nextToken")
  valid_600252 = validateParameter(valid_600252, JString, required = false,
                                 default = nil)
  if valid_600252 != nil:
    section.add "nextToken", valid_600252
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
  var valid_600253 = header.getOrDefault("X-Amz-Date")
  valid_600253 = validateParameter(valid_600253, JString, required = false,
                                 default = nil)
  if valid_600253 != nil:
    section.add "X-Amz-Date", valid_600253
  var valid_600254 = header.getOrDefault("X-Amz-Security-Token")
  valid_600254 = validateParameter(valid_600254, JString, required = false,
                                 default = nil)
  if valid_600254 != nil:
    section.add "X-Amz-Security-Token", valid_600254
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600255 = header.getOrDefault("X-Amz-Target")
  valid_600255 = validateParameter(valid_600255, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.GetSystemTemplateRevisions"))
  if valid_600255 != nil:
    section.add "X-Amz-Target", valid_600255
  var valid_600256 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600256 = validateParameter(valid_600256, JString, required = false,
                                 default = nil)
  if valid_600256 != nil:
    section.add "X-Amz-Content-Sha256", valid_600256
  var valid_600257 = header.getOrDefault("X-Amz-Algorithm")
  valid_600257 = validateParameter(valid_600257, JString, required = false,
                                 default = nil)
  if valid_600257 != nil:
    section.add "X-Amz-Algorithm", valid_600257
  var valid_600258 = header.getOrDefault("X-Amz-Signature")
  valid_600258 = validateParameter(valid_600258, JString, required = false,
                                 default = nil)
  if valid_600258 != nil:
    section.add "X-Amz-Signature", valid_600258
  var valid_600259 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600259 = validateParameter(valid_600259, JString, required = false,
                                 default = nil)
  if valid_600259 != nil:
    section.add "X-Amz-SignedHeaders", valid_600259
  var valid_600260 = header.getOrDefault("X-Amz-Credential")
  valid_600260 = validateParameter(valid_600260, JString, required = false,
                                 default = nil)
  if valid_600260 != nil:
    section.add "X-Amz-Credential", valid_600260
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600262: Call_GetSystemTemplateRevisions_600248; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets revisions made to the specified system template. Only the previous 100 revisions are stored. If the system has been deprecated, this action will return the revisions that occurred before its deprecation. This action won't work with systems that have been deleted.
  ## 
  let valid = call_600262.validator(path, query, header, formData, body)
  let scheme = call_600262.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600262.url(scheme.get, call_600262.host, call_600262.base,
                         call_600262.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600262, url, valid)

proc call*(call_600263: Call_GetSystemTemplateRevisions_600248; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getSystemTemplateRevisions
  ## Gets revisions made to the specified system template. Only the previous 100 revisions are stored. If the system has been deprecated, this action will return the revisions that occurred before its deprecation. This action won't work with systems that have been deleted.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600264 = newJObject()
  var body_600265 = newJObject()
  add(query_600264, "maxResults", newJString(maxResults))
  add(query_600264, "nextToken", newJString(nextToken))
  if body != nil:
    body_600265 = body
  result = call_600263.call(nil, query_600264, nil, nil, body_600265)

var getSystemTemplateRevisions* = Call_GetSystemTemplateRevisions_600248(
    name: "getSystemTemplateRevisions", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com", route: "/#X-Amz-Target=IotThingsGraphFrontEndService.GetSystemTemplateRevisions",
    validator: validate_GetSystemTemplateRevisions_600249, base: "/",
    url: url_GetSystemTemplateRevisions_600250,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUploadStatus_600266 = ref object of OpenApiRestCall_599368
proc url_GetUploadStatus_600268(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUploadStatus_600267(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600269 = header.getOrDefault("X-Amz-Date")
  valid_600269 = validateParameter(valid_600269, JString, required = false,
                                 default = nil)
  if valid_600269 != nil:
    section.add "X-Amz-Date", valid_600269
  var valid_600270 = header.getOrDefault("X-Amz-Security-Token")
  valid_600270 = validateParameter(valid_600270, JString, required = false,
                                 default = nil)
  if valid_600270 != nil:
    section.add "X-Amz-Security-Token", valid_600270
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600271 = header.getOrDefault("X-Amz-Target")
  valid_600271 = validateParameter(valid_600271, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.GetUploadStatus"))
  if valid_600271 != nil:
    section.add "X-Amz-Target", valid_600271
  var valid_600272 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600272 = validateParameter(valid_600272, JString, required = false,
                                 default = nil)
  if valid_600272 != nil:
    section.add "X-Amz-Content-Sha256", valid_600272
  var valid_600273 = header.getOrDefault("X-Amz-Algorithm")
  valid_600273 = validateParameter(valid_600273, JString, required = false,
                                 default = nil)
  if valid_600273 != nil:
    section.add "X-Amz-Algorithm", valid_600273
  var valid_600274 = header.getOrDefault("X-Amz-Signature")
  valid_600274 = validateParameter(valid_600274, JString, required = false,
                                 default = nil)
  if valid_600274 != nil:
    section.add "X-Amz-Signature", valid_600274
  var valid_600275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600275 = validateParameter(valid_600275, JString, required = false,
                                 default = nil)
  if valid_600275 != nil:
    section.add "X-Amz-SignedHeaders", valid_600275
  var valid_600276 = header.getOrDefault("X-Amz-Credential")
  valid_600276 = validateParameter(valid_600276, JString, required = false,
                                 default = nil)
  if valid_600276 != nil:
    section.add "X-Amz-Credential", valid_600276
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600278: Call_GetUploadStatus_600266; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the status of the specified upload.
  ## 
  let valid = call_600278.validator(path, query, header, formData, body)
  let scheme = call_600278.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600278.url(scheme.get, call_600278.host, call_600278.base,
                         call_600278.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600278, url, valid)

proc call*(call_600279: Call_GetUploadStatus_600266; body: JsonNode): Recallable =
  ## getUploadStatus
  ## Gets the status of the specified upload.
  ##   body: JObject (required)
  var body_600280 = newJObject()
  if body != nil:
    body_600280 = body
  result = call_600279.call(nil, nil, nil, nil, body_600280)

var getUploadStatus* = Call_GetUploadStatus_600266(name: "getUploadStatus",
    meth: HttpMethod.HttpPost, host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.GetUploadStatus",
    validator: validate_GetUploadStatus_600267, base: "/", url: url_GetUploadStatus_600268,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFlowExecutionMessages_600281 = ref object of OpenApiRestCall_599368
proc url_ListFlowExecutionMessages_600283(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListFlowExecutionMessages_600282(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of objects that contain information about events in a flow execution.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_600284 = query.getOrDefault("maxResults")
  valid_600284 = validateParameter(valid_600284, JString, required = false,
                                 default = nil)
  if valid_600284 != nil:
    section.add "maxResults", valid_600284
  var valid_600285 = query.getOrDefault("nextToken")
  valid_600285 = validateParameter(valid_600285, JString, required = false,
                                 default = nil)
  if valid_600285 != nil:
    section.add "nextToken", valid_600285
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
  var valid_600286 = header.getOrDefault("X-Amz-Date")
  valid_600286 = validateParameter(valid_600286, JString, required = false,
                                 default = nil)
  if valid_600286 != nil:
    section.add "X-Amz-Date", valid_600286
  var valid_600287 = header.getOrDefault("X-Amz-Security-Token")
  valid_600287 = validateParameter(valid_600287, JString, required = false,
                                 default = nil)
  if valid_600287 != nil:
    section.add "X-Amz-Security-Token", valid_600287
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600288 = header.getOrDefault("X-Amz-Target")
  valid_600288 = validateParameter(valid_600288, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.ListFlowExecutionMessages"))
  if valid_600288 != nil:
    section.add "X-Amz-Target", valid_600288
  var valid_600289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600289 = validateParameter(valid_600289, JString, required = false,
                                 default = nil)
  if valid_600289 != nil:
    section.add "X-Amz-Content-Sha256", valid_600289
  var valid_600290 = header.getOrDefault("X-Amz-Algorithm")
  valid_600290 = validateParameter(valid_600290, JString, required = false,
                                 default = nil)
  if valid_600290 != nil:
    section.add "X-Amz-Algorithm", valid_600290
  var valid_600291 = header.getOrDefault("X-Amz-Signature")
  valid_600291 = validateParameter(valid_600291, JString, required = false,
                                 default = nil)
  if valid_600291 != nil:
    section.add "X-Amz-Signature", valid_600291
  var valid_600292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600292 = validateParameter(valid_600292, JString, required = false,
                                 default = nil)
  if valid_600292 != nil:
    section.add "X-Amz-SignedHeaders", valid_600292
  var valid_600293 = header.getOrDefault("X-Amz-Credential")
  valid_600293 = validateParameter(valid_600293, JString, required = false,
                                 default = nil)
  if valid_600293 != nil:
    section.add "X-Amz-Credential", valid_600293
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600295: Call_ListFlowExecutionMessages_600281; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of objects that contain information about events in a flow execution.
  ## 
  let valid = call_600295.validator(path, query, header, formData, body)
  let scheme = call_600295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600295.url(scheme.get, call_600295.host, call_600295.base,
                         call_600295.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600295, url, valid)

proc call*(call_600296: Call_ListFlowExecutionMessages_600281; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listFlowExecutionMessages
  ## Returns a list of objects that contain information about events in a flow execution.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600297 = newJObject()
  var body_600298 = newJObject()
  add(query_600297, "maxResults", newJString(maxResults))
  add(query_600297, "nextToken", newJString(nextToken))
  if body != nil:
    body_600298 = body
  result = call_600296.call(nil, query_600297, nil, nil, body_600298)

var listFlowExecutionMessages* = Call_ListFlowExecutionMessages_600281(
    name: "listFlowExecutionMessages", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com", route: "/#X-Amz-Target=IotThingsGraphFrontEndService.ListFlowExecutionMessages",
    validator: validate_ListFlowExecutionMessages_600282, base: "/",
    url: url_ListFlowExecutionMessages_600283,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_600299 = ref object of OpenApiRestCall_599368
proc url_ListTagsForResource_600301(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_600300(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Lists all tags on an AWS IoT Things Graph resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_600302 = query.getOrDefault("maxResults")
  valid_600302 = validateParameter(valid_600302, JString, required = false,
                                 default = nil)
  if valid_600302 != nil:
    section.add "maxResults", valid_600302
  var valid_600303 = query.getOrDefault("nextToken")
  valid_600303 = validateParameter(valid_600303, JString, required = false,
                                 default = nil)
  if valid_600303 != nil:
    section.add "nextToken", valid_600303
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
  var valid_600304 = header.getOrDefault("X-Amz-Date")
  valid_600304 = validateParameter(valid_600304, JString, required = false,
                                 default = nil)
  if valid_600304 != nil:
    section.add "X-Amz-Date", valid_600304
  var valid_600305 = header.getOrDefault("X-Amz-Security-Token")
  valid_600305 = validateParameter(valid_600305, JString, required = false,
                                 default = nil)
  if valid_600305 != nil:
    section.add "X-Amz-Security-Token", valid_600305
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600306 = header.getOrDefault("X-Amz-Target")
  valid_600306 = validateParameter(valid_600306, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.ListTagsForResource"))
  if valid_600306 != nil:
    section.add "X-Amz-Target", valid_600306
  var valid_600307 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600307 = validateParameter(valid_600307, JString, required = false,
                                 default = nil)
  if valid_600307 != nil:
    section.add "X-Amz-Content-Sha256", valid_600307
  var valid_600308 = header.getOrDefault("X-Amz-Algorithm")
  valid_600308 = validateParameter(valid_600308, JString, required = false,
                                 default = nil)
  if valid_600308 != nil:
    section.add "X-Amz-Algorithm", valid_600308
  var valid_600309 = header.getOrDefault("X-Amz-Signature")
  valid_600309 = validateParameter(valid_600309, JString, required = false,
                                 default = nil)
  if valid_600309 != nil:
    section.add "X-Amz-Signature", valid_600309
  var valid_600310 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600310 = validateParameter(valid_600310, JString, required = false,
                                 default = nil)
  if valid_600310 != nil:
    section.add "X-Amz-SignedHeaders", valid_600310
  var valid_600311 = header.getOrDefault("X-Amz-Credential")
  valid_600311 = validateParameter(valid_600311, JString, required = false,
                                 default = nil)
  if valid_600311 != nil:
    section.add "X-Amz-Credential", valid_600311
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600313: Call_ListTagsForResource_600299; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all tags on an AWS IoT Things Graph resource.
  ## 
  let valid = call_600313.validator(path, query, header, formData, body)
  let scheme = call_600313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600313.url(scheme.get, call_600313.host, call_600313.base,
                         call_600313.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600313, url, valid)

proc call*(call_600314: Call_ListTagsForResource_600299; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listTagsForResource
  ## Lists all tags on an AWS IoT Things Graph resource.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600315 = newJObject()
  var body_600316 = newJObject()
  add(query_600315, "maxResults", newJString(maxResults))
  add(query_600315, "nextToken", newJString(nextToken))
  if body != nil:
    body_600316 = body
  result = call_600314.call(nil, query_600315, nil, nil, body_600316)

var listTagsForResource* = Call_ListTagsForResource_600299(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.ListTagsForResource",
    validator: validate_ListTagsForResource_600300, base: "/",
    url: url_ListTagsForResource_600301, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchEntities_600317 = ref object of OpenApiRestCall_599368
proc url_SearchEntities_600319(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SearchEntities_600318(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Searches for entities of the specified type. You can search for entities in your namespace and the public namespace that you're tracking.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_600320 = query.getOrDefault("maxResults")
  valid_600320 = validateParameter(valid_600320, JString, required = false,
                                 default = nil)
  if valid_600320 != nil:
    section.add "maxResults", valid_600320
  var valid_600321 = query.getOrDefault("nextToken")
  valid_600321 = validateParameter(valid_600321, JString, required = false,
                                 default = nil)
  if valid_600321 != nil:
    section.add "nextToken", valid_600321
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
  var valid_600322 = header.getOrDefault("X-Amz-Date")
  valid_600322 = validateParameter(valid_600322, JString, required = false,
                                 default = nil)
  if valid_600322 != nil:
    section.add "X-Amz-Date", valid_600322
  var valid_600323 = header.getOrDefault("X-Amz-Security-Token")
  valid_600323 = validateParameter(valid_600323, JString, required = false,
                                 default = nil)
  if valid_600323 != nil:
    section.add "X-Amz-Security-Token", valid_600323
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600324 = header.getOrDefault("X-Amz-Target")
  valid_600324 = validateParameter(valid_600324, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.SearchEntities"))
  if valid_600324 != nil:
    section.add "X-Amz-Target", valid_600324
  var valid_600325 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600325 = validateParameter(valid_600325, JString, required = false,
                                 default = nil)
  if valid_600325 != nil:
    section.add "X-Amz-Content-Sha256", valid_600325
  var valid_600326 = header.getOrDefault("X-Amz-Algorithm")
  valid_600326 = validateParameter(valid_600326, JString, required = false,
                                 default = nil)
  if valid_600326 != nil:
    section.add "X-Amz-Algorithm", valid_600326
  var valid_600327 = header.getOrDefault("X-Amz-Signature")
  valid_600327 = validateParameter(valid_600327, JString, required = false,
                                 default = nil)
  if valid_600327 != nil:
    section.add "X-Amz-Signature", valid_600327
  var valid_600328 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600328 = validateParameter(valid_600328, JString, required = false,
                                 default = nil)
  if valid_600328 != nil:
    section.add "X-Amz-SignedHeaders", valid_600328
  var valid_600329 = header.getOrDefault("X-Amz-Credential")
  valid_600329 = validateParameter(valid_600329, JString, required = false,
                                 default = nil)
  if valid_600329 != nil:
    section.add "X-Amz-Credential", valid_600329
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600331: Call_SearchEntities_600317; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches for entities of the specified type. You can search for entities in your namespace and the public namespace that you're tracking.
  ## 
  let valid = call_600331.validator(path, query, header, formData, body)
  let scheme = call_600331.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600331.url(scheme.get, call_600331.host, call_600331.base,
                         call_600331.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600331, url, valid)

proc call*(call_600332: Call_SearchEntities_600317; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## searchEntities
  ## Searches for entities of the specified type. You can search for entities in your namespace and the public namespace that you're tracking.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600333 = newJObject()
  var body_600334 = newJObject()
  add(query_600333, "maxResults", newJString(maxResults))
  add(query_600333, "nextToken", newJString(nextToken))
  if body != nil:
    body_600334 = body
  result = call_600332.call(nil, query_600333, nil, nil, body_600334)

var searchEntities* = Call_SearchEntities_600317(name: "searchEntities",
    meth: HttpMethod.HttpPost, host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.SearchEntities",
    validator: validate_SearchEntities_600318, base: "/", url: url_SearchEntities_600319,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchFlowExecutions_600335 = ref object of OpenApiRestCall_599368
proc url_SearchFlowExecutions_600337(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SearchFlowExecutions_600336(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Searches for AWS IoT Things Graph workflow execution instances.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_600338 = query.getOrDefault("maxResults")
  valid_600338 = validateParameter(valid_600338, JString, required = false,
                                 default = nil)
  if valid_600338 != nil:
    section.add "maxResults", valid_600338
  var valid_600339 = query.getOrDefault("nextToken")
  valid_600339 = validateParameter(valid_600339, JString, required = false,
                                 default = nil)
  if valid_600339 != nil:
    section.add "nextToken", valid_600339
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
  var valid_600340 = header.getOrDefault("X-Amz-Date")
  valid_600340 = validateParameter(valid_600340, JString, required = false,
                                 default = nil)
  if valid_600340 != nil:
    section.add "X-Amz-Date", valid_600340
  var valid_600341 = header.getOrDefault("X-Amz-Security-Token")
  valid_600341 = validateParameter(valid_600341, JString, required = false,
                                 default = nil)
  if valid_600341 != nil:
    section.add "X-Amz-Security-Token", valid_600341
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600342 = header.getOrDefault("X-Amz-Target")
  valid_600342 = validateParameter(valid_600342, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.SearchFlowExecutions"))
  if valid_600342 != nil:
    section.add "X-Amz-Target", valid_600342
  var valid_600343 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600343 = validateParameter(valid_600343, JString, required = false,
                                 default = nil)
  if valid_600343 != nil:
    section.add "X-Amz-Content-Sha256", valid_600343
  var valid_600344 = header.getOrDefault("X-Amz-Algorithm")
  valid_600344 = validateParameter(valid_600344, JString, required = false,
                                 default = nil)
  if valid_600344 != nil:
    section.add "X-Amz-Algorithm", valid_600344
  var valid_600345 = header.getOrDefault("X-Amz-Signature")
  valid_600345 = validateParameter(valid_600345, JString, required = false,
                                 default = nil)
  if valid_600345 != nil:
    section.add "X-Amz-Signature", valid_600345
  var valid_600346 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600346 = validateParameter(valid_600346, JString, required = false,
                                 default = nil)
  if valid_600346 != nil:
    section.add "X-Amz-SignedHeaders", valid_600346
  var valid_600347 = header.getOrDefault("X-Amz-Credential")
  valid_600347 = validateParameter(valid_600347, JString, required = false,
                                 default = nil)
  if valid_600347 != nil:
    section.add "X-Amz-Credential", valid_600347
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600349: Call_SearchFlowExecutions_600335; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches for AWS IoT Things Graph workflow execution instances.
  ## 
  let valid = call_600349.validator(path, query, header, formData, body)
  let scheme = call_600349.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600349.url(scheme.get, call_600349.host, call_600349.base,
                         call_600349.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600349, url, valid)

proc call*(call_600350: Call_SearchFlowExecutions_600335; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## searchFlowExecutions
  ## Searches for AWS IoT Things Graph workflow execution instances.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600351 = newJObject()
  var body_600352 = newJObject()
  add(query_600351, "maxResults", newJString(maxResults))
  add(query_600351, "nextToken", newJString(nextToken))
  if body != nil:
    body_600352 = body
  result = call_600350.call(nil, query_600351, nil, nil, body_600352)

var searchFlowExecutions* = Call_SearchFlowExecutions_600335(
    name: "searchFlowExecutions", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.SearchFlowExecutions",
    validator: validate_SearchFlowExecutions_600336, base: "/",
    url: url_SearchFlowExecutions_600337, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchFlowTemplates_600353 = ref object of OpenApiRestCall_599368
proc url_SearchFlowTemplates_600355(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SearchFlowTemplates_600354(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Searches for summary information about workflows.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_600356 = query.getOrDefault("maxResults")
  valid_600356 = validateParameter(valid_600356, JString, required = false,
                                 default = nil)
  if valid_600356 != nil:
    section.add "maxResults", valid_600356
  var valid_600357 = query.getOrDefault("nextToken")
  valid_600357 = validateParameter(valid_600357, JString, required = false,
                                 default = nil)
  if valid_600357 != nil:
    section.add "nextToken", valid_600357
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
  var valid_600358 = header.getOrDefault("X-Amz-Date")
  valid_600358 = validateParameter(valid_600358, JString, required = false,
                                 default = nil)
  if valid_600358 != nil:
    section.add "X-Amz-Date", valid_600358
  var valid_600359 = header.getOrDefault("X-Amz-Security-Token")
  valid_600359 = validateParameter(valid_600359, JString, required = false,
                                 default = nil)
  if valid_600359 != nil:
    section.add "X-Amz-Security-Token", valid_600359
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600360 = header.getOrDefault("X-Amz-Target")
  valid_600360 = validateParameter(valid_600360, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.SearchFlowTemplates"))
  if valid_600360 != nil:
    section.add "X-Amz-Target", valid_600360
  var valid_600361 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600361 = validateParameter(valid_600361, JString, required = false,
                                 default = nil)
  if valid_600361 != nil:
    section.add "X-Amz-Content-Sha256", valid_600361
  var valid_600362 = header.getOrDefault("X-Amz-Algorithm")
  valid_600362 = validateParameter(valid_600362, JString, required = false,
                                 default = nil)
  if valid_600362 != nil:
    section.add "X-Amz-Algorithm", valid_600362
  var valid_600363 = header.getOrDefault("X-Amz-Signature")
  valid_600363 = validateParameter(valid_600363, JString, required = false,
                                 default = nil)
  if valid_600363 != nil:
    section.add "X-Amz-Signature", valid_600363
  var valid_600364 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600364 = validateParameter(valid_600364, JString, required = false,
                                 default = nil)
  if valid_600364 != nil:
    section.add "X-Amz-SignedHeaders", valid_600364
  var valid_600365 = header.getOrDefault("X-Amz-Credential")
  valid_600365 = validateParameter(valid_600365, JString, required = false,
                                 default = nil)
  if valid_600365 != nil:
    section.add "X-Amz-Credential", valid_600365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600367: Call_SearchFlowTemplates_600353; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches for summary information about workflows.
  ## 
  let valid = call_600367.validator(path, query, header, formData, body)
  let scheme = call_600367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600367.url(scheme.get, call_600367.host, call_600367.base,
                         call_600367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600367, url, valid)

proc call*(call_600368: Call_SearchFlowTemplates_600353; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## searchFlowTemplates
  ## Searches for summary information about workflows.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600369 = newJObject()
  var body_600370 = newJObject()
  add(query_600369, "maxResults", newJString(maxResults))
  add(query_600369, "nextToken", newJString(nextToken))
  if body != nil:
    body_600370 = body
  result = call_600368.call(nil, query_600369, nil, nil, body_600370)

var searchFlowTemplates* = Call_SearchFlowTemplates_600353(
    name: "searchFlowTemplates", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.SearchFlowTemplates",
    validator: validate_SearchFlowTemplates_600354, base: "/",
    url: url_SearchFlowTemplates_600355, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchSystemInstances_600371 = ref object of OpenApiRestCall_599368
proc url_SearchSystemInstances_600373(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SearchSystemInstances_600372(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Searches for system instances in the user's account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_600374 = query.getOrDefault("maxResults")
  valid_600374 = validateParameter(valid_600374, JString, required = false,
                                 default = nil)
  if valid_600374 != nil:
    section.add "maxResults", valid_600374
  var valid_600375 = query.getOrDefault("nextToken")
  valid_600375 = validateParameter(valid_600375, JString, required = false,
                                 default = nil)
  if valid_600375 != nil:
    section.add "nextToken", valid_600375
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
  var valid_600376 = header.getOrDefault("X-Amz-Date")
  valid_600376 = validateParameter(valid_600376, JString, required = false,
                                 default = nil)
  if valid_600376 != nil:
    section.add "X-Amz-Date", valid_600376
  var valid_600377 = header.getOrDefault("X-Amz-Security-Token")
  valid_600377 = validateParameter(valid_600377, JString, required = false,
                                 default = nil)
  if valid_600377 != nil:
    section.add "X-Amz-Security-Token", valid_600377
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600378 = header.getOrDefault("X-Amz-Target")
  valid_600378 = validateParameter(valid_600378, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.SearchSystemInstances"))
  if valid_600378 != nil:
    section.add "X-Amz-Target", valid_600378
  var valid_600379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600379 = validateParameter(valid_600379, JString, required = false,
                                 default = nil)
  if valid_600379 != nil:
    section.add "X-Amz-Content-Sha256", valid_600379
  var valid_600380 = header.getOrDefault("X-Amz-Algorithm")
  valid_600380 = validateParameter(valid_600380, JString, required = false,
                                 default = nil)
  if valid_600380 != nil:
    section.add "X-Amz-Algorithm", valid_600380
  var valid_600381 = header.getOrDefault("X-Amz-Signature")
  valid_600381 = validateParameter(valid_600381, JString, required = false,
                                 default = nil)
  if valid_600381 != nil:
    section.add "X-Amz-Signature", valid_600381
  var valid_600382 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600382 = validateParameter(valid_600382, JString, required = false,
                                 default = nil)
  if valid_600382 != nil:
    section.add "X-Amz-SignedHeaders", valid_600382
  var valid_600383 = header.getOrDefault("X-Amz-Credential")
  valid_600383 = validateParameter(valid_600383, JString, required = false,
                                 default = nil)
  if valid_600383 != nil:
    section.add "X-Amz-Credential", valid_600383
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600385: Call_SearchSystemInstances_600371; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches for system instances in the user's account.
  ## 
  let valid = call_600385.validator(path, query, header, formData, body)
  let scheme = call_600385.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600385.url(scheme.get, call_600385.host, call_600385.base,
                         call_600385.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600385, url, valid)

proc call*(call_600386: Call_SearchSystemInstances_600371; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## searchSystemInstances
  ## Searches for system instances in the user's account.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600387 = newJObject()
  var body_600388 = newJObject()
  add(query_600387, "maxResults", newJString(maxResults))
  add(query_600387, "nextToken", newJString(nextToken))
  if body != nil:
    body_600388 = body
  result = call_600386.call(nil, query_600387, nil, nil, body_600388)

var searchSystemInstances* = Call_SearchSystemInstances_600371(
    name: "searchSystemInstances", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com", route: "/#X-Amz-Target=IotThingsGraphFrontEndService.SearchSystemInstances",
    validator: validate_SearchSystemInstances_600372, base: "/",
    url: url_SearchSystemInstances_600373, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchSystemTemplates_600389 = ref object of OpenApiRestCall_599368
proc url_SearchSystemTemplates_600391(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SearchSystemTemplates_600390(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Searches for summary information about systems in the user's account. You can filter by the ID of a workflow to return only systems that use the specified workflow.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_600392 = query.getOrDefault("maxResults")
  valid_600392 = validateParameter(valid_600392, JString, required = false,
                                 default = nil)
  if valid_600392 != nil:
    section.add "maxResults", valid_600392
  var valid_600393 = query.getOrDefault("nextToken")
  valid_600393 = validateParameter(valid_600393, JString, required = false,
                                 default = nil)
  if valid_600393 != nil:
    section.add "nextToken", valid_600393
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
  var valid_600394 = header.getOrDefault("X-Amz-Date")
  valid_600394 = validateParameter(valid_600394, JString, required = false,
                                 default = nil)
  if valid_600394 != nil:
    section.add "X-Amz-Date", valid_600394
  var valid_600395 = header.getOrDefault("X-Amz-Security-Token")
  valid_600395 = validateParameter(valid_600395, JString, required = false,
                                 default = nil)
  if valid_600395 != nil:
    section.add "X-Amz-Security-Token", valid_600395
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600396 = header.getOrDefault("X-Amz-Target")
  valid_600396 = validateParameter(valid_600396, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.SearchSystemTemplates"))
  if valid_600396 != nil:
    section.add "X-Amz-Target", valid_600396
  var valid_600397 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600397 = validateParameter(valid_600397, JString, required = false,
                                 default = nil)
  if valid_600397 != nil:
    section.add "X-Amz-Content-Sha256", valid_600397
  var valid_600398 = header.getOrDefault("X-Amz-Algorithm")
  valid_600398 = validateParameter(valid_600398, JString, required = false,
                                 default = nil)
  if valid_600398 != nil:
    section.add "X-Amz-Algorithm", valid_600398
  var valid_600399 = header.getOrDefault("X-Amz-Signature")
  valid_600399 = validateParameter(valid_600399, JString, required = false,
                                 default = nil)
  if valid_600399 != nil:
    section.add "X-Amz-Signature", valid_600399
  var valid_600400 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600400 = validateParameter(valid_600400, JString, required = false,
                                 default = nil)
  if valid_600400 != nil:
    section.add "X-Amz-SignedHeaders", valid_600400
  var valid_600401 = header.getOrDefault("X-Amz-Credential")
  valid_600401 = validateParameter(valid_600401, JString, required = false,
                                 default = nil)
  if valid_600401 != nil:
    section.add "X-Amz-Credential", valid_600401
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600403: Call_SearchSystemTemplates_600389; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches for summary information about systems in the user's account. You can filter by the ID of a workflow to return only systems that use the specified workflow.
  ## 
  let valid = call_600403.validator(path, query, header, formData, body)
  let scheme = call_600403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600403.url(scheme.get, call_600403.host, call_600403.base,
                         call_600403.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600403, url, valid)

proc call*(call_600404: Call_SearchSystemTemplates_600389; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## searchSystemTemplates
  ## Searches for summary information about systems in the user's account. You can filter by the ID of a workflow to return only systems that use the specified workflow.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600405 = newJObject()
  var body_600406 = newJObject()
  add(query_600405, "maxResults", newJString(maxResults))
  add(query_600405, "nextToken", newJString(nextToken))
  if body != nil:
    body_600406 = body
  result = call_600404.call(nil, query_600405, nil, nil, body_600406)

var searchSystemTemplates* = Call_SearchSystemTemplates_600389(
    name: "searchSystemTemplates", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com", route: "/#X-Amz-Target=IotThingsGraphFrontEndService.SearchSystemTemplates",
    validator: validate_SearchSystemTemplates_600390, base: "/",
    url: url_SearchSystemTemplates_600391, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchThings_600407 = ref object of OpenApiRestCall_599368
proc url_SearchThings_600409(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SearchThings_600408(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Searches for things associated with the specified entity. You can search by both device and device model.</p> <p>For example, if two different devices, camera1 and camera2, implement the camera device model, the user can associate thing1 to camera1 and thing2 to camera2. <code>SearchThings(camera2)</code> will return only thing2, but <code>SearchThings(camera)</code> will return both thing1 and thing2.</p> <p>This action searches for exact matches and doesn't perform partial text matching.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_600410 = query.getOrDefault("maxResults")
  valid_600410 = validateParameter(valid_600410, JString, required = false,
                                 default = nil)
  if valid_600410 != nil:
    section.add "maxResults", valid_600410
  var valid_600411 = query.getOrDefault("nextToken")
  valid_600411 = validateParameter(valid_600411, JString, required = false,
                                 default = nil)
  if valid_600411 != nil:
    section.add "nextToken", valid_600411
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
  var valid_600412 = header.getOrDefault("X-Amz-Date")
  valid_600412 = validateParameter(valid_600412, JString, required = false,
                                 default = nil)
  if valid_600412 != nil:
    section.add "X-Amz-Date", valid_600412
  var valid_600413 = header.getOrDefault("X-Amz-Security-Token")
  valid_600413 = validateParameter(valid_600413, JString, required = false,
                                 default = nil)
  if valid_600413 != nil:
    section.add "X-Amz-Security-Token", valid_600413
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600414 = header.getOrDefault("X-Amz-Target")
  valid_600414 = validateParameter(valid_600414, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.SearchThings"))
  if valid_600414 != nil:
    section.add "X-Amz-Target", valid_600414
  var valid_600415 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600415 = validateParameter(valid_600415, JString, required = false,
                                 default = nil)
  if valid_600415 != nil:
    section.add "X-Amz-Content-Sha256", valid_600415
  var valid_600416 = header.getOrDefault("X-Amz-Algorithm")
  valid_600416 = validateParameter(valid_600416, JString, required = false,
                                 default = nil)
  if valid_600416 != nil:
    section.add "X-Amz-Algorithm", valid_600416
  var valid_600417 = header.getOrDefault("X-Amz-Signature")
  valid_600417 = validateParameter(valid_600417, JString, required = false,
                                 default = nil)
  if valid_600417 != nil:
    section.add "X-Amz-Signature", valid_600417
  var valid_600418 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600418 = validateParameter(valid_600418, JString, required = false,
                                 default = nil)
  if valid_600418 != nil:
    section.add "X-Amz-SignedHeaders", valid_600418
  var valid_600419 = header.getOrDefault("X-Amz-Credential")
  valid_600419 = validateParameter(valid_600419, JString, required = false,
                                 default = nil)
  if valid_600419 != nil:
    section.add "X-Amz-Credential", valid_600419
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600421: Call_SearchThings_600407; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Searches for things associated with the specified entity. You can search by both device and device model.</p> <p>For example, if two different devices, camera1 and camera2, implement the camera device model, the user can associate thing1 to camera1 and thing2 to camera2. <code>SearchThings(camera2)</code> will return only thing2, but <code>SearchThings(camera)</code> will return both thing1 and thing2.</p> <p>This action searches for exact matches and doesn't perform partial text matching.</p>
  ## 
  let valid = call_600421.validator(path, query, header, formData, body)
  let scheme = call_600421.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600421.url(scheme.get, call_600421.host, call_600421.base,
                         call_600421.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600421, url, valid)

proc call*(call_600422: Call_SearchThings_600407; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## searchThings
  ## <p>Searches for things associated with the specified entity. You can search by both device and device model.</p> <p>For example, if two different devices, camera1 and camera2, implement the camera device model, the user can associate thing1 to camera1 and thing2 to camera2. <code>SearchThings(camera2)</code> will return only thing2, but <code>SearchThings(camera)</code> will return both thing1 and thing2.</p> <p>This action searches for exact matches and doesn't perform partial text matching.</p>
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600423 = newJObject()
  var body_600424 = newJObject()
  add(query_600423, "maxResults", newJString(maxResults))
  add(query_600423, "nextToken", newJString(nextToken))
  if body != nil:
    body_600424 = body
  result = call_600422.call(nil, query_600423, nil, nil, body_600424)

var searchThings* = Call_SearchThings_600407(name: "searchThings",
    meth: HttpMethod.HttpPost, host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.SearchThings",
    validator: validate_SearchThings_600408, base: "/", url: url_SearchThings_600409,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_600425 = ref object of OpenApiRestCall_599368
proc url_TagResource_600427(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_600426(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600428 = header.getOrDefault("X-Amz-Date")
  valid_600428 = validateParameter(valid_600428, JString, required = false,
                                 default = nil)
  if valid_600428 != nil:
    section.add "X-Amz-Date", valid_600428
  var valid_600429 = header.getOrDefault("X-Amz-Security-Token")
  valid_600429 = validateParameter(valid_600429, JString, required = false,
                                 default = nil)
  if valid_600429 != nil:
    section.add "X-Amz-Security-Token", valid_600429
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600430 = header.getOrDefault("X-Amz-Target")
  valid_600430 = validateParameter(valid_600430, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.TagResource"))
  if valid_600430 != nil:
    section.add "X-Amz-Target", valid_600430
  var valid_600431 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600431 = validateParameter(valid_600431, JString, required = false,
                                 default = nil)
  if valid_600431 != nil:
    section.add "X-Amz-Content-Sha256", valid_600431
  var valid_600432 = header.getOrDefault("X-Amz-Algorithm")
  valid_600432 = validateParameter(valid_600432, JString, required = false,
                                 default = nil)
  if valid_600432 != nil:
    section.add "X-Amz-Algorithm", valid_600432
  var valid_600433 = header.getOrDefault("X-Amz-Signature")
  valid_600433 = validateParameter(valid_600433, JString, required = false,
                                 default = nil)
  if valid_600433 != nil:
    section.add "X-Amz-Signature", valid_600433
  var valid_600434 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600434 = validateParameter(valid_600434, JString, required = false,
                                 default = nil)
  if valid_600434 != nil:
    section.add "X-Amz-SignedHeaders", valid_600434
  var valid_600435 = header.getOrDefault("X-Amz-Credential")
  valid_600435 = validateParameter(valid_600435, JString, required = false,
                                 default = nil)
  if valid_600435 != nil:
    section.add "X-Amz-Credential", valid_600435
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600437: Call_TagResource_600425; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a tag for the specified resource.
  ## 
  let valid = call_600437.validator(path, query, header, formData, body)
  let scheme = call_600437.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600437.url(scheme.get, call_600437.host, call_600437.base,
                         call_600437.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600437, url, valid)

proc call*(call_600438: Call_TagResource_600425; body: JsonNode): Recallable =
  ## tagResource
  ## Creates a tag for the specified resource.
  ##   body: JObject (required)
  var body_600439 = newJObject()
  if body != nil:
    body_600439 = body
  result = call_600438.call(nil, nil, nil, nil, body_600439)

var tagResource* = Call_TagResource_600425(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "iotthingsgraph.amazonaws.com", route: "/#X-Amz-Target=IotThingsGraphFrontEndService.TagResource",
                                        validator: validate_TagResource_600426,
                                        base: "/", url: url_TagResource_600427,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UndeploySystemInstance_600440 = ref object of OpenApiRestCall_599368
proc url_UndeploySystemInstance_600442(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UndeploySystemInstance_600441(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600443 = header.getOrDefault("X-Amz-Date")
  valid_600443 = validateParameter(valid_600443, JString, required = false,
                                 default = nil)
  if valid_600443 != nil:
    section.add "X-Amz-Date", valid_600443
  var valid_600444 = header.getOrDefault("X-Amz-Security-Token")
  valid_600444 = validateParameter(valid_600444, JString, required = false,
                                 default = nil)
  if valid_600444 != nil:
    section.add "X-Amz-Security-Token", valid_600444
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600445 = header.getOrDefault("X-Amz-Target")
  valid_600445 = validateParameter(valid_600445, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.UndeploySystemInstance"))
  if valid_600445 != nil:
    section.add "X-Amz-Target", valid_600445
  var valid_600446 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600446 = validateParameter(valid_600446, JString, required = false,
                                 default = nil)
  if valid_600446 != nil:
    section.add "X-Amz-Content-Sha256", valid_600446
  var valid_600447 = header.getOrDefault("X-Amz-Algorithm")
  valid_600447 = validateParameter(valid_600447, JString, required = false,
                                 default = nil)
  if valid_600447 != nil:
    section.add "X-Amz-Algorithm", valid_600447
  var valid_600448 = header.getOrDefault("X-Amz-Signature")
  valid_600448 = validateParameter(valid_600448, JString, required = false,
                                 default = nil)
  if valid_600448 != nil:
    section.add "X-Amz-Signature", valid_600448
  var valid_600449 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600449 = validateParameter(valid_600449, JString, required = false,
                                 default = nil)
  if valid_600449 != nil:
    section.add "X-Amz-SignedHeaders", valid_600449
  var valid_600450 = header.getOrDefault("X-Amz-Credential")
  valid_600450 = validateParameter(valid_600450, JString, required = false,
                                 default = nil)
  if valid_600450 != nil:
    section.add "X-Amz-Credential", valid_600450
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600452: Call_UndeploySystemInstance_600440; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a system instance from its target (Cloud or Greengrass).
  ## 
  let valid = call_600452.validator(path, query, header, formData, body)
  let scheme = call_600452.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600452.url(scheme.get, call_600452.host, call_600452.base,
                         call_600452.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600452, url, valid)

proc call*(call_600453: Call_UndeploySystemInstance_600440; body: JsonNode): Recallable =
  ## undeploySystemInstance
  ## Removes a system instance from its target (Cloud or Greengrass).
  ##   body: JObject (required)
  var body_600454 = newJObject()
  if body != nil:
    body_600454 = body
  result = call_600453.call(nil, nil, nil, nil, body_600454)

var undeploySystemInstance* = Call_UndeploySystemInstance_600440(
    name: "undeploySystemInstance", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com", route: "/#X-Amz-Target=IotThingsGraphFrontEndService.UndeploySystemInstance",
    validator: validate_UndeploySystemInstance_600441, base: "/",
    url: url_UndeploySystemInstance_600442, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_600455 = ref object of OpenApiRestCall_599368
proc url_UntagResource_600457(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_600456(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600458 = header.getOrDefault("X-Amz-Date")
  valid_600458 = validateParameter(valid_600458, JString, required = false,
                                 default = nil)
  if valid_600458 != nil:
    section.add "X-Amz-Date", valid_600458
  var valid_600459 = header.getOrDefault("X-Amz-Security-Token")
  valid_600459 = validateParameter(valid_600459, JString, required = false,
                                 default = nil)
  if valid_600459 != nil:
    section.add "X-Amz-Security-Token", valid_600459
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600460 = header.getOrDefault("X-Amz-Target")
  valid_600460 = validateParameter(valid_600460, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.UntagResource"))
  if valid_600460 != nil:
    section.add "X-Amz-Target", valid_600460
  var valid_600461 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600461 = validateParameter(valid_600461, JString, required = false,
                                 default = nil)
  if valid_600461 != nil:
    section.add "X-Amz-Content-Sha256", valid_600461
  var valid_600462 = header.getOrDefault("X-Amz-Algorithm")
  valid_600462 = validateParameter(valid_600462, JString, required = false,
                                 default = nil)
  if valid_600462 != nil:
    section.add "X-Amz-Algorithm", valid_600462
  var valid_600463 = header.getOrDefault("X-Amz-Signature")
  valid_600463 = validateParameter(valid_600463, JString, required = false,
                                 default = nil)
  if valid_600463 != nil:
    section.add "X-Amz-Signature", valid_600463
  var valid_600464 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600464 = validateParameter(valid_600464, JString, required = false,
                                 default = nil)
  if valid_600464 != nil:
    section.add "X-Amz-SignedHeaders", valid_600464
  var valid_600465 = header.getOrDefault("X-Amz-Credential")
  valid_600465 = validateParameter(valid_600465, JString, required = false,
                                 default = nil)
  if valid_600465 != nil:
    section.add "X-Amz-Credential", valid_600465
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600467: Call_UntagResource_600455; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a tag from the specified resource.
  ## 
  let valid = call_600467.validator(path, query, header, formData, body)
  let scheme = call_600467.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600467.url(scheme.get, call_600467.host, call_600467.base,
                         call_600467.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600467, url, valid)

proc call*(call_600468: Call_UntagResource_600455; body: JsonNode): Recallable =
  ## untagResource
  ## Removes a tag from the specified resource.
  ##   body: JObject (required)
  var body_600469 = newJObject()
  if body != nil:
    body_600469 = body
  result = call_600468.call(nil, nil, nil, nil, body_600469)

var untagResource* = Call_UntagResource_600455(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.UntagResource",
    validator: validate_UntagResource_600456, base: "/", url: url_UntagResource_600457,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFlowTemplate_600470 = ref object of OpenApiRestCall_599368
proc url_UpdateFlowTemplate_600472(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateFlowTemplate_600471(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600473 = header.getOrDefault("X-Amz-Date")
  valid_600473 = validateParameter(valid_600473, JString, required = false,
                                 default = nil)
  if valid_600473 != nil:
    section.add "X-Amz-Date", valid_600473
  var valid_600474 = header.getOrDefault("X-Amz-Security-Token")
  valid_600474 = validateParameter(valid_600474, JString, required = false,
                                 default = nil)
  if valid_600474 != nil:
    section.add "X-Amz-Security-Token", valid_600474
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600475 = header.getOrDefault("X-Amz-Target")
  valid_600475 = validateParameter(valid_600475, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.UpdateFlowTemplate"))
  if valid_600475 != nil:
    section.add "X-Amz-Target", valid_600475
  var valid_600476 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600476 = validateParameter(valid_600476, JString, required = false,
                                 default = nil)
  if valid_600476 != nil:
    section.add "X-Amz-Content-Sha256", valid_600476
  var valid_600477 = header.getOrDefault("X-Amz-Algorithm")
  valid_600477 = validateParameter(valid_600477, JString, required = false,
                                 default = nil)
  if valid_600477 != nil:
    section.add "X-Amz-Algorithm", valid_600477
  var valid_600478 = header.getOrDefault("X-Amz-Signature")
  valid_600478 = validateParameter(valid_600478, JString, required = false,
                                 default = nil)
  if valid_600478 != nil:
    section.add "X-Amz-Signature", valid_600478
  var valid_600479 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600479 = validateParameter(valid_600479, JString, required = false,
                                 default = nil)
  if valid_600479 != nil:
    section.add "X-Amz-SignedHeaders", valid_600479
  var valid_600480 = header.getOrDefault("X-Amz-Credential")
  valid_600480 = validateParameter(valid_600480, JString, required = false,
                                 default = nil)
  if valid_600480 != nil:
    section.add "X-Amz-Credential", valid_600480
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600482: Call_UpdateFlowTemplate_600470; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified workflow. All deployed systems and system instances that use the workflow will see the changes in the flow when it is redeployed. If you don't want this behavior, copy the workflow (creating a new workflow with a different ID), and update the copy. The workflow can contain only entities in the specified namespace. 
  ## 
  let valid = call_600482.validator(path, query, header, formData, body)
  let scheme = call_600482.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600482.url(scheme.get, call_600482.host, call_600482.base,
                         call_600482.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600482, url, valid)

proc call*(call_600483: Call_UpdateFlowTemplate_600470; body: JsonNode): Recallable =
  ## updateFlowTemplate
  ## Updates the specified workflow. All deployed systems and system instances that use the workflow will see the changes in the flow when it is redeployed. If you don't want this behavior, copy the workflow (creating a new workflow with a different ID), and update the copy. The workflow can contain only entities in the specified namespace. 
  ##   body: JObject (required)
  var body_600484 = newJObject()
  if body != nil:
    body_600484 = body
  result = call_600483.call(nil, nil, nil, nil, body_600484)

var updateFlowTemplate* = Call_UpdateFlowTemplate_600470(
    name: "updateFlowTemplate", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.UpdateFlowTemplate",
    validator: validate_UpdateFlowTemplate_600471, base: "/",
    url: url_UpdateFlowTemplate_600472, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSystemTemplate_600485 = ref object of OpenApiRestCall_599368
proc url_UpdateSystemTemplate_600487(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateSystemTemplate_600486(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600488 = header.getOrDefault("X-Amz-Date")
  valid_600488 = validateParameter(valid_600488, JString, required = false,
                                 default = nil)
  if valid_600488 != nil:
    section.add "X-Amz-Date", valid_600488
  var valid_600489 = header.getOrDefault("X-Amz-Security-Token")
  valid_600489 = validateParameter(valid_600489, JString, required = false,
                                 default = nil)
  if valid_600489 != nil:
    section.add "X-Amz-Security-Token", valid_600489
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600490 = header.getOrDefault("X-Amz-Target")
  valid_600490 = validateParameter(valid_600490, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.UpdateSystemTemplate"))
  if valid_600490 != nil:
    section.add "X-Amz-Target", valid_600490
  var valid_600491 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600491 = validateParameter(valid_600491, JString, required = false,
                                 default = nil)
  if valid_600491 != nil:
    section.add "X-Amz-Content-Sha256", valid_600491
  var valid_600492 = header.getOrDefault("X-Amz-Algorithm")
  valid_600492 = validateParameter(valid_600492, JString, required = false,
                                 default = nil)
  if valid_600492 != nil:
    section.add "X-Amz-Algorithm", valid_600492
  var valid_600493 = header.getOrDefault("X-Amz-Signature")
  valid_600493 = validateParameter(valid_600493, JString, required = false,
                                 default = nil)
  if valid_600493 != nil:
    section.add "X-Amz-Signature", valid_600493
  var valid_600494 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600494 = validateParameter(valid_600494, JString, required = false,
                                 default = nil)
  if valid_600494 != nil:
    section.add "X-Amz-SignedHeaders", valid_600494
  var valid_600495 = header.getOrDefault("X-Amz-Credential")
  valid_600495 = validateParameter(valid_600495, JString, required = false,
                                 default = nil)
  if valid_600495 != nil:
    section.add "X-Amz-Credential", valid_600495
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600497: Call_UpdateSystemTemplate_600485; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified system. You don't need to run this action after updating a workflow. Any deployment that uses the system will see the changes in the system when it is redeployed.
  ## 
  let valid = call_600497.validator(path, query, header, formData, body)
  let scheme = call_600497.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600497.url(scheme.get, call_600497.host, call_600497.base,
                         call_600497.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600497, url, valid)

proc call*(call_600498: Call_UpdateSystemTemplate_600485; body: JsonNode): Recallable =
  ## updateSystemTemplate
  ## Updates the specified system. You don't need to run this action after updating a workflow. Any deployment that uses the system will see the changes in the system when it is redeployed.
  ##   body: JObject (required)
  var body_600499 = newJObject()
  if body != nil:
    body_600499 = body
  result = call_600498.call(nil, nil, nil, nil, body_600499)

var updateSystemTemplate* = Call_UpdateSystemTemplate_600485(
    name: "updateSystemTemplate", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.UpdateSystemTemplate",
    validator: validate_UpdateSystemTemplate_600486, base: "/",
    url: url_UpdateSystemTemplate_600487, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UploadEntityDefinitions_600500 = ref object of OpenApiRestCall_599368
proc url_UploadEntityDefinitions_600502(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UploadEntityDefinitions_600501(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600503 = header.getOrDefault("X-Amz-Date")
  valid_600503 = validateParameter(valid_600503, JString, required = false,
                                 default = nil)
  if valid_600503 != nil:
    section.add "X-Amz-Date", valid_600503
  var valid_600504 = header.getOrDefault("X-Amz-Security-Token")
  valid_600504 = validateParameter(valid_600504, JString, required = false,
                                 default = nil)
  if valid_600504 != nil:
    section.add "X-Amz-Security-Token", valid_600504
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600505 = header.getOrDefault("X-Amz-Target")
  valid_600505 = validateParameter(valid_600505, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.UploadEntityDefinitions"))
  if valid_600505 != nil:
    section.add "X-Amz-Target", valid_600505
  var valid_600506 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600506 = validateParameter(valid_600506, JString, required = false,
                                 default = nil)
  if valid_600506 != nil:
    section.add "X-Amz-Content-Sha256", valid_600506
  var valid_600507 = header.getOrDefault("X-Amz-Algorithm")
  valid_600507 = validateParameter(valid_600507, JString, required = false,
                                 default = nil)
  if valid_600507 != nil:
    section.add "X-Amz-Algorithm", valid_600507
  var valid_600508 = header.getOrDefault("X-Amz-Signature")
  valid_600508 = validateParameter(valid_600508, JString, required = false,
                                 default = nil)
  if valid_600508 != nil:
    section.add "X-Amz-Signature", valid_600508
  var valid_600509 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600509 = validateParameter(valid_600509, JString, required = false,
                                 default = nil)
  if valid_600509 != nil:
    section.add "X-Amz-SignedHeaders", valid_600509
  var valid_600510 = header.getOrDefault("X-Amz-Credential")
  valid_600510 = validateParameter(valid_600510, JString, required = false,
                                 default = nil)
  if valid_600510 != nil:
    section.add "X-Amz-Credential", valid_600510
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600512: Call_UploadEntityDefinitions_600500; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Asynchronously uploads one or more entity definitions to the user's namespace. The <code>document</code> parameter is required if <code>syncWithPublicNamespace</code> and <code>deleteExistingEntites</code> are false. If the <code>syncWithPublicNamespace</code> parameter is set to <code>true</code>, the user's namespace will synchronize with the latest version of the public namespace. If <code>deprecateExistingEntities</code> is set to true, all entities in the latest version will be deleted before the new <code>DefinitionDocument</code> is uploaded.</p> <p>When a user uploads entity definitions for the first time, the service creates a new namespace for the user. The new namespace tracks the public namespace. Currently users can have only one namespace. The namespace version increments whenever a user uploads entity definitions that are backwards-incompatible and whenever a user sets the <code>syncWithPublicNamespace</code> parameter or the <code>deprecateExistingEntities</code> parameter to <code>true</code>.</p> <p>The IDs for all of the entities should be in URN format. Each entity must be in the user's namespace. Users can't create entities in the public namespace, but entity definitions can refer to entities in the public namespace.</p> <p>Valid entities are <code>Device</code>, <code>DeviceModel</code>, <code>Service</code>, <code>Capability</code>, <code>State</code>, <code>Action</code>, <code>Event</code>, <code>Property</code>, <code>Mapping</code>, <code>Enum</code>. </p>
  ## 
  let valid = call_600512.validator(path, query, header, formData, body)
  let scheme = call_600512.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600512.url(scheme.get, call_600512.host, call_600512.base,
                         call_600512.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600512, url, valid)

proc call*(call_600513: Call_UploadEntityDefinitions_600500; body: JsonNode): Recallable =
  ## uploadEntityDefinitions
  ## <p>Asynchronously uploads one or more entity definitions to the user's namespace. The <code>document</code> parameter is required if <code>syncWithPublicNamespace</code> and <code>deleteExistingEntites</code> are false. If the <code>syncWithPublicNamespace</code> parameter is set to <code>true</code>, the user's namespace will synchronize with the latest version of the public namespace. If <code>deprecateExistingEntities</code> is set to true, all entities in the latest version will be deleted before the new <code>DefinitionDocument</code> is uploaded.</p> <p>When a user uploads entity definitions for the first time, the service creates a new namespace for the user. The new namespace tracks the public namespace. Currently users can have only one namespace. The namespace version increments whenever a user uploads entity definitions that are backwards-incompatible and whenever a user sets the <code>syncWithPublicNamespace</code> parameter or the <code>deprecateExistingEntities</code> parameter to <code>true</code>.</p> <p>The IDs for all of the entities should be in URN format. Each entity must be in the user's namespace. Users can't create entities in the public namespace, but entity definitions can refer to entities in the public namespace.</p> <p>Valid entities are <code>Device</code>, <code>DeviceModel</code>, <code>Service</code>, <code>Capability</code>, <code>State</code>, <code>Action</code>, <code>Event</code>, <code>Property</code>, <code>Mapping</code>, <code>Enum</code>. </p>
  ##   body: JObject (required)
  var body_600514 = newJObject()
  if body != nil:
    body_600514 = body
  result = call_600513.call(nil, nil, nil, nil, body_600514)

var uploadEntityDefinitions* = Call_UploadEntityDefinitions_600500(
    name: "uploadEntityDefinitions", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com", route: "/#X-Amz-Target=IotThingsGraphFrontEndService.UploadEntityDefinitions",
    validator: validate_UploadEntityDefinitions_600501, base: "/",
    url: url_UploadEntityDefinitions_600502, schemes: {Scheme.Https, Scheme.Http})
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
