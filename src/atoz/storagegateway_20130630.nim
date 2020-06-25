
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Storage Gateway
## version: 2013-06-30
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS Storage Gateway Service</fullname> <p>AWS Storage Gateway is the service that connects an on-premises software appliance with cloud-based storage to provide seamless and secure integration between an organization's on-premises IT environment and the AWS storage infrastructure. The service enables you to securely upload data to the AWS cloud for cost effective backup and rapid disaster recovery.</p> <p>Use the following links to get started using the <i>AWS Storage Gateway Service API Reference</i>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/AWSStorageGatewayAPI.html#AWSStorageGatewayHTTPRequestsHeaders">AWS Storage Gateway Required Request Headers</a>: Describes the required headers that you must send with every POST request to AWS Storage Gateway.</p> </li> <li> <p> <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/AWSStorageGatewayAPI.html#AWSStorageGatewaySigningRequests">Signing Requests</a>: AWS Storage Gateway requires that you authenticate every request you send; this topic describes how sign such a request.</p> </li> <li> <p> <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/AWSStorageGatewayAPI.html#APIErrorResponses">Error Responses</a>: Provides reference information about AWS Storage Gateway errors.</p> </li> <li> <p> <a href="https://docs.aws.amazon.com/storagegateway/latest/APIReference/API_Operations.html">Operations in AWS Storage Gateway</a>: Contains detailed descriptions of all AWS Storage Gateway operations, their request parameters, response elements, possible errors, and examples of requests and responses.</p> </li> <li> <p> <a href="http://docs.aws.amazon.com/general/latest/gr/rande.html#sg_region">AWS Storage Gateway Regions and Endpoints:</a> Provides a list of each AWS Region and the endpoints available for use with AWS Storage Gateway. </p> </li> </ul> <note> <p>AWS Storage Gateway resource IDs are in uppercase. When you use these resource IDs with the Amazon EC2 API, EC2 expects resource IDs in lowercase. You must change your resource ID to lowercase to use it with the EC2 API. For example, in Storage Gateway the ID for a volume might be <code>vol-AA22BB012345DAF670</code>. When you use this ID with the EC2 API, you must change it to <code>vol-aa22bb012345daf670</code>. Otherwise, the EC2 API might not behave as expected.</p> </note> <important> <p>IDs for Storage Gateway volumes and Amazon EBS snapshots created from gateway volumes are changing to a longer format. Starting in December 2016, all new volumes and snapshots will be created with a 17-character string. Starting in April 2016, you will be able to use these longer IDs so you can test your systems with the new format. For more information, see <a href="https://aws.amazon.com/ec2/faqs/#longer-ids">Longer EC2 and EBS Resource IDs</a>. </p> <p> For example, a volume Amazon Resource Name (ARN) with the longer volume ID format looks like the following:</p> <p> <code>arn:aws:storagegateway:us-west-2:111122223333:gateway/sgw-12A3456B/volume/vol-1122AABBCCDDEEFFG</code>.</p> <p>A snapshot ID with the longer ID format looks like the following: <code>snap-78e226633445566ee</code>.</p> <p>For more information, see <a href="https://forums.aws.amazon.com/ann.jspa?annID=3557">Announcement: Heads-up – Longer AWS Storage Gateway volume and snapshot IDs coming in 2016</a>.</p> </important>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/storagegateway/
type
  Scheme {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (path: JsonNode = nil; query: JsonNode = nil;
                          header: JsonNode = nil; formData: JsonNode = nil;
                          body: JsonNode = nil; _: string = ""): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    makeUrl*: proc (protocol: Scheme; host: string; base: string; route: string;
                  path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_21625437 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625437](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625437): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low .. Scheme.high:
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
  if js == nil:
    if required:
      if default != nil:
        return validateParameter(default, kind, required = required)
  result = js
  if result == nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind == kind, $kind & " expected; received " & $js.kind

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
  awsServers = {Scheme.Http: {"ap-northeast-1": "storagegateway.ap-northeast-1.amazonaws.com", "ap-southeast-1": "storagegateway.ap-southeast-1.amazonaws.com", "us-west-2": "storagegateway.us-west-2.amazonaws.com", "eu-west-2": "storagegateway.eu-west-2.amazonaws.com", "ap-northeast-3": "storagegateway.ap-northeast-3.amazonaws.com", "eu-central-1": "storagegateway.eu-central-1.amazonaws.com", "us-east-2": "storagegateway.us-east-2.amazonaws.com", "us-east-1": "storagegateway.us-east-1.amazonaws.com", "cn-northwest-1": "storagegateway.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "storagegateway.ap-south-1.amazonaws.com", "eu-north-1": "storagegateway.eu-north-1.amazonaws.com", "ap-northeast-2": "storagegateway.ap-northeast-2.amazonaws.com", "us-west-1": "storagegateway.us-west-1.amazonaws.com", "us-gov-east-1": "storagegateway.us-gov-east-1.amazonaws.com", "eu-west-3": "storagegateway.eu-west-3.amazonaws.com", "cn-north-1": "storagegateway.cn-north-1.amazonaws.com.cn", "sa-east-1": "storagegateway.sa-east-1.amazonaws.com", "eu-west-1": "storagegateway.eu-west-1.amazonaws.com", "us-gov-west-1": "storagegateway.us-gov-west-1.amazonaws.com", "ap-southeast-2": "storagegateway.ap-southeast-2.amazonaws.com", "ca-central-1": "storagegateway.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "storagegateway.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "storagegateway.ap-southeast-1.amazonaws.com",
      "us-west-2": "storagegateway.us-west-2.amazonaws.com",
      "eu-west-2": "storagegateway.eu-west-2.amazonaws.com",
      "ap-northeast-3": "storagegateway.ap-northeast-3.amazonaws.com",
      "eu-central-1": "storagegateway.eu-central-1.amazonaws.com",
      "us-east-2": "storagegateway.us-east-2.amazonaws.com",
      "us-east-1": "storagegateway.us-east-1.amazonaws.com",
      "cn-northwest-1": "storagegateway.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "storagegateway.ap-south-1.amazonaws.com",
      "eu-north-1": "storagegateway.eu-north-1.amazonaws.com",
      "ap-northeast-2": "storagegateway.ap-northeast-2.amazonaws.com",
      "us-west-1": "storagegateway.us-west-1.amazonaws.com",
      "us-gov-east-1": "storagegateway.us-gov-east-1.amazonaws.com",
      "eu-west-3": "storagegateway.eu-west-3.amazonaws.com",
      "cn-north-1": "storagegateway.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "storagegateway.sa-east-1.amazonaws.com",
      "eu-west-1": "storagegateway.eu-west-1.amazonaws.com",
      "us-gov-west-1": "storagegateway.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "storagegateway.ap-southeast-2.amazonaws.com",
      "ca-central-1": "storagegateway.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "storagegateway"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_ActivateGateway_21625781 = ref object of OpenApiRestCall_21625437
proc url_ActivateGateway_21625783(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ActivateGateway_21625782(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Activates the gateway you previously deployed on your host. In the activation process, you specify information such as the AWS Region that you want to use for storing snapshots or tapes, the time zone for scheduled snapshots the gateway snapshot schedule window, an activation key, and a name for your gateway. The activation process also associates your gateway with your account; for more information, see <a>UpdateGatewayInformation</a>.</p> <note> <p>You must turn on the gateway VM before you can activate your gateway.</p> </note>
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
  var valid_21625884 = header.getOrDefault("X-Amz-Date")
  valid_21625884 = validateParameter(valid_21625884, JString, required = false,
                                   default = nil)
  if valid_21625884 != nil:
    section.add "X-Amz-Date", valid_21625884
  var valid_21625885 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625885 = validateParameter(valid_21625885, JString, required = false,
                                   default = nil)
  if valid_21625885 != nil:
    section.add "X-Amz-Security-Token", valid_21625885
  var valid_21625900 = header.getOrDefault("X-Amz-Target")
  valid_21625900 = validateParameter(valid_21625900, JString, required = true, default = newJString(
      "StorageGateway_20130630.ActivateGateway"))
  if valid_21625900 != nil:
    section.add "X-Amz-Target", valid_21625900
  var valid_21625901 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625901 = validateParameter(valid_21625901, JString, required = false,
                                   default = nil)
  if valid_21625901 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625901
  var valid_21625902 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625902 = validateParameter(valid_21625902, JString, required = false,
                                   default = nil)
  if valid_21625902 != nil:
    section.add "X-Amz-Algorithm", valid_21625902
  var valid_21625903 = header.getOrDefault("X-Amz-Signature")
  valid_21625903 = validateParameter(valid_21625903, JString, required = false,
                                   default = nil)
  if valid_21625903 != nil:
    section.add "X-Amz-Signature", valid_21625903
  var valid_21625904 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625904 = validateParameter(valid_21625904, JString, required = false,
                                   default = nil)
  if valid_21625904 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625904
  var valid_21625905 = header.getOrDefault("X-Amz-Credential")
  valid_21625905 = validateParameter(valid_21625905, JString, required = false,
                                   default = nil)
  if valid_21625905 != nil:
    section.add "X-Amz-Credential", valid_21625905
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21625931: Call_ActivateGateway_21625781; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Activates the gateway you previously deployed on your host. In the activation process, you specify information such as the AWS Region that you want to use for storing snapshots or tapes, the time zone for scheduled snapshots the gateway snapshot schedule window, an activation key, and a name for your gateway. The activation process also associates your gateway with your account; for more information, see <a>UpdateGatewayInformation</a>.</p> <note> <p>You must turn on the gateway VM before you can activate your gateway.</p> </note>
  ## 
  let valid = call_21625931.validator(path, query, header, formData, body, _)
  let scheme = call_21625931.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625931.makeUrl(scheme.get, call_21625931.host, call_21625931.base,
                               call_21625931.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625931, uri, valid, _)

proc call*(call_21625994: Call_ActivateGateway_21625781; body: JsonNode): Recallable =
  ## activateGateway
  ## <p>Activates the gateway you previously deployed on your host. In the activation process, you specify information such as the AWS Region that you want to use for storing snapshots or tapes, the time zone for scheduled snapshots the gateway snapshot schedule window, an activation key, and a name for your gateway. The activation process also associates your gateway with your account; for more information, see <a>UpdateGatewayInformation</a>.</p> <note> <p>You must turn on the gateway VM before you can activate your gateway.</p> </note>
  ##   body: JObject (required)
  var body_21625995 = newJObject()
  if body != nil:
    body_21625995 = body
  result = call_21625994.call(nil, nil, nil, nil, body_21625995)

var activateGateway* = Call_ActivateGateway_21625781(name: "activateGateway",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.ActivateGateway",
    validator: validate_ActivateGateway_21625782, base: "/",
    makeUrl: url_ActivateGateway_21625783, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AddCache_21626031 = ref object of OpenApiRestCall_21625437
proc url_AddCache_21626033(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AddCache_21626032(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Configures one or more gateway local disks as cache for a gateway. This operation is only supported in the cached volume, tape and file gateway type (see <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/StorageGatewayConcepts.html">Storage Gateway Concepts</a>).</p> <p>In the request, you specify the gateway Amazon Resource Name (ARN) to which you want to add cache, and one or more disk IDs that you want to configure as cache.</p>
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
  var valid_21626034 = header.getOrDefault("X-Amz-Date")
  valid_21626034 = validateParameter(valid_21626034, JString, required = false,
                                   default = nil)
  if valid_21626034 != nil:
    section.add "X-Amz-Date", valid_21626034
  var valid_21626035 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626035 = validateParameter(valid_21626035, JString, required = false,
                                   default = nil)
  if valid_21626035 != nil:
    section.add "X-Amz-Security-Token", valid_21626035
  var valid_21626036 = header.getOrDefault("X-Amz-Target")
  valid_21626036 = validateParameter(valid_21626036, JString, required = true, default = newJString(
      "StorageGateway_20130630.AddCache"))
  if valid_21626036 != nil:
    section.add "X-Amz-Target", valid_21626036
  var valid_21626037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626037 = validateParameter(valid_21626037, JString, required = false,
                                   default = nil)
  if valid_21626037 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626037
  var valid_21626038 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626038 = validateParameter(valid_21626038, JString, required = false,
                                   default = nil)
  if valid_21626038 != nil:
    section.add "X-Amz-Algorithm", valid_21626038
  var valid_21626039 = header.getOrDefault("X-Amz-Signature")
  valid_21626039 = validateParameter(valid_21626039, JString, required = false,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "X-Amz-Signature", valid_21626039
  var valid_21626040 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626040 = validateParameter(valid_21626040, JString, required = false,
                                   default = nil)
  if valid_21626040 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626040
  var valid_21626041 = header.getOrDefault("X-Amz-Credential")
  valid_21626041 = validateParameter(valid_21626041, JString, required = false,
                                   default = nil)
  if valid_21626041 != nil:
    section.add "X-Amz-Credential", valid_21626041
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626043: Call_AddCache_21626031; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Configures one or more gateway local disks as cache for a gateway. This operation is only supported in the cached volume, tape and file gateway type (see <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/StorageGatewayConcepts.html">Storage Gateway Concepts</a>).</p> <p>In the request, you specify the gateway Amazon Resource Name (ARN) to which you want to add cache, and one or more disk IDs that you want to configure as cache.</p>
  ## 
  let valid = call_21626043.validator(path, query, header, formData, body, _)
  let scheme = call_21626043.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626043.makeUrl(scheme.get, call_21626043.host, call_21626043.base,
                               call_21626043.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626043, uri, valid, _)

proc call*(call_21626044: Call_AddCache_21626031; body: JsonNode): Recallable =
  ## addCache
  ## <p>Configures one or more gateway local disks as cache for a gateway. This operation is only supported in the cached volume, tape and file gateway type (see <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/StorageGatewayConcepts.html">Storage Gateway Concepts</a>).</p> <p>In the request, you specify the gateway Amazon Resource Name (ARN) to which you want to add cache, and one or more disk IDs that you want to configure as cache.</p>
  ##   body: JObject (required)
  var body_21626045 = newJObject()
  if body != nil:
    body_21626045 = body
  result = call_21626044.call(nil, nil, nil, nil, body_21626045)

var addCache* = Call_AddCache_21626031(name: "addCache", meth: HttpMethod.HttpPost,
                                    host: "storagegateway.amazonaws.com", route: "/#X-Amz-Target=StorageGateway_20130630.AddCache",
                                    validator: validate_AddCache_21626032,
                                    base: "/", makeUrl: url_AddCache_21626033,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AddTagsToResource_21626046 = ref object of OpenApiRestCall_21625437
proc url_AddTagsToResource_21626048(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AddTagsToResource_21626047(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Adds one or more tags to the specified resource. You use tags to add metadata to resources, which you can use to categorize these resources. For example, you can categorize resources by purpose, owner, environment, or team. Each tag consists of a key and a value, which you define. You can add tags to the following AWS Storage Gateway resources:</p> <ul> <li> <p>Storage gateways of all types</p> </li> <li> <p>Storage volumes</p> </li> <li> <p>Virtual tapes</p> </li> <li> <p>NFS and SMB file shares</p> </li> </ul> <p>You can create a maximum of 50 tags for each resource. Virtual tapes and storage volumes that are recovered to a new gateway maintain their tags.</p>
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
  var valid_21626049 = header.getOrDefault("X-Amz-Date")
  valid_21626049 = validateParameter(valid_21626049, JString, required = false,
                                   default = nil)
  if valid_21626049 != nil:
    section.add "X-Amz-Date", valid_21626049
  var valid_21626050 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626050 = validateParameter(valid_21626050, JString, required = false,
                                   default = nil)
  if valid_21626050 != nil:
    section.add "X-Amz-Security-Token", valid_21626050
  var valid_21626051 = header.getOrDefault("X-Amz-Target")
  valid_21626051 = validateParameter(valid_21626051, JString, required = true, default = newJString(
      "StorageGateway_20130630.AddTagsToResource"))
  if valid_21626051 != nil:
    section.add "X-Amz-Target", valid_21626051
  var valid_21626052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626052 = validateParameter(valid_21626052, JString, required = false,
                                   default = nil)
  if valid_21626052 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626052
  var valid_21626053 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626053 = validateParameter(valid_21626053, JString, required = false,
                                   default = nil)
  if valid_21626053 != nil:
    section.add "X-Amz-Algorithm", valid_21626053
  var valid_21626054 = header.getOrDefault("X-Amz-Signature")
  valid_21626054 = validateParameter(valid_21626054, JString, required = false,
                                   default = nil)
  if valid_21626054 != nil:
    section.add "X-Amz-Signature", valid_21626054
  var valid_21626055 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626055 = validateParameter(valid_21626055, JString, required = false,
                                   default = nil)
  if valid_21626055 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626055
  var valid_21626056 = header.getOrDefault("X-Amz-Credential")
  valid_21626056 = validateParameter(valid_21626056, JString, required = false,
                                   default = nil)
  if valid_21626056 != nil:
    section.add "X-Amz-Credential", valid_21626056
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626058: Call_AddTagsToResource_21626046; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Adds one or more tags to the specified resource. You use tags to add metadata to resources, which you can use to categorize these resources. For example, you can categorize resources by purpose, owner, environment, or team. Each tag consists of a key and a value, which you define. You can add tags to the following AWS Storage Gateway resources:</p> <ul> <li> <p>Storage gateways of all types</p> </li> <li> <p>Storage volumes</p> </li> <li> <p>Virtual tapes</p> </li> <li> <p>NFS and SMB file shares</p> </li> </ul> <p>You can create a maximum of 50 tags for each resource. Virtual tapes and storage volumes that are recovered to a new gateway maintain their tags.</p>
  ## 
  let valid = call_21626058.validator(path, query, header, formData, body, _)
  let scheme = call_21626058.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626058.makeUrl(scheme.get, call_21626058.host, call_21626058.base,
                               call_21626058.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626058, uri, valid, _)

proc call*(call_21626059: Call_AddTagsToResource_21626046; body: JsonNode): Recallable =
  ## addTagsToResource
  ## <p>Adds one or more tags to the specified resource. You use tags to add metadata to resources, which you can use to categorize these resources. For example, you can categorize resources by purpose, owner, environment, or team. Each tag consists of a key and a value, which you define. You can add tags to the following AWS Storage Gateway resources:</p> <ul> <li> <p>Storage gateways of all types</p> </li> <li> <p>Storage volumes</p> </li> <li> <p>Virtual tapes</p> </li> <li> <p>NFS and SMB file shares</p> </li> </ul> <p>You can create a maximum of 50 tags for each resource. Virtual tapes and storage volumes that are recovered to a new gateway maintain their tags.</p>
  ##   body: JObject (required)
  var body_21626060 = newJObject()
  if body != nil:
    body_21626060 = body
  result = call_21626059.call(nil, nil, nil, nil, body_21626060)

var addTagsToResource* = Call_AddTagsToResource_21626046(name: "addTagsToResource",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.AddTagsToResource",
    validator: validate_AddTagsToResource_21626047, base: "/",
    makeUrl: url_AddTagsToResource_21626048, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AddUploadBuffer_21626061 = ref object of OpenApiRestCall_21625437
proc url_AddUploadBuffer_21626063(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AddUploadBuffer_21626062(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Configures one or more gateway local disks as upload buffer for a specified gateway. This operation is supported for the stored volume, cached volume and tape gateway types.</p> <p>In the request, you specify the gateway Amazon Resource Name (ARN) to which you want to add upload buffer, and one or more disk IDs that you want to configure as upload buffer.</p>
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
  var valid_21626064 = header.getOrDefault("X-Amz-Date")
  valid_21626064 = validateParameter(valid_21626064, JString, required = false,
                                   default = nil)
  if valid_21626064 != nil:
    section.add "X-Amz-Date", valid_21626064
  var valid_21626065 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626065 = validateParameter(valid_21626065, JString, required = false,
                                   default = nil)
  if valid_21626065 != nil:
    section.add "X-Amz-Security-Token", valid_21626065
  var valid_21626066 = header.getOrDefault("X-Amz-Target")
  valid_21626066 = validateParameter(valid_21626066, JString, required = true, default = newJString(
      "StorageGateway_20130630.AddUploadBuffer"))
  if valid_21626066 != nil:
    section.add "X-Amz-Target", valid_21626066
  var valid_21626067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626067 = validateParameter(valid_21626067, JString, required = false,
                                   default = nil)
  if valid_21626067 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626067
  var valid_21626068 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626068 = validateParameter(valid_21626068, JString, required = false,
                                   default = nil)
  if valid_21626068 != nil:
    section.add "X-Amz-Algorithm", valid_21626068
  var valid_21626069 = header.getOrDefault("X-Amz-Signature")
  valid_21626069 = validateParameter(valid_21626069, JString, required = false,
                                   default = nil)
  if valid_21626069 != nil:
    section.add "X-Amz-Signature", valid_21626069
  var valid_21626070 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626070 = validateParameter(valid_21626070, JString, required = false,
                                   default = nil)
  if valid_21626070 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626070
  var valid_21626071 = header.getOrDefault("X-Amz-Credential")
  valid_21626071 = validateParameter(valid_21626071, JString, required = false,
                                   default = nil)
  if valid_21626071 != nil:
    section.add "X-Amz-Credential", valid_21626071
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626073: Call_AddUploadBuffer_21626061; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Configures one or more gateway local disks as upload buffer for a specified gateway. This operation is supported for the stored volume, cached volume and tape gateway types.</p> <p>In the request, you specify the gateway Amazon Resource Name (ARN) to which you want to add upload buffer, and one or more disk IDs that you want to configure as upload buffer.</p>
  ## 
  let valid = call_21626073.validator(path, query, header, formData, body, _)
  let scheme = call_21626073.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626073.makeUrl(scheme.get, call_21626073.host, call_21626073.base,
                               call_21626073.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626073, uri, valid, _)

proc call*(call_21626074: Call_AddUploadBuffer_21626061; body: JsonNode): Recallable =
  ## addUploadBuffer
  ## <p>Configures one or more gateway local disks as upload buffer for a specified gateway. This operation is supported for the stored volume, cached volume and tape gateway types.</p> <p>In the request, you specify the gateway Amazon Resource Name (ARN) to which you want to add upload buffer, and one or more disk IDs that you want to configure as upload buffer.</p>
  ##   body: JObject (required)
  var body_21626075 = newJObject()
  if body != nil:
    body_21626075 = body
  result = call_21626074.call(nil, nil, nil, nil, body_21626075)

var addUploadBuffer* = Call_AddUploadBuffer_21626061(name: "addUploadBuffer",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.AddUploadBuffer",
    validator: validate_AddUploadBuffer_21626062, base: "/",
    makeUrl: url_AddUploadBuffer_21626063, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AddWorkingStorage_21626076 = ref object of OpenApiRestCall_21625437
proc url_AddWorkingStorage_21626078(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AddWorkingStorage_21626077(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Configures one or more gateway local disks as working storage for a gateway. This operation is only supported in the stored volume gateway type. This operation is deprecated in cached volume API version 20120630. Use <a>AddUploadBuffer</a> instead.</p> <note> <p>Working storage is also referred to as upload buffer. You can also use the <a>AddUploadBuffer</a> operation to add upload buffer to a stored volume gateway.</p> </note> <p>In the request, you specify the gateway Amazon Resource Name (ARN) to which you want to add working storage, and one or more disk IDs that you want to configure as working storage.</p>
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
  var valid_21626079 = header.getOrDefault("X-Amz-Date")
  valid_21626079 = validateParameter(valid_21626079, JString, required = false,
                                   default = nil)
  if valid_21626079 != nil:
    section.add "X-Amz-Date", valid_21626079
  var valid_21626080 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626080 = validateParameter(valid_21626080, JString, required = false,
                                   default = nil)
  if valid_21626080 != nil:
    section.add "X-Amz-Security-Token", valid_21626080
  var valid_21626081 = header.getOrDefault("X-Amz-Target")
  valid_21626081 = validateParameter(valid_21626081, JString, required = true, default = newJString(
      "StorageGateway_20130630.AddWorkingStorage"))
  if valid_21626081 != nil:
    section.add "X-Amz-Target", valid_21626081
  var valid_21626082 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626082 = validateParameter(valid_21626082, JString, required = false,
                                   default = nil)
  if valid_21626082 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626082
  var valid_21626083 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626083 = validateParameter(valid_21626083, JString, required = false,
                                   default = nil)
  if valid_21626083 != nil:
    section.add "X-Amz-Algorithm", valid_21626083
  var valid_21626084 = header.getOrDefault("X-Amz-Signature")
  valid_21626084 = validateParameter(valid_21626084, JString, required = false,
                                   default = nil)
  if valid_21626084 != nil:
    section.add "X-Amz-Signature", valid_21626084
  var valid_21626085 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626085 = validateParameter(valid_21626085, JString, required = false,
                                   default = nil)
  if valid_21626085 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626085
  var valid_21626086 = header.getOrDefault("X-Amz-Credential")
  valid_21626086 = validateParameter(valid_21626086, JString, required = false,
                                   default = nil)
  if valid_21626086 != nil:
    section.add "X-Amz-Credential", valid_21626086
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626088: Call_AddWorkingStorage_21626076; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Configures one or more gateway local disks as working storage for a gateway. This operation is only supported in the stored volume gateway type. This operation is deprecated in cached volume API version 20120630. Use <a>AddUploadBuffer</a> instead.</p> <note> <p>Working storage is also referred to as upload buffer. You can also use the <a>AddUploadBuffer</a> operation to add upload buffer to a stored volume gateway.</p> </note> <p>In the request, you specify the gateway Amazon Resource Name (ARN) to which you want to add working storage, and one or more disk IDs that you want to configure as working storage.</p>
  ## 
  let valid = call_21626088.validator(path, query, header, formData, body, _)
  let scheme = call_21626088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626088.makeUrl(scheme.get, call_21626088.host, call_21626088.base,
                               call_21626088.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626088, uri, valid, _)

proc call*(call_21626089: Call_AddWorkingStorage_21626076; body: JsonNode): Recallable =
  ## addWorkingStorage
  ## <p>Configures one or more gateway local disks as working storage for a gateway. This operation is only supported in the stored volume gateway type. This operation is deprecated in cached volume API version 20120630. Use <a>AddUploadBuffer</a> instead.</p> <note> <p>Working storage is also referred to as upload buffer. You can also use the <a>AddUploadBuffer</a> operation to add upload buffer to a stored volume gateway.</p> </note> <p>In the request, you specify the gateway Amazon Resource Name (ARN) to which you want to add working storage, and one or more disk IDs that you want to configure as working storage.</p>
  ##   body: JObject (required)
  var body_21626090 = newJObject()
  if body != nil:
    body_21626090 = body
  result = call_21626089.call(nil, nil, nil, nil, body_21626090)

var addWorkingStorage* = Call_AddWorkingStorage_21626076(name: "addWorkingStorage",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.AddWorkingStorage",
    validator: validate_AddWorkingStorage_21626077, base: "/",
    makeUrl: url_AddWorkingStorage_21626078, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssignTapePool_21626091 = ref object of OpenApiRestCall_21625437
proc url_AssignTapePool_21626093(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssignTapePool_21626092(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Assigns a tape to a tape pool for archiving. The tape assigned to a pool is archived in the S3 storage class that is associated with the pool. When you use your backup application to eject the tape, the tape is archived directly into the S3 storage class (Glacier or Deep Archive) that corresponds to the pool.</p> <p>Valid values: "GLACIER", "DEEP_ARCHIVE"</p>
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
  var valid_21626094 = header.getOrDefault("X-Amz-Date")
  valid_21626094 = validateParameter(valid_21626094, JString, required = false,
                                   default = nil)
  if valid_21626094 != nil:
    section.add "X-Amz-Date", valid_21626094
  var valid_21626095 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626095 = validateParameter(valid_21626095, JString, required = false,
                                   default = nil)
  if valid_21626095 != nil:
    section.add "X-Amz-Security-Token", valid_21626095
  var valid_21626096 = header.getOrDefault("X-Amz-Target")
  valid_21626096 = validateParameter(valid_21626096, JString, required = true, default = newJString(
      "StorageGateway_20130630.AssignTapePool"))
  if valid_21626096 != nil:
    section.add "X-Amz-Target", valid_21626096
  var valid_21626097 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626097 = validateParameter(valid_21626097, JString, required = false,
                                   default = nil)
  if valid_21626097 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626097
  var valid_21626098 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626098 = validateParameter(valid_21626098, JString, required = false,
                                   default = nil)
  if valid_21626098 != nil:
    section.add "X-Amz-Algorithm", valid_21626098
  var valid_21626099 = header.getOrDefault("X-Amz-Signature")
  valid_21626099 = validateParameter(valid_21626099, JString, required = false,
                                   default = nil)
  if valid_21626099 != nil:
    section.add "X-Amz-Signature", valid_21626099
  var valid_21626100 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626100 = validateParameter(valid_21626100, JString, required = false,
                                   default = nil)
  if valid_21626100 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626100
  var valid_21626101 = header.getOrDefault("X-Amz-Credential")
  valid_21626101 = validateParameter(valid_21626101, JString, required = false,
                                   default = nil)
  if valid_21626101 != nil:
    section.add "X-Amz-Credential", valid_21626101
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626103: Call_AssignTapePool_21626091; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Assigns a tape to a tape pool for archiving. The tape assigned to a pool is archived in the S3 storage class that is associated with the pool. When you use your backup application to eject the tape, the tape is archived directly into the S3 storage class (Glacier or Deep Archive) that corresponds to the pool.</p> <p>Valid values: "GLACIER", "DEEP_ARCHIVE"</p>
  ## 
  let valid = call_21626103.validator(path, query, header, formData, body, _)
  let scheme = call_21626103.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626103.makeUrl(scheme.get, call_21626103.host, call_21626103.base,
                               call_21626103.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626103, uri, valid, _)

proc call*(call_21626104: Call_AssignTapePool_21626091; body: JsonNode): Recallable =
  ## assignTapePool
  ## <p>Assigns a tape to a tape pool for archiving. The tape assigned to a pool is archived in the S3 storage class that is associated with the pool. When you use your backup application to eject the tape, the tape is archived directly into the S3 storage class (Glacier or Deep Archive) that corresponds to the pool.</p> <p>Valid values: "GLACIER", "DEEP_ARCHIVE"</p>
  ##   body: JObject (required)
  var body_21626105 = newJObject()
  if body != nil:
    body_21626105 = body
  result = call_21626104.call(nil, nil, nil, nil, body_21626105)

var assignTapePool* = Call_AssignTapePool_21626091(name: "assignTapePool",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.AssignTapePool",
    validator: validate_AssignTapePool_21626092, base: "/",
    makeUrl: url_AssignTapePool_21626093, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachVolume_21626106 = ref object of OpenApiRestCall_21625437
proc url_AttachVolume_21626108(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AttachVolume_21626107(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Connects a volume to an iSCSI connection and then attaches the volume to the specified gateway. Detaching and attaching a volume enables you to recover your data from one gateway to a different gateway without creating a snapshot. It also makes it easier to move your volumes from an on-premises gateway to a gateway hosted on an Amazon EC2 instance.
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
  var valid_21626109 = header.getOrDefault("X-Amz-Date")
  valid_21626109 = validateParameter(valid_21626109, JString, required = false,
                                   default = nil)
  if valid_21626109 != nil:
    section.add "X-Amz-Date", valid_21626109
  var valid_21626110 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626110 = validateParameter(valid_21626110, JString, required = false,
                                   default = nil)
  if valid_21626110 != nil:
    section.add "X-Amz-Security-Token", valid_21626110
  var valid_21626111 = header.getOrDefault("X-Amz-Target")
  valid_21626111 = validateParameter(valid_21626111, JString, required = true, default = newJString(
      "StorageGateway_20130630.AttachVolume"))
  if valid_21626111 != nil:
    section.add "X-Amz-Target", valid_21626111
  var valid_21626112 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626112 = validateParameter(valid_21626112, JString, required = false,
                                   default = nil)
  if valid_21626112 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626112
  var valid_21626113 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626113 = validateParameter(valid_21626113, JString, required = false,
                                   default = nil)
  if valid_21626113 != nil:
    section.add "X-Amz-Algorithm", valid_21626113
  var valid_21626114 = header.getOrDefault("X-Amz-Signature")
  valid_21626114 = validateParameter(valid_21626114, JString, required = false,
                                   default = nil)
  if valid_21626114 != nil:
    section.add "X-Amz-Signature", valid_21626114
  var valid_21626115 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626115 = validateParameter(valid_21626115, JString, required = false,
                                   default = nil)
  if valid_21626115 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626115
  var valid_21626116 = header.getOrDefault("X-Amz-Credential")
  valid_21626116 = validateParameter(valid_21626116, JString, required = false,
                                   default = nil)
  if valid_21626116 != nil:
    section.add "X-Amz-Credential", valid_21626116
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626118: Call_AttachVolume_21626106; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Connects a volume to an iSCSI connection and then attaches the volume to the specified gateway. Detaching and attaching a volume enables you to recover your data from one gateway to a different gateway without creating a snapshot. It also makes it easier to move your volumes from an on-premises gateway to a gateway hosted on an Amazon EC2 instance.
  ## 
  let valid = call_21626118.validator(path, query, header, formData, body, _)
  let scheme = call_21626118.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626118.makeUrl(scheme.get, call_21626118.host, call_21626118.base,
                               call_21626118.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626118, uri, valid, _)

proc call*(call_21626119: Call_AttachVolume_21626106; body: JsonNode): Recallable =
  ## attachVolume
  ## Connects a volume to an iSCSI connection and then attaches the volume to the specified gateway. Detaching and attaching a volume enables you to recover your data from one gateway to a different gateway without creating a snapshot. It also makes it easier to move your volumes from an on-premises gateway to a gateway hosted on an Amazon EC2 instance.
  ##   body: JObject (required)
  var body_21626120 = newJObject()
  if body != nil:
    body_21626120 = body
  result = call_21626119.call(nil, nil, nil, nil, body_21626120)

var attachVolume* = Call_AttachVolume_21626106(name: "attachVolume",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.AttachVolume",
    validator: validate_AttachVolume_21626107, base: "/", makeUrl: url_AttachVolume_21626108,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelArchival_21626121 = ref object of OpenApiRestCall_21625437
proc url_CancelArchival_21626123(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CancelArchival_21626122(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Cancels archiving of a virtual tape to the virtual tape shelf (VTS) after the archiving process is initiated. This operation is only supported in the tape gateway type.
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
  var valid_21626124 = header.getOrDefault("X-Amz-Date")
  valid_21626124 = validateParameter(valid_21626124, JString, required = false,
                                   default = nil)
  if valid_21626124 != nil:
    section.add "X-Amz-Date", valid_21626124
  var valid_21626125 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626125 = validateParameter(valid_21626125, JString, required = false,
                                   default = nil)
  if valid_21626125 != nil:
    section.add "X-Amz-Security-Token", valid_21626125
  var valid_21626126 = header.getOrDefault("X-Amz-Target")
  valid_21626126 = validateParameter(valid_21626126, JString, required = true, default = newJString(
      "StorageGateway_20130630.CancelArchival"))
  if valid_21626126 != nil:
    section.add "X-Amz-Target", valid_21626126
  var valid_21626127 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626127 = validateParameter(valid_21626127, JString, required = false,
                                   default = nil)
  if valid_21626127 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626127
  var valid_21626128 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626128 = validateParameter(valid_21626128, JString, required = false,
                                   default = nil)
  if valid_21626128 != nil:
    section.add "X-Amz-Algorithm", valid_21626128
  var valid_21626129 = header.getOrDefault("X-Amz-Signature")
  valid_21626129 = validateParameter(valid_21626129, JString, required = false,
                                   default = nil)
  if valid_21626129 != nil:
    section.add "X-Amz-Signature", valid_21626129
  var valid_21626130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626130 = validateParameter(valid_21626130, JString, required = false,
                                   default = nil)
  if valid_21626130 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626130
  var valid_21626131 = header.getOrDefault("X-Amz-Credential")
  valid_21626131 = validateParameter(valid_21626131, JString, required = false,
                                   default = nil)
  if valid_21626131 != nil:
    section.add "X-Amz-Credential", valid_21626131
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626133: Call_CancelArchival_21626121; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Cancels archiving of a virtual tape to the virtual tape shelf (VTS) after the archiving process is initiated. This operation is only supported in the tape gateway type.
  ## 
  let valid = call_21626133.validator(path, query, header, formData, body, _)
  let scheme = call_21626133.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626133.makeUrl(scheme.get, call_21626133.host, call_21626133.base,
                               call_21626133.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626133, uri, valid, _)

proc call*(call_21626134: Call_CancelArchival_21626121; body: JsonNode): Recallable =
  ## cancelArchival
  ## Cancels archiving of a virtual tape to the virtual tape shelf (VTS) after the archiving process is initiated. This operation is only supported in the tape gateway type.
  ##   body: JObject (required)
  var body_21626135 = newJObject()
  if body != nil:
    body_21626135 = body
  result = call_21626134.call(nil, nil, nil, nil, body_21626135)

var cancelArchival* = Call_CancelArchival_21626121(name: "cancelArchival",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.CancelArchival",
    validator: validate_CancelArchival_21626122, base: "/",
    makeUrl: url_CancelArchival_21626123, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelRetrieval_21626136 = ref object of OpenApiRestCall_21625437
proc url_CancelRetrieval_21626138(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CancelRetrieval_21626137(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Cancels retrieval of a virtual tape from the virtual tape shelf (VTS) to a gateway after the retrieval process is initiated. The virtual tape is returned to the VTS. This operation is only supported in the tape gateway type.
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
  var valid_21626139 = header.getOrDefault("X-Amz-Date")
  valid_21626139 = validateParameter(valid_21626139, JString, required = false,
                                   default = nil)
  if valid_21626139 != nil:
    section.add "X-Amz-Date", valid_21626139
  var valid_21626140 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626140 = validateParameter(valid_21626140, JString, required = false,
                                   default = nil)
  if valid_21626140 != nil:
    section.add "X-Amz-Security-Token", valid_21626140
  var valid_21626141 = header.getOrDefault("X-Amz-Target")
  valid_21626141 = validateParameter(valid_21626141, JString, required = true, default = newJString(
      "StorageGateway_20130630.CancelRetrieval"))
  if valid_21626141 != nil:
    section.add "X-Amz-Target", valid_21626141
  var valid_21626142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626142 = validateParameter(valid_21626142, JString, required = false,
                                   default = nil)
  if valid_21626142 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626142
  var valid_21626143 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626143 = validateParameter(valid_21626143, JString, required = false,
                                   default = nil)
  if valid_21626143 != nil:
    section.add "X-Amz-Algorithm", valid_21626143
  var valid_21626144 = header.getOrDefault("X-Amz-Signature")
  valid_21626144 = validateParameter(valid_21626144, JString, required = false,
                                   default = nil)
  if valid_21626144 != nil:
    section.add "X-Amz-Signature", valid_21626144
  var valid_21626145 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626145 = validateParameter(valid_21626145, JString, required = false,
                                   default = nil)
  if valid_21626145 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626145
  var valid_21626146 = header.getOrDefault("X-Amz-Credential")
  valid_21626146 = validateParameter(valid_21626146, JString, required = false,
                                   default = nil)
  if valid_21626146 != nil:
    section.add "X-Amz-Credential", valid_21626146
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626148: Call_CancelRetrieval_21626136; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Cancels retrieval of a virtual tape from the virtual tape shelf (VTS) to a gateway after the retrieval process is initiated. The virtual tape is returned to the VTS. This operation is only supported in the tape gateway type.
  ## 
  let valid = call_21626148.validator(path, query, header, formData, body, _)
  let scheme = call_21626148.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626148.makeUrl(scheme.get, call_21626148.host, call_21626148.base,
                               call_21626148.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626148, uri, valid, _)

proc call*(call_21626149: Call_CancelRetrieval_21626136; body: JsonNode): Recallable =
  ## cancelRetrieval
  ## Cancels retrieval of a virtual tape from the virtual tape shelf (VTS) to a gateway after the retrieval process is initiated. The virtual tape is returned to the VTS. This operation is only supported in the tape gateway type.
  ##   body: JObject (required)
  var body_21626150 = newJObject()
  if body != nil:
    body_21626150 = body
  result = call_21626149.call(nil, nil, nil, nil, body_21626150)

var cancelRetrieval* = Call_CancelRetrieval_21626136(name: "cancelRetrieval",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.CancelRetrieval",
    validator: validate_CancelRetrieval_21626137, base: "/",
    makeUrl: url_CancelRetrieval_21626138, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCachediSCSIVolume_21626151 = ref object of OpenApiRestCall_21625437
proc url_CreateCachediSCSIVolume_21626153(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateCachediSCSIVolume_21626152(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a cached volume on a specified cached volume gateway. This operation is only supported in the cached volume gateway type.</p> <note> <p>Cache storage must be allocated to the gateway before you can create a cached volume. Use the <a>AddCache</a> operation to add cache storage to a gateway. </p> </note> <p>In the request, you must specify the gateway, size of the volume in bytes, the iSCSI target name, an IP address on which to expose the target, and a unique client token. In response, the gateway creates the volume and returns information about it. This information includes the volume Amazon Resource Name (ARN), its size, and the iSCSI target ARN that initiators can use to connect to the volume target.</p> <p>Optionally, you can provide the ARN for an existing volume as the <code>SourceVolumeARN</code> for this cached volume, which creates an exact copy of the existing volume’s latest recovery point. The <code>VolumeSizeInBytes</code> value must be equal to or larger than the size of the copied volume, in bytes.</p>
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
  var valid_21626154 = header.getOrDefault("X-Amz-Date")
  valid_21626154 = validateParameter(valid_21626154, JString, required = false,
                                   default = nil)
  if valid_21626154 != nil:
    section.add "X-Amz-Date", valid_21626154
  var valid_21626155 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626155 = validateParameter(valid_21626155, JString, required = false,
                                   default = nil)
  if valid_21626155 != nil:
    section.add "X-Amz-Security-Token", valid_21626155
  var valid_21626156 = header.getOrDefault("X-Amz-Target")
  valid_21626156 = validateParameter(valid_21626156, JString, required = true, default = newJString(
      "StorageGateway_20130630.CreateCachediSCSIVolume"))
  if valid_21626156 != nil:
    section.add "X-Amz-Target", valid_21626156
  var valid_21626157 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626157 = validateParameter(valid_21626157, JString, required = false,
                                   default = nil)
  if valid_21626157 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626157
  var valid_21626158 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626158 = validateParameter(valid_21626158, JString, required = false,
                                   default = nil)
  if valid_21626158 != nil:
    section.add "X-Amz-Algorithm", valid_21626158
  var valid_21626159 = header.getOrDefault("X-Amz-Signature")
  valid_21626159 = validateParameter(valid_21626159, JString, required = false,
                                   default = nil)
  if valid_21626159 != nil:
    section.add "X-Amz-Signature", valid_21626159
  var valid_21626160 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626160 = validateParameter(valid_21626160, JString, required = false,
                                   default = nil)
  if valid_21626160 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626160
  var valid_21626161 = header.getOrDefault("X-Amz-Credential")
  valid_21626161 = validateParameter(valid_21626161, JString, required = false,
                                   default = nil)
  if valid_21626161 != nil:
    section.add "X-Amz-Credential", valid_21626161
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626163: Call_CreateCachediSCSIVolume_21626151;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a cached volume on a specified cached volume gateway. This operation is only supported in the cached volume gateway type.</p> <note> <p>Cache storage must be allocated to the gateway before you can create a cached volume. Use the <a>AddCache</a> operation to add cache storage to a gateway. </p> </note> <p>In the request, you must specify the gateway, size of the volume in bytes, the iSCSI target name, an IP address on which to expose the target, and a unique client token. In response, the gateway creates the volume and returns information about it. This information includes the volume Amazon Resource Name (ARN), its size, and the iSCSI target ARN that initiators can use to connect to the volume target.</p> <p>Optionally, you can provide the ARN for an existing volume as the <code>SourceVolumeARN</code> for this cached volume, which creates an exact copy of the existing volume’s latest recovery point. The <code>VolumeSizeInBytes</code> value must be equal to or larger than the size of the copied volume, in bytes.</p>
  ## 
  let valid = call_21626163.validator(path, query, header, formData, body, _)
  let scheme = call_21626163.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626163.makeUrl(scheme.get, call_21626163.host, call_21626163.base,
                               call_21626163.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626163, uri, valid, _)

proc call*(call_21626164: Call_CreateCachediSCSIVolume_21626151; body: JsonNode): Recallable =
  ## createCachediSCSIVolume
  ## <p>Creates a cached volume on a specified cached volume gateway. This operation is only supported in the cached volume gateway type.</p> <note> <p>Cache storage must be allocated to the gateway before you can create a cached volume. Use the <a>AddCache</a> operation to add cache storage to a gateway. </p> </note> <p>In the request, you must specify the gateway, size of the volume in bytes, the iSCSI target name, an IP address on which to expose the target, and a unique client token. In response, the gateway creates the volume and returns information about it. This information includes the volume Amazon Resource Name (ARN), its size, and the iSCSI target ARN that initiators can use to connect to the volume target.</p> <p>Optionally, you can provide the ARN for an existing volume as the <code>SourceVolumeARN</code> for this cached volume, which creates an exact copy of the existing volume’s latest recovery point. The <code>VolumeSizeInBytes</code> value must be equal to or larger than the size of the copied volume, in bytes.</p>
  ##   body: JObject (required)
  var body_21626165 = newJObject()
  if body != nil:
    body_21626165 = body
  result = call_21626164.call(nil, nil, nil, nil, body_21626165)

var createCachediSCSIVolume* = Call_CreateCachediSCSIVolume_21626151(
    name: "createCachediSCSIVolume", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.CreateCachediSCSIVolume",
    validator: validate_CreateCachediSCSIVolume_21626152, base: "/",
    makeUrl: url_CreateCachediSCSIVolume_21626153,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNFSFileShare_21626166 = ref object of OpenApiRestCall_21625437
proc url_CreateNFSFileShare_21626168(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateNFSFileShare_21626167(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a Network File System (NFS) file share on an existing file gateway. In Storage Gateway, a file share is a file system mount point backed by Amazon S3 cloud storage. Storage Gateway exposes file shares using a NFS interface. This operation is only supported for file gateways.</p> <important> <p>File gateway requires AWS Security Token Service (AWS STS) to be activated to enable you create a file share. Make sure AWS STS is activated in the AWS Region you are creating your file gateway in. If AWS STS is not activated in the AWS Region, activate it. For information about how to activate AWS STS, see Activating and Deactivating AWS STS in an AWS Region in the AWS Identity and Access Management User Guide. </p> <p>File gateway does not support creating hard or symbolic links on a file share.</p> </important>
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
  var valid_21626169 = header.getOrDefault("X-Amz-Date")
  valid_21626169 = validateParameter(valid_21626169, JString, required = false,
                                   default = nil)
  if valid_21626169 != nil:
    section.add "X-Amz-Date", valid_21626169
  var valid_21626170 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626170 = validateParameter(valid_21626170, JString, required = false,
                                   default = nil)
  if valid_21626170 != nil:
    section.add "X-Amz-Security-Token", valid_21626170
  var valid_21626171 = header.getOrDefault("X-Amz-Target")
  valid_21626171 = validateParameter(valid_21626171, JString, required = true, default = newJString(
      "StorageGateway_20130630.CreateNFSFileShare"))
  if valid_21626171 != nil:
    section.add "X-Amz-Target", valid_21626171
  var valid_21626172 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626172 = validateParameter(valid_21626172, JString, required = false,
                                   default = nil)
  if valid_21626172 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626172
  var valid_21626173 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626173 = validateParameter(valid_21626173, JString, required = false,
                                   default = nil)
  if valid_21626173 != nil:
    section.add "X-Amz-Algorithm", valid_21626173
  var valid_21626174 = header.getOrDefault("X-Amz-Signature")
  valid_21626174 = validateParameter(valid_21626174, JString, required = false,
                                   default = nil)
  if valid_21626174 != nil:
    section.add "X-Amz-Signature", valid_21626174
  var valid_21626175 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626175 = validateParameter(valid_21626175, JString, required = false,
                                   default = nil)
  if valid_21626175 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626175
  var valid_21626176 = header.getOrDefault("X-Amz-Credential")
  valid_21626176 = validateParameter(valid_21626176, JString, required = false,
                                   default = nil)
  if valid_21626176 != nil:
    section.add "X-Amz-Credential", valid_21626176
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626178: Call_CreateNFSFileShare_21626166; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a Network File System (NFS) file share on an existing file gateway. In Storage Gateway, a file share is a file system mount point backed by Amazon S3 cloud storage. Storage Gateway exposes file shares using a NFS interface. This operation is only supported for file gateways.</p> <important> <p>File gateway requires AWS Security Token Service (AWS STS) to be activated to enable you create a file share. Make sure AWS STS is activated in the AWS Region you are creating your file gateway in. If AWS STS is not activated in the AWS Region, activate it. For information about how to activate AWS STS, see Activating and Deactivating AWS STS in an AWS Region in the AWS Identity and Access Management User Guide. </p> <p>File gateway does not support creating hard or symbolic links on a file share.</p> </important>
  ## 
  let valid = call_21626178.validator(path, query, header, formData, body, _)
  let scheme = call_21626178.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626178.makeUrl(scheme.get, call_21626178.host, call_21626178.base,
                               call_21626178.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626178, uri, valid, _)

proc call*(call_21626179: Call_CreateNFSFileShare_21626166; body: JsonNode): Recallable =
  ## createNFSFileShare
  ## <p>Creates a Network File System (NFS) file share on an existing file gateway. In Storage Gateway, a file share is a file system mount point backed by Amazon S3 cloud storage. Storage Gateway exposes file shares using a NFS interface. This operation is only supported for file gateways.</p> <important> <p>File gateway requires AWS Security Token Service (AWS STS) to be activated to enable you create a file share. Make sure AWS STS is activated in the AWS Region you are creating your file gateway in. If AWS STS is not activated in the AWS Region, activate it. For information about how to activate AWS STS, see Activating and Deactivating AWS STS in an AWS Region in the AWS Identity and Access Management User Guide. </p> <p>File gateway does not support creating hard or symbolic links on a file share.</p> </important>
  ##   body: JObject (required)
  var body_21626180 = newJObject()
  if body != nil:
    body_21626180 = body
  result = call_21626179.call(nil, nil, nil, nil, body_21626180)

var createNFSFileShare* = Call_CreateNFSFileShare_21626166(
    name: "createNFSFileShare", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.CreateNFSFileShare",
    validator: validate_CreateNFSFileShare_21626167, base: "/",
    makeUrl: url_CreateNFSFileShare_21626168, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSMBFileShare_21626181 = ref object of OpenApiRestCall_21625437
proc url_CreateSMBFileShare_21626183(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateSMBFileShare_21626182(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a Server Message Block (SMB) file share on an existing file gateway. In Storage Gateway, a file share is a file system mount point backed by Amazon S3 cloud storage. Storage Gateway expose file shares using a SMB interface. This operation is only supported for file gateways.</p> <important> <p>File gateways require AWS Security Token Service (AWS STS) to be activated to enable you to create a file share. Make sure that AWS STS is activated in the AWS Region you are creating your file gateway in. If AWS STS is not activated in this AWS Region, activate it. For information about how to activate AWS STS, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_enable-regions.html">Activating and Deactivating AWS STS in an AWS Region</a> in the <i>AWS Identity and Access Management User Guide.</i> </p> <p>File gateways don't support creating hard or symbolic links on a file share.</p> </important>
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
  var valid_21626184 = header.getOrDefault("X-Amz-Date")
  valid_21626184 = validateParameter(valid_21626184, JString, required = false,
                                   default = nil)
  if valid_21626184 != nil:
    section.add "X-Amz-Date", valid_21626184
  var valid_21626185 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626185 = validateParameter(valid_21626185, JString, required = false,
                                   default = nil)
  if valid_21626185 != nil:
    section.add "X-Amz-Security-Token", valid_21626185
  var valid_21626186 = header.getOrDefault("X-Amz-Target")
  valid_21626186 = validateParameter(valid_21626186, JString, required = true, default = newJString(
      "StorageGateway_20130630.CreateSMBFileShare"))
  if valid_21626186 != nil:
    section.add "X-Amz-Target", valid_21626186
  var valid_21626187 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626187 = validateParameter(valid_21626187, JString, required = false,
                                   default = nil)
  if valid_21626187 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626187
  var valid_21626188 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626188 = validateParameter(valid_21626188, JString, required = false,
                                   default = nil)
  if valid_21626188 != nil:
    section.add "X-Amz-Algorithm", valid_21626188
  var valid_21626189 = header.getOrDefault("X-Amz-Signature")
  valid_21626189 = validateParameter(valid_21626189, JString, required = false,
                                   default = nil)
  if valid_21626189 != nil:
    section.add "X-Amz-Signature", valid_21626189
  var valid_21626190 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626190 = validateParameter(valid_21626190, JString, required = false,
                                   default = nil)
  if valid_21626190 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626190
  var valid_21626191 = header.getOrDefault("X-Amz-Credential")
  valid_21626191 = validateParameter(valid_21626191, JString, required = false,
                                   default = nil)
  if valid_21626191 != nil:
    section.add "X-Amz-Credential", valid_21626191
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626193: Call_CreateSMBFileShare_21626181; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a Server Message Block (SMB) file share on an existing file gateway. In Storage Gateway, a file share is a file system mount point backed by Amazon S3 cloud storage. Storage Gateway expose file shares using a SMB interface. This operation is only supported for file gateways.</p> <important> <p>File gateways require AWS Security Token Service (AWS STS) to be activated to enable you to create a file share. Make sure that AWS STS is activated in the AWS Region you are creating your file gateway in. If AWS STS is not activated in this AWS Region, activate it. For information about how to activate AWS STS, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_enable-regions.html">Activating and Deactivating AWS STS in an AWS Region</a> in the <i>AWS Identity and Access Management User Guide.</i> </p> <p>File gateways don't support creating hard or symbolic links on a file share.</p> </important>
  ## 
  let valid = call_21626193.validator(path, query, header, formData, body, _)
  let scheme = call_21626193.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626193.makeUrl(scheme.get, call_21626193.host, call_21626193.base,
                               call_21626193.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626193, uri, valid, _)

proc call*(call_21626194: Call_CreateSMBFileShare_21626181; body: JsonNode): Recallable =
  ## createSMBFileShare
  ## <p>Creates a Server Message Block (SMB) file share on an existing file gateway. In Storage Gateway, a file share is a file system mount point backed by Amazon S3 cloud storage. Storage Gateway expose file shares using a SMB interface. This operation is only supported for file gateways.</p> <important> <p>File gateways require AWS Security Token Service (AWS STS) to be activated to enable you to create a file share. Make sure that AWS STS is activated in the AWS Region you are creating your file gateway in. If AWS STS is not activated in this AWS Region, activate it. For information about how to activate AWS STS, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_enable-regions.html">Activating and Deactivating AWS STS in an AWS Region</a> in the <i>AWS Identity and Access Management User Guide.</i> </p> <p>File gateways don't support creating hard or symbolic links on a file share.</p> </important>
  ##   body: JObject (required)
  var body_21626195 = newJObject()
  if body != nil:
    body_21626195 = body
  result = call_21626194.call(nil, nil, nil, nil, body_21626195)

var createSMBFileShare* = Call_CreateSMBFileShare_21626181(
    name: "createSMBFileShare", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.CreateSMBFileShare",
    validator: validate_CreateSMBFileShare_21626182, base: "/",
    makeUrl: url_CreateSMBFileShare_21626183, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSnapshot_21626196 = ref object of OpenApiRestCall_21625437
proc url_CreateSnapshot_21626198(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateSnapshot_21626197(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Initiates a snapshot of a volume.</p> <p>AWS Storage Gateway provides the ability to back up point-in-time snapshots of your data to Amazon Simple Storage (S3) for durable off-site recovery, as well as import the data to an Amazon Elastic Block Store (EBS) volume in Amazon Elastic Compute Cloud (EC2). You can take snapshots of your gateway volume on a scheduled or ad hoc basis. This API enables you to take ad-hoc snapshot. For more information, see <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/managing-volumes.html#SchedulingSnapshot">Editing a Snapshot Schedule</a>.</p> <p>In the CreateSnapshot request you identify the volume by providing its Amazon Resource Name (ARN). You must also provide description for the snapshot. When AWS Storage Gateway takes the snapshot of specified volume, the snapshot and description appears in the AWS Storage Gateway Console. In response, AWS Storage Gateway returns you a snapshot ID. You can use this snapshot ID to check the snapshot progress or later use it when you want to create a volume from a snapshot. This operation is only supported in stored and cached volume gateway type.</p> <note> <p>To list or delete a snapshot, you must use the Amazon EC2 API. For more information, see DescribeSnapshots or DeleteSnapshot in the <a href="https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_Operations.html">EC2 API reference</a>.</p> </note> <important> <p>Volume and snapshot IDs are changing to a longer length ID format. For more information, see the important note on the <a href="https://docs.aws.amazon.com/storagegateway/latest/APIReference/Welcome.html">Welcome</a> page.</p> </important>
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
  var valid_21626199 = header.getOrDefault("X-Amz-Date")
  valid_21626199 = validateParameter(valid_21626199, JString, required = false,
                                   default = nil)
  if valid_21626199 != nil:
    section.add "X-Amz-Date", valid_21626199
  var valid_21626200 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626200 = validateParameter(valid_21626200, JString, required = false,
                                   default = nil)
  if valid_21626200 != nil:
    section.add "X-Amz-Security-Token", valid_21626200
  var valid_21626201 = header.getOrDefault("X-Amz-Target")
  valid_21626201 = validateParameter(valid_21626201, JString, required = true, default = newJString(
      "StorageGateway_20130630.CreateSnapshot"))
  if valid_21626201 != nil:
    section.add "X-Amz-Target", valid_21626201
  var valid_21626202 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626202 = validateParameter(valid_21626202, JString, required = false,
                                   default = nil)
  if valid_21626202 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626202
  var valid_21626203 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626203 = validateParameter(valid_21626203, JString, required = false,
                                   default = nil)
  if valid_21626203 != nil:
    section.add "X-Amz-Algorithm", valid_21626203
  var valid_21626204 = header.getOrDefault("X-Amz-Signature")
  valid_21626204 = validateParameter(valid_21626204, JString, required = false,
                                   default = nil)
  if valid_21626204 != nil:
    section.add "X-Amz-Signature", valid_21626204
  var valid_21626205 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626205 = validateParameter(valid_21626205, JString, required = false,
                                   default = nil)
  if valid_21626205 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626205
  var valid_21626206 = header.getOrDefault("X-Amz-Credential")
  valid_21626206 = validateParameter(valid_21626206, JString, required = false,
                                   default = nil)
  if valid_21626206 != nil:
    section.add "X-Amz-Credential", valid_21626206
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626208: Call_CreateSnapshot_21626196; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Initiates a snapshot of a volume.</p> <p>AWS Storage Gateway provides the ability to back up point-in-time snapshots of your data to Amazon Simple Storage (S3) for durable off-site recovery, as well as import the data to an Amazon Elastic Block Store (EBS) volume in Amazon Elastic Compute Cloud (EC2). You can take snapshots of your gateway volume on a scheduled or ad hoc basis. This API enables you to take ad-hoc snapshot. For more information, see <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/managing-volumes.html#SchedulingSnapshot">Editing a Snapshot Schedule</a>.</p> <p>In the CreateSnapshot request you identify the volume by providing its Amazon Resource Name (ARN). You must also provide description for the snapshot. When AWS Storage Gateway takes the snapshot of specified volume, the snapshot and description appears in the AWS Storage Gateway Console. In response, AWS Storage Gateway returns you a snapshot ID. You can use this snapshot ID to check the snapshot progress or later use it when you want to create a volume from a snapshot. This operation is only supported in stored and cached volume gateway type.</p> <note> <p>To list or delete a snapshot, you must use the Amazon EC2 API. For more information, see DescribeSnapshots or DeleteSnapshot in the <a href="https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_Operations.html">EC2 API reference</a>.</p> </note> <important> <p>Volume and snapshot IDs are changing to a longer length ID format. For more information, see the important note on the <a href="https://docs.aws.amazon.com/storagegateway/latest/APIReference/Welcome.html">Welcome</a> page.</p> </important>
  ## 
  let valid = call_21626208.validator(path, query, header, formData, body, _)
  let scheme = call_21626208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626208.makeUrl(scheme.get, call_21626208.host, call_21626208.base,
                               call_21626208.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626208, uri, valid, _)

proc call*(call_21626209: Call_CreateSnapshot_21626196; body: JsonNode): Recallable =
  ## createSnapshot
  ## <p>Initiates a snapshot of a volume.</p> <p>AWS Storage Gateway provides the ability to back up point-in-time snapshots of your data to Amazon Simple Storage (S3) for durable off-site recovery, as well as import the data to an Amazon Elastic Block Store (EBS) volume in Amazon Elastic Compute Cloud (EC2). You can take snapshots of your gateway volume on a scheduled or ad hoc basis. This API enables you to take ad-hoc snapshot. For more information, see <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/managing-volumes.html#SchedulingSnapshot">Editing a Snapshot Schedule</a>.</p> <p>In the CreateSnapshot request you identify the volume by providing its Amazon Resource Name (ARN). You must also provide description for the snapshot. When AWS Storage Gateway takes the snapshot of specified volume, the snapshot and description appears in the AWS Storage Gateway Console. In response, AWS Storage Gateway returns you a snapshot ID. You can use this snapshot ID to check the snapshot progress or later use it when you want to create a volume from a snapshot. This operation is only supported in stored and cached volume gateway type.</p> <note> <p>To list or delete a snapshot, you must use the Amazon EC2 API. For more information, see DescribeSnapshots or DeleteSnapshot in the <a href="https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_Operations.html">EC2 API reference</a>.</p> </note> <important> <p>Volume and snapshot IDs are changing to a longer length ID format. For more information, see the important note on the <a href="https://docs.aws.amazon.com/storagegateway/latest/APIReference/Welcome.html">Welcome</a> page.</p> </important>
  ##   body: JObject (required)
  var body_21626210 = newJObject()
  if body != nil:
    body_21626210 = body
  result = call_21626209.call(nil, nil, nil, nil, body_21626210)

var createSnapshot* = Call_CreateSnapshot_21626196(name: "createSnapshot",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.CreateSnapshot",
    validator: validate_CreateSnapshot_21626197, base: "/",
    makeUrl: url_CreateSnapshot_21626198, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSnapshotFromVolumeRecoveryPoint_21626211 = ref object of OpenApiRestCall_21625437
proc url_CreateSnapshotFromVolumeRecoveryPoint_21626213(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateSnapshotFromVolumeRecoveryPoint_21626212(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Initiates a snapshot of a gateway from a volume recovery point. This operation is only supported in the cached volume gateway type.</p> <p>A volume recovery point is a point in time at which all data of the volume is consistent and from which you can create a snapshot. To get a list of volume recovery point for cached volume gateway, use <a>ListVolumeRecoveryPoints</a>.</p> <p>In the <code>CreateSnapshotFromVolumeRecoveryPoint</code> request, you identify the volume by providing its Amazon Resource Name (ARN). You must also provide a description for the snapshot. When the gateway takes a snapshot of the specified volume, the snapshot and its description appear in the AWS Storage Gateway console. In response, the gateway returns you a snapshot ID. You can use this snapshot ID to check the snapshot progress or later use it when you want to create a volume from a snapshot.</p> <note> <p>To list or delete a snapshot, you must use the Amazon EC2 API. For more information, in <i>Amazon Elastic Compute Cloud API Reference</i>.</p> </note>
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
  var valid_21626214 = header.getOrDefault("X-Amz-Date")
  valid_21626214 = validateParameter(valid_21626214, JString, required = false,
                                   default = nil)
  if valid_21626214 != nil:
    section.add "X-Amz-Date", valid_21626214
  var valid_21626215 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626215 = validateParameter(valid_21626215, JString, required = false,
                                   default = nil)
  if valid_21626215 != nil:
    section.add "X-Amz-Security-Token", valid_21626215
  var valid_21626216 = header.getOrDefault("X-Amz-Target")
  valid_21626216 = validateParameter(valid_21626216, JString, required = true, default = newJString(
      "StorageGateway_20130630.CreateSnapshotFromVolumeRecoveryPoint"))
  if valid_21626216 != nil:
    section.add "X-Amz-Target", valid_21626216
  var valid_21626217 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626217 = validateParameter(valid_21626217, JString, required = false,
                                   default = nil)
  if valid_21626217 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626217
  var valid_21626218 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626218 = validateParameter(valid_21626218, JString, required = false,
                                   default = nil)
  if valid_21626218 != nil:
    section.add "X-Amz-Algorithm", valid_21626218
  var valid_21626219 = header.getOrDefault("X-Amz-Signature")
  valid_21626219 = validateParameter(valid_21626219, JString, required = false,
                                   default = nil)
  if valid_21626219 != nil:
    section.add "X-Amz-Signature", valid_21626219
  var valid_21626220 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626220 = validateParameter(valid_21626220, JString, required = false,
                                   default = nil)
  if valid_21626220 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626220
  var valid_21626221 = header.getOrDefault("X-Amz-Credential")
  valid_21626221 = validateParameter(valid_21626221, JString, required = false,
                                   default = nil)
  if valid_21626221 != nil:
    section.add "X-Amz-Credential", valid_21626221
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626223: Call_CreateSnapshotFromVolumeRecoveryPoint_21626211;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Initiates a snapshot of a gateway from a volume recovery point. This operation is only supported in the cached volume gateway type.</p> <p>A volume recovery point is a point in time at which all data of the volume is consistent and from which you can create a snapshot. To get a list of volume recovery point for cached volume gateway, use <a>ListVolumeRecoveryPoints</a>.</p> <p>In the <code>CreateSnapshotFromVolumeRecoveryPoint</code> request, you identify the volume by providing its Amazon Resource Name (ARN). You must also provide a description for the snapshot. When the gateway takes a snapshot of the specified volume, the snapshot and its description appear in the AWS Storage Gateway console. In response, the gateway returns you a snapshot ID. You can use this snapshot ID to check the snapshot progress or later use it when you want to create a volume from a snapshot.</p> <note> <p>To list or delete a snapshot, you must use the Amazon EC2 API. For more information, in <i>Amazon Elastic Compute Cloud API Reference</i>.</p> </note>
  ## 
  let valid = call_21626223.validator(path, query, header, formData, body, _)
  let scheme = call_21626223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626223.makeUrl(scheme.get, call_21626223.host, call_21626223.base,
                               call_21626223.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626223, uri, valid, _)

proc call*(call_21626224: Call_CreateSnapshotFromVolumeRecoveryPoint_21626211;
          body: JsonNode): Recallable =
  ## createSnapshotFromVolumeRecoveryPoint
  ## <p>Initiates a snapshot of a gateway from a volume recovery point. This operation is only supported in the cached volume gateway type.</p> <p>A volume recovery point is a point in time at which all data of the volume is consistent and from which you can create a snapshot. To get a list of volume recovery point for cached volume gateway, use <a>ListVolumeRecoveryPoints</a>.</p> <p>In the <code>CreateSnapshotFromVolumeRecoveryPoint</code> request, you identify the volume by providing its Amazon Resource Name (ARN). You must also provide a description for the snapshot. When the gateway takes a snapshot of the specified volume, the snapshot and its description appear in the AWS Storage Gateway console. In response, the gateway returns you a snapshot ID. You can use this snapshot ID to check the snapshot progress or later use it when you want to create a volume from a snapshot.</p> <note> <p>To list or delete a snapshot, you must use the Amazon EC2 API. For more information, in <i>Amazon Elastic Compute Cloud API Reference</i>.</p> </note>
  ##   body: JObject (required)
  var body_21626225 = newJObject()
  if body != nil:
    body_21626225 = body
  result = call_21626224.call(nil, nil, nil, nil, body_21626225)

var createSnapshotFromVolumeRecoveryPoint* = Call_CreateSnapshotFromVolumeRecoveryPoint_21626211(
    name: "createSnapshotFromVolumeRecoveryPoint", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com", route: "/#X-Amz-Target=StorageGateway_20130630.CreateSnapshotFromVolumeRecoveryPoint",
    validator: validate_CreateSnapshotFromVolumeRecoveryPoint_21626212, base: "/",
    makeUrl: url_CreateSnapshotFromVolumeRecoveryPoint_21626213,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStorediSCSIVolume_21626226 = ref object of OpenApiRestCall_21625437
proc url_CreateStorediSCSIVolume_21626228(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateStorediSCSIVolume_21626227(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a volume on a specified gateway. This operation is only supported in the stored volume gateway type.</p> <p>The size of the volume to create is inferred from the disk size. You can choose to preserve existing data on the disk, create volume from an existing snapshot, or create an empty volume. If you choose to create an empty gateway volume, then any existing data on the disk is erased.</p> <p>In the request you must specify the gateway and the disk information on which you are creating the volume. In response, the gateway creates the volume and returns volume information such as the volume Amazon Resource Name (ARN), its size, and the iSCSI target ARN that initiators can use to connect to the volume target.</p>
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
  var valid_21626229 = header.getOrDefault("X-Amz-Date")
  valid_21626229 = validateParameter(valid_21626229, JString, required = false,
                                   default = nil)
  if valid_21626229 != nil:
    section.add "X-Amz-Date", valid_21626229
  var valid_21626230 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626230 = validateParameter(valid_21626230, JString, required = false,
                                   default = nil)
  if valid_21626230 != nil:
    section.add "X-Amz-Security-Token", valid_21626230
  var valid_21626231 = header.getOrDefault("X-Amz-Target")
  valid_21626231 = validateParameter(valid_21626231, JString, required = true, default = newJString(
      "StorageGateway_20130630.CreateStorediSCSIVolume"))
  if valid_21626231 != nil:
    section.add "X-Amz-Target", valid_21626231
  var valid_21626232 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626232 = validateParameter(valid_21626232, JString, required = false,
                                   default = nil)
  if valid_21626232 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626232
  var valid_21626233 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626233 = validateParameter(valid_21626233, JString, required = false,
                                   default = nil)
  if valid_21626233 != nil:
    section.add "X-Amz-Algorithm", valid_21626233
  var valid_21626234 = header.getOrDefault("X-Amz-Signature")
  valid_21626234 = validateParameter(valid_21626234, JString, required = false,
                                   default = nil)
  if valid_21626234 != nil:
    section.add "X-Amz-Signature", valid_21626234
  var valid_21626235 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626235 = validateParameter(valid_21626235, JString, required = false,
                                   default = nil)
  if valid_21626235 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626235
  var valid_21626236 = header.getOrDefault("X-Amz-Credential")
  valid_21626236 = validateParameter(valid_21626236, JString, required = false,
                                   default = nil)
  if valid_21626236 != nil:
    section.add "X-Amz-Credential", valid_21626236
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626238: Call_CreateStorediSCSIVolume_21626226;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a volume on a specified gateway. This operation is only supported in the stored volume gateway type.</p> <p>The size of the volume to create is inferred from the disk size. You can choose to preserve existing data on the disk, create volume from an existing snapshot, or create an empty volume. If you choose to create an empty gateway volume, then any existing data on the disk is erased.</p> <p>In the request you must specify the gateway and the disk information on which you are creating the volume. In response, the gateway creates the volume and returns volume information such as the volume Amazon Resource Name (ARN), its size, and the iSCSI target ARN that initiators can use to connect to the volume target.</p>
  ## 
  let valid = call_21626238.validator(path, query, header, formData, body, _)
  let scheme = call_21626238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626238.makeUrl(scheme.get, call_21626238.host, call_21626238.base,
                               call_21626238.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626238, uri, valid, _)

proc call*(call_21626239: Call_CreateStorediSCSIVolume_21626226; body: JsonNode): Recallable =
  ## createStorediSCSIVolume
  ## <p>Creates a volume on a specified gateway. This operation is only supported in the stored volume gateway type.</p> <p>The size of the volume to create is inferred from the disk size. You can choose to preserve existing data on the disk, create volume from an existing snapshot, or create an empty volume. If you choose to create an empty gateway volume, then any existing data on the disk is erased.</p> <p>In the request you must specify the gateway and the disk information on which you are creating the volume. In response, the gateway creates the volume and returns volume information such as the volume Amazon Resource Name (ARN), its size, and the iSCSI target ARN that initiators can use to connect to the volume target.</p>
  ##   body: JObject (required)
  var body_21626240 = newJObject()
  if body != nil:
    body_21626240 = body
  result = call_21626239.call(nil, nil, nil, nil, body_21626240)

var createStorediSCSIVolume* = Call_CreateStorediSCSIVolume_21626226(
    name: "createStorediSCSIVolume", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.CreateStorediSCSIVolume",
    validator: validate_CreateStorediSCSIVolume_21626227, base: "/",
    makeUrl: url_CreateStorediSCSIVolume_21626228,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTapeWithBarcode_21626241 = ref object of OpenApiRestCall_21625437
proc url_CreateTapeWithBarcode_21626243(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTapeWithBarcode_21626242(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a virtual tape by using your own barcode. You write data to the virtual tape and then archive the tape. A barcode is unique and can not be reused if it has already been used on a tape . This applies to barcodes used on deleted tapes. This operation is only supported in the tape gateway type.</p> <note> <p>Cache storage must be allocated to the gateway before you can create a virtual tape. Use the <a>AddCache</a> operation to add cache storage to a gateway.</p> </note>
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
  var valid_21626244 = header.getOrDefault("X-Amz-Date")
  valid_21626244 = validateParameter(valid_21626244, JString, required = false,
                                   default = nil)
  if valid_21626244 != nil:
    section.add "X-Amz-Date", valid_21626244
  var valid_21626245 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626245 = validateParameter(valid_21626245, JString, required = false,
                                   default = nil)
  if valid_21626245 != nil:
    section.add "X-Amz-Security-Token", valid_21626245
  var valid_21626246 = header.getOrDefault("X-Amz-Target")
  valid_21626246 = validateParameter(valid_21626246, JString, required = true, default = newJString(
      "StorageGateway_20130630.CreateTapeWithBarcode"))
  if valid_21626246 != nil:
    section.add "X-Amz-Target", valid_21626246
  var valid_21626247 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626247 = validateParameter(valid_21626247, JString, required = false,
                                   default = nil)
  if valid_21626247 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626247
  var valid_21626248 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626248 = validateParameter(valid_21626248, JString, required = false,
                                   default = nil)
  if valid_21626248 != nil:
    section.add "X-Amz-Algorithm", valid_21626248
  var valid_21626249 = header.getOrDefault("X-Amz-Signature")
  valid_21626249 = validateParameter(valid_21626249, JString, required = false,
                                   default = nil)
  if valid_21626249 != nil:
    section.add "X-Amz-Signature", valid_21626249
  var valid_21626250 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626250 = validateParameter(valid_21626250, JString, required = false,
                                   default = nil)
  if valid_21626250 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626250
  var valid_21626251 = header.getOrDefault("X-Amz-Credential")
  valid_21626251 = validateParameter(valid_21626251, JString, required = false,
                                   default = nil)
  if valid_21626251 != nil:
    section.add "X-Amz-Credential", valid_21626251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626253: Call_CreateTapeWithBarcode_21626241;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a virtual tape by using your own barcode. You write data to the virtual tape and then archive the tape. A barcode is unique and can not be reused if it has already been used on a tape . This applies to barcodes used on deleted tapes. This operation is only supported in the tape gateway type.</p> <note> <p>Cache storage must be allocated to the gateway before you can create a virtual tape. Use the <a>AddCache</a> operation to add cache storage to a gateway.</p> </note>
  ## 
  let valid = call_21626253.validator(path, query, header, formData, body, _)
  let scheme = call_21626253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626253.makeUrl(scheme.get, call_21626253.host, call_21626253.base,
                               call_21626253.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626253, uri, valid, _)

proc call*(call_21626254: Call_CreateTapeWithBarcode_21626241; body: JsonNode): Recallable =
  ## createTapeWithBarcode
  ## <p>Creates a virtual tape by using your own barcode. You write data to the virtual tape and then archive the tape. A barcode is unique and can not be reused if it has already been used on a tape . This applies to barcodes used on deleted tapes. This operation is only supported in the tape gateway type.</p> <note> <p>Cache storage must be allocated to the gateway before you can create a virtual tape. Use the <a>AddCache</a> operation to add cache storage to a gateway.</p> </note>
  ##   body: JObject (required)
  var body_21626255 = newJObject()
  if body != nil:
    body_21626255 = body
  result = call_21626254.call(nil, nil, nil, nil, body_21626255)

var createTapeWithBarcode* = Call_CreateTapeWithBarcode_21626241(
    name: "createTapeWithBarcode", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.CreateTapeWithBarcode",
    validator: validate_CreateTapeWithBarcode_21626242, base: "/",
    makeUrl: url_CreateTapeWithBarcode_21626243,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTapes_21626256 = ref object of OpenApiRestCall_21625437
proc url_CreateTapes_21626258(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTapes_21626257(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates one or more virtual tapes. You write data to the virtual tapes and then archive the tapes. This operation is only supported in the tape gateway type.</p> <note> <p>Cache storage must be allocated to the gateway before you can create virtual tapes. Use the <a>AddCache</a> operation to add cache storage to a gateway. </p> </note>
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
  var valid_21626259 = header.getOrDefault("X-Amz-Date")
  valid_21626259 = validateParameter(valid_21626259, JString, required = false,
                                   default = nil)
  if valid_21626259 != nil:
    section.add "X-Amz-Date", valid_21626259
  var valid_21626260 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626260 = validateParameter(valid_21626260, JString, required = false,
                                   default = nil)
  if valid_21626260 != nil:
    section.add "X-Amz-Security-Token", valid_21626260
  var valid_21626261 = header.getOrDefault("X-Amz-Target")
  valid_21626261 = validateParameter(valid_21626261, JString, required = true, default = newJString(
      "StorageGateway_20130630.CreateTapes"))
  if valid_21626261 != nil:
    section.add "X-Amz-Target", valid_21626261
  var valid_21626262 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626262 = validateParameter(valid_21626262, JString, required = false,
                                   default = nil)
  if valid_21626262 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626262
  var valid_21626263 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626263 = validateParameter(valid_21626263, JString, required = false,
                                   default = nil)
  if valid_21626263 != nil:
    section.add "X-Amz-Algorithm", valid_21626263
  var valid_21626264 = header.getOrDefault("X-Amz-Signature")
  valid_21626264 = validateParameter(valid_21626264, JString, required = false,
                                   default = nil)
  if valid_21626264 != nil:
    section.add "X-Amz-Signature", valid_21626264
  var valid_21626265 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626265 = validateParameter(valid_21626265, JString, required = false,
                                   default = nil)
  if valid_21626265 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626265
  var valid_21626266 = header.getOrDefault("X-Amz-Credential")
  valid_21626266 = validateParameter(valid_21626266, JString, required = false,
                                   default = nil)
  if valid_21626266 != nil:
    section.add "X-Amz-Credential", valid_21626266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626268: Call_CreateTapes_21626256; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates one or more virtual tapes. You write data to the virtual tapes and then archive the tapes. This operation is only supported in the tape gateway type.</p> <note> <p>Cache storage must be allocated to the gateway before you can create virtual tapes. Use the <a>AddCache</a> operation to add cache storage to a gateway. </p> </note>
  ## 
  let valid = call_21626268.validator(path, query, header, formData, body, _)
  let scheme = call_21626268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626268.makeUrl(scheme.get, call_21626268.host, call_21626268.base,
                               call_21626268.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626268, uri, valid, _)

proc call*(call_21626269: Call_CreateTapes_21626256; body: JsonNode): Recallable =
  ## createTapes
  ## <p>Creates one or more virtual tapes. You write data to the virtual tapes and then archive the tapes. This operation is only supported in the tape gateway type.</p> <note> <p>Cache storage must be allocated to the gateway before you can create virtual tapes. Use the <a>AddCache</a> operation to add cache storage to a gateway. </p> </note>
  ##   body: JObject (required)
  var body_21626270 = newJObject()
  if body != nil:
    body_21626270 = body
  result = call_21626269.call(nil, nil, nil, nil, body_21626270)

var createTapes* = Call_CreateTapes_21626256(name: "createTapes",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.CreateTapes",
    validator: validate_CreateTapes_21626257, base: "/", makeUrl: url_CreateTapes_21626258,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBandwidthRateLimit_21626271 = ref object of OpenApiRestCall_21625437
proc url_DeleteBandwidthRateLimit_21626273(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteBandwidthRateLimit_21626272(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes the bandwidth rate limits of a gateway. You can delete either the upload and download bandwidth rate limit, or you can delete both. If you delete only one of the limits, the other limit remains unchanged. To specify which gateway to work with, use the Amazon Resource Name (ARN) of the gateway in your request. This operation is supported for the stored volume, cached volume and tape gateway types.
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
  var valid_21626274 = header.getOrDefault("X-Amz-Date")
  valid_21626274 = validateParameter(valid_21626274, JString, required = false,
                                   default = nil)
  if valid_21626274 != nil:
    section.add "X-Amz-Date", valid_21626274
  var valid_21626275 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626275 = validateParameter(valid_21626275, JString, required = false,
                                   default = nil)
  if valid_21626275 != nil:
    section.add "X-Amz-Security-Token", valid_21626275
  var valid_21626276 = header.getOrDefault("X-Amz-Target")
  valid_21626276 = validateParameter(valid_21626276, JString, required = true, default = newJString(
      "StorageGateway_20130630.DeleteBandwidthRateLimit"))
  if valid_21626276 != nil:
    section.add "X-Amz-Target", valid_21626276
  var valid_21626277 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626277 = validateParameter(valid_21626277, JString, required = false,
                                   default = nil)
  if valid_21626277 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626277
  var valid_21626278 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626278 = validateParameter(valid_21626278, JString, required = false,
                                   default = nil)
  if valid_21626278 != nil:
    section.add "X-Amz-Algorithm", valid_21626278
  var valid_21626279 = header.getOrDefault("X-Amz-Signature")
  valid_21626279 = validateParameter(valid_21626279, JString, required = false,
                                   default = nil)
  if valid_21626279 != nil:
    section.add "X-Amz-Signature", valid_21626279
  var valid_21626280 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626280 = validateParameter(valid_21626280, JString, required = false,
                                   default = nil)
  if valid_21626280 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626280
  var valid_21626281 = header.getOrDefault("X-Amz-Credential")
  valid_21626281 = validateParameter(valid_21626281, JString, required = false,
                                   default = nil)
  if valid_21626281 != nil:
    section.add "X-Amz-Credential", valid_21626281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626283: Call_DeleteBandwidthRateLimit_21626271;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the bandwidth rate limits of a gateway. You can delete either the upload and download bandwidth rate limit, or you can delete both. If you delete only one of the limits, the other limit remains unchanged. To specify which gateway to work with, use the Amazon Resource Name (ARN) of the gateway in your request. This operation is supported for the stored volume, cached volume and tape gateway types.
  ## 
  let valid = call_21626283.validator(path, query, header, formData, body, _)
  let scheme = call_21626283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626283.makeUrl(scheme.get, call_21626283.host, call_21626283.base,
                               call_21626283.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626283, uri, valid, _)

proc call*(call_21626284: Call_DeleteBandwidthRateLimit_21626271; body: JsonNode): Recallable =
  ## deleteBandwidthRateLimit
  ## Deletes the bandwidth rate limits of a gateway. You can delete either the upload and download bandwidth rate limit, or you can delete both. If you delete only one of the limits, the other limit remains unchanged. To specify which gateway to work with, use the Amazon Resource Name (ARN) of the gateway in your request. This operation is supported for the stored volume, cached volume and tape gateway types.
  ##   body: JObject (required)
  var body_21626285 = newJObject()
  if body != nil:
    body_21626285 = body
  result = call_21626284.call(nil, nil, nil, nil, body_21626285)

var deleteBandwidthRateLimit* = Call_DeleteBandwidthRateLimit_21626271(
    name: "deleteBandwidthRateLimit", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DeleteBandwidthRateLimit",
    validator: validate_DeleteBandwidthRateLimit_21626272, base: "/",
    makeUrl: url_DeleteBandwidthRateLimit_21626273,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteChapCredentials_21626286 = ref object of OpenApiRestCall_21625437
proc url_DeleteChapCredentials_21626288(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteChapCredentials_21626287(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes Challenge-Handshake Authentication Protocol (CHAP) credentials for a specified iSCSI target and initiator pair. This operation is supported in volume and tape gateway types.
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
  var valid_21626289 = header.getOrDefault("X-Amz-Date")
  valid_21626289 = validateParameter(valid_21626289, JString, required = false,
                                   default = nil)
  if valid_21626289 != nil:
    section.add "X-Amz-Date", valid_21626289
  var valid_21626290 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626290 = validateParameter(valid_21626290, JString, required = false,
                                   default = nil)
  if valid_21626290 != nil:
    section.add "X-Amz-Security-Token", valid_21626290
  var valid_21626291 = header.getOrDefault("X-Amz-Target")
  valid_21626291 = validateParameter(valid_21626291, JString, required = true, default = newJString(
      "StorageGateway_20130630.DeleteChapCredentials"))
  if valid_21626291 != nil:
    section.add "X-Amz-Target", valid_21626291
  var valid_21626292 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626292 = validateParameter(valid_21626292, JString, required = false,
                                   default = nil)
  if valid_21626292 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626292
  var valid_21626293 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626293 = validateParameter(valid_21626293, JString, required = false,
                                   default = nil)
  if valid_21626293 != nil:
    section.add "X-Amz-Algorithm", valid_21626293
  var valid_21626294 = header.getOrDefault("X-Amz-Signature")
  valid_21626294 = validateParameter(valid_21626294, JString, required = false,
                                   default = nil)
  if valid_21626294 != nil:
    section.add "X-Amz-Signature", valid_21626294
  var valid_21626295 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626295 = validateParameter(valid_21626295, JString, required = false,
                                   default = nil)
  if valid_21626295 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626295
  var valid_21626296 = header.getOrDefault("X-Amz-Credential")
  valid_21626296 = validateParameter(valid_21626296, JString, required = false,
                                   default = nil)
  if valid_21626296 != nil:
    section.add "X-Amz-Credential", valid_21626296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626298: Call_DeleteChapCredentials_21626286;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes Challenge-Handshake Authentication Protocol (CHAP) credentials for a specified iSCSI target and initiator pair. This operation is supported in volume and tape gateway types.
  ## 
  let valid = call_21626298.validator(path, query, header, formData, body, _)
  let scheme = call_21626298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626298.makeUrl(scheme.get, call_21626298.host, call_21626298.base,
                               call_21626298.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626298, uri, valid, _)

proc call*(call_21626299: Call_DeleteChapCredentials_21626286; body: JsonNode): Recallable =
  ## deleteChapCredentials
  ## Deletes Challenge-Handshake Authentication Protocol (CHAP) credentials for a specified iSCSI target and initiator pair. This operation is supported in volume and tape gateway types.
  ##   body: JObject (required)
  var body_21626300 = newJObject()
  if body != nil:
    body_21626300 = body
  result = call_21626299.call(nil, nil, nil, nil, body_21626300)

var deleteChapCredentials* = Call_DeleteChapCredentials_21626286(
    name: "deleteChapCredentials", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DeleteChapCredentials",
    validator: validate_DeleteChapCredentials_21626287, base: "/",
    makeUrl: url_DeleteChapCredentials_21626288,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFileShare_21626301 = ref object of OpenApiRestCall_21625437
proc url_DeleteFileShare_21626303(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteFileShare_21626302(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a file share from a file gateway. This operation is only supported for file gateways.
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
  var valid_21626304 = header.getOrDefault("X-Amz-Date")
  valid_21626304 = validateParameter(valid_21626304, JString, required = false,
                                   default = nil)
  if valid_21626304 != nil:
    section.add "X-Amz-Date", valid_21626304
  var valid_21626305 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626305 = validateParameter(valid_21626305, JString, required = false,
                                   default = nil)
  if valid_21626305 != nil:
    section.add "X-Amz-Security-Token", valid_21626305
  var valid_21626306 = header.getOrDefault("X-Amz-Target")
  valid_21626306 = validateParameter(valid_21626306, JString, required = true, default = newJString(
      "StorageGateway_20130630.DeleteFileShare"))
  if valid_21626306 != nil:
    section.add "X-Amz-Target", valid_21626306
  var valid_21626307 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626307 = validateParameter(valid_21626307, JString, required = false,
                                   default = nil)
  if valid_21626307 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626307
  var valid_21626308 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626308 = validateParameter(valid_21626308, JString, required = false,
                                   default = nil)
  if valid_21626308 != nil:
    section.add "X-Amz-Algorithm", valid_21626308
  var valid_21626309 = header.getOrDefault("X-Amz-Signature")
  valid_21626309 = validateParameter(valid_21626309, JString, required = false,
                                   default = nil)
  if valid_21626309 != nil:
    section.add "X-Amz-Signature", valid_21626309
  var valid_21626310 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626310 = validateParameter(valid_21626310, JString, required = false,
                                   default = nil)
  if valid_21626310 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626310
  var valid_21626311 = header.getOrDefault("X-Amz-Credential")
  valid_21626311 = validateParameter(valid_21626311, JString, required = false,
                                   default = nil)
  if valid_21626311 != nil:
    section.add "X-Amz-Credential", valid_21626311
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626313: Call_DeleteFileShare_21626301; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a file share from a file gateway. This operation is only supported for file gateways.
  ## 
  let valid = call_21626313.validator(path, query, header, formData, body, _)
  let scheme = call_21626313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626313.makeUrl(scheme.get, call_21626313.host, call_21626313.base,
                               call_21626313.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626313, uri, valid, _)

proc call*(call_21626314: Call_DeleteFileShare_21626301; body: JsonNode): Recallable =
  ## deleteFileShare
  ## Deletes a file share from a file gateway. This operation is only supported for file gateways.
  ##   body: JObject (required)
  var body_21626315 = newJObject()
  if body != nil:
    body_21626315 = body
  result = call_21626314.call(nil, nil, nil, nil, body_21626315)

var deleteFileShare* = Call_DeleteFileShare_21626301(name: "deleteFileShare",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DeleteFileShare",
    validator: validate_DeleteFileShare_21626302, base: "/",
    makeUrl: url_DeleteFileShare_21626303, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGateway_21626316 = ref object of OpenApiRestCall_21625437
proc url_DeleteGateway_21626318(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteGateway_21626317(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>Deletes a gateway. To specify which gateway to delete, use the Amazon Resource Name (ARN) of the gateway in your request. The operation deletes the gateway; however, it does not delete the gateway virtual machine (VM) from your host computer.</p> <p>After you delete a gateway, you cannot reactivate it. Completed snapshots of the gateway volumes are not deleted upon deleting the gateway, however, pending snapshots will not complete. After you delete a gateway, your next step is to remove it from your environment.</p> <important> <p>You no longer pay software charges after the gateway is deleted; however, your existing Amazon EBS snapshots persist and you will continue to be billed for these snapshots. You can choose to remove all remaining Amazon EBS snapshots by canceling your Amazon EC2 subscription.  If you prefer not to cancel your Amazon EC2 subscription, you can delete your snapshots using the Amazon EC2 console. For more information, see the <a href="http://aws.amazon.com/storagegateway"> AWS Storage Gateway Detail Page</a>. </p> </important>
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
  var valid_21626319 = header.getOrDefault("X-Amz-Date")
  valid_21626319 = validateParameter(valid_21626319, JString, required = false,
                                   default = nil)
  if valid_21626319 != nil:
    section.add "X-Amz-Date", valid_21626319
  var valid_21626320 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626320 = validateParameter(valid_21626320, JString, required = false,
                                   default = nil)
  if valid_21626320 != nil:
    section.add "X-Amz-Security-Token", valid_21626320
  var valid_21626321 = header.getOrDefault("X-Amz-Target")
  valid_21626321 = validateParameter(valid_21626321, JString, required = true, default = newJString(
      "StorageGateway_20130630.DeleteGateway"))
  if valid_21626321 != nil:
    section.add "X-Amz-Target", valid_21626321
  var valid_21626322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626322 = validateParameter(valid_21626322, JString, required = false,
                                   default = nil)
  if valid_21626322 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626322
  var valid_21626323 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626323 = validateParameter(valid_21626323, JString, required = false,
                                   default = nil)
  if valid_21626323 != nil:
    section.add "X-Amz-Algorithm", valid_21626323
  var valid_21626324 = header.getOrDefault("X-Amz-Signature")
  valid_21626324 = validateParameter(valid_21626324, JString, required = false,
                                   default = nil)
  if valid_21626324 != nil:
    section.add "X-Amz-Signature", valid_21626324
  var valid_21626325 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626325 = validateParameter(valid_21626325, JString, required = false,
                                   default = nil)
  if valid_21626325 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626325
  var valid_21626326 = header.getOrDefault("X-Amz-Credential")
  valid_21626326 = validateParameter(valid_21626326, JString, required = false,
                                   default = nil)
  if valid_21626326 != nil:
    section.add "X-Amz-Credential", valid_21626326
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626328: Call_DeleteGateway_21626316; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a gateway. To specify which gateway to delete, use the Amazon Resource Name (ARN) of the gateway in your request. The operation deletes the gateway; however, it does not delete the gateway virtual machine (VM) from your host computer.</p> <p>After you delete a gateway, you cannot reactivate it. Completed snapshots of the gateway volumes are not deleted upon deleting the gateway, however, pending snapshots will not complete. After you delete a gateway, your next step is to remove it from your environment.</p> <important> <p>You no longer pay software charges after the gateway is deleted; however, your existing Amazon EBS snapshots persist and you will continue to be billed for these snapshots. You can choose to remove all remaining Amazon EBS snapshots by canceling your Amazon EC2 subscription.  If you prefer not to cancel your Amazon EC2 subscription, you can delete your snapshots using the Amazon EC2 console. For more information, see the <a href="http://aws.amazon.com/storagegateway"> AWS Storage Gateway Detail Page</a>. </p> </important>
  ## 
  let valid = call_21626328.validator(path, query, header, formData, body, _)
  let scheme = call_21626328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626328.makeUrl(scheme.get, call_21626328.host, call_21626328.base,
                               call_21626328.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626328, uri, valid, _)

proc call*(call_21626329: Call_DeleteGateway_21626316; body: JsonNode): Recallable =
  ## deleteGateway
  ## <p>Deletes a gateway. To specify which gateway to delete, use the Amazon Resource Name (ARN) of the gateway in your request. The operation deletes the gateway; however, it does not delete the gateway virtual machine (VM) from your host computer.</p> <p>After you delete a gateway, you cannot reactivate it. Completed snapshots of the gateway volumes are not deleted upon deleting the gateway, however, pending snapshots will not complete. After you delete a gateway, your next step is to remove it from your environment.</p> <important> <p>You no longer pay software charges after the gateway is deleted; however, your existing Amazon EBS snapshots persist and you will continue to be billed for these snapshots. You can choose to remove all remaining Amazon EBS snapshots by canceling your Amazon EC2 subscription.  If you prefer not to cancel your Amazon EC2 subscription, you can delete your snapshots using the Amazon EC2 console. For more information, see the <a href="http://aws.amazon.com/storagegateway"> AWS Storage Gateway Detail Page</a>. </p> </important>
  ##   body: JObject (required)
  var body_21626330 = newJObject()
  if body != nil:
    body_21626330 = body
  result = call_21626329.call(nil, nil, nil, nil, body_21626330)

var deleteGateway* = Call_DeleteGateway_21626316(name: "deleteGateway",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DeleteGateway",
    validator: validate_DeleteGateway_21626317, base: "/",
    makeUrl: url_DeleteGateway_21626318, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSnapshotSchedule_21626331 = ref object of OpenApiRestCall_21625437
proc url_DeleteSnapshotSchedule_21626333(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteSnapshotSchedule_21626332(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Deletes a snapshot of a volume.</p> <p>You can take snapshots of your gateway volumes on a scheduled or ad hoc basis. This API action enables you to delete a snapshot schedule for a volume. For more information, see <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/WorkingWithSnapshots.html">Working with Snapshots</a>. In the <code>DeleteSnapshotSchedule</code> request, you identify the volume by providing its Amazon Resource Name (ARN). This operation is only supported in stored and cached volume gateway types.</p> <note> <p>To list or delete a snapshot, you must use the Amazon EC2 API. in <i>Amazon Elastic Compute Cloud API Reference</i>.</p> </note>
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
  var valid_21626334 = header.getOrDefault("X-Amz-Date")
  valid_21626334 = validateParameter(valid_21626334, JString, required = false,
                                   default = nil)
  if valid_21626334 != nil:
    section.add "X-Amz-Date", valid_21626334
  var valid_21626335 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626335 = validateParameter(valid_21626335, JString, required = false,
                                   default = nil)
  if valid_21626335 != nil:
    section.add "X-Amz-Security-Token", valid_21626335
  var valid_21626336 = header.getOrDefault("X-Amz-Target")
  valid_21626336 = validateParameter(valid_21626336, JString, required = true, default = newJString(
      "StorageGateway_20130630.DeleteSnapshotSchedule"))
  if valid_21626336 != nil:
    section.add "X-Amz-Target", valid_21626336
  var valid_21626337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626337 = validateParameter(valid_21626337, JString, required = false,
                                   default = nil)
  if valid_21626337 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626337
  var valid_21626338 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626338 = validateParameter(valid_21626338, JString, required = false,
                                   default = nil)
  if valid_21626338 != nil:
    section.add "X-Amz-Algorithm", valid_21626338
  var valid_21626339 = header.getOrDefault("X-Amz-Signature")
  valid_21626339 = validateParameter(valid_21626339, JString, required = false,
                                   default = nil)
  if valid_21626339 != nil:
    section.add "X-Amz-Signature", valid_21626339
  var valid_21626340 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626340 = validateParameter(valid_21626340, JString, required = false,
                                   default = nil)
  if valid_21626340 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626340
  var valid_21626341 = header.getOrDefault("X-Amz-Credential")
  valid_21626341 = validateParameter(valid_21626341, JString, required = false,
                                   default = nil)
  if valid_21626341 != nil:
    section.add "X-Amz-Credential", valid_21626341
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626343: Call_DeleteSnapshotSchedule_21626331;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a snapshot of a volume.</p> <p>You can take snapshots of your gateway volumes on a scheduled or ad hoc basis. This API action enables you to delete a snapshot schedule for a volume. For more information, see <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/WorkingWithSnapshots.html">Working with Snapshots</a>. In the <code>DeleteSnapshotSchedule</code> request, you identify the volume by providing its Amazon Resource Name (ARN). This operation is only supported in stored and cached volume gateway types.</p> <note> <p>To list or delete a snapshot, you must use the Amazon EC2 API. in <i>Amazon Elastic Compute Cloud API Reference</i>.</p> </note>
  ## 
  let valid = call_21626343.validator(path, query, header, formData, body, _)
  let scheme = call_21626343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626343.makeUrl(scheme.get, call_21626343.host, call_21626343.base,
                               call_21626343.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626343, uri, valid, _)

proc call*(call_21626344: Call_DeleteSnapshotSchedule_21626331; body: JsonNode): Recallable =
  ## deleteSnapshotSchedule
  ## <p>Deletes a snapshot of a volume.</p> <p>You can take snapshots of your gateway volumes on a scheduled or ad hoc basis. This API action enables you to delete a snapshot schedule for a volume. For more information, see <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/WorkingWithSnapshots.html">Working with Snapshots</a>. In the <code>DeleteSnapshotSchedule</code> request, you identify the volume by providing its Amazon Resource Name (ARN). This operation is only supported in stored and cached volume gateway types.</p> <note> <p>To list or delete a snapshot, you must use the Amazon EC2 API. in <i>Amazon Elastic Compute Cloud API Reference</i>.</p> </note>
  ##   body: JObject (required)
  var body_21626345 = newJObject()
  if body != nil:
    body_21626345 = body
  result = call_21626344.call(nil, nil, nil, nil, body_21626345)

var deleteSnapshotSchedule* = Call_DeleteSnapshotSchedule_21626331(
    name: "deleteSnapshotSchedule", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DeleteSnapshotSchedule",
    validator: validate_DeleteSnapshotSchedule_21626332, base: "/",
    makeUrl: url_DeleteSnapshotSchedule_21626333,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTape_21626346 = ref object of OpenApiRestCall_21625437
proc url_DeleteTape_21626348(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteTape_21626347(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes the specified virtual tape. This operation is only supported in the tape gateway type.
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
  var valid_21626349 = header.getOrDefault("X-Amz-Date")
  valid_21626349 = validateParameter(valid_21626349, JString, required = false,
                                   default = nil)
  if valid_21626349 != nil:
    section.add "X-Amz-Date", valid_21626349
  var valid_21626350 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626350 = validateParameter(valid_21626350, JString, required = false,
                                   default = nil)
  if valid_21626350 != nil:
    section.add "X-Amz-Security-Token", valid_21626350
  var valid_21626351 = header.getOrDefault("X-Amz-Target")
  valid_21626351 = validateParameter(valid_21626351, JString, required = true, default = newJString(
      "StorageGateway_20130630.DeleteTape"))
  if valid_21626351 != nil:
    section.add "X-Amz-Target", valid_21626351
  var valid_21626352 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626352 = validateParameter(valid_21626352, JString, required = false,
                                   default = nil)
  if valid_21626352 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626352
  var valid_21626353 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626353 = validateParameter(valid_21626353, JString, required = false,
                                   default = nil)
  if valid_21626353 != nil:
    section.add "X-Amz-Algorithm", valid_21626353
  var valid_21626354 = header.getOrDefault("X-Amz-Signature")
  valid_21626354 = validateParameter(valid_21626354, JString, required = false,
                                   default = nil)
  if valid_21626354 != nil:
    section.add "X-Amz-Signature", valid_21626354
  var valid_21626355 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626355 = validateParameter(valid_21626355, JString, required = false,
                                   default = nil)
  if valid_21626355 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626355
  var valid_21626356 = header.getOrDefault("X-Amz-Credential")
  valid_21626356 = validateParameter(valid_21626356, JString, required = false,
                                   default = nil)
  if valid_21626356 != nil:
    section.add "X-Amz-Credential", valid_21626356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626358: Call_DeleteTape_21626346; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified virtual tape. This operation is only supported in the tape gateway type.
  ## 
  let valid = call_21626358.validator(path, query, header, formData, body, _)
  let scheme = call_21626358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626358.makeUrl(scheme.get, call_21626358.host, call_21626358.base,
                               call_21626358.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626358, uri, valid, _)

proc call*(call_21626359: Call_DeleteTape_21626346; body: JsonNode): Recallable =
  ## deleteTape
  ## Deletes the specified virtual tape. This operation is only supported in the tape gateway type.
  ##   body: JObject (required)
  var body_21626360 = newJObject()
  if body != nil:
    body_21626360 = body
  result = call_21626359.call(nil, nil, nil, nil, body_21626360)

var deleteTape* = Call_DeleteTape_21626346(name: "deleteTape",
                                        meth: HttpMethod.HttpPost,
                                        host: "storagegateway.amazonaws.com", route: "/#X-Amz-Target=StorageGateway_20130630.DeleteTape",
                                        validator: validate_DeleteTape_21626347,
                                        base: "/", makeUrl: url_DeleteTape_21626348,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTapeArchive_21626361 = ref object of OpenApiRestCall_21625437
proc url_DeleteTapeArchive_21626363(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteTapeArchive_21626362(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes the specified virtual tape from the virtual tape shelf (VTS). This operation is only supported in the tape gateway type.
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
  var valid_21626364 = header.getOrDefault("X-Amz-Date")
  valid_21626364 = validateParameter(valid_21626364, JString, required = false,
                                   default = nil)
  if valid_21626364 != nil:
    section.add "X-Amz-Date", valid_21626364
  var valid_21626365 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626365 = validateParameter(valid_21626365, JString, required = false,
                                   default = nil)
  if valid_21626365 != nil:
    section.add "X-Amz-Security-Token", valid_21626365
  var valid_21626366 = header.getOrDefault("X-Amz-Target")
  valid_21626366 = validateParameter(valid_21626366, JString, required = true, default = newJString(
      "StorageGateway_20130630.DeleteTapeArchive"))
  if valid_21626366 != nil:
    section.add "X-Amz-Target", valid_21626366
  var valid_21626367 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626367 = validateParameter(valid_21626367, JString, required = false,
                                   default = nil)
  if valid_21626367 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626367
  var valid_21626368 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626368 = validateParameter(valid_21626368, JString, required = false,
                                   default = nil)
  if valid_21626368 != nil:
    section.add "X-Amz-Algorithm", valid_21626368
  var valid_21626369 = header.getOrDefault("X-Amz-Signature")
  valid_21626369 = validateParameter(valid_21626369, JString, required = false,
                                   default = nil)
  if valid_21626369 != nil:
    section.add "X-Amz-Signature", valid_21626369
  var valid_21626370 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626370 = validateParameter(valid_21626370, JString, required = false,
                                   default = nil)
  if valid_21626370 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626370
  var valid_21626371 = header.getOrDefault("X-Amz-Credential")
  valid_21626371 = validateParameter(valid_21626371, JString, required = false,
                                   default = nil)
  if valid_21626371 != nil:
    section.add "X-Amz-Credential", valid_21626371
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626373: Call_DeleteTapeArchive_21626361; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified virtual tape from the virtual tape shelf (VTS). This operation is only supported in the tape gateway type.
  ## 
  let valid = call_21626373.validator(path, query, header, formData, body, _)
  let scheme = call_21626373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626373.makeUrl(scheme.get, call_21626373.host, call_21626373.base,
                               call_21626373.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626373, uri, valid, _)

proc call*(call_21626374: Call_DeleteTapeArchive_21626361; body: JsonNode): Recallable =
  ## deleteTapeArchive
  ## Deletes the specified virtual tape from the virtual tape shelf (VTS). This operation is only supported in the tape gateway type.
  ##   body: JObject (required)
  var body_21626375 = newJObject()
  if body != nil:
    body_21626375 = body
  result = call_21626374.call(nil, nil, nil, nil, body_21626375)

var deleteTapeArchive* = Call_DeleteTapeArchive_21626361(name: "deleteTapeArchive",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DeleteTapeArchive",
    validator: validate_DeleteTapeArchive_21626362, base: "/",
    makeUrl: url_DeleteTapeArchive_21626363, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVolume_21626376 = ref object of OpenApiRestCall_21625437
proc url_DeleteVolume_21626378(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteVolume_21626377(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>Deletes the specified storage volume that you previously created using the <a>CreateCachediSCSIVolume</a> or <a>CreateStorediSCSIVolume</a> API. This operation is only supported in the cached volume and stored volume types. For stored volume gateways, the local disk that was configured as the storage volume is not deleted. You can reuse the local disk to create another storage volume. </p> <p>Before you delete a volume, make sure there are no iSCSI connections to the volume you are deleting. You should also make sure there is no snapshot in progress. You can use the Amazon Elastic Compute Cloud (Amazon EC2) API to query snapshots on the volume you are deleting and check the snapshot status. For more information, go to <a href="https://docs.aws.amazon.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeSnapshots.html">DescribeSnapshots</a> in the <i>Amazon Elastic Compute Cloud API Reference</i>.</p> <p>In the request, you must provide the Amazon Resource Name (ARN) of the storage volume you want to delete.</p>
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
  var valid_21626379 = header.getOrDefault("X-Amz-Date")
  valid_21626379 = validateParameter(valid_21626379, JString, required = false,
                                   default = nil)
  if valid_21626379 != nil:
    section.add "X-Amz-Date", valid_21626379
  var valid_21626380 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626380 = validateParameter(valid_21626380, JString, required = false,
                                   default = nil)
  if valid_21626380 != nil:
    section.add "X-Amz-Security-Token", valid_21626380
  var valid_21626381 = header.getOrDefault("X-Amz-Target")
  valid_21626381 = validateParameter(valid_21626381, JString, required = true, default = newJString(
      "StorageGateway_20130630.DeleteVolume"))
  if valid_21626381 != nil:
    section.add "X-Amz-Target", valid_21626381
  var valid_21626382 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626382 = validateParameter(valid_21626382, JString, required = false,
                                   default = nil)
  if valid_21626382 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626382
  var valid_21626383 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626383 = validateParameter(valid_21626383, JString, required = false,
                                   default = nil)
  if valid_21626383 != nil:
    section.add "X-Amz-Algorithm", valid_21626383
  var valid_21626384 = header.getOrDefault("X-Amz-Signature")
  valid_21626384 = validateParameter(valid_21626384, JString, required = false,
                                   default = nil)
  if valid_21626384 != nil:
    section.add "X-Amz-Signature", valid_21626384
  var valid_21626385 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626385 = validateParameter(valid_21626385, JString, required = false,
                                   default = nil)
  if valid_21626385 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626385
  var valid_21626386 = header.getOrDefault("X-Amz-Credential")
  valid_21626386 = validateParameter(valid_21626386, JString, required = false,
                                   default = nil)
  if valid_21626386 != nil:
    section.add "X-Amz-Credential", valid_21626386
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626388: Call_DeleteVolume_21626376; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the specified storage volume that you previously created using the <a>CreateCachediSCSIVolume</a> or <a>CreateStorediSCSIVolume</a> API. This operation is only supported in the cached volume and stored volume types. For stored volume gateways, the local disk that was configured as the storage volume is not deleted. You can reuse the local disk to create another storage volume. </p> <p>Before you delete a volume, make sure there are no iSCSI connections to the volume you are deleting. You should also make sure there is no snapshot in progress. You can use the Amazon Elastic Compute Cloud (Amazon EC2) API to query snapshots on the volume you are deleting and check the snapshot status. For more information, go to <a href="https://docs.aws.amazon.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeSnapshots.html">DescribeSnapshots</a> in the <i>Amazon Elastic Compute Cloud API Reference</i>.</p> <p>In the request, you must provide the Amazon Resource Name (ARN) of the storage volume you want to delete.</p>
  ## 
  let valid = call_21626388.validator(path, query, header, formData, body, _)
  let scheme = call_21626388.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626388.makeUrl(scheme.get, call_21626388.host, call_21626388.base,
                               call_21626388.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626388, uri, valid, _)

proc call*(call_21626389: Call_DeleteVolume_21626376; body: JsonNode): Recallable =
  ## deleteVolume
  ## <p>Deletes the specified storage volume that you previously created using the <a>CreateCachediSCSIVolume</a> or <a>CreateStorediSCSIVolume</a> API. This operation is only supported in the cached volume and stored volume types. For stored volume gateways, the local disk that was configured as the storage volume is not deleted. You can reuse the local disk to create another storage volume. </p> <p>Before you delete a volume, make sure there are no iSCSI connections to the volume you are deleting. You should also make sure there is no snapshot in progress. You can use the Amazon Elastic Compute Cloud (Amazon EC2) API to query snapshots on the volume you are deleting and check the snapshot status. For more information, go to <a href="https://docs.aws.amazon.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeSnapshots.html">DescribeSnapshots</a> in the <i>Amazon Elastic Compute Cloud API Reference</i>.</p> <p>In the request, you must provide the Amazon Resource Name (ARN) of the storage volume you want to delete.</p>
  ##   body: JObject (required)
  var body_21626390 = newJObject()
  if body != nil:
    body_21626390 = body
  result = call_21626389.call(nil, nil, nil, nil, body_21626390)

var deleteVolume* = Call_DeleteVolume_21626376(name: "deleteVolume",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DeleteVolume",
    validator: validate_DeleteVolume_21626377, base: "/", makeUrl: url_DeleteVolume_21626378,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAvailabilityMonitorTest_21626391 = ref object of OpenApiRestCall_21625437
proc url_DescribeAvailabilityMonitorTest_21626393(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeAvailabilityMonitorTest_21626392(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Returns information about the most recent High Availability monitoring test that was performed on the host in a cluster. If a test isn't performed, the status and start time in the response would be null.
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
  var valid_21626394 = header.getOrDefault("X-Amz-Date")
  valid_21626394 = validateParameter(valid_21626394, JString, required = false,
                                   default = nil)
  if valid_21626394 != nil:
    section.add "X-Amz-Date", valid_21626394
  var valid_21626395 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626395 = validateParameter(valid_21626395, JString, required = false,
                                   default = nil)
  if valid_21626395 != nil:
    section.add "X-Amz-Security-Token", valid_21626395
  var valid_21626396 = header.getOrDefault("X-Amz-Target")
  valid_21626396 = validateParameter(valid_21626396, JString, required = true, default = newJString(
      "StorageGateway_20130630.DescribeAvailabilityMonitorTest"))
  if valid_21626396 != nil:
    section.add "X-Amz-Target", valid_21626396
  var valid_21626397 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626397 = validateParameter(valid_21626397, JString, required = false,
                                   default = nil)
  if valid_21626397 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626397
  var valid_21626398 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626398 = validateParameter(valid_21626398, JString, required = false,
                                   default = nil)
  if valid_21626398 != nil:
    section.add "X-Amz-Algorithm", valid_21626398
  var valid_21626399 = header.getOrDefault("X-Amz-Signature")
  valid_21626399 = validateParameter(valid_21626399, JString, required = false,
                                   default = nil)
  if valid_21626399 != nil:
    section.add "X-Amz-Signature", valid_21626399
  var valid_21626400 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626400 = validateParameter(valid_21626400, JString, required = false,
                                   default = nil)
  if valid_21626400 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626400
  var valid_21626401 = header.getOrDefault("X-Amz-Credential")
  valid_21626401 = validateParameter(valid_21626401, JString, required = false,
                                   default = nil)
  if valid_21626401 != nil:
    section.add "X-Amz-Credential", valid_21626401
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626403: Call_DescribeAvailabilityMonitorTest_21626391;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about the most recent High Availability monitoring test that was performed on the host in a cluster. If a test isn't performed, the status and start time in the response would be null.
  ## 
  let valid = call_21626403.validator(path, query, header, formData, body, _)
  let scheme = call_21626403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626403.makeUrl(scheme.get, call_21626403.host, call_21626403.base,
                               call_21626403.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626403, uri, valid, _)

proc call*(call_21626404: Call_DescribeAvailabilityMonitorTest_21626391;
          body: JsonNode): Recallable =
  ## describeAvailabilityMonitorTest
  ## Returns information about the most recent High Availability monitoring test that was performed on the host in a cluster. If a test isn't performed, the status and start time in the response would be null.
  ##   body: JObject (required)
  var body_21626405 = newJObject()
  if body != nil:
    body_21626405 = body
  result = call_21626404.call(nil, nil, nil, nil, body_21626405)

var describeAvailabilityMonitorTest* = Call_DescribeAvailabilityMonitorTest_21626391(
    name: "describeAvailabilityMonitorTest", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com", route: "/#X-Amz-Target=StorageGateway_20130630.DescribeAvailabilityMonitorTest",
    validator: validate_DescribeAvailabilityMonitorTest_21626392, base: "/",
    makeUrl: url_DescribeAvailabilityMonitorTest_21626393,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBandwidthRateLimit_21626406 = ref object of OpenApiRestCall_21625437
proc url_DescribeBandwidthRateLimit_21626408(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeBandwidthRateLimit_21626407(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns the bandwidth rate limits of a gateway. By default, these limits are not set, which means no bandwidth rate limiting is in effect. This operation is supported for the stored volume, cached volume and tape gateway types.'</p> <p>This operation only returns a value for a bandwidth rate limit only if the limit is set. If no limits are set for the gateway, then this operation returns only the gateway ARN in the response body. To specify which gateway to describe, use the Amazon Resource Name (ARN) of the gateway in your request.</p>
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
  var valid_21626409 = header.getOrDefault("X-Amz-Date")
  valid_21626409 = validateParameter(valid_21626409, JString, required = false,
                                   default = nil)
  if valid_21626409 != nil:
    section.add "X-Amz-Date", valid_21626409
  var valid_21626410 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626410 = validateParameter(valid_21626410, JString, required = false,
                                   default = nil)
  if valid_21626410 != nil:
    section.add "X-Amz-Security-Token", valid_21626410
  var valid_21626411 = header.getOrDefault("X-Amz-Target")
  valid_21626411 = validateParameter(valid_21626411, JString, required = true, default = newJString(
      "StorageGateway_20130630.DescribeBandwidthRateLimit"))
  if valid_21626411 != nil:
    section.add "X-Amz-Target", valid_21626411
  var valid_21626412 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626412 = validateParameter(valid_21626412, JString, required = false,
                                   default = nil)
  if valid_21626412 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626412
  var valid_21626413 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626413 = validateParameter(valid_21626413, JString, required = false,
                                   default = nil)
  if valid_21626413 != nil:
    section.add "X-Amz-Algorithm", valid_21626413
  var valid_21626414 = header.getOrDefault("X-Amz-Signature")
  valid_21626414 = validateParameter(valid_21626414, JString, required = false,
                                   default = nil)
  if valid_21626414 != nil:
    section.add "X-Amz-Signature", valid_21626414
  var valid_21626415 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626415 = validateParameter(valid_21626415, JString, required = false,
                                   default = nil)
  if valid_21626415 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626415
  var valid_21626416 = header.getOrDefault("X-Amz-Credential")
  valid_21626416 = validateParameter(valid_21626416, JString, required = false,
                                   default = nil)
  if valid_21626416 != nil:
    section.add "X-Amz-Credential", valid_21626416
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626418: Call_DescribeBandwidthRateLimit_21626406;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns the bandwidth rate limits of a gateway. By default, these limits are not set, which means no bandwidth rate limiting is in effect. This operation is supported for the stored volume, cached volume and tape gateway types.'</p> <p>This operation only returns a value for a bandwidth rate limit only if the limit is set. If no limits are set for the gateway, then this operation returns only the gateway ARN in the response body. To specify which gateway to describe, use the Amazon Resource Name (ARN) of the gateway in your request.</p>
  ## 
  let valid = call_21626418.validator(path, query, header, formData, body, _)
  let scheme = call_21626418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626418.makeUrl(scheme.get, call_21626418.host, call_21626418.base,
                               call_21626418.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626418, uri, valid, _)

proc call*(call_21626419: Call_DescribeBandwidthRateLimit_21626406; body: JsonNode): Recallable =
  ## describeBandwidthRateLimit
  ## <p>Returns the bandwidth rate limits of a gateway. By default, these limits are not set, which means no bandwidth rate limiting is in effect. This operation is supported for the stored volume, cached volume and tape gateway types.'</p> <p>This operation only returns a value for a bandwidth rate limit only if the limit is set. If no limits are set for the gateway, then this operation returns only the gateway ARN in the response body. To specify which gateway to describe, use the Amazon Resource Name (ARN) of the gateway in your request.</p>
  ##   body: JObject (required)
  var body_21626420 = newJObject()
  if body != nil:
    body_21626420 = body
  result = call_21626419.call(nil, nil, nil, nil, body_21626420)

var describeBandwidthRateLimit* = Call_DescribeBandwidthRateLimit_21626406(
    name: "describeBandwidthRateLimit", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeBandwidthRateLimit",
    validator: validate_DescribeBandwidthRateLimit_21626407, base: "/",
    makeUrl: url_DescribeBandwidthRateLimit_21626408,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCache_21626421 = ref object of OpenApiRestCall_21625437
proc url_DescribeCache_21626423(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeCache_21626422(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>Returns information about the cache of a gateway. This operation is only supported in the cached volume, tape and file gateway types.</p> <p>The response includes disk IDs that are configured as cache, and it includes the amount of cache allocated and used.</p>
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
  var valid_21626424 = header.getOrDefault("X-Amz-Date")
  valid_21626424 = validateParameter(valid_21626424, JString, required = false,
                                   default = nil)
  if valid_21626424 != nil:
    section.add "X-Amz-Date", valid_21626424
  var valid_21626425 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626425 = validateParameter(valid_21626425, JString, required = false,
                                   default = nil)
  if valid_21626425 != nil:
    section.add "X-Amz-Security-Token", valid_21626425
  var valid_21626426 = header.getOrDefault("X-Amz-Target")
  valid_21626426 = validateParameter(valid_21626426, JString, required = true, default = newJString(
      "StorageGateway_20130630.DescribeCache"))
  if valid_21626426 != nil:
    section.add "X-Amz-Target", valid_21626426
  var valid_21626427 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626427 = validateParameter(valid_21626427, JString, required = false,
                                   default = nil)
  if valid_21626427 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626427
  var valid_21626428 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626428 = validateParameter(valid_21626428, JString, required = false,
                                   default = nil)
  if valid_21626428 != nil:
    section.add "X-Amz-Algorithm", valid_21626428
  var valid_21626429 = header.getOrDefault("X-Amz-Signature")
  valid_21626429 = validateParameter(valid_21626429, JString, required = false,
                                   default = nil)
  if valid_21626429 != nil:
    section.add "X-Amz-Signature", valid_21626429
  var valid_21626430 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626430 = validateParameter(valid_21626430, JString, required = false,
                                   default = nil)
  if valid_21626430 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626430
  var valid_21626431 = header.getOrDefault("X-Amz-Credential")
  valid_21626431 = validateParameter(valid_21626431, JString, required = false,
                                   default = nil)
  if valid_21626431 != nil:
    section.add "X-Amz-Credential", valid_21626431
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626433: Call_DescribeCache_21626421; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns information about the cache of a gateway. This operation is only supported in the cached volume, tape and file gateway types.</p> <p>The response includes disk IDs that are configured as cache, and it includes the amount of cache allocated and used.</p>
  ## 
  let valid = call_21626433.validator(path, query, header, formData, body, _)
  let scheme = call_21626433.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626433.makeUrl(scheme.get, call_21626433.host, call_21626433.base,
                               call_21626433.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626433, uri, valid, _)

proc call*(call_21626434: Call_DescribeCache_21626421; body: JsonNode): Recallable =
  ## describeCache
  ## <p>Returns information about the cache of a gateway. This operation is only supported in the cached volume, tape and file gateway types.</p> <p>The response includes disk IDs that are configured as cache, and it includes the amount of cache allocated and used.</p>
  ##   body: JObject (required)
  var body_21626435 = newJObject()
  if body != nil:
    body_21626435 = body
  result = call_21626434.call(nil, nil, nil, nil, body_21626435)

var describeCache* = Call_DescribeCache_21626421(name: "describeCache",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeCache",
    validator: validate_DescribeCache_21626422, base: "/",
    makeUrl: url_DescribeCache_21626423, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCachediSCSIVolumes_21626436 = ref object of OpenApiRestCall_21625437
proc url_DescribeCachediSCSIVolumes_21626438(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeCachediSCSIVolumes_21626437(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns a description of the gateway volumes specified in the request. This operation is only supported in the cached volume gateway types.</p> <p>The list of gateway volumes in the request must be from one gateway. In the response Amazon Storage Gateway returns volume information sorted by volume Amazon Resource Name (ARN).</p>
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
  var valid_21626439 = header.getOrDefault("X-Amz-Date")
  valid_21626439 = validateParameter(valid_21626439, JString, required = false,
                                   default = nil)
  if valid_21626439 != nil:
    section.add "X-Amz-Date", valid_21626439
  var valid_21626440 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626440 = validateParameter(valid_21626440, JString, required = false,
                                   default = nil)
  if valid_21626440 != nil:
    section.add "X-Amz-Security-Token", valid_21626440
  var valid_21626441 = header.getOrDefault("X-Amz-Target")
  valid_21626441 = validateParameter(valid_21626441, JString, required = true, default = newJString(
      "StorageGateway_20130630.DescribeCachediSCSIVolumes"))
  if valid_21626441 != nil:
    section.add "X-Amz-Target", valid_21626441
  var valid_21626442 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626442 = validateParameter(valid_21626442, JString, required = false,
                                   default = nil)
  if valid_21626442 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626442
  var valid_21626443 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626443 = validateParameter(valid_21626443, JString, required = false,
                                   default = nil)
  if valid_21626443 != nil:
    section.add "X-Amz-Algorithm", valid_21626443
  var valid_21626444 = header.getOrDefault("X-Amz-Signature")
  valid_21626444 = validateParameter(valid_21626444, JString, required = false,
                                   default = nil)
  if valid_21626444 != nil:
    section.add "X-Amz-Signature", valid_21626444
  var valid_21626445 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626445 = validateParameter(valid_21626445, JString, required = false,
                                   default = nil)
  if valid_21626445 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626445
  var valid_21626446 = header.getOrDefault("X-Amz-Credential")
  valid_21626446 = validateParameter(valid_21626446, JString, required = false,
                                   default = nil)
  if valid_21626446 != nil:
    section.add "X-Amz-Credential", valid_21626446
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626448: Call_DescribeCachediSCSIVolumes_21626436;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns a description of the gateway volumes specified in the request. This operation is only supported in the cached volume gateway types.</p> <p>The list of gateway volumes in the request must be from one gateway. In the response Amazon Storage Gateway returns volume information sorted by volume Amazon Resource Name (ARN).</p>
  ## 
  let valid = call_21626448.validator(path, query, header, formData, body, _)
  let scheme = call_21626448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626448.makeUrl(scheme.get, call_21626448.host, call_21626448.base,
                               call_21626448.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626448, uri, valid, _)

proc call*(call_21626449: Call_DescribeCachediSCSIVolumes_21626436; body: JsonNode): Recallable =
  ## describeCachediSCSIVolumes
  ## <p>Returns a description of the gateway volumes specified in the request. This operation is only supported in the cached volume gateway types.</p> <p>The list of gateway volumes in the request must be from one gateway. In the response Amazon Storage Gateway returns volume information sorted by volume Amazon Resource Name (ARN).</p>
  ##   body: JObject (required)
  var body_21626450 = newJObject()
  if body != nil:
    body_21626450 = body
  result = call_21626449.call(nil, nil, nil, nil, body_21626450)

var describeCachediSCSIVolumes* = Call_DescribeCachediSCSIVolumes_21626436(
    name: "describeCachediSCSIVolumes", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeCachediSCSIVolumes",
    validator: validate_DescribeCachediSCSIVolumes_21626437, base: "/",
    makeUrl: url_DescribeCachediSCSIVolumes_21626438,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeChapCredentials_21626451 = ref object of OpenApiRestCall_21625437
proc url_DescribeChapCredentials_21626453(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeChapCredentials_21626452(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns an array of Challenge-Handshake Authentication Protocol (CHAP) credentials information for a specified iSCSI target, one for each target-initiator pair. This operation is supported in the volume and tape gateway types.
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
  var valid_21626454 = header.getOrDefault("X-Amz-Date")
  valid_21626454 = validateParameter(valid_21626454, JString, required = false,
                                   default = nil)
  if valid_21626454 != nil:
    section.add "X-Amz-Date", valid_21626454
  var valid_21626455 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626455 = validateParameter(valid_21626455, JString, required = false,
                                   default = nil)
  if valid_21626455 != nil:
    section.add "X-Amz-Security-Token", valid_21626455
  var valid_21626456 = header.getOrDefault("X-Amz-Target")
  valid_21626456 = validateParameter(valid_21626456, JString, required = true, default = newJString(
      "StorageGateway_20130630.DescribeChapCredentials"))
  if valid_21626456 != nil:
    section.add "X-Amz-Target", valid_21626456
  var valid_21626457 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626457 = validateParameter(valid_21626457, JString, required = false,
                                   default = nil)
  if valid_21626457 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626457
  var valid_21626458 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626458 = validateParameter(valid_21626458, JString, required = false,
                                   default = nil)
  if valid_21626458 != nil:
    section.add "X-Amz-Algorithm", valid_21626458
  var valid_21626459 = header.getOrDefault("X-Amz-Signature")
  valid_21626459 = validateParameter(valid_21626459, JString, required = false,
                                   default = nil)
  if valid_21626459 != nil:
    section.add "X-Amz-Signature", valid_21626459
  var valid_21626460 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626460 = validateParameter(valid_21626460, JString, required = false,
                                   default = nil)
  if valid_21626460 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626460
  var valid_21626461 = header.getOrDefault("X-Amz-Credential")
  valid_21626461 = validateParameter(valid_21626461, JString, required = false,
                                   default = nil)
  if valid_21626461 != nil:
    section.add "X-Amz-Credential", valid_21626461
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626463: Call_DescribeChapCredentials_21626451;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns an array of Challenge-Handshake Authentication Protocol (CHAP) credentials information for a specified iSCSI target, one for each target-initiator pair. This operation is supported in the volume and tape gateway types.
  ## 
  let valid = call_21626463.validator(path, query, header, formData, body, _)
  let scheme = call_21626463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626463.makeUrl(scheme.get, call_21626463.host, call_21626463.base,
                               call_21626463.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626463, uri, valid, _)

proc call*(call_21626464: Call_DescribeChapCredentials_21626451; body: JsonNode): Recallable =
  ## describeChapCredentials
  ## Returns an array of Challenge-Handshake Authentication Protocol (CHAP) credentials information for a specified iSCSI target, one for each target-initiator pair. This operation is supported in the volume and tape gateway types.
  ##   body: JObject (required)
  var body_21626465 = newJObject()
  if body != nil:
    body_21626465 = body
  result = call_21626464.call(nil, nil, nil, nil, body_21626465)

var describeChapCredentials* = Call_DescribeChapCredentials_21626451(
    name: "describeChapCredentials", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeChapCredentials",
    validator: validate_DescribeChapCredentials_21626452, base: "/",
    makeUrl: url_DescribeChapCredentials_21626453,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeGatewayInformation_21626466 = ref object of OpenApiRestCall_21625437
proc url_DescribeGatewayInformation_21626468(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeGatewayInformation_21626467(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns metadata about a gateway such as its name, network interfaces, configured time zone, and the state (whether the gateway is running or not). To specify which gateway to describe, use the Amazon Resource Name (ARN) of the gateway in your request.
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
  var valid_21626469 = header.getOrDefault("X-Amz-Date")
  valid_21626469 = validateParameter(valid_21626469, JString, required = false,
                                   default = nil)
  if valid_21626469 != nil:
    section.add "X-Amz-Date", valid_21626469
  var valid_21626470 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626470 = validateParameter(valid_21626470, JString, required = false,
                                   default = nil)
  if valid_21626470 != nil:
    section.add "X-Amz-Security-Token", valid_21626470
  var valid_21626471 = header.getOrDefault("X-Amz-Target")
  valid_21626471 = validateParameter(valid_21626471, JString, required = true, default = newJString(
      "StorageGateway_20130630.DescribeGatewayInformation"))
  if valid_21626471 != nil:
    section.add "X-Amz-Target", valid_21626471
  var valid_21626472 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626472 = validateParameter(valid_21626472, JString, required = false,
                                   default = nil)
  if valid_21626472 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626472
  var valid_21626473 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626473 = validateParameter(valid_21626473, JString, required = false,
                                   default = nil)
  if valid_21626473 != nil:
    section.add "X-Amz-Algorithm", valid_21626473
  var valid_21626474 = header.getOrDefault("X-Amz-Signature")
  valid_21626474 = validateParameter(valid_21626474, JString, required = false,
                                   default = nil)
  if valid_21626474 != nil:
    section.add "X-Amz-Signature", valid_21626474
  var valid_21626475 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626475 = validateParameter(valid_21626475, JString, required = false,
                                   default = nil)
  if valid_21626475 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626475
  var valid_21626476 = header.getOrDefault("X-Amz-Credential")
  valid_21626476 = validateParameter(valid_21626476, JString, required = false,
                                   default = nil)
  if valid_21626476 != nil:
    section.add "X-Amz-Credential", valid_21626476
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626478: Call_DescribeGatewayInformation_21626466;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns metadata about a gateway such as its name, network interfaces, configured time zone, and the state (whether the gateway is running or not). To specify which gateway to describe, use the Amazon Resource Name (ARN) of the gateway in your request.
  ## 
  let valid = call_21626478.validator(path, query, header, formData, body, _)
  let scheme = call_21626478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626478.makeUrl(scheme.get, call_21626478.host, call_21626478.base,
                               call_21626478.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626478, uri, valid, _)

proc call*(call_21626479: Call_DescribeGatewayInformation_21626466; body: JsonNode): Recallable =
  ## describeGatewayInformation
  ## Returns metadata about a gateway such as its name, network interfaces, configured time zone, and the state (whether the gateway is running or not). To specify which gateway to describe, use the Amazon Resource Name (ARN) of the gateway in your request.
  ##   body: JObject (required)
  var body_21626480 = newJObject()
  if body != nil:
    body_21626480 = body
  result = call_21626479.call(nil, nil, nil, nil, body_21626480)

var describeGatewayInformation* = Call_DescribeGatewayInformation_21626466(
    name: "describeGatewayInformation", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeGatewayInformation",
    validator: validate_DescribeGatewayInformation_21626467, base: "/",
    makeUrl: url_DescribeGatewayInformation_21626468,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceStartTime_21626481 = ref object of OpenApiRestCall_21625437
proc url_DescribeMaintenanceStartTime_21626483(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeMaintenanceStartTime_21626482(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Returns your gateway's weekly maintenance start time including the day and time of the week. Note that values are in terms of the gateway's time zone.
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
  var valid_21626484 = header.getOrDefault("X-Amz-Date")
  valid_21626484 = validateParameter(valid_21626484, JString, required = false,
                                   default = nil)
  if valid_21626484 != nil:
    section.add "X-Amz-Date", valid_21626484
  var valid_21626485 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626485 = validateParameter(valid_21626485, JString, required = false,
                                   default = nil)
  if valid_21626485 != nil:
    section.add "X-Amz-Security-Token", valid_21626485
  var valid_21626486 = header.getOrDefault("X-Amz-Target")
  valid_21626486 = validateParameter(valid_21626486, JString, required = true, default = newJString(
      "StorageGateway_20130630.DescribeMaintenanceStartTime"))
  if valid_21626486 != nil:
    section.add "X-Amz-Target", valid_21626486
  var valid_21626487 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626487 = validateParameter(valid_21626487, JString, required = false,
                                   default = nil)
  if valid_21626487 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626487
  var valid_21626488 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626488 = validateParameter(valid_21626488, JString, required = false,
                                   default = nil)
  if valid_21626488 != nil:
    section.add "X-Amz-Algorithm", valid_21626488
  var valid_21626489 = header.getOrDefault("X-Amz-Signature")
  valid_21626489 = validateParameter(valid_21626489, JString, required = false,
                                   default = nil)
  if valid_21626489 != nil:
    section.add "X-Amz-Signature", valid_21626489
  var valid_21626490 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626490 = validateParameter(valid_21626490, JString, required = false,
                                   default = nil)
  if valid_21626490 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626490
  var valid_21626491 = header.getOrDefault("X-Amz-Credential")
  valid_21626491 = validateParameter(valid_21626491, JString, required = false,
                                   default = nil)
  if valid_21626491 != nil:
    section.add "X-Amz-Credential", valid_21626491
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626493: Call_DescribeMaintenanceStartTime_21626481;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns your gateway's weekly maintenance start time including the day and time of the week. Note that values are in terms of the gateway's time zone.
  ## 
  let valid = call_21626493.validator(path, query, header, formData, body, _)
  let scheme = call_21626493.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626493.makeUrl(scheme.get, call_21626493.host, call_21626493.base,
                               call_21626493.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626493, uri, valid, _)

proc call*(call_21626494: Call_DescribeMaintenanceStartTime_21626481;
          body: JsonNode): Recallable =
  ## describeMaintenanceStartTime
  ## Returns your gateway's weekly maintenance start time including the day and time of the week. Note that values are in terms of the gateway's time zone.
  ##   body: JObject (required)
  var body_21626495 = newJObject()
  if body != nil:
    body_21626495 = body
  result = call_21626494.call(nil, nil, nil, nil, body_21626495)

var describeMaintenanceStartTime* = Call_DescribeMaintenanceStartTime_21626481(
    name: "describeMaintenanceStartTime", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com", route: "/#X-Amz-Target=StorageGateway_20130630.DescribeMaintenanceStartTime",
    validator: validate_DescribeMaintenanceStartTime_21626482, base: "/",
    makeUrl: url_DescribeMaintenanceStartTime_21626483,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeNFSFileShares_21626496 = ref object of OpenApiRestCall_21625437
proc url_DescribeNFSFileShares_21626498(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeNFSFileShares_21626497(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets a description for one or more Network File System (NFS) file shares from a file gateway. This operation is only supported for file gateways.
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
  var valid_21626499 = header.getOrDefault("X-Amz-Date")
  valid_21626499 = validateParameter(valid_21626499, JString, required = false,
                                   default = nil)
  if valid_21626499 != nil:
    section.add "X-Amz-Date", valid_21626499
  var valid_21626500 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626500 = validateParameter(valid_21626500, JString, required = false,
                                   default = nil)
  if valid_21626500 != nil:
    section.add "X-Amz-Security-Token", valid_21626500
  var valid_21626501 = header.getOrDefault("X-Amz-Target")
  valid_21626501 = validateParameter(valid_21626501, JString, required = true, default = newJString(
      "StorageGateway_20130630.DescribeNFSFileShares"))
  if valid_21626501 != nil:
    section.add "X-Amz-Target", valid_21626501
  var valid_21626502 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626502 = validateParameter(valid_21626502, JString, required = false,
                                   default = nil)
  if valid_21626502 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626502
  var valid_21626503 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626503 = validateParameter(valid_21626503, JString, required = false,
                                   default = nil)
  if valid_21626503 != nil:
    section.add "X-Amz-Algorithm", valid_21626503
  var valid_21626504 = header.getOrDefault("X-Amz-Signature")
  valid_21626504 = validateParameter(valid_21626504, JString, required = false,
                                   default = nil)
  if valid_21626504 != nil:
    section.add "X-Amz-Signature", valid_21626504
  var valid_21626505 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626505 = validateParameter(valid_21626505, JString, required = false,
                                   default = nil)
  if valid_21626505 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626505
  var valid_21626506 = header.getOrDefault("X-Amz-Credential")
  valid_21626506 = validateParameter(valid_21626506, JString, required = false,
                                   default = nil)
  if valid_21626506 != nil:
    section.add "X-Amz-Credential", valid_21626506
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626508: Call_DescribeNFSFileShares_21626496;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a description for one or more Network File System (NFS) file shares from a file gateway. This operation is only supported for file gateways.
  ## 
  let valid = call_21626508.validator(path, query, header, formData, body, _)
  let scheme = call_21626508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626508.makeUrl(scheme.get, call_21626508.host, call_21626508.base,
                               call_21626508.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626508, uri, valid, _)

proc call*(call_21626509: Call_DescribeNFSFileShares_21626496; body: JsonNode): Recallable =
  ## describeNFSFileShares
  ## Gets a description for one or more Network File System (NFS) file shares from a file gateway. This operation is only supported for file gateways.
  ##   body: JObject (required)
  var body_21626510 = newJObject()
  if body != nil:
    body_21626510 = body
  result = call_21626509.call(nil, nil, nil, nil, body_21626510)

var describeNFSFileShares* = Call_DescribeNFSFileShares_21626496(
    name: "describeNFSFileShares", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeNFSFileShares",
    validator: validate_DescribeNFSFileShares_21626497, base: "/",
    makeUrl: url_DescribeNFSFileShares_21626498,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSMBFileShares_21626511 = ref object of OpenApiRestCall_21625437
proc url_DescribeSMBFileShares_21626513(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeSMBFileShares_21626512(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets a description for one or more Server Message Block (SMB) file shares from a file gateway. This operation is only supported for file gateways.
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
  var valid_21626514 = header.getOrDefault("X-Amz-Date")
  valid_21626514 = validateParameter(valid_21626514, JString, required = false,
                                   default = nil)
  if valid_21626514 != nil:
    section.add "X-Amz-Date", valid_21626514
  var valid_21626515 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626515 = validateParameter(valid_21626515, JString, required = false,
                                   default = nil)
  if valid_21626515 != nil:
    section.add "X-Amz-Security-Token", valid_21626515
  var valid_21626516 = header.getOrDefault("X-Amz-Target")
  valid_21626516 = validateParameter(valid_21626516, JString, required = true, default = newJString(
      "StorageGateway_20130630.DescribeSMBFileShares"))
  if valid_21626516 != nil:
    section.add "X-Amz-Target", valid_21626516
  var valid_21626517 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626517 = validateParameter(valid_21626517, JString, required = false,
                                   default = nil)
  if valid_21626517 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626517
  var valid_21626518 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626518 = validateParameter(valid_21626518, JString, required = false,
                                   default = nil)
  if valid_21626518 != nil:
    section.add "X-Amz-Algorithm", valid_21626518
  var valid_21626519 = header.getOrDefault("X-Amz-Signature")
  valid_21626519 = validateParameter(valid_21626519, JString, required = false,
                                   default = nil)
  if valid_21626519 != nil:
    section.add "X-Amz-Signature", valid_21626519
  var valid_21626520 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626520 = validateParameter(valid_21626520, JString, required = false,
                                   default = nil)
  if valid_21626520 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626520
  var valid_21626521 = header.getOrDefault("X-Amz-Credential")
  valid_21626521 = validateParameter(valid_21626521, JString, required = false,
                                   default = nil)
  if valid_21626521 != nil:
    section.add "X-Amz-Credential", valid_21626521
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626523: Call_DescribeSMBFileShares_21626511;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a description for one or more Server Message Block (SMB) file shares from a file gateway. This operation is only supported for file gateways.
  ## 
  let valid = call_21626523.validator(path, query, header, formData, body, _)
  let scheme = call_21626523.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626523.makeUrl(scheme.get, call_21626523.host, call_21626523.base,
                               call_21626523.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626523, uri, valid, _)

proc call*(call_21626524: Call_DescribeSMBFileShares_21626511; body: JsonNode): Recallable =
  ## describeSMBFileShares
  ## Gets a description for one or more Server Message Block (SMB) file shares from a file gateway. This operation is only supported for file gateways.
  ##   body: JObject (required)
  var body_21626525 = newJObject()
  if body != nil:
    body_21626525 = body
  result = call_21626524.call(nil, nil, nil, nil, body_21626525)

var describeSMBFileShares* = Call_DescribeSMBFileShares_21626511(
    name: "describeSMBFileShares", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeSMBFileShares",
    validator: validate_DescribeSMBFileShares_21626512, base: "/",
    makeUrl: url_DescribeSMBFileShares_21626513,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSMBSettings_21626526 = ref object of OpenApiRestCall_21625437
proc url_DescribeSMBSettings_21626528(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeSMBSettings_21626527(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets a description of a Server Message Block (SMB) file share settings from a file gateway. This operation is only supported for file gateways.
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
  var valid_21626529 = header.getOrDefault("X-Amz-Date")
  valid_21626529 = validateParameter(valid_21626529, JString, required = false,
                                   default = nil)
  if valid_21626529 != nil:
    section.add "X-Amz-Date", valid_21626529
  var valid_21626530 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626530 = validateParameter(valid_21626530, JString, required = false,
                                   default = nil)
  if valid_21626530 != nil:
    section.add "X-Amz-Security-Token", valid_21626530
  var valid_21626531 = header.getOrDefault("X-Amz-Target")
  valid_21626531 = validateParameter(valid_21626531, JString, required = true, default = newJString(
      "StorageGateway_20130630.DescribeSMBSettings"))
  if valid_21626531 != nil:
    section.add "X-Amz-Target", valid_21626531
  var valid_21626532 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626532 = validateParameter(valid_21626532, JString, required = false,
                                   default = nil)
  if valid_21626532 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626532
  var valid_21626533 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626533 = validateParameter(valid_21626533, JString, required = false,
                                   default = nil)
  if valid_21626533 != nil:
    section.add "X-Amz-Algorithm", valid_21626533
  var valid_21626534 = header.getOrDefault("X-Amz-Signature")
  valid_21626534 = validateParameter(valid_21626534, JString, required = false,
                                   default = nil)
  if valid_21626534 != nil:
    section.add "X-Amz-Signature", valid_21626534
  var valid_21626535 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626535 = validateParameter(valid_21626535, JString, required = false,
                                   default = nil)
  if valid_21626535 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626535
  var valid_21626536 = header.getOrDefault("X-Amz-Credential")
  valid_21626536 = validateParameter(valid_21626536, JString, required = false,
                                   default = nil)
  if valid_21626536 != nil:
    section.add "X-Amz-Credential", valid_21626536
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626538: Call_DescribeSMBSettings_21626526; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a description of a Server Message Block (SMB) file share settings from a file gateway. This operation is only supported for file gateways.
  ## 
  let valid = call_21626538.validator(path, query, header, formData, body, _)
  let scheme = call_21626538.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626538.makeUrl(scheme.get, call_21626538.host, call_21626538.base,
                               call_21626538.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626538, uri, valid, _)

proc call*(call_21626539: Call_DescribeSMBSettings_21626526; body: JsonNode): Recallable =
  ## describeSMBSettings
  ## Gets a description of a Server Message Block (SMB) file share settings from a file gateway. This operation is only supported for file gateways.
  ##   body: JObject (required)
  var body_21626540 = newJObject()
  if body != nil:
    body_21626540 = body
  result = call_21626539.call(nil, nil, nil, nil, body_21626540)

var describeSMBSettings* = Call_DescribeSMBSettings_21626526(
    name: "describeSMBSettings", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeSMBSettings",
    validator: validate_DescribeSMBSettings_21626527, base: "/",
    makeUrl: url_DescribeSMBSettings_21626528,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSnapshotSchedule_21626541 = ref object of OpenApiRestCall_21625437
proc url_DescribeSnapshotSchedule_21626543(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeSnapshotSchedule_21626542(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Describes the snapshot schedule for the specified gateway volume. The snapshot schedule information includes intervals at which snapshots are automatically initiated on the volume. This operation is only supported in the cached volume and stored volume types.
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
  var valid_21626544 = header.getOrDefault("X-Amz-Date")
  valid_21626544 = validateParameter(valid_21626544, JString, required = false,
                                   default = nil)
  if valid_21626544 != nil:
    section.add "X-Amz-Date", valid_21626544
  var valid_21626545 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626545 = validateParameter(valid_21626545, JString, required = false,
                                   default = nil)
  if valid_21626545 != nil:
    section.add "X-Amz-Security-Token", valid_21626545
  var valid_21626546 = header.getOrDefault("X-Amz-Target")
  valid_21626546 = validateParameter(valid_21626546, JString, required = true, default = newJString(
      "StorageGateway_20130630.DescribeSnapshotSchedule"))
  if valid_21626546 != nil:
    section.add "X-Amz-Target", valid_21626546
  var valid_21626547 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626547 = validateParameter(valid_21626547, JString, required = false,
                                   default = nil)
  if valid_21626547 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626547
  var valid_21626548 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626548 = validateParameter(valid_21626548, JString, required = false,
                                   default = nil)
  if valid_21626548 != nil:
    section.add "X-Amz-Algorithm", valid_21626548
  var valid_21626549 = header.getOrDefault("X-Amz-Signature")
  valid_21626549 = validateParameter(valid_21626549, JString, required = false,
                                   default = nil)
  if valid_21626549 != nil:
    section.add "X-Amz-Signature", valid_21626549
  var valid_21626550 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626550 = validateParameter(valid_21626550, JString, required = false,
                                   default = nil)
  if valid_21626550 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626550
  var valid_21626551 = header.getOrDefault("X-Amz-Credential")
  valid_21626551 = validateParameter(valid_21626551, JString, required = false,
                                   default = nil)
  if valid_21626551 != nil:
    section.add "X-Amz-Credential", valid_21626551
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626553: Call_DescribeSnapshotSchedule_21626541;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the snapshot schedule for the specified gateway volume. The snapshot schedule information includes intervals at which snapshots are automatically initiated on the volume. This operation is only supported in the cached volume and stored volume types.
  ## 
  let valid = call_21626553.validator(path, query, header, formData, body, _)
  let scheme = call_21626553.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626553.makeUrl(scheme.get, call_21626553.host, call_21626553.base,
                               call_21626553.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626553, uri, valid, _)

proc call*(call_21626554: Call_DescribeSnapshotSchedule_21626541; body: JsonNode): Recallable =
  ## describeSnapshotSchedule
  ## Describes the snapshot schedule for the specified gateway volume. The snapshot schedule information includes intervals at which snapshots are automatically initiated on the volume. This operation is only supported in the cached volume and stored volume types.
  ##   body: JObject (required)
  var body_21626555 = newJObject()
  if body != nil:
    body_21626555 = body
  result = call_21626554.call(nil, nil, nil, nil, body_21626555)

var describeSnapshotSchedule* = Call_DescribeSnapshotSchedule_21626541(
    name: "describeSnapshotSchedule", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeSnapshotSchedule",
    validator: validate_DescribeSnapshotSchedule_21626542, base: "/",
    makeUrl: url_DescribeSnapshotSchedule_21626543,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeStorediSCSIVolumes_21626556 = ref object of OpenApiRestCall_21625437
proc url_DescribeStorediSCSIVolumes_21626558(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeStorediSCSIVolumes_21626557(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns the description of the gateway volumes specified in the request. The list of gateway volumes in the request must be from one gateway. In the response Amazon Storage Gateway returns volume information sorted by volume ARNs. This operation is only supported in stored volume gateway type.
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
  var valid_21626559 = header.getOrDefault("X-Amz-Date")
  valid_21626559 = validateParameter(valid_21626559, JString, required = false,
                                   default = nil)
  if valid_21626559 != nil:
    section.add "X-Amz-Date", valid_21626559
  var valid_21626560 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626560 = validateParameter(valid_21626560, JString, required = false,
                                   default = nil)
  if valid_21626560 != nil:
    section.add "X-Amz-Security-Token", valid_21626560
  var valid_21626561 = header.getOrDefault("X-Amz-Target")
  valid_21626561 = validateParameter(valid_21626561, JString, required = true, default = newJString(
      "StorageGateway_20130630.DescribeStorediSCSIVolumes"))
  if valid_21626561 != nil:
    section.add "X-Amz-Target", valid_21626561
  var valid_21626562 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626562 = validateParameter(valid_21626562, JString, required = false,
                                   default = nil)
  if valid_21626562 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626562
  var valid_21626563 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626563 = validateParameter(valid_21626563, JString, required = false,
                                   default = nil)
  if valid_21626563 != nil:
    section.add "X-Amz-Algorithm", valid_21626563
  var valid_21626564 = header.getOrDefault("X-Amz-Signature")
  valid_21626564 = validateParameter(valid_21626564, JString, required = false,
                                   default = nil)
  if valid_21626564 != nil:
    section.add "X-Amz-Signature", valid_21626564
  var valid_21626565 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626565 = validateParameter(valid_21626565, JString, required = false,
                                   default = nil)
  if valid_21626565 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626565
  var valid_21626566 = header.getOrDefault("X-Amz-Credential")
  valid_21626566 = validateParameter(valid_21626566, JString, required = false,
                                   default = nil)
  if valid_21626566 != nil:
    section.add "X-Amz-Credential", valid_21626566
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626568: Call_DescribeStorediSCSIVolumes_21626556;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the description of the gateway volumes specified in the request. The list of gateway volumes in the request must be from one gateway. In the response Amazon Storage Gateway returns volume information sorted by volume ARNs. This operation is only supported in stored volume gateway type.
  ## 
  let valid = call_21626568.validator(path, query, header, formData, body, _)
  let scheme = call_21626568.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626568.makeUrl(scheme.get, call_21626568.host, call_21626568.base,
                               call_21626568.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626568, uri, valid, _)

proc call*(call_21626569: Call_DescribeStorediSCSIVolumes_21626556; body: JsonNode): Recallable =
  ## describeStorediSCSIVolumes
  ## Returns the description of the gateway volumes specified in the request. The list of gateway volumes in the request must be from one gateway. In the response Amazon Storage Gateway returns volume information sorted by volume ARNs. This operation is only supported in stored volume gateway type.
  ##   body: JObject (required)
  var body_21626570 = newJObject()
  if body != nil:
    body_21626570 = body
  result = call_21626569.call(nil, nil, nil, nil, body_21626570)

var describeStorediSCSIVolumes* = Call_DescribeStorediSCSIVolumes_21626556(
    name: "describeStorediSCSIVolumes", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeStorediSCSIVolumes",
    validator: validate_DescribeStorediSCSIVolumes_21626557, base: "/",
    makeUrl: url_DescribeStorediSCSIVolumes_21626558,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTapeArchives_21626571 = ref object of OpenApiRestCall_21625437
proc url_DescribeTapeArchives_21626573(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTapeArchives_21626572(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns a description of specified virtual tapes in the virtual tape shelf (VTS). This operation is only supported in the tape gateway type.</p> <p>If a specific <code>TapeARN</code> is not specified, AWS Storage Gateway returns a description of all virtual tapes found in the VTS associated with your account.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Limit: JString
  ##        : Pagination limit
  ##   Marker: JString
  ##         : Pagination token
  section = newJObject()
  var valid_21626574 = query.getOrDefault("Limit")
  valid_21626574 = validateParameter(valid_21626574, JString, required = false,
                                   default = nil)
  if valid_21626574 != nil:
    section.add "Limit", valid_21626574
  var valid_21626575 = query.getOrDefault("Marker")
  valid_21626575 = validateParameter(valid_21626575, JString, required = false,
                                   default = nil)
  if valid_21626575 != nil:
    section.add "Marker", valid_21626575
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626576 = header.getOrDefault("X-Amz-Date")
  valid_21626576 = validateParameter(valid_21626576, JString, required = false,
                                   default = nil)
  if valid_21626576 != nil:
    section.add "X-Amz-Date", valid_21626576
  var valid_21626577 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626577 = validateParameter(valid_21626577, JString, required = false,
                                   default = nil)
  if valid_21626577 != nil:
    section.add "X-Amz-Security-Token", valid_21626577
  var valid_21626578 = header.getOrDefault("X-Amz-Target")
  valid_21626578 = validateParameter(valid_21626578, JString, required = true, default = newJString(
      "StorageGateway_20130630.DescribeTapeArchives"))
  if valid_21626578 != nil:
    section.add "X-Amz-Target", valid_21626578
  var valid_21626579 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626579 = validateParameter(valid_21626579, JString, required = false,
                                   default = nil)
  if valid_21626579 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626579
  var valid_21626580 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626580 = validateParameter(valid_21626580, JString, required = false,
                                   default = nil)
  if valid_21626580 != nil:
    section.add "X-Amz-Algorithm", valid_21626580
  var valid_21626581 = header.getOrDefault("X-Amz-Signature")
  valid_21626581 = validateParameter(valid_21626581, JString, required = false,
                                   default = nil)
  if valid_21626581 != nil:
    section.add "X-Amz-Signature", valid_21626581
  var valid_21626582 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626582 = validateParameter(valid_21626582, JString, required = false,
                                   default = nil)
  if valid_21626582 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626582
  var valid_21626583 = header.getOrDefault("X-Amz-Credential")
  valid_21626583 = validateParameter(valid_21626583, JString, required = false,
                                   default = nil)
  if valid_21626583 != nil:
    section.add "X-Amz-Credential", valid_21626583
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626585: Call_DescribeTapeArchives_21626571; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns a description of specified virtual tapes in the virtual tape shelf (VTS). This operation is only supported in the tape gateway type.</p> <p>If a specific <code>TapeARN</code> is not specified, AWS Storage Gateway returns a description of all virtual tapes found in the VTS associated with your account.</p>
  ## 
  let valid = call_21626585.validator(path, query, header, formData, body, _)
  let scheme = call_21626585.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626585.makeUrl(scheme.get, call_21626585.host, call_21626585.base,
                               call_21626585.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626585, uri, valid, _)

proc call*(call_21626586: Call_DescribeTapeArchives_21626571; body: JsonNode;
          Limit: string = ""; Marker: string = ""): Recallable =
  ## describeTapeArchives
  ## <p>Returns a description of specified virtual tapes in the virtual tape shelf (VTS). This operation is only supported in the tape gateway type.</p> <p>If a specific <code>TapeARN</code> is not specified, AWS Storage Gateway returns a description of all virtual tapes found in the VTS associated with your account.</p>
  ##   Limit: string
  ##        : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_21626588 = newJObject()
  var body_21626589 = newJObject()
  add(query_21626588, "Limit", newJString(Limit))
  add(query_21626588, "Marker", newJString(Marker))
  if body != nil:
    body_21626589 = body
  result = call_21626586.call(nil, query_21626588, nil, nil, body_21626589)

var describeTapeArchives* = Call_DescribeTapeArchives_21626571(
    name: "describeTapeArchives", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeTapeArchives",
    validator: validate_DescribeTapeArchives_21626572, base: "/",
    makeUrl: url_DescribeTapeArchives_21626573,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTapeRecoveryPoints_21626593 = ref object of OpenApiRestCall_21625437
proc url_DescribeTapeRecoveryPoints_21626595(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTapeRecoveryPoints_21626594(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns a list of virtual tape recovery points that are available for the specified tape gateway.</p> <p>A recovery point is a point-in-time view of a virtual tape at which all the data on the virtual tape is consistent. If your gateway crashes, virtual tapes that have recovery points can be recovered to a new gateway. This operation is only supported in the tape gateway type.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Limit: JString
  ##        : Pagination limit
  ##   Marker: JString
  ##         : Pagination token
  section = newJObject()
  var valid_21626596 = query.getOrDefault("Limit")
  valid_21626596 = validateParameter(valid_21626596, JString, required = false,
                                   default = nil)
  if valid_21626596 != nil:
    section.add "Limit", valid_21626596
  var valid_21626597 = query.getOrDefault("Marker")
  valid_21626597 = validateParameter(valid_21626597, JString, required = false,
                                   default = nil)
  if valid_21626597 != nil:
    section.add "Marker", valid_21626597
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626598 = header.getOrDefault("X-Amz-Date")
  valid_21626598 = validateParameter(valid_21626598, JString, required = false,
                                   default = nil)
  if valid_21626598 != nil:
    section.add "X-Amz-Date", valid_21626598
  var valid_21626599 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626599 = validateParameter(valid_21626599, JString, required = false,
                                   default = nil)
  if valid_21626599 != nil:
    section.add "X-Amz-Security-Token", valid_21626599
  var valid_21626600 = header.getOrDefault("X-Amz-Target")
  valid_21626600 = validateParameter(valid_21626600, JString, required = true, default = newJString(
      "StorageGateway_20130630.DescribeTapeRecoveryPoints"))
  if valid_21626600 != nil:
    section.add "X-Amz-Target", valid_21626600
  var valid_21626601 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626601 = validateParameter(valid_21626601, JString, required = false,
                                   default = nil)
  if valid_21626601 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626601
  var valid_21626602 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626602 = validateParameter(valid_21626602, JString, required = false,
                                   default = nil)
  if valid_21626602 != nil:
    section.add "X-Amz-Algorithm", valid_21626602
  var valid_21626603 = header.getOrDefault("X-Amz-Signature")
  valid_21626603 = validateParameter(valid_21626603, JString, required = false,
                                   default = nil)
  if valid_21626603 != nil:
    section.add "X-Amz-Signature", valid_21626603
  var valid_21626604 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626604 = validateParameter(valid_21626604, JString, required = false,
                                   default = nil)
  if valid_21626604 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626604
  var valid_21626605 = header.getOrDefault("X-Amz-Credential")
  valid_21626605 = validateParameter(valid_21626605, JString, required = false,
                                   default = nil)
  if valid_21626605 != nil:
    section.add "X-Amz-Credential", valid_21626605
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626607: Call_DescribeTapeRecoveryPoints_21626593;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns a list of virtual tape recovery points that are available for the specified tape gateway.</p> <p>A recovery point is a point-in-time view of a virtual tape at which all the data on the virtual tape is consistent. If your gateway crashes, virtual tapes that have recovery points can be recovered to a new gateway. This operation is only supported in the tape gateway type.</p>
  ## 
  let valid = call_21626607.validator(path, query, header, formData, body, _)
  let scheme = call_21626607.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626607.makeUrl(scheme.get, call_21626607.host, call_21626607.base,
                               call_21626607.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626607, uri, valid, _)

proc call*(call_21626608: Call_DescribeTapeRecoveryPoints_21626593; body: JsonNode;
          Limit: string = ""; Marker: string = ""): Recallable =
  ## describeTapeRecoveryPoints
  ## <p>Returns a list of virtual tape recovery points that are available for the specified tape gateway.</p> <p>A recovery point is a point-in-time view of a virtual tape at which all the data on the virtual tape is consistent. If your gateway crashes, virtual tapes that have recovery points can be recovered to a new gateway. This operation is only supported in the tape gateway type.</p>
  ##   Limit: string
  ##        : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_21626609 = newJObject()
  var body_21626610 = newJObject()
  add(query_21626609, "Limit", newJString(Limit))
  add(query_21626609, "Marker", newJString(Marker))
  if body != nil:
    body_21626610 = body
  result = call_21626608.call(nil, query_21626609, nil, nil, body_21626610)

var describeTapeRecoveryPoints* = Call_DescribeTapeRecoveryPoints_21626593(
    name: "describeTapeRecoveryPoints", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeTapeRecoveryPoints",
    validator: validate_DescribeTapeRecoveryPoints_21626594, base: "/",
    makeUrl: url_DescribeTapeRecoveryPoints_21626595,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTapes_21626611 = ref object of OpenApiRestCall_21625437
proc url_DescribeTapes_21626613(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTapes_21626612(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Returns a description of the specified Amazon Resource Name (ARN) of virtual tapes. If a <code>TapeARN</code> is not specified, returns a description of all virtual tapes associated with the specified gateway. This operation is only supported in the tape gateway type.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Limit: JString
  ##        : Pagination limit
  ##   Marker: JString
  ##         : Pagination token
  section = newJObject()
  var valid_21626614 = query.getOrDefault("Limit")
  valid_21626614 = validateParameter(valid_21626614, JString, required = false,
                                   default = nil)
  if valid_21626614 != nil:
    section.add "Limit", valid_21626614
  var valid_21626615 = query.getOrDefault("Marker")
  valid_21626615 = validateParameter(valid_21626615, JString, required = false,
                                   default = nil)
  if valid_21626615 != nil:
    section.add "Marker", valid_21626615
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626616 = header.getOrDefault("X-Amz-Date")
  valid_21626616 = validateParameter(valid_21626616, JString, required = false,
                                   default = nil)
  if valid_21626616 != nil:
    section.add "X-Amz-Date", valid_21626616
  var valid_21626617 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626617 = validateParameter(valid_21626617, JString, required = false,
                                   default = nil)
  if valid_21626617 != nil:
    section.add "X-Amz-Security-Token", valid_21626617
  var valid_21626618 = header.getOrDefault("X-Amz-Target")
  valid_21626618 = validateParameter(valid_21626618, JString, required = true, default = newJString(
      "StorageGateway_20130630.DescribeTapes"))
  if valid_21626618 != nil:
    section.add "X-Amz-Target", valid_21626618
  var valid_21626619 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626619 = validateParameter(valid_21626619, JString, required = false,
                                   default = nil)
  if valid_21626619 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626619
  var valid_21626620 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626620 = validateParameter(valid_21626620, JString, required = false,
                                   default = nil)
  if valid_21626620 != nil:
    section.add "X-Amz-Algorithm", valid_21626620
  var valid_21626621 = header.getOrDefault("X-Amz-Signature")
  valid_21626621 = validateParameter(valid_21626621, JString, required = false,
                                   default = nil)
  if valid_21626621 != nil:
    section.add "X-Amz-Signature", valid_21626621
  var valid_21626622 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626622 = validateParameter(valid_21626622, JString, required = false,
                                   default = nil)
  if valid_21626622 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626622
  var valid_21626623 = header.getOrDefault("X-Amz-Credential")
  valid_21626623 = validateParameter(valid_21626623, JString, required = false,
                                   default = nil)
  if valid_21626623 != nil:
    section.add "X-Amz-Credential", valid_21626623
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626625: Call_DescribeTapes_21626611; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a description of the specified Amazon Resource Name (ARN) of virtual tapes. If a <code>TapeARN</code> is not specified, returns a description of all virtual tapes associated with the specified gateway. This operation is only supported in the tape gateway type.
  ## 
  let valid = call_21626625.validator(path, query, header, formData, body, _)
  let scheme = call_21626625.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626625.makeUrl(scheme.get, call_21626625.host, call_21626625.base,
                               call_21626625.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626625, uri, valid, _)

proc call*(call_21626626: Call_DescribeTapes_21626611; body: JsonNode;
          Limit: string = ""; Marker: string = ""): Recallable =
  ## describeTapes
  ## Returns a description of the specified Amazon Resource Name (ARN) of virtual tapes. If a <code>TapeARN</code> is not specified, returns a description of all virtual tapes associated with the specified gateway. This operation is only supported in the tape gateway type.
  ##   Limit: string
  ##        : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_21626627 = newJObject()
  var body_21626628 = newJObject()
  add(query_21626627, "Limit", newJString(Limit))
  add(query_21626627, "Marker", newJString(Marker))
  if body != nil:
    body_21626628 = body
  result = call_21626626.call(nil, query_21626627, nil, nil, body_21626628)

var describeTapes* = Call_DescribeTapes_21626611(name: "describeTapes",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeTapes",
    validator: validate_DescribeTapes_21626612, base: "/",
    makeUrl: url_DescribeTapes_21626613, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUploadBuffer_21626629 = ref object of OpenApiRestCall_21625437
proc url_DescribeUploadBuffer_21626631(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeUploadBuffer_21626630(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns information about the upload buffer of a gateway. This operation is supported for the stored volume, cached volume and tape gateway types.</p> <p>The response includes disk IDs that are configured as upload buffer space, and it includes the amount of upload buffer space allocated and used.</p>
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
  var valid_21626632 = header.getOrDefault("X-Amz-Date")
  valid_21626632 = validateParameter(valid_21626632, JString, required = false,
                                   default = nil)
  if valid_21626632 != nil:
    section.add "X-Amz-Date", valid_21626632
  var valid_21626633 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626633 = validateParameter(valid_21626633, JString, required = false,
                                   default = nil)
  if valid_21626633 != nil:
    section.add "X-Amz-Security-Token", valid_21626633
  var valid_21626634 = header.getOrDefault("X-Amz-Target")
  valid_21626634 = validateParameter(valid_21626634, JString, required = true, default = newJString(
      "StorageGateway_20130630.DescribeUploadBuffer"))
  if valid_21626634 != nil:
    section.add "X-Amz-Target", valid_21626634
  var valid_21626635 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626635 = validateParameter(valid_21626635, JString, required = false,
                                   default = nil)
  if valid_21626635 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626635
  var valid_21626636 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626636 = validateParameter(valid_21626636, JString, required = false,
                                   default = nil)
  if valid_21626636 != nil:
    section.add "X-Amz-Algorithm", valid_21626636
  var valid_21626637 = header.getOrDefault("X-Amz-Signature")
  valid_21626637 = validateParameter(valid_21626637, JString, required = false,
                                   default = nil)
  if valid_21626637 != nil:
    section.add "X-Amz-Signature", valid_21626637
  var valid_21626638 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626638 = validateParameter(valid_21626638, JString, required = false,
                                   default = nil)
  if valid_21626638 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626638
  var valid_21626639 = header.getOrDefault("X-Amz-Credential")
  valid_21626639 = validateParameter(valid_21626639, JString, required = false,
                                   default = nil)
  if valid_21626639 != nil:
    section.add "X-Amz-Credential", valid_21626639
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626641: Call_DescribeUploadBuffer_21626629; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns information about the upload buffer of a gateway. This operation is supported for the stored volume, cached volume and tape gateway types.</p> <p>The response includes disk IDs that are configured as upload buffer space, and it includes the amount of upload buffer space allocated and used.</p>
  ## 
  let valid = call_21626641.validator(path, query, header, formData, body, _)
  let scheme = call_21626641.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626641.makeUrl(scheme.get, call_21626641.host, call_21626641.base,
                               call_21626641.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626641, uri, valid, _)

proc call*(call_21626642: Call_DescribeUploadBuffer_21626629; body: JsonNode): Recallable =
  ## describeUploadBuffer
  ## <p>Returns information about the upload buffer of a gateway. This operation is supported for the stored volume, cached volume and tape gateway types.</p> <p>The response includes disk IDs that are configured as upload buffer space, and it includes the amount of upload buffer space allocated and used.</p>
  ##   body: JObject (required)
  var body_21626643 = newJObject()
  if body != nil:
    body_21626643 = body
  result = call_21626642.call(nil, nil, nil, nil, body_21626643)

var describeUploadBuffer* = Call_DescribeUploadBuffer_21626629(
    name: "describeUploadBuffer", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeUploadBuffer",
    validator: validate_DescribeUploadBuffer_21626630, base: "/",
    makeUrl: url_DescribeUploadBuffer_21626631,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeVTLDevices_21626644 = ref object of OpenApiRestCall_21625437
proc url_DescribeVTLDevices_21626646(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeVTLDevices_21626645(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns a description of virtual tape library (VTL) devices for the specified tape gateway. In the response, AWS Storage Gateway returns VTL device information.</p> <p>This operation is only supported in the tape gateway type.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Limit: JString
  ##        : Pagination limit
  ##   Marker: JString
  ##         : Pagination token
  section = newJObject()
  var valid_21626647 = query.getOrDefault("Limit")
  valid_21626647 = validateParameter(valid_21626647, JString, required = false,
                                   default = nil)
  if valid_21626647 != nil:
    section.add "Limit", valid_21626647
  var valid_21626648 = query.getOrDefault("Marker")
  valid_21626648 = validateParameter(valid_21626648, JString, required = false,
                                   default = nil)
  if valid_21626648 != nil:
    section.add "Marker", valid_21626648
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626649 = header.getOrDefault("X-Amz-Date")
  valid_21626649 = validateParameter(valid_21626649, JString, required = false,
                                   default = nil)
  if valid_21626649 != nil:
    section.add "X-Amz-Date", valid_21626649
  var valid_21626650 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626650 = validateParameter(valid_21626650, JString, required = false,
                                   default = nil)
  if valid_21626650 != nil:
    section.add "X-Amz-Security-Token", valid_21626650
  var valid_21626651 = header.getOrDefault("X-Amz-Target")
  valid_21626651 = validateParameter(valid_21626651, JString, required = true, default = newJString(
      "StorageGateway_20130630.DescribeVTLDevices"))
  if valid_21626651 != nil:
    section.add "X-Amz-Target", valid_21626651
  var valid_21626652 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626652 = validateParameter(valid_21626652, JString, required = false,
                                   default = nil)
  if valid_21626652 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626652
  var valid_21626653 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626653 = validateParameter(valid_21626653, JString, required = false,
                                   default = nil)
  if valid_21626653 != nil:
    section.add "X-Amz-Algorithm", valid_21626653
  var valid_21626654 = header.getOrDefault("X-Amz-Signature")
  valid_21626654 = validateParameter(valid_21626654, JString, required = false,
                                   default = nil)
  if valid_21626654 != nil:
    section.add "X-Amz-Signature", valid_21626654
  var valid_21626655 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626655 = validateParameter(valid_21626655, JString, required = false,
                                   default = nil)
  if valid_21626655 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626655
  var valid_21626656 = header.getOrDefault("X-Amz-Credential")
  valid_21626656 = validateParameter(valid_21626656, JString, required = false,
                                   default = nil)
  if valid_21626656 != nil:
    section.add "X-Amz-Credential", valid_21626656
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626658: Call_DescribeVTLDevices_21626644; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns a description of virtual tape library (VTL) devices for the specified tape gateway. In the response, AWS Storage Gateway returns VTL device information.</p> <p>This operation is only supported in the tape gateway type.</p>
  ## 
  let valid = call_21626658.validator(path, query, header, formData, body, _)
  let scheme = call_21626658.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626658.makeUrl(scheme.get, call_21626658.host, call_21626658.base,
                               call_21626658.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626658, uri, valid, _)

proc call*(call_21626659: Call_DescribeVTLDevices_21626644; body: JsonNode;
          Limit: string = ""; Marker: string = ""): Recallable =
  ## describeVTLDevices
  ## <p>Returns a description of virtual tape library (VTL) devices for the specified tape gateway. In the response, AWS Storage Gateway returns VTL device information.</p> <p>This operation is only supported in the tape gateway type.</p>
  ##   Limit: string
  ##        : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_21626660 = newJObject()
  var body_21626661 = newJObject()
  add(query_21626660, "Limit", newJString(Limit))
  add(query_21626660, "Marker", newJString(Marker))
  if body != nil:
    body_21626661 = body
  result = call_21626659.call(nil, query_21626660, nil, nil, body_21626661)

var describeVTLDevices* = Call_DescribeVTLDevices_21626644(
    name: "describeVTLDevices", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeVTLDevices",
    validator: validate_DescribeVTLDevices_21626645, base: "/",
    makeUrl: url_DescribeVTLDevices_21626646, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkingStorage_21626662 = ref object of OpenApiRestCall_21625437
proc url_DescribeWorkingStorage_21626664(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeWorkingStorage_21626663(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns information about the working storage of a gateway. This operation is only supported in the stored volumes gateway type. This operation is deprecated in cached volumes API version (20120630). Use DescribeUploadBuffer instead.</p> <note> <p>Working storage is also referred to as upload buffer. You can also use the DescribeUploadBuffer operation to add upload buffer to a stored volume gateway.</p> </note> <p>The response includes disk IDs that are configured as working storage, and it includes the amount of working storage allocated and used.</p>
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
  var valid_21626665 = header.getOrDefault("X-Amz-Date")
  valid_21626665 = validateParameter(valid_21626665, JString, required = false,
                                   default = nil)
  if valid_21626665 != nil:
    section.add "X-Amz-Date", valid_21626665
  var valid_21626666 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626666 = validateParameter(valid_21626666, JString, required = false,
                                   default = nil)
  if valid_21626666 != nil:
    section.add "X-Amz-Security-Token", valid_21626666
  var valid_21626667 = header.getOrDefault("X-Amz-Target")
  valid_21626667 = validateParameter(valid_21626667, JString, required = true, default = newJString(
      "StorageGateway_20130630.DescribeWorkingStorage"))
  if valid_21626667 != nil:
    section.add "X-Amz-Target", valid_21626667
  var valid_21626668 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626668 = validateParameter(valid_21626668, JString, required = false,
                                   default = nil)
  if valid_21626668 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626668
  var valid_21626669 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626669 = validateParameter(valid_21626669, JString, required = false,
                                   default = nil)
  if valid_21626669 != nil:
    section.add "X-Amz-Algorithm", valid_21626669
  var valid_21626670 = header.getOrDefault("X-Amz-Signature")
  valid_21626670 = validateParameter(valid_21626670, JString, required = false,
                                   default = nil)
  if valid_21626670 != nil:
    section.add "X-Amz-Signature", valid_21626670
  var valid_21626671 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626671 = validateParameter(valid_21626671, JString, required = false,
                                   default = nil)
  if valid_21626671 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626671
  var valid_21626672 = header.getOrDefault("X-Amz-Credential")
  valid_21626672 = validateParameter(valid_21626672, JString, required = false,
                                   default = nil)
  if valid_21626672 != nil:
    section.add "X-Amz-Credential", valid_21626672
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626674: Call_DescribeWorkingStorage_21626662;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns information about the working storage of a gateway. This operation is only supported in the stored volumes gateway type. This operation is deprecated in cached volumes API version (20120630). Use DescribeUploadBuffer instead.</p> <note> <p>Working storage is also referred to as upload buffer. You can also use the DescribeUploadBuffer operation to add upload buffer to a stored volume gateway.</p> </note> <p>The response includes disk IDs that are configured as working storage, and it includes the amount of working storage allocated and used.</p>
  ## 
  let valid = call_21626674.validator(path, query, header, formData, body, _)
  let scheme = call_21626674.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626674.makeUrl(scheme.get, call_21626674.host, call_21626674.base,
                               call_21626674.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626674, uri, valid, _)

proc call*(call_21626675: Call_DescribeWorkingStorage_21626662; body: JsonNode): Recallable =
  ## describeWorkingStorage
  ## <p>Returns information about the working storage of a gateway. This operation is only supported in the stored volumes gateway type. This operation is deprecated in cached volumes API version (20120630). Use DescribeUploadBuffer instead.</p> <note> <p>Working storage is also referred to as upload buffer. You can also use the DescribeUploadBuffer operation to add upload buffer to a stored volume gateway.</p> </note> <p>The response includes disk IDs that are configured as working storage, and it includes the amount of working storage allocated and used.</p>
  ##   body: JObject (required)
  var body_21626676 = newJObject()
  if body != nil:
    body_21626676 = body
  result = call_21626675.call(nil, nil, nil, nil, body_21626676)

var describeWorkingStorage* = Call_DescribeWorkingStorage_21626662(
    name: "describeWorkingStorage", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeWorkingStorage",
    validator: validate_DescribeWorkingStorage_21626663, base: "/",
    makeUrl: url_DescribeWorkingStorage_21626664,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachVolume_21626677 = ref object of OpenApiRestCall_21625437
proc url_DetachVolume_21626679(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DetachVolume_21626678(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Disconnects a volume from an iSCSI connection and then detaches the volume from the specified gateway. Detaching and attaching a volume enables you to recover your data from one gateway to a different gateway without creating a snapshot. It also makes it easier to move your volumes from an on-premises gateway to a gateway hosted on an Amazon EC2 instance. This operation is only supported in the volume gateway type.
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
  var valid_21626680 = header.getOrDefault("X-Amz-Date")
  valid_21626680 = validateParameter(valid_21626680, JString, required = false,
                                   default = nil)
  if valid_21626680 != nil:
    section.add "X-Amz-Date", valid_21626680
  var valid_21626681 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626681 = validateParameter(valid_21626681, JString, required = false,
                                   default = nil)
  if valid_21626681 != nil:
    section.add "X-Amz-Security-Token", valid_21626681
  var valid_21626682 = header.getOrDefault("X-Amz-Target")
  valid_21626682 = validateParameter(valid_21626682, JString, required = true, default = newJString(
      "StorageGateway_20130630.DetachVolume"))
  if valid_21626682 != nil:
    section.add "X-Amz-Target", valid_21626682
  var valid_21626683 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626683 = validateParameter(valid_21626683, JString, required = false,
                                   default = nil)
  if valid_21626683 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626683
  var valid_21626684 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626684 = validateParameter(valid_21626684, JString, required = false,
                                   default = nil)
  if valid_21626684 != nil:
    section.add "X-Amz-Algorithm", valid_21626684
  var valid_21626685 = header.getOrDefault("X-Amz-Signature")
  valid_21626685 = validateParameter(valid_21626685, JString, required = false,
                                   default = nil)
  if valid_21626685 != nil:
    section.add "X-Amz-Signature", valid_21626685
  var valid_21626686 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626686 = validateParameter(valid_21626686, JString, required = false,
                                   default = nil)
  if valid_21626686 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626686
  var valid_21626687 = header.getOrDefault("X-Amz-Credential")
  valid_21626687 = validateParameter(valid_21626687, JString, required = false,
                                   default = nil)
  if valid_21626687 != nil:
    section.add "X-Amz-Credential", valid_21626687
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626689: Call_DetachVolume_21626677; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Disconnects a volume from an iSCSI connection and then detaches the volume from the specified gateway. Detaching and attaching a volume enables you to recover your data from one gateway to a different gateway without creating a snapshot. It also makes it easier to move your volumes from an on-premises gateway to a gateway hosted on an Amazon EC2 instance. This operation is only supported in the volume gateway type.
  ## 
  let valid = call_21626689.validator(path, query, header, formData, body, _)
  let scheme = call_21626689.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626689.makeUrl(scheme.get, call_21626689.host, call_21626689.base,
                               call_21626689.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626689, uri, valid, _)

proc call*(call_21626690: Call_DetachVolume_21626677; body: JsonNode): Recallable =
  ## detachVolume
  ## Disconnects a volume from an iSCSI connection and then detaches the volume from the specified gateway. Detaching and attaching a volume enables you to recover your data from one gateway to a different gateway without creating a snapshot. It also makes it easier to move your volumes from an on-premises gateway to a gateway hosted on an Amazon EC2 instance. This operation is only supported in the volume gateway type.
  ##   body: JObject (required)
  var body_21626691 = newJObject()
  if body != nil:
    body_21626691 = body
  result = call_21626690.call(nil, nil, nil, nil, body_21626691)

var detachVolume* = Call_DetachVolume_21626677(name: "detachVolume",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DetachVolume",
    validator: validate_DetachVolume_21626678, base: "/", makeUrl: url_DetachVolume_21626679,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableGateway_21626692 = ref object of OpenApiRestCall_21625437
proc url_DisableGateway_21626694(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisableGateway_21626693(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Disables a tape gateway when the gateway is no longer functioning. For example, if your gateway VM is damaged, you can disable the gateway so you can recover virtual tapes.</p> <p>Use this operation for a tape gateway that is not reachable or not functioning. This operation is only supported in the tape gateway type.</p> <important> <p>Once a gateway is disabled it cannot be enabled.</p> </important>
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
  var valid_21626695 = header.getOrDefault("X-Amz-Date")
  valid_21626695 = validateParameter(valid_21626695, JString, required = false,
                                   default = nil)
  if valid_21626695 != nil:
    section.add "X-Amz-Date", valid_21626695
  var valid_21626696 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626696 = validateParameter(valid_21626696, JString, required = false,
                                   default = nil)
  if valid_21626696 != nil:
    section.add "X-Amz-Security-Token", valid_21626696
  var valid_21626697 = header.getOrDefault("X-Amz-Target")
  valid_21626697 = validateParameter(valid_21626697, JString, required = true, default = newJString(
      "StorageGateway_20130630.DisableGateway"))
  if valid_21626697 != nil:
    section.add "X-Amz-Target", valid_21626697
  var valid_21626698 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626698 = validateParameter(valid_21626698, JString, required = false,
                                   default = nil)
  if valid_21626698 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626698
  var valid_21626699 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626699 = validateParameter(valid_21626699, JString, required = false,
                                   default = nil)
  if valid_21626699 != nil:
    section.add "X-Amz-Algorithm", valid_21626699
  var valid_21626700 = header.getOrDefault("X-Amz-Signature")
  valid_21626700 = validateParameter(valid_21626700, JString, required = false,
                                   default = nil)
  if valid_21626700 != nil:
    section.add "X-Amz-Signature", valid_21626700
  var valid_21626701 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626701 = validateParameter(valid_21626701, JString, required = false,
                                   default = nil)
  if valid_21626701 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626701
  var valid_21626702 = header.getOrDefault("X-Amz-Credential")
  valid_21626702 = validateParameter(valid_21626702, JString, required = false,
                                   default = nil)
  if valid_21626702 != nil:
    section.add "X-Amz-Credential", valid_21626702
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626704: Call_DisableGateway_21626692; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Disables a tape gateway when the gateway is no longer functioning. For example, if your gateway VM is damaged, you can disable the gateway so you can recover virtual tapes.</p> <p>Use this operation for a tape gateway that is not reachable or not functioning. This operation is only supported in the tape gateway type.</p> <important> <p>Once a gateway is disabled it cannot be enabled.</p> </important>
  ## 
  let valid = call_21626704.validator(path, query, header, formData, body, _)
  let scheme = call_21626704.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626704.makeUrl(scheme.get, call_21626704.host, call_21626704.base,
                               call_21626704.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626704, uri, valid, _)

proc call*(call_21626705: Call_DisableGateway_21626692; body: JsonNode): Recallable =
  ## disableGateway
  ## <p>Disables a tape gateway when the gateway is no longer functioning. For example, if your gateway VM is damaged, you can disable the gateway so you can recover virtual tapes.</p> <p>Use this operation for a tape gateway that is not reachable or not functioning. This operation is only supported in the tape gateway type.</p> <important> <p>Once a gateway is disabled it cannot be enabled.</p> </important>
  ##   body: JObject (required)
  var body_21626706 = newJObject()
  if body != nil:
    body_21626706 = body
  result = call_21626705.call(nil, nil, nil, nil, body_21626706)

var disableGateway* = Call_DisableGateway_21626692(name: "disableGateway",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DisableGateway",
    validator: validate_DisableGateway_21626693, base: "/",
    makeUrl: url_DisableGateway_21626694, schemes: {Scheme.Https, Scheme.Http})
type
  Call_JoinDomain_21626707 = ref object of OpenApiRestCall_21625437
proc url_JoinDomain_21626709(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_JoinDomain_21626708(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Adds a file gateway to an Active Directory domain. This operation is only supported for file gateways that support the SMB file protocol.
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
  var valid_21626710 = header.getOrDefault("X-Amz-Date")
  valid_21626710 = validateParameter(valid_21626710, JString, required = false,
                                   default = nil)
  if valid_21626710 != nil:
    section.add "X-Amz-Date", valid_21626710
  var valid_21626711 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626711 = validateParameter(valid_21626711, JString, required = false,
                                   default = nil)
  if valid_21626711 != nil:
    section.add "X-Amz-Security-Token", valid_21626711
  var valid_21626712 = header.getOrDefault("X-Amz-Target")
  valid_21626712 = validateParameter(valid_21626712, JString, required = true, default = newJString(
      "StorageGateway_20130630.JoinDomain"))
  if valid_21626712 != nil:
    section.add "X-Amz-Target", valid_21626712
  var valid_21626713 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626713 = validateParameter(valid_21626713, JString, required = false,
                                   default = nil)
  if valid_21626713 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626713
  var valid_21626714 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626714 = validateParameter(valid_21626714, JString, required = false,
                                   default = nil)
  if valid_21626714 != nil:
    section.add "X-Amz-Algorithm", valid_21626714
  var valid_21626715 = header.getOrDefault("X-Amz-Signature")
  valid_21626715 = validateParameter(valid_21626715, JString, required = false,
                                   default = nil)
  if valid_21626715 != nil:
    section.add "X-Amz-Signature", valid_21626715
  var valid_21626716 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626716 = validateParameter(valid_21626716, JString, required = false,
                                   default = nil)
  if valid_21626716 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626716
  var valid_21626717 = header.getOrDefault("X-Amz-Credential")
  valid_21626717 = validateParameter(valid_21626717, JString, required = false,
                                   default = nil)
  if valid_21626717 != nil:
    section.add "X-Amz-Credential", valid_21626717
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626719: Call_JoinDomain_21626707; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds a file gateway to an Active Directory domain. This operation is only supported for file gateways that support the SMB file protocol.
  ## 
  let valid = call_21626719.validator(path, query, header, formData, body, _)
  let scheme = call_21626719.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626719.makeUrl(scheme.get, call_21626719.host, call_21626719.base,
                               call_21626719.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626719, uri, valid, _)

proc call*(call_21626720: Call_JoinDomain_21626707; body: JsonNode): Recallable =
  ## joinDomain
  ## Adds a file gateway to an Active Directory domain. This operation is only supported for file gateways that support the SMB file protocol.
  ##   body: JObject (required)
  var body_21626721 = newJObject()
  if body != nil:
    body_21626721 = body
  result = call_21626720.call(nil, nil, nil, nil, body_21626721)

var joinDomain* = Call_JoinDomain_21626707(name: "joinDomain",
                                        meth: HttpMethod.HttpPost,
                                        host: "storagegateway.amazonaws.com", route: "/#X-Amz-Target=StorageGateway_20130630.JoinDomain",
                                        validator: validate_JoinDomain_21626708,
                                        base: "/", makeUrl: url_JoinDomain_21626709,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFileShares_21626722 = ref object of OpenApiRestCall_21625437
proc url_ListFileShares_21626724(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListFileShares_21626723(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets a list of the file shares for a specific file gateway, or the list of file shares that belong to the calling user account. This operation is only supported for file gateways.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Limit: JString
  ##        : Pagination limit
  ##   Marker: JString
  ##         : Pagination token
  section = newJObject()
  var valid_21626725 = query.getOrDefault("Limit")
  valid_21626725 = validateParameter(valid_21626725, JString, required = false,
                                   default = nil)
  if valid_21626725 != nil:
    section.add "Limit", valid_21626725
  var valid_21626726 = query.getOrDefault("Marker")
  valid_21626726 = validateParameter(valid_21626726, JString, required = false,
                                   default = nil)
  if valid_21626726 != nil:
    section.add "Marker", valid_21626726
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626727 = header.getOrDefault("X-Amz-Date")
  valid_21626727 = validateParameter(valid_21626727, JString, required = false,
                                   default = nil)
  if valid_21626727 != nil:
    section.add "X-Amz-Date", valid_21626727
  var valid_21626728 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626728 = validateParameter(valid_21626728, JString, required = false,
                                   default = nil)
  if valid_21626728 != nil:
    section.add "X-Amz-Security-Token", valid_21626728
  var valid_21626729 = header.getOrDefault("X-Amz-Target")
  valid_21626729 = validateParameter(valid_21626729, JString, required = true, default = newJString(
      "StorageGateway_20130630.ListFileShares"))
  if valid_21626729 != nil:
    section.add "X-Amz-Target", valid_21626729
  var valid_21626730 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626730 = validateParameter(valid_21626730, JString, required = false,
                                   default = nil)
  if valid_21626730 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626730
  var valid_21626731 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626731 = validateParameter(valid_21626731, JString, required = false,
                                   default = nil)
  if valid_21626731 != nil:
    section.add "X-Amz-Algorithm", valid_21626731
  var valid_21626732 = header.getOrDefault("X-Amz-Signature")
  valid_21626732 = validateParameter(valid_21626732, JString, required = false,
                                   default = nil)
  if valid_21626732 != nil:
    section.add "X-Amz-Signature", valid_21626732
  var valid_21626733 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626733 = validateParameter(valid_21626733, JString, required = false,
                                   default = nil)
  if valid_21626733 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626733
  var valid_21626734 = header.getOrDefault("X-Amz-Credential")
  valid_21626734 = validateParameter(valid_21626734, JString, required = false,
                                   default = nil)
  if valid_21626734 != nil:
    section.add "X-Amz-Credential", valid_21626734
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626736: Call_ListFileShares_21626722; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a list of the file shares for a specific file gateway, or the list of file shares that belong to the calling user account. This operation is only supported for file gateways.
  ## 
  let valid = call_21626736.validator(path, query, header, formData, body, _)
  let scheme = call_21626736.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626736.makeUrl(scheme.get, call_21626736.host, call_21626736.base,
                               call_21626736.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626736, uri, valid, _)

proc call*(call_21626737: Call_ListFileShares_21626722; body: JsonNode;
          Limit: string = ""; Marker: string = ""): Recallable =
  ## listFileShares
  ## Gets a list of the file shares for a specific file gateway, or the list of file shares that belong to the calling user account. This operation is only supported for file gateways.
  ##   Limit: string
  ##        : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_21626738 = newJObject()
  var body_21626739 = newJObject()
  add(query_21626738, "Limit", newJString(Limit))
  add(query_21626738, "Marker", newJString(Marker))
  if body != nil:
    body_21626739 = body
  result = call_21626737.call(nil, query_21626738, nil, nil, body_21626739)

var listFileShares* = Call_ListFileShares_21626722(name: "listFileShares",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.ListFileShares",
    validator: validate_ListFileShares_21626723, base: "/",
    makeUrl: url_ListFileShares_21626724, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGateways_21626740 = ref object of OpenApiRestCall_21625437
proc url_ListGateways_21626742(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListGateways_21626741(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>Lists gateways owned by an AWS account in an AWS Region specified in the request. The returned list is ordered by gateway Amazon Resource Name (ARN).</p> <p>By default, the operation returns a maximum of 100 gateways. This operation supports pagination that allows you to optionally reduce the number of gateways returned in a response.</p> <p>If you have more gateways than are returned in a response (that is, the response returns only a truncated list of your gateways), the response contains a marker that you can specify in your next request to fetch the next page of gateways.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Limit: JString
  ##        : Pagination limit
  ##   Marker: JString
  ##         : Pagination token
  section = newJObject()
  var valid_21626743 = query.getOrDefault("Limit")
  valid_21626743 = validateParameter(valid_21626743, JString, required = false,
                                   default = nil)
  if valid_21626743 != nil:
    section.add "Limit", valid_21626743
  var valid_21626744 = query.getOrDefault("Marker")
  valid_21626744 = validateParameter(valid_21626744, JString, required = false,
                                   default = nil)
  if valid_21626744 != nil:
    section.add "Marker", valid_21626744
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626745 = header.getOrDefault("X-Amz-Date")
  valid_21626745 = validateParameter(valid_21626745, JString, required = false,
                                   default = nil)
  if valid_21626745 != nil:
    section.add "X-Amz-Date", valid_21626745
  var valid_21626746 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626746 = validateParameter(valid_21626746, JString, required = false,
                                   default = nil)
  if valid_21626746 != nil:
    section.add "X-Amz-Security-Token", valid_21626746
  var valid_21626747 = header.getOrDefault("X-Amz-Target")
  valid_21626747 = validateParameter(valid_21626747, JString, required = true, default = newJString(
      "StorageGateway_20130630.ListGateways"))
  if valid_21626747 != nil:
    section.add "X-Amz-Target", valid_21626747
  var valid_21626748 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626748 = validateParameter(valid_21626748, JString, required = false,
                                   default = nil)
  if valid_21626748 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626748
  var valid_21626749 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626749 = validateParameter(valid_21626749, JString, required = false,
                                   default = nil)
  if valid_21626749 != nil:
    section.add "X-Amz-Algorithm", valid_21626749
  var valid_21626750 = header.getOrDefault("X-Amz-Signature")
  valid_21626750 = validateParameter(valid_21626750, JString, required = false,
                                   default = nil)
  if valid_21626750 != nil:
    section.add "X-Amz-Signature", valid_21626750
  var valid_21626751 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626751 = validateParameter(valid_21626751, JString, required = false,
                                   default = nil)
  if valid_21626751 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626751
  var valid_21626752 = header.getOrDefault("X-Amz-Credential")
  valid_21626752 = validateParameter(valid_21626752, JString, required = false,
                                   default = nil)
  if valid_21626752 != nil:
    section.add "X-Amz-Credential", valid_21626752
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626754: Call_ListGateways_21626740; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Lists gateways owned by an AWS account in an AWS Region specified in the request. The returned list is ordered by gateway Amazon Resource Name (ARN).</p> <p>By default, the operation returns a maximum of 100 gateways. This operation supports pagination that allows you to optionally reduce the number of gateways returned in a response.</p> <p>If you have more gateways than are returned in a response (that is, the response returns only a truncated list of your gateways), the response contains a marker that you can specify in your next request to fetch the next page of gateways.</p>
  ## 
  let valid = call_21626754.validator(path, query, header, formData, body, _)
  let scheme = call_21626754.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626754.makeUrl(scheme.get, call_21626754.host, call_21626754.base,
                               call_21626754.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626754, uri, valid, _)

proc call*(call_21626755: Call_ListGateways_21626740; body: JsonNode;
          Limit: string = ""; Marker: string = ""): Recallable =
  ## listGateways
  ## <p>Lists gateways owned by an AWS account in an AWS Region specified in the request. The returned list is ordered by gateway Amazon Resource Name (ARN).</p> <p>By default, the operation returns a maximum of 100 gateways. This operation supports pagination that allows you to optionally reduce the number of gateways returned in a response.</p> <p>If you have more gateways than are returned in a response (that is, the response returns only a truncated list of your gateways), the response contains a marker that you can specify in your next request to fetch the next page of gateways.</p>
  ##   Limit: string
  ##        : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_21626756 = newJObject()
  var body_21626757 = newJObject()
  add(query_21626756, "Limit", newJString(Limit))
  add(query_21626756, "Marker", newJString(Marker))
  if body != nil:
    body_21626757 = body
  result = call_21626755.call(nil, query_21626756, nil, nil, body_21626757)

var listGateways* = Call_ListGateways_21626740(name: "listGateways",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.ListGateways",
    validator: validate_ListGateways_21626741, base: "/", makeUrl: url_ListGateways_21626742,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLocalDisks_21626758 = ref object of OpenApiRestCall_21625437
proc url_ListLocalDisks_21626760(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListLocalDisks_21626759(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns a list of the gateway's local disks. To specify which gateway to describe, you use the Amazon Resource Name (ARN) of the gateway in the body of the request.</p> <p>The request returns a list of all disks, specifying which are configured as working storage, cache storage, or stored volume or not configured at all. The response includes a <code>DiskStatus</code> field. This field can have a value of present (the disk is available to use), missing (the disk is no longer connected to the gateway), or mismatch (the disk node is occupied by a disk that has incorrect metadata or the disk content is corrupted).</p>
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
  var valid_21626761 = header.getOrDefault("X-Amz-Date")
  valid_21626761 = validateParameter(valid_21626761, JString, required = false,
                                   default = nil)
  if valid_21626761 != nil:
    section.add "X-Amz-Date", valid_21626761
  var valid_21626762 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626762 = validateParameter(valid_21626762, JString, required = false,
                                   default = nil)
  if valid_21626762 != nil:
    section.add "X-Amz-Security-Token", valid_21626762
  var valid_21626763 = header.getOrDefault("X-Amz-Target")
  valid_21626763 = validateParameter(valid_21626763, JString, required = true, default = newJString(
      "StorageGateway_20130630.ListLocalDisks"))
  if valid_21626763 != nil:
    section.add "X-Amz-Target", valid_21626763
  var valid_21626764 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626764 = validateParameter(valid_21626764, JString, required = false,
                                   default = nil)
  if valid_21626764 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626764
  var valid_21626765 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626765 = validateParameter(valid_21626765, JString, required = false,
                                   default = nil)
  if valid_21626765 != nil:
    section.add "X-Amz-Algorithm", valid_21626765
  var valid_21626766 = header.getOrDefault("X-Amz-Signature")
  valid_21626766 = validateParameter(valid_21626766, JString, required = false,
                                   default = nil)
  if valid_21626766 != nil:
    section.add "X-Amz-Signature", valid_21626766
  var valid_21626767 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626767 = validateParameter(valid_21626767, JString, required = false,
                                   default = nil)
  if valid_21626767 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626767
  var valid_21626768 = header.getOrDefault("X-Amz-Credential")
  valid_21626768 = validateParameter(valid_21626768, JString, required = false,
                                   default = nil)
  if valid_21626768 != nil:
    section.add "X-Amz-Credential", valid_21626768
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626770: Call_ListLocalDisks_21626758; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns a list of the gateway's local disks. To specify which gateway to describe, you use the Amazon Resource Name (ARN) of the gateway in the body of the request.</p> <p>The request returns a list of all disks, specifying which are configured as working storage, cache storage, or stored volume or not configured at all. The response includes a <code>DiskStatus</code> field. This field can have a value of present (the disk is available to use), missing (the disk is no longer connected to the gateway), or mismatch (the disk node is occupied by a disk that has incorrect metadata or the disk content is corrupted).</p>
  ## 
  let valid = call_21626770.validator(path, query, header, formData, body, _)
  let scheme = call_21626770.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626770.makeUrl(scheme.get, call_21626770.host, call_21626770.base,
                               call_21626770.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626770, uri, valid, _)

proc call*(call_21626771: Call_ListLocalDisks_21626758; body: JsonNode): Recallable =
  ## listLocalDisks
  ## <p>Returns a list of the gateway's local disks. To specify which gateway to describe, you use the Amazon Resource Name (ARN) of the gateway in the body of the request.</p> <p>The request returns a list of all disks, specifying which are configured as working storage, cache storage, or stored volume or not configured at all. The response includes a <code>DiskStatus</code> field. This field can have a value of present (the disk is available to use), missing (the disk is no longer connected to the gateway), or mismatch (the disk node is occupied by a disk that has incorrect metadata or the disk content is corrupted).</p>
  ##   body: JObject (required)
  var body_21626772 = newJObject()
  if body != nil:
    body_21626772 = body
  result = call_21626771.call(nil, nil, nil, nil, body_21626772)

var listLocalDisks* = Call_ListLocalDisks_21626758(name: "listLocalDisks",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.ListLocalDisks",
    validator: validate_ListLocalDisks_21626759, base: "/",
    makeUrl: url_ListLocalDisks_21626760, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_21626773 = ref object of OpenApiRestCall_21625437
proc url_ListTagsForResource_21626775(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_21626774(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the tags that have been added to the specified resource. This operation is supported in storage gateways of all types.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Limit: JString
  ##        : Pagination limit
  ##   Marker: JString
  ##         : Pagination token
  section = newJObject()
  var valid_21626776 = query.getOrDefault("Limit")
  valid_21626776 = validateParameter(valid_21626776, JString, required = false,
                                   default = nil)
  if valid_21626776 != nil:
    section.add "Limit", valid_21626776
  var valid_21626777 = query.getOrDefault("Marker")
  valid_21626777 = validateParameter(valid_21626777, JString, required = false,
                                   default = nil)
  if valid_21626777 != nil:
    section.add "Marker", valid_21626777
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626778 = header.getOrDefault("X-Amz-Date")
  valid_21626778 = validateParameter(valid_21626778, JString, required = false,
                                   default = nil)
  if valid_21626778 != nil:
    section.add "X-Amz-Date", valid_21626778
  var valid_21626779 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626779 = validateParameter(valid_21626779, JString, required = false,
                                   default = nil)
  if valid_21626779 != nil:
    section.add "X-Amz-Security-Token", valid_21626779
  var valid_21626780 = header.getOrDefault("X-Amz-Target")
  valid_21626780 = validateParameter(valid_21626780, JString, required = true, default = newJString(
      "StorageGateway_20130630.ListTagsForResource"))
  if valid_21626780 != nil:
    section.add "X-Amz-Target", valid_21626780
  var valid_21626781 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626781 = validateParameter(valid_21626781, JString, required = false,
                                   default = nil)
  if valid_21626781 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626781
  var valid_21626782 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626782 = validateParameter(valid_21626782, JString, required = false,
                                   default = nil)
  if valid_21626782 != nil:
    section.add "X-Amz-Algorithm", valid_21626782
  var valid_21626783 = header.getOrDefault("X-Amz-Signature")
  valid_21626783 = validateParameter(valid_21626783, JString, required = false,
                                   default = nil)
  if valid_21626783 != nil:
    section.add "X-Amz-Signature", valid_21626783
  var valid_21626784 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626784 = validateParameter(valid_21626784, JString, required = false,
                                   default = nil)
  if valid_21626784 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626784
  var valid_21626785 = header.getOrDefault("X-Amz-Credential")
  valid_21626785 = validateParameter(valid_21626785, JString, required = false,
                                   default = nil)
  if valid_21626785 != nil:
    section.add "X-Amz-Credential", valid_21626785
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626787: Call_ListTagsForResource_21626773; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the tags that have been added to the specified resource. This operation is supported in storage gateways of all types.
  ## 
  let valid = call_21626787.validator(path, query, header, formData, body, _)
  let scheme = call_21626787.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626787.makeUrl(scheme.get, call_21626787.host, call_21626787.base,
                               call_21626787.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626787, uri, valid, _)

proc call*(call_21626788: Call_ListTagsForResource_21626773; body: JsonNode;
          Limit: string = ""; Marker: string = ""): Recallable =
  ## listTagsForResource
  ## Lists the tags that have been added to the specified resource. This operation is supported in storage gateways of all types.
  ##   Limit: string
  ##        : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_21626789 = newJObject()
  var body_21626790 = newJObject()
  add(query_21626789, "Limit", newJString(Limit))
  add(query_21626789, "Marker", newJString(Marker))
  if body != nil:
    body_21626790 = body
  result = call_21626788.call(nil, query_21626789, nil, nil, body_21626790)

var listTagsForResource* = Call_ListTagsForResource_21626773(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.ListTagsForResource",
    validator: validate_ListTagsForResource_21626774, base: "/",
    makeUrl: url_ListTagsForResource_21626775,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTapes_21626791 = ref object of OpenApiRestCall_21625437
proc url_ListTapes_21626793(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTapes_21626792(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Lists virtual tapes in your virtual tape library (VTL) and your virtual tape shelf (VTS). You specify the tapes to list by specifying one or more tape Amazon Resource Names (ARNs). If you don't specify a tape ARN, the operation lists all virtual tapes in both your VTL and VTS.</p> <p>This operation supports pagination. By default, the operation returns a maximum of up to 100 tapes. You can optionally specify the <code>Limit</code> parameter in the body to limit the number of tapes in the response. If the number of tapes returned in the response is truncated, the response includes a <code>Marker</code> element that you can use in your subsequent request to retrieve the next set of tapes. This operation is only supported in the tape gateway type.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Limit: JString
  ##        : Pagination limit
  ##   Marker: JString
  ##         : Pagination token
  section = newJObject()
  var valid_21626794 = query.getOrDefault("Limit")
  valid_21626794 = validateParameter(valid_21626794, JString, required = false,
                                   default = nil)
  if valid_21626794 != nil:
    section.add "Limit", valid_21626794
  var valid_21626795 = query.getOrDefault("Marker")
  valid_21626795 = validateParameter(valid_21626795, JString, required = false,
                                   default = nil)
  if valid_21626795 != nil:
    section.add "Marker", valid_21626795
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626796 = header.getOrDefault("X-Amz-Date")
  valid_21626796 = validateParameter(valid_21626796, JString, required = false,
                                   default = nil)
  if valid_21626796 != nil:
    section.add "X-Amz-Date", valid_21626796
  var valid_21626797 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626797 = validateParameter(valid_21626797, JString, required = false,
                                   default = nil)
  if valid_21626797 != nil:
    section.add "X-Amz-Security-Token", valid_21626797
  var valid_21626798 = header.getOrDefault("X-Amz-Target")
  valid_21626798 = validateParameter(valid_21626798, JString, required = true, default = newJString(
      "StorageGateway_20130630.ListTapes"))
  if valid_21626798 != nil:
    section.add "X-Amz-Target", valid_21626798
  var valid_21626799 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626799 = validateParameter(valid_21626799, JString, required = false,
                                   default = nil)
  if valid_21626799 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626799
  var valid_21626800 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626800 = validateParameter(valid_21626800, JString, required = false,
                                   default = nil)
  if valid_21626800 != nil:
    section.add "X-Amz-Algorithm", valid_21626800
  var valid_21626801 = header.getOrDefault("X-Amz-Signature")
  valid_21626801 = validateParameter(valid_21626801, JString, required = false,
                                   default = nil)
  if valid_21626801 != nil:
    section.add "X-Amz-Signature", valid_21626801
  var valid_21626802 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626802 = validateParameter(valid_21626802, JString, required = false,
                                   default = nil)
  if valid_21626802 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626802
  var valid_21626803 = header.getOrDefault("X-Amz-Credential")
  valid_21626803 = validateParameter(valid_21626803, JString, required = false,
                                   default = nil)
  if valid_21626803 != nil:
    section.add "X-Amz-Credential", valid_21626803
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626805: Call_ListTapes_21626791; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Lists virtual tapes in your virtual tape library (VTL) and your virtual tape shelf (VTS). You specify the tapes to list by specifying one or more tape Amazon Resource Names (ARNs). If you don't specify a tape ARN, the operation lists all virtual tapes in both your VTL and VTS.</p> <p>This operation supports pagination. By default, the operation returns a maximum of up to 100 tapes. You can optionally specify the <code>Limit</code> parameter in the body to limit the number of tapes in the response. If the number of tapes returned in the response is truncated, the response includes a <code>Marker</code> element that you can use in your subsequent request to retrieve the next set of tapes. This operation is only supported in the tape gateway type.</p>
  ## 
  let valid = call_21626805.validator(path, query, header, formData, body, _)
  let scheme = call_21626805.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626805.makeUrl(scheme.get, call_21626805.host, call_21626805.base,
                               call_21626805.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626805, uri, valid, _)

proc call*(call_21626806: Call_ListTapes_21626791; body: JsonNode;
          Limit: string = ""; Marker: string = ""): Recallable =
  ## listTapes
  ## <p>Lists virtual tapes in your virtual tape library (VTL) and your virtual tape shelf (VTS). You specify the tapes to list by specifying one or more tape Amazon Resource Names (ARNs). If you don't specify a tape ARN, the operation lists all virtual tapes in both your VTL and VTS.</p> <p>This operation supports pagination. By default, the operation returns a maximum of up to 100 tapes. You can optionally specify the <code>Limit</code> parameter in the body to limit the number of tapes in the response. If the number of tapes returned in the response is truncated, the response includes a <code>Marker</code> element that you can use in your subsequent request to retrieve the next set of tapes. This operation is only supported in the tape gateway type.</p>
  ##   Limit: string
  ##        : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_21626807 = newJObject()
  var body_21626808 = newJObject()
  add(query_21626807, "Limit", newJString(Limit))
  add(query_21626807, "Marker", newJString(Marker))
  if body != nil:
    body_21626808 = body
  result = call_21626806.call(nil, query_21626807, nil, nil, body_21626808)

var listTapes* = Call_ListTapes_21626791(name: "listTapes",
                                      meth: HttpMethod.HttpPost,
                                      host: "storagegateway.amazonaws.com", route: "/#X-Amz-Target=StorageGateway_20130630.ListTapes",
                                      validator: validate_ListTapes_21626792,
                                      base: "/", makeUrl: url_ListTapes_21626793,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVolumeInitiators_21626809 = ref object of OpenApiRestCall_21625437
proc url_ListVolumeInitiators_21626811(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListVolumeInitiators_21626810(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists iSCSI initiators that are connected to a volume. You can use this operation to determine whether a volume is being used or not. This operation is only supported in the cached volume and stored volume gateway types.
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
  var valid_21626812 = header.getOrDefault("X-Amz-Date")
  valid_21626812 = validateParameter(valid_21626812, JString, required = false,
                                   default = nil)
  if valid_21626812 != nil:
    section.add "X-Amz-Date", valid_21626812
  var valid_21626813 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626813 = validateParameter(valid_21626813, JString, required = false,
                                   default = nil)
  if valid_21626813 != nil:
    section.add "X-Amz-Security-Token", valid_21626813
  var valid_21626814 = header.getOrDefault("X-Amz-Target")
  valid_21626814 = validateParameter(valid_21626814, JString, required = true, default = newJString(
      "StorageGateway_20130630.ListVolumeInitiators"))
  if valid_21626814 != nil:
    section.add "X-Amz-Target", valid_21626814
  var valid_21626815 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626815 = validateParameter(valid_21626815, JString, required = false,
                                   default = nil)
  if valid_21626815 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626815
  var valid_21626816 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626816 = validateParameter(valid_21626816, JString, required = false,
                                   default = nil)
  if valid_21626816 != nil:
    section.add "X-Amz-Algorithm", valid_21626816
  var valid_21626817 = header.getOrDefault("X-Amz-Signature")
  valid_21626817 = validateParameter(valid_21626817, JString, required = false,
                                   default = nil)
  if valid_21626817 != nil:
    section.add "X-Amz-Signature", valid_21626817
  var valid_21626818 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626818 = validateParameter(valid_21626818, JString, required = false,
                                   default = nil)
  if valid_21626818 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626818
  var valid_21626819 = header.getOrDefault("X-Amz-Credential")
  valid_21626819 = validateParameter(valid_21626819, JString, required = false,
                                   default = nil)
  if valid_21626819 != nil:
    section.add "X-Amz-Credential", valid_21626819
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626821: Call_ListVolumeInitiators_21626809; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists iSCSI initiators that are connected to a volume. You can use this operation to determine whether a volume is being used or not. This operation is only supported in the cached volume and stored volume gateway types.
  ## 
  let valid = call_21626821.validator(path, query, header, formData, body, _)
  let scheme = call_21626821.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626821.makeUrl(scheme.get, call_21626821.host, call_21626821.base,
                               call_21626821.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626821, uri, valid, _)

proc call*(call_21626822: Call_ListVolumeInitiators_21626809; body: JsonNode): Recallable =
  ## listVolumeInitiators
  ## Lists iSCSI initiators that are connected to a volume. You can use this operation to determine whether a volume is being used or not. This operation is only supported in the cached volume and stored volume gateway types.
  ##   body: JObject (required)
  var body_21626823 = newJObject()
  if body != nil:
    body_21626823 = body
  result = call_21626822.call(nil, nil, nil, nil, body_21626823)

var listVolumeInitiators* = Call_ListVolumeInitiators_21626809(
    name: "listVolumeInitiators", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.ListVolumeInitiators",
    validator: validate_ListVolumeInitiators_21626810, base: "/",
    makeUrl: url_ListVolumeInitiators_21626811,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVolumeRecoveryPoints_21626824 = ref object of OpenApiRestCall_21625437
proc url_ListVolumeRecoveryPoints_21626826(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListVolumeRecoveryPoints_21626825(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Lists the recovery points for a specified gateway. This operation is only supported in the cached volume gateway type.</p> <p>Each cache volume has one recovery point. A volume recovery point is a point in time at which all data of the volume is consistent and from which you can create a snapshot or clone a new cached volume from a source volume. To create a snapshot from a volume recovery point use the <a>CreateSnapshotFromVolumeRecoveryPoint</a> operation.</p>
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
  var valid_21626827 = header.getOrDefault("X-Amz-Date")
  valid_21626827 = validateParameter(valid_21626827, JString, required = false,
                                   default = nil)
  if valid_21626827 != nil:
    section.add "X-Amz-Date", valid_21626827
  var valid_21626828 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626828 = validateParameter(valid_21626828, JString, required = false,
                                   default = nil)
  if valid_21626828 != nil:
    section.add "X-Amz-Security-Token", valid_21626828
  var valid_21626829 = header.getOrDefault("X-Amz-Target")
  valid_21626829 = validateParameter(valid_21626829, JString, required = true, default = newJString(
      "StorageGateway_20130630.ListVolumeRecoveryPoints"))
  if valid_21626829 != nil:
    section.add "X-Amz-Target", valid_21626829
  var valid_21626830 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626830 = validateParameter(valid_21626830, JString, required = false,
                                   default = nil)
  if valid_21626830 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626830
  var valid_21626831 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626831 = validateParameter(valid_21626831, JString, required = false,
                                   default = nil)
  if valid_21626831 != nil:
    section.add "X-Amz-Algorithm", valid_21626831
  var valid_21626832 = header.getOrDefault("X-Amz-Signature")
  valid_21626832 = validateParameter(valid_21626832, JString, required = false,
                                   default = nil)
  if valid_21626832 != nil:
    section.add "X-Amz-Signature", valid_21626832
  var valid_21626833 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626833 = validateParameter(valid_21626833, JString, required = false,
                                   default = nil)
  if valid_21626833 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626833
  var valid_21626834 = header.getOrDefault("X-Amz-Credential")
  valid_21626834 = validateParameter(valid_21626834, JString, required = false,
                                   default = nil)
  if valid_21626834 != nil:
    section.add "X-Amz-Credential", valid_21626834
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626836: Call_ListVolumeRecoveryPoints_21626824;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Lists the recovery points for a specified gateway. This operation is only supported in the cached volume gateway type.</p> <p>Each cache volume has one recovery point. A volume recovery point is a point in time at which all data of the volume is consistent and from which you can create a snapshot or clone a new cached volume from a source volume. To create a snapshot from a volume recovery point use the <a>CreateSnapshotFromVolumeRecoveryPoint</a> operation.</p>
  ## 
  let valid = call_21626836.validator(path, query, header, formData, body, _)
  let scheme = call_21626836.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626836.makeUrl(scheme.get, call_21626836.host, call_21626836.base,
                               call_21626836.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626836, uri, valid, _)

proc call*(call_21626837: Call_ListVolumeRecoveryPoints_21626824; body: JsonNode): Recallable =
  ## listVolumeRecoveryPoints
  ## <p>Lists the recovery points for a specified gateway. This operation is only supported in the cached volume gateway type.</p> <p>Each cache volume has one recovery point. A volume recovery point is a point in time at which all data of the volume is consistent and from which you can create a snapshot or clone a new cached volume from a source volume. To create a snapshot from a volume recovery point use the <a>CreateSnapshotFromVolumeRecoveryPoint</a> operation.</p>
  ##   body: JObject (required)
  var body_21626838 = newJObject()
  if body != nil:
    body_21626838 = body
  result = call_21626837.call(nil, nil, nil, nil, body_21626838)

var listVolumeRecoveryPoints* = Call_ListVolumeRecoveryPoints_21626824(
    name: "listVolumeRecoveryPoints", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.ListVolumeRecoveryPoints",
    validator: validate_ListVolumeRecoveryPoints_21626825, base: "/",
    makeUrl: url_ListVolumeRecoveryPoints_21626826,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVolumes_21626839 = ref object of OpenApiRestCall_21625437
proc url_ListVolumes_21626841(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListVolumes_21626840(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Lists the iSCSI stored volumes of a gateway. Results are sorted by volume ARN. The response includes only the volume ARNs. If you want additional volume information, use the <a>DescribeStorediSCSIVolumes</a> or the <a>DescribeCachediSCSIVolumes</a> API.</p> <p>The operation supports pagination. By default, the operation returns a maximum of up to 100 volumes. You can optionally specify the <code>Limit</code> field in the body to limit the number of volumes in the response. If the number of volumes returned in the response is truncated, the response includes a Marker field. You can use this Marker value in your subsequent request to retrieve the next set of volumes. This operation is only supported in the cached volume and stored volume gateway types.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Limit: JString
  ##        : Pagination limit
  ##   Marker: JString
  ##         : Pagination token
  section = newJObject()
  var valid_21626842 = query.getOrDefault("Limit")
  valid_21626842 = validateParameter(valid_21626842, JString, required = false,
                                   default = nil)
  if valid_21626842 != nil:
    section.add "Limit", valid_21626842
  var valid_21626843 = query.getOrDefault("Marker")
  valid_21626843 = validateParameter(valid_21626843, JString, required = false,
                                   default = nil)
  if valid_21626843 != nil:
    section.add "Marker", valid_21626843
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626844 = header.getOrDefault("X-Amz-Date")
  valid_21626844 = validateParameter(valid_21626844, JString, required = false,
                                   default = nil)
  if valid_21626844 != nil:
    section.add "X-Amz-Date", valid_21626844
  var valid_21626845 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626845 = validateParameter(valid_21626845, JString, required = false,
                                   default = nil)
  if valid_21626845 != nil:
    section.add "X-Amz-Security-Token", valid_21626845
  var valid_21626846 = header.getOrDefault("X-Amz-Target")
  valid_21626846 = validateParameter(valid_21626846, JString, required = true, default = newJString(
      "StorageGateway_20130630.ListVolumes"))
  if valid_21626846 != nil:
    section.add "X-Amz-Target", valid_21626846
  var valid_21626847 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626847 = validateParameter(valid_21626847, JString, required = false,
                                   default = nil)
  if valid_21626847 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626847
  var valid_21626848 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626848 = validateParameter(valid_21626848, JString, required = false,
                                   default = nil)
  if valid_21626848 != nil:
    section.add "X-Amz-Algorithm", valid_21626848
  var valid_21626849 = header.getOrDefault("X-Amz-Signature")
  valid_21626849 = validateParameter(valid_21626849, JString, required = false,
                                   default = nil)
  if valid_21626849 != nil:
    section.add "X-Amz-Signature", valid_21626849
  var valid_21626850 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626850 = validateParameter(valid_21626850, JString, required = false,
                                   default = nil)
  if valid_21626850 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626850
  var valid_21626851 = header.getOrDefault("X-Amz-Credential")
  valid_21626851 = validateParameter(valid_21626851, JString, required = false,
                                   default = nil)
  if valid_21626851 != nil:
    section.add "X-Amz-Credential", valid_21626851
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626853: Call_ListVolumes_21626839; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Lists the iSCSI stored volumes of a gateway. Results are sorted by volume ARN. The response includes only the volume ARNs. If you want additional volume information, use the <a>DescribeStorediSCSIVolumes</a> or the <a>DescribeCachediSCSIVolumes</a> API.</p> <p>The operation supports pagination. By default, the operation returns a maximum of up to 100 volumes. You can optionally specify the <code>Limit</code> field in the body to limit the number of volumes in the response. If the number of volumes returned in the response is truncated, the response includes a Marker field. You can use this Marker value in your subsequent request to retrieve the next set of volumes. This operation is only supported in the cached volume and stored volume gateway types.</p>
  ## 
  let valid = call_21626853.validator(path, query, header, formData, body, _)
  let scheme = call_21626853.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626853.makeUrl(scheme.get, call_21626853.host, call_21626853.base,
                               call_21626853.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626853, uri, valid, _)

proc call*(call_21626854: Call_ListVolumes_21626839; body: JsonNode;
          Limit: string = ""; Marker: string = ""): Recallable =
  ## listVolumes
  ## <p>Lists the iSCSI stored volumes of a gateway. Results are sorted by volume ARN. The response includes only the volume ARNs. If you want additional volume information, use the <a>DescribeStorediSCSIVolumes</a> or the <a>DescribeCachediSCSIVolumes</a> API.</p> <p>The operation supports pagination. By default, the operation returns a maximum of up to 100 volumes. You can optionally specify the <code>Limit</code> field in the body to limit the number of volumes in the response. If the number of volumes returned in the response is truncated, the response includes a Marker field. You can use this Marker value in your subsequent request to retrieve the next set of volumes. This operation is only supported in the cached volume and stored volume gateway types.</p>
  ##   Limit: string
  ##        : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_21626855 = newJObject()
  var body_21626856 = newJObject()
  add(query_21626855, "Limit", newJString(Limit))
  add(query_21626855, "Marker", newJString(Marker))
  if body != nil:
    body_21626856 = body
  result = call_21626854.call(nil, query_21626855, nil, nil, body_21626856)

var listVolumes* = Call_ListVolumes_21626839(name: "listVolumes",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.ListVolumes",
    validator: validate_ListVolumes_21626840, base: "/", makeUrl: url_ListVolumes_21626841,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_NotifyWhenUploaded_21626857 = ref object of OpenApiRestCall_21625437
proc url_NotifyWhenUploaded_21626859(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_NotifyWhenUploaded_21626858(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Sends you notification through CloudWatch Events when all files written to your file share have been uploaded to Amazon S3.</p> <p>AWS Storage Gateway can send a notification through Amazon CloudWatch Events when all files written to your file share up to that point in time have been uploaded to Amazon S3. These files include files written to the file share up to the time that you make a request for notification. When the upload is done, Storage Gateway sends you notification through an Amazon CloudWatch Event. You can configure CloudWatch Events to send the notification through event targets such as Amazon SNS or AWS Lambda function. This operation is only supported for file gateways.</p> <p>For more information, see Getting File Upload Notification in the Storage Gateway User Guide (https://docs.aws.amazon.com/storagegateway/latest/userguide/monitoring-file-gateway.html#get-upload-notification). </p>
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
  var valid_21626860 = header.getOrDefault("X-Amz-Date")
  valid_21626860 = validateParameter(valid_21626860, JString, required = false,
                                   default = nil)
  if valid_21626860 != nil:
    section.add "X-Amz-Date", valid_21626860
  var valid_21626861 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626861 = validateParameter(valid_21626861, JString, required = false,
                                   default = nil)
  if valid_21626861 != nil:
    section.add "X-Amz-Security-Token", valid_21626861
  var valid_21626862 = header.getOrDefault("X-Amz-Target")
  valid_21626862 = validateParameter(valid_21626862, JString, required = true, default = newJString(
      "StorageGateway_20130630.NotifyWhenUploaded"))
  if valid_21626862 != nil:
    section.add "X-Amz-Target", valid_21626862
  var valid_21626863 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626863 = validateParameter(valid_21626863, JString, required = false,
                                   default = nil)
  if valid_21626863 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626863
  var valid_21626864 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626864 = validateParameter(valid_21626864, JString, required = false,
                                   default = nil)
  if valid_21626864 != nil:
    section.add "X-Amz-Algorithm", valid_21626864
  var valid_21626865 = header.getOrDefault("X-Amz-Signature")
  valid_21626865 = validateParameter(valid_21626865, JString, required = false,
                                   default = nil)
  if valid_21626865 != nil:
    section.add "X-Amz-Signature", valid_21626865
  var valid_21626866 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626866 = validateParameter(valid_21626866, JString, required = false,
                                   default = nil)
  if valid_21626866 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626866
  var valid_21626867 = header.getOrDefault("X-Amz-Credential")
  valid_21626867 = validateParameter(valid_21626867, JString, required = false,
                                   default = nil)
  if valid_21626867 != nil:
    section.add "X-Amz-Credential", valid_21626867
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626869: Call_NotifyWhenUploaded_21626857; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Sends you notification through CloudWatch Events when all files written to your file share have been uploaded to Amazon S3.</p> <p>AWS Storage Gateway can send a notification through Amazon CloudWatch Events when all files written to your file share up to that point in time have been uploaded to Amazon S3. These files include files written to the file share up to the time that you make a request for notification. When the upload is done, Storage Gateway sends you notification through an Amazon CloudWatch Event. You can configure CloudWatch Events to send the notification through event targets such as Amazon SNS or AWS Lambda function. This operation is only supported for file gateways.</p> <p>For more information, see Getting File Upload Notification in the Storage Gateway User Guide (https://docs.aws.amazon.com/storagegateway/latest/userguide/monitoring-file-gateway.html#get-upload-notification). </p>
  ## 
  let valid = call_21626869.validator(path, query, header, formData, body, _)
  let scheme = call_21626869.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626869.makeUrl(scheme.get, call_21626869.host, call_21626869.base,
                               call_21626869.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626869, uri, valid, _)

proc call*(call_21626870: Call_NotifyWhenUploaded_21626857; body: JsonNode): Recallable =
  ## notifyWhenUploaded
  ## <p>Sends you notification through CloudWatch Events when all files written to your file share have been uploaded to Amazon S3.</p> <p>AWS Storage Gateway can send a notification through Amazon CloudWatch Events when all files written to your file share up to that point in time have been uploaded to Amazon S3. These files include files written to the file share up to the time that you make a request for notification. When the upload is done, Storage Gateway sends you notification through an Amazon CloudWatch Event. You can configure CloudWatch Events to send the notification through event targets such as Amazon SNS or AWS Lambda function. This operation is only supported for file gateways.</p> <p>For more information, see Getting File Upload Notification in the Storage Gateway User Guide (https://docs.aws.amazon.com/storagegateway/latest/userguide/monitoring-file-gateway.html#get-upload-notification). </p>
  ##   body: JObject (required)
  var body_21626871 = newJObject()
  if body != nil:
    body_21626871 = body
  result = call_21626870.call(nil, nil, nil, nil, body_21626871)

var notifyWhenUploaded* = Call_NotifyWhenUploaded_21626857(
    name: "notifyWhenUploaded", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.NotifyWhenUploaded",
    validator: validate_NotifyWhenUploaded_21626858, base: "/",
    makeUrl: url_NotifyWhenUploaded_21626859, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RefreshCache_21626872 = ref object of OpenApiRestCall_21625437
proc url_RefreshCache_21626874(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RefreshCache_21626873(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>Refreshes the cache for the specified file share. This operation finds objects in the Amazon S3 bucket that were added, removed or replaced since the gateway last listed the bucket's contents and cached the results. This operation is only supported in the file gateway type. You can subscribe to be notified through an Amazon CloudWatch event when your RefreshCache operation completes. For more information, see <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/monitoring-file-gateway.html#get-notification">Getting Notified About File Operations</a>.</p> <p>When this API is called, it only initiates the refresh operation. When the API call completes and returns a success code, it doesn't necessarily mean that the file refresh has completed. You should use the refresh-complete notification to determine that the operation has completed before you check for new files on the gateway file share. You can subscribe to be notified through an CloudWatch event when your <code>RefreshCache</code> operation completes. </p> <p>Throttle limit: This API is asynchronous so the gateway will accept no more than two refreshes at any time. We recommend using the refresh-complete CloudWatch event notification before issuing additional requests. For more information, see <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/monitoring-file-gateway.html#get-notification">Getting Notified About File Operations</a>.</p> <p>If you invoke the RefreshCache API when two requests are already being processed, any new request will cause an <code>InvalidGatewayRequestException</code> error because too many requests were sent to the server.</p> <p>For more information, see "https://docs.aws.amazon.com/storagegateway/latest/userguide/monitoring-file-gateway.html#get-notification".</p>
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
  var valid_21626875 = header.getOrDefault("X-Amz-Date")
  valid_21626875 = validateParameter(valid_21626875, JString, required = false,
                                   default = nil)
  if valid_21626875 != nil:
    section.add "X-Amz-Date", valid_21626875
  var valid_21626876 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626876 = validateParameter(valid_21626876, JString, required = false,
                                   default = nil)
  if valid_21626876 != nil:
    section.add "X-Amz-Security-Token", valid_21626876
  var valid_21626877 = header.getOrDefault("X-Amz-Target")
  valid_21626877 = validateParameter(valid_21626877, JString, required = true, default = newJString(
      "StorageGateway_20130630.RefreshCache"))
  if valid_21626877 != nil:
    section.add "X-Amz-Target", valid_21626877
  var valid_21626878 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626878 = validateParameter(valid_21626878, JString, required = false,
                                   default = nil)
  if valid_21626878 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626878
  var valid_21626879 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626879 = validateParameter(valid_21626879, JString, required = false,
                                   default = nil)
  if valid_21626879 != nil:
    section.add "X-Amz-Algorithm", valid_21626879
  var valid_21626880 = header.getOrDefault("X-Amz-Signature")
  valid_21626880 = validateParameter(valid_21626880, JString, required = false,
                                   default = nil)
  if valid_21626880 != nil:
    section.add "X-Amz-Signature", valid_21626880
  var valid_21626881 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626881 = validateParameter(valid_21626881, JString, required = false,
                                   default = nil)
  if valid_21626881 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626881
  var valid_21626882 = header.getOrDefault("X-Amz-Credential")
  valid_21626882 = validateParameter(valid_21626882, JString, required = false,
                                   default = nil)
  if valid_21626882 != nil:
    section.add "X-Amz-Credential", valid_21626882
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626884: Call_RefreshCache_21626872; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Refreshes the cache for the specified file share. This operation finds objects in the Amazon S3 bucket that were added, removed or replaced since the gateway last listed the bucket's contents and cached the results. This operation is only supported in the file gateway type. You can subscribe to be notified through an Amazon CloudWatch event when your RefreshCache operation completes. For more information, see <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/monitoring-file-gateway.html#get-notification">Getting Notified About File Operations</a>.</p> <p>When this API is called, it only initiates the refresh operation. When the API call completes and returns a success code, it doesn't necessarily mean that the file refresh has completed. You should use the refresh-complete notification to determine that the operation has completed before you check for new files on the gateway file share. You can subscribe to be notified through an CloudWatch event when your <code>RefreshCache</code> operation completes. </p> <p>Throttle limit: This API is asynchronous so the gateway will accept no more than two refreshes at any time. We recommend using the refresh-complete CloudWatch event notification before issuing additional requests. For more information, see <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/monitoring-file-gateway.html#get-notification">Getting Notified About File Operations</a>.</p> <p>If you invoke the RefreshCache API when two requests are already being processed, any new request will cause an <code>InvalidGatewayRequestException</code> error because too many requests were sent to the server.</p> <p>For more information, see "https://docs.aws.amazon.com/storagegateway/latest/userguide/monitoring-file-gateway.html#get-notification".</p>
  ## 
  let valid = call_21626884.validator(path, query, header, formData, body, _)
  let scheme = call_21626884.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626884.makeUrl(scheme.get, call_21626884.host, call_21626884.base,
                               call_21626884.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626884, uri, valid, _)

proc call*(call_21626885: Call_RefreshCache_21626872; body: JsonNode): Recallable =
  ## refreshCache
  ## <p>Refreshes the cache for the specified file share. This operation finds objects in the Amazon S3 bucket that were added, removed or replaced since the gateway last listed the bucket's contents and cached the results. This operation is only supported in the file gateway type. You can subscribe to be notified through an Amazon CloudWatch event when your RefreshCache operation completes. For more information, see <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/monitoring-file-gateway.html#get-notification">Getting Notified About File Operations</a>.</p> <p>When this API is called, it only initiates the refresh operation. When the API call completes and returns a success code, it doesn't necessarily mean that the file refresh has completed. You should use the refresh-complete notification to determine that the operation has completed before you check for new files on the gateway file share. You can subscribe to be notified through an CloudWatch event when your <code>RefreshCache</code> operation completes. </p> <p>Throttle limit: This API is asynchronous so the gateway will accept no more than two refreshes at any time. We recommend using the refresh-complete CloudWatch event notification before issuing additional requests. For more information, see <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/monitoring-file-gateway.html#get-notification">Getting Notified About File Operations</a>.</p> <p>If you invoke the RefreshCache API when two requests are already being processed, any new request will cause an <code>InvalidGatewayRequestException</code> error because too many requests were sent to the server.</p> <p>For more information, see "https://docs.aws.amazon.com/storagegateway/latest/userguide/monitoring-file-gateway.html#get-notification".</p>
  ##   body: JObject (required)
  var body_21626886 = newJObject()
  if body != nil:
    body_21626886 = body
  result = call_21626885.call(nil, nil, nil, nil, body_21626886)

var refreshCache* = Call_RefreshCache_21626872(name: "refreshCache",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.RefreshCache",
    validator: validate_RefreshCache_21626873, base: "/", makeUrl: url_RefreshCache_21626874,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveTagsFromResource_21626887 = ref object of OpenApiRestCall_21625437
proc url_RemoveTagsFromResource_21626889(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RemoveTagsFromResource_21626888(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Removes one or more tags from the specified resource. This operation is supported in storage gateways of all types.
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
  var valid_21626890 = header.getOrDefault("X-Amz-Date")
  valid_21626890 = validateParameter(valid_21626890, JString, required = false,
                                   default = nil)
  if valid_21626890 != nil:
    section.add "X-Amz-Date", valid_21626890
  var valid_21626891 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626891 = validateParameter(valid_21626891, JString, required = false,
                                   default = nil)
  if valid_21626891 != nil:
    section.add "X-Amz-Security-Token", valid_21626891
  var valid_21626892 = header.getOrDefault("X-Amz-Target")
  valid_21626892 = validateParameter(valid_21626892, JString, required = true, default = newJString(
      "StorageGateway_20130630.RemoveTagsFromResource"))
  if valid_21626892 != nil:
    section.add "X-Amz-Target", valid_21626892
  var valid_21626893 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626893 = validateParameter(valid_21626893, JString, required = false,
                                   default = nil)
  if valid_21626893 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626893
  var valid_21626894 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626894 = validateParameter(valid_21626894, JString, required = false,
                                   default = nil)
  if valid_21626894 != nil:
    section.add "X-Amz-Algorithm", valid_21626894
  var valid_21626895 = header.getOrDefault("X-Amz-Signature")
  valid_21626895 = validateParameter(valid_21626895, JString, required = false,
                                   default = nil)
  if valid_21626895 != nil:
    section.add "X-Amz-Signature", valid_21626895
  var valid_21626896 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626896 = validateParameter(valid_21626896, JString, required = false,
                                   default = nil)
  if valid_21626896 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626896
  var valid_21626897 = header.getOrDefault("X-Amz-Credential")
  valid_21626897 = validateParameter(valid_21626897, JString, required = false,
                                   default = nil)
  if valid_21626897 != nil:
    section.add "X-Amz-Credential", valid_21626897
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626899: Call_RemoveTagsFromResource_21626887;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes one or more tags from the specified resource. This operation is supported in storage gateways of all types.
  ## 
  let valid = call_21626899.validator(path, query, header, formData, body, _)
  let scheme = call_21626899.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626899.makeUrl(scheme.get, call_21626899.host, call_21626899.base,
                               call_21626899.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626899, uri, valid, _)

proc call*(call_21626900: Call_RemoveTagsFromResource_21626887; body: JsonNode): Recallable =
  ## removeTagsFromResource
  ## Removes one or more tags from the specified resource. This operation is supported in storage gateways of all types.
  ##   body: JObject (required)
  var body_21626901 = newJObject()
  if body != nil:
    body_21626901 = body
  result = call_21626900.call(nil, nil, nil, nil, body_21626901)

var removeTagsFromResource* = Call_RemoveTagsFromResource_21626887(
    name: "removeTagsFromResource", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.RemoveTagsFromResource",
    validator: validate_RemoveTagsFromResource_21626888, base: "/",
    makeUrl: url_RemoveTagsFromResource_21626889,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResetCache_21626902 = ref object of OpenApiRestCall_21625437
proc url_ResetCache_21626904(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ResetCache_21626903(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Resets all cache disks that have encountered a error and makes the disks available for reconfiguration as cache storage. If your cache disk encounters a error, the gateway prevents read and write operations on virtual tapes in the gateway. For example, an error can occur when a disk is corrupted or removed from the gateway. When a cache is reset, the gateway loses its cache storage. At this point you can reconfigure the disks as cache disks. This operation is only supported in the cached volume and tape types.</p> <important> <p>If the cache disk you are resetting contains data that has not been uploaded to Amazon S3 yet, that data can be lost. After you reset cache disks, there will be no configured cache disks left in the gateway, so you must configure at least one new cache disk for your gateway to function properly.</p> </important>
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
  var valid_21626905 = header.getOrDefault("X-Amz-Date")
  valid_21626905 = validateParameter(valid_21626905, JString, required = false,
                                   default = nil)
  if valid_21626905 != nil:
    section.add "X-Amz-Date", valid_21626905
  var valid_21626906 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626906 = validateParameter(valid_21626906, JString, required = false,
                                   default = nil)
  if valid_21626906 != nil:
    section.add "X-Amz-Security-Token", valid_21626906
  var valid_21626907 = header.getOrDefault("X-Amz-Target")
  valid_21626907 = validateParameter(valid_21626907, JString, required = true, default = newJString(
      "StorageGateway_20130630.ResetCache"))
  if valid_21626907 != nil:
    section.add "X-Amz-Target", valid_21626907
  var valid_21626908 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626908 = validateParameter(valid_21626908, JString, required = false,
                                   default = nil)
  if valid_21626908 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626908
  var valid_21626909 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626909 = validateParameter(valid_21626909, JString, required = false,
                                   default = nil)
  if valid_21626909 != nil:
    section.add "X-Amz-Algorithm", valid_21626909
  var valid_21626910 = header.getOrDefault("X-Amz-Signature")
  valid_21626910 = validateParameter(valid_21626910, JString, required = false,
                                   default = nil)
  if valid_21626910 != nil:
    section.add "X-Amz-Signature", valid_21626910
  var valid_21626911 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626911 = validateParameter(valid_21626911, JString, required = false,
                                   default = nil)
  if valid_21626911 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626911
  var valid_21626912 = header.getOrDefault("X-Amz-Credential")
  valid_21626912 = validateParameter(valid_21626912, JString, required = false,
                                   default = nil)
  if valid_21626912 != nil:
    section.add "X-Amz-Credential", valid_21626912
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626914: Call_ResetCache_21626902; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Resets all cache disks that have encountered a error and makes the disks available for reconfiguration as cache storage. If your cache disk encounters a error, the gateway prevents read and write operations on virtual tapes in the gateway. For example, an error can occur when a disk is corrupted or removed from the gateway. When a cache is reset, the gateway loses its cache storage. At this point you can reconfigure the disks as cache disks. This operation is only supported in the cached volume and tape types.</p> <important> <p>If the cache disk you are resetting contains data that has not been uploaded to Amazon S3 yet, that data can be lost. After you reset cache disks, there will be no configured cache disks left in the gateway, so you must configure at least one new cache disk for your gateway to function properly.</p> </important>
  ## 
  let valid = call_21626914.validator(path, query, header, formData, body, _)
  let scheme = call_21626914.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626914.makeUrl(scheme.get, call_21626914.host, call_21626914.base,
                               call_21626914.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626914, uri, valid, _)

proc call*(call_21626915: Call_ResetCache_21626902; body: JsonNode): Recallable =
  ## resetCache
  ## <p>Resets all cache disks that have encountered a error and makes the disks available for reconfiguration as cache storage. If your cache disk encounters a error, the gateway prevents read and write operations on virtual tapes in the gateway. For example, an error can occur when a disk is corrupted or removed from the gateway. When a cache is reset, the gateway loses its cache storage. At this point you can reconfigure the disks as cache disks. This operation is only supported in the cached volume and tape types.</p> <important> <p>If the cache disk you are resetting contains data that has not been uploaded to Amazon S3 yet, that data can be lost. After you reset cache disks, there will be no configured cache disks left in the gateway, so you must configure at least one new cache disk for your gateway to function properly.</p> </important>
  ##   body: JObject (required)
  var body_21626916 = newJObject()
  if body != nil:
    body_21626916 = body
  result = call_21626915.call(nil, nil, nil, nil, body_21626916)

var resetCache* = Call_ResetCache_21626902(name: "resetCache",
                                        meth: HttpMethod.HttpPost,
                                        host: "storagegateway.amazonaws.com", route: "/#X-Amz-Target=StorageGateway_20130630.ResetCache",
                                        validator: validate_ResetCache_21626903,
                                        base: "/", makeUrl: url_ResetCache_21626904,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_RetrieveTapeArchive_21626917 = ref object of OpenApiRestCall_21625437
proc url_RetrieveTapeArchive_21626919(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RetrieveTapeArchive_21626918(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Retrieves an archived virtual tape from the virtual tape shelf (VTS) to a tape gateway. Virtual tapes archived in the VTS are not associated with any gateway. However after a tape is retrieved, it is associated with a gateway, even though it is also listed in the VTS, that is, archive. This operation is only supported in the tape gateway type.</p> <p>Once a tape is successfully retrieved to a gateway, it cannot be retrieved again to another gateway. You must archive the tape again before you can retrieve it to another gateway. This operation is only supported in the tape gateway type.</p>
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
  var valid_21626920 = header.getOrDefault("X-Amz-Date")
  valid_21626920 = validateParameter(valid_21626920, JString, required = false,
                                   default = nil)
  if valid_21626920 != nil:
    section.add "X-Amz-Date", valid_21626920
  var valid_21626921 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626921 = validateParameter(valid_21626921, JString, required = false,
                                   default = nil)
  if valid_21626921 != nil:
    section.add "X-Amz-Security-Token", valid_21626921
  var valid_21626922 = header.getOrDefault("X-Amz-Target")
  valid_21626922 = validateParameter(valid_21626922, JString, required = true, default = newJString(
      "StorageGateway_20130630.RetrieveTapeArchive"))
  if valid_21626922 != nil:
    section.add "X-Amz-Target", valid_21626922
  var valid_21626923 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626923 = validateParameter(valid_21626923, JString, required = false,
                                   default = nil)
  if valid_21626923 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626923
  var valid_21626924 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626924 = validateParameter(valid_21626924, JString, required = false,
                                   default = nil)
  if valid_21626924 != nil:
    section.add "X-Amz-Algorithm", valid_21626924
  var valid_21626925 = header.getOrDefault("X-Amz-Signature")
  valid_21626925 = validateParameter(valid_21626925, JString, required = false,
                                   default = nil)
  if valid_21626925 != nil:
    section.add "X-Amz-Signature", valid_21626925
  var valid_21626926 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626926 = validateParameter(valid_21626926, JString, required = false,
                                   default = nil)
  if valid_21626926 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626926
  var valid_21626927 = header.getOrDefault("X-Amz-Credential")
  valid_21626927 = validateParameter(valid_21626927, JString, required = false,
                                   default = nil)
  if valid_21626927 != nil:
    section.add "X-Amz-Credential", valid_21626927
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626929: Call_RetrieveTapeArchive_21626917; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Retrieves an archived virtual tape from the virtual tape shelf (VTS) to a tape gateway. Virtual tapes archived in the VTS are not associated with any gateway. However after a tape is retrieved, it is associated with a gateway, even though it is also listed in the VTS, that is, archive. This operation is only supported in the tape gateway type.</p> <p>Once a tape is successfully retrieved to a gateway, it cannot be retrieved again to another gateway. You must archive the tape again before you can retrieve it to another gateway. This operation is only supported in the tape gateway type.</p>
  ## 
  let valid = call_21626929.validator(path, query, header, formData, body, _)
  let scheme = call_21626929.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626929.makeUrl(scheme.get, call_21626929.host, call_21626929.base,
                               call_21626929.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626929, uri, valid, _)

proc call*(call_21626930: Call_RetrieveTapeArchive_21626917; body: JsonNode): Recallable =
  ## retrieveTapeArchive
  ## <p>Retrieves an archived virtual tape from the virtual tape shelf (VTS) to a tape gateway. Virtual tapes archived in the VTS are not associated with any gateway. However after a tape is retrieved, it is associated with a gateway, even though it is also listed in the VTS, that is, archive. This operation is only supported in the tape gateway type.</p> <p>Once a tape is successfully retrieved to a gateway, it cannot be retrieved again to another gateway. You must archive the tape again before you can retrieve it to another gateway. This operation is only supported in the tape gateway type.</p>
  ##   body: JObject (required)
  var body_21626931 = newJObject()
  if body != nil:
    body_21626931 = body
  result = call_21626930.call(nil, nil, nil, nil, body_21626931)

var retrieveTapeArchive* = Call_RetrieveTapeArchive_21626917(
    name: "retrieveTapeArchive", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.RetrieveTapeArchive",
    validator: validate_RetrieveTapeArchive_21626918, base: "/",
    makeUrl: url_RetrieveTapeArchive_21626919,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RetrieveTapeRecoveryPoint_21626932 = ref object of OpenApiRestCall_21625437
proc url_RetrieveTapeRecoveryPoint_21626934(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RetrieveTapeRecoveryPoint_21626933(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Retrieves the recovery point for the specified virtual tape. This operation is only supported in the tape gateway type.</p> <p>A recovery point is a point in time view of a virtual tape at which all the data on the tape is consistent. If your gateway crashes, virtual tapes that have recovery points can be recovered to a new gateway.</p> <note> <p>The virtual tape can be retrieved to only one gateway. The retrieved tape is read-only. The virtual tape can be retrieved to only a tape gateway. There is no charge for retrieving recovery points.</p> </note>
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
  var valid_21626935 = header.getOrDefault("X-Amz-Date")
  valid_21626935 = validateParameter(valid_21626935, JString, required = false,
                                   default = nil)
  if valid_21626935 != nil:
    section.add "X-Amz-Date", valid_21626935
  var valid_21626936 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626936 = validateParameter(valid_21626936, JString, required = false,
                                   default = nil)
  if valid_21626936 != nil:
    section.add "X-Amz-Security-Token", valid_21626936
  var valid_21626937 = header.getOrDefault("X-Amz-Target")
  valid_21626937 = validateParameter(valid_21626937, JString, required = true, default = newJString(
      "StorageGateway_20130630.RetrieveTapeRecoveryPoint"))
  if valid_21626937 != nil:
    section.add "X-Amz-Target", valid_21626937
  var valid_21626938 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626938 = validateParameter(valid_21626938, JString, required = false,
                                   default = nil)
  if valid_21626938 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626938
  var valid_21626939 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626939 = validateParameter(valid_21626939, JString, required = false,
                                   default = nil)
  if valid_21626939 != nil:
    section.add "X-Amz-Algorithm", valid_21626939
  var valid_21626940 = header.getOrDefault("X-Amz-Signature")
  valid_21626940 = validateParameter(valid_21626940, JString, required = false,
                                   default = nil)
  if valid_21626940 != nil:
    section.add "X-Amz-Signature", valid_21626940
  var valid_21626941 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626941 = validateParameter(valid_21626941, JString, required = false,
                                   default = nil)
  if valid_21626941 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626941
  var valid_21626942 = header.getOrDefault("X-Amz-Credential")
  valid_21626942 = validateParameter(valid_21626942, JString, required = false,
                                   default = nil)
  if valid_21626942 != nil:
    section.add "X-Amz-Credential", valid_21626942
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626944: Call_RetrieveTapeRecoveryPoint_21626932;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Retrieves the recovery point for the specified virtual tape. This operation is only supported in the tape gateway type.</p> <p>A recovery point is a point in time view of a virtual tape at which all the data on the tape is consistent. If your gateway crashes, virtual tapes that have recovery points can be recovered to a new gateway.</p> <note> <p>The virtual tape can be retrieved to only one gateway. The retrieved tape is read-only. The virtual tape can be retrieved to only a tape gateway. There is no charge for retrieving recovery points.</p> </note>
  ## 
  let valid = call_21626944.validator(path, query, header, formData, body, _)
  let scheme = call_21626944.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626944.makeUrl(scheme.get, call_21626944.host, call_21626944.base,
                               call_21626944.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626944, uri, valid, _)

proc call*(call_21626945: Call_RetrieveTapeRecoveryPoint_21626932; body: JsonNode): Recallable =
  ## retrieveTapeRecoveryPoint
  ## <p>Retrieves the recovery point for the specified virtual tape. This operation is only supported in the tape gateway type.</p> <p>A recovery point is a point in time view of a virtual tape at which all the data on the tape is consistent. If your gateway crashes, virtual tapes that have recovery points can be recovered to a new gateway.</p> <note> <p>The virtual tape can be retrieved to only one gateway. The retrieved tape is read-only. The virtual tape can be retrieved to only a tape gateway. There is no charge for retrieving recovery points.</p> </note>
  ##   body: JObject (required)
  var body_21626946 = newJObject()
  if body != nil:
    body_21626946 = body
  result = call_21626945.call(nil, nil, nil, nil, body_21626946)

var retrieveTapeRecoveryPoint* = Call_RetrieveTapeRecoveryPoint_21626932(
    name: "retrieveTapeRecoveryPoint", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.RetrieveTapeRecoveryPoint",
    validator: validate_RetrieveTapeRecoveryPoint_21626933, base: "/",
    makeUrl: url_RetrieveTapeRecoveryPoint_21626934,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetLocalConsolePassword_21626947 = ref object of OpenApiRestCall_21625437
proc url_SetLocalConsolePassword_21626949(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SetLocalConsolePassword_21626948(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Sets the password for your VM local console. When you log in to the local console for the first time, you log in to the VM with the default credentials. We recommend that you set a new password. You don't need to know the default password to set a new password.
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
  var valid_21626950 = header.getOrDefault("X-Amz-Date")
  valid_21626950 = validateParameter(valid_21626950, JString, required = false,
                                   default = nil)
  if valid_21626950 != nil:
    section.add "X-Amz-Date", valid_21626950
  var valid_21626951 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626951 = validateParameter(valid_21626951, JString, required = false,
                                   default = nil)
  if valid_21626951 != nil:
    section.add "X-Amz-Security-Token", valid_21626951
  var valid_21626952 = header.getOrDefault("X-Amz-Target")
  valid_21626952 = validateParameter(valid_21626952, JString, required = true, default = newJString(
      "StorageGateway_20130630.SetLocalConsolePassword"))
  if valid_21626952 != nil:
    section.add "X-Amz-Target", valid_21626952
  var valid_21626953 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626953 = validateParameter(valid_21626953, JString, required = false,
                                   default = nil)
  if valid_21626953 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626953
  var valid_21626954 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626954 = validateParameter(valid_21626954, JString, required = false,
                                   default = nil)
  if valid_21626954 != nil:
    section.add "X-Amz-Algorithm", valid_21626954
  var valid_21626955 = header.getOrDefault("X-Amz-Signature")
  valid_21626955 = validateParameter(valid_21626955, JString, required = false,
                                   default = nil)
  if valid_21626955 != nil:
    section.add "X-Amz-Signature", valid_21626955
  var valid_21626956 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626956 = validateParameter(valid_21626956, JString, required = false,
                                   default = nil)
  if valid_21626956 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626956
  var valid_21626957 = header.getOrDefault("X-Amz-Credential")
  valid_21626957 = validateParameter(valid_21626957, JString, required = false,
                                   default = nil)
  if valid_21626957 != nil:
    section.add "X-Amz-Credential", valid_21626957
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626959: Call_SetLocalConsolePassword_21626947;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Sets the password for your VM local console. When you log in to the local console for the first time, you log in to the VM with the default credentials. We recommend that you set a new password. You don't need to know the default password to set a new password.
  ## 
  let valid = call_21626959.validator(path, query, header, formData, body, _)
  let scheme = call_21626959.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626959.makeUrl(scheme.get, call_21626959.host, call_21626959.base,
                               call_21626959.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626959, uri, valid, _)

proc call*(call_21626960: Call_SetLocalConsolePassword_21626947; body: JsonNode): Recallable =
  ## setLocalConsolePassword
  ## Sets the password for your VM local console. When you log in to the local console for the first time, you log in to the VM with the default credentials. We recommend that you set a new password. You don't need to know the default password to set a new password.
  ##   body: JObject (required)
  var body_21626961 = newJObject()
  if body != nil:
    body_21626961 = body
  result = call_21626960.call(nil, nil, nil, nil, body_21626961)

var setLocalConsolePassword* = Call_SetLocalConsolePassword_21626947(
    name: "setLocalConsolePassword", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.SetLocalConsolePassword",
    validator: validate_SetLocalConsolePassword_21626948, base: "/",
    makeUrl: url_SetLocalConsolePassword_21626949,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetSMBGuestPassword_21626962 = ref object of OpenApiRestCall_21625437
proc url_SetSMBGuestPassword_21626964(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SetSMBGuestPassword_21626963(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Sets the password for the guest user <code>smbguest</code>. The <code>smbguest</code> user is the user when the authentication method for the file share is set to <code>GuestAccess</code>.
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
  var valid_21626965 = header.getOrDefault("X-Amz-Date")
  valid_21626965 = validateParameter(valid_21626965, JString, required = false,
                                   default = nil)
  if valid_21626965 != nil:
    section.add "X-Amz-Date", valid_21626965
  var valid_21626966 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626966 = validateParameter(valid_21626966, JString, required = false,
                                   default = nil)
  if valid_21626966 != nil:
    section.add "X-Amz-Security-Token", valid_21626966
  var valid_21626967 = header.getOrDefault("X-Amz-Target")
  valid_21626967 = validateParameter(valid_21626967, JString, required = true, default = newJString(
      "StorageGateway_20130630.SetSMBGuestPassword"))
  if valid_21626967 != nil:
    section.add "X-Amz-Target", valid_21626967
  var valid_21626968 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626968 = validateParameter(valid_21626968, JString, required = false,
                                   default = nil)
  if valid_21626968 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626968
  var valid_21626969 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626969 = validateParameter(valid_21626969, JString, required = false,
                                   default = nil)
  if valid_21626969 != nil:
    section.add "X-Amz-Algorithm", valid_21626969
  var valid_21626970 = header.getOrDefault("X-Amz-Signature")
  valid_21626970 = validateParameter(valid_21626970, JString, required = false,
                                   default = nil)
  if valid_21626970 != nil:
    section.add "X-Amz-Signature", valid_21626970
  var valid_21626971 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626971 = validateParameter(valid_21626971, JString, required = false,
                                   default = nil)
  if valid_21626971 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626971
  var valid_21626972 = header.getOrDefault("X-Amz-Credential")
  valid_21626972 = validateParameter(valid_21626972, JString, required = false,
                                   default = nil)
  if valid_21626972 != nil:
    section.add "X-Amz-Credential", valid_21626972
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626974: Call_SetSMBGuestPassword_21626962; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Sets the password for the guest user <code>smbguest</code>. The <code>smbguest</code> user is the user when the authentication method for the file share is set to <code>GuestAccess</code>.
  ## 
  let valid = call_21626974.validator(path, query, header, formData, body, _)
  let scheme = call_21626974.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626974.makeUrl(scheme.get, call_21626974.host, call_21626974.base,
                               call_21626974.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626974, uri, valid, _)

proc call*(call_21626975: Call_SetSMBGuestPassword_21626962; body: JsonNode): Recallable =
  ## setSMBGuestPassword
  ## Sets the password for the guest user <code>smbguest</code>. The <code>smbguest</code> user is the user when the authentication method for the file share is set to <code>GuestAccess</code>.
  ##   body: JObject (required)
  var body_21626976 = newJObject()
  if body != nil:
    body_21626976 = body
  result = call_21626975.call(nil, nil, nil, nil, body_21626976)

var setSMBGuestPassword* = Call_SetSMBGuestPassword_21626962(
    name: "setSMBGuestPassword", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.SetSMBGuestPassword",
    validator: validate_SetSMBGuestPassword_21626963, base: "/",
    makeUrl: url_SetSMBGuestPassword_21626964,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ShutdownGateway_21626977 = ref object of OpenApiRestCall_21625437
proc url_ShutdownGateway_21626979(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ShutdownGateway_21626978(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Shuts down a gateway. To specify which gateway to shut down, use the Amazon Resource Name (ARN) of the gateway in the body of your request.</p> <p>The operation shuts down the gateway service component running in the gateway's virtual machine (VM) and not the host VM.</p> <note> <p>If you want to shut down the VM, it is recommended that you first shut down the gateway component in the VM to avoid unpredictable conditions.</p> </note> <p>After the gateway is shutdown, you cannot call any other API except <a>StartGateway</a>, <a>DescribeGatewayInformation</a>, and <a>ListGateways</a>. For more information, see <a>ActivateGateway</a>. Your applications cannot read from or write to the gateway's storage volumes, and there are no snapshots taken.</p> <note> <p>When you make a shutdown request, you will get a <code>200 OK</code> success response immediately. However, it might take some time for the gateway to shut down. You can call the <a>DescribeGatewayInformation</a> API to check the status. For more information, see <a>ActivateGateway</a>.</p> </note> <p>If do not intend to use the gateway again, you must delete the gateway (using <a>DeleteGateway</a>) to no longer pay software charges associated with the gateway.</p>
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
  var valid_21626980 = header.getOrDefault("X-Amz-Date")
  valid_21626980 = validateParameter(valid_21626980, JString, required = false,
                                   default = nil)
  if valid_21626980 != nil:
    section.add "X-Amz-Date", valid_21626980
  var valid_21626981 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626981 = validateParameter(valid_21626981, JString, required = false,
                                   default = nil)
  if valid_21626981 != nil:
    section.add "X-Amz-Security-Token", valid_21626981
  var valid_21626982 = header.getOrDefault("X-Amz-Target")
  valid_21626982 = validateParameter(valid_21626982, JString, required = true, default = newJString(
      "StorageGateway_20130630.ShutdownGateway"))
  if valid_21626982 != nil:
    section.add "X-Amz-Target", valid_21626982
  var valid_21626983 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626983 = validateParameter(valid_21626983, JString, required = false,
                                   default = nil)
  if valid_21626983 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626983
  var valid_21626984 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626984 = validateParameter(valid_21626984, JString, required = false,
                                   default = nil)
  if valid_21626984 != nil:
    section.add "X-Amz-Algorithm", valid_21626984
  var valid_21626985 = header.getOrDefault("X-Amz-Signature")
  valid_21626985 = validateParameter(valid_21626985, JString, required = false,
                                   default = nil)
  if valid_21626985 != nil:
    section.add "X-Amz-Signature", valid_21626985
  var valid_21626986 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626986 = validateParameter(valid_21626986, JString, required = false,
                                   default = nil)
  if valid_21626986 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626986
  var valid_21626987 = header.getOrDefault("X-Amz-Credential")
  valid_21626987 = validateParameter(valid_21626987, JString, required = false,
                                   default = nil)
  if valid_21626987 != nil:
    section.add "X-Amz-Credential", valid_21626987
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626989: Call_ShutdownGateway_21626977; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Shuts down a gateway. To specify which gateway to shut down, use the Amazon Resource Name (ARN) of the gateway in the body of your request.</p> <p>The operation shuts down the gateway service component running in the gateway's virtual machine (VM) and not the host VM.</p> <note> <p>If you want to shut down the VM, it is recommended that you first shut down the gateway component in the VM to avoid unpredictable conditions.</p> </note> <p>After the gateway is shutdown, you cannot call any other API except <a>StartGateway</a>, <a>DescribeGatewayInformation</a>, and <a>ListGateways</a>. For more information, see <a>ActivateGateway</a>. Your applications cannot read from or write to the gateway's storage volumes, and there are no snapshots taken.</p> <note> <p>When you make a shutdown request, you will get a <code>200 OK</code> success response immediately. However, it might take some time for the gateway to shut down. You can call the <a>DescribeGatewayInformation</a> API to check the status. For more information, see <a>ActivateGateway</a>.</p> </note> <p>If do not intend to use the gateway again, you must delete the gateway (using <a>DeleteGateway</a>) to no longer pay software charges associated with the gateway.</p>
  ## 
  let valid = call_21626989.validator(path, query, header, formData, body, _)
  let scheme = call_21626989.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626989.makeUrl(scheme.get, call_21626989.host, call_21626989.base,
                               call_21626989.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626989, uri, valid, _)

proc call*(call_21626990: Call_ShutdownGateway_21626977; body: JsonNode): Recallable =
  ## shutdownGateway
  ## <p>Shuts down a gateway. To specify which gateway to shut down, use the Amazon Resource Name (ARN) of the gateway in the body of your request.</p> <p>The operation shuts down the gateway service component running in the gateway's virtual machine (VM) and not the host VM.</p> <note> <p>If you want to shut down the VM, it is recommended that you first shut down the gateway component in the VM to avoid unpredictable conditions.</p> </note> <p>After the gateway is shutdown, you cannot call any other API except <a>StartGateway</a>, <a>DescribeGatewayInformation</a>, and <a>ListGateways</a>. For more information, see <a>ActivateGateway</a>. Your applications cannot read from or write to the gateway's storage volumes, and there are no snapshots taken.</p> <note> <p>When you make a shutdown request, you will get a <code>200 OK</code> success response immediately. However, it might take some time for the gateway to shut down. You can call the <a>DescribeGatewayInformation</a> API to check the status. For more information, see <a>ActivateGateway</a>.</p> </note> <p>If do not intend to use the gateway again, you must delete the gateway (using <a>DeleteGateway</a>) to no longer pay software charges associated with the gateway.</p>
  ##   body: JObject (required)
  var body_21626991 = newJObject()
  if body != nil:
    body_21626991 = body
  result = call_21626990.call(nil, nil, nil, nil, body_21626991)

var shutdownGateway* = Call_ShutdownGateway_21626977(name: "shutdownGateway",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.ShutdownGateway",
    validator: validate_ShutdownGateway_21626978, base: "/",
    makeUrl: url_ShutdownGateway_21626979, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartAvailabilityMonitorTest_21626992 = ref object of OpenApiRestCall_21625437
proc url_StartAvailabilityMonitorTest_21626994(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartAvailabilityMonitorTest_21626993(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Start a test that verifies that the specified gateway is configured for High Availability monitoring in your host environment. This request only initiates the test and that a successful response only indicates that the test was started. It doesn't indicate that the test passed. For the status of the test, invoke the <code>DescribeAvailabilityMonitorTest</code> API. </p> <note> <p>Starting this test will cause your gateway to go offline for a brief period.</p> </note>
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
  var valid_21626995 = header.getOrDefault("X-Amz-Date")
  valid_21626995 = validateParameter(valid_21626995, JString, required = false,
                                   default = nil)
  if valid_21626995 != nil:
    section.add "X-Amz-Date", valid_21626995
  var valid_21626996 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626996 = validateParameter(valid_21626996, JString, required = false,
                                   default = nil)
  if valid_21626996 != nil:
    section.add "X-Amz-Security-Token", valid_21626996
  var valid_21626997 = header.getOrDefault("X-Amz-Target")
  valid_21626997 = validateParameter(valid_21626997, JString, required = true, default = newJString(
      "StorageGateway_20130630.StartAvailabilityMonitorTest"))
  if valid_21626997 != nil:
    section.add "X-Amz-Target", valid_21626997
  var valid_21626998 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626998 = validateParameter(valid_21626998, JString, required = false,
                                   default = nil)
  if valid_21626998 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626998
  var valid_21626999 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626999 = validateParameter(valid_21626999, JString, required = false,
                                   default = nil)
  if valid_21626999 != nil:
    section.add "X-Amz-Algorithm", valid_21626999
  var valid_21627000 = header.getOrDefault("X-Amz-Signature")
  valid_21627000 = validateParameter(valid_21627000, JString, required = false,
                                   default = nil)
  if valid_21627000 != nil:
    section.add "X-Amz-Signature", valid_21627000
  var valid_21627001 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627001 = validateParameter(valid_21627001, JString, required = false,
                                   default = nil)
  if valid_21627001 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627001
  var valid_21627002 = header.getOrDefault("X-Amz-Credential")
  valid_21627002 = validateParameter(valid_21627002, JString, required = false,
                                   default = nil)
  if valid_21627002 != nil:
    section.add "X-Amz-Credential", valid_21627002
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627004: Call_StartAvailabilityMonitorTest_21626992;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Start a test that verifies that the specified gateway is configured for High Availability monitoring in your host environment. This request only initiates the test and that a successful response only indicates that the test was started. It doesn't indicate that the test passed. For the status of the test, invoke the <code>DescribeAvailabilityMonitorTest</code> API. </p> <note> <p>Starting this test will cause your gateway to go offline for a brief period.</p> </note>
  ## 
  let valid = call_21627004.validator(path, query, header, formData, body, _)
  let scheme = call_21627004.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627004.makeUrl(scheme.get, call_21627004.host, call_21627004.base,
                               call_21627004.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627004, uri, valid, _)

proc call*(call_21627005: Call_StartAvailabilityMonitorTest_21626992;
          body: JsonNode): Recallable =
  ## startAvailabilityMonitorTest
  ## <p>Start a test that verifies that the specified gateway is configured for High Availability monitoring in your host environment. This request only initiates the test and that a successful response only indicates that the test was started. It doesn't indicate that the test passed. For the status of the test, invoke the <code>DescribeAvailabilityMonitorTest</code> API. </p> <note> <p>Starting this test will cause your gateway to go offline for a brief period.</p> </note>
  ##   body: JObject (required)
  var body_21627006 = newJObject()
  if body != nil:
    body_21627006 = body
  result = call_21627005.call(nil, nil, nil, nil, body_21627006)

var startAvailabilityMonitorTest* = Call_StartAvailabilityMonitorTest_21626992(
    name: "startAvailabilityMonitorTest", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com", route: "/#X-Amz-Target=StorageGateway_20130630.StartAvailabilityMonitorTest",
    validator: validate_StartAvailabilityMonitorTest_21626993, base: "/",
    makeUrl: url_StartAvailabilityMonitorTest_21626994,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartGateway_21627007 = ref object of OpenApiRestCall_21625437
proc url_StartGateway_21627009(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartGateway_21627008(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>Starts a gateway that you previously shut down (see <a>ShutdownGateway</a>). After the gateway starts, you can then make other API calls, your applications can read from or write to the gateway's storage volumes and you will be able to take snapshot backups.</p> <note> <p>When you make a request, you will get a 200 OK success response immediately. However, it might take some time for the gateway to be ready. You should call <a>DescribeGatewayInformation</a> and check the status before making any additional API calls. For more information, see <a>ActivateGateway</a>.</p> </note> <p>To specify which gateway to start, use the Amazon Resource Name (ARN) of the gateway in your request.</p>
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
  var valid_21627010 = header.getOrDefault("X-Amz-Date")
  valid_21627010 = validateParameter(valid_21627010, JString, required = false,
                                   default = nil)
  if valid_21627010 != nil:
    section.add "X-Amz-Date", valid_21627010
  var valid_21627011 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627011 = validateParameter(valid_21627011, JString, required = false,
                                   default = nil)
  if valid_21627011 != nil:
    section.add "X-Amz-Security-Token", valid_21627011
  var valid_21627012 = header.getOrDefault("X-Amz-Target")
  valid_21627012 = validateParameter(valid_21627012, JString, required = true, default = newJString(
      "StorageGateway_20130630.StartGateway"))
  if valid_21627012 != nil:
    section.add "X-Amz-Target", valid_21627012
  var valid_21627013 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627013 = validateParameter(valid_21627013, JString, required = false,
                                   default = nil)
  if valid_21627013 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627013
  var valid_21627014 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627014 = validateParameter(valid_21627014, JString, required = false,
                                   default = nil)
  if valid_21627014 != nil:
    section.add "X-Amz-Algorithm", valid_21627014
  var valid_21627015 = header.getOrDefault("X-Amz-Signature")
  valid_21627015 = validateParameter(valid_21627015, JString, required = false,
                                   default = nil)
  if valid_21627015 != nil:
    section.add "X-Amz-Signature", valid_21627015
  var valid_21627016 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627016 = validateParameter(valid_21627016, JString, required = false,
                                   default = nil)
  if valid_21627016 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627016
  var valid_21627017 = header.getOrDefault("X-Amz-Credential")
  valid_21627017 = validateParameter(valid_21627017, JString, required = false,
                                   default = nil)
  if valid_21627017 != nil:
    section.add "X-Amz-Credential", valid_21627017
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627019: Call_StartGateway_21627007; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Starts a gateway that you previously shut down (see <a>ShutdownGateway</a>). After the gateway starts, you can then make other API calls, your applications can read from or write to the gateway's storage volumes and you will be able to take snapshot backups.</p> <note> <p>When you make a request, you will get a 200 OK success response immediately. However, it might take some time for the gateway to be ready. You should call <a>DescribeGatewayInformation</a> and check the status before making any additional API calls. For more information, see <a>ActivateGateway</a>.</p> </note> <p>To specify which gateway to start, use the Amazon Resource Name (ARN) of the gateway in your request.</p>
  ## 
  let valid = call_21627019.validator(path, query, header, formData, body, _)
  let scheme = call_21627019.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627019.makeUrl(scheme.get, call_21627019.host, call_21627019.base,
                               call_21627019.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627019, uri, valid, _)

proc call*(call_21627020: Call_StartGateway_21627007; body: JsonNode): Recallable =
  ## startGateway
  ## <p>Starts a gateway that you previously shut down (see <a>ShutdownGateway</a>). After the gateway starts, you can then make other API calls, your applications can read from or write to the gateway's storage volumes and you will be able to take snapshot backups.</p> <note> <p>When you make a request, you will get a 200 OK success response immediately. However, it might take some time for the gateway to be ready. You should call <a>DescribeGatewayInformation</a> and check the status before making any additional API calls. For more information, see <a>ActivateGateway</a>.</p> </note> <p>To specify which gateway to start, use the Amazon Resource Name (ARN) of the gateway in your request.</p>
  ##   body: JObject (required)
  var body_21627021 = newJObject()
  if body != nil:
    body_21627021 = body
  result = call_21627020.call(nil, nil, nil, nil, body_21627021)

var startGateway* = Call_StartGateway_21627007(name: "startGateway",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.StartGateway",
    validator: validate_StartGateway_21627008, base: "/", makeUrl: url_StartGateway_21627009,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBandwidthRateLimit_21627022 = ref object of OpenApiRestCall_21625437
proc url_UpdateBandwidthRateLimit_21627024(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateBandwidthRateLimit_21627023(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Updates the bandwidth rate limits of a gateway. You can update both the upload and download bandwidth rate limit or specify only one of the two. If you don't set a bandwidth rate limit, the existing rate limit remains. This operation is supported for the stored volume, cached volume and tape gateway types.'</p> <p>By default, a gateway's bandwidth rate limits are not set. If you don't set any limit, the gateway does not have any limitations on its bandwidth usage and could potentially use the maximum available bandwidth.</p> <p>To specify which gateway to update, use the Amazon Resource Name (ARN) of the gateway in your request.</p>
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
  var valid_21627025 = header.getOrDefault("X-Amz-Date")
  valid_21627025 = validateParameter(valid_21627025, JString, required = false,
                                   default = nil)
  if valid_21627025 != nil:
    section.add "X-Amz-Date", valid_21627025
  var valid_21627026 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627026 = validateParameter(valid_21627026, JString, required = false,
                                   default = nil)
  if valid_21627026 != nil:
    section.add "X-Amz-Security-Token", valid_21627026
  var valid_21627027 = header.getOrDefault("X-Amz-Target")
  valid_21627027 = validateParameter(valid_21627027, JString, required = true, default = newJString(
      "StorageGateway_20130630.UpdateBandwidthRateLimit"))
  if valid_21627027 != nil:
    section.add "X-Amz-Target", valid_21627027
  var valid_21627028 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627028 = validateParameter(valid_21627028, JString, required = false,
                                   default = nil)
  if valid_21627028 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627028
  var valid_21627029 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627029 = validateParameter(valid_21627029, JString, required = false,
                                   default = nil)
  if valid_21627029 != nil:
    section.add "X-Amz-Algorithm", valid_21627029
  var valid_21627030 = header.getOrDefault("X-Amz-Signature")
  valid_21627030 = validateParameter(valid_21627030, JString, required = false,
                                   default = nil)
  if valid_21627030 != nil:
    section.add "X-Amz-Signature", valid_21627030
  var valid_21627031 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627031 = validateParameter(valid_21627031, JString, required = false,
                                   default = nil)
  if valid_21627031 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627031
  var valid_21627032 = header.getOrDefault("X-Amz-Credential")
  valid_21627032 = validateParameter(valid_21627032, JString, required = false,
                                   default = nil)
  if valid_21627032 != nil:
    section.add "X-Amz-Credential", valid_21627032
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627034: Call_UpdateBandwidthRateLimit_21627022;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates the bandwidth rate limits of a gateway. You can update both the upload and download bandwidth rate limit or specify only one of the two. If you don't set a bandwidth rate limit, the existing rate limit remains. This operation is supported for the stored volume, cached volume and tape gateway types.'</p> <p>By default, a gateway's bandwidth rate limits are not set. If you don't set any limit, the gateway does not have any limitations on its bandwidth usage and could potentially use the maximum available bandwidth.</p> <p>To specify which gateway to update, use the Amazon Resource Name (ARN) of the gateway in your request.</p>
  ## 
  let valid = call_21627034.validator(path, query, header, formData, body, _)
  let scheme = call_21627034.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627034.makeUrl(scheme.get, call_21627034.host, call_21627034.base,
                               call_21627034.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627034, uri, valid, _)

proc call*(call_21627035: Call_UpdateBandwidthRateLimit_21627022; body: JsonNode): Recallable =
  ## updateBandwidthRateLimit
  ## <p>Updates the bandwidth rate limits of a gateway. You can update both the upload and download bandwidth rate limit or specify only one of the two. If you don't set a bandwidth rate limit, the existing rate limit remains. This operation is supported for the stored volume, cached volume and tape gateway types.'</p> <p>By default, a gateway's bandwidth rate limits are not set. If you don't set any limit, the gateway does not have any limitations on its bandwidth usage and could potentially use the maximum available bandwidth.</p> <p>To specify which gateway to update, use the Amazon Resource Name (ARN) of the gateway in your request.</p>
  ##   body: JObject (required)
  var body_21627036 = newJObject()
  if body != nil:
    body_21627036 = body
  result = call_21627035.call(nil, nil, nil, nil, body_21627036)

var updateBandwidthRateLimit* = Call_UpdateBandwidthRateLimit_21627022(
    name: "updateBandwidthRateLimit", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.UpdateBandwidthRateLimit",
    validator: validate_UpdateBandwidthRateLimit_21627023, base: "/",
    makeUrl: url_UpdateBandwidthRateLimit_21627024,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateChapCredentials_21627037 = ref object of OpenApiRestCall_21625437
proc url_UpdateChapCredentials_21627039(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateChapCredentials_21627038(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Updates the Challenge-Handshake Authentication Protocol (CHAP) credentials for a specified iSCSI target. By default, a gateway does not have CHAP enabled; however, for added security, you might use it. This operation is supported in the volume and tape gateway types.</p> <important> <p>When you update CHAP credentials, all existing connections on the target are closed and initiators must reconnect with the new credentials.</p> </important>
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
  var valid_21627040 = header.getOrDefault("X-Amz-Date")
  valid_21627040 = validateParameter(valid_21627040, JString, required = false,
                                   default = nil)
  if valid_21627040 != nil:
    section.add "X-Amz-Date", valid_21627040
  var valid_21627041 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627041 = validateParameter(valid_21627041, JString, required = false,
                                   default = nil)
  if valid_21627041 != nil:
    section.add "X-Amz-Security-Token", valid_21627041
  var valid_21627042 = header.getOrDefault("X-Amz-Target")
  valid_21627042 = validateParameter(valid_21627042, JString, required = true, default = newJString(
      "StorageGateway_20130630.UpdateChapCredentials"))
  if valid_21627042 != nil:
    section.add "X-Amz-Target", valid_21627042
  var valid_21627043 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627043 = validateParameter(valid_21627043, JString, required = false,
                                   default = nil)
  if valid_21627043 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627043
  var valid_21627044 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627044 = validateParameter(valid_21627044, JString, required = false,
                                   default = nil)
  if valid_21627044 != nil:
    section.add "X-Amz-Algorithm", valid_21627044
  var valid_21627045 = header.getOrDefault("X-Amz-Signature")
  valid_21627045 = validateParameter(valid_21627045, JString, required = false,
                                   default = nil)
  if valid_21627045 != nil:
    section.add "X-Amz-Signature", valid_21627045
  var valid_21627046 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627046 = validateParameter(valid_21627046, JString, required = false,
                                   default = nil)
  if valid_21627046 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627046
  var valid_21627047 = header.getOrDefault("X-Amz-Credential")
  valid_21627047 = validateParameter(valid_21627047, JString, required = false,
                                   default = nil)
  if valid_21627047 != nil:
    section.add "X-Amz-Credential", valid_21627047
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627049: Call_UpdateChapCredentials_21627037;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates the Challenge-Handshake Authentication Protocol (CHAP) credentials for a specified iSCSI target. By default, a gateway does not have CHAP enabled; however, for added security, you might use it. This operation is supported in the volume and tape gateway types.</p> <important> <p>When you update CHAP credentials, all existing connections on the target are closed and initiators must reconnect with the new credentials.</p> </important>
  ## 
  let valid = call_21627049.validator(path, query, header, formData, body, _)
  let scheme = call_21627049.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627049.makeUrl(scheme.get, call_21627049.host, call_21627049.base,
                               call_21627049.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627049, uri, valid, _)

proc call*(call_21627050: Call_UpdateChapCredentials_21627037; body: JsonNode): Recallable =
  ## updateChapCredentials
  ## <p>Updates the Challenge-Handshake Authentication Protocol (CHAP) credentials for a specified iSCSI target. By default, a gateway does not have CHAP enabled; however, for added security, you might use it. This operation is supported in the volume and tape gateway types.</p> <important> <p>When you update CHAP credentials, all existing connections on the target are closed and initiators must reconnect with the new credentials.</p> </important>
  ##   body: JObject (required)
  var body_21627051 = newJObject()
  if body != nil:
    body_21627051 = body
  result = call_21627050.call(nil, nil, nil, nil, body_21627051)

var updateChapCredentials* = Call_UpdateChapCredentials_21627037(
    name: "updateChapCredentials", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.UpdateChapCredentials",
    validator: validate_UpdateChapCredentials_21627038, base: "/",
    makeUrl: url_UpdateChapCredentials_21627039,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGatewayInformation_21627052 = ref object of OpenApiRestCall_21625437
proc url_UpdateGatewayInformation_21627054(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateGatewayInformation_21627053(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Updates a gateway's metadata, which includes the gateway's name and time zone. To specify which gateway to update, use the Amazon Resource Name (ARN) of the gateway in your request.</p> <note> <p>For Gateways activated after September 2, 2015, the gateway's ARN contains the gateway ID rather than the gateway name. However, changing the name of the gateway has no effect on the gateway's ARN.</p> </note>
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
  var valid_21627055 = header.getOrDefault("X-Amz-Date")
  valid_21627055 = validateParameter(valid_21627055, JString, required = false,
                                   default = nil)
  if valid_21627055 != nil:
    section.add "X-Amz-Date", valid_21627055
  var valid_21627056 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627056 = validateParameter(valid_21627056, JString, required = false,
                                   default = nil)
  if valid_21627056 != nil:
    section.add "X-Amz-Security-Token", valid_21627056
  var valid_21627057 = header.getOrDefault("X-Amz-Target")
  valid_21627057 = validateParameter(valid_21627057, JString, required = true, default = newJString(
      "StorageGateway_20130630.UpdateGatewayInformation"))
  if valid_21627057 != nil:
    section.add "X-Amz-Target", valid_21627057
  var valid_21627058 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627058 = validateParameter(valid_21627058, JString, required = false,
                                   default = nil)
  if valid_21627058 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627058
  var valid_21627059 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627059 = validateParameter(valid_21627059, JString, required = false,
                                   default = nil)
  if valid_21627059 != nil:
    section.add "X-Amz-Algorithm", valid_21627059
  var valid_21627060 = header.getOrDefault("X-Amz-Signature")
  valid_21627060 = validateParameter(valid_21627060, JString, required = false,
                                   default = nil)
  if valid_21627060 != nil:
    section.add "X-Amz-Signature", valid_21627060
  var valid_21627061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627061 = validateParameter(valid_21627061, JString, required = false,
                                   default = nil)
  if valid_21627061 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627061
  var valid_21627062 = header.getOrDefault("X-Amz-Credential")
  valid_21627062 = validateParameter(valid_21627062, JString, required = false,
                                   default = nil)
  if valid_21627062 != nil:
    section.add "X-Amz-Credential", valid_21627062
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627064: Call_UpdateGatewayInformation_21627052;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates a gateway's metadata, which includes the gateway's name and time zone. To specify which gateway to update, use the Amazon Resource Name (ARN) of the gateway in your request.</p> <note> <p>For Gateways activated after September 2, 2015, the gateway's ARN contains the gateway ID rather than the gateway name. However, changing the name of the gateway has no effect on the gateway's ARN.</p> </note>
  ## 
  let valid = call_21627064.validator(path, query, header, formData, body, _)
  let scheme = call_21627064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627064.makeUrl(scheme.get, call_21627064.host, call_21627064.base,
                               call_21627064.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627064, uri, valid, _)

proc call*(call_21627065: Call_UpdateGatewayInformation_21627052; body: JsonNode): Recallable =
  ## updateGatewayInformation
  ## <p>Updates a gateway's metadata, which includes the gateway's name and time zone. To specify which gateway to update, use the Amazon Resource Name (ARN) of the gateway in your request.</p> <note> <p>For Gateways activated after September 2, 2015, the gateway's ARN contains the gateway ID rather than the gateway name. However, changing the name of the gateway has no effect on the gateway's ARN.</p> </note>
  ##   body: JObject (required)
  var body_21627066 = newJObject()
  if body != nil:
    body_21627066 = body
  result = call_21627065.call(nil, nil, nil, nil, body_21627066)

var updateGatewayInformation* = Call_UpdateGatewayInformation_21627052(
    name: "updateGatewayInformation", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.UpdateGatewayInformation",
    validator: validate_UpdateGatewayInformation_21627053, base: "/",
    makeUrl: url_UpdateGatewayInformation_21627054,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGatewaySoftwareNow_21627067 = ref object of OpenApiRestCall_21625437
proc url_UpdateGatewaySoftwareNow_21627069(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateGatewaySoftwareNow_21627068(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Updates the gateway virtual machine (VM) software. The request immediately triggers the software update.</p> <note> <p>When you make this request, you get a <code>200 OK</code> success response immediately. However, it might take some time for the update to complete. You can call <a>DescribeGatewayInformation</a> to verify the gateway is in the <code>STATE_RUNNING</code> state.</p> </note> <important> <p>A software update forces a system restart of your gateway. You can minimize the chance of any disruption to your applications by increasing your iSCSI Initiators' timeouts. For more information about increasing iSCSI Initiator timeouts for Windows and Linux, see <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/ConfiguringiSCSIClientInitiatorWindowsClient.html#CustomizeWindowsiSCSISettings">Customizing Your Windows iSCSI Settings</a> and <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/ConfiguringiSCSIClientInitiatorRedHatClient.html#CustomizeLinuxiSCSISettings">Customizing Your Linux iSCSI Settings</a>, respectively.</p> </important>
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
  var valid_21627070 = header.getOrDefault("X-Amz-Date")
  valid_21627070 = validateParameter(valid_21627070, JString, required = false,
                                   default = nil)
  if valid_21627070 != nil:
    section.add "X-Amz-Date", valid_21627070
  var valid_21627071 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627071 = validateParameter(valid_21627071, JString, required = false,
                                   default = nil)
  if valid_21627071 != nil:
    section.add "X-Amz-Security-Token", valid_21627071
  var valid_21627072 = header.getOrDefault("X-Amz-Target")
  valid_21627072 = validateParameter(valid_21627072, JString, required = true, default = newJString(
      "StorageGateway_20130630.UpdateGatewaySoftwareNow"))
  if valid_21627072 != nil:
    section.add "X-Amz-Target", valid_21627072
  var valid_21627073 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627073 = validateParameter(valid_21627073, JString, required = false,
                                   default = nil)
  if valid_21627073 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627073
  var valid_21627074 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627074 = validateParameter(valid_21627074, JString, required = false,
                                   default = nil)
  if valid_21627074 != nil:
    section.add "X-Amz-Algorithm", valid_21627074
  var valid_21627075 = header.getOrDefault("X-Amz-Signature")
  valid_21627075 = validateParameter(valid_21627075, JString, required = false,
                                   default = nil)
  if valid_21627075 != nil:
    section.add "X-Amz-Signature", valid_21627075
  var valid_21627076 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627076 = validateParameter(valid_21627076, JString, required = false,
                                   default = nil)
  if valid_21627076 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627076
  var valid_21627077 = header.getOrDefault("X-Amz-Credential")
  valid_21627077 = validateParameter(valid_21627077, JString, required = false,
                                   default = nil)
  if valid_21627077 != nil:
    section.add "X-Amz-Credential", valid_21627077
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627079: Call_UpdateGatewaySoftwareNow_21627067;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates the gateway virtual machine (VM) software. The request immediately triggers the software update.</p> <note> <p>When you make this request, you get a <code>200 OK</code> success response immediately. However, it might take some time for the update to complete. You can call <a>DescribeGatewayInformation</a> to verify the gateway is in the <code>STATE_RUNNING</code> state.</p> </note> <important> <p>A software update forces a system restart of your gateway. You can minimize the chance of any disruption to your applications by increasing your iSCSI Initiators' timeouts. For more information about increasing iSCSI Initiator timeouts for Windows and Linux, see <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/ConfiguringiSCSIClientInitiatorWindowsClient.html#CustomizeWindowsiSCSISettings">Customizing Your Windows iSCSI Settings</a> and <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/ConfiguringiSCSIClientInitiatorRedHatClient.html#CustomizeLinuxiSCSISettings">Customizing Your Linux iSCSI Settings</a>, respectively.</p> </important>
  ## 
  let valid = call_21627079.validator(path, query, header, formData, body, _)
  let scheme = call_21627079.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627079.makeUrl(scheme.get, call_21627079.host, call_21627079.base,
                               call_21627079.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627079, uri, valid, _)

proc call*(call_21627080: Call_UpdateGatewaySoftwareNow_21627067; body: JsonNode): Recallable =
  ## updateGatewaySoftwareNow
  ## <p>Updates the gateway virtual machine (VM) software. The request immediately triggers the software update.</p> <note> <p>When you make this request, you get a <code>200 OK</code> success response immediately. However, it might take some time for the update to complete. You can call <a>DescribeGatewayInformation</a> to verify the gateway is in the <code>STATE_RUNNING</code> state.</p> </note> <important> <p>A software update forces a system restart of your gateway. You can minimize the chance of any disruption to your applications by increasing your iSCSI Initiators' timeouts. For more information about increasing iSCSI Initiator timeouts for Windows and Linux, see <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/ConfiguringiSCSIClientInitiatorWindowsClient.html#CustomizeWindowsiSCSISettings">Customizing Your Windows iSCSI Settings</a> and <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/ConfiguringiSCSIClientInitiatorRedHatClient.html#CustomizeLinuxiSCSISettings">Customizing Your Linux iSCSI Settings</a>, respectively.</p> </important>
  ##   body: JObject (required)
  var body_21627081 = newJObject()
  if body != nil:
    body_21627081 = body
  result = call_21627080.call(nil, nil, nil, nil, body_21627081)

var updateGatewaySoftwareNow* = Call_UpdateGatewaySoftwareNow_21627067(
    name: "updateGatewaySoftwareNow", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.UpdateGatewaySoftwareNow",
    validator: validate_UpdateGatewaySoftwareNow_21627068, base: "/",
    makeUrl: url_UpdateGatewaySoftwareNow_21627069,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMaintenanceStartTime_21627082 = ref object of OpenApiRestCall_21625437
proc url_UpdateMaintenanceStartTime_21627084(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateMaintenanceStartTime_21627083(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates a gateway's weekly maintenance start time information, including day and time of the week. The maintenance time is the time in your gateway's time zone.
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
  var valid_21627085 = header.getOrDefault("X-Amz-Date")
  valid_21627085 = validateParameter(valid_21627085, JString, required = false,
                                   default = nil)
  if valid_21627085 != nil:
    section.add "X-Amz-Date", valid_21627085
  var valid_21627086 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627086 = validateParameter(valid_21627086, JString, required = false,
                                   default = nil)
  if valid_21627086 != nil:
    section.add "X-Amz-Security-Token", valid_21627086
  var valid_21627087 = header.getOrDefault("X-Amz-Target")
  valid_21627087 = validateParameter(valid_21627087, JString, required = true, default = newJString(
      "StorageGateway_20130630.UpdateMaintenanceStartTime"))
  if valid_21627087 != nil:
    section.add "X-Amz-Target", valid_21627087
  var valid_21627088 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627088 = validateParameter(valid_21627088, JString, required = false,
                                   default = nil)
  if valid_21627088 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627088
  var valid_21627089 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627089 = validateParameter(valid_21627089, JString, required = false,
                                   default = nil)
  if valid_21627089 != nil:
    section.add "X-Amz-Algorithm", valid_21627089
  var valid_21627090 = header.getOrDefault("X-Amz-Signature")
  valid_21627090 = validateParameter(valid_21627090, JString, required = false,
                                   default = nil)
  if valid_21627090 != nil:
    section.add "X-Amz-Signature", valid_21627090
  var valid_21627091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627091 = validateParameter(valid_21627091, JString, required = false,
                                   default = nil)
  if valid_21627091 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627091
  var valid_21627092 = header.getOrDefault("X-Amz-Credential")
  valid_21627092 = validateParameter(valid_21627092, JString, required = false,
                                   default = nil)
  if valid_21627092 != nil:
    section.add "X-Amz-Credential", valid_21627092
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627094: Call_UpdateMaintenanceStartTime_21627082;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a gateway's weekly maintenance start time information, including day and time of the week. The maintenance time is the time in your gateway's time zone.
  ## 
  let valid = call_21627094.validator(path, query, header, formData, body, _)
  let scheme = call_21627094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627094.makeUrl(scheme.get, call_21627094.host, call_21627094.base,
                               call_21627094.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627094, uri, valid, _)

proc call*(call_21627095: Call_UpdateMaintenanceStartTime_21627082; body: JsonNode): Recallable =
  ## updateMaintenanceStartTime
  ## Updates a gateway's weekly maintenance start time information, including day and time of the week. The maintenance time is the time in your gateway's time zone.
  ##   body: JObject (required)
  var body_21627096 = newJObject()
  if body != nil:
    body_21627096 = body
  result = call_21627095.call(nil, nil, nil, nil, body_21627096)

var updateMaintenanceStartTime* = Call_UpdateMaintenanceStartTime_21627082(
    name: "updateMaintenanceStartTime", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.UpdateMaintenanceStartTime",
    validator: validate_UpdateMaintenanceStartTime_21627083, base: "/",
    makeUrl: url_UpdateMaintenanceStartTime_21627084,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNFSFileShare_21627097 = ref object of OpenApiRestCall_21625437
proc url_UpdateNFSFileShare_21627099(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateNFSFileShare_21627098(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Updates a Network File System (NFS) file share. This operation is only supported in the file gateway type.</p> <note> <p>To leave a file share field unchanged, set the corresponding input field to null.</p> </note> <p>Updates the following file share setting:</p> <ul> <li> <p>Default storage class for your S3 bucket</p> </li> <li> <p>Metadata defaults for your S3 bucket</p> </li> <li> <p>Allowed NFS clients for your file share</p> </li> <li> <p>Squash settings</p> </li> <li> <p>Write status of your file share</p> </li> </ul> <note> <p>To leave a file share field unchanged, set the corresponding input field to null. This operation is only supported in file gateways.</p> </note>
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
  var valid_21627100 = header.getOrDefault("X-Amz-Date")
  valid_21627100 = validateParameter(valid_21627100, JString, required = false,
                                   default = nil)
  if valid_21627100 != nil:
    section.add "X-Amz-Date", valid_21627100
  var valid_21627101 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627101 = validateParameter(valid_21627101, JString, required = false,
                                   default = nil)
  if valid_21627101 != nil:
    section.add "X-Amz-Security-Token", valid_21627101
  var valid_21627102 = header.getOrDefault("X-Amz-Target")
  valid_21627102 = validateParameter(valid_21627102, JString, required = true, default = newJString(
      "StorageGateway_20130630.UpdateNFSFileShare"))
  if valid_21627102 != nil:
    section.add "X-Amz-Target", valid_21627102
  var valid_21627103 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627103 = validateParameter(valid_21627103, JString, required = false,
                                   default = nil)
  if valid_21627103 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627103
  var valid_21627104 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627104 = validateParameter(valid_21627104, JString, required = false,
                                   default = nil)
  if valid_21627104 != nil:
    section.add "X-Amz-Algorithm", valid_21627104
  var valid_21627105 = header.getOrDefault("X-Amz-Signature")
  valid_21627105 = validateParameter(valid_21627105, JString, required = false,
                                   default = nil)
  if valid_21627105 != nil:
    section.add "X-Amz-Signature", valid_21627105
  var valid_21627106 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627106 = validateParameter(valid_21627106, JString, required = false,
                                   default = nil)
  if valid_21627106 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627106
  var valid_21627107 = header.getOrDefault("X-Amz-Credential")
  valid_21627107 = validateParameter(valid_21627107, JString, required = false,
                                   default = nil)
  if valid_21627107 != nil:
    section.add "X-Amz-Credential", valid_21627107
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627109: Call_UpdateNFSFileShare_21627097; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates a Network File System (NFS) file share. This operation is only supported in the file gateway type.</p> <note> <p>To leave a file share field unchanged, set the corresponding input field to null.</p> </note> <p>Updates the following file share setting:</p> <ul> <li> <p>Default storage class for your S3 bucket</p> </li> <li> <p>Metadata defaults for your S3 bucket</p> </li> <li> <p>Allowed NFS clients for your file share</p> </li> <li> <p>Squash settings</p> </li> <li> <p>Write status of your file share</p> </li> </ul> <note> <p>To leave a file share field unchanged, set the corresponding input field to null. This operation is only supported in file gateways.</p> </note>
  ## 
  let valid = call_21627109.validator(path, query, header, formData, body, _)
  let scheme = call_21627109.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627109.makeUrl(scheme.get, call_21627109.host, call_21627109.base,
                               call_21627109.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627109, uri, valid, _)

proc call*(call_21627110: Call_UpdateNFSFileShare_21627097; body: JsonNode): Recallable =
  ## updateNFSFileShare
  ## <p>Updates a Network File System (NFS) file share. This operation is only supported in the file gateway type.</p> <note> <p>To leave a file share field unchanged, set the corresponding input field to null.</p> </note> <p>Updates the following file share setting:</p> <ul> <li> <p>Default storage class for your S3 bucket</p> </li> <li> <p>Metadata defaults for your S3 bucket</p> </li> <li> <p>Allowed NFS clients for your file share</p> </li> <li> <p>Squash settings</p> </li> <li> <p>Write status of your file share</p> </li> </ul> <note> <p>To leave a file share field unchanged, set the corresponding input field to null. This operation is only supported in file gateways.</p> </note>
  ##   body: JObject (required)
  var body_21627111 = newJObject()
  if body != nil:
    body_21627111 = body
  result = call_21627110.call(nil, nil, nil, nil, body_21627111)

var updateNFSFileShare* = Call_UpdateNFSFileShare_21627097(
    name: "updateNFSFileShare", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.UpdateNFSFileShare",
    validator: validate_UpdateNFSFileShare_21627098, base: "/",
    makeUrl: url_UpdateNFSFileShare_21627099, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSMBFileShare_21627112 = ref object of OpenApiRestCall_21625437
proc url_UpdateSMBFileShare_21627114(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateSMBFileShare_21627113(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Updates a Server Message Block (SMB) file share.</p> <note> <p>To leave a file share field unchanged, set the corresponding input field to null. This operation is only supported for file gateways.</p> </note> <important> <p>File gateways require AWS Security Token Service (AWS STS) to be activated to enable you to create a file share. Make sure that AWS STS is activated in the AWS Region you are creating your file gateway in. If AWS STS is not activated in this AWS Region, activate it. For information about how to activate AWS STS, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_enable-regions.html">Activating and Deactivating AWS STS in an AWS Region</a> in the <i>AWS Identity and Access Management User Guide.</i> </p> <p>File gateways don't support creating hard or symbolic links on a file share.</p> </important>
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
  var valid_21627115 = header.getOrDefault("X-Amz-Date")
  valid_21627115 = validateParameter(valid_21627115, JString, required = false,
                                   default = nil)
  if valid_21627115 != nil:
    section.add "X-Amz-Date", valid_21627115
  var valid_21627116 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627116 = validateParameter(valid_21627116, JString, required = false,
                                   default = nil)
  if valid_21627116 != nil:
    section.add "X-Amz-Security-Token", valid_21627116
  var valid_21627117 = header.getOrDefault("X-Amz-Target")
  valid_21627117 = validateParameter(valid_21627117, JString, required = true, default = newJString(
      "StorageGateway_20130630.UpdateSMBFileShare"))
  if valid_21627117 != nil:
    section.add "X-Amz-Target", valid_21627117
  var valid_21627118 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627118 = validateParameter(valid_21627118, JString, required = false,
                                   default = nil)
  if valid_21627118 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627118
  var valid_21627119 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627119 = validateParameter(valid_21627119, JString, required = false,
                                   default = nil)
  if valid_21627119 != nil:
    section.add "X-Amz-Algorithm", valid_21627119
  var valid_21627120 = header.getOrDefault("X-Amz-Signature")
  valid_21627120 = validateParameter(valid_21627120, JString, required = false,
                                   default = nil)
  if valid_21627120 != nil:
    section.add "X-Amz-Signature", valid_21627120
  var valid_21627121 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627121 = validateParameter(valid_21627121, JString, required = false,
                                   default = nil)
  if valid_21627121 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627121
  var valid_21627122 = header.getOrDefault("X-Amz-Credential")
  valid_21627122 = validateParameter(valid_21627122, JString, required = false,
                                   default = nil)
  if valid_21627122 != nil:
    section.add "X-Amz-Credential", valid_21627122
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627124: Call_UpdateSMBFileShare_21627112; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates a Server Message Block (SMB) file share.</p> <note> <p>To leave a file share field unchanged, set the corresponding input field to null. This operation is only supported for file gateways.</p> </note> <important> <p>File gateways require AWS Security Token Service (AWS STS) to be activated to enable you to create a file share. Make sure that AWS STS is activated in the AWS Region you are creating your file gateway in. If AWS STS is not activated in this AWS Region, activate it. For information about how to activate AWS STS, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_enable-regions.html">Activating and Deactivating AWS STS in an AWS Region</a> in the <i>AWS Identity and Access Management User Guide.</i> </p> <p>File gateways don't support creating hard or symbolic links on a file share.</p> </important>
  ## 
  let valid = call_21627124.validator(path, query, header, formData, body, _)
  let scheme = call_21627124.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627124.makeUrl(scheme.get, call_21627124.host, call_21627124.base,
                               call_21627124.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627124, uri, valid, _)

proc call*(call_21627125: Call_UpdateSMBFileShare_21627112; body: JsonNode): Recallable =
  ## updateSMBFileShare
  ## <p>Updates a Server Message Block (SMB) file share.</p> <note> <p>To leave a file share field unchanged, set the corresponding input field to null. This operation is only supported for file gateways.</p> </note> <important> <p>File gateways require AWS Security Token Service (AWS STS) to be activated to enable you to create a file share. Make sure that AWS STS is activated in the AWS Region you are creating your file gateway in. If AWS STS is not activated in this AWS Region, activate it. For information about how to activate AWS STS, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_enable-regions.html">Activating and Deactivating AWS STS in an AWS Region</a> in the <i>AWS Identity and Access Management User Guide.</i> </p> <p>File gateways don't support creating hard or symbolic links on a file share.</p> </important>
  ##   body: JObject (required)
  var body_21627126 = newJObject()
  if body != nil:
    body_21627126 = body
  result = call_21627125.call(nil, nil, nil, nil, body_21627126)

var updateSMBFileShare* = Call_UpdateSMBFileShare_21627112(
    name: "updateSMBFileShare", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.UpdateSMBFileShare",
    validator: validate_UpdateSMBFileShare_21627113, base: "/",
    makeUrl: url_UpdateSMBFileShare_21627114, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSMBSecurityStrategy_21627127 = ref object of OpenApiRestCall_21625437
proc url_UpdateSMBSecurityStrategy_21627129(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateSMBSecurityStrategy_21627128(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Updates the SMB security strategy on a file gateway. This action is only supported in file gateways.</p> <note> <p>This API is called Security level in the User Guide.</p> <p>A higher security level can affect performance of the gateway.</p> </note>
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
  var valid_21627130 = header.getOrDefault("X-Amz-Date")
  valid_21627130 = validateParameter(valid_21627130, JString, required = false,
                                   default = nil)
  if valid_21627130 != nil:
    section.add "X-Amz-Date", valid_21627130
  var valid_21627131 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627131 = validateParameter(valid_21627131, JString, required = false,
                                   default = nil)
  if valid_21627131 != nil:
    section.add "X-Amz-Security-Token", valid_21627131
  var valid_21627132 = header.getOrDefault("X-Amz-Target")
  valid_21627132 = validateParameter(valid_21627132, JString, required = true, default = newJString(
      "StorageGateway_20130630.UpdateSMBSecurityStrategy"))
  if valid_21627132 != nil:
    section.add "X-Amz-Target", valid_21627132
  var valid_21627133 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627133 = validateParameter(valid_21627133, JString, required = false,
                                   default = nil)
  if valid_21627133 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627133
  var valid_21627134 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627134 = validateParameter(valid_21627134, JString, required = false,
                                   default = nil)
  if valid_21627134 != nil:
    section.add "X-Amz-Algorithm", valid_21627134
  var valid_21627135 = header.getOrDefault("X-Amz-Signature")
  valid_21627135 = validateParameter(valid_21627135, JString, required = false,
                                   default = nil)
  if valid_21627135 != nil:
    section.add "X-Amz-Signature", valid_21627135
  var valid_21627136 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627136 = validateParameter(valid_21627136, JString, required = false,
                                   default = nil)
  if valid_21627136 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627136
  var valid_21627137 = header.getOrDefault("X-Amz-Credential")
  valid_21627137 = validateParameter(valid_21627137, JString, required = false,
                                   default = nil)
  if valid_21627137 != nil:
    section.add "X-Amz-Credential", valid_21627137
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627139: Call_UpdateSMBSecurityStrategy_21627127;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates the SMB security strategy on a file gateway. This action is only supported in file gateways.</p> <note> <p>This API is called Security level in the User Guide.</p> <p>A higher security level can affect performance of the gateway.</p> </note>
  ## 
  let valid = call_21627139.validator(path, query, header, formData, body, _)
  let scheme = call_21627139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627139.makeUrl(scheme.get, call_21627139.host, call_21627139.base,
                               call_21627139.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627139, uri, valid, _)

proc call*(call_21627140: Call_UpdateSMBSecurityStrategy_21627127; body: JsonNode): Recallable =
  ## updateSMBSecurityStrategy
  ## <p>Updates the SMB security strategy on a file gateway. This action is only supported in file gateways.</p> <note> <p>This API is called Security level in the User Guide.</p> <p>A higher security level can affect performance of the gateway.</p> </note>
  ##   body: JObject (required)
  var body_21627141 = newJObject()
  if body != nil:
    body_21627141 = body
  result = call_21627140.call(nil, nil, nil, nil, body_21627141)

var updateSMBSecurityStrategy* = Call_UpdateSMBSecurityStrategy_21627127(
    name: "updateSMBSecurityStrategy", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.UpdateSMBSecurityStrategy",
    validator: validate_UpdateSMBSecurityStrategy_21627128, base: "/",
    makeUrl: url_UpdateSMBSecurityStrategy_21627129,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSnapshotSchedule_21627142 = ref object of OpenApiRestCall_21625437
proc url_UpdateSnapshotSchedule_21627144(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateSnapshotSchedule_21627143(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Updates a snapshot schedule configured for a gateway volume. This operation is only supported in the cached volume and stored volume gateway types.</p> <p>The default snapshot schedule for volume is once every 24 hours, starting at the creation time of the volume. You can use this API to change the snapshot schedule configured for the volume.</p> <p>In the request you must identify the gateway volume whose snapshot schedule you want to update, and the schedule information, including when you want the snapshot to begin on a day and the frequency (in hours) of snapshots.</p>
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
  var valid_21627145 = header.getOrDefault("X-Amz-Date")
  valid_21627145 = validateParameter(valid_21627145, JString, required = false,
                                   default = nil)
  if valid_21627145 != nil:
    section.add "X-Amz-Date", valid_21627145
  var valid_21627146 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627146 = validateParameter(valid_21627146, JString, required = false,
                                   default = nil)
  if valid_21627146 != nil:
    section.add "X-Amz-Security-Token", valid_21627146
  var valid_21627147 = header.getOrDefault("X-Amz-Target")
  valid_21627147 = validateParameter(valid_21627147, JString, required = true, default = newJString(
      "StorageGateway_20130630.UpdateSnapshotSchedule"))
  if valid_21627147 != nil:
    section.add "X-Amz-Target", valid_21627147
  var valid_21627148 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627148 = validateParameter(valid_21627148, JString, required = false,
                                   default = nil)
  if valid_21627148 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627148
  var valid_21627149 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627149 = validateParameter(valid_21627149, JString, required = false,
                                   default = nil)
  if valid_21627149 != nil:
    section.add "X-Amz-Algorithm", valid_21627149
  var valid_21627150 = header.getOrDefault("X-Amz-Signature")
  valid_21627150 = validateParameter(valid_21627150, JString, required = false,
                                   default = nil)
  if valid_21627150 != nil:
    section.add "X-Amz-Signature", valid_21627150
  var valid_21627151 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627151 = validateParameter(valid_21627151, JString, required = false,
                                   default = nil)
  if valid_21627151 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627151
  var valid_21627152 = header.getOrDefault("X-Amz-Credential")
  valid_21627152 = validateParameter(valid_21627152, JString, required = false,
                                   default = nil)
  if valid_21627152 != nil:
    section.add "X-Amz-Credential", valid_21627152
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627154: Call_UpdateSnapshotSchedule_21627142;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates a snapshot schedule configured for a gateway volume. This operation is only supported in the cached volume and stored volume gateway types.</p> <p>The default snapshot schedule for volume is once every 24 hours, starting at the creation time of the volume. You can use this API to change the snapshot schedule configured for the volume.</p> <p>In the request you must identify the gateway volume whose snapshot schedule you want to update, and the schedule information, including when you want the snapshot to begin on a day and the frequency (in hours) of snapshots.</p>
  ## 
  let valid = call_21627154.validator(path, query, header, formData, body, _)
  let scheme = call_21627154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627154.makeUrl(scheme.get, call_21627154.host, call_21627154.base,
                               call_21627154.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627154, uri, valid, _)

proc call*(call_21627155: Call_UpdateSnapshotSchedule_21627142; body: JsonNode): Recallable =
  ## updateSnapshotSchedule
  ## <p>Updates a snapshot schedule configured for a gateway volume. This operation is only supported in the cached volume and stored volume gateway types.</p> <p>The default snapshot schedule for volume is once every 24 hours, starting at the creation time of the volume. You can use this API to change the snapshot schedule configured for the volume.</p> <p>In the request you must identify the gateway volume whose snapshot schedule you want to update, and the schedule information, including when you want the snapshot to begin on a day and the frequency (in hours) of snapshots.</p>
  ##   body: JObject (required)
  var body_21627156 = newJObject()
  if body != nil:
    body_21627156 = body
  result = call_21627155.call(nil, nil, nil, nil, body_21627156)

var updateSnapshotSchedule* = Call_UpdateSnapshotSchedule_21627142(
    name: "updateSnapshotSchedule", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.UpdateSnapshotSchedule",
    validator: validate_UpdateSnapshotSchedule_21627143, base: "/",
    makeUrl: url_UpdateSnapshotSchedule_21627144,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVTLDeviceType_21627157 = ref object of OpenApiRestCall_21625437
proc url_UpdateVTLDeviceType_21627159(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateVTLDeviceType_21627158(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates the type of medium changer in a tape gateway. When you activate a tape gateway, you select a medium changer type for the tape gateway. This operation enables you to select a different type of medium changer after a tape gateway is activated. This operation is only supported in the tape gateway type.
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
  var valid_21627160 = header.getOrDefault("X-Amz-Date")
  valid_21627160 = validateParameter(valid_21627160, JString, required = false,
                                   default = nil)
  if valid_21627160 != nil:
    section.add "X-Amz-Date", valid_21627160
  var valid_21627161 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627161 = validateParameter(valid_21627161, JString, required = false,
                                   default = nil)
  if valid_21627161 != nil:
    section.add "X-Amz-Security-Token", valid_21627161
  var valid_21627162 = header.getOrDefault("X-Amz-Target")
  valid_21627162 = validateParameter(valid_21627162, JString, required = true, default = newJString(
      "StorageGateway_20130630.UpdateVTLDeviceType"))
  if valid_21627162 != nil:
    section.add "X-Amz-Target", valid_21627162
  var valid_21627163 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627163 = validateParameter(valid_21627163, JString, required = false,
                                   default = nil)
  if valid_21627163 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627163
  var valid_21627164 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627164 = validateParameter(valid_21627164, JString, required = false,
                                   default = nil)
  if valid_21627164 != nil:
    section.add "X-Amz-Algorithm", valid_21627164
  var valid_21627165 = header.getOrDefault("X-Amz-Signature")
  valid_21627165 = validateParameter(valid_21627165, JString, required = false,
                                   default = nil)
  if valid_21627165 != nil:
    section.add "X-Amz-Signature", valid_21627165
  var valid_21627166 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627166 = validateParameter(valid_21627166, JString, required = false,
                                   default = nil)
  if valid_21627166 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627166
  var valid_21627167 = header.getOrDefault("X-Amz-Credential")
  valid_21627167 = validateParameter(valid_21627167, JString, required = false,
                                   default = nil)
  if valid_21627167 != nil:
    section.add "X-Amz-Credential", valid_21627167
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627169: Call_UpdateVTLDeviceType_21627157; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the type of medium changer in a tape gateway. When you activate a tape gateway, you select a medium changer type for the tape gateway. This operation enables you to select a different type of medium changer after a tape gateway is activated. This operation is only supported in the tape gateway type.
  ## 
  let valid = call_21627169.validator(path, query, header, formData, body, _)
  let scheme = call_21627169.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627169.makeUrl(scheme.get, call_21627169.host, call_21627169.base,
                               call_21627169.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627169, uri, valid, _)

proc call*(call_21627170: Call_UpdateVTLDeviceType_21627157; body: JsonNode): Recallable =
  ## updateVTLDeviceType
  ## Updates the type of medium changer in a tape gateway. When you activate a tape gateway, you select a medium changer type for the tape gateway. This operation enables you to select a different type of medium changer after a tape gateway is activated. This operation is only supported in the tape gateway type.
  ##   body: JObject (required)
  var body_21627171 = newJObject()
  if body != nil:
    body_21627171 = body
  result = call_21627170.call(nil, nil, nil, nil, body_21627171)

var updateVTLDeviceType* = Call_UpdateVTLDeviceType_21627157(
    name: "updateVTLDeviceType", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.UpdateVTLDeviceType",
    validator: validate_UpdateVTLDeviceType_21627158, base: "/",
    makeUrl: url_UpdateVTLDeviceType_21627159,
    schemes: {Scheme.Https, Scheme.Http})
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
type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body = ""): Recallable {.
    base.} =
  ## the hook is a terrible earworm
  var
    headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
    text = body
  if text.len == 0 and "body" in input:
    text = input.getOrDefault("body").getStr
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  else:
    headers["content-md5"] = base64.encode text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

when not defined(ssl):
  {.error: "use ssl".}