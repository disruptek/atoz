
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_599369 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599369](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599369): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_ActivateGateway_599706 = ref object of OpenApiRestCall_599369
proc url_ActivateGateway_599708(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ActivateGateway_599707(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
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
  var valid_599820 = header.getOrDefault("X-Amz-Date")
  valid_599820 = validateParameter(valid_599820, JString, required = false,
                                 default = nil)
  if valid_599820 != nil:
    section.add "X-Amz-Date", valid_599820
  var valid_599821 = header.getOrDefault("X-Amz-Security-Token")
  valid_599821 = validateParameter(valid_599821, JString, required = false,
                                 default = nil)
  if valid_599821 != nil:
    section.add "X-Amz-Security-Token", valid_599821
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599835 = header.getOrDefault("X-Amz-Target")
  valid_599835 = validateParameter(valid_599835, JString, required = true, default = newJString(
      "StorageGateway_20130630.ActivateGateway"))
  if valid_599835 != nil:
    section.add "X-Amz-Target", valid_599835
  var valid_599836 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599836 = validateParameter(valid_599836, JString, required = false,
                                 default = nil)
  if valid_599836 != nil:
    section.add "X-Amz-Content-Sha256", valid_599836
  var valid_599837 = header.getOrDefault("X-Amz-Algorithm")
  valid_599837 = validateParameter(valid_599837, JString, required = false,
                                 default = nil)
  if valid_599837 != nil:
    section.add "X-Amz-Algorithm", valid_599837
  var valid_599838 = header.getOrDefault("X-Amz-Signature")
  valid_599838 = validateParameter(valid_599838, JString, required = false,
                                 default = nil)
  if valid_599838 != nil:
    section.add "X-Amz-Signature", valid_599838
  var valid_599839 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599839 = validateParameter(valid_599839, JString, required = false,
                                 default = nil)
  if valid_599839 != nil:
    section.add "X-Amz-SignedHeaders", valid_599839
  var valid_599840 = header.getOrDefault("X-Amz-Credential")
  valid_599840 = validateParameter(valid_599840, JString, required = false,
                                 default = nil)
  if valid_599840 != nil:
    section.add "X-Amz-Credential", valid_599840
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599864: Call_ActivateGateway_599706; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Activates the gateway you previously deployed on your host. In the activation process, you specify information such as the AWS Region that you want to use for storing snapshots or tapes, the time zone for scheduled snapshots the gateway snapshot schedule window, an activation key, and a name for your gateway. The activation process also associates your gateway with your account; for more information, see <a>UpdateGatewayInformation</a>.</p> <note> <p>You must turn on the gateway VM before you can activate your gateway.</p> </note>
  ## 
  let valid = call_599864.validator(path, query, header, formData, body)
  let scheme = call_599864.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599864.url(scheme.get, call_599864.host, call_599864.base,
                         call_599864.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599864, url, valid)

proc call*(call_599935: Call_ActivateGateway_599706; body: JsonNode): Recallable =
  ## activateGateway
  ## <p>Activates the gateway you previously deployed on your host. In the activation process, you specify information such as the AWS Region that you want to use for storing snapshots or tapes, the time zone for scheduled snapshots the gateway snapshot schedule window, an activation key, and a name for your gateway. The activation process also associates your gateway with your account; for more information, see <a>UpdateGatewayInformation</a>.</p> <note> <p>You must turn on the gateway VM before you can activate your gateway.</p> </note>
  ##   body: JObject (required)
  var body_599936 = newJObject()
  if body != nil:
    body_599936 = body
  result = call_599935.call(nil, nil, nil, nil, body_599936)

var activateGateway* = Call_ActivateGateway_599706(name: "activateGateway",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.ActivateGateway",
    validator: validate_ActivateGateway_599707, base: "/", url: url_ActivateGateway_599708,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AddCache_599975 = ref object of OpenApiRestCall_599369
proc url_AddCache_599977(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AddCache_599976(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_599978 = header.getOrDefault("X-Amz-Date")
  valid_599978 = validateParameter(valid_599978, JString, required = false,
                                 default = nil)
  if valid_599978 != nil:
    section.add "X-Amz-Date", valid_599978
  var valid_599979 = header.getOrDefault("X-Amz-Security-Token")
  valid_599979 = validateParameter(valid_599979, JString, required = false,
                                 default = nil)
  if valid_599979 != nil:
    section.add "X-Amz-Security-Token", valid_599979
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599980 = header.getOrDefault("X-Amz-Target")
  valid_599980 = validateParameter(valid_599980, JString, required = true, default = newJString(
      "StorageGateway_20130630.AddCache"))
  if valid_599980 != nil:
    section.add "X-Amz-Target", valid_599980
  var valid_599981 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599981 = validateParameter(valid_599981, JString, required = false,
                                 default = nil)
  if valid_599981 != nil:
    section.add "X-Amz-Content-Sha256", valid_599981
  var valid_599982 = header.getOrDefault("X-Amz-Algorithm")
  valid_599982 = validateParameter(valid_599982, JString, required = false,
                                 default = nil)
  if valid_599982 != nil:
    section.add "X-Amz-Algorithm", valid_599982
  var valid_599983 = header.getOrDefault("X-Amz-Signature")
  valid_599983 = validateParameter(valid_599983, JString, required = false,
                                 default = nil)
  if valid_599983 != nil:
    section.add "X-Amz-Signature", valid_599983
  var valid_599984 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599984 = validateParameter(valid_599984, JString, required = false,
                                 default = nil)
  if valid_599984 != nil:
    section.add "X-Amz-SignedHeaders", valid_599984
  var valid_599985 = header.getOrDefault("X-Amz-Credential")
  valid_599985 = validateParameter(valid_599985, JString, required = false,
                                 default = nil)
  if valid_599985 != nil:
    section.add "X-Amz-Credential", valid_599985
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599987: Call_AddCache_599975; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Configures one or more gateway local disks as cache for a gateway. This operation is only supported in the cached volume, tape and file gateway type (see <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/StorageGatewayConcepts.html">Storage Gateway Concepts</a>).</p> <p>In the request, you specify the gateway Amazon Resource Name (ARN) to which you want to add cache, and one or more disk IDs that you want to configure as cache.</p>
  ## 
  let valid = call_599987.validator(path, query, header, formData, body)
  let scheme = call_599987.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599987.url(scheme.get, call_599987.host, call_599987.base,
                         call_599987.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599987, url, valid)

proc call*(call_599988: Call_AddCache_599975; body: JsonNode): Recallable =
  ## addCache
  ## <p>Configures one or more gateway local disks as cache for a gateway. This operation is only supported in the cached volume, tape and file gateway type (see <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/StorageGatewayConcepts.html">Storage Gateway Concepts</a>).</p> <p>In the request, you specify the gateway Amazon Resource Name (ARN) to which you want to add cache, and one or more disk IDs that you want to configure as cache.</p>
  ##   body: JObject (required)
  var body_599989 = newJObject()
  if body != nil:
    body_599989 = body
  result = call_599988.call(nil, nil, nil, nil, body_599989)

var addCache* = Call_AddCache_599975(name: "addCache", meth: HttpMethod.HttpPost,
                                  host: "storagegateway.amazonaws.com", route: "/#X-Amz-Target=StorageGateway_20130630.AddCache",
                                  validator: validate_AddCache_599976, base: "/",
                                  url: url_AddCache_599977,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_AddTagsToResource_599990 = ref object of OpenApiRestCall_599369
proc url_AddTagsToResource_599992(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AddTagsToResource_599991(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  var valid_599993 = header.getOrDefault("X-Amz-Date")
  valid_599993 = validateParameter(valid_599993, JString, required = false,
                                 default = nil)
  if valid_599993 != nil:
    section.add "X-Amz-Date", valid_599993
  var valid_599994 = header.getOrDefault("X-Amz-Security-Token")
  valid_599994 = validateParameter(valid_599994, JString, required = false,
                                 default = nil)
  if valid_599994 != nil:
    section.add "X-Amz-Security-Token", valid_599994
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599995 = header.getOrDefault("X-Amz-Target")
  valid_599995 = validateParameter(valid_599995, JString, required = true, default = newJString(
      "StorageGateway_20130630.AddTagsToResource"))
  if valid_599995 != nil:
    section.add "X-Amz-Target", valid_599995
  var valid_599996 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599996 = validateParameter(valid_599996, JString, required = false,
                                 default = nil)
  if valid_599996 != nil:
    section.add "X-Amz-Content-Sha256", valid_599996
  var valid_599997 = header.getOrDefault("X-Amz-Algorithm")
  valid_599997 = validateParameter(valid_599997, JString, required = false,
                                 default = nil)
  if valid_599997 != nil:
    section.add "X-Amz-Algorithm", valid_599997
  var valid_599998 = header.getOrDefault("X-Amz-Signature")
  valid_599998 = validateParameter(valid_599998, JString, required = false,
                                 default = nil)
  if valid_599998 != nil:
    section.add "X-Amz-Signature", valid_599998
  var valid_599999 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599999 = validateParameter(valid_599999, JString, required = false,
                                 default = nil)
  if valid_599999 != nil:
    section.add "X-Amz-SignedHeaders", valid_599999
  var valid_600000 = header.getOrDefault("X-Amz-Credential")
  valid_600000 = validateParameter(valid_600000, JString, required = false,
                                 default = nil)
  if valid_600000 != nil:
    section.add "X-Amz-Credential", valid_600000
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600002: Call_AddTagsToResource_599990; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds one or more tags to the specified resource. You use tags to add metadata to resources, which you can use to categorize these resources. For example, you can categorize resources by purpose, owner, environment, or team. Each tag consists of a key and a value, which you define. You can add tags to the following AWS Storage Gateway resources:</p> <ul> <li> <p>Storage gateways of all types</p> </li> <li> <p>Storage volumes</p> </li> <li> <p>Virtual tapes</p> </li> <li> <p>NFS and SMB file shares</p> </li> </ul> <p>You can create a maximum of 50 tags for each resource. Virtual tapes and storage volumes that are recovered to a new gateway maintain their tags.</p>
  ## 
  let valid = call_600002.validator(path, query, header, formData, body)
  let scheme = call_600002.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600002.url(scheme.get, call_600002.host, call_600002.base,
                         call_600002.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600002, url, valid)

proc call*(call_600003: Call_AddTagsToResource_599990; body: JsonNode): Recallable =
  ## addTagsToResource
  ## <p>Adds one or more tags to the specified resource. You use tags to add metadata to resources, which you can use to categorize these resources. For example, you can categorize resources by purpose, owner, environment, or team. Each tag consists of a key and a value, which you define. You can add tags to the following AWS Storage Gateway resources:</p> <ul> <li> <p>Storage gateways of all types</p> </li> <li> <p>Storage volumes</p> </li> <li> <p>Virtual tapes</p> </li> <li> <p>NFS and SMB file shares</p> </li> </ul> <p>You can create a maximum of 50 tags for each resource. Virtual tapes and storage volumes that are recovered to a new gateway maintain their tags.</p>
  ##   body: JObject (required)
  var body_600004 = newJObject()
  if body != nil:
    body_600004 = body
  result = call_600003.call(nil, nil, nil, nil, body_600004)

var addTagsToResource* = Call_AddTagsToResource_599990(name: "addTagsToResource",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.AddTagsToResource",
    validator: validate_AddTagsToResource_599991, base: "/",
    url: url_AddTagsToResource_599992, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AddUploadBuffer_600005 = ref object of OpenApiRestCall_599369
proc url_AddUploadBuffer_600007(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AddUploadBuffer_600006(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
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
  var valid_600008 = header.getOrDefault("X-Amz-Date")
  valid_600008 = validateParameter(valid_600008, JString, required = false,
                                 default = nil)
  if valid_600008 != nil:
    section.add "X-Amz-Date", valid_600008
  var valid_600009 = header.getOrDefault("X-Amz-Security-Token")
  valid_600009 = validateParameter(valid_600009, JString, required = false,
                                 default = nil)
  if valid_600009 != nil:
    section.add "X-Amz-Security-Token", valid_600009
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600010 = header.getOrDefault("X-Amz-Target")
  valid_600010 = validateParameter(valid_600010, JString, required = true, default = newJString(
      "StorageGateway_20130630.AddUploadBuffer"))
  if valid_600010 != nil:
    section.add "X-Amz-Target", valid_600010
  var valid_600011 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600011 = validateParameter(valid_600011, JString, required = false,
                                 default = nil)
  if valid_600011 != nil:
    section.add "X-Amz-Content-Sha256", valid_600011
  var valid_600012 = header.getOrDefault("X-Amz-Algorithm")
  valid_600012 = validateParameter(valid_600012, JString, required = false,
                                 default = nil)
  if valid_600012 != nil:
    section.add "X-Amz-Algorithm", valid_600012
  var valid_600013 = header.getOrDefault("X-Amz-Signature")
  valid_600013 = validateParameter(valid_600013, JString, required = false,
                                 default = nil)
  if valid_600013 != nil:
    section.add "X-Amz-Signature", valid_600013
  var valid_600014 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600014 = validateParameter(valid_600014, JString, required = false,
                                 default = nil)
  if valid_600014 != nil:
    section.add "X-Amz-SignedHeaders", valid_600014
  var valid_600015 = header.getOrDefault("X-Amz-Credential")
  valid_600015 = validateParameter(valid_600015, JString, required = false,
                                 default = nil)
  if valid_600015 != nil:
    section.add "X-Amz-Credential", valid_600015
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600017: Call_AddUploadBuffer_600005; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Configures one or more gateway local disks as upload buffer for a specified gateway. This operation is supported for the stored volume, cached volume and tape gateway types.</p> <p>In the request, you specify the gateway Amazon Resource Name (ARN) to which you want to add upload buffer, and one or more disk IDs that you want to configure as upload buffer.</p>
  ## 
  let valid = call_600017.validator(path, query, header, formData, body)
  let scheme = call_600017.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600017.url(scheme.get, call_600017.host, call_600017.base,
                         call_600017.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600017, url, valid)

proc call*(call_600018: Call_AddUploadBuffer_600005; body: JsonNode): Recallable =
  ## addUploadBuffer
  ## <p>Configures one or more gateway local disks as upload buffer for a specified gateway. This operation is supported for the stored volume, cached volume and tape gateway types.</p> <p>In the request, you specify the gateway Amazon Resource Name (ARN) to which you want to add upload buffer, and one or more disk IDs that you want to configure as upload buffer.</p>
  ##   body: JObject (required)
  var body_600019 = newJObject()
  if body != nil:
    body_600019 = body
  result = call_600018.call(nil, nil, nil, nil, body_600019)

var addUploadBuffer* = Call_AddUploadBuffer_600005(name: "addUploadBuffer",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.AddUploadBuffer",
    validator: validate_AddUploadBuffer_600006, base: "/", url: url_AddUploadBuffer_600007,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AddWorkingStorage_600020 = ref object of OpenApiRestCall_599369
proc url_AddWorkingStorage_600022(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AddWorkingStorage_600021(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  var valid_600023 = header.getOrDefault("X-Amz-Date")
  valid_600023 = validateParameter(valid_600023, JString, required = false,
                                 default = nil)
  if valid_600023 != nil:
    section.add "X-Amz-Date", valid_600023
  var valid_600024 = header.getOrDefault("X-Amz-Security-Token")
  valid_600024 = validateParameter(valid_600024, JString, required = false,
                                 default = nil)
  if valid_600024 != nil:
    section.add "X-Amz-Security-Token", valid_600024
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600025 = header.getOrDefault("X-Amz-Target")
  valid_600025 = validateParameter(valid_600025, JString, required = true, default = newJString(
      "StorageGateway_20130630.AddWorkingStorage"))
  if valid_600025 != nil:
    section.add "X-Amz-Target", valid_600025
  var valid_600026 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600026 = validateParameter(valid_600026, JString, required = false,
                                 default = nil)
  if valid_600026 != nil:
    section.add "X-Amz-Content-Sha256", valid_600026
  var valid_600027 = header.getOrDefault("X-Amz-Algorithm")
  valid_600027 = validateParameter(valid_600027, JString, required = false,
                                 default = nil)
  if valid_600027 != nil:
    section.add "X-Amz-Algorithm", valid_600027
  var valid_600028 = header.getOrDefault("X-Amz-Signature")
  valid_600028 = validateParameter(valid_600028, JString, required = false,
                                 default = nil)
  if valid_600028 != nil:
    section.add "X-Amz-Signature", valid_600028
  var valid_600029 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600029 = validateParameter(valid_600029, JString, required = false,
                                 default = nil)
  if valid_600029 != nil:
    section.add "X-Amz-SignedHeaders", valid_600029
  var valid_600030 = header.getOrDefault("X-Amz-Credential")
  valid_600030 = validateParameter(valid_600030, JString, required = false,
                                 default = nil)
  if valid_600030 != nil:
    section.add "X-Amz-Credential", valid_600030
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600032: Call_AddWorkingStorage_600020; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Configures one or more gateway local disks as working storage for a gateway. This operation is only supported in the stored volume gateway type. This operation is deprecated in cached volume API version 20120630. Use <a>AddUploadBuffer</a> instead.</p> <note> <p>Working storage is also referred to as upload buffer. You can also use the <a>AddUploadBuffer</a> operation to add upload buffer to a stored volume gateway.</p> </note> <p>In the request, you specify the gateway Amazon Resource Name (ARN) to which you want to add working storage, and one or more disk IDs that you want to configure as working storage.</p>
  ## 
  let valid = call_600032.validator(path, query, header, formData, body)
  let scheme = call_600032.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600032.url(scheme.get, call_600032.host, call_600032.base,
                         call_600032.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600032, url, valid)

proc call*(call_600033: Call_AddWorkingStorage_600020; body: JsonNode): Recallable =
  ## addWorkingStorage
  ## <p>Configures one or more gateway local disks as working storage for a gateway. This operation is only supported in the stored volume gateway type. This operation is deprecated in cached volume API version 20120630. Use <a>AddUploadBuffer</a> instead.</p> <note> <p>Working storage is also referred to as upload buffer. You can also use the <a>AddUploadBuffer</a> operation to add upload buffer to a stored volume gateway.</p> </note> <p>In the request, you specify the gateway Amazon Resource Name (ARN) to which you want to add working storage, and one or more disk IDs that you want to configure as working storage.</p>
  ##   body: JObject (required)
  var body_600034 = newJObject()
  if body != nil:
    body_600034 = body
  result = call_600033.call(nil, nil, nil, nil, body_600034)

var addWorkingStorage* = Call_AddWorkingStorage_600020(name: "addWorkingStorage",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.AddWorkingStorage",
    validator: validate_AddWorkingStorage_600021, base: "/",
    url: url_AddWorkingStorage_600022, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssignTapePool_600035 = ref object of OpenApiRestCall_599369
proc url_AssignTapePool_600037(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssignTapePool_600036(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
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
  var valid_600038 = header.getOrDefault("X-Amz-Date")
  valid_600038 = validateParameter(valid_600038, JString, required = false,
                                 default = nil)
  if valid_600038 != nil:
    section.add "X-Amz-Date", valid_600038
  var valid_600039 = header.getOrDefault("X-Amz-Security-Token")
  valid_600039 = validateParameter(valid_600039, JString, required = false,
                                 default = nil)
  if valid_600039 != nil:
    section.add "X-Amz-Security-Token", valid_600039
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600040 = header.getOrDefault("X-Amz-Target")
  valid_600040 = validateParameter(valid_600040, JString, required = true, default = newJString(
      "StorageGateway_20130630.AssignTapePool"))
  if valid_600040 != nil:
    section.add "X-Amz-Target", valid_600040
  var valid_600041 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600041 = validateParameter(valid_600041, JString, required = false,
                                 default = nil)
  if valid_600041 != nil:
    section.add "X-Amz-Content-Sha256", valid_600041
  var valid_600042 = header.getOrDefault("X-Amz-Algorithm")
  valid_600042 = validateParameter(valid_600042, JString, required = false,
                                 default = nil)
  if valid_600042 != nil:
    section.add "X-Amz-Algorithm", valid_600042
  var valid_600043 = header.getOrDefault("X-Amz-Signature")
  valid_600043 = validateParameter(valid_600043, JString, required = false,
                                 default = nil)
  if valid_600043 != nil:
    section.add "X-Amz-Signature", valid_600043
  var valid_600044 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600044 = validateParameter(valid_600044, JString, required = false,
                                 default = nil)
  if valid_600044 != nil:
    section.add "X-Amz-SignedHeaders", valid_600044
  var valid_600045 = header.getOrDefault("X-Amz-Credential")
  valid_600045 = validateParameter(valid_600045, JString, required = false,
                                 default = nil)
  if valid_600045 != nil:
    section.add "X-Amz-Credential", valid_600045
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600047: Call_AssignTapePool_600035; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Assigns a tape to a tape pool for archiving. The tape assigned to a pool is archived in the S3 storage class that is associated with the pool. When you use your backup application to eject the tape, the tape is archived directly into the S3 storage class (Glacier or Deep Archive) that corresponds to the pool.</p> <p>Valid values: "GLACIER", "DEEP_ARCHIVE"</p>
  ## 
  let valid = call_600047.validator(path, query, header, formData, body)
  let scheme = call_600047.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600047.url(scheme.get, call_600047.host, call_600047.base,
                         call_600047.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600047, url, valid)

proc call*(call_600048: Call_AssignTapePool_600035; body: JsonNode): Recallable =
  ## assignTapePool
  ## <p>Assigns a tape to a tape pool for archiving. The tape assigned to a pool is archived in the S3 storage class that is associated with the pool. When you use your backup application to eject the tape, the tape is archived directly into the S3 storage class (Glacier or Deep Archive) that corresponds to the pool.</p> <p>Valid values: "GLACIER", "DEEP_ARCHIVE"</p>
  ##   body: JObject (required)
  var body_600049 = newJObject()
  if body != nil:
    body_600049 = body
  result = call_600048.call(nil, nil, nil, nil, body_600049)

var assignTapePool* = Call_AssignTapePool_600035(name: "assignTapePool",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.AssignTapePool",
    validator: validate_AssignTapePool_600036, base: "/", url: url_AssignTapePool_600037,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachVolume_600050 = ref object of OpenApiRestCall_599369
proc url_AttachVolume_600052(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AttachVolume_600051(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600053 = header.getOrDefault("X-Amz-Date")
  valid_600053 = validateParameter(valid_600053, JString, required = false,
                                 default = nil)
  if valid_600053 != nil:
    section.add "X-Amz-Date", valid_600053
  var valid_600054 = header.getOrDefault("X-Amz-Security-Token")
  valid_600054 = validateParameter(valid_600054, JString, required = false,
                                 default = nil)
  if valid_600054 != nil:
    section.add "X-Amz-Security-Token", valid_600054
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600055 = header.getOrDefault("X-Amz-Target")
  valid_600055 = validateParameter(valid_600055, JString, required = true, default = newJString(
      "StorageGateway_20130630.AttachVolume"))
  if valid_600055 != nil:
    section.add "X-Amz-Target", valid_600055
  var valid_600056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600056 = validateParameter(valid_600056, JString, required = false,
                                 default = nil)
  if valid_600056 != nil:
    section.add "X-Amz-Content-Sha256", valid_600056
  var valid_600057 = header.getOrDefault("X-Amz-Algorithm")
  valid_600057 = validateParameter(valid_600057, JString, required = false,
                                 default = nil)
  if valid_600057 != nil:
    section.add "X-Amz-Algorithm", valid_600057
  var valid_600058 = header.getOrDefault("X-Amz-Signature")
  valid_600058 = validateParameter(valid_600058, JString, required = false,
                                 default = nil)
  if valid_600058 != nil:
    section.add "X-Amz-Signature", valid_600058
  var valid_600059 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600059 = validateParameter(valid_600059, JString, required = false,
                                 default = nil)
  if valid_600059 != nil:
    section.add "X-Amz-SignedHeaders", valid_600059
  var valid_600060 = header.getOrDefault("X-Amz-Credential")
  valid_600060 = validateParameter(valid_600060, JString, required = false,
                                 default = nil)
  if valid_600060 != nil:
    section.add "X-Amz-Credential", valid_600060
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600062: Call_AttachVolume_600050; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Connects a volume to an iSCSI connection and then attaches the volume to the specified gateway. Detaching and attaching a volume enables you to recover your data from one gateway to a different gateway without creating a snapshot. It also makes it easier to move your volumes from an on-premises gateway to a gateway hosted on an Amazon EC2 instance.
  ## 
  let valid = call_600062.validator(path, query, header, formData, body)
  let scheme = call_600062.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600062.url(scheme.get, call_600062.host, call_600062.base,
                         call_600062.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600062, url, valid)

proc call*(call_600063: Call_AttachVolume_600050; body: JsonNode): Recallable =
  ## attachVolume
  ## Connects a volume to an iSCSI connection and then attaches the volume to the specified gateway. Detaching and attaching a volume enables you to recover your data from one gateway to a different gateway without creating a snapshot. It also makes it easier to move your volumes from an on-premises gateway to a gateway hosted on an Amazon EC2 instance.
  ##   body: JObject (required)
  var body_600064 = newJObject()
  if body != nil:
    body_600064 = body
  result = call_600063.call(nil, nil, nil, nil, body_600064)

var attachVolume* = Call_AttachVolume_600050(name: "attachVolume",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.AttachVolume",
    validator: validate_AttachVolume_600051, base: "/", url: url_AttachVolume_600052,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelArchival_600065 = ref object of OpenApiRestCall_599369
proc url_CancelArchival_600067(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CancelArchival_600066(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
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
  var valid_600068 = header.getOrDefault("X-Amz-Date")
  valid_600068 = validateParameter(valid_600068, JString, required = false,
                                 default = nil)
  if valid_600068 != nil:
    section.add "X-Amz-Date", valid_600068
  var valid_600069 = header.getOrDefault("X-Amz-Security-Token")
  valid_600069 = validateParameter(valid_600069, JString, required = false,
                                 default = nil)
  if valid_600069 != nil:
    section.add "X-Amz-Security-Token", valid_600069
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600070 = header.getOrDefault("X-Amz-Target")
  valid_600070 = validateParameter(valid_600070, JString, required = true, default = newJString(
      "StorageGateway_20130630.CancelArchival"))
  if valid_600070 != nil:
    section.add "X-Amz-Target", valid_600070
  var valid_600071 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600071 = validateParameter(valid_600071, JString, required = false,
                                 default = nil)
  if valid_600071 != nil:
    section.add "X-Amz-Content-Sha256", valid_600071
  var valid_600072 = header.getOrDefault("X-Amz-Algorithm")
  valid_600072 = validateParameter(valid_600072, JString, required = false,
                                 default = nil)
  if valid_600072 != nil:
    section.add "X-Amz-Algorithm", valid_600072
  var valid_600073 = header.getOrDefault("X-Amz-Signature")
  valid_600073 = validateParameter(valid_600073, JString, required = false,
                                 default = nil)
  if valid_600073 != nil:
    section.add "X-Amz-Signature", valid_600073
  var valid_600074 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600074 = validateParameter(valid_600074, JString, required = false,
                                 default = nil)
  if valid_600074 != nil:
    section.add "X-Amz-SignedHeaders", valid_600074
  var valid_600075 = header.getOrDefault("X-Amz-Credential")
  valid_600075 = validateParameter(valid_600075, JString, required = false,
                                 default = nil)
  if valid_600075 != nil:
    section.add "X-Amz-Credential", valid_600075
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600077: Call_CancelArchival_600065; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels archiving of a virtual tape to the virtual tape shelf (VTS) after the archiving process is initiated. This operation is only supported in the tape gateway type.
  ## 
  let valid = call_600077.validator(path, query, header, formData, body)
  let scheme = call_600077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600077.url(scheme.get, call_600077.host, call_600077.base,
                         call_600077.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600077, url, valid)

proc call*(call_600078: Call_CancelArchival_600065; body: JsonNode): Recallable =
  ## cancelArchival
  ## Cancels archiving of a virtual tape to the virtual tape shelf (VTS) after the archiving process is initiated. This operation is only supported in the tape gateway type.
  ##   body: JObject (required)
  var body_600079 = newJObject()
  if body != nil:
    body_600079 = body
  result = call_600078.call(nil, nil, nil, nil, body_600079)

var cancelArchival* = Call_CancelArchival_600065(name: "cancelArchival",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.CancelArchival",
    validator: validate_CancelArchival_600066, base: "/", url: url_CancelArchival_600067,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelRetrieval_600080 = ref object of OpenApiRestCall_599369
proc url_CancelRetrieval_600082(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CancelRetrieval_600081(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
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
  var valid_600083 = header.getOrDefault("X-Amz-Date")
  valid_600083 = validateParameter(valid_600083, JString, required = false,
                                 default = nil)
  if valid_600083 != nil:
    section.add "X-Amz-Date", valid_600083
  var valid_600084 = header.getOrDefault("X-Amz-Security-Token")
  valid_600084 = validateParameter(valid_600084, JString, required = false,
                                 default = nil)
  if valid_600084 != nil:
    section.add "X-Amz-Security-Token", valid_600084
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600085 = header.getOrDefault("X-Amz-Target")
  valid_600085 = validateParameter(valid_600085, JString, required = true, default = newJString(
      "StorageGateway_20130630.CancelRetrieval"))
  if valid_600085 != nil:
    section.add "X-Amz-Target", valid_600085
  var valid_600086 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600086 = validateParameter(valid_600086, JString, required = false,
                                 default = nil)
  if valid_600086 != nil:
    section.add "X-Amz-Content-Sha256", valid_600086
  var valid_600087 = header.getOrDefault("X-Amz-Algorithm")
  valid_600087 = validateParameter(valid_600087, JString, required = false,
                                 default = nil)
  if valid_600087 != nil:
    section.add "X-Amz-Algorithm", valid_600087
  var valid_600088 = header.getOrDefault("X-Amz-Signature")
  valid_600088 = validateParameter(valid_600088, JString, required = false,
                                 default = nil)
  if valid_600088 != nil:
    section.add "X-Amz-Signature", valid_600088
  var valid_600089 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600089 = validateParameter(valid_600089, JString, required = false,
                                 default = nil)
  if valid_600089 != nil:
    section.add "X-Amz-SignedHeaders", valid_600089
  var valid_600090 = header.getOrDefault("X-Amz-Credential")
  valid_600090 = validateParameter(valid_600090, JString, required = false,
                                 default = nil)
  if valid_600090 != nil:
    section.add "X-Amz-Credential", valid_600090
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600092: Call_CancelRetrieval_600080; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels retrieval of a virtual tape from the virtual tape shelf (VTS) to a gateway after the retrieval process is initiated. The virtual tape is returned to the VTS. This operation is only supported in the tape gateway type.
  ## 
  let valid = call_600092.validator(path, query, header, formData, body)
  let scheme = call_600092.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600092.url(scheme.get, call_600092.host, call_600092.base,
                         call_600092.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600092, url, valid)

proc call*(call_600093: Call_CancelRetrieval_600080; body: JsonNode): Recallable =
  ## cancelRetrieval
  ## Cancels retrieval of a virtual tape from the virtual tape shelf (VTS) to a gateway after the retrieval process is initiated. The virtual tape is returned to the VTS. This operation is only supported in the tape gateway type.
  ##   body: JObject (required)
  var body_600094 = newJObject()
  if body != nil:
    body_600094 = body
  result = call_600093.call(nil, nil, nil, nil, body_600094)

var cancelRetrieval* = Call_CancelRetrieval_600080(name: "cancelRetrieval",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.CancelRetrieval",
    validator: validate_CancelRetrieval_600081, base: "/", url: url_CancelRetrieval_600082,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCachediSCSIVolume_600095 = ref object of OpenApiRestCall_599369
proc url_CreateCachediSCSIVolume_600097(protocol: Scheme; host: string; base: string;
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

proc validate_CreateCachediSCSIVolume_600096(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600098 = header.getOrDefault("X-Amz-Date")
  valid_600098 = validateParameter(valid_600098, JString, required = false,
                                 default = nil)
  if valid_600098 != nil:
    section.add "X-Amz-Date", valid_600098
  var valid_600099 = header.getOrDefault("X-Amz-Security-Token")
  valid_600099 = validateParameter(valid_600099, JString, required = false,
                                 default = nil)
  if valid_600099 != nil:
    section.add "X-Amz-Security-Token", valid_600099
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600100 = header.getOrDefault("X-Amz-Target")
  valid_600100 = validateParameter(valid_600100, JString, required = true, default = newJString(
      "StorageGateway_20130630.CreateCachediSCSIVolume"))
  if valid_600100 != nil:
    section.add "X-Amz-Target", valid_600100
  var valid_600101 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600101 = validateParameter(valid_600101, JString, required = false,
                                 default = nil)
  if valid_600101 != nil:
    section.add "X-Amz-Content-Sha256", valid_600101
  var valid_600102 = header.getOrDefault("X-Amz-Algorithm")
  valid_600102 = validateParameter(valid_600102, JString, required = false,
                                 default = nil)
  if valid_600102 != nil:
    section.add "X-Amz-Algorithm", valid_600102
  var valid_600103 = header.getOrDefault("X-Amz-Signature")
  valid_600103 = validateParameter(valid_600103, JString, required = false,
                                 default = nil)
  if valid_600103 != nil:
    section.add "X-Amz-Signature", valid_600103
  var valid_600104 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600104 = validateParameter(valid_600104, JString, required = false,
                                 default = nil)
  if valid_600104 != nil:
    section.add "X-Amz-SignedHeaders", valid_600104
  var valid_600105 = header.getOrDefault("X-Amz-Credential")
  valid_600105 = validateParameter(valid_600105, JString, required = false,
                                 default = nil)
  if valid_600105 != nil:
    section.add "X-Amz-Credential", valid_600105
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600107: Call_CreateCachediSCSIVolume_600095; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a cached volume on a specified cached volume gateway. This operation is only supported in the cached volume gateway type.</p> <note> <p>Cache storage must be allocated to the gateway before you can create a cached volume. Use the <a>AddCache</a> operation to add cache storage to a gateway. </p> </note> <p>In the request, you must specify the gateway, size of the volume in bytes, the iSCSI target name, an IP address on which to expose the target, and a unique client token. In response, the gateway creates the volume and returns information about it. This information includes the volume Amazon Resource Name (ARN), its size, and the iSCSI target ARN that initiators can use to connect to the volume target.</p> <p>Optionally, you can provide the ARN for an existing volume as the <code>SourceVolumeARN</code> for this cached volume, which creates an exact copy of the existing volume’s latest recovery point. The <code>VolumeSizeInBytes</code> value must be equal to or larger than the size of the copied volume, in bytes.</p>
  ## 
  let valid = call_600107.validator(path, query, header, formData, body)
  let scheme = call_600107.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600107.url(scheme.get, call_600107.host, call_600107.base,
                         call_600107.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600107, url, valid)

proc call*(call_600108: Call_CreateCachediSCSIVolume_600095; body: JsonNode): Recallable =
  ## createCachediSCSIVolume
  ## <p>Creates a cached volume on a specified cached volume gateway. This operation is only supported in the cached volume gateway type.</p> <note> <p>Cache storage must be allocated to the gateway before you can create a cached volume. Use the <a>AddCache</a> operation to add cache storage to a gateway. </p> </note> <p>In the request, you must specify the gateway, size of the volume in bytes, the iSCSI target name, an IP address on which to expose the target, and a unique client token. In response, the gateway creates the volume and returns information about it. This information includes the volume Amazon Resource Name (ARN), its size, and the iSCSI target ARN that initiators can use to connect to the volume target.</p> <p>Optionally, you can provide the ARN for an existing volume as the <code>SourceVolumeARN</code> for this cached volume, which creates an exact copy of the existing volume’s latest recovery point. The <code>VolumeSizeInBytes</code> value must be equal to or larger than the size of the copied volume, in bytes.</p>
  ##   body: JObject (required)
  var body_600109 = newJObject()
  if body != nil:
    body_600109 = body
  result = call_600108.call(nil, nil, nil, nil, body_600109)

var createCachediSCSIVolume* = Call_CreateCachediSCSIVolume_600095(
    name: "createCachediSCSIVolume", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.CreateCachediSCSIVolume",
    validator: validate_CreateCachediSCSIVolume_600096, base: "/",
    url: url_CreateCachediSCSIVolume_600097, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNFSFileShare_600110 = ref object of OpenApiRestCall_599369
proc url_CreateNFSFileShare_600112(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateNFSFileShare_600111(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
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
  var valid_600113 = header.getOrDefault("X-Amz-Date")
  valid_600113 = validateParameter(valid_600113, JString, required = false,
                                 default = nil)
  if valid_600113 != nil:
    section.add "X-Amz-Date", valid_600113
  var valid_600114 = header.getOrDefault("X-Amz-Security-Token")
  valid_600114 = validateParameter(valid_600114, JString, required = false,
                                 default = nil)
  if valid_600114 != nil:
    section.add "X-Amz-Security-Token", valid_600114
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600115 = header.getOrDefault("X-Amz-Target")
  valid_600115 = validateParameter(valid_600115, JString, required = true, default = newJString(
      "StorageGateway_20130630.CreateNFSFileShare"))
  if valid_600115 != nil:
    section.add "X-Amz-Target", valid_600115
  var valid_600116 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600116 = validateParameter(valid_600116, JString, required = false,
                                 default = nil)
  if valid_600116 != nil:
    section.add "X-Amz-Content-Sha256", valid_600116
  var valid_600117 = header.getOrDefault("X-Amz-Algorithm")
  valid_600117 = validateParameter(valid_600117, JString, required = false,
                                 default = nil)
  if valid_600117 != nil:
    section.add "X-Amz-Algorithm", valid_600117
  var valid_600118 = header.getOrDefault("X-Amz-Signature")
  valid_600118 = validateParameter(valid_600118, JString, required = false,
                                 default = nil)
  if valid_600118 != nil:
    section.add "X-Amz-Signature", valid_600118
  var valid_600119 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600119 = validateParameter(valid_600119, JString, required = false,
                                 default = nil)
  if valid_600119 != nil:
    section.add "X-Amz-SignedHeaders", valid_600119
  var valid_600120 = header.getOrDefault("X-Amz-Credential")
  valid_600120 = validateParameter(valid_600120, JString, required = false,
                                 default = nil)
  if valid_600120 != nil:
    section.add "X-Amz-Credential", valid_600120
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600122: Call_CreateNFSFileShare_600110; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Network File System (NFS) file share on an existing file gateway. In Storage Gateway, a file share is a file system mount point backed by Amazon S3 cloud storage. Storage Gateway exposes file shares using a NFS interface. This operation is only supported for file gateways.</p> <important> <p>File gateway requires AWS Security Token Service (AWS STS) to be activated to enable you create a file share. Make sure AWS STS is activated in the AWS Region you are creating your file gateway in. If AWS STS is not activated in the AWS Region, activate it. For information about how to activate AWS STS, see Activating and Deactivating AWS STS in an AWS Region in the AWS Identity and Access Management User Guide. </p> <p>File gateway does not support creating hard or symbolic links on a file share.</p> </important>
  ## 
  let valid = call_600122.validator(path, query, header, formData, body)
  let scheme = call_600122.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600122.url(scheme.get, call_600122.host, call_600122.base,
                         call_600122.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600122, url, valid)

proc call*(call_600123: Call_CreateNFSFileShare_600110; body: JsonNode): Recallable =
  ## createNFSFileShare
  ## <p>Creates a Network File System (NFS) file share on an existing file gateway. In Storage Gateway, a file share is a file system mount point backed by Amazon S3 cloud storage. Storage Gateway exposes file shares using a NFS interface. This operation is only supported for file gateways.</p> <important> <p>File gateway requires AWS Security Token Service (AWS STS) to be activated to enable you create a file share. Make sure AWS STS is activated in the AWS Region you are creating your file gateway in. If AWS STS is not activated in the AWS Region, activate it. For information about how to activate AWS STS, see Activating and Deactivating AWS STS in an AWS Region in the AWS Identity and Access Management User Guide. </p> <p>File gateway does not support creating hard or symbolic links on a file share.</p> </important>
  ##   body: JObject (required)
  var body_600124 = newJObject()
  if body != nil:
    body_600124 = body
  result = call_600123.call(nil, nil, nil, nil, body_600124)

var createNFSFileShare* = Call_CreateNFSFileShare_600110(
    name: "createNFSFileShare", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.CreateNFSFileShare",
    validator: validate_CreateNFSFileShare_600111, base: "/",
    url: url_CreateNFSFileShare_600112, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSMBFileShare_600125 = ref object of OpenApiRestCall_599369
proc url_CreateSMBFileShare_600127(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateSMBFileShare_600126(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
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
  var valid_600128 = header.getOrDefault("X-Amz-Date")
  valid_600128 = validateParameter(valid_600128, JString, required = false,
                                 default = nil)
  if valid_600128 != nil:
    section.add "X-Amz-Date", valid_600128
  var valid_600129 = header.getOrDefault("X-Amz-Security-Token")
  valid_600129 = validateParameter(valid_600129, JString, required = false,
                                 default = nil)
  if valid_600129 != nil:
    section.add "X-Amz-Security-Token", valid_600129
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600130 = header.getOrDefault("X-Amz-Target")
  valid_600130 = validateParameter(valid_600130, JString, required = true, default = newJString(
      "StorageGateway_20130630.CreateSMBFileShare"))
  if valid_600130 != nil:
    section.add "X-Amz-Target", valid_600130
  var valid_600131 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600131 = validateParameter(valid_600131, JString, required = false,
                                 default = nil)
  if valid_600131 != nil:
    section.add "X-Amz-Content-Sha256", valid_600131
  var valid_600132 = header.getOrDefault("X-Amz-Algorithm")
  valid_600132 = validateParameter(valid_600132, JString, required = false,
                                 default = nil)
  if valid_600132 != nil:
    section.add "X-Amz-Algorithm", valid_600132
  var valid_600133 = header.getOrDefault("X-Amz-Signature")
  valid_600133 = validateParameter(valid_600133, JString, required = false,
                                 default = nil)
  if valid_600133 != nil:
    section.add "X-Amz-Signature", valid_600133
  var valid_600134 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600134 = validateParameter(valid_600134, JString, required = false,
                                 default = nil)
  if valid_600134 != nil:
    section.add "X-Amz-SignedHeaders", valid_600134
  var valid_600135 = header.getOrDefault("X-Amz-Credential")
  valid_600135 = validateParameter(valid_600135, JString, required = false,
                                 default = nil)
  if valid_600135 != nil:
    section.add "X-Amz-Credential", valid_600135
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600137: Call_CreateSMBFileShare_600125; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Server Message Block (SMB) file share on an existing file gateway. In Storage Gateway, a file share is a file system mount point backed by Amazon S3 cloud storage. Storage Gateway expose file shares using a SMB interface. This operation is only supported for file gateways.</p> <important> <p>File gateways require AWS Security Token Service (AWS STS) to be activated to enable you to create a file share. Make sure that AWS STS is activated in the AWS Region you are creating your file gateway in. If AWS STS is not activated in this AWS Region, activate it. For information about how to activate AWS STS, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_enable-regions.html">Activating and Deactivating AWS STS in an AWS Region</a> in the <i>AWS Identity and Access Management User Guide.</i> </p> <p>File gateways don't support creating hard or symbolic links on a file share.</p> </important>
  ## 
  let valid = call_600137.validator(path, query, header, formData, body)
  let scheme = call_600137.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600137.url(scheme.get, call_600137.host, call_600137.base,
                         call_600137.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600137, url, valid)

proc call*(call_600138: Call_CreateSMBFileShare_600125; body: JsonNode): Recallable =
  ## createSMBFileShare
  ## <p>Creates a Server Message Block (SMB) file share on an existing file gateway. In Storage Gateway, a file share is a file system mount point backed by Amazon S3 cloud storage. Storage Gateway expose file shares using a SMB interface. This operation is only supported for file gateways.</p> <important> <p>File gateways require AWS Security Token Service (AWS STS) to be activated to enable you to create a file share. Make sure that AWS STS is activated in the AWS Region you are creating your file gateway in. If AWS STS is not activated in this AWS Region, activate it. For information about how to activate AWS STS, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_enable-regions.html">Activating and Deactivating AWS STS in an AWS Region</a> in the <i>AWS Identity and Access Management User Guide.</i> </p> <p>File gateways don't support creating hard or symbolic links on a file share.</p> </important>
  ##   body: JObject (required)
  var body_600139 = newJObject()
  if body != nil:
    body_600139 = body
  result = call_600138.call(nil, nil, nil, nil, body_600139)

var createSMBFileShare* = Call_CreateSMBFileShare_600125(
    name: "createSMBFileShare", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.CreateSMBFileShare",
    validator: validate_CreateSMBFileShare_600126, base: "/",
    url: url_CreateSMBFileShare_600127, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSnapshot_600140 = ref object of OpenApiRestCall_599369
proc url_CreateSnapshot_600142(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateSnapshot_600141(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
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
  var valid_600143 = header.getOrDefault("X-Amz-Date")
  valid_600143 = validateParameter(valid_600143, JString, required = false,
                                 default = nil)
  if valid_600143 != nil:
    section.add "X-Amz-Date", valid_600143
  var valid_600144 = header.getOrDefault("X-Amz-Security-Token")
  valid_600144 = validateParameter(valid_600144, JString, required = false,
                                 default = nil)
  if valid_600144 != nil:
    section.add "X-Amz-Security-Token", valid_600144
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600145 = header.getOrDefault("X-Amz-Target")
  valid_600145 = validateParameter(valid_600145, JString, required = true, default = newJString(
      "StorageGateway_20130630.CreateSnapshot"))
  if valid_600145 != nil:
    section.add "X-Amz-Target", valid_600145
  var valid_600146 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600146 = validateParameter(valid_600146, JString, required = false,
                                 default = nil)
  if valid_600146 != nil:
    section.add "X-Amz-Content-Sha256", valid_600146
  var valid_600147 = header.getOrDefault("X-Amz-Algorithm")
  valid_600147 = validateParameter(valid_600147, JString, required = false,
                                 default = nil)
  if valid_600147 != nil:
    section.add "X-Amz-Algorithm", valid_600147
  var valid_600148 = header.getOrDefault("X-Amz-Signature")
  valid_600148 = validateParameter(valid_600148, JString, required = false,
                                 default = nil)
  if valid_600148 != nil:
    section.add "X-Amz-Signature", valid_600148
  var valid_600149 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600149 = validateParameter(valid_600149, JString, required = false,
                                 default = nil)
  if valid_600149 != nil:
    section.add "X-Amz-SignedHeaders", valid_600149
  var valid_600150 = header.getOrDefault("X-Amz-Credential")
  valid_600150 = validateParameter(valid_600150, JString, required = false,
                                 default = nil)
  if valid_600150 != nil:
    section.add "X-Amz-Credential", valid_600150
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600152: Call_CreateSnapshot_600140; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates a snapshot of a volume.</p> <p>AWS Storage Gateway provides the ability to back up point-in-time snapshots of your data to Amazon Simple Storage (S3) for durable off-site recovery, as well as import the data to an Amazon Elastic Block Store (EBS) volume in Amazon Elastic Compute Cloud (EC2). You can take snapshots of your gateway volume on a scheduled or ad hoc basis. This API enables you to take ad-hoc snapshot. For more information, see <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/managing-volumes.html#SchedulingSnapshot">Editing a Snapshot Schedule</a>.</p> <p>In the CreateSnapshot request you identify the volume by providing its Amazon Resource Name (ARN). You must also provide description for the snapshot. When AWS Storage Gateway takes the snapshot of specified volume, the snapshot and description appears in the AWS Storage Gateway Console. In response, AWS Storage Gateway returns you a snapshot ID. You can use this snapshot ID to check the snapshot progress or later use it when you want to create a volume from a snapshot. This operation is only supported in stored and cached volume gateway type.</p> <note> <p>To list or delete a snapshot, you must use the Amazon EC2 API. For more information, see DescribeSnapshots or DeleteSnapshot in the <a href="https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_Operations.html">EC2 API reference</a>.</p> </note> <important> <p>Volume and snapshot IDs are changing to a longer length ID format. For more information, see the important note on the <a href="https://docs.aws.amazon.com/storagegateway/latest/APIReference/Welcome.html">Welcome</a> page.</p> </important>
  ## 
  let valid = call_600152.validator(path, query, header, formData, body)
  let scheme = call_600152.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600152.url(scheme.get, call_600152.host, call_600152.base,
                         call_600152.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600152, url, valid)

proc call*(call_600153: Call_CreateSnapshot_600140; body: JsonNode): Recallable =
  ## createSnapshot
  ## <p>Initiates a snapshot of a volume.</p> <p>AWS Storage Gateway provides the ability to back up point-in-time snapshots of your data to Amazon Simple Storage (S3) for durable off-site recovery, as well as import the data to an Amazon Elastic Block Store (EBS) volume in Amazon Elastic Compute Cloud (EC2). You can take snapshots of your gateway volume on a scheduled or ad hoc basis. This API enables you to take ad-hoc snapshot. For more information, see <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/managing-volumes.html#SchedulingSnapshot">Editing a Snapshot Schedule</a>.</p> <p>In the CreateSnapshot request you identify the volume by providing its Amazon Resource Name (ARN). You must also provide description for the snapshot. When AWS Storage Gateway takes the snapshot of specified volume, the snapshot and description appears in the AWS Storage Gateway Console. In response, AWS Storage Gateway returns you a snapshot ID. You can use this snapshot ID to check the snapshot progress or later use it when you want to create a volume from a snapshot. This operation is only supported in stored and cached volume gateway type.</p> <note> <p>To list or delete a snapshot, you must use the Amazon EC2 API. For more information, see DescribeSnapshots or DeleteSnapshot in the <a href="https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_Operations.html">EC2 API reference</a>.</p> </note> <important> <p>Volume and snapshot IDs are changing to a longer length ID format. For more information, see the important note on the <a href="https://docs.aws.amazon.com/storagegateway/latest/APIReference/Welcome.html">Welcome</a> page.</p> </important>
  ##   body: JObject (required)
  var body_600154 = newJObject()
  if body != nil:
    body_600154 = body
  result = call_600153.call(nil, nil, nil, nil, body_600154)

var createSnapshot* = Call_CreateSnapshot_600140(name: "createSnapshot",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.CreateSnapshot",
    validator: validate_CreateSnapshot_600141, base: "/", url: url_CreateSnapshot_600142,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSnapshotFromVolumeRecoveryPoint_600155 = ref object of OpenApiRestCall_599369
proc url_CreateSnapshotFromVolumeRecoveryPoint_600157(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateSnapshotFromVolumeRecoveryPoint_600156(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600158 = header.getOrDefault("X-Amz-Date")
  valid_600158 = validateParameter(valid_600158, JString, required = false,
                                 default = nil)
  if valid_600158 != nil:
    section.add "X-Amz-Date", valid_600158
  var valid_600159 = header.getOrDefault("X-Amz-Security-Token")
  valid_600159 = validateParameter(valid_600159, JString, required = false,
                                 default = nil)
  if valid_600159 != nil:
    section.add "X-Amz-Security-Token", valid_600159
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600160 = header.getOrDefault("X-Amz-Target")
  valid_600160 = validateParameter(valid_600160, JString, required = true, default = newJString(
      "StorageGateway_20130630.CreateSnapshotFromVolumeRecoveryPoint"))
  if valid_600160 != nil:
    section.add "X-Amz-Target", valid_600160
  var valid_600161 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600161 = validateParameter(valid_600161, JString, required = false,
                                 default = nil)
  if valid_600161 != nil:
    section.add "X-Amz-Content-Sha256", valid_600161
  var valid_600162 = header.getOrDefault("X-Amz-Algorithm")
  valid_600162 = validateParameter(valid_600162, JString, required = false,
                                 default = nil)
  if valid_600162 != nil:
    section.add "X-Amz-Algorithm", valid_600162
  var valid_600163 = header.getOrDefault("X-Amz-Signature")
  valid_600163 = validateParameter(valid_600163, JString, required = false,
                                 default = nil)
  if valid_600163 != nil:
    section.add "X-Amz-Signature", valid_600163
  var valid_600164 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600164 = validateParameter(valid_600164, JString, required = false,
                                 default = nil)
  if valid_600164 != nil:
    section.add "X-Amz-SignedHeaders", valid_600164
  var valid_600165 = header.getOrDefault("X-Amz-Credential")
  valid_600165 = validateParameter(valid_600165, JString, required = false,
                                 default = nil)
  if valid_600165 != nil:
    section.add "X-Amz-Credential", valid_600165
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600167: Call_CreateSnapshotFromVolumeRecoveryPoint_600155;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Initiates a snapshot of a gateway from a volume recovery point. This operation is only supported in the cached volume gateway type.</p> <p>A volume recovery point is a point in time at which all data of the volume is consistent and from which you can create a snapshot. To get a list of volume recovery point for cached volume gateway, use <a>ListVolumeRecoveryPoints</a>.</p> <p>In the <code>CreateSnapshotFromVolumeRecoveryPoint</code> request, you identify the volume by providing its Amazon Resource Name (ARN). You must also provide a description for the snapshot. When the gateway takes a snapshot of the specified volume, the snapshot and its description appear in the AWS Storage Gateway console. In response, the gateway returns you a snapshot ID. You can use this snapshot ID to check the snapshot progress or later use it when you want to create a volume from a snapshot.</p> <note> <p>To list or delete a snapshot, you must use the Amazon EC2 API. For more information, in <i>Amazon Elastic Compute Cloud API Reference</i>.</p> </note>
  ## 
  let valid = call_600167.validator(path, query, header, formData, body)
  let scheme = call_600167.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600167.url(scheme.get, call_600167.host, call_600167.base,
                         call_600167.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600167, url, valid)

proc call*(call_600168: Call_CreateSnapshotFromVolumeRecoveryPoint_600155;
          body: JsonNode): Recallable =
  ## createSnapshotFromVolumeRecoveryPoint
  ## <p>Initiates a snapshot of a gateway from a volume recovery point. This operation is only supported in the cached volume gateway type.</p> <p>A volume recovery point is a point in time at which all data of the volume is consistent and from which you can create a snapshot. To get a list of volume recovery point for cached volume gateway, use <a>ListVolumeRecoveryPoints</a>.</p> <p>In the <code>CreateSnapshotFromVolumeRecoveryPoint</code> request, you identify the volume by providing its Amazon Resource Name (ARN). You must also provide a description for the snapshot. When the gateway takes a snapshot of the specified volume, the snapshot and its description appear in the AWS Storage Gateway console. In response, the gateway returns you a snapshot ID. You can use this snapshot ID to check the snapshot progress or later use it when you want to create a volume from a snapshot.</p> <note> <p>To list or delete a snapshot, you must use the Amazon EC2 API. For more information, in <i>Amazon Elastic Compute Cloud API Reference</i>.</p> </note>
  ##   body: JObject (required)
  var body_600169 = newJObject()
  if body != nil:
    body_600169 = body
  result = call_600168.call(nil, nil, nil, nil, body_600169)

var createSnapshotFromVolumeRecoveryPoint* = Call_CreateSnapshotFromVolumeRecoveryPoint_600155(
    name: "createSnapshotFromVolumeRecoveryPoint", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com", route: "/#X-Amz-Target=StorageGateway_20130630.CreateSnapshotFromVolumeRecoveryPoint",
    validator: validate_CreateSnapshotFromVolumeRecoveryPoint_600156, base: "/",
    url: url_CreateSnapshotFromVolumeRecoveryPoint_600157,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStorediSCSIVolume_600170 = ref object of OpenApiRestCall_599369
proc url_CreateStorediSCSIVolume_600172(protocol: Scheme; host: string; base: string;
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

proc validate_CreateStorediSCSIVolume_600171(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600173 = header.getOrDefault("X-Amz-Date")
  valid_600173 = validateParameter(valid_600173, JString, required = false,
                                 default = nil)
  if valid_600173 != nil:
    section.add "X-Amz-Date", valid_600173
  var valid_600174 = header.getOrDefault("X-Amz-Security-Token")
  valid_600174 = validateParameter(valid_600174, JString, required = false,
                                 default = nil)
  if valid_600174 != nil:
    section.add "X-Amz-Security-Token", valid_600174
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600175 = header.getOrDefault("X-Amz-Target")
  valid_600175 = validateParameter(valid_600175, JString, required = true, default = newJString(
      "StorageGateway_20130630.CreateStorediSCSIVolume"))
  if valid_600175 != nil:
    section.add "X-Amz-Target", valid_600175
  var valid_600176 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600176 = validateParameter(valid_600176, JString, required = false,
                                 default = nil)
  if valid_600176 != nil:
    section.add "X-Amz-Content-Sha256", valid_600176
  var valid_600177 = header.getOrDefault("X-Amz-Algorithm")
  valid_600177 = validateParameter(valid_600177, JString, required = false,
                                 default = nil)
  if valid_600177 != nil:
    section.add "X-Amz-Algorithm", valid_600177
  var valid_600178 = header.getOrDefault("X-Amz-Signature")
  valid_600178 = validateParameter(valid_600178, JString, required = false,
                                 default = nil)
  if valid_600178 != nil:
    section.add "X-Amz-Signature", valid_600178
  var valid_600179 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600179 = validateParameter(valid_600179, JString, required = false,
                                 default = nil)
  if valid_600179 != nil:
    section.add "X-Amz-SignedHeaders", valid_600179
  var valid_600180 = header.getOrDefault("X-Amz-Credential")
  valid_600180 = validateParameter(valid_600180, JString, required = false,
                                 default = nil)
  if valid_600180 != nil:
    section.add "X-Amz-Credential", valid_600180
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600182: Call_CreateStorediSCSIVolume_600170; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a volume on a specified gateway. This operation is only supported in the stored volume gateway type.</p> <p>The size of the volume to create is inferred from the disk size. You can choose to preserve existing data on the disk, create volume from an existing snapshot, or create an empty volume. If you choose to create an empty gateway volume, then any existing data on the disk is erased.</p> <p>In the request you must specify the gateway and the disk information on which you are creating the volume. In response, the gateway creates the volume and returns volume information such as the volume Amazon Resource Name (ARN), its size, and the iSCSI target ARN that initiators can use to connect to the volume target.</p>
  ## 
  let valid = call_600182.validator(path, query, header, formData, body)
  let scheme = call_600182.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600182.url(scheme.get, call_600182.host, call_600182.base,
                         call_600182.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600182, url, valid)

proc call*(call_600183: Call_CreateStorediSCSIVolume_600170; body: JsonNode): Recallable =
  ## createStorediSCSIVolume
  ## <p>Creates a volume on a specified gateway. This operation is only supported in the stored volume gateway type.</p> <p>The size of the volume to create is inferred from the disk size. You can choose to preserve existing data on the disk, create volume from an existing snapshot, or create an empty volume. If you choose to create an empty gateway volume, then any existing data on the disk is erased.</p> <p>In the request you must specify the gateway and the disk information on which you are creating the volume. In response, the gateway creates the volume and returns volume information such as the volume Amazon Resource Name (ARN), its size, and the iSCSI target ARN that initiators can use to connect to the volume target.</p>
  ##   body: JObject (required)
  var body_600184 = newJObject()
  if body != nil:
    body_600184 = body
  result = call_600183.call(nil, nil, nil, nil, body_600184)

var createStorediSCSIVolume* = Call_CreateStorediSCSIVolume_600170(
    name: "createStorediSCSIVolume", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.CreateStorediSCSIVolume",
    validator: validate_CreateStorediSCSIVolume_600171, base: "/",
    url: url_CreateStorediSCSIVolume_600172, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTapeWithBarcode_600185 = ref object of OpenApiRestCall_599369
proc url_CreateTapeWithBarcode_600187(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTapeWithBarcode_600186(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600188 = header.getOrDefault("X-Amz-Date")
  valid_600188 = validateParameter(valid_600188, JString, required = false,
                                 default = nil)
  if valid_600188 != nil:
    section.add "X-Amz-Date", valid_600188
  var valid_600189 = header.getOrDefault("X-Amz-Security-Token")
  valid_600189 = validateParameter(valid_600189, JString, required = false,
                                 default = nil)
  if valid_600189 != nil:
    section.add "X-Amz-Security-Token", valid_600189
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600190 = header.getOrDefault("X-Amz-Target")
  valid_600190 = validateParameter(valid_600190, JString, required = true, default = newJString(
      "StorageGateway_20130630.CreateTapeWithBarcode"))
  if valid_600190 != nil:
    section.add "X-Amz-Target", valid_600190
  var valid_600191 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600191 = validateParameter(valid_600191, JString, required = false,
                                 default = nil)
  if valid_600191 != nil:
    section.add "X-Amz-Content-Sha256", valid_600191
  var valid_600192 = header.getOrDefault("X-Amz-Algorithm")
  valid_600192 = validateParameter(valid_600192, JString, required = false,
                                 default = nil)
  if valid_600192 != nil:
    section.add "X-Amz-Algorithm", valid_600192
  var valid_600193 = header.getOrDefault("X-Amz-Signature")
  valid_600193 = validateParameter(valid_600193, JString, required = false,
                                 default = nil)
  if valid_600193 != nil:
    section.add "X-Amz-Signature", valid_600193
  var valid_600194 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600194 = validateParameter(valid_600194, JString, required = false,
                                 default = nil)
  if valid_600194 != nil:
    section.add "X-Amz-SignedHeaders", valid_600194
  var valid_600195 = header.getOrDefault("X-Amz-Credential")
  valid_600195 = validateParameter(valid_600195, JString, required = false,
                                 default = nil)
  if valid_600195 != nil:
    section.add "X-Amz-Credential", valid_600195
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600197: Call_CreateTapeWithBarcode_600185; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a virtual tape by using your own barcode. You write data to the virtual tape and then archive the tape. A barcode is unique and can not be reused if it has already been used on a tape . This applies to barcodes used on deleted tapes. This operation is only supported in the tape gateway type.</p> <note> <p>Cache storage must be allocated to the gateway before you can create a virtual tape. Use the <a>AddCache</a> operation to add cache storage to a gateway.</p> </note>
  ## 
  let valid = call_600197.validator(path, query, header, formData, body)
  let scheme = call_600197.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600197.url(scheme.get, call_600197.host, call_600197.base,
                         call_600197.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600197, url, valid)

proc call*(call_600198: Call_CreateTapeWithBarcode_600185; body: JsonNode): Recallable =
  ## createTapeWithBarcode
  ## <p>Creates a virtual tape by using your own barcode. You write data to the virtual tape and then archive the tape. A barcode is unique and can not be reused if it has already been used on a tape . This applies to barcodes used on deleted tapes. This operation is only supported in the tape gateway type.</p> <note> <p>Cache storage must be allocated to the gateway before you can create a virtual tape. Use the <a>AddCache</a> operation to add cache storage to a gateway.</p> </note>
  ##   body: JObject (required)
  var body_600199 = newJObject()
  if body != nil:
    body_600199 = body
  result = call_600198.call(nil, nil, nil, nil, body_600199)

var createTapeWithBarcode* = Call_CreateTapeWithBarcode_600185(
    name: "createTapeWithBarcode", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.CreateTapeWithBarcode",
    validator: validate_CreateTapeWithBarcode_600186, base: "/",
    url: url_CreateTapeWithBarcode_600187, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTapes_600200 = ref object of OpenApiRestCall_599369
proc url_CreateTapes_600202(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTapes_600201(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600203 = header.getOrDefault("X-Amz-Date")
  valid_600203 = validateParameter(valid_600203, JString, required = false,
                                 default = nil)
  if valid_600203 != nil:
    section.add "X-Amz-Date", valid_600203
  var valid_600204 = header.getOrDefault("X-Amz-Security-Token")
  valid_600204 = validateParameter(valid_600204, JString, required = false,
                                 default = nil)
  if valid_600204 != nil:
    section.add "X-Amz-Security-Token", valid_600204
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600205 = header.getOrDefault("X-Amz-Target")
  valid_600205 = validateParameter(valid_600205, JString, required = true, default = newJString(
      "StorageGateway_20130630.CreateTapes"))
  if valid_600205 != nil:
    section.add "X-Amz-Target", valid_600205
  var valid_600206 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600206 = validateParameter(valid_600206, JString, required = false,
                                 default = nil)
  if valid_600206 != nil:
    section.add "X-Amz-Content-Sha256", valid_600206
  var valid_600207 = header.getOrDefault("X-Amz-Algorithm")
  valid_600207 = validateParameter(valid_600207, JString, required = false,
                                 default = nil)
  if valid_600207 != nil:
    section.add "X-Amz-Algorithm", valid_600207
  var valid_600208 = header.getOrDefault("X-Amz-Signature")
  valid_600208 = validateParameter(valid_600208, JString, required = false,
                                 default = nil)
  if valid_600208 != nil:
    section.add "X-Amz-Signature", valid_600208
  var valid_600209 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600209 = validateParameter(valid_600209, JString, required = false,
                                 default = nil)
  if valid_600209 != nil:
    section.add "X-Amz-SignedHeaders", valid_600209
  var valid_600210 = header.getOrDefault("X-Amz-Credential")
  valid_600210 = validateParameter(valid_600210, JString, required = false,
                                 default = nil)
  if valid_600210 != nil:
    section.add "X-Amz-Credential", valid_600210
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600212: Call_CreateTapes_600200; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates one or more virtual tapes. You write data to the virtual tapes and then archive the tapes. This operation is only supported in the tape gateway type.</p> <note> <p>Cache storage must be allocated to the gateway before you can create virtual tapes. Use the <a>AddCache</a> operation to add cache storage to a gateway. </p> </note>
  ## 
  let valid = call_600212.validator(path, query, header, formData, body)
  let scheme = call_600212.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600212.url(scheme.get, call_600212.host, call_600212.base,
                         call_600212.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600212, url, valid)

proc call*(call_600213: Call_CreateTapes_600200; body: JsonNode): Recallable =
  ## createTapes
  ## <p>Creates one or more virtual tapes. You write data to the virtual tapes and then archive the tapes. This operation is only supported in the tape gateway type.</p> <note> <p>Cache storage must be allocated to the gateway before you can create virtual tapes. Use the <a>AddCache</a> operation to add cache storage to a gateway. </p> </note>
  ##   body: JObject (required)
  var body_600214 = newJObject()
  if body != nil:
    body_600214 = body
  result = call_600213.call(nil, nil, nil, nil, body_600214)

var createTapes* = Call_CreateTapes_600200(name: "createTapes",
                                        meth: HttpMethod.HttpPost,
                                        host: "storagegateway.amazonaws.com", route: "/#X-Amz-Target=StorageGateway_20130630.CreateTapes",
                                        validator: validate_CreateTapes_600201,
                                        base: "/", url: url_CreateTapes_600202,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBandwidthRateLimit_600215 = ref object of OpenApiRestCall_599369
proc url_DeleteBandwidthRateLimit_600217(protocol: Scheme; host: string;
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

proc validate_DeleteBandwidthRateLimit_600216(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600218 = header.getOrDefault("X-Amz-Date")
  valid_600218 = validateParameter(valid_600218, JString, required = false,
                                 default = nil)
  if valid_600218 != nil:
    section.add "X-Amz-Date", valid_600218
  var valid_600219 = header.getOrDefault("X-Amz-Security-Token")
  valid_600219 = validateParameter(valid_600219, JString, required = false,
                                 default = nil)
  if valid_600219 != nil:
    section.add "X-Amz-Security-Token", valid_600219
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600220 = header.getOrDefault("X-Amz-Target")
  valid_600220 = validateParameter(valid_600220, JString, required = true, default = newJString(
      "StorageGateway_20130630.DeleteBandwidthRateLimit"))
  if valid_600220 != nil:
    section.add "X-Amz-Target", valid_600220
  var valid_600221 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600221 = validateParameter(valid_600221, JString, required = false,
                                 default = nil)
  if valid_600221 != nil:
    section.add "X-Amz-Content-Sha256", valid_600221
  var valid_600222 = header.getOrDefault("X-Amz-Algorithm")
  valid_600222 = validateParameter(valid_600222, JString, required = false,
                                 default = nil)
  if valid_600222 != nil:
    section.add "X-Amz-Algorithm", valid_600222
  var valid_600223 = header.getOrDefault("X-Amz-Signature")
  valid_600223 = validateParameter(valid_600223, JString, required = false,
                                 default = nil)
  if valid_600223 != nil:
    section.add "X-Amz-Signature", valid_600223
  var valid_600224 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600224 = validateParameter(valid_600224, JString, required = false,
                                 default = nil)
  if valid_600224 != nil:
    section.add "X-Amz-SignedHeaders", valid_600224
  var valid_600225 = header.getOrDefault("X-Amz-Credential")
  valid_600225 = validateParameter(valid_600225, JString, required = false,
                                 default = nil)
  if valid_600225 != nil:
    section.add "X-Amz-Credential", valid_600225
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600227: Call_DeleteBandwidthRateLimit_600215; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the bandwidth rate limits of a gateway. You can delete either the upload and download bandwidth rate limit, or you can delete both. If you delete only one of the limits, the other limit remains unchanged. To specify which gateway to work with, use the Amazon Resource Name (ARN) of the gateway in your request. This operation is supported for the stored volume, cached volume and tape gateway types.
  ## 
  let valid = call_600227.validator(path, query, header, formData, body)
  let scheme = call_600227.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600227.url(scheme.get, call_600227.host, call_600227.base,
                         call_600227.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600227, url, valid)

proc call*(call_600228: Call_DeleteBandwidthRateLimit_600215; body: JsonNode): Recallable =
  ## deleteBandwidthRateLimit
  ## Deletes the bandwidth rate limits of a gateway. You can delete either the upload and download bandwidth rate limit, or you can delete both. If you delete only one of the limits, the other limit remains unchanged. To specify which gateway to work with, use the Amazon Resource Name (ARN) of the gateway in your request. This operation is supported for the stored volume, cached volume and tape gateway types.
  ##   body: JObject (required)
  var body_600229 = newJObject()
  if body != nil:
    body_600229 = body
  result = call_600228.call(nil, nil, nil, nil, body_600229)

var deleteBandwidthRateLimit* = Call_DeleteBandwidthRateLimit_600215(
    name: "deleteBandwidthRateLimit", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DeleteBandwidthRateLimit",
    validator: validate_DeleteBandwidthRateLimit_600216, base: "/",
    url: url_DeleteBandwidthRateLimit_600217, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteChapCredentials_600230 = ref object of OpenApiRestCall_599369
proc url_DeleteChapCredentials_600232(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteChapCredentials_600231(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600233 = header.getOrDefault("X-Amz-Date")
  valid_600233 = validateParameter(valid_600233, JString, required = false,
                                 default = nil)
  if valid_600233 != nil:
    section.add "X-Amz-Date", valid_600233
  var valid_600234 = header.getOrDefault("X-Amz-Security-Token")
  valid_600234 = validateParameter(valid_600234, JString, required = false,
                                 default = nil)
  if valid_600234 != nil:
    section.add "X-Amz-Security-Token", valid_600234
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600235 = header.getOrDefault("X-Amz-Target")
  valid_600235 = validateParameter(valid_600235, JString, required = true, default = newJString(
      "StorageGateway_20130630.DeleteChapCredentials"))
  if valid_600235 != nil:
    section.add "X-Amz-Target", valid_600235
  var valid_600236 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600236 = validateParameter(valid_600236, JString, required = false,
                                 default = nil)
  if valid_600236 != nil:
    section.add "X-Amz-Content-Sha256", valid_600236
  var valid_600237 = header.getOrDefault("X-Amz-Algorithm")
  valid_600237 = validateParameter(valid_600237, JString, required = false,
                                 default = nil)
  if valid_600237 != nil:
    section.add "X-Amz-Algorithm", valid_600237
  var valid_600238 = header.getOrDefault("X-Amz-Signature")
  valid_600238 = validateParameter(valid_600238, JString, required = false,
                                 default = nil)
  if valid_600238 != nil:
    section.add "X-Amz-Signature", valid_600238
  var valid_600239 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600239 = validateParameter(valid_600239, JString, required = false,
                                 default = nil)
  if valid_600239 != nil:
    section.add "X-Amz-SignedHeaders", valid_600239
  var valid_600240 = header.getOrDefault("X-Amz-Credential")
  valid_600240 = validateParameter(valid_600240, JString, required = false,
                                 default = nil)
  if valid_600240 != nil:
    section.add "X-Amz-Credential", valid_600240
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600242: Call_DeleteChapCredentials_600230; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes Challenge-Handshake Authentication Protocol (CHAP) credentials for a specified iSCSI target and initiator pair. This operation is supported in volume and tape gateway types.
  ## 
  let valid = call_600242.validator(path, query, header, formData, body)
  let scheme = call_600242.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600242.url(scheme.get, call_600242.host, call_600242.base,
                         call_600242.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600242, url, valid)

proc call*(call_600243: Call_DeleteChapCredentials_600230; body: JsonNode): Recallable =
  ## deleteChapCredentials
  ## Deletes Challenge-Handshake Authentication Protocol (CHAP) credentials for a specified iSCSI target and initiator pair. This operation is supported in volume and tape gateway types.
  ##   body: JObject (required)
  var body_600244 = newJObject()
  if body != nil:
    body_600244 = body
  result = call_600243.call(nil, nil, nil, nil, body_600244)

var deleteChapCredentials* = Call_DeleteChapCredentials_600230(
    name: "deleteChapCredentials", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DeleteChapCredentials",
    validator: validate_DeleteChapCredentials_600231, base: "/",
    url: url_DeleteChapCredentials_600232, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFileShare_600245 = ref object of OpenApiRestCall_599369
proc url_DeleteFileShare_600247(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteFileShare_600246(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
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
  var valid_600248 = header.getOrDefault("X-Amz-Date")
  valid_600248 = validateParameter(valid_600248, JString, required = false,
                                 default = nil)
  if valid_600248 != nil:
    section.add "X-Amz-Date", valid_600248
  var valid_600249 = header.getOrDefault("X-Amz-Security-Token")
  valid_600249 = validateParameter(valid_600249, JString, required = false,
                                 default = nil)
  if valid_600249 != nil:
    section.add "X-Amz-Security-Token", valid_600249
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600250 = header.getOrDefault("X-Amz-Target")
  valid_600250 = validateParameter(valid_600250, JString, required = true, default = newJString(
      "StorageGateway_20130630.DeleteFileShare"))
  if valid_600250 != nil:
    section.add "X-Amz-Target", valid_600250
  var valid_600251 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600251 = validateParameter(valid_600251, JString, required = false,
                                 default = nil)
  if valid_600251 != nil:
    section.add "X-Amz-Content-Sha256", valid_600251
  var valid_600252 = header.getOrDefault("X-Amz-Algorithm")
  valid_600252 = validateParameter(valid_600252, JString, required = false,
                                 default = nil)
  if valid_600252 != nil:
    section.add "X-Amz-Algorithm", valid_600252
  var valid_600253 = header.getOrDefault("X-Amz-Signature")
  valid_600253 = validateParameter(valid_600253, JString, required = false,
                                 default = nil)
  if valid_600253 != nil:
    section.add "X-Amz-Signature", valid_600253
  var valid_600254 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600254 = validateParameter(valid_600254, JString, required = false,
                                 default = nil)
  if valid_600254 != nil:
    section.add "X-Amz-SignedHeaders", valid_600254
  var valid_600255 = header.getOrDefault("X-Amz-Credential")
  valid_600255 = validateParameter(valid_600255, JString, required = false,
                                 default = nil)
  if valid_600255 != nil:
    section.add "X-Amz-Credential", valid_600255
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600257: Call_DeleteFileShare_600245; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a file share from a file gateway. This operation is only supported for file gateways.
  ## 
  let valid = call_600257.validator(path, query, header, formData, body)
  let scheme = call_600257.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600257.url(scheme.get, call_600257.host, call_600257.base,
                         call_600257.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600257, url, valid)

proc call*(call_600258: Call_DeleteFileShare_600245; body: JsonNode): Recallable =
  ## deleteFileShare
  ## Deletes a file share from a file gateway. This operation is only supported for file gateways.
  ##   body: JObject (required)
  var body_600259 = newJObject()
  if body != nil:
    body_600259 = body
  result = call_600258.call(nil, nil, nil, nil, body_600259)

var deleteFileShare* = Call_DeleteFileShare_600245(name: "deleteFileShare",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DeleteFileShare",
    validator: validate_DeleteFileShare_600246, base: "/", url: url_DeleteFileShare_600247,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGateway_600260 = ref object of OpenApiRestCall_599369
proc url_DeleteGateway_600262(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteGateway_600261(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600263 = header.getOrDefault("X-Amz-Date")
  valid_600263 = validateParameter(valid_600263, JString, required = false,
                                 default = nil)
  if valid_600263 != nil:
    section.add "X-Amz-Date", valid_600263
  var valid_600264 = header.getOrDefault("X-Amz-Security-Token")
  valid_600264 = validateParameter(valid_600264, JString, required = false,
                                 default = nil)
  if valid_600264 != nil:
    section.add "X-Amz-Security-Token", valid_600264
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600265 = header.getOrDefault("X-Amz-Target")
  valid_600265 = validateParameter(valid_600265, JString, required = true, default = newJString(
      "StorageGateway_20130630.DeleteGateway"))
  if valid_600265 != nil:
    section.add "X-Amz-Target", valid_600265
  var valid_600266 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600266 = validateParameter(valid_600266, JString, required = false,
                                 default = nil)
  if valid_600266 != nil:
    section.add "X-Amz-Content-Sha256", valid_600266
  var valid_600267 = header.getOrDefault("X-Amz-Algorithm")
  valid_600267 = validateParameter(valid_600267, JString, required = false,
                                 default = nil)
  if valid_600267 != nil:
    section.add "X-Amz-Algorithm", valid_600267
  var valid_600268 = header.getOrDefault("X-Amz-Signature")
  valid_600268 = validateParameter(valid_600268, JString, required = false,
                                 default = nil)
  if valid_600268 != nil:
    section.add "X-Amz-Signature", valid_600268
  var valid_600269 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600269 = validateParameter(valid_600269, JString, required = false,
                                 default = nil)
  if valid_600269 != nil:
    section.add "X-Amz-SignedHeaders", valid_600269
  var valid_600270 = header.getOrDefault("X-Amz-Credential")
  valid_600270 = validateParameter(valid_600270, JString, required = false,
                                 default = nil)
  if valid_600270 != nil:
    section.add "X-Amz-Credential", valid_600270
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600272: Call_DeleteGateway_600260; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a gateway. To specify which gateway to delete, use the Amazon Resource Name (ARN) of the gateway in your request. The operation deletes the gateway; however, it does not delete the gateway virtual machine (VM) from your host computer.</p> <p>After you delete a gateway, you cannot reactivate it. Completed snapshots of the gateway volumes are not deleted upon deleting the gateway, however, pending snapshots will not complete. After you delete a gateway, your next step is to remove it from your environment.</p> <important> <p>You no longer pay software charges after the gateway is deleted; however, your existing Amazon EBS snapshots persist and you will continue to be billed for these snapshots. You can choose to remove all remaining Amazon EBS snapshots by canceling your Amazon EC2 subscription.  If you prefer not to cancel your Amazon EC2 subscription, you can delete your snapshots using the Amazon EC2 console. For more information, see the <a href="http://aws.amazon.com/storagegateway"> AWS Storage Gateway Detail Page</a>. </p> </important>
  ## 
  let valid = call_600272.validator(path, query, header, formData, body)
  let scheme = call_600272.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600272.url(scheme.get, call_600272.host, call_600272.base,
                         call_600272.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600272, url, valid)

proc call*(call_600273: Call_DeleteGateway_600260; body: JsonNode): Recallable =
  ## deleteGateway
  ## <p>Deletes a gateway. To specify which gateway to delete, use the Amazon Resource Name (ARN) of the gateway in your request. The operation deletes the gateway; however, it does not delete the gateway virtual machine (VM) from your host computer.</p> <p>After you delete a gateway, you cannot reactivate it. Completed snapshots of the gateway volumes are not deleted upon deleting the gateway, however, pending snapshots will not complete. After you delete a gateway, your next step is to remove it from your environment.</p> <important> <p>You no longer pay software charges after the gateway is deleted; however, your existing Amazon EBS snapshots persist and you will continue to be billed for these snapshots. You can choose to remove all remaining Amazon EBS snapshots by canceling your Amazon EC2 subscription.  If you prefer not to cancel your Amazon EC2 subscription, you can delete your snapshots using the Amazon EC2 console. For more information, see the <a href="http://aws.amazon.com/storagegateway"> AWS Storage Gateway Detail Page</a>. </p> </important>
  ##   body: JObject (required)
  var body_600274 = newJObject()
  if body != nil:
    body_600274 = body
  result = call_600273.call(nil, nil, nil, nil, body_600274)

var deleteGateway* = Call_DeleteGateway_600260(name: "deleteGateway",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DeleteGateway",
    validator: validate_DeleteGateway_600261, base: "/", url: url_DeleteGateway_600262,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSnapshotSchedule_600275 = ref object of OpenApiRestCall_599369
proc url_DeleteSnapshotSchedule_600277(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteSnapshotSchedule_600276(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600278 = header.getOrDefault("X-Amz-Date")
  valid_600278 = validateParameter(valid_600278, JString, required = false,
                                 default = nil)
  if valid_600278 != nil:
    section.add "X-Amz-Date", valid_600278
  var valid_600279 = header.getOrDefault("X-Amz-Security-Token")
  valid_600279 = validateParameter(valid_600279, JString, required = false,
                                 default = nil)
  if valid_600279 != nil:
    section.add "X-Amz-Security-Token", valid_600279
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600280 = header.getOrDefault("X-Amz-Target")
  valid_600280 = validateParameter(valid_600280, JString, required = true, default = newJString(
      "StorageGateway_20130630.DeleteSnapshotSchedule"))
  if valid_600280 != nil:
    section.add "X-Amz-Target", valid_600280
  var valid_600281 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600281 = validateParameter(valid_600281, JString, required = false,
                                 default = nil)
  if valid_600281 != nil:
    section.add "X-Amz-Content-Sha256", valid_600281
  var valid_600282 = header.getOrDefault("X-Amz-Algorithm")
  valid_600282 = validateParameter(valid_600282, JString, required = false,
                                 default = nil)
  if valid_600282 != nil:
    section.add "X-Amz-Algorithm", valid_600282
  var valid_600283 = header.getOrDefault("X-Amz-Signature")
  valid_600283 = validateParameter(valid_600283, JString, required = false,
                                 default = nil)
  if valid_600283 != nil:
    section.add "X-Amz-Signature", valid_600283
  var valid_600284 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600284 = validateParameter(valid_600284, JString, required = false,
                                 default = nil)
  if valid_600284 != nil:
    section.add "X-Amz-SignedHeaders", valid_600284
  var valid_600285 = header.getOrDefault("X-Amz-Credential")
  valid_600285 = validateParameter(valid_600285, JString, required = false,
                                 default = nil)
  if valid_600285 != nil:
    section.add "X-Amz-Credential", valid_600285
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600287: Call_DeleteSnapshotSchedule_600275; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a snapshot of a volume.</p> <p>You can take snapshots of your gateway volumes on a scheduled or ad hoc basis. This API action enables you to delete a snapshot schedule for a volume. For more information, see <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/WorkingWithSnapshots.html">Working with Snapshots</a>. In the <code>DeleteSnapshotSchedule</code> request, you identify the volume by providing its Amazon Resource Name (ARN). This operation is only supported in stored and cached volume gateway types.</p> <note> <p>To list or delete a snapshot, you must use the Amazon EC2 API. in <i>Amazon Elastic Compute Cloud API Reference</i>.</p> </note>
  ## 
  let valid = call_600287.validator(path, query, header, formData, body)
  let scheme = call_600287.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600287.url(scheme.get, call_600287.host, call_600287.base,
                         call_600287.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600287, url, valid)

proc call*(call_600288: Call_DeleteSnapshotSchedule_600275; body: JsonNode): Recallable =
  ## deleteSnapshotSchedule
  ## <p>Deletes a snapshot of a volume.</p> <p>You can take snapshots of your gateway volumes on a scheduled or ad hoc basis. This API action enables you to delete a snapshot schedule for a volume. For more information, see <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/WorkingWithSnapshots.html">Working with Snapshots</a>. In the <code>DeleteSnapshotSchedule</code> request, you identify the volume by providing its Amazon Resource Name (ARN). This operation is only supported in stored and cached volume gateway types.</p> <note> <p>To list or delete a snapshot, you must use the Amazon EC2 API. in <i>Amazon Elastic Compute Cloud API Reference</i>.</p> </note>
  ##   body: JObject (required)
  var body_600289 = newJObject()
  if body != nil:
    body_600289 = body
  result = call_600288.call(nil, nil, nil, nil, body_600289)

var deleteSnapshotSchedule* = Call_DeleteSnapshotSchedule_600275(
    name: "deleteSnapshotSchedule", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DeleteSnapshotSchedule",
    validator: validate_DeleteSnapshotSchedule_600276, base: "/",
    url: url_DeleteSnapshotSchedule_600277, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTape_600290 = ref object of OpenApiRestCall_599369
proc url_DeleteTape_600292(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteTape_600291(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600293 = header.getOrDefault("X-Amz-Date")
  valid_600293 = validateParameter(valid_600293, JString, required = false,
                                 default = nil)
  if valid_600293 != nil:
    section.add "X-Amz-Date", valid_600293
  var valid_600294 = header.getOrDefault("X-Amz-Security-Token")
  valid_600294 = validateParameter(valid_600294, JString, required = false,
                                 default = nil)
  if valid_600294 != nil:
    section.add "X-Amz-Security-Token", valid_600294
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600295 = header.getOrDefault("X-Amz-Target")
  valid_600295 = validateParameter(valid_600295, JString, required = true, default = newJString(
      "StorageGateway_20130630.DeleteTape"))
  if valid_600295 != nil:
    section.add "X-Amz-Target", valid_600295
  var valid_600296 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600296 = validateParameter(valid_600296, JString, required = false,
                                 default = nil)
  if valid_600296 != nil:
    section.add "X-Amz-Content-Sha256", valid_600296
  var valid_600297 = header.getOrDefault("X-Amz-Algorithm")
  valid_600297 = validateParameter(valid_600297, JString, required = false,
                                 default = nil)
  if valid_600297 != nil:
    section.add "X-Amz-Algorithm", valid_600297
  var valid_600298 = header.getOrDefault("X-Amz-Signature")
  valid_600298 = validateParameter(valid_600298, JString, required = false,
                                 default = nil)
  if valid_600298 != nil:
    section.add "X-Amz-Signature", valid_600298
  var valid_600299 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600299 = validateParameter(valid_600299, JString, required = false,
                                 default = nil)
  if valid_600299 != nil:
    section.add "X-Amz-SignedHeaders", valid_600299
  var valid_600300 = header.getOrDefault("X-Amz-Credential")
  valid_600300 = validateParameter(valid_600300, JString, required = false,
                                 default = nil)
  if valid_600300 != nil:
    section.add "X-Amz-Credential", valid_600300
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600302: Call_DeleteTape_600290; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified virtual tape. This operation is only supported in the tape gateway type.
  ## 
  let valid = call_600302.validator(path, query, header, formData, body)
  let scheme = call_600302.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600302.url(scheme.get, call_600302.host, call_600302.base,
                         call_600302.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600302, url, valid)

proc call*(call_600303: Call_DeleteTape_600290; body: JsonNode): Recallable =
  ## deleteTape
  ## Deletes the specified virtual tape. This operation is only supported in the tape gateway type.
  ##   body: JObject (required)
  var body_600304 = newJObject()
  if body != nil:
    body_600304 = body
  result = call_600303.call(nil, nil, nil, nil, body_600304)

var deleteTape* = Call_DeleteTape_600290(name: "deleteTape",
                                      meth: HttpMethod.HttpPost,
                                      host: "storagegateway.amazonaws.com", route: "/#X-Amz-Target=StorageGateway_20130630.DeleteTape",
                                      validator: validate_DeleteTape_600291,
                                      base: "/", url: url_DeleteTape_600292,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTapeArchive_600305 = ref object of OpenApiRestCall_599369
proc url_DeleteTapeArchive_600307(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteTapeArchive_600306(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  var valid_600308 = header.getOrDefault("X-Amz-Date")
  valid_600308 = validateParameter(valid_600308, JString, required = false,
                                 default = nil)
  if valid_600308 != nil:
    section.add "X-Amz-Date", valid_600308
  var valid_600309 = header.getOrDefault("X-Amz-Security-Token")
  valid_600309 = validateParameter(valid_600309, JString, required = false,
                                 default = nil)
  if valid_600309 != nil:
    section.add "X-Amz-Security-Token", valid_600309
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600310 = header.getOrDefault("X-Amz-Target")
  valid_600310 = validateParameter(valid_600310, JString, required = true, default = newJString(
      "StorageGateway_20130630.DeleteTapeArchive"))
  if valid_600310 != nil:
    section.add "X-Amz-Target", valid_600310
  var valid_600311 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600311 = validateParameter(valid_600311, JString, required = false,
                                 default = nil)
  if valid_600311 != nil:
    section.add "X-Amz-Content-Sha256", valid_600311
  var valid_600312 = header.getOrDefault("X-Amz-Algorithm")
  valid_600312 = validateParameter(valid_600312, JString, required = false,
                                 default = nil)
  if valid_600312 != nil:
    section.add "X-Amz-Algorithm", valid_600312
  var valid_600313 = header.getOrDefault("X-Amz-Signature")
  valid_600313 = validateParameter(valid_600313, JString, required = false,
                                 default = nil)
  if valid_600313 != nil:
    section.add "X-Amz-Signature", valid_600313
  var valid_600314 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600314 = validateParameter(valid_600314, JString, required = false,
                                 default = nil)
  if valid_600314 != nil:
    section.add "X-Amz-SignedHeaders", valid_600314
  var valid_600315 = header.getOrDefault("X-Amz-Credential")
  valid_600315 = validateParameter(valid_600315, JString, required = false,
                                 default = nil)
  if valid_600315 != nil:
    section.add "X-Amz-Credential", valid_600315
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600317: Call_DeleteTapeArchive_600305; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified virtual tape from the virtual tape shelf (VTS). This operation is only supported in the tape gateway type.
  ## 
  let valid = call_600317.validator(path, query, header, formData, body)
  let scheme = call_600317.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600317.url(scheme.get, call_600317.host, call_600317.base,
                         call_600317.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600317, url, valid)

proc call*(call_600318: Call_DeleteTapeArchive_600305; body: JsonNode): Recallable =
  ## deleteTapeArchive
  ## Deletes the specified virtual tape from the virtual tape shelf (VTS). This operation is only supported in the tape gateway type.
  ##   body: JObject (required)
  var body_600319 = newJObject()
  if body != nil:
    body_600319 = body
  result = call_600318.call(nil, nil, nil, nil, body_600319)

var deleteTapeArchive* = Call_DeleteTapeArchive_600305(name: "deleteTapeArchive",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DeleteTapeArchive",
    validator: validate_DeleteTapeArchive_600306, base: "/",
    url: url_DeleteTapeArchive_600307, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVolume_600320 = ref object of OpenApiRestCall_599369
proc url_DeleteVolume_600322(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteVolume_600321(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600323 = header.getOrDefault("X-Amz-Date")
  valid_600323 = validateParameter(valid_600323, JString, required = false,
                                 default = nil)
  if valid_600323 != nil:
    section.add "X-Amz-Date", valid_600323
  var valid_600324 = header.getOrDefault("X-Amz-Security-Token")
  valid_600324 = validateParameter(valid_600324, JString, required = false,
                                 default = nil)
  if valid_600324 != nil:
    section.add "X-Amz-Security-Token", valid_600324
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600325 = header.getOrDefault("X-Amz-Target")
  valid_600325 = validateParameter(valid_600325, JString, required = true, default = newJString(
      "StorageGateway_20130630.DeleteVolume"))
  if valid_600325 != nil:
    section.add "X-Amz-Target", valid_600325
  var valid_600326 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600326 = validateParameter(valid_600326, JString, required = false,
                                 default = nil)
  if valid_600326 != nil:
    section.add "X-Amz-Content-Sha256", valid_600326
  var valid_600327 = header.getOrDefault("X-Amz-Algorithm")
  valid_600327 = validateParameter(valid_600327, JString, required = false,
                                 default = nil)
  if valid_600327 != nil:
    section.add "X-Amz-Algorithm", valid_600327
  var valid_600328 = header.getOrDefault("X-Amz-Signature")
  valid_600328 = validateParameter(valid_600328, JString, required = false,
                                 default = nil)
  if valid_600328 != nil:
    section.add "X-Amz-Signature", valid_600328
  var valid_600329 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600329 = validateParameter(valid_600329, JString, required = false,
                                 default = nil)
  if valid_600329 != nil:
    section.add "X-Amz-SignedHeaders", valid_600329
  var valid_600330 = header.getOrDefault("X-Amz-Credential")
  valid_600330 = validateParameter(valid_600330, JString, required = false,
                                 default = nil)
  if valid_600330 != nil:
    section.add "X-Amz-Credential", valid_600330
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600332: Call_DeleteVolume_600320; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified storage volume that you previously created using the <a>CreateCachediSCSIVolume</a> or <a>CreateStorediSCSIVolume</a> API. This operation is only supported in the cached volume and stored volume types. For stored volume gateways, the local disk that was configured as the storage volume is not deleted. You can reuse the local disk to create another storage volume. </p> <p>Before you delete a volume, make sure there are no iSCSI connections to the volume you are deleting. You should also make sure there is no snapshot in progress. You can use the Amazon Elastic Compute Cloud (Amazon EC2) API to query snapshots on the volume you are deleting and check the snapshot status. For more information, go to <a href="https://docs.aws.amazon.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeSnapshots.html">DescribeSnapshots</a> in the <i>Amazon Elastic Compute Cloud API Reference</i>.</p> <p>In the request, you must provide the Amazon Resource Name (ARN) of the storage volume you want to delete.</p>
  ## 
  let valid = call_600332.validator(path, query, header, formData, body)
  let scheme = call_600332.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600332.url(scheme.get, call_600332.host, call_600332.base,
                         call_600332.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600332, url, valid)

proc call*(call_600333: Call_DeleteVolume_600320; body: JsonNode): Recallable =
  ## deleteVolume
  ## <p>Deletes the specified storage volume that you previously created using the <a>CreateCachediSCSIVolume</a> or <a>CreateStorediSCSIVolume</a> API. This operation is only supported in the cached volume and stored volume types. For stored volume gateways, the local disk that was configured as the storage volume is not deleted. You can reuse the local disk to create another storage volume. </p> <p>Before you delete a volume, make sure there are no iSCSI connections to the volume you are deleting. You should also make sure there is no snapshot in progress. You can use the Amazon Elastic Compute Cloud (Amazon EC2) API to query snapshots on the volume you are deleting and check the snapshot status. For more information, go to <a href="https://docs.aws.amazon.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeSnapshots.html">DescribeSnapshots</a> in the <i>Amazon Elastic Compute Cloud API Reference</i>.</p> <p>In the request, you must provide the Amazon Resource Name (ARN) of the storage volume you want to delete.</p>
  ##   body: JObject (required)
  var body_600334 = newJObject()
  if body != nil:
    body_600334 = body
  result = call_600333.call(nil, nil, nil, nil, body_600334)

var deleteVolume* = Call_DeleteVolume_600320(name: "deleteVolume",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DeleteVolume",
    validator: validate_DeleteVolume_600321, base: "/", url: url_DeleteVolume_600322,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAvailabilityMonitorTest_600335 = ref object of OpenApiRestCall_599369
proc url_DescribeAvailabilityMonitorTest_600337(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeAvailabilityMonitorTest_600336(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600338 = header.getOrDefault("X-Amz-Date")
  valid_600338 = validateParameter(valid_600338, JString, required = false,
                                 default = nil)
  if valid_600338 != nil:
    section.add "X-Amz-Date", valid_600338
  var valid_600339 = header.getOrDefault("X-Amz-Security-Token")
  valid_600339 = validateParameter(valid_600339, JString, required = false,
                                 default = nil)
  if valid_600339 != nil:
    section.add "X-Amz-Security-Token", valid_600339
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600340 = header.getOrDefault("X-Amz-Target")
  valid_600340 = validateParameter(valid_600340, JString, required = true, default = newJString(
      "StorageGateway_20130630.DescribeAvailabilityMonitorTest"))
  if valid_600340 != nil:
    section.add "X-Amz-Target", valid_600340
  var valid_600341 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600341 = validateParameter(valid_600341, JString, required = false,
                                 default = nil)
  if valid_600341 != nil:
    section.add "X-Amz-Content-Sha256", valid_600341
  var valid_600342 = header.getOrDefault("X-Amz-Algorithm")
  valid_600342 = validateParameter(valid_600342, JString, required = false,
                                 default = nil)
  if valid_600342 != nil:
    section.add "X-Amz-Algorithm", valid_600342
  var valid_600343 = header.getOrDefault("X-Amz-Signature")
  valid_600343 = validateParameter(valid_600343, JString, required = false,
                                 default = nil)
  if valid_600343 != nil:
    section.add "X-Amz-Signature", valid_600343
  var valid_600344 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600344 = validateParameter(valid_600344, JString, required = false,
                                 default = nil)
  if valid_600344 != nil:
    section.add "X-Amz-SignedHeaders", valid_600344
  var valid_600345 = header.getOrDefault("X-Amz-Credential")
  valid_600345 = validateParameter(valid_600345, JString, required = false,
                                 default = nil)
  if valid_600345 != nil:
    section.add "X-Amz-Credential", valid_600345
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600347: Call_DescribeAvailabilityMonitorTest_600335;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns information about the most recent High Availability monitoring test that was performed on the host in a cluster. If a test isn't performed, the status and start time in the response would be null.
  ## 
  let valid = call_600347.validator(path, query, header, formData, body)
  let scheme = call_600347.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600347.url(scheme.get, call_600347.host, call_600347.base,
                         call_600347.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600347, url, valid)

proc call*(call_600348: Call_DescribeAvailabilityMonitorTest_600335; body: JsonNode): Recallable =
  ## describeAvailabilityMonitorTest
  ## Returns information about the most recent High Availability monitoring test that was performed on the host in a cluster. If a test isn't performed, the status and start time in the response would be null.
  ##   body: JObject (required)
  var body_600349 = newJObject()
  if body != nil:
    body_600349 = body
  result = call_600348.call(nil, nil, nil, nil, body_600349)

var describeAvailabilityMonitorTest* = Call_DescribeAvailabilityMonitorTest_600335(
    name: "describeAvailabilityMonitorTest", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com", route: "/#X-Amz-Target=StorageGateway_20130630.DescribeAvailabilityMonitorTest",
    validator: validate_DescribeAvailabilityMonitorTest_600336, base: "/",
    url: url_DescribeAvailabilityMonitorTest_600337,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBandwidthRateLimit_600350 = ref object of OpenApiRestCall_599369
proc url_DescribeBandwidthRateLimit_600352(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeBandwidthRateLimit_600351(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600353 = header.getOrDefault("X-Amz-Date")
  valid_600353 = validateParameter(valid_600353, JString, required = false,
                                 default = nil)
  if valid_600353 != nil:
    section.add "X-Amz-Date", valid_600353
  var valid_600354 = header.getOrDefault("X-Amz-Security-Token")
  valid_600354 = validateParameter(valid_600354, JString, required = false,
                                 default = nil)
  if valid_600354 != nil:
    section.add "X-Amz-Security-Token", valid_600354
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600355 = header.getOrDefault("X-Amz-Target")
  valid_600355 = validateParameter(valid_600355, JString, required = true, default = newJString(
      "StorageGateway_20130630.DescribeBandwidthRateLimit"))
  if valid_600355 != nil:
    section.add "X-Amz-Target", valid_600355
  var valid_600356 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600356 = validateParameter(valid_600356, JString, required = false,
                                 default = nil)
  if valid_600356 != nil:
    section.add "X-Amz-Content-Sha256", valid_600356
  var valid_600357 = header.getOrDefault("X-Amz-Algorithm")
  valid_600357 = validateParameter(valid_600357, JString, required = false,
                                 default = nil)
  if valid_600357 != nil:
    section.add "X-Amz-Algorithm", valid_600357
  var valid_600358 = header.getOrDefault("X-Amz-Signature")
  valid_600358 = validateParameter(valid_600358, JString, required = false,
                                 default = nil)
  if valid_600358 != nil:
    section.add "X-Amz-Signature", valid_600358
  var valid_600359 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600359 = validateParameter(valid_600359, JString, required = false,
                                 default = nil)
  if valid_600359 != nil:
    section.add "X-Amz-SignedHeaders", valid_600359
  var valid_600360 = header.getOrDefault("X-Amz-Credential")
  valid_600360 = validateParameter(valid_600360, JString, required = false,
                                 default = nil)
  if valid_600360 != nil:
    section.add "X-Amz-Credential", valid_600360
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600362: Call_DescribeBandwidthRateLimit_600350; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the bandwidth rate limits of a gateway. By default, these limits are not set, which means no bandwidth rate limiting is in effect. This operation is supported for the stored volume, cached volume and tape gateway types.'</p> <p>This operation only returns a value for a bandwidth rate limit only if the limit is set. If no limits are set for the gateway, then this operation returns only the gateway ARN in the response body. To specify which gateway to describe, use the Amazon Resource Name (ARN) of the gateway in your request.</p>
  ## 
  let valid = call_600362.validator(path, query, header, formData, body)
  let scheme = call_600362.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600362.url(scheme.get, call_600362.host, call_600362.base,
                         call_600362.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600362, url, valid)

proc call*(call_600363: Call_DescribeBandwidthRateLimit_600350; body: JsonNode): Recallable =
  ## describeBandwidthRateLimit
  ## <p>Returns the bandwidth rate limits of a gateway. By default, these limits are not set, which means no bandwidth rate limiting is in effect. This operation is supported for the stored volume, cached volume and tape gateway types.'</p> <p>This operation only returns a value for a bandwidth rate limit only if the limit is set. If no limits are set for the gateway, then this operation returns only the gateway ARN in the response body. To specify which gateway to describe, use the Amazon Resource Name (ARN) of the gateway in your request.</p>
  ##   body: JObject (required)
  var body_600364 = newJObject()
  if body != nil:
    body_600364 = body
  result = call_600363.call(nil, nil, nil, nil, body_600364)

var describeBandwidthRateLimit* = Call_DescribeBandwidthRateLimit_600350(
    name: "describeBandwidthRateLimit", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeBandwidthRateLimit",
    validator: validate_DescribeBandwidthRateLimit_600351, base: "/",
    url: url_DescribeBandwidthRateLimit_600352,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCache_600365 = ref object of OpenApiRestCall_599369
proc url_DescribeCache_600367(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeCache_600366(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600368 = header.getOrDefault("X-Amz-Date")
  valid_600368 = validateParameter(valid_600368, JString, required = false,
                                 default = nil)
  if valid_600368 != nil:
    section.add "X-Amz-Date", valid_600368
  var valid_600369 = header.getOrDefault("X-Amz-Security-Token")
  valid_600369 = validateParameter(valid_600369, JString, required = false,
                                 default = nil)
  if valid_600369 != nil:
    section.add "X-Amz-Security-Token", valid_600369
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600370 = header.getOrDefault("X-Amz-Target")
  valid_600370 = validateParameter(valid_600370, JString, required = true, default = newJString(
      "StorageGateway_20130630.DescribeCache"))
  if valid_600370 != nil:
    section.add "X-Amz-Target", valid_600370
  var valid_600371 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600371 = validateParameter(valid_600371, JString, required = false,
                                 default = nil)
  if valid_600371 != nil:
    section.add "X-Amz-Content-Sha256", valid_600371
  var valid_600372 = header.getOrDefault("X-Amz-Algorithm")
  valid_600372 = validateParameter(valid_600372, JString, required = false,
                                 default = nil)
  if valid_600372 != nil:
    section.add "X-Amz-Algorithm", valid_600372
  var valid_600373 = header.getOrDefault("X-Amz-Signature")
  valid_600373 = validateParameter(valid_600373, JString, required = false,
                                 default = nil)
  if valid_600373 != nil:
    section.add "X-Amz-Signature", valid_600373
  var valid_600374 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600374 = validateParameter(valid_600374, JString, required = false,
                                 default = nil)
  if valid_600374 != nil:
    section.add "X-Amz-SignedHeaders", valid_600374
  var valid_600375 = header.getOrDefault("X-Amz-Credential")
  valid_600375 = validateParameter(valid_600375, JString, required = false,
                                 default = nil)
  if valid_600375 != nil:
    section.add "X-Amz-Credential", valid_600375
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600377: Call_DescribeCache_600365; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about the cache of a gateway. This operation is only supported in the cached volume, tape and file gateway types.</p> <p>The response includes disk IDs that are configured as cache, and it includes the amount of cache allocated and used.</p>
  ## 
  let valid = call_600377.validator(path, query, header, formData, body)
  let scheme = call_600377.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600377.url(scheme.get, call_600377.host, call_600377.base,
                         call_600377.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600377, url, valid)

proc call*(call_600378: Call_DescribeCache_600365; body: JsonNode): Recallable =
  ## describeCache
  ## <p>Returns information about the cache of a gateway. This operation is only supported in the cached volume, tape and file gateway types.</p> <p>The response includes disk IDs that are configured as cache, and it includes the amount of cache allocated and used.</p>
  ##   body: JObject (required)
  var body_600379 = newJObject()
  if body != nil:
    body_600379 = body
  result = call_600378.call(nil, nil, nil, nil, body_600379)

var describeCache* = Call_DescribeCache_600365(name: "describeCache",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeCache",
    validator: validate_DescribeCache_600366, base: "/", url: url_DescribeCache_600367,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCachediSCSIVolumes_600380 = ref object of OpenApiRestCall_599369
proc url_DescribeCachediSCSIVolumes_600382(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeCachediSCSIVolumes_600381(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600383 = header.getOrDefault("X-Amz-Date")
  valid_600383 = validateParameter(valid_600383, JString, required = false,
                                 default = nil)
  if valid_600383 != nil:
    section.add "X-Amz-Date", valid_600383
  var valid_600384 = header.getOrDefault("X-Amz-Security-Token")
  valid_600384 = validateParameter(valid_600384, JString, required = false,
                                 default = nil)
  if valid_600384 != nil:
    section.add "X-Amz-Security-Token", valid_600384
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600385 = header.getOrDefault("X-Amz-Target")
  valid_600385 = validateParameter(valid_600385, JString, required = true, default = newJString(
      "StorageGateway_20130630.DescribeCachediSCSIVolumes"))
  if valid_600385 != nil:
    section.add "X-Amz-Target", valid_600385
  var valid_600386 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600386 = validateParameter(valid_600386, JString, required = false,
                                 default = nil)
  if valid_600386 != nil:
    section.add "X-Amz-Content-Sha256", valid_600386
  var valid_600387 = header.getOrDefault("X-Amz-Algorithm")
  valid_600387 = validateParameter(valid_600387, JString, required = false,
                                 default = nil)
  if valid_600387 != nil:
    section.add "X-Amz-Algorithm", valid_600387
  var valid_600388 = header.getOrDefault("X-Amz-Signature")
  valid_600388 = validateParameter(valid_600388, JString, required = false,
                                 default = nil)
  if valid_600388 != nil:
    section.add "X-Amz-Signature", valid_600388
  var valid_600389 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600389 = validateParameter(valid_600389, JString, required = false,
                                 default = nil)
  if valid_600389 != nil:
    section.add "X-Amz-SignedHeaders", valid_600389
  var valid_600390 = header.getOrDefault("X-Amz-Credential")
  valid_600390 = validateParameter(valid_600390, JString, required = false,
                                 default = nil)
  if valid_600390 != nil:
    section.add "X-Amz-Credential", valid_600390
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600392: Call_DescribeCachediSCSIVolumes_600380; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a description of the gateway volumes specified in the request. This operation is only supported in the cached volume gateway types.</p> <p>The list of gateway volumes in the request must be from one gateway. In the response Amazon Storage Gateway returns volume information sorted by volume Amazon Resource Name (ARN).</p>
  ## 
  let valid = call_600392.validator(path, query, header, formData, body)
  let scheme = call_600392.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600392.url(scheme.get, call_600392.host, call_600392.base,
                         call_600392.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600392, url, valid)

proc call*(call_600393: Call_DescribeCachediSCSIVolumes_600380; body: JsonNode): Recallable =
  ## describeCachediSCSIVolumes
  ## <p>Returns a description of the gateway volumes specified in the request. This operation is only supported in the cached volume gateway types.</p> <p>The list of gateway volumes in the request must be from one gateway. In the response Amazon Storage Gateway returns volume information sorted by volume Amazon Resource Name (ARN).</p>
  ##   body: JObject (required)
  var body_600394 = newJObject()
  if body != nil:
    body_600394 = body
  result = call_600393.call(nil, nil, nil, nil, body_600394)

var describeCachediSCSIVolumes* = Call_DescribeCachediSCSIVolumes_600380(
    name: "describeCachediSCSIVolumes", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeCachediSCSIVolumes",
    validator: validate_DescribeCachediSCSIVolumes_600381, base: "/",
    url: url_DescribeCachediSCSIVolumes_600382,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeChapCredentials_600395 = ref object of OpenApiRestCall_599369
proc url_DescribeChapCredentials_600397(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeChapCredentials_600396(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600398 = header.getOrDefault("X-Amz-Date")
  valid_600398 = validateParameter(valid_600398, JString, required = false,
                                 default = nil)
  if valid_600398 != nil:
    section.add "X-Amz-Date", valid_600398
  var valid_600399 = header.getOrDefault("X-Amz-Security-Token")
  valid_600399 = validateParameter(valid_600399, JString, required = false,
                                 default = nil)
  if valid_600399 != nil:
    section.add "X-Amz-Security-Token", valid_600399
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600400 = header.getOrDefault("X-Amz-Target")
  valid_600400 = validateParameter(valid_600400, JString, required = true, default = newJString(
      "StorageGateway_20130630.DescribeChapCredentials"))
  if valid_600400 != nil:
    section.add "X-Amz-Target", valid_600400
  var valid_600401 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600401 = validateParameter(valid_600401, JString, required = false,
                                 default = nil)
  if valid_600401 != nil:
    section.add "X-Amz-Content-Sha256", valid_600401
  var valid_600402 = header.getOrDefault("X-Amz-Algorithm")
  valid_600402 = validateParameter(valid_600402, JString, required = false,
                                 default = nil)
  if valid_600402 != nil:
    section.add "X-Amz-Algorithm", valid_600402
  var valid_600403 = header.getOrDefault("X-Amz-Signature")
  valid_600403 = validateParameter(valid_600403, JString, required = false,
                                 default = nil)
  if valid_600403 != nil:
    section.add "X-Amz-Signature", valid_600403
  var valid_600404 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600404 = validateParameter(valid_600404, JString, required = false,
                                 default = nil)
  if valid_600404 != nil:
    section.add "X-Amz-SignedHeaders", valid_600404
  var valid_600405 = header.getOrDefault("X-Amz-Credential")
  valid_600405 = validateParameter(valid_600405, JString, required = false,
                                 default = nil)
  if valid_600405 != nil:
    section.add "X-Amz-Credential", valid_600405
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600407: Call_DescribeChapCredentials_600395; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of Challenge-Handshake Authentication Protocol (CHAP) credentials information for a specified iSCSI target, one for each target-initiator pair. This operation is supported in the volume and tape gateway types.
  ## 
  let valid = call_600407.validator(path, query, header, formData, body)
  let scheme = call_600407.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600407.url(scheme.get, call_600407.host, call_600407.base,
                         call_600407.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600407, url, valid)

proc call*(call_600408: Call_DescribeChapCredentials_600395; body: JsonNode): Recallable =
  ## describeChapCredentials
  ## Returns an array of Challenge-Handshake Authentication Protocol (CHAP) credentials information for a specified iSCSI target, one for each target-initiator pair. This operation is supported in the volume and tape gateway types.
  ##   body: JObject (required)
  var body_600409 = newJObject()
  if body != nil:
    body_600409 = body
  result = call_600408.call(nil, nil, nil, nil, body_600409)

var describeChapCredentials* = Call_DescribeChapCredentials_600395(
    name: "describeChapCredentials", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeChapCredentials",
    validator: validate_DescribeChapCredentials_600396, base: "/",
    url: url_DescribeChapCredentials_600397, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeGatewayInformation_600410 = ref object of OpenApiRestCall_599369
proc url_DescribeGatewayInformation_600412(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeGatewayInformation_600411(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600413 = header.getOrDefault("X-Amz-Date")
  valid_600413 = validateParameter(valid_600413, JString, required = false,
                                 default = nil)
  if valid_600413 != nil:
    section.add "X-Amz-Date", valid_600413
  var valid_600414 = header.getOrDefault("X-Amz-Security-Token")
  valid_600414 = validateParameter(valid_600414, JString, required = false,
                                 default = nil)
  if valid_600414 != nil:
    section.add "X-Amz-Security-Token", valid_600414
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600415 = header.getOrDefault("X-Amz-Target")
  valid_600415 = validateParameter(valid_600415, JString, required = true, default = newJString(
      "StorageGateway_20130630.DescribeGatewayInformation"))
  if valid_600415 != nil:
    section.add "X-Amz-Target", valid_600415
  var valid_600416 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600416 = validateParameter(valid_600416, JString, required = false,
                                 default = nil)
  if valid_600416 != nil:
    section.add "X-Amz-Content-Sha256", valid_600416
  var valid_600417 = header.getOrDefault("X-Amz-Algorithm")
  valid_600417 = validateParameter(valid_600417, JString, required = false,
                                 default = nil)
  if valid_600417 != nil:
    section.add "X-Amz-Algorithm", valid_600417
  var valid_600418 = header.getOrDefault("X-Amz-Signature")
  valid_600418 = validateParameter(valid_600418, JString, required = false,
                                 default = nil)
  if valid_600418 != nil:
    section.add "X-Amz-Signature", valid_600418
  var valid_600419 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600419 = validateParameter(valid_600419, JString, required = false,
                                 default = nil)
  if valid_600419 != nil:
    section.add "X-Amz-SignedHeaders", valid_600419
  var valid_600420 = header.getOrDefault("X-Amz-Credential")
  valid_600420 = validateParameter(valid_600420, JString, required = false,
                                 default = nil)
  if valid_600420 != nil:
    section.add "X-Amz-Credential", valid_600420
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600422: Call_DescribeGatewayInformation_600410; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata about a gateway such as its name, network interfaces, configured time zone, and the state (whether the gateway is running or not). To specify which gateway to describe, use the Amazon Resource Name (ARN) of the gateway in your request.
  ## 
  let valid = call_600422.validator(path, query, header, formData, body)
  let scheme = call_600422.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600422.url(scheme.get, call_600422.host, call_600422.base,
                         call_600422.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600422, url, valid)

proc call*(call_600423: Call_DescribeGatewayInformation_600410; body: JsonNode): Recallable =
  ## describeGatewayInformation
  ## Returns metadata about a gateway such as its name, network interfaces, configured time zone, and the state (whether the gateway is running or not). To specify which gateway to describe, use the Amazon Resource Name (ARN) of the gateway in your request.
  ##   body: JObject (required)
  var body_600424 = newJObject()
  if body != nil:
    body_600424 = body
  result = call_600423.call(nil, nil, nil, nil, body_600424)

var describeGatewayInformation* = Call_DescribeGatewayInformation_600410(
    name: "describeGatewayInformation", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeGatewayInformation",
    validator: validate_DescribeGatewayInformation_600411, base: "/",
    url: url_DescribeGatewayInformation_600412,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceStartTime_600425 = ref object of OpenApiRestCall_599369
proc url_DescribeMaintenanceStartTime_600427(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeMaintenanceStartTime_600426(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
      "StorageGateway_20130630.DescribeMaintenanceStartTime"))
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

proc call*(call_600437: Call_DescribeMaintenanceStartTime_600425; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns your gateway's weekly maintenance start time including the day and time of the week. Note that values are in terms of the gateway's time zone.
  ## 
  let valid = call_600437.validator(path, query, header, formData, body)
  let scheme = call_600437.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600437.url(scheme.get, call_600437.host, call_600437.base,
                         call_600437.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600437, url, valid)

proc call*(call_600438: Call_DescribeMaintenanceStartTime_600425; body: JsonNode): Recallable =
  ## describeMaintenanceStartTime
  ## Returns your gateway's weekly maintenance start time including the day and time of the week. Note that values are in terms of the gateway's time zone.
  ##   body: JObject (required)
  var body_600439 = newJObject()
  if body != nil:
    body_600439 = body
  result = call_600438.call(nil, nil, nil, nil, body_600439)

var describeMaintenanceStartTime* = Call_DescribeMaintenanceStartTime_600425(
    name: "describeMaintenanceStartTime", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com", route: "/#X-Amz-Target=StorageGateway_20130630.DescribeMaintenanceStartTime",
    validator: validate_DescribeMaintenanceStartTime_600426, base: "/",
    url: url_DescribeMaintenanceStartTime_600427,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeNFSFileShares_600440 = ref object of OpenApiRestCall_599369
proc url_DescribeNFSFileShares_600442(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeNFSFileShares_600441(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
      "StorageGateway_20130630.DescribeNFSFileShares"))
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

proc call*(call_600452: Call_DescribeNFSFileShares_600440; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a description for one or more Network File System (NFS) file shares from a file gateway. This operation is only supported for file gateways.
  ## 
  let valid = call_600452.validator(path, query, header, formData, body)
  let scheme = call_600452.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600452.url(scheme.get, call_600452.host, call_600452.base,
                         call_600452.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600452, url, valid)

proc call*(call_600453: Call_DescribeNFSFileShares_600440; body: JsonNode): Recallable =
  ## describeNFSFileShares
  ## Gets a description for one or more Network File System (NFS) file shares from a file gateway. This operation is only supported for file gateways.
  ##   body: JObject (required)
  var body_600454 = newJObject()
  if body != nil:
    body_600454 = body
  result = call_600453.call(nil, nil, nil, nil, body_600454)

var describeNFSFileShares* = Call_DescribeNFSFileShares_600440(
    name: "describeNFSFileShares", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeNFSFileShares",
    validator: validate_DescribeNFSFileShares_600441, base: "/",
    url: url_DescribeNFSFileShares_600442, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSMBFileShares_600455 = ref object of OpenApiRestCall_599369
proc url_DescribeSMBFileShares_600457(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeSMBFileShares_600456(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
      "StorageGateway_20130630.DescribeSMBFileShares"))
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

proc call*(call_600467: Call_DescribeSMBFileShares_600455; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a description for one or more Server Message Block (SMB) file shares from a file gateway. This operation is only supported for file gateways.
  ## 
  let valid = call_600467.validator(path, query, header, formData, body)
  let scheme = call_600467.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600467.url(scheme.get, call_600467.host, call_600467.base,
                         call_600467.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600467, url, valid)

proc call*(call_600468: Call_DescribeSMBFileShares_600455; body: JsonNode): Recallable =
  ## describeSMBFileShares
  ## Gets a description for one or more Server Message Block (SMB) file shares from a file gateway. This operation is only supported for file gateways.
  ##   body: JObject (required)
  var body_600469 = newJObject()
  if body != nil:
    body_600469 = body
  result = call_600468.call(nil, nil, nil, nil, body_600469)

var describeSMBFileShares* = Call_DescribeSMBFileShares_600455(
    name: "describeSMBFileShares", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeSMBFileShares",
    validator: validate_DescribeSMBFileShares_600456, base: "/",
    url: url_DescribeSMBFileShares_600457, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSMBSettings_600470 = ref object of OpenApiRestCall_599369
proc url_DescribeSMBSettings_600472(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeSMBSettings_600471(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
      "StorageGateway_20130630.DescribeSMBSettings"))
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

proc call*(call_600482: Call_DescribeSMBSettings_600470; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a description of a Server Message Block (SMB) file share settings from a file gateway. This operation is only supported for file gateways.
  ## 
  let valid = call_600482.validator(path, query, header, formData, body)
  let scheme = call_600482.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600482.url(scheme.get, call_600482.host, call_600482.base,
                         call_600482.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600482, url, valid)

proc call*(call_600483: Call_DescribeSMBSettings_600470; body: JsonNode): Recallable =
  ## describeSMBSettings
  ## Gets a description of a Server Message Block (SMB) file share settings from a file gateway. This operation is only supported for file gateways.
  ##   body: JObject (required)
  var body_600484 = newJObject()
  if body != nil:
    body_600484 = body
  result = call_600483.call(nil, nil, nil, nil, body_600484)

var describeSMBSettings* = Call_DescribeSMBSettings_600470(
    name: "describeSMBSettings", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeSMBSettings",
    validator: validate_DescribeSMBSettings_600471, base: "/",
    url: url_DescribeSMBSettings_600472, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSnapshotSchedule_600485 = ref object of OpenApiRestCall_599369
proc url_DescribeSnapshotSchedule_600487(protocol: Scheme; host: string;
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

proc validate_DescribeSnapshotSchedule_600486(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
      "StorageGateway_20130630.DescribeSnapshotSchedule"))
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

proc call*(call_600497: Call_DescribeSnapshotSchedule_600485; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the snapshot schedule for the specified gateway volume. The snapshot schedule information includes intervals at which snapshots are automatically initiated on the volume. This operation is only supported in the cached volume and stored volume types.
  ## 
  let valid = call_600497.validator(path, query, header, formData, body)
  let scheme = call_600497.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600497.url(scheme.get, call_600497.host, call_600497.base,
                         call_600497.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600497, url, valid)

proc call*(call_600498: Call_DescribeSnapshotSchedule_600485; body: JsonNode): Recallable =
  ## describeSnapshotSchedule
  ## Describes the snapshot schedule for the specified gateway volume. The snapshot schedule information includes intervals at which snapshots are automatically initiated on the volume. This operation is only supported in the cached volume and stored volume types.
  ##   body: JObject (required)
  var body_600499 = newJObject()
  if body != nil:
    body_600499 = body
  result = call_600498.call(nil, nil, nil, nil, body_600499)

var describeSnapshotSchedule* = Call_DescribeSnapshotSchedule_600485(
    name: "describeSnapshotSchedule", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeSnapshotSchedule",
    validator: validate_DescribeSnapshotSchedule_600486, base: "/",
    url: url_DescribeSnapshotSchedule_600487, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeStorediSCSIVolumes_600500 = ref object of OpenApiRestCall_599369
proc url_DescribeStorediSCSIVolumes_600502(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeStorediSCSIVolumes_600501(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
      "StorageGateway_20130630.DescribeStorediSCSIVolumes"))
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

proc call*(call_600512: Call_DescribeStorediSCSIVolumes_600500; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the description of the gateway volumes specified in the request. The list of gateway volumes in the request must be from one gateway. In the response Amazon Storage Gateway returns volume information sorted by volume ARNs. This operation is only supported in stored volume gateway type.
  ## 
  let valid = call_600512.validator(path, query, header, formData, body)
  let scheme = call_600512.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600512.url(scheme.get, call_600512.host, call_600512.base,
                         call_600512.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600512, url, valid)

proc call*(call_600513: Call_DescribeStorediSCSIVolumes_600500; body: JsonNode): Recallable =
  ## describeStorediSCSIVolumes
  ## Returns the description of the gateway volumes specified in the request. The list of gateway volumes in the request must be from one gateway. In the response Amazon Storage Gateway returns volume information sorted by volume ARNs. This operation is only supported in stored volume gateway type.
  ##   body: JObject (required)
  var body_600514 = newJObject()
  if body != nil:
    body_600514 = body
  result = call_600513.call(nil, nil, nil, nil, body_600514)

var describeStorediSCSIVolumes* = Call_DescribeStorediSCSIVolumes_600500(
    name: "describeStorediSCSIVolumes", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeStorediSCSIVolumes",
    validator: validate_DescribeStorediSCSIVolumes_600501, base: "/",
    url: url_DescribeStorediSCSIVolumes_600502,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTapeArchives_600515 = ref object of OpenApiRestCall_599369
proc url_DescribeTapeArchives_600517(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTapeArchives_600516(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600518 = query.getOrDefault("Limit")
  valid_600518 = validateParameter(valid_600518, JString, required = false,
                                 default = nil)
  if valid_600518 != nil:
    section.add "Limit", valid_600518
  var valid_600519 = query.getOrDefault("Marker")
  valid_600519 = validateParameter(valid_600519, JString, required = false,
                                 default = nil)
  if valid_600519 != nil:
    section.add "Marker", valid_600519
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600520 = header.getOrDefault("X-Amz-Date")
  valid_600520 = validateParameter(valid_600520, JString, required = false,
                                 default = nil)
  if valid_600520 != nil:
    section.add "X-Amz-Date", valid_600520
  var valid_600521 = header.getOrDefault("X-Amz-Security-Token")
  valid_600521 = validateParameter(valid_600521, JString, required = false,
                                 default = nil)
  if valid_600521 != nil:
    section.add "X-Amz-Security-Token", valid_600521
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600522 = header.getOrDefault("X-Amz-Target")
  valid_600522 = validateParameter(valid_600522, JString, required = true, default = newJString(
      "StorageGateway_20130630.DescribeTapeArchives"))
  if valid_600522 != nil:
    section.add "X-Amz-Target", valid_600522
  var valid_600523 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600523 = validateParameter(valid_600523, JString, required = false,
                                 default = nil)
  if valid_600523 != nil:
    section.add "X-Amz-Content-Sha256", valid_600523
  var valid_600524 = header.getOrDefault("X-Amz-Algorithm")
  valid_600524 = validateParameter(valid_600524, JString, required = false,
                                 default = nil)
  if valid_600524 != nil:
    section.add "X-Amz-Algorithm", valid_600524
  var valid_600525 = header.getOrDefault("X-Amz-Signature")
  valid_600525 = validateParameter(valid_600525, JString, required = false,
                                 default = nil)
  if valid_600525 != nil:
    section.add "X-Amz-Signature", valid_600525
  var valid_600526 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600526 = validateParameter(valid_600526, JString, required = false,
                                 default = nil)
  if valid_600526 != nil:
    section.add "X-Amz-SignedHeaders", valid_600526
  var valid_600527 = header.getOrDefault("X-Amz-Credential")
  valid_600527 = validateParameter(valid_600527, JString, required = false,
                                 default = nil)
  if valid_600527 != nil:
    section.add "X-Amz-Credential", valid_600527
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600529: Call_DescribeTapeArchives_600515; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a description of specified virtual tapes in the virtual tape shelf (VTS). This operation is only supported in the tape gateway type.</p> <p>If a specific <code>TapeARN</code> is not specified, AWS Storage Gateway returns a description of all virtual tapes found in the VTS associated with your account.</p>
  ## 
  let valid = call_600529.validator(path, query, header, formData, body)
  let scheme = call_600529.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600529.url(scheme.get, call_600529.host, call_600529.base,
                         call_600529.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600529, url, valid)

proc call*(call_600530: Call_DescribeTapeArchives_600515; body: JsonNode;
          Limit: string = ""; Marker: string = ""): Recallable =
  ## describeTapeArchives
  ## <p>Returns a description of specified virtual tapes in the virtual tape shelf (VTS). This operation is only supported in the tape gateway type.</p> <p>If a specific <code>TapeARN</code> is not specified, AWS Storage Gateway returns a description of all virtual tapes found in the VTS associated with your account.</p>
  ##   Limit: string
  ##        : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_600531 = newJObject()
  var body_600532 = newJObject()
  add(query_600531, "Limit", newJString(Limit))
  add(query_600531, "Marker", newJString(Marker))
  if body != nil:
    body_600532 = body
  result = call_600530.call(nil, query_600531, nil, nil, body_600532)

var describeTapeArchives* = Call_DescribeTapeArchives_600515(
    name: "describeTapeArchives", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeTapeArchives",
    validator: validate_DescribeTapeArchives_600516, base: "/",
    url: url_DescribeTapeArchives_600517, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTapeRecoveryPoints_600534 = ref object of OpenApiRestCall_599369
proc url_DescribeTapeRecoveryPoints_600536(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTapeRecoveryPoints_600535(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600537 = query.getOrDefault("Limit")
  valid_600537 = validateParameter(valid_600537, JString, required = false,
                                 default = nil)
  if valid_600537 != nil:
    section.add "Limit", valid_600537
  var valid_600538 = query.getOrDefault("Marker")
  valid_600538 = validateParameter(valid_600538, JString, required = false,
                                 default = nil)
  if valid_600538 != nil:
    section.add "Marker", valid_600538
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600539 = header.getOrDefault("X-Amz-Date")
  valid_600539 = validateParameter(valid_600539, JString, required = false,
                                 default = nil)
  if valid_600539 != nil:
    section.add "X-Amz-Date", valid_600539
  var valid_600540 = header.getOrDefault("X-Amz-Security-Token")
  valid_600540 = validateParameter(valid_600540, JString, required = false,
                                 default = nil)
  if valid_600540 != nil:
    section.add "X-Amz-Security-Token", valid_600540
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600541 = header.getOrDefault("X-Amz-Target")
  valid_600541 = validateParameter(valid_600541, JString, required = true, default = newJString(
      "StorageGateway_20130630.DescribeTapeRecoveryPoints"))
  if valid_600541 != nil:
    section.add "X-Amz-Target", valid_600541
  var valid_600542 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600542 = validateParameter(valid_600542, JString, required = false,
                                 default = nil)
  if valid_600542 != nil:
    section.add "X-Amz-Content-Sha256", valid_600542
  var valid_600543 = header.getOrDefault("X-Amz-Algorithm")
  valid_600543 = validateParameter(valid_600543, JString, required = false,
                                 default = nil)
  if valid_600543 != nil:
    section.add "X-Amz-Algorithm", valid_600543
  var valid_600544 = header.getOrDefault("X-Amz-Signature")
  valid_600544 = validateParameter(valid_600544, JString, required = false,
                                 default = nil)
  if valid_600544 != nil:
    section.add "X-Amz-Signature", valid_600544
  var valid_600545 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600545 = validateParameter(valid_600545, JString, required = false,
                                 default = nil)
  if valid_600545 != nil:
    section.add "X-Amz-SignedHeaders", valid_600545
  var valid_600546 = header.getOrDefault("X-Amz-Credential")
  valid_600546 = validateParameter(valid_600546, JString, required = false,
                                 default = nil)
  if valid_600546 != nil:
    section.add "X-Amz-Credential", valid_600546
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600548: Call_DescribeTapeRecoveryPoints_600534; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of virtual tape recovery points that are available for the specified tape gateway.</p> <p>A recovery point is a point-in-time view of a virtual tape at which all the data on the virtual tape is consistent. If your gateway crashes, virtual tapes that have recovery points can be recovered to a new gateway. This operation is only supported in the tape gateway type.</p>
  ## 
  let valid = call_600548.validator(path, query, header, formData, body)
  let scheme = call_600548.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600548.url(scheme.get, call_600548.host, call_600548.base,
                         call_600548.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600548, url, valid)

proc call*(call_600549: Call_DescribeTapeRecoveryPoints_600534; body: JsonNode;
          Limit: string = ""; Marker: string = ""): Recallable =
  ## describeTapeRecoveryPoints
  ## <p>Returns a list of virtual tape recovery points that are available for the specified tape gateway.</p> <p>A recovery point is a point-in-time view of a virtual tape at which all the data on the virtual tape is consistent. If your gateway crashes, virtual tapes that have recovery points can be recovered to a new gateway. This operation is only supported in the tape gateway type.</p>
  ##   Limit: string
  ##        : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_600550 = newJObject()
  var body_600551 = newJObject()
  add(query_600550, "Limit", newJString(Limit))
  add(query_600550, "Marker", newJString(Marker))
  if body != nil:
    body_600551 = body
  result = call_600549.call(nil, query_600550, nil, nil, body_600551)

var describeTapeRecoveryPoints* = Call_DescribeTapeRecoveryPoints_600534(
    name: "describeTapeRecoveryPoints", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeTapeRecoveryPoints",
    validator: validate_DescribeTapeRecoveryPoints_600535, base: "/",
    url: url_DescribeTapeRecoveryPoints_600536,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTapes_600552 = ref object of OpenApiRestCall_599369
proc url_DescribeTapes_600554(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTapes_600553(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600555 = query.getOrDefault("Limit")
  valid_600555 = validateParameter(valid_600555, JString, required = false,
                                 default = nil)
  if valid_600555 != nil:
    section.add "Limit", valid_600555
  var valid_600556 = query.getOrDefault("Marker")
  valid_600556 = validateParameter(valid_600556, JString, required = false,
                                 default = nil)
  if valid_600556 != nil:
    section.add "Marker", valid_600556
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600557 = header.getOrDefault("X-Amz-Date")
  valid_600557 = validateParameter(valid_600557, JString, required = false,
                                 default = nil)
  if valid_600557 != nil:
    section.add "X-Amz-Date", valid_600557
  var valid_600558 = header.getOrDefault("X-Amz-Security-Token")
  valid_600558 = validateParameter(valid_600558, JString, required = false,
                                 default = nil)
  if valid_600558 != nil:
    section.add "X-Amz-Security-Token", valid_600558
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600559 = header.getOrDefault("X-Amz-Target")
  valid_600559 = validateParameter(valid_600559, JString, required = true, default = newJString(
      "StorageGateway_20130630.DescribeTapes"))
  if valid_600559 != nil:
    section.add "X-Amz-Target", valid_600559
  var valid_600560 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600560 = validateParameter(valid_600560, JString, required = false,
                                 default = nil)
  if valid_600560 != nil:
    section.add "X-Amz-Content-Sha256", valid_600560
  var valid_600561 = header.getOrDefault("X-Amz-Algorithm")
  valid_600561 = validateParameter(valid_600561, JString, required = false,
                                 default = nil)
  if valid_600561 != nil:
    section.add "X-Amz-Algorithm", valid_600561
  var valid_600562 = header.getOrDefault("X-Amz-Signature")
  valid_600562 = validateParameter(valid_600562, JString, required = false,
                                 default = nil)
  if valid_600562 != nil:
    section.add "X-Amz-Signature", valid_600562
  var valid_600563 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600563 = validateParameter(valid_600563, JString, required = false,
                                 default = nil)
  if valid_600563 != nil:
    section.add "X-Amz-SignedHeaders", valid_600563
  var valid_600564 = header.getOrDefault("X-Amz-Credential")
  valid_600564 = validateParameter(valid_600564, JString, required = false,
                                 default = nil)
  if valid_600564 != nil:
    section.add "X-Amz-Credential", valid_600564
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600566: Call_DescribeTapes_600552; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a description of the specified Amazon Resource Name (ARN) of virtual tapes. If a <code>TapeARN</code> is not specified, returns a description of all virtual tapes associated with the specified gateway. This operation is only supported in the tape gateway type.
  ## 
  let valid = call_600566.validator(path, query, header, formData, body)
  let scheme = call_600566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600566.url(scheme.get, call_600566.host, call_600566.base,
                         call_600566.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600566, url, valid)

proc call*(call_600567: Call_DescribeTapes_600552; body: JsonNode;
          Limit: string = ""; Marker: string = ""): Recallable =
  ## describeTapes
  ## Returns a description of the specified Amazon Resource Name (ARN) of virtual tapes. If a <code>TapeARN</code> is not specified, returns a description of all virtual tapes associated with the specified gateway. This operation is only supported in the tape gateway type.
  ##   Limit: string
  ##        : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_600568 = newJObject()
  var body_600569 = newJObject()
  add(query_600568, "Limit", newJString(Limit))
  add(query_600568, "Marker", newJString(Marker))
  if body != nil:
    body_600569 = body
  result = call_600567.call(nil, query_600568, nil, nil, body_600569)

var describeTapes* = Call_DescribeTapes_600552(name: "describeTapes",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeTapes",
    validator: validate_DescribeTapes_600553, base: "/", url: url_DescribeTapes_600554,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUploadBuffer_600570 = ref object of OpenApiRestCall_599369
proc url_DescribeUploadBuffer_600572(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeUploadBuffer_600571(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600573 = header.getOrDefault("X-Amz-Date")
  valid_600573 = validateParameter(valid_600573, JString, required = false,
                                 default = nil)
  if valid_600573 != nil:
    section.add "X-Amz-Date", valid_600573
  var valid_600574 = header.getOrDefault("X-Amz-Security-Token")
  valid_600574 = validateParameter(valid_600574, JString, required = false,
                                 default = nil)
  if valid_600574 != nil:
    section.add "X-Amz-Security-Token", valid_600574
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600575 = header.getOrDefault("X-Amz-Target")
  valid_600575 = validateParameter(valid_600575, JString, required = true, default = newJString(
      "StorageGateway_20130630.DescribeUploadBuffer"))
  if valid_600575 != nil:
    section.add "X-Amz-Target", valid_600575
  var valid_600576 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600576 = validateParameter(valid_600576, JString, required = false,
                                 default = nil)
  if valid_600576 != nil:
    section.add "X-Amz-Content-Sha256", valid_600576
  var valid_600577 = header.getOrDefault("X-Amz-Algorithm")
  valid_600577 = validateParameter(valid_600577, JString, required = false,
                                 default = nil)
  if valid_600577 != nil:
    section.add "X-Amz-Algorithm", valid_600577
  var valid_600578 = header.getOrDefault("X-Amz-Signature")
  valid_600578 = validateParameter(valid_600578, JString, required = false,
                                 default = nil)
  if valid_600578 != nil:
    section.add "X-Amz-Signature", valid_600578
  var valid_600579 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600579 = validateParameter(valid_600579, JString, required = false,
                                 default = nil)
  if valid_600579 != nil:
    section.add "X-Amz-SignedHeaders", valid_600579
  var valid_600580 = header.getOrDefault("X-Amz-Credential")
  valid_600580 = validateParameter(valid_600580, JString, required = false,
                                 default = nil)
  if valid_600580 != nil:
    section.add "X-Amz-Credential", valid_600580
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600582: Call_DescribeUploadBuffer_600570; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about the upload buffer of a gateway. This operation is supported for the stored volume, cached volume and tape gateway types.</p> <p>The response includes disk IDs that are configured as upload buffer space, and it includes the amount of upload buffer space allocated and used.</p>
  ## 
  let valid = call_600582.validator(path, query, header, formData, body)
  let scheme = call_600582.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600582.url(scheme.get, call_600582.host, call_600582.base,
                         call_600582.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600582, url, valid)

proc call*(call_600583: Call_DescribeUploadBuffer_600570; body: JsonNode): Recallable =
  ## describeUploadBuffer
  ## <p>Returns information about the upload buffer of a gateway. This operation is supported for the stored volume, cached volume and tape gateway types.</p> <p>The response includes disk IDs that are configured as upload buffer space, and it includes the amount of upload buffer space allocated and used.</p>
  ##   body: JObject (required)
  var body_600584 = newJObject()
  if body != nil:
    body_600584 = body
  result = call_600583.call(nil, nil, nil, nil, body_600584)

var describeUploadBuffer* = Call_DescribeUploadBuffer_600570(
    name: "describeUploadBuffer", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeUploadBuffer",
    validator: validate_DescribeUploadBuffer_600571, base: "/",
    url: url_DescribeUploadBuffer_600572, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeVTLDevices_600585 = ref object of OpenApiRestCall_599369
proc url_DescribeVTLDevices_600587(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeVTLDevices_600586(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
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
  var valid_600588 = query.getOrDefault("Limit")
  valid_600588 = validateParameter(valid_600588, JString, required = false,
                                 default = nil)
  if valid_600588 != nil:
    section.add "Limit", valid_600588
  var valid_600589 = query.getOrDefault("Marker")
  valid_600589 = validateParameter(valid_600589, JString, required = false,
                                 default = nil)
  if valid_600589 != nil:
    section.add "Marker", valid_600589
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600590 = header.getOrDefault("X-Amz-Date")
  valid_600590 = validateParameter(valid_600590, JString, required = false,
                                 default = nil)
  if valid_600590 != nil:
    section.add "X-Amz-Date", valid_600590
  var valid_600591 = header.getOrDefault("X-Amz-Security-Token")
  valid_600591 = validateParameter(valid_600591, JString, required = false,
                                 default = nil)
  if valid_600591 != nil:
    section.add "X-Amz-Security-Token", valid_600591
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600592 = header.getOrDefault("X-Amz-Target")
  valid_600592 = validateParameter(valid_600592, JString, required = true, default = newJString(
      "StorageGateway_20130630.DescribeVTLDevices"))
  if valid_600592 != nil:
    section.add "X-Amz-Target", valid_600592
  var valid_600593 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600593 = validateParameter(valid_600593, JString, required = false,
                                 default = nil)
  if valid_600593 != nil:
    section.add "X-Amz-Content-Sha256", valid_600593
  var valid_600594 = header.getOrDefault("X-Amz-Algorithm")
  valid_600594 = validateParameter(valid_600594, JString, required = false,
                                 default = nil)
  if valid_600594 != nil:
    section.add "X-Amz-Algorithm", valid_600594
  var valid_600595 = header.getOrDefault("X-Amz-Signature")
  valid_600595 = validateParameter(valid_600595, JString, required = false,
                                 default = nil)
  if valid_600595 != nil:
    section.add "X-Amz-Signature", valid_600595
  var valid_600596 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600596 = validateParameter(valid_600596, JString, required = false,
                                 default = nil)
  if valid_600596 != nil:
    section.add "X-Amz-SignedHeaders", valid_600596
  var valid_600597 = header.getOrDefault("X-Amz-Credential")
  valid_600597 = validateParameter(valid_600597, JString, required = false,
                                 default = nil)
  if valid_600597 != nil:
    section.add "X-Amz-Credential", valid_600597
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600599: Call_DescribeVTLDevices_600585; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a description of virtual tape library (VTL) devices for the specified tape gateway. In the response, AWS Storage Gateway returns VTL device information.</p> <p>This operation is only supported in the tape gateway type.</p>
  ## 
  let valid = call_600599.validator(path, query, header, formData, body)
  let scheme = call_600599.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600599.url(scheme.get, call_600599.host, call_600599.base,
                         call_600599.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600599, url, valid)

proc call*(call_600600: Call_DescribeVTLDevices_600585; body: JsonNode;
          Limit: string = ""; Marker: string = ""): Recallable =
  ## describeVTLDevices
  ## <p>Returns a description of virtual tape library (VTL) devices for the specified tape gateway. In the response, AWS Storage Gateway returns VTL device information.</p> <p>This operation is only supported in the tape gateway type.</p>
  ##   Limit: string
  ##        : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_600601 = newJObject()
  var body_600602 = newJObject()
  add(query_600601, "Limit", newJString(Limit))
  add(query_600601, "Marker", newJString(Marker))
  if body != nil:
    body_600602 = body
  result = call_600600.call(nil, query_600601, nil, nil, body_600602)

var describeVTLDevices* = Call_DescribeVTLDevices_600585(
    name: "describeVTLDevices", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeVTLDevices",
    validator: validate_DescribeVTLDevices_600586, base: "/",
    url: url_DescribeVTLDevices_600587, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkingStorage_600603 = ref object of OpenApiRestCall_599369
proc url_DescribeWorkingStorage_600605(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeWorkingStorage_600604(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600606 = header.getOrDefault("X-Amz-Date")
  valid_600606 = validateParameter(valid_600606, JString, required = false,
                                 default = nil)
  if valid_600606 != nil:
    section.add "X-Amz-Date", valid_600606
  var valid_600607 = header.getOrDefault("X-Amz-Security-Token")
  valid_600607 = validateParameter(valid_600607, JString, required = false,
                                 default = nil)
  if valid_600607 != nil:
    section.add "X-Amz-Security-Token", valid_600607
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600608 = header.getOrDefault("X-Amz-Target")
  valid_600608 = validateParameter(valid_600608, JString, required = true, default = newJString(
      "StorageGateway_20130630.DescribeWorkingStorage"))
  if valid_600608 != nil:
    section.add "X-Amz-Target", valid_600608
  var valid_600609 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600609 = validateParameter(valid_600609, JString, required = false,
                                 default = nil)
  if valid_600609 != nil:
    section.add "X-Amz-Content-Sha256", valid_600609
  var valid_600610 = header.getOrDefault("X-Amz-Algorithm")
  valid_600610 = validateParameter(valid_600610, JString, required = false,
                                 default = nil)
  if valid_600610 != nil:
    section.add "X-Amz-Algorithm", valid_600610
  var valid_600611 = header.getOrDefault("X-Amz-Signature")
  valid_600611 = validateParameter(valid_600611, JString, required = false,
                                 default = nil)
  if valid_600611 != nil:
    section.add "X-Amz-Signature", valid_600611
  var valid_600612 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600612 = validateParameter(valid_600612, JString, required = false,
                                 default = nil)
  if valid_600612 != nil:
    section.add "X-Amz-SignedHeaders", valid_600612
  var valid_600613 = header.getOrDefault("X-Amz-Credential")
  valid_600613 = validateParameter(valid_600613, JString, required = false,
                                 default = nil)
  if valid_600613 != nil:
    section.add "X-Amz-Credential", valid_600613
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600615: Call_DescribeWorkingStorage_600603; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about the working storage of a gateway. This operation is only supported in the stored volumes gateway type. This operation is deprecated in cached volumes API version (20120630). Use DescribeUploadBuffer instead.</p> <note> <p>Working storage is also referred to as upload buffer. You can also use the DescribeUploadBuffer operation to add upload buffer to a stored volume gateway.</p> </note> <p>The response includes disk IDs that are configured as working storage, and it includes the amount of working storage allocated and used.</p>
  ## 
  let valid = call_600615.validator(path, query, header, formData, body)
  let scheme = call_600615.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600615.url(scheme.get, call_600615.host, call_600615.base,
                         call_600615.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600615, url, valid)

proc call*(call_600616: Call_DescribeWorkingStorage_600603; body: JsonNode): Recallable =
  ## describeWorkingStorage
  ## <p>Returns information about the working storage of a gateway. This operation is only supported in the stored volumes gateway type. This operation is deprecated in cached volumes API version (20120630). Use DescribeUploadBuffer instead.</p> <note> <p>Working storage is also referred to as upload buffer. You can also use the DescribeUploadBuffer operation to add upload buffer to a stored volume gateway.</p> </note> <p>The response includes disk IDs that are configured as working storage, and it includes the amount of working storage allocated and used.</p>
  ##   body: JObject (required)
  var body_600617 = newJObject()
  if body != nil:
    body_600617 = body
  result = call_600616.call(nil, nil, nil, nil, body_600617)

var describeWorkingStorage* = Call_DescribeWorkingStorage_600603(
    name: "describeWorkingStorage", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeWorkingStorage",
    validator: validate_DescribeWorkingStorage_600604, base: "/",
    url: url_DescribeWorkingStorage_600605, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachVolume_600618 = ref object of OpenApiRestCall_599369
proc url_DetachVolume_600620(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DetachVolume_600619(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600621 = header.getOrDefault("X-Amz-Date")
  valid_600621 = validateParameter(valid_600621, JString, required = false,
                                 default = nil)
  if valid_600621 != nil:
    section.add "X-Amz-Date", valid_600621
  var valid_600622 = header.getOrDefault("X-Amz-Security-Token")
  valid_600622 = validateParameter(valid_600622, JString, required = false,
                                 default = nil)
  if valid_600622 != nil:
    section.add "X-Amz-Security-Token", valid_600622
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600623 = header.getOrDefault("X-Amz-Target")
  valid_600623 = validateParameter(valid_600623, JString, required = true, default = newJString(
      "StorageGateway_20130630.DetachVolume"))
  if valid_600623 != nil:
    section.add "X-Amz-Target", valid_600623
  var valid_600624 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600624 = validateParameter(valid_600624, JString, required = false,
                                 default = nil)
  if valid_600624 != nil:
    section.add "X-Amz-Content-Sha256", valid_600624
  var valid_600625 = header.getOrDefault("X-Amz-Algorithm")
  valid_600625 = validateParameter(valid_600625, JString, required = false,
                                 default = nil)
  if valid_600625 != nil:
    section.add "X-Amz-Algorithm", valid_600625
  var valid_600626 = header.getOrDefault("X-Amz-Signature")
  valid_600626 = validateParameter(valid_600626, JString, required = false,
                                 default = nil)
  if valid_600626 != nil:
    section.add "X-Amz-Signature", valid_600626
  var valid_600627 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600627 = validateParameter(valid_600627, JString, required = false,
                                 default = nil)
  if valid_600627 != nil:
    section.add "X-Amz-SignedHeaders", valid_600627
  var valid_600628 = header.getOrDefault("X-Amz-Credential")
  valid_600628 = validateParameter(valid_600628, JString, required = false,
                                 default = nil)
  if valid_600628 != nil:
    section.add "X-Amz-Credential", valid_600628
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600630: Call_DetachVolume_600618; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disconnects a volume from an iSCSI connection and then detaches the volume from the specified gateway. Detaching and attaching a volume enables you to recover your data from one gateway to a different gateway without creating a snapshot. It also makes it easier to move your volumes from an on-premises gateway to a gateway hosted on an Amazon EC2 instance. This operation is only supported in the volume gateway type.
  ## 
  let valid = call_600630.validator(path, query, header, formData, body)
  let scheme = call_600630.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600630.url(scheme.get, call_600630.host, call_600630.base,
                         call_600630.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600630, url, valid)

proc call*(call_600631: Call_DetachVolume_600618; body: JsonNode): Recallable =
  ## detachVolume
  ## Disconnects a volume from an iSCSI connection and then detaches the volume from the specified gateway. Detaching and attaching a volume enables you to recover your data from one gateway to a different gateway without creating a snapshot. It also makes it easier to move your volumes from an on-premises gateway to a gateway hosted on an Amazon EC2 instance. This operation is only supported in the volume gateway type.
  ##   body: JObject (required)
  var body_600632 = newJObject()
  if body != nil:
    body_600632 = body
  result = call_600631.call(nil, nil, nil, nil, body_600632)

var detachVolume* = Call_DetachVolume_600618(name: "detachVolume",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DetachVolume",
    validator: validate_DetachVolume_600619, base: "/", url: url_DetachVolume_600620,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableGateway_600633 = ref object of OpenApiRestCall_599369
proc url_DisableGateway_600635(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisableGateway_600634(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
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
  var valid_600636 = header.getOrDefault("X-Amz-Date")
  valid_600636 = validateParameter(valid_600636, JString, required = false,
                                 default = nil)
  if valid_600636 != nil:
    section.add "X-Amz-Date", valid_600636
  var valid_600637 = header.getOrDefault("X-Amz-Security-Token")
  valid_600637 = validateParameter(valid_600637, JString, required = false,
                                 default = nil)
  if valid_600637 != nil:
    section.add "X-Amz-Security-Token", valid_600637
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600638 = header.getOrDefault("X-Amz-Target")
  valid_600638 = validateParameter(valid_600638, JString, required = true, default = newJString(
      "StorageGateway_20130630.DisableGateway"))
  if valid_600638 != nil:
    section.add "X-Amz-Target", valid_600638
  var valid_600639 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600639 = validateParameter(valid_600639, JString, required = false,
                                 default = nil)
  if valid_600639 != nil:
    section.add "X-Amz-Content-Sha256", valid_600639
  var valid_600640 = header.getOrDefault("X-Amz-Algorithm")
  valid_600640 = validateParameter(valid_600640, JString, required = false,
                                 default = nil)
  if valid_600640 != nil:
    section.add "X-Amz-Algorithm", valid_600640
  var valid_600641 = header.getOrDefault("X-Amz-Signature")
  valid_600641 = validateParameter(valid_600641, JString, required = false,
                                 default = nil)
  if valid_600641 != nil:
    section.add "X-Amz-Signature", valid_600641
  var valid_600642 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600642 = validateParameter(valid_600642, JString, required = false,
                                 default = nil)
  if valid_600642 != nil:
    section.add "X-Amz-SignedHeaders", valid_600642
  var valid_600643 = header.getOrDefault("X-Amz-Credential")
  valid_600643 = validateParameter(valid_600643, JString, required = false,
                                 default = nil)
  if valid_600643 != nil:
    section.add "X-Amz-Credential", valid_600643
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600645: Call_DisableGateway_600633; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disables a tape gateway when the gateway is no longer functioning. For example, if your gateway VM is damaged, you can disable the gateway so you can recover virtual tapes.</p> <p>Use this operation for a tape gateway that is not reachable or not functioning. This operation is only supported in the tape gateway type.</p> <important> <p>Once a gateway is disabled it cannot be enabled.</p> </important>
  ## 
  let valid = call_600645.validator(path, query, header, formData, body)
  let scheme = call_600645.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600645.url(scheme.get, call_600645.host, call_600645.base,
                         call_600645.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600645, url, valid)

proc call*(call_600646: Call_DisableGateway_600633; body: JsonNode): Recallable =
  ## disableGateway
  ## <p>Disables a tape gateway when the gateway is no longer functioning. For example, if your gateway VM is damaged, you can disable the gateway so you can recover virtual tapes.</p> <p>Use this operation for a tape gateway that is not reachable or not functioning. This operation is only supported in the tape gateway type.</p> <important> <p>Once a gateway is disabled it cannot be enabled.</p> </important>
  ##   body: JObject (required)
  var body_600647 = newJObject()
  if body != nil:
    body_600647 = body
  result = call_600646.call(nil, nil, nil, nil, body_600647)

var disableGateway* = Call_DisableGateway_600633(name: "disableGateway",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DisableGateway",
    validator: validate_DisableGateway_600634, base: "/", url: url_DisableGateway_600635,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_JoinDomain_600648 = ref object of OpenApiRestCall_599369
proc url_JoinDomain_600650(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_JoinDomain_600649(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600651 = header.getOrDefault("X-Amz-Date")
  valid_600651 = validateParameter(valid_600651, JString, required = false,
                                 default = nil)
  if valid_600651 != nil:
    section.add "X-Amz-Date", valid_600651
  var valid_600652 = header.getOrDefault("X-Amz-Security-Token")
  valid_600652 = validateParameter(valid_600652, JString, required = false,
                                 default = nil)
  if valid_600652 != nil:
    section.add "X-Amz-Security-Token", valid_600652
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600653 = header.getOrDefault("X-Amz-Target")
  valid_600653 = validateParameter(valid_600653, JString, required = true, default = newJString(
      "StorageGateway_20130630.JoinDomain"))
  if valid_600653 != nil:
    section.add "X-Amz-Target", valid_600653
  var valid_600654 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600654 = validateParameter(valid_600654, JString, required = false,
                                 default = nil)
  if valid_600654 != nil:
    section.add "X-Amz-Content-Sha256", valid_600654
  var valid_600655 = header.getOrDefault("X-Amz-Algorithm")
  valid_600655 = validateParameter(valid_600655, JString, required = false,
                                 default = nil)
  if valid_600655 != nil:
    section.add "X-Amz-Algorithm", valid_600655
  var valid_600656 = header.getOrDefault("X-Amz-Signature")
  valid_600656 = validateParameter(valid_600656, JString, required = false,
                                 default = nil)
  if valid_600656 != nil:
    section.add "X-Amz-Signature", valid_600656
  var valid_600657 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600657 = validateParameter(valid_600657, JString, required = false,
                                 default = nil)
  if valid_600657 != nil:
    section.add "X-Amz-SignedHeaders", valid_600657
  var valid_600658 = header.getOrDefault("X-Amz-Credential")
  valid_600658 = validateParameter(valid_600658, JString, required = false,
                                 default = nil)
  if valid_600658 != nil:
    section.add "X-Amz-Credential", valid_600658
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600660: Call_JoinDomain_600648; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a file gateway to an Active Directory domain. This operation is only supported for file gateways that support the SMB file protocol.
  ## 
  let valid = call_600660.validator(path, query, header, formData, body)
  let scheme = call_600660.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600660.url(scheme.get, call_600660.host, call_600660.base,
                         call_600660.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600660, url, valid)

proc call*(call_600661: Call_JoinDomain_600648; body: JsonNode): Recallable =
  ## joinDomain
  ## Adds a file gateway to an Active Directory domain. This operation is only supported for file gateways that support the SMB file protocol.
  ##   body: JObject (required)
  var body_600662 = newJObject()
  if body != nil:
    body_600662 = body
  result = call_600661.call(nil, nil, nil, nil, body_600662)

var joinDomain* = Call_JoinDomain_600648(name: "joinDomain",
                                      meth: HttpMethod.HttpPost,
                                      host: "storagegateway.amazonaws.com", route: "/#X-Amz-Target=StorageGateway_20130630.JoinDomain",
                                      validator: validate_JoinDomain_600649,
                                      base: "/", url: url_JoinDomain_600650,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFileShares_600663 = ref object of OpenApiRestCall_599369
proc url_ListFileShares_600665(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListFileShares_600664(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
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
  var valid_600666 = query.getOrDefault("Limit")
  valid_600666 = validateParameter(valid_600666, JString, required = false,
                                 default = nil)
  if valid_600666 != nil:
    section.add "Limit", valid_600666
  var valid_600667 = query.getOrDefault("Marker")
  valid_600667 = validateParameter(valid_600667, JString, required = false,
                                 default = nil)
  if valid_600667 != nil:
    section.add "Marker", valid_600667
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600668 = header.getOrDefault("X-Amz-Date")
  valid_600668 = validateParameter(valid_600668, JString, required = false,
                                 default = nil)
  if valid_600668 != nil:
    section.add "X-Amz-Date", valid_600668
  var valid_600669 = header.getOrDefault("X-Amz-Security-Token")
  valid_600669 = validateParameter(valid_600669, JString, required = false,
                                 default = nil)
  if valid_600669 != nil:
    section.add "X-Amz-Security-Token", valid_600669
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600670 = header.getOrDefault("X-Amz-Target")
  valid_600670 = validateParameter(valid_600670, JString, required = true, default = newJString(
      "StorageGateway_20130630.ListFileShares"))
  if valid_600670 != nil:
    section.add "X-Amz-Target", valid_600670
  var valid_600671 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600671 = validateParameter(valid_600671, JString, required = false,
                                 default = nil)
  if valid_600671 != nil:
    section.add "X-Amz-Content-Sha256", valid_600671
  var valid_600672 = header.getOrDefault("X-Amz-Algorithm")
  valid_600672 = validateParameter(valid_600672, JString, required = false,
                                 default = nil)
  if valid_600672 != nil:
    section.add "X-Amz-Algorithm", valid_600672
  var valid_600673 = header.getOrDefault("X-Amz-Signature")
  valid_600673 = validateParameter(valid_600673, JString, required = false,
                                 default = nil)
  if valid_600673 != nil:
    section.add "X-Amz-Signature", valid_600673
  var valid_600674 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600674 = validateParameter(valid_600674, JString, required = false,
                                 default = nil)
  if valid_600674 != nil:
    section.add "X-Amz-SignedHeaders", valid_600674
  var valid_600675 = header.getOrDefault("X-Amz-Credential")
  valid_600675 = validateParameter(valid_600675, JString, required = false,
                                 default = nil)
  if valid_600675 != nil:
    section.add "X-Amz-Credential", valid_600675
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600677: Call_ListFileShares_600663; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of the file shares for a specific file gateway, or the list of file shares that belong to the calling user account. This operation is only supported for file gateways.
  ## 
  let valid = call_600677.validator(path, query, header, formData, body)
  let scheme = call_600677.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600677.url(scheme.get, call_600677.host, call_600677.base,
                         call_600677.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600677, url, valid)

proc call*(call_600678: Call_ListFileShares_600663; body: JsonNode;
          Limit: string = ""; Marker: string = ""): Recallable =
  ## listFileShares
  ## Gets a list of the file shares for a specific file gateway, or the list of file shares that belong to the calling user account. This operation is only supported for file gateways.
  ##   Limit: string
  ##        : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_600679 = newJObject()
  var body_600680 = newJObject()
  add(query_600679, "Limit", newJString(Limit))
  add(query_600679, "Marker", newJString(Marker))
  if body != nil:
    body_600680 = body
  result = call_600678.call(nil, query_600679, nil, nil, body_600680)

var listFileShares* = Call_ListFileShares_600663(name: "listFileShares",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.ListFileShares",
    validator: validate_ListFileShares_600664, base: "/", url: url_ListFileShares_600665,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGateways_600681 = ref object of OpenApiRestCall_599369
proc url_ListGateways_600683(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListGateways_600682(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600684 = query.getOrDefault("Limit")
  valid_600684 = validateParameter(valid_600684, JString, required = false,
                                 default = nil)
  if valid_600684 != nil:
    section.add "Limit", valid_600684
  var valid_600685 = query.getOrDefault("Marker")
  valid_600685 = validateParameter(valid_600685, JString, required = false,
                                 default = nil)
  if valid_600685 != nil:
    section.add "Marker", valid_600685
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600686 = header.getOrDefault("X-Amz-Date")
  valid_600686 = validateParameter(valid_600686, JString, required = false,
                                 default = nil)
  if valid_600686 != nil:
    section.add "X-Amz-Date", valid_600686
  var valid_600687 = header.getOrDefault("X-Amz-Security-Token")
  valid_600687 = validateParameter(valid_600687, JString, required = false,
                                 default = nil)
  if valid_600687 != nil:
    section.add "X-Amz-Security-Token", valid_600687
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600688 = header.getOrDefault("X-Amz-Target")
  valid_600688 = validateParameter(valid_600688, JString, required = true, default = newJString(
      "StorageGateway_20130630.ListGateways"))
  if valid_600688 != nil:
    section.add "X-Amz-Target", valid_600688
  var valid_600689 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600689 = validateParameter(valid_600689, JString, required = false,
                                 default = nil)
  if valid_600689 != nil:
    section.add "X-Amz-Content-Sha256", valid_600689
  var valid_600690 = header.getOrDefault("X-Amz-Algorithm")
  valid_600690 = validateParameter(valid_600690, JString, required = false,
                                 default = nil)
  if valid_600690 != nil:
    section.add "X-Amz-Algorithm", valid_600690
  var valid_600691 = header.getOrDefault("X-Amz-Signature")
  valid_600691 = validateParameter(valid_600691, JString, required = false,
                                 default = nil)
  if valid_600691 != nil:
    section.add "X-Amz-Signature", valid_600691
  var valid_600692 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600692 = validateParameter(valid_600692, JString, required = false,
                                 default = nil)
  if valid_600692 != nil:
    section.add "X-Amz-SignedHeaders", valid_600692
  var valid_600693 = header.getOrDefault("X-Amz-Credential")
  valid_600693 = validateParameter(valid_600693, JString, required = false,
                                 default = nil)
  if valid_600693 != nil:
    section.add "X-Amz-Credential", valid_600693
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600695: Call_ListGateways_600681; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists gateways owned by an AWS account in an AWS Region specified in the request. The returned list is ordered by gateway Amazon Resource Name (ARN).</p> <p>By default, the operation returns a maximum of 100 gateways. This operation supports pagination that allows you to optionally reduce the number of gateways returned in a response.</p> <p>If you have more gateways than are returned in a response (that is, the response returns only a truncated list of your gateways), the response contains a marker that you can specify in your next request to fetch the next page of gateways.</p>
  ## 
  let valid = call_600695.validator(path, query, header, formData, body)
  let scheme = call_600695.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600695.url(scheme.get, call_600695.host, call_600695.base,
                         call_600695.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600695, url, valid)

proc call*(call_600696: Call_ListGateways_600681; body: JsonNode; Limit: string = "";
          Marker: string = ""): Recallable =
  ## listGateways
  ## <p>Lists gateways owned by an AWS account in an AWS Region specified in the request. The returned list is ordered by gateway Amazon Resource Name (ARN).</p> <p>By default, the operation returns a maximum of 100 gateways. This operation supports pagination that allows you to optionally reduce the number of gateways returned in a response.</p> <p>If you have more gateways than are returned in a response (that is, the response returns only a truncated list of your gateways), the response contains a marker that you can specify in your next request to fetch the next page of gateways.</p>
  ##   Limit: string
  ##        : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_600697 = newJObject()
  var body_600698 = newJObject()
  add(query_600697, "Limit", newJString(Limit))
  add(query_600697, "Marker", newJString(Marker))
  if body != nil:
    body_600698 = body
  result = call_600696.call(nil, query_600697, nil, nil, body_600698)

var listGateways* = Call_ListGateways_600681(name: "listGateways",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.ListGateways",
    validator: validate_ListGateways_600682, base: "/", url: url_ListGateways_600683,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLocalDisks_600699 = ref object of OpenApiRestCall_599369
proc url_ListLocalDisks_600701(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListLocalDisks_600700(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
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
  var valid_600702 = header.getOrDefault("X-Amz-Date")
  valid_600702 = validateParameter(valid_600702, JString, required = false,
                                 default = nil)
  if valid_600702 != nil:
    section.add "X-Amz-Date", valid_600702
  var valid_600703 = header.getOrDefault("X-Amz-Security-Token")
  valid_600703 = validateParameter(valid_600703, JString, required = false,
                                 default = nil)
  if valid_600703 != nil:
    section.add "X-Amz-Security-Token", valid_600703
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600704 = header.getOrDefault("X-Amz-Target")
  valid_600704 = validateParameter(valid_600704, JString, required = true, default = newJString(
      "StorageGateway_20130630.ListLocalDisks"))
  if valid_600704 != nil:
    section.add "X-Amz-Target", valid_600704
  var valid_600705 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600705 = validateParameter(valid_600705, JString, required = false,
                                 default = nil)
  if valid_600705 != nil:
    section.add "X-Amz-Content-Sha256", valid_600705
  var valid_600706 = header.getOrDefault("X-Amz-Algorithm")
  valid_600706 = validateParameter(valid_600706, JString, required = false,
                                 default = nil)
  if valid_600706 != nil:
    section.add "X-Amz-Algorithm", valid_600706
  var valid_600707 = header.getOrDefault("X-Amz-Signature")
  valid_600707 = validateParameter(valid_600707, JString, required = false,
                                 default = nil)
  if valid_600707 != nil:
    section.add "X-Amz-Signature", valid_600707
  var valid_600708 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600708 = validateParameter(valid_600708, JString, required = false,
                                 default = nil)
  if valid_600708 != nil:
    section.add "X-Amz-SignedHeaders", valid_600708
  var valid_600709 = header.getOrDefault("X-Amz-Credential")
  valid_600709 = validateParameter(valid_600709, JString, required = false,
                                 default = nil)
  if valid_600709 != nil:
    section.add "X-Amz-Credential", valid_600709
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600711: Call_ListLocalDisks_600699; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the gateway's local disks. To specify which gateway to describe, you use the Amazon Resource Name (ARN) of the gateway in the body of the request.</p> <p>The request returns a list of all disks, specifying which are configured as working storage, cache storage, or stored volume or not configured at all. The response includes a <code>DiskStatus</code> field. This field can have a value of present (the disk is available to use), missing (the disk is no longer connected to the gateway), or mismatch (the disk node is occupied by a disk that has incorrect metadata or the disk content is corrupted).</p>
  ## 
  let valid = call_600711.validator(path, query, header, formData, body)
  let scheme = call_600711.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600711.url(scheme.get, call_600711.host, call_600711.base,
                         call_600711.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600711, url, valid)

proc call*(call_600712: Call_ListLocalDisks_600699; body: JsonNode): Recallable =
  ## listLocalDisks
  ## <p>Returns a list of the gateway's local disks. To specify which gateway to describe, you use the Amazon Resource Name (ARN) of the gateway in the body of the request.</p> <p>The request returns a list of all disks, specifying which are configured as working storage, cache storage, or stored volume or not configured at all. The response includes a <code>DiskStatus</code> field. This field can have a value of present (the disk is available to use), missing (the disk is no longer connected to the gateway), or mismatch (the disk node is occupied by a disk that has incorrect metadata or the disk content is corrupted).</p>
  ##   body: JObject (required)
  var body_600713 = newJObject()
  if body != nil:
    body_600713 = body
  result = call_600712.call(nil, nil, nil, nil, body_600713)

var listLocalDisks* = Call_ListLocalDisks_600699(name: "listLocalDisks",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.ListLocalDisks",
    validator: validate_ListLocalDisks_600700, base: "/", url: url_ListLocalDisks_600701,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_600714 = ref object of OpenApiRestCall_599369
proc url_ListTagsForResource_600716(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_600715(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_600717 = query.getOrDefault("Limit")
  valid_600717 = validateParameter(valid_600717, JString, required = false,
                                 default = nil)
  if valid_600717 != nil:
    section.add "Limit", valid_600717
  var valid_600718 = query.getOrDefault("Marker")
  valid_600718 = validateParameter(valid_600718, JString, required = false,
                                 default = nil)
  if valid_600718 != nil:
    section.add "Marker", valid_600718
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600719 = header.getOrDefault("X-Amz-Date")
  valid_600719 = validateParameter(valid_600719, JString, required = false,
                                 default = nil)
  if valid_600719 != nil:
    section.add "X-Amz-Date", valid_600719
  var valid_600720 = header.getOrDefault("X-Amz-Security-Token")
  valid_600720 = validateParameter(valid_600720, JString, required = false,
                                 default = nil)
  if valid_600720 != nil:
    section.add "X-Amz-Security-Token", valid_600720
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600721 = header.getOrDefault("X-Amz-Target")
  valid_600721 = validateParameter(valid_600721, JString, required = true, default = newJString(
      "StorageGateway_20130630.ListTagsForResource"))
  if valid_600721 != nil:
    section.add "X-Amz-Target", valid_600721
  var valid_600722 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600722 = validateParameter(valid_600722, JString, required = false,
                                 default = nil)
  if valid_600722 != nil:
    section.add "X-Amz-Content-Sha256", valid_600722
  var valid_600723 = header.getOrDefault("X-Amz-Algorithm")
  valid_600723 = validateParameter(valid_600723, JString, required = false,
                                 default = nil)
  if valid_600723 != nil:
    section.add "X-Amz-Algorithm", valid_600723
  var valid_600724 = header.getOrDefault("X-Amz-Signature")
  valid_600724 = validateParameter(valid_600724, JString, required = false,
                                 default = nil)
  if valid_600724 != nil:
    section.add "X-Amz-Signature", valid_600724
  var valid_600725 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600725 = validateParameter(valid_600725, JString, required = false,
                                 default = nil)
  if valid_600725 != nil:
    section.add "X-Amz-SignedHeaders", valid_600725
  var valid_600726 = header.getOrDefault("X-Amz-Credential")
  valid_600726 = validateParameter(valid_600726, JString, required = false,
                                 default = nil)
  if valid_600726 != nil:
    section.add "X-Amz-Credential", valid_600726
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600728: Call_ListTagsForResource_600714; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags that have been added to the specified resource. This operation is supported in storage gateways of all types.
  ## 
  let valid = call_600728.validator(path, query, header, formData, body)
  let scheme = call_600728.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600728.url(scheme.get, call_600728.host, call_600728.base,
                         call_600728.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600728, url, valid)

proc call*(call_600729: Call_ListTagsForResource_600714; body: JsonNode;
          Limit: string = ""; Marker: string = ""): Recallable =
  ## listTagsForResource
  ## Lists the tags that have been added to the specified resource. This operation is supported in storage gateways of all types.
  ##   Limit: string
  ##        : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_600730 = newJObject()
  var body_600731 = newJObject()
  add(query_600730, "Limit", newJString(Limit))
  add(query_600730, "Marker", newJString(Marker))
  if body != nil:
    body_600731 = body
  result = call_600729.call(nil, query_600730, nil, nil, body_600731)

var listTagsForResource* = Call_ListTagsForResource_600714(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.ListTagsForResource",
    validator: validate_ListTagsForResource_600715, base: "/",
    url: url_ListTagsForResource_600716, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTapes_600732 = ref object of OpenApiRestCall_599369
proc url_ListTapes_600734(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTapes_600733(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600735 = query.getOrDefault("Limit")
  valid_600735 = validateParameter(valid_600735, JString, required = false,
                                 default = nil)
  if valid_600735 != nil:
    section.add "Limit", valid_600735
  var valid_600736 = query.getOrDefault("Marker")
  valid_600736 = validateParameter(valid_600736, JString, required = false,
                                 default = nil)
  if valid_600736 != nil:
    section.add "Marker", valid_600736
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600737 = header.getOrDefault("X-Amz-Date")
  valid_600737 = validateParameter(valid_600737, JString, required = false,
                                 default = nil)
  if valid_600737 != nil:
    section.add "X-Amz-Date", valid_600737
  var valid_600738 = header.getOrDefault("X-Amz-Security-Token")
  valid_600738 = validateParameter(valid_600738, JString, required = false,
                                 default = nil)
  if valid_600738 != nil:
    section.add "X-Amz-Security-Token", valid_600738
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600739 = header.getOrDefault("X-Amz-Target")
  valid_600739 = validateParameter(valid_600739, JString, required = true, default = newJString(
      "StorageGateway_20130630.ListTapes"))
  if valid_600739 != nil:
    section.add "X-Amz-Target", valid_600739
  var valid_600740 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600740 = validateParameter(valid_600740, JString, required = false,
                                 default = nil)
  if valid_600740 != nil:
    section.add "X-Amz-Content-Sha256", valid_600740
  var valid_600741 = header.getOrDefault("X-Amz-Algorithm")
  valid_600741 = validateParameter(valid_600741, JString, required = false,
                                 default = nil)
  if valid_600741 != nil:
    section.add "X-Amz-Algorithm", valid_600741
  var valid_600742 = header.getOrDefault("X-Amz-Signature")
  valid_600742 = validateParameter(valid_600742, JString, required = false,
                                 default = nil)
  if valid_600742 != nil:
    section.add "X-Amz-Signature", valid_600742
  var valid_600743 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600743 = validateParameter(valid_600743, JString, required = false,
                                 default = nil)
  if valid_600743 != nil:
    section.add "X-Amz-SignedHeaders", valid_600743
  var valid_600744 = header.getOrDefault("X-Amz-Credential")
  valid_600744 = validateParameter(valid_600744, JString, required = false,
                                 default = nil)
  if valid_600744 != nil:
    section.add "X-Amz-Credential", valid_600744
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600746: Call_ListTapes_600732; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists virtual tapes in your virtual tape library (VTL) and your virtual tape shelf (VTS). You specify the tapes to list by specifying one or more tape Amazon Resource Names (ARNs). If you don't specify a tape ARN, the operation lists all virtual tapes in both your VTL and VTS.</p> <p>This operation supports pagination. By default, the operation returns a maximum of up to 100 tapes. You can optionally specify the <code>Limit</code> parameter in the body to limit the number of tapes in the response. If the number of tapes returned in the response is truncated, the response includes a <code>Marker</code> element that you can use in your subsequent request to retrieve the next set of tapes. This operation is only supported in the tape gateway type.</p>
  ## 
  let valid = call_600746.validator(path, query, header, formData, body)
  let scheme = call_600746.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600746.url(scheme.get, call_600746.host, call_600746.base,
                         call_600746.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600746, url, valid)

proc call*(call_600747: Call_ListTapes_600732; body: JsonNode; Limit: string = "";
          Marker: string = ""): Recallable =
  ## listTapes
  ## <p>Lists virtual tapes in your virtual tape library (VTL) and your virtual tape shelf (VTS). You specify the tapes to list by specifying one or more tape Amazon Resource Names (ARNs). If you don't specify a tape ARN, the operation lists all virtual tapes in both your VTL and VTS.</p> <p>This operation supports pagination. By default, the operation returns a maximum of up to 100 tapes. You can optionally specify the <code>Limit</code> parameter in the body to limit the number of tapes in the response. If the number of tapes returned in the response is truncated, the response includes a <code>Marker</code> element that you can use in your subsequent request to retrieve the next set of tapes. This operation is only supported in the tape gateway type.</p>
  ##   Limit: string
  ##        : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_600748 = newJObject()
  var body_600749 = newJObject()
  add(query_600748, "Limit", newJString(Limit))
  add(query_600748, "Marker", newJString(Marker))
  if body != nil:
    body_600749 = body
  result = call_600747.call(nil, query_600748, nil, nil, body_600749)

var listTapes* = Call_ListTapes_600732(name: "listTapes", meth: HttpMethod.HttpPost,
                                    host: "storagegateway.amazonaws.com", route: "/#X-Amz-Target=StorageGateway_20130630.ListTapes",
                                    validator: validate_ListTapes_600733,
                                    base: "/", url: url_ListTapes_600734,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVolumeInitiators_600750 = ref object of OpenApiRestCall_599369
proc url_ListVolumeInitiators_600752(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListVolumeInitiators_600751(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600753 = header.getOrDefault("X-Amz-Date")
  valid_600753 = validateParameter(valid_600753, JString, required = false,
                                 default = nil)
  if valid_600753 != nil:
    section.add "X-Amz-Date", valid_600753
  var valid_600754 = header.getOrDefault("X-Amz-Security-Token")
  valid_600754 = validateParameter(valid_600754, JString, required = false,
                                 default = nil)
  if valid_600754 != nil:
    section.add "X-Amz-Security-Token", valid_600754
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600755 = header.getOrDefault("X-Amz-Target")
  valid_600755 = validateParameter(valid_600755, JString, required = true, default = newJString(
      "StorageGateway_20130630.ListVolumeInitiators"))
  if valid_600755 != nil:
    section.add "X-Amz-Target", valid_600755
  var valid_600756 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600756 = validateParameter(valid_600756, JString, required = false,
                                 default = nil)
  if valid_600756 != nil:
    section.add "X-Amz-Content-Sha256", valid_600756
  var valid_600757 = header.getOrDefault("X-Amz-Algorithm")
  valid_600757 = validateParameter(valid_600757, JString, required = false,
                                 default = nil)
  if valid_600757 != nil:
    section.add "X-Amz-Algorithm", valid_600757
  var valid_600758 = header.getOrDefault("X-Amz-Signature")
  valid_600758 = validateParameter(valid_600758, JString, required = false,
                                 default = nil)
  if valid_600758 != nil:
    section.add "X-Amz-Signature", valid_600758
  var valid_600759 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600759 = validateParameter(valid_600759, JString, required = false,
                                 default = nil)
  if valid_600759 != nil:
    section.add "X-Amz-SignedHeaders", valid_600759
  var valid_600760 = header.getOrDefault("X-Amz-Credential")
  valid_600760 = validateParameter(valid_600760, JString, required = false,
                                 default = nil)
  if valid_600760 != nil:
    section.add "X-Amz-Credential", valid_600760
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600762: Call_ListVolumeInitiators_600750; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists iSCSI initiators that are connected to a volume. You can use this operation to determine whether a volume is being used or not. This operation is only supported in the cached volume and stored volume gateway types.
  ## 
  let valid = call_600762.validator(path, query, header, formData, body)
  let scheme = call_600762.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600762.url(scheme.get, call_600762.host, call_600762.base,
                         call_600762.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600762, url, valid)

proc call*(call_600763: Call_ListVolumeInitiators_600750; body: JsonNode): Recallable =
  ## listVolumeInitiators
  ## Lists iSCSI initiators that are connected to a volume. You can use this operation to determine whether a volume is being used or not. This operation is only supported in the cached volume and stored volume gateway types.
  ##   body: JObject (required)
  var body_600764 = newJObject()
  if body != nil:
    body_600764 = body
  result = call_600763.call(nil, nil, nil, nil, body_600764)

var listVolumeInitiators* = Call_ListVolumeInitiators_600750(
    name: "listVolumeInitiators", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.ListVolumeInitiators",
    validator: validate_ListVolumeInitiators_600751, base: "/",
    url: url_ListVolumeInitiators_600752, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVolumeRecoveryPoints_600765 = ref object of OpenApiRestCall_599369
proc url_ListVolumeRecoveryPoints_600767(protocol: Scheme; host: string;
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

proc validate_ListVolumeRecoveryPoints_600766(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600768 = header.getOrDefault("X-Amz-Date")
  valid_600768 = validateParameter(valid_600768, JString, required = false,
                                 default = nil)
  if valid_600768 != nil:
    section.add "X-Amz-Date", valid_600768
  var valid_600769 = header.getOrDefault("X-Amz-Security-Token")
  valid_600769 = validateParameter(valid_600769, JString, required = false,
                                 default = nil)
  if valid_600769 != nil:
    section.add "X-Amz-Security-Token", valid_600769
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600770 = header.getOrDefault("X-Amz-Target")
  valid_600770 = validateParameter(valid_600770, JString, required = true, default = newJString(
      "StorageGateway_20130630.ListVolumeRecoveryPoints"))
  if valid_600770 != nil:
    section.add "X-Amz-Target", valid_600770
  var valid_600771 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600771 = validateParameter(valid_600771, JString, required = false,
                                 default = nil)
  if valid_600771 != nil:
    section.add "X-Amz-Content-Sha256", valid_600771
  var valid_600772 = header.getOrDefault("X-Amz-Algorithm")
  valid_600772 = validateParameter(valid_600772, JString, required = false,
                                 default = nil)
  if valid_600772 != nil:
    section.add "X-Amz-Algorithm", valid_600772
  var valid_600773 = header.getOrDefault("X-Amz-Signature")
  valid_600773 = validateParameter(valid_600773, JString, required = false,
                                 default = nil)
  if valid_600773 != nil:
    section.add "X-Amz-Signature", valid_600773
  var valid_600774 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600774 = validateParameter(valid_600774, JString, required = false,
                                 default = nil)
  if valid_600774 != nil:
    section.add "X-Amz-SignedHeaders", valid_600774
  var valid_600775 = header.getOrDefault("X-Amz-Credential")
  valid_600775 = validateParameter(valid_600775, JString, required = false,
                                 default = nil)
  if valid_600775 != nil:
    section.add "X-Amz-Credential", valid_600775
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600777: Call_ListVolumeRecoveryPoints_600765; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the recovery points for a specified gateway. This operation is only supported in the cached volume gateway type.</p> <p>Each cache volume has one recovery point. A volume recovery point is a point in time at which all data of the volume is consistent and from which you can create a snapshot or clone a new cached volume from a source volume. To create a snapshot from a volume recovery point use the <a>CreateSnapshotFromVolumeRecoveryPoint</a> operation.</p>
  ## 
  let valid = call_600777.validator(path, query, header, formData, body)
  let scheme = call_600777.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600777.url(scheme.get, call_600777.host, call_600777.base,
                         call_600777.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600777, url, valid)

proc call*(call_600778: Call_ListVolumeRecoveryPoints_600765; body: JsonNode): Recallable =
  ## listVolumeRecoveryPoints
  ## <p>Lists the recovery points for a specified gateway. This operation is only supported in the cached volume gateway type.</p> <p>Each cache volume has one recovery point. A volume recovery point is a point in time at which all data of the volume is consistent and from which you can create a snapshot or clone a new cached volume from a source volume. To create a snapshot from a volume recovery point use the <a>CreateSnapshotFromVolumeRecoveryPoint</a> operation.</p>
  ##   body: JObject (required)
  var body_600779 = newJObject()
  if body != nil:
    body_600779 = body
  result = call_600778.call(nil, nil, nil, nil, body_600779)

var listVolumeRecoveryPoints* = Call_ListVolumeRecoveryPoints_600765(
    name: "listVolumeRecoveryPoints", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.ListVolumeRecoveryPoints",
    validator: validate_ListVolumeRecoveryPoints_600766, base: "/",
    url: url_ListVolumeRecoveryPoints_600767, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVolumes_600780 = ref object of OpenApiRestCall_599369
proc url_ListVolumes_600782(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListVolumes_600781(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600783 = query.getOrDefault("Limit")
  valid_600783 = validateParameter(valid_600783, JString, required = false,
                                 default = nil)
  if valid_600783 != nil:
    section.add "Limit", valid_600783
  var valid_600784 = query.getOrDefault("Marker")
  valid_600784 = validateParameter(valid_600784, JString, required = false,
                                 default = nil)
  if valid_600784 != nil:
    section.add "Marker", valid_600784
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600785 = header.getOrDefault("X-Amz-Date")
  valid_600785 = validateParameter(valid_600785, JString, required = false,
                                 default = nil)
  if valid_600785 != nil:
    section.add "X-Amz-Date", valid_600785
  var valid_600786 = header.getOrDefault("X-Amz-Security-Token")
  valid_600786 = validateParameter(valid_600786, JString, required = false,
                                 default = nil)
  if valid_600786 != nil:
    section.add "X-Amz-Security-Token", valid_600786
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600787 = header.getOrDefault("X-Amz-Target")
  valid_600787 = validateParameter(valid_600787, JString, required = true, default = newJString(
      "StorageGateway_20130630.ListVolumes"))
  if valid_600787 != nil:
    section.add "X-Amz-Target", valid_600787
  var valid_600788 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600788 = validateParameter(valid_600788, JString, required = false,
                                 default = nil)
  if valid_600788 != nil:
    section.add "X-Amz-Content-Sha256", valid_600788
  var valid_600789 = header.getOrDefault("X-Amz-Algorithm")
  valid_600789 = validateParameter(valid_600789, JString, required = false,
                                 default = nil)
  if valid_600789 != nil:
    section.add "X-Amz-Algorithm", valid_600789
  var valid_600790 = header.getOrDefault("X-Amz-Signature")
  valid_600790 = validateParameter(valid_600790, JString, required = false,
                                 default = nil)
  if valid_600790 != nil:
    section.add "X-Amz-Signature", valid_600790
  var valid_600791 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600791 = validateParameter(valid_600791, JString, required = false,
                                 default = nil)
  if valid_600791 != nil:
    section.add "X-Amz-SignedHeaders", valid_600791
  var valid_600792 = header.getOrDefault("X-Amz-Credential")
  valid_600792 = validateParameter(valid_600792, JString, required = false,
                                 default = nil)
  if valid_600792 != nil:
    section.add "X-Amz-Credential", valid_600792
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600794: Call_ListVolumes_600780; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the iSCSI stored volumes of a gateway. Results are sorted by volume ARN. The response includes only the volume ARNs. If you want additional volume information, use the <a>DescribeStorediSCSIVolumes</a> or the <a>DescribeCachediSCSIVolumes</a> API.</p> <p>The operation supports pagination. By default, the operation returns a maximum of up to 100 volumes. You can optionally specify the <code>Limit</code> field in the body to limit the number of volumes in the response. If the number of volumes returned in the response is truncated, the response includes a Marker field. You can use this Marker value in your subsequent request to retrieve the next set of volumes. This operation is only supported in the cached volume and stored volume gateway types.</p>
  ## 
  let valid = call_600794.validator(path, query, header, formData, body)
  let scheme = call_600794.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600794.url(scheme.get, call_600794.host, call_600794.base,
                         call_600794.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600794, url, valid)

proc call*(call_600795: Call_ListVolumes_600780; body: JsonNode; Limit: string = "";
          Marker: string = ""): Recallable =
  ## listVolumes
  ## <p>Lists the iSCSI stored volumes of a gateway. Results are sorted by volume ARN. The response includes only the volume ARNs. If you want additional volume information, use the <a>DescribeStorediSCSIVolumes</a> or the <a>DescribeCachediSCSIVolumes</a> API.</p> <p>The operation supports pagination. By default, the operation returns a maximum of up to 100 volumes. You can optionally specify the <code>Limit</code> field in the body to limit the number of volumes in the response. If the number of volumes returned in the response is truncated, the response includes a Marker field. You can use this Marker value in your subsequent request to retrieve the next set of volumes. This operation is only supported in the cached volume and stored volume gateway types.</p>
  ##   Limit: string
  ##        : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_600796 = newJObject()
  var body_600797 = newJObject()
  add(query_600796, "Limit", newJString(Limit))
  add(query_600796, "Marker", newJString(Marker))
  if body != nil:
    body_600797 = body
  result = call_600795.call(nil, query_600796, nil, nil, body_600797)

var listVolumes* = Call_ListVolumes_600780(name: "listVolumes",
                                        meth: HttpMethod.HttpPost,
                                        host: "storagegateway.amazonaws.com", route: "/#X-Amz-Target=StorageGateway_20130630.ListVolumes",
                                        validator: validate_ListVolumes_600781,
                                        base: "/", url: url_ListVolumes_600782,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_NotifyWhenUploaded_600798 = ref object of OpenApiRestCall_599369
proc url_NotifyWhenUploaded_600800(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_NotifyWhenUploaded_600799(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
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
  var valid_600801 = header.getOrDefault("X-Amz-Date")
  valid_600801 = validateParameter(valid_600801, JString, required = false,
                                 default = nil)
  if valid_600801 != nil:
    section.add "X-Amz-Date", valid_600801
  var valid_600802 = header.getOrDefault("X-Amz-Security-Token")
  valid_600802 = validateParameter(valid_600802, JString, required = false,
                                 default = nil)
  if valid_600802 != nil:
    section.add "X-Amz-Security-Token", valid_600802
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600803 = header.getOrDefault("X-Amz-Target")
  valid_600803 = validateParameter(valid_600803, JString, required = true, default = newJString(
      "StorageGateway_20130630.NotifyWhenUploaded"))
  if valid_600803 != nil:
    section.add "X-Amz-Target", valid_600803
  var valid_600804 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600804 = validateParameter(valid_600804, JString, required = false,
                                 default = nil)
  if valid_600804 != nil:
    section.add "X-Amz-Content-Sha256", valid_600804
  var valid_600805 = header.getOrDefault("X-Amz-Algorithm")
  valid_600805 = validateParameter(valid_600805, JString, required = false,
                                 default = nil)
  if valid_600805 != nil:
    section.add "X-Amz-Algorithm", valid_600805
  var valid_600806 = header.getOrDefault("X-Amz-Signature")
  valid_600806 = validateParameter(valid_600806, JString, required = false,
                                 default = nil)
  if valid_600806 != nil:
    section.add "X-Amz-Signature", valid_600806
  var valid_600807 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600807 = validateParameter(valid_600807, JString, required = false,
                                 default = nil)
  if valid_600807 != nil:
    section.add "X-Amz-SignedHeaders", valid_600807
  var valid_600808 = header.getOrDefault("X-Amz-Credential")
  valid_600808 = validateParameter(valid_600808, JString, required = false,
                                 default = nil)
  if valid_600808 != nil:
    section.add "X-Amz-Credential", valid_600808
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600810: Call_NotifyWhenUploaded_600798; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sends you notification through CloudWatch Events when all files written to your file share have been uploaded to Amazon S3.</p> <p>AWS Storage Gateway can send a notification through Amazon CloudWatch Events when all files written to your file share up to that point in time have been uploaded to Amazon S3. These files include files written to the file share up to the time that you make a request for notification. When the upload is done, Storage Gateway sends you notification through an Amazon CloudWatch Event. You can configure CloudWatch Events to send the notification through event targets such as Amazon SNS or AWS Lambda function. This operation is only supported for file gateways.</p> <p>For more information, see Getting File Upload Notification in the Storage Gateway User Guide (https://docs.aws.amazon.com/storagegateway/latest/userguide/monitoring-file-gateway.html#get-upload-notification). </p>
  ## 
  let valid = call_600810.validator(path, query, header, formData, body)
  let scheme = call_600810.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600810.url(scheme.get, call_600810.host, call_600810.base,
                         call_600810.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600810, url, valid)

proc call*(call_600811: Call_NotifyWhenUploaded_600798; body: JsonNode): Recallable =
  ## notifyWhenUploaded
  ## <p>Sends you notification through CloudWatch Events when all files written to your file share have been uploaded to Amazon S3.</p> <p>AWS Storage Gateway can send a notification through Amazon CloudWatch Events when all files written to your file share up to that point in time have been uploaded to Amazon S3. These files include files written to the file share up to the time that you make a request for notification. When the upload is done, Storage Gateway sends you notification through an Amazon CloudWatch Event. You can configure CloudWatch Events to send the notification through event targets such as Amazon SNS or AWS Lambda function. This operation is only supported for file gateways.</p> <p>For more information, see Getting File Upload Notification in the Storage Gateway User Guide (https://docs.aws.amazon.com/storagegateway/latest/userguide/monitoring-file-gateway.html#get-upload-notification). </p>
  ##   body: JObject (required)
  var body_600812 = newJObject()
  if body != nil:
    body_600812 = body
  result = call_600811.call(nil, nil, nil, nil, body_600812)

var notifyWhenUploaded* = Call_NotifyWhenUploaded_600798(
    name: "notifyWhenUploaded", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.NotifyWhenUploaded",
    validator: validate_NotifyWhenUploaded_600799, base: "/",
    url: url_NotifyWhenUploaded_600800, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RefreshCache_600813 = ref object of OpenApiRestCall_599369
proc url_RefreshCache_600815(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RefreshCache_600814(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600816 = header.getOrDefault("X-Amz-Date")
  valid_600816 = validateParameter(valid_600816, JString, required = false,
                                 default = nil)
  if valid_600816 != nil:
    section.add "X-Amz-Date", valid_600816
  var valid_600817 = header.getOrDefault("X-Amz-Security-Token")
  valid_600817 = validateParameter(valid_600817, JString, required = false,
                                 default = nil)
  if valid_600817 != nil:
    section.add "X-Amz-Security-Token", valid_600817
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600818 = header.getOrDefault("X-Amz-Target")
  valid_600818 = validateParameter(valid_600818, JString, required = true, default = newJString(
      "StorageGateway_20130630.RefreshCache"))
  if valid_600818 != nil:
    section.add "X-Amz-Target", valid_600818
  var valid_600819 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600819 = validateParameter(valid_600819, JString, required = false,
                                 default = nil)
  if valid_600819 != nil:
    section.add "X-Amz-Content-Sha256", valid_600819
  var valid_600820 = header.getOrDefault("X-Amz-Algorithm")
  valid_600820 = validateParameter(valid_600820, JString, required = false,
                                 default = nil)
  if valid_600820 != nil:
    section.add "X-Amz-Algorithm", valid_600820
  var valid_600821 = header.getOrDefault("X-Amz-Signature")
  valid_600821 = validateParameter(valid_600821, JString, required = false,
                                 default = nil)
  if valid_600821 != nil:
    section.add "X-Amz-Signature", valid_600821
  var valid_600822 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600822 = validateParameter(valid_600822, JString, required = false,
                                 default = nil)
  if valid_600822 != nil:
    section.add "X-Amz-SignedHeaders", valid_600822
  var valid_600823 = header.getOrDefault("X-Amz-Credential")
  valid_600823 = validateParameter(valid_600823, JString, required = false,
                                 default = nil)
  if valid_600823 != nil:
    section.add "X-Amz-Credential", valid_600823
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600825: Call_RefreshCache_600813; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Refreshes the cache for the specified file share. This operation finds objects in the Amazon S3 bucket that were added, removed or replaced since the gateway last listed the bucket's contents and cached the results. This operation is only supported in the file gateway type. You can subscribe to be notified through an Amazon CloudWatch event when your RefreshCache operation completes. For more information, see <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/monitoring-file-gateway.html#get-notification">Getting Notified About File Operations</a>.</p> <p>When this API is called, it only initiates the refresh operation. When the API call completes and returns a success code, it doesn't necessarily mean that the file refresh has completed. You should use the refresh-complete notification to determine that the operation has completed before you check for new files on the gateway file share. You can subscribe to be notified through an CloudWatch event when your <code>RefreshCache</code> operation completes. </p> <p>Throttle limit: This API is asynchronous so the gateway will accept no more than two refreshes at any time. We recommend using the refresh-complete CloudWatch event notification before issuing additional requests. For more information, see <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/monitoring-file-gateway.html#get-notification">Getting Notified About File Operations</a>.</p> <p>If you invoke the RefreshCache API when two requests are already being processed, any new request will cause an <code>InvalidGatewayRequestException</code> error because too many requests were sent to the server.</p> <p>For more information, see "https://docs.aws.amazon.com/storagegateway/latest/userguide/monitoring-file-gateway.html#get-notification".</p>
  ## 
  let valid = call_600825.validator(path, query, header, formData, body)
  let scheme = call_600825.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600825.url(scheme.get, call_600825.host, call_600825.base,
                         call_600825.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600825, url, valid)

proc call*(call_600826: Call_RefreshCache_600813; body: JsonNode): Recallable =
  ## refreshCache
  ## <p>Refreshes the cache for the specified file share. This operation finds objects in the Amazon S3 bucket that were added, removed or replaced since the gateway last listed the bucket's contents and cached the results. This operation is only supported in the file gateway type. You can subscribe to be notified through an Amazon CloudWatch event when your RefreshCache operation completes. For more information, see <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/monitoring-file-gateway.html#get-notification">Getting Notified About File Operations</a>.</p> <p>When this API is called, it only initiates the refresh operation. When the API call completes and returns a success code, it doesn't necessarily mean that the file refresh has completed. You should use the refresh-complete notification to determine that the operation has completed before you check for new files on the gateway file share. You can subscribe to be notified through an CloudWatch event when your <code>RefreshCache</code> operation completes. </p> <p>Throttle limit: This API is asynchronous so the gateway will accept no more than two refreshes at any time. We recommend using the refresh-complete CloudWatch event notification before issuing additional requests. For more information, see <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/monitoring-file-gateway.html#get-notification">Getting Notified About File Operations</a>.</p> <p>If you invoke the RefreshCache API when two requests are already being processed, any new request will cause an <code>InvalidGatewayRequestException</code> error because too many requests were sent to the server.</p> <p>For more information, see "https://docs.aws.amazon.com/storagegateway/latest/userguide/monitoring-file-gateway.html#get-notification".</p>
  ##   body: JObject (required)
  var body_600827 = newJObject()
  if body != nil:
    body_600827 = body
  result = call_600826.call(nil, nil, nil, nil, body_600827)

var refreshCache* = Call_RefreshCache_600813(name: "refreshCache",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.RefreshCache",
    validator: validate_RefreshCache_600814, base: "/", url: url_RefreshCache_600815,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveTagsFromResource_600828 = ref object of OpenApiRestCall_599369
proc url_RemoveTagsFromResource_600830(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RemoveTagsFromResource_600829(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600831 = header.getOrDefault("X-Amz-Date")
  valid_600831 = validateParameter(valid_600831, JString, required = false,
                                 default = nil)
  if valid_600831 != nil:
    section.add "X-Amz-Date", valid_600831
  var valid_600832 = header.getOrDefault("X-Amz-Security-Token")
  valid_600832 = validateParameter(valid_600832, JString, required = false,
                                 default = nil)
  if valid_600832 != nil:
    section.add "X-Amz-Security-Token", valid_600832
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600833 = header.getOrDefault("X-Amz-Target")
  valid_600833 = validateParameter(valid_600833, JString, required = true, default = newJString(
      "StorageGateway_20130630.RemoveTagsFromResource"))
  if valid_600833 != nil:
    section.add "X-Amz-Target", valid_600833
  var valid_600834 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600834 = validateParameter(valid_600834, JString, required = false,
                                 default = nil)
  if valid_600834 != nil:
    section.add "X-Amz-Content-Sha256", valid_600834
  var valid_600835 = header.getOrDefault("X-Amz-Algorithm")
  valid_600835 = validateParameter(valid_600835, JString, required = false,
                                 default = nil)
  if valid_600835 != nil:
    section.add "X-Amz-Algorithm", valid_600835
  var valid_600836 = header.getOrDefault("X-Amz-Signature")
  valid_600836 = validateParameter(valid_600836, JString, required = false,
                                 default = nil)
  if valid_600836 != nil:
    section.add "X-Amz-Signature", valid_600836
  var valid_600837 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600837 = validateParameter(valid_600837, JString, required = false,
                                 default = nil)
  if valid_600837 != nil:
    section.add "X-Amz-SignedHeaders", valid_600837
  var valid_600838 = header.getOrDefault("X-Amz-Credential")
  valid_600838 = validateParameter(valid_600838, JString, required = false,
                                 default = nil)
  if valid_600838 != nil:
    section.add "X-Amz-Credential", valid_600838
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600840: Call_RemoveTagsFromResource_600828; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from the specified resource. This operation is supported in storage gateways of all types.
  ## 
  let valid = call_600840.validator(path, query, header, formData, body)
  let scheme = call_600840.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600840.url(scheme.get, call_600840.host, call_600840.base,
                         call_600840.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600840, url, valid)

proc call*(call_600841: Call_RemoveTagsFromResource_600828; body: JsonNode): Recallable =
  ## removeTagsFromResource
  ## Removes one or more tags from the specified resource. This operation is supported in storage gateways of all types.
  ##   body: JObject (required)
  var body_600842 = newJObject()
  if body != nil:
    body_600842 = body
  result = call_600841.call(nil, nil, nil, nil, body_600842)

var removeTagsFromResource* = Call_RemoveTagsFromResource_600828(
    name: "removeTagsFromResource", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.RemoveTagsFromResource",
    validator: validate_RemoveTagsFromResource_600829, base: "/",
    url: url_RemoveTagsFromResource_600830, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResetCache_600843 = ref object of OpenApiRestCall_599369
proc url_ResetCache_600845(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ResetCache_600844(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600846 = header.getOrDefault("X-Amz-Date")
  valid_600846 = validateParameter(valid_600846, JString, required = false,
                                 default = nil)
  if valid_600846 != nil:
    section.add "X-Amz-Date", valid_600846
  var valid_600847 = header.getOrDefault("X-Amz-Security-Token")
  valid_600847 = validateParameter(valid_600847, JString, required = false,
                                 default = nil)
  if valid_600847 != nil:
    section.add "X-Amz-Security-Token", valid_600847
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600848 = header.getOrDefault("X-Amz-Target")
  valid_600848 = validateParameter(valid_600848, JString, required = true, default = newJString(
      "StorageGateway_20130630.ResetCache"))
  if valid_600848 != nil:
    section.add "X-Amz-Target", valid_600848
  var valid_600849 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600849 = validateParameter(valid_600849, JString, required = false,
                                 default = nil)
  if valid_600849 != nil:
    section.add "X-Amz-Content-Sha256", valid_600849
  var valid_600850 = header.getOrDefault("X-Amz-Algorithm")
  valid_600850 = validateParameter(valid_600850, JString, required = false,
                                 default = nil)
  if valid_600850 != nil:
    section.add "X-Amz-Algorithm", valid_600850
  var valid_600851 = header.getOrDefault("X-Amz-Signature")
  valid_600851 = validateParameter(valid_600851, JString, required = false,
                                 default = nil)
  if valid_600851 != nil:
    section.add "X-Amz-Signature", valid_600851
  var valid_600852 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600852 = validateParameter(valid_600852, JString, required = false,
                                 default = nil)
  if valid_600852 != nil:
    section.add "X-Amz-SignedHeaders", valid_600852
  var valid_600853 = header.getOrDefault("X-Amz-Credential")
  valid_600853 = validateParameter(valid_600853, JString, required = false,
                                 default = nil)
  if valid_600853 != nil:
    section.add "X-Amz-Credential", valid_600853
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600855: Call_ResetCache_600843; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Resets all cache disks that have encountered a error and makes the disks available for reconfiguration as cache storage. If your cache disk encounters a error, the gateway prevents read and write operations on virtual tapes in the gateway. For example, an error can occur when a disk is corrupted or removed from the gateway. When a cache is reset, the gateway loses its cache storage. At this point you can reconfigure the disks as cache disks. This operation is only supported in the cached volume and tape types.</p> <important> <p>If the cache disk you are resetting contains data that has not been uploaded to Amazon S3 yet, that data can be lost. After you reset cache disks, there will be no configured cache disks left in the gateway, so you must configure at least one new cache disk for your gateway to function properly.</p> </important>
  ## 
  let valid = call_600855.validator(path, query, header, formData, body)
  let scheme = call_600855.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600855.url(scheme.get, call_600855.host, call_600855.base,
                         call_600855.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600855, url, valid)

proc call*(call_600856: Call_ResetCache_600843; body: JsonNode): Recallable =
  ## resetCache
  ## <p>Resets all cache disks that have encountered a error and makes the disks available for reconfiguration as cache storage. If your cache disk encounters a error, the gateway prevents read and write operations on virtual tapes in the gateway. For example, an error can occur when a disk is corrupted or removed from the gateway. When a cache is reset, the gateway loses its cache storage. At this point you can reconfigure the disks as cache disks. This operation is only supported in the cached volume and tape types.</p> <important> <p>If the cache disk you are resetting contains data that has not been uploaded to Amazon S3 yet, that data can be lost. After you reset cache disks, there will be no configured cache disks left in the gateway, so you must configure at least one new cache disk for your gateway to function properly.</p> </important>
  ##   body: JObject (required)
  var body_600857 = newJObject()
  if body != nil:
    body_600857 = body
  result = call_600856.call(nil, nil, nil, nil, body_600857)

var resetCache* = Call_ResetCache_600843(name: "resetCache",
                                      meth: HttpMethod.HttpPost,
                                      host: "storagegateway.amazonaws.com", route: "/#X-Amz-Target=StorageGateway_20130630.ResetCache",
                                      validator: validate_ResetCache_600844,
                                      base: "/", url: url_ResetCache_600845,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_RetrieveTapeArchive_600858 = ref object of OpenApiRestCall_599369
proc url_RetrieveTapeArchive_600860(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RetrieveTapeArchive_600859(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_600861 = header.getOrDefault("X-Amz-Date")
  valid_600861 = validateParameter(valid_600861, JString, required = false,
                                 default = nil)
  if valid_600861 != nil:
    section.add "X-Amz-Date", valid_600861
  var valid_600862 = header.getOrDefault("X-Amz-Security-Token")
  valid_600862 = validateParameter(valid_600862, JString, required = false,
                                 default = nil)
  if valid_600862 != nil:
    section.add "X-Amz-Security-Token", valid_600862
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600863 = header.getOrDefault("X-Amz-Target")
  valid_600863 = validateParameter(valid_600863, JString, required = true, default = newJString(
      "StorageGateway_20130630.RetrieveTapeArchive"))
  if valid_600863 != nil:
    section.add "X-Amz-Target", valid_600863
  var valid_600864 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600864 = validateParameter(valid_600864, JString, required = false,
                                 default = nil)
  if valid_600864 != nil:
    section.add "X-Amz-Content-Sha256", valid_600864
  var valid_600865 = header.getOrDefault("X-Amz-Algorithm")
  valid_600865 = validateParameter(valid_600865, JString, required = false,
                                 default = nil)
  if valid_600865 != nil:
    section.add "X-Amz-Algorithm", valid_600865
  var valid_600866 = header.getOrDefault("X-Amz-Signature")
  valid_600866 = validateParameter(valid_600866, JString, required = false,
                                 default = nil)
  if valid_600866 != nil:
    section.add "X-Amz-Signature", valid_600866
  var valid_600867 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600867 = validateParameter(valid_600867, JString, required = false,
                                 default = nil)
  if valid_600867 != nil:
    section.add "X-Amz-SignedHeaders", valid_600867
  var valid_600868 = header.getOrDefault("X-Amz-Credential")
  valid_600868 = validateParameter(valid_600868, JString, required = false,
                                 default = nil)
  if valid_600868 != nil:
    section.add "X-Amz-Credential", valid_600868
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600870: Call_RetrieveTapeArchive_600858; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves an archived virtual tape from the virtual tape shelf (VTS) to a tape gateway. Virtual tapes archived in the VTS are not associated with any gateway. However after a tape is retrieved, it is associated with a gateway, even though it is also listed in the VTS, that is, archive. This operation is only supported in the tape gateway type.</p> <p>Once a tape is successfully retrieved to a gateway, it cannot be retrieved again to another gateway. You must archive the tape again before you can retrieve it to another gateway. This operation is only supported in the tape gateway type.</p>
  ## 
  let valid = call_600870.validator(path, query, header, formData, body)
  let scheme = call_600870.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600870.url(scheme.get, call_600870.host, call_600870.base,
                         call_600870.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600870, url, valid)

proc call*(call_600871: Call_RetrieveTapeArchive_600858; body: JsonNode): Recallable =
  ## retrieveTapeArchive
  ## <p>Retrieves an archived virtual tape from the virtual tape shelf (VTS) to a tape gateway. Virtual tapes archived in the VTS are not associated with any gateway. However after a tape is retrieved, it is associated with a gateway, even though it is also listed in the VTS, that is, archive. This operation is only supported in the tape gateway type.</p> <p>Once a tape is successfully retrieved to a gateway, it cannot be retrieved again to another gateway. You must archive the tape again before you can retrieve it to another gateway. This operation is only supported in the tape gateway type.</p>
  ##   body: JObject (required)
  var body_600872 = newJObject()
  if body != nil:
    body_600872 = body
  result = call_600871.call(nil, nil, nil, nil, body_600872)

var retrieveTapeArchive* = Call_RetrieveTapeArchive_600858(
    name: "retrieveTapeArchive", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.RetrieveTapeArchive",
    validator: validate_RetrieveTapeArchive_600859, base: "/",
    url: url_RetrieveTapeArchive_600860, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RetrieveTapeRecoveryPoint_600873 = ref object of OpenApiRestCall_599369
proc url_RetrieveTapeRecoveryPoint_600875(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RetrieveTapeRecoveryPoint_600874(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600876 = header.getOrDefault("X-Amz-Date")
  valid_600876 = validateParameter(valid_600876, JString, required = false,
                                 default = nil)
  if valid_600876 != nil:
    section.add "X-Amz-Date", valid_600876
  var valid_600877 = header.getOrDefault("X-Amz-Security-Token")
  valid_600877 = validateParameter(valid_600877, JString, required = false,
                                 default = nil)
  if valid_600877 != nil:
    section.add "X-Amz-Security-Token", valid_600877
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600878 = header.getOrDefault("X-Amz-Target")
  valid_600878 = validateParameter(valid_600878, JString, required = true, default = newJString(
      "StorageGateway_20130630.RetrieveTapeRecoveryPoint"))
  if valid_600878 != nil:
    section.add "X-Amz-Target", valid_600878
  var valid_600879 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600879 = validateParameter(valid_600879, JString, required = false,
                                 default = nil)
  if valid_600879 != nil:
    section.add "X-Amz-Content-Sha256", valid_600879
  var valid_600880 = header.getOrDefault("X-Amz-Algorithm")
  valid_600880 = validateParameter(valid_600880, JString, required = false,
                                 default = nil)
  if valid_600880 != nil:
    section.add "X-Amz-Algorithm", valid_600880
  var valid_600881 = header.getOrDefault("X-Amz-Signature")
  valid_600881 = validateParameter(valid_600881, JString, required = false,
                                 default = nil)
  if valid_600881 != nil:
    section.add "X-Amz-Signature", valid_600881
  var valid_600882 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600882 = validateParameter(valid_600882, JString, required = false,
                                 default = nil)
  if valid_600882 != nil:
    section.add "X-Amz-SignedHeaders", valid_600882
  var valid_600883 = header.getOrDefault("X-Amz-Credential")
  valid_600883 = validateParameter(valid_600883, JString, required = false,
                                 default = nil)
  if valid_600883 != nil:
    section.add "X-Amz-Credential", valid_600883
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600885: Call_RetrieveTapeRecoveryPoint_600873; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the recovery point for the specified virtual tape. This operation is only supported in the tape gateway type.</p> <p>A recovery point is a point in time view of a virtual tape at which all the data on the tape is consistent. If your gateway crashes, virtual tapes that have recovery points can be recovered to a new gateway.</p> <note> <p>The virtual tape can be retrieved to only one gateway. The retrieved tape is read-only. The virtual tape can be retrieved to only a tape gateway. There is no charge for retrieving recovery points.</p> </note>
  ## 
  let valid = call_600885.validator(path, query, header, formData, body)
  let scheme = call_600885.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600885.url(scheme.get, call_600885.host, call_600885.base,
                         call_600885.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600885, url, valid)

proc call*(call_600886: Call_RetrieveTapeRecoveryPoint_600873; body: JsonNode): Recallable =
  ## retrieveTapeRecoveryPoint
  ## <p>Retrieves the recovery point for the specified virtual tape. This operation is only supported in the tape gateway type.</p> <p>A recovery point is a point in time view of a virtual tape at which all the data on the tape is consistent. If your gateway crashes, virtual tapes that have recovery points can be recovered to a new gateway.</p> <note> <p>The virtual tape can be retrieved to only one gateway. The retrieved tape is read-only. The virtual tape can be retrieved to only a tape gateway. There is no charge for retrieving recovery points.</p> </note>
  ##   body: JObject (required)
  var body_600887 = newJObject()
  if body != nil:
    body_600887 = body
  result = call_600886.call(nil, nil, nil, nil, body_600887)

var retrieveTapeRecoveryPoint* = Call_RetrieveTapeRecoveryPoint_600873(
    name: "retrieveTapeRecoveryPoint", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.RetrieveTapeRecoveryPoint",
    validator: validate_RetrieveTapeRecoveryPoint_600874, base: "/",
    url: url_RetrieveTapeRecoveryPoint_600875,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetLocalConsolePassword_600888 = ref object of OpenApiRestCall_599369
proc url_SetLocalConsolePassword_600890(protocol: Scheme; host: string; base: string;
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

proc validate_SetLocalConsolePassword_600889(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600891 = header.getOrDefault("X-Amz-Date")
  valid_600891 = validateParameter(valid_600891, JString, required = false,
                                 default = nil)
  if valid_600891 != nil:
    section.add "X-Amz-Date", valid_600891
  var valid_600892 = header.getOrDefault("X-Amz-Security-Token")
  valid_600892 = validateParameter(valid_600892, JString, required = false,
                                 default = nil)
  if valid_600892 != nil:
    section.add "X-Amz-Security-Token", valid_600892
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600893 = header.getOrDefault("X-Amz-Target")
  valid_600893 = validateParameter(valid_600893, JString, required = true, default = newJString(
      "StorageGateway_20130630.SetLocalConsolePassword"))
  if valid_600893 != nil:
    section.add "X-Amz-Target", valid_600893
  var valid_600894 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600894 = validateParameter(valid_600894, JString, required = false,
                                 default = nil)
  if valid_600894 != nil:
    section.add "X-Amz-Content-Sha256", valid_600894
  var valid_600895 = header.getOrDefault("X-Amz-Algorithm")
  valid_600895 = validateParameter(valid_600895, JString, required = false,
                                 default = nil)
  if valid_600895 != nil:
    section.add "X-Amz-Algorithm", valid_600895
  var valid_600896 = header.getOrDefault("X-Amz-Signature")
  valid_600896 = validateParameter(valid_600896, JString, required = false,
                                 default = nil)
  if valid_600896 != nil:
    section.add "X-Amz-Signature", valid_600896
  var valid_600897 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600897 = validateParameter(valid_600897, JString, required = false,
                                 default = nil)
  if valid_600897 != nil:
    section.add "X-Amz-SignedHeaders", valid_600897
  var valid_600898 = header.getOrDefault("X-Amz-Credential")
  valid_600898 = validateParameter(valid_600898, JString, required = false,
                                 default = nil)
  if valid_600898 != nil:
    section.add "X-Amz-Credential", valid_600898
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600900: Call_SetLocalConsolePassword_600888; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the password for your VM local console. When you log in to the local console for the first time, you log in to the VM with the default credentials. We recommend that you set a new password. You don't need to know the default password to set a new password.
  ## 
  let valid = call_600900.validator(path, query, header, formData, body)
  let scheme = call_600900.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600900.url(scheme.get, call_600900.host, call_600900.base,
                         call_600900.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600900, url, valid)

proc call*(call_600901: Call_SetLocalConsolePassword_600888; body: JsonNode): Recallable =
  ## setLocalConsolePassword
  ## Sets the password for your VM local console. When you log in to the local console for the first time, you log in to the VM with the default credentials. We recommend that you set a new password. You don't need to know the default password to set a new password.
  ##   body: JObject (required)
  var body_600902 = newJObject()
  if body != nil:
    body_600902 = body
  result = call_600901.call(nil, nil, nil, nil, body_600902)

var setLocalConsolePassword* = Call_SetLocalConsolePassword_600888(
    name: "setLocalConsolePassword", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.SetLocalConsolePassword",
    validator: validate_SetLocalConsolePassword_600889, base: "/",
    url: url_SetLocalConsolePassword_600890, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetSMBGuestPassword_600903 = ref object of OpenApiRestCall_599369
proc url_SetSMBGuestPassword_600905(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SetSMBGuestPassword_600904(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_600906 = header.getOrDefault("X-Amz-Date")
  valid_600906 = validateParameter(valid_600906, JString, required = false,
                                 default = nil)
  if valid_600906 != nil:
    section.add "X-Amz-Date", valid_600906
  var valid_600907 = header.getOrDefault("X-Amz-Security-Token")
  valid_600907 = validateParameter(valid_600907, JString, required = false,
                                 default = nil)
  if valid_600907 != nil:
    section.add "X-Amz-Security-Token", valid_600907
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600908 = header.getOrDefault("X-Amz-Target")
  valid_600908 = validateParameter(valid_600908, JString, required = true, default = newJString(
      "StorageGateway_20130630.SetSMBGuestPassword"))
  if valid_600908 != nil:
    section.add "X-Amz-Target", valid_600908
  var valid_600909 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600909 = validateParameter(valid_600909, JString, required = false,
                                 default = nil)
  if valid_600909 != nil:
    section.add "X-Amz-Content-Sha256", valid_600909
  var valid_600910 = header.getOrDefault("X-Amz-Algorithm")
  valid_600910 = validateParameter(valid_600910, JString, required = false,
                                 default = nil)
  if valid_600910 != nil:
    section.add "X-Amz-Algorithm", valid_600910
  var valid_600911 = header.getOrDefault("X-Amz-Signature")
  valid_600911 = validateParameter(valid_600911, JString, required = false,
                                 default = nil)
  if valid_600911 != nil:
    section.add "X-Amz-Signature", valid_600911
  var valid_600912 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600912 = validateParameter(valid_600912, JString, required = false,
                                 default = nil)
  if valid_600912 != nil:
    section.add "X-Amz-SignedHeaders", valid_600912
  var valid_600913 = header.getOrDefault("X-Amz-Credential")
  valid_600913 = validateParameter(valid_600913, JString, required = false,
                                 default = nil)
  if valid_600913 != nil:
    section.add "X-Amz-Credential", valid_600913
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600915: Call_SetSMBGuestPassword_600903; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the password for the guest user <code>smbguest</code>. The <code>smbguest</code> user is the user when the authentication method for the file share is set to <code>GuestAccess</code>.
  ## 
  let valid = call_600915.validator(path, query, header, formData, body)
  let scheme = call_600915.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600915.url(scheme.get, call_600915.host, call_600915.base,
                         call_600915.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600915, url, valid)

proc call*(call_600916: Call_SetSMBGuestPassword_600903; body: JsonNode): Recallable =
  ## setSMBGuestPassword
  ## Sets the password for the guest user <code>smbguest</code>. The <code>smbguest</code> user is the user when the authentication method for the file share is set to <code>GuestAccess</code>.
  ##   body: JObject (required)
  var body_600917 = newJObject()
  if body != nil:
    body_600917 = body
  result = call_600916.call(nil, nil, nil, nil, body_600917)

var setSMBGuestPassword* = Call_SetSMBGuestPassword_600903(
    name: "setSMBGuestPassword", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.SetSMBGuestPassword",
    validator: validate_SetSMBGuestPassword_600904, base: "/",
    url: url_SetSMBGuestPassword_600905, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ShutdownGateway_600918 = ref object of OpenApiRestCall_599369
proc url_ShutdownGateway_600920(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ShutdownGateway_600919(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
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
  var valid_600921 = header.getOrDefault("X-Amz-Date")
  valid_600921 = validateParameter(valid_600921, JString, required = false,
                                 default = nil)
  if valid_600921 != nil:
    section.add "X-Amz-Date", valid_600921
  var valid_600922 = header.getOrDefault("X-Amz-Security-Token")
  valid_600922 = validateParameter(valid_600922, JString, required = false,
                                 default = nil)
  if valid_600922 != nil:
    section.add "X-Amz-Security-Token", valid_600922
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600923 = header.getOrDefault("X-Amz-Target")
  valid_600923 = validateParameter(valid_600923, JString, required = true, default = newJString(
      "StorageGateway_20130630.ShutdownGateway"))
  if valid_600923 != nil:
    section.add "X-Amz-Target", valid_600923
  var valid_600924 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600924 = validateParameter(valid_600924, JString, required = false,
                                 default = nil)
  if valid_600924 != nil:
    section.add "X-Amz-Content-Sha256", valid_600924
  var valid_600925 = header.getOrDefault("X-Amz-Algorithm")
  valid_600925 = validateParameter(valid_600925, JString, required = false,
                                 default = nil)
  if valid_600925 != nil:
    section.add "X-Amz-Algorithm", valid_600925
  var valid_600926 = header.getOrDefault("X-Amz-Signature")
  valid_600926 = validateParameter(valid_600926, JString, required = false,
                                 default = nil)
  if valid_600926 != nil:
    section.add "X-Amz-Signature", valid_600926
  var valid_600927 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600927 = validateParameter(valid_600927, JString, required = false,
                                 default = nil)
  if valid_600927 != nil:
    section.add "X-Amz-SignedHeaders", valid_600927
  var valid_600928 = header.getOrDefault("X-Amz-Credential")
  valid_600928 = validateParameter(valid_600928, JString, required = false,
                                 default = nil)
  if valid_600928 != nil:
    section.add "X-Amz-Credential", valid_600928
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600930: Call_ShutdownGateway_600918; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Shuts down a gateway. To specify which gateway to shut down, use the Amazon Resource Name (ARN) of the gateway in the body of your request.</p> <p>The operation shuts down the gateway service component running in the gateway's virtual machine (VM) and not the host VM.</p> <note> <p>If you want to shut down the VM, it is recommended that you first shut down the gateway component in the VM to avoid unpredictable conditions.</p> </note> <p>After the gateway is shutdown, you cannot call any other API except <a>StartGateway</a>, <a>DescribeGatewayInformation</a>, and <a>ListGateways</a>. For more information, see <a>ActivateGateway</a>. Your applications cannot read from or write to the gateway's storage volumes, and there are no snapshots taken.</p> <note> <p>When you make a shutdown request, you will get a <code>200 OK</code> success response immediately. However, it might take some time for the gateway to shut down. You can call the <a>DescribeGatewayInformation</a> API to check the status. For more information, see <a>ActivateGateway</a>.</p> </note> <p>If do not intend to use the gateway again, you must delete the gateway (using <a>DeleteGateway</a>) to no longer pay software charges associated with the gateway.</p>
  ## 
  let valid = call_600930.validator(path, query, header, formData, body)
  let scheme = call_600930.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600930.url(scheme.get, call_600930.host, call_600930.base,
                         call_600930.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600930, url, valid)

proc call*(call_600931: Call_ShutdownGateway_600918; body: JsonNode): Recallable =
  ## shutdownGateway
  ## <p>Shuts down a gateway. To specify which gateway to shut down, use the Amazon Resource Name (ARN) of the gateway in the body of your request.</p> <p>The operation shuts down the gateway service component running in the gateway's virtual machine (VM) and not the host VM.</p> <note> <p>If you want to shut down the VM, it is recommended that you first shut down the gateway component in the VM to avoid unpredictable conditions.</p> </note> <p>After the gateway is shutdown, you cannot call any other API except <a>StartGateway</a>, <a>DescribeGatewayInformation</a>, and <a>ListGateways</a>. For more information, see <a>ActivateGateway</a>. Your applications cannot read from or write to the gateway's storage volumes, and there are no snapshots taken.</p> <note> <p>When you make a shutdown request, you will get a <code>200 OK</code> success response immediately. However, it might take some time for the gateway to shut down. You can call the <a>DescribeGatewayInformation</a> API to check the status. For more information, see <a>ActivateGateway</a>.</p> </note> <p>If do not intend to use the gateway again, you must delete the gateway (using <a>DeleteGateway</a>) to no longer pay software charges associated with the gateway.</p>
  ##   body: JObject (required)
  var body_600932 = newJObject()
  if body != nil:
    body_600932 = body
  result = call_600931.call(nil, nil, nil, nil, body_600932)

var shutdownGateway* = Call_ShutdownGateway_600918(name: "shutdownGateway",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.ShutdownGateway",
    validator: validate_ShutdownGateway_600919, base: "/", url: url_ShutdownGateway_600920,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartAvailabilityMonitorTest_600933 = ref object of OpenApiRestCall_599369
proc url_StartAvailabilityMonitorTest_600935(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartAvailabilityMonitorTest_600934(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600936 = header.getOrDefault("X-Amz-Date")
  valid_600936 = validateParameter(valid_600936, JString, required = false,
                                 default = nil)
  if valid_600936 != nil:
    section.add "X-Amz-Date", valid_600936
  var valid_600937 = header.getOrDefault("X-Amz-Security-Token")
  valid_600937 = validateParameter(valid_600937, JString, required = false,
                                 default = nil)
  if valid_600937 != nil:
    section.add "X-Amz-Security-Token", valid_600937
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600938 = header.getOrDefault("X-Amz-Target")
  valid_600938 = validateParameter(valid_600938, JString, required = true, default = newJString(
      "StorageGateway_20130630.StartAvailabilityMonitorTest"))
  if valid_600938 != nil:
    section.add "X-Amz-Target", valid_600938
  var valid_600939 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600939 = validateParameter(valid_600939, JString, required = false,
                                 default = nil)
  if valid_600939 != nil:
    section.add "X-Amz-Content-Sha256", valid_600939
  var valid_600940 = header.getOrDefault("X-Amz-Algorithm")
  valid_600940 = validateParameter(valid_600940, JString, required = false,
                                 default = nil)
  if valid_600940 != nil:
    section.add "X-Amz-Algorithm", valid_600940
  var valid_600941 = header.getOrDefault("X-Amz-Signature")
  valid_600941 = validateParameter(valid_600941, JString, required = false,
                                 default = nil)
  if valid_600941 != nil:
    section.add "X-Amz-Signature", valid_600941
  var valid_600942 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600942 = validateParameter(valid_600942, JString, required = false,
                                 default = nil)
  if valid_600942 != nil:
    section.add "X-Amz-SignedHeaders", valid_600942
  var valid_600943 = header.getOrDefault("X-Amz-Credential")
  valid_600943 = validateParameter(valid_600943, JString, required = false,
                                 default = nil)
  if valid_600943 != nil:
    section.add "X-Amz-Credential", valid_600943
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600945: Call_StartAvailabilityMonitorTest_600933; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Start a test that verifies that the specified gateway is configured for High Availability monitoring in your host environment. This request only initiates the test and that a successful response only indicates that the test was started. It doesn't indicate that the test passed. For the status of the test, invoke the <code>DescribeAvailabilityMonitorTest</code> API. </p> <note> <p>Starting this test will cause your gateway to go offline for a brief period.</p> </note>
  ## 
  let valid = call_600945.validator(path, query, header, formData, body)
  let scheme = call_600945.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600945.url(scheme.get, call_600945.host, call_600945.base,
                         call_600945.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600945, url, valid)

proc call*(call_600946: Call_StartAvailabilityMonitorTest_600933; body: JsonNode): Recallable =
  ## startAvailabilityMonitorTest
  ## <p>Start a test that verifies that the specified gateway is configured for High Availability monitoring in your host environment. This request only initiates the test and that a successful response only indicates that the test was started. It doesn't indicate that the test passed. For the status of the test, invoke the <code>DescribeAvailabilityMonitorTest</code> API. </p> <note> <p>Starting this test will cause your gateway to go offline for a brief period.</p> </note>
  ##   body: JObject (required)
  var body_600947 = newJObject()
  if body != nil:
    body_600947 = body
  result = call_600946.call(nil, nil, nil, nil, body_600947)

var startAvailabilityMonitorTest* = Call_StartAvailabilityMonitorTest_600933(
    name: "startAvailabilityMonitorTest", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com", route: "/#X-Amz-Target=StorageGateway_20130630.StartAvailabilityMonitorTest",
    validator: validate_StartAvailabilityMonitorTest_600934, base: "/",
    url: url_StartAvailabilityMonitorTest_600935,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartGateway_600948 = ref object of OpenApiRestCall_599369
proc url_StartGateway_600950(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartGateway_600949(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600951 = header.getOrDefault("X-Amz-Date")
  valid_600951 = validateParameter(valid_600951, JString, required = false,
                                 default = nil)
  if valid_600951 != nil:
    section.add "X-Amz-Date", valid_600951
  var valid_600952 = header.getOrDefault("X-Amz-Security-Token")
  valid_600952 = validateParameter(valid_600952, JString, required = false,
                                 default = nil)
  if valid_600952 != nil:
    section.add "X-Amz-Security-Token", valid_600952
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600953 = header.getOrDefault("X-Amz-Target")
  valid_600953 = validateParameter(valid_600953, JString, required = true, default = newJString(
      "StorageGateway_20130630.StartGateway"))
  if valid_600953 != nil:
    section.add "X-Amz-Target", valid_600953
  var valid_600954 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600954 = validateParameter(valid_600954, JString, required = false,
                                 default = nil)
  if valid_600954 != nil:
    section.add "X-Amz-Content-Sha256", valid_600954
  var valid_600955 = header.getOrDefault("X-Amz-Algorithm")
  valid_600955 = validateParameter(valid_600955, JString, required = false,
                                 default = nil)
  if valid_600955 != nil:
    section.add "X-Amz-Algorithm", valid_600955
  var valid_600956 = header.getOrDefault("X-Amz-Signature")
  valid_600956 = validateParameter(valid_600956, JString, required = false,
                                 default = nil)
  if valid_600956 != nil:
    section.add "X-Amz-Signature", valid_600956
  var valid_600957 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600957 = validateParameter(valid_600957, JString, required = false,
                                 default = nil)
  if valid_600957 != nil:
    section.add "X-Amz-SignedHeaders", valid_600957
  var valid_600958 = header.getOrDefault("X-Amz-Credential")
  valid_600958 = validateParameter(valid_600958, JString, required = false,
                                 default = nil)
  if valid_600958 != nil:
    section.add "X-Amz-Credential", valid_600958
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600960: Call_StartGateway_600948; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a gateway that you previously shut down (see <a>ShutdownGateway</a>). After the gateway starts, you can then make other API calls, your applications can read from or write to the gateway's storage volumes and you will be able to take snapshot backups.</p> <note> <p>When you make a request, you will get a 200 OK success response immediately. However, it might take some time for the gateway to be ready. You should call <a>DescribeGatewayInformation</a> and check the status before making any additional API calls. For more information, see <a>ActivateGateway</a>.</p> </note> <p>To specify which gateway to start, use the Amazon Resource Name (ARN) of the gateway in your request.</p>
  ## 
  let valid = call_600960.validator(path, query, header, formData, body)
  let scheme = call_600960.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600960.url(scheme.get, call_600960.host, call_600960.base,
                         call_600960.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600960, url, valid)

proc call*(call_600961: Call_StartGateway_600948; body: JsonNode): Recallable =
  ## startGateway
  ## <p>Starts a gateway that you previously shut down (see <a>ShutdownGateway</a>). After the gateway starts, you can then make other API calls, your applications can read from or write to the gateway's storage volumes and you will be able to take snapshot backups.</p> <note> <p>When you make a request, you will get a 200 OK success response immediately. However, it might take some time for the gateway to be ready. You should call <a>DescribeGatewayInformation</a> and check the status before making any additional API calls. For more information, see <a>ActivateGateway</a>.</p> </note> <p>To specify which gateway to start, use the Amazon Resource Name (ARN) of the gateway in your request.</p>
  ##   body: JObject (required)
  var body_600962 = newJObject()
  if body != nil:
    body_600962 = body
  result = call_600961.call(nil, nil, nil, nil, body_600962)

var startGateway* = Call_StartGateway_600948(name: "startGateway",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.StartGateway",
    validator: validate_StartGateway_600949, base: "/", url: url_StartGateway_600950,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBandwidthRateLimit_600963 = ref object of OpenApiRestCall_599369
proc url_UpdateBandwidthRateLimit_600965(protocol: Scheme; host: string;
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

proc validate_UpdateBandwidthRateLimit_600964(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600966 = header.getOrDefault("X-Amz-Date")
  valid_600966 = validateParameter(valid_600966, JString, required = false,
                                 default = nil)
  if valid_600966 != nil:
    section.add "X-Amz-Date", valid_600966
  var valid_600967 = header.getOrDefault("X-Amz-Security-Token")
  valid_600967 = validateParameter(valid_600967, JString, required = false,
                                 default = nil)
  if valid_600967 != nil:
    section.add "X-Amz-Security-Token", valid_600967
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600968 = header.getOrDefault("X-Amz-Target")
  valid_600968 = validateParameter(valid_600968, JString, required = true, default = newJString(
      "StorageGateway_20130630.UpdateBandwidthRateLimit"))
  if valid_600968 != nil:
    section.add "X-Amz-Target", valid_600968
  var valid_600969 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600969 = validateParameter(valid_600969, JString, required = false,
                                 default = nil)
  if valid_600969 != nil:
    section.add "X-Amz-Content-Sha256", valid_600969
  var valid_600970 = header.getOrDefault("X-Amz-Algorithm")
  valid_600970 = validateParameter(valid_600970, JString, required = false,
                                 default = nil)
  if valid_600970 != nil:
    section.add "X-Amz-Algorithm", valid_600970
  var valid_600971 = header.getOrDefault("X-Amz-Signature")
  valid_600971 = validateParameter(valid_600971, JString, required = false,
                                 default = nil)
  if valid_600971 != nil:
    section.add "X-Amz-Signature", valid_600971
  var valid_600972 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600972 = validateParameter(valid_600972, JString, required = false,
                                 default = nil)
  if valid_600972 != nil:
    section.add "X-Amz-SignedHeaders", valid_600972
  var valid_600973 = header.getOrDefault("X-Amz-Credential")
  valid_600973 = validateParameter(valid_600973, JString, required = false,
                                 default = nil)
  if valid_600973 != nil:
    section.add "X-Amz-Credential", valid_600973
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600975: Call_UpdateBandwidthRateLimit_600963; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the bandwidth rate limits of a gateway. You can update both the upload and download bandwidth rate limit or specify only one of the two. If you don't set a bandwidth rate limit, the existing rate limit remains. This operation is supported for the stored volume, cached volume and tape gateway types.'</p> <p>By default, a gateway's bandwidth rate limits are not set. If you don't set any limit, the gateway does not have any limitations on its bandwidth usage and could potentially use the maximum available bandwidth.</p> <p>To specify which gateway to update, use the Amazon Resource Name (ARN) of the gateway in your request.</p>
  ## 
  let valid = call_600975.validator(path, query, header, formData, body)
  let scheme = call_600975.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600975.url(scheme.get, call_600975.host, call_600975.base,
                         call_600975.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600975, url, valid)

proc call*(call_600976: Call_UpdateBandwidthRateLimit_600963; body: JsonNode): Recallable =
  ## updateBandwidthRateLimit
  ## <p>Updates the bandwidth rate limits of a gateway. You can update both the upload and download bandwidth rate limit or specify only one of the two. If you don't set a bandwidth rate limit, the existing rate limit remains. This operation is supported for the stored volume, cached volume and tape gateway types.'</p> <p>By default, a gateway's bandwidth rate limits are not set. If you don't set any limit, the gateway does not have any limitations on its bandwidth usage and could potentially use the maximum available bandwidth.</p> <p>To specify which gateway to update, use the Amazon Resource Name (ARN) of the gateway in your request.</p>
  ##   body: JObject (required)
  var body_600977 = newJObject()
  if body != nil:
    body_600977 = body
  result = call_600976.call(nil, nil, nil, nil, body_600977)

var updateBandwidthRateLimit* = Call_UpdateBandwidthRateLimit_600963(
    name: "updateBandwidthRateLimit", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.UpdateBandwidthRateLimit",
    validator: validate_UpdateBandwidthRateLimit_600964, base: "/",
    url: url_UpdateBandwidthRateLimit_600965, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateChapCredentials_600978 = ref object of OpenApiRestCall_599369
proc url_UpdateChapCredentials_600980(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateChapCredentials_600979(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600981 = header.getOrDefault("X-Amz-Date")
  valid_600981 = validateParameter(valid_600981, JString, required = false,
                                 default = nil)
  if valid_600981 != nil:
    section.add "X-Amz-Date", valid_600981
  var valid_600982 = header.getOrDefault("X-Amz-Security-Token")
  valid_600982 = validateParameter(valid_600982, JString, required = false,
                                 default = nil)
  if valid_600982 != nil:
    section.add "X-Amz-Security-Token", valid_600982
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600983 = header.getOrDefault("X-Amz-Target")
  valid_600983 = validateParameter(valid_600983, JString, required = true, default = newJString(
      "StorageGateway_20130630.UpdateChapCredentials"))
  if valid_600983 != nil:
    section.add "X-Amz-Target", valid_600983
  var valid_600984 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600984 = validateParameter(valid_600984, JString, required = false,
                                 default = nil)
  if valid_600984 != nil:
    section.add "X-Amz-Content-Sha256", valid_600984
  var valid_600985 = header.getOrDefault("X-Amz-Algorithm")
  valid_600985 = validateParameter(valid_600985, JString, required = false,
                                 default = nil)
  if valid_600985 != nil:
    section.add "X-Amz-Algorithm", valid_600985
  var valid_600986 = header.getOrDefault("X-Amz-Signature")
  valid_600986 = validateParameter(valid_600986, JString, required = false,
                                 default = nil)
  if valid_600986 != nil:
    section.add "X-Amz-Signature", valid_600986
  var valid_600987 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600987 = validateParameter(valid_600987, JString, required = false,
                                 default = nil)
  if valid_600987 != nil:
    section.add "X-Amz-SignedHeaders", valid_600987
  var valid_600988 = header.getOrDefault("X-Amz-Credential")
  valid_600988 = validateParameter(valid_600988, JString, required = false,
                                 default = nil)
  if valid_600988 != nil:
    section.add "X-Amz-Credential", valid_600988
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600990: Call_UpdateChapCredentials_600978; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the Challenge-Handshake Authentication Protocol (CHAP) credentials for a specified iSCSI target. By default, a gateway does not have CHAP enabled; however, for added security, you might use it. This operation is supported in the volume and tape gateway types.</p> <important> <p>When you update CHAP credentials, all existing connections on the target are closed and initiators must reconnect with the new credentials.</p> </important>
  ## 
  let valid = call_600990.validator(path, query, header, formData, body)
  let scheme = call_600990.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600990.url(scheme.get, call_600990.host, call_600990.base,
                         call_600990.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600990, url, valid)

proc call*(call_600991: Call_UpdateChapCredentials_600978; body: JsonNode): Recallable =
  ## updateChapCredentials
  ## <p>Updates the Challenge-Handshake Authentication Protocol (CHAP) credentials for a specified iSCSI target. By default, a gateway does not have CHAP enabled; however, for added security, you might use it. This operation is supported in the volume and tape gateway types.</p> <important> <p>When you update CHAP credentials, all existing connections on the target are closed and initiators must reconnect with the new credentials.</p> </important>
  ##   body: JObject (required)
  var body_600992 = newJObject()
  if body != nil:
    body_600992 = body
  result = call_600991.call(nil, nil, nil, nil, body_600992)

var updateChapCredentials* = Call_UpdateChapCredentials_600978(
    name: "updateChapCredentials", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.UpdateChapCredentials",
    validator: validate_UpdateChapCredentials_600979, base: "/",
    url: url_UpdateChapCredentials_600980, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGatewayInformation_600993 = ref object of OpenApiRestCall_599369
proc url_UpdateGatewayInformation_600995(protocol: Scheme; host: string;
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

proc validate_UpdateGatewayInformation_600994(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600996 = header.getOrDefault("X-Amz-Date")
  valid_600996 = validateParameter(valid_600996, JString, required = false,
                                 default = nil)
  if valid_600996 != nil:
    section.add "X-Amz-Date", valid_600996
  var valid_600997 = header.getOrDefault("X-Amz-Security-Token")
  valid_600997 = validateParameter(valid_600997, JString, required = false,
                                 default = nil)
  if valid_600997 != nil:
    section.add "X-Amz-Security-Token", valid_600997
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600998 = header.getOrDefault("X-Amz-Target")
  valid_600998 = validateParameter(valid_600998, JString, required = true, default = newJString(
      "StorageGateway_20130630.UpdateGatewayInformation"))
  if valid_600998 != nil:
    section.add "X-Amz-Target", valid_600998
  var valid_600999 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600999 = validateParameter(valid_600999, JString, required = false,
                                 default = nil)
  if valid_600999 != nil:
    section.add "X-Amz-Content-Sha256", valid_600999
  var valid_601000 = header.getOrDefault("X-Amz-Algorithm")
  valid_601000 = validateParameter(valid_601000, JString, required = false,
                                 default = nil)
  if valid_601000 != nil:
    section.add "X-Amz-Algorithm", valid_601000
  var valid_601001 = header.getOrDefault("X-Amz-Signature")
  valid_601001 = validateParameter(valid_601001, JString, required = false,
                                 default = nil)
  if valid_601001 != nil:
    section.add "X-Amz-Signature", valid_601001
  var valid_601002 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601002 = validateParameter(valid_601002, JString, required = false,
                                 default = nil)
  if valid_601002 != nil:
    section.add "X-Amz-SignedHeaders", valid_601002
  var valid_601003 = header.getOrDefault("X-Amz-Credential")
  valid_601003 = validateParameter(valid_601003, JString, required = false,
                                 default = nil)
  if valid_601003 != nil:
    section.add "X-Amz-Credential", valid_601003
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601005: Call_UpdateGatewayInformation_600993; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates a gateway's metadata, which includes the gateway's name and time zone. To specify which gateway to update, use the Amazon Resource Name (ARN) of the gateway in your request.</p> <note> <p>For Gateways activated after September 2, 2015, the gateway's ARN contains the gateway ID rather than the gateway name. However, changing the name of the gateway has no effect on the gateway's ARN.</p> </note>
  ## 
  let valid = call_601005.validator(path, query, header, formData, body)
  let scheme = call_601005.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601005.url(scheme.get, call_601005.host, call_601005.base,
                         call_601005.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601005, url, valid)

proc call*(call_601006: Call_UpdateGatewayInformation_600993; body: JsonNode): Recallable =
  ## updateGatewayInformation
  ## <p>Updates a gateway's metadata, which includes the gateway's name and time zone. To specify which gateway to update, use the Amazon Resource Name (ARN) of the gateway in your request.</p> <note> <p>For Gateways activated after September 2, 2015, the gateway's ARN contains the gateway ID rather than the gateway name. However, changing the name of the gateway has no effect on the gateway's ARN.</p> </note>
  ##   body: JObject (required)
  var body_601007 = newJObject()
  if body != nil:
    body_601007 = body
  result = call_601006.call(nil, nil, nil, nil, body_601007)

var updateGatewayInformation* = Call_UpdateGatewayInformation_600993(
    name: "updateGatewayInformation", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.UpdateGatewayInformation",
    validator: validate_UpdateGatewayInformation_600994, base: "/",
    url: url_UpdateGatewayInformation_600995, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGatewaySoftwareNow_601008 = ref object of OpenApiRestCall_599369
proc url_UpdateGatewaySoftwareNow_601010(protocol: Scheme; host: string;
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

proc validate_UpdateGatewaySoftwareNow_601009(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601011 = header.getOrDefault("X-Amz-Date")
  valid_601011 = validateParameter(valid_601011, JString, required = false,
                                 default = nil)
  if valid_601011 != nil:
    section.add "X-Amz-Date", valid_601011
  var valid_601012 = header.getOrDefault("X-Amz-Security-Token")
  valid_601012 = validateParameter(valid_601012, JString, required = false,
                                 default = nil)
  if valid_601012 != nil:
    section.add "X-Amz-Security-Token", valid_601012
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601013 = header.getOrDefault("X-Amz-Target")
  valid_601013 = validateParameter(valid_601013, JString, required = true, default = newJString(
      "StorageGateway_20130630.UpdateGatewaySoftwareNow"))
  if valid_601013 != nil:
    section.add "X-Amz-Target", valid_601013
  var valid_601014 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601014 = validateParameter(valid_601014, JString, required = false,
                                 default = nil)
  if valid_601014 != nil:
    section.add "X-Amz-Content-Sha256", valid_601014
  var valid_601015 = header.getOrDefault("X-Amz-Algorithm")
  valid_601015 = validateParameter(valid_601015, JString, required = false,
                                 default = nil)
  if valid_601015 != nil:
    section.add "X-Amz-Algorithm", valid_601015
  var valid_601016 = header.getOrDefault("X-Amz-Signature")
  valid_601016 = validateParameter(valid_601016, JString, required = false,
                                 default = nil)
  if valid_601016 != nil:
    section.add "X-Amz-Signature", valid_601016
  var valid_601017 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601017 = validateParameter(valid_601017, JString, required = false,
                                 default = nil)
  if valid_601017 != nil:
    section.add "X-Amz-SignedHeaders", valid_601017
  var valid_601018 = header.getOrDefault("X-Amz-Credential")
  valid_601018 = validateParameter(valid_601018, JString, required = false,
                                 default = nil)
  if valid_601018 != nil:
    section.add "X-Amz-Credential", valid_601018
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601020: Call_UpdateGatewaySoftwareNow_601008; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the gateway virtual machine (VM) software. The request immediately triggers the software update.</p> <note> <p>When you make this request, you get a <code>200 OK</code> success response immediately. However, it might take some time for the update to complete. You can call <a>DescribeGatewayInformation</a> to verify the gateway is in the <code>STATE_RUNNING</code> state.</p> </note> <important> <p>A software update forces a system restart of your gateway. You can minimize the chance of any disruption to your applications by increasing your iSCSI Initiators' timeouts. For more information about increasing iSCSI Initiator timeouts for Windows and Linux, see <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/ConfiguringiSCSIClientInitiatorWindowsClient.html#CustomizeWindowsiSCSISettings">Customizing Your Windows iSCSI Settings</a> and <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/ConfiguringiSCSIClientInitiatorRedHatClient.html#CustomizeLinuxiSCSISettings">Customizing Your Linux iSCSI Settings</a>, respectively.</p> </important>
  ## 
  let valid = call_601020.validator(path, query, header, formData, body)
  let scheme = call_601020.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601020.url(scheme.get, call_601020.host, call_601020.base,
                         call_601020.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601020, url, valid)

proc call*(call_601021: Call_UpdateGatewaySoftwareNow_601008; body: JsonNode): Recallable =
  ## updateGatewaySoftwareNow
  ## <p>Updates the gateway virtual machine (VM) software. The request immediately triggers the software update.</p> <note> <p>When you make this request, you get a <code>200 OK</code> success response immediately. However, it might take some time for the update to complete. You can call <a>DescribeGatewayInformation</a> to verify the gateway is in the <code>STATE_RUNNING</code> state.</p> </note> <important> <p>A software update forces a system restart of your gateway. You can minimize the chance of any disruption to your applications by increasing your iSCSI Initiators' timeouts. For more information about increasing iSCSI Initiator timeouts for Windows and Linux, see <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/ConfiguringiSCSIClientInitiatorWindowsClient.html#CustomizeWindowsiSCSISettings">Customizing Your Windows iSCSI Settings</a> and <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/ConfiguringiSCSIClientInitiatorRedHatClient.html#CustomizeLinuxiSCSISettings">Customizing Your Linux iSCSI Settings</a>, respectively.</p> </important>
  ##   body: JObject (required)
  var body_601022 = newJObject()
  if body != nil:
    body_601022 = body
  result = call_601021.call(nil, nil, nil, nil, body_601022)

var updateGatewaySoftwareNow* = Call_UpdateGatewaySoftwareNow_601008(
    name: "updateGatewaySoftwareNow", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.UpdateGatewaySoftwareNow",
    validator: validate_UpdateGatewaySoftwareNow_601009, base: "/",
    url: url_UpdateGatewaySoftwareNow_601010, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMaintenanceStartTime_601023 = ref object of OpenApiRestCall_599369
proc url_UpdateMaintenanceStartTime_601025(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateMaintenanceStartTime_601024(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601026 = header.getOrDefault("X-Amz-Date")
  valid_601026 = validateParameter(valid_601026, JString, required = false,
                                 default = nil)
  if valid_601026 != nil:
    section.add "X-Amz-Date", valid_601026
  var valid_601027 = header.getOrDefault("X-Amz-Security-Token")
  valid_601027 = validateParameter(valid_601027, JString, required = false,
                                 default = nil)
  if valid_601027 != nil:
    section.add "X-Amz-Security-Token", valid_601027
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601028 = header.getOrDefault("X-Amz-Target")
  valid_601028 = validateParameter(valid_601028, JString, required = true, default = newJString(
      "StorageGateway_20130630.UpdateMaintenanceStartTime"))
  if valid_601028 != nil:
    section.add "X-Amz-Target", valid_601028
  var valid_601029 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601029 = validateParameter(valid_601029, JString, required = false,
                                 default = nil)
  if valid_601029 != nil:
    section.add "X-Amz-Content-Sha256", valid_601029
  var valid_601030 = header.getOrDefault("X-Amz-Algorithm")
  valid_601030 = validateParameter(valid_601030, JString, required = false,
                                 default = nil)
  if valid_601030 != nil:
    section.add "X-Amz-Algorithm", valid_601030
  var valid_601031 = header.getOrDefault("X-Amz-Signature")
  valid_601031 = validateParameter(valid_601031, JString, required = false,
                                 default = nil)
  if valid_601031 != nil:
    section.add "X-Amz-Signature", valid_601031
  var valid_601032 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601032 = validateParameter(valid_601032, JString, required = false,
                                 default = nil)
  if valid_601032 != nil:
    section.add "X-Amz-SignedHeaders", valid_601032
  var valid_601033 = header.getOrDefault("X-Amz-Credential")
  valid_601033 = validateParameter(valid_601033, JString, required = false,
                                 default = nil)
  if valid_601033 != nil:
    section.add "X-Amz-Credential", valid_601033
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601035: Call_UpdateMaintenanceStartTime_601023; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a gateway's weekly maintenance start time information, including day and time of the week. The maintenance time is the time in your gateway's time zone.
  ## 
  let valid = call_601035.validator(path, query, header, formData, body)
  let scheme = call_601035.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601035.url(scheme.get, call_601035.host, call_601035.base,
                         call_601035.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601035, url, valid)

proc call*(call_601036: Call_UpdateMaintenanceStartTime_601023; body: JsonNode): Recallable =
  ## updateMaintenanceStartTime
  ## Updates a gateway's weekly maintenance start time information, including day and time of the week. The maintenance time is the time in your gateway's time zone.
  ##   body: JObject (required)
  var body_601037 = newJObject()
  if body != nil:
    body_601037 = body
  result = call_601036.call(nil, nil, nil, nil, body_601037)

var updateMaintenanceStartTime* = Call_UpdateMaintenanceStartTime_601023(
    name: "updateMaintenanceStartTime", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.UpdateMaintenanceStartTime",
    validator: validate_UpdateMaintenanceStartTime_601024, base: "/",
    url: url_UpdateMaintenanceStartTime_601025,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNFSFileShare_601038 = ref object of OpenApiRestCall_599369
proc url_UpdateNFSFileShare_601040(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateNFSFileShare_601039(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
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
  var valid_601041 = header.getOrDefault("X-Amz-Date")
  valid_601041 = validateParameter(valid_601041, JString, required = false,
                                 default = nil)
  if valid_601041 != nil:
    section.add "X-Amz-Date", valid_601041
  var valid_601042 = header.getOrDefault("X-Amz-Security-Token")
  valid_601042 = validateParameter(valid_601042, JString, required = false,
                                 default = nil)
  if valid_601042 != nil:
    section.add "X-Amz-Security-Token", valid_601042
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601043 = header.getOrDefault("X-Amz-Target")
  valid_601043 = validateParameter(valid_601043, JString, required = true, default = newJString(
      "StorageGateway_20130630.UpdateNFSFileShare"))
  if valid_601043 != nil:
    section.add "X-Amz-Target", valid_601043
  var valid_601044 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601044 = validateParameter(valid_601044, JString, required = false,
                                 default = nil)
  if valid_601044 != nil:
    section.add "X-Amz-Content-Sha256", valid_601044
  var valid_601045 = header.getOrDefault("X-Amz-Algorithm")
  valid_601045 = validateParameter(valid_601045, JString, required = false,
                                 default = nil)
  if valid_601045 != nil:
    section.add "X-Amz-Algorithm", valid_601045
  var valid_601046 = header.getOrDefault("X-Amz-Signature")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "X-Amz-Signature", valid_601046
  var valid_601047 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601047 = validateParameter(valid_601047, JString, required = false,
                                 default = nil)
  if valid_601047 != nil:
    section.add "X-Amz-SignedHeaders", valid_601047
  var valid_601048 = header.getOrDefault("X-Amz-Credential")
  valid_601048 = validateParameter(valid_601048, JString, required = false,
                                 default = nil)
  if valid_601048 != nil:
    section.add "X-Amz-Credential", valid_601048
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601050: Call_UpdateNFSFileShare_601038; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates a Network File System (NFS) file share. This operation is only supported in the file gateway type.</p> <note> <p>To leave a file share field unchanged, set the corresponding input field to null.</p> </note> <p>Updates the following file share setting:</p> <ul> <li> <p>Default storage class for your S3 bucket</p> </li> <li> <p>Metadata defaults for your S3 bucket</p> </li> <li> <p>Allowed NFS clients for your file share</p> </li> <li> <p>Squash settings</p> </li> <li> <p>Write status of your file share</p> </li> </ul> <note> <p>To leave a file share field unchanged, set the corresponding input field to null. This operation is only supported in file gateways.</p> </note>
  ## 
  let valid = call_601050.validator(path, query, header, formData, body)
  let scheme = call_601050.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601050.url(scheme.get, call_601050.host, call_601050.base,
                         call_601050.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601050, url, valid)

proc call*(call_601051: Call_UpdateNFSFileShare_601038; body: JsonNode): Recallable =
  ## updateNFSFileShare
  ## <p>Updates a Network File System (NFS) file share. This operation is only supported in the file gateway type.</p> <note> <p>To leave a file share field unchanged, set the corresponding input field to null.</p> </note> <p>Updates the following file share setting:</p> <ul> <li> <p>Default storage class for your S3 bucket</p> </li> <li> <p>Metadata defaults for your S3 bucket</p> </li> <li> <p>Allowed NFS clients for your file share</p> </li> <li> <p>Squash settings</p> </li> <li> <p>Write status of your file share</p> </li> </ul> <note> <p>To leave a file share field unchanged, set the corresponding input field to null. This operation is only supported in file gateways.</p> </note>
  ##   body: JObject (required)
  var body_601052 = newJObject()
  if body != nil:
    body_601052 = body
  result = call_601051.call(nil, nil, nil, nil, body_601052)

var updateNFSFileShare* = Call_UpdateNFSFileShare_601038(
    name: "updateNFSFileShare", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.UpdateNFSFileShare",
    validator: validate_UpdateNFSFileShare_601039, base: "/",
    url: url_UpdateNFSFileShare_601040, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSMBFileShare_601053 = ref object of OpenApiRestCall_599369
proc url_UpdateSMBFileShare_601055(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateSMBFileShare_601054(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
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
  var valid_601056 = header.getOrDefault("X-Amz-Date")
  valid_601056 = validateParameter(valid_601056, JString, required = false,
                                 default = nil)
  if valid_601056 != nil:
    section.add "X-Amz-Date", valid_601056
  var valid_601057 = header.getOrDefault("X-Amz-Security-Token")
  valid_601057 = validateParameter(valid_601057, JString, required = false,
                                 default = nil)
  if valid_601057 != nil:
    section.add "X-Amz-Security-Token", valid_601057
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601058 = header.getOrDefault("X-Amz-Target")
  valid_601058 = validateParameter(valid_601058, JString, required = true, default = newJString(
      "StorageGateway_20130630.UpdateSMBFileShare"))
  if valid_601058 != nil:
    section.add "X-Amz-Target", valid_601058
  var valid_601059 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601059 = validateParameter(valid_601059, JString, required = false,
                                 default = nil)
  if valid_601059 != nil:
    section.add "X-Amz-Content-Sha256", valid_601059
  var valid_601060 = header.getOrDefault("X-Amz-Algorithm")
  valid_601060 = validateParameter(valid_601060, JString, required = false,
                                 default = nil)
  if valid_601060 != nil:
    section.add "X-Amz-Algorithm", valid_601060
  var valid_601061 = header.getOrDefault("X-Amz-Signature")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-Signature", valid_601061
  var valid_601062 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601062 = validateParameter(valid_601062, JString, required = false,
                                 default = nil)
  if valid_601062 != nil:
    section.add "X-Amz-SignedHeaders", valid_601062
  var valid_601063 = header.getOrDefault("X-Amz-Credential")
  valid_601063 = validateParameter(valid_601063, JString, required = false,
                                 default = nil)
  if valid_601063 != nil:
    section.add "X-Amz-Credential", valid_601063
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601065: Call_UpdateSMBFileShare_601053; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates a Server Message Block (SMB) file share.</p> <note> <p>To leave a file share field unchanged, set the corresponding input field to null. This operation is only supported for file gateways.</p> </note> <important> <p>File gateways require AWS Security Token Service (AWS STS) to be activated to enable you to create a file share. Make sure that AWS STS is activated in the AWS Region you are creating your file gateway in. If AWS STS is not activated in this AWS Region, activate it. For information about how to activate AWS STS, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_enable-regions.html">Activating and Deactivating AWS STS in an AWS Region</a> in the <i>AWS Identity and Access Management User Guide.</i> </p> <p>File gateways don't support creating hard or symbolic links on a file share.</p> </important>
  ## 
  let valid = call_601065.validator(path, query, header, formData, body)
  let scheme = call_601065.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601065.url(scheme.get, call_601065.host, call_601065.base,
                         call_601065.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601065, url, valid)

proc call*(call_601066: Call_UpdateSMBFileShare_601053; body: JsonNode): Recallable =
  ## updateSMBFileShare
  ## <p>Updates a Server Message Block (SMB) file share.</p> <note> <p>To leave a file share field unchanged, set the corresponding input field to null. This operation is only supported for file gateways.</p> </note> <important> <p>File gateways require AWS Security Token Service (AWS STS) to be activated to enable you to create a file share. Make sure that AWS STS is activated in the AWS Region you are creating your file gateway in. If AWS STS is not activated in this AWS Region, activate it. For information about how to activate AWS STS, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_enable-regions.html">Activating and Deactivating AWS STS in an AWS Region</a> in the <i>AWS Identity and Access Management User Guide.</i> </p> <p>File gateways don't support creating hard or symbolic links on a file share.</p> </important>
  ##   body: JObject (required)
  var body_601067 = newJObject()
  if body != nil:
    body_601067 = body
  result = call_601066.call(nil, nil, nil, nil, body_601067)

var updateSMBFileShare* = Call_UpdateSMBFileShare_601053(
    name: "updateSMBFileShare", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.UpdateSMBFileShare",
    validator: validate_UpdateSMBFileShare_601054, base: "/",
    url: url_UpdateSMBFileShare_601055, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSMBSecurityStrategy_601068 = ref object of OpenApiRestCall_599369
proc url_UpdateSMBSecurityStrategy_601070(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateSMBSecurityStrategy_601069(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601071 = header.getOrDefault("X-Amz-Date")
  valid_601071 = validateParameter(valid_601071, JString, required = false,
                                 default = nil)
  if valid_601071 != nil:
    section.add "X-Amz-Date", valid_601071
  var valid_601072 = header.getOrDefault("X-Amz-Security-Token")
  valid_601072 = validateParameter(valid_601072, JString, required = false,
                                 default = nil)
  if valid_601072 != nil:
    section.add "X-Amz-Security-Token", valid_601072
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601073 = header.getOrDefault("X-Amz-Target")
  valid_601073 = validateParameter(valid_601073, JString, required = true, default = newJString(
      "StorageGateway_20130630.UpdateSMBSecurityStrategy"))
  if valid_601073 != nil:
    section.add "X-Amz-Target", valid_601073
  var valid_601074 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601074 = validateParameter(valid_601074, JString, required = false,
                                 default = nil)
  if valid_601074 != nil:
    section.add "X-Amz-Content-Sha256", valid_601074
  var valid_601075 = header.getOrDefault("X-Amz-Algorithm")
  valid_601075 = validateParameter(valid_601075, JString, required = false,
                                 default = nil)
  if valid_601075 != nil:
    section.add "X-Amz-Algorithm", valid_601075
  var valid_601076 = header.getOrDefault("X-Amz-Signature")
  valid_601076 = validateParameter(valid_601076, JString, required = false,
                                 default = nil)
  if valid_601076 != nil:
    section.add "X-Amz-Signature", valid_601076
  var valid_601077 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601077 = validateParameter(valid_601077, JString, required = false,
                                 default = nil)
  if valid_601077 != nil:
    section.add "X-Amz-SignedHeaders", valid_601077
  var valid_601078 = header.getOrDefault("X-Amz-Credential")
  valid_601078 = validateParameter(valid_601078, JString, required = false,
                                 default = nil)
  if valid_601078 != nil:
    section.add "X-Amz-Credential", valid_601078
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601080: Call_UpdateSMBSecurityStrategy_601068; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the SMB security strategy on a file gateway. This action is only supported in file gateways.</p> <note> <p>This API is called Security level in the User Guide.</p> <p>A higher security level can affect performance of the gateway.</p> </note>
  ## 
  let valid = call_601080.validator(path, query, header, formData, body)
  let scheme = call_601080.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601080.url(scheme.get, call_601080.host, call_601080.base,
                         call_601080.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601080, url, valid)

proc call*(call_601081: Call_UpdateSMBSecurityStrategy_601068; body: JsonNode): Recallable =
  ## updateSMBSecurityStrategy
  ## <p>Updates the SMB security strategy on a file gateway. This action is only supported in file gateways.</p> <note> <p>This API is called Security level in the User Guide.</p> <p>A higher security level can affect performance of the gateway.</p> </note>
  ##   body: JObject (required)
  var body_601082 = newJObject()
  if body != nil:
    body_601082 = body
  result = call_601081.call(nil, nil, nil, nil, body_601082)

var updateSMBSecurityStrategy* = Call_UpdateSMBSecurityStrategy_601068(
    name: "updateSMBSecurityStrategy", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.UpdateSMBSecurityStrategy",
    validator: validate_UpdateSMBSecurityStrategy_601069, base: "/",
    url: url_UpdateSMBSecurityStrategy_601070,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSnapshotSchedule_601083 = ref object of OpenApiRestCall_599369
proc url_UpdateSnapshotSchedule_601085(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateSnapshotSchedule_601084(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601086 = header.getOrDefault("X-Amz-Date")
  valid_601086 = validateParameter(valid_601086, JString, required = false,
                                 default = nil)
  if valid_601086 != nil:
    section.add "X-Amz-Date", valid_601086
  var valid_601087 = header.getOrDefault("X-Amz-Security-Token")
  valid_601087 = validateParameter(valid_601087, JString, required = false,
                                 default = nil)
  if valid_601087 != nil:
    section.add "X-Amz-Security-Token", valid_601087
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601088 = header.getOrDefault("X-Amz-Target")
  valid_601088 = validateParameter(valid_601088, JString, required = true, default = newJString(
      "StorageGateway_20130630.UpdateSnapshotSchedule"))
  if valid_601088 != nil:
    section.add "X-Amz-Target", valid_601088
  var valid_601089 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601089 = validateParameter(valid_601089, JString, required = false,
                                 default = nil)
  if valid_601089 != nil:
    section.add "X-Amz-Content-Sha256", valid_601089
  var valid_601090 = header.getOrDefault("X-Amz-Algorithm")
  valid_601090 = validateParameter(valid_601090, JString, required = false,
                                 default = nil)
  if valid_601090 != nil:
    section.add "X-Amz-Algorithm", valid_601090
  var valid_601091 = header.getOrDefault("X-Amz-Signature")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "X-Amz-Signature", valid_601091
  var valid_601092 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601092 = validateParameter(valid_601092, JString, required = false,
                                 default = nil)
  if valid_601092 != nil:
    section.add "X-Amz-SignedHeaders", valid_601092
  var valid_601093 = header.getOrDefault("X-Amz-Credential")
  valid_601093 = validateParameter(valid_601093, JString, required = false,
                                 default = nil)
  if valid_601093 != nil:
    section.add "X-Amz-Credential", valid_601093
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601095: Call_UpdateSnapshotSchedule_601083; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates a snapshot schedule configured for a gateway volume. This operation is only supported in the cached volume and stored volume gateway types.</p> <p>The default snapshot schedule for volume is once every 24 hours, starting at the creation time of the volume. You can use this API to change the snapshot schedule configured for the volume.</p> <p>In the request you must identify the gateway volume whose snapshot schedule you want to update, and the schedule information, including when you want the snapshot to begin on a day and the frequency (in hours) of snapshots.</p>
  ## 
  let valid = call_601095.validator(path, query, header, formData, body)
  let scheme = call_601095.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601095.url(scheme.get, call_601095.host, call_601095.base,
                         call_601095.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601095, url, valid)

proc call*(call_601096: Call_UpdateSnapshotSchedule_601083; body: JsonNode): Recallable =
  ## updateSnapshotSchedule
  ## <p>Updates a snapshot schedule configured for a gateway volume. This operation is only supported in the cached volume and stored volume gateway types.</p> <p>The default snapshot schedule for volume is once every 24 hours, starting at the creation time of the volume. You can use this API to change the snapshot schedule configured for the volume.</p> <p>In the request you must identify the gateway volume whose snapshot schedule you want to update, and the schedule information, including when you want the snapshot to begin on a day and the frequency (in hours) of snapshots.</p>
  ##   body: JObject (required)
  var body_601097 = newJObject()
  if body != nil:
    body_601097 = body
  result = call_601096.call(nil, nil, nil, nil, body_601097)

var updateSnapshotSchedule* = Call_UpdateSnapshotSchedule_601083(
    name: "updateSnapshotSchedule", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.UpdateSnapshotSchedule",
    validator: validate_UpdateSnapshotSchedule_601084, base: "/",
    url: url_UpdateSnapshotSchedule_601085, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVTLDeviceType_601098 = ref object of OpenApiRestCall_599369
proc url_UpdateVTLDeviceType_601100(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateVTLDeviceType_601099(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_601101 = header.getOrDefault("X-Amz-Date")
  valid_601101 = validateParameter(valid_601101, JString, required = false,
                                 default = nil)
  if valid_601101 != nil:
    section.add "X-Amz-Date", valid_601101
  var valid_601102 = header.getOrDefault("X-Amz-Security-Token")
  valid_601102 = validateParameter(valid_601102, JString, required = false,
                                 default = nil)
  if valid_601102 != nil:
    section.add "X-Amz-Security-Token", valid_601102
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601103 = header.getOrDefault("X-Amz-Target")
  valid_601103 = validateParameter(valid_601103, JString, required = true, default = newJString(
      "StorageGateway_20130630.UpdateVTLDeviceType"))
  if valid_601103 != nil:
    section.add "X-Amz-Target", valid_601103
  var valid_601104 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601104 = validateParameter(valid_601104, JString, required = false,
                                 default = nil)
  if valid_601104 != nil:
    section.add "X-Amz-Content-Sha256", valid_601104
  var valid_601105 = header.getOrDefault("X-Amz-Algorithm")
  valid_601105 = validateParameter(valid_601105, JString, required = false,
                                 default = nil)
  if valid_601105 != nil:
    section.add "X-Amz-Algorithm", valid_601105
  var valid_601106 = header.getOrDefault("X-Amz-Signature")
  valid_601106 = validateParameter(valid_601106, JString, required = false,
                                 default = nil)
  if valid_601106 != nil:
    section.add "X-Amz-Signature", valid_601106
  var valid_601107 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601107 = validateParameter(valid_601107, JString, required = false,
                                 default = nil)
  if valid_601107 != nil:
    section.add "X-Amz-SignedHeaders", valid_601107
  var valid_601108 = header.getOrDefault("X-Amz-Credential")
  valid_601108 = validateParameter(valid_601108, JString, required = false,
                                 default = nil)
  if valid_601108 != nil:
    section.add "X-Amz-Credential", valid_601108
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601110: Call_UpdateVTLDeviceType_601098; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the type of medium changer in a tape gateway. When you activate a tape gateway, you select a medium changer type for the tape gateway. This operation enables you to select a different type of medium changer after a tape gateway is activated. This operation is only supported in the tape gateway type.
  ## 
  let valid = call_601110.validator(path, query, header, formData, body)
  let scheme = call_601110.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601110.url(scheme.get, call_601110.host, call_601110.base,
                         call_601110.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601110, url, valid)

proc call*(call_601111: Call_UpdateVTLDeviceType_601098; body: JsonNode): Recallable =
  ## updateVTLDeviceType
  ## Updates the type of medium changer in a tape gateway. When you activate a tape gateway, you select a medium changer type for the tape gateway. This operation enables you to select a different type of medium changer after a tape gateway is activated. This operation is only supported in the tape gateway type.
  ##   body: JObject (required)
  var body_601112 = newJObject()
  if body != nil:
    body_601112 = body
  result = call_601111.call(nil, nil, nil, nil, body_601112)

var updateVTLDeviceType* = Call_UpdateVTLDeviceType_601098(
    name: "updateVTLDeviceType", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.UpdateVTLDeviceType",
    validator: validate_UpdateVTLDeviceType_601099, base: "/",
    url: url_UpdateVTLDeviceType_601100, schemes: {Scheme.Https, Scheme.Http})
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
