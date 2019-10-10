
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_602467 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602467](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602467): Option[Scheme] {.used.} =
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
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_ActivateGateway_602804 = ref object of OpenApiRestCall_602467
proc url_ActivateGateway_602806(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ActivateGateway_602805(path: JsonNode; query: JsonNode;
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
  var valid_602918 = header.getOrDefault("X-Amz-Date")
  valid_602918 = validateParameter(valid_602918, JString, required = false,
                                 default = nil)
  if valid_602918 != nil:
    section.add "X-Amz-Date", valid_602918
  var valid_602919 = header.getOrDefault("X-Amz-Security-Token")
  valid_602919 = validateParameter(valid_602919, JString, required = false,
                                 default = nil)
  if valid_602919 != nil:
    section.add "X-Amz-Security-Token", valid_602919
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602933 = header.getOrDefault("X-Amz-Target")
  valid_602933 = validateParameter(valid_602933, JString, required = true, default = newJString(
      "StorageGateway_20130630.ActivateGateway"))
  if valid_602933 != nil:
    section.add "X-Amz-Target", valid_602933
  var valid_602934 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602934 = validateParameter(valid_602934, JString, required = false,
                                 default = nil)
  if valid_602934 != nil:
    section.add "X-Amz-Content-Sha256", valid_602934
  var valid_602935 = header.getOrDefault("X-Amz-Algorithm")
  valid_602935 = validateParameter(valid_602935, JString, required = false,
                                 default = nil)
  if valid_602935 != nil:
    section.add "X-Amz-Algorithm", valid_602935
  var valid_602936 = header.getOrDefault("X-Amz-Signature")
  valid_602936 = validateParameter(valid_602936, JString, required = false,
                                 default = nil)
  if valid_602936 != nil:
    section.add "X-Amz-Signature", valid_602936
  var valid_602937 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602937 = validateParameter(valid_602937, JString, required = false,
                                 default = nil)
  if valid_602937 != nil:
    section.add "X-Amz-SignedHeaders", valid_602937
  var valid_602938 = header.getOrDefault("X-Amz-Credential")
  valid_602938 = validateParameter(valid_602938, JString, required = false,
                                 default = nil)
  if valid_602938 != nil:
    section.add "X-Amz-Credential", valid_602938
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602962: Call_ActivateGateway_602804; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Activates the gateway you previously deployed on your host. In the activation process, you specify information such as the AWS Region that you want to use for storing snapshots or tapes, the time zone for scheduled snapshots the gateway snapshot schedule window, an activation key, and a name for your gateway. The activation process also associates your gateway with your account; for more information, see <a>UpdateGatewayInformation</a>.</p> <note> <p>You must turn on the gateway VM before you can activate your gateway.</p> </note>
  ## 
  let valid = call_602962.validator(path, query, header, formData, body)
  let scheme = call_602962.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602962.url(scheme.get, call_602962.host, call_602962.base,
                         call_602962.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602962, url, valid)

proc call*(call_603033: Call_ActivateGateway_602804; body: JsonNode): Recallable =
  ## activateGateway
  ## <p>Activates the gateway you previously deployed on your host. In the activation process, you specify information such as the AWS Region that you want to use for storing snapshots or tapes, the time zone for scheduled snapshots the gateway snapshot schedule window, an activation key, and a name for your gateway. The activation process also associates your gateway with your account; for more information, see <a>UpdateGatewayInformation</a>.</p> <note> <p>You must turn on the gateway VM before you can activate your gateway.</p> </note>
  ##   body: JObject (required)
  var body_603034 = newJObject()
  if body != nil:
    body_603034 = body
  result = call_603033.call(nil, nil, nil, nil, body_603034)

var activateGateway* = Call_ActivateGateway_602804(name: "activateGateway",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.ActivateGateway",
    validator: validate_ActivateGateway_602805, base: "/", url: url_ActivateGateway_602806,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AddCache_603073 = ref object of OpenApiRestCall_602467
proc url_AddCache_603075(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AddCache_603074(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603076 = header.getOrDefault("X-Amz-Date")
  valid_603076 = validateParameter(valid_603076, JString, required = false,
                                 default = nil)
  if valid_603076 != nil:
    section.add "X-Amz-Date", valid_603076
  var valid_603077 = header.getOrDefault("X-Amz-Security-Token")
  valid_603077 = validateParameter(valid_603077, JString, required = false,
                                 default = nil)
  if valid_603077 != nil:
    section.add "X-Amz-Security-Token", valid_603077
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603078 = header.getOrDefault("X-Amz-Target")
  valid_603078 = validateParameter(valid_603078, JString, required = true, default = newJString(
      "StorageGateway_20130630.AddCache"))
  if valid_603078 != nil:
    section.add "X-Amz-Target", valid_603078
  var valid_603079 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603079 = validateParameter(valid_603079, JString, required = false,
                                 default = nil)
  if valid_603079 != nil:
    section.add "X-Amz-Content-Sha256", valid_603079
  var valid_603080 = header.getOrDefault("X-Amz-Algorithm")
  valid_603080 = validateParameter(valid_603080, JString, required = false,
                                 default = nil)
  if valid_603080 != nil:
    section.add "X-Amz-Algorithm", valid_603080
  var valid_603081 = header.getOrDefault("X-Amz-Signature")
  valid_603081 = validateParameter(valid_603081, JString, required = false,
                                 default = nil)
  if valid_603081 != nil:
    section.add "X-Amz-Signature", valid_603081
  var valid_603082 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-SignedHeaders", valid_603082
  var valid_603083 = header.getOrDefault("X-Amz-Credential")
  valid_603083 = validateParameter(valid_603083, JString, required = false,
                                 default = nil)
  if valid_603083 != nil:
    section.add "X-Amz-Credential", valid_603083
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603085: Call_AddCache_603073; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Configures one or more gateway local disks as cache for a gateway. This operation is only supported in the cached volume, tape and file gateway type (see <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/StorageGatewayConcepts.html">Storage Gateway Concepts</a>).</p> <p>In the request, you specify the gateway Amazon Resource Name (ARN) to which you want to add cache, and one or more disk IDs that you want to configure as cache.</p>
  ## 
  let valid = call_603085.validator(path, query, header, formData, body)
  let scheme = call_603085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603085.url(scheme.get, call_603085.host, call_603085.base,
                         call_603085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603085, url, valid)

proc call*(call_603086: Call_AddCache_603073; body: JsonNode): Recallable =
  ## addCache
  ## <p>Configures one or more gateway local disks as cache for a gateway. This operation is only supported in the cached volume, tape and file gateway type (see <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/StorageGatewayConcepts.html">Storage Gateway Concepts</a>).</p> <p>In the request, you specify the gateway Amazon Resource Name (ARN) to which you want to add cache, and one or more disk IDs that you want to configure as cache.</p>
  ##   body: JObject (required)
  var body_603087 = newJObject()
  if body != nil:
    body_603087 = body
  result = call_603086.call(nil, nil, nil, nil, body_603087)

var addCache* = Call_AddCache_603073(name: "addCache", meth: HttpMethod.HttpPost,
                                  host: "storagegateway.amazonaws.com", route: "/#X-Amz-Target=StorageGateway_20130630.AddCache",
                                  validator: validate_AddCache_603074, base: "/",
                                  url: url_AddCache_603075,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_AddTagsToResource_603088 = ref object of OpenApiRestCall_602467
proc url_AddTagsToResource_603090(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AddTagsToResource_603089(path: JsonNode; query: JsonNode;
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
  var valid_603091 = header.getOrDefault("X-Amz-Date")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "X-Amz-Date", valid_603091
  var valid_603092 = header.getOrDefault("X-Amz-Security-Token")
  valid_603092 = validateParameter(valid_603092, JString, required = false,
                                 default = nil)
  if valid_603092 != nil:
    section.add "X-Amz-Security-Token", valid_603092
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603093 = header.getOrDefault("X-Amz-Target")
  valid_603093 = validateParameter(valid_603093, JString, required = true, default = newJString(
      "StorageGateway_20130630.AddTagsToResource"))
  if valid_603093 != nil:
    section.add "X-Amz-Target", valid_603093
  var valid_603094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = nil)
  if valid_603094 != nil:
    section.add "X-Amz-Content-Sha256", valid_603094
  var valid_603095 = header.getOrDefault("X-Amz-Algorithm")
  valid_603095 = validateParameter(valid_603095, JString, required = false,
                                 default = nil)
  if valid_603095 != nil:
    section.add "X-Amz-Algorithm", valid_603095
  var valid_603096 = header.getOrDefault("X-Amz-Signature")
  valid_603096 = validateParameter(valid_603096, JString, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "X-Amz-Signature", valid_603096
  var valid_603097 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603097 = validateParameter(valid_603097, JString, required = false,
                                 default = nil)
  if valid_603097 != nil:
    section.add "X-Amz-SignedHeaders", valid_603097
  var valid_603098 = header.getOrDefault("X-Amz-Credential")
  valid_603098 = validateParameter(valid_603098, JString, required = false,
                                 default = nil)
  if valid_603098 != nil:
    section.add "X-Amz-Credential", valid_603098
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603100: Call_AddTagsToResource_603088; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds one or more tags to the specified resource. You use tags to add metadata to resources, which you can use to categorize these resources. For example, you can categorize resources by purpose, owner, environment, or team. Each tag consists of a key and a value, which you define. You can add tags to the following AWS Storage Gateway resources:</p> <ul> <li> <p>Storage gateways of all types</p> </li> <li> <p>Storage volumes</p> </li> <li> <p>Virtual tapes</p> </li> <li> <p>NFS and SMB file shares</p> </li> </ul> <p>You can create a maximum of 50 tags for each resource. Virtual tapes and storage volumes that are recovered to a new gateway maintain their tags.</p>
  ## 
  let valid = call_603100.validator(path, query, header, formData, body)
  let scheme = call_603100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603100.url(scheme.get, call_603100.host, call_603100.base,
                         call_603100.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603100, url, valid)

proc call*(call_603101: Call_AddTagsToResource_603088; body: JsonNode): Recallable =
  ## addTagsToResource
  ## <p>Adds one or more tags to the specified resource. You use tags to add metadata to resources, which you can use to categorize these resources. For example, you can categorize resources by purpose, owner, environment, or team. Each tag consists of a key and a value, which you define. You can add tags to the following AWS Storage Gateway resources:</p> <ul> <li> <p>Storage gateways of all types</p> </li> <li> <p>Storage volumes</p> </li> <li> <p>Virtual tapes</p> </li> <li> <p>NFS and SMB file shares</p> </li> </ul> <p>You can create a maximum of 50 tags for each resource. Virtual tapes and storage volumes that are recovered to a new gateway maintain their tags.</p>
  ##   body: JObject (required)
  var body_603102 = newJObject()
  if body != nil:
    body_603102 = body
  result = call_603101.call(nil, nil, nil, nil, body_603102)

var addTagsToResource* = Call_AddTagsToResource_603088(name: "addTagsToResource",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.AddTagsToResource",
    validator: validate_AddTagsToResource_603089, base: "/",
    url: url_AddTagsToResource_603090, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AddUploadBuffer_603103 = ref object of OpenApiRestCall_602467
proc url_AddUploadBuffer_603105(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AddUploadBuffer_603104(path: JsonNode; query: JsonNode;
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
  var valid_603106 = header.getOrDefault("X-Amz-Date")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-Date", valid_603106
  var valid_603107 = header.getOrDefault("X-Amz-Security-Token")
  valid_603107 = validateParameter(valid_603107, JString, required = false,
                                 default = nil)
  if valid_603107 != nil:
    section.add "X-Amz-Security-Token", valid_603107
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603108 = header.getOrDefault("X-Amz-Target")
  valid_603108 = validateParameter(valid_603108, JString, required = true, default = newJString(
      "StorageGateway_20130630.AddUploadBuffer"))
  if valid_603108 != nil:
    section.add "X-Amz-Target", valid_603108
  var valid_603109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603109 = validateParameter(valid_603109, JString, required = false,
                                 default = nil)
  if valid_603109 != nil:
    section.add "X-Amz-Content-Sha256", valid_603109
  var valid_603110 = header.getOrDefault("X-Amz-Algorithm")
  valid_603110 = validateParameter(valid_603110, JString, required = false,
                                 default = nil)
  if valid_603110 != nil:
    section.add "X-Amz-Algorithm", valid_603110
  var valid_603111 = header.getOrDefault("X-Amz-Signature")
  valid_603111 = validateParameter(valid_603111, JString, required = false,
                                 default = nil)
  if valid_603111 != nil:
    section.add "X-Amz-Signature", valid_603111
  var valid_603112 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603112 = validateParameter(valid_603112, JString, required = false,
                                 default = nil)
  if valid_603112 != nil:
    section.add "X-Amz-SignedHeaders", valid_603112
  var valid_603113 = header.getOrDefault("X-Amz-Credential")
  valid_603113 = validateParameter(valid_603113, JString, required = false,
                                 default = nil)
  if valid_603113 != nil:
    section.add "X-Amz-Credential", valid_603113
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603115: Call_AddUploadBuffer_603103; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Configures one or more gateway local disks as upload buffer for a specified gateway. This operation is supported for the stored volume, cached volume and tape gateway types.</p> <p>In the request, you specify the gateway Amazon Resource Name (ARN) to which you want to add upload buffer, and one or more disk IDs that you want to configure as upload buffer.</p>
  ## 
  let valid = call_603115.validator(path, query, header, formData, body)
  let scheme = call_603115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603115.url(scheme.get, call_603115.host, call_603115.base,
                         call_603115.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603115, url, valid)

proc call*(call_603116: Call_AddUploadBuffer_603103; body: JsonNode): Recallable =
  ## addUploadBuffer
  ## <p>Configures one or more gateway local disks as upload buffer for a specified gateway. This operation is supported for the stored volume, cached volume and tape gateway types.</p> <p>In the request, you specify the gateway Amazon Resource Name (ARN) to which you want to add upload buffer, and one or more disk IDs that you want to configure as upload buffer.</p>
  ##   body: JObject (required)
  var body_603117 = newJObject()
  if body != nil:
    body_603117 = body
  result = call_603116.call(nil, nil, nil, nil, body_603117)

var addUploadBuffer* = Call_AddUploadBuffer_603103(name: "addUploadBuffer",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.AddUploadBuffer",
    validator: validate_AddUploadBuffer_603104, base: "/", url: url_AddUploadBuffer_603105,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AddWorkingStorage_603118 = ref object of OpenApiRestCall_602467
proc url_AddWorkingStorage_603120(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AddWorkingStorage_603119(path: JsonNode; query: JsonNode;
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
  var valid_603121 = header.getOrDefault("X-Amz-Date")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-Date", valid_603121
  var valid_603122 = header.getOrDefault("X-Amz-Security-Token")
  valid_603122 = validateParameter(valid_603122, JString, required = false,
                                 default = nil)
  if valid_603122 != nil:
    section.add "X-Amz-Security-Token", valid_603122
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603123 = header.getOrDefault("X-Amz-Target")
  valid_603123 = validateParameter(valid_603123, JString, required = true, default = newJString(
      "StorageGateway_20130630.AddWorkingStorage"))
  if valid_603123 != nil:
    section.add "X-Amz-Target", valid_603123
  var valid_603124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "X-Amz-Content-Sha256", valid_603124
  var valid_603125 = header.getOrDefault("X-Amz-Algorithm")
  valid_603125 = validateParameter(valid_603125, JString, required = false,
                                 default = nil)
  if valid_603125 != nil:
    section.add "X-Amz-Algorithm", valid_603125
  var valid_603126 = header.getOrDefault("X-Amz-Signature")
  valid_603126 = validateParameter(valid_603126, JString, required = false,
                                 default = nil)
  if valid_603126 != nil:
    section.add "X-Amz-Signature", valid_603126
  var valid_603127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603127 = validateParameter(valid_603127, JString, required = false,
                                 default = nil)
  if valid_603127 != nil:
    section.add "X-Amz-SignedHeaders", valid_603127
  var valid_603128 = header.getOrDefault("X-Amz-Credential")
  valid_603128 = validateParameter(valid_603128, JString, required = false,
                                 default = nil)
  if valid_603128 != nil:
    section.add "X-Amz-Credential", valid_603128
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603130: Call_AddWorkingStorage_603118; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Configures one or more gateway local disks as working storage for a gateway. This operation is only supported in the stored volume gateway type. This operation is deprecated in cached volume API version 20120630. Use <a>AddUploadBuffer</a> instead.</p> <note> <p>Working storage is also referred to as upload buffer. You can also use the <a>AddUploadBuffer</a> operation to add upload buffer to a stored volume gateway.</p> </note> <p>In the request, you specify the gateway Amazon Resource Name (ARN) to which you want to add working storage, and one or more disk IDs that you want to configure as working storage.</p>
  ## 
  let valid = call_603130.validator(path, query, header, formData, body)
  let scheme = call_603130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603130.url(scheme.get, call_603130.host, call_603130.base,
                         call_603130.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603130, url, valid)

proc call*(call_603131: Call_AddWorkingStorage_603118; body: JsonNode): Recallable =
  ## addWorkingStorage
  ## <p>Configures one or more gateway local disks as working storage for a gateway. This operation is only supported in the stored volume gateway type. This operation is deprecated in cached volume API version 20120630. Use <a>AddUploadBuffer</a> instead.</p> <note> <p>Working storage is also referred to as upload buffer. You can also use the <a>AddUploadBuffer</a> operation to add upload buffer to a stored volume gateway.</p> </note> <p>In the request, you specify the gateway Amazon Resource Name (ARN) to which you want to add working storage, and one or more disk IDs that you want to configure as working storage.</p>
  ##   body: JObject (required)
  var body_603132 = newJObject()
  if body != nil:
    body_603132 = body
  result = call_603131.call(nil, nil, nil, nil, body_603132)

var addWorkingStorage* = Call_AddWorkingStorage_603118(name: "addWorkingStorage",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.AddWorkingStorage",
    validator: validate_AddWorkingStorage_603119, base: "/",
    url: url_AddWorkingStorage_603120, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssignTapePool_603133 = ref object of OpenApiRestCall_602467
proc url_AssignTapePool_603135(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AssignTapePool_603134(path: JsonNode; query: JsonNode;
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
  var valid_603136 = header.getOrDefault("X-Amz-Date")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "X-Amz-Date", valid_603136
  var valid_603137 = header.getOrDefault("X-Amz-Security-Token")
  valid_603137 = validateParameter(valid_603137, JString, required = false,
                                 default = nil)
  if valid_603137 != nil:
    section.add "X-Amz-Security-Token", valid_603137
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603138 = header.getOrDefault("X-Amz-Target")
  valid_603138 = validateParameter(valid_603138, JString, required = true, default = newJString(
      "StorageGateway_20130630.AssignTapePool"))
  if valid_603138 != nil:
    section.add "X-Amz-Target", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-Content-Sha256", valid_603139
  var valid_603140 = header.getOrDefault("X-Amz-Algorithm")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "X-Amz-Algorithm", valid_603140
  var valid_603141 = header.getOrDefault("X-Amz-Signature")
  valid_603141 = validateParameter(valid_603141, JString, required = false,
                                 default = nil)
  if valid_603141 != nil:
    section.add "X-Amz-Signature", valid_603141
  var valid_603142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "X-Amz-SignedHeaders", valid_603142
  var valid_603143 = header.getOrDefault("X-Amz-Credential")
  valid_603143 = validateParameter(valid_603143, JString, required = false,
                                 default = nil)
  if valid_603143 != nil:
    section.add "X-Amz-Credential", valid_603143
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603145: Call_AssignTapePool_603133; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Assigns a tape to a tape pool for archiving. The tape assigned to a pool is archived in the S3 storage class that is associated with the pool. When you use your backup application to eject the tape, the tape is archived directly into the S3 storage class (Glacier or Deep Archive) that corresponds to the pool.</p> <p>Valid values: "GLACIER", "DEEP_ARCHIVE"</p>
  ## 
  let valid = call_603145.validator(path, query, header, formData, body)
  let scheme = call_603145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603145.url(scheme.get, call_603145.host, call_603145.base,
                         call_603145.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603145, url, valid)

proc call*(call_603146: Call_AssignTapePool_603133; body: JsonNode): Recallable =
  ## assignTapePool
  ## <p>Assigns a tape to a tape pool for archiving. The tape assigned to a pool is archived in the S3 storage class that is associated with the pool. When you use your backup application to eject the tape, the tape is archived directly into the S3 storage class (Glacier or Deep Archive) that corresponds to the pool.</p> <p>Valid values: "GLACIER", "DEEP_ARCHIVE"</p>
  ##   body: JObject (required)
  var body_603147 = newJObject()
  if body != nil:
    body_603147 = body
  result = call_603146.call(nil, nil, nil, nil, body_603147)

var assignTapePool* = Call_AssignTapePool_603133(name: "assignTapePool",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.AssignTapePool",
    validator: validate_AssignTapePool_603134, base: "/", url: url_AssignTapePool_603135,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachVolume_603148 = ref object of OpenApiRestCall_602467
proc url_AttachVolume_603150(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AttachVolume_603149(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603151 = header.getOrDefault("X-Amz-Date")
  valid_603151 = validateParameter(valid_603151, JString, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "X-Amz-Date", valid_603151
  var valid_603152 = header.getOrDefault("X-Amz-Security-Token")
  valid_603152 = validateParameter(valid_603152, JString, required = false,
                                 default = nil)
  if valid_603152 != nil:
    section.add "X-Amz-Security-Token", valid_603152
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603153 = header.getOrDefault("X-Amz-Target")
  valid_603153 = validateParameter(valid_603153, JString, required = true, default = newJString(
      "StorageGateway_20130630.AttachVolume"))
  if valid_603153 != nil:
    section.add "X-Amz-Target", valid_603153
  var valid_603154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "X-Amz-Content-Sha256", valid_603154
  var valid_603155 = header.getOrDefault("X-Amz-Algorithm")
  valid_603155 = validateParameter(valid_603155, JString, required = false,
                                 default = nil)
  if valid_603155 != nil:
    section.add "X-Amz-Algorithm", valid_603155
  var valid_603156 = header.getOrDefault("X-Amz-Signature")
  valid_603156 = validateParameter(valid_603156, JString, required = false,
                                 default = nil)
  if valid_603156 != nil:
    section.add "X-Amz-Signature", valid_603156
  var valid_603157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603157 = validateParameter(valid_603157, JString, required = false,
                                 default = nil)
  if valid_603157 != nil:
    section.add "X-Amz-SignedHeaders", valid_603157
  var valid_603158 = header.getOrDefault("X-Amz-Credential")
  valid_603158 = validateParameter(valid_603158, JString, required = false,
                                 default = nil)
  if valid_603158 != nil:
    section.add "X-Amz-Credential", valid_603158
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603160: Call_AttachVolume_603148; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Connects a volume to an iSCSI connection and then attaches the volume to the specified gateway. Detaching and attaching a volume enables you to recover your data from one gateway to a different gateway without creating a snapshot. It also makes it easier to move your volumes from an on-premises gateway to a gateway hosted on an Amazon EC2 instance.
  ## 
  let valid = call_603160.validator(path, query, header, formData, body)
  let scheme = call_603160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603160.url(scheme.get, call_603160.host, call_603160.base,
                         call_603160.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603160, url, valid)

proc call*(call_603161: Call_AttachVolume_603148; body: JsonNode): Recallable =
  ## attachVolume
  ## Connects a volume to an iSCSI connection and then attaches the volume to the specified gateway. Detaching and attaching a volume enables you to recover your data from one gateway to a different gateway without creating a snapshot. It also makes it easier to move your volumes from an on-premises gateway to a gateway hosted on an Amazon EC2 instance.
  ##   body: JObject (required)
  var body_603162 = newJObject()
  if body != nil:
    body_603162 = body
  result = call_603161.call(nil, nil, nil, nil, body_603162)

var attachVolume* = Call_AttachVolume_603148(name: "attachVolume",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.AttachVolume",
    validator: validate_AttachVolume_603149, base: "/", url: url_AttachVolume_603150,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelArchival_603163 = ref object of OpenApiRestCall_602467
proc url_CancelArchival_603165(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CancelArchival_603164(path: JsonNode; query: JsonNode;
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
  var valid_603166 = header.getOrDefault("X-Amz-Date")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "X-Amz-Date", valid_603166
  var valid_603167 = header.getOrDefault("X-Amz-Security-Token")
  valid_603167 = validateParameter(valid_603167, JString, required = false,
                                 default = nil)
  if valid_603167 != nil:
    section.add "X-Amz-Security-Token", valid_603167
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603168 = header.getOrDefault("X-Amz-Target")
  valid_603168 = validateParameter(valid_603168, JString, required = true, default = newJString(
      "StorageGateway_20130630.CancelArchival"))
  if valid_603168 != nil:
    section.add "X-Amz-Target", valid_603168
  var valid_603169 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603169 = validateParameter(valid_603169, JString, required = false,
                                 default = nil)
  if valid_603169 != nil:
    section.add "X-Amz-Content-Sha256", valid_603169
  var valid_603170 = header.getOrDefault("X-Amz-Algorithm")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "X-Amz-Algorithm", valid_603170
  var valid_603171 = header.getOrDefault("X-Amz-Signature")
  valid_603171 = validateParameter(valid_603171, JString, required = false,
                                 default = nil)
  if valid_603171 != nil:
    section.add "X-Amz-Signature", valid_603171
  var valid_603172 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603172 = validateParameter(valid_603172, JString, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "X-Amz-SignedHeaders", valid_603172
  var valid_603173 = header.getOrDefault("X-Amz-Credential")
  valid_603173 = validateParameter(valid_603173, JString, required = false,
                                 default = nil)
  if valid_603173 != nil:
    section.add "X-Amz-Credential", valid_603173
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603175: Call_CancelArchival_603163; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels archiving of a virtual tape to the virtual tape shelf (VTS) after the archiving process is initiated. This operation is only supported in the tape gateway type.
  ## 
  let valid = call_603175.validator(path, query, header, formData, body)
  let scheme = call_603175.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603175.url(scheme.get, call_603175.host, call_603175.base,
                         call_603175.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603175, url, valid)

proc call*(call_603176: Call_CancelArchival_603163; body: JsonNode): Recallable =
  ## cancelArchival
  ## Cancels archiving of a virtual tape to the virtual tape shelf (VTS) after the archiving process is initiated. This operation is only supported in the tape gateway type.
  ##   body: JObject (required)
  var body_603177 = newJObject()
  if body != nil:
    body_603177 = body
  result = call_603176.call(nil, nil, nil, nil, body_603177)

var cancelArchival* = Call_CancelArchival_603163(name: "cancelArchival",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.CancelArchival",
    validator: validate_CancelArchival_603164, base: "/", url: url_CancelArchival_603165,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelRetrieval_603178 = ref object of OpenApiRestCall_602467
proc url_CancelRetrieval_603180(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CancelRetrieval_603179(path: JsonNode; query: JsonNode;
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
  var valid_603181 = header.getOrDefault("X-Amz-Date")
  valid_603181 = validateParameter(valid_603181, JString, required = false,
                                 default = nil)
  if valid_603181 != nil:
    section.add "X-Amz-Date", valid_603181
  var valid_603182 = header.getOrDefault("X-Amz-Security-Token")
  valid_603182 = validateParameter(valid_603182, JString, required = false,
                                 default = nil)
  if valid_603182 != nil:
    section.add "X-Amz-Security-Token", valid_603182
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603183 = header.getOrDefault("X-Amz-Target")
  valid_603183 = validateParameter(valid_603183, JString, required = true, default = newJString(
      "StorageGateway_20130630.CancelRetrieval"))
  if valid_603183 != nil:
    section.add "X-Amz-Target", valid_603183
  var valid_603184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603184 = validateParameter(valid_603184, JString, required = false,
                                 default = nil)
  if valid_603184 != nil:
    section.add "X-Amz-Content-Sha256", valid_603184
  var valid_603185 = header.getOrDefault("X-Amz-Algorithm")
  valid_603185 = validateParameter(valid_603185, JString, required = false,
                                 default = nil)
  if valid_603185 != nil:
    section.add "X-Amz-Algorithm", valid_603185
  var valid_603186 = header.getOrDefault("X-Amz-Signature")
  valid_603186 = validateParameter(valid_603186, JString, required = false,
                                 default = nil)
  if valid_603186 != nil:
    section.add "X-Amz-Signature", valid_603186
  var valid_603187 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603187 = validateParameter(valid_603187, JString, required = false,
                                 default = nil)
  if valid_603187 != nil:
    section.add "X-Amz-SignedHeaders", valid_603187
  var valid_603188 = header.getOrDefault("X-Amz-Credential")
  valid_603188 = validateParameter(valid_603188, JString, required = false,
                                 default = nil)
  if valid_603188 != nil:
    section.add "X-Amz-Credential", valid_603188
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603190: Call_CancelRetrieval_603178; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels retrieval of a virtual tape from the virtual tape shelf (VTS) to a gateway after the retrieval process is initiated. The virtual tape is returned to the VTS. This operation is only supported in the tape gateway type.
  ## 
  let valid = call_603190.validator(path, query, header, formData, body)
  let scheme = call_603190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603190.url(scheme.get, call_603190.host, call_603190.base,
                         call_603190.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603190, url, valid)

proc call*(call_603191: Call_CancelRetrieval_603178; body: JsonNode): Recallable =
  ## cancelRetrieval
  ## Cancels retrieval of a virtual tape from the virtual tape shelf (VTS) to a gateway after the retrieval process is initiated. The virtual tape is returned to the VTS. This operation is only supported in the tape gateway type.
  ##   body: JObject (required)
  var body_603192 = newJObject()
  if body != nil:
    body_603192 = body
  result = call_603191.call(nil, nil, nil, nil, body_603192)

var cancelRetrieval* = Call_CancelRetrieval_603178(name: "cancelRetrieval",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.CancelRetrieval",
    validator: validate_CancelRetrieval_603179, base: "/", url: url_CancelRetrieval_603180,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCachediSCSIVolume_603193 = ref object of OpenApiRestCall_602467
proc url_CreateCachediSCSIVolume_603195(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateCachediSCSIVolume_603194(path: JsonNode; query: JsonNode;
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
  var valid_603196 = header.getOrDefault("X-Amz-Date")
  valid_603196 = validateParameter(valid_603196, JString, required = false,
                                 default = nil)
  if valid_603196 != nil:
    section.add "X-Amz-Date", valid_603196
  var valid_603197 = header.getOrDefault("X-Amz-Security-Token")
  valid_603197 = validateParameter(valid_603197, JString, required = false,
                                 default = nil)
  if valid_603197 != nil:
    section.add "X-Amz-Security-Token", valid_603197
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603198 = header.getOrDefault("X-Amz-Target")
  valid_603198 = validateParameter(valid_603198, JString, required = true, default = newJString(
      "StorageGateway_20130630.CreateCachediSCSIVolume"))
  if valid_603198 != nil:
    section.add "X-Amz-Target", valid_603198
  var valid_603199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603199 = validateParameter(valid_603199, JString, required = false,
                                 default = nil)
  if valid_603199 != nil:
    section.add "X-Amz-Content-Sha256", valid_603199
  var valid_603200 = header.getOrDefault("X-Amz-Algorithm")
  valid_603200 = validateParameter(valid_603200, JString, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "X-Amz-Algorithm", valid_603200
  var valid_603201 = header.getOrDefault("X-Amz-Signature")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "X-Amz-Signature", valid_603201
  var valid_603202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603202 = validateParameter(valid_603202, JString, required = false,
                                 default = nil)
  if valid_603202 != nil:
    section.add "X-Amz-SignedHeaders", valid_603202
  var valid_603203 = header.getOrDefault("X-Amz-Credential")
  valid_603203 = validateParameter(valid_603203, JString, required = false,
                                 default = nil)
  if valid_603203 != nil:
    section.add "X-Amz-Credential", valid_603203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603205: Call_CreateCachediSCSIVolume_603193; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a cached volume on a specified cached volume gateway. This operation is only supported in the cached volume gateway type.</p> <note> <p>Cache storage must be allocated to the gateway before you can create a cached volume. Use the <a>AddCache</a> operation to add cache storage to a gateway. </p> </note> <p>In the request, you must specify the gateway, size of the volume in bytes, the iSCSI target name, an IP address on which to expose the target, and a unique client token. In response, the gateway creates the volume and returns information about it. This information includes the volume Amazon Resource Name (ARN), its size, and the iSCSI target ARN that initiators can use to connect to the volume target.</p> <p>Optionally, you can provide the ARN for an existing volume as the <code>SourceVolumeARN</code> for this cached volume, which creates an exact copy of the existing volume’s latest recovery point. The <code>VolumeSizeInBytes</code> value must be equal to or larger than the size of the copied volume, in bytes.</p>
  ## 
  let valid = call_603205.validator(path, query, header, formData, body)
  let scheme = call_603205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603205.url(scheme.get, call_603205.host, call_603205.base,
                         call_603205.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603205, url, valid)

proc call*(call_603206: Call_CreateCachediSCSIVolume_603193; body: JsonNode): Recallable =
  ## createCachediSCSIVolume
  ## <p>Creates a cached volume on a specified cached volume gateway. This operation is only supported in the cached volume gateway type.</p> <note> <p>Cache storage must be allocated to the gateway before you can create a cached volume. Use the <a>AddCache</a> operation to add cache storage to a gateway. </p> </note> <p>In the request, you must specify the gateway, size of the volume in bytes, the iSCSI target name, an IP address on which to expose the target, and a unique client token. In response, the gateway creates the volume and returns information about it. This information includes the volume Amazon Resource Name (ARN), its size, and the iSCSI target ARN that initiators can use to connect to the volume target.</p> <p>Optionally, you can provide the ARN for an existing volume as the <code>SourceVolumeARN</code> for this cached volume, which creates an exact copy of the existing volume’s latest recovery point. The <code>VolumeSizeInBytes</code> value must be equal to or larger than the size of the copied volume, in bytes.</p>
  ##   body: JObject (required)
  var body_603207 = newJObject()
  if body != nil:
    body_603207 = body
  result = call_603206.call(nil, nil, nil, nil, body_603207)

var createCachediSCSIVolume* = Call_CreateCachediSCSIVolume_603193(
    name: "createCachediSCSIVolume", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.CreateCachediSCSIVolume",
    validator: validate_CreateCachediSCSIVolume_603194, base: "/",
    url: url_CreateCachediSCSIVolume_603195, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNFSFileShare_603208 = ref object of OpenApiRestCall_602467
proc url_CreateNFSFileShare_603210(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateNFSFileShare_603209(path: JsonNode; query: JsonNode;
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
  var valid_603211 = header.getOrDefault("X-Amz-Date")
  valid_603211 = validateParameter(valid_603211, JString, required = false,
                                 default = nil)
  if valid_603211 != nil:
    section.add "X-Amz-Date", valid_603211
  var valid_603212 = header.getOrDefault("X-Amz-Security-Token")
  valid_603212 = validateParameter(valid_603212, JString, required = false,
                                 default = nil)
  if valid_603212 != nil:
    section.add "X-Amz-Security-Token", valid_603212
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603213 = header.getOrDefault("X-Amz-Target")
  valid_603213 = validateParameter(valid_603213, JString, required = true, default = newJString(
      "StorageGateway_20130630.CreateNFSFileShare"))
  if valid_603213 != nil:
    section.add "X-Amz-Target", valid_603213
  var valid_603214 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603214 = validateParameter(valid_603214, JString, required = false,
                                 default = nil)
  if valid_603214 != nil:
    section.add "X-Amz-Content-Sha256", valid_603214
  var valid_603215 = header.getOrDefault("X-Amz-Algorithm")
  valid_603215 = validateParameter(valid_603215, JString, required = false,
                                 default = nil)
  if valid_603215 != nil:
    section.add "X-Amz-Algorithm", valid_603215
  var valid_603216 = header.getOrDefault("X-Amz-Signature")
  valid_603216 = validateParameter(valid_603216, JString, required = false,
                                 default = nil)
  if valid_603216 != nil:
    section.add "X-Amz-Signature", valid_603216
  var valid_603217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603217 = validateParameter(valid_603217, JString, required = false,
                                 default = nil)
  if valid_603217 != nil:
    section.add "X-Amz-SignedHeaders", valid_603217
  var valid_603218 = header.getOrDefault("X-Amz-Credential")
  valid_603218 = validateParameter(valid_603218, JString, required = false,
                                 default = nil)
  if valid_603218 != nil:
    section.add "X-Amz-Credential", valid_603218
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603220: Call_CreateNFSFileShare_603208; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Network File System (NFS) file share on an existing file gateway. In Storage Gateway, a file share is a file system mount point backed by Amazon S3 cloud storage. Storage Gateway exposes file shares using a NFS interface. This operation is only supported for file gateways.</p> <important> <p>File gateway requires AWS Security Token Service (AWS STS) to be activated to enable you create a file share. Make sure AWS STS is activated in the AWS Region you are creating your file gateway in. If AWS STS is not activated in the AWS Region, activate it. For information about how to activate AWS STS, see Activating and Deactivating AWS STS in an AWS Region in the AWS Identity and Access Management User Guide. </p> <p>File gateway does not support creating hard or symbolic links on a file share.</p> </important>
  ## 
  let valid = call_603220.validator(path, query, header, formData, body)
  let scheme = call_603220.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603220.url(scheme.get, call_603220.host, call_603220.base,
                         call_603220.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603220, url, valid)

proc call*(call_603221: Call_CreateNFSFileShare_603208; body: JsonNode): Recallable =
  ## createNFSFileShare
  ## <p>Creates a Network File System (NFS) file share on an existing file gateway. In Storage Gateway, a file share is a file system mount point backed by Amazon S3 cloud storage. Storage Gateway exposes file shares using a NFS interface. This operation is only supported for file gateways.</p> <important> <p>File gateway requires AWS Security Token Service (AWS STS) to be activated to enable you create a file share. Make sure AWS STS is activated in the AWS Region you are creating your file gateway in. If AWS STS is not activated in the AWS Region, activate it. For information about how to activate AWS STS, see Activating and Deactivating AWS STS in an AWS Region in the AWS Identity and Access Management User Guide. </p> <p>File gateway does not support creating hard or symbolic links on a file share.</p> </important>
  ##   body: JObject (required)
  var body_603222 = newJObject()
  if body != nil:
    body_603222 = body
  result = call_603221.call(nil, nil, nil, nil, body_603222)

var createNFSFileShare* = Call_CreateNFSFileShare_603208(
    name: "createNFSFileShare", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.CreateNFSFileShare",
    validator: validate_CreateNFSFileShare_603209, base: "/",
    url: url_CreateNFSFileShare_603210, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSMBFileShare_603223 = ref object of OpenApiRestCall_602467
proc url_CreateSMBFileShare_603225(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateSMBFileShare_603224(path: JsonNode; query: JsonNode;
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
  var valid_603226 = header.getOrDefault("X-Amz-Date")
  valid_603226 = validateParameter(valid_603226, JString, required = false,
                                 default = nil)
  if valid_603226 != nil:
    section.add "X-Amz-Date", valid_603226
  var valid_603227 = header.getOrDefault("X-Amz-Security-Token")
  valid_603227 = validateParameter(valid_603227, JString, required = false,
                                 default = nil)
  if valid_603227 != nil:
    section.add "X-Amz-Security-Token", valid_603227
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603228 = header.getOrDefault("X-Amz-Target")
  valid_603228 = validateParameter(valid_603228, JString, required = true, default = newJString(
      "StorageGateway_20130630.CreateSMBFileShare"))
  if valid_603228 != nil:
    section.add "X-Amz-Target", valid_603228
  var valid_603229 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603229 = validateParameter(valid_603229, JString, required = false,
                                 default = nil)
  if valid_603229 != nil:
    section.add "X-Amz-Content-Sha256", valid_603229
  var valid_603230 = header.getOrDefault("X-Amz-Algorithm")
  valid_603230 = validateParameter(valid_603230, JString, required = false,
                                 default = nil)
  if valid_603230 != nil:
    section.add "X-Amz-Algorithm", valid_603230
  var valid_603231 = header.getOrDefault("X-Amz-Signature")
  valid_603231 = validateParameter(valid_603231, JString, required = false,
                                 default = nil)
  if valid_603231 != nil:
    section.add "X-Amz-Signature", valid_603231
  var valid_603232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603232 = validateParameter(valid_603232, JString, required = false,
                                 default = nil)
  if valid_603232 != nil:
    section.add "X-Amz-SignedHeaders", valid_603232
  var valid_603233 = header.getOrDefault("X-Amz-Credential")
  valid_603233 = validateParameter(valid_603233, JString, required = false,
                                 default = nil)
  if valid_603233 != nil:
    section.add "X-Amz-Credential", valid_603233
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603235: Call_CreateSMBFileShare_603223; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Server Message Block (SMB) file share on an existing file gateway. In Storage Gateway, a file share is a file system mount point backed by Amazon S3 cloud storage. Storage Gateway expose file shares using a SMB interface. This operation is only supported for file gateways.</p> <important> <p>File gateways require AWS Security Token Service (AWS STS) to be activated to enable you to create a file share. Make sure that AWS STS is activated in the AWS Region you are creating your file gateway in. If AWS STS is not activated in this AWS Region, activate it. For information about how to activate AWS STS, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_enable-regions.html">Activating and Deactivating AWS STS in an AWS Region</a> in the <i>AWS Identity and Access Management User Guide.</i> </p> <p>File gateways don't support creating hard or symbolic links on a file share.</p> </important>
  ## 
  let valid = call_603235.validator(path, query, header, formData, body)
  let scheme = call_603235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603235.url(scheme.get, call_603235.host, call_603235.base,
                         call_603235.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603235, url, valid)

proc call*(call_603236: Call_CreateSMBFileShare_603223; body: JsonNode): Recallable =
  ## createSMBFileShare
  ## <p>Creates a Server Message Block (SMB) file share on an existing file gateway. In Storage Gateway, a file share is a file system mount point backed by Amazon S3 cloud storage. Storage Gateway expose file shares using a SMB interface. This operation is only supported for file gateways.</p> <important> <p>File gateways require AWS Security Token Service (AWS STS) to be activated to enable you to create a file share. Make sure that AWS STS is activated in the AWS Region you are creating your file gateway in. If AWS STS is not activated in this AWS Region, activate it. For information about how to activate AWS STS, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_enable-regions.html">Activating and Deactivating AWS STS in an AWS Region</a> in the <i>AWS Identity and Access Management User Guide.</i> </p> <p>File gateways don't support creating hard or symbolic links on a file share.</p> </important>
  ##   body: JObject (required)
  var body_603237 = newJObject()
  if body != nil:
    body_603237 = body
  result = call_603236.call(nil, nil, nil, nil, body_603237)

var createSMBFileShare* = Call_CreateSMBFileShare_603223(
    name: "createSMBFileShare", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.CreateSMBFileShare",
    validator: validate_CreateSMBFileShare_603224, base: "/",
    url: url_CreateSMBFileShare_603225, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSnapshot_603238 = ref object of OpenApiRestCall_602467
proc url_CreateSnapshot_603240(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateSnapshot_603239(path: JsonNode; query: JsonNode;
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
  var valid_603241 = header.getOrDefault("X-Amz-Date")
  valid_603241 = validateParameter(valid_603241, JString, required = false,
                                 default = nil)
  if valid_603241 != nil:
    section.add "X-Amz-Date", valid_603241
  var valid_603242 = header.getOrDefault("X-Amz-Security-Token")
  valid_603242 = validateParameter(valid_603242, JString, required = false,
                                 default = nil)
  if valid_603242 != nil:
    section.add "X-Amz-Security-Token", valid_603242
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603243 = header.getOrDefault("X-Amz-Target")
  valid_603243 = validateParameter(valid_603243, JString, required = true, default = newJString(
      "StorageGateway_20130630.CreateSnapshot"))
  if valid_603243 != nil:
    section.add "X-Amz-Target", valid_603243
  var valid_603244 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603244 = validateParameter(valid_603244, JString, required = false,
                                 default = nil)
  if valid_603244 != nil:
    section.add "X-Amz-Content-Sha256", valid_603244
  var valid_603245 = header.getOrDefault("X-Amz-Algorithm")
  valid_603245 = validateParameter(valid_603245, JString, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "X-Amz-Algorithm", valid_603245
  var valid_603246 = header.getOrDefault("X-Amz-Signature")
  valid_603246 = validateParameter(valid_603246, JString, required = false,
                                 default = nil)
  if valid_603246 != nil:
    section.add "X-Amz-Signature", valid_603246
  var valid_603247 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603247 = validateParameter(valid_603247, JString, required = false,
                                 default = nil)
  if valid_603247 != nil:
    section.add "X-Amz-SignedHeaders", valid_603247
  var valid_603248 = header.getOrDefault("X-Amz-Credential")
  valid_603248 = validateParameter(valid_603248, JString, required = false,
                                 default = nil)
  if valid_603248 != nil:
    section.add "X-Amz-Credential", valid_603248
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603250: Call_CreateSnapshot_603238; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates a snapshot of a volume.</p> <p>AWS Storage Gateway provides the ability to back up point-in-time snapshots of your data to Amazon Simple Storage (S3) for durable off-site recovery, as well as import the data to an Amazon Elastic Block Store (EBS) volume in Amazon Elastic Compute Cloud (EC2). You can take snapshots of your gateway volume on a scheduled or ad hoc basis. This API enables you to take ad-hoc snapshot. For more information, see <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/managing-volumes.html#SchedulingSnapshot">Editing a Snapshot Schedule</a>.</p> <p>In the CreateSnapshot request you identify the volume by providing its Amazon Resource Name (ARN). You must also provide description for the snapshot. When AWS Storage Gateway takes the snapshot of specified volume, the snapshot and description appears in the AWS Storage Gateway Console. In response, AWS Storage Gateway returns you a snapshot ID. You can use this snapshot ID to check the snapshot progress or later use it when you want to create a volume from a snapshot. This operation is only supported in stored and cached volume gateway type.</p> <note> <p>To list or delete a snapshot, you must use the Amazon EC2 API. For more information, see DescribeSnapshots or DeleteSnapshot in the <a href="https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_Operations.html">EC2 API reference</a>.</p> </note> <important> <p>Volume and snapshot IDs are changing to a longer length ID format. For more information, see the important note on the <a href="https://docs.aws.amazon.com/storagegateway/latest/APIReference/Welcome.html">Welcome</a> page.</p> </important>
  ## 
  let valid = call_603250.validator(path, query, header, formData, body)
  let scheme = call_603250.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603250.url(scheme.get, call_603250.host, call_603250.base,
                         call_603250.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603250, url, valid)

proc call*(call_603251: Call_CreateSnapshot_603238; body: JsonNode): Recallable =
  ## createSnapshot
  ## <p>Initiates a snapshot of a volume.</p> <p>AWS Storage Gateway provides the ability to back up point-in-time snapshots of your data to Amazon Simple Storage (S3) for durable off-site recovery, as well as import the data to an Amazon Elastic Block Store (EBS) volume in Amazon Elastic Compute Cloud (EC2). You can take snapshots of your gateway volume on a scheduled or ad hoc basis. This API enables you to take ad-hoc snapshot. For more information, see <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/managing-volumes.html#SchedulingSnapshot">Editing a Snapshot Schedule</a>.</p> <p>In the CreateSnapshot request you identify the volume by providing its Amazon Resource Name (ARN). You must also provide description for the snapshot. When AWS Storage Gateway takes the snapshot of specified volume, the snapshot and description appears in the AWS Storage Gateway Console. In response, AWS Storage Gateway returns you a snapshot ID. You can use this snapshot ID to check the snapshot progress or later use it when you want to create a volume from a snapshot. This operation is only supported in stored and cached volume gateway type.</p> <note> <p>To list or delete a snapshot, you must use the Amazon EC2 API. For more information, see DescribeSnapshots or DeleteSnapshot in the <a href="https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_Operations.html">EC2 API reference</a>.</p> </note> <important> <p>Volume and snapshot IDs are changing to a longer length ID format. For more information, see the important note on the <a href="https://docs.aws.amazon.com/storagegateway/latest/APIReference/Welcome.html">Welcome</a> page.</p> </important>
  ##   body: JObject (required)
  var body_603252 = newJObject()
  if body != nil:
    body_603252 = body
  result = call_603251.call(nil, nil, nil, nil, body_603252)

var createSnapshot* = Call_CreateSnapshot_603238(name: "createSnapshot",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.CreateSnapshot",
    validator: validate_CreateSnapshot_603239, base: "/", url: url_CreateSnapshot_603240,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSnapshotFromVolumeRecoveryPoint_603253 = ref object of OpenApiRestCall_602467
proc url_CreateSnapshotFromVolumeRecoveryPoint_603255(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateSnapshotFromVolumeRecoveryPoint_603254(path: JsonNode;
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
  var valid_603256 = header.getOrDefault("X-Amz-Date")
  valid_603256 = validateParameter(valid_603256, JString, required = false,
                                 default = nil)
  if valid_603256 != nil:
    section.add "X-Amz-Date", valid_603256
  var valid_603257 = header.getOrDefault("X-Amz-Security-Token")
  valid_603257 = validateParameter(valid_603257, JString, required = false,
                                 default = nil)
  if valid_603257 != nil:
    section.add "X-Amz-Security-Token", valid_603257
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603258 = header.getOrDefault("X-Amz-Target")
  valid_603258 = validateParameter(valid_603258, JString, required = true, default = newJString(
      "StorageGateway_20130630.CreateSnapshotFromVolumeRecoveryPoint"))
  if valid_603258 != nil:
    section.add "X-Amz-Target", valid_603258
  var valid_603259 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "X-Amz-Content-Sha256", valid_603259
  var valid_603260 = header.getOrDefault("X-Amz-Algorithm")
  valid_603260 = validateParameter(valid_603260, JString, required = false,
                                 default = nil)
  if valid_603260 != nil:
    section.add "X-Amz-Algorithm", valid_603260
  var valid_603261 = header.getOrDefault("X-Amz-Signature")
  valid_603261 = validateParameter(valid_603261, JString, required = false,
                                 default = nil)
  if valid_603261 != nil:
    section.add "X-Amz-Signature", valid_603261
  var valid_603262 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603262 = validateParameter(valid_603262, JString, required = false,
                                 default = nil)
  if valid_603262 != nil:
    section.add "X-Amz-SignedHeaders", valid_603262
  var valid_603263 = header.getOrDefault("X-Amz-Credential")
  valid_603263 = validateParameter(valid_603263, JString, required = false,
                                 default = nil)
  if valid_603263 != nil:
    section.add "X-Amz-Credential", valid_603263
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603265: Call_CreateSnapshotFromVolumeRecoveryPoint_603253;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Initiates a snapshot of a gateway from a volume recovery point. This operation is only supported in the cached volume gateway type.</p> <p>A volume recovery point is a point in time at which all data of the volume is consistent and from which you can create a snapshot. To get a list of volume recovery point for cached volume gateway, use <a>ListVolumeRecoveryPoints</a>.</p> <p>In the <code>CreateSnapshotFromVolumeRecoveryPoint</code> request, you identify the volume by providing its Amazon Resource Name (ARN). You must also provide a description for the snapshot. When the gateway takes a snapshot of the specified volume, the snapshot and its description appear in the AWS Storage Gateway console. In response, the gateway returns you a snapshot ID. You can use this snapshot ID to check the snapshot progress or later use it when you want to create a volume from a snapshot.</p> <note> <p>To list or delete a snapshot, you must use the Amazon EC2 API. For more information, in <i>Amazon Elastic Compute Cloud API Reference</i>.</p> </note>
  ## 
  let valid = call_603265.validator(path, query, header, formData, body)
  let scheme = call_603265.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603265.url(scheme.get, call_603265.host, call_603265.base,
                         call_603265.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603265, url, valid)

proc call*(call_603266: Call_CreateSnapshotFromVolumeRecoveryPoint_603253;
          body: JsonNode): Recallable =
  ## createSnapshotFromVolumeRecoveryPoint
  ## <p>Initiates a snapshot of a gateway from a volume recovery point. This operation is only supported in the cached volume gateway type.</p> <p>A volume recovery point is a point in time at which all data of the volume is consistent and from which you can create a snapshot. To get a list of volume recovery point for cached volume gateway, use <a>ListVolumeRecoveryPoints</a>.</p> <p>In the <code>CreateSnapshotFromVolumeRecoveryPoint</code> request, you identify the volume by providing its Amazon Resource Name (ARN). You must also provide a description for the snapshot. When the gateway takes a snapshot of the specified volume, the snapshot and its description appear in the AWS Storage Gateway console. In response, the gateway returns you a snapshot ID. You can use this snapshot ID to check the snapshot progress or later use it when you want to create a volume from a snapshot.</p> <note> <p>To list or delete a snapshot, you must use the Amazon EC2 API. For more information, in <i>Amazon Elastic Compute Cloud API Reference</i>.</p> </note>
  ##   body: JObject (required)
  var body_603267 = newJObject()
  if body != nil:
    body_603267 = body
  result = call_603266.call(nil, nil, nil, nil, body_603267)

var createSnapshotFromVolumeRecoveryPoint* = Call_CreateSnapshotFromVolumeRecoveryPoint_603253(
    name: "createSnapshotFromVolumeRecoveryPoint", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com", route: "/#X-Amz-Target=StorageGateway_20130630.CreateSnapshotFromVolumeRecoveryPoint",
    validator: validate_CreateSnapshotFromVolumeRecoveryPoint_603254, base: "/",
    url: url_CreateSnapshotFromVolumeRecoveryPoint_603255,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStorediSCSIVolume_603268 = ref object of OpenApiRestCall_602467
proc url_CreateStorediSCSIVolume_603270(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateStorediSCSIVolume_603269(path: JsonNode; query: JsonNode;
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
  var valid_603271 = header.getOrDefault("X-Amz-Date")
  valid_603271 = validateParameter(valid_603271, JString, required = false,
                                 default = nil)
  if valid_603271 != nil:
    section.add "X-Amz-Date", valid_603271
  var valid_603272 = header.getOrDefault("X-Amz-Security-Token")
  valid_603272 = validateParameter(valid_603272, JString, required = false,
                                 default = nil)
  if valid_603272 != nil:
    section.add "X-Amz-Security-Token", valid_603272
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603273 = header.getOrDefault("X-Amz-Target")
  valid_603273 = validateParameter(valid_603273, JString, required = true, default = newJString(
      "StorageGateway_20130630.CreateStorediSCSIVolume"))
  if valid_603273 != nil:
    section.add "X-Amz-Target", valid_603273
  var valid_603274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603274 = validateParameter(valid_603274, JString, required = false,
                                 default = nil)
  if valid_603274 != nil:
    section.add "X-Amz-Content-Sha256", valid_603274
  var valid_603275 = header.getOrDefault("X-Amz-Algorithm")
  valid_603275 = validateParameter(valid_603275, JString, required = false,
                                 default = nil)
  if valid_603275 != nil:
    section.add "X-Amz-Algorithm", valid_603275
  var valid_603276 = header.getOrDefault("X-Amz-Signature")
  valid_603276 = validateParameter(valid_603276, JString, required = false,
                                 default = nil)
  if valid_603276 != nil:
    section.add "X-Amz-Signature", valid_603276
  var valid_603277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603277 = validateParameter(valid_603277, JString, required = false,
                                 default = nil)
  if valid_603277 != nil:
    section.add "X-Amz-SignedHeaders", valid_603277
  var valid_603278 = header.getOrDefault("X-Amz-Credential")
  valid_603278 = validateParameter(valid_603278, JString, required = false,
                                 default = nil)
  if valid_603278 != nil:
    section.add "X-Amz-Credential", valid_603278
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603280: Call_CreateStorediSCSIVolume_603268; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a volume on a specified gateway. This operation is only supported in the stored volume gateway type.</p> <p>The size of the volume to create is inferred from the disk size. You can choose to preserve existing data on the disk, create volume from an existing snapshot, or create an empty volume. If you choose to create an empty gateway volume, then any existing data on the disk is erased.</p> <p>In the request you must specify the gateway and the disk information on which you are creating the volume. In response, the gateway creates the volume and returns volume information such as the volume Amazon Resource Name (ARN), its size, and the iSCSI target ARN that initiators can use to connect to the volume target.</p>
  ## 
  let valid = call_603280.validator(path, query, header, formData, body)
  let scheme = call_603280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603280.url(scheme.get, call_603280.host, call_603280.base,
                         call_603280.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603280, url, valid)

proc call*(call_603281: Call_CreateStorediSCSIVolume_603268; body: JsonNode): Recallable =
  ## createStorediSCSIVolume
  ## <p>Creates a volume on a specified gateway. This operation is only supported in the stored volume gateway type.</p> <p>The size of the volume to create is inferred from the disk size. You can choose to preserve existing data on the disk, create volume from an existing snapshot, or create an empty volume. If you choose to create an empty gateway volume, then any existing data on the disk is erased.</p> <p>In the request you must specify the gateway and the disk information on which you are creating the volume. In response, the gateway creates the volume and returns volume information such as the volume Amazon Resource Name (ARN), its size, and the iSCSI target ARN that initiators can use to connect to the volume target.</p>
  ##   body: JObject (required)
  var body_603282 = newJObject()
  if body != nil:
    body_603282 = body
  result = call_603281.call(nil, nil, nil, nil, body_603282)

var createStorediSCSIVolume* = Call_CreateStorediSCSIVolume_603268(
    name: "createStorediSCSIVolume", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.CreateStorediSCSIVolume",
    validator: validate_CreateStorediSCSIVolume_603269, base: "/",
    url: url_CreateStorediSCSIVolume_603270, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTapeWithBarcode_603283 = ref object of OpenApiRestCall_602467
proc url_CreateTapeWithBarcode_603285(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateTapeWithBarcode_603284(path: JsonNode; query: JsonNode;
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
  var valid_603286 = header.getOrDefault("X-Amz-Date")
  valid_603286 = validateParameter(valid_603286, JString, required = false,
                                 default = nil)
  if valid_603286 != nil:
    section.add "X-Amz-Date", valid_603286
  var valid_603287 = header.getOrDefault("X-Amz-Security-Token")
  valid_603287 = validateParameter(valid_603287, JString, required = false,
                                 default = nil)
  if valid_603287 != nil:
    section.add "X-Amz-Security-Token", valid_603287
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603288 = header.getOrDefault("X-Amz-Target")
  valid_603288 = validateParameter(valid_603288, JString, required = true, default = newJString(
      "StorageGateway_20130630.CreateTapeWithBarcode"))
  if valid_603288 != nil:
    section.add "X-Amz-Target", valid_603288
  var valid_603289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603289 = validateParameter(valid_603289, JString, required = false,
                                 default = nil)
  if valid_603289 != nil:
    section.add "X-Amz-Content-Sha256", valid_603289
  var valid_603290 = header.getOrDefault("X-Amz-Algorithm")
  valid_603290 = validateParameter(valid_603290, JString, required = false,
                                 default = nil)
  if valid_603290 != nil:
    section.add "X-Amz-Algorithm", valid_603290
  var valid_603291 = header.getOrDefault("X-Amz-Signature")
  valid_603291 = validateParameter(valid_603291, JString, required = false,
                                 default = nil)
  if valid_603291 != nil:
    section.add "X-Amz-Signature", valid_603291
  var valid_603292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603292 = validateParameter(valid_603292, JString, required = false,
                                 default = nil)
  if valid_603292 != nil:
    section.add "X-Amz-SignedHeaders", valid_603292
  var valid_603293 = header.getOrDefault("X-Amz-Credential")
  valid_603293 = validateParameter(valid_603293, JString, required = false,
                                 default = nil)
  if valid_603293 != nil:
    section.add "X-Amz-Credential", valid_603293
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603295: Call_CreateTapeWithBarcode_603283; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a virtual tape by using your own barcode. You write data to the virtual tape and then archive the tape. A barcode is unique and can not be reused if it has already been used on a tape . This applies to barcodes used on deleted tapes. This operation is only supported in the tape gateway type.</p> <note> <p>Cache storage must be allocated to the gateway before you can create a virtual tape. Use the <a>AddCache</a> operation to add cache storage to a gateway.</p> </note>
  ## 
  let valid = call_603295.validator(path, query, header, formData, body)
  let scheme = call_603295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603295.url(scheme.get, call_603295.host, call_603295.base,
                         call_603295.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603295, url, valid)

proc call*(call_603296: Call_CreateTapeWithBarcode_603283; body: JsonNode): Recallable =
  ## createTapeWithBarcode
  ## <p>Creates a virtual tape by using your own barcode. You write data to the virtual tape and then archive the tape. A barcode is unique and can not be reused if it has already been used on a tape . This applies to barcodes used on deleted tapes. This operation is only supported in the tape gateway type.</p> <note> <p>Cache storage must be allocated to the gateway before you can create a virtual tape. Use the <a>AddCache</a> operation to add cache storage to a gateway.</p> </note>
  ##   body: JObject (required)
  var body_603297 = newJObject()
  if body != nil:
    body_603297 = body
  result = call_603296.call(nil, nil, nil, nil, body_603297)

var createTapeWithBarcode* = Call_CreateTapeWithBarcode_603283(
    name: "createTapeWithBarcode", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.CreateTapeWithBarcode",
    validator: validate_CreateTapeWithBarcode_603284, base: "/",
    url: url_CreateTapeWithBarcode_603285, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTapes_603298 = ref object of OpenApiRestCall_602467
proc url_CreateTapes_603300(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateTapes_603299(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603301 = header.getOrDefault("X-Amz-Date")
  valid_603301 = validateParameter(valid_603301, JString, required = false,
                                 default = nil)
  if valid_603301 != nil:
    section.add "X-Amz-Date", valid_603301
  var valid_603302 = header.getOrDefault("X-Amz-Security-Token")
  valid_603302 = validateParameter(valid_603302, JString, required = false,
                                 default = nil)
  if valid_603302 != nil:
    section.add "X-Amz-Security-Token", valid_603302
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603303 = header.getOrDefault("X-Amz-Target")
  valid_603303 = validateParameter(valid_603303, JString, required = true, default = newJString(
      "StorageGateway_20130630.CreateTapes"))
  if valid_603303 != nil:
    section.add "X-Amz-Target", valid_603303
  var valid_603304 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603304 = validateParameter(valid_603304, JString, required = false,
                                 default = nil)
  if valid_603304 != nil:
    section.add "X-Amz-Content-Sha256", valid_603304
  var valid_603305 = header.getOrDefault("X-Amz-Algorithm")
  valid_603305 = validateParameter(valid_603305, JString, required = false,
                                 default = nil)
  if valid_603305 != nil:
    section.add "X-Amz-Algorithm", valid_603305
  var valid_603306 = header.getOrDefault("X-Amz-Signature")
  valid_603306 = validateParameter(valid_603306, JString, required = false,
                                 default = nil)
  if valid_603306 != nil:
    section.add "X-Amz-Signature", valid_603306
  var valid_603307 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603307 = validateParameter(valid_603307, JString, required = false,
                                 default = nil)
  if valid_603307 != nil:
    section.add "X-Amz-SignedHeaders", valid_603307
  var valid_603308 = header.getOrDefault("X-Amz-Credential")
  valid_603308 = validateParameter(valid_603308, JString, required = false,
                                 default = nil)
  if valid_603308 != nil:
    section.add "X-Amz-Credential", valid_603308
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603310: Call_CreateTapes_603298; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates one or more virtual tapes. You write data to the virtual tapes and then archive the tapes. This operation is only supported in the tape gateway type.</p> <note> <p>Cache storage must be allocated to the gateway before you can create virtual tapes. Use the <a>AddCache</a> operation to add cache storage to a gateway. </p> </note>
  ## 
  let valid = call_603310.validator(path, query, header, formData, body)
  let scheme = call_603310.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603310.url(scheme.get, call_603310.host, call_603310.base,
                         call_603310.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603310, url, valid)

proc call*(call_603311: Call_CreateTapes_603298; body: JsonNode): Recallable =
  ## createTapes
  ## <p>Creates one or more virtual tapes. You write data to the virtual tapes and then archive the tapes. This operation is only supported in the tape gateway type.</p> <note> <p>Cache storage must be allocated to the gateway before you can create virtual tapes. Use the <a>AddCache</a> operation to add cache storage to a gateway. </p> </note>
  ##   body: JObject (required)
  var body_603312 = newJObject()
  if body != nil:
    body_603312 = body
  result = call_603311.call(nil, nil, nil, nil, body_603312)

var createTapes* = Call_CreateTapes_603298(name: "createTapes",
                                        meth: HttpMethod.HttpPost,
                                        host: "storagegateway.amazonaws.com", route: "/#X-Amz-Target=StorageGateway_20130630.CreateTapes",
                                        validator: validate_CreateTapes_603299,
                                        base: "/", url: url_CreateTapes_603300,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBandwidthRateLimit_603313 = ref object of OpenApiRestCall_602467
proc url_DeleteBandwidthRateLimit_603315(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteBandwidthRateLimit_603314(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the bandwidth rate limits of a gateway. You can delete either the upload and download bandwidth rate limit, or you can delete both. If you delete only one of the limits, the other limit remains unchanged. To specify which gateway to work with, use the Amazon Resource Name (ARN) of the gateway in your request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603316 = header.getOrDefault("X-Amz-Date")
  valid_603316 = validateParameter(valid_603316, JString, required = false,
                                 default = nil)
  if valid_603316 != nil:
    section.add "X-Amz-Date", valid_603316
  var valid_603317 = header.getOrDefault("X-Amz-Security-Token")
  valid_603317 = validateParameter(valid_603317, JString, required = false,
                                 default = nil)
  if valid_603317 != nil:
    section.add "X-Amz-Security-Token", valid_603317
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603318 = header.getOrDefault("X-Amz-Target")
  valid_603318 = validateParameter(valid_603318, JString, required = true, default = newJString(
      "StorageGateway_20130630.DeleteBandwidthRateLimit"))
  if valid_603318 != nil:
    section.add "X-Amz-Target", valid_603318
  var valid_603319 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603319 = validateParameter(valid_603319, JString, required = false,
                                 default = nil)
  if valid_603319 != nil:
    section.add "X-Amz-Content-Sha256", valid_603319
  var valid_603320 = header.getOrDefault("X-Amz-Algorithm")
  valid_603320 = validateParameter(valid_603320, JString, required = false,
                                 default = nil)
  if valid_603320 != nil:
    section.add "X-Amz-Algorithm", valid_603320
  var valid_603321 = header.getOrDefault("X-Amz-Signature")
  valid_603321 = validateParameter(valid_603321, JString, required = false,
                                 default = nil)
  if valid_603321 != nil:
    section.add "X-Amz-Signature", valid_603321
  var valid_603322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603322 = validateParameter(valid_603322, JString, required = false,
                                 default = nil)
  if valid_603322 != nil:
    section.add "X-Amz-SignedHeaders", valid_603322
  var valid_603323 = header.getOrDefault("X-Amz-Credential")
  valid_603323 = validateParameter(valid_603323, JString, required = false,
                                 default = nil)
  if valid_603323 != nil:
    section.add "X-Amz-Credential", valid_603323
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603325: Call_DeleteBandwidthRateLimit_603313; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the bandwidth rate limits of a gateway. You can delete either the upload and download bandwidth rate limit, or you can delete both. If you delete only one of the limits, the other limit remains unchanged. To specify which gateway to work with, use the Amazon Resource Name (ARN) of the gateway in your request.
  ## 
  let valid = call_603325.validator(path, query, header, formData, body)
  let scheme = call_603325.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603325.url(scheme.get, call_603325.host, call_603325.base,
                         call_603325.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603325, url, valid)

proc call*(call_603326: Call_DeleteBandwidthRateLimit_603313; body: JsonNode): Recallable =
  ## deleteBandwidthRateLimit
  ## Deletes the bandwidth rate limits of a gateway. You can delete either the upload and download bandwidth rate limit, or you can delete both. If you delete only one of the limits, the other limit remains unchanged. To specify which gateway to work with, use the Amazon Resource Name (ARN) of the gateway in your request.
  ##   body: JObject (required)
  var body_603327 = newJObject()
  if body != nil:
    body_603327 = body
  result = call_603326.call(nil, nil, nil, nil, body_603327)

var deleteBandwidthRateLimit* = Call_DeleteBandwidthRateLimit_603313(
    name: "deleteBandwidthRateLimit", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DeleteBandwidthRateLimit",
    validator: validate_DeleteBandwidthRateLimit_603314, base: "/",
    url: url_DeleteBandwidthRateLimit_603315, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteChapCredentials_603328 = ref object of OpenApiRestCall_602467
proc url_DeleteChapCredentials_603330(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteChapCredentials_603329(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes Challenge-Handshake Authentication Protocol (CHAP) credentials for a specified iSCSI target and initiator pair.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603331 = header.getOrDefault("X-Amz-Date")
  valid_603331 = validateParameter(valid_603331, JString, required = false,
                                 default = nil)
  if valid_603331 != nil:
    section.add "X-Amz-Date", valid_603331
  var valid_603332 = header.getOrDefault("X-Amz-Security-Token")
  valid_603332 = validateParameter(valid_603332, JString, required = false,
                                 default = nil)
  if valid_603332 != nil:
    section.add "X-Amz-Security-Token", valid_603332
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603333 = header.getOrDefault("X-Amz-Target")
  valid_603333 = validateParameter(valid_603333, JString, required = true, default = newJString(
      "StorageGateway_20130630.DeleteChapCredentials"))
  if valid_603333 != nil:
    section.add "X-Amz-Target", valid_603333
  var valid_603334 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603334 = validateParameter(valid_603334, JString, required = false,
                                 default = nil)
  if valid_603334 != nil:
    section.add "X-Amz-Content-Sha256", valid_603334
  var valid_603335 = header.getOrDefault("X-Amz-Algorithm")
  valid_603335 = validateParameter(valid_603335, JString, required = false,
                                 default = nil)
  if valid_603335 != nil:
    section.add "X-Amz-Algorithm", valid_603335
  var valid_603336 = header.getOrDefault("X-Amz-Signature")
  valid_603336 = validateParameter(valid_603336, JString, required = false,
                                 default = nil)
  if valid_603336 != nil:
    section.add "X-Amz-Signature", valid_603336
  var valid_603337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603337 = validateParameter(valid_603337, JString, required = false,
                                 default = nil)
  if valid_603337 != nil:
    section.add "X-Amz-SignedHeaders", valid_603337
  var valid_603338 = header.getOrDefault("X-Amz-Credential")
  valid_603338 = validateParameter(valid_603338, JString, required = false,
                                 default = nil)
  if valid_603338 != nil:
    section.add "X-Amz-Credential", valid_603338
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603340: Call_DeleteChapCredentials_603328; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes Challenge-Handshake Authentication Protocol (CHAP) credentials for a specified iSCSI target and initiator pair.
  ## 
  let valid = call_603340.validator(path, query, header, formData, body)
  let scheme = call_603340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603340.url(scheme.get, call_603340.host, call_603340.base,
                         call_603340.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603340, url, valid)

proc call*(call_603341: Call_DeleteChapCredentials_603328; body: JsonNode): Recallable =
  ## deleteChapCredentials
  ## Deletes Challenge-Handshake Authentication Protocol (CHAP) credentials for a specified iSCSI target and initiator pair.
  ##   body: JObject (required)
  var body_603342 = newJObject()
  if body != nil:
    body_603342 = body
  result = call_603341.call(nil, nil, nil, nil, body_603342)

var deleteChapCredentials* = Call_DeleteChapCredentials_603328(
    name: "deleteChapCredentials", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DeleteChapCredentials",
    validator: validate_DeleteChapCredentials_603329, base: "/",
    url: url_DeleteChapCredentials_603330, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFileShare_603343 = ref object of OpenApiRestCall_602467
proc url_DeleteFileShare_603345(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteFileShare_603344(path: JsonNode; query: JsonNode;
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
  var valid_603346 = header.getOrDefault("X-Amz-Date")
  valid_603346 = validateParameter(valid_603346, JString, required = false,
                                 default = nil)
  if valid_603346 != nil:
    section.add "X-Amz-Date", valid_603346
  var valid_603347 = header.getOrDefault("X-Amz-Security-Token")
  valid_603347 = validateParameter(valid_603347, JString, required = false,
                                 default = nil)
  if valid_603347 != nil:
    section.add "X-Amz-Security-Token", valid_603347
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603348 = header.getOrDefault("X-Amz-Target")
  valid_603348 = validateParameter(valid_603348, JString, required = true, default = newJString(
      "StorageGateway_20130630.DeleteFileShare"))
  if valid_603348 != nil:
    section.add "X-Amz-Target", valid_603348
  var valid_603349 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603349 = validateParameter(valid_603349, JString, required = false,
                                 default = nil)
  if valid_603349 != nil:
    section.add "X-Amz-Content-Sha256", valid_603349
  var valid_603350 = header.getOrDefault("X-Amz-Algorithm")
  valid_603350 = validateParameter(valid_603350, JString, required = false,
                                 default = nil)
  if valid_603350 != nil:
    section.add "X-Amz-Algorithm", valid_603350
  var valid_603351 = header.getOrDefault("X-Amz-Signature")
  valid_603351 = validateParameter(valid_603351, JString, required = false,
                                 default = nil)
  if valid_603351 != nil:
    section.add "X-Amz-Signature", valid_603351
  var valid_603352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603352 = validateParameter(valid_603352, JString, required = false,
                                 default = nil)
  if valid_603352 != nil:
    section.add "X-Amz-SignedHeaders", valid_603352
  var valid_603353 = header.getOrDefault("X-Amz-Credential")
  valid_603353 = validateParameter(valid_603353, JString, required = false,
                                 default = nil)
  if valid_603353 != nil:
    section.add "X-Amz-Credential", valid_603353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603355: Call_DeleteFileShare_603343; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a file share from a file gateway. This operation is only supported for file gateways.
  ## 
  let valid = call_603355.validator(path, query, header, formData, body)
  let scheme = call_603355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603355.url(scheme.get, call_603355.host, call_603355.base,
                         call_603355.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603355, url, valid)

proc call*(call_603356: Call_DeleteFileShare_603343; body: JsonNode): Recallable =
  ## deleteFileShare
  ## Deletes a file share from a file gateway. This operation is only supported for file gateways.
  ##   body: JObject (required)
  var body_603357 = newJObject()
  if body != nil:
    body_603357 = body
  result = call_603356.call(nil, nil, nil, nil, body_603357)

var deleteFileShare* = Call_DeleteFileShare_603343(name: "deleteFileShare",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DeleteFileShare",
    validator: validate_DeleteFileShare_603344, base: "/", url: url_DeleteFileShare_603345,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGateway_603358 = ref object of OpenApiRestCall_602467
proc url_DeleteGateway_603360(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteGateway_603359(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603361 = header.getOrDefault("X-Amz-Date")
  valid_603361 = validateParameter(valid_603361, JString, required = false,
                                 default = nil)
  if valid_603361 != nil:
    section.add "X-Amz-Date", valid_603361
  var valid_603362 = header.getOrDefault("X-Amz-Security-Token")
  valid_603362 = validateParameter(valid_603362, JString, required = false,
                                 default = nil)
  if valid_603362 != nil:
    section.add "X-Amz-Security-Token", valid_603362
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603363 = header.getOrDefault("X-Amz-Target")
  valid_603363 = validateParameter(valid_603363, JString, required = true, default = newJString(
      "StorageGateway_20130630.DeleteGateway"))
  if valid_603363 != nil:
    section.add "X-Amz-Target", valid_603363
  var valid_603364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603364 = validateParameter(valid_603364, JString, required = false,
                                 default = nil)
  if valid_603364 != nil:
    section.add "X-Amz-Content-Sha256", valid_603364
  var valid_603365 = header.getOrDefault("X-Amz-Algorithm")
  valid_603365 = validateParameter(valid_603365, JString, required = false,
                                 default = nil)
  if valid_603365 != nil:
    section.add "X-Amz-Algorithm", valid_603365
  var valid_603366 = header.getOrDefault("X-Amz-Signature")
  valid_603366 = validateParameter(valid_603366, JString, required = false,
                                 default = nil)
  if valid_603366 != nil:
    section.add "X-Amz-Signature", valid_603366
  var valid_603367 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603367 = validateParameter(valid_603367, JString, required = false,
                                 default = nil)
  if valid_603367 != nil:
    section.add "X-Amz-SignedHeaders", valid_603367
  var valid_603368 = header.getOrDefault("X-Amz-Credential")
  valid_603368 = validateParameter(valid_603368, JString, required = false,
                                 default = nil)
  if valid_603368 != nil:
    section.add "X-Amz-Credential", valid_603368
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603370: Call_DeleteGateway_603358; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a gateway. To specify which gateway to delete, use the Amazon Resource Name (ARN) of the gateway in your request. The operation deletes the gateway; however, it does not delete the gateway virtual machine (VM) from your host computer.</p> <p>After you delete a gateway, you cannot reactivate it. Completed snapshots of the gateway volumes are not deleted upon deleting the gateway, however, pending snapshots will not complete. After you delete a gateway, your next step is to remove it from your environment.</p> <important> <p>You no longer pay software charges after the gateway is deleted; however, your existing Amazon EBS snapshots persist and you will continue to be billed for these snapshots. You can choose to remove all remaining Amazon EBS snapshots by canceling your Amazon EC2 subscription.  If you prefer not to cancel your Amazon EC2 subscription, you can delete your snapshots using the Amazon EC2 console. For more information, see the <a href="http://aws.amazon.com/storagegateway"> AWS Storage Gateway Detail Page</a>. </p> </important>
  ## 
  let valid = call_603370.validator(path, query, header, formData, body)
  let scheme = call_603370.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603370.url(scheme.get, call_603370.host, call_603370.base,
                         call_603370.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603370, url, valid)

proc call*(call_603371: Call_DeleteGateway_603358; body: JsonNode): Recallable =
  ## deleteGateway
  ## <p>Deletes a gateway. To specify which gateway to delete, use the Amazon Resource Name (ARN) of the gateway in your request. The operation deletes the gateway; however, it does not delete the gateway virtual machine (VM) from your host computer.</p> <p>After you delete a gateway, you cannot reactivate it. Completed snapshots of the gateway volumes are not deleted upon deleting the gateway, however, pending snapshots will not complete. After you delete a gateway, your next step is to remove it from your environment.</p> <important> <p>You no longer pay software charges after the gateway is deleted; however, your existing Amazon EBS snapshots persist and you will continue to be billed for these snapshots. You can choose to remove all remaining Amazon EBS snapshots by canceling your Amazon EC2 subscription.  If you prefer not to cancel your Amazon EC2 subscription, you can delete your snapshots using the Amazon EC2 console. For more information, see the <a href="http://aws.amazon.com/storagegateway"> AWS Storage Gateway Detail Page</a>. </p> </important>
  ##   body: JObject (required)
  var body_603372 = newJObject()
  if body != nil:
    body_603372 = body
  result = call_603371.call(nil, nil, nil, nil, body_603372)

var deleteGateway* = Call_DeleteGateway_603358(name: "deleteGateway",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DeleteGateway",
    validator: validate_DeleteGateway_603359, base: "/", url: url_DeleteGateway_603360,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSnapshotSchedule_603373 = ref object of OpenApiRestCall_602467
proc url_DeleteSnapshotSchedule_603375(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteSnapshotSchedule_603374(path: JsonNode; query: JsonNode;
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
  var valid_603376 = header.getOrDefault("X-Amz-Date")
  valid_603376 = validateParameter(valid_603376, JString, required = false,
                                 default = nil)
  if valid_603376 != nil:
    section.add "X-Amz-Date", valid_603376
  var valid_603377 = header.getOrDefault("X-Amz-Security-Token")
  valid_603377 = validateParameter(valid_603377, JString, required = false,
                                 default = nil)
  if valid_603377 != nil:
    section.add "X-Amz-Security-Token", valid_603377
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603378 = header.getOrDefault("X-Amz-Target")
  valid_603378 = validateParameter(valid_603378, JString, required = true, default = newJString(
      "StorageGateway_20130630.DeleteSnapshotSchedule"))
  if valid_603378 != nil:
    section.add "X-Amz-Target", valid_603378
  var valid_603379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603379 = validateParameter(valid_603379, JString, required = false,
                                 default = nil)
  if valid_603379 != nil:
    section.add "X-Amz-Content-Sha256", valid_603379
  var valid_603380 = header.getOrDefault("X-Amz-Algorithm")
  valid_603380 = validateParameter(valid_603380, JString, required = false,
                                 default = nil)
  if valid_603380 != nil:
    section.add "X-Amz-Algorithm", valid_603380
  var valid_603381 = header.getOrDefault("X-Amz-Signature")
  valid_603381 = validateParameter(valid_603381, JString, required = false,
                                 default = nil)
  if valid_603381 != nil:
    section.add "X-Amz-Signature", valid_603381
  var valid_603382 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603382 = validateParameter(valid_603382, JString, required = false,
                                 default = nil)
  if valid_603382 != nil:
    section.add "X-Amz-SignedHeaders", valid_603382
  var valid_603383 = header.getOrDefault("X-Amz-Credential")
  valid_603383 = validateParameter(valid_603383, JString, required = false,
                                 default = nil)
  if valid_603383 != nil:
    section.add "X-Amz-Credential", valid_603383
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603385: Call_DeleteSnapshotSchedule_603373; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a snapshot of a volume.</p> <p>You can take snapshots of your gateway volumes on a scheduled or ad hoc basis. This API action enables you to delete a snapshot schedule for a volume. For more information, see <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/WorkingWithSnapshots.html">Working with Snapshots</a>. In the <code>DeleteSnapshotSchedule</code> request, you identify the volume by providing its Amazon Resource Name (ARN). This operation is only supported in stored and cached volume gateway types.</p> <note> <p>To list or delete a snapshot, you must use the Amazon EC2 API. in <i>Amazon Elastic Compute Cloud API Reference</i>.</p> </note>
  ## 
  let valid = call_603385.validator(path, query, header, formData, body)
  let scheme = call_603385.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603385.url(scheme.get, call_603385.host, call_603385.base,
                         call_603385.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603385, url, valid)

proc call*(call_603386: Call_DeleteSnapshotSchedule_603373; body: JsonNode): Recallable =
  ## deleteSnapshotSchedule
  ## <p>Deletes a snapshot of a volume.</p> <p>You can take snapshots of your gateway volumes on a scheduled or ad hoc basis. This API action enables you to delete a snapshot schedule for a volume. For more information, see <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/WorkingWithSnapshots.html">Working with Snapshots</a>. In the <code>DeleteSnapshotSchedule</code> request, you identify the volume by providing its Amazon Resource Name (ARN). This operation is only supported in stored and cached volume gateway types.</p> <note> <p>To list or delete a snapshot, you must use the Amazon EC2 API. in <i>Amazon Elastic Compute Cloud API Reference</i>.</p> </note>
  ##   body: JObject (required)
  var body_603387 = newJObject()
  if body != nil:
    body_603387 = body
  result = call_603386.call(nil, nil, nil, nil, body_603387)

var deleteSnapshotSchedule* = Call_DeleteSnapshotSchedule_603373(
    name: "deleteSnapshotSchedule", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DeleteSnapshotSchedule",
    validator: validate_DeleteSnapshotSchedule_603374, base: "/",
    url: url_DeleteSnapshotSchedule_603375, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTape_603388 = ref object of OpenApiRestCall_602467
proc url_DeleteTape_603390(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteTape_603389(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603391 = header.getOrDefault("X-Amz-Date")
  valid_603391 = validateParameter(valid_603391, JString, required = false,
                                 default = nil)
  if valid_603391 != nil:
    section.add "X-Amz-Date", valid_603391
  var valid_603392 = header.getOrDefault("X-Amz-Security-Token")
  valid_603392 = validateParameter(valid_603392, JString, required = false,
                                 default = nil)
  if valid_603392 != nil:
    section.add "X-Amz-Security-Token", valid_603392
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603393 = header.getOrDefault("X-Amz-Target")
  valid_603393 = validateParameter(valid_603393, JString, required = true, default = newJString(
      "StorageGateway_20130630.DeleteTape"))
  if valid_603393 != nil:
    section.add "X-Amz-Target", valid_603393
  var valid_603394 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603394 = validateParameter(valid_603394, JString, required = false,
                                 default = nil)
  if valid_603394 != nil:
    section.add "X-Amz-Content-Sha256", valid_603394
  var valid_603395 = header.getOrDefault("X-Amz-Algorithm")
  valid_603395 = validateParameter(valid_603395, JString, required = false,
                                 default = nil)
  if valid_603395 != nil:
    section.add "X-Amz-Algorithm", valid_603395
  var valid_603396 = header.getOrDefault("X-Amz-Signature")
  valid_603396 = validateParameter(valid_603396, JString, required = false,
                                 default = nil)
  if valid_603396 != nil:
    section.add "X-Amz-Signature", valid_603396
  var valid_603397 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603397 = validateParameter(valid_603397, JString, required = false,
                                 default = nil)
  if valid_603397 != nil:
    section.add "X-Amz-SignedHeaders", valid_603397
  var valid_603398 = header.getOrDefault("X-Amz-Credential")
  valid_603398 = validateParameter(valid_603398, JString, required = false,
                                 default = nil)
  if valid_603398 != nil:
    section.add "X-Amz-Credential", valid_603398
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603400: Call_DeleteTape_603388; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified virtual tape. This operation is only supported in the tape gateway type.
  ## 
  let valid = call_603400.validator(path, query, header, formData, body)
  let scheme = call_603400.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603400.url(scheme.get, call_603400.host, call_603400.base,
                         call_603400.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603400, url, valid)

proc call*(call_603401: Call_DeleteTape_603388; body: JsonNode): Recallable =
  ## deleteTape
  ## Deletes the specified virtual tape. This operation is only supported in the tape gateway type.
  ##   body: JObject (required)
  var body_603402 = newJObject()
  if body != nil:
    body_603402 = body
  result = call_603401.call(nil, nil, nil, nil, body_603402)

var deleteTape* = Call_DeleteTape_603388(name: "deleteTape",
                                      meth: HttpMethod.HttpPost,
                                      host: "storagegateway.amazonaws.com", route: "/#X-Amz-Target=StorageGateway_20130630.DeleteTape",
                                      validator: validate_DeleteTape_603389,
                                      base: "/", url: url_DeleteTape_603390,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTapeArchive_603403 = ref object of OpenApiRestCall_602467
proc url_DeleteTapeArchive_603405(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteTapeArchive_603404(path: JsonNode; query: JsonNode;
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
      "StorageGateway_20130630.DeleteTapeArchive"))
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

proc call*(call_603415: Call_DeleteTapeArchive_603403; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified virtual tape from the virtual tape shelf (VTS). This operation is only supported in the tape gateway type.
  ## 
  let valid = call_603415.validator(path, query, header, formData, body)
  let scheme = call_603415.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603415.url(scheme.get, call_603415.host, call_603415.base,
                         call_603415.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603415, url, valid)

proc call*(call_603416: Call_DeleteTapeArchive_603403; body: JsonNode): Recallable =
  ## deleteTapeArchive
  ## Deletes the specified virtual tape from the virtual tape shelf (VTS). This operation is only supported in the tape gateway type.
  ##   body: JObject (required)
  var body_603417 = newJObject()
  if body != nil:
    body_603417 = body
  result = call_603416.call(nil, nil, nil, nil, body_603417)

var deleteTapeArchive* = Call_DeleteTapeArchive_603403(name: "deleteTapeArchive",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DeleteTapeArchive",
    validator: validate_DeleteTapeArchive_603404, base: "/",
    url: url_DeleteTapeArchive_603405, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVolume_603418 = ref object of OpenApiRestCall_602467
proc url_DeleteVolume_603420(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteVolume_603419(path: JsonNode; query: JsonNode; header: JsonNode;
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
      "StorageGateway_20130630.DeleteVolume"))
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

proc call*(call_603430: Call_DeleteVolume_603418; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified storage volume that you previously created using the <a>CreateCachediSCSIVolume</a> or <a>CreateStorediSCSIVolume</a> API. This operation is only supported in the cached volume and stored volume types. For stored volume gateways, the local disk that was configured as the storage volume is not deleted. You can reuse the local disk to create another storage volume. </p> <p>Before you delete a volume, make sure there are no iSCSI connections to the volume you are deleting. You should also make sure there is no snapshot in progress. You can use the Amazon Elastic Compute Cloud (Amazon EC2) API to query snapshots on the volume you are deleting and check the snapshot status. For more information, go to <a href="https://docs.aws.amazon.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeSnapshots.html">DescribeSnapshots</a> in the <i>Amazon Elastic Compute Cloud API Reference</i>.</p> <p>In the request, you must provide the Amazon Resource Name (ARN) of the storage volume you want to delete.</p>
  ## 
  let valid = call_603430.validator(path, query, header, formData, body)
  let scheme = call_603430.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603430.url(scheme.get, call_603430.host, call_603430.base,
                         call_603430.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603430, url, valid)

proc call*(call_603431: Call_DeleteVolume_603418; body: JsonNode): Recallable =
  ## deleteVolume
  ## <p>Deletes the specified storage volume that you previously created using the <a>CreateCachediSCSIVolume</a> or <a>CreateStorediSCSIVolume</a> API. This operation is only supported in the cached volume and stored volume types. For stored volume gateways, the local disk that was configured as the storage volume is not deleted. You can reuse the local disk to create another storage volume. </p> <p>Before you delete a volume, make sure there are no iSCSI connections to the volume you are deleting. You should also make sure there is no snapshot in progress. You can use the Amazon Elastic Compute Cloud (Amazon EC2) API to query snapshots on the volume you are deleting and check the snapshot status. For more information, go to <a href="https://docs.aws.amazon.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeSnapshots.html">DescribeSnapshots</a> in the <i>Amazon Elastic Compute Cloud API Reference</i>.</p> <p>In the request, you must provide the Amazon Resource Name (ARN) of the storage volume you want to delete.</p>
  ##   body: JObject (required)
  var body_603432 = newJObject()
  if body != nil:
    body_603432 = body
  result = call_603431.call(nil, nil, nil, nil, body_603432)

var deleteVolume* = Call_DeleteVolume_603418(name: "deleteVolume",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DeleteVolume",
    validator: validate_DeleteVolume_603419, base: "/", url: url_DeleteVolume_603420,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBandwidthRateLimit_603433 = ref object of OpenApiRestCall_602467
proc url_DescribeBandwidthRateLimit_603435(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeBandwidthRateLimit_603434(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns the bandwidth rate limits of a gateway. By default, these limits are not set, which means no bandwidth rate limiting is in effect.</p> <p>This operation only returns a value for a bandwidth rate limit only if the limit is set. If no limits are set for the gateway, then this operation returns only the gateway ARN in the response body. To specify which gateway to describe, use the Amazon Resource Name (ARN) of the gateway in your request.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
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
      "StorageGateway_20130630.DescribeBandwidthRateLimit"))
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

proc call*(call_603445: Call_DescribeBandwidthRateLimit_603433; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the bandwidth rate limits of a gateway. By default, these limits are not set, which means no bandwidth rate limiting is in effect.</p> <p>This operation only returns a value for a bandwidth rate limit only if the limit is set. If no limits are set for the gateway, then this operation returns only the gateway ARN in the response body. To specify which gateway to describe, use the Amazon Resource Name (ARN) of the gateway in your request.</p>
  ## 
  let valid = call_603445.validator(path, query, header, formData, body)
  let scheme = call_603445.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603445.url(scheme.get, call_603445.host, call_603445.base,
                         call_603445.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603445, url, valid)

proc call*(call_603446: Call_DescribeBandwidthRateLimit_603433; body: JsonNode): Recallable =
  ## describeBandwidthRateLimit
  ## <p>Returns the bandwidth rate limits of a gateway. By default, these limits are not set, which means no bandwidth rate limiting is in effect.</p> <p>This operation only returns a value for a bandwidth rate limit only if the limit is set. If no limits are set for the gateway, then this operation returns only the gateway ARN in the response body. To specify which gateway to describe, use the Amazon Resource Name (ARN) of the gateway in your request.</p>
  ##   body: JObject (required)
  var body_603447 = newJObject()
  if body != nil:
    body_603447 = body
  result = call_603446.call(nil, nil, nil, nil, body_603447)

var describeBandwidthRateLimit* = Call_DescribeBandwidthRateLimit_603433(
    name: "describeBandwidthRateLimit", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeBandwidthRateLimit",
    validator: validate_DescribeBandwidthRateLimit_603434, base: "/",
    url: url_DescribeBandwidthRateLimit_603435,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCache_603448 = ref object of OpenApiRestCall_602467
proc url_DescribeCache_603450(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeCache_603449(path: JsonNode; query: JsonNode; header: JsonNode;
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
      "StorageGateway_20130630.DescribeCache"))
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

proc call*(call_603460: Call_DescribeCache_603448; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about the cache of a gateway. This operation is only supported in the cached volume, tape and file gateway types.</p> <p>The response includes disk IDs that are configured as cache, and it includes the amount of cache allocated and used.</p>
  ## 
  let valid = call_603460.validator(path, query, header, formData, body)
  let scheme = call_603460.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603460.url(scheme.get, call_603460.host, call_603460.base,
                         call_603460.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603460, url, valid)

proc call*(call_603461: Call_DescribeCache_603448; body: JsonNode): Recallable =
  ## describeCache
  ## <p>Returns information about the cache of a gateway. This operation is only supported in the cached volume, tape and file gateway types.</p> <p>The response includes disk IDs that are configured as cache, and it includes the amount of cache allocated and used.</p>
  ##   body: JObject (required)
  var body_603462 = newJObject()
  if body != nil:
    body_603462 = body
  result = call_603461.call(nil, nil, nil, nil, body_603462)

var describeCache* = Call_DescribeCache_603448(name: "describeCache",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeCache",
    validator: validate_DescribeCache_603449, base: "/", url: url_DescribeCache_603450,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCachediSCSIVolumes_603463 = ref object of OpenApiRestCall_602467
proc url_DescribeCachediSCSIVolumes_603465(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeCachediSCSIVolumes_603464(path: JsonNode; query: JsonNode;
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
      "StorageGateway_20130630.DescribeCachediSCSIVolumes"))
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

proc call*(call_603475: Call_DescribeCachediSCSIVolumes_603463; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a description of the gateway volumes specified in the request. This operation is only supported in the cached volume gateway types.</p> <p>The list of gateway volumes in the request must be from one gateway. In the response Amazon Storage Gateway returns volume information sorted by volume Amazon Resource Name (ARN).</p>
  ## 
  let valid = call_603475.validator(path, query, header, formData, body)
  let scheme = call_603475.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603475.url(scheme.get, call_603475.host, call_603475.base,
                         call_603475.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603475, url, valid)

proc call*(call_603476: Call_DescribeCachediSCSIVolumes_603463; body: JsonNode): Recallable =
  ## describeCachediSCSIVolumes
  ## <p>Returns a description of the gateway volumes specified in the request. This operation is only supported in the cached volume gateway types.</p> <p>The list of gateway volumes in the request must be from one gateway. In the response Amazon Storage Gateway returns volume information sorted by volume Amazon Resource Name (ARN).</p>
  ##   body: JObject (required)
  var body_603477 = newJObject()
  if body != nil:
    body_603477 = body
  result = call_603476.call(nil, nil, nil, nil, body_603477)

var describeCachediSCSIVolumes* = Call_DescribeCachediSCSIVolumes_603463(
    name: "describeCachediSCSIVolumes", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeCachediSCSIVolumes",
    validator: validate_DescribeCachediSCSIVolumes_603464, base: "/",
    url: url_DescribeCachediSCSIVolumes_603465,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeChapCredentials_603478 = ref object of OpenApiRestCall_602467
proc url_DescribeChapCredentials_603480(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeChapCredentials_603479(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns an array of Challenge-Handshake Authentication Protocol (CHAP) credentials information for a specified iSCSI target, one for each target-initiator pair.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
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
      "StorageGateway_20130630.DescribeChapCredentials"))
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

proc call*(call_603490: Call_DescribeChapCredentials_603478; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of Challenge-Handshake Authentication Protocol (CHAP) credentials information for a specified iSCSI target, one for each target-initiator pair.
  ## 
  let valid = call_603490.validator(path, query, header, formData, body)
  let scheme = call_603490.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603490.url(scheme.get, call_603490.host, call_603490.base,
                         call_603490.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603490, url, valid)

proc call*(call_603491: Call_DescribeChapCredentials_603478; body: JsonNode): Recallable =
  ## describeChapCredentials
  ## Returns an array of Challenge-Handshake Authentication Protocol (CHAP) credentials information for a specified iSCSI target, one for each target-initiator pair.
  ##   body: JObject (required)
  var body_603492 = newJObject()
  if body != nil:
    body_603492 = body
  result = call_603491.call(nil, nil, nil, nil, body_603492)

var describeChapCredentials* = Call_DescribeChapCredentials_603478(
    name: "describeChapCredentials", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeChapCredentials",
    validator: validate_DescribeChapCredentials_603479, base: "/",
    url: url_DescribeChapCredentials_603480, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeGatewayInformation_603493 = ref object of OpenApiRestCall_602467
proc url_DescribeGatewayInformation_603495(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeGatewayInformation_603494(path: JsonNode; query: JsonNode;
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
      "StorageGateway_20130630.DescribeGatewayInformation"))
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

proc call*(call_603505: Call_DescribeGatewayInformation_603493; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata about a gateway such as its name, network interfaces, configured time zone, and the state (whether the gateway is running or not). To specify which gateway to describe, use the Amazon Resource Name (ARN) of the gateway in your request.
  ## 
  let valid = call_603505.validator(path, query, header, formData, body)
  let scheme = call_603505.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603505.url(scheme.get, call_603505.host, call_603505.base,
                         call_603505.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603505, url, valid)

proc call*(call_603506: Call_DescribeGatewayInformation_603493; body: JsonNode): Recallable =
  ## describeGatewayInformation
  ## Returns metadata about a gateway such as its name, network interfaces, configured time zone, and the state (whether the gateway is running or not). To specify which gateway to describe, use the Amazon Resource Name (ARN) of the gateway in your request.
  ##   body: JObject (required)
  var body_603507 = newJObject()
  if body != nil:
    body_603507 = body
  result = call_603506.call(nil, nil, nil, nil, body_603507)

var describeGatewayInformation* = Call_DescribeGatewayInformation_603493(
    name: "describeGatewayInformation", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeGatewayInformation",
    validator: validate_DescribeGatewayInformation_603494, base: "/",
    url: url_DescribeGatewayInformation_603495,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceStartTime_603508 = ref object of OpenApiRestCall_602467
proc url_DescribeMaintenanceStartTime_603510(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeMaintenanceStartTime_603509(path: JsonNode; query: JsonNode;
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
      "StorageGateway_20130630.DescribeMaintenanceStartTime"))
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

proc call*(call_603520: Call_DescribeMaintenanceStartTime_603508; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns your gateway's weekly maintenance start time including the day and time of the week. Note that values are in terms of the gateway's time zone.
  ## 
  let valid = call_603520.validator(path, query, header, formData, body)
  let scheme = call_603520.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603520.url(scheme.get, call_603520.host, call_603520.base,
                         call_603520.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603520, url, valid)

proc call*(call_603521: Call_DescribeMaintenanceStartTime_603508; body: JsonNode): Recallable =
  ## describeMaintenanceStartTime
  ## Returns your gateway's weekly maintenance start time including the day and time of the week. Note that values are in terms of the gateway's time zone.
  ##   body: JObject (required)
  var body_603522 = newJObject()
  if body != nil:
    body_603522 = body
  result = call_603521.call(nil, nil, nil, nil, body_603522)

var describeMaintenanceStartTime* = Call_DescribeMaintenanceStartTime_603508(
    name: "describeMaintenanceStartTime", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com", route: "/#X-Amz-Target=StorageGateway_20130630.DescribeMaintenanceStartTime",
    validator: validate_DescribeMaintenanceStartTime_603509, base: "/",
    url: url_DescribeMaintenanceStartTime_603510,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeNFSFileShares_603523 = ref object of OpenApiRestCall_602467
proc url_DescribeNFSFileShares_603525(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeNFSFileShares_603524(path: JsonNode; query: JsonNode;
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
      "StorageGateway_20130630.DescribeNFSFileShares"))
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

proc call*(call_603535: Call_DescribeNFSFileShares_603523; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a description for one or more Network File System (NFS) file shares from a file gateway. This operation is only supported for file gateways.
  ## 
  let valid = call_603535.validator(path, query, header, formData, body)
  let scheme = call_603535.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603535.url(scheme.get, call_603535.host, call_603535.base,
                         call_603535.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603535, url, valid)

proc call*(call_603536: Call_DescribeNFSFileShares_603523; body: JsonNode): Recallable =
  ## describeNFSFileShares
  ## Gets a description for one or more Network File System (NFS) file shares from a file gateway. This operation is only supported for file gateways.
  ##   body: JObject (required)
  var body_603537 = newJObject()
  if body != nil:
    body_603537 = body
  result = call_603536.call(nil, nil, nil, nil, body_603537)

var describeNFSFileShares* = Call_DescribeNFSFileShares_603523(
    name: "describeNFSFileShares", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeNFSFileShares",
    validator: validate_DescribeNFSFileShares_603524, base: "/",
    url: url_DescribeNFSFileShares_603525, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSMBFileShares_603538 = ref object of OpenApiRestCall_602467
proc url_DescribeSMBFileShares_603540(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeSMBFileShares_603539(path: JsonNode; query: JsonNode;
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
      "StorageGateway_20130630.DescribeSMBFileShares"))
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

proc call*(call_603550: Call_DescribeSMBFileShares_603538; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a description for one or more Server Message Block (SMB) file shares from a file gateway. This operation is only supported for file gateways.
  ## 
  let valid = call_603550.validator(path, query, header, formData, body)
  let scheme = call_603550.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603550.url(scheme.get, call_603550.host, call_603550.base,
                         call_603550.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603550, url, valid)

proc call*(call_603551: Call_DescribeSMBFileShares_603538; body: JsonNode): Recallable =
  ## describeSMBFileShares
  ## Gets a description for one or more Server Message Block (SMB) file shares from a file gateway. This operation is only supported for file gateways.
  ##   body: JObject (required)
  var body_603552 = newJObject()
  if body != nil:
    body_603552 = body
  result = call_603551.call(nil, nil, nil, nil, body_603552)

var describeSMBFileShares* = Call_DescribeSMBFileShares_603538(
    name: "describeSMBFileShares", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeSMBFileShares",
    validator: validate_DescribeSMBFileShares_603539, base: "/",
    url: url_DescribeSMBFileShares_603540, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSMBSettings_603553 = ref object of OpenApiRestCall_602467
proc url_DescribeSMBSettings_603555(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeSMBSettings_603554(path: JsonNode; query: JsonNode;
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
      "StorageGateway_20130630.DescribeSMBSettings"))
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

proc call*(call_603565: Call_DescribeSMBSettings_603553; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a description of a Server Message Block (SMB) file share settings from a file gateway. This operation is only supported for file gateways.
  ## 
  let valid = call_603565.validator(path, query, header, formData, body)
  let scheme = call_603565.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603565.url(scheme.get, call_603565.host, call_603565.base,
                         call_603565.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603565, url, valid)

proc call*(call_603566: Call_DescribeSMBSettings_603553; body: JsonNode): Recallable =
  ## describeSMBSettings
  ## Gets a description of a Server Message Block (SMB) file share settings from a file gateway. This operation is only supported for file gateways.
  ##   body: JObject (required)
  var body_603567 = newJObject()
  if body != nil:
    body_603567 = body
  result = call_603566.call(nil, nil, nil, nil, body_603567)

var describeSMBSettings* = Call_DescribeSMBSettings_603553(
    name: "describeSMBSettings", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeSMBSettings",
    validator: validate_DescribeSMBSettings_603554, base: "/",
    url: url_DescribeSMBSettings_603555, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSnapshotSchedule_603568 = ref object of OpenApiRestCall_602467
proc url_DescribeSnapshotSchedule_603570(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeSnapshotSchedule_603569(path: JsonNode; query: JsonNode;
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
  var valid_603571 = header.getOrDefault("X-Amz-Date")
  valid_603571 = validateParameter(valid_603571, JString, required = false,
                                 default = nil)
  if valid_603571 != nil:
    section.add "X-Amz-Date", valid_603571
  var valid_603572 = header.getOrDefault("X-Amz-Security-Token")
  valid_603572 = validateParameter(valid_603572, JString, required = false,
                                 default = nil)
  if valid_603572 != nil:
    section.add "X-Amz-Security-Token", valid_603572
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603573 = header.getOrDefault("X-Amz-Target")
  valid_603573 = validateParameter(valid_603573, JString, required = true, default = newJString(
      "StorageGateway_20130630.DescribeSnapshotSchedule"))
  if valid_603573 != nil:
    section.add "X-Amz-Target", valid_603573
  var valid_603574 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603574 = validateParameter(valid_603574, JString, required = false,
                                 default = nil)
  if valid_603574 != nil:
    section.add "X-Amz-Content-Sha256", valid_603574
  var valid_603575 = header.getOrDefault("X-Amz-Algorithm")
  valid_603575 = validateParameter(valid_603575, JString, required = false,
                                 default = nil)
  if valid_603575 != nil:
    section.add "X-Amz-Algorithm", valid_603575
  var valid_603576 = header.getOrDefault("X-Amz-Signature")
  valid_603576 = validateParameter(valid_603576, JString, required = false,
                                 default = nil)
  if valid_603576 != nil:
    section.add "X-Amz-Signature", valid_603576
  var valid_603577 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603577 = validateParameter(valid_603577, JString, required = false,
                                 default = nil)
  if valid_603577 != nil:
    section.add "X-Amz-SignedHeaders", valid_603577
  var valid_603578 = header.getOrDefault("X-Amz-Credential")
  valid_603578 = validateParameter(valid_603578, JString, required = false,
                                 default = nil)
  if valid_603578 != nil:
    section.add "X-Amz-Credential", valid_603578
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603580: Call_DescribeSnapshotSchedule_603568; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the snapshot schedule for the specified gateway volume. The snapshot schedule information includes intervals at which snapshots are automatically initiated on the volume. This operation is only supported in the cached volume and stored volume types.
  ## 
  let valid = call_603580.validator(path, query, header, formData, body)
  let scheme = call_603580.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603580.url(scheme.get, call_603580.host, call_603580.base,
                         call_603580.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603580, url, valid)

proc call*(call_603581: Call_DescribeSnapshotSchedule_603568; body: JsonNode): Recallable =
  ## describeSnapshotSchedule
  ## Describes the snapshot schedule for the specified gateway volume. The snapshot schedule information includes intervals at which snapshots are automatically initiated on the volume. This operation is only supported in the cached volume and stored volume types.
  ##   body: JObject (required)
  var body_603582 = newJObject()
  if body != nil:
    body_603582 = body
  result = call_603581.call(nil, nil, nil, nil, body_603582)

var describeSnapshotSchedule* = Call_DescribeSnapshotSchedule_603568(
    name: "describeSnapshotSchedule", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeSnapshotSchedule",
    validator: validate_DescribeSnapshotSchedule_603569, base: "/",
    url: url_DescribeSnapshotSchedule_603570, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeStorediSCSIVolumes_603583 = ref object of OpenApiRestCall_602467
proc url_DescribeStorediSCSIVolumes_603585(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeStorediSCSIVolumes_603584(path: JsonNode; query: JsonNode;
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
  var valid_603586 = header.getOrDefault("X-Amz-Date")
  valid_603586 = validateParameter(valid_603586, JString, required = false,
                                 default = nil)
  if valid_603586 != nil:
    section.add "X-Amz-Date", valid_603586
  var valid_603587 = header.getOrDefault("X-Amz-Security-Token")
  valid_603587 = validateParameter(valid_603587, JString, required = false,
                                 default = nil)
  if valid_603587 != nil:
    section.add "X-Amz-Security-Token", valid_603587
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603588 = header.getOrDefault("X-Amz-Target")
  valid_603588 = validateParameter(valid_603588, JString, required = true, default = newJString(
      "StorageGateway_20130630.DescribeStorediSCSIVolumes"))
  if valid_603588 != nil:
    section.add "X-Amz-Target", valid_603588
  var valid_603589 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603589 = validateParameter(valid_603589, JString, required = false,
                                 default = nil)
  if valid_603589 != nil:
    section.add "X-Amz-Content-Sha256", valid_603589
  var valid_603590 = header.getOrDefault("X-Amz-Algorithm")
  valid_603590 = validateParameter(valid_603590, JString, required = false,
                                 default = nil)
  if valid_603590 != nil:
    section.add "X-Amz-Algorithm", valid_603590
  var valid_603591 = header.getOrDefault("X-Amz-Signature")
  valid_603591 = validateParameter(valid_603591, JString, required = false,
                                 default = nil)
  if valid_603591 != nil:
    section.add "X-Amz-Signature", valid_603591
  var valid_603592 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603592 = validateParameter(valid_603592, JString, required = false,
                                 default = nil)
  if valid_603592 != nil:
    section.add "X-Amz-SignedHeaders", valid_603592
  var valid_603593 = header.getOrDefault("X-Amz-Credential")
  valid_603593 = validateParameter(valid_603593, JString, required = false,
                                 default = nil)
  if valid_603593 != nil:
    section.add "X-Amz-Credential", valid_603593
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603595: Call_DescribeStorediSCSIVolumes_603583; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the description of the gateway volumes specified in the request. The list of gateway volumes in the request must be from one gateway. In the response Amazon Storage Gateway returns volume information sorted by volume ARNs. This operation is only supported in stored volume gateway type.
  ## 
  let valid = call_603595.validator(path, query, header, formData, body)
  let scheme = call_603595.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603595.url(scheme.get, call_603595.host, call_603595.base,
                         call_603595.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603595, url, valid)

proc call*(call_603596: Call_DescribeStorediSCSIVolumes_603583; body: JsonNode): Recallable =
  ## describeStorediSCSIVolumes
  ## Returns the description of the gateway volumes specified in the request. The list of gateway volumes in the request must be from one gateway. In the response Amazon Storage Gateway returns volume information sorted by volume ARNs. This operation is only supported in stored volume gateway type.
  ##   body: JObject (required)
  var body_603597 = newJObject()
  if body != nil:
    body_603597 = body
  result = call_603596.call(nil, nil, nil, nil, body_603597)

var describeStorediSCSIVolumes* = Call_DescribeStorediSCSIVolumes_603583(
    name: "describeStorediSCSIVolumes", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeStorediSCSIVolumes",
    validator: validate_DescribeStorediSCSIVolumes_603584, base: "/",
    url: url_DescribeStorediSCSIVolumes_603585,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTapeArchives_603598 = ref object of OpenApiRestCall_602467
proc url_DescribeTapeArchives_603600(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeTapeArchives_603599(path: JsonNode; query: JsonNode;
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
  var valid_603601 = query.getOrDefault("Limit")
  valid_603601 = validateParameter(valid_603601, JString, required = false,
                                 default = nil)
  if valid_603601 != nil:
    section.add "Limit", valid_603601
  var valid_603602 = query.getOrDefault("Marker")
  valid_603602 = validateParameter(valid_603602, JString, required = false,
                                 default = nil)
  if valid_603602 != nil:
    section.add "Marker", valid_603602
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603603 = header.getOrDefault("X-Amz-Date")
  valid_603603 = validateParameter(valid_603603, JString, required = false,
                                 default = nil)
  if valid_603603 != nil:
    section.add "X-Amz-Date", valid_603603
  var valid_603604 = header.getOrDefault("X-Amz-Security-Token")
  valid_603604 = validateParameter(valid_603604, JString, required = false,
                                 default = nil)
  if valid_603604 != nil:
    section.add "X-Amz-Security-Token", valid_603604
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603605 = header.getOrDefault("X-Amz-Target")
  valid_603605 = validateParameter(valid_603605, JString, required = true, default = newJString(
      "StorageGateway_20130630.DescribeTapeArchives"))
  if valid_603605 != nil:
    section.add "X-Amz-Target", valid_603605
  var valid_603606 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603606 = validateParameter(valid_603606, JString, required = false,
                                 default = nil)
  if valid_603606 != nil:
    section.add "X-Amz-Content-Sha256", valid_603606
  var valid_603607 = header.getOrDefault("X-Amz-Algorithm")
  valid_603607 = validateParameter(valid_603607, JString, required = false,
                                 default = nil)
  if valid_603607 != nil:
    section.add "X-Amz-Algorithm", valid_603607
  var valid_603608 = header.getOrDefault("X-Amz-Signature")
  valid_603608 = validateParameter(valid_603608, JString, required = false,
                                 default = nil)
  if valid_603608 != nil:
    section.add "X-Amz-Signature", valid_603608
  var valid_603609 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603609 = validateParameter(valid_603609, JString, required = false,
                                 default = nil)
  if valid_603609 != nil:
    section.add "X-Amz-SignedHeaders", valid_603609
  var valid_603610 = header.getOrDefault("X-Amz-Credential")
  valid_603610 = validateParameter(valid_603610, JString, required = false,
                                 default = nil)
  if valid_603610 != nil:
    section.add "X-Amz-Credential", valid_603610
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603612: Call_DescribeTapeArchives_603598; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a description of specified virtual tapes in the virtual tape shelf (VTS). This operation is only supported in the tape gateway type.</p> <p>If a specific <code>TapeARN</code> is not specified, AWS Storage Gateway returns a description of all virtual tapes found in the VTS associated with your account.</p>
  ## 
  let valid = call_603612.validator(path, query, header, formData, body)
  let scheme = call_603612.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603612.url(scheme.get, call_603612.host, call_603612.base,
                         call_603612.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603612, url, valid)

proc call*(call_603613: Call_DescribeTapeArchives_603598; body: JsonNode;
          Limit: string = ""; Marker: string = ""): Recallable =
  ## describeTapeArchives
  ## <p>Returns a description of specified virtual tapes in the virtual tape shelf (VTS). This operation is only supported in the tape gateway type.</p> <p>If a specific <code>TapeARN</code> is not specified, AWS Storage Gateway returns a description of all virtual tapes found in the VTS associated with your account.</p>
  ##   Limit: string
  ##        : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_603614 = newJObject()
  var body_603615 = newJObject()
  add(query_603614, "Limit", newJString(Limit))
  add(query_603614, "Marker", newJString(Marker))
  if body != nil:
    body_603615 = body
  result = call_603613.call(nil, query_603614, nil, nil, body_603615)

var describeTapeArchives* = Call_DescribeTapeArchives_603598(
    name: "describeTapeArchives", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeTapeArchives",
    validator: validate_DescribeTapeArchives_603599, base: "/",
    url: url_DescribeTapeArchives_603600, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTapeRecoveryPoints_603617 = ref object of OpenApiRestCall_602467
proc url_DescribeTapeRecoveryPoints_603619(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeTapeRecoveryPoints_603618(path: JsonNode; query: JsonNode;
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
  var valid_603620 = query.getOrDefault("Limit")
  valid_603620 = validateParameter(valid_603620, JString, required = false,
                                 default = nil)
  if valid_603620 != nil:
    section.add "Limit", valid_603620
  var valid_603621 = query.getOrDefault("Marker")
  valid_603621 = validateParameter(valid_603621, JString, required = false,
                                 default = nil)
  if valid_603621 != nil:
    section.add "Marker", valid_603621
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603622 = header.getOrDefault("X-Amz-Date")
  valid_603622 = validateParameter(valid_603622, JString, required = false,
                                 default = nil)
  if valid_603622 != nil:
    section.add "X-Amz-Date", valid_603622
  var valid_603623 = header.getOrDefault("X-Amz-Security-Token")
  valid_603623 = validateParameter(valid_603623, JString, required = false,
                                 default = nil)
  if valid_603623 != nil:
    section.add "X-Amz-Security-Token", valid_603623
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603624 = header.getOrDefault("X-Amz-Target")
  valid_603624 = validateParameter(valid_603624, JString, required = true, default = newJString(
      "StorageGateway_20130630.DescribeTapeRecoveryPoints"))
  if valid_603624 != nil:
    section.add "X-Amz-Target", valid_603624
  var valid_603625 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603625 = validateParameter(valid_603625, JString, required = false,
                                 default = nil)
  if valid_603625 != nil:
    section.add "X-Amz-Content-Sha256", valid_603625
  var valid_603626 = header.getOrDefault("X-Amz-Algorithm")
  valid_603626 = validateParameter(valid_603626, JString, required = false,
                                 default = nil)
  if valid_603626 != nil:
    section.add "X-Amz-Algorithm", valid_603626
  var valid_603627 = header.getOrDefault("X-Amz-Signature")
  valid_603627 = validateParameter(valid_603627, JString, required = false,
                                 default = nil)
  if valid_603627 != nil:
    section.add "X-Amz-Signature", valid_603627
  var valid_603628 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603628 = validateParameter(valid_603628, JString, required = false,
                                 default = nil)
  if valid_603628 != nil:
    section.add "X-Amz-SignedHeaders", valid_603628
  var valid_603629 = header.getOrDefault("X-Amz-Credential")
  valid_603629 = validateParameter(valid_603629, JString, required = false,
                                 default = nil)
  if valid_603629 != nil:
    section.add "X-Amz-Credential", valid_603629
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603631: Call_DescribeTapeRecoveryPoints_603617; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of virtual tape recovery points that are available for the specified tape gateway.</p> <p>A recovery point is a point-in-time view of a virtual tape at which all the data on the virtual tape is consistent. If your gateway crashes, virtual tapes that have recovery points can be recovered to a new gateway. This operation is only supported in the tape gateway type.</p>
  ## 
  let valid = call_603631.validator(path, query, header, formData, body)
  let scheme = call_603631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603631.url(scheme.get, call_603631.host, call_603631.base,
                         call_603631.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603631, url, valid)

proc call*(call_603632: Call_DescribeTapeRecoveryPoints_603617; body: JsonNode;
          Limit: string = ""; Marker: string = ""): Recallable =
  ## describeTapeRecoveryPoints
  ## <p>Returns a list of virtual tape recovery points that are available for the specified tape gateway.</p> <p>A recovery point is a point-in-time view of a virtual tape at which all the data on the virtual tape is consistent. If your gateway crashes, virtual tapes that have recovery points can be recovered to a new gateway. This operation is only supported in the tape gateway type.</p>
  ##   Limit: string
  ##        : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_603633 = newJObject()
  var body_603634 = newJObject()
  add(query_603633, "Limit", newJString(Limit))
  add(query_603633, "Marker", newJString(Marker))
  if body != nil:
    body_603634 = body
  result = call_603632.call(nil, query_603633, nil, nil, body_603634)

var describeTapeRecoveryPoints* = Call_DescribeTapeRecoveryPoints_603617(
    name: "describeTapeRecoveryPoints", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeTapeRecoveryPoints",
    validator: validate_DescribeTapeRecoveryPoints_603618, base: "/",
    url: url_DescribeTapeRecoveryPoints_603619,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTapes_603635 = ref object of OpenApiRestCall_602467
proc url_DescribeTapes_603637(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeTapes_603636(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603638 = query.getOrDefault("Limit")
  valid_603638 = validateParameter(valid_603638, JString, required = false,
                                 default = nil)
  if valid_603638 != nil:
    section.add "Limit", valid_603638
  var valid_603639 = query.getOrDefault("Marker")
  valid_603639 = validateParameter(valid_603639, JString, required = false,
                                 default = nil)
  if valid_603639 != nil:
    section.add "Marker", valid_603639
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603640 = header.getOrDefault("X-Amz-Date")
  valid_603640 = validateParameter(valid_603640, JString, required = false,
                                 default = nil)
  if valid_603640 != nil:
    section.add "X-Amz-Date", valid_603640
  var valid_603641 = header.getOrDefault("X-Amz-Security-Token")
  valid_603641 = validateParameter(valid_603641, JString, required = false,
                                 default = nil)
  if valid_603641 != nil:
    section.add "X-Amz-Security-Token", valid_603641
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603642 = header.getOrDefault("X-Amz-Target")
  valid_603642 = validateParameter(valid_603642, JString, required = true, default = newJString(
      "StorageGateway_20130630.DescribeTapes"))
  if valid_603642 != nil:
    section.add "X-Amz-Target", valid_603642
  var valid_603643 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603643 = validateParameter(valid_603643, JString, required = false,
                                 default = nil)
  if valid_603643 != nil:
    section.add "X-Amz-Content-Sha256", valid_603643
  var valid_603644 = header.getOrDefault("X-Amz-Algorithm")
  valid_603644 = validateParameter(valid_603644, JString, required = false,
                                 default = nil)
  if valid_603644 != nil:
    section.add "X-Amz-Algorithm", valid_603644
  var valid_603645 = header.getOrDefault("X-Amz-Signature")
  valid_603645 = validateParameter(valid_603645, JString, required = false,
                                 default = nil)
  if valid_603645 != nil:
    section.add "X-Amz-Signature", valid_603645
  var valid_603646 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603646 = validateParameter(valid_603646, JString, required = false,
                                 default = nil)
  if valid_603646 != nil:
    section.add "X-Amz-SignedHeaders", valid_603646
  var valid_603647 = header.getOrDefault("X-Amz-Credential")
  valid_603647 = validateParameter(valid_603647, JString, required = false,
                                 default = nil)
  if valid_603647 != nil:
    section.add "X-Amz-Credential", valid_603647
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603649: Call_DescribeTapes_603635; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a description of the specified Amazon Resource Name (ARN) of virtual tapes. If a <code>TapeARN</code> is not specified, returns a description of all virtual tapes associated with the specified gateway. This operation is only supported in the tape gateway type.
  ## 
  let valid = call_603649.validator(path, query, header, formData, body)
  let scheme = call_603649.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603649.url(scheme.get, call_603649.host, call_603649.base,
                         call_603649.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603649, url, valid)

proc call*(call_603650: Call_DescribeTapes_603635; body: JsonNode;
          Limit: string = ""; Marker: string = ""): Recallable =
  ## describeTapes
  ## Returns a description of the specified Amazon Resource Name (ARN) of virtual tapes. If a <code>TapeARN</code> is not specified, returns a description of all virtual tapes associated with the specified gateway. This operation is only supported in the tape gateway type.
  ##   Limit: string
  ##        : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_603651 = newJObject()
  var body_603652 = newJObject()
  add(query_603651, "Limit", newJString(Limit))
  add(query_603651, "Marker", newJString(Marker))
  if body != nil:
    body_603652 = body
  result = call_603650.call(nil, query_603651, nil, nil, body_603652)

var describeTapes* = Call_DescribeTapes_603635(name: "describeTapes",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeTapes",
    validator: validate_DescribeTapes_603636, base: "/", url: url_DescribeTapes_603637,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUploadBuffer_603653 = ref object of OpenApiRestCall_602467
proc url_DescribeUploadBuffer_603655(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeUploadBuffer_603654(path: JsonNode; query: JsonNode;
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
  var valid_603656 = header.getOrDefault("X-Amz-Date")
  valid_603656 = validateParameter(valid_603656, JString, required = false,
                                 default = nil)
  if valid_603656 != nil:
    section.add "X-Amz-Date", valid_603656
  var valid_603657 = header.getOrDefault("X-Amz-Security-Token")
  valid_603657 = validateParameter(valid_603657, JString, required = false,
                                 default = nil)
  if valid_603657 != nil:
    section.add "X-Amz-Security-Token", valid_603657
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603658 = header.getOrDefault("X-Amz-Target")
  valid_603658 = validateParameter(valid_603658, JString, required = true, default = newJString(
      "StorageGateway_20130630.DescribeUploadBuffer"))
  if valid_603658 != nil:
    section.add "X-Amz-Target", valid_603658
  var valid_603659 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603659 = validateParameter(valid_603659, JString, required = false,
                                 default = nil)
  if valid_603659 != nil:
    section.add "X-Amz-Content-Sha256", valid_603659
  var valid_603660 = header.getOrDefault("X-Amz-Algorithm")
  valid_603660 = validateParameter(valid_603660, JString, required = false,
                                 default = nil)
  if valid_603660 != nil:
    section.add "X-Amz-Algorithm", valid_603660
  var valid_603661 = header.getOrDefault("X-Amz-Signature")
  valid_603661 = validateParameter(valid_603661, JString, required = false,
                                 default = nil)
  if valid_603661 != nil:
    section.add "X-Amz-Signature", valid_603661
  var valid_603662 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603662 = validateParameter(valid_603662, JString, required = false,
                                 default = nil)
  if valid_603662 != nil:
    section.add "X-Amz-SignedHeaders", valid_603662
  var valid_603663 = header.getOrDefault("X-Amz-Credential")
  valid_603663 = validateParameter(valid_603663, JString, required = false,
                                 default = nil)
  if valid_603663 != nil:
    section.add "X-Amz-Credential", valid_603663
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603665: Call_DescribeUploadBuffer_603653; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about the upload buffer of a gateway. This operation is supported for the stored volume, cached volume and tape gateway types.</p> <p>The response includes disk IDs that are configured as upload buffer space, and it includes the amount of upload buffer space allocated and used.</p>
  ## 
  let valid = call_603665.validator(path, query, header, formData, body)
  let scheme = call_603665.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603665.url(scheme.get, call_603665.host, call_603665.base,
                         call_603665.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603665, url, valid)

proc call*(call_603666: Call_DescribeUploadBuffer_603653; body: JsonNode): Recallable =
  ## describeUploadBuffer
  ## <p>Returns information about the upload buffer of a gateway. This operation is supported for the stored volume, cached volume and tape gateway types.</p> <p>The response includes disk IDs that are configured as upload buffer space, and it includes the amount of upload buffer space allocated and used.</p>
  ##   body: JObject (required)
  var body_603667 = newJObject()
  if body != nil:
    body_603667 = body
  result = call_603666.call(nil, nil, nil, nil, body_603667)

var describeUploadBuffer* = Call_DescribeUploadBuffer_603653(
    name: "describeUploadBuffer", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeUploadBuffer",
    validator: validate_DescribeUploadBuffer_603654, base: "/",
    url: url_DescribeUploadBuffer_603655, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeVTLDevices_603668 = ref object of OpenApiRestCall_602467
proc url_DescribeVTLDevices_603670(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeVTLDevices_603669(path: JsonNode; query: JsonNode;
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
  var valid_603671 = query.getOrDefault("Limit")
  valid_603671 = validateParameter(valid_603671, JString, required = false,
                                 default = nil)
  if valid_603671 != nil:
    section.add "Limit", valid_603671
  var valid_603672 = query.getOrDefault("Marker")
  valid_603672 = validateParameter(valid_603672, JString, required = false,
                                 default = nil)
  if valid_603672 != nil:
    section.add "Marker", valid_603672
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603673 = header.getOrDefault("X-Amz-Date")
  valid_603673 = validateParameter(valid_603673, JString, required = false,
                                 default = nil)
  if valid_603673 != nil:
    section.add "X-Amz-Date", valid_603673
  var valid_603674 = header.getOrDefault("X-Amz-Security-Token")
  valid_603674 = validateParameter(valid_603674, JString, required = false,
                                 default = nil)
  if valid_603674 != nil:
    section.add "X-Amz-Security-Token", valid_603674
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603675 = header.getOrDefault("X-Amz-Target")
  valid_603675 = validateParameter(valid_603675, JString, required = true, default = newJString(
      "StorageGateway_20130630.DescribeVTLDevices"))
  if valid_603675 != nil:
    section.add "X-Amz-Target", valid_603675
  var valid_603676 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603676 = validateParameter(valid_603676, JString, required = false,
                                 default = nil)
  if valid_603676 != nil:
    section.add "X-Amz-Content-Sha256", valid_603676
  var valid_603677 = header.getOrDefault("X-Amz-Algorithm")
  valid_603677 = validateParameter(valid_603677, JString, required = false,
                                 default = nil)
  if valid_603677 != nil:
    section.add "X-Amz-Algorithm", valid_603677
  var valid_603678 = header.getOrDefault("X-Amz-Signature")
  valid_603678 = validateParameter(valid_603678, JString, required = false,
                                 default = nil)
  if valid_603678 != nil:
    section.add "X-Amz-Signature", valid_603678
  var valid_603679 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603679 = validateParameter(valid_603679, JString, required = false,
                                 default = nil)
  if valid_603679 != nil:
    section.add "X-Amz-SignedHeaders", valid_603679
  var valid_603680 = header.getOrDefault("X-Amz-Credential")
  valid_603680 = validateParameter(valid_603680, JString, required = false,
                                 default = nil)
  if valid_603680 != nil:
    section.add "X-Amz-Credential", valid_603680
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603682: Call_DescribeVTLDevices_603668; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a description of virtual tape library (VTL) devices for the specified tape gateway. In the response, AWS Storage Gateway returns VTL device information.</p> <p>This operation is only supported in the tape gateway type.</p>
  ## 
  let valid = call_603682.validator(path, query, header, formData, body)
  let scheme = call_603682.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603682.url(scheme.get, call_603682.host, call_603682.base,
                         call_603682.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603682, url, valid)

proc call*(call_603683: Call_DescribeVTLDevices_603668; body: JsonNode;
          Limit: string = ""; Marker: string = ""): Recallable =
  ## describeVTLDevices
  ## <p>Returns a description of virtual tape library (VTL) devices for the specified tape gateway. In the response, AWS Storage Gateway returns VTL device information.</p> <p>This operation is only supported in the tape gateway type.</p>
  ##   Limit: string
  ##        : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_603684 = newJObject()
  var body_603685 = newJObject()
  add(query_603684, "Limit", newJString(Limit))
  add(query_603684, "Marker", newJString(Marker))
  if body != nil:
    body_603685 = body
  result = call_603683.call(nil, query_603684, nil, nil, body_603685)

var describeVTLDevices* = Call_DescribeVTLDevices_603668(
    name: "describeVTLDevices", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeVTLDevices",
    validator: validate_DescribeVTLDevices_603669, base: "/",
    url: url_DescribeVTLDevices_603670, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkingStorage_603686 = ref object of OpenApiRestCall_602467
proc url_DescribeWorkingStorage_603688(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeWorkingStorage_603687(path: JsonNode; query: JsonNode;
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
  var valid_603689 = header.getOrDefault("X-Amz-Date")
  valid_603689 = validateParameter(valid_603689, JString, required = false,
                                 default = nil)
  if valid_603689 != nil:
    section.add "X-Amz-Date", valid_603689
  var valid_603690 = header.getOrDefault("X-Amz-Security-Token")
  valid_603690 = validateParameter(valid_603690, JString, required = false,
                                 default = nil)
  if valid_603690 != nil:
    section.add "X-Amz-Security-Token", valid_603690
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603691 = header.getOrDefault("X-Amz-Target")
  valid_603691 = validateParameter(valid_603691, JString, required = true, default = newJString(
      "StorageGateway_20130630.DescribeWorkingStorage"))
  if valid_603691 != nil:
    section.add "X-Amz-Target", valid_603691
  var valid_603692 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603692 = validateParameter(valid_603692, JString, required = false,
                                 default = nil)
  if valid_603692 != nil:
    section.add "X-Amz-Content-Sha256", valid_603692
  var valid_603693 = header.getOrDefault("X-Amz-Algorithm")
  valid_603693 = validateParameter(valid_603693, JString, required = false,
                                 default = nil)
  if valid_603693 != nil:
    section.add "X-Amz-Algorithm", valid_603693
  var valid_603694 = header.getOrDefault("X-Amz-Signature")
  valid_603694 = validateParameter(valid_603694, JString, required = false,
                                 default = nil)
  if valid_603694 != nil:
    section.add "X-Amz-Signature", valid_603694
  var valid_603695 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603695 = validateParameter(valid_603695, JString, required = false,
                                 default = nil)
  if valid_603695 != nil:
    section.add "X-Amz-SignedHeaders", valid_603695
  var valid_603696 = header.getOrDefault("X-Amz-Credential")
  valid_603696 = validateParameter(valid_603696, JString, required = false,
                                 default = nil)
  if valid_603696 != nil:
    section.add "X-Amz-Credential", valid_603696
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603698: Call_DescribeWorkingStorage_603686; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about the working storage of a gateway. This operation is only supported in the stored volumes gateway type. This operation is deprecated in cached volumes API version (20120630). Use DescribeUploadBuffer instead.</p> <note> <p>Working storage is also referred to as upload buffer. You can also use the DescribeUploadBuffer operation to add upload buffer to a stored volume gateway.</p> </note> <p>The response includes disk IDs that are configured as working storage, and it includes the amount of working storage allocated and used.</p>
  ## 
  let valid = call_603698.validator(path, query, header, formData, body)
  let scheme = call_603698.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603698.url(scheme.get, call_603698.host, call_603698.base,
                         call_603698.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603698, url, valid)

proc call*(call_603699: Call_DescribeWorkingStorage_603686; body: JsonNode): Recallable =
  ## describeWorkingStorage
  ## <p>Returns information about the working storage of a gateway. This operation is only supported in the stored volumes gateway type. This operation is deprecated in cached volumes API version (20120630). Use DescribeUploadBuffer instead.</p> <note> <p>Working storage is also referred to as upload buffer. You can also use the DescribeUploadBuffer operation to add upload buffer to a stored volume gateway.</p> </note> <p>The response includes disk IDs that are configured as working storage, and it includes the amount of working storage allocated and used.</p>
  ##   body: JObject (required)
  var body_603700 = newJObject()
  if body != nil:
    body_603700 = body
  result = call_603699.call(nil, nil, nil, nil, body_603700)

var describeWorkingStorage* = Call_DescribeWorkingStorage_603686(
    name: "describeWorkingStorage", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeWorkingStorage",
    validator: validate_DescribeWorkingStorage_603687, base: "/",
    url: url_DescribeWorkingStorage_603688, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachVolume_603701 = ref object of OpenApiRestCall_602467
proc url_DetachVolume_603703(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DetachVolume_603702(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Disconnects a volume from an iSCSI connection and then detaches the volume from the specified gateway. Detaching and attaching a volume enables you to recover your data from one gateway to a different gateway without creating a snapshot. It also makes it easier to move your volumes from an on-premises gateway to a gateway hosted on an Amazon EC2 instance.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603704 = header.getOrDefault("X-Amz-Date")
  valid_603704 = validateParameter(valid_603704, JString, required = false,
                                 default = nil)
  if valid_603704 != nil:
    section.add "X-Amz-Date", valid_603704
  var valid_603705 = header.getOrDefault("X-Amz-Security-Token")
  valid_603705 = validateParameter(valid_603705, JString, required = false,
                                 default = nil)
  if valid_603705 != nil:
    section.add "X-Amz-Security-Token", valid_603705
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603706 = header.getOrDefault("X-Amz-Target")
  valid_603706 = validateParameter(valid_603706, JString, required = true, default = newJString(
      "StorageGateway_20130630.DetachVolume"))
  if valid_603706 != nil:
    section.add "X-Amz-Target", valid_603706
  var valid_603707 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603707 = validateParameter(valid_603707, JString, required = false,
                                 default = nil)
  if valid_603707 != nil:
    section.add "X-Amz-Content-Sha256", valid_603707
  var valid_603708 = header.getOrDefault("X-Amz-Algorithm")
  valid_603708 = validateParameter(valid_603708, JString, required = false,
                                 default = nil)
  if valid_603708 != nil:
    section.add "X-Amz-Algorithm", valid_603708
  var valid_603709 = header.getOrDefault("X-Amz-Signature")
  valid_603709 = validateParameter(valid_603709, JString, required = false,
                                 default = nil)
  if valid_603709 != nil:
    section.add "X-Amz-Signature", valid_603709
  var valid_603710 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603710 = validateParameter(valid_603710, JString, required = false,
                                 default = nil)
  if valid_603710 != nil:
    section.add "X-Amz-SignedHeaders", valid_603710
  var valid_603711 = header.getOrDefault("X-Amz-Credential")
  valid_603711 = validateParameter(valid_603711, JString, required = false,
                                 default = nil)
  if valid_603711 != nil:
    section.add "X-Amz-Credential", valid_603711
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603713: Call_DetachVolume_603701; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disconnects a volume from an iSCSI connection and then detaches the volume from the specified gateway. Detaching and attaching a volume enables you to recover your data from one gateway to a different gateway without creating a snapshot. It also makes it easier to move your volumes from an on-premises gateway to a gateway hosted on an Amazon EC2 instance.
  ## 
  let valid = call_603713.validator(path, query, header, formData, body)
  let scheme = call_603713.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603713.url(scheme.get, call_603713.host, call_603713.base,
                         call_603713.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603713, url, valid)

proc call*(call_603714: Call_DetachVolume_603701; body: JsonNode): Recallable =
  ## detachVolume
  ## Disconnects a volume from an iSCSI connection and then detaches the volume from the specified gateway. Detaching and attaching a volume enables you to recover your data from one gateway to a different gateway without creating a snapshot. It also makes it easier to move your volumes from an on-premises gateway to a gateway hosted on an Amazon EC2 instance.
  ##   body: JObject (required)
  var body_603715 = newJObject()
  if body != nil:
    body_603715 = body
  result = call_603714.call(nil, nil, nil, nil, body_603715)

var detachVolume* = Call_DetachVolume_603701(name: "detachVolume",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DetachVolume",
    validator: validate_DetachVolume_603702, base: "/", url: url_DetachVolume_603703,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableGateway_603716 = ref object of OpenApiRestCall_602467
proc url_DisableGateway_603718(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisableGateway_603717(path: JsonNode; query: JsonNode;
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
  var valid_603719 = header.getOrDefault("X-Amz-Date")
  valid_603719 = validateParameter(valid_603719, JString, required = false,
                                 default = nil)
  if valid_603719 != nil:
    section.add "X-Amz-Date", valid_603719
  var valid_603720 = header.getOrDefault("X-Amz-Security-Token")
  valid_603720 = validateParameter(valid_603720, JString, required = false,
                                 default = nil)
  if valid_603720 != nil:
    section.add "X-Amz-Security-Token", valid_603720
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603721 = header.getOrDefault("X-Amz-Target")
  valid_603721 = validateParameter(valid_603721, JString, required = true, default = newJString(
      "StorageGateway_20130630.DisableGateway"))
  if valid_603721 != nil:
    section.add "X-Amz-Target", valid_603721
  var valid_603722 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603722 = validateParameter(valid_603722, JString, required = false,
                                 default = nil)
  if valid_603722 != nil:
    section.add "X-Amz-Content-Sha256", valid_603722
  var valid_603723 = header.getOrDefault("X-Amz-Algorithm")
  valid_603723 = validateParameter(valid_603723, JString, required = false,
                                 default = nil)
  if valid_603723 != nil:
    section.add "X-Amz-Algorithm", valid_603723
  var valid_603724 = header.getOrDefault("X-Amz-Signature")
  valid_603724 = validateParameter(valid_603724, JString, required = false,
                                 default = nil)
  if valid_603724 != nil:
    section.add "X-Amz-Signature", valid_603724
  var valid_603725 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603725 = validateParameter(valid_603725, JString, required = false,
                                 default = nil)
  if valid_603725 != nil:
    section.add "X-Amz-SignedHeaders", valid_603725
  var valid_603726 = header.getOrDefault("X-Amz-Credential")
  valid_603726 = validateParameter(valid_603726, JString, required = false,
                                 default = nil)
  if valid_603726 != nil:
    section.add "X-Amz-Credential", valid_603726
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603728: Call_DisableGateway_603716; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disables a tape gateway when the gateway is no longer functioning. For example, if your gateway VM is damaged, you can disable the gateway so you can recover virtual tapes.</p> <p>Use this operation for a tape gateway that is not reachable or not functioning. This operation is only supported in the tape gateway type.</p> <important> <p>Once a gateway is disabled it cannot be enabled.</p> </important>
  ## 
  let valid = call_603728.validator(path, query, header, formData, body)
  let scheme = call_603728.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603728.url(scheme.get, call_603728.host, call_603728.base,
                         call_603728.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603728, url, valid)

proc call*(call_603729: Call_DisableGateway_603716; body: JsonNode): Recallable =
  ## disableGateway
  ## <p>Disables a tape gateway when the gateway is no longer functioning. For example, if your gateway VM is damaged, you can disable the gateway so you can recover virtual tapes.</p> <p>Use this operation for a tape gateway that is not reachable or not functioning. This operation is only supported in the tape gateway type.</p> <important> <p>Once a gateway is disabled it cannot be enabled.</p> </important>
  ##   body: JObject (required)
  var body_603730 = newJObject()
  if body != nil:
    body_603730 = body
  result = call_603729.call(nil, nil, nil, nil, body_603730)

var disableGateway* = Call_DisableGateway_603716(name: "disableGateway",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DisableGateway",
    validator: validate_DisableGateway_603717, base: "/", url: url_DisableGateway_603718,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_JoinDomain_603731 = ref object of OpenApiRestCall_602467
proc url_JoinDomain_603733(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_JoinDomain_603732(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603734 = header.getOrDefault("X-Amz-Date")
  valid_603734 = validateParameter(valid_603734, JString, required = false,
                                 default = nil)
  if valid_603734 != nil:
    section.add "X-Amz-Date", valid_603734
  var valid_603735 = header.getOrDefault("X-Amz-Security-Token")
  valid_603735 = validateParameter(valid_603735, JString, required = false,
                                 default = nil)
  if valid_603735 != nil:
    section.add "X-Amz-Security-Token", valid_603735
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603736 = header.getOrDefault("X-Amz-Target")
  valid_603736 = validateParameter(valid_603736, JString, required = true, default = newJString(
      "StorageGateway_20130630.JoinDomain"))
  if valid_603736 != nil:
    section.add "X-Amz-Target", valid_603736
  var valid_603737 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603737 = validateParameter(valid_603737, JString, required = false,
                                 default = nil)
  if valid_603737 != nil:
    section.add "X-Amz-Content-Sha256", valid_603737
  var valid_603738 = header.getOrDefault("X-Amz-Algorithm")
  valid_603738 = validateParameter(valid_603738, JString, required = false,
                                 default = nil)
  if valid_603738 != nil:
    section.add "X-Amz-Algorithm", valid_603738
  var valid_603739 = header.getOrDefault("X-Amz-Signature")
  valid_603739 = validateParameter(valid_603739, JString, required = false,
                                 default = nil)
  if valid_603739 != nil:
    section.add "X-Amz-Signature", valid_603739
  var valid_603740 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603740 = validateParameter(valid_603740, JString, required = false,
                                 default = nil)
  if valid_603740 != nil:
    section.add "X-Amz-SignedHeaders", valid_603740
  var valid_603741 = header.getOrDefault("X-Amz-Credential")
  valid_603741 = validateParameter(valid_603741, JString, required = false,
                                 default = nil)
  if valid_603741 != nil:
    section.add "X-Amz-Credential", valid_603741
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603743: Call_JoinDomain_603731; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a file gateway to an Active Directory domain. This operation is only supported for file gateways that support the SMB file protocol.
  ## 
  let valid = call_603743.validator(path, query, header, formData, body)
  let scheme = call_603743.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603743.url(scheme.get, call_603743.host, call_603743.base,
                         call_603743.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603743, url, valid)

proc call*(call_603744: Call_JoinDomain_603731; body: JsonNode): Recallable =
  ## joinDomain
  ## Adds a file gateway to an Active Directory domain. This operation is only supported for file gateways that support the SMB file protocol.
  ##   body: JObject (required)
  var body_603745 = newJObject()
  if body != nil:
    body_603745 = body
  result = call_603744.call(nil, nil, nil, nil, body_603745)

var joinDomain* = Call_JoinDomain_603731(name: "joinDomain",
                                      meth: HttpMethod.HttpPost,
                                      host: "storagegateway.amazonaws.com", route: "/#X-Amz-Target=StorageGateway_20130630.JoinDomain",
                                      validator: validate_JoinDomain_603732,
                                      base: "/", url: url_JoinDomain_603733,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFileShares_603746 = ref object of OpenApiRestCall_602467
proc url_ListFileShares_603748(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListFileShares_603747(path: JsonNode; query: JsonNode;
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
  var valid_603749 = query.getOrDefault("Limit")
  valid_603749 = validateParameter(valid_603749, JString, required = false,
                                 default = nil)
  if valid_603749 != nil:
    section.add "Limit", valid_603749
  var valid_603750 = query.getOrDefault("Marker")
  valid_603750 = validateParameter(valid_603750, JString, required = false,
                                 default = nil)
  if valid_603750 != nil:
    section.add "Marker", valid_603750
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603751 = header.getOrDefault("X-Amz-Date")
  valid_603751 = validateParameter(valid_603751, JString, required = false,
                                 default = nil)
  if valid_603751 != nil:
    section.add "X-Amz-Date", valid_603751
  var valid_603752 = header.getOrDefault("X-Amz-Security-Token")
  valid_603752 = validateParameter(valid_603752, JString, required = false,
                                 default = nil)
  if valid_603752 != nil:
    section.add "X-Amz-Security-Token", valid_603752
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603753 = header.getOrDefault("X-Amz-Target")
  valid_603753 = validateParameter(valid_603753, JString, required = true, default = newJString(
      "StorageGateway_20130630.ListFileShares"))
  if valid_603753 != nil:
    section.add "X-Amz-Target", valid_603753
  var valid_603754 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603754 = validateParameter(valid_603754, JString, required = false,
                                 default = nil)
  if valid_603754 != nil:
    section.add "X-Amz-Content-Sha256", valid_603754
  var valid_603755 = header.getOrDefault("X-Amz-Algorithm")
  valid_603755 = validateParameter(valid_603755, JString, required = false,
                                 default = nil)
  if valid_603755 != nil:
    section.add "X-Amz-Algorithm", valid_603755
  var valid_603756 = header.getOrDefault("X-Amz-Signature")
  valid_603756 = validateParameter(valid_603756, JString, required = false,
                                 default = nil)
  if valid_603756 != nil:
    section.add "X-Amz-Signature", valid_603756
  var valid_603757 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603757 = validateParameter(valid_603757, JString, required = false,
                                 default = nil)
  if valid_603757 != nil:
    section.add "X-Amz-SignedHeaders", valid_603757
  var valid_603758 = header.getOrDefault("X-Amz-Credential")
  valid_603758 = validateParameter(valid_603758, JString, required = false,
                                 default = nil)
  if valid_603758 != nil:
    section.add "X-Amz-Credential", valid_603758
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603760: Call_ListFileShares_603746; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of the file shares for a specific file gateway, or the list of file shares that belong to the calling user account. This operation is only supported for file gateways.
  ## 
  let valid = call_603760.validator(path, query, header, formData, body)
  let scheme = call_603760.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603760.url(scheme.get, call_603760.host, call_603760.base,
                         call_603760.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603760, url, valid)

proc call*(call_603761: Call_ListFileShares_603746; body: JsonNode;
          Limit: string = ""; Marker: string = ""): Recallable =
  ## listFileShares
  ## Gets a list of the file shares for a specific file gateway, or the list of file shares that belong to the calling user account. This operation is only supported for file gateways.
  ##   Limit: string
  ##        : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_603762 = newJObject()
  var body_603763 = newJObject()
  add(query_603762, "Limit", newJString(Limit))
  add(query_603762, "Marker", newJString(Marker))
  if body != nil:
    body_603763 = body
  result = call_603761.call(nil, query_603762, nil, nil, body_603763)

var listFileShares* = Call_ListFileShares_603746(name: "listFileShares",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.ListFileShares",
    validator: validate_ListFileShares_603747, base: "/", url: url_ListFileShares_603748,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGateways_603764 = ref object of OpenApiRestCall_602467
proc url_ListGateways_603766(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListGateways_603765(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603767 = query.getOrDefault("Limit")
  valid_603767 = validateParameter(valid_603767, JString, required = false,
                                 default = nil)
  if valid_603767 != nil:
    section.add "Limit", valid_603767
  var valid_603768 = query.getOrDefault("Marker")
  valid_603768 = validateParameter(valid_603768, JString, required = false,
                                 default = nil)
  if valid_603768 != nil:
    section.add "Marker", valid_603768
  result.add "query", section
  ## parameters in `header` object:
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
      "StorageGateway_20130630.ListGateways"))
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

proc call*(call_603778: Call_ListGateways_603764; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists gateways owned by an AWS account in an AWS Region specified in the request. The returned list is ordered by gateway Amazon Resource Name (ARN).</p> <p>By default, the operation returns a maximum of 100 gateways. This operation supports pagination that allows you to optionally reduce the number of gateways returned in a response.</p> <p>If you have more gateways than are returned in a response (that is, the response returns only a truncated list of your gateways), the response contains a marker that you can specify in your next request to fetch the next page of gateways.</p>
  ## 
  let valid = call_603778.validator(path, query, header, formData, body)
  let scheme = call_603778.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603778.url(scheme.get, call_603778.host, call_603778.base,
                         call_603778.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603778, url, valid)

proc call*(call_603779: Call_ListGateways_603764; body: JsonNode; Limit: string = "";
          Marker: string = ""): Recallable =
  ## listGateways
  ## <p>Lists gateways owned by an AWS account in an AWS Region specified in the request. The returned list is ordered by gateway Amazon Resource Name (ARN).</p> <p>By default, the operation returns a maximum of 100 gateways. This operation supports pagination that allows you to optionally reduce the number of gateways returned in a response.</p> <p>If you have more gateways than are returned in a response (that is, the response returns only a truncated list of your gateways), the response contains a marker that you can specify in your next request to fetch the next page of gateways.</p>
  ##   Limit: string
  ##        : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_603780 = newJObject()
  var body_603781 = newJObject()
  add(query_603780, "Limit", newJString(Limit))
  add(query_603780, "Marker", newJString(Marker))
  if body != nil:
    body_603781 = body
  result = call_603779.call(nil, query_603780, nil, nil, body_603781)

var listGateways* = Call_ListGateways_603764(name: "listGateways",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.ListGateways",
    validator: validate_ListGateways_603765, base: "/", url: url_ListGateways_603766,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLocalDisks_603782 = ref object of OpenApiRestCall_602467
proc url_ListLocalDisks_603784(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListLocalDisks_603783(path: JsonNode; query: JsonNode;
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
  var valid_603785 = header.getOrDefault("X-Amz-Date")
  valid_603785 = validateParameter(valid_603785, JString, required = false,
                                 default = nil)
  if valid_603785 != nil:
    section.add "X-Amz-Date", valid_603785
  var valid_603786 = header.getOrDefault("X-Amz-Security-Token")
  valid_603786 = validateParameter(valid_603786, JString, required = false,
                                 default = nil)
  if valid_603786 != nil:
    section.add "X-Amz-Security-Token", valid_603786
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603787 = header.getOrDefault("X-Amz-Target")
  valid_603787 = validateParameter(valid_603787, JString, required = true, default = newJString(
      "StorageGateway_20130630.ListLocalDisks"))
  if valid_603787 != nil:
    section.add "X-Amz-Target", valid_603787
  var valid_603788 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603788 = validateParameter(valid_603788, JString, required = false,
                                 default = nil)
  if valid_603788 != nil:
    section.add "X-Amz-Content-Sha256", valid_603788
  var valid_603789 = header.getOrDefault("X-Amz-Algorithm")
  valid_603789 = validateParameter(valid_603789, JString, required = false,
                                 default = nil)
  if valid_603789 != nil:
    section.add "X-Amz-Algorithm", valid_603789
  var valid_603790 = header.getOrDefault("X-Amz-Signature")
  valid_603790 = validateParameter(valid_603790, JString, required = false,
                                 default = nil)
  if valid_603790 != nil:
    section.add "X-Amz-Signature", valid_603790
  var valid_603791 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603791 = validateParameter(valid_603791, JString, required = false,
                                 default = nil)
  if valid_603791 != nil:
    section.add "X-Amz-SignedHeaders", valid_603791
  var valid_603792 = header.getOrDefault("X-Amz-Credential")
  valid_603792 = validateParameter(valid_603792, JString, required = false,
                                 default = nil)
  if valid_603792 != nil:
    section.add "X-Amz-Credential", valid_603792
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603794: Call_ListLocalDisks_603782; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the gateway's local disks. To specify which gateway to describe, you use the Amazon Resource Name (ARN) of the gateway in the body of the request.</p> <p>The request returns a list of all disks, specifying which are configured as working storage, cache storage, or stored volume or not configured at all. The response includes a <code>DiskStatus</code> field. This field can have a value of present (the disk is available to use), missing (the disk is no longer connected to the gateway), or mismatch (the disk node is occupied by a disk that has incorrect metadata or the disk content is corrupted).</p>
  ## 
  let valid = call_603794.validator(path, query, header, formData, body)
  let scheme = call_603794.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603794.url(scheme.get, call_603794.host, call_603794.base,
                         call_603794.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603794, url, valid)

proc call*(call_603795: Call_ListLocalDisks_603782; body: JsonNode): Recallable =
  ## listLocalDisks
  ## <p>Returns a list of the gateway's local disks. To specify which gateway to describe, you use the Amazon Resource Name (ARN) of the gateway in the body of the request.</p> <p>The request returns a list of all disks, specifying which are configured as working storage, cache storage, or stored volume or not configured at all. The response includes a <code>DiskStatus</code> field. This field can have a value of present (the disk is available to use), missing (the disk is no longer connected to the gateway), or mismatch (the disk node is occupied by a disk that has incorrect metadata or the disk content is corrupted).</p>
  ##   body: JObject (required)
  var body_603796 = newJObject()
  if body != nil:
    body_603796 = body
  result = call_603795.call(nil, nil, nil, nil, body_603796)

var listLocalDisks* = Call_ListLocalDisks_603782(name: "listLocalDisks",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.ListLocalDisks",
    validator: validate_ListLocalDisks_603783, base: "/", url: url_ListLocalDisks_603784,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_603797 = ref object of OpenApiRestCall_602467
proc url_ListTagsForResource_603799(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTagsForResource_603798(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Lists the tags that have been added to the specified resource. This operation is only supported in the cached volume, stored volume and tape gateway type.
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
  var valid_603800 = query.getOrDefault("Limit")
  valid_603800 = validateParameter(valid_603800, JString, required = false,
                                 default = nil)
  if valid_603800 != nil:
    section.add "Limit", valid_603800
  var valid_603801 = query.getOrDefault("Marker")
  valid_603801 = validateParameter(valid_603801, JString, required = false,
                                 default = nil)
  if valid_603801 != nil:
    section.add "Marker", valid_603801
  result.add "query", section
  ## parameters in `header` object:
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
      "StorageGateway_20130630.ListTagsForResource"))
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

proc call*(call_603811: Call_ListTagsForResource_603797; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags that have been added to the specified resource. This operation is only supported in the cached volume, stored volume and tape gateway type.
  ## 
  let valid = call_603811.validator(path, query, header, formData, body)
  let scheme = call_603811.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603811.url(scheme.get, call_603811.host, call_603811.base,
                         call_603811.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603811, url, valid)

proc call*(call_603812: Call_ListTagsForResource_603797; body: JsonNode;
          Limit: string = ""; Marker: string = ""): Recallable =
  ## listTagsForResource
  ## Lists the tags that have been added to the specified resource. This operation is only supported in the cached volume, stored volume and tape gateway type.
  ##   Limit: string
  ##        : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_603813 = newJObject()
  var body_603814 = newJObject()
  add(query_603813, "Limit", newJString(Limit))
  add(query_603813, "Marker", newJString(Marker))
  if body != nil:
    body_603814 = body
  result = call_603812.call(nil, query_603813, nil, nil, body_603814)

var listTagsForResource* = Call_ListTagsForResource_603797(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.ListTagsForResource",
    validator: validate_ListTagsForResource_603798, base: "/",
    url: url_ListTagsForResource_603799, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTapes_603815 = ref object of OpenApiRestCall_602467
proc url_ListTapes_603817(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTapes_603816(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603818 = query.getOrDefault("Limit")
  valid_603818 = validateParameter(valid_603818, JString, required = false,
                                 default = nil)
  if valid_603818 != nil:
    section.add "Limit", valid_603818
  var valid_603819 = query.getOrDefault("Marker")
  valid_603819 = validateParameter(valid_603819, JString, required = false,
                                 default = nil)
  if valid_603819 != nil:
    section.add "Marker", valid_603819
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603820 = header.getOrDefault("X-Amz-Date")
  valid_603820 = validateParameter(valid_603820, JString, required = false,
                                 default = nil)
  if valid_603820 != nil:
    section.add "X-Amz-Date", valid_603820
  var valid_603821 = header.getOrDefault("X-Amz-Security-Token")
  valid_603821 = validateParameter(valid_603821, JString, required = false,
                                 default = nil)
  if valid_603821 != nil:
    section.add "X-Amz-Security-Token", valid_603821
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603822 = header.getOrDefault("X-Amz-Target")
  valid_603822 = validateParameter(valid_603822, JString, required = true, default = newJString(
      "StorageGateway_20130630.ListTapes"))
  if valid_603822 != nil:
    section.add "X-Amz-Target", valid_603822
  var valid_603823 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603823 = validateParameter(valid_603823, JString, required = false,
                                 default = nil)
  if valid_603823 != nil:
    section.add "X-Amz-Content-Sha256", valid_603823
  var valid_603824 = header.getOrDefault("X-Amz-Algorithm")
  valid_603824 = validateParameter(valid_603824, JString, required = false,
                                 default = nil)
  if valid_603824 != nil:
    section.add "X-Amz-Algorithm", valid_603824
  var valid_603825 = header.getOrDefault("X-Amz-Signature")
  valid_603825 = validateParameter(valid_603825, JString, required = false,
                                 default = nil)
  if valid_603825 != nil:
    section.add "X-Amz-Signature", valid_603825
  var valid_603826 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603826 = validateParameter(valid_603826, JString, required = false,
                                 default = nil)
  if valid_603826 != nil:
    section.add "X-Amz-SignedHeaders", valid_603826
  var valid_603827 = header.getOrDefault("X-Amz-Credential")
  valid_603827 = validateParameter(valid_603827, JString, required = false,
                                 default = nil)
  if valid_603827 != nil:
    section.add "X-Amz-Credential", valid_603827
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603829: Call_ListTapes_603815; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists virtual tapes in your virtual tape library (VTL) and your virtual tape shelf (VTS). You specify the tapes to list by specifying one or more tape Amazon Resource Names (ARNs). If you don't specify a tape ARN, the operation lists all virtual tapes in both your VTL and VTS.</p> <p>This operation supports pagination. By default, the operation returns a maximum of up to 100 tapes. You can optionally specify the <code>Limit</code> parameter in the body to limit the number of tapes in the response. If the number of tapes returned in the response is truncated, the response includes a <code>Marker</code> element that you can use in your subsequent request to retrieve the next set of tapes. This operation is only supported in the tape gateway type.</p>
  ## 
  let valid = call_603829.validator(path, query, header, formData, body)
  let scheme = call_603829.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603829.url(scheme.get, call_603829.host, call_603829.base,
                         call_603829.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603829, url, valid)

proc call*(call_603830: Call_ListTapes_603815; body: JsonNode; Limit: string = "";
          Marker: string = ""): Recallable =
  ## listTapes
  ## <p>Lists virtual tapes in your virtual tape library (VTL) and your virtual tape shelf (VTS). You specify the tapes to list by specifying one or more tape Amazon Resource Names (ARNs). If you don't specify a tape ARN, the operation lists all virtual tapes in both your VTL and VTS.</p> <p>This operation supports pagination. By default, the operation returns a maximum of up to 100 tapes. You can optionally specify the <code>Limit</code> parameter in the body to limit the number of tapes in the response. If the number of tapes returned in the response is truncated, the response includes a <code>Marker</code> element that you can use in your subsequent request to retrieve the next set of tapes. This operation is only supported in the tape gateway type.</p>
  ##   Limit: string
  ##        : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_603831 = newJObject()
  var body_603832 = newJObject()
  add(query_603831, "Limit", newJString(Limit))
  add(query_603831, "Marker", newJString(Marker))
  if body != nil:
    body_603832 = body
  result = call_603830.call(nil, query_603831, nil, nil, body_603832)

var listTapes* = Call_ListTapes_603815(name: "listTapes", meth: HttpMethod.HttpPost,
                                    host: "storagegateway.amazonaws.com", route: "/#X-Amz-Target=StorageGateway_20130630.ListTapes",
                                    validator: validate_ListTapes_603816,
                                    base: "/", url: url_ListTapes_603817,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVolumeInitiators_603833 = ref object of OpenApiRestCall_602467
proc url_ListVolumeInitiators_603835(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListVolumeInitiators_603834(path: JsonNode; query: JsonNode;
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
  var valid_603836 = header.getOrDefault("X-Amz-Date")
  valid_603836 = validateParameter(valid_603836, JString, required = false,
                                 default = nil)
  if valid_603836 != nil:
    section.add "X-Amz-Date", valid_603836
  var valid_603837 = header.getOrDefault("X-Amz-Security-Token")
  valid_603837 = validateParameter(valid_603837, JString, required = false,
                                 default = nil)
  if valid_603837 != nil:
    section.add "X-Amz-Security-Token", valid_603837
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603838 = header.getOrDefault("X-Amz-Target")
  valid_603838 = validateParameter(valid_603838, JString, required = true, default = newJString(
      "StorageGateway_20130630.ListVolumeInitiators"))
  if valid_603838 != nil:
    section.add "X-Amz-Target", valid_603838
  var valid_603839 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603839 = validateParameter(valid_603839, JString, required = false,
                                 default = nil)
  if valid_603839 != nil:
    section.add "X-Amz-Content-Sha256", valid_603839
  var valid_603840 = header.getOrDefault("X-Amz-Algorithm")
  valid_603840 = validateParameter(valid_603840, JString, required = false,
                                 default = nil)
  if valid_603840 != nil:
    section.add "X-Amz-Algorithm", valid_603840
  var valid_603841 = header.getOrDefault("X-Amz-Signature")
  valid_603841 = validateParameter(valid_603841, JString, required = false,
                                 default = nil)
  if valid_603841 != nil:
    section.add "X-Amz-Signature", valid_603841
  var valid_603842 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603842 = validateParameter(valid_603842, JString, required = false,
                                 default = nil)
  if valid_603842 != nil:
    section.add "X-Amz-SignedHeaders", valid_603842
  var valid_603843 = header.getOrDefault("X-Amz-Credential")
  valid_603843 = validateParameter(valid_603843, JString, required = false,
                                 default = nil)
  if valid_603843 != nil:
    section.add "X-Amz-Credential", valid_603843
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603845: Call_ListVolumeInitiators_603833; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists iSCSI initiators that are connected to a volume. You can use this operation to determine whether a volume is being used or not. This operation is only supported in the cached volume and stored volume gateway types.
  ## 
  let valid = call_603845.validator(path, query, header, formData, body)
  let scheme = call_603845.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603845.url(scheme.get, call_603845.host, call_603845.base,
                         call_603845.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603845, url, valid)

proc call*(call_603846: Call_ListVolumeInitiators_603833; body: JsonNode): Recallable =
  ## listVolumeInitiators
  ## Lists iSCSI initiators that are connected to a volume. You can use this operation to determine whether a volume is being used or not. This operation is only supported in the cached volume and stored volume gateway types.
  ##   body: JObject (required)
  var body_603847 = newJObject()
  if body != nil:
    body_603847 = body
  result = call_603846.call(nil, nil, nil, nil, body_603847)

var listVolumeInitiators* = Call_ListVolumeInitiators_603833(
    name: "listVolumeInitiators", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.ListVolumeInitiators",
    validator: validate_ListVolumeInitiators_603834, base: "/",
    url: url_ListVolumeInitiators_603835, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVolumeRecoveryPoints_603848 = ref object of OpenApiRestCall_602467
proc url_ListVolumeRecoveryPoints_603850(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListVolumeRecoveryPoints_603849(path: JsonNode; query: JsonNode;
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
  var valid_603851 = header.getOrDefault("X-Amz-Date")
  valid_603851 = validateParameter(valid_603851, JString, required = false,
                                 default = nil)
  if valid_603851 != nil:
    section.add "X-Amz-Date", valid_603851
  var valid_603852 = header.getOrDefault("X-Amz-Security-Token")
  valid_603852 = validateParameter(valid_603852, JString, required = false,
                                 default = nil)
  if valid_603852 != nil:
    section.add "X-Amz-Security-Token", valid_603852
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603853 = header.getOrDefault("X-Amz-Target")
  valid_603853 = validateParameter(valid_603853, JString, required = true, default = newJString(
      "StorageGateway_20130630.ListVolumeRecoveryPoints"))
  if valid_603853 != nil:
    section.add "X-Amz-Target", valid_603853
  var valid_603854 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603854 = validateParameter(valid_603854, JString, required = false,
                                 default = nil)
  if valid_603854 != nil:
    section.add "X-Amz-Content-Sha256", valid_603854
  var valid_603855 = header.getOrDefault("X-Amz-Algorithm")
  valid_603855 = validateParameter(valid_603855, JString, required = false,
                                 default = nil)
  if valid_603855 != nil:
    section.add "X-Amz-Algorithm", valid_603855
  var valid_603856 = header.getOrDefault("X-Amz-Signature")
  valid_603856 = validateParameter(valid_603856, JString, required = false,
                                 default = nil)
  if valid_603856 != nil:
    section.add "X-Amz-Signature", valid_603856
  var valid_603857 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603857 = validateParameter(valid_603857, JString, required = false,
                                 default = nil)
  if valid_603857 != nil:
    section.add "X-Amz-SignedHeaders", valid_603857
  var valid_603858 = header.getOrDefault("X-Amz-Credential")
  valid_603858 = validateParameter(valid_603858, JString, required = false,
                                 default = nil)
  if valid_603858 != nil:
    section.add "X-Amz-Credential", valid_603858
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603860: Call_ListVolumeRecoveryPoints_603848; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the recovery points for a specified gateway. This operation is only supported in the cached volume gateway type.</p> <p>Each cache volume has one recovery point. A volume recovery point is a point in time at which all data of the volume is consistent and from which you can create a snapshot or clone a new cached volume from a source volume. To create a snapshot from a volume recovery point use the <a>CreateSnapshotFromVolumeRecoveryPoint</a> operation.</p>
  ## 
  let valid = call_603860.validator(path, query, header, formData, body)
  let scheme = call_603860.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603860.url(scheme.get, call_603860.host, call_603860.base,
                         call_603860.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603860, url, valid)

proc call*(call_603861: Call_ListVolumeRecoveryPoints_603848; body: JsonNode): Recallable =
  ## listVolumeRecoveryPoints
  ## <p>Lists the recovery points for a specified gateway. This operation is only supported in the cached volume gateway type.</p> <p>Each cache volume has one recovery point. A volume recovery point is a point in time at which all data of the volume is consistent and from which you can create a snapshot or clone a new cached volume from a source volume. To create a snapshot from a volume recovery point use the <a>CreateSnapshotFromVolumeRecoveryPoint</a> operation.</p>
  ##   body: JObject (required)
  var body_603862 = newJObject()
  if body != nil:
    body_603862 = body
  result = call_603861.call(nil, nil, nil, nil, body_603862)

var listVolumeRecoveryPoints* = Call_ListVolumeRecoveryPoints_603848(
    name: "listVolumeRecoveryPoints", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.ListVolumeRecoveryPoints",
    validator: validate_ListVolumeRecoveryPoints_603849, base: "/",
    url: url_ListVolumeRecoveryPoints_603850, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVolumes_603863 = ref object of OpenApiRestCall_602467
proc url_ListVolumes_603865(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListVolumes_603864(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603866 = query.getOrDefault("Limit")
  valid_603866 = validateParameter(valid_603866, JString, required = false,
                                 default = nil)
  if valid_603866 != nil:
    section.add "Limit", valid_603866
  var valid_603867 = query.getOrDefault("Marker")
  valid_603867 = validateParameter(valid_603867, JString, required = false,
                                 default = nil)
  if valid_603867 != nil:
    section.add "Marker", valid_603867
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603868 = header.getOrDefault("X-Amz-Date")
  valid_603868 = validateParameter(valid_603868, JString, required = false,
                                 default = nil)
  if valid_603868 != nil:
    section.add "X-Amz-Date", valid_603868
  var valid_603869 = header.getOrDefault("X-Amz-Security-Token")
  valid_603869 = validateParameter(valid_603869, JString, required = false,
                                 default = nil)
  if valid_603869 != nil:
    section.add "X-Amz-Security-Token", valid_603869
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603870 = header.getOrDefault("X-Amz-Target")
  valid_603870 = validateParameter(valid_603870, JString, required = true, default = newJString(
      "StorageGateway_20130630.ListVolumes"))
  if valid_603870 != nil:
    section.add "X-Amz-Target", valid_603870
  var valid_603871 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603871 = validateParameter(valid_603871, JString, required = false,
                                 default = nil)
  if valid_603871 != nil:
    section.add "X-Amz-Content-Sha256", valid_603871
  var valid_603872 = header.getOrDefault("X-Amz-Algorithm")
  valid_603872 = validateParameter(valid_603872, JString, required = false,
                                 default = nil)
  if valid_603872 != nil:
    section.add "X-Amz-Algorithm", valid_603872
  var valid_603873 = header.getOrDefault("X-Amz-Signature")
  valid_603873 = validateParameter(valid_603873, JString, required = false,
                                 default = nil)
  if valid_603873 != nil:
    section.add "X-Amz-Signature", valid_603873
  var valid_603874 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603874 = validateParameter(valid_603874, JString, required = false,
                                 default = nil)
  if valid_603874 != nil:
    section.add "X-Amz-SignedHeaders", valid_603874
  var valid_603875 = header.getOrDefault("X-Amz-Credential")
  valid_603875 = validateParameter(valid_603875, JString, required = false,
                                 default = nil)
  if valid_603875 != nil:
    section.add "X-Amz-Credential", valid_603875
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603877: Call_ListVolumes_603863; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the iSCSI stored volumes of a gateway. Results are sorted by volume ARN. The response includes only the volume ARNs. If you want additional volume information, use the <a>DescribeStorediSCSIVolumes</a> or the <a>DescribeCachediSCSIVolumes</a> API.</p> <p>The operation supports pagination. By default, the operation returns a maximum of up to 100 volumes. You can optionally specify the <code>Limit</code> field in the body to limit the number of volumes in the response. If the number of volumes returned in the response is truncated, the response includes a Marker field. You can use this Marker value in your subsequent request to retrieve the next set of volumes. This operation is only supported in the cached volume and stored volume gateway types.</p>
  ## 
  let valid = call_603877.validator(path, query, header, formData, body)
  let scheme = call_603877.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603877.url(scheme.get, call_603877.host, call_603877.base,
                         call_603877.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603877, url, valid)

proc call*(call_603878: Call_ListVolumes_603863; body: JsonNode; Limit: string = "";
          Marker: string = ""): Recallable =
  ## listVolumes
  ## <p>Lists the iSCSI stored volumes of a gateway. Results are sorted by volume ARN. The response includes only the volume ARNs. If you want additional volume information, use the <a>DescribeStorediSCSIVolumes</a> or the <a>DescribeCachediSCSIVolumes</a> API.</p> <p>The operation supports pagination. By default, the operation returns a maximum of up to 100 volumes. You can optionally specify the <code>Limit</code> field in the body to limit the number of volumes in the response. If the number of volumes returned in the response is truncated, the response includes a Marker field. You can use this Marker value in your subsequent request to retrieve the next set of volumes. This operation is only supported in the cached volume and stored volume gateway types.</p>
  ##   Limit: string
  ##        : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_603879 = newJObject()
  var body_603880 = newJObject()
  add(query_603879, "Limit", newJString(Limit))
  add(query_603879, "Marker", newJString(Marker))
  if body != nil:
    body_603880 = body
  result = call_603878.call(nil, query_603879, nil, nil, body_603880)

var listVolumes* = Call_ListVolumes_603863(name: "listVolumes",
                                        meth: HttpMethod.HttpPost,
                                        host: "storagegateway.amazonaws.com", route: "/#X-Amz-Target=StorageGateway_20130630.ListVolumes",
                                        validator: validate_ListVolumes_603864,
                                        base: "/", url: url_ListVolumes_603865,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_NotifyWhenUploaded_603881 = ref object of OpenApiRestCall_602467
proc url_NotifyWhenUploaded_603883(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_NotifyWhenUploaded_603882(path: JsonNode; query: JsonNode;
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
  var valid_603884 = header.getOrDefault("X-Amz-Date")
  valid_603884 = validateParameter(valid_603884, JString, required = false,
                                 default = nil)
  if valid_603884 != nil:
    section.add "X-Amz-Date", valid_603884
  var valid_603885 = header.getOrDefault("X-Amz-Security-Token")
  valid_603885 = validateParameter(valid_603885, JString, required = false,
                                 default = nil)
  if valid_603885 != nil:
    section.add "X-Amz-Security-Token", valid_603885
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603886 = header.getOrDefault("X-Amz-Target")
  valid_603886 = validateParameter(valid_603886, JString, required = true, default = newJString(
      "StorageGateway_20130630.NotifyWhenUploaded"))
  if valid_603886 != nil:
    section.add "X-Amz-Target", valid_603886
  var valid_603887 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603887 = validateParameter(valid_603887, JString, required = false,
                                 default = nil)
  if valid_603887 != nil:
    section.add "X-Amz-Content-Sha256", valid_603887
  var valid_603888 = header.getOrDefault("X-Amz-Algorithm")
  valid_603888 = validateParameter(valid_603888, JString, required = false,
                                 default = nil)
  if valid_603888 != nil:
    section.add "X-Amz-Algorithm", valid_603888
  var valid_603889 = header.getOrDefault("X-Amz-Signature")
  valid_603889 = validateParameter(valid_603889, JString, required = false,
                                 default = nil)
  if valid_603889 != nil:
    section.add "X-Amz-Signature", valid_603889
  var valid_603890 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603890 = validateParameter(valid_603890, JString, required = false,
                                 default = nil)
  if valid_603890 != nil:
    section.add "X-Amz-SignedHeaders", valid_603890
  var valid_603891 = header.getOrDefault("X-Amz-Credential")
  valid_603891 = validateParameter(valid_603891, JString, required = false,
                                 default = nil)
  if valid_603891 != nil:
    section.add "X-Amz-Credential", valid_603891
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603893: Call_NotifyWhenUploaded_603881; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sends you notification through CloudWatch Events when all files written to your file share have been uploaded to Amazon S3.</p> <p>AWS Storage Gateway can send a notification through Amazon CloudWatch Events when all files written to your file share up to that point in time have been uploaded to Amazon S3. These files include files written to the file share up to the time that you make a request for notification. When the upload is done, Storage Gateway sends you notification through an Amazon CloudWatch Event. You can configure CloudWatch Events to send the notification through event targets such as Amazon SNS or AWS Lambda function. This operation is only supported for file gateways.</p> <p>For more information, see Getting File Upload Notification in the Storage Gateway User Guide (https://docs.aws.amazon.com/storagegateway/latest/userguide/monitoring-file-gateway.html#get-upload-notification). </p>
  ## 
  let valid = call_603893.validator(path, query, header, formData, body)
  let scheme = call_603893.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603893.url(scheme.get, call_603893.host, call_603893.base,
                         call_603893.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603893, url, valid)

proc call*(call_603894: Call_NotifyWhenUploaded_603881; body: JsonNode): Recallable =
  ## notifyWhenUploaded
  ## <p>Sends you notification through CloudWatch Events when all files written to your file share have been uploaded to Amazon S3.</p> <p>AWS Storage Gateway can send a notification through Amazon CloudWatch Events when all files written to your file share up to that point in time have been uploaded to Amazon S3. These files include files written to the file share up to the time that you make a request for notification. When the upload is done, Storage Gateway sends you notification through an Amazon CloudWatch Event. You can configure CloudWatch Events to send the notification through event targets such as Amazon SNS or AWS Lambda function. This operation is only supported for file gateways.</p> <p>For more information, see Getting File Upload Notification in the Storage Gateway User Guide (https://docs.aws.amazon.com/storagegateway/latest/userguide/monitoring-file-gateway.html#get-upload-notification). </p>
  ##   body: JObject (required)
  var body_603895 = newJObject()
  if body != nil:
    body_603895 = body
  result = call_603894.call(nil, nil, nil, nil, body_603895)

var notifyWhenUploaded* = Call_NotifyWhenUploaded_603881(
    name: "notifyWhenUploaded", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.NotifyWhenUploaded",
    validator: validate_NotifyWhenUploaded_603882, base: "/",
    url: url_NotifyWhenUploaded_603883, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RefreshCache_603896 = ref object of OpenApiRestCall_602467
proc url_RefreshCache_603898(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RefreshCache_603897(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Refreshes the cache for the specified file share. This operation finds objects in the Amazon S3 bucket that were added, removed or replaced since the gateway last listed the bucket's contents and cached the results. This operation is only supported in the file gateway type. You can subscribe to be notified through an Amazon CloudWatch event when your RefreshCache operation completes. For more information, see <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/monitoring-file-gateway.html#get-notification">Getting Notified About File Operations</a>.</p> <p>When this API is called, it only initiates the refresh operation. When the API call completes and returns a success code, it doesn't necessarily mean that the file refresh has completed. You should use the refresh-complete notification to determine that the operation has completed before you check for new files on the gateway file share. You can subscribe to be notified through an CloudWatch event when your <code>RefreshCache</code> operation completes. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603899 = header.getOrDefault("X-Amz-Date")
  valid_603899 = validateParameter(valid_603899, JString, required = false,
                                 default = nil)
  if valid_603899 != nil:
    section.add "X-Amz-Date", valid_603899
  var valid_603900 = header.getOrDefault("X-Amz-Security-Token")
  valid_603900 = validateParameter(valid_603900, JString, required = false,
                                 default = nil)
  if valid_603900 != nil:
    section.add "X-Amz-Security-Token", valid_603900
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603901 = header.getOrDefault("X-Amz-Target")
  valid_603901 = validateParameter(valid_603901, JString, required = true, default = newJString(
      "StorageGateway_20130630.RefreshCache"))
  if valid_603901 != nil:
    section.add "X-Amz-Target", valid_603901
  var valid_603902 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603902 = validateParameter(valid_603902, JString, required = false,
                                 default = nil)
  if valid_603902 != nil:
    section.add "X-Amz-Content-Sha256", valid_603902
  var valid_603903 = header.getOrDefault("X-Amz-Algorithm")
  valid_603903 = validateParameter(valid_603903, JString, required = false,
                                 default = nil)
  if valid_603903 != nil:
    section.add "X-Amz-Algorithm", valid_603903
  var valid_603904 = header.getOrDefault("X-Amz-Signature")
  valid_603904 = validateParameter(valid_603904, JString, required = false,
                                 default = nil)
  if valid_603904 != nil:
    section.add "X-Amz-Signature", valid_603904
  var valid_603905 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603905 = validateParameter(valid_603905, JString, required = false,
                                 default = nil)
  if valid_603905 != nil:
    section.add "X-Amz-SignedHeaders", valid_603905
  var valid_603906 = header.getOrDefault("X-Amz-Credential")
  valid_603906 = validateParameter(valid_603906, JString, required = false,
                                 default = nil)
  if valid_603906 != nil:
    section.add "X-Amz-Credential", valid_603906
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603908: Call_RefreshCache_603896; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Refreshes the cache for the specified file share. This operation finds objects in the Amazon S3 bucket that were added, removed or replaced since the gateway last listed the bucket's contents and cached the results. This operation is only supported in the file gateway type. You can subscribe to be notified through an Amazon CloudWatch event when your RefreshCache operation completes. For more information, see <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/monitoring-file-gateway.html#get-notification">Getting Notified About File Operations</a>.</p> <p>When this API is called, it only initiates the refresh operation. When the API call completes and returns a success code, it doesn't necessarily mean that the file refresh has completed. You should use the refresh-complete notification to determine that the operation has completed before you check for new files on the gateway file share. You can subscribe to be notified through an CloudWatch event when your <code>RefreshCache</code> operation completes. </p>
  ## 
  let valid = call_603908.validator(path, query, header, formData, body)
  let scheme = call_603908.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603908.url(scheme.get, call_603908.host, call_603908.base,
                         call_603908.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603908, url, valid)

proc call*(call_603909: Call_RefreshCache_603896; body: JsonNode): Recallable =
  ## refreshCache
  ## <p>Refreshes the cache for the specified file share. This operation finds objects in the Amazon S3 bucket that were added, removed or replaced since the gateway last listed the bucket's contents and cached the results. This operation is only supported in the file gateway type. You can subscribe to be notified through an Amazon CloudWatch event when your RefreshCache operation completes. For more information, see <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/monitoring-file-gateway.html#get-notification">Getting Notified About File Operations</a>.</p> <p>When this API is called, it only initiates the refresh operation. When the API call completes and returns a success code, it doesn't necessarily mean that the file refresh has completed. You should use the refresh-complete notification to determine that the operation has completed before you check for new files on the gateway file share. You can subscribe to be notified through an CloudWatch event when your <code>RefreshCache</code> operation completes. </p>
  ##   body: JObject (required)
  var body_603910 = newJObject()
  if body != nil:
    body_603910 = body
  result = call_603909.call(nil, nil, nil, nil, body_603910)

var refreshCache* = Call_RefreshCache_603896(name: "refreshCache",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.RefreshCache",
    validator: validate_RefreshCache_603897, base: "/", url: url_RefreshCache_603898,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveTagsFromResource_603911 = ref object of OpenApiRestCall_602467
proc url_RemoveTagsFromResource_603913(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RemoveTagsFromResource_603912(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes one or more tags from the specified resource. This operation is only supported in the cached volume, stored volume and tape gateway types.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603914 = header.getOrDefault("X-Amz-Date")
  valid_603914 = validateParameter(valid_603914, JString, required = false,
                                 default = nil)
  if valid_603914 != nil:
    section.add "X-Amz-Date", valid_603914
  var valid_603915 = header.getOrDefault("X-Amz-Security-Token")
  valid_603915 = validateParameter(valid_603915, JString, required = false,
                                 default = nil)
  if valid_603915 != nil:
    section.add "X-Amz-Security-Token", valid_603915
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603916 = header.getOrDefault("X-Amz-Target")
  valid_603916 = validateParameter(valid_603916, JString, required = true, default = newJString(
      "StorageGateway_20130630.RemoveTagsFromResource"))
  if valid_603916 != nil:
    section.add "X-Amz-Target", valid_603916
  var valid_603917 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603917 = validateParameter(valid_603917, JString, required = false,
                                 default = nil)
  if valid_603917 != nil:
    section.add "X-Amz-Content-Sha256", valid_603917
  var valid_603918 = header.getOrDefault("X-Amz-Algorithm")
  valid_603918 = validateParameter(valid_603918, JString, required = false,
                                 default = nil)
  if valid_603918 != nil:
    section.add "X-Amz-Algorithm", valid_603918
  var valid_603919 = header.getOrDefault("X-Amz-Signature")
  valid_603919 = validateParameter(valid_603919, JString, required = false,
                                 default = nil)
  if valid_603919 != nil:
    section.add "X-Amz-Signature", valid_603919
  var valid_603920 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603920 = validateParameter(valid_603920, JString, required = false,
                                 default = nil)
  if valid_603920 != nil:
    section.add "X-Amz-SignedHeaders", valid_603920
  var valid_603921 = header.getOrDefault("X-Amz-Credential")
  valid_603921 = validateParameter(valid_603921, JString, required = false,
                                 default = nil)
  if valid_603921 != nil:
    section.add "X-Amz-Credential", valid_603921
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603923: Call_RemoveTagsFromResource_603911; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from the specified resource. This operation is only supported in the cached volume, stored volume and tape gateway types.
  ## 
  let valid = call_603923.validator(path, query, header, formData, body)
  let scheme = call_603923.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603923.url(scheme.get, call_603923.host, call_603923.base,
                         call_603923.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603923, url, valid)

proc call*(call_603924: Call_RemoveTagsFromResource_603911; body: JsonNode): Recallable =
  ## removeTagsFromResource
  ## Removes one or more tags from the specified resource. This operation is only supported in the cached volume, stored volume and tape gateway types.
  ##   body: JObject (required)
  var body_603925 = newJObject()
  if body != nil:
    body_603925 = body
  result = call_603924.call(nil, nil, nil, nil, body_603925)

var removeTagsFromResource* = Call_RemoveTagsFromResource_603911(
    name: "removeTagsFromResource", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.RemoveTagsFromResource",
    validator: validate_RemoveTagsFromResource_603912, base: "/",
    url: url_RemoveTagsFromResource_603913, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResetCache_603926 = ref object of OpenApiRestCall_602467
proc url_ResetCache_603928(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ResetCache_603927(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603929 = header.getOrDefault("X-Amz-Date")
  valid_603929 = validateParameter(valid_603929, JString, required = false,
                                 default = nil)
  if valid_603929 != nil:
    section.add "X-Amz-Date", valid_603929
  var valid_603930 = header.getOrDefault("X-Amz-Security-Token")
  valid_603930 = validateParameter(valid_603930, JString, required = false,
                                 default = nil)
  if valid_603930 != nil:
    section.add "X-Amz-Security-Token", valid_603930
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603931 = header.getOrDefault("X-Amz-Target")
  valid_603931 = validateParameter(valid_603931, JString, required = true, default = newJString(
      "StorageGateway_20130630.ResetCache"))
  if valid_603931 != nil:
    section.add "X-Amz-Target", valid_603931
  var valid_603932 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603932 = validateParameter(valid_603932, JString, required = false,
                                 default = nil)
  if valid_603932 != nil:
    section.add "X-Amz-Content-Sha256", valid_603932
  var valid_603933 = header.getOrDefault("X-Amz-Algorithm")
  valid_603933 = validateParameter(valid_603933, JString, required = false,
                                 default = nil)
  if valid_603933 != nil:
    section.add "X-Amz-Algorithm", valid_603933
  var valid_603934 = header.getOrDefault("X-Amz-Signature")
  valid_603934 = validateParameter(valid_603934, JString, required = false,
                                 default = nil)
  if valid_603934 != nil:
    section.add "X-Amz-Signature", valid_603934
  var valid_603935 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603935 = validateParameter(valid_603935, JString, required = false,
                                 default = nil)
  if valid_603935 != nil:
    section.add "X-Amz-SignedHeaders", valid_603935
  var valid_603936 = header.getOrDefault("X-Amz-Credential")
  valid_603936 = validateParameter(valid_603936, JString, required = false,
                                 default = nil)
  if valid_603936 != nil:
    section.add "X-Amz-Credential", valid_603936
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603938: Call_ResetCache_603926; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Resets all cache disks that have encountered a error and makes the disks available for reconfiguration as cache storage. If your cache disk encounters a error, the gateway prevents read and write operations on virtual tapes in the gateway. For example, an error can occur when a disk is corrupted or removed from the gateway. When a cache is reset, the gateway loses its cache storage. At this point you can reconfigure the disks as cache disks. This operation is only supported in the cached volume and tape types.</p> <important> <p>If the cache disk you are resetting contains data that has not been uploaded to Amazon S3 yet, that data can be lost. After you reset cache disks, there will be no configured cache disks left in the gateway, so you must configure at least one new cache disk for your gateway to function properly.</p> </important>
  ## 
  let valid = call_603938.validator(path, query, header, formData, body)
  let scheme = call_603938.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603938.url(scheme.get, call_603938.host, call_603938.base,
                         call_603938.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603938, url, valid)

proc call*(call_603939: Call_ResetCache_603926; body: JsonNode): Recallable =
  ## resetCache
  ## <p>Resets all cache disks that have encountered a error and makes the disks available for reconfiguration as cache storage. If your cache disk encounters a error, the gateway prevents read and write operations on virtual tapes in the gateway. For example, an error can occur when a disk is corrupted or removed from the gateway. When a cache is reset, the gateway loses its cache storage. At this point you can reconfigure the disks as cache disks. This operation is only supported in the cached volume and tape types.</p> <important> <p>If the cache disk you are resetting contains data that has not been uploaded to Amazon S3 yet, that data can be lost. After you reset cache disks, there will be no configured cache disks left in the gateway, so you must configure at least one new cache disk for your gateway to function properly.</p> </important>
  ##   body: JObject (required)
  var body_603940 = newJObject()
  if body != nil:
    body_603940 = body
  result = call_603939.call(nil, nil, nil, nil, body_603940)

var resetCache* = Call_ResetCache_603926(name: "resetCache",
                                      meth: HttpMethod.HttpPost,
                                      host: "storagegateway.amazonaws.com", route: "/#X-Amz-Target=StorageGateway_20130630.ResetCache",
                                      validator: validate_ResetCache_603927,
                                      base: "/", url: url_ResetCache_603928,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_RetrieveTapeArchive_603941 = ref object of OpenApiRestCall_602467
proc url_RetrieveTapeArchive_603943(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RetrieveTapeArchive_603942(path: JsonNode; query: JsonNode;
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
  var valid_603944 = header.getOrDefault("X-Amz-Date")
  valid_603944 = validateParameter(valid_603944, JString, required = false,
                                 default = nil)
  if valid_603944 != nil:
    section.add "X-Amz-Date", valid_603944
  var valid_603945 = header.getOrDefault("X-Amz-Security-Token")
  valid_603945 = validateParameter(valid_603945, JString, required = false,
                                 default = nil)
  if valid_603945 != nil:
    section.add "X-Amz-Security-Token", valid_603945
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603946 = header.getOrDefault("X-Amz-Target")
  valid_603946 = validateParameter(valid_603946, JString, required = true, default = newJString(
      "StorageGateway_20130630.RetrieveTapeArchive"))
  if valid_603946 != nil:
    section.add "X-Amz-Target", valid_603946
  var valid_603947 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603947 = validateParameter(valid_603947, JString, required = false,
                                 default = nil)
  if valid_603947 != nil:
    section.add "X-Amz-Content-Sha256", valid_603947
  var valid_603948 = header.getOrDefault("X-Amz-Algorithm")
  valid_603948 = validateParameter(valid_603948, JString, required = false,
                                 default = nil)
  if valid_603948 != nil:
    section.add "X-Amz-Algorithm", valid_603948
  var valid_603949 = header.getOrDefault("X-Amz-Signature")
  valid_603949 = validateParameter(valid_603949, JString, required = false,
                                 default = nil)
  if valid_603949 != nil:
    section.add "X-Amz-Signature", valid_603949
  var valid_603950 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603950 = validateParameter(valid_603950, JString, required = false,
                                 default = nil)
  if valid_603950 != nil:
    section.add "X-Amz-SignedHeaders", valid_603950
  var valid_603951 = header.getOrDefault("X-Amz-Credential")
  valid_603951 = validateParameter(valid_603951, JString, required = false,
                                 default = nil)
  if valid_603951 != nil:
    section.add "X-Amz-Credential", valid_603951
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603953: Call_RetrieveTapeArchive_603941; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves an archived virtual tape from the virtual tape shelf (VTS) to a tape gateway. Virtual tapes archived in the VTS are not associated with any gateway. However after a tape is retrieved, it is associated with a gateway, even though it is also listed in the VTS, that is, archive. This operation is only supported in the tape gateway type.</p> <p>Once a tape is successfully retrieved to a gateway, it cannot be retrieved again to another gateway. You must archive the tape again before you can retrieve it to another gateway. This operation is only supported in the tape gateway type.</p>
  ## 
  let valid = call_603953.validator(path, query, header, formData, body)
  let scheme = call_603953.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603953.url(scheme.get, call_603953.host, call_603953.base,
                         call_603953.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603953, url, valid)

proc call*(call_603954: Call_RetrieveTapeArchive_603941; body: JsonNode): Recallable =
  ## retrieveTapeArchive
  ## <p>Retrieves an archived virtual tape from the virtual tape shelf (VTS) to a tape gateway. Virtual tapes archived in the VTS are not associated with any gateway. However after a tape is retrieved, it is associated with a gateway, even though it is also listed in the VTS, that is, archive. This operation is only supported in the tape gateway type.</p> <p>Once a tape is successfully retrieved to a gateway, it cannot be retrieved again to another gateway. You must archive the tape again before you can retrieve it to another gateway. This operation is only supported in the tape gateway type.</p>
  ##   body: JObject (required)
  var body_603955 = newJObject()
  if body != nil:
    body_603955 = body
  result = call_603954.call(nil, nil, nil, nil, body_603955)

var retrieveTapeArchive* = Call_RetrieveTapeArchive_603941(
    name: "retrieveTapeArchive", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.RetrieveTapeArchive",
    validator: validate_RetrieveTapeArchive_603942, base: "/",
    url: url_RetrieveTapeArchive_603943, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RetrieveTapeRecoveryPoint_603956 = ref object of OpenApiRestCall_602467
proc url_RetrieveTapeRecoveryPoint_603958(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RetrieveTapeRecoveryPoint_603957(path: JsonNode; query: JsonNode;
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
  var valid_603959 = header.getOrDefault("X-Amz-Date")
  valid_603959 = validateParameter(valid_603959, JString, required = false,
                                 default = nil)
  if valid_603959 != nil:
    section.add "X-Amz-Date", valid_603959
  var valid_603960 = header.getOrDefault("X-Amz-Security-Token")
  valid_603960 = validateParameter(valid_603960, JString, required = false,
                                 default = nil)
  if valid_603960 != nil:
    section.add "X-Amz-Security-Token", valid_603960
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603961 = header.getOrDefault("X-Amz-Target")
  valid_603961 = validateParameter(valid_603961, JString, required = true, default = newJString(
      "StorageGateway_20130630.RetrieveTapeRecoveryPoint"))
  if valid_603961 != nil:
    section.add "X-Amz-Target", valid_603961
  var valid_603962 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603962 = validateParameter(valid_603962, JString, required = false,
                                 default = nil)
  if valid_603962 != nil:
    section.add "X-Amz-Content-Sha256", valid_603962
  var valid_603963 = header.getOrDefault("X-Amz-Algorithm")
  valid_603963 = validateParameter(valid_603963, JString, required = false,
                                 default = nil)
  if valid_603963 != nil:
    section.add "X-Amz-Algorithm", valid_603963
  var valid_603964 = header.getOrDefault("X-Amz-Signature")
  valid_603964 = validateParameter(valid_603964, JString, required = false,
                                 default = nil)
  if valid_603964 != nil:
    section.add "X-Amz-Signature", valid_603964
  var valid_603965 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603965 = validateParameter(valid_603965, JString, required = false,
                                 default = nil)
  if valid_603965 != nil:
    section.add "X-Amz-SignedHeaders", valid_603965
  var valid_603966 = header.getOrDefault("X-Amz-Credential")
  valid_603966 = validateParameter(valid_603966, JString, required = false,
                                 default = nil)
  if valid_603966 != nil:
    section.add "X-Amz-Credential", valid_603966
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603968: Call_RetrieveTapeRecoveryPoint_603956; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the recovery point for the specified virtual tape. This operation is only supported in the tape gateway type.</p> <p>A recovery point is a point in time view of a virtual tape at which all the data on the tape is consistent. If your gateway crashes, virtual tapes that have recovery points can be recovered to a new gateway.</p> <note> <p>The virtual tape can be retrieved to only one gateway. The retrieved tape is read-only. The virtual tape can be retrieved to only a tape gateway. There is no charge for retrieving recovery points.</p> </note>
  ## 
  let valid = call_603968.validator(path, query, header, formData, body)
  let scheme = call_603968.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603968.url(scheme.get, call_603968.host, call_603968.base,
                         call_603968.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603968, url, valid)

proc call*(call_603969: Call_RetrieveTapeRecoveryPoint_603956; body: JsonNode): Recallable =
  ## retrieveTapeRecoveryPoint
  ## <p>Retrieves the recovery point for the specified virtual tape. This operation is only supported in the tape gateway type.</p> <p>A recovery point is a point in time view of a virtual tape at which all the data on the tape is consistent. If your gateway crashes, virtual tapes that have recovery points can be recovered to a new gateway.</p> <note> <p>The virtual tape can be retrieved to only one gateway. The retrieved tape is read-only. The virtual tape can be retrieved to only a tape gateway. There is no charge for retrieving recovery points.</p> </note>
  ##   body: JObject (required)
  var body_603970 = newJObject()
  if body != nil:
    body_603970 = body
  result = call_603969.call(nil, nil, nil, nil, body_603970)

var retrieveTapeRecoveryPoint* = Call_RetrieveTapeRecoveryPoint_603956(
    name: "retrieveTapeRecoveryPoint", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.RetrieveTapeRecoveryPoint",
    validator: validate_RetrieveTapeRecoveryPoint_603957, base: "/",
    url: url_RetrieveTapeRecoveryPoint_603958,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetLocalConsolePassword_603971 = ref object of OpenApiRestCall_602467
proc url_SetLocalConsolePassword_603973(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SetLocalConsolePassword_603972(path: JsonNode; query: JsonNode;
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
  var valid_603974 = header.getOrDefault("X-Amz-Date")
  valid_603974 = validateParameter(valid_603974, JString, required = false,
                                 default = nil)
  if valid_603974 != nil:
    section.add "X-Amz-Date", valid_603974
  var valid_603975 = header.getOrDefault("X-Amz-Security-Token")
  valid_603975 = validateParameter(valid_603975, JString, required = false,
                                 default = nil)
  if valid_603975 != nil:
    section.add "X-Amz-Security-Token", valid_603975
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603976 = header.getOrDefault("X-Amz-Target")
  valid_603976 = validateParameter(valid_603976, JString, required = true, default = newJString(
      "StorageGateway_20130630.SetLocalConsolePassword"))
  if valid_603976 != nil:
    section.add "X-Amz-Target", valid_603976
  var valid_603977 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603977 = validateParameter(valid_603977, JString, required = false,
                                 default = nil)
  if valid_603977 != nil:
    section.add "X-Amz-Content-Sha256", valid_603977
  var valid_603978 = header.getOrDefault("X-Amz-Algorithm")
  valid_603978 = validateParameter(valid_603978, JString, required = false,
                                 default = nil)
  if valid_603978 != nil:
    section.add "X-Amz-Algorithm", valid_603978
  var valid_603979 = header.getOrDefault("X-Amz-Signature")
  valid_603979 = validateParameter(valid_603979, JString, required = false,
                                 default = nil)
  if valid_603979 != nil:
    section.add "X-Amz-Signature", valid_603979
  var valid_603980 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603980 = validateParameter(valid_603980, JString, required = false,
                                 default = nil)
  if valid_603980 != nil:
    section.add "X-Amz-SignedHeaders", valid_603980
  var valid_603981 = header.getOrDefault("X-Amz-Credential")
  valid_603981 = validateParameter(valid_603981, JString, required = false,
                                 default = nil)
  if valid_603981 != nil:
    section.add "X-Amz-Credential", valid_603981
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603983: Call_SetLocalConsolePassword_603971; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the password for your VM local console. When you log in to the local console for the first time, you log in to the VM with the default credentials. We recommend that you set a new password. You don't need to know the default password to set a new password.
  ## 
  let valid = call_603983.validator(path, query, header, formData, body)
  let scheme = call_603983.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603983.url(scheme.get, call_603983.host, call_603983.base,
                         call_603983.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603983, url, valid)

proc call*(call_603984: Call_SetLocalConsolePassword_603971; body: JsonNode): Recallable =
  ## setLocalConsolePassword
  ## Sets the password for your VM local console. When you log in to the local console for the first time, you log in to the VM with the default credentials. We recommend that you set a new password. You don't need to know the default password to set a new password.
  ##   body: JObject (required)
  var body_603985 = newJObject()
  if body != nil:
    body_603985 = body
  result = call_603984.call(nil, nil, nil, nil, body_603985)

var setLocalConsolePassword* = Call_SetLocalConsolePassword_603971(
    name: "setLocalConsolePassword", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.SetLocalConsolePassword",
    validator: validate_SetLocalConsolePassword_603972, base: "/",
    url: url_SetLocalConsolePassword_603973, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetSMBGuestPassword_603986 = ref object of OpenApiRestCall_602467
proc url_SetSMBGuestPassword_603988(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SetSMBGuestPassword_603987(path: JsonNode; query: JsonNode;
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
  var valid_603989 = header.getOrDefault("X-Amz-Date")
  valid_603989 = validateParameter(valid_603989, JString, required = false,
                                 default = nil)
  if valid_603989 != nil:
    section.add "X-Amz-Date", valid_603989
  var valid_603990 = header.getOrDefault("X-Amz-Security-Token")
  valid_603990 = validateParameter(valid_603990, JString, required = false,
                                 default = nil)
  if valid_603990 != nil:
    section.add "X-Amz-Security-Token", valid_603990
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603991 = header.getOrDefault("X-Amz-Target")
  valid_603991 = validateParameter(valid_603991, JString, required = true, default = newJString(
      "StorageGateway_20130630.SetSMBGuestPassword"))
  if valid_603991 != nil:
    section.add "X-Amz-Target", valid_603991
  var valid_603992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603992 = validateParameter(valid_603992, JString, required = false,
                                 default = nil)
  if valid_603992 != nil:
    section.add "X-Amz-Content-Sha256", valid_603992
  var valid_603993 = header.getOrDefault("X-Amz-Algorithm")
  valid_603993 = validateParameter(valid_603993, JString, required = false,
                                 default = nil)
  if valid_603993 != nil:
    section.add "X-Amz-Algorithm", valid_603993
  var valid_603994 = header.getOrDefault("X-Amz-Signature")
  valid_603994 = validateParameter(valid_603994, JString, required = false,
                                 default = nil)
  if valid_603994 != nil:
    section.add "X-Amz-Signature", valid_603994
  var valid_603995 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603995 = validateParameter(valid_603995, JString, required = false,
                                 default = nil)
  if valid_603995 != nil:
    section.add "X-Amz-SignedHeaders", valid_603995
  var valid_603996 = header.getOrDefault("X-Amz-Credential")
  valid_603996 = validateParameter(valid_603996, JString, required = false,
                                 default = nil)
  if valid_603996 != nil:
    section.add "X-Amz-Credential", valid_603996
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603998: Call_SetSMBGuestPassword_603986; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the password for the guest user <code>smbguest</code>. The <code>smbguest</code> user is the user when the authentication method for the file share is set to <code>GuestAccess</code>.
  ## 
  let valid = call_603998.validator(path, query, header, formData, body)
  let scheme = call_603998.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603998.url(scheme.get, call_603998.host, call_603998.base,
                         call_603998.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603998, url, valid)

proc call*(call_603999: Call_SetSMBGuestPassword_603986; body: JsonNode): Recallable =
  ## setSMBGuestPassword
  ## Sets the password for the guest user <code>smbguest</code>. The <code>smbguest</code> user is the user when the authentication method for the file share is set to <code>GuestAccess</code>.
  ##   body: JObject (required)
  var body_604000 = newJObject()
  if body != nil:
    body_604000 = body
  result = call_603999.call(nil, nil, nil, nil, body_604000)

var setSMBGuestPassword* = Call_SetSMBGuestPassword_603986(
    name: "setSMBGuestPassword", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.SetSMBGuestPassword",
    validator: validate_SetSMBGuestPassword_603987, base: "/",
    url: url_SetSMBGuestPassword_603988, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ShutdownGateway_604001 = ref object of OpenApiRestCall_602467
proc url_ShutdownGateway_604003(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ShutdownGateway_604002(path: JsonNode; query: JsonNode;
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
  var valid_604004 = header.getOrDefault("X-Amz-Date")
  valid_604004 = validateParameter(valid_604004, JString, required = false,
                                 default = nil)
  if valid_604004 != nil:
    section.add "X-Amz-Date", valid_604004
  var valid_604005 = header.getOrDefault("X-Amz-Security-Token")
  valid_604005 = validateParameter(valid_604005, JString, required = false,
                                 default = nil)
  if valid_604005 != nil:
    section.add "X-Amz-Security-Token", valid_604005
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604006 = header.getOrDefault("X-Amz-Target")
  valid_604006 = validateParameter(valid_604006, JString, required = true, default = newJString(
      "StorageGateway_20130630.ShutdownGateway"))
  if valid_604006 != nil:
    section.add "X-Amz-Target", valid_604006
  var valid_604007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604007 = validateParameter(valid_604007, JString, required = false,
                                 default = nil)
  if valid_604007 != nil:
    section.add "X-Amz-Content-Sha256", valid_604007
  var valid_604008 = header.getOrDefault("X-Amz-Algorithm")
  valid_604008 = validateParameter(valid_604008, JString, required = false,
                                 default = nil)
  if valid_604008 != nil:
    section.add "X-Amz-Algorithm", valid_604008
  var valid_604009 = header.getOrDefault("X-Amz-Signature")
  valid_604009 = validateParameter(valid_604009, JString, required = false,
                                 default = nil)
  if valid_604009 != nil:
    section.add "X-Amz-Signature", valid_604009
  var valid_604010 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604010 = validateParameter(valid_604010, JString, required = false,
                                 default = nil)
  if valid_604010 != nil:
    section.add "X-Amz-SignedHeaders", valid_604010
  var valid_604011 = header.getOrDefault("X-Amz-Credential")
  valid_604011 = validateParameter(valid_604011, JString, required = false,
                                 default = nil)
  if valid_604011 != nil:
    section.add "X-Amz-Credential", valid_604011
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604013: Call_ShutdownGateway_604001; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Shuts down a gateway. To specify which gateway to shut down, use the Amazon Resource Name (ARN) of the gateway in the body of your request.</p> <p>The operation shuts down the gateway service component running in the gateway's virtual machine (VM) and not the host VM.</p> <note> <p>If you want to shut down the VM, it is recommended that you first shut down the gateway component in the VM to avoid unpredictable conditions.</p> </note> <p>After the gateway is shutdown, you cannot call any other API except <a>StartGateway</a>, <a>DescribeGatewayInformation</a>, and <a>ListGateways</a>. For more information, see <a>ActivateGateway</a>. Your applications cannot read from or write to the gateway's storage volumes, and there are no snapshots taken.</p> <note> <p>When you make a shutdown request, you will get a <code>200 OK</code> success response immediately. However, it might take some time for the gateway to shut down. You can call the <a>DescribeGatewayInformation</a> API to check the status. For more information, see <a>ActivateGateway</a>.</p> </note> <p>If do not intend to use the gateway again, you must delete the gateway (using <a>DeleteGateway</a>) to no longer pay software charges associated with the gateway.</p>
  ## 
  let valid = call_604013.validator(path, query, header, formData, body)
  let scheme = call_604013.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604013.url(scheme.get, call_604013.host, call_604013.base,
                         call_604013.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604013, url, valid)

proc call*(call_604014: Call_ShutdownGateway_604001; body: JsonNode): Recallable =
  ## shutdownGateway
  ## <p>Shuts down a gateway. To specify which gateway to shut down, use the Amazon Resource Name (ARN) of the gateway in the body of your request.</p> <p>The operation shuts down the gateway service component running in the gateway's virtual machine (VM) and not the host VM.</p> <note> <p>If you want to shut down the VM, it is recommended that you first shut down the gateway component in the VM to avoid unpredictable conditions.</p> </note> <p>After the gateway is shutdown, you cannot call any other API except <a>StartGateway</a>, <a>DescribeGatewayInformation</a>, and <a>ListGateways</a>. For more information, see <a>ActivateGateway</a>. Your applications cannot read from or write to the gateway's storage volumes, and there are no snapshots taken.</p> <note> <p>When you make a shutdown request, you will get a <code>200 OK</code> success response immediately. However, it might take some time for the gateway to shut down. You can call the <a>DescribeGatewayInformation</a> API to check the status. For more information, see <a>ActivateGateway</a>.</p> </note> <p>If do not intend to use the gateway again, you must delete the gateway (using <a>DeleteGateway</a>) to no longer pay software charges associated with the gateway.</p>
  ##   body: JObject (required)
  var body_604015 = newJObject()
  if body != nil:
    body_604015 = body
  result = call_604014.call(nil, nil, nil, nil, body_604015)

var shutdownGateway* = Call_ShutdownGateway_604001(name: "shutdownGateway",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.ShutdownGateway",
    validator: validate_ShutdownGateway_604002, base: "/", url: url_ShutdownGateway_604003,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartGateway_604016 = ref object of OpenApiRestCall_602467
proc url_StartGateway_604018(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartGateway_604017(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604019 = header.getOrDefault("X-Amz-Date")
  valid_604019 = validateParameter(valid_604019, JString, required = false,
                                 default = nil)
  if valid_604019 != nil:
    section.add "X-Amz-Date", valid_604019
  var valid_604020 = header.getOrDefault("X-Amz-Security-Token")
  valid_604020 = validateParameter(valid_604020, JString, required = false,
                                 default = nil)
  if valid_604020 != nil:
    section.add "X-Amz-Security-Token", valid_604020
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604021 = header.getOrDefault("X-Amz-Target")
  valid_604021 = validateParameter(valid_604021, JString, required = true, default = newJString(
      "StorageGateway_20130630.StartGateway"))
  if valid_604021 != nil:
    section.add "X-Amz-Target", valid_604021
  var valid_604022 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604022 = validateParameter(valid_604022, JString, required = false,
                                 default = nil)
  if valid_604022 != nil:
    section.add "X-Amz-Content-Sha256", valid_604022
  var valid_604023 = header.getOrDefault("X-Amz-Algorithm")
  valid_604023 = validateParameter(valid_604023, JString, required = false,
                                 default = nil)
  if valid_604023 != nil:
    section.add "X-Amz-Algorithm", valid_604023
  var valid_604024 = header.getOrDefault("X-Amz-Signature")
  valid_604024 = validateParameter(valid_604024, JString, required = false,
                                 default = nil)
  if valid_604024 != nil:
    section.add "X-Amz-Signature", valid_604024
  var valid_604025 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604025 = validateParameter(valid_604025, JString, required = false,
                                 default = nil)
  if valid_604025 != nil:
    section.add "X-Amz-SignedHeaders", valid_604025
  var valid_604026 = header.getOrDefault("X-Amz-Credential")
  valid_604026 = validateParameter(valid_604026, JString, required = false,
                                 default = nil)
  if valid_604026 != nil:
    section.add "X-Amz-Credential", valid_604026
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604028: Call_StartGateway_604016; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a gateway that you previously shut down (see <a>ShutdownGateway</a>). After the gateway starts, you can then make other API calls, your applications can read from or write to the gateway's storage volumes and you will be able to take snapshot backups.</p> <note> <p>When you make a request, you will get a 200 OK success response immediately. However, it might take some time for the gateway to be ready. You should call <a>DescribeGatewayInformation</a> and check the status before making any additional API calls. For more information, see <a>ActivateGateway</a>.</p> </note> <p>To specify which gateway to start, use the Amazon Resource Name (ARN) of the gateway in your request.</p>
  ## 
  let valid = call_604028.validator(path, query, header, formData, body)
  let scheme = call_604028.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604028.url(scheme.get, call_604028.host, call_604028.base,
                         call_604028.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604028, url, valid)

proc call*(call_604029: Call_StartGateway_604016; body: JsonNode): Recallable =
  ## startGateway
  ## <p>Starts a gateway that you previously shut down (see <a>ShutdownGateway</a>). After the gateway starts, you can then make other API calls, your applications can read from or write to the gateway's storage volumes and you will be able to take snapshot backups.</p> <note> <p>When you make a request, you will get a 200 OK success response immediately. However, it might take some time for the gateway to be ready. You should call <a>DescribeGatewayInformation</a> and check the status before making any additional API calls. For more information, see <a>ActivateGateway</a>.</p> </note> <p>To specify which gateway to start, use the Amazon Resource Name (ARN) of the gateway in your request.</p>
  ##   body: JObject (required)
  var body_604030 = newJObject()
  if body != nil:
    body_604030 = body
  result = call_604029.call(nil, nil, nil, nil, body_604030)

var startGateway* = Call_StartGateway_604016(name: "startGateway",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.StartGateway",
    validator: validate_StartGateway_604017, base: "/", url: url_StartGateway_604018,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBandwidthRateLimit_604031 = ref object of OpenApiRestCall_602467
proc url_UpdateBandwidthRateLimit_604033(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateBandwidthRateLimit_604032(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates the bandwidth rate limits of a gateway. You can update both the upload and download bandwidth rate limit or specify only one of the two. If you don't set a bandwidth rate limit, the existing rate limit remains.</p> <p>By default, a gateway's bandwidth rate limits are not set. If you don't set any limit, the gateway does not have any limitations on its bandwidth usage and could potentially use the maximum available bandwidth.</p> <p>To specify which gateway to update, use the Amazon Resource Name (ARN) of the gateway in your request.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604034 = header.getOrDefault("X-Amz-Date")
  valid_604034 = validateParameter(valid_604034, JString, required = false,
                                 default = nil)
  if valid_604034 != nil:
    section.add "X-Amz-Date", valid_604034
  var valid_604035 = header.getOrDefault("X-Amz-Security-Token")
  valid_604035 = validateParameter(valid_604035, JString, required = false,
                                 default = nil)
  if valid_604035 != nil:
    section.add "X-Amz-Security-Token", valid_604035
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604036 = header.getOrDefault("X-Amz-Target")
  valid_604036 = validateParameter(valid_604036, JString, required = true, default = newJString(
      "StorageGateway_20130630.UpdateBandwidthRateLimit"))
  if valid_604036 != nil:
    section.add "X-Amz-Target", valid_604036
  var valid_604037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604037 = validateParameter(valid_604037, JString, required = false,
                                 default = nil)
  if valid_604037 != nil:
    section.add "X-Amz-Content-Sha256", valid_604037
  var valid_604038 = header.getOrDefault("X-Amz-Algorithm")
  valid_604038 = validateParameter(valid_604038, JString, required = false,
                                 default = nil)
  if valid_604038 != nil:
    section.add "X-Amz-Algorithm", valid_604038
  var valid_604039 = header.getOrDefault("X-Amz-Signature")
  valid_604039 = validateParameter(valid_604039, JString, required = false,
                                 default = nil)
  if valid_604039 != nil:
    section.add "X-Amz-Signature", valid_604039
  var valid_604040 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604040 = validateParameter(valid_604040, JString, required = false,
                                 default = nil)
  if valid_604040 != nil:
    section.add "X-Amz-SignedHeaders", valid_604040
  var valid_604041 = header.getOrDefault("X-Amz-Credential")
  valid_604041 = validateParameter(valid_604041, JString, required = false,
                                 default = nil)
  if valid_604041 != nil:
    section.add "X-Amz-Credential", valid_604041
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604043: Call_UpdateBandwidthRateLimit_604031; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the bandwidth rate limits of a gateway. You can update both the upload and download bandwidth rate limit or specify only one of the two. If you don't set a bandwidth rate limit, the existing rate limit remains.</p> <p>By default, a gateway's bandwidth rate limits are not set. If you don't set any limit, the gateway does not have any limitations on its bandwidth usage and could potentially use the maximum available bandwidth.</p> <p>To specify which gateway to update, use the Amazon Resource Name (ARN) of the gateway in your request.</p>
  ## 
  let valid = call_604043.validator(path, query, header, formData, body)
  let scheme = call_604043.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604043.url(scheme.get, call_604043.host, call_604043.base,
                         call_604043.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604043, url, valid)

proc call*(call_604044: Call_UpdateBandwidthRateLimit_604031; body: JsonNode): Recallable =
  ## updateBandwidthRateLimit
  ## <p>Updates the bandwidth rate limits of a gateway. You can update both the upload and download bandwidth rate limit or specify only one of the two. If you don't set a bandwidth rate limit, the existing rate limit remains.</p> <p>By default, a gateway's bandwidth rate limits are not set. If you don't set any limit, the gateway does not have any limitations on its bandwidth usage and could potentially use the maximum available bandwidth.</p> <p>To specify which gateway to update, use the Amazon Resource Name (ARN) of the gateway in your request.</p>
  ##   body: JObject (required)
  var body_604045 = newJObject()
  if body != nil:
    body_604045 = body
  result = call_604044.call(nil, nil, nil, nil, body_604045)

var updateBandwidthRateLimit* = Call_UpdateBandwidthRateLimit_604031(
    name: "updateBandwidthRateLimit", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.UpdateBandwidthRateLimit",
    validator: validate_UpdateBandwidthRateLimit_604032, base: "/",
    url: url_UpdateBandwidthRateLimit_604033, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateChapCredentials_604046 = ref object of OpenApiRestCall_602467
proc url_UpdateChapCredentials_604048(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateChapCredentials_604047(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates the Challenge-Handshake Authentication Protocol (CHAP) credentials for a specified iSCSI target. By default, a gateway does not have CHAP enabled; however, for added security, you might use it.</p> <important> <p>When you update CHAP credentials, all existing connections on the target are closed and initiators must reconnect with the new credentials.</p> </important>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604049 = header.getOrDefault("X-Amz-Date")
  valid_604049 = validateParameter(valid_604049, JString, required = false,
                                 default = nil)
  if valid_604049 != nil:
    section.add "X-Amz-Date", valid_604049
  var valid_604050 = header.getOrDefault("X-Amz-Security-Token")
  valid_604050 = validateParameter(valid_604050, JString, required = false,
                                 default = nil)
  if valid_604050 != nil:
    section.add "X-Amz-Security-Token", valid_604050
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604051 = header.getOrDefault("X-Amz-Target")
  valid_604051 = validateParameter(valid_604051, JString, required = true, default = newJString(
      "StorageGateway_20130630.UpdateChapCredentials"))
  if valid_604051 != nil:
    section.add "X-Amz-Target", valid_604051
  var valid_604052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604052 = validateParameter(valid_604052, JString, required = false,
                                 default = nil)
  if valid_604052 != nil:
    section.add "X-Amz-Content-Sha256", valid_604052
  var valid_604053 = header.getOrDefault("X-Amz-Algorithm")
  valid_604053 = validateParameter(valid_604053, JString, required = false,
                                 default = nil)
  if valid_604053 != nil:
    section.add "X-Amz-Algorithm", valid_604053
  var valid_604054 = header.getOrDefault("X-Amz-Signature")
  valid_604054 = validateParameter(valid_604054, JString, required = false,
                                 default = nil)
  if valid_604054 != nil:
    section.add "X-Amz-Signature", valid_604054
  var valid_604055 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604055 = validateParameter(valid_604055, JString, required = false,
                                 default = nil)
  if valid_604055 != nil:
    section.add "X-Amz-SignedHeaders", valid_604055
  var valid_604056 = header.getOrDefault("X-Amz-Credential")
  valid_604056 = validateParameter(valid_604056, JString, required = false,
                                 default = nil)
  if valid_604056 != nil:
    section.add "X-Amz-Credential", valid_604056
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604058: Call_UpdateChapCredentials_604046; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the Challenge-Handshake Authentication Protocol (CHAP) credentials for a specified iSCSI target. By default, a gateway does not have CHAP enabled; however, for added security, you might use it.</p> <important> <p>When you update CHAP credentials, all existing connections on the target are closed and initiators must reconnect with the new credentials.</p> </important>
  ## 
  let valid = call_604058.validator(path, query, header, formData, body)
  let scheme = call_604058.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604058.url(scheme.get, call_604058.host, call_604058.base,
                         call_604058.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604058, url, valid)

proc call*(call_604059: Call_UpdateChapCredentials_604046; body: JsonNode): Recallable =
  ## updateChapCredentials
  ## <p>Updates the Challenge-Handshake Authentication Protocol (CHAP) credentials for a specified iSCSI target. By default, a gateway does not have CHAP enabled; however, for added security, you might use it.</p> <important> <p>When you update CHAP credentials, all existing connections on the target are closed and initiators must reconnect with the new credentials.</p> </important>
  ##   body: JObject (required)
  var body_604060 = newJObject()
  if body != nil:
    body_604060 = body
  result = call_604059.call(nil, nil, nil, nil, body_604060)

var updateChapCredentials* = Call_UpdateChapCredentials_604046(
    name: "updateChapCredentials", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.UpdateChapCredentials",
    validator: validate_UpdateChapCredentials_604047, base: "/",
    url: url_UpdateChapCredentials_604048, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGatewayInformation_604061 = ref object of OpenApiRestCall_602467
proc url_UpdateGatewayInformation_604063(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateGatewayInformation_604062(path: JsonNode; query: JsonNode;
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
  var valid_604064 = header.getOrDefault("X-Amz-Date")
  valid_604064 = validateParameter(valid_604064, JString, required = false,
                                 default = nil)
  if valid_604064 != nil:
    section.add "X-Amz-Date", valid_604064
  var valid_604065 = header.getOrDefault("X-Amz-Security-Token")
  valid_604065 = validateParameter(valid_604065, JString, required = false,
                                 default = nil)
  if valid_604065 != nil:
    section.add "X-Amz-Security-Token", valid_604065
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604066 = header.getOrDefault("X-Amz-Target")
  valid_604066 = validateParameter(valid_604066, JString, required = true, default = newJString(
      "StorageGateway_20130630.UpdateGatewayInformation"))
  if valid_604066 != nil:
    section.add "X-Amz-Target", valid_604066
  var valid_604067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604067 = validateParameter(valid_604067, JString, required = false,
                                 default = nil)
  if valid_604067 != nil:
    section.add "X-Amz-Content-Sha256", valid_604067
  var valid_604068 = header.getOrDefault("X-Amz-Algorithm")
  valid_604068 = validateParameter(valid_604068, JString, required = false,
                                 default = nil)
  if valid_604068 != nil:
    section.add "X-Amz-Algorithm", valid_604068
  var valid_604069 = header.getOrDefault("X-Amz-Signature")
  valid_604069 = validateParameter(valid_604069, JString, required = false,
                                 default = nil)
  if valid_604069 != nil:
    section.add "X-Amz-Signature", valid_604069
  var valid_604070 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604070 = validateParameter(valid_604070, JString, required = false,
                                 default = nil)
  if valid_604070 != nil:
    section.add "X-Amz-SignedHeaders", valid_604070
  var valid_604071 = header.getOrDefault("X-Amz-Credential")
  valid_604071 = validateParameter(valid_604071, JString, required = false,
                                 default = nil)
  if valid_604071 != nil:
    section.add "X-Amz-Credential", valid_604071
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604073: Call_UpdateGatewayInformation_604061; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates a gateway's metadata, which includes the gateway's name and time zone. To specify which gateway to update, use the Amazon Resource Name (ARN) of the gateway in your request.</p> <note> <p>For Gateways activated after September 2, 2015, the gateway's ARN contains the gateway ID rather than the gateway name. However, changing the name of the gateway has no effect on the gateway's ARN.</p> </note>
  ## 
  let valid = call_604073.validator(path, query, header, formData, body)
  let scheme = call_604073.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604073.url(scheme.get, call_604073.host, call_604073.base,
                         call_604073.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604073, url, valid)

proc call*(call_604074: Call_UpdateGatewayInformation_604061; body: JsonNode): Recallable =
  ## updateGatewayInformation
  ## <p>Updates a gateway's metadata, which includes the gateway's name and time zone. To specify which gateway to update, use the Amazon Resource Name (ARN) of the gateway in your request.</p> <note> <p>For Gateways activated after September 2, 2015, the gateway's ARN contains the gateway ID rather than the gateway name. However, changing the name of the gateway has no effect on the gateway's ARN.</p> </note>
  ##   body: JObject (required)
  var body_604075 = newJObject()
  if body != nil:
    body_604075 = body
  result = call_604074.call(nil, nil, nil, nil, body_604075)

var updateGatewayInformation* = Call_UpdateGatewayInformation_604061(
    name: "updateGatewayInformation", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.UpdateGatewayInformation",
    validator: validate_UpdateGatewayInformation_604062, base: "/",
    url: url_UpdateGatewayInformation_604063, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGatewaySoftwareNow_604076 = ref object of OpenApiRestCall_602467
proc url_UpdateGatewaySoftwareNow_604078(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateGatewaySoftwareNow_604077(path: JsonNode; query: JsonNode;
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
  var valid_604079 = header.getOrDefault("X-Amz-Date")
  valid_604079 = validateParameter(valid_604079, JString, required = false,
                                 default = nil)
  if valid_604079 != nil:
    section.add "X-Amz-Date", valid_604079
  var valid_604080 = header.getOrDefault("X-Amz-Security-Token")
  valid_604080 = validateParameter(valid_604080, JString, required = false,
                                 default = nil)
  if valid_604080 != nil:
    section.add "X-Amz-Security-Token", valid_604080
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604081 = header.getOrDefault("X-Amz-Target")
  valid_604081 = validateParameter(valid_604081, JString, required = true, default = newJString(
      "StorageGateway_20130630.UpdateGatewaySoftwareNow"))
  if valid_604081 != nil:
    section.add "X-Amz-Target", valid_604081
  var valid_604082 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604082 = validateParameter(valid_604082, JString, required = false,
                                 default = nil)
  if valid_604082 != nil:
    section.add "X-Amz-Content-Sha256", valid_604082
  var valid_604083 = header.getOrDefault("X-Amz-Algorithm")
  valid_604083 = validateParameter(valid_604083, JString, required = false,
                                 default = nil)
  if valid_604083 != nil:
    section.add "X-Amz-Algorithm", valid_604083
  var valid_604084 = header.getOrDefault("X-Amz-Signature")
  valid_604084 = validateParameter(valid_604084, JString, required = false,
                                 default = nil)
  if valid_604084 != nil:
    section.add "X-Amz-Signature", valid_604084
  var valid_604085 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604085 = validateParameter(valid_604085, JString, required = false,
                                 default = nil)
  if valid_604085 != nil:
    section.add "X-Amz-SignedHeaders", valid_604085
  var valid_604086 = header.getOrDefault("X-Amz-Credential")
  valid_604086 = validateParameter(valid_604086, JString, required = false,
                                 default = nil)
  if valid_604086 != nil:
    section.add "X-Amz-Credential", valid_604086
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604088: Call_UpdateGatewaySoftwareNow_604076; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the gateway virtual machine (VM) software. The request immediately triggers the software update.</p> <note> <p>When you make this request, you get a <code>200 OK</code> success response immediately. However, it might take some time for the update to complete. You can call <a>DescribeGatewayInformation</a> to verify the gateway is in the <code>STATE_RUNNING</code> state.</p> </note> <important> <p>A software update forces a system restart of your gateway. You can minimize the chance of any disruption to your applications by increasing your iSCSI Initiators' timeouts. For more information about increasing iSCSI Initiator timeouts for Windows and Linux, see <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/ConfiguringiSCSIClientInitiatorWindowsClient.html#CustomizeWindowsiSCSISettings">Customizing Your Windows iSCSI Settings</a> and <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/ConfiguringiSCSIClientInitiatorRedHatClient.html#CustomizeLinuxiSCSISettings">Customizing Your Linux iSCSI Settings</a>, respectively.</p> </important>
  ## 
  let valid = call_604088.validator(path, query, header, formData, body)
  let scheme = call_604088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604088.url(scheme.get, call_604088.host, call_604088.base,
                         call_604088.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604088, url, valid)

proc call*(call_604089: Call_UpdateGatewaySoftwareNow_604076; body: JsonNode): Recallable =
  ## updateGatewaySoftwareNow
  ## <p>Updates the gateway virtual machine (VM) software. The request immediately triggers the software update.</p> <note> <p>When you make this request, you get a <code>200 OK</code> success response immediately. However, it might take some time for the update to complete. You can call <a>DescribeGatewayInformation</a> to verify the gateway is in the <code>STATE_RUNNING</code> state.</p> </note> <important> <p>A software update forces a system restart of your gateway. You can minimize the chance of any disruption to your applications by increasing your iSCSI Initiators' timeouts. For more information about increasing iSCSI Initiator timeouts for Windows and Linux, see <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/ConfiguringiSCSIClientInitiatorWindowsClient.html#CustomizeWindowsiSCSISettings">Customizing Your Windows iSCSI Settings</a> and <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/ConfiguringiSCSIClientInitiatorRedHatClient.html#CustomizeLinuxiSCSISettings">Customizing Your Linux iSCSI Settings</a>, respectively.</p> </important>
  ##   body: JObject (required)
  var body_604090 = newJObject()
  if body != nil:
    body_604090 = body
  result = call_604089.call(nil, nil, nil, nil, body_604090)

var updateGatewaySoftwareNow* = Call_UpdateGatewaySoftwareNow_604076(
    name: "updateGatewaySoftwareNow", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.UpdateGatewaySoftwareNow",
    validator: validate_UpdateGatewaySoftwareNow_604077, base: "/",
    url: url_UpdateGatewaySoftwareNow_604078, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMaintenanceStartTime_604091 = ref object of OpenApiRestCall_602467
proc url_UpdateMaintenanceStartTime_604093(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateMaintenanceStartTime_604092(path: JsonNode; query: JsonNode;
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
  var valid_604094 = header.getOrDefault("X-Amz-Date")
  valid_604094 = validateParameter(valid_604094, JString, required = false,
                                 default = nil)
  if valid_604094 != nil:
    section.add "X-Amz-Date", valid_604094
  var valid_604095 = header.getOrDefault("X-Amz-Security-Token")
  valid_604095 = validateParameter(valid_604095, JString, required = false,
                                 default = nil)
  if valid_604095 != nil:
    section.add "X-Amz-Security-Token", valid_604095
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604096 = header.getOrDefault("X-Amz-Target")
  valid_604096 = validateParameter(valid_604096, JString, required = true, default = newJString(
      "StorageGateway_20130630.UpdateMaintenanceStartTime"))
  if valid_604096 != nil:
    section.add "X-Amz-Target", valid_604096
  var valid_604097 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604097 = validateParameter(valid_604097, JString, required = false,
                                 default = nil)
  if valid_604097 != nil:
    section.add "X-Amz-Content-Sha256", valid_604097
  var valid_604098 = header.getOrDefault("X-Amz-Algorithm")
  valid_604098 = validateParameter(valid_604098, JString, required = false,
                                 default = nil)
  if valid_604098 != nil:
    section.add "X-Amz-Algorithm", valid_604098
  var valid_604099 = header.getOrDefault("X-Amz-Signature")
  valid_604099 = validateParameter(valid_604099, JString, required = false,
                                 default = nil)
  if valid_604099 != nil:
    section.add "X-Amz-Signature", valid_604099
  var valid_604100 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604100 = validateParameter(valid_604100, JString, required = false,
                                 default = nil)
  if valid_604100 != nil:
    section.add "X-Amz-SignedHeaders", valid_604100
  var valid_604101 = header.getOrDefault("X-Amz-Credential")
  valid_604101 = validateParameter(valid_604101, JString, required = false,
                                 default = nil)
  if valid_604101 != nil:
    section.add "X-Amz-Credential", valid_604101
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604103: Call_UpdateMaintenanceStartTime_604091; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a gateway's weekly maintenance start time information, including day and time of the week. The maintenance time is the time in your gateway's time zone.
  ## 
  let valid = call_604103.validator(path, query, header, formData, body)
  let scheme = call_604103.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604103.url(scheme.get, call_604103.host, call_604103.base,
                         call_604103.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604103, url, valid)

proc call*(call_604104: Call_UpdateMaintenanceStartTime_604091; body: JsonNode): Recallable =
  ## updateMaintenanceStartTime
  ## Updates a gateway's weekly maintenance start time information, including day and time of the week. The maintenance time is the time in your gateway's time zone.
  ##   body: JObject (required)
  var body_604105 = newJObject()
  if body != nil:
    body_604105 = body
  result = call_604104.call(nil, nil, nil, nil, body_604105)

var updateMaintenanceStartTime* = Call_UpdateMaintenanceStartTime_604091(
    name: "updateMaintenanceStartTime", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.UpdateMaintenanceStartTime",
    validator: validate_UpdateMaintenanceStartTime_604092, base: "/",
    url: url_UpdateMaintenanceStartTime_604093,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNFSFileShare_604106 = ref object of OpenApiRestCall_602467
proc url_UpdateNFSFileShare_604108(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateNFSFileShare_604107(path: JsonNode; query: JsonNode;
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
  var valid_604109 = header.getOrDefault("X-Amz-Date")
  valid_604109 = validateParameter(valid_604109, JString, required = false,
                                 default = nil)
  if valid_604109 != nil:
    section.add "X-Amz-Date", valid_604109
  var valid_604110 = header.getOrDefault("X-Amz-Security-Token")
  valid_604110 = validateParameter(valid_604110, JString, required = false,
                                 default = nil)
  if valid_604110 != nil:
    section.add "X-Amz-Security-Token", valid_604110
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604111 = header.getOrDefault("X-Amz-Target")
  valid_604111 = validateParameter(valid_604111, JString, required = true, default = newJString(
      "StorageGateway_20130630.UpdateNFSFileShare"))
  if valid_604111 != nil:
    section.add "X-Amz-Target", valid_604111
  var valid_604112 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604112 = validateParameter(valid_604112, JString, required = false,
                                 default = nil)
  if valid_604112 != nil:
    section.add "X-Amz-Content-Sha256", valid_604112
  var valid_604113 = header.getOrDefault("X-Amz-Algorithm")
  valid_604113 = validateParameter(valid_604113, JString, required = false,
                                 default = nil)
  if valid_604113 != nil:
    section.add "X-Amz-Algorithm", valid_604113
  var valid_604114 = header.getOrDefault("X-Amz-Signature")
  valid_604114 = validateParameter(valid_604114, JString, required = false,
                                 default = nil)
  if valid_604114 != nil:
    section.add "X-Amz-Signature", valid_604114
  var valid_604115 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604115 = validateParameter(valid_604115, JString, required = false,
                                 default = nil)
  if valid_604115 != nil:
    section.add "X-Amz-SignedHeaders", valid_604115
  var valid_604116 = header.getOrDefault("X-Amz-Credential")
  valid_604116 = validateParameter(valid_604116, JString, required = false,
                                 default = nil)
  if valid_604116 != nil:
    section.add "X-Amz-Credential", valid_604116
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604118: Call_UpdateNFSFileShare_604106; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates a Network File System (NFS) file share. This operation is only supported in the file gateway type.</p> <note> <p>To leave a file share field unchanged, set the corresponding input field to null.</p> </note> <p>Updates the following file share setting:</p> <ul> <li> <p>Default storage class for your S3 bucket</p> </li> <li> <p>Metadata defaults for your S3 bucket</p> </li> <li> <p>Allowed NFS clients for your file share</p> </li> <li> <p>Squash settings</p> </li> <li> <p>Write status of your file share</p> </li> </ul> <note> <p>To leave a file share field unchanged, set the corresponding input field to null. This operation is only supported in file gateways.</p> </note>
  ## 
  let valid = call_604118.validator(path, query, header, formData, body)
  let scheme = call_604118.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604118.url(scheme.get, call_604118.host, call_604118.base,
                         call_604118.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604118, url, valid)

proc call*(call_604119: Call_UpdateNFSFileShare_604106; body: JsonNode): Recallable =
  ## updateNFSFileShare
  ## <p>Updates a Network File System (NFS) file share. This operation is only supported in the file gateway type.</p> <note> <p>To leave a file share field unchanged, set the corresponding input field to null.</p> </note> <p>Updates the following file share setting:</p> <ul> <li> <p>Default storage class for your S3 bucket</p> </li> <li> <p>Metadata defaults for your S3 bucket</p> </li> <li> <p>Allowed NFS clients for your file share</p> </li> <li> <p>Squash settings</p> </li> <li> <p>Write status of your file share</p> </li> </ul> <note> <p>To leave a file share field unchanged, set the corresponding input field to null. This operation is only supported in file gateways.</p> </note>
  ##   body: JObject (required)
  var body_604120 = newJObject()
  if body != nil:
    body_604120 = body
  result = call_604119.call(nil, nil, nil, nil, body_604120)

var updateNFSFileShare* = Call_UpdateNFSFileShare_604106(
    name: "updateNFSFileShare", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.UpdateNFSFileShare",
    validator: validate_UpdateNFSFileShare_604107, base: "/",
    url: url_UpdateNFSFileShare_604108, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSMBFileShare_604121 = ref object of OpenApiRestCall_602467
proc url_UpdateSMBFileShare_604123(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateSMBFileShare_604122(path: JsonNode; query: JsonNode;
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
  var valid_604124 = header.getOrDefault("X-Amz-Date")
  valid_604124 = validateParameter(valid_604124, JString, required = false,
                                 default = nil)
  if valid_604124 != nil:
    section.add "X-Amz-Date", valid_604124
  var valid_604125 = header.getOrDefault("X-Amz-Security-Token")
  valid_604125 = validateParameter(valid_604125, JString, required = false,
                                 default = nil)
  if valid_604125 != nil:
    section.add "X-Amz-Security-Token", valid_604125
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604126 = header.getOrDefault("X-Amz-Target")
  valid_604126 = validateParameter(valid_604126, JString, required = true, default = newJString(
      "StorageGateway_20130630.UpdateSMBFileShare"))
  if valid_604126 != nil:
    section.add "X-Amz-Target", valid_604126
  var valid_604127 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604127 = validateParameter(valid_604127, JString, required = false,
                                 default = nil)
  if valid_604127 != nil:
    section.add "X-Amz-Content-Sha256", valid_604127
  var valid_604128 = header.getOrDefault("X-Amz-Algorithm")
  valid_604128 = validateParameter(valid_604128, JString, required = false,
                                 default = nil)
  if valid_604128 != nil:
    section.add "X-Amz-Algorithm", valid_604128
  var valid_604129 = header.getOrDefault("X-Amz-Signature")
  valid_604129 = validateParameter(valid_604129, JString, required = false,
                                 default = nil)
  if valid_604129 != nil:
    section.add "X-Amz-Signature", valid_604129
  var valid_604130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604130 = validateParameter(valid_604130, JString, required = false,
                                 default = nil)
  if valid_604130 != nil:
    section.add "X-Amz-SignedHeaders", valid_604130
  var valid_604131 = header.getOrDefault("X-Amz-Credential")
  valid_604131 = validateParameter(valid_604131, JString, required = false,
                                 default = nil)
  if valid_604131 != nil:
    section.add "X-Amz-Credential", valid_604131
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604133: Call_UpdateSMBFileShare_604121; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates a Server Message Block (SMB) file share.</p> <note> <p>To leave a file share field unchanged, set the corresponding input field to null. This operation is only supported for file gateways.</p> </note> <important> <p>File gateways require AWS Security Token Service (AWS STS) to be activated to enable you to create a file share. Make sure that AWS STS is activated in the AWS Region you are creating your file gateway in. If AWS STS is not activated in this AWS Region, activate it. For information about how to activate AWS STS, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_enable-regions.html">Activating and Deactivating AWS STS in an AWS Region</a> in the <i>AWS Identity and Access Management User Guide.</i> </p> <p>File gateways don't support creating hard or symbolic links on a file share.</p> </important>
  ## 
  let valid = call_604133.validator(path, query, header, formData, body)
  let scheme = call_604133.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604133.url(scheme.get, call_604133.host, call_604133.base,
                         call_604133.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604133, url, valid)

proc call*(call_604134: Call_UpdateSMBFileShare_604121; body: JsonNode): Recallable =
  ## updateSMBFileShare
  ## <p>Updates a Server Message Block (SMB) file share.</p> <note> <p>To leave a file share field unchanged, set the corresponding input field to null. This operation is only supported for file gateways.</p> </note> <important> <p>File gateways require AWS Security Token Service (AWS STS) to be activated to enable you to create a file share. Make sure that AWS STS is activated in the AWS Region you are creating your file gateway in. If AWS STS is not activated in this AWS Region, activate it. For information about how to activate AWS STS, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_enable-regions.html">Activating and Deactivating AWS STS in an AWS Region</a> in the <i>AWS Identity and Access Management User Guide.</i> </p> <p>File gateways don't support creating hard or symbolic links on a file share.</p> </important>
  ##   body: JObject (required)
  var body_604135 = newJObject()
  if body != nil:
    body_604135 = body
  result = call_604134.call(nil, nil, nil, nil, body_604135)

var updateSMBFileShare* = Call_UpdateSMBFileShare_604121(
    name: "updateSMBFileShare", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.UpdateSMBFileShare",
    validator: validate_UpdateSMBFileShare_604122, base: "/",
    url: url_UpdateSMBFileShare_604123, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSMBSecurityStrategy_604136 = ref object of OpenApiRestCall_602467
proc url_UpdateSMBSecurityStrategy_604138(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateSMBSecurityStrategy_604137(path: JsonNode; query: JsonNode;
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
  var valid_604139 = header.getOrDefault("X-Amz-Date")
  valid_604139 = validateParameter(valid_604139, JString, required = false,
                                 default = nil)
  if valid_604139 != nil:
    section.add "X-Amz-Date", valid_604139
  var valid_604140 = header.getOrDefault("X-Amz-Security-Token")
  valid_604140 = validateParameter(valid_604140, JString, required = false,
                                 default = nil)
  if valid_604140 != nil:
    section.add "X-Amz-Security-Token", valid_604140
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604141 = header.getOrDefault("X-Amz-Target")
  valid_604141 = validateParameter(valid_604141, JString, required = true, default = newJString(
      "StorageGateway_20130630.UpdateSMBSecurityStrategy"))
  if valid_604141 != nil:
    section.add "X-Amz-Target", valid_604141
  var valid_604142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604142 = validateParameter(valid_604142, JString, required = false,
                                 default = nil)
  if valid_604142 != nil:
    section.add "X-Amz-Content-Sha256", valid_604142
  var valid_604143 = header.getOrDefault("X-Amz-Algorithm")
  valid_604143 = validateParameter(valid_604143, JString, required = false,
                                 default = nil)
  if valid_604143 != nil:
    section.add "X-Amz-Algorithm", valid_604143
  var valid_604144 = header.getOrDefault("X-Amz-Signature")
  valid_604144 = validateParameter(valid_604144, JString, required = false,
                                 default = nil)
  if valid_604144 != nil:
    section.add "X-Amz-Signature", valid_604144
  var valid_604145 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604145 = validateParameter(valid_604145, JString, required = false,
                                 default = nil)
  if valid_604145 != nil:
    section.add "X-Amz-SignedHeaders", valid_604145
  var valid_604146 = header.getOrDefault("X-Amz-Credential")
  valid_604146 = validateParameter(valid_604146, JString, required = false,
                                 default = nil)
  if valid_604146 != nil:
    section.add "X-Amz-Credential", valid_604146
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604148: Call_UpdateSMBSecurityStrategy_604136; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the SMB security strategy on a file gateway. This action is only supported in file gateways.</p> <note> <p>This API is called Security level in the User Guide.</p> <p>A higher security level can affect performance of the gateway.</p> </note>
  ## 
  let valid = call_604148.validator(path, query, header, formData, body)
  let scheme = call_604148.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604148.url(scheme.get, call_604148.host, call_604148.base,
                         call_604148.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604148, url, valid)

proc call*(call_604149: Call_UpdateSMBSecurityStrategy_604136; body: JsonNode): Recallable =
  ## updateSMBSecurityStrategy
  ## <p>Updates the SMB security strategy on a file gateway. This action is only supported in file gateways.</p> <note> <p>This API is called Security level in the User Guide.</p> <p>A higher security level can affect performance of the gateway.</p> </note>
  ##   body: JObject (required)
  var body_604150 = newJObject()
  if body != nil:
    body_604150 = body
  result = call_604149.call(nil, nil, nil, nil, body_604150)

var updateSMBSecurityStrategy* = Call_UpdateSMBSecurityStrategy_604136(
    name: "updateSMBSecurityStrategy", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.UpdateSMBSecurityStrategy",
    validator: validate_UpdateSMBSecurityStrategy_604137, base: "/",
    url: url_UpdateSMBSecurityStrategy_604138,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSnapshotSchedule_604151 = ref object of OpenApiRestCall_602467
proc url_UpdateSnapshotSchedule_604153(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateSnapshotSchedule_604152(path: JsonNode; query: JsonNode;
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
  var valid_604154 = header.getOrDefault("X-Amz-Date")
  valid_604154 = validateParameter(valid_604154, JString, required = false,
                                 default = nil)
  if valid_604154 != nil:
    section.add "X-Amz-Date", valid_604154
  var valid_604155 = header.getOrDefault("X-Amz-Security-Token")
  valid_604155 = validateParameter(valid_604155, JString, required = false,
                                 default = nil)
  if valid_604155 != nil:
    section.add "X-Amz-Security-Token", valid_604155
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604156 = header.getOrDefault("X-Amz-Target")
  valid_604156 = validateParameter(valid_604156, JString, required = true, default = newJString(
      "StorageGateway_20130630.UpdateSnapshotSchedule"))
  if valid_604156 != nil:
    section.add "X-Amz-Target", valid_604156
  var valid_604157 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604157 = validateParameter(valid_604157, JString, required = false,
                                 default = nil)
  if valid_604157 != nil:
    section.add "X-Amz-Content-Sha256", valid_604157
  var valid_604158 = header.getOrDefault("X-Amz-Algorithm")
  valid_604158 = validateParameter(valid_604158, JString, required = false,
                                 default = nil)
  if valid_604158 != nil:
    section.add "X-Amz-Algorithm", valid_604158
  var valid_604159 = header.getOrDefault("X-Amz-Signature")
  valid_604159 = validateParameter(valid_604159, JString, required = false,
                                 default = nil)
  if valid_604159 != nil:
    section.add "X-Amz-Signature", valid_604159
  var valid_604160 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604160 = validateParameter(valid_604160, JString, required = false,
                                 default = nil)
  if valid_604160 != nil:
    section.add "X-Amz-SignedHeaders", valid_604160
  var valid_604161 = header.getOrDefault("X-Amz-Credential")
  valid_604161 = validateParameter(valid_604161, JString, required = false,
                                 default = nil)
  if valid_604161 != nil:
    section.add "X-Amz-Credential", valid_604161
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604163: Call_UpdateSnapshotSchedule_604151; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates a snapshot schedule configured for a gateway volume. This operation is only supported in the cached volume and stored volume gateway types.</p> <p>The default snapshot schedule for volume is once every 24 hours, starting at the creation time of the volume. You can use this API to change the snapshot schedule configured for the volume.</p> <p>In the request you must identify the gateway volume whose snapshot schedule you want to update, and the schedule information, including when you want the snapshot to begin on a day and the frequency (in hours) of snapshots.</p>
  ## 
  let valid = call_604163.validator(path, query, header, formData, body)
  let scheme = call_604163.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604163.url(scheme.get, call_604163.host, call_604163.base,
                         call_604163.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604163, url, valid)

proc call*(call_604164: Call_UpdateSnapshotSchedule_604151; body: JsonNode): Recallable =
  ## updateSnapshotSchedule
  ## <p>Updates a snapshot schedule configured for a gateway volume. This operation is only supported in the cached volume and stored volume gateway types.</p> <p>The default snapshot schedule for volume is once every 24 hours, starting at the creation time of the volume. You can use this API to change the snapshot schedule configured for the volume.</p> <p>In the request you must identify the gateway volume whose snapshot schedule you want to update, and the schedule information, including when you want the snapshot to begin on a day and the frequency (in hours) of snapshots.</p>
  ##   body: JObject (required)
  var body_604165 = newJObject()
  if body != nil:
    body_604165 = body
  result = call_604164.call(nil, nil, nil, nil, body_604165)

var updateSnapshotSchedule* = Call_UpdateSnapshotSchedule_604151(
    name: "updateSnapshotSchedule", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.UpdateSnapshotSchedule",
    validator: validate_UpdateSnapshotSchedule_604152, base: "/",
    url: url_UpdateSnapshotSchedule_604153, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVTLDeviceType_604166 = ref object of OpenApiRestCall_602467
proc url_UpdateVTLDeviceType_604168(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateVTLDeviceType_604167(path: JsonNode; query: JsonNode;
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
  var valid_604169 = header.getOrDefault("X-Amz-Date")
  valid_604169 = validateParameter(valid_604169, JString, required = false,
                                 default = nil)
  if valid_604169 != nil:
    section.add "X-Amz-Date", valid_604169
  var valid_604170 = header.getOrDefault("X-Amz-Security-Token")
  valid_604170 = validateParameter(valid_604170, JString, required = false,
                                 default = nil)
  if valid_604170 != nil:
    section.add "X-Amz-Security-Token", valid_604170
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604171 = header.getOrDefault("X-Amz-Target")
  valid_604171 = validateParameter(valid_604171, JString, required = true, default = newJString(
      "StorageGateway_20130630.UpdateVTLDeviceType"))
  if valid_604171 != nil:
    section.add "X-Amz-Target", valid_604171
  var valid_604172 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604172 = validateParameter(valid_604172, JString, required = false,
                                 default = nil)
  if valid_604172 != nil:
    section.add "X-Amz-Content-Sha256", valid_604172
  var valid_604173 = header.getOrDefault("X-Amz-Algorithm")
  valid_604173 = validateParameter(valid_604173, JString, required = false,
                                 default = nil)
  if valid_604173 != nil:
    section.add "X-Amz-Algorithm", valid_604173
  var valid_604174 = header.getOrDefault("X-Amz-Signature")
  valid_604174 = validateParameter(valid_604174, JString, required = false,
                                 default = nil)
  if valid_604174 != nil:
    section.add "X-Amz-Signature", valid_604174
  var valid_604175 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604175 = validateParameter(valid_604175, JString, required = false,
                                 default = nil)
  if valid_604175 != nil:
    section.add "X-Amz-SignedHeaders", valid_604175
  var valid_604176 = header.getOrDefault("X-Amz-Credential")
  valid_604176 = validateParameter(valid_604176, JString, required = false,
                                 default = nil)
  if valid_604176 != nil:
    section.add "X-Amz-Credential", valid_604176
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604178: Call_UpdateVTLDeviceType_604166; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the type of medium changer in a tape gateway. When you activate a tape gateway, you select a medium changer type for the tape gateway. This operation enables you to select a different type of medium changer after a tape gateway is activated. This operation is only supported in the tape gateway type.
  ## 
  let valid = call_604178.validator(path, query, header, formData, body)
  let scheme = call_604178.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604178.url(scheme.get, call_604178.host, call_604178.base,
                         call_604178.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604178, url, valid)

proc call*(call_604179: Call_UpdateVTLDeviceType_604166; body: JsonNode): Recallable =
  ## updateVTLDeviceType
  ## Updates the type of medium changer in a tape gateway. When you activate a tape gateway, you select a medium changer type for the tape gateway. This operation enables you to select a different type of medium changer after a tape gateway is activated. This operation is only supported in the tape gateway type.
  ##   body: JObject (required)
  var body_604180 = newJObject()
  if body != nil:
    body_604180 = body
  result = call_604179.call(nil, nil, nil, nil, body_604180)

var updateVTLDeviceType* = Call_UpdateVTLDeviceType_604166(
    name: "updateVTLDeviceType", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.UpdateVTLDeviceType",
    validator: validate_UpdateVTLDeviceType_604167, base: "/",
    url: url_UpdateVTLDeviceType_604168, schemes: {Scheme.Https, Scheme.Http})
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
