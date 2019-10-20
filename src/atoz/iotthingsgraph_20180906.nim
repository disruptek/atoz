
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_592364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592364): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AssociateEntityToThing_592703 = ref object of OpenApiRestCall_592364
proc url_AssociateEntityToThing_592705(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AssociateEntityToThing_592704(path: JsonNode; query: JsonNode;
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
  var valid_592830 = header.getOrDefault("X-Amz-Target")
  valid_592830 = validateParameter(valid_592830, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.AssociateEntityToThing"))
  if valid_592830 != nil:
    section.add "X-Amz-Target", valid_592830
  var valid_592831 = header.getOrDefault("X-Amz-Signature")
  valid_592831 = validateParameter(valid_592831, JString, required = false,
                                 default = nil)
  if valid_592831 != nil:
    section.add "X-Amz-Signature", valid_592831
  var valid_592832 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592832 = validateParameter(valid_592832, JString, required = false,
                                 default = nil)
  if valid_592832 != nil:
    section.add "X-Amz-Content-Sha256", valid_592832
  var valid_592833 = header.getOrDefault("X-Amz-Date")
  valid_592833 = validateParameter(valid_592833, JString, required = false,
                                 default = nil)
  if valid_592833 != nil:
    section.add "X-Amz-Date", valid_592833
  var valid_592834 = header.getOrDefault("X-Amz-Credential")
  valid_592834 = validateParameter(valid_592834, JString, required = false,
                                 default = nil)
  if valid_592834 != nil:
    section.add "X-Amz-Credential", valid_592834
  var valid_592835 = header.getOrDefault("X-Amz-Security-Token")
  valid_592835 = validateParameter(valid_592835, JString, required = false,
                                 default = nil)
  if valid_592835 != nil:
    section.add "X-Amz-Security-Token", valid_592835
  var valid_592836 = header.getOrDefault("X-Amz-Algorithm")
  valid_592836 = validateParameter(valid_592836, JString, required = false,
                                 default = nil)
  if valid_592836 != nil:
    section.add "X-Amz-Algorithm", valid_592836
  var valid_592837 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592837 = validateParameter(valid_592837, JString, required = false,
                                 default = nil)
  if valid_592837 != nil:
    section.add "X-Amz-SignedHeaders", valid_592837
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592861: Call_AssociateEntityToThing_592703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates a device with a concrete thing that is in the user's registry.</p> <p>A thing can be associated with only one device at a time. If you associate a thing with a new device id, its previous association will be removed.</p>
  ## 
  let valid = call_592861.validator(path, query, header, formData, body)
  let scheme = call_592861.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592861.url(scheme.get, call_592861.host, call_592861.base,
                         call_592861.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592861, url, valid)

proc call*(call_592932: Call_AssociateEntityToThing_592703; body: JsonNode): Recallable =
  ## associateEntityToThing
  ## <p>Associates a device with a concrete thing that is in the user's registry.</p> <p>A thing can be associated with only one device at a time. If you associate a thing with a new device id, its previous association will be removed.</p>
  ##   body: JObject (required)
  var body_592933 = newJObject()
  if body != nil:
    body_592933 = body
  result = call_592932.call(nil, nil, nil, nil, body_592933)

var associateEntityToThing* = Call_AssociateEntityToThing_592703(
    name: "associateEntityToThing", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com", route: "/#X-Amz-Target=IotThingsGraphFrontEndService.AssociateEntityToThing",
    validator: validate_AssociateEntityToThing_592704, base: "/",
    url: url_AssociateEntityToThing_592705, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFlowTemplate_592972 = ref object of OpenApiRestCall_592364
proc url_CreateFlowTemplate_592974(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateFlowTemplate_592973(path: JsonNode; query: JsonNode;
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
  var valid_592975 = header.getOrDefault("X-Amz-Target")
  valid_592975 = validateParameter(valid_592975, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.CreateFlowTemplate"))
  if valid_592975 != nil:
    section.add "X-Amz-Target", valid_592975
  var valid_592976 = header.getOrDefault("X-Amz-Signature")
  valid_592976 = validateParameter(valid_592976, JString, required = false,
                                 default = nil)
  if valid_592976 != nil:
    section.add "X-Amz-Signature", valid_592976
  var valid_592977 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592977 = validateParameter(valid_592977, JString, required = false,
                                 default = nil)
  if valid_592977 != nil:
    section.add "X-Amz-Content-Sha256", valid_592977
  var valid_592978 = header.getOrDefault("X-Amz-Date")
  valid_592978 = validateParameter(valid_592978, JString, required = false,
                                 default = nil)
  if valid_592978 != nil:
    section.add "X-Amz-Date", valid_592978
  var valid_592979 = header.getOrDefault("X-Amz-Credential")
  valid_592979 = validateParameter(valid_592979, JString, required = false,
                                 default = nil)
  if valid_592979 != nil:
    section.add "X-Amz-Credential", valid_592979
  var valid_592980 = header.getOrDefault("X-Amz-Security-Token")
  valid_592980 = validateParameter(valid_592980, JString, required = false,
                                 default = nil)
  if valid_592980 != nil:
    section.add "X-Amz-Security-Token", valid_592980
  var valid_592981 = header.getOrDefault("X-Amz-Algorithm")
  valid_592981 = validateParameter(valid_592981, JString, required = false,
                                 default = nil)
  if valid_592981 != nil:
    section.add "X-Amz-Algorithm", valid_592981
  var valid_592982 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592982 = validateParameter(valid_592982, JString, required = false,
                                 default = nil)
  if valid_592982 != nil:
    section.add "X-Amz-SignedHeaders", valid_592982
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592984: Call_CreateFlowTemplate_592972; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a workflow template. Workflows can be created only in the user's namespace. (The public namespace contains only entities.) The workflow can contain only entities in the specified namespace. The workflow is validated against the entities in the latest version of the user's namespace unless another namespace version is specified in the request.
  ## 
  let valid = call_592984.validator(path, query, header, formData, body)
  let scheme = call_592984.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592984.url(scheme.get, call_592984.host, call_592984.base,
                         call_592984.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592984, url, valid)

proc call*(call_592985: Call_CreateFlowTemplate_592972; body: JsonNode): Recallable =
  ## createFlowTemplate
  ## Creates a workflow template. Workflows can be created only in the user's namespace. (The public namespace contains only entities.) The workflow can contain only entities in the specified namespace. The workflow is validated against the entities in the latest version of the user's namespace unless another namespace version is specified in the request.
  ##   body: JObject (required)
  var body_592986 = newJObject()
  if body != nil:
    body_592986 = body
  result = call_592985.call(nil, nil, nil, nil, body_592986)

var createFlowTemplate* = Call_CreateFlowTemplate_592972(
    name: "createFlowTemplate", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.CreateFlowTemplate",
    validator: validate_CreateFlowTemplate_592973, base: "/",
    url: url_CreateFlowTemplate_592974, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSystemInstance_592987 = ref object of OpenApiRestCall_592364
proc url_CreateSystemInstance_592989(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateSystemInstance_592988(path: JsonNode; query: JsonNode;
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
  var valid_592990 = header.getOrDefault("X-Amz-Target")
  valid_592990 = validateParameter(valid_592990, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.CreateSystemInstance"))
  if valid_592990 != nil:
    section.add "X-Amz-Target", valid_592990
  var valid_592991 = header.getOrDefault("X-Amz-Signature")
  valid_592991 = validateParameter(valid_592991, JString, required = false,
                                 default = nil)
  if valid_592991 != nil:
    section.add "X-Amz-Signature", valid_592991
  var valid_592992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592992 = validateParameter(valid_592992, JString, required = false,
                                 default = nil)
  if valid_592992 != nil:
    section.add "X-Amz-Content-Sha256", valid_592992
  var valid_592993 = header.getOrDefault("X-Amz-Date")
  valid_592993 = validateParameter(valid_592993, JString, required = false,
                                 default = nil)
  if valid_592993 != nil:
    section.add "X-Amz-Date", valid_592993
  var valid_592994 = header.getOrDefault("X-Amz-Credential")
  valid_592994 = validateParameter(valid_592994, JString, required = false,
                                 default = nil)
  if valid_592994 != nil:
    section.add "X-Amz-Credential", valid_592994
  var valid_592995 = header.getOrDefault("X-Amz-Security-Token")
  valid_592995 = validateParameter(valid_592995, JString, required = false,
                                 default = nil)
  if valid_592995 != nil:
    section.add "X-Amz-Security-Token", valid_592995
  var valid_592996 = header.getOrDefault("X-Amz-Algorithm")
  valid_592996 = validateParameter(valid_592996, JString, required = false,
                                 default = nil)
  if valid_592996 != nil:
    section.add "X-Amz-Algorithm", valid_592996
  var valid_592997 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592997 = validateParameter(valid_592997, JString, required = false,
                                 default = nil)
  if valid_592997 != nil:
    section.add "X-Amz-SignedHeaders", valid_592997
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592999: Call_CreateSystemInstance_592987; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a system instance. </p> <p>This action validates the system instance, prepares the deployment-related resources. For Greengrass deployments, it updates the Greengrass group that is specified by the <code>greengrassGroupName</code> parameter. It also adds a file to the S3 bucket specified by the <code>s3BucketName</code> parameter. You need to call <code>DeploySystemInstance</code> after running this action.</p> <p>For Greengrass deployments, since this action modifies and adds resources to a Greengrass group and an S3 bucket on the caller's behalf, the calling identity must have write permissions to both the specified Greengrass group and S3 bucket. Otherwise, the call will fail with an authorization error.</p> <p>For cloud deployments, this action requires a <code>flowActionsRoleArn</code> value. This is an IAM role that has permissions to access AWS services, such as AWS Lambda and AWS IoT, that the flow uses when it executes.</p> <p>If the definition document doesn't specify a version of the user's namespace, the latest version will be used by default.</p>
  ## 
  let valid = call_592999.validator(path, query, header, formData, body)
  let scheme = call_592999.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592999.url(scheme.get, call_592999.host, call_592999.base,
                         call_592999.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592999, url, valid)

proc call*(call_593000: Call_CreateSystemInstance_592987; body: JsonNode): Recallable =
  ## createSystemInstance
  ## <p>Creates a system instance. </p> <p>This action validates the system instance, prepares the deployment-related resources. For Greengrass deployments, it updates the Greengrass group that is specified by the <code>greengrassGroupName</code> parameter. It also adds a file to the S3 bucket specified by the <code>s3BucketName</code> parameter. You need to call <code>DeploySystemInstance</code> after running this action.</p> <p>For Greengrass deployments, since this action modifies and adds resources to a Greengrass group and an S3 bucket on the caller's behalf, the calling identity must have write permissions to both the specified Greengrass group and S3 bucket. Otherwise, the call will fail with an authorization error.</p> <p>For cloud deployments, this action requires a <code>flowActionsRoleArn</code> value. This is an IAM role that has permissions to access AWS services, such as AWS Lambda and AWS IoT, that the flow uses when it executes.</p> <p>If the definition document doesn't specify a version of the user's namespace, the latest version will be used by default.</p>
  ##   body: JObject (required)
  var body_593001 = newJObject()
  if body != nil:
    body_593001 = body
  result = call_593000.call(nil, nil, nil, nil, body_593001)

var createSystemInstance* = Call_CreateSystemInstance_592987(
    name: "createSystemInstance", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.CreateSystemInstance",
    validator: validate_CreateSystemInstance_592988, base: "/",
    url: url_CreateSystemInstance_592989, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSystemTemplate_593002 = ref object of OpenApiRestCall_592364
proc url_CreateSystemTemplate_593004(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateSystemTemplate_593003(path: JsonNode; query: JsonNode;
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
  var valid_593005 = header.getOrDefault("X-Amz-Target")
  valid_593005 = validateParameter(valid_593005, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.CreateSystemTemplate"))
  if valid_593005 != nil:
    section.add "X-Amz-Target", valid_593005
  var valid_593006 = header.getOrDefault("X-Amz-Signature")
  valid_593006 = validateParameter(valid_593006, JString, required = false,
                                 default = nil)
  if valid_593006 != nil:
    section.add "X-Amz-Signature", valid_593006
  var valid_593007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593007 = validateParameter(valid_593007, JString, required = false,
                                 default = nil)
  if valid_593007 != nil:
    section.add "X-Amz-Content-Sha256", valid_593007
  var valid_593008 = header.getOrDefault("X-Amz-Date")
  valid_593008 = validateParameter(valid_593008, JString, required = false,
                                 default = nil)
  if valid_593008 != nil:
    section.add "X-Amz-Date", valid_593008
  var valid_593009 = header.getOrDefault("X-Amz-Credential")
  valid_593009 = validateParameter(valid_593009, JString, required = false,
                                 default = nil)
  if valid_593009 != nil:
    section.add "X-Amz-Credential", valid_593009
  var valid_593010 = header.getOrDefault("X-Amz-Security-Token")
  valid_593010 = validateParameter(valid_593010, JString, required = false,
                                 default = nil)
  if valid_593010 != nil:
    section.add "X-Amz-Security-Token", valid_593010
  var valid_593011 = header.getOrDefault("X-Amz-Algorithm")
  valid_593011 = validateParameter(valid_593011, JString, required = false,
                                 default = nil)
  if valid_593011 != nil:
    section.add "X-Amz-Algorithm", valid_593011
  var valid_593012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593012 = validateParameter(valid_593012, JString, required = false,
                                 default = nil)
  if valid_593012 != nil:
    section.add "X-Amz-SignedHeaders", valid_593012
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593014: Call_CreateSystemTemplate_593002; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a system. The system is validated against the entities in the latest version of the user's namespace unless another namespace version is specified in the request.
  ## 
  let valid = call_593014.validator(path, query, header, formData, body)
  let scheme = call_593014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593014.url(scheme.get, call_593014.host, call_593014.base,
                         call_593014.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593014, url, valid)

proc call*(call_593015: Call_CreateSystemTemplate_593002; body: JsonNode): Recallable =
  ## createSystemTemplate
  ## Creates a system. The system is validated against the entities in the latest version of the user's namespace unless another namespace version is specified in the request.
  ##   body: JObject (required)
  var body_593016 = newJObject()
  if body != nil:
    body_593016 = body
  result = call_593015.call(nil, nil, nil, nil, body_593016)

var createSystemTemplate* = Call_CreateSystemTemplate_593002(
    name: "createSystemTemplate", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.CreateSystemTemplate",
    validator: validate_CreateSystemTemplate_593003, base: "/",
    url: url_CreateSystemTemplate_593004, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFlowTemplate_593017 = ref object of OpenApiRestCall_592364
proc url_DeleteFlowTemplate_593019(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteFlowTemplate_593018(path: JsonNode; query: JsonNode;
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
  var valid_593020 = header.getOrDefault("X-Amz-Target")
  valid_593020 = validateParameter(valid_593020, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.DeleteFlowTemplate"))
  if valid_593020 != nil:
    section.add "X-Amz-Target", valid_593020
  var valid_593021 = header.getOrDefault("X-Amz-Signature")
  valid_593021 = validateParameter(valid_593021, JString, required = false,
                                 default = nil)
  if valid_593021 != nil:
    section.add "X-Amz-Signature", valid_593021
  var valid_593022 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593022 = validateParameter(valid_593022, JString, required = false,
                                 default = nil)
  if valid_593022 != nil:
    section.add "X-Amz-Content-Sha256", valid_593022
  var valid_593023 = header.getOrDefault("X-Amz-Date")
  valid_593023 = validateParameter(valid_593023, JString, required = false,
                                 default = nil)
  if valid_593023 != nil:
    section.add "X-Amz-Date", valid_593023
  var valid_593024 = header.getOrDefault("X-Amz-Credential")
  valid_593024 = validateParameter(valid_593024, JString, required = false,
                                 default = nil)
  if valid_593024 != nil:
    section.add "X-Amz-Credential", valid_593024
  var valid_593025 = header.getOrDefault("X-Amz-Security-Token")
  valid_593025 = validateParameter(valid_593025, JString, required = false,
                                 default = nil)
  if valid_593025 != nil:
    section.add "X-Amz-Security-Token", valid_593025
  var valid_593026 = header.getOrDefault("X-Amz-Algorithm")
  valid_593026 = validateParameter(valid_593026, JString, required = false,
                                 default = nil)
  if valid_593026 != nil:
    section.add "X-Amz-Algorithm", valid_593026
  var valid_593027 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593027 = validateParameter(valid_593027, JString, required = false,
                                 default = nil)
  if valid_593027 != nil:
    section.add "X-Amz-SignedHeaders", valid_593027
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593029: Call_DeleteFlowTemplate_593017; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a workflow. Any new system or deployment that contains this workflow will fail to update or deploy. Existing deployments that contain the workflow will continue to run (since they use a snapshot of the workflow taken at the time of deployment).
  ## 
  let valid = call_593029.validator(path, query, header, formData, body)
  let scheme = call_593029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593029.url(scheme.get, call_593029.host, call_593029.base,
                         call_593029.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593029, url, valid)

proc call*(call_593030: Call_DeleteFlowTemplate_593017; body: JsonNode): Recallable =
  ## deleteFlowTemplate
  ## Deletes a workflow. Any new system or deployment that contains this workflow will fail to update or deploy. Existing deployments that contain the workflow will continue to run (since they use a snapshot of the workflow taken at the time of deployment).
  ##   body: JObject (required)
  var body_593031 = newJObject()
  if body != nil:
    body_593031 = body
  result = call_593030.call(nil, nil, nil, nil, body_593031)

var deleteFlowTemplate* = Call_DeleteFlowTemplate_593017(
    name: "deleteFlowTemplate", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.DeleteFlowTemplate",
    validator: validate_DeleteFlowTemplate_593018, base: "/",
    url: url_DeleteFlowTemplate_593019, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNamespace_593032 = ref object of OpenApiRestCall_592364
proc url_DeleteNamespace_593034(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteNamespace_593033(path: JsonNode; query: JsonNode;
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
  var valid_593035 = header.getOrDefault("X-Amz-Target")
  valid_593035 = validateParameter(valid_593035, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.DeleteNamespace"))
  if valid_593035 != nil:
    section.add "X-Amz-Target", valid_593035
  var valid_593036 = header.getOrDefault("X-Amz-Signature")
  valid_593036 = validateParameter(valid_593036, JString, required = false,
                                 default = nil)
  if valid_593036 != nil:
    section.add "X-Amz-Signature", valid_593036
  var valid_593037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593037 = validateParameter(valid_593037, JString, required = false,
                                 default = nil)
  if valid_593037 != nil:
    section.add "X-Amz-Content-Sha256", valid_593037
  var valid_593038 = header.getOrDefault("X-Amz-Date")
  valid_593038 = validateParameter(valid_593038, JString, required = false,
                                 default = nil)
  if valid_593038 != nil:
    section.add "X-Amz-Date", valid_593038
  var valid_593039 = header.getOrDefault("X-Amz-Credential")
  valid_593039 = validateParameter(valid_593039, JString, required = false,
                                 default = nil)
  if valid_593039 != nil:
    section.add "X-Amz-Credential", valid_593039
  var valid_593040 = header.getOrDefault("X-Amz-Security-Token")
  valid_593040 = validateParameter(valid_593040, JString, required = false,
                                 default = nil)
  if valid_593040 != nil:
    section.add "X-Amz-Security-Token", valid_593040
  var valid_593041 = header.getOrDefault("X-Amz-Algorithm")
  valid_593041 = validateParameter(valid_593041, JString, required = false,
                                 default = nil)
  if valid_593041 != nil:
    section.add "X-Amz-Algorithm", valid_593041
  var valid_593042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593042 = validateParameter(valid_593042, JString, required = false,
                                 default = nil)
  if valid_593042 != nil:
    section.add "X-Amz-SignedHeaders", valid_593042
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593044: Call_DeleteNamespace_593032; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified namespace. This action deletes all of the entities in the namespace. Delete the systems and flows that use entities in the namespace before performing this action.
  ## 
  let valid = call_593044.validator(path, query, header, formData, body)
  let scheme = call_593044.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593044.url(scheme.get, call_593044.host, call_593044.base,
                         call_593044.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593044, url, valid)

proc call*(call_593045: Call_DeleteNamespace_593032; body: JsonNode): Recallable =
  ## deleteNamespace
  ## Deletes the specified namespace. This action deletes all of the entities in the namespace. Delete the systems and flows that use entities in the namespace before performing this action.
  ##   body: JObject (required)
  var body_593046 = newJObject()
  if body != nil:
    body_593046 = body
  result = call_593045.call(nil, nil, nil, nil, body_593046)

var deleteNamespace* = Call_DeleteNamespace_593032(name: "deleteNamespace",
    meth: HttpMethod.HttpPost, host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.DeleteNamespace",
    validator: validate_DeleteNamespace_593033, base: "/", url: url_DeleteNamespace_593034,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSystemInstance_593047 = ref object of OpenApiRestCall_592364
proc url_DeleteSystemInstance_593049(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteSystemInstance_593048(path: JsonNode; query: JsonNode;
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
  var valid_593050 = header.getOrDefault("X-Amz-Target")
  valid_593050 = validateParameter(valid_593050, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.DeleteSystemInstance"))
  if valid_593050 != nil:
    section.add "X-Amz-Target", valid_593050
  var valid_593051 = header.getOrDefault("X-Amz-Signature")
  valid_593051 = validateParameter(valid_593051, JString, required = false,
                                 default = nil)
  if valid_593051 != nil:
    section.add "X-Amz-Signature", valid_593051
  var valid_593052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593052 = validateParameter(valid_593052, JString, required = false,
                                 default = nil)
  if valid_593052 != nil:
    section.add "X-Amz-Content-Sha256", valid_593052
  var valid_593053 = header.getOrDefault("X-Amz-Date")
  valid_593053 = validateParameter(valid_593053, JString, required = false,
                                 default = nil)
  if valid_593053 != nil:
    section.add "X-Amz-Date", valid_593053
  var valid_593054 = header.getOrDefault("X-Amz-Credential")
  valid_593054 = validateParameter(valid_593054, JString, required = false,
                                 default = nil)
  if valid_593054 != nil:
    section.add "X-Amz-Credential", valid_593054
  var valid_593055 = header.getOrDefault("X-Amz-Security-Token")
  valid_593055 = validateParameter(valid_593055, JString, required = false,
                                 default = nil)
  if valid_593055 != nil:
    section.add "X-Amz-Security-Token", valid_593055
  var valid_593056 = header.getOrDefault("X-Amz-Algorithm")
  valid_593056 = validateParameter(valid_593056, JString, required = false,
                                 default = nil)
  if valid_593056 != nil:
    section.add "X-Amz-Algorithm", valid_593056
  var valid_593057 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593057 = validateParameter(valid_593057, JString, required = false,
                                 default = nil)
  if valid_593057 != nil:
    section.add "X-Amz-SignedHeaders", valid_593057
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593059: Call_DeleteSystemInstance_593047; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a system instance. Only system instances that have never been deployed, or that have been undeployed can be deleted.</p> <p>Users can create a new system instance that has the same ID as a deleted system instance.</p>
  ## 
  let valid = call_593059.validator(path, query, header, formData, body)
  let scheme = call_593059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593059.url(scheme.get, call_593059.host, call_593059.base,
                         call_593059.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593059, url, valid)

proc call*(call_593060: Call_DeleteSystemInstance_593047; body: JsonNode): Recallable =
  ## deleteSystemInstance
  ## <p>Deletes a system instance. Only system instances that have never been deployed, or that have been undeployed can be deleted.</p> <p>Users can create a new system instance that has the same ID as a deleted system instance.</p>
  ##   body: JObject (required)
  var body_593061 = newJObject()
  if body != nil:
    body_593061 = body
  result = call_593060.call(nil, nil, nil, nil, body_593061)

var deleteSystemInstance* = Call_DeleteSystemInstance_593047(
    name: "deleteSystemInstance", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.DeleteSystemInstance",
    validator: validate_DeleteSystemInstance_593048, base: "/",
    url: url_DeleteSystemInstance_593049, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSystemTemplate_593062 = ref object of OpenApiRestCall_592364
proc url_DeleteSystemTemplate_593064(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteSystemTemplate_593063(path: JsonNode; query: JsonNode;
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
  var valid_593065 = header.getOrDefault("X-Amz-Target")
  valid_593065 = validateParameter(valid_593065, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.DeleteSystemTemplate"))
  if valid_593065 != nil:
    section.add "X-Amz-Target", valid_593065
  var valid_593066 = header.getOrDefault("X-Amz-Signature")
  valid_593066 = validateParameter(valid_593066, JString, required = false,
                                 default = nil)
  if valid_593066 != nil:
    section.add "X-Amz-Signature", valid_593066
  var valid_593067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593067 = validateParameter(valid_593067, JString, required = false,
                                 default = nil)
  if valid_593067 != nil:
    section.add "X-Amz-Content-Sha256", valid_593067
  var valid_593068 = header.getOrDefault("X-Amz-Date")
  valid_593068 = validateParameter(valid_593068, JString, required = false,
                                 default = nil)
  if valid_593068 != nil:
    section.add "X-Amz-Date", valid_593068
  var valid_593069 = header.getOrDefault("X-Amz-Credential")
  valid_593069 = validateParameter(valid_593069, JString, required = false,
                                 default = nil)
  if valid_593069 != nil:
    section.add "X-Amz-Credential", valid_593069
  var valid_593070 = header.getOrDefault("X-Amz-Security-Token")
  valid_593070 = validateParameter(valid_593070, JString, required = false,
                                 default = nil)
  if valid_593070 != nil:
    section.add "X-Amz-Security-Token", valid_593070
  var valid_593071 = header.getOrDefault("X-Amz-Algorithm")
  valid_593071 = validateParameter(valid_593071, JString, required = false,
                                 default = nil)
  if valid_593071 != nil:
    section.add "X-Amz-Algorithm", valid_593071
  var valid_593072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593072 = validateParameter(valid_593072, JString, required = false,
                                 default = nil)
  if valid_593072 != nil:
    section.add "X-Amz-SignedHeaders", valid_593072
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593074: Call_DeleteSystemTemplate_593062; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a system. New deployments can't contain the system after its deletion. Existing deployments that contain the system will continue to work because they use a snapshot of the system that is taken when it is deployed.
  ## 
  let valid = call_593074.validator(path, query, header, formData, body)
  let scheme = call_593074.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593074.url(scheme.get, call_593074.host, call_593074.base,
                         call_593074.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593074, url, valid)

proc call*(call_593075: Call_DeleteSystemTemplate_593062; body: JsonNode): Recallable =
  ## deleteSystemTemplate
  ## Deletes a system. New deployments can't contain the system after its deletion. Existing deployments that contain the system will continue to work because they use a snapshot of the system that is taken when it is deployed.
  ##   body: JObject (required)
  var body_593076 = newJObject()
  if body != nil:
    body_593076 = body
  result = call_593075.call(nil, nil, nil, nil, body_593076)

var deleteSystemTemplate* = Call_DeleteSystemTemplate_593062(
    name: "deleteSystemTemplate", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.DeleteSystemTemplate",
    validator: validate_DeleteSystemTemplate_593063, base: "/",
    url: url_DeleteSystemTemplate_593064, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeploySystemInstance_593077 = ref object of OpenApiRestCall_592364
proc url_DeploySystemInstance_593079(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeploySystemInstance_593078(path: JsonNode; query: JsonNode;
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
  var valid_593080 = header.getOrDefault("X-Amz-Target")
  valid_593080 = validateParameter(valid_593080, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.DeploySystemInstance"))
  if valid_593080 != nil:
    section.add "X-Amz-Target", valid_593080
  var valid_593081 = header.getOrDefault("X-Amz-Signature")
  valid_593081 = validateParameter(valid_593081, JString, required = false,
                                 default = nil)
  if valid_593081 != nil:
    section.add "X-Amz-Signature", valid_593081
  var valid_593082 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593082 = validateParameter(valid_593082, JString, required = false,
                                 default = nil)
  if valid_593082 != nil:
    section.add "X-Amz-Content-Sha256", valid_593082
  var valid_593083 = header.getOrDefault("X-Amz-Date")
  valid_593083 = validateParameter(valid_593083, JString, required = false,
                                 default = nil)
  if valid_593083 != nil:
    section.add "X-Amz-Date", valid_593083
  var valid_593084 = header.getOrDefault("X-Amz-Credential")
  valid_593084 = validateParameter(valid_593084, JString, required = false,
                                 default = nil)
  if valid_593084 != nil:
    section.add "X-Amz-Credential", valid_593084
  var valid_593085 = header.getOrDefault("X-Amz-Security-Token")
  valid_593085 = validateParameter(valid_593085, JString, required = false,
                                 default = nil)
  if valid_593085 != nil:
    section.add "X-Amz-Security-Token", valid_593085
  var valid_593086 = header.getOrDefault("X-Amz-Algorithm")
  valid_593086 = validateParameter(valid_593086, JString, required = false,
                                 default = nil)
  if valid_593086 != nil:
    section.add "X-Amz-Algorithm", valid_593086
  var valid_593087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593087 = validateParameter(valid_593087, JString, required = false,
                                 default = nil)
  if valid_593087 != nil:
    section.add "X-Amz-SignedHeaders", valid_593087
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593089: Call_DeploySystemInstance_593077; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> <b>Greengrass and Cloud Deployments</b> </p> <p>Deploys the system instance to the target specified in <code>CreateSystemInstance</code>. </p> <p> <b>Greengrass Deployments</b> </p> <p>If the system or any workflows and entities have been updated before this action is called, then the deployment will create a new Amazon Simple Storage Service resource file and then deploy it.</p> <p>Since this action creates a Greengrass deployment on the caller's behalf, the calling identity must have write permissions to the specified Greengrass group. Otherwise, the call will fail with an authorization error.</p> <p>For information about the artifacts that get added to your Greengrass core device when you use this API, see <a href="https://docs.aws.amazon.com/thingsgraph/latest/ug/iot-tg-greengrass.html">AWS IoT Things Graph and AWS IoT Greengrass</a>.</p>
  ## 
  let valid = call_593089.validator(path, query, header, formData, body)
  let scheme = call_593089.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593089.url(scheme.get, call_593089.host, call_593089.base,
                         call_593089.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593089, url, valid)

proc call*(call_593090: Call_DeploySystemInstance_593077; body: JsonNode): Recallable =
  ## deploySystemInstance
  ## <p> <b>Greengrass and Cloud Deployments</b> </p> <p>Deploys the system instance to the target specified in <code>CreateSystemInstance</code>. </p> <p> <b>Greengrass Deployments</b> </p> <p>If the system or any workflows and entities have been updated before this action is called, then the deployment will create a new Amazon Simple Storage Service resource file and then deploy it.</p> <p>Since this action creates a Greengrass deployment on the caller's behalf, the calling identity must have write permissions to the specified Greengrass group. Otherwise, the call will fail with an authorization error.</p> <p>For information about the artifacts that get added to your Greengrass core device when you use this API, see <a href="https://docs.aws.amazon.com/thingsgraph/latest/ug/iot-tg-greengrass.html">AWS IoT Things Graph and AWS IoT Greengrass</a>.</p>
  ##   body: JObject (required)
  var body_593091 = newJObject()
  if body != nil:
    body_593091 = body
  result = call_593090.call(nil, nil, nil, nil, body_593091)

var deploySystemInstance* = Call_DeploySystemInstance_593077(
    name: "deploySystemInstance", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.DeploySystemInstance",
    validator: validate_DeploySystemInstance_593078, base: "/",
    url: url_DeploySystemInstance_593079, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeprecateFlowTemplate_593092 = ref object of OpenApiRestCall_592364
proc url_DeprecateFlowTemplate_593094(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeprecateFlowTemplate_593093(path: JsonNode; query: JsonNode;
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
  var valid_593095 = header.getOrDefault("X-Amz-Target")
  valid_593095 = validateParameter(valid_593095, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.DeprecateFlowTemplate"))
  if valid_593095 != nil:
    section.add "X-Amz-Target", valid_593095
  var valid_593096 = header.getOrDefault("X-Amz-Signature")
  valid_593096 = validateParameter(valid_593096, JString, required = false,
                                 default = nil)
  if valid_593096 != nil:
    section.add "X-Amz-Signature", valid_593096
  var valid_593097 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593097 = validateParameter(valid_593097, JString, required = false,
                                 default = nil)
  if valid_593097 != nil:
    section.add "X-Amz-Content-Sha256", valid_593097
  var valid_593098 = header.getOrDefault("X-Amz-Date")
  valid_593098 = validateParameter(valid_593098, JString, required = false,
                                 default = nil)
  if valid_593098 != nil:
    section.add "X-Amz-Date", valid_593098
  var valid_593099 = header.getOrDefault("X-Amz-Credential")
  valid_593099 = validateParameter(valid_593099, JString, required = false,
                                 default = nil)
  if valid_593099 != nil:
    section.add "X-Amz-Credential", valid_593099
  var valid_593100 = header.getOrDefault("X-Amz-Security-Token")
  valid_593100 = validateParameter(valid_593100, JString, required = false,
                                 default = nil)
  if valid_593100 != nil:
    section.add "X-Amz-Security-Token", valid_593100
  var valid_593101 = header.getOrDefault("X-Amz-Algorithm")
  valid_593101 = validateParameter(valid_593101, JString, required = false,
                                 default = nil)
  if valid_593101 != nil:
    section.add "X-Amz-Algorithm", valid_593101
  var valid_593102 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593102 = validateParameter(valid_593102, JString, required = false,
                                 default = nil)
  if valid_593102 != nil:
    section.add "X-Amz-SignedHeaders", valid_593102
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593104: Call_DeprecateFlowTemplate_593092; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deprecates the specified workflow. This action marks the workflow for deletion. Deprecated flows can't be deployed, but existing deployments will continue to run.
  ## 
  let valid = call_593104.validator(path, query, header, formData, body)
  let scheme = call_593104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593104.url(scheme.get, call_593104.host, call_593104.base,
                         call_593104.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593104, url, valid)

proc call*(call_593105: Call_DeprecateFlowTemplate_593092; body: JsonNode): Recallable =
  ## deprecateFlowTemplate
  ## Deprecates the specified workflow. This action marks the workflow for deletion. Deprecated flows can't be deployed, but existing deployments will continue to run.
  ##   body: JObject (required)
  var body_593106 = newJObject()
  if body != nil:
    body_593106 = body
  result = call_593105.call(nil, nil, nil, nil, body_593106)

var deprecateFlowTemplate* = Call_DeprecateFlowTemplate_593092(
    name: "deprecateFlowTemplate", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com", route: "/#X-Amz-Target=IotThingsGraphFrontEndService.DeprecateFlowTemplate",
    validator: validate_DeprecateFlowTemplate_593093, base: "/",
    url: url_DeprecateFlowTemplate_593094, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeprecateSystemTemplate_593107 = ref object of OpenApiRestCall_592364
proc url_DeprecateSystemTemplate_593109(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeprecateSystemTemplate_593108(path: JsonNode; query: JsonNode;
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
  var valid_593110 = header.getOrDefault("X-Amz-Target")
  valid_593110 = validateParameter(valid_593110, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.DeprecateSystemTemplate"))
  if valid_593110 != nil:
    section.add "X-Amz-Target", valid_593110
  var valid_593111 = header.getOrDefault("X-Amz-Signature")
  valid_593111 = validateParameter(valid_593111, JString, required = false,
                                 default = nil)
  if valid_593111 != nil:
    section.add "X-Amz-Signature", valid_593111
  var valid_593112 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593112 = validateParameter(valid_593112, JString, required = false,
                                 default = nil)
  if valid_593112 != nil:
    section.add "X-Amz-Content-Sha256", valid_593112
  var valid_593113 = header.getOrDefault("X-Amz-Date")
  valid_593113 = validateParameter(valid_593113, JString, required = false,
                                 default = nil)
  if valid_593113 != nil:
    section.add "X-Amz-Date", valid_593113
  var valid_593114 = header.getOrDefault("X-Amz-Credential")
  valid_593114 = validateParameter(valid_593114, JString, required = false,
                                 default = nil)
  if valid_593114 != nil:
    section.add "X-Amz-Credential", valid_593114
  var valid_593115 = header.getOrDefault("X-Amz-Security-Token")
  valid_593115 = validateParameter(valid_593115, JString, required = false,
                                 default = nil)
  if valid_593115 != nil:
    section.add "X-Amz-Security-Token", valid_593115
  var valid_593116 = header.getOrDefault("X-Amz-Algorithm")
  valid_593116 = validateParameter(valid_593116, JString, required = false,
                                 default = nil)
  if valid_593116 != nil:
    section.add "X-Amz-Algorithm", valid_593116
  var valid_593117 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593117 = validateParameter(valid_593117, JString, required = false,
                                 default = nil)
  if valid_593117 != nil:
    section.add "X-Amz-SignedHeaders", valid_593117
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593119: Call_DeprecateSystemTemplate_593107; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deprecates the specified system.
  ## 
  let valid = call_593119.validator(path, query, header, formData, body)
  let scheme = call_593119.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593119.url(scheme.get, call_593119.host, call_593119.base,
                         call_593119.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593119, url, valid)

proc call*(call_593120: Call_DeprecateSystemTemplate_593107; body: JsonNode): Recallable =
  ## deprecateSystemTemplate
  ## Deprecates the specified system.
  ##   body: JObject (required)
  var body_593121 = newJObject()
  if body != nil:
    body_593121 = body
  result = call_593120.call(nil, nil, nil, nil, body_593121)

var deprecateSystemTemplate* = Call_DeprecateSystemTemplate_593107(
    name: "deprecateSystemTemplate", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com", route: "/#X-Amz-Target=IotThingsGraphFrontEndService.DeprecateSystemTemplate",
    validator: validate_DeprecateSystemTemplate_593108, base: "/",
    url: url_DeprecateSystemTemplate_593109, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeNamespace_593122 = ref object of OpenApiRestCall_592364
proc url_DescribeNamespace_593124(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeNamespace_593123(path: JsonNode; query: JsonNode;
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
  var valid_593125 = header.getOrDefault("X-Amz-Target")
  valid_593125 = validateParameter(valid_593125, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.DescribeNamespace"))
  if valid_593125 != nil:
    section.add "X-Amz-Target", valid_593125
  var valid_593126 = header.getOrDefault("X-Amz-Signature")
  valid_593126 = validateParameter(valid_593126, JString, required = false,
                                 default = nil)
  if valid_593126 != nil:
    section.add "X-Amz-Signature", valid_593126
  var valid_593127 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593127 = validateParameter(valid_593127, JString, required = false,
                                 default = nil)
  if valid_593127 != nil:
    section.add "X-Amz-Content-Sha256", valid_593127
  var valid_593128 = header.getOrDefault("X-Amz-Date")
  valid_593128 = validateParameter(valid_593128, JString, required = false,
                                 default = nil)
  if valid_593128 != nil:
    section.add "X-Amz-Date", valid_593128
  var valid_593129 = header.getOrDefault("X-Amz-Credential")
  valid_593129 = validateParameter(valid_593129, JString, required = false,
                                 default = nil)
  if valid_593129 != nil:
    section.add "X-Amz-Credential", valid_593129
  var valid_593130 = header.getOrDefault("X-Amz-Security-Token")
  valid_593130 = validateParameter(valid_593130, JString, required = false,
                                 default = nil)
  if valid_593130 != nil:
    section.add "X-Amz-Security-Token", valid_593130
  var valid_593131 = header.getOrDefault("X-Amz-Algorithm")
  valid_593131 = validateParameter(valid_593131, JString, required = false,
                                 default = nil)
  if valid_593131 != nil:
    section.add "X-Amz-Algorithm", valid_593131
  var valid_593132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593132 = validateParameter(valid_593132, JString, required = false,
                                 default = nil)
  if valid_593132 != nil:
    section.add "X-Amz-SignedHeaders", valid_593132
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593134: Call_DescribeNamespace_593122; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the latest version of the user's namespace and the public version that it is tracking.
  ## 
  let valid = call_593134.validator(path, query, header, formData, body)
  let scheme = call_593134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593134.url(scheme.get, call_593134.host, call_593134.base,
                         call_593134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593134, url, valid)

proc call*(call_593135: Call_DescribeNamespace_593122; body: JsonNode): Recallable =
  ## describeNamespace
  ## Gets the latest version of the user's namespace and the public version that it is tracking.
  ##   body: JObject (required)
  var body_593136 = newJObject()
  if body != nil:
    body_593136 = body
  result = call_593135.call(nil, nil, nil, nil, body_593136)

var describeNamespace* = Call_DescribeNamespace_593122(name: "describeNamespace",
    meth: HttpMethod.HttpPost, host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.DescribeNamespace",
    validator: validate_DescribeNamespace_593123, base: "/",
    url: url_DescribeNamespace_593124, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DissociateEntityFromThing_593137 = ref object of OpenApiRestCall_592364
proc url_DissociateEntityFromThing_593139(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DissociateEntityFromThing_593138(path: JsonNode; query: JsonNode;
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
  var valid_593140 = header.getOrDefault("X-Amz-Target")
  valid_593140 = validateParameter(valid_593140, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.DissociateEntityFromThing"))
  if valid_593140 != nil:
    section.add "X-Amz-Target", valid_593140
  var valid_593141 = header.getOrDefault("X-Amz-Signature")
  valid_593141 = validateParameter(valid_593141, JString, required = false,
                                 default = nil)
  if valid_593141 != nil:
    section.add "X-Amz-Signature", valid_593141
  var valid_593142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593142 = validateParameter(valid_593142, JString, required = false,
                                 default = nil)
  if valid_593142 != nil:
    section.add "X-Amz-Content-Sha256", valid_593142
  var valid_593143 = header.getOrDefault("X-Amz-Date")
  valid_593143 = validateParameter(valid_593143, JString, required = false,
                                 default = nil)
  if valid_593143 != nil:
    section.add "X-Amz-Date", valid_593143
  var valid_593144 = header.getOrDefault("X-Amz-Credential")
  valid_593144 = validateParameter(valid_593144, JString, required = false,
                                 default = nil)
  if valid_593144 != nil:
    section.add "X-Amz-Credential", valid_593144
  var valid_593145 = header.getOrDefault("X-Amz-Security-Token")
  valid_593145 = validateParameter(valid_593145, JString, required = false,
                                 default = nil)
  if valid_593145 != nil:
    section.add "X-Amz-Security-Token", valid_593145
  var valid_593146 = header.getOrDefault("X-Amz-Algorithm")
  valid_593146 = validateParameter(valid_593146, JString, required = false,
                                 default = nil)
  if valid_593146 != nil:
    section.add "X-Amz-Algorithm", valid_593146
  var valid_593147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593147 = validateParameter(valid_593147, JString, required = false,
                                 default = nil)
  if valid_593147 != nil:
    section.add "X-Amz-SignedHeaders", valid_593147
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593149: Call_DissociateEntityFromThing_593137; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Dissociates a device entity from a concrete thing. The action takes only the type of the entity that you need to dissociate because only one entity of a particular type can be associated with a thing.
  ## 
  let valid = call_593149.validator(path, query, header, formData, body)
  let scheme = call_593149.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593149.url(scheme.get, call_593149.host, call_593149.base,
                         call_593149.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593149, url, valid)

proc call*(call_593150: Call_DissociateEntityFromThing_593137; body: JsonNode): Recallable =
  ## dissociateEntityFromThing
  ## Dissociates a device entity from a concrete thing. The action takes only the type of the entity that you need to dissociate because only one entity of a particular type can be associated with a thing.
  ##   body: JObject (required)
  var body_593151 = newJObject()
  if body != nil:
    body_593151 = body
  result = call_593150.call(nil, nil, nil, nil, body_593151)

var dissociateEntityFromThing* = Call_DissociateEntityFromThing_593137(
    name: "dissociateEntityFromThing", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com", route: "/#X-Amz-Target=IotThingsGraphFrontEndService.DissociateEntityFromThing",
    validator: validate_DissociateEntityFromThing_593138, base: "/",
    url: url_DissociateEntityFromThing_593139,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEntities_593152 = ref object of OpenApiRestCall_592364
proc url_GetEntities_593154(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetEntities_593153(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593155 = header.getOrDefault("X-Amz-Target")
  valid_593155 = validateParameter(valid_593155, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.GetEntities"))
  if valid_593155 != nil:
    section.add "X-Amz-Target", valid_593155
  var valid_593156 = header.getOrDefault("X-Amz-Signature")
  valid_593156 = validateParameter(valid_593156, JString, required = false,
                                 default = nil)
  if valid_593156 != nil:
    section.add "X-Amz-Signature", valid_593156
  var valid_593157 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593157 = validateParameter(valid_593157, JString, required = false,
                                 default = nil)
  if valid_593157 != nil:
    section.add "X-Amz-Content-Sha256", valid_593157
  var valid_593158 = header.getOrDefault("X-Amz-Date")
  valid_593158 = validateParameter(valid_593158, JString, required = false,
                                 default = nil)
  if valid_593158 != nil:
    section.add "X-Amz-Date", valid_593158
  var valid_593159 = header.getOrDefault("X-Amz-Credential")
  valid_593159 = validateParameter(valid_593159, JString, required = false,
                                 default = nil)
  if valid_593159 != nil:
    section.add "X-Amz-Credential", valid_593159
  var valid_593160 = header.getOrDefault("X-Amz-Security-Token")
  valid_593160 = validateParameter(valid_593160, JString, required = false,
                                 default = nil)
  if valid_593160 != nil:
    section.add "X-Amz-Security-Token", valid_593160
  var valid_593161 = header.getOrDefault("X-Amz-Algorithm")
  valid_593161 = validateParameter(valid_593161, JString, required = false,
                                 default = nil)
  if valid_593161 != nil:
    section.add "X-Amz-Algorithm", valid_593161
  var valid_593162 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593162 = validateParameter(valid_593162, JString, required = false,
                                 default = nil)
  if valid_593162 != nil:
    section.add "X-Amz-SignedHeaders", valid_593162
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593164: Call_GetEntities_593152; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets definitions of the specified entities. Uses the latest version of the user's namespace by default. This API returns the following TDM entities.</p> <ul> <li> <p>Properties</p> </li> <li> <p>States</p> </li> <li> <p>Events</p> </li> <li> <p>Actions</p> </li> <li> <p>Capabilities</p> </li> <li> <p>Mappings</p> </li> <li> <p>Devices</p> </li> <li> <p>Device Models</p> </li> <li> <p>Services</p> </li> </ul> <p>This action doesn't return definitions for systems, flows, and deployments.</p>
  ## 
  let valid = call_593164.validator(path, query, header, formData, body)
  let scheme = call_593164.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593164.url(scheme.get, call_593164.host, call_593164.base,
                         call_593164.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593164, url, valid)

proc call*(call_593165: Call_GetEntities_593152; body: JsonNode): Recallable =
  ## getEntities
  ## <p>Gets definitions of the specified entities. Uses the latest version of the user's namespace by default. This API returns the following TDM entities.</p> <ul> <li> <p>Properties</p> </li> <li> <p>States</p> </li> <li> <p>Events</p> </li> <li> <p>Actions</p> </li> <li> <p>Capabilities</p> </li> <li> <p>Mappings</p> </li> <li> <p>Devices</p> </li> <li> <p>Device Models</p> </li> <li> <p>Services</p> </li> </ul> <p>This action doesn't return definitions for systems, flows, and deployments.</p>
  ##   body: JObject (required)
  var body_593166 = newJObject()
  if body != nil:
    body_593166 = body
  result = call_593165.call(nil, nil, nil, nil, body_593166)

var getEntities* = Call_GetEntities_593152(name: "getEntities",
                                        meth: HttpMethod.HttpPost,
                                        host: "iotthingsgraph.amazonaws.com", route: "/#X-Amz-Target=IotThingsGraphFrontEndService.GetEntities",
                                        validator: validate_GetEntities_593153,
                                        base: "/", url: url_GetEntities_593154,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFlowTemplate_593167 = ref object of OpenApiRestCall_592364
proc url_GetFlowTemplate_593169(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetFlowTemplate_593168(path: JsonNode; query: JsonNode;
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
  var valid_593170 = header.getOrDefault("X-Amz-Target")
  valid_593170 = validateParameter(valid_593170, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.GetFlowTemplate"))
  if valid_593170 != nil:
    section.add "X-Amz-Target", valid_593170
  var valid_593171 = header.getOrDefault("X-Amz-Signature")
  valid_593171 = validateParameter(valid_593171, JString, required = false,
                                 default = nil)
  if valid_593171 != nil:
    section.add "X-Amz-Signature", valid_593171
  var valid_593172 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593172 = validateParameter(valid_593172, JString, required = false,
                                 default = nil)
  if valid_593172 != nil:
    section.add "X-Amz-Content-Sha256", valid_593172
  var valid_593173 = header.getOrDefault("X-Amz-Date")
  valid_593173 = validateParameter(valid_593173, JString, required = false,
                                 default = nil)
  if valid_593173 != nil:
    section.add "X-Amz-Date", valid_593173
  var valid_593174 = header.getOrDefault("X-Amz-Credential")
  valid_593174 = validateParameter(valid_593174, JString, required = false,
                                 default = nil)
  if valid_593174 != nil:
    section.add "X-Amz-Credential", valid_593174
  var valid_593175 = header.getOrDefault("X-Amz-Security-Token")
  valid_593175 = validateParameter(valid_593175, JString, required = false,
                                 default = nil)
  if valid_593175 != nil:
    section.add "X-Amz-Security-Token", valid_593175
  var valid_593176 = header.getOrDefault("X-Amz-Algorithm")
  valid_593176 = validateParameter(valid_593176, JString, required = false,
                                 default = nil)
  if valid_593176 != nil:
    section.add "X-Amz-Algorithm", valid_593176
  var valid_593177 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593177 = validateParameter(valid_593177, JString, required = false,
                                 default = nil)
  if valid_593177 != nil:
    section.add "X-Amz-SignedHeaders", valid_593177
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593179: Call_GetFlowTemplate_593167; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the latest version of the <code>DefinitionDocument</code> and <code>FlowTemplateSummary</code> for the specified workflow.
  ## 
  let valid = call_593179.validator(path, query, header, formData, body)
  let scheme = call_593179.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593179.url(scheme.get, call_593179.host, call_593179.base,
                         call_593179.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593179, url, valid)

proc call*(call_593180: Call_GetFlowTemplate_593167; body: JsonNode): Recallable =
  ## getFlowTemplate
  ## Gets the latest version of the <code>DefinitionDocument</code> and <code>FlowTemplateSummary</code> for the specified workflow.
  ##   body: JObject (required)
  var body_593181 = newJObject()
  if body != nil:
    body_593181 = body
  result = call_593180.call(nil, nil, nil, nil, body_593181)

var getFlowTemplate* = Call_GetFlowTemplate_593167(name: "getFlowTemplate",
    meth: HttpMethod.HttpPost, host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.GetFlowTemplate",
    validator: validate_GetFlowTemplate_593168, base: "/", url: url_GetFlowTemplate_593169,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFlowTemplateRevisions_593182 = ref object of OpenApiRestCall_592364
proc url_GetFlowTemplateRevisions_593184(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetFlowTemplateRevisions_593183(path: JsonNode; query: JsonNode;
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
  var valid_593185 = query.getOrDefault("nextToken")
  valid_593185 = validateParameter(valid_593185, JString, required = false,
                                 default = nil)
  if valid_593185 != nil:
    section.add "nextToken", valid_593185
  var valid_593186 = query.getOrDefault("maxResults")
  valid_593186 = validateParameter(valid_593186, JString, required = false,
                                 default = nil)
  if valid_593186 != nil:
    section.add "maxResults", valid_593186
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593187 = header.getOrDefault("X-Amz-Target")
  valid_593187 = validateParameter(valid_593187, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.GetFlowTemplateRevisions"))
  if valid_593187 != nil:
    section.add "X-Amz-Target", valid_593187
  var valid_593188 = header.getOrDefault("X-Amz-Signature")
  valid_593188 = validateParameter(valid_593188, JString, required = false,
                                 default = nil)
  if valid_593188 != nil:
    section.add "X-Amz-Signature", valid_593188
  var valid_593189 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593189 = validateParameter(valid_593189, JString, required = false,
                                 default = nil)
  if valid_593189 != nil:
    section.add "X-Amz-Content-Sha256", valid_593189
  var valid_593190 = header.getOrDefault("X-Amz-Date")
  valid_593190 = validateParameter(valid_593190, JString, required = false,
                                 default = nil)
  if valid_593190 != nil:
    section.add "X-Amz-Date", valid_593190
  var valid_593191 = header.getOrDefault("X-Amz-Credential")
  valid_593191 = validateParameter(valid_593191, JString, required = false,
                                 default = nil)
  if valid_593191 != nil:
    section.add "X-Amz-Credential", valid_593191
  var valid_593192 = header.getOrDefault("X-Amz-Security-Token")
  valid_593192 = validateParameter(valid_593192, JString, required = false,
                                 default = nil)
  if valid_593192 != nil:
    section.add "X-Amz-Security-Token", valid_593192
  var valid_593193 = header.getOrDefault("X-Amz-Algorithm")
  valid_593193 = validateParameter(valid_593193, JString, required = false,
                                 default = nil)
  if valid_593193 != nil:
    section.add "X-Amz-Algorithm", valid_593193
  var valid_593194 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593194 = validateParameter(valid_593194, JString, required = false,
                                 default = nil)
  if valid_593194 != nil:
    section.add "X-Amz-SignedHeaders", valid_593194
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593196: Call_GetFlowTemplateRevisions_593182; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets revisions of the specified workflow. Only the last 100 revisions are stored. If the workflow has been deprecated, this action will return revisions that occurred before the deprecation. This action won't work for workflows that have been deleted.
  ## 
  let valid = call_593196.validator(path, query, header, formData, body)
  let scheme = call_593196.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593196.url(scheme.get, call_593196.host, call_593196.base,
                         call_593196.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593196, url, valid)

proc call*(call_593197: Call_GetFlowTemplateRevisions_593182; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getFlowTemplateRevisions
  ## Gets revisions of the specified workflow. Only the last 100 revisions are stored. If the workflow has been deprecated, this action will return revisions that occurred before the deprecation. This action won't work for workflows that have been deleted.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_593198 = newJObject()
  var body_593199 = newJObject()
  add(query_593198, "nextToken", newJString(nextToken))
  if body != nil:
    body_593199 = body
  add(query_593198, "maxResults", newJString(maxResults))
  result = call_593197.call(nil, query_593198, nil, nil, body_593199)

var getFlowTemplateRevisions* = Call_GetFlowTemplateRevisions_593182(
    name: "getFlowTemplateRevisions", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com", route: "/#X-Amz-Target=IotThingsGraphFrontEndService.GetFlowTemplateRevisions",
    validator: validate_GetFlowTemplateRevisions_593183, base: "/",
    url: url_GetFlowTemplateRevisions_593184, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetNamespaceDeletionStatus_593201 = ref object of OpenApiRestCall_592364
proc url_GetNamespaceDeletionStatus_593203(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetNamespaceDeletionStatus_593202(path: JsonNode; query: JsonNode;
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
  var valid_593204 = header.getOrDefault("X-Amz-Target")
  valid_593204 = validateParameter(valid_593204, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.GetNamespaceDeletionStatus"))
  if valid_593204 != nil:
    section.add "X-Amz-Target", valid_593204
  var valid_593205 = header.getOrDefault("X-Amz-Signature")
  valid_593205 = validateParameter(valid_593205, JString, required = false,
                                 default = nil)
  if valid_593205 != nil:
    section.add "X-Amz-Signature", valid_593205
  var valid_593206 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593206 = validateParameter(valid_593206, JString, required = false,
                                 default = nil)
  if valid_593206 != nil:
    section.add "X-Amz-Content-Sha256", valid_593206
  var valid_593207 = header.getOrDefault("X-Amz-Date")
  valid_593207 = validateParameter(valid_593207, JString, required = false,
                                 default = nil)
  if valid_593207 != nil:
    section.add "X-Amz-Date", valid_593207
  var valid_593208 = header.getOrDefault("X-Amz-Credential")
  valid_593208 = validateParameter(valid_593208, JString, required = false,
                                 default = nil)
  if valid_593208 != nil:
    section.add "X-Amz-Credential", valid_593208
  var valid_593209 = header.getOrDefault("X-Amz-Security-Token")
  valid_593209 = validateParameter(valid_593209, JString, required = false,
                                 default = nil)
  if valid_593209 != nil:
    section.add "X-Amz-Security-Token", valid_593209
  var valid_593210 = header.getOrDefault("X-Amz-Algorithm")
  valid_593210 = validateParameter(valid_593210, JString, required = false,
                                 default = nil)
  if valid_593210 != nil:
    section.add "X-Amz-Algorithm", valid_593210
  var valid_593211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593211 = validateParameter(valid_593211, JString, required = false,
                                 default = nil)
  if valid_593211 != nil:
    section.add "X-Amz-SignedHeaders", valid_593211
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593213: Call_GetNamespaceDeletionStatus_593201; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the status of a namespace deletion task.
  ## 
  let valid = call_593213.validator(path, query, header, formData, body)
  let scheme = call_593213.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593213.url(scheme.get, call_593213.host, call_593213.base,
                         call_593213.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593213, url, valid)

proc call*(call_593214: Call_GetNamespaceDeletionStatus_593201; body: JsonNode): Recallable =
  ## getNamespaceDeletionStatus
  ## Gets the status of a namespace deletion task.
  ##   body: JObject (required)
  var body_593215 = newJObject()
  if body != nil:
    body_593215 = body
  result = call_593214.call(nil, nil, nil, nil, body_593215)

var getNamespaceDeletionStatus* = Call_GetNamespaceDeletionStatus_593201(
    name: "getNamespaceDeletionStatus", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com", route: "/#X-Amz-Target=IotThingsGraphFrontEndService.GetNamespaceDeletionStatus",
    validator: validate_GetNamespaceDeletionStatus_593202, base: "/",
    url: url_GetNamespaceDeletionStatus_593203,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSystemInstance_593216 = ref object of OpenApiRestCall_592364
proc url_GetSystemInstance_593218(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSystemInstance_593217(path: JsonNode; query: JsonNode;
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
  var valid_593219 = header.getOrDefault("X-Amz-Target")
  valid_593219 = validateParameter(valid_593219, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.GetSystemInstance"))
  if valid_593219 != nil:
    section.add "X-Amz-Target", valid_593219
  var valid_593220 = header.getOrDefault("X-Amz-Signature")
  valid_593220 = validateParameter(valid_593220, JString, required = false,
                                 default = nil)
  if valid_593220 != nil:
    section.add "X-Amz-Signature", valid_593220
  var valid_593221 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593221 = validateParameter(valid_593221, JString, required = false,
                                 default = nil)
  if valid_593221 != nil:
    section.add "X-Amz-Content-Sha256", valid_593221
  var valid_593222 = header.getOrDefault("X-Amz-Date")
  valid_593222 = validateParameter(valid_593222, JString, required = false,
                                 default = nil)
  if valid_593222 != nil:
    section.add "X-Amz-Date", valid_593222
  var valid_593223 = header.getOrDefault("X-Amz-Credential")
  valid_593223 = validateParameter(valid_593223, JString, required = false,
                                 default = nil)
  if valid_593223 != nil:
    section.add "X-Amz-Credential", valid_593223
  var valid_593224 = header.getOrDefault("X-Amz-Security-Token")
  valid_593224 = validateParameter(valid_593224, JString, required = false,
                                 default = nil)
  if valid_593224 != nil:
    section.add "X-Amz-Security-Token", valid_593224
  var valid_593225 = header.getOrDefault("X-Amz-Algorithm")
  valid_593225 = validateParameter(valid_593225, JString, required = false,
                                 default = nil)
  if valid_593225 != nil:
    section.add "X-Amz-Algorithm", valid_593225
  var valid_593226 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593226 = validateParameter(valid_593226, JString, required = false,
                                 default = nil)
  if valid_593226 != nil:
    section.add "X-Amz-SignedHeaders", valid_593226
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593228: Call_GetSystemInstance_593216; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a system instance.
  ## 
  let valid = call_593228.validator(path, query, header, formData, body)
  let scheme = call_593228.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593228.url(scheme.get, call_593228.host, call_593228.base,
                         call_593228.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593228, url, valid)

proc call*(call_593229: Call_GetSystemInstance_593216; body: JsonNode): Recallable =
  ## getSystemInstance
  ## Gets a system instance.
  ##   body: JObject (required)
  var body_593230 = newJObject()
  if body != nil:
    body_593230 = body
  result = call_593229.call(nil, nil, nil, nil, body_593230)

var getSystemInstance* = Call_GetSystemInstance_593216(name: "getSystemInstance",
    meth: HttpMethod.HttpPost, host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.GetSystemInstance",
    validator: validate_GetSystemInstance_593217, base: "/",
    url: url_GetSystemInstance_593218, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSystemTemplate_593231 = ref object of OpenApiRestCall_592364
proc url_GetSystemTemplate_593233(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSystemTemplate_593232(path: JsonNode; query: JsonNode;
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
  var valid_593234 = header.getOrDefault("X-Amz-Target")
  valid_593234 = validateParameter(valid_593234, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.GetSystemTemplate"))
  if valid_593234 != nil:
    section.add "X-Amz-Target", valid_593234
  var valid_593235 = header.getOrDefault("X-Amz-Signature")
  valid_593235 = validateParameter(valid_593235, JString, required = false,
                                 default = nil)
  if valid_593235 != nil:
    section.add "X-Amz-Signature", valid_593235
  var valid_593236 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593236 = validateParameter(valid_593236, JString, required = false,
                                 default = nil)
  if valid_593236 != nil:
    section.add "X-Amz-Content-Sha256", valid_593236
  var valid_593237 = header.getOrDefault("X-Amz-Date")
  valid_593237 = validateParameter(valid_593237, JString, required = false,
                                 default = nil)
  if valid_593237 != nil:
    section.add "X-Amz-Date", valid_593237
  var valid_593238 = header.getOrDefault("X-Amz-Credential")
  valid_593238 = validateParameter(valid_593238, JString, required = false,
                                 default = nil)
  if valid_593238 != nil:
    section.add "X-Amz-Credential", valid_593238
  var valid_593239 = header.getOrDefault("X-Amz-Security-Token")
  valid_593239 = validateParameter(valid_593239, JString, required = false,
                                 default = nil)
  if valid_593239 != nil:
    section.add "X-Amz-Security-Token", valid_593239
  var valid_593240 = header.getOrDefault("X-Amz-Algorithm")
  valid_593240 = validateParameter(valid_593240, JString, required = false,
                                 default = nil)
  if valid_593240 != nil:
    section.add "X-Amz-Algorithm", valid_593240
  var valid_593241 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593241 = validateParameter(valid_593241, JString, required = false,
                                 default = nil)
  if valid_593241 != nil:
    section.add "X-Amz-SignedHeaders", valid_593241
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593243: Call_GetSystemTemplate_593231; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a system.
  ## 
  let valid = call_593243.validator(path, query, header, formData, body)
  let scheme = call_593243.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593243.url(scheme.get, call_593243.host, call_593243.base,
                         call_593243.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593243, url, valid)

proc call*(call_593244: Call_GetSystemTemplate_593231; body: JsonNode): Recallable =
  ## getSystemTemplate
  ## Gets a system.
  ##   body: JObject (required)
  var body_593245 = newJObject()
  if body != nil:
    body_593245 = body
  result = call_593244.call(nil, nil, nil, nil, body_593245)

var getSystemTemplate* = Call_GetSystemTemplate_593231(name: "getSystemTemplate",
    meth: HttpMethod.HttpPost, host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.GetSystemTemplate",
    validator: validate_GetSystemTemplate_593232, base: "/",
    url: url_GetSystemTemplate_593233, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSystemTemplateRevisions_593246 = ref object of OpenApiRestCall_592364
proc url_GetSystemTemplateRevisions_593248(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSystemTemplateRevisions_593247(path: JsonNode; query: JsonNode;
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
  var valid_593249 = query.getOrDefault("nextToken")
  valid_593249 = validateParameter(valid_593249, JString, required = false,
                                 default = nil)
  if valid_593249 != nil:
    section.add "nextToken", valid_593249
  var valid_593250 = query.getOrDefault("maxResults")
  valid_593250 = validateParameter(valid_593250, JString, required = false,
                                 default = nil)
  if valid_593250 != nil:
    section.add "maxResults", valid_593250
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593251 = header.getOrDefault("X-Amz-Target")
  valid_593251 = validateParameter(valid_593251, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.GetSystemTemplateRevisions"))
  if valid_593251 != nil:
    section.add "X-Amz-Target", valid_593251
  var valid_593252 = header.getOrDefault("X-Amz-Signature")
  valid_593252 = validateParameter(valid_593252, JString, required = false,
                                 default = nil)
  if valid_593252 != nil:
    section.add "X-Amz-Signature", valid_593252
  var valid_593253 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593253 = validateParameter(valid_593253, JString, required = false,
                                 default = nil)
  if valid_593253 != nil:
    section.add "X-Amz-Content-Sha256", valid_593253
  var valid_593254 = header.getOrDefault("X-Amz-Date")
  valid_593254 = validateParameter(valid_593254, JString, required = false,
                                 default = nil)
  if valid_593254 != nil:
    section.add "X-Amz-Date", valid_593254
  var valid_593255 = header.getOrDefault("X-Amz-Credential")
  valid_593255 = validateParameter(valid_593255, JString, required = false,
                                 default = nil)
  if valid_593255 != nil:
    section.add "X-Amz-Credential", valid_593255
  var valid_593256 = header.getOrDefault("X-Amz-Security-Token")
  valid_593256 = validateParameter(valid_593256, JString, required = false,
                                 default = nil)
  if valid_593256 != nil:
    section.add "X-Amz-Security-Token", valid_593256
  var valid_593257 = header.getOrDefault("X-Amz-Algorithm")
  valid_593257 = validateParameter(valid_593257, JString, required = false,
                                 default = nil)
  if valid_593257 != nil:
    section.add "X-Amz-Algorithm", valid_593257
  var valid_593258 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593258 = validateParameter(valid_593258, JString, required = false,
                                 default = nil)
  if valid_593258 != nil:
    section.add "X-Amz-SignedHeaders", valid_593258
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593260: Call_GetSystemTemplateRevisions_593246; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets revisions made to the specified system template. Only the previous 100 revisions are stored. If the system has been deprecated, this action will return the revisions that occurred before its deprecation. This action won't work with systems that have been deleted.
  ## 
  let valid = call_593260.validator(path, query, header, formData, body)
  let scheme = call_593260.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593260.url(scheme.get, call_593260.host, call_593260.base,
                         call_593260.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593260, url, valid)

proc call*(call_593261: Call_GetSystemTemplateRevisions_593246; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getSystemTemplateRevisions
  ## Gets revisions made to the specified system template. Only the previous 100 revisions are stored. If the system has been deprecated, this action will return the revisions that occurred before its deprecation. This action won't work with systems that have been deleted.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_593262 = newJObject()
  var body_593263 = newJObject()
  add(query_593262, "nextToken", newJString(nextToken))
  if body != nil:
    body_593263 = body
  add(query_593262, "maxResults", newJString(maxResults))
  result = call_593261.call(nil, query_593262, nil, nil, body_593263)

var getSystemTemplateRevisions* = Call_GetSystemTemplateRevisions_593246(
    name: "getSystemTemplateRevisions", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com", route: "/#X-Amz-Target=IotThingsGraphFrontEndService.GetSystemTemplateRevisions",
    validator: validate_GetSystemTemplateRevisions_593247, base: "/",
    url: url_GetSystemTemplateRevisions_593248,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUploadStatus_593264 = ref object of OpenApiRestCall_592364
proc url_GetUploadStatus_593266(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUploadStatus_593265(path: JsonNode; query: JsonNode;
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
  var valid_593267 = header.getOrDefault("X-Amz-Target")
  valid_593267 = validateParameter(valid_593267, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.GetUploadStatus"))
  if valid_593267 != nil:
    section.add "X-Amz-Target", valid_593267
  var valid_593268 = header.getOrDefault("X-Amz-Signature")
  valid_593268 = validateParameter(valid_593268, JString, required = false,
                                 default = nil)
  if valid_593268 != nil:
    section.add "X-Amz-Signature", valid_593268
  var valid_593269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593269 = validateParameter(valid_593269, JString, required = false,
                                 default = nil)
  if valid_593269 != nil:
    section.add "X-Amz-Content-Sha256", valid_593269
  var valid_593270 = header.getOrDefault("X-Amz-Date")
  valid_593270 = validateParameter(valid_593270, JString, required = false,
                                 default = nil)
  if valid_593270 != nil:
    section.add "X-Amz-Date", valid_593270
  var valid_593271 = header.getOrDefault("X-Amz-Credential")
  valid_593271 = validateParameter(valid_593271, JString, required = false,
                                 default = nil)
  if valid_593271 != nil:
    section.add "X-Amz-Credential", valid_593271
  var valid_593272 = header.getOrDefault("X-Amz-Security-Token")
  valid_593272 = validateParameter(valid_593272, JString, required = false,
                                 default = nil)
  if valid_593272 != nil:
    section.add "X-Amz-Security-Token", valid_593272
  var valid_593273 = header.getOrDefault("X-Amz-Algorithm")
  valid_593273 = validateParameter(valid_593273, JString, required = false,
                                 default = nil)
  if valid_593273 != nil:
    section.add "X-Amz-Algorithm", valid_593273
  var valid_593274 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593274 = validateParameter(valid_593274, JString, required = false,
                                 default = nil)
  if valid_593274 != nil:
    section.add "X-Amz-SignedHeaders", valid_593274
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593276: Call_GetUploadStatus_593264; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the status of the specified upload.
  ## 
  let valid = call_593276.validator(path, query, header, formData, body)
  let scheme = call_593276.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593276.url(scheme.get, call_593276.host, call_593276.base,
                         call_593276.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593276, url, valid)

proc call*(call_593277: Call_GetUploadStatus_593264; body: JsonNode): Recallable =
  ## getUploadStatus
  ## Gets the status of the specified upload.
  ##   body: JObject (required)
  var body_593278 = newJObject()
  if body != nil:
    body_593278 = body
  result = call_593277.call(nil, nil, nil, nil, body_593278)

var getUploadStatus* = Call_GetUploadStatus_593264(name: "getUploadStatus",
    meth: HttpMethod.HttpPost, host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.GetUploadStatus",
    validator: validate_GetUploadStatus_593265, base: "/", url: url_GetUploadStatus_593266,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFlowExecutionMessages_593279 = ref object of OpenApiRestCall_592364
proc url_ListFlowExecutionMessages_593281(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListFlowExecutionMessages_593280(path: JsonNode; query: JsonNode;
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
  var valid_593282 = query.getOrDefault("nextToken")
  valid_593282 = validateParameter(valid_593282, JString, required = false,
                                 default = nil)
  if valid_593282 != nil:
    section.add "nextToken", valid_593282
  var valid_593283 = query.getOrDefault("maxResults")
  valid_593283 = validateParameter(valid_593283, JString, required = false,
                                 default = nil)
  if valid_593283 != nil:
    section.add "maxResults", valid_593283
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593284 = header.getOrDefault("X-Amz-Target")
  valid_593284 = validateParameter(valid_593284, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.ListFlowExecutionMessages"))
  if valid_593284 != nil:
    section.add "X-Amz-Target", valid_593284
  var valid_593285 = header.getOrDefault("X-Amz-Signature")
  valid_593285 = validateParameter(valid_593285, JString, required = false,
                                 default = nil)
  if valid_593285 != nil:
    section.add "X-Amz-Signature", valid_593285
  var valid_593286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593286 = validateParameter(valid_593286, JString, required = false,
                                 default = nil)
  if valid_593286 != nil:
    section.add "X-Amz-Content-Sha256", valid_593286
  var valid_593287 = header.getOrDefault("X-Amz-Date")
  valid_593287 = validateParameter(valid_593287, JString, required = false,
                                 default = nil)
  if valid_593287 != nil:
    section.add "X-Amz-Date", valid_593287
  var valid_593288 = header.getOrDefault("X-Amz-Credential")
  valid_593288 = validateParameter(valid_593288, JString, required = false,
                                 default = nil)
  if valid_593288 != nil:
    section.add "X-Amz-Credential", valid_593288
  var valid_593289 = header.getOrDefault("X-Amz-Security-Token")
  valid_593289 = validateParameter(valid_593289, JString, required = false,
                                 default = nil)
  if valid_593289 != nil:
    section.add "X-Amz-Security-Token", valid_593289
  var valid_593290 = header.getOrDefault("X-Amz-Algorithm")
  valid_593290 = validateParameter(valid_593290, JString, required = false,
                                 default = nil)
  if valid_593290 != nil:
    section.add "X-Amz-Algorithm", valid_593290
  var valid_593291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593291 = validateParameter(valid_593291, JString, required = false,
                                 default = nil)
  if valid_593291 != nil:
    section.add "X-Amz-SignedHeaders", valid_593291
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593293: Call_ListFlowExecutionMessages_593279; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of objects that contain information about events in a flow execution.
  ## 
  let valid = call_593293.validator(path, query, header, formData, body)
  let scheme = call_593293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593293.url(scheme.get, call_593293.host, call_593293.base,
                         call_593293.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593293, url, valid)

proc call*(call_593294: Call_ListFlowExecutionMessages_593279; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listFlowExecutionMessages
  ## Returns a list of objects that contain information about events in a flow execution.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_593295 = newJObject()
  var body_593296 = newJObject()
  add(query_593295, "nextToken", newJString(nextToken))
  if body != nil:
    body_593296 = body
  add(query_593295, "maxResults", newJString(maxResults))
  result = call_593294.call(nil, query_593295, nil, nil, body_593296)

var listFlowExecutionMessages* = Call_ListFlowExecutionMessages_593279(
    name: "listFlowExecutionMessages", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com", route: "/#X-Amz-Target=IotThingsGraphFrontEndService.ListFlowExecutionMessages",
    validator: validate_ListFlowExecutionMessages_593280, base: "/",
    url: url_ListFlowExecutionMessages_593281,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_593297 = ref object of OpenApiRestCall_592364
proc url_ListTagsForResource_593299(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTagsForResource_593298(path: JsonNode; query: JsonNode;
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
  var valid_593300 = query.getOrDefault("nextToken")
  valid_593300 = validateParameter(valid_593300, JString, required = false,
                                 default = nil)
  if valid_593300 != nil:
    section.add "nextToken", valid_593300
  var valid_593301 = query.getOrDefault("maxResults")
  valid_593301 = validateParameter(valid_593301, JString, required = false,
                                 default = nil)
  if valid_593301 != nil:
    section.add "maxResults", valid_593301
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593302 = header.getOrDefault("X-Amz-Target")
  valid_593302 = validateParameter(valid_593302, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.ListTagsForResource"))
  if valid_593302 != nil:
    section.add "X-Amz-Target", valid_593302
  var valid_593303 = header.getOrDefault("X-Amz-Signature")
  valid_593303 = validateParameter(valid_593303, JString, required = false,
                                 default = nil)
  if valid_593303 != nil:
    section.add "X-Amz-Signature", valid_593303
  var valid_593304 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593304 = validateParameter(valid_593304, JString, required = false,
                                 default = nil)
  if valid_593304 != nil:
    section.add "X-Amz-Content-Sha256", valid_593304
  var valid_593305 = header.getOrDefault("X-Amz-Date")
  valid_593305 = validateParameter(valid_593305, JString, required = false,
                                 default = nil)
  if valid_593305 != nil:
    section.add "X-Amz-Date", valid_593305
  var valid_593306 = header.getOrDefault("X-Amz-Credential")
  valid_593306 = validateParameter(valid_593306, JString, required = false,
                                 default = nil)
  if valid_593306 != nil:
    section.add "X-Amz-Credential", valid_593306
  var valid_593307 = header.getOrDefault("X-Amz-Security-Token")
  valid_593307 = validateParameter(valid_593307, JString, required = false,
                                 default = nil)
  if valid_593307 != nil:
    section.add "X-Amz-Security-Token", valid_593307
  var valid_593308 = header.getOrDefault("X-Amz-Algorithm")
  valid_593308 = validateParameter(valid_593308, JString, required = false,
                                 default = nil)
  if valid_593308 != nil:
    section.add "X-Amz-Algorithm", valid_593308
  var valid_593309 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593309 = validateParameter(valid_593309, JString, required = false,
                                 default = nil)
  if valid_593309 != nil:
    section.add "X-Amz-SignedHeaders", valid_593309
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593311: Call_ListTagsForResource_593297; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all tags on an AWS IoT Things Graph resource.
  ## 
  let valid = call_593311.validator(path, query, header, formData, body)
  let scheme = call_593311.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593311.url(scheme.get, call_593311.host, call_593311.base,
                         call_593311.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593311, url, valid)

proc call*(call_593312: Call_ListTagsForResource_593297; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listTagsForResource
  ## Lists all tags on an AWS IoT Things Graph resource.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_593313 = newJObject()
  var body_593314 = newJObject()
  add(query_593313, "nextToken", newJString(nextToken))
  if body != nil:
    body_593314 = body
  add(query_593313, "maxResults", newJString(maxResults))
  result = call_593312.call(nil, query_593313, nil, nil, body_593314)

var listTagsForResource* = Call_ListTagsForResource_593297(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.ListTagsForResource",
    validator: validate_ListTagsForResource_593298, base: "/",
    url: url_ListTagsForResource_593299, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchEntities_593315 = ref object of OpenApiRestCall_592364
proc url_SearchEntities_593317(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SearchEntities_593316(path: JsonNode; query: JsonNode;
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
  var valid_593318 = query.getOrDefault("nextToken")
  valid_593318 = validateParameter(valid_593318, JString, required = false,
                                 default = nil)
  if valid_593318 != nil:
    section.add "nextToken", valid_593318
  var valid_593319 = query.getOrDefault("maxResults")
  valid_593319 = validateParameter(valid_593319, JString, required = false,
                                 default = nil)
  if valid_593319 != nil:
    section.add "maxResults", valid_593319
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593320 = header.getOrDefault("X-Amz-Target")
  valid_593320 = validateParameter(valid_593320, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.SearchEntities"))
  if valid_593320 != nil:
    section.add "X-Amz-Target", valid_593320
  var valid_593321 = header.getOrDefault("X-Amz-Signature")
  valid_593321 = validateParameter(valid_593321, JString, required = false,
                                 default = nil)
  if valid_593321 != nil:
    section.add "X-Amz-Signature", valid_593321
  var valid_593322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593322 = validateParameter(valid_593322, JString, required = false,
                                 default = nil)
  if valid_593322 != nil:
    section.add "X-Amz-Content-Sha256", valid_593322
  var valid_593323 = header.getOrDefault("X-Amz-Date")
  valid_593323 = validateParameter(valid_593323, JString, required = false,
                                 default = nil)
  if valid_593323 != nil:
    section.add "X-Amz-Date", valid_593323
  var valid_593324 = header.getOrDefault("X-Amz-Credential")
  valid_593324 = validateParameter(valid_593324, JString, required = false,
                                 default = nil)
  if valid_593324 != nil:
    section.add "X-Amz-Credential", valid_593324
  var valid_593325 = header.getOrDefault("X-Amz-Security-Token")
  valid_593325 = validateParameter(valid_593325, JString, required = false,
                                 default = nil)
  if valid_593325 != nil:
    section.add "X-Amz-Security-Token", valid_593325
  var valid_593326 = header.getOrDefault("X-Amz-Algorithm")
  valid_593326 = validateParameter(valid_593326, JString, required = false,
                                 default = nil)
  if valid_593326 != nil:
    section.add "X-Amz-Algorithm", valid_593326
  var valid_593327 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593327 = validateParameter(valid_593327, JString, required = false,
                                 default = nil)
  if valid_593327 != nil:
    section.add "X-Amz-SignedHeaders", valid_593327
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593329: Call_SearchEntities_593315; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches for entities of the specified type. You can search for entities in your namespace and the public namespace that you're tracking.
  ## 
  let valid = call_593329.validator(path, query, header, formData, body)
  let scheme = call_593329.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593329.url(scheme.get, call_593329.host, call_593329.base,
                         call_593329.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593329, url, valid)

proc call*(call_593330: Call_SearchEntities_593315; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## searchEntities
  ## Searches for entities of the specified type. You can search for entities in your namespace and the public namespace that you're tracking.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_593331 = newJObject()
  var body_593332 = newJObject()
  add(query_593331, "nextToken", newJString(nextToken))
  if body != nil:
    body_593332 = body
  add(query_593331, "maxResults", newJString(maxResults))
  result = call_593330.call(nil, query_593331, nil, nil, body_593332)

var searchEntities* = Call_SearchEntities_593315(name: "searchEntities",
    meth: HttpMethod.HttpPost, host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.SearchEntities",
    validator: validate_SearchEntities_593316, base: "/", url: url_SearchEntities_593317,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchFlowExecutions_593333 = ref object of OpenApiRestCall_592364
proc url_SearchFlowExecutions_593335(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SearchFlowExecutions_593334(path: JsonNode; query: JsonNode;
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
  var valid_593336 = query.getOrDefault("nextToken")
  valid_593336 = validateParameter(valid_593336, JString, required = false,
                                 default = nil)
  if valid_593336 != nil:
    section.add "nextToken", valid_593336
  var valid_593337 = query.getOrDefault("maxResults")
  valid_593337 = validateParameter(valid_593337, JString, required = false,
                                 default = nil)
  if valid_593337 != nil:
    section.add "maxResults", valid_593337
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593338 = header.getOrDefault("X-Amz-Target")
  valid_593338 = validateParameter(valid_593338, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.SearchFlowExecutions"))
  if valid_593338 != nil:
    section.add "X-Amz-Target", valid_593338
  var valid_593339 = header.getOrDefault("X-Amz-Signature")
  valid_593339 = validateParameter(valid_593339, JString, required = false,
                                 default = nil)
  if valid_593339 != nil:
    section.add "X-Amz-Signature", valid_593339
  var valid_593340 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593340 = validateParameter(valid_593340, JString, required = false,
                                 default = nil)
  if valid_593340 != nil:
    section.add "X-Amz-Content-Sha256", valid_593340
  var valid_593341 = header.getOrDefault("X-Amz-Date")
  valid_593341 = validateParameter(valid_593341, JString, required = false,
                                 default = nil)
  if valid_593341 != nil:
    section.add "X-Amz-Date", valid_593341
  var valid_593342 = header.getOrDefault("X-Amz-Credential")
  valid_593342 = validateParameter(valid_593342, JString, required = false,
                                 default = nil)
  if valid_593342 != nil:
    section.add "X-Amz-Credential", valid_593342
  var valid_593343 = header.getOrDefault("X-Amz-Security-Token")
  valid_593343 = validateParameter(valid_593343, JString, required = false,
                                 default = nil)
  if valid_593343 != nil:
    section.add "X-Amz-Security-Token", valid_593343
  var valid_593344 = header.getOrDefault("X-Amz-Algorithm")
  valid_593344 = validateParameter(valid_593344, JString, required = false,
                                 default = nil)
  if valid_593344 != nil:
    section.add "X-Amz-Algorithm", valid_593344
  var valid_593345 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593345 = validateParameter(valid_593345, JString, required = false,
                                 default = nil)
  if valid_593345 != nil:
    section.add "X-Amz-SignedHeaders", valid_593345
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593347: Call_SearchFlowExecutions_593333; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches for AWS IoT Things Graph workflow execution instances.
  ## 
  let valid = call_593347.validator(path, query, header, formData, body)
  let scheme = call_593347.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593347.url(scheme.get, call_593347.host, call_593347.base,
                         call_593347.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593347, url, valid)

proc call*(call_593348: Call_SearchFlowExecutions_593333; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## searchFlowExecutions
  ## Searches for AWS IoT Things Graph workflow execution instances.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_593349 = newJObject()
  var body_593350 = newJObject()
  add(query_593349, "nextToken", newJString(nextToken))
  if body != nil:
    body_593350 = body
  add(query_593349, "maxResults", newJString(maxResults))
  result = call_593348.call(nil, query_593349, nil, nil, body_593350)

var searchFlowExecutions* = Call_SearchFlowExecutions_593333(
    name: "searchFlowExecutions", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.SearchFlowExecutions",
    validator: validate_SearchFlowExecutions_593334, base: "/",
    url: url_SearchFlowExecutions_593335, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchFlowTemplates_593351 = ref object of OpenApiRestCall_592364
proc url_SearchFlowTemplates_593353(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SearchFlowTemplates_593352(path: JsonNode; query: JsonNode;
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
  var valid_593354 = query.getOrDefault("nextToken")
  valid_593354 = validateParameter(valid_593354, JString, required = false,
                                 default = nil)
  if valid_593354 != nil:
    section.add "nextToken", valid_593354
  var valid_593355 = query.getOrDefault("maxResults")
  valid_593355 = validateParameter(valid_593355, JString, required = false,
                                 default = nil)
  if valid_593355 != nil:
    section.add "maxResults", valid_593355
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593356 = header.getOrDefault("X-Amz-Target")
  valid_593356 = validateParameter(valid_593356, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.SearchFlowTemplates"))
  if valid_593356 != nil:
    section.add "X-Amz-Target", valid_593356
  var valid_593357 = header.getOrDefault("X-Amz-Signature")
  valid_593357 = validateParameter(valid_593357, JString, required = false,
                                 default = nil)
  if valid_593357 != nil:
    section.add "X-Amz-Signature", valid_593357
  var valid_593358 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593358 = validateParameter(valid_593358, JString, required = false,
                                 default = nil)
  if valid_593358 != nil:
    section.add "X-Amz-Content-Sha256", valid_593358
  var valid_593359 = header.getOrDefault("X-Amz-Date")
  valid_593359 = validateParameter(valid_593359, JString, required = false,
                                 default = nil)
  if valid_593359 != nil:
    section.add "X-Amz-Date", valid_593359
  var valid_593360 = header.getOrDefault("X-Amz-Credential")
  valid_593360 = validateParameter(valid_593360, JString, required = false,
                                 default = nil)
  if valid_593360 != nil:
    section.add "X-Amz-Credential", valid_593360
  var valid_593361 = header.getOrDefault("X-Amz-Security-Token")
  valid_593361 = validateParameter(valid_593361, JString, required = false,
                                 default = nil)
  if valid_593361 != nil:
    section.add "X-Amz-Security-Token", valid_593361
  var valid_593362 = header.getOrDefault("X-Amz-Algorithm")
  valid_593362 = validateParameter(valid_593362, JString, required = false,
                                 default = nil)
  if valid_593362 != nil:
    section.add "X-Amz-Algorithm", valid_593362
  var valid_593363 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593363 = validateParameter(valid_593363, JString, required = false,
                                 default = nil)
  if valid_593363 != nil:
    section.add "X-Amz-SignedHeaders", valid_593363
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593365: Call_SearchFlowTemplates_593351; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches for summary information about workflows.
  ## 
  let valid = call_593365.validator(path, query, header, formData, body)
  let scheme = call_593365.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593365.url(scheme.get, call_593365.host, call_593365.base,
                         call_593365.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593365, url, valid)

proc call*(call_593366: Call_SearchFlowTemplates_593351; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## searchFlowTemplates
  ## Searches for summary information about workflows.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_593367 = newJObject()
  var body_593368 = newJObject()
  add(query_593367, "nextToken", newJString(nextToken))
  if body != nil:
    body_593368 = body
  add(query_593367, "maxResults", newJString(maxResults))
  result = call_593366.call(nil, query_593367, nil, nil, body_593368)

var searchFlowTemplates* = Call_SearchFlowTemplates_593351(
    name: "searchFlowTemplates", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.SearchFlowTemplates",
    validator: validate_SearchFlowTemplates_593352, base: "/",
    url: url_SearchFlowTemplates_593353, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchSystemInstances_593369 = ref object of OpenApiRestCall_592364
proc url_SearchSystemInstances_593371(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SearchSystemInstances_593370(path: JsonNode; query: JsonNode;
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
  var valid_593372 = query.getOrDefault("nextToken")
  valid_593372 = validateParameter(valid_593372, JString, required = false,
                                 default = nil)
  if valid_593372 != nil:
    section.add "nextToken", valid_593372
  var valid_593373 = query.getOrDefault("maxResults")
  valid_593373 = validateParameter(valid_593373, JString, required = false,
                                 default = nil)
  if valid_593373 != nil:
    section.add "maxResults", valid_593373
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593374 = header.getOrDefault("X-Amz-Target")
  valid_593374 = validateParameter(valid_593374, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.SearchSystemInstances"))
  if valid_593374 != nil:
    section.add "X-Amz-Target", valid_593374
  var valid_593375 = header.getOrDefault("X-Amz-Signature")
  valid_593375 = validateParameter(valid_593375, JString, required = false,
                                 default = nil)
  if valid_593375 != nil:
    section.add "X-Amz-Signature", valid_593375
  var valid_593376 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593376 = validateParameter(valid_593376, JString, required = false,
                                 default = nil)
  if valid_593376 != nil:
    section.add "X-Amz-Content-Sha256", valid_593376
  var valid_593377 = header.getOrDefault("X-Amz-Date")
  valid_593377 = validateParameter(valid_593377, JString, required = false,
                                 default = nil)
  if valid_593377 != nil:
    section.add "X-Amz-Date", valid_593377
  var valid_593378 = header.getOrDefault("X-Amz-Credential")
  valid_593378 = validateParameter(valid_593378, JString, required = false,
                                 default = nil)
  if valid_593378 != nil:
    section.add "X-Amz-Credential", valid_593378
  var valid_593379 = header.getOrDefault("X-Amz-Security-Token")
  valid_593379 = validateParameter(valid_593379, JString, required = false,
                                 default = nil)
  if valid_593379 != nil:
    section.add "X-Amz-Security-Token", valid_593379
  var valid_593380 = header.getOrDefault("X-Amz-Algorithm")
  valid_593380 = validateParameter(valid_593380, JString, required = false,
                                 default = nil)
  if valid_593380 != nil:
    section.add "X-Amz-Algorithm", valid_593380
  var valid_593381 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593381 = validateParameter(valid_593381, JString, required = false,
                                 default = nil)
  if valid_593381 != nil:
    section.add "X-Amz-SignedHeaders", valid_593381
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593383: Call_SearchSystemInstances_593369; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches for system instances in the user's account.
  ## 
  let valid = call_593383.validator(path, query, header, formData, body)
  let scheme = call_593383.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593383.url(scheme.get, call_593383.host, call_593383.base,
                         call_593383.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593383, url, valid)

proc call*(call_593384: Call_SearchSystemInstances_593369; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## searchSystemInstances
  ## Searches for system instances in the user's account.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_593385 = newJObject()
  var body_593386 = newJObject()
  add(query_593385, "nextToken", newJString(nextToken))
  if body != nil:
    body_593386 = body
  add(query_593385, "maxResults", newJString(maxResults))
  result = call_593384.call(nil, query_593385, nil, nil, body_593386)

var searchSystemInstances* = Call_SearchSystemInstances_593369(
    name: "searchSystemInstances", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com", route: "/#X-Amz-Target=IotThingsGraphFrontEndService.SearchSystemInstances",
    validator: validate_SearchSystemInstances_593370, base: "/",
    url: url_SearchSystemInstances_593371, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchSystemTemplates_593387 = ref object of OpenApiRestCall_592364
proc url_SearchSystemTemplates_593389(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SearchSystemTemplates_593388(path: JsonNode; query: JsonNode;
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
  var valid_593390 = query.getOrDefault("nextToken")
  valid_593390 = validateParameter(valid_593390, JString, required = false,
                                 default = nil)
  if valid_593390 != nil:
    section.add "nextToken", valid_593390
  var valid_593391 = query.getOrDefault("maxResults")
  valid_593391 = validateParameter(valid_593391, JString, required = false,
                                 default = nil)
  if valid_593391 != nil:
    section.add "maxResults", valid_593391
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593392 = header.getOrDefault("X-Amz-Target")
  valid_593392 = validateParameter(valid_593392, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.SearchSystemTemplates"))
  if valid_593392 != nil:
    section.add "X-Amz-Target", valid_593392
  var valid_593393 = header.getOrDefault("X-Amz-Signature")
  valid_593393 = validateParameter(valid_593393, JString, required = false,
                                 default = nil)
  if valid_593393 != nil:
    section.add "X-Amz-Signature", valid_593393
  var valid_593394 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593394 = validateParameter(valid_593394, JString, required = false,
                                 default = nil)
  if valid_593394 != nil:
    section.add "X-Amz-Content-Sha256", valid_593394
  var valid_593395 = header.getOrDefault("X-Amz-Date")
  valid_593395 = validateParameter(valid_593395, JString, required = false,
                                 default = nil)
  if valid_593395 != nil:
    section.add "X-Amz-Date", valid_593395
  var valid_593396 = header.getOrDefault("X-Amz-Credential")
  valid_593396 = validateParameter(valid_593396, JString, required = false,
                                 default = nil)
  if valid_593396 != nil:
    section.add "X-Amz-Credential", valid_593396
  var valid_593397 = header.getOrDefault("X-Amz-Security-Token")
  valid_593397 = validateParameter(valid_593397, JString, required = false,
                                 default = nil)
  if valid_593397 != nil:
    section.add "X-Amz-Security-Token", valid_593397
  var valid_593398 = header.getOrDefault("X-Amz-Algorithm")
  valid_593398 = validateParameter(valid_593398, JString, required = false,
                                 default = nil)
  if valid_593398 != nil:
    section.add "X-Amz-Algorithm", valid_593398
  var valid_593399 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593399 = validateParameter(valid_593399, JString, required = false,
                                 default = nil)
  if valid_593399 != nil:
    section.add "X-Amz-SignedHeaders", valid_593399
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593401: Call_SearchSystemTemplates_593387; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches for summary information about systems in the user's account. You can filter by the ID of a workflow to return only systems that use the specified workflow.
  ## 
  let valid = call_593401.validator(path, query, header, formData, body)
  let scheme = call_593401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593401.url(scheme.get, call_593401.host, call_593401.base,
                         call_593401.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593401, url, valid)

proc call*(call_593402: Call_SearchSystemTemplates_593387; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## searchSystemTemplates
  ## Searches for summary information about systems in the user's account. You can filter by the ID of a workflow to return only systems that use the specified workflow.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_593403 = newJObject()
  var body_593404 = newJObject()
  add(query_593403, "nextToken", newJString(nextToken))
  if body != nil:
    body_593404 = body
  add(query_593403, "maxResults", newJString(maxResults))
  result = call_593402.call(nil, query_593403, nil, nil, body_593404)

var searchSystemTemplates* = Call_SearchSystemTemplates_593387(
    name: "searchSystemTemplates", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com", route: "/#X-Amz-Target=IotThingsGraphFrontEndService.SearchSystemTemplates",
    validator: validate_SearchSystemTemplates_593388, base: "/",
    url: url_SearchSystemTemplates_593389, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchThings_593405 = ref object of OpenApiRestCall_592364
proc url_SearchThings_593407(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SearchThings_593406(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593408 = query.getOrDefault("nextToken")
  valid_593408 = validateParameter(valid_593408, JString, required = false,
                                 default = nil)
  if valid_593408 != nil:
    section.add "nextToken", valid_593408
  var valid_593409 = query.getOrDefault("maxResults")
  valid_593409 = validateParameter(valid_593409, JString, required = false,
                                 default = nil)
  if valid_593409 != nil:
    section.add "maxResults", valid_593409
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593410 = header.getOrDefault("X-Amz-Target")
  valid_593410 = validateParameter(valid_593410, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.SearchThings"))
  if valid_593410 != nil:
    section.add "X-Amz-Target", valid_593410
  var valid_593411 = header.getOrDefault("X-Amz-Signature")
  valid_593411 = validateParameter(valid_593411, JString, required = false,
                                 default = nil)
  if valid_593411 != nil:
    section.add "X-Amz-Signature", valid_593411
  var valid_593412 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593412 = validateParameter(valid_593412, JString, required = false,
                                 default = nil)
  if valid_593412 != nil:
    section.add "X-Amz-Content-Sha256", valid_593412
  var valid_593413 = header.getOrDefault("X-Amz-Date")
  valid_593413 = validateParameter(valid_593413, JString, required = false,
                                 default = nil)
  if valid_593413 != nil:
    section.add "X-Amz-Date", valid_593413
  var valid_593414 = header.getOrDefault("X-Amz-Credential")
  valid_593414 = validateParameter(valid_593414, JString, required = false,
                                 default = nil)
  if valid_593414 != nil:
    section.add "X-Amz-Credential", valid_593414
  var valid_593415 = header.getOrDefault("X-Amz-Security-Token")
  valid_593415 = validateParameter(valid_593415, JString, required = false,
                                 default = nil)
  if valid_593415 != nil:
    section.add "X-Amz-Security-Token", valid_593415
  var valid_593416 = header.getOrDefault("X-Amz-Algorithm")
  valid_593416 = validateParameter(valid_593416, JString, required = false,
                                 default = nil)
  if valid_593416 != nil:
    section.add "X-Amz-Algorithm", valid_593416
  var valid_593417 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593417 = validateParameter(valid_593417, JString, required = false,
                                 default = nil)
  if valid_593417 != nil:
    section.add "X-Amz-SignedHeaders", valid_593417
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593419: Call_SearchThings_593405; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Searches for things associated with the specified entity. You can search by both device and device model.</p> <p>For example, if two different devices, camera1 and camera2, implement the camera device model, the user can associate thing1 to camera1 and thing2 to camera2. <code>SearchThings(camera2)</code> will return only thing2, but <code>SearchThings(camera)</code> will return both thing1 and thing2.</p> <p>This action searches for exact matches and doesn't perform partial text matching.</p>
  ## 
  let valid = call_593419.validator(path, query, header, formData, body)
  let scheme = call_593419.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593419.url(scheme.get, call_593419.host, call_593419.base,
                         call_593419.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593419, url, valid)

proc call*(call_593420: Call_SearchThings_593405; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## searchThings
  ## <p>Searches for things associated with the specified entity. You can search by both device and device model.</p> <p>For example, if two different devices, camera1 and camera2, implement the camera device model, the user can associate thing1 to camera1 and thing2 to camera2. <code>SearchThings(camera2)</code> will return only thing2, but <code>SearchThings(camera)</code> will return both thing1 and thing2.</p> <p>This action searches for exact matches and doesn't perform partial text matching.</p>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_593421 = newJObject()
  var body_593422 = newJObject()
  add(query_593421, "nextToken", newJString(nextToken))
  if body != nil:
    body_593422 = body
  add(query_593421, "maxResults", newJString(maxResults))
  result = call_593420.call(nil, query_593421, nil, nil, body_593422)

var searchThings* = Call_SearchThings_593405(name: "searchThings",
    meth: HttpMethod.HttpPost, host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.SearchThings",
    validator: validate_SearchThings_593406, base: "/", url: url_SearchThings_593407,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_593423 = ref object of OpenApiRestCall_592364
proc url_TagResource_593425(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagResource_593424(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593426 = header.getOrDefault("X-Amz-Target")
  valid_593426 = validateParameter(valid_593426, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.TagResource"))
  if valid_593426 != nil:
    section.add "X-Amz-Target", valid_593426
  var valid_593427 = header.getOrDefault("X-Amz-Signature")
  valid_593427 = validateParameter(valid_593427, JString, required = false,
                                 default = nil)
  if valid_593427 != nil:
    section.add "X-Amz-Signature", valid_593427
  var valid_593428 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593428 = validateParameter(valid_593428, JString, required = false,
                                 default = nil)
  if valid_593428 != nil:
    section.add "X-Amz-Content-Sha256", valid_593428
  var valid_593429 = header.getOrDefault("X-Amz-Date")
  valid_593429 = validateParameter(valid_593429, JString, required = false,
                                 default = nil)
  if valid_593429 != nil:
    section.add "X-Amz-Date", valid_593429
  var valid_593430 = header.getOrDefault("X-Amz-Credential")
  valid_593430 = validateParameter(valid_593430, JString, required = false,
                                 default = nil)
  if valid_593430 != nil:
    section.add "X-Amz-Credential", valid_593430
  var valid_593431 = header.getOrDefault("X-Amz-Security-Token")
  valid_593431 = validateParameter(valid_593431, JString, required = false,
                                 default = nil)
  if valid_593431 != nil:
    section.add "X-Amz-Security-Token", valid_593431
  var valid_593432 = header.getOrDefault("X-Amz-Algorithm")
  valid_593432 = validateParameter(valid_593432, JString, required = false,
                                 default = nil)
  if valid_593432 != nil:
    section.add "X-Amz-Algorithm", valid_593432
  var valid_593433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593433 = validateParameter(valid_593433, JString, required = false,
                                 default = nil)
  if valid_593433 != nil:
    section.add "X-Amz-SignedHeaders", valid_593433
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593435: Call_TagResource_593423; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a tag for the specified resource.
  ## 
  let valid = call_593435.validator(path, query, header, formData, body)
  let scheme = call_593435.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593435.url(scheme.get, call_593435.host, call_593435.base,
                         call_593435.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593435, url, valid)

proc call*(call_593436: Call_TagResource_593423; body: JsonNode): Recallable =
  ## tagResource
  ## Creates a tag for the specified resource.
  ##   body: JObject (required)
  var body_593437 = newJObject()
  if body != nil:
    body_593437 = body
  result = call_593436.call(nil, nil, nil, nil, body_593437)

var tagResource* = Call_TagResource_593423(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "iotthingsgraph.amazonaws.com", route: "/#X-Amz-Target=IotThingsGraphFrontEndService.TagResource",
                                        validator: validate_TagResource_593424,
                                        base: "/", url: url_TagResource_593425,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UndeploySystemInstance_593438 = ref object of OpenApiRestCall_592364
proc url_UndeploySystemInstance_593440(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UndeploySystemInstance_593439(path: JsonNode; query: JsonNode;
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
  var valid_593441 = header.getOrDefault("X-Amz-Target")
  valid_593441 = validateParameter(valid_593441, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.UndeploySystemInstance"))
  if valid_593441 != nil:
    section.add "X-Amz-Target", valid_593441
  var valid_593442 = header.getOrDefault("X-Amz-Signature")
  valid_593442 = validateParameter(valid_593442, JString, required = false,
                                 default = nil)
  if valid_593442 != nil:
    section.add "X-Amz-Signature", valid_593442
  var valid_593443 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593443 = validateParameter(valid_593443, JString, required = false,
                                 default = nil)
  if valid_593443 != nil:
    section.add "X-Amz-Content-Sha256", valid_593443
  var valid_593444 = header.getOrDefault("X-Amz-Date")
  valid_593444 = validateParameter(valid_593444, JString, required = false,
                                 default = nil)
  if valid_593444 != nil:
    section.add "X-Amz-Date", valid_593444
  var valid_593445 = header.getOrDefault("X-Amz-Credential")
  valid_593445 = validateParameter(valid_593445, JString, required = false,
                                 default = nil)
  if valid_593445 != nil:
    section.add "X-Amz-Credential", valid_593445
  var valid_593446 = header.getOrDefault("X-Amz-Security-Token")
  valid_593446 = validateParameter(valid_593446, JString, required = false,
                                 default = nil)
  if valid_593446 != nil:
    section.add "X-Amz-Security-Token", valid_593446
  var valid_593447 = header.getOrDefault("X-Amz-Algorithm")
  valid_593447 = validateParameter(valid_593447, JString, required = false,
                                 default = nil)
  if valid_593447 != nil:
    section.add "X-Amz-Algorithm", valid_593447
  var valid_593448 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593448 = validateParameter(valid_593448, JString, required = false,
                                 default = nil)
  if valid_593448 != nil:
    section.add "X-Amz-SignedHeaders", valid_593448
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593450: Call_UndeploySystemInstance_593438; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a system instance from its target (Cloud or Greengrass).
  ## 
  let valid = call_593450.validator(path, query, header, formData, body)
  let scheme = call_593450.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593450.url(scheme.get, call_593450.host, call_593450.base,
                         call_593450.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593450, url, valid)

proc call*(call_593451: Call_UndeploySystemInstance_593438; body: JsonNode): Recallable =
  ## undeploySystemInstance
  ## Removes a system instance from its target (Cloud or Greengrass).
  ##   body: JObject (required)
  var body_593452 = newJObject()
  if body != nil:
    body_593452 = body
  result = call_593451.call(nil, nil, nil, nil, body_593452)

var undeploySystemInstance* = Call_UndeploySystemInstance_593438(
    name: "undeploySystemInstance", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com", route: "/#X-Amz-Target=IotThingsGraphFrontEndService.UndeploySystemInstance",
    validator: validate_UndeploySystemInstance_593439, base: "/",
    url: url_UndeploySystemInstance_593440, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_593453 = ref object of OpenApiRestCall_592364
proc url_UntagResource_593455(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UntagResource_593454(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593456 = header.getOrDefault("X-Amz-Target")
  valid_593456 = validateParameter(valid_593456, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.UntagResource"))
  if valid_593456 != nil:
    section.add "X-Amz-Target", valid_593456
  var valid_593457 = header.getOrDefault("X-Amz-Signature")
  valid_593457 = validateParameter(valid_593457, JString, required = false,
                                 default = nil)
  if valid_593457 != nil:
    section.add "X-Amz-Signature", valid_593457
  var valid_593458 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593458 = validateParameter(valid_593458, JString, required = false,
                                 default = nil)
  if valid_593458 != nil:
    section.add "X-Amz-Content-Sha256", valid_593458
  var valid_593459 = header.getOrDefault("X-Amz-Date")
  valid_593459 = validateParameter(valid_593459, JString, required = false,
                                 default = nil)
  if valid_593459 != nil:
    section.add "X-Amz-Date", valid_593459
  var valid_593460 = header.getOrDefault("X-Amz-Credential")
  valid_593460 = validateParameter(valid_593460, JString, required = false,
                                 default = nil)
  if valid_593460 != nil:
    section.add "X-Amz-Credential", valid_593460
  var valid_593461 = header.getOrDefault("X-Amz-Security-Token")
  valid_593461 = validateParameter(valid_593461, JString, required = false,
                                 default = nil)
  if valid_593461 != nil:
    section.add "X-Amz-Security-Token", valid_593461
  var valid_593462 = header.getOrDefault("X-Amz-Algorithm")
  valid_593462 = validateParameter(valid_593462, JString, required = false,
                                 default = nil)
  if valid_593462 != nil:
    section.add "X-Amz-Algorithm", valid_593462
  var valid_593463 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593463 = validateParameter(valid_593463, JString, required = false,
                                 default = nil)
  if valid_593463 != nil:
    section.add "X-Amz-SignedHeaders", valid_593463
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593465: Call_UntagResource_593453; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a tag from the specified resource.
  ## 
  let valid = call_593465.validator(path, query, header, formData, body)
  let scheme = call_593465.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593465.url(scheme.get, call_593465.host, call_593465.base,
                         call_593465.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593465, url, valid)

proc call*(call_593466: Call_UntagResource_593453; body: JsonNode): Recallable =
  ## untagResource
  ## Removes a tag from the specified resource.
  ##   body: JObject (required)
  var body_593467 = newJObject()
  if body != nil:
    body_593467 = body
  result = call_593466.call(nil, nil, nil, nil, body_593467)

var untagResource* = Call_UntagResource_593453(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.UntagResource",
    validator: validate_UntagResource_593454, base: "/", url: url_UntagResource_593455,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFlowTemplate_593468 = ref object of OpenApiRestCall_592364
proc url_UpdateFlowTemplate_593470(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateFlowTemplate_593469(path: JsonNode; query: JsonNode;
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
  var valid_593471 = header.getOrDefault("X-Amz-Target")
  valid_593471 = validateParameter(valid_593471, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.UpdateFlowTemplate"))
  if valid_593471 != nil:
    section.add "X-Amz-Target", valid_593471
  var valid_593472 = header.getOrDefault("X-Amz-Signature")
  valid_593472 = validateParameter(valid_593472, JString, required = false,
                                 default = nil)
  if valid_593472 != nil:
    section.add "X-Amz-Signature", valid_593472
  var valid_593473 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593473 = validateParameter(valid_593473, JString, required = false,
                                 default = nil)
  if valid_593473 != nil:
    section.add "X-Amz-Content-Sha256", valid_593473
  var valid_593474 = header.getOrDefault("X-Amz-Date")
  valid_593474 = validateParameter(valid_593474, JString, required = false,
                                 default = nil)
  if valid_593474 != nil:
    section.add "X-Amz-Date", valid_593474
  var valid_593475 = header.getOrDefault("X-Amz-Credential")
  valid_593475 = validateParameter(valid_593475, JString, required = false,
                                 default = nil)
  if valid_593475 != nil:
    section.add "X-Amz-Credential", valid_593475
  var valid_593476 = header.getOrDefault("X-Amz-Security-Token")
  valid_593476 = validateParameter(valid_593476, JString, required = false,
                                 default = nil)
  if valid_593476 != nil:
    section.add "X-Amz-Security-Token", valid_593476
  var valid_593477 = header.getOrDefault("X-Amz-Algorithm")
  valid_593477 = validateParameter(valid_593477, JString, required = false,
                                 default = nil)
  if valid_593477 != nil:
    section.add "X-Amz-Algorithm", valid_593477
  var valid_593478 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593478 = validateParameter(valid_593478, JString, required = false,
                                 default = nil)
  if valid_593478 != nil:
    section.add "X-Amz-SignedHeaders", valid_593478
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593480: Call_UpdateFlowTemplate_593468; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified workflow. All deployed systems and system instances that use the workflow will see the changes in the flow when it is redeployed. If you don't want this behavior, copy the workflow (creating a new workflow with a different ID), and update the copy. The workflow can contain only entities in the specified namespace. 
  ## 
  let valid = call_593480.validator(path, query, header, formData, body)
  let scheme = call_593480.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593480.url(scheme.get, call_593480.host, call_593480.base,
                         call_593480.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593480, url, valid)

proc call*(call_593481: Call_UpdateFlowTemplate_593468; body: JsonNode): Recallable =
  ## updateFlowTemplate
  ## Updates the specified workflow. All deployed systems and system instances that use the workflow will see the changes in the flow when it is redeployed. If you don't want this behavior, copy the workflow (creating a new workflow with a different ID), and update the copy. The workflow can contain only entities in the specified namespace. 
  ##   body: JObject (required)
  var body_593482 = newJObject()
  if body != nil:
    body_593482 = body
  result = call_593481.call(nil, nil, nil, nil, body_593482)

var updateFlowTemplate* = Call_UpdateFlowTemplate_593468(
    name: "updateFlowTemplate", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.UpdateFlowTemplate",
    validator: validate_UpdateFlowTemplate_593469, base: "/",
    url: url_UpdateFlowTemplate_593470, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSystemTemplate_593483 = ref object of OpenApiRestCall_592364
proc url_UpdateSystemTemplate_593485(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateSystemTemplate_593484(path: JsonNode; query: JsonNode;
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
  var valid_593486 = header.getOrDefault("X-Amz-Target")
  valid_593486 = validateParameter(valid_593486, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.UpdateSystemTemplate"))
  if valid_593486 != nil:
    section.add "X-Amz-Target", valid_593486
  var valid_593487 = header.getOrDefault("X-Amz-Signature")
  valid_593487 = validateParameter(valid_593487, JString, required = false,
                                 default = nil)
  if valid_593487 != nil:
    section.add "X-Amz-Signature", valid_593487
  var valid_593488 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593488 = validateParameter(valid_593488, JString, required = false,
                                 default = nil)
  if valid_593488 != nil:
    section.add "X-Amz-Content-Sha256", valid_593488
  var valid_593489 = header.getOrDefault("X-Amz-Date")
  valid_593489 = validateParameter(valid_593489, JString, required = false,
                                 default = nil)
  if valid_593489 != nil:
    section.add "X-Amz-Date", valid_593489
  var valid_593490 = header.getOrDefault("X-Amz-Credential")
  valid_593490 = validateParameter(valid_593490, JString, required = false,
                                 default = nil)
  if valid_593490 != nil:
    section.add "X-Amz-Credential", valid_593490
  var valid_593491 = header.getOrDefault("X-Amz-Security-Token")
  valid_593491 = validateParameter(valid_593491, JString, required = false,
                                 default = nil)
  if valid_593491 != nil:
    section.add "X-Amz-Security-Token", valid_593491
  var valid_593492 = header.getOrDefault("X-Amz-Algorithm")
  valid_593492 = validateParameter(valid_593492, JString, required = false,
                                 default = nil)
  if valid_593492 != nil:
    section.add "X-Amz-Algorithm", valid_593492
  var valid_593493 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593493 = validateParameter(valid_593493, JString, required = false,
                                 default = nil)
  if valid_593493 != nil:
    section.add "X-Amz-SignedHeaders", valid_593493
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593495: Call_UpdateSystemTemplate_593483; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified system. You don't need to run this action after updating a workflow. Any deployment that uses the system will see the changes in the system when it is redeployed.
  ## 
  let valid = call_593495.validator(path, query, header, formData, body)
  let scheme = call_593495.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593495.url(scheme.get, call_593495.host, call_593495.base,
                         call_593495.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593495, url, valid)

proc call*(call_593496: Call_UpdateSystemTemplate_593483; body: JsonNode): Recallable =
  ## updateSystemTemplate
  ## Updates the specified system. You don't need to run this action after updating a workflow. Any deployment that uses the system will see the changes in the system when it is redeployed.
  ##   body: JObject (required)
  var body_593497 = newJObject()
  if body != nil:
    body_593497 = body
  result = call_593496.call(nil, nil, nil, nil, body_593497)

var updateSystemTemplate* = Call_UpdateSystemTemplate_593483(
    name: "updateSystemTemplate", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com",
    route: "/#X-Amz-Target=IotThingsGraphFrontEndService.UpdateSystemTemplate",
    validator: validate_UpdateSystemTemplate_593484, base: "/",
    url: url_UpdateSystemTemplate_593485, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UploadEntityDefinitions_593498 = ref object of OpenApiRestCall_592364
proc url_UploadEntityDefinitions_593500(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UploadEntityDefinitions_593499(path: JsonNode; query: JsonNode;
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
  var valid_593501 = header.getOrDefault("X-Amz-Target")
  valid_593501 = validateParameter(valid_593501, JString, required = true, default = newJString(
      "IotThingsGraphFrontEndService.UploadEntityDefinitions"))
  if valid_593501 != nil:
    section.add "X-Amz-Target", valid_593501
  var valid_593502 = header.getOrDefault("X-Amz-Signature")
  valid_593502 = validateParameter(valid_593502, JString, required = false,
                                 default = nil)
  if valid_593502 != nil:
    section.add "X-Amz-Signature", valid_593502
  var valid_593503 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593503 = validateParameter(valid_593503, JString, required = false,
                                 default = nil)
  if valid_593503 != nil:
    section.add "X-Amz-Content-Sha256", valid_593503
  var valid_593504 = header.getOrDefault("X-Amz-Date")
  valid_593504 = validateParameter(valid_593504, JString, required = false,
                                 default = nil)
  if valid_593504 != nil:
    section.add "X-Amz-Date", valid_593504
  var valid_593505 = header.getOrDefault("X-Amz-Credential")
  valid_593505 = validateParameter(valid_593505, JString, required = false,
                                 default = nil)
  if valid_593505 != nil:
    section.add "X-Amz-Credential", valid_593505
  var valid_593506 = header.getOrDefault("X-Amz-Security-Token")
  valid_593506 = validateParameter(valid_593506, JString, required = false,
                                 default = nil)
  if valid_593506 != nil:
    section.add "X-Amz-Security-Token", valid_593506
  var valid_593507 = header.getOrDefault("X-Amz-Algorithm")
  valid_593507 = validateParameter(valid_593507, JString, required = false,
                                 default = nil)
  if valid_593507 != nil:
    section.add "X-Amz-Algorithm", valid_593507
  var valid_593508 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593508 = validateParameter(valid_593508, JString, required = false,
                                 default = nil)
  if valid_593508 != nil:
    section.add "X-Amz-SignedHeaders", valid_593508
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593510: Call_UploadEntityDefinitions_593498; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Asynchronously uploads one or more entity definitions to the user's namespace. The <code>document</code> parameter is required if <code>syncWithPublicNamespace</code> and <code>deleteExistingEntites</code> are false. If the <code>syncWithPublicNamespace</code> parameter is set to <code>true</code>, the user's namespace will synchronize with the latest version of the public namespace. If <code>deprecateExistingEntities</code> is set to true, all entities in the latest version will be deleted before the new <code>DefinitionDocument</code> is uploaded.</p> <p>When a user uploads entity definitions for the first time, the service creates a new namespace for the user. The new namespace tracks the public namespace. Currently users can have only one namespace. The namespace version increments whenever a user uploads entity definitions that are backwards-incompatible and whenever a user sets the <code>syncWithPublicNamespace</code> parameter or the <code>deprecateExistingEntities</code> parameter to <code>true</code>.</p> <p>The IDs for all of the entities should be in URN format. Each entity must be in the user's namespace. Users can't create entities in the public namespace, but entity definitions can refer to entities in the public namespace.</p> <p>Valid entities are <code>Device</code>, <code>DeviceModel</code>, <code>Service</code>, <code>Capability</code>, <code>State</code>, <code>Action</code>, <code>Event</code>, <code>Property</code>, <code>Mapping</code>, <code>Enum</code>. </p>
  ## 
  let valid = call_593510.validator(path, query, header, formData, body)
  let scheme = call_593510.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593510.url(scheme.get, call_593510.host, call_593510.base,
                         call_593510.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593510, url, valid)

proc call*(call_593511: Call_UploadEntityDefinitions_593498; body: JsonNode): Recallable =
  ## uploadEntityDefinitions
  ## <p>Asynchronously uploads one or more entity definitions to the user's namespace. The <code>document</code> parameter is required if <code>syncWithPublicNamespace</code> and <code>deleteExistingEntites</code> are false. If the <code>syncWithPublicNamespace</code> parameter is set to <code>true</code>, the user's namespace will synchronize with the latest version of the public namespace. If <code>deprecateExistingEntities</code> is set to true, all entities in the latest version will be deleted before the new <code>DefinitionDocument</code> is uploaded.</p> <p>When a user uploads entity definitions for the first time, the service creates a new namespace for the user. The new namespace tracks the public namespace. Currently users can have only one namespace. The namespace version increments whenever a user uploads entity definitions that are backwards-incompatible and whenever a user sets the <code>syncWithPublicNamespace</code> parameter or the <code>deprecateExistingEntities</code> parameter to <code>true</code>.</p> <p>The IDs for all of the entities should be in URN format. Each entity must be in the user's namespace. Users can't create entities in the public namespace, but entity definitions can refer to entities in the public namespace.</p> <p>Valid entities are <code>Device</code>, <code>DeviceModel</code>, <code>Service</code>, <code>Capability</code>, <code>State</code>, <code>Action</code>, <code>Event</code>, <code>Property</code>, <code>Mapping</code>, <code>Enum</code>. </p>
  ##   body: JObject (required)
  var body_593512 = newJObject()
  if body != nil:
    body_593512 = body
  result = call_593511.call(nil, nil, nil, nil, body_593512)

var uploadEntityDefinitions* = Call_UploadEntityDefinitions_593498(
    name: "uploadEntityDefinitions", meth: HttpMethod.HttpPost,
    host: "iotthingsgraph.amazonaws.com", route: "/#X-Amz-Target=IotThingsGraphFrontEndService.UploadEntityDefinitions",
    validator: validate_UploadEntityDefinitions_593499, base: "/",
    url: url_UploadEntityDefinitions_593500, schemes: {Scheme.Https, Scheme.Http})
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
