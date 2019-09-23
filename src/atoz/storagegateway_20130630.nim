
import
  json, options, hashes, uri, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_600438 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600438](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600438): Option[Scheme] {.used.} =
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
proc queryString(query: JsonNode): string =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

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
  Call_ActivateGateway_600775 = ref object of OpenApiRestCall_600438
proc url_ActivateGateway_600777(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ActivateGateway_600776(path: JsonNode; query: JsonNode;
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
  var valid_600889 = header.getOrDefault("X-Amz-Date")
  valid_600889 = validateParameter(valid_600889, JString, required = false,
                                 default = nil)
  if valid_600889 != nil:
    section.add "X-Amz-Date", valid_600889
  var valid_600890 = header.getOrDefault("X-Amz-Security-Token")
  valid_600890 = validateParameter(valid_600890, JString, required = false,
                                 default = nil)
  if valid_600890 != nil:
    section.add "X-Amz-Security-Token", valid_600890
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600904 = header.getOrDefault("X-Amz-Target")
  valid_600904 = validateParameter(valid_600904, JString, required = true, default = newJString(
      "StorageGateway_20130630.ActivateGateway"))
  if valid_600904 != nil:
    section.add "X-Amz-Target", valid_600904
  var valid_600905 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600905 = validateParameter(valid_600905, JString, required = false,
                                 default = nil)
  if valid_600905 != nil:
    section.add "X-Amz-Content-Sha256", valid_600905
  var valid_600906 = header.getOrDefault("X-Amz-Algorithm")
  valid_600906 = validateParameter(valid_600906, JString, required = false,
                                 default = nil)
  if valid_600906 != nil:
    section.add "X-Amz-Algorithm", valid_600906
  var valid_600907 = header.getOrDefault("X-Amz-Signature")
  valid_600907 = validateParameter(valid_600907, JString, required = false,
                                 default = nil)
  if valid_600907 != nil:
    section.add "X-Amz-Signature", valid_600907
  var valid_600908 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600908 = validateParameter(valid_600908, JString, required = false,
                                 default = nil)
  if valid_600908 != nil:
    section.add "X-Amz-SignedHeaders", valid_600908
  var valid_600909 = header.getOrDefault("X-Amz-Credential")
  valid_600909 = validateParameter(valid_600909, JString, required = false,
                                 default = nil)
  if valid_600909 != nil:
    section.add "X-Amz-Credential", valid_600909
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600933: Call_ActivateGateway_600775; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Activates the gateway you previously deployed on your host. In the activation process, you specify information such as the AWS Region that you want to use for storing snapshots or tapes, the time zone for scheduled snapshots the gateway snapshot schedule window, an activation key, and a name for your gateway. The activation process also associates your gateway with your account; for more information, see <a>UpdateGatewayInformation</a>.</p> <note> <p>You must turn on the gateway VM before you can activate your gateway.</p> </note>
  ## 
  let valid = call_600933.validator(path, query, header, formData, body)
  let scheme = call_600933.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600933.url(scheme.get, call_600933.host, call_600933.base,
                         call_600933.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_600933, url, valid)

proc call*(call_601004: Call_ActivateGateway_600775; body: JsonNode): Recallable =
  ## activateGateway
  ## <p>Activates the gateway you previously deployed on your host. In the activation process, you specify information such as the AWS Region that you want to use for storing snapshots or tapes, the time zone for scheduled snapshots the gateway snapshot schedule window, an activation key, and a name for your gateway. The activation process also associates your gateway with your account; for more information, see <a>UpdateGatewayInformation</a>.</p> <note> <p>You must turn on the gateway VM before you can activate your gateway.</p> </note>
  ##   body: JObject (required)
  var body_601005 = newJObject()
  if body != nil:
    body_601005 = body
  result = call_601004.call(nil, nil, nil, nil, body_601005)

var activateGateway* = Call_ActivateGateway_600775(name: "activateGateway",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.ActivateGateway",
    validator: validate_ActivateGateway_600776, base: "/", url: url_ActivateGateway_600777,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AddCache_601044 = ref object of OpenApiRestCall_600438
proc url_AddCache_601046(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AddCache_601045(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601047 = header.getOrDefault("X-Amz-Date")
  valid_601047 = validateParameter(valid_601047, JString, required = false,
                                 default = nil)
  if valid_601047 != nil:
    section.add "X-Amz-Date", valid_601047
  var valid_601048 = header.getOrDefault("X-Amz-Security-Token")
  valid_601048 = validateParameter(valid_601048, JString, required = false,
                                 default = nil)
  if valid_601048 != nil:
    section.add "X-Amz-Security-Token", valid_601048
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601049 = header.getOrDefault("X-Amz-Target")
  valid_601049 = validateParameter(valid_601049, JString, required = true, default = newJString(
      "StorageGateway_20130630.AddCache"))
  if valid_601049 != nil:
    section.add "X-Amz-Target", valid_601049
  var valid_601050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601050 = validateParameter(valid_601050, JString, required = false,
                                 default = nil)
  if valid_601050 != nil:
    section.add "X-Amz-Content-Sha256", valid_601050
  var valid_601051 = header.getOrDefault("X-Amz-Algorithm")
  valid_601051 = validateParameter(valid_601051, JString, required = false,
                                 default = nil)
  if valid_601051 != nil:
    section.add "X-Amz-Algorithm", valid_601051
  var valid_601052 = header.getOrDefault("X-Amz-Signature")
  valid_601052 = validateParameter(valid_601052, JString, required = false,
                                 default = nil)
  if valid_601052 != nil:
    section.add "X-Amz-Signature", valid_601052
  var valid_601053 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601053 = validateParameter(valid_601053, JString, required = false,
                                 default = nil)
  if valid_601053 != nil:
    section.add "X-Amz-SignedHeaders", valid_601053
  var valid_601054 = header.getOrDefault("X-Amz-Credential")
  valid_601054 = validateParameter(valid_601054, JString, required = false,
                                 default = nil)
  if valid_601054 != nil:
    section.add "X-Amz-Credential", valid_601054
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601056: Call_AddCache_601044; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Configures one or more gateway local disks as cache for a gateway. This operation is only supported in the cached volume, tape and file gateway type (see <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/StorageGatewayConcepts.html">Storage Gateway Concepts</a>).</p> <p>In the request, you specify the gateway Amazon Resource Name (ARN) to which you want to add cache, and one or more disk IDs that you want to configure as cache.</p>
  ## 
  let valid = call_601056.validator(path, query, header, formData, body)
  let scheme = call_601056.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601056.url(scheme.get, call_601056.host, call_601056.base,
                         call_601056.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601056, url, valid)

proc call*(call_601057: Call_AddCache_601044; body: JsonNode): Recallable =
  ## addCache
  ## <p>Configures one or more gateway local disks as cache for a gateway. This operation is only supported in the cached volume, tape and file gateway type (see <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/StorageGatewayConcepts.html">Storage Gateway Concepts</a>).</p> <p>In the request, you specify the gateway Amazon Resource Name (ARN) to which you want to add cache, and one or more disk IDs that you want to configure as cache.</p>
  ##   body: JObject (required)
  var body_601058 = newJObject()
  if body != nil:
    body_601058 = body
  result = call_601057.call(nil, nil, nil, nil, body_601058)

var addCache* = Call_AddCache_601044(name: "addCache", meth: HttpMethod.HttpPost,
                                  host: "storagegateway.amazonaws.com", route: "/#X-Amz-Target=StorageGateway_20130630.AddCache",
                                  validator: validate_AddCache_601045, base: "/",
                                  url: url_AddCache_601046,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_AddTagsToResource_601059 = ref object of OpenApiRestCall_600438
proc url_AddTagsToResource_601061(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AddTagsToResource_601060(path: JsonNode; query: JsonNode;
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
  var valid_601062 = header.getOrDefault("X-Amz-Date")
  valid_601062 = validateParameter(valid_601062, JString, required = false,
                                 default = nil)
  if valid_601062 != nil:
    section.add "X-Amz-Date", valid_601062
  var valid_601063 = header.getOrDefault("X-Amz-Security-Token")
  valid_601063 = validateParameter(valid_601063, JString, required = false,
                                 default = nil)
  if valid_601063 != nil:
    section.add "X-Amz-Security-Token", valid_601063
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601064 = header.getOrDefault("X-Amz-Target")
  valid_601064 = validateParameter(valid_601064, JString, required = true, default = newJString(
      "StorageGateway_20130630.AddTagsToResource"))
  if valid_601064 != nil:
    section.add "X-Amz-Target", valid_601064
  var valid_601065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601065 = validateParameter(valid_601065, JString, required = false,
                                 default = nil)
  if valid_601065 != nil:
    section.add "X-Amz-Content-Sha256", valid_601065
  var valid_601066 = header.getOrDefault("X-Amz-Algorithm")
  valid_601066 = validateParameter(valid_601066, JString, required = false,
                                 default = nil)
  if valid_601066 != nil:
    section.add "X-Amz-Algorithm", valid_601066
  var valid_601067 = header.getOrDefault("X-Amz-Signature")
  valid_601067 = validateParameter(valid_601067, JString, required = false,
                                 default = nil)
  if valid_601067 != nil:
    section.add "X-Amz-Signature", valid_601067
  var valid_601068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601068 = validateParameter(valid_601068, JString, required = false,
                                 default = nil)
  if valid_601068 != nil:
    section.add "X-Amz-SignedHeaders", valid_601068
  var valid_601069 = header.getOrDefault("X-Amz-Credential")
  valid_601069 = validateParameter(valid_601069, JString, required = false,
                                 default = nil)
  if valid_601069 != nil:
    section.add "X-Amz-Credential", valid_601069
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601071: Call_AddTagsToResource_601059; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds one or more tags to the specified resource. You use tags to add metadata to resources, which you can use to categorize these resources. For example, you can categorize resources by purpose, owner, environment, or team. Each tag consists of a key and a value, which you define. You can add tags to the following AWS Storage Gateway resources:</p> <ul> <li> <p>Storage gateways of all types</p> </li> <li> <p>Storage volumes</p> </li> <li> <p>Virtual tapes</p> </li> <li> <p>NFS and SMB file shares</p> </li> </ul> <p>You can create a maximum of 50 tags for each resource. Virtual tapes and storage volumes that are recovered to a new gateway maintain their tags.</p>
  ## 
  let valid = call_601071.validator(path, query, header, formData, body)
  let scheme = call_601071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601071.url(scheme.get, call_601071.host, call_601071.base,
                         call_601071.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601071, url, valid)

proc call*(call_601072: Call_AddTagsToResource_601059; body: JsonNode): Recallable =
  ## addTagsToResource
  ## <p>Adds one or more tags to the specified resource. You use tags to add metadata to resources, which you can use to categorize these resources. For example, you can categorize resources by purpose, owner, environment, or team. Each tag consists of a key and a value, which you define. You can add tags to the following AWS Storage Gateway resources:</p> <ul> <li> <p>Storage gateways of all types</p> </li> <li> <p>Storage volumes</p> </li> <li> <p>Virtual tapes</p> </li> <li> <p>NFS and SMB file shares</p> </li> </ul> <p>You can create a maximum of 50 tags for each resource. Virtual tapes and storage volumes that are recovered to a new gateway maintain their tags.</p>
  ##   body: JObject (required)
  var body_601073 = newJObject()
  if body != nil:
    body_601073 = body
  result = call_601072.call(nil, nil, nil, nil, body_601073)

var addTagsToResource* = Call_AddTagsToResource_601059(name: "addTagsToResource",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.AddTagsToResource",
    validator: validate_AddTagsToResource_601060, base: "/",
    url: url_AddTagsToResource_601061, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AddUploadBuffer_601074 = ref object of OpenApiRestCall_600438
proc url_AddUploadBuffer_601076(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AddUploadBuffer_601075(path: JsonNode; query: JsonNode;
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
  var valid_601077 = header.getOrDefault("X-Amz-Date")
  valid_601077 = validateParameter(valid_601077, JString, required = false,
                                 default = nil)
  if valid_601077 != nil:
    section.add "X-Amz-Date", valid_601077
  var valid_601078 = header.getOrDefault("X-Amz-Security-Token")
  valid_601078 = validateParameter(valid_601078, JString, required = false,
                                 default = nil)
  if valid_601078 != nil:
    section.add "X-Amz-Security-Token", valid_601078
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601079 = header.getOrDefault("X-Amz-Target")
  valid_601079 = validateParameter(valid_601079, JString, required = true, default = newJString(
      "StorageGateway_20130630.AddUploadBuffer"))
  if valid_601079 != nil:
    section.add "X-Amz-Target", valid_601079
  var valid_601080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601080 = validateParameter(valid_601080, JString, required = false,
                                 default = nil)
  if valid_601080 != nil:
    section.add "X-Amz-Content-Sha256", valid_601080
  var valid_601081 = header.getOrDefault("X-Amz-Algorithm")
  valid_601081 = validateParameter(valid_601081, JString, required = false,
                                 default = nil)
  if valid_601081 != nil:
    section.add "X-Amz-Algorithm", valid_601081
  var valid_601082 = header.getOrDefault("X-Amz-Signature")
  valid_601082 = validateParameter(valid_601082, JString, required = false,
                                 default = nil)
  if valid_601082 != nil:
    section.add "X-Amz-Signature", valid_601082
  var valid_601083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601083 = validateParameter(valid_601083, JString, required = false,
                                 default = nil)
  if valid_601083 != nil:
    section.add "X-Amz-SignedHeaders", valid_601083
  var valid_601084 = header.getOrDefault("X-Amz-Credential")
  valid_601084 = validateParameter(valid_601084, JString, required = false,
                                 default = nil)
  if valid_601084 != nil:
    section.add "X-Amz-Credential", valid_601084
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601086: Call_AddUploadBuffer_601074; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Configures one or more gateway local disks as upload buffer for a specified gateway. This operation is supported for the stored volume, cached volume and tape gateway types.</p> <p>In the request, you specify the gateway Amazon Resource Name (ARN) to which you want to add upload buffer, and one or more disk IDs that you want to configure as upload buffer.</p>
  ## 
  let valid = call_601086.validator(path, query, header, formData, body)
  let scheme = call_601086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601086.url(scheme.get, call_601086.host, call_601086.base,
                         call_601086.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601086, url, valid)

proc call*(call_601087: Call_AddUploadBuffer_601074; body: JsonNode): Recallable =
  ## addUploadBuffer
  ## <p>Configures one or more gateway local disks as upload buffer for a specified gateway. This operation is supported for the stored volume, cached volume and tape gateway types.</p> <p>In the request, you specify the gateway Amazon Resource Name (ARN) to which you want to add upload buffer, and one or more disk IDs that you want to configure as upload buffer.</p>
  ##   body: JObject (required)
  var body_601088 = newJObject()
  if body != nil:
    body_601088 = body
  result = call_601087.call(nil, nil, nil, nil, body_601088)

var addUploadBuffer* = Call_AddUploadBuffer_601074(name: "addUploadBuffer",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.AddUploadBuffer",
    validator: validate_AddUploadBuffer_601075, base: "/", url: url_AddUploadBuffer_601076,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AddWorkingStorage_601089 = ref object of OpenApiRestCall_600438
proc url_AddWorkingStorage_601091(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AddWorkingStorage_601090(path: JsonNode; query: JsonNode;
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
  var valid_601092 = header.getOrDefault("X-Amz-Date")
  valid_601092 = validateParameter(valid_601092, JString, required = false,
                                 default = nil)
  if valid_601092 != nil:
    section.add "X-Amz-Date", valid_601092
  var valid_601093 = header.getOrDefault("X-Amz-Security-Token")
  valid_601093 = validateParameter(valid_601093, JString, required = false,
                                 default = nil)
  if valid_601093 != nil:
    section.add "X-Amz-Security-Token", valid_601093
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601094 = header.getOrDefault("X-Amz-Target")
  valid_601094 = validateParameter(valid_601094, JString, required = true, default = newJString(
      "StorageGateway_20130630.AddWorkingStorage"))
  if valid_601094 != nil:
    section.add "X-Amz-Target", valid_601094
  var valid_601095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601095 = validateParameter(valid_601095, JString, required = false,
                                 default = nil)
  if valid_601095 != nil:
    section.add "X-Amz-Content-Sha256", valid_601095
  var valid_601096 = header.getOrDefault("X-Amz-Algorithm")
  valid_601096 = validateParameter(valid_601096, JString, required = false,
                                 default = nil)
  if valid_601096 != nil:
    section.add "X-Amz-Algorithm", valid_601096
  var valid_601097 = header.getOrDefault("X-Amz-Signature")
  valid_601097 = validateParameter(valid_601097, JString, required = false,
                                 default = nil)
  if valid_601097 != nil:
    section.add "X-Amz-Signature", valid_601097
  var valid_601098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601098 = validateParameter(valid_601098, JString, required = false,
                                 default = nil)
  if valid_601098 != nil:
    section.add "X-Amz-SignedHeaders", valid_601098
  var valid_601099 = header.getOrDefault("X-Amz-Credential")
  valid_601099 = validateParameter(valid_601099, JString, required = false,
                                 default = nil)
  if valid_601099 != nil:
    section.add "X-Amz-Credential", valid_601099
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601101: Call_AddWorkingStorage_601089; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Configures one or more gateway local disks as working storage for a gateway. This operation is only supported in the stored volume gateway type. This operation is deprecated in cached volume API version 20120630. Use <a>AddUploadBuffer</a> instead.</p> <note> <p>Working storage is also referred to as upload buffer. You can also use the <a>AddUploadBuffer</a> operation to add upload buffer to a stored volume gateway.</p> </note> <p>In the request, you specify the gateway Amazon Resource Name (ARN) to which you want to add working storage, and one or more disk IDs that you want to configure as working storage.</p>
  ## 
  let valid = call_601101.validator(path, query, header, formData, body)
  let scheme = call_601101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601101.url(scheme.get, call_601101.host, call_601101.base,
                         call_601101.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601101, url, valid)

proc call*(call_601102: Call_AddWorkingStorage_601089; body: JsonNode): Recallable =
  ## addWorkingStorage
  ## <p>Configures one or more gateway local disks as working storage for a gateway. This operation is only supported in the stored volume gateway type. This operation is deprecated in cached volume API version 20120630. Use <a>AddUploadBuffer</a> instead.</p> <note> <p>Working storage is also referred to as upload buffer. You can also use the <a>AddUploadBuffer</a> operation to add upload buffer to a stored volume gateway.</p> </note> <p>In the request, you specify the gateway Amazon Resource Name (ARN) to which you want to add working storage, and one or more disk IDs that you want to configure as working storage.</p>
  ##   body: JObject (required)
  var body_601103 = newJObject()
  if body != nil:
    body_601103 = body
  result = call_601102.call(nil, nil, nil, nil, body_601103)

var addWorkingStorage* = Call_AddWorkingStorage_601089(name: "addWorkingStorage",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.AddWorkingStorage",
    validator: validate_AddWorkingStorage_601090, base: "/",
    url: url_AddWorkingStorage_601091, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssignTapePool_601104 = ref object of OpenApiRestCall_600438
proc url_AssignTapePool_601106(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AssignTapePool_601105(path: JsonNode; query: JsonNode;
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
  var valid_601107 = header.getOrDefault("X-Amz-Date")
  valid_601107 = validateParameter(valid_601107, JString, required = false,
                                 default = nil)
  if valid_601107 != nil:
    section.add "X-Amz-Date", valid_601107
  var valid_601108 = header.getOrDefault("X-Amz-Security-Token")
  valid_601108 = validateParameter(valid_601108, JString, required = false,
                                 default = nil)
  if valid_601108 != nil:
    section.add "X-Amz-Security-Token", valid_601108
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601109 = header.getOrDefault("X-Amz-Target")
  valid_601109 = validateParameter(valid_601109, JString, required = true, default = newJString(
      "StorageGateway_20130630.AssignTapePool"))
  if valid_601109 != nil:
    section.add "X-Amz-Target", valid_601109
  var valid_601110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601110 = validateParameter(valid_601110, JString, required = false,
                                 default = nil)
  if valid_601110 != nil:
    section.add "X-Amz-Content-Sha256", valid_601110
  var valid_601111 = header.getOrDefault("X-Amz-Algorithm")
  valid_601111 = validateParameter(valid_601111, JString, required = false,
                                 default = nil)
  if valid_601111 != nil:
    section.add "X-Amz-Algorithm", valid_601111
  var valid_601112 = header.getOrDefault("X-Amz-Signature")
  valid_601112 = validateParameter(valid_601112, JString, required = false,
                                 default = nil)
  if valid_601112 != nil:
    section.add "X-Amz-Signature", valid_601112
  var valid_601113 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601113 = validateParameter(valid_601113, JString, required = false,
                                 default = nil)
  if valid_601113 != nil:
    section.add "X-Amz-SignedHeaders", valid_601113
  var valid_601114 = header.getOrDefault("X-Amz-Credential")
  valid_601114 = validateParameter(valid_601114, JString, required = false,
                                 default = nil)
  if valid_601114 != nil:
    section.add "X-Amz-Credential", valid_601114
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601116: Call_AssignTapePool_601104; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Assigns a tape to a tape pool for archiving. The tape assigned to a pool is archived in the S3 storage class that is associated with the pool. When you use your backup application to eject the tape, the tape is archived directly into the S3 storage class (Glacier or Deep Archive) that corresponds to the pool.</p> <p>Valid values: "GLACIER", "DEEP_ARCHIVE"</p>
  ## 
  let valid = call_601116.validator(path, query, header, formData, body)
  let scheme = call_601116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601116.url(scheme.get, call_601116.host, call_601116.base,
                         call_601116.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601116, url, valid)

proc call*(call_601117: Call_AssignTapePool_601104; body: JsonNode): Recallable =
  ## assignTapePool
  ## <p>Assigns a tape to a tape pool for archiving. The tape assigned to a pool is archived in the S3 storage class that is associated with the pool. When you use your backup application to eject the tape, the tape is archived directly into the S3 storage class (Glacier or Deep Archive) that corresponds to the pool.</p> <p>Valid values: "GLACIER", "DEEP_ARCHIVE"</p>
  ##   body: JObject (required)
  var body_601118 = newJObject()
  if body != nil:
    body_601118 = body
  result = call_601117.call(nil, nil, nil, nil, body_601118)

var assignTapePool* = Call_AssignTapePool_601104(name: "assignTapePool",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.AssignTapePool",
    validator: validate_AssignTapePool_601105, base: "/", url: url_AssignTapePool_601106,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachVolume_601119 = ref object of OpenApiRestCall_600438
proc url_AttachVolume_601121(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AttachVolume_601120(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601122 = header.getOrDefault("X-Amz-Date")
  valid_601122 = validateParameter(valid_601122, JString, required = false,
                                 default = nil)
  if valid_601122 != nil:
    section.add "X-Amz-Date", valid_601122
  var valid_601123 = header.getOrDefault("X-Amz-Security-Token")
  valid_601123 = validateParameter(valid_601123, JString, required = false,
                                 default = nil)
  if valid_601123 != nil:
    section.add "X-Amz-Security-Token", valid_601123
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601124 = header.getOrDefault("X-Amz-Target")
  valid_601124 = validateParameter(valid_601124, JString, required = true, default = newJString(
      "StorageGateway_20130630.AttachVolume"))
  if valid_601124 != nil:
    section.add "X-Amz-Target", valid_601124
  var valid_601125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601125 = validateParameter(valid_601125, JString, required = false,
                                 default = nil)
  if valid_601125 != nil:
    section.add "X-Amz-Content-Sha256", valid_601125
  var valid_601126 = header.getOrDefault("X-Amz-Algorithm")
  valid_601126 = validateParameter(valid_601126, JString, required = false,
                                 default = nil)
  if valid_601126 != nil:
    section.add "X-Amz-Algorithm", valid_601126
  var valid_601127 = header.getOrDefault("X-Amz-Signature")
  valid_601127 = validateParameter(valid_601127, JString, required = false,
                                 default = nil)
  if valid_601127 != nil:
    section.add "X-Amz-Signature", valid_601127
  var valid_601128 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601128 = validateParameter(valid_601128, JString, required = false,
                                 default = nil)
  if valid_601128 != nil:
    section.add "X-Amz-SignedHeaders", valid_601128
  var valid_601129 = header.getOrDefault("X-Amz-Credential")
  valid_601129 = validateParameter(valid_601129, JString, required = false,
                                 default = nil)
  if valid_601129 != nil:
    section.add "X-Amz-Credential", valid_601129
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601131: Call_AttachVolume_601119; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Connects a volume to an iSCSI connection and then attaches the volume to the specified gateway. Detaching and attaching a volume enables you to recover your data from one gateway to a different gateway without creating a snapshot. It also makes it easier to move your volumes from an on-premises gateway to a gateway hosted on an Amazon EC2 instance.
  ## 
  let valid = call_601131.validator(path, query, header, formData, body)
  let scheme = call_601131.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601131.url(scheme.get, call_601131.host, call_601131.base,
                         call_601131.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601131, url, valid)

proc call*(call_601132: Call_AttachVolume_601119; body: JsonNode): Recallable =
  ## attachVolume
  ## Connects a volume to an iSCSI connection and then attaches the volume to the specified gateway. Detaching and attaching a volume enables you to recover your data from one gateway to a different gateway without creating a snapshot. It also makes it easier to move your volumes from an on-premises gateway to a gateway hosted on an Amazon EC2 instance.
  ##   body: JObject (required)
  var body_601133 = newJObject()
  if body != nil:
    body_601133 = body
  result = call_601132.call(nil, nil, nil, nil, body_601133)

var attachVolume* = Call_AttachVolume_601119(name: "attachVolume",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.AttachVolume",
    validator: validate_AttachVolume_601120, base: "/", url: url_AttachVolume_601121,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelArchival_601134 = ref object of OpenApiRestCall_600438
proc url_CancelArchival_601136(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CancelArchival_601135(path: JsonNode; query: JsonNode;
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
  var valid_601137 = header.getOrDefault("X-Amz-Date")
  valid_601137 = validateParameter(valid_601137, JString, required = false,
                                 default = nil)
  if valid_601137 != nil:
    section.add "X-Amz-Date", valid_601137
  var valid_601138 = header.getOrDefault("X-Amz-Security-Token")
  valid_601138 = validateParameter(valid_601138, JString, required = false,
                                 default = nil)
  if valid_601138 != nil:
    section.add "X-Amz-Security-Token", valid_601138
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601139 = header.getOrDefault("X-Amz-Target")
  valid_601139 = validateParameter(valid_601139, JString, required = true, default = newJString(
      "StorageGateway_20130630.CancelArchival"))
  if valid_601139 != nil:
    section.add "X-Amz-Target", valid_601139
  var valid_601140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601140 = validateParameter(valid_601140, JString, required = false,
                                 default = nil)
  if valid_601140 != nil:
    section.add "X-Amz-Content-Sha256", valid_601140
  var valid_601141 = header.getOrDefault("X-Amz-Algorithm")
  valid_601141 = validateParameter(valid_601141, JString, required = false,
                                 default = nil)
  if valid_601141 != nil:
    section.add "X-Amz-Algorithm", valid_601141
  var valid_601142 = header.getOrDefault("X-Amz-Signature")
  valid_601142 = validateParameter(valid_601142, JString, required = false,
                                 default = nil)
  if valid_601142 != nil:
    section.add "X-Amz-Signature", valid_601142
  var valid_601143 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601143 = validateParameter(valid_601143, JString, required = false,
                                 default = nil)
  if valid_601143 != nil:
    section.add "X-Amz-SignedHeaders", valid_601143
  var valid_601144 = header.getOrDefault("X-Amz-Credential")
  valid_601144 = validateParameter(valid_601144, JString, required = false,
                                 default = nil)
  if valid_601144 != nil:
    section.add "X-Amz-Credential", valid_601144
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601146: Call_CancelArchival_601134; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels archiving of a virtual tape to the virtual tape shelf (VTS) after the archiving process is initiated. This operation is only supported in the tape gateway type.
  ## 
  let valid = call_601146.validator(path, query, header, formData, body)
  let scheme = call_601146.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601146.url(scheme.get, call_601146.host, call_601146.base,
                         call_601146.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601146, url, valid)

proc call*(call_601147: Call_CancelArchival_601134; body: JsonNode): Recallable =
  ## cancelArchival
  ## Cancels archiving of a virtual tape to the virtual tape shelf (VTS) after the archiving process is initiated. This operation is only supported in the tape gateway type.
  ##   body: JObject (required)
  var body_601148 = newJObject()
  if body != nil:
    body_601148 = body
  result = call_601147.call(nil, nil, nil, nil, body_601148)

var cancelArchival* = Call_CancelArchival_601134(name: "cancelArchival",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.CancelArchival",
    validator: validate_CancelArchival_601135, base: "/", url: url_CancelArchival_601136,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelRetrieval_601149 = ref object of OpenApiRestCall_600438
proc url_CancelRetrieval_601151(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CancelRetrieval_601150(path: JsonNode; query: JsonNode;
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
  var valid_601152 = header.getOrDefault("X-Amz-Date")
  valid_601152 = validateParameter(valid_601152, JString, required = false,
                                 default = nil)
  if valid_601152 != nil:
    section.add "X-Amz-Date", valid_601152
  var valid_601153 = header.getOrDefault("X-Amz-Security-Token")
  valid_601153 = validateParameter(valid_601153, JString, required = false,
                                 default = nil)
  if valid_601153 != nil:
    section.add "X-Amz-Security-Token", valid_601153
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601154 = header.getOrDefault("X-Amz-Target")
  valid_601154 = validateParameter(valid_601154, JString, required = true, default = newJString(
      "StorageGateway_20130630.CancelRetrieval"))
  if valid_601154 != nil:
    section.add "X-Amz-Target", valid_601154
  var valid_601155 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601155 = validateParameter(valid_601155, JString, required = false,
                                 default = nil)
  if valid_601155 != nil:
    section.add "X-Amz-Content-Sha256", valid_601155
  var valid_601156 = header.getOrDefault("X-Amz-Algorithm")
  valid_601156 = validateParameter(valid_601156, JString, required = false,
                                 default = nil)
  if valid_601156 != nil:
    section.add "X-Amz-Algorithm", valid_601156
  var valid_601157 = header.getOrDefault("X-Amz-Signature")
  valid_601157 = validateParameter(valid_601157, JString, required = false,
                                 default = nil)
  if valid_601157 != nil:
    section.add "X-Amz-Signature", valid_601157
  var valid_601158 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601158 = validateParameter(valid_601158, JString, required = false,
                                 default = nil)
  if valid_601158 != nil:
    section.add "X-Amz-SignedHeaders", valid_601158
  var valid_601159 = header.getOrDefault("X-Amz-Credential")
  valid_601159 = validateParameter(valid_601159, JString, required = false,
                                 default = nil)
  if valid_601159 != nil:
    section.add "X-Amz-Credential", valid_601159
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601161: Call_CancelRetrieval_601149; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels retrieval of a virtual tape from the virtual tape shelf (VTS) to a gateway after the retrieval process is initiated. The virtual tape is returned to the VTS. This operation is only supported in the tape gateway type.
  ## 
  let valid = call_601161.validator(path, query, header, formData, body)
  let scheme = call_601161.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601161.url(scheme.get, call_601161.host, call_601161.base,
                         call_601161.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601161, url, valid)

proc call*(call_601162: Call_CancelRetrieval_601149; body: JsonNode): Recallable =
  ## cancelRetrieval
  ## Cancels retrieval of a virtual tape from the virtual tape shelf (VTS) to a gateway after the retrieval process is initiated. The virtual tape is returned to the VTS. This operation is only supported in the tape gateway type.
  ##   body: JObject (required)
  var body_601163 = newJObject()
  if body != nil:
    body_601163 = body
  result = call_601162.call(nil, nil, nil, nil, body_601163)

var cancelRetrieval* = Call_CancelRetrieval_601149(name: "cancelRetrieval",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.CancelRetrieval",
    validator: validate_CancelRetrieval_601150, base: "/", url: url_CancelRetrieval_601151,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCachediSCSIVolume_601164 = ref object of OpenApiRestCall_600438
proc url_CreateCachediSCSIVolume_601166(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateCachediSCSIVolume_601165(path: JsonNode; query: JsonNode;
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
  var valid_601167 = header.getOrDefault("X-Amz-Date")
  valid_601167 = validateParameter(valid_601167, JString, required = false,
                                 default = nil)
  if valid_601167 != nil:
    section.add "X-Amz-Date", valid_601167
  var valid_601168 = header.getOrDefault("X-Amz-Security-Token")
  valid_601168 = validateParameter(valid_601168, JString, required = false,
                                 default = nil)
  if valid_601168 != nil:
    section.add "X-Amz-Security-Token", valid_601168
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601169 = header.getOrDefault("X-Amz-Target")
  valid_601169 = validateParameter(valid_601169, JString, required = true, default = newJString(
      "StorageGateway_20130630.CreateCachediSCSIVolume"))
  if valid_601169 != nil:
    section.add "X-Amz-Target", valid_601169
  var valid_601170 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601170 = validateParameter(valid_601170, JString, required = false,
                                 default = nil)
  if valid_601170 != nil:
    section.add "X-Amz-Content-Sha256", valid_601170
  var valid_601171 = header.getOrDefault("X-Amz-Algorithm")
  valid_601171 = validateParameter(valid_601171, JString, required = false,
                                 default = nil)
  if valid_601171 != nil:
    section.add "X-Amz-Algorithm", valid_601171
  var valid_601172 = header.getOrDefault("X-Amz-Signature")
  valid_601172 = validateParameter(valid_601172, JString, required = false,
                                 default = nil)
  if valid_601172 != nil:
    section.add "X-Amz-Signature", valid_601172
  var valid_601173 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601173 = validateParameter(valid_601173, JString, required = false,
                                 default = nil)
  if valid_601173 != nil:
    section.add "X-Amz-SignedHeaders", valid_601173
  var valid_601174 = header.getOrDefault("X-Amz-Credential")
  valid_601174 = validateParameter(valid_601174, JString, required = false,
                                 default = nil)
  if valid_601174 != nil:
    section.add "X-Amz-Credential", valid_601174
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601176: Call_CreateCachediSCSIVolume_601164; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a cached volume on a specified cached volume gateway. This operation is only supported in the cached volume gateway type.</p> <note> <p>Cache storage must be allocated to the gateway before you can create a cached volume. Use the <a>AddCache</a> operation to add cache storage to a gateway. </p> </note> <p>In the request, you must specify the gateway, size of the volume in bytes, the iSCSI target name, an IP address on which to expose the target, and a unique client token. In response, the gateway creates the volume and returns information about it. This information includes the volume Amazon Resource Name (ARN), its size, and the iSCSI target ARN that initiators can use to connect to the volume target.</p> <p>Optionally, you can provide the ARN for an existing volume as the <code>SourceVolumeARN</code> for this cached volume, which creates an exact copy of the existing volume’s latest recovery point. The <code>VolumeSizeInBytes</code> value must be equal to or larger than the size of the copied volume, in bytes.</p>
  ## 
  let valid = call_601176.validator(path, query, header, formData, body)
  let scheme = call_601176.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601176.url(scheme.get, call_601176.host, call_601176.base,
                         call_601176.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601176, url, valid)

proc call*(call_601177: Call_CreateCachediSCSIVolume_601164; body: JsonNode): Recallable =
  ## createCachediSCSIVolume
  ## <p>Creates a cached volume on a specified cached volume gateway. This operation is only supported in the cached volume gateway type.</p> <note> <p>Cache storage must be allocated to the gateway before you can create a cached volume. Use the <a>AddCache</a> operation to add cache storage to a gateway. </p> </note> <p>In the request, you must specify the gateway, size of the volume in bytes, the iSCSI target name, an IP address on which to expose the target, and a unique client token. In response, the gateway creates the volume and returns information about it. This information includes the volume Amazon Resource Name (ARN), its size, and the iSCSI target ARN that initiators can use to connect to the volume target.</p> <p>Optionally, you can provide the ARN for an existing volume as the <code>SourceVolumeARN</code> for this cached volume, which creates an exact copy of the existing volume’s latest recovery point. The <code>VolumeSizeInBytes</code> value must be equal to or larger than the size of the copied volume, in bytes.</p>
  ##   body: JObject (required)
  var body_601178 = newJObject()
  if body != nil:
    body_601178 = body
  result = call_601177.call(nil, nil, nil, nil, body_601178)

var createCachediSCSIVolume* = Call_CreateCachediSCSIVolume_601164(
    name: "createCachediSCSIVolume", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.CreateCachediSCSIVolume",
    validator: validate_CreateCachediSCSIVolume_601165, base: "/",
    url: url_CreateCachediSCSIVolume_601166, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNFSFileShare_601179 = ref object of OpenApiRestCall_600438
proc url_CreateNFSFileShare_601181(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateNFSFileShare_601180(path: JsonNode; query: JsonNode;
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
  var valid_601182 = header.getOrDefault("X-Amz-Date")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "X-Amz-Date", valid_601182
  var valid_601183 = header.getOrDefault("X-Amz-Security-Token")
  valid_601183 = validateParameter(valid_601183, JString, required = false,
                                 default = nil)
  if valid_601183 != nil:
    section.add "X-Amz-Security-Token", valid_601183
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601184 = header.getOrDefault("X-Amz-Target")
  valid_601184 = validateParameter(valid_601184, JString, required = true, default = newJString(
      "StorageGateway_20130630.CreateNFSFileShare"))
  if valid_601184 != nil:
    section.add "X-Amz-Target", valid_601184
  var valid_601185 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601185 = validateParameter(valid_601185, JString, required = false,
                                 default = nil)
  if valid_601185 != nil:
    section.add "X-Amz-Content-Sha256", valid_601185
  var valid_601186 = header.getOrDefault("X-Amz-Algorithm")
  valid_601186 = validateParameter(valid_601186, JString, required = false,
                                 default = nil)
  if valid_601186 != nil:
    section.add "X-Amz-Algorithm", valid_601186
  var valid_601187 = header.getOrDefault("X-Amz-Signature")
  valid_601187 = validateParameter(valid_601187, JString, required = false,
                                 default = nil)
  if valid_601187 != nil:
    section.add "X-Amz-Signature", valid_601187
  var valid_601188 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601188 = validateParameter(valid_601188, JString, required = false,
                                 default = nil)
  if valid_601188 != nil:
    section.add "X-Amz-SignedHeaders", valid_601188
  var valid_601189 = header.getOrDefault("X-Amz-Credential")
  valid_601189 = validateParameter(valid_601189, JString, required = false,
                                 default = nil)
  if valid_601189 != nil:
    section.add "X-Amz-Credential", valid_601189
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601191: Call_CreateNFSFileShare_601179; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Network File System (NFS) file share on an existing file gateway. In Storage Gateway, a file share is a file system mount point backed by Amazon S3 cloud storage. Storage Gateway exposes file shares using a NFS interface. This operation is only supported for file gateways.</p> <important> <p>File gateway requires AWS Security Token Service (AWS STS) to be activated to enable you create a file share. Make sure AWS STS is activated in the AWS Region you are creating your file gateway in. If AWS STS is not activated in the AWS Region, activate it. For information about how to activate AWS STS, see Activating and Deactivating AWS STS in an AWS Region in the AWS Identity and Access Management User Guide. </p> <p>File gateway does not support creating hard or symbolic links on a file share.</p> </important>
  ## 
  let valid = call_601191.validator(path, query, header, formData, body)
  let scheme = call_601191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601191.url(scheme.get, call_601191.host, call_601191.base,
                         call_601191.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601191, url, valid)

proc call*(call_601192: Call_CreateNFSFileShare_601179; body: JsonNode): Recallable =
  ## createNFSFileShare
  ## <p>Creates a Network File System (NFS) file share on an existing file gateway. In Storage Gateway, a file share is a file system mount point backed by Amazon S3 cloud storage. Storage Gateway exposes file shares using a NFS interface. This operation is only supported for file gateways.</p> <important> <p>File gateway requires AWS Security Token Service (AWS STS) to be activated to enable you create a file share. Make sure AWS STS is activated in the AWS Region you are creating your file gateway in. If AWS STS is not activated in the AWS Region, activate it. For information about how to activate AWS STS, see Activating and Deactivating AWS STS in an AWS Region in the AWS Identity and Access Management User Guide. </p> <p>File gateway does not support creating hard or symbolic links on a file share.</p> </important>
  ##   body: JObject (required)
  var body_601193 = newJObject()
  if body != nil:
    body_601193 = body
  result = call_601192.call(nil, nil, nil, nil, body_601193)

var createNFSFileShare* = Call_CreateNFSFileShare_601179(
    name: "createNFSFileShare", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.CreateNFSFileShare",
    validator: validate_CreateNFSFileShare_601180, base: "/",
    url: url_CreateNFSFileShare_601181, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSMBFileShare_601194 = ref object of OpenApiRestCall_600438
proc url_CreateSMBFileShare_601196(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateSMBFileShare_601195(path: JsonNode; query: JsonNode;
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
  var valid_601197 = header.getOrDefault("X-Amz-Date")
  valid_601197 = validateParameter(valid_601197, JString, required = false,
                                 default = nil)
  if valid_601197 != nil:
    section.add "X-Amz-Date", valid_601197
  var valid_601198 = header.getOrDefault("X-Amz-Security-Token")
  valid_601198 = validateParameter(valid_601198, JString, required = false,
                                 default = nil)
  if valid_601198 != nil:
    section.add "X-Amz-Security-Token", valid_601198
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601199 = header.getOrDefault("X-Amz-Target")
  valid_601199 = validateParameter(valid_601199, JString, required = true, default = newJString(
      "StorageGateway_20130630.CreateSMBFileShare"))
  if valid_601199 != nil:
    section.add "X-Amz-Target", valid_601199
  var valid_601200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601200 = validateParameter(valid_601200, JString, required = false,
                                 default = nil)
  if valid_601200 != nil:
    section.add "X-Amz-Content-Sha256", valid_601200
  var valid_601201 = header.getOrDefault("X-Amz-Algorithm")
  valid_601201 = validateParameter(valid_601201, JString, required = false,
                                 default = nil)
  if valid_601201 != nil:
    section.add "X-Amz-Algorithm", valid_601201
  var valid_601202 = header.getOrDefault("X-Amz-Signature")
  valid_601202 = validateParameter(valid_601202, JString, required = false,
                                 default = nil)
  if valid_601202 != nil:
    section.add "X-Amz-Signature", valid_601202
  var valid_601203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601203 = validateParameter(valid_601203, JString, required = false,
                                 default = nil)
  if valid_601203 != nil:
    section.add "X-Amz-SignedHeaders", valid_601203
  var valid_601204 = header.getOrDefault("X-Amz-Credential")
  valid_601204 = validateParameter(valid_601204, JString, required = false,
                                 default = nil)
  if valid_601204 != nil:
    section.add "X-Amz-Credential", valid_601204
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601206: Call_CreateSMBFileShare_601194; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Server Message Block (SMB) file share on an existing file gateway. In Storage Gateway, a file share is a file system mount point backed by Amazon S3 cloud storage. Storage Gateway expose file shares using a SMB interface. This operation is only supported for file gateways.</p> <important> <p>File gateways require AWS Security Token Service (AWS STS) to be activated to enable you to create a file share. Make sure that AWS STS is activated in the AWS Region you are creating your file gateway in. If AWS STS is not activated in this AWS Region, activate it. For information about how to activate AWS STS, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_enable-regions.html">Activating and Deactivating AWS STS in an AWS Region</a> in the <i>AWS Identity and Access Management User Guide.</i> </p> <p>File gateways don't support creating hard or symbolic links on a file share.</p> </important>
  ## 
  let valid = call_601206.validator(path, query, header, formData, body)
  let scheme = call_601206.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601206.url(scheme.get, call_601206.host, call_601206.base,
                         call_601206.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601206, url, valid)

proc call*(call_601207: Call_CreateSMBFileShare_601194; body: JsonNode): Recallable =
  ## createSMBFileShare
  ## <p>Creates a Server Message Block (SMB) file share on an existing file gateway. In Storage Gateway, a file share is a file system mount point backed by Amazon S3 cloud storage. Storage Gateway expose file shares using a SMB interface. This operation is only supported for file gateways.</p> <important> <p>File gateways require AWS Security Token Service (AWS STS) to be activated to enable you to create a file share. Make sure that AWS STS is activated in the AWS Region you are creating your file gateway in. If AWS STS is not activated in this AWS Region, activate it. For information about how to activate AWS STS, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_enable-regions.html">Activating and Deactivating AWS STS in an AWS Region</a> in the <i>AWS Identity and Access Management User Guide.</i> </p> <p>File gateways don't support creating hard or symbolic links on a file share.</p> </important>
  ##   body: JObject (required)
  var body_601208 = newJObject()
  if body != nil:
    body_601208 = body
  result = call_601207.call(nil, nil, nil, nil, body_601208)

var createSMBFileShare* = Call_CreateSMBFileShare_601194(
    name: "createSMBFileShare", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.CreateSMBFileShare",
    validator: validate_CreateSMBFileShare_601195, base: "/",
    url: url_CreateSMBFileShare_601196, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSnapshot_601209 = ref object of OpenApiRestCall_600438
proc url_CreateSnapshot_601211(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateSnapshot_601210(path: JsonNode; query: JsonNode;
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
  var valid_601212 = header.getOrDefault("X-Amz-Date")
  valid_601212 = validateParameter(valid_601212, JString, required = false,
                                 default = nil)
  if valid_601212 != nil:
    section.add "X-Amz-Date", valid_601212
  var valid_601213 = header.getOrDefault("X-Amz-Security-Token")
  valid_601213 = validateParameter(valid_601213, JString, required = false,
                                 default = nil)
  if valid_601213 != nil:
    section.add "X-Amz-Security-Token", valid_601213
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601214 = header.getOrDefault("X-Amz-Target")
  valid_601214 = validateParameter(valid_601214, JString, required = true, default = newJString(
      "StorageGateway_20130630.CreateSnapshot"))
  if valid_601214 != nil:
    section.add "X-Amz-Target", valid_601214
  var valid_601215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601215 = validateParameter(valid_601215, JString, required = false,
                                 default = nil)
  if valid_601215 != nil:
    section.add "X-Amz-Content-Sha256", valid_601215
  var valid_601216 = header.getOrDefault("X-Amz-Algorithm")
  valid_601216 = validateParameter(valid_601216, JString, required = false,
                                 default = nil)
  if valid_601216 != nil:
    section.add "X-Amz-Algorithm", valid_601216
  var valid_601217 = header.getOrDefault("X-Amz-Signature")
  valid_601217 = validateParameter(valid_601217, JString, required = false,
                                 default = nil)
  if valid_601217 != nil:
    section.add "X-Amz-Signature", valid_601217
  var valid_601218 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601218 = validateParameter(valid_601218, JString, required = false,
                                 default = nil)
  if valid_601218 != nil:
    section.add "X-Amz-SignedHeaders", valid_601218
  var valid_601219 = header.getOrDefault("X-Amz-Credential")
  valid_601219 = validateParameter(valid_601219, JString, required = false,
                                 default = nil)
  if valid_601219 != nil:
    section.add "X-Amz-Credential", valid_601219
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601221: Call_CreateSnapshot_601209; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates a snapshot of a volume.</p> <p>AWS Storage Gateway provides the ability to back up point-in-time snapshots of your data to Amazon Simple Storage (S3) for durable off-site recovery, as well as import the data to an Amazon Elastic Block Store (EBS) volume in Amazon Elastic Compute Cloud (EC2). You can take snapshots of your gateway volume on a scheduled or ad hoc basis. This API enables you to take ad-hoc snapshot. For more information, see <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/managing-volumes.html#SchedulingSnapshot">Editing a Snapshot Schedule</a>.</p> <p>In the CreateSnapshot request you identify the volume by providing its Amazon Resource Name (ARN). You must also provide description for the snapshot. When AWS Storage Gateway takes the snapshot of specified volume, the snapshot and description appears in the AWS Storage Gateway Console. In response, AWS Storage Gateway returns you a snapshot ID. You can use this snapshot ID to check the snapshot progress or later use it when you want to create a volume from a snapshot. This operation is only supported in stored and cached volume gateway type.</p> <note> <p>To list or delete a snapshot, you must use the Amazon EC2 API. For more information, see DescribeSnapshots or DeleteSnapshot in the <a href="https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_Operations.html">EC2 API reference</a>.</p> </note> <important> <p>Volume and snapshot IDs are changing to a longer length ID format. For more information, see the important note on the <a href="https://docs.aws.amazon.com/storagegateway/latest/APIReference/Welcome.html">Welcome</a> page.</p> </important>
  ## 
  let valid = call_601221.validator(path, query, header, formData, body)
  let scheme = call_601221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601221.url(scheme.get, call_601221.host, call_601221.base,
                         call_601221.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601221, url, valid)

proc call*(call_601222: Call_CreateSnapshot_601209; body: JsonNode): Recallable =
  ## createSnapshot
  ## <p>Initiates a snapshot of a volume.</p> <p>AWS Storage Gateway provides the ability to back up point-in-time snapshots of your data to Amazon Simple Storage (S3) for durable off-site recovery, as well as import the data to an Amazon Elastic Block Store (EBS) volume in Amazon Elastic Compute Cloud (EC2). You can take snapshots of your gateway volume on a scheduled or ad hoc basis. This API enables you to take ad-hoc snapshot. For more information, see <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/managing-volumes.html#SchedulingSnapshot">Editing a Snapshot Schedule</a>.</p> <p>In the CreateSnapshot request you identify the volume by providing its Amazon Resource Name (ARN). You must also provide description for the snapshot. When AWS Storage Gateway takes the snapshot of specified volume, the snapshot and description appears in the AWS Storage Gateway Console. In response, AWS Storage Gateway returns you a snapshot ID. You can use this snapshot ID to check the snapshot progress or later use it when you want to create a volume from a snapshot. This operation is only supported in stored and cached volume gateway type.</p> <note> <p>To list or delete a snapshot, you must use the Amazon EC2 API. For more information, see DescribeSnapshots or DeleteSnapshot in the <a href="https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_Operations.html">EC2 API reference</a>.</p> </note> <important> <p>Volume and snapshot IDs are changing to a longer length ID format. For more information, see the important note on the <a href="https://docs.aws.amazon.com/storagegateway/latest/APIReference/Welcome.html">Welcome</a> page.</p> </important>
  ##   body: JObject (required)
  var body_601223 = newJObject()
  if body != nil:
    body_601223 = body
  result = call_601222.call(nil, nil, nil, nil, body_601223)

var createSnapshot* = Call_CreateSnapshot_601209(name: "createSnapshot",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.CreateSnapshot",
    validator: validate_CreateSnapshot_601210, base: "/", url: url_CreateSnapshot_601211,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSnapshotFromVolumeRecoveryPoint_601224 = ref object of OpenApiRestCall_600438
proc url_CreateSnapshotFromVolumeRecoveryPoint_601226(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateSnapshotFromVolumeRecoveryPoint_601225(path: JsonNode;
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
  var valid_601227 = header.getOrDefault("X-Amz-Date")
  valid_601227 = validateParameter(valid_601227, JString, required = false,
                                 default = nil)
  if valid_601227 != nil:
    section.add "X-Amz-Date", valid_601227
  var valid_601228 = header.getOrDefault("X-Amz-Security-Token")
  valid_601228 = validateParameter(valid_601228, JString, required = false,
                                 default = nil)
  if valid_601228 != nil:
    section.add "X-Amz-Security-Token", valid_601228
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601229 = header.getOrDefault("X-Amz-Target")
  valid_601229 = validateParameter(valid_601229, JString, required = true, default = newJString(
      "StorageGateway_20130630.CreateSnapshotFromVolumeRecoveryPoint"))
  if valid_601229 != nil:
    section.add "X-Amz-Target", valid_601229
  var valid_601230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601230 = validateParameter(valid_601230, JString, required = false,
                                 default = nil)
  if valid_601230 != nil:
    section.add "X-Amz-Content-Sha256", valid_601230
  var valid_601231 = header.getOrDefault("X-Amz-Algorithm")
  valid_601231 = validateParameter(valid_601231, JString, required = false,
                                 default = nil)
  if valid_601231 != nil:
    section.add "X-Amz-Algorithm", valid_601231
  var valid_601232 = header.getOrDefault("X-Amz-Signature")
  valid_601232 = validateParameter(valid_601232, JString, required = false,
                                 default = nil)
  if valid_601232 != nil:
    section.add "X-Amz-Signature", valid_601232
  var valid_601233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601233 = validateParameter(valid_601233, JString, required = false,
                                 default = nil)
  if valid_601233 != nil:
    section.add "X-Amz-SignedHeaders", valid_601233
  var valid_601234 = header.getOrDefault("X-Amz-Credential")
  valid_601234 = validateParameter(valid_601234, JString, required = false,
                                 default = nil)
  if valid_601234 != nil:
    section.add "X-Amz-Credential", valid_601234
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601236: Call_CreateSnapshotFromVolumeRecoveryPoint_601224;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Initiates a snapshot of a gateway from a volume recovery point. This operation is only supported in the cached volume gateway type.</p> <p>A volume recovery point is a point in time at which all data of the volume is consistent and from which you can create a snapshot. To get a list of volume recovery point for cached volume gateway, use <a>ListVolumeRecoveryPoints</a>.</p> <p>In the <code>CreateSnapshotFromVolumeRecoveryPoint</code> request, you identify the volume by providing its Amazon Resource Name (ARN). You must also provide a description for the snapshot. When the gateway takes a snapshot of the specified volume, the snapshot and its description appear in the AWS Storage Gateway console. In response, the gateway returns you a snapshot ID. You can use this snapshot ID to check the snapshot progress or later use it when you want to create a volume from a snapshot.</p> <note> <p>To list or delete a snapshot, you must use the Amazon EC2 API. For more information, in <i>Amazon Elastic Compute Cloud API Reference</i>.</p> </note>
  ## 
  let valid = call_601236.validator(path, query, header, formData, body)
  let scheme = call_601236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601236.url(scheme.get, call_601236.host, call_601236.base,
                         call_601236.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601236, url, valid)

proc call*(call_601237: Call_CreateSnapshotFromVolumeRecoveryPoint_601224;
          body: JsonNode): Recallable =
  ## createSnapshotFromVolumeRecoveryPoint
  ## <p>Initiates a snapshot of a gateway from a volume recovery point. This operation is only supported in the cached volume gateway type.</p> <p>A volume recovery point is a point in time at which all data of the volume is consistent and from which you can create a snapshot. To get a list of volume recovery point for cached volume gateway, use <a>ListVolumeRecoveryPoints</a>.</p> <p>In the <code>CreateSnapshotFromVolumeRecoveryPoint</code> request, you identify the volume by providing its Amazon Resource Name (ARN). You must also provide a description for the snapshot. When the gateway takes a snapshot of the specified volume, the snapshot and its description appear in the AWS Storage Gateway console. In response, the gateway returns you a snapshot ID. You can use this snapshot ID to check the snapshot progress or later use it when you want to create a volume from a snapshot.</p> <note> <p>To list or delete a snapshot, you must use the Amazon EC2 API. For more information, in <i>Amazon Elastic Compute Cloud API Reference</i>.</p> </note>
  ##   body: JObject (required)
  var body_601238 = newJObject()
  if body != nil:
    body_601238 = body
  result = call_601237.call(nil, nil, nil, nil, body_601238)

var createSnapshotFromVolumeRecoveryPoint* = Call_CreateSnapshotFromVolumeRecoveryPoint_601224(
    name: "createSnapshotFromVolumeRecoveryPoint", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com", route: "/#X-Amz-Target=StorageGateway_20130630.CreateSnapshotFromVolumeRecoveryPoint",
    validator: validate_CreateSnapshotFromVolumeRecoveryPoint_601225, base: "/",
    url: url_CreateSnapshotFromVolumeRecoveryPoint_601226,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStorediSCSIVolume_601239 = ref object of OpenApiRestCall_600438
proc url_CreateStorediSCSIVolume_601241(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateStorediSCSIVolume_601240(path: JsonNode; query: JsonNode;
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
  var valid_601242 = header.getOrDefault("X-Amz-Date")
  valid_601242 = validateParameter(valid_601242, JString, required = false,
                                 default = nil)
  if valid_601242 != nil:
    section.add "X-Amz-Date", valid_601242
  var valid_601243 = header.getOrDefault("X-Amz-Security-Token")
  valid_601243 = validateParameter(valid_601243, JString, required = false,
                                 default = nil)
  if valid_601243 != nil:
    section.add "X-Amz-Security-Token", valid_601243
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601244 = header.getOrDefault("X-Amz-Target")
  valid_601244 = validateParameter(valid_601244, JString, required = true, default = newJString(
      "StorageGateway_20130630.CreateStorediSCSIVolume"))
  if valid_601244 != nil:
    section.add "X-Amz-Target", valid_601244
  var valid_601245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601245 = validateParameter(valid_601245, JString, required = false,
                                 default = nil)
  if valid_601245 != nil:
    section.add "X-Amz-Content-Sha256", valid_601245
  var valid_601246 = header.getOrDefault("X-Amz-Algorithm")
  valid_601246 = validateParameter(valid_601246, JString, required = false,
                                 default = nil)
  if valid_601246 != nil:
    section.add "X-Amz-Algorithm", valid_601246
  var valid_601247 = header.getOrDefault("X-Amz-Signature")
  valid_601247 = validateParameter(valid_601247, JString, required = false,
                                 default = nil)
  if valid_601247 != nil:
    section.add "X-Amz-Signature", valid_601247
  var valid_601248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601248 = validateParameter(valid_601248, JString, required = false,
                                 default = nil)
  if valid_601248 != nil:
    section.add "X-Amz-SignedHeaders", valid_601248
  var valid_601249 = header.getOrDefault("X-Amz-Credential")
  valid_601249 = validateParameter(valid_601249, JString, required = false,
                                 default = nil)
  if valid_601249 != nil:
    section.add "X-Amz-Credential", valid_601249
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601251: Call_CreateStorediSCSIVolume_601239; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a volume on a specified gateway. This operation is only supported in the stored volume gateway type.</p> <p>The size of the volume to create is inferred from the disk size. You can choose to preserve existing data on the disk, create volume from an existing snapshot, or create an empty volume. If you choose to create an empty gateway volume, then any existing data on the disk is erased.</p> <p>In the request you must specify the gateway and the disk information on which you are creating the volume. In response, the gateway creates the volume and returns volume information such as the volume Amazon Resource Name (ARN), its size, and the iSCSI target ARN that initiators can use to connect to the volume target.</p>
  ## 
  let valid = call_601251.validator(path, query, header, formData, body)
  let scheme = call_601251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601251.url(scheme.get, call_601251.host, call_601251.base,
                         call_601251.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601251, url, valid)

proc call*(call_601252: Call_CreateStorediSCSIVolume_601239; body: JsonNode): Recallable =
  ## createStorediSCSIVolume
  ## <p>Creates a volume on a specified gateway. This operation is only supported in the stored volume gateway type.</p> <p>The size of the volume to create is inferred from the disk size. You can choose to preserve existing data on the disk, create volume from an existing snapshot, or create an empty volume. If you choose to create an empty gateway volume, then any existing data on the disk is erased.</p> <p>In the request you must specify the gateway and the disk information on which you are creating the volume. In response, the gateway creates the volume and returns volume information such as the volume Amazon Resource Name (ARN), its size, and the iSCSI target ARN that initiators can use to connect to the volume target.</p>
  ##   body: JObject (required)
  var body_601253 = newJObject()
  if body != nil:
    body_601253 = body
  result = call_601252.call(nil, nil, nil, nil, body_601253)

var createStorediSCSIVolume* = Call_CreateStorediSCSIVolume_601239(
    name: "createStorediSCSIVolume", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.CreateStorediSCSIVolume",
    validator: validate_CreateStorediSCSIVolume_601240, base: "/",
    url: url_CreateStorediSCSIVolume_601241, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTapeWithBarcode_601254 = ref object of OpenApiRestCall_600438
proc url_CreateTapeWithBarcode_601256(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateTapeWithBarcode_601255(path: JsonNode; query: JsonNode;
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
  var valid_601257 = header.getOrDefault("X-Amz-Date")
  valid_601257 = validateParameter(valid_601257, JString, required = false,
                                 default = nil)
  if valid_601257 != nil:
    section.add "X-Amz-Date", valid_601257
  var valid_601258 = header.getOrDefault("X-Amz-Security-Token")
  valid_601258 = validateParameter(valid_601258, JString, required = false,
                                 default = nil)
  if valid_601258 != nil:
    section.add "X-Amz-Security-Token", valid_601258
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601259 = header.getOrDefault("X-Amz-Target")
  valid_601259 = validateParameter(valid_601259, JString, required = true, default = newJString(
      "StorageGateway_20130630.CreateTapeWithBarcode"))
  if valid_601259 != nil:
    section.add "X-Amz-Target", valid_601259
  var valid_601260 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601260 = validateParameter(valid_601260, JString, required = false,
                                 default = nil)
  if valid_601260 != nil:
    section.add "X-Amz-Content-Sha256", valid_601260
  var valid_601261 = header.getOrDefault("X-Amz-Algorithm")
  valid_601261 = validateParameter(valid_601261, JString, required = false,
                                 default = nil)
  if valid_601261 != nil:
    section.add "X-Amz-Algorithm", valid_601261
  var valid_601262 = header.getOrDefault("X-Amz-Signature")
  valid_601262 = validateParameter(valid_601262, JString, required = false,
                                 default = nil)
  if valid_601262 != nil:
    section.add "X-Amz-Signature", valid_601262
  var valid_601263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601263 = validateParameter(valid_601263, JString, required = false,
                                 default = nil)
  if valid_601263 != nil:
    section.add "X-Amz-SignedHeaders", valid_601263
  var valid_601264 = header.getOrDefault("X-Amz-Credential")
  valid_601264 = validateParameter(valid_601264, JString, required = false,
                                 default = nil)
  if valid_601264 != nil:
    section.add "X-Amz-Credential", valid_601264
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601266: Call_CreateTapeWithBarcode_601254; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a virtual tape by using your own barcode. You write data to the virtual tape and then archive the tape. A barcode is unique and can not be reused if it has already been used on a tape . This applies to barcodes used on deleted tapes. This operation is only supported in the tape gateway type.</p> <note> <p>Cache storage must be allocated to the gateway before you can create a virtual tape. Use the <a>AddCache</a> operation to add cache storage to a gateway.</p> </note>
  ## 
  let valid = call_601266.validator(path, query, header, formData, body)
  let scheme = call_601266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601266.url(scheme.get, call_601266.host, call_601266.base,
                         call_601266.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601266, url, valid)

proc call*(call_601267: Call_CreateTapeWithBarcode_601254; body: JsonNode): Recallable =
  ## createTapeWithBarcode
  ## <p>Creates a virtual tape by using your own barcode. You write data to the virtual tape and then archive the tape. A barcode is unique and can not be reused if it has already been used on a tape . This applies to barcodes used on deleted tapes. This operation is only supported in the tape gateway type.</p> <note> <p>Cache storage must be allocated to the gateway before you can create a virtual tape. Use the <a>AddCache</a> operation to add cache storage to a gateway.</p> </note>
  ##   body: JObject (required)
  var body_601268 = newJObject()
  if body != nil:
    body_601268 = body
  result = call_601267.call(nil, nil, nil, nil, body_601268)

var createTapeWithBarcode* = Call_CreateTapeWithBarcode_601254(
    name: "createTapeWithBarcode", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.CreateTapeWithBarcode",
    validator: validate_CreateTapeWithBarcode_601255, base: "/",
    url: url_CreateTapeWithBarcode_601256, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTapes_601269 = ref object of OpenApiRestCall_600438
proc url_CreateTapes_601271(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateTapes_601270(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601272 = header.getOrDefault("X-Amz-Date")
  valid_601272 = validateParameter(valid_601272, JString, required = false,
                                 default = nil)
  if valid_601272 != nil:
    section.add "X-Amz-Date", valid_601272
  var valid_601273 = header.getOrDefault("X-Amz-Security-Token")
  valid_601273 = validateParameter(valid_601273, JString, required = false,
                                 default = nil)
  if valid_601273 != nil:
    section.add "X-Amz-Security-Token", valid_601273
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601274 = header.getOrDefault("X-Amz-Target")
  valid_601274 = validateParameter(valid_601274, JString, required = true, default = newJString(
      "StorageGateway_20130630.CreateTapes"))
  if valid_601274 != nil:
    section.add "X-Amz-Target", valid_601274
  var valid_601275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601275 = validateParameter(valid_601275, JString, required = false,
                                 default = nil)
  if valid_601275 != nil:
    section.add "X-Amz-Content-Sha256", valid_601275
  var valid_601276 = header.getOrDefault("X-Amz-Algorithm")
  valid_601276 = validateParameter(valid_601276, JString, required = false,
                                 default = nil)
  if valid_601276 != nil:
    section.add "X-Amz-Algorithm", valid_601276
  var valid_601277 = header.getOrDefault("X-Amz-Signature")
  valid_601277 = validateParameter(valid_601277, JString, required = false,
                                 default = nil)
  if valid_601277 != nil:
    section.add "X-Amz-Signature", valid_601277
  var valid_601278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601278 = validateParameter(valid_601278, JString, required = false,
                                 default = nil)
  if valid_601278 != nil:
    section.add "X-Amz-SignedHeaders", valid_601278
  var valid_601279 = header.getOrDefault("X-Amz-Credential")
  valid_601279 = validateParameter(valid_601279, JString, required = false,
                                 default = nil)
  if valid_601279 != nil:
    section.add "X-Amz-Credential", valid_601279
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601281: Call_CreateTapes_601269; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates one or more virtual tapes. You write data to the virtual tapes and then archive the tapes. This operation is only supported in the tape gateway type.</p> <note> <p>Cache storage must be allocated to the gateway before you can create virtual tapes. Use the <a>AddCache</a> operation to add cache storage to a gateway. </p> </note>
  ## 
  let valid = call_601281.validator(path, query, header, formData, body)
  let scheme = call_601281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601281.url(scheme.get, call_601281.host, call_601281.base,
                         call_601281.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601281, url, valid)

proc call*(call_601282: Call_CreateTapes_601269; body: JsonNode): Recallable =
  ## createTapes
  ## <p>Creates one or more virtual tapes. You write data to the virtual tapes and then archive the tapes. This operation is only supported in the tape gateway type.</p> <note> <p>Cache storage must be allocated to the gateway before you can create virtual tapes. Use the <a>AddCache</a> operation to add cache storage to a gateway. </p> </note>
  ##   body: JObject (required)
  var body_601283 = newJObject()
  if body != nil:
    body_601283 = body
  result = call_601282.call(nil, nil, nil, nil, body_601283)

var createTapes* = Call_CreateTapes_601269(name: "createTapes",
                                        meth: HttpMethod.HttpPost,
                                        host: "storagegateway.amazonaws.com", route: "/#X-Amz-Target=StorageGateway_20130630.CreateTapes",
                                        validator: validate_CreateTapes_601270,
                                        base: "/", url: url_CreateTapes_601271,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBandwidthRateLimit_601284 = ref object of OpenApiRestCall_600438
proc url_DeleteBandwidthRateLimit_601286(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteBandwidthRateLimit_601285(path: JsonNode; query: JsonNode;
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
  var valid_601287 = header.getOrDefault("X-Amz-Date")
  valid_601287 = validateParameter(valid_601287, JString, required = false,
                                 default = nil)
  if valid_601287 != nil:
    section.add "X-Amz-Date", valid_601287
  var valid_601288 = header.getOrDefault("X-Amz-Security-Token")
  valid_601288 = validateParameter(valid_601288, JString, required = false,
                                 default = nil)
  if valid_601288 != nil:
    section.add "X-Amz-Security-Token", valid_601288
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601289 = header.getOrDefault("X-Amz-Target")
  valid_601289 = validateParameter(valid_601289, JString, required = true, default = newJString(
      "StorageGateway_20130630.DeleteBandwidthRateLimit"))
  if valid_601289 != nil:
    section.add "X-Amz-Target", valid_601289
  var valid_601290 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601290 = validateParameter(valid_601290, JString, required = false,
                                 default = nil)
  if valid_601290 != nil:
    section.add "X-Amz-Content-Sha256", valid_601290
  var valid_601291 = header.getOrDefault("X-Amz-Algorithm")
  valid_601291 = validateParameter(valid_601291, JString, required = false,
                                 default = nil)
  if valid_601291 != nil:
    section.add "X-Amz-Algorithm", valid_601291
  var valid_601292 = header.getOrDefault("X-Amz-Signature")
  valid_601292 = validateParameter(valid_601292, JString, required = false,
                                 default = nil)
  if valid_601292 != nil:
    section.add "X-Amz-Signature", valid_601292
  var valid_601293 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601293 = validateParameter(valid_601293, JString, required = false,
                                 default = nil)
  if valid_601293 != nil:
    section.add "X-Amz-SignedHeaders", valid_601293
  var valid_601294 = header.getOrDefault("X-Amz-Credential")
  valid_601294 = validateParameter(valid_601294, JString, required = false,
                                 default = nil)
  if valid_601294 != nil:
    section.add "X-Amz-Credential", valid_601294
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601296: Call_DeleteBandwidthRateLimit_601284; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the bandwidth rate limits of a gateway. You can delete either the upload and download bandwidth rate limit, or you can delete both. If you delete only one of the limits, the other limit remains unchanged. To specify which gateway to work with, use the Amazon Resource Name (ARN) of the gateway in your request.
  ## 
  let valid = call_601296.validator(path, query, header, formData, body)
  let scheme = call_601296.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601296.url(scheme.get, call_601296.host, call_601296.base,
                         call_601296.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601296, url, valid)

proc call*(call_601297: Call_DeleteBandwidthRateLimit_601284; body: JsonNode): Recallable =
  ## deleteBandwidthRateLimit
  ## Deletes the bandwidth rate limits of a gateway. You can delete either the upload and download bandwidth rate limit, or you can delete both. If you delete only one of the limits, the other limit remains unchanged. To specify which gateway to work with, use the Amazon Resource Name (ARN) of the gateway in your request.
  ##   body: JObject (required)
  var body_601298 = newJObject()
  if body != nil:
    body_601298 = body
  result = call_601297.call(nil, nil, nil, nil, body_601298)

var deleteBandwidthRateLimit* = Call_DeleteBandwidthRateLimit_601284(
    name: "deleteBandwidthRateLimit", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DeleteBandwidthRateLimit",
    validator: validate_DeleteBandwidthRateLimit_601285, base: "/",
    url: url_DeleteBandwidthRateLimit_601286, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteChapCredentials_601299 = ref object of OpenApiRestCall_600438
proc url_DeleteChapCredentials_601301(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteChapCredentials_601300(path: JsonNode; query: JsonNode;
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
  var valid_601302 = header.getOrDefault("X-Amz-Date")
  valid_601302 = validateParameter(valid_601302, JString, required = false,
                                 default = nil)
  if valid_601302 != nil:
    section.add "X-Amz-Date", valid_601302
  var valid_601303 = header.getOrDefault("X-Amz-Security-Token")
  valid_601303 = validateParameter(valid_601303, JString, required = false,
                                 default = nil)
  if valid_601303 != nil:
    section.add "X-Amz-Security-Token", valid_601303
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601304 = header.getOrDefault("X-Amz-Target")
  valid_601304 = validateParameter(valid_601304, JString, required = true, default = newJString(
      "StorageGateway_20130630.DeleteChapCredentials"))
  if valid_601304 != nil:
    section.add "X-Amz-Target", valid_601304
  var valid_601305 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601305 = validateParameter(valid_601305, JString, required = false,
                                 default = nil)
  if valid_601305 != nil:
    section.add "X-Amz-Content-Sha256", valid_601305
  var valid_601306 = header.getOrDefault("X-Amz-Algorithm")
  valid_601306 = validateParameter(valid_601306, JString, required = false,
                                 default = nil)
  if valid_601306 != nil:
    section.add "X-Amz-Algorithm", valid_601306
  var valid_601307 = header.getOrDefault("X-Amz-Signature")
  valid_601307 = validateParameter(valid_601307, JString, required = false,
                                 default = nil)
  if valid_601307 != nil:
    section.add "X-Amz-Signature", valid_601307
  var valid_601308 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601308 = validateParameter(valid_601308, JString, required = false,
                                 default = nil)
  if valid_601308 != nil:
    section.add "X-Amz-SignedHeaders", valid_601308
  var valid_601309 = header.getOrDefault("X-Amz-Credential")
  valid_601309 = validateParameter(valid_601309, JString, required = false,
                                 default = nil)
  if valid_601309 != nil:
    section.add "X-Amz-Credential", valid_601309
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601311: Call_DeleteChapCredentials_601299; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes Challenge-Handshake Authentication Protocol (CHAP) credentials for a specified iSCSI target and initiator pair.
  ## 
  let valid = call_601311.validator(path, query, header, formData, body)
  let scheme = call_601311.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601311.url(scheme.get, call_601311.host, call_601311.base,
                         call_601311.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601311, url, valid)

proc call*(call_601312: Call_DeleteChapCredentials_601299; body: JsonNode): Recallable =
  ## deleteChapCredentials
  ## Deletes Challenge-Handshake Authentication Protocol (CHAP) credentials for a specified iSCSI target and initiator pair.
  ##   body: JObject (required)
  var body_601313 = newJObject()
  if body != nil:
    body_601313 = body
  result = call_601312.call(nil, nil, nil, nil, body_601313)

var deleteChapCredentials* = Call_DeleteChapCredentials_601299(
    name: "deleteChapCredentials", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DeleteChapCredentials",
    validator: validate_DeleteChapCredentials_601300, base: "/",
    url: url_DeleteChapCredentials_601301, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFileShare_601314 = ref object of OpenApiRestCall_600438
proc url_DeleteFileShare_601316(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteFileShare_601315(path: JsonNode; query: JsonNode;
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
  var valid_601317 = header.getOrDefault("X-Amz-Date")
  valid_601317 = validateParameter(valid_601317, JString, required = false,
                                 default = nil)
  if valid_601317 != nil:
    section.add "X-Amz-Date", valid_601317
  var valid_601318 = header.getOrDefault("X-Amz-Security-Token")
  valid_601318 = validateParameter(valid_601318, JString, required = false,
                                 default = nil)
  if valid_601318 != nil:
    section.add "X-Amz-Security-Token", valid_601318
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601319 = header.getOrDefault("X-Amz-Target")
  valid_601319 = validateParameter(valid_601319, JString, required = true, default = newJString(
      "StorageGateway_20130630.DeleteFileShare"))
  if valid_601319 != nil:
    section.add "X-Amz-Target", valid_601319
  var valid_601320 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601320 = validateParameter(valid_601320, JString, required = false,
                                 default = nil)
  if valid_601320 != nil:
    section.add "X-Amz-Content-Sha256", valid_601320
  var valid_601321 = header.getOrDefault("X-Amz-Algorithm")
  valid_601321 = validateParameter(valid_601321, JString, required = false,
                                 default = nil)
  if valid_601321 != nil:
    section.add "X-Amz-Algorithm", valid_601321
  var valid_601322 = header.getOrDefault("X-Amz-Signature")
  valid_601322 = validateParameter(valid_601322, JString, required = false,
                                 default = nil)
  if valid_601322 != nil:
    section.add "X-Amz-Signature", valid_601322
  var valid_601323 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601323 = validateParameter(valid_601323, JString, required = false,
                                 default = nil)
  if valid_601323 != nil:
    section.add "X-Amz-SignedHeaders", valid_601323
  var valid_601324 = header.getOrDefault("X-Amz-Credential")
  valid_601324 = validateParameter(valid_601324, JString, required = false,
                                 default = nil)
  if valid_601324 != nil:
    section.add "X-Amz-Credential", valid_601324
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601326: Call_DeleteFileShare_601314; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a file share from a file gateway. This operation is only supported for file gateways.
  ## 
  let valid = call_601326.validator(path, query, header, formData, body)
  let scheme = call_601326.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601326.url(scheme.get, call_601326.host, call_601326.base,
                         call_601326.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601326, url, valid)

proc call*(call_601327: Call_DeleteFileShare_601314; body: JsonNode): Recallable =
  ## deleteFileShare
  ## Deletes a file share from a file gateway. This operation is only supported for file gateways.
  ##   body: JObject (required)
  var body_601328 = newJObject()
  if body != nil:
    body_601328 = body
  result = call_601327.call(nil, nil, nil, nil, body_601328)

var deleteFileShare* = Call_DeleteFileShare_601314(name: "deleteFileShare",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DeleteFileShare",
    validator: validate_DeleteFileShare_601315, base: "/", url: url_DeleteFileShare_601316,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGateway_601329 = ref object of OpenApiRestCall_600438
proc url_DeleteGateway_601331(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteGateway_601330(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601332 = header.getOrDefault("X-Amz-Date")
  valid_601332 = validateParameter(valid_601332, JString, required = false,
                                 default = nil)
  if valid_601332 != nil:
    section.add "X-Amz-Date", valid_601332
  var valid_601333 = header.getOrDefault("X-Amz-Security-Token")
  valid_601333 = validateParameter(valid_601333, JString, required = false,
                                 default = nil)
  if valid_601333 != nil:
    section.add "X-Amz-Security-Token", valid_601333
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601334 = header.getOrDefault("X-Amz-Target")
  valid_601334 = validateParameter(valid_601334, JString, required = true, default = newJString(
      "StorageGateway_20130630.DeleteGateway"))
  if valid_601334 != nil:
    section.add "X-Amz-Target", valid_601334
  var valid_601335 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601335 = validateParameter(valid_601335, JString, required = false,
                                 default = nil)
  if valid_601335 != nil:
    section.add "X-Amz-Content-Sha256", valid_601335
  var valid_601336 = header.getOrDefault("X-Amz-Algorithm")
  valid_601336 = validateParameter(valid_601336, JString, required = false,
                                 default = nil)
  if valid_601336 != nil:
    section.add "X-Amz-Algorithm", valid_601336
  var valid_601337 = header.getOrDefault("X-Amz-Signature")
  valid_601337 = validateParameter(valid_601337, JString, required = false,
                                 default = nil)
  if valid_601337 != nil:
    section.add "X-Amz-Signature", valid_601337
  var valid_601338 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601338 = validateParameter(valid_601338, JString, required = false,
                                 default = nil)
  if valid_601338 != nil:
    section.add "X-Amz-SignedHeaders", valid_601338
  var valid_601339 = header.getOrDefault("X-Amz-Credential")
  valid_601339 = validateParameter(valid_601339, JString, required = false,
                                 default = nil)
  if valid_601339 != nil:
    section.add "X-Amz-Credential", valid_601339
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601341: Call_DeleteGateway_601329; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a gateway. To specify which gateway to delete, use the Amazon Resource Name (ARN) of the gateway in your request. The operation deletes the gateway; however, it does not delete the gateway virtual machine (VM) from your host computer.</p> <p>After you delete a gateway, you cannot reactivate it. Completed snapshots of the gateway volumes are not deleted upon deleting the gateway, however, pending snapshots will not complete. After you delete a gateway, your next step is to remove it from your environment.</p> <important> <p>You no longer pay software charges after the gateway is deleted; however, your existing Amazon EBS snapshots persist and you will continue to be billed for these snapshots. You can choose to remove all remaining Amazon EBS snapshots by canceling your Amazon EC2 subscription.  If you prefer not to cancel your Amazon EC2 subscription, you can delete your snapshots using the Amazon EC2 console. For more information, see the <a href="http://aws.amazon.com/storagegateway"> AWS Storage Gateway Detail Page</a>. </p> </important>
  ## 
  let valid = call_601341.validator(path, query, header, formData, body)
  let scheme = call_601341.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601341.url(scheme.get, call_601341.host, call_601341.base,
                         call_601341.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601341, url, valid)

proc call*(call_601342: Call_DeleteGateway_601329; body: JsonNode): Recallable =
  ## deleteGateway
  ## <p>Deletes a gateway. To specify which gateway to delete, use the Amazon Resource Name (ARN) of the gateway in your request. The operation deletes the gateway; however, it does not delete the gateway virtual machine (VM) from your host computer.</p> <p>After you delete a gateway, you cannot reactivate it. Completed snapshots of the gateway volumes are not deleted upon deleting the gateway, however, pending snapshots will not complete. After you delete a gateway, your next step is to remove it from your environment.</p> <important> <p>You no longer pay software charges after the gateway is deleted; however, your existing Amazon EBS snapshots persist and you will continue to be billed for these snapshots. You can choose to remove all remaining Amazon EBS snapshots by canceling your Amazon EC2 subscription.  If you prefer not to cancel your Amazon EC2 subscription, you can delete your snapshots using the Amazon EC2 console. For more information, see the <a href="http://aws.amazon.com/storagegateway"> AWS Storage Gateway Detail Page</a>. </p> </important>
  ##   body: JObject (required)
  var body_601343 = newJObject()
  if body != nil:
    body_601343 = body
  result = call_601342.call(nil, nil, nil, nil, body_601343)

var deleteGateway* = Call_DeleteGateway_601329(name: "deleteGateway",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DeleteGateway",
    validator: validate_DeleteGateway_601330, base: "/", url: url_DeleteGateway_601331,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSnapshotSchedule_601344 = ref object of OpenApiRestCall_600438
proc url_DeleteSnapshotSchedule_601346(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteSnapshotSchedule_601345(path: JsonNode; query: JsonNode;
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
  var valid_601347 = header.getOrDefault("X-Amz-Date")
  valid_601347 = validateParameter(valid_601347, JString, required = false,
                                 default = nil)
  if valid_601347 != nil:
    section.add "X-Amz-Date", valid_601347
  var valid_601348 = header.getOrDefault("X-Amz-Security-Token")
  valid_601348 = validateParameter(valid_601348, JString, required = false,
                                 default = nil)
  if valid_601348 != nil:
    section.add "X-Amz-Security-Token", valid_601348
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601349 = header.getOrDefault("X-Amz-Target")
  valid_601349 = validateParameter(valid_601349, JString, required = true, default = newJString(
      "StorageGateway_20130630.DeleteSnapshotSchedule"))
  if valid_601349 != nil:
    section.add "X-Amz-Target", valid_601349
  var valid_601350 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601350 = validateParameter(valid_601350, JString, required = false,
                                 default = nil)
  if valid_601350 != nil:
    section.add "X-Amz-Content-Sha256", valid_601350
  var valid_601351 = header.getOrDefault("X-Amz-Algorithm")
  valid_601351 = validateParameter(valid_601351, JString, required = false,
                                 default = nil)
  if valid_601351 != nil:
    section.add "X-Amz-Algorithm", valid_601351
  var valid_601352 = header.getOrDefault("X-Amz-Signature")
  valid_601352 = validateParameter(valid_601352, JString, required = false,
                                 default = nil)
  if valid_601352 != nil:
    section.add "X-Amz-Signature", valid_601352
  var valid_601353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601353 = validateParameter(valid_601353, JString, required = false,
                                 default = nil)
  if valid_601353 != nil:
    section.add "X-Amz-SignedHeaders", valid_601353
  var valid_601354 = header.getOrDefault("X-Amz-Credential")
  valid_601354 = validateParameter(valid_601354, JString, required = false,
                                 default = nil)
  if valid_601354 != nil:
    section.add "X-Amz-Credential", valid_601354
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601356: Call_DeleteSnapshotSchedule_601344; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a snapshot of a volume.</p> <p>You can take snapshots of your gateway volumes on a scheduled or ad hoc basis. This API action enables you to delete a snapshot schedule for a volume. For more information, see <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/WorkingWithSnapshots.html">Working with Snapshots</a>. In the <code>DeleteSnapshotSchedule</code> request, you identify the volume by providing its Amazon Resource Name (ARN). This operation is only supported in stored and cached volume gateway types.</p> <note> <p>To list or delete a snapshot, you must use the Amazon EC2 API. in <i>Amazon Elastic Compute Cloud API Reference</i>.</p> </note>
  ## 
  let valid = call_601356.validator(path, query, header, formData, body)
  let scheme = call_601356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601356.url(scheme.get, call_601356.host, call_601356.base,
                         call_601356.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601356, url, valid)

proc call*(call_601357: Call_DeleteSnapshotSchedule_601344; body: JsonNode): Recallable =
  ## deleteSnapshotSchedule
  ## <p>Deletes a snapshot of a volume.</p> <p>You can take snapshots of your gateway volumes on a scheduled or ad hoc basis. This API action enables you to delete a snapshot schedule for a volume. For more information, see <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/WorkingWithSnapshots.html">Working with Snapshots</a>. In the <code>DeleteSnapshotSchedule</code> request, you identify the volume by providing its Amazon Resource Name (ARN). This operation is only supported in stored and cached volume gateway types.</p> <note> <p>To list or delete a snapshot, you must use the Amazon EC2 API. in <i>Amazon Elastic Compute Cloud API Reference</i>.</p> </note>
  ##   body: JObject (required)
  var body_601358 = newJObject()
  if body != nil:
    body_601358 = body
  result = call_601357.call(nil, nil, nil, nil, body_601358)

var deleteSnapshotSchedule* = Call_DeleteSnapshotSchedule_601344(
    name: "deleteSnapshotSchedule", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DeleteSnapshotSchedule",
    validator: validate_DeleteSnapshotSchedule_601345, base: "/",
    url: url_DeleteSnapshotSchedule_601346, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTape_601359 = ref object of OpenApiRestCall_600438
proc url_DeleteTape_601361(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteTape_601360(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601362 = header.getOrDefault("X-Amz-Date")
  valid_601362 = validateParameter(valid_601362, JString, required = false,
                                 default = nil)
  if valid_601362 != nil:
    section.add "X-Amz-Date", valid_601362
  var valid_601363 = header.getOrDefault("X-Amz-Security-Token")
  valid_601363 = validateParameter(valid_601363, JString, required = false,
                                 default = nil)
  if valid_601363 != nil:
    section.add "X-Amz-Security-Token", valid_601363
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601364 = header.getOrDefault("X-Amz-Target")
  valid_601364 = validateParameter(valid_601364, JString, required = true, default = newJString(
      "StorageGateway_20130630.DeleteTape"))
  if valid_601364 != nil:
    section.add "X-Amz-Target", valid_601364
  var valid_601365 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601365 = validateParameter(valid_601365, JString, required = false,
                                 default = nil)
  if valid_601365 != nil:
    section.add "X-Amz-Content-Sha256", valid_601365
  var valid_601366 = header.getOrDefault("X-Amz-Algorithm")
  valid_601366 = validateParameter(valid_601366, JString, required = false,
                                 default = nil)
  if valid_601366 != nil:
    section.add "X-Amz-Algorithm", valid_601366
  var valid_601367 = header.getOrDefault("X-Amz-Signature")
  valid_601367 = validateParameter(valid_601367, JString, required = false,
                                 default = nil)
  if valid_601367 != nil:
    section.add "X-Amz-Signature", valid_601367
  var valid_601368 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601368 = validateParameter(valid_601368, JString, required = false,
                                 default = nil)
  if valid_601368 != nil:
    section.add "X-Amz-SignedHeaders", valid_601368
  var valid_601369 = header.getOrDefault("X-Amz-Credential")
  valid_601369 = validateParameter(valid_601369, JString, required = false,
                                 default = nil)
  if valid_601369 != nil:
    section.add "X-Amz-Credential", valid_601369
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601371: Call_DeleteTape_601359; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified virtual tape. This operation is only supported in the tape gateway type.
  ## 
  let valid = call_601371.validator(path, query, header, formData, body)
  let scheme = call_601371.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601371.url(scheme.get, call_601371.host, call_601371.base,
                         call_601371.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601371, url, valid)

proc call*(call_601372: Call_DeleteTape_601359; body: JsonNode): Recallable =
  ## deleteTape
  ## Deletes the specified virtual tape. This operation is only supported in the tape gateway type.
  ##   body: JObject (required)
  var body_601373 = newJObject()
  if body != nil:
    body_601373 = body
  result = call_601372.call(nil, nil, nil, nil, body_601373)

var deleteTape* = Call_DeleteTape_601359(name: "deleteTape",
                                      meth: HttpMethod.HttpPost,
                                      host: "storagegateway.amazonaws.com", route: "/#X-Amz-Target=StorageGateway_20130630.DeleteTape",
                                      validator: validate_DeleteTape_601360,
                                      base: "/", url: url_DeleteTape_601361,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTapeArchive_601374 = ref object of OpenApiRestCall_600438
proc url_DeleteTapeArchive_601376(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteTapeArchive_601375(path: JsonNode; query: JsonNode;
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
  var valid_601377 = header.getOrDefault("X-Amz-Date")
  valid_601377 = validateParameter(valid_601377, JString, required = false,
                                 default = nil)
  if valid_601377 != nil:
    section.add "X-Amz-Date", valid_601377
  var valid_601378 = header.getOrDefault("X-Amz-Security-Token")
  valid_601378 = validateParameter(valid_601378, JString, required = false,
                                 default = nil)
  if valid_601378 != nil:
    section.add "X-Amz-Security-Token", valid_601378
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601379 = header.getOrDefault("X-Amz-Target")
  valid_601379 = validateParameter(valid_601379, JString, required = true, default = newJString(
      "StorageGateway_20130630.DeleteTapeArchive"))
  if valid_601379 != nil:
    section.add "X-Amz-Target", valid_601379
  var valid_601380 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601380 = validateParameter(valid_601380, JString, required = false,
                                 default = nil)
  if valid_601380 != nil:
    section.add "X-Amz-Content-Sha256", valid_601380
  var valid_601381 = header.getOrDefault("X-Amz-Algorithm")
  valid_601381 = validateParameter(valid_601381, JString, required = false,
                                 default = nil)
  if valid_601381 != nil:
    section.add "X-Amz-Algorithm", valid_601381
  var valid_601382 = header.getOrDefault("X-Amz-Signature")
  valid_601382 = validateParameter(valid_601382, JString, required = false,
                                 default = nil)
  if valid_601382 != nil:
    section.add "X-Amz-Signature", valid_601382
  var valid_601383 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601383 = validateParameter(valid_601383, JString, required = false,
                                 default = nil)
  if valid_601383 != nil:
    section.add "X-Amz-SignedHeaders", valid_601383
  var valid_601384 = header.getOrDefault("X-Amz-Credential")
  valid_601384 = validateParameter(valid_601384, JString, required = false,
                                 default = nil)
  if valid_601384 != nil:
    section.add "X-Amz-Credential", valid_601384
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601386: Call_DeleteTapeArchive_601374; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified virtual tape from the virtual tape shelf (VTS). This operation is only supported in the tape gateway type.
  ## 
  let valid = call_601386.validator(path, query, header, formData, body)
  let scheme = call_601386.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601386.url(scheme.get, call_601386.host, call_601386.base,
                         call_601386.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601386, url, valid)

proc call*(call_601387: Call_DeleteTapeArchive_601374; body: JsonNode): Recallable =
  ## deleteTapeArchive
  ## Deletes the specified virtual tape from the virtual tape shelf (VTS). This operation is only supported in the tape gateway type.
  ##   body: JObject (required)
  var body_601388 = newJObject()
  if body != nil:
    body_601388 = body
  result = call_601387.call(nil, nil, nil, nil, body_601388)

var deleteTapeArchive* = Call_DeleteTapeArchive_601374(name: "deleteTapeArchive",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DeleteTapeArchive",
    validator: validate_DeleteTapeArchive_601375, base: "/",
    url: url_DeleteTapeArchive_601376, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVolume_601389 = ref object of OpenApiRestCall_600438
proc url_DeleteVolume_601391(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteVolume_601390(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601392 = header.getOrDefault("X-Amz-Date")
  valid_601392 = validateParameter(valid_601392, JString, required = false,
                                 default = nil)
  if valid_601392 != nil:
    section.add "X-Amz-Date", valid_601392
  var valid_601393 = header.getOrDefault("X-Amz-Security-Token")
  valid_601393 = validateParameter(valid_601393, JString, required = false,
                                 default = nil)
  if valid_601393 != nil:
    section.add "X-Amz-Security-Token", valid_601393
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601394 = header.getOrDefault("X-Amz-Target")
  valid_601394 = validateParameter(valid_601394, JString, required = true, default = newJString(
      "StorageGateway_20130630.DeleteVolume"))
  if valid_601394 != nil:
    section.add "X-Amz-Target", valid_601394
  var valid_601395 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601395 = validateParameter(valid_601395, JString, required = false,
                                 default = nil)
  if valid_601395 != nil:
    section.add "X-Amz-Content-Sha256", valid_601395
  var valid_601396 = header.getOrDefault("X-Amz-Algorithm")
  valid_601396 = validateParameter(valid_601396, JString, required = false,
                                 default = nil)
  if valid_601396 != nil:
    section.add "X-Amz-Algorithm", valid_601396
  var valid_601397 = header.getOrDefault("X-Amz-Signature")
  valid_601397 = validateParameter(valid_601397, JString, required = false,
                                 default = nil)
  if valid_601397 != nil:
    section.add "X-Amz-Signature", valid_601397
  var valid_601398 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601398 = validateParameter(valid_601398, JString, required = false,
                                 default = nil)
  if valid_601398 != nil:
    section.add "X-Amz-SignedHeaders", valid_601398
  var valid_601399 = header.getOrDefault("X-Amz-Credential")
  valid_601399 = validateParameter(valid_601399, JString, required = false,
                                 default = nil)
  if valid_601399 != nil:
    section.add "X-Amz-Credential", valid_601399
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601401: Call_DeleteVolume_601389; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified storage volume that you previously created using the <a>CreateCachediSCSIVolume</a> or <a>CreateStorediSCSIVolume</a> API. This operation is only supported in the cached volume and stored volume types. For stored volume gateways, the local disk that was configured as the storage volume is not deleted. You can reuse the local disk to create another storage volume. </p> <p>Before you delete a volume, make sure there are no iSCSI connections to the volume you are deleting. You should also make sure there is no snapshot in progress. You can use the Amazon Elastic Compute Cloud (Amazon EC2) API to query snapshots on the volume you are deleting and check the snapshot status. For more information, go to <a href="https://docs.aws.amazon.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeSnapshots.html">DescribeSnapshots</a> in the <i>Amazon Elastic Compute Cloud API Reference</i>.</p> <p>In the request, you must provide the Amazon Resource Name (ARN) of the storage volume you want to delete.</p>
  ## 
  let valid = call_601401.validator(path, query, header, formData, body)
  let scheme = call_601401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601401.url(scheme.get, call_601401.host, call_601401.base,
                         call_601401.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601401, url, valid)

proc call*(call_601402: Call_DeleteVolume_601389; body: JsonNode): Recallable =
  ## deleteVolume
  ## <p>Deletes the specified storage volume that you previously created using the <a>CreateCachediSCSIVolume</a> or <a>CreateStorediSCSIVolume</a> API. This operation is only supported in the cached volume and stored volume types. For stored volume gateways, the local disk that was configured as the storage volume is not deleted. You can reuse the local disk to create another storage volume. </p> <p>Before you delete a volume, make sure there are no iSCSI connections to the volume you are deleting. You should also make sure there is no snapshot in progress. You can use the Amazon Elastic Compute Cloud (Amazon EC2) API to query snapshots on the volume you are deleting and check the snapshot status. For more information, go to <a href="https://docs.aws.amazon.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeSnapshots.html">DescribeSnapshots</a> in the <i>Amazon Elastic Compute Cloud API Reference</i>.</p> <p>In the request, you must provide the Amazon Resource Name (ARN) of the storage volume you want to delete.</p>
  ##   body: JObject (required)
  var body_601403 = newJObject()
  if body != nil:
    body_601403 = body
  result = call_601402.call(nil, nil, nil, nil, body_601403)

var deleteVolume* = Call_DeleteVolume_601389(name: "deleteVolume",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DeleteVolume",
    validator: validate_DeleteVolume_601390, base: "/", url: url_DeleteVolume_601391,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBandwidthRateLimit_601404 = ref object of OpenApiRestCall_600438
proc url_DescribeBandwidthRateLimit_601406(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeBandwidthRateLimit_601405(path: JsonNode; query: JsonNode;
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
  var valid_601407 = header.getOrDefault("X-Amz-Date")
  valid_601407 = validateParameter(valid_601407, JString, required = false,
                                 default = nil)
  if valid_601407 != nil:
    section.add "X-Amz-Date", valid_601407
  var valid_601408 = header.getOrDefault("X-Amz-Security-Token")
  valid_601408 = validateParameter(valid_601408, JString, required = false,
                                 default = nil)
  if valid_601408 != nil:
    section.add "X-Amz-Security-Token", valid_601408
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601409 = header.getOrDefault("X-Amz-Target")
  valid_601409 = validateParameter(valid_601409, JString, required = true, default = newJString(
      "StorageGateway_20130630.DescribeBandwidthRateLimit"))
  if valid_601409 != nil:
    section.add "X-Amz-Target", valid_601409
  var valid_601410 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601410 = validateParameter(valid_601410, JString, required = false,
                                 default = nil)
  if valid_601410 != nil:
    section.add "X-Amz-Content-Sha256", valid_601410
  var valid_601411 = header.getOrDefault("X-Amz-Algorithm")
  valid_601411 = validateParameter(valid_601411, JString, required = false,
                                 default = nil)
  if valid_601411 != nil:
    section.add "X-Amz-Algorithm", valid_601411
  var valid_601412 = header.getOrDefault("X-Amz-Signature")
  valid_601412 = validateParameter(valid_601412, JString, required = false,
                                 default = nil)
  if valid_601412 != nil:
    section.add "X-Amz-Signature", valid_601412
  var valid_601413 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601413 = validateParameter(valid_601413, JString, required = false,
                                 default = nil)
  if valid_601413 != nil:
    section.add "X-Amz-SignedHeaders", valid_601413
  var valid_601414 = header.getOrDefault("X-Amz-Credential")
  valid_601414 = validateParameter(valid_601414, JString, required = false,
                                 default = nil)
  if valid_601414 != nil:
    section.add "X-Amz-Credential", valid_601414
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601416: Call_DescribeBandwidthRateLimit_601404; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the bandwidth rate limits of a gateway. By default, these limits are not set, which means no bandwidth rate limiting is in effect.</p> <p>This operation only returns a value for a bandwidth rate limit only if the limit is set. If no limits are set for the gateway, then this operation returns only the gateway ARN in the response body. To specify which gateway to describe, use the Amazon Resource Name (ARN) of the gateway in your request.</p>
  ## 
  let valid = call_601416.validator(path, query, header, formData, body)
  let scheme = call_601416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601416.url(scheme.get, call_601416.host, call_601416.base,
                         call_601416.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601416, url, valid)

proc call*(call_601417: Call_DescribeBandwidthRateLimit_601404; body: JsonNode): Recallable =
  ## describeBandwidthRateLimit
  ## <p>Returns the bandwidth rate limits of a gateway. By default, these limits are not set, which means no bandwidth rate limiting is in effect.</p> <p>This operation only returns a value for a bandwidth rate limit only if the limit is set. If no limits are set for the gateway, then this operation returns only the gateway ARN in the response body. To specify which gateway to describe, use the Amazon Resource Name (ARN) of the gateway in your request.</p>
  ##   body: JObject (required)
  var body_601418 = newJObject()
  if body != nil:
    body_601418 = body
  result = call_601417.call(nil, nil, nil, nil, body_601418)

var describeBandwidthRateLimit* = Call_DescribeBandwidthRateLimit_601404(
    name: "describeBandwidthRateLimit", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeBandwidthRateLimit",
    validator: validate_DescribeBandwidthRateLimit_601405, base: "/",
    url: url_DescribeBandwidthRateLimit_601406,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCache_601419 = ref object of OpenApiRestCall_600438
proc url_DescribeCache_601421(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeCache_601420(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601422 = header.getOrDefault("X-Amz-Date")
  valid_601422 = validateParameter(valid_601422, JString, required = false,
                                 default = nil)
  if valid_601422 != nil:
    section.add "X-Amz-Date", valid_601422
  var valid_601423 = header.getOrDefault("X-Amz-Security-Token")
  valid_601423 = validateParameter(valid_601423, JString, required = false,
                                 default = nil)
  if valid_601423 != nil:
    section.add "X-Amz-Security-Token", valid_601423
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601424 = header.getOrDefault("X-Amz-Target")
  valid_601424 = validateParameter(valid_601424, JString, required = true, default = newJString(
      "StorageGateway_20130630.DescribeCache"))
  if valid_601424 != nil:
    section.add "X-Amz-Target", valid_601424
  var valid_601425 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601425 = validateParameter(valid_601425, JString, required = false,
                                 default = nil)
  if valid_601425 != nil:
    section.add "X-Amz-Content-Sha256", valid_601425
  var valid_601426 = header.getOrDefault("X-Amz-Algorithm")
  valid_601426 = validateParameter(valid_601426, JString, required = false,
                                 default = nil)
  if valid_601426 != nil:
    section.add "X-Amz-Algorithm", valid_601426
  var valid_601427 = header.getOrDefault("X-Amz-Signature")
  valid_601427 = validateParameter(valid_601427, JString, required = false,
                                 default = nil)
  if valid_601427 != nil:
    section.add "X-Amz-Signature", valid_601427
  var valid_601428 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601428 = validateParameter(valid_601428, JString, required = false,
                                 default = nil)
  if valid_601428 != nil:
    section.add "X-Amz-SignedHeaders", valid_601428
  var valid_601429 = header.getOrDefault("X-Amz-Credential")
  valid_601429 = validateParameter(valid_601429, JString, required = false,
                                 default = nil)
  if valid_601429 != nil:
    section.add "X-Amz-Credential", valid_601429
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601431: Call_DescribeCache_601419; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about the cache of a gateway. This operation is only supported in the cached volume, tape and file gateway types.</p> <p>The response includes disk IDs that are configured as cache, and it includes the amount of cache allocated and used.</p>
  ## 
  let valid = call_601431.validator(path, query, header, formData, body)
  let scheme = call_601431.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601431.url(scheme.get, call_601431.host, call_601431.base,
                         call_601431.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601431, url, valid)

proc call*(call_601432: Call_DescribeCache_601419; body: JsonNode): Recallable =
  ## describeCache
  ## <p>Returns information about the cache of a gateway. This operation is only supported in the cached volume, tape and file gateway types.</p> <p>The response includes disk IDs that are configured as cache, and it includes the amount of cache allocated and used.</p>
  ##   body: JObject (required)
  var body_601433 = newJObject()
  if body != nil:
    body_601433 = body
  result = call_601432.call(nil, nil, nil, nil, body_601433)

var describeCache* = Call_DescribeCache_601419(name: "describeCache",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeCache",
    validator: validate_DescribeCache_601420, base: "/", url: url_DescribeCache_601421,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCachediSCSIVolumes_601434 = ref object of OpenApiRestCall_600438
proc url_DescribeCachediSCSIVolumes_601436(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeCachediSCSIVolumes_601435(path: JsonNode; query: JsonNode;
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
  var valid_601437 = header.getOrDefault("X-Amz-Date")
  valid_601437 = validateParameter(valid_601437, JString, required = false,
                                 default = nil)
  if valid_601437 != nil:
    section.add "X-Amz-Date", valid_601437
  var valid_601438 = header.getOrDefault("X-Amz-Security-Token")
  valid_601438 = validateParameter(valid_601438, JString, required = false,
                                 default = nil)
  if valid_601438 != nil:
    section.add "X-Amz-Security-Token", valid_601438
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601439 = header.getOrDefault("X-Amz-Target")
  valid_601439 = validateParameter(valid_601439, JString, required = true, default = newJString(
      "StorageGateway_20130630.DescribeCachediSCSIVolumes"))
  if valid_601439 != nil:
    section.add "X-Amz-Target", valid_601439
  var valid_601440 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601440 = validateParameter(valid_601440, JString, required = false,
                                 default = nil)
  if valid_601440 != nil:
    section.add "X-Amz-Content-Sha256", valid_601440
  var valid_601441 = header.getOrDefault("X-Amz-Algorithm")
  valid_601441 = validateParameter(valid_601441, JString, required = false,
                                 default = nil)
  if valid_601441 != nil:
    section.add "X-Amz-Algorithm", valid_601441
  var valid_601442 = header.getOrDefault("X-Amz-Signature")
  valid_601442 = validateParameter(valid_601442, JString, required = false,
                                 default = nil)
  if valid_601442 != nil:
    section.add "X-Amz-Signature", valid_601442
  var valid_601443 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601443 = validateParameter(valid_601443, JString, required = false,
                                 default = nil)
  if valid_601443 != nil:
    section.add "X-Amz-SignedHeaders", valid_601443
  var valid_601444 = header.getOrDefault("X-Amz-Credential")
  valid_601444 = validateParameter(valid_601444, JString, required = false,
                                 default = nil)
  if valid_601444 != nil:
    section.add "X-Amz-Credential", valid_601444
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601446: Call_DescribeCachediSCSIVolumes_601434; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a description of the gateway volumes specified in the request. This operation is only supported in the cached volume gateway types.</p> <p>The list of gateway volumes in the request must be from one gateway. In the response Amazon Storage Gateway returns volume information sorted by volume Amazon Resource Name (ARN).</p>
  ## 
  let valid = call_601446.validator(path, query, header, formData, body)
  let scheme = call_601446.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601446.url(scheme.get, call_601446.host, call_601446.base,
                         call_601446.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601446, url, valid)

proc call*(call_601447: Call_DescribeCachediSCSIVolumes_601434; body: JsonNode): Recallable =
  ## describeCachediSCSIVolumes
  ## <p>Returns a description of the gateway volumes specified in the request. This operation is only supported in the cached volume gateway types.</p> <p>The list of gateway volumes in the request must be from one gateway. In the response Amazon Storage Gateway returns volume information sorted by volume Amazon Resource Name (ARN).</p>
  ##   body: JObject (required)
  var body_601448 = newJObject()
  if body != nil:
    body_601448 = body
  result = call_601447.call(nil, nil, nil, nil, body_601448)

var describeCachediSCSIVolumes* = Call_DescribeCachediSCSIVolumes_601434(
    name: "describeCachediSCSIVolumes", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeCachediSCSIVolumes",
    validator: validate_DescribeCachediSCSIVolumes_601435, base: "/",
    url: url_DescribeCachediSCSIVolumes_601436,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeChapCredentials_601449 = ref object of OpenApiRestCall_600438
proc url_DescribeChapCredentials_601451(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeChapCredentials_601450(path: JsonNode; query: JsonNode;
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
  var valid_601452 = header.getOrDefault("X-Amz-Date")
  valid_601452 = validateParameter(valid_601452, JString, required = false,
                                 default = nil)
  if valid_601452 != nil:
    section.add "X-Amz-Date", valid_601452
  var valid_601453 = header.getOrDefault("X-Amz-Security-Token")
  valid_601453 = validateParameter(valid_601453, JString, required = false,
                                 default = nil)
  if valid_601453 != nil:
    section.add "X-Amz-Security-Token", valid_601453
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601454 = header.getOrDefault("X-Amz-Target")
  valid_601454 = validateParameter(valid_601454, JString, required = true, default = newJString(
      "StorageGateway_20130630.DescribeChapCredentials"))
  if valid_601454 != nil:
    section.add "X-Amz-Target", valid_601454
  var valid_601455 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601455 = validateParameter(valid_601455, JString, required = false,
                                 default = nil)
  if valid_601455 != nil:
    section.add "X-Amz-Content-Sha256", valid_601455
  var valid_601456 = header.getOrDefault("X-Amz-Algorithm")
  valid_601456 = validateParameter(valid_601456, JString, required = false,
                                 default = nil)
  if valid_601456 != nil:
    section.add "X-Amz-Algorithm", valid_601456
  var valid_601457 = header.getOrDefault("X-Amz-Signature")
  valid_601457 = validateParameter(valid_601457, JString, required = false,
                                 default = nil)
  if valid_601457 != nil:
    section.add "X-Amz-Signature", valid_601457
  var valid_601458 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601458 = validateParameter(valid_601458, JString, required = false,
                                 default = nil)
  if valid_601458 != nil:
    section.add "X-Amz-SignedHeaders", valid_601458
  var valid_601459 = header.getOrDefault("X-Amz-Credential")
  valid_601459 = validateParameter(valid_601459, JString, required = false,
                                 default = nil)
  if valid_601459 != nil:
    section.add "X-Amz-Credential", valid_601459
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601461: Call_DescribeChapCredentials_601449; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of Challenge-Handshake Authentication Protocol (CHAP) credentials information for a specified iSCSI target, one for each target-initiator pair.
  ## 
  let valid = call_601461.validator(path, query, header, formData, body)
  let scheme = call_601461.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601461.url(scheme.get, call_601461.host, call_601461.base,
                         call_601461.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601461, url, valid)

proc call*(call_601462: Call_DescribeChapCredentials_601449; body: JsonNode): Recallable =
  ## describeChapCredentials
  ## Returns an array of Challenge-Handshake Authentication Protocol (CHAP) credentials information for a specified iSCSI target, one for each target-initiator pair.
  ##   body: JObject (required)
  var body_601463 = newJObject()
  if body != nil:
    body_601463 = body
  result = call_601462.call(nil, nil, nil, nil, body_601463)

var describeChapCredentials* = Call_DescribeChapCredentials_601449(
    name: "describeChapCredentials", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeChapCredentials",
    validator: validate_DescribeChapCredentials_601450, base: "/",
    url: url_DescribeChapCredentials_601451, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeGatewayInformation_601464 = ref object of OpenApiRestCall_600438
proc url_DescribeGatewayInformation_601466(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeGatewayInformation_601465(path: JsonNode; query: JsonNode;
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
  var valid_601467 = header.getOrDefault("X-Amz-Date")
  valid_601467 = validateParameter(valid_601467, JString, required = false,
                                 default = nil)
  if valid_601467 != nil:
    section.add "X-Amz-Date", valid_601467
  var valid_601468 = header.getOrDefault("X-Amz-Security-Token")
  valid_601468 = validateParameter(valid_601468, JString, required = false,
                                 default = nil)
  if valid_601468 != nil:
    section.add "X-Amz-Security-Token", valid_601468
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601469 = header.getOrDefault("X-Amz-Target")
  valid_601469 = validateParameter(valid_601469, JString, required = true, default = newJString(
      "StorageGateway_20130630.DescribeGatewayInformation"))
  if valid_601469 != nil:
    section.add "X-Amz-Target", valid_601469
  var valid_601470 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601470 = validateParameter(valid_601470, JString, required = false,
                                 default = nil)
  if valid_601470 != nil:
    section.add "X-Amz-Content-Sha256", valid_601470
  var valid_601471 = header.getOrDefault("X-Amz-Algorithm")
  valid_601471 = validateParameter(valid_601471, JString, required = false,
                                 default = nil)
  if valid_601471 != nil:
    section.add "X-Amz-Algorithm", valid_601471
  var valid_601472 = header.getOrDefault("X-Amz-Signature")
  valid_601472 = validateParameter(valid_601472, JString, required = false,
                                 default = nil)
  if valid_601472 != nil:
    section.add "X-Amz-Signature", valid_601472
  var valid_601473 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601473 = validateParameter(valid_601473, JString, required = false,
                                 default = nil)
  if valid_601473 != nil:
    section.add "X-Amz-SignedHeaders", valid_601473
  var valid_601474 = header.getOrDefault("X-Amz-Credential")
  valid_601474 = validateParameter(valid_601474, JString, required = false,
                                 default = nil)
  if valid_601474 != nil:
    section.add "X-Amz-Credential", valid_601474
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601476: Call_DescribeGatewayInformation_601464; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata about a gateway such as its name, network interfaces, configured time zone, and the state (whether the gateway is running or not). To specify which gateway to describe, use the Amazon Resource Name (ARN) of the gateway in your request.
  ## 
  let valid = call_601476.validator(path, query, header, formData, body)
  let scheme = call_601476.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601476.url(scheme.get, call_601476.host, call_601476.base,
                         call_601476.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601476, url, valid)

proc call*(call_601477: Call_DescribeGatewayInformation_601464; body: JsonNode): Recallable =
  ## describeGatewayInformation
  ## Returns metadata about a gateway such as its name, network interfaces, configured time zone, and the state (whether the gateway is running or not). To specify which gateway to describe, use the Amazon Resource Name (ARN) of the gateway in your request.
  ##   body: JObject (required)
  var body_601478 = newJObject()
  if body != nil:
    body_601478 = body
  result = call_601477.call(nil, nil, nil, nil, body_601478)

var describeGatewayInformation* = Call_DescribeGatewayInformation_601464(
    name: "describeGatewayInformation", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeGatewayInformation",
    validator: validate_DescribeGatewayInformation_601465, base: "/",
    url: url_DescribeGatewayInformation_601466,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceStartTime_601479 = ref object of OpenApiRestCall_600438
proc url_DescribeMaintenanceStartTime_601481(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeMaintenanceStartTime_601480(path: JsonNode; query: JsonNode;
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
  var valid_601482 = header.getOrDefault("X-Amz-Date")
  valid_601482 = validateParameter(valid_601482, JString, required = false,
                                 default = nil)
  if valid_601482 != nil:
    section.add "X-Amz-Date", valid_601482
  var valid_601483 = header.getOrDefault("X-Amz-Security-Token")
  valid_601483 = validateParameter(valid_601483, JString, required = false,
                                 default = nil)
  if valid_601483 != nil:
    section.add "X-Amz-Security-Token", valid_601483
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601484 = header.getOrDefault("X-Amz-Target")
  valid_601484 = validateParameter(valid_601484, JString, required = true, default = newJString(
      "StorageGateway_20130630.DescribeMaintenanceStartTime"))
  if valid_601484 != nil:
    section.add "X-Amz-Target", valid_601484
  var valid_601485 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601485 = validateParameter(valid_601485, JString, required = false,
                                 default = nil)
  if valid_601485 != nil:
    section.add "X-Amz-Content-Sha256", valid_601485
  var valid_601486 = header.getOrDefault("X-Amz-Algorithm")
  valid_601486 = validateParameter(valid_601486, JString, required = false,
                                 default = nil)
  if valid_601486 != nil:
    section.add "X-Amz-Algorithm", valid_601486
  var valid_601487 = header.getOrDefault("X-Amz-Signature")
  valid_601487 = validateParameter(valid_601487, JString, required = false,
                                 default = nil)
  if valid_601487 != nil:
    section.add "X-Amz-Signature", valid_601487
  var valid_601488 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601488 = validateParameter(valid_601488, JString, required = false,
                                 default = nil)
  if valid_601488 != nil:
    section.add "X-Amz-SignedHeaders", valid_601488
  var valid_601489 = header.getOrDefault("X-Amz-Credential")
  valid_601489 = validateParameter(valid_601489, JString, required = false,
                                 default = nil)
  if valid_601489 != nil:
    section.add "X-Amz-Credential", valid_601489
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601491: Call_DescribeMaintenanceStartTime_601479; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns your gateway's weekly maintenance start time including the day and time of the week. Note that values are in terms of the gateway's time zone.
  ## 
  let valid = call_601491.validator(path, query, header, formData, body)
  let scheme = call_601491.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601491.url(scheme.get, call_601491.host, call_601491.base,
                         call_601491.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601491, url, valid)

proc call*(call_601492: Call_DescribeMaintenanceStartTime_601479; body: JsonNode): Recallable =
  ## describeMaintenanceStartTime
  ## Returns your gateway's weekly maintenance start time including the day and time of the week. Note that values are in terms of the gateway's time zone.
  ##   body: JObject (required)
  var body_601493 = newJObject()
  if body != nil:
    body_601493 = body
  result = call_601492.call(nil, nil, nil, nil, body_601493)

var describeMaintenanceStartTime* = Call_DescribeMaintenanceStartTime_601479(
    name: "describeMaintenanceStartTime", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com", route: "/#X-Amz-Target=StorageGateway_20130630.DescribeMaintenanceStartTime",
    validator: validate_DescribeMaintenanceStartTime_601480, base: "/",
    url: url_DescribeMaintenanceStartTime_601481,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeNFSFileShares_601494 = ref object of OpenApiRestCall_600438
proc url_DescribeNFSFileShares_601496(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeNFSFileShares_601495(path: JsonNode; query: JsonNode;
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
  var valid_601497 = header.getOrDefault("X-Amz-Date")
  valid_601497 = validateParameter(valid_601497, JString, required = false,
                                 default = nil)
  if valid_601497 != nil:
    section.add "X-Amz-Date", valid_601497
  var valid_601498 = header.getOrDefault("X-Amz-Security-Token")
  valid_601498 = validateParameter(valid_601498, JString, required = false,
                                 default = nil)
  if valid_601498 != nil:
    section.add "X-Amz-Security-Token", valid_601498
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601499 = header.getOrDefault("X-Amz-Target")
  valid_601499 = validateParameter(valid_601499, JString, required = true, default = newJString(
      "StorageGateway_20130630.DescribeNFSFileShares"))
  if valid_601499 != nil:
    section.add "X-Amz-Target", valid_601499
  var valid_601500 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601500 = validateParameter(valid_601500, JString, required = false,
                                 default = nil)
  if valid_601500 != nil:
    section.add "X-Amz-Content-Sha256", valid_601500
  var valid_601501 = header.getOrDefault("X-Amz-Algorithm")
  valid_601501 = validateParameter(valid_601501, JString, required = false,
                                 default = nil)
  if valid_601501 != nil:
    section.add "X-Amz-Algorithm", valid_601501
  var valid_601502 = header.getOrDefault("X-Amz-Signature")
  valid_601502 = validateParameter(valid_601502, JString, required = false,
                                 default = nil)
  if valid_601502 != nil:
    section.add "X-Amz-Signature", valid_601502
  var valid_601503 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601503 = validateParameter(valid_601503, JString, required = false,
                                 default = nil)
  if valid_601503 != nil:
    section.add "X-Amz-SignedHeaders", valid_601503
  var valid_601504 = header.getOrDefault("X-Amz-Credential")
  valid_601504 = validateParameter(valid_601504, JString, required = false,
                                 default = nil)
  if valid_601504 != nil:
    section.add "X-Amz-Credential", valid_601504
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601506: Call_DescribeNFSFileShares_601494; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a description for one or more Network File System (NFS) file shares from a file gateway. This operation is only supported for file gateways.
  ## 
  let valid = call_601506.validator(path, query, header, formData, body)
  let scheme = call_601506.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601506.url(scheme.get, call_601506.host, call_601506.base,
                         call_601506.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601506, url, valid)

proc call*(call_601507: Call_DescribeNFSFileShares_601494; body: JsonNode): Recallable =
  ## describeNFSFileShares
  ## Gets a description for one or more Network File System (NFS) file shares from a file gateway. This operation is only supported for file gateways.
  ##   body: JObject (required)
  var body_601508 = newJObject()
  if body != nil:
    body_601508 = body
  result = call_601507.call(nil, nil, nil, nil, body_601508)

var describeNFSFileShares* = Call_DescribeNFSFileShares_601494(
    name: "describeNFSFileShares", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeNFSFileShares",
    validator: validate_DescribeNFSFileShares_601495, base: "/",
    url: url_DescribeNFSFileShares_601496, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSMBFileShares_601509 = ref object of OpenApiRestCall_600438
proc url_DescribeSMBFileShares_601511(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeSMBFileShares_601510(path: JsonNode; query: JsonNode;
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
  var valid_601512 = header.getOrDefault("X-Amz-Date")
  valid_601512 = validateParameter(valid_601512, JString, required = false,
                                 default = nil)
  if valid_601512 != nil:
    section.add "X-Amz-Date", valid_601512
  var valid_601513 = header.getOrDefault("X-Amz-Security-Token")
  valid_601513 = validateParameter(valid_601513, JString, required = false,
                                 default = nil)
  if valid_601513 != nil:
    section.add "X-Amz-Security-Token", valid_601513
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601514 = header.getOrDefault("X-Amz-Target")
  valid_601514 = validateParameter(valid_601514, JString, required = true, default = newJString(
      "StorageGateway_20130630.DescribeSMBFileShares"))
  if valid_601514 != nil:
    section.add "X-Amz-Target", valid_601514
  var valid_601515 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601515 = validateParameter(valid_601515, JString, required = false,
                                 default = nil)
  if valid_601515 != nil:
    section.add "X-Amz-Content-Sha256", valid_601515
  var valid_601516 = header.getOrDefault("X-Amz-Algorithm")
  valid_601516 = validateParameter(valid_601516, JString, required = false,
                                 default = nil)
  if valid_601516 != nil:
    section.add "X-Amz-Algorithm", valid_601516
  var valid_601517 = header.getOrDefault("X-Amz-Signature")
  valid_601517 = validateParameter(valid_601517, JString, required = false,
                                 default = nil)
  if valid_601517 != nil:
    section.add "X-Amz-Signature", valid_601517
  var valid_601518 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601518 = validateParameter(valid_601518, JString, required = false,
                                 default = nil)
  if valid_601518 != nil:
    section.add "X-Amz-SignedHeaders", valid_601518
  var valid_601519 = header.getOrDefault("X-Amz-Credential")
  valid_601519 = validateParameter(valid_601519, JString, required = false,
                                 default = nil)
  if valid_601519 != nil:
    section.add "X-Amz-Credential", valid_601519
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601521: Call_DescribeSMBFileShares_601509; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a description for one or more Server Message Block (SMB) file shares from a file gateway. This operation is only supported for file gateways.
  ## 
  let valid = call_601521.validator(path, query, header, formData, body)
  let scheme = call_601521.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601521.url(scheme.get, call_601521.host, call_601521.base,
                         call_601521.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601521, url, valid)

proc call*(call_601522: Call_DescribeSMBFileShares_601509; body: JsonNode): Recallable =
  ## describeSMBFileShares
  ## Gets a description for one or more Server Message Block (SMB) file shares from a file gateway. This operation is only supported for file gateways.
  ##   body: JObject (required)
  var body_601523 = newJObject()
  if body != nil:
    body_601523 = body
  result = call_601522.call(nil, nil, nil, nil, body_601523)

var describeSMBFileShares* = Call_DescribeSMBFileShares_601509(
    name: "describeSMBFileShares", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeSMBFileShares",
    validator: validate_DescribeSMBFileShares_601510, base: "/",
    url: url_DescribeSMBFileShares_601511, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSMBSettings_601524 = ref object of OpenApiRestCall_600438
proc url_DescribeSMBSettings_601526(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeSMBSettings_601525(path: JsonNode; query: JsonNode;
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
  var valid_601527 = header.getOrDefault("X-Amz-Date")
  valid_601527 = validateParameter(valid_601527, JString, required = false,
                                 default = nil)
  if valid_601527 != nil:
    section.add "X-Amz-Date", valid_601527
  var valid_601528 = header.getOrDefault("X-Amz-Security-Token")
  valid_601528 = validateParameter(valid_601528, JString, required = false,
                                 default = nil)
  if valid_601528 != nil:
    section.add "X-Amz-Security-Token", valid_601528
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601529 = header.getOrDefault("X-Amz-Target")
  valid_601529 = validateParameter(valid_601529, JString, required = true, default = newJString(
      "StorageGateway_20130630.DescribeSMBSettings"))
  if valid_601529 != nil:
    section.add "X-Amz-Target", valid_601529
  var valid_601530 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601530 = validateParameter(valid_601530, JString, required = false,
                                 default = nil)
  if valid_601530 != nil:
    section.add "X-Amz-Content-Sha256", valid_601530
  var valid_601531 = header.getOrDefault("X-Amz-Algorithm")
  valid_601531 = validateParameter(valid_601531, JString, required = false,
                                 default = nil)
  if valid_601531 != nil:
    section.add "X-Amz-Algorithm", valid_601531
  var valid_601532 = header.getOrDefault("X-Amz-Signature")
  valid_601532 = validateParameter(valid_601532, JString, required = false,
                                 default = nil)
  if valid_601532 != nil:
    section.add "X-Amz-Signature", valid_601532
  var valid_601533 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601533 = validateParameter(valid_601533, JString, required = false,
                                 default = nil)
  if valid_601533 != nil:
    section.add "X-Amz-SignedHeaders", valid_601533
  var valid_601534 = header.getOrDefault("X-Amz-Credential")
  valid_601534 = validateParameter(valid_601534, JString, required = false,
                                 default = nil)
  if valid_601534 != nil:
    section.add "X-Amz-Credential", valid_601534
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601536: Call_DescribeSMBSettings_601524; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a description of a Server Message Block (SMB) file share settings from a file gateway. This operation is only supported for file gateways.
  ## 
  let valid = call_601536.validator(path, query, header, formData, body)
  let scheme = call_601536.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601536.url(scheme.get, call_601536.host, call_601536.base,
                         call_601536.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601536, url, valid)

proc call*(call_601537: Call_DescribeSMBSettings_601524; body: JsonNode): Recallable =
  ## describeSMBSettings
  ## Gets a description of a Server Message Block (SMB) file share settings from a file gateway. This operation is only supported for file gateways.
  ##   body: JObject (required)
  var body_601538 = newJObject()
  if body != nil:
    body_601538 = body
  result = call_601537.call(nil, nil, nil, nil, body_601538)

var describeSMBSettings* = Call_DescribeSMBSettings_601524(
    name: "describeSMBSettings", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeSMBSettings",
    validator: validate_DescribeSMBSettings_601525, base: "/",
    url: url_DescribeSMBSettings_601526, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSnapshotSchedule_601539 = ref object of OpenApiRestCall_600438
proc url_DescribeSnapshotSchedule_601541(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeSnapshotSchedule_601540(path: JsonNode; query: JsonNode;
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
  var valid_601542 = header.getOrDefault("X-Amz-Date")
  valid_601542 = validateParameter(valid_601542, JString, required = false,
                                 default = nil)
  if valid_601542 != nil:
    section.add "X-Amz-Date", valid_601542
  var valid_601543 = header.getOrDefault("X-Amz-Security-Token")
  valid_601543 = validateParameter(valid_601543, JString, required = false,
                                 default = nil)
  if valid_601543 != nil:
    section.add "X-Amz-Security-Token", valid_601543
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601544 = header.getOrDefault("X-Amz-Target")
  valid_601544 = validateParameter(valid_601544, JString, required = true, default = newJString(
      "StorageGateway_20130630.DescribeSnapshotSchedule"))
  if valid_601544 != nil:
    section.add "X-Amz-Target", valid_601544
  var valid_601545 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601545 = validateParameter(valid_601545, JString, required = false,
                                 default = nil)
  if valid_601545 != nil:
    section.add "X-Amz-Content-Sha256", valid_601545
  var valid_601546 = header.getOrDefault("X-Amz-Algorithm")
  valid_601546 = validateParameter(valid_601546, JString, required = false,
                                 default = nil)
  if valid_601546 != nil:
    section.add "X-Amz-Algorithm", valid_601546
  var valid_601547 = header.getOrDefault("X-Amz-Signature")
  valid_601547 = validateParameter(valid_601547, JString, required = false,
                                 default = nil)
  if valid_601547 != nil:
    section.add "X-Amz-Signature", valid_601547
  var valid_601548 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601548 = validateParameter(valid_601548, JString, required = false,
                                 default = nil)
  if valid_601548 != nil:
    section.add "X-Amz-SignedHeaders", valid_601548
  var valid_601549 = header.getOrDefault("X-Amz-Credential")
  valid_601549 = validateParameter(valid_601549, JString, required = false,
                                 default = nil)
  if valid_601549 != nil:
    section.add "X-Amz-Credential", valid_601549
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601551: Call_DescribeSnapshotSchedule_601539; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the snapshot schedule for the specified gateway volume. The snapshot schedule information includes intervals at which snapshots are automatically initiated on the volume. This operation is only supported in the cached volume and stored volume types.
  ## 
  let valid = call_601551.validator(path, query, header, formData, body)
  let scheme = call_601551.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601551.url(scheme.get, call_601551.host, call_601551.base,
                         call_601551.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601551, url, valid)

proc call*(call_601552: Call_DescribeSnapshotSchedule_601539; body: JsonNode): Recallable =
  ## describeSnapshotSchedule
  ## Describes the snapshot schedule for the specified gateway volume. The snapshot schedule information includes intervals at which snapshots are automatically initiated on the volume. This operation is only supported in the cached volume and stored volume types.
  ##   body: JObject (required)
  var body_601553 = newJObject()
  if body != nil:
    body_601553 = body
  result = call_601552.call(nil, nil, nil, nil, body_601553)

var describeSnapshotSchedule* = Call_DescribeSnapshotSchedule_601539(
    name: "describeSnapshotSchedule", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeSnapshotSchedule",
    validator: validate_DescribeSnapshotSchedule_601540, base: "/",
    url: url_DescribeSnapshotSchedule_601541, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeStorediSCSIVolumes_601554 = ref object of OpenApiRestCall_600438
proc url_DescribeStorediSCSIVolumes_601556(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeStorediSCSIVolumes_601555(path: JsonNode; query: JsonNode;
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
  var valid_601557 = header.getOrDefault("X-Amz-Date")
  valid_601557 = validateParameter(valid_601557, JString, required = false,
                                 default = nil)
  if valid_601557 != nil:
    section.add "X-Amz-Date", valid_601557
  var valid_601558 = header.getOrDefault("X-Amz-Security-Token")
  valid_601558 = validateParameter(valid_601558, JString, required = false,
                                 default = nil)
  if valid_601558 != nil:
    section.add "X-Amz-Security-Token", valid_601558
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601559 = header.getOrDefault("X-Amz-Target")
  valid_601559 = validateParameter(valid_601559, JString, required = true, default = newJString(
      "StorageGateway_20130630.DescribeStorediSCSIVolumes"))
  if valid_601559 != nil:
    section.add "X-Amz-Target", valid_601559
  var valid_601560 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601560 = validateParameter(valid_601560, JString, required = false,
                                 default = nil)
  if valid_601560 != nil:
    section.add "X-Amz-Content-Sha256", valid_601560
  var valid_601561 = header.getOrDefault("X-Amz-Algorithm")
  valid_601561 = validateParameter(valid_601561, JString, required = false,
                                 default = nil)
  if valid_601561 != nil:
    section.add "X-Amz-Algorithm", valid_601561
  var valid_601562 = header.getOrDefault("X-Amz-Signature")
  valid_601562 = validateParameter(valid_601562, JString, required = false,
                                 default = nil)
  if valid_601562 != nil:
    section.add "X-Amz-Signature", valid_601562
  var valid_601563 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601563 = validateParameter(valid_601563, JString, required = false,
                                 default = nil)
  if valid_601563 != nil:
    section.add "X-Amz-SignedHeaders", valid_601563
  var valid_601564 = header.getOrDefault("X-Amz-Credential")
  valid_601564 = validateParameter(valid_601564, JString, required = false,
                                 default = nil)
  if valid_601564 != nil:
    section.add "X-Amz-Credential", valid_601564
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601566: Call_DescribeStorediSCSIVolumes_601554; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the description of the gateway volumes specified in the request. The list of gateway volumes in the request must be from one gateway. In the response Amazon Storage Gateway returns volume information sorted by volume ARNs. This operation is only supported in stored volume gateway type.
  ## 
  let valid = call_601566.validator(path, query, header, formData, body)
  let scheme = call_601566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601566.url(scheme.get, call_601566.host, call_601566.base,
                         call_601566.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601566, url, valid)

proc call*(call_601567: Call_DescribeStorediSCSIVolumes_601554; body: JsonNode): Recallable =
  ## describeStorediSCSIVolumes
  ## Returns the description of the gateway volumes specified in the request. The list of gateway volumes in the request must be from one gateway. In the response Amazon Storage Gateway returns volume information sorted by volume ARNs. This operation is only supported in stored volume gateway type.
  ##   body: JObject (required)
  var body_601568 = newJObject()
  if body != nil:
    body_601568 = body
  result = call_601567.call(nil, nil, nil, nil, body_601568)

var describeStorediSCSIVolumes* = Call_DescribeStorediSCSIVolumes_601554(
    name: "describeStorediSCSIVolumes", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeStorediSCSIVolumes",
    validator: validate_DescribeStorediSCSIVolumes_601555, base: "/",
    url: url_DescribeStorediSCSIVolumes_601556,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTapeArchives_601569 = ref object of OpenApiRestCall_600438
proc url_DescribeTapeArchives_601571(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeTapeArchives_601570(path: JsonNode; query: JsonNode;
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
  var valid_601572 = query.getOrDefault("Limit")
  valid_601572 = validateParameter(valid_601572, JString, required = false,
                                 default = nil)
  if valid_601572 != nil:
    section.add "Limit", valid_601572
  var valid_601573 = query.getOrDefault("Marker")
  valid_601573 = validateParameter(valid_601573, JString, required = false,
                                 default = nil)
  if valid_601573 != nil:
    section.add "Marker", valid_601573
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601574 = header.getOrDefault("X-Amz-Date")
  valid_601574 = validateParameter(valid_601574, JString, required = false,
                                 default = nil)
  if valid_601574 != nil:
    section.add "X-Amz-Date", valid_601574
  var valid_601575 = header.getOrDefault("X-Amz-Security-Token")
  valid_601575 = validateParameter(valid_601575, JString, required = false,
                                 default = nil)
  if valid_601575 != nil:
    section.add "X-Amz-Security-Token", valid_601575
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601576 = header.getOrDefault("X-Amz-Target")
  valid_601576 = validateParameter(valid_601576, JString, required = true, default = newJString(
      "StorageGateway_20130630.DescribeTapeArchives"))
  if valid_601576 != nil:
    section.add "X-Amz-Target", valid_601576
  var valid_601577 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601577 = validateParameter(valid_601577, JString, required = false,
                                 default = nil)
  if valid_601577 != nil:
    section.add "X-Amz-Content-Sha256", valid_601577
  var valid_601578 = header.getOrDefault("X-Amz-Algorithm")
  valid_601578 = validateParameter(valid_601578, JString, required = false,
                                 default = nil)
  if valid_601578 != nil:
    section.add "X-Amz-Algorithm", valid_601578
  var valid_601579 = header.getOrDefault("X-Amz-Signature")
  valid_601579 = validateParameter(valid_601579, JString, required = false,
                                 default = nil)
  if valid_601579 != nil:
    section.add "X-Amz-Signature", valid_601579
  var valid_601580 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601580 = validateParameter(valid_601580, JString, required = false,
                                 default = nil)
  if valid_601580 != nil:
    section.add "X-Amz-SignedHeaders", valid_601580
  var valid_601581 = header.getOrDefault("X-Amz-Credential")
  valid_601581 = validateParameter(valid_601581, JString, required = false,
                                 default = nil)
  if valid_601581 != nil:
    section.add "X-Amz-Credential", valid_601581
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601583: Call_DescribeTapeArchives_601569; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a description of specified virtual tapes in the virtual tape shelf (VTS). This operation is only supported in the tape gateway type.</p> <p>If a specific <code>TapeARN</code> is not specified, AWS Storage Gateway returns a description of all virtual tapes found in the VTS associated with your account.</p>
  ## 
  let valid = call_601583.validator(path, query, header, formData, body)
  let scheme = call_601583.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601583.url(scheme.get, call_601583.host, call_601583.base,
                         call_601583.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601583, url, valid)

proc call*(call_601584: Call_DescribeTapeArchives_601569; body: JsonNode;
          Limit: string = ""; Marker: string = ""): Recallable =
  ## describeTapeArchives
  ## <p>Returns a description of specified virtual tapes in the virtual tape shelf (VTS). This operation is only supported in the tape gateway type.</p> <p>If a specific <code>TapeARN</code> is not specified, AWS Storage Gateway returns a description of all virtual tapes found in the VTS associated with your account.</p>
  ##   Limit: string
  ##        : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_601585 = newJObject()
  var body_601586 = newJObject()
  add(query_601585, "Limit", newJString(Limit))
  add(query_601585, "Marker", newJString(Marker))
  if body != nil:
    body_601586 = body
  result = call_601584.call(nil, query_601585, nil, nil, body_601586)

var describeTapeArchives* = Call_DescribeTapeArchives_601569(
    name: "describeTapeArchives", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeTapeArchives",
    validator: validate_DescribeTapeArchives_601570, base: "/",
    url: url_DescribeTapeArchives_601571, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTapeRecoveryPoints_601588 = ref object of OpenApiRestCall_600438
proc url_DescribeTapeRecoveryPoints_601590(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeTapeRecoveryPoints_601589(path: JsonNode; query: JsonNode;
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
  var valid_601591 = query.getOrDefault("Limit")
  valid_601591 = validateParameter(valid_601591, JString, required = false,
                                 default = nil)
  if valid_601591 != nil:
    section.add "Limit", valid_601591
  var valid_601592 = query.getOrDefault("Marker")
  valid_601592 = validateParameter(valid_601592, JString, required = false,
                                 default = nil)
  if valid_601592 != nil:
    section.add "Marker", valid_601592
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601593 = header.getOrDefault("X-Amz-Date")
  valid_601593 = validateParameter(valid_601593, JString, required = false,
                                 default = nil)
  if valid_601593 != nil:
    section.add "X-Amz-Date", valid_601593
  var valid_601594 = header.getOrDefault("X-Amz-Security-Token")
  valid_601594 = validateParameter(valid_601594, JString, required = false,
                                 default = nil)
  if valid_601594 != nil:
    section.add "X-Amz-Security-Token", valid_601594
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601595 = header.getOrDefault("X-Amz-Target")
  valid_601595 = validateParameter(valid_601595, JString, required = true, default = newJString(
      "StorageGateway_20130630.DescribeTapeRecoveryPoints"))
  if valid_601595 != nil:
    section.add "X-Amz-Target", valid_601595
  var valid_601596 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601596 = validateParameter(valid_601596, JString, required = false,
                                 default = nil)
  if valid_601596 != nil:
    section.add "X-Amz-Content-Sha256", valid_601596
  var valid_601597 = header.getOrDefault("X-Amz-Algorithm")
  valid_601597 = validateParameter(valid_601597, JString, required = false,
                                 default = nil)
  if valid_601597 != nil:
    section.add "X-Amz-Algorithm", valid_601597
  var valid_601598 = header.getOrDefault("X-Amz-Signature")
  valid_601598 = validateParameter(valid_601598, JString, required = false,
                                 default = nil)
  if valid_601598 != nil:
    section.add "X-Amz-Signature", valid_601598
  var valid_601599 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601599 = validateParameter(valid_601599, JString, required = false,
                                 default = nil)
  if valid_601599 != nil:
    section.add "X-Amz-SignedHeaders", valid_601599
  var valid_601600 = header.getOrDefault("X-Amz-Credential")
  valid_601600 = validateParameter(valid_601600, JString, required = false,
                                 default = nil)
  if valid_601600 != nil:
    section.add "X-Amz-Credential", valid_601600
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601602: Call_DescribeTapeRecoveryPoints_601588; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of virtual tape recovery points that are available for the specified tape gateway.</p> <p>A recovery point is a point-in-time view of a virtual tape at which all the data on the virtual tape is consistent. If your gateway crashes, virtual tapes that have recovery points can be recovered to a new gateway. This operation is only supported in the tape gateway type.</p>
  ## 
  let valid = call_601602.validator(path, query, header, formData, body)
  let scheme = call_601602.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601602.url(scheme.get, call_601602.host, call_601602.base,
                         call_601602.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601602, url, valid)

proc call*(call_601603: Call_DescribeTapeRecoveryPoints_601588; body: JsonNode;
          Limit: string = ""; Marker: string = ""): Recallable =
  ## describeTapeRecoveryPoints
  ## <p>Returns a list of virtual tape recovery points that are available for the specified tape gateway.</p> <p>A recovery point is a point-in-time view of a virtual tape at which all the data on the virtual tape is consistent. If your gateway crashes, virtual tapes that have recovery points can be recovered to a new gateway. This operation is only supported in the tape gateway type.</p>
  ##   Limit: string
  ##        : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_601604 = newJObject()
  var body_601605 = newJObject()
  add(query_601604, "Limit", newJString(Limit))
  add(query_601604, "Marker", newJString(Marker))
  if body != nil:
    body_601605 = body
  result = call_601603.call(nil, query_601604, nil, nil, body_601605)

var describeTapeRecoveryPoints* = Call_DescribeTapeRecoveryPoints_601588(
    name: "describeTapeRecoveryPoints", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeTapeRecoveryPoints",
    validator: validate_DescribeTapeRecoveryPoints_601589, base: "/",
    url: url_DescribeTapeRecoveryPoints_601590,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTapes_601606 = ref object of OpenApiRestCall_600438
proc url_DescribeTapes_601608(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeTapes_601607(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601609 = query.getOrDefault("Limit")
  valid_601609 = validateParameter(valid_601609, JString, required = false,
                                 default = nil)
  if valid_601609 != nil:
    section.add "Limit", valid_601609
  var valid_601610 = query.getOrDefault("Marker")
  valid_601610 = validateParameter(valid_601610, JString, required = false,
                                 default = nil)
  if valid_601610 != nil:
    section.add "Marker", valid_601610
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601611 = header.getOrDefault("X-Amz-Date")
  valid_601611 = validateParameter(valid_601611, JString, required = false,
                                 default = nil)
  if valid_601611 != nil:
    section.add "X-Amz-Date", valid_601611
  var valid_601612 = header.getOrDefault("X-Amz-Security-Token")
  valid_601612 = validateParameter(valid_601612, JString, required = false,
                                 default = nil)
  if valid_601612 != nil:
    section.add "X-Amz-Security-Token", valid_601612
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601613 = header.getOrDefault("X-Amz-Target")
  valid_601613 = validateParameter(valid_601613, JString, required = true, default = newJString(
      "StorageGateway_20130630.DescribeTapes"))
  if valid_601613 != nil:
    section.add "X-Amz-Target", valid_601613
  var valid_601614 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601614 = validateParameter(valid_601614, JString, required = false,
                                 default = nil)
  if valid_601614 != nil:
    section.add "X-Amz-Content-Sha256", valid_601614
  var valid_601615 = header.getOrDefault("X-Amz-Algorithm")
  valid_601615 = validateParameter(valid_601615, JString, required = false,
                                 default = nil)
  if valid_601615 != nil:
    section.add "X-Amz-Algorithm", valid_601615
  var valid_601616 = header.getOrDefault("X-Amz-Signature")
  valid_601616 = validateParameter(valid_601616, JString, required = false,
                                 default = nil)
  if valid_601616 != nil:
    section.add "X-Amz-Signature", valid_601616
  var valid_601617 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601617 = validateParameter(valid_601617, JString, required = false,
                                 default = nil)
  if valid_601617 != nil:
    section.add "X-Amz-SignedHeaders", valid_601617
  var valid_601618 = header.getOrDefault("X-Amz-Credential")
  valid_601618 = validateParameter(valid_601618, JString, required = false,
                                 default = nil)
  if valid_601618 != nil:
    section.add "X-Amz-Credential", valid_601618
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601620: Call_DescribeTapes_601606; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a description of the specified Amazon Resource Name (ARN) of virtual tapes. If a <code>TapeARN</code> is not specified, returns a description of all virtual tapes associated with the specified gateway. This operation is only supported in the tape gateway type.
  ## 
  let valid = call_601620.validator(path, query, header, formData, body)
  let scheme = call_601620.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601620.url(scheme.get, call_601620.host, call_601620.base,
                         call_601620.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601620, url, valid)

proc call*(call_601621: Call_DescribeTapes_601606; body: JsonNode;
          Limit: string = ""; Marker: string = ""): Recallable =
  ## describeTapes
  ## Returns a description of the specified Amazon Resource Name (ARN) of virtual tapes. If a <code>TapeARN</code> is not specified, returns a description of all virtual tapes associated with the specified gateway. This operation is only supported in the tape gateway type.
  ##   Limit: string
  ##        : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_601622 = newJObject()
  var body_601623 = newJObject()
  add(query_601622, "Limit", newJString(Limit))
  add(query_601622, "Marker", newJString(Marker))
  if body != nil:
    body_601623 = body
  result = call_601621.call(nil, query_601622, nil, nil, body_601623)

var describeTapes* = Call_DescribeTapes_601606(name: "describeTapes",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeTapes",
    validator: validate_DescribeTapes_601607, base: "/", url: url_DescribeTapes_601608,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUploadBuffer_601624 = ref object of OpenApiRestCall_600438
proc url_DescribeUploadBuffer_601626(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeUploadBuffer_601625(path: JsonNode; query: JsonNode;
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
  var valid_601627 = header.getOrDefault("X-Amz-Date")
  valid_601627 = validateParameter(valid_601627, JString, required = false,
                                 default = nil)
  if valid_601627 != nil:
    section.add "X-Amz-Date", valid_601627
  var valid_601628 = header.getOrDefault("X-Amz-Security-Token")
  valid_601628 = validateParameter(valid_601628, JString, required = false,
                                 default = nil)
  if valid_601628 != nil:
    section.add "X-Amz-Security-Token", valid_601628
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601629 = header.getOrDefault("X-Amz-Target")
  valid_601629 = validateParameter(valid_601629, JString, required = true, default = newJString(
      "StorageGateway_20130630.DescribeUploadBuffer"))
  if valid_601629 != nil:
    section.add "X-Amz-Target", valid_601629
  var valid_601630 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601630 = validateParameter(valid_601630, JString, required = false,
                                 default = nil)
  if valid_601630 != nil:
    section.add "X-Amz-Content-Sha256", valid_601630
  var valid_601631 = header.getOrDefault("X-Amz-Algorithm")
  valid_601631 = validateParameter(valid_601631, JString, required = false,
                                 default = nil)
  if valid_601631 != nil:
    section.add "X-Amz-Algorithm", valid_601631
  var valid_601632 = header.getOrDefault("X-Amz-Signature")
  valid_601632 = validateParameter(valid_601632, JString, required = false,
                                 default = nil)
  if valid_601632 != nil:
    section.add "X-Amz-Signature", valid_601632
  var valid_601633 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601633 = validateParameter(valid_601633, JString, required = false,
                                 default = nil)
  if valid_601633 != nil:
    section.add "X-Amz-SignedHeaders", valid_601633
  var valid_601634 = header.getOrDefault("X-Amz-Credential")
  valid_601634 = validateParameter(valid_601634, JString, required = false,
                                 default = nil)
  if valid_601634 != nil:
    section.add "X-Amz-Credential", valid_601634
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601636: Call_DescribeUploadBuffer_601624; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about the upload buffer of a gateway. This operation is supported for the stored volume, cached volume and tape gateway types.</p> <p>The response includes disk IDs that are configured as upload buffer space, and it includes the amount of upload buffer space allocated and used.</p>
  ## 
  let valid = call_601636.validator(path, query, header, formData, body)
  let scheme = call_601636.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601636.url(scheme.get, call_601636.host, call_601636.base,
                         call_601636.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601636, url, valid)

proc call*(call_601637: Call_DescribeUploadBuffer_601624; body: JsonNode): Recallable =
  ## describeUploadBuffer
  ## <p>Returns information about the upload buffer of a gateway. This operation is supported for the stored volume, cached volume and tape gateway types.</p> <p>The response includes disk IDs that are configured as upload buffer space, and it includes the amount of upload buffer space allocated and used.</p>
  ##   body: JObject (required)
  var body_601638 = newJObject()
  if body != nil:
    body_601638 = body
  result = call_601637.call(nil, nil, nil, nil, body_601638)

var describeUploadBuffer* = Call_DescribeUploadBuffer_601624(
    name: "describeUploadBuffer", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeUploadBuffer",
    validator: validate_DescribeUploadBuffer_601625, base: "/",
    url: url_DescribeUploadBuffer_601626, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeVTLDevices_601639 = ref object of OpenApiRestCall_600438
proc url_DescribeVTLDevices_601641(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeVTLDevices_601640(path: JsonNode; query: JsonNode;
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
  var valid_601642 = query.getOrDefault("Limit")
  valid_601642 = validateParameter(valid_601642, JString, required = false,
                                 default = nil)
  if valid_601642 != nil:
    section.add "Limit", valid_601642
  var valid_601643 = query.getOrDefault("Marker")
  valid_601643 = validateParameter(valid_601643, JString, required = false,
                                 default = nil)
  if valid_601643 != nil:
    section.add "Marker", valid_601643
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601644 = header.getOrDefault("X-Amz-Date")
  valid_601644 = validateParameter(valid_601644, JString, required = false,
                                 default = nil)
  if valid_601644 != nil:
    section.add "X-Amz-Date", valid_601644
  var valid_601645 = header.getOrDefault("X-Amz-Security-Token")
  valid_601645 = validateParameter(valid_601645, JString, required = false,
                                 default = nil)
  if valid_601645 != nil:
    section.add "X-Amz-Security-Token", valid_601645
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601646 = header.getOrDefault("X-Amz-Target")
  valid_601646 = validateParameter(valid_601646, JString, required = true, default = newJString(
      "StorageGateway_20130630.DescribeVTLDevices"))
  if valid_601646 != nil:
    section.add "X-Amz-Target", valid_601646
  var valid_601647 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601647 = validateParameter(valid_601647, JString, required = false,
                                 default = nil)
  if valid_601647 != nil:
    section.add "X-Amz-Content-Sha256", valid_601647
  var valid_601648 = header.getOrDefault("X-Amz-Algorithm")
  valid_601648 = validateParameter(valid_601648, JString, required = false,
                                 default = nil)
  if valid_601648 != nil:
    section.add "X-Amz-Algorithm", valid_601648
  var valid_601649 = header.getOrDefault("X-Amz-Signature")
  valid_601649 = validateParameter(valid_601649, JString, required = false,
                                 default = nil)
  if valid_601649 != nil:
    section.add "X-Amz-Signature", valid_601649
  var valid_601650 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601650 = validateParameter(valid_601650, JString, required = false,
                                 default = nil)
  if valid_601650 != nil:
    section.add "X-Amz-SignedHeaders", valid_601650
  var valid_601651 = header.getOrDefault("X-Amz-Credential")
  valid_601651 = validateParameter(valid_601651, JString, required = false,
                                 default = nil)
  if valid_601651 != nil:
    section.add "X-Amz-Credential", valid_601651
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601653: Call_DescribeVTLDevices_601639; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a description of virtual tape library (VTL) devices for the specified tape gateway. In the response, AWS Storage Gateway returns VTL device information.</p> <p>This operation is only supported in the tape gateway type.</p>
  ## 
  let valid = call_601653.validator(path, query, header, formData, body)
  let scheme = call_601653.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601653.url(scheme.get, call_601653.host, call_601653.base,
                         call_601653.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601653, url, valid)

proc call*(call_601654: Call_DescribeVTLDevices_601639; body: JsonNode;
          Limit: string = ""; Marker: string = ""): Recallable =
  ## describeVTLDevices
  ## <p>Returns a description of virtual tape library (VTL) devices for the specified tape gateway. In the response, AWS Storage Gateway returns VTL device information.</p> <p>This operation is only supported in the tape gateway type.</p>
  ##   Limit: string
  ##        : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_601655 = newJObject()
  var body_601656 = newJObject()
  add(query_601655, "Limit", newJString(Limit))
  add(query_601655, "Marker", newJString(Marker))
  if body != nil:
    body_601656 = body
  result = call_601654.call(nil, query_601655, nil, nil, body_601656)

var describeVTLDevices* = Call_DescribeVTLDevices_601639(
    name: "describeVTLDevices", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeVTLDevices",
    validator: validate_DescribeVTLDevices_601640, base: "/",
    url: url_DescribeVTLDevices_601641, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkingStorage_601657 = ref object of OpenApiRestCall_600438
proc url_DescribeWorkingStorage_601659(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeWorkingStorage_601658(path: JsonNode; query: JsonNode;
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
  var valid_601660 = header.getOrDefault("X-Amz-Date")
  valid_601660 = validateParameter(valid_601660, JString, required = false,
                                 default = nil)
  if valid_601660 != nil:
    section.add "X-Amz-Date", valid_601660
  var valid_601661 = header.getOrDefault("X-Amz-Security-Token")
  valid_601661 = validateParameter(valid_601661, JString, required = false,
                                 default = nil)
  if valid_601661 != nil:
    section.add "X-Amz-Security-Token", valid_601661
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601662 = header.getOrDefault("X-Amz-Target")
  valid_601662 = validateParameter(valid_601662, JString, required = true, default = newJString(
      "StorageGateway_20130630.DescribeWorkingStorage"))
  if valid_601662 != nil:
    section.add "X-Amz-Target", valid_601662
  var valid_601663 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601663 = validateParameter(valid_601663, JString, required = false,
                                 default = nil)
  if valid_601663 != nil:
    section.add "X-Amz-Content-Sha256", valid_601663
  var valid_601664 = header.getOrDefault("X-Amz-Algorithm")
  valid_601664 = validateParameter(valid_601664, JString, required = false,
                                 default = nil)
  if valid_601664 != nil:
    section.add "X-Amz-Algorithm", valid_601664
  var valid_601665 = header.getOrDefault("X-Amz-Signature")
  valid_601665 = validateParameter(valid_601665, JString, required = false,
                                 default = nil)
  if valid_601665 != nil:
    section.add "X-Amz-Signature", valid_601665
  var valid_601666 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601666 = validateParameter(valid_601666, JString, required = false,
                                 default = nil)
  if valid_601666 != nil:
    section.add "X-Amz-SignedHeaders", valid_601666
  var valid_601667 = header.getOrDefault("X-Amz-Credential")
  valid_601667 = validateParameter(valid_601667, JString, required = false,
                                 default = nil)
  if valid_601667 != nil:
    section.add "X-Amz-Credential", valid_601667
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601669: Call_DescribeWorkingStorage_601657; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about the working storage of a gateway. This operation is only supported in the stored volumes gateway type. This operation is deprecated in cached volumes API version (20120630). Use DescribeUploadBuffer instead.</p> <note> <p>Working storage is also referred to as upload buffer. You can also use the DescribeUploadBuffer operation to add upload buffer to a stored volume gateway.</p> </note> <p>The response includes disk IDs that are configured as working storage, and it includes the amount of working storage allocated and used.</p>
  ## 
  let valid = call_601669.validator(path, query, header, formData, body)
  let scheme = call_601669.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601669.url(scheme.get, call_601669.host, call_601669.base,
                         call_601669.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601669, url, valid)

proc call*(call_601670: Call_DescribeWorkingStorage_601657; body: JsonNode): Recallable =
  ## describeWorkingStorage
  ## <p>Returns information about the working storage of a gateway. This operation is only supported in the stored volumes gateway type. This operation is deprecated in cached volumes API version (20120630). Use DescribeUploadBuffer instead.</p> <note> <p>Working storage is also referred to as upload buffer. You can also use the DescribeUploadBuffer operation to add upload buffer to a stored volume gateway.</p> </note> <p>The response includes disk IDs that are configured as working storage, and it includes the amount of working storage allocated and used.</p>
  ##   body: JObject (required)
  var body_601671 = newJObject()
  if body != nil:
    body_601671 = body
  result = call_601670.call(nil, nil, nil, nil, body_601671)

var describeWorkingStorage* = Call_DescribeWorkingStorage_601657(
    name: "describeWorkingStorage", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DescribeWorkingStorage",
    validator: validate_DescribeWorkingStorage_601658, base: "/",
    url: url_DescribeWorkingStorage_601659, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachVolume_601672 = ref object of OpenApiRestCall_600438
proc url_DetachVolume_601674(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DetachVolume_601673(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601675 = header.getOrDefault("X-Amz-Date")
  valid_601675 = validateParameter(valid_601675, JString, required = false,
                                 default = nil)
  if valid_601675 != nil:
    section.add "X-Amz-Date", valid_601675
  var valid_601676 = header.getOrDefault("X-Amz-Security-Token")
  valid_601676 = validateParameter(valid_601676, JString, required = false,
                                 default = nil)
  if valid_601676 != nil:
    section.add "X-Amz-Security-Token", valid_601676
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601677 = header.getOrDefault("X-Amz-Target")
  valid_601677 = validateParameter(valid_601677, JString, required = true, default = newJString(
      "StorageGateway_20130630.DetachVolume"))
  if valid_601677 != nil:
    section.add "X-Amz-Target", valid_601677
  var valid_601678 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601678 = validateParameter(valid_601678, JString, required = false,
                                 default = nil)
  if valid_601678 != nil:
    section.add "X-Amz-Content-Sha256", valid_601678
  var valid_601679 = header.getOrDefault("X-Amz-Algorithm")
  valid_601679 = validateParameter(valid_601679, JString, required = false,
                                 default = nil)
  if valid_601679 != nil:
    section.add "X-Amz-Algorithm", valid_601679
  var valid_601680 = header.getOrDefault("X-Amz-Signature")
  valid_601680 = validateParameter(valid_601680, JString, required = false,
                                 default = nil)
  if valid_601680 != nil:
    section.add "X-Amz-Signature", valid_601680
  var valid_601681 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601681 = validateParameter(valid_601681, JString, required = false,
                                 default = nil)
  if valid_601681 != nil:
    section.add "X-Amz-SignedHeaders", valid_601681
  var valid_601682 = header.getOrDefault("X-Amz-Credential")
  valid_601682 = validateParameter(valid_601682, JString, required = false,
                                 default = nil)
  if valid_601682 != nil:
    section.add "X-Amz-Credential", valid_601682
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601684: Call_DetachVolume_601672; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disconnects a volume from an iSCSI connection and then detaches the volume from the specified gateway. Detaching and attaching a volume enables you to recover your data from one gateway to a different gateway without creating a snapshot. It also makes it easier to move your volumes from an on-premises gateway to a gateway hosted on an Amazon EC2 instance.
  ## 
  let valid = call_601684.validator(path, query, header, formData, body)
  let scheme = call_601684.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601684.url(scheme.get, call_601684.host, call_601684.base,
                         call_601684.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601684, url, valid)

proc call*(call_601685: Call_DetachVolume_601672; body: JsonNode): Recallable =
  ## detachVolume
  ## Disconnects a volume from an iSCSI connection and then detaches the volume from the specified gateway. Detaching and attaching a volume enables you to recover your data from one gateway to a different gateway without creating a snapshot. It also makes it easier to move your volumes from an on-premises gateway to a gateway hosted on an Amazon EC2 instance.
  ##   body: JObject (required)
  var body_601686 = newJObject()
  if body != nil:
    body_601686 = body
  result = call_601685.call(nil, nil, nil, nil, body_601686)

var detachVolume* = Call_DetachVolume_601672(name: "detachVolume",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DetachVolume",
    validator: validate_DetachVolume_601673, base: "/", url: url_DetachVolume_601674,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableGateway_601687 = ref object of OpenApiRestCall_600438
proc url_DisableGateway_601689(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisableGateway_601688(path: JsonNode; query: JsonNode;
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
  var valid_601690 = header.getOrDefault("X-Amz-Date")
  valid_601690 = validateParameter(valid_601690, JString, required = false,
                                 default = nil)
  if valid_601690 != nil:
    section.add "X-Amz-Date", valid_601690
  var valid_601691 = header.getOrDefault("X-Amz-Security-Token")
  valid_601691 = validateParameter(valid_601691, JString, required = false,
                                 default = nil)
  if valid_601691 != nil:
    section.add "X-Amz-Security-Token", valid_601691
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601692 = header.getOrDefault("X-Amz-Target")
  valid_601692 = validateParameter(valid_601692, JString, required = true, default = newJString(
      "StorageGateway_20130630.DisableGateway"))
  if valid_601692 != nil:
    section.add "X-Amz-Target", valid_601692
  var valid_601693 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601693 = validateParameter(valid_601693, JString, required = false,
                                 default = nil)
  if valid_601693 != nil:
    section.add "X-Amz-Content-Sha256", valid_601693
  var valid_601694 = header.getOrDefault("X-Amz-Algorithm")
  valid_601694 = validateParameter(valid_601694, JString, required = false,
                                 default = nil)
  if valid_601694 != nil:
    section.add "X-Amz-Algorithm", valid_601694
  var valid_601695 = header.getOrDefault("X-Amz-Signature")
  valid_601695 = validateParameter(valid_601695, JString, required = false,
                                 default = nil)
  if valid_601695 != nil:
    section.add "X-Amz-Signature", valid_601695
  var valid_601696 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601696 = validateParameter(valid_601696, JString, required = false,
                                 default = nil)
  if valid_601696 != nil:
    section.add "X-Amz-SignedHeaders", valid_601696
  var valid_601697 = header.getOrDefault("X-Amz-Credential")
  valid_601697 = validateParameter(valid_601697, JString, required = false,
                                 default = nil)
  if valid_601697 != nil:
    section.add "X-Amz-Credential", valid_601697
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601699: Call_DisableGateway_601687; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disables a tape gateway when the gateway is no longer functioning. For example, if your gateway VM is damaged, you can disable the gateway so you can recover virtual tapes.</p> <p>Use this operation for a tape gateway that is not reachable or not functioning. This operation is only supported in the tape gateway type.</p> <important> <p>Once a gateway is disabled it cannot be enabled.</p> </important>
  ## 
  let valid = call_601699.validator(path, query, header, formData, body)
  let scheme = call_601699.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601699.url(scheme.get, call_601699.host, call_601699.base,
                         call_601699.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601699, url, valid)

proc call*(call_601700: Call_DisableGateway_601687; body: JsonNode): Recallable =
  ## disableGateway
  ## <p>Disables a tape gateway when the gateway is no longer functioning. For example, if your gateway VM is damaged, you can disable the gateway so you can recover virtual tapes.</p> <p>Use this operation for a tape gateway that is not reachable or not functioning. This operation is only supported in the tape gateway type.</p> <important> <p>Once a gateway is disabled it cannot be enabled.</p> </important>
  ##   body: JObject (required)
  var body_601701 = newJObject()
  if body != nil:
    body_601701 = body
  result = call_601700.call(nil, nil, nil, nil, body_601701)

var disableGateway* = Call_DisableGateway_601687(name: "disableGateway",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.DisableGateway",
    validator: validate_DisableGateway_601688, base: "/", url: url_DisableGateway_601689,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_JoinDomain_601702 = ref object of OpenApiRestCall_600438
proc url_JoinDomain_601704(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_JoinDomain_601703(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601705 = header.getOrDefault("X-Amz-Date")
  valid_601705 = validateParameter(valid_601705, JString, required = false,
                                 default = nil)
  if valid_601705 != nil:
    section.add "X-Amz-Date", valid_601705
  var valid_601706 = header.getOrDefault("X-Amz-Security-Token")
  valid_601706 = validateParameter(valid_601706, JString, required = false,
                                 default = nil)
  if valid_601706 != nil:
    section.add "X-Amz-Security-Token", valid_601706
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601707 = header.getOrDefault("X-Amz-Target")
  valid_601707 = validateParameter(valid_601707, JString, required = true, default = newJString(
      "StorageGateway_20130630.JoinDomain"))
  if valid_601707 != nil:
    section.add "X-Amz-Target", valid_601707
  var valid_601708 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601708 = validateParameter(valid_601708, JString, required = false,
                                 default = nil)
  if valid_601708 != nil:
    section.add "X-Amz-Content-Sha256", valid_601708
  var valid_601709 = header.getOrDefault("X-Amz-Algorithm")
  valid_601709 = validateParameter(valid_601709, JString, required = false,
                                 default = nil)
  if valid_601709 != nil:
    section.add "X-Amz-Algorithm", valid_601709
  var valid_601710 = header.getOrDefault("X-Amz-Signature")
  valid_601710 = validateParameter(valid_601710, JString, required = false,
                                 default = nil)
  if valid_601710 != nil:
    section.add "X-Amz-Signature", valid_601710
  var valid_601711 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601711 = validateParameter(valid_601711, JString, required = false,
                                 default = nil)
  if valid_601711 != nil:
    section.add "X-Amz-SignedHeaders", valid_601711
  var valid_601712 = header.getOrDefault("X-Amz-Credential")
  valid_601712 = validateParameter(valid_601712, JString, required = false,
                                 default = nil)
  if valid_601712 != nil:
    section.add "X-Amz-Credential", valid_601712
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601714: Call_JoinDomain_601702; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a file gateway to an Active Directory domain. This operation is only supported for file gateways that support the SMB file protocol.
  ## 
  let valid = call_601714.validator(path, query, header, formData, body)
  let scheme = call_601714.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601714.url(scheme.get, call_601714.host, call_601714.base,
                         call_601714.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601714, url, valid)

proc call*(call_601715: Call_JoinDomain_601702; body: JsonNode): Recallable =
  ## joinDomain
  ## Adds a file gateway to an Active Directory domain. This operation is only supported for file gateways that support the SMB file protocol.
  ##   body: JObject (required)
  var body_601716 = newJObject()
  if body != nil:
    body_601716 = body
  result = call_601715.call(nil, nil, nil, nil, body_601716)

var joinDomain* = Call_JoinDomain_601702(name: "joinDomain",
                                      meth: HttpMethod.HttpPost,
                                      host: "storagegateway.amazonaws.com", route: "/#X-Amz-Target=StorageGateway_20130630.JoinDomain",
                                      validator: validate_JoinDomain_601703,
                                      base: "/", url: url_JoinDomain_601704,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFileShares_601717 = ref object of OpenApiRestCall_600438
proc url_ListFileShares_601719(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListFileShares_601718(path: JsonNode; query: JsonNode;
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
  var valid_601720 = query.getOrDefault("Limit")
  valid_601720 = validateParameter(valid_601720, JString, required = false,
                                 default = nil)
  if valid_601720 != nil:
    section.add "Limit", valid_601720
  var valid_601721 = query.getOrDefault("Marker")
  valid_601721 = validateParameter(valid_601721, JString, required = false,
                                 default = nil)
  if valid_601721 != nil:
    section.add "Marker", valid_601721
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601722 = header.getOrDefault("X-Amz-Date")
  valid_601722 = validateParameter(valid_601722, JString, required = false,
                                 default = nil)
  if valid_601722 != nil:
    section.add "X-Amz-Date", valid_601722
  var valid_601723 = header.getOrDefault("X-Amz-Security-Token")
  valid_601723 = validateParameter(valid_601723, JString, required = false,
                                 default = nil)
  if valid_601723 != nil:
    section.add "X-Amz-Security-Token", valid_601723
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601724 = header.getOrDefault("X-Amz-Target")
  valid_601724 = validateParameter(valid_601724, JString, required = true, default = newJString(
      "StorageGateway_20130630.ListFileShares"))
  if valid_601724 != nil:
    section.add "X-Amz-Target", valid_601724
  var valid_601725 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601725 = validateParameter(valid_601725, JString, required = false,
                                 default = nil)
  if valid_601725 != nil:
    section.add "X-Amz-Content-Sha256", valid_601725
  var valid_601726 = header.getOrDefault("X-Amz-Algorithm")
  valid_601726 = validateParameter(valid_601726, JString, required = false,
                                 default = nil)
  if valid_601726 != nil:
    section.add "X-Amz-Algorithm", valid_601726
  var valid_601727 = header.getOrDefault("X-Amz-Signature")
  valid_601727 = validateParameter(valid_601727, JString, required = false,
                                 default = nil)
  if valid_601727 != nil:
    section.add "X-Amz-Signature", valid_601727
  var valid_601728 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601728 = validateParameter(valid_601728, JString, required = false,
                                 default = nil)
  if valid_601728 != nil:
    section.add "X-Amz-SignedHeaders", valid_601728
  var valid_601729 = header.getOrDefault("X-Amz-Credential")
  valid_601729 = validateParameter(valid_601729, JString, required = false,
                                 default = nil)
  if valid_601729 != nil:
    section.add "X-Amz-Credential", valid_601729
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601731: Call_ListFileShares_601717; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of the file shares for a specific file gateway, or the list of file shares that belong to the calling user account. This operation is only supported for file gateways.
  ## 
  let valid = call_601731.validator(path, query, header, formData, body)
  let scheme = call_601731.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601731.url(scheme.get, call_601731.host, call_601731.base,
                         call_601731.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601731, url, valid)

proc call*(call_601732: Call_ListFileShares_601717; body: JsonNode;
          Limit: string = ""; Marker: string = ""): Recallable =
  ## listFileShares
  ## Gets a list of the file shares for a specific file gateway, or the list of file shares that belong to the calling user account. This operation is only supported for file gateways.
  ##   Limit: string
  ##        : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_601733 = newJObject()
  var body_601734 = newJObject()
  add(query_601733, "Limit", newJString(Limit))
  add(query_601733, "Marker", newJString(Marker))
  if body != nil:
    body_601734 = body
  result = call_601732.call(nil, query_601733, nil, nil, body_601734)

var listFileShares* = Call_ListFileShares_601717(name: "listFileShares",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.ListFileShares",
    validator: validate_ListFileShares_601718, base: "/", url: url_ListFileShares_601719,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGateways_601735 = ref object of OpenApiRestCall_600438
proc url_ListGateways_601737(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListGateways_601736(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601738 = query.getOrDefault("Limit")
  valid_601738 = validateParameter(valid_601738, JString, required = false,
                                 default = nil)
  if valid_601738 != nil:
    section.add "Limit", valid_601738
  var valid_601739 = query.getOrDefault("Marker")
  valid_601739 = validateParameter(valid_601739, JString, required = false,
                                 default = nil)
  if valid_601739 != nil:
    section.add "Marker", valid_601739
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601740 = header.getOrDefault("X-Amz-Date")
  valid_601740 = validateParameter(valid_601740, JString, required = false,
                                 default = nil)
  if valid_601740 != nil:
    section.add "X-Amz-Date", valid_601740
  var valid_601741 = header.getOrDefault("X-Amz-Security-Token")
  valid_601741 = validateParameter(valid_601741, JString, required = false,
                                 default = nil)
  if valid_601741 != nil:
    section.add "X-Amz-Security-Token", valid_601741
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601742 = header.getOrDefault("X-Amz-Target")
  valid_601742 = validateParameter(valid_601742, JString, required = true, default = newJString(
      "StorageGateway_20130630.ListGateways"))
  if valid_601742 != nil:
    section.add "X-Amz-Target", valid_601742
  var valid_601743 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601743 = validateParameter(valid_601743, JString, required = false,
                                 default = nil)
  if valid_601743 != nil:
    section.add "X-Amz-Content-Sha256", valid_601743
  var valid_601744 = header.getOrDefault("X-Amz-Algorithm")
  valid_601744 = validateParameter(valid_601744, JString, required = false,
                                 default = nil)
  if valid_601744 != nil:
    section.add "X-Amz-Algorithm", valid_601744
  var valid_601745 = header.getOrDefault("X-Amz-Signature")
  valid_601745 = validateParameter(valid_601745, JString, required = false,
                                 default = nil)
  if valid_601745 != nil:
    section.add "X-Amz-Signature", valid_601745
  var valid_601746 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601746 = validateParameter(valid_601746, JString, required = false,
                                 default = nil)
  if valid_601746 != nil:
    section.add "X-Amz-SignedHeaders", valid_601746
  var valid_601747 = header.getOrDefault("X-Amz-Credential")
  valid_601747 = validateParameter(valid_601747, JString, required = false,
                                 default = nil)
  if valid_601747 != nil:
    section.add "X-Amz-Credential", valid_601747
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601749: Call_ListGateways_601735; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists gateways owned by an AWS account in an AWS Region specified in the request. The returned list is ordered by gateway Amazon Resource Name (ARN).</p> <p>By default, the operation returns a maximum of 100 gateways. This operation supports pagination that allows you to optionally reduce the number of gateways returned in a response.</p> <p>If you have more gateways than are returned in a response (that is, the response returns only a truncated list of your gateways), the response contains a marker that you can specify in your next request to fetch the next page of gateways.</p>
  ## 
  let valid = call_601749.validator(path, query, header, formData, body)
  let scheme = call_601749.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601749.url(scheme.get, call_601749.host, call_601749.base,
                         call_601749.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601749, url, valid)

proc call*(call_601750: Call_ListGateways_601735; body: JsonNode; Limit: string = "";
          Marker: string = ""): Recallable =
  ## listGateways
  ## <p>Lists gateways owned by an AWS account in an AWS Region specified in the request. The returned list is ordered by gateway Amazon Resource Name (ARN).</p> <p>By default, the operation returns a maximum of 100 gateways. This operation supports pagination that allows you to optionally reduce the number of gateways returned in a response.</p> <p>If you have more gateways than are returned in a response (that is, the response returns only a truncated list of your gateways), the response contains a marker that you can specify in your next request to fetch the next page of gateways.</p>
  ##   Limit: string
  ##        : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_601751 = newJObject()
  var body_601752 = newJObject()
  add(query_601751, "Limit", newJString(Limit))
  add(query_601751, "Marker", newJString(Marker))
  if body != nil:
    body_601752 = body
  result = call_601750.call(nil, query_601751, nil, nil, body_601752)

var listGateways* = Call_ListGateways_601735(name: "listGateways",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.ListGateways",
    validator: validate_ListGateways_601736, base: "/", url: url_ListGateways_601737,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLocalDisks_601753 = ref object of OpenApiRestCall_600438
proc url_ListLocalDisks_601755(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListLocalDisks_601754(path: JsonNode; query: JsonNode;
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
  var valid_601756 = header.getOrDefault("X-Amz-Date")
  valid_601756 = validateParameter(valid_601756, JString, required = false,
                                 default = nil)
  if valid_601756 != nil:
    section.add "X-Amz-Date", valid_601756
  var valid_601757 = header.getOrDefault("X-Amz-Security-Token")
  valid_601757 = validateParameter(valid_601757, JString, required = false,
                                 default = nil)
  if valid_601757 != nil:
    section.add "X-Amz-Security-Token", valid_601757
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601758 = header.getOrDefault("X-Amz-Target")
  valid_601758 = validateParameter(valid_601758, JString, required = true, default = newJString(
      "StorageGateway_20130630.ListLocalDisks"))
  if valid_601758 != nil:
    section.add "X-Amz-Target", valid_601758
  var valid_601759 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601759 = validateParameter(valid_601759, JString, required = false,
                                 default = nil)
  if valid_601759 != nil:
    section.add "X-Amz-Content-Sha256", valid_601759
  var valid_601760 = header.getOrDefault("X-Amz-Algorithm")
  valid_601760 = validateParameter(valid_601760, JString, required = false,
                                 default = nil)
  if valid_601760 != nil:
    section.add "X-Amz-Algorithm", valid_601760
  var valid_601761 = header.getOrDefault("X-Amz-Signature")
  valid_601761 = validateParameter(valid_601761, JString, required = false,
                                 default = nil)
  if valid_601761 != nil:
    section.add "X-Amz-Signature", valid_601761
  var valid_601762 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601762 = validateParameter(valid_601762, JString, required = false,
                                 default = nil)
  if valid_601762 != nil:
    section.add "X-Amz-SignedHeaders", valid_601762
  var valid_601763 = header.getOrDefault("X-Amz-Credential")
  valid_601763 = validateParameter(valid_601763, JString, required = false,
                                 default = nil)
  if valid_601763 != nil:
    section.add "X-Amz-Credential", valid_601763
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601765: Call_ListLocalDisks_601753; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the gateway's local disks. To specify which gateway to describe, you use the Amazon Resource Name (ARN) of the gateway in the body of the request.</p> <p>The request returns a list of all disks, specifying which are configured as working storage, cache storage, or stored volume or not configured at all. The response includes a <code>DiskStatus</code> field. This field can have a value of present (the disk is available to use), missing (the disk is no longer connected to the gateway), or mismatch (the disk node is occupied by a disk that has incorrect metadata or the disk content is corrupted).</p>
  ## 
  let valid = call_601765.validator(path, query, header, formData, body)
  let scheme = call_601765.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601765.url(scheme.get, call_601765.host, call_601765.base,
                         call_601765.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601765, url, valid)

proc call*(call_601766: Call_ListLocalDisks_601753; body: JsonNode): Recallable =
  ## listLocalDisks
  ## <p>Returns a list of the gateway's local disks. To specify which gateway to describe, you use the Amazon Resource Name (ARN) of the gateway in the body of the request.</p> <p>The request returns a list of all disks, specifying which are configured as working storage, cache storage, or stored volume or not configured at all. The response includes a <code>DiskStatus</code> field. This field can have a value of present (the disk is available to use), missing (the disk is no longer connected to the gateway), or mismatch (the disk node is occupied by a disk that has incorrect metadata or the disk content is corrupted).</p>
  ##   body: JObject (required)
  var body_601767 = newJObject()
  if body != nil:
    body_601767 = body
  result = call_601766.call(nil, nil, nil, nil, body_601767)

var listLocalDisks* = Call_ListLocalDisks_601753(name: "listLocalDisks",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.ListLocalDisks",
    validator: validate_ListLocalDisks_601754, base: "/", url: url_ListLocalDisks_601755,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_601768 = ref object of OpenApiRestCall_600438
proc url_ListTagsForResource_601770(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTagsForResource_601769(path: JsonNode; query: JsonNode;
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
  var valid_601771 = query.getOrDefault("Limit")
  valid_601771 = validateParameter(valid_601771, JString, required = false,
                                 default = nil)
  if valid_601771 != nil:
    section.add "Limit", valid_601771
  var valid_601772 = query.getOrDefault("Marker")
  valid_601772 = validateParameter(valid_601772, JString, required = false,
                                 default = nil)
  if valid_601772 != nil:
    section.add "Marker", valid_601772
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601773 = header.getOrDefault("X-Amz-Date")
  valid_601773 = validateParameter(valid_601773, JString, required = false,
                                 default = nil)
  if valid_601773 != nil:
    section.add "X-Amz-Date", valid_601773
  var valid_601774 = header.getOrDefault("X-Amz-Security-Token")
  valid_601774 = validateParameter(valid_601774, JString, required = false,
                                 default = nil)
  if valid_601774 != nil:
    section.add "X-Amz-Security-Token", valid_601774
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601775 = header.getOrDefault("X-Amz-Target")
  valid_601775 = validateParameter(valid_601775, JString, required = true, default = newJString(
      "StorageGateway_20130630.ListTagsForResource"))
  if valid_601775 != nil:
    section.add "X-Amz-Target", valid_601775
  var valid_601776 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601776 = validateParameter(valid_601776, JString, required = false,
                                 default = nil)
  if valid_601776 != nil:
    section.add "X-Amz-Content-Sha256", valid_601776
  var valid_601777 = header.getOrDefault("X-Amz-Algorithm")
  valid_601777 = validateParameter(valid_601777, JString, required = false,
                                 default = nil)
  if valid_601777 != nil:
    section.add "X-Amz-Algorithm", valid_601777
  var valid_601778 = header.getOrDefault("X-Amz-Signature")
  valid_601778 = validateParameter(valid_601778, JString, required = false,
                                 default = nil)
  if valid_601778 != nil:
    section.add "X-Amz-Signature", valid_601778
  var valid_601779 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601779 = validateParameter(valid_601779, JString, required = false,
                                 default = nil)
  if valid_601779 != nil:
    section.add "X-Amz-SignedHeaders", valid_601779
  var valid_601780 = header.getOrDefault("X-Amz-Credential")
  valid_601780 = validateParameter(valid_601780, JString, required = false,
                                 default = nil)
  if valid_601780 != nil:
    section.add "X-Amz-Credential", valid_601780
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601782: Call_ListTagsForResource_601768; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags that have been added to the specified resource. This operation is only supported in the cached volume, stored volume and tape gateway type.
  ## 
  let valid = call_601782.validator(path, query, header, formData, body)
  let scheme = call_601782.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601782.url(scheme.get, call_601782.host, call_601782.base,
                         call_601782.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601782, url, valid)

proc call*(call_601783: Call_ListTagsForResource_601768; body: JsonNode;
          Limit: string = ""; Marker: string = ""): Recallable =
  ## listTagsForResource
  ## Lists the tags that have been added to the specified resource. This operation is only supported in the cached volume, stored volume and tape gateway type.
  ##   Limit: string
  ##        : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_601784 = newJObject()
  var body_601785 = newJObject()
  add(query_601784, "Limit", newJString(Limit))
  add(query_601784, "Marker", newJString(Marker))
  if body != nil:
    body_601785 = body
  result = call_601783.call(nil, query_601784, nil, nil, body_601785)

var listTagsForResource* = Call_ListTagsForResource_601768(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.ListTagsForResource",
    validator: validate_ListTagsForResource_601769, base: "/",
    url: url_ListTagsForResource_601770, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTapes_601786 = ref object of OpenApiRestCall_600438
proc url_ListTapes_601788(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTapes_601787(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601789 = query.getOrDefault("Limit")
  valid_601789 = validateParameter(valid_601789, JString, required = false,
                                 default = nil)
  if valid_601789 != nil:
    section.add "Limit", valid_601789
  var valid_601790 = query.getOrDefault("Marker")
  valid_601790 = validateParameter(valid_601790, JString, required = false,
                                 default = nil)
  if valid_601790 != nil:
    section.add "Marker", valid_601790
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601791 = header.getOrDefault("X-Amz-Date")
  valid_601791 = validateParameter(valid_601791, JString, required = false,
                                 default = nil)
  if valid_601791 != nil:
    section.add "X-Amz-Date", valid_601791
  var valid_601792 = header.getOrDefault("X-Amz-Security-Token")
  valid_601792 = validateParameter(valid_601792, JString, required = false,
                                 default = nil)
  if valid_601792 != nil:
    section.add "X-Amz-Security-Token", valid_601792
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601793 = header.getOrDefault("X-Amz-Target")
  valid_601793 = validateParameter(valid_601793, JString, required = true, default = newJString(
      "StorageGateway_20130630.ListTapes"))
  if valid_601793 != nil:
    section.add "X-Amz-Target", valid_601793
  var valid_601794 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601794 = validateParameter(valid_601794, JString, required = false,
                                 default = nil)
  if valid_601794 != nil:
    section.add "X-Amz-Content-Sha256", valid_601794
  var valid_601795 = header.getOrDefault("X-Amz-Algorithm")
  valid_601795 = validateParameter(valid_601795, JString, required = false,
                                 default = nil)
  if valid_601795 != nil:
    section.add "X-Amz-Algorithm", valid_601795
  var valid_601796 = header.getOrDefault("X-Amz-Signature")
  valid_601796 = validateParameter(valid_601796, JString, required = false,
                                 default = nil)
  if valid_601796 != nil:
    section.add "X-Amz-Signature", valid_601796
  var valid_601797 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601797 = validateParameter(valid_601797, JString, required = false,
                                 default = nil)
  if valid_601797 != nil:
    section.add "X-Amz-SignedHeaders", valid_601797
  var valid_601798 = header.getOrDefault("X-Amz-Credential")
  valid_601798 = validateParameter(valid_601798, JString, required = false,
                                 default = nil)
  if valid_601798 != nil:
    section.add "X-Amz-Credential", valid_601798
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601800: Call_ListTapes_601786; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists virtual tapes in your virtual tape library (VTL) and your virtual tape shelf (VTS). You specify the tapes to list by specifying one or more tape Amazon Resource Names (ARNs). If you don't specify a tape ARN, the operation lists all virtual tapes in both your VTL and VTS.</p> <p>This operation supports pagination. By default, the operation returns a maximum of up to 100 tapes. You can optionally specify the <code>Limit</code> parameter in the body to limit the number of tapes in the response. If the number of tapes returned in the response is truncated, the response includes a <code>Marker</code> element that you can use in your subsequent request to retrieve the next set of tapes. This operation is only supported in the tape gateway type.</p>
  ## 
  let valid = call_601800.validator(path, query, header, formData, body)
  let scheme = call_601800.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601800.url(scheme.get, call_601800.host, call_601800.base,
                         call_601800.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601800, url, valid)

proc call*(call_601801: Call_ListTapes_601786; body: JsonNode; Limit: string = "";
          Marker: string = ""): Recallable =
  ## listTapes
  ## <p>Lists virtual tapes in your virtual tape library (VTL) and your virtual tape shelf (VTS). You specify the tapes to list by specifying one or more tape Amazon Resource Names (ARNs). If you don't specify a tape ARN, the operation lists all virtual tapes in both your VTL and VTS.</p> <p>This operation supports pagination. By default, the operation returns a maximum of up to 100 tapes. You can optionally specify the <code>Limit</code> parameter in the body to limit the number of tapes in the response. If the number of tapes returned in the response is truncated, the response includes a <code>Marker</code> element that you can use in your subsequent request to retrieve the next set of tapes. This operation is only supported in the tape gateway type.</p>
  ##   Limit: string
  ##        : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_601802 = newJObject()
  var body_601803 = newJObject()
  add(query_601802, "Limit", newJString(Limit))
  add(query_601802, "Marker", newJString(Marker))
  if body != nil:
    body_601803 = body
  result = call_601801.call(nil, query_601802, nil, nil, body_601803)

var listTapes* = Call_ListTapes_601786(name: "listTapes", meth: HttpMethod.HttpPost,
                                    host: "storagegateway.amazonaws.com", route: "/#X-Amz-Target=StorageGateway_20130630.ListTapes",
                                    validator: validate_ListTapes_601787,
                                    base: "/", url: url_ListTapes_601788,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVolumeInitiators_601804 = ref object of OpenApiRestCall_600438
proc url_ListVolumeInitiators_601806(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListVolumeInitiators_601805(path: JsonNode; query: JsonNode;
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
  var valid_601807 = header.getOrDefault("X-Amz-Date")
  valid_601807 = validateParameter(valid_601807, JString, required = false,
                                 default = nil)
  if valid_601807 != nil:
    section.add "X-Amz-Date", valid_601807
  var valid_601808 = header.getOrDefault("X-Amz-Security-Token")
  valid_601808 = validateParameter(valid_601808, JString, required = false,
                                 default = nil)
  if valid_601808 != nil:
    section.add "X-Amz-Security-Token", valid_601808
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601809 = header.getOrDefault("X-Amz-Target")
  valid_601809 = validateParameter(valid_601809, JString, required = true, default = newJString(
      "StorageGateway_20130630.ListVolumeInitiators"))
  if valid_601809 != nil:
    section.add "X-Amz-Target", valid_601809
  var valid_601810 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601810 = validateParameter(valid_601810, JString, required = false,
                                 default = nil)
  if valid_601810 != nil:
    section.add "X-Amz-Content-Sha256", valid_601810
  var valid_601811 = header.getOrDefault("X-Amz-Algorithm")
  valid_601811 = validateParameter(valid_601811, JString, required = false,
                                 default = nil)
  if valid_601811 != nil:
    section.add "X-Amz-Algorithm", valid_601811
  var valid_601812 = header.getOrDefault("X-Amz-Signature")
  valid_601812 = validateParameter(valid_601812, JString, required = false,
                                 default = nil)
  if valid_601812 != nil:
    section.add "X-Amz-Signature", valid_601812
  var valid_601813 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601813 = validateParameter(valid_601813, JString, required = false,
                                 default = nil)
  if valid_601813 != nil:
    section.add "X-Amz-SignedHeaders", valid_601813
  var valid_601814 = header.getOrDefault("X-Amz-Credential")
  valid_601814 = validateParameter(valid_601814, JString, required = false,
                                 default = nil)
  if valid_601814 != nil:
    section.add "X-Amz-Credential", valid_601814
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601816: Call_ListVolumeInitiators_601804; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists iSCSI initiators that are connected to a volume. You can use this operation to determine whether a volume is being used or not. This operation is only supported in the cached volume and stored volume gateway types.
  ## 
  let valid = call_601816.validator(path, query, header, formData, body)
  let scheme = call_601816.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601816.url(scheme.get, call_601816.host, call_601816.base,
                         call_601816.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601816, url, valid)

proc call*(call_601817: Call_ListVolumeInitiators_601804; body: JsonNode): Recallable =
  ## listVolumeInitiators
  ## Lists iSCSI initiators that are connected to a volume. You can use this operation to determine whether a volume is being used or not. This operation is only supported in the cached volume and stored volume gateway types.
  ##   body: JObject (required)
  var body_601818 = newJObject()
  if body != nil:
    body_601818 = body
  result = call_601817.call(nil, nil, nil, nil, body_601818)

var listVolumeInitiators* = Call_ListVolumeInitiators_601804(
    name: "listVolumeInitiators", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.ListVolumeInitiators",
    validator: validate_ListVolumeInitiators_601805, base: "/",
    url: url_ListVolumeInitiators_601806, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVolumeRecoveryPoints_601819 = ref object of OpenApiRestCall_600438
proc url_ListVolumeRecoveryPoints_601821(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListVolumeRecoveryPoints_601820(path: JsonNode; query: JsonNode;
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
  var valid_601822 = header.getOrDefault("X-Amz-Date")
  valid_601822 = validateParameter(valid_601822, JString, required = false,
                                 default = nil)
  if valid_601822 != nil:
    section.add "X-Amz-Date", valid_601822
  var valid_601823 = header.getOrDefault("X-Amz-Security-Token")
  valid_601823 = validateParameter(valid_601823, JString, required = false,
                                 default = nil)
  if valid_601823 != nil:
    section.add "X-Amz-Security-Token", valid_601823
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601824 = header.getOrDefault("X-Amz-Target")
  valid_601824 = validateParameter(valid_601824, JString, required = true, default = newJString(
      "StorageGateway_20130630.ListVolumeRecoveryPoints"))
  if valid_601824 != nil:
    section.add "X-Amz-Target", valid_601824
  var valid_601825 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601825 = validateParameter(valid_601825, JString, required = false,
                                 default = nil)
  if valid_601825 != nil:
    section.add "X-Amz-Content-Sha256", valid_601825
  var valid_601826 = header.getOrDefault("X-Amz-Algorithm")
  valid_601826 = validateParameter(valid_601826, JString, required = false,
                                 default = nil)
  if valid_601826 != nil:
    section.add "X-Amz-Algorithm", valid_601826
  var valid_601827 = header.getOrDefault("X-Amz-Signature")
  valid_601827 = validateParameter(valid_601827, JString, required = false,
                                 default = nil)
  if valid_601827 != nil:
    section.add "X-Amz-Signature", valid_601827
  var valid_601828 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601828 = validateParameter(valid_601828, JString, required = false,
                                 default = nil)
  if valid_601828 != nil:
    section.add "X-Amz-SignedHeaders", valid_601828
  var valid_601829 = header.getOrDefault("X-Amz-Credential")
  valid_601829 = validateParameter(valid_601829, JString, required = false,
                                 default = nil)
  if valid_601829 != nil:
    section.add "X-Amz-Credential", valid_601829
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601831: Call_ListVolumeRecoveryPoints_601819; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the recovery points for a specified gateway. This operation is only supported in the cached volume gateway type.</p> <p>Each cache volume has one recovery point. A volume recovery point is a point in time at which all data of the volume is consistent and from which you can create a snapshot or clone a new cached volume from a source volume. To create a snapshot from a volume recovery point use the <a>CreateSnapshotFromVolumeRecoveryPoint</a> operation.</p>
  ## 
  let valid = call_601831.validator(path, query, header, formData, body)
  let scheme = call_601831.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601831.url(scheme.get, call_601831.host, call_601831.base,
                         call_601831.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601831, url, valid)

proc call*(call_601832: Call_ListVolumeRecoveryPoints_601819; body: JsonNode): Recallable =
  ## listVolumeRecoveryPoints
  ## <p>Lists the recovery points for a specified gateway. This operation is only supported in the cached volume gateway type.</p> <p>Each cache volume has one recovery point. A volume recovery point is a point in time at which all data of the volume is consistent and from which you can create a snapshot or clone a new cached volume from a source volume. To create a snapshot from a volume recovery point use the <a>CreateSnapshotFromVolumeRecoveryPoint</a> operation.</p>
  ##   body: JObject (required)
  var body_601833 = newJObject()
  if body != nil:
    body_601833 = body
  result = call_601832.call(nil, nil, nil, nil, body_601833)

var listVolumeRecoveryPoints* = Call_ListVolumeRecoveryPoints_601819(
    name: "listVolumeRecoveryPoints", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.ListVolumeRecoveryPoints",
    validator: validate_ListVolumeRecoveryPoints_601820, base: "/",
    url: url_ListVolumeRecoveryPoints_601821, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVolumes_601834 = ref object of OpenApiRestCall_600438
proc url_ListVolumes_601836(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListVolumes_601835(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601837 = query.getOrDefault("Limit")
  valid_601837 = validateParameter(valid_601837, JString, required = false,
                                 default = nil)
  if valid_601837 != nil:
    section.add "Limit", valid_601837
  var valid_601838 = query.getOrDefault("Marker")
  valid_601838 = validateParameter(valid_601838, JString, required = false,
                                 default = nil)
  if valid_601838 != nil:
    section.add "Marker", valid_601838
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601839 = header.getOrDefault("X-Amz-Date")
  valid_601839 = validateParameter(valid_601839, JString, required = false,
                                 default = nil)
  if valid_601839 != nil:
    section.add "X-Amz-Date", valid_601839
  var valid_601840 = header.getOrDefault("X-Amz-Security-Token")
  valid_601840 = validateParameter(valid_601840, JString, required = false,
                                 default = nil)
  if valid_601840 != nil:
    section.add "X-Amz-Security-Token", valid_601840
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601841 = header.getOrDefault("X-Amz-Target")
  valid_601841 = validateParameter(valid_601841, JString, required = true, default = newJString(
      "StorageGateway_20130630.ListVolumes"))
  if valid_601841 != nil:
    section.add "X-Amz-Target", valid_601841
  var valid_601842 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601842 = validateParameter(valid_601842, JString, required = false,
                                 default = nil)
  if valid_601842 != nil:
    section.add "X-Amz-Content-Sha256", valid_601842
  var valid_601843 = header.getOrDefault("X-Amz-Algorithm")
  valid_601843 = validateParameter(valid_601843, JString, required = false,
                                 default = nil)
  if valid_601843 != nil:
    section.add "X-Amz-Algorithm", valid_601843
  var valid_601844 = header.getOrDefault("X-Amz-Signature")
  valid_601844 = validateParameter(valid_601844, JString, required = false,
                                 default = nil)
  if valid_601844 != nil:
    section.add "X-Amz-Signature", valid_601844
  var valid_601845 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601845 = validateParameter(valid_601845, JString, required = false,
                                 default = nil)
  if valid_601845 != nil:
    section.add "X-Amz-SignedHeaders", valid_601845
  var valid_601846 = header.getOrDefault("X-Amz-Credential")
  valid_601846 = validateParameter(valid_601846, JString, required = false,
                                 default = nil)
  if valid_601846 != nil:
    section.add "X-Amz-Credential", valid_601846
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601848: Call_ListVolumes_601834; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the iSCSI stored volumes of a gateway. Results are sorted by volume ARN. The response includes only the volume ARNs. If you want additional volume information, use the <a>DescribeStorediSCSIVolumes</a> or the <a>DescribeCachediSCSIVolumes</a> API.</p> <p>The operation supports pagination. By default, the operation returns a maximum of up to 100 volumes. You can optionally specify the <code>Limit</code> field in the body to limit the number of volumes in the response. If the number of volumes returned in the response is truncated, the response includes a Marker field. You can use this Marker value in your subsequent request to retrieve the next set of volumes. This operation is only supported in the cached volume and stored volume gateway types.</p>
  ## 
  let valid = call_601848.validator(path, query, header, formData, body)
  let scheme = call_601848.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601848.url(scheme.get, call_601848.host, call_601848.base,
                         call_601848.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601848, url, valid)

proc call*(call_601849: Call_ListVolumes_601834; body: JsonNode; Limit: string = "";
          Marker: string = ""): Recallable =
  ## listVolumes
  ## <p>Lists the iSCSI stored volumes of a gateway. Results are sorted by volume ARN. The response includes only the volume ARNs. If you want additional volume information, use the <a>DescribeStorediSCSIVolumes</a> or the <a>DescribeCachediSCSIVolumes</a> API.</p> <p>The operation supports pagination. By default, the operation returns a maximum of up to 100 volumes. You can optionally specify the <code>Limit</code> field in the body to limit the number of volumes in the response. If the number of volumes returned in the response is truncated, the response includes a Marker field. You can use this Marker value in your subsequent request to retrieve the next set of volumes. This operation is only supported in the cached volume and stored volume gateway types.</p>
  ##   Limit: string
  ##        : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_601850 = newJObject()
  var body_601851 = newJObject()
  add(query_601850, "Limit", newJString(Limit))
  add(query_601850, "Marker", newJString(Marker))
  if body != nil:
    body_601851 = body
  result = call_601849.call(nil, query_601850, nil, nil, body_601851)

var listVolumes* = Call_ListVolumes_601834(name: "listVolumes",
                                        meth: HttpMethod.HttpPost,
                                        host: "storagegateway.amazonaws.com", route: "/#X-Amz-Target=StorageGateway_20130630.ListVolumes",
                                        validator: validate_ListVolumes_601835,
                                        base: "/", url: url_ListVolumes_601836,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_NotifyWhenUploaded_601852 = ref object of OpenApiRestCall_600438
proc url_NotifyWhenUploaded_601854(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_NotifyWhenUploaded_601853(path: JsonNode; query: JsonNode;
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
  var valid_601855 = header.getOrDefault("X-Amz-Date")
  valid_601855 = validateParameter(valid_601855, JString, required = false,
                                 default = nil)
  if valid_601855 != nil:
    section.add "X-Amz-Date", valid_601855
  var valid_601856 = header.getOrDefault("X-Amz-Security-Token")
  valid_601856 = validateParameter(valid_601856, JString, required = false,
                                 default = nil)
  if valid_601856 != nil:
    section.add "X-Amz-Security-Token", valid_601856
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601857 = header.getOrDefault("X-Amz-Target")
  valid_601857 = validateParameter(valid_601857, JString, required = true, default = newJString(
      "StorageGateway_20130630.NotifyWhenUploaded"))
  if valid_601857 != nil:
    section.add "X-Amz-Target", valid_601857
  var valid_601858 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601858 = validateParameter(valid_601858, JString, required = false,
                                 default = nil)
  if valid_601858 != nil:
    section.add "X-Amz-Content-Sha256", valid_601858
  var valid_601859 = header.getOrDefault("X-Amz-Algorithm")
  valid_601859 = validateParameter(valid_601859, JString, required = false,
                                 default = nil)
  if valid_601859 != nil:
    section.add "X-Amz-Algorithm", valid_601859
  var valid_601860 = header.getOrDefault("X-Amz-Signature")
  valid_601860 = validateParameter(valid_601860, JString, required = false,
                                 default = nil)
  if valid_601860 != nil:
    section.add "X-Amz-Signature", valid_601860
  var valid_601861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601861 = validateParameter(valid_601861, JString, required = false,
                                 default = nil)
  if valid_601861 != nil:
    section.add "X-Amz-SignedHeaders", valid_601861
  var valid_601862 = header.getOrDefault("X-Amz-Credential")
  valid_601862 = validateParameter(valid_601862, JString, required = false,
                                 default = nil)
  if valid_601862 != nil:
    section.add "X-Amz-Credential", valid_601862
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601864: Call_NotifyWhenUploaded_601852; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sends you notification through CloudWatch Events when all files written to your file share have been uploaded to Amazon S3.</p> <p>AWS Storage Gateway can send a notification through Amazon CloudWatch Events when all files written to your file share up to that point in time have been uploaded to Amazon S3. These files include files written to the file share up to the time that you make a request for notification. When the upload is done, Storage Gateway sends you notification through an Amazon CloudWatch Event. You can configure CloudWatch Events to send the notification through event targets such as Amazon SNS or AWS Lambda function. This operation is only supported for file gateways.</p> <p>For more information, see Getting File Upload Notification in the Storage Gateway User Guide (https://docs.aws.amazon.com/storagegateway/latest/userguide/monitoring-file-gateway.html#get-upload-notification). </p>
  ## 
  let valid = call_601864.validator(path, query, header, formData, body)
  let scheme = call_601864.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601864.url(scheme.get, call_601864.host, call_601864.base,
                         call_601864.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601864, url, valid)

proc call*(call_601865: Call_NotifyWhenUploaded_601852; body: JsonNode): Recallable =
  ## notifyWhenUploaded
  ## <p>Sends you notification through CloudWatch Events when all files written to your file share have been uploaded to Amazon S3.</p> <p>AWS Storage Gateway can send a notification through Amazon CloudWatch Events when all files written to your file share up to that point in time have been uploaded to Amazon S3. These files include files written to the file share up to the time that you make a request for notification. When the upload is done, Storage Gateway sends you notification through an Amazon CloudWatch Event. You can configure CloudWatch Events to send the notification through event targets such as Amazon SNS or AWS Lambda function. This operation is only supported for file gateways.</p> <p>For more information, see Getting File Upload Notification in the Storage Gateway User Guide (https://docs.aws.amazon.com/storagegateway/latest/userguide/monitoring-file-gateway.html#get-upload-notification). </p>
  ##   body: JObject (required)
  var body_601866 = newJObject()
  if body != nil:
    body_601866 = body
  result = call_601865.call(nil, nil, nil, nil, body_601866)

var notifyWhenUploaded* = Call_NotifyWhenUploaded_601852(
    name: "notifyWhenUploaded", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.NotifyWhenUploaded",
    validator: validate_NotifyWhenUploaded_601853, base: "/",
    url: url_NotifyWhenUploaded_601854, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RefreshCache_601867 = ref object of OpenApiRestCall_600438
proc url_RefreshCache_601869(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RefreshCache_601868(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601870 = header.getOrDefault("X-Amz-Date")
  valid_601870 = validateParameter(valid_601870, JString, required = false,
                                 default = nil)
  if valid_601870 != nil:
    section.add "X-Amz-Date", valid_601870
  var valid_601871 = header.getOrDefault("X-Amz-Security-Token")
  valid_601871 = validateParameter(valid_601871, JString, required = false,
                                 default = nil)
  if valid_601871 != nil:
    section.add "X-Amz-Security-Token", valid_601871
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601872 = header.getOrDefault("X-Amz-Target")
  valid_601872 = validateParameter(valid_601872, JString, required = true, default = newJString(
      "StorageGateway_20130630.RefreshCache"))
  if valid_601872 != nil:
    section.add "X-Amz-Target", valid_601872
  var valid_601873 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601873 = validateParameter(valid_601873, JString, required = false,
                                 default = nil)
  if valid_601873 != nil:
    section.add "X-Amz-Content-Sha256", valid_601873
  var valid_601874 = header.getOrDefault("X-Amz-Algorithm")
  valid_601874 = validateParameter(valid_601874, JString, required = false,
                                 default = nil)
  if valid_601874 != nil:
    section.add "X-Amz-Algorithm", valid_601874
  var valid_601875 = header.getOrDefault("X-Amz-Signature")
  valid_601875 = validateParameter(valid_601875, JString, required = false,
                                 default = nil)
  if valid_601875 != nil:
    section.add "X-Amz-Signature", valid_601875
  var valid_601876 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601876 = validateParameter(valid_601876, JString, required = false,
                                 default = nil)
  if valid_601876 != nil:
    section.add "X-Amz-SignedHeaders", valid_601876
  var valid_601877 = header.getOrDefault("X-Amz-Credential")
  valid_601877 = validateParameter(valid_601877, JString, required = false,
                                 default = nil)
  if valid_601877 != nil:
    section.add "X-Amz-Credential", valid_601877
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601879: Call_RefreshCache_601867; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Refreshes the cache for the specified file share. This operation finds objects in the Amazon S3 bucket that were added, removed or replaced since the gateway last listed the bucket's contents and cached the results. This operation is only supported in the file gateway type. You can subscribe to be notified through an Amazon CloudWatch event when your RefreshCache operation completes. For more information, see <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/monitoring-file-gateway.html#get-notification">Getting Notified About File Operations</a>.</p> <p>When this API is called, it only initiates the refresh operation. When the API call completes and returns a success code, it doesn't necessarily mean that the file refresh has completed. You should use the refresh-complete notification to determine that the operation has completed before you check for new files on the gateway file share. You can subscribe to be notified through an CloudWatch event when your <code>RefreshCache</code> operation completes. </p>
  ## 
  let valid = call_601879.validator(path, query, header, formData, body)
  let scheme = call_601879.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601879.url(scheme.get, call_601879.host, call_601879.base,
                         call_601879.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601879, url, valid)

proc call*(call_601880: Call_RefreshCache_601867; body: JsonNode): Recallable =
  ## refreshCache
  ## <p>Refreshes the cache for the specified file share. This operation finds objects in the Amazon S3 bucket that were added, removed or replaced since the gateway last listed the bucket's contents and cached the results. This operation is only supported in the file gateway type. You can subscribe to be notified through an Amazon CloudWatch event when your RefreshCache operation completes. For more information, see <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/monitoring-file-gateway.html#get-notification">Getting Notified About File Operations</a>.</p> <p>When this API is called, it only initiates the refresh operation. When the API call completes and returns a success code, it doesn't necessarily mean that the file refresh has completed. You should use the refresh-complete notification to determine that the operation has completed before you check for new files on the gateway file share. You can subscribe to be notified through an CloudWatch event when your <code>RefreshCache</code> operation completes. </p>
  ##   body: JObject (required)
  var body_601881 = newJObject()
  if body != nil:
    body_601881 = body
  result = call_601880.call(nil, nil, nil, nil, body_601881)

var refreshCache* = Call_RefreshCache_601867(name: "refreshCache",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.RefreshCache",
    validator: validate_RefreshCache_601868, base: "/", url: url_RefreshCache_601869,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveTagsFromResource_601882 = ref object of OpenApiRestCall_600438
proc url_RemoveTagsFromResource_601884(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RemoveTagsFromResource_601883(path: JsonNode; query: JsonNode;
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
  var valid_601885 = header.getOrDefault("X-Amz-Date")
  valid_601885 = validateParameter(valid_601885, JString, required = false,
                                 default = nil)
  if valid_601885 != nil:
    section.add "X-Amz-Date", valid_601885
  var valid_601886 = header.getOrDefault("X-Amz-Security-Token")
  valid_601886 = validateParameter(valid_601886, JString, required = false,
                                 default = nil)
  if valid_601886 != nil:
    section.add "X-Amz-Security-Token", valid_601886
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601887 = header.getOrDefault("X-Amz-Target")
  valid_601887 = validateParameter(valid_601887, JString, required = true, default = newJString(
      "StorageGateway_20130630.RemoveTagsFromResource"))
  if valid_601887 != nil:
    section.add "X-Amz-Target", valid_601887
  var valid_601888 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601888 = validateParameter(valid_601888, JString, required = false,
                                 default = nil)
  if valid_601888 != nil:
    section.add "X-Amz-Content-Sha256", valid_601888
  var valid_601889 = header.getOrDefault("X-Amz-Algorithm")
  valid_601889 = validateParameter(valid_601889, JString, required = false,
                                 default = nil)
  if valid_601889 != nil:
    section.add "X-Amz-Algorithm", valid_601889
  var valid_601890 = header.getOrDefault("X-Amz-Signature")
  valid_601890 = validateParameter(valid_601890, JString, required = false,
                                 default = nil)
  if valid_601890 != nil:
    section.add "X-Amz-Signature", valid_601890
  var valid_601891 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601891 = validateParameter(valid_601891, JString, required = false,
                                 default = nil)
  if valid_601891 != nil:
    section.add "X-Amz-SignedHeaders", valid_601891
  var valid_601892 = header.getOrDefault("X-Amz-Credential")
  valid_601892 = validateParameter(valid_601892, JString, required = false,
                                 default = nil)
  if valid_601892 != nil:
    section.add "X-Amz-Credential", valid_601892
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601894: Call_RemoveTagsFromResource_601882; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from the specified resource. This operation is only supported in the cached volume, stored volume and tape gateway types.
  ## 
  let valid = call_601894.validator(path, query, header, formData, body)
  let scheme = call_601894.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601894.url(scheme.get, call_601894.host, call_601894.base,
                         call_601894.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601894, url, valid)

proc call*(call_601895: Call_RemoveTagsFromResource_601882; body: JsonNode): Recallable =
  ## removeTagsFromResource
  ## Removes one or more tags from the specified resource. This operation is only supported in the cached volume, stored volume and tape gateway types.
  ##   body: JObject (required)
  var body_601896 = newJObject()
  if body != nil:
    body_601896 = body
  result = call_601895.call(nil, nil, nil, nil, body_601896)

var removeTagsFromResource* = Call_RemoveTagsFromResource_601882(
    name: "removeTagsFromResource", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.RemoveTagsFromResource",
    validator: validate_RemoveTagsFromResource_601883, base: "/",
    url: url_RemoveTagsFromResource_601884, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResetCache_601897 = ref object of OpenApiRestCall_600438
proc url_ResetCache_601899(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ResetCache_601898(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601900 = header.getOrDefault("X-Amz-Date")
  valid_601900 = validateParameter(valid_601900, JString, required = false,
                                 default = nil)
  if valid_601900 != nil:
    section.add "X-Amz-Date", valid_601900
  var valid_601901 = header.getOrDefault("X-Amz-Security-Token")
  valid_601901 = validateParameter(valid_601901, JString, required = false,
                                 default = nil)
  if valid_601901 != nil:
    section.add "X-Amz-Security-Token", valid_601901
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601902 = header.getOrDefault("X-Amz-Target")
  valid_601902 = validateParameter(valid_601902, JString, required = true, default = newJString(
      "StorageGateway_20130630.ResetCache"))
  if valid_601902 != nil:
    section.add "X-Amz-Target", valid_601902
  var valid_601903 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601903 = validateParameter(valid_601903, JString, required = false,
                                 default = nil)
  if valid_601903 != nil:
    section.add "X-Amz-Content-Sha256", valid_601903
  var valid_601904 = header.getOrDefault("X-Amz-Algorithm")
  valid_601904 = validateParameter(valid_601904, JString, required = false,
                                 default = nil)
  if valid_601904 != nil:
    section.add "X-Amz-Algorithm", valid_601904
  var valid_601905 = header.getOrDefault("X-Amz-Signature")
  valid_601905 = validateParameter(valid_601905, JString, required = false,
                                 default = nil)
  if valid_601905 != nil:
    section.add "X-Amz-Signature", valid_601905
  var valid_601906 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601906 = validateParameter(valid_601906, JString, required = false,
                                 default = nil)
  if valid_601906 != nil:
    section.add "X-Amz-SignedHeaders", valid_601906
  var valid_601907 = header.getOrDefault("X-Amz-Credential")
  valid_601907 = validateParameter(valid_601907, JString, required = false,
                                 default = nil)
  if valid_601907 != nil:
    section.add "X-Amz-Credential", valid_601907
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601909: Call_ResetCache_601897; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Resets all cache disks that have encountered a error and makes the disks available for reconfiguration as cache storage. If your cache disk encounters a error, the gateway prevents read and write operations on virtual tapes in the gateway. For example, an error can occur when a disk is corrupted or removed from the gateway. When a cache is reset, the gateway loses its cache storage. At this point you can reconfigure the disks as cache disks. This operation is only supported in the cached volume and tape types.</p> <important> <p>If the cache disk you are resetting contains data that has not been uploaded to Amazon S3 yet, that data can be lost. After you reset cache disks, there will be no configured cache disks left in the gateway, so you must configure at least one new cache disk for your gateway to function properly.</p> </important>
  ## 
  let valid = call_601909.validator(path, query, header, formData, body)
  let scheme = call_601909.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601909.url(scheme.get, call_601909.host, call_601909.base,
                         call_601909.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601909, url, valid)

proc call*(call_601910: Call_ResetCache_601897; body: JsonNode): Recallable =
  ## resetCache
  ## <p>Resets all cache disks that have encountered a error and makes the disks available for reconfiguration as cache storage. If your cache disk encounters a error, the gateway prevents read and write operations on virtual tapes in the gateway. For example, an error can occur when a disk is corrupted or removed from the gateway. When a cache is reset, the gateway loses its cache storage. At this point you can reconfigure the disks as cache disks. This operation is only supported in the cached volume and tape types.</p> <important> <p>If the cache disk you are resetting contains data that has not been uploaded to Amazon S3 yet, that data can be lost. After you reset cache disks, there will be no configured cache disks left in the gateway, so you must configure at least one new cache disk for your gateway to function properly.</p> </important>
  ##   body: JObject (required)
  var body_601911 = newJObject()
  if body != nil:
    body_601911 = body
  result = call_601910.call(nil, nil, nil, nil, body_601911)

var resetCache* = Call_ResetCache_601897(name: "resetCache",
                                      meth: HttpMethod.HttpPost,
                                      host: "storagegateway.amazonaws.com", route: "/#X-Amz-Target=StorageGateway_20130630.ResetCache",
                                      validator: validate_ResetCache_601898,
                                      base: "/", url: url_ResetCache_601899,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_RetrieveTapeArchive_601912 = ref object of OpenApiRestCall_600438
proc url_RetrieveTapeArchive_601914(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RetrieveTapeArchive_601913(path: JsonNode; query: JsonNode;
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
  var valid_601915 = header.getOrDefault("X-Amz-Date")
  valid_601915 = validateParameter(valid_601915, JString, required = false,
                                 default = nil)
  if valid_601915 != nil:
    section.add "X-Amz-Date", valid_601915
  var valid_601916 = header.getOrDefault("X-Amz-Security-Token")
  valid_601916 = validateParameter(valid_601916, JString, required = false,
                                 default = nil)
  if valid_601916 != nil:
    section.add "X-Amz-Security-Token", valid_601916
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601917 = header.getOrDefault("X-Amz-Target")
  valid_601917 = validateParameter(valid_601917, JString, required = true, default = newJString(
      "StorageGateway_20130630.RetrieveTapeArchive"))
  if valid_601917 != nil:
    section.add "X-Amz-Target", valid_601917
  var valid_601918 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601918 = validateParameter(valid_601918, JString, required = false,
                                 default = nil)
  if valid_601918 != nil:
    section.add "X-Amz-Content-Sha256", valid_601918
  var valid_601919 = header.getOrDefault("X-Amz-Algorithm")
  valid_601919 = validateParameter(valid_601919, JString, required = false,
                                 default = nil)
  if valid_601919 != nil:
    section.add "X-Amz-Algorithm", valid_601919
  var valid_601920 = header.getOrDefault("X-Amz-Signature")
  valid_601920 = validateParameter(valid_601920, JString, required = false,
                                 default = nil)
  if valid_601920 != nil:
    section.add "X-Amz-Signature", valid_601920
  var valid_601921 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601921 = validateParameter(valid_601921, JString, required = false,
                                 default = nil)
  if valid_601921 != nil:
    section.add "X-Amz-SignedHeaders", valid_601921
  var valid_601922 = header.getOrDefault("X-Amz-Credential")
  valid_601922 = validateParameter(valid_601922, JString, required = false,
                                 default = nil)
  if valid_601922 != nil:
    section.add "X-Amz-Credential", valid_601922
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601924: Call_RetrieveTapeArchive_601912; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves an archived virtual tape from the virtual tape shelf (VTS) to a tape gateway. Virtual tapes archived in the VTS are not associated with any gateway. However after a tape is retrieved, it is associated with a gateway, even though it is also listed in the VTS, that is, archive. This operation is only supported in the tape gateway type.</p> <p>Once a tape is successfully retrieved to a gateway, it cannot be retrieved again to another gateway. You must archive the tape again before you can retrieve it to another gateway. This operation is only supported in the tape gateway type.</p>
  ## 
  let valid = call_601924.validator(path, query, header, formData, body)
  let scheme = call_601924.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601924.url(scheme.get, call_601924.host, call_601924.base,
                         call_601924.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601924, url, valid)

proc call*(call_601925: Call_RetrieveTapeArchive_601912; body: JsonNode): Recallable =
  ## retrieveTapeArchive
  ## <p>Retrieves an archived virtual tape from the virtual tape shelf (VTS) to a tape gateway. Virtual tapes archived in the VTS are not associated with any gateway. However after a tape is retrieved, it is associated with a gateway, even though it is also listed in the VTS, that is, archive. This operation is only supported in the tape gateway type.</p> <p>Once a tape is successfully retrieved to a gateway, it cannot be retrieved again to another gateway. You must archive the tape again before you can retrieve it to another gateway. This operation is only supported in the tape gateway type.</p>
  ##   body: JObject (required)
  var body_601926 = newJObject()
  if body != nil:
    body_601926 = body
  result = call_601925.call(nil, nil, nil, nil, body_601926)

var retrieveTapeArchive* = Call_RetrieveTapeArchive_601912(
    name: "retrieveTapeArchive", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.RetrieveTapeArchive",
    validator: validate_RetrieveTapeArchive_601913, base: "/",
    url: url_RetrieveTapeArchive_601914, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RetrieveTapeRecoveryPoint_601927 = ref object of OpenApiRestCall_600438
proc url_RetrieveTapeRecoveryPoint_601929(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RetrieveTapeRecoveryPoint_601928(path: JsonNode; query: JsonNode;
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
  var valid_601930 = header.getOrDefault("X-Amz-Date")
  valid_601930 = validateParameter(valid_601930, JString, required = false,
                                 default = nil)
  if valid_601930 != nil:
    section.add "X-Amz-Date", valid_601930
  var valid_601931 = header.getOrDefault("X-Amz-Security-Token")
  valid_601931 = validateParameter(valid_601931, JString, required = false,
                                 default = nil)
  if valid_601931 != nil:
    section.add "X-Amz-Security-Token", valid_601931
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601932 = header.getOrDefault("X-Amz-Target")
  valid_601932 = validateParameter(valid_601932, JString, required = true, default = newJString(
      "StorageGateway_20130630.RetrieveTapeRecoveryPoint"))
  if valid_601932 != nil:
    section.add "X-Amz-Target", valid_601932
  var valid_601933 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601933 = validateParameter(valid_601933, JString, required = false,
                                 default = nil)
  if valid_601933 != nil:
    section.add "X-Amz-Content-Sha256", valid_601933
  var valid_601934 = header.getOrDefault("X-Amz-Algorithm")
  valid_601934 = validateParameter(valid_601934, JString, required = false,
                                 default = nil)
  if valid_601934 != nil:
    section.add "X-Amz-Algorithm", valid_601934
  var valid_601935 = header.getOrDefault("X-Amz-Signature")
  valid_601935 = validateParameter(valid_601935, JString, required = false,
                                 default = nil)
  if valid_601935 != nil:
    section.add "X-Amz-Signature", valid_601935
  var valid_601936 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601936 = validateParameter(valid_601936, JString, required = false,
                                 default = nil)
  if valid_601936 != nil:
    section.add "X-Amz-SignedHeaders", valid_601936
  var valid_601937 = header.getOrDefault("X-Amz-Credential")
  valid_601937 = validateParameter(valid_601937, JString, required = false,
                                 default = nil)
  if valid_601937 != nil:
    section.add "X-Amz-Credential", valid_601937
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601939: Call_RetrieveTapeRecoveryPoint_601927; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the recovery point for the specified virtual tape. This operation is only supported in the tape gateway type.</p> <p>A recovery point is a point in time view of a virtual tape at which all the data on the tape is consistent. If your gateway crashes, virtual tapes that have recovery points can be recovered to a new gateway.</p> <note> <p>The virtual tape can be retrieved to only one gateway. The retrieved tape is read-only. The virtual tape can be retrieved to only a tape gateway. There is no charge for retrieving recovery points.</p> </note>
  ## 
  let valid = call_601939.validator(path, query, header, formData, body)
  let scheme = call_601939.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601939.url(scheme.get, call_601939.host, call_601939.base,
                         call_601939.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601939, url, valid)

proc call*(call_601940: Call_RetrieveTapeRecoveryPoint_601927; body: JsonNode): Recallable =
  ## retrieveTapeRecoveryPoint
  ## <p>Retrieves the recovery point for the specified virtual tape. This operation is only supported in the tape gateway type.</p> <p>A recovery point is a point in time view of a virtual tape at which all the data on the tape is consistent. If your gateway crashes, virtual tapes that have recovery points can be recovered to a new gateway.</p> <note> <p>The virtual tape can be retrieved to only one gateway. The retrieved tape is read-only. The virtual tape can be retrieved to only a tape gateway. There is no charge for retrieving recovery points.</p> </note>
  ##   body: JObject (required)
  var body_601941 = newJObject()
  if body != nil:
    body_601941 = body
  result = call_601940.call(nil, nil, nil, nil, body_601941)

var retrieveTapeRecoveryPoint* = Call_RetrieveTapeRecoveryPoint_601927(
    name: "retrieveTapeRecoveryPoint", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.RetrieveTapeRecoveryPoint",
    validator: validate_RetrieveTapeRecoveryPoint_601928, base: "/",
    url: url_RetrieveTapeRecoveryPoint_601929,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetLocalConsolePassword_601942 = ref object of OpenApiRestCall_600438
proc url_SetLocalConsolePassword_601944(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SetLocalConsolePassword_601943(path: JsonNode; query: JsonNode;
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
  var valid_601945 = header.getOrDefault("X-Amz-Date")
  valid_601945 = validateParameter(valid_601945, JString, required = false,
                                 default = nil)
  if valid_601945 != nil:
    section.add "X-Amz-Date", valid_601945
  var valid_601946 = header.getOrDefault("X-Amz-Security-Token")
  valid_601946 = validateParameter(valid_601946, JString, required = false,
                                 default = nil)
  if valid_601946 != nil:
    section.add "X-Amz-Security-Token", valid_601946
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601947 = header.getOrDefault("X-Amz-Target")
  valid_601947 = validateParameter(valid_601947, JString, required = true, default = newJString(
      "StorageGateway_20130630.SetLocalConsolePassword"))
  if valid_601947 != nil:
    section.add "X-Amz-Target", valid_601947
  var valid_601948 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601948 = validateParameter(valid_601948, JString, required = false,
                                 default = nil)
  if valid_601948 != nil:
    section.add "X-Amz-Content-Sha256", valid_601948
  var valid_601949 = header.getOrDefault("X-Amz-Algorithm")
  valid_601949 = validateParameter(valid_601949, JString, required = false,
                                 default = nil)
  if valid_601949 != nil:
    section.add "X-Amz-Algorithm", valid_601949
  var valid_601950 = header.getOrDefault("X-Amz-Signature")
  valid_601950 = validateParameter(valid_601950, JString, required = false,
                                 default = nil)
  if valid_601950 != nil:
    section.add "X-Amz-Signature", valid_601950
  var valid_601951 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601951 = validateParameter(valid_601951, JString, required = false,
                                 default = nil)
  if valid_601951 != nil:
    section.add "X-Amz-SignedHeaders", valid_601951
  var valid_601952 = header.getOrDefault("X-Amz-Credential")
  valid_601952 = validateParameter(valid_601952, JString, required = false,
                                 default = nil)
  if valid_601952 != nil:
    section.add "X-Amz-Credential", valid_601952
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601954: Call_SetLocalConsolePassword_601942; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the password for your VM local console. When you log in to the local console for the first time, you log in to the VM with the default credentials. We recommend that you set a new password. You don't need to know the default password to set a new password.
  ## 
  let valid = call_601954.validator(path, query, header, formData, body)
  let scheme = call_601954.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601954.url(scheme.get, call_601954.host, call_601954.base,
                         call_601954.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601954, url, valid)

proc call*(call_601955: Call_SetLocalConsolePassword_601942; body: JsonNode): Recallable =
  ## setLocalConsolePassword
  ## Sets the password for your VM local console. When you log in to the local console for the first time, you log in to the VM with the default credentials. We recommend that you set a new password. You don't need to know the default password to set a new password.
  ##   body: JObject (required)
  var body_601956 = newJObject()
  if body != nil:
    body_601956 = body
  result = call_601955.call(nil, nil, nil, nil, body_601956)

var setLocalConsolePassword* = Call_SetLocalConsolePassword_601942(
    name: "setLocalConsolePassword", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.SetLocalConsolePassword",
    validator: validate_SetLocalConsolePassword_601943, base: "/",
    url: url_SetLocalConsolePassword_601944, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetSMBGuestPassword_601957 = ref object of OpenApiRestCall_600438
proc url_SetSMBGuestPassword_601959(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SetSMBGuestPassword_601958(path: JsonNode; query: JsonNode;
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
  var valid_601960 = header.getOrDefault("X-Amz-Date")
  valid_601960 = validateParameter(valid_601960, JString, required = false,
                                 default = nil)
  if valid_601960 != nil:
    section.add "X-Amz-Date", valid_601960
  var valid_601961 = header.getOrDefault("X-Amz-Security-Token")
  valid_601961 = validateParameter(valid_601961, JString, required = false,
                                 default = nil)
  if valid_601961 != nil:
    section.add "X-Amz-Security-Token", valid_601961
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601962 = header.getOrDefault("X-Amz-Target")
  valid_601962 = validateParameter(valid_601962, JString, required = true, default = newJString(
      "StorageGateway_20130630.SetSMBGuestPassword"))
  if valid_601962 != nil:
    section.add "X-Amz-Target", valid_601962
  var valid_601963 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601963 = validateParameter(valid_601963, JString, required = false,
                                 default = nil)
  if valid_601963 != nil:
    section.add "X-Amz-Content-Sha256", valid_601963
  var valid_601964 = header.getOrDefault("X-Amz-Algorithm")
  valid_601964 = validateParameter(valid_601964, JString, required = false,
                                 default = nil)
  if valid_601964 != nil:
    section.add "X-Amz-Algorithm", valid_601964
  var valid_601965 = header.getOrDefault("X-Amz-Signature")
  valid_601965 = validateParameter(valid_601965, JString, required = false,
                                 default = nil)
  if valid_601965 != nil:
    section.add "X-Amz-Signature", valid_601965
  var valid_601966 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601966 = validateParameter(valid_601966, JString, required = false,
                                 default = nil)
  if valid_601966 != nil:
    section.add "X-Amz-SignedHeaders", valid_601966
  var valid_601967 = header.getOrDefault("X-Amz-Credential")
  valid_601967 = validateParameter(valid_601967, JString, required = false,
                                 default = nil)
  if valid_601967 != nil:
    section.add "X-Amz-Credential", valid_601967
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601969: Call_SetSMBGuestPassword_601957; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the password for the guest user <code>smbguest</code>. The <code>smbguest</code> user is the user when the authentication method for the file share is set to <code>GuestAccess</code>.
  ## 
  let valid = call_601969.validator(path, query, header, formData, body)
  let scheme = call_601969.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601969.url(scheme.get, call_601969.host, call_601969.base,
                         call_601969.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601969, url, valid)

proc call*(call_601970: Call_SetSMBGuestPassword_601957; body: JsonNode): Recallable =
  ## setSMBGuestPassword
  ## Sets the password for the guest user <code>smbguest</code>. The <code>smbguest</code> user is the user when the authentication method for the file share is set to <code>GuestAccess</code>.
  ##   body: JObject (required)
  var body_601971 = newJObject()
  if body != nil:
    body_601971 = body
  result = call_601970.call(nil, nil, nil, nil, body_601971)

var setSMBGuestPassword* = Call_SetSMBGuestPassword_601957(
    name: "setSMBGuestPassword", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.SetSMBGuestPassword",
    validator: validate_SetSMBGuestPassword_601958, base: "/",
    url: url_SetSMBGuestPassword_601959, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ShutdownGateway_601972 = ref object of OpenApiRestCall_600438
proc url_ShutdownGateway_601974(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ShutdownGateway_601973(path: JsonNode; query: JsonNode;
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
  var valid_601975 = header.getOrDefault("X-Amz-Date")
  valid_601975 = validateParameter(valid_601975, JString, required = false,
                                 default = nil)
  if valid_601975 != nil:
    section.add "X-Amz-Date", valid_601975
  var valid_601976 = header.getOrDefault("X-Amz-Security-Token")
  valid_601976 = validateParameter(valid_601976, JString, required = false,
                                 default = nil)
  if valid_601976 != nil:
    section.add "X-Amz-Security-Token", valid_601976
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601977 = header.getOrDefault("X-Amz-Target")
  valid_601977 = validateParameter(valid_601977, JString, required = true, default = newJString(
      "StorageGateway_20130630.ShutdownGateway"))
  if valid_601977 != nil:
    section.add "X-Amz-Target", valid_601977
  var valid_601978 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601978 = validateParameter(valid_601978, JString, required = false,
                                 default = nil)
  if valid_601978 != nil:
    section.add "X-Amz-Content-Sha256", valid_601978
  var valid_601979 = header.getOrDefault("X-Amz-Algorithm")
  valid_601979 = validateParameter(valid_601979, JString, required = false,
                                 default = nil)
  if valid_601979 != nil:
    section.add "X-Amz-Algorithm", valid_601979
  var valid_601980 = header.getOrDefault("X-Amz-Signature")
  valid_601980 = validateParameter(valid_601980, JString, required = false,
                                 default = nil)
  if valid_601980 != nil:
    section.add "X-Amz-Signature", valid_601980
  var valid_601981 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601981 = validateParameter(valid_601981, JString, required = false,
                                 default = nil)
  if valid_601981 != nil:
    section.add "X-Amz-SignedHeaders", valid_601981
  var valid_601982 = header.getOrDefault("X-Amz-Credential")
  valid_601982 = validateParameter(valid_601982, JString, required = false,
                                 default = nil)
  if valid_601982 != nil:
    section.add "X-Amz-Credential", valid_601982
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601984: Call_ShutdownGateway_601972; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Shuts down a gateway. To specify which gateway to shut down, use the Amazon Resource Name (ARN) of the gateway in the body of your request.</p> <p>The operation shuts down the gateway service component running in the gateway's virtual machine (VM) and not the host VM.</p> <note> <p>If you want to shut down the VM, it is recommended that you first shut down the gateway component in the VM to avoid unpredictable conditions.</p> </note> <p>After the gateway is shutdown, you cannot call any other API except <a>StartGateway</a>, <a>DescribeGatewayInformation</a>, and <a>ListGateways</a>. For more information, see <a>ActivateGateway</a>. Your applications cannot read from or write to the gateway's storage volumes, and there are no snapshots taken.</p> <note> <p>When you make a shutdown request, you will get a <code>200 OK</code> success response immediately. However, it might take some time for the gateway to shut down. You can call the <a>DescribeGatewayInformation</a> API to check the status. For more information, see <a>ActivateGateway</a>.</p> </note> <p>If do not intend to use the gateway again, you must delete the gateway (using <a>DeleteGateway</a>) to no longer pay software charges associated with the gateway.</p>
  ## 
  let valid = call_601984.validator(path, query, header, formData, body)
  let scheme = call_601984.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601984.url(scheme.get, call_601984.host, call_601984.base,
                         call_601984.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601984, url, valid)

proc call*(call_601985: Call_ShutdownGateway_601972; body: JsonNode): Recallable =
  ## shutdownGateway
  ## <p>Shuts down a gateway. To specify which gateway to shut down, use the Amazon Resource Name (ARN) of the gateway in the body of your request.</p> <p>The operation shuts down the gateway service component running in the gateway's virtual machine (VM) and not the host VM.</p> <note> <p>If you want to shut down the VM, it is recommended that you first shut down the gateway component in the VM to avoid unpredictable conditions.</p> </note> <p>After the gateway is shutdown, you cannot call any other API except <a>StartGateway</a>, <a>DescribeGatewayInformation</a>, and <a>ListGateways</a>. For more information, see <a>ActivateGateway</a>. Your applications cannot read from or write to the gateway's storage volumes, and there are no snapshots taken.</p> <note> <p>When you make a shutdown request, you will get a <code>200 OK</code> success response immediately. However, it might take some time for the gateway to shut down. You can call the <a>DescribeGatewayInformation</a> API to check the status. For more information, see <a>ActivateGateway</a>.</p> </note> <p>If do not intend to use the gateway again, you must delete the gateway (using <a>DeleteGateway</a>) to no longer pay software charges associated with the gateway.</p>
  ##   body: JObject (required)
  var body_601986 = newJObject()
  if body != nil:
    body_601986 = body
  result = call_601985.call(nil, nil, nil, nil, body_601986)

var shutdownGateway* = Call_ShutdownGateway_601972(name: "shutdownGateway",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.ShutdownGateway",
    validator: validate_ShutdownGateway_601973, base: "/", url: url_ShutdownGateway_601974,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartGateway_601987 = ref object of OpenApiRestCall_600438
proc url_StartGateway_601989(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartGateway_601988(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601990 = header.getOrDefault("X-Amz-Date")
  valid_601990 = validateParameter(valid_601990, JString, required = false,
                                 default = nil)
  if valid_601990 != nil:
    section.add "X-Amz-Date", valid_601990
  var valid_601991 = header.getOrDefault("X-Amz-Security-Token")
  valid_601991 = validateParameter(valid_601991, JString, required = false,
                                 default = nil)
  if valid_601991 != nil:
    section.add "X-Amz-Security-Token", valid_601991
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601992 = header.getOrDefault("X-Amz-Target")
  valid_601992 = validateParameter(valid_601992, JString, required = true, default = newJString(
      "StorageGateway_20130630.StartGateway"))
  if valid_601992 != nil:
    section.add "X-Amz-Target", valid_601992
  var valid_601993 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601993 = validateParameter(valid_601993, JString, required = false,
                                 default = nil)
  if valid_601993 != nil:
    section.add "X-Amz-Content-Sha256", valid_601993
  var valid_601994 = header.getOrDefault("X-Amz-Algorithm")
  valid_601994 = validateParameter(valid_601994, JString, required = false,
                                 default = nil)
  if valid_601994 != nil:
    section.add "X-Amz-Algorithm", valid_601994
  var valid_601995 = header.getOrDefault("X-Amz-Signature")
  valid_601995 = validateParameter(valid_601995, JString, required = false,
                                 default = nil)
  if valid_601995 != nil:
    section.add "X-Amz-Signature", valid_601995
  var valid_601996 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601996 = validateParameter(valid_601996, JString, required = false,
                                 default = nil)
  if valid_601996 != nil:
    section.add "X-Amz-SignedHeaders", valid_601996
  var valid_601997 = header.getOrDefault("X-Amz-Credential")
  valid_601997 = validateParameter(valid_601997, JString, required = false,
                                 default = nil)
  if valid_601997 != nil:
    section.add "X-Amz-Credential", valid_601997
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601999: Call_StartGateway_601987; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a gateway that you previously shut down (see <a>ShutdownGateway</a>). After the gateway starts, you can then make other API calls, your applications can read from or write to the gateway's storage volumes and you will be able to take snapshot backups.</p> <note> <p>When you make a request, you will get a 200 OK success response immediately. However, it might take some time for the gateway to be ready. You should call <a>DescribeGatewayInformation</a> and check the status before making any additional API calls. For more information, see <a>ActivateGateway</a>.</p> </note> <p>To specify which gateway to start, use the Amazon Resource Name (ARN) of the gateway in your request.</p>
  ## 
  let valid = call_601999.validator(path, query, header, formData, body)
  let scheme = call_601999.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601999.url(scheme.get, call_601999.host, call_601999.base,
                         call_601999.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601999, url, valid)

proc call*(call_602000: Call_StartGateway_601987; body: JsonNode): Recallable =
  ## startGateway
  ## <p>Starts a gateway that you previously shut down (see <a>ShutdownGateway</a>). After the gateway starts, you can then make other API calls, your applications can read from or write to the gateway's storage volumes and you will be able to take snapshot backups.</p> <note> <p>When you make a request, you will get a 200 OK success response immediately. However, it might take some time for the gateway to be ready. You should call <a>DescribeGatewayInformation</a> and check the status before making any additional API calls. For more information, see <a>ActivateGateway</a>.</p> </note> <p>To specify which gateway to start, use the Amazon Resource Name (ARN) of the gateway in your request.</p>
  ##   body: JObject (required)
  var body_602001 = newJObject()
  if body != nil:
    body_602001 = body
  result = call_602000.call(nil, nil, nil, nil, body_602001)

var startGateway* = Call_StartGateway_601987(name: "startGateway",
    meth: HttpMethod.HttpPost, host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.StartGateway",
    validator: validate_StartGateway_601988, base: "/", url: url_StartGateway_601989,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBandwidthRateLimit_602002 = ref object of OpenApiRestCall_600438
proc url_UpdateBandwidthRateLimit_602004(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateBandwidthRateLimit_602003(path: JsonNode; query: JsonNode;
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
  var valid_602005 = header.getOrDefault("X-Amz-Date")
  valid_602005 = validateParameter(valid_602005, JString, required = false,
                                 default = nil)
  if valid_602005 != nil:
    section.add "X-Amz-Date", valid_602005
  var valid_602006 = header.getOrDefault("X-Amz-Security-Token")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "X-Amz-Security-Token", valid_602006
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602007 = header.getOrDefault("X-Amz-Target")
  valid_602007 = validateParameter(valid_602007, JString, required = true, default = newJString(
      "StorageGateway_20130630.UpdateBandwidthRateLimit"))
  if valid_602007 != nil:
    section.add "X-Amz-Target", valid_602007
  var valid_602008 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602008 = validateParameter(valid_602008, JString, required = false,
                                 default = nil)
  if valid_602008 != nil:
    section.add "X-Amz-Content-Sha256", valid_602008
  var valid_602009 = header.getOrDefault("X-Amz-Algorithm")
  valid_602009 = validateParameter(valid_602009, JString, required = false,
                                 default = nil)
  if valid_602009 != nil:
    section.add "X-Amz-Algorithm", valid_602009
  var valid_602010 = header.getOrDefault("X-Amz-Signature")
  valid_602010 = validateParameter(valid_602010, JString, required = false,
                                 default = nil)
  if valid_602010 != nil:
    section.add "X-Amz-Signature", valid_602010
  var valid_602011 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602011 = validateParameter(valid_602011, JString, required = false,
                                 default = nil)
  if valid_602011 != nil:
    section.add "X-Amz-SignedHeaders", valid_602011
  var valid_602012 = header.getOrDefault("X-Amz-Credential")
  valid_602012 = validateParameter(valid_602012, JString, required = false,
                                 default = nil)
  if valid_602012 != nil:
    section.add "X-Amz-Credential", valid_602012
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602014: Call_UpdateBandwidthRateLimit_602002; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the bandwidth rate limits of a gateway. You can update both the upload and download bandwidth rate limit or specify only one of the two. If you don't set a bandwidth rate limit, the existing rate limit remains.</p> <p>By default, a gateway's bandwidth rate limits are not set. If you don't set any limit, the gateway does not have any limitations on its bandwidth usage and could potentially use the maximum available bandwidth.</p> <p>To specify which gateway to update, use the Amazon Resource Name (ARN) of the gateway in your request.</p>
  ## 
  let valid = call_602014.validator(path, query, header, formData, body)
  let scheme = call_602014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602014.url(scheme.get, call_602014.host, call_602014.base,
                         call_602014.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602014, url, valid)

proc call*(call_602015: Call_UpdateBandwidthRateLimit_602002; body: JsonNode): Recallable =
  ## updateBandwidthRateLimit
  ## <p>Updates the bandwidth rate limits of a gateway. You can update both the upload and download bandwidth rate limit or specify only one of the two. If you don't set a bandwidth rate limit, the existing rate limit remains.</p> <p>By default, a gateway's bandwidth rate limits are not set. If you don't set any limit, the gateway does not have any limitations on its bandwidth usage and could potentially use the maximum available bandwidth.</p> <p>To specify which gateway to update, use the Amazon Resource Name (ARN) of the gateway in your request.</p>
  ##   body: JObject (required)
  var body_602016 = newJObject()
  if body != nil:
    body_602016 = body
  result = call_602015.call(nil, nil, nil, nil, body_602016)

var updateBandwidthRateLimit* = Call_UpdateBandwidthRateLimit_602002(
    name: "updateBandwidthRateLimit", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.UpdateBandwidthRateLimit",
    validator: validate_UpdateBandwidthRateLimit_602003, base: "/",
    url: url_UpdateBandwidthRateLimit_602004, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateChapCredentials_602017 = ref object of OpenApiRestCall_600438
proc url_UpdateChapCredentials_602019(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateChapCredentials_602018(path: JsonNode; query: JsonNode;
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
  var valid_602020 = header.getOrDefault("X-Amz-Date")
  valid_602020 = validateParameter(valid_602020, JString, required = false,
                                 default = nil)
  if valid_602020 != nil:
    section.add "X-Amz-Date", valid_602020
  var valid_602021 = header.getOrDefault("X-Amz-Security-Token")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "X-Amz-Security-Token", valid_602021
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602022 = header.getOrDefault("X-Amz-Target")
  valid_602022 = validateParameter(valid_602022, JString, required = true, default = newJString(
      "StorageGateway_20130630.UpdateChapCredentials"))
  if valid_602022 != nil:
    section.add "X-Amz-Target", valid_602022
  var valid_602023 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602023 = validateParameter(valid_602023, JString, required = false,
                                 default = nil)
  if valid_602023 != nil:
    section.add "X-Amz-Content-Sha256", valid_602023
  var valid_602024 = header.getOrDefault("X-Amz-Algorithm")
  valid_602024 = validateParameter(valid_602024, JString, required = false,
                                 default = nil)
  if valid_602024 != nil:
    section.add "X-Amz-Algorithm", valid_602024
  var valid_602025 = header.getOrDefault("X-Amz-Signature")
  valid_602025 = validateParameter(valid_602025, JString, required = false,
                                 default = nil)
  if valid_602025 != nil:
    section.add "X-Amz-Signature", valid_602025
  var valid_602026 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602026 = validateParameter(valid_602026, JString, required = false,
                                 default = nil)
  if valid_602026 != nil:
    section.add "X-Amz-SignedHeaders", valid_602026
  var valid_602027 = header.getOrDefault("X-Amz-Credential")
  valid_602027 = validateParameter(valid_602027, JString, required = false,
                                 default = nil)
  if valid_602027 != nil:
    section.add "X-Amz-Credential", valid_602027
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602029: Call_UpdateChapCredentials_602017; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the Challenge-Handshake Authentication Protocol (CHAP) credentials for a specified iSCSI target. By default, a gateway does not have CHAP enabled; however, for added security, you might use it.</p> <important> <p>When you update CHAP credentials, all existing connections on the target are closed and initiators must reconnect with the new credentials.</p> </important>
  ## 
  let valid = call_602029.validator(path, query, header, formData, body)
  let scheme = call_602029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602029.url(scheme.get, call_602029.host, call_602029.base,
                         call_602029.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602029, url, valid)

proc call*(call_602030: Call_UpdateChapCredentials_602017; body: JsonNode): Recallable =
  ## updateChapCredentials
  ## <p>Updates the Challenge-Handshake Authentication Protocol (CHAP) credentials for a specified iSCSI target. By default, a gateway does not have CHAP enabled; however, for added security, you might use it.</p> <important> <p>When you update CHAP credentials, all existing connections on the target are closed and initiators must reconnect with the new credentials.</p> </important>
  ##   body: JObject (required)
  var body_602031 = newJObject()
  if body != nil:
    body_602031 = body
  result = call_602030.call(nil, nil, nil, nil, body_602031)

var updateChapCredentials* = Call_UpdateChapCredentials_602017(
    name: "updateChapCredentials", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.UpdateChapCredentials",
    validator: validate_UpdateChapCredentials_602018, base: "/",
    url: url_UpdateChapCredentials_602019, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGatewayInformation_602032 = ref object of OpenApiRestCall_600438
proc url_UpdateGatewayInformation_602034(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateGatewayInformation_602033(path: JsonNode; query: JsonNode;
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
  var valid_602035 = header.getOrDefault("X-Amz-Date")
  valid_602035 = validateParameter(valid_602035, JString, required = false,
                                 default = nil)
  if valid_602035 != nil:
    section.add "X-Amz-Date", valid_602035
  var valid_602036 = header.getOrDefault("X-Amz-Security-Token")
  valid_602036 = validateParameter(valid_602036, JString, required = false,
                                 default = nil)
  if valid_602036 != nil:
    section.add "X-Amz-Security-Token", valid_602036
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602037 = header.getOrDefault("X-Amz-Target")
  valid_602037 = validateParameter(valid_602037, JString, required = true, default = newJString(
      "StorageGateway_20130630.UpdateGatewayInformation"))
  if valid_602037 != nil:
    section.add "X-Amz-Target", valid_602037
  var valid_602038 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602038 = validateParameter(valid_602038, JString, required = false,
                                 default = nil)
  if valid_602038 != nil:
    section.add "X-Amz-Content-Sha256", valid_602038
  var valid_602039 = header.getOrDefault("X-Amz-Algorithm")
  valid_602039 = validateParameter(valid_602039, JString, required = false,
                                 default = nil)
  if valid_602039 != nil:
    section.add "X-Amz-Algorithm", valid_602039
  var valid_602040 = header.getOrDefault("X-Amz-Signature")
  valid_602040 = validateParameter(valid_602040, JString, required = false,
                                 default = nil)
  if valid_602040 != nil:
    section.add "X-Amz-Signature", valid_602040
  var valid_602041 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602041 = validateParameter(valid_602041, JString, required = false,
                                 default = nil)
  if valid_602041 != nil:
    section.add "X-Amz-SignedHeaders", valid_602041
  var valid_602042 = header.getOrDefault("X-Amz-Credential")
  valid_602042 = validateParameter(valid_602042, JString, required = false,
                                 default = nil)
  if valid_602042 != nil:
    section.add "X-Amz-Credential", valid_602042
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602044: Call_UpdateGatewayInformation_602032; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates a gateway's metadata, which includes the gateway's name and time zone. To specify which gateway to update, use the Amazon Resource Name (ARN) of the gateway in your request.</p> <note> <p>For Gateways activated after September 2, 2015, the gateway's ARN contains the gateway ID rather than the gateway name. However, changing the name of the gateway has no effect on the gateway's ARN.</p> </note>
  ## 
  let valid = call_602044.validator(path, query, header, formData, body)
  let scheme = call_602044.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602044.url(scheme.get, call_602044.host, call_602044.base,
                         call_602044.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602044, url, valid)

proc call*(call_602045: Call_UpdateGatewayInformation_602032; body: JsonNode): Recallable =
  ## updateGatewayInformation
  ## <p>Updates a gateway's metadata, which includes the gateway's name and time zone. To specify which gateway to update, use the Amazon Resource Name (ARN) of the gateway in your request.</p> <note> <p>For Gateways activated after September 2, 2015, the gateway's ARN contains the gateway ID rather than the gateway name. However, changing the name of the gateway has no effect on the gateway's ARN.</p> </note>
  ##   body: JObject (required)
  var body_602046 = newJObject()
  if body != nil:
    body_602046 = body
  result = call_602045.call(nil, nil, nil, nil, body_602046)

var updateGatewayInformation* = Call_UpdateGatewayInformation_602032(
    name: "updateGatewayInformation", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.UpdateGatewayInformation",
    validator: validate_UpdateGatewayInformation_602033, base: "/",
    url: url_UpdateGatewayInformation_602034, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGatewaySoftwareNow_602047 = ref object of OpenApiRestCall_600438
proc url_UpdateGatewaySoftwareNow_602049(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateGatewaySoftwareNow_602048(path: JsonNode; query: JsonNode;
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
  var valid_602050 = header.getOrDefault("X-Amz-Date")
  valid_602050 = validateParameter(valid_602050, JString, required = false,
                                 default = nil)
  if valid_602050 != nil:
    section.add "X-Amz-Date", valid_602050
  var valid_602051 = header.getOrDefault("X-Amz-Security-Token")
  valid_602051 = validateParameter(valid_602051, JString, required = false,
                                 default = nil)
  if valid_602051 != nil:
    section.add "X-Amz-Security-Token", valid_602051
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602052 = header.getOrDefault("X-Amz-Target")
  valid_602052 = validateParameter(valid_602052, JString, required = true, default = newJString(
      "StorageGateway_20130630.UpdateGatewaySoftwareNow"))
  if valid_602052 != nil:
    section.add "X-Amz-Target", valid_602052
  var valid_602053 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602053 = validateParameter(valid_602053, JString, required = false,
                                 default = nil)
  if valid_602053 != nil:
    section.add "X-Amz-Content-Sha256", valid_602053
  var valid_602054 = header.getOrDefault("X-Amz-Algorithm")
  valid_602054 = validateParameter(valid_602054, JString, required = false,
                                 default = nil)
  if valid_602054 != nil:
    section.add "X-Amz-Algorithm", valid_602054
  var valid_602055 = header.getOrDefault("X-Amz-Signature")
  valid_602055 = validateParameter(valid_602055, JString, required = false,
                                 default = nil)
  if valid_602055 != nil:
    section.add "X-Amz-Signature", valid_602055
  var valid_602056 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602056 = validateParameter(valid_602056, JString, required = false,
                                 default = nil)
  if valid_602056 != nil:
    section.add "X-Amz-SignedHeaders", valid_602056
  var valid_602057 = header.getOrDefault("X-Amz-Credential")
  valid_602057 = validateParameter(valid_602057, JString, required = false,
                                 default = nil)
  if valid_602057 != nil:
    section.add "X-Amz-Credential", valid_602057
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602059: Call_UpdateGatewaySoftwareNow_602047; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the gateway virtual machine (VM) software. The request immediately triggers the software update.</p> <note> <p>When you make this request, you get a <code>200 OK</code> success response immediately. However, it might take some time for the update to complete. You can call <a>DescribeGatewayInformation</a> to verify the gateway is in the <code>STATE_RUNNING</code> state.</p> </note> <important> <p>A software update forces a system restart of your gateway. You can minimize the chance of any disruption to your applications by increasing your iSCSI Initiators' timeouts. For more information about increasing iSCSI Initiator timeouts for Windows and Linux, see <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/ConfiguringiSCSIClientInitiatorWindowsClient.html#CustomizeWindowsiSCSISettings">Customizing Your Windows iSCSI Settings</a> and <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/ConfiguringiSCSIClientInitiatorRedHatClient.html#CustomizeLinuxiSCSISettings">Customizing Your Linux iSCSI Settings</a>, respectively.</p> </important>
  ## 
  let valid = call_602059.validator(path, query, header, formData, body)
  let scheme = call_602059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602059.url(scheme.get, call_602059.host, call_602059.base,
                         call_602059.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602059, url, valid)

proc call*(call_602060: Call_UpdateGatewaySoftwareNow_602047; body: JsonNode): Recallable =
  ## updateGatewaySoftwareNow
  ## <p>Updates the gateway virtual machine (VM) software. The request immediately triggers the software update.</p> <note> <p>When you make this request, you get a <code>200 OK</code> success response immediately. However, it might take some time for the update to complete. You can call <a>DescribeGatewayInformation</a> to verify the gateway is in the <code>STATE_RUNNING</code> state.</p> </note> <important> <p>A software update forces a system restart of your gateway. You can minimize the chance of any disruption to your applications by increasing your iSCSI Initiators' timeouts. For more information about increasing iSCSI Initiator timeouts for Windows and Linux, see <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/ConfiguringiSCSIClientInitiatorWindowsClient.html#CustomizeWindowsiSCSISettings">Customizing Your Windows iSCSI Settings</a> and <a href="https://docs.aws.amazon.com/storagegateway/latest/userguide/ConfiguringiSCSIClientInitiatorRedHatClient.html#CustomizeLinuxiSCSISettings">Customizing Your Linux iSCSI Settings</a>, respectively.</p> </important>
  ##   body: JObject (required)
  var body_602061 = newJObject()
  if body != nil:
    body_602061 = body
  result = call_602060.call(nil, nil, nil, nil, body_602061)

var updateGatewaySoftwareNow* = Call_UpdateGatewaySoftwareNow_602047(
    name: "updateGatewaySoftwareNow", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.UpdateGatewaySoftwareNow",
    validator: validate_UpdateGatewaySoftwareNow_602048, base: "/",
    url: url_UpdateGatewaySoftwareNow_602049, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMaintenanceStartTime_602062 = ref object of OpenApiRestCall_600438
proc url_UpdateMaintenanceStartTime_602064(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateMaintenanceStartTime_602063(path: JsonNode; query: JsonNode;
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
  var valid_602065 = header.getOrDefault("X-Amz-Date")
  valid_602065 = validateParameter(valid_602065, JString, required = false,
                                 default = nil)
  if valid_602065 != nil:
    section.add "X-Amz-Date", valid_602065
  var valid_602066 = header.getOrDefault("X-Amz-Security-Token")
  valid_602066 = validateParameter(valid_602066, JString, required = false,
                                 default = nil)
  if valid_602066 != nil:
    section.add "X-Amz-Security-Token", valid_602066
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602067 = header.getOrDefault("X-Amz-Target")
  valid_602067 = validateParameter(valid_602067, JString, required = true, default = newJString(
      "StorageGateway_20130630.UpdateMaintenanceStartTime"))
  if valid_602067 != nil:
    section.add "X-Amz-Target", valid_602067
  var valid_602068 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602068 = validateParameter(valid_602068, JString, required = false,
                                 default = nil)
  if valid_602068 != nil:
    section.add "X-Amz-Content-Sha256", valid_602068
  var valid_602069 = header.getOrDefault("X-Amz-Algorithm")
  valid_602069 = validateParameter(valid_602069, JString, required = false,
                                 default = nil)
  if valid_602069 != nil:
    section.add "X-Amz-Algorithm", valid_602069
  var valid_602070 = header.getOrDefault("X-Amz-Signature")
  valid_602070 = validateParameter(valid_602070, JString, required = false,
                                 default = nil)
  if valid_602070 != nil:
    section.add "X-Amz-Signature", valid_602070
  var valid_602071 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602071 = validateParameter(valid_602071, JString, required = false,
                                 default = nil)
  if valid_602071 != nil:
    section.add "X-Amz-SignedHeaders", valid_602071
  var valid_602072 = header.getOrDefault("X-Amz-Credential")
  valid_602072 = validateParameter(valid_602072, JString, required = false,
                                 default = nil)
  if valid_602072 != nil:
    section.add "X-Amz-Credential", valid_602072
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602074: Call_UpdateMaintenanceStartTime_602062; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a gateway's weekly maintenance start time information, including day and time of the week. The maintenance time is the time in your gateway's time zone.
  ## 
  let valid = call_602074.validator(path, query, header, formData, body)
  let scheme = call_602074.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602074.url(scheme.get, call_602074.host, call_602074.base,
                         call_602074.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602074, url, valid)

proc call*(call_602075: Call_UpdateMaintenanceStartTime_602062; body: JsonNode): Recallable =
  ## updateMaintenanceStartTime
  ## Updates a gateway's weekly maintenance start time information, including day and time of the week. The maintenance time is the time in your gateway's time zone.
  ##   body: JObject (required)
  var body_602076 = newJObject()
  if body != nil:
    body_602076 = body
  result = call_602075.call(nil, nil, nil, nil, body_602076)

var updateMaintenanceStartTime* = Call_UpdateMaintenanceStartTime_602062(
    name: "updateMaintenanceStartTime", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.UpdateMaintenanceStartTime",
    validator: validate_UpdateMaintenanceStartTime_602063, base: "/",
    url: url_UpdateMaintenanceStartTime_602064,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNFSFileShare_602077 = ref object of OpenApiRestCall_600438
proc url_UpdateNFSFileShare_602079(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateNFSFileShare_602078(path: JsonNode; query: JsonNode;
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
  var valid_602080 = header.getOrDefault("X-Amz-Date")
  valid_602080 = validateParameter(valid_602080, JString, required = false,
                                 default = nil)
  if valid_602080 != nil:
    section.add "X-Amz-Date", valid_602080
  var valid_602081 = header.getOrDefault("X-Amz-Security-Token")
  valid_602081 = validateParameter(valid_602081, JString, required = false,
                                 default = nil)
  if valid_602081 != nil:
    section.add "X-Amz-Security-Token", valid_602081
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602082 = header.getOrDefault("X-Amz-Target")
  valid_602082 = validateParameter(valid_602082, JString, required = true, default = newJString(
      "StorageGateway_20130630.UpdateNFSFileShare"))
  if valid_602082 != nil:
    section.add "X-Amz-Target", valid_602082
  var valid_602083 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602083 = validateParameter(valid_602083, JString, required = false,
                                 default = nil)
  if valid_602083 != nil:
    section.add "X-Amz-Content-Sha256", valid_602083
  var valid_602084 = header.getOrDefault("X-Amz-Algorithm")
  valid_602084 = validateParameter(valid_602084, JString, required = false,
                                 default = nil)
  if valid_602084 != nil:
    section.add "X-Amz-Algorithm", valid_602084
  var valid_602085 = header.getOrDefault("X-Amz-Signature")
  valid_602085 = validateParameter(valid_602085, JString, required = false,
                                 default = nil)
  if valid_602085 != nil:
    section.add "X-Amz-Signature", valid_602085
  var valid_602086 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602086 = validateParameter(valid_602086, JString, required = false,
                                 default = nil)
  if valid_602086 != nil:
    section.add "X-Amz-SignedHeaders", valid_602086
  var valid_602087 = header.getOrDefault("X-Amz-Credential")
  valid_602087 = validateParameter(valid_602087, JString, required = false,
                                 default = nil)
  if valid_602087 != nil:
    section.add "X-Amz-Credential", valid_602087
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602089: Call_UpdateNFSFileShare_602077; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates a Network File System (NFS) file share. This operation is only supported in the file gateway type.</p> <note> <p>To leave a file share field unchanged, set the corresponding input field to null.</p> </note> <p>Updates the following file share setting:</p> <ul> <li> <p>Default storage class for your S3 bucket</p> </li> <li> <p>Metadata defaults for your S3 bucket</p> </li> <li> <p>Allowed NFS clients for your file share</p> </li> <li> <p>Squash settings</p> </li> <li> <p>Write status of your file share</p> </li> </ul> <note> <p>To leave a file share field unchanged, set the corresponding input field to null. This operation is only supported in file gateways.</p> </note>
  ## 
  let valid = call_602089.validator(path, query, header, formData, body)
  let scheme = call_602089.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602089.url(scheme.get, call_602089.host, call_602089.base,
                         call_602089.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602089, url, valid)

proc call*(call_602090: Call_UpdateNFSFileShare_602077; body: JsonNode): Recallable =
  ## updateNFSFileShare
  ## <p>Updates a Network File System (NFS) file share. This operation is only supported in the file gateway type.</p> <note> <p>To leave a file share field unchanged, set the corresponding input field to null.</p> </note> <p>Updates the following file share setting:</p> <ul> <li> <p>Default storage class for your S3 bucket</p> </li> <li> <p>Metadata defaults for your S3 bucket</p> </li> <li> <p>Allowed NFS clients for your file share</p> </li> <li> <p>Squash settings</p> </li> <li> <p>Write status of your file share</p> </li> </ul> <note> <p>To leave a file share field unchanged, set the corresponding input field to null. This operation is only supported in file gateways.</p> </note>
  ##   body: JObject (required)
  var body_602091 = newJObject()
  if body != nil:
    body_602091 = body
  result = call_602090.call(nil, nil, nil, nil, body_602091)

var updateNFSFileShare* = Call_UpdateNFSFileShare_602077(
    name: "updateNFSFileShare", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.UpdateNFSFileShare",
    validator: validate_UpdateNFSFileShare_602078, base: "/",
    url: url_UpdateNFSFileShare_602079, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSMBFileShare_602092 = ref object of OpenApiRestCall_600438
proc url_UpdateSMBFileShare_602094(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateSMBFileShare_602093(path: JsonNode; query: JsonNode;
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
  var valid_602095 = header.getOrDefault("X-Amz-Date")
  valid_602095 = validateParameter(valid_602095, JString, required = false,
                                 default = nil)
  if valid_602095 != nil:
    section.add "X-Amz-Date", valid_602095
  var valid_602096 = header.getOrDefault("X-Amz-Security-Token")
  valid_602096 = validateParameter(valid_602096, JString, required = false,
                                 default = nil)
  if valid_602096 != nil:
    section.add "X-Amz-Security-Token", valid_602096
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602097 = header.getOrDefault("X-Amz-Target")
  valid_602097 = validateParameter(valid_602097, JString, required = true, default = newJString(
      "StorageGateway_20130630.UpdateSMBFileShare"))
  if valid_602097 != nil:
    section.add "X-Amz-Target", valid_602097
  var valid_602098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602098 = validateParameter(valid_602098, JString, required = false,
                                 default = nil)
  if valid_602098 != nil:
    section.add "X-Amz-Content-Sha256", valid_602098
  var valid_602099 = header.getOrDefault("X-Amz-Algorithm")
  valid_602099 = validateParameter(valid_602099, JString, required = false,
                                 default = nil)
  if valid_602099 != nil:
    section.add "X-Amz-Algorithm", valid_602099
  var valid_602100 = header.getOrDefault("X-Amz-Signature")
  valid_602100 = validateParameter(valid_602100, JString, required = false,
                                 default = nil)
  if valid_602100 != nil:
    section.add "X-Amz-Signature", valid_602100
  var valid_602101 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602101 = validateParameter(valid_602101, JString, required = false,
                                 default = nil)
  if valid_602101 != nil:
    section.add "X-Amz-SignedHeaders", valid_602101
  var valid_602102 = header.getOrDefault("X-Amz-Credential")
  valid_602102 = validateParameter(valid_602102, JString, required = false,
                                 default = nil)
  if valid_602102 != nil:
    section.add "X-Amz-Credential", valid_602102
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602104: Call_UpdateSMBFileShare_602092; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates a Server Message Block (SMB) file share.</p> <note> <p>To leave a file share field unchanged, set the corresponding input field to null. This operation is only supported for file gateways.</p> </note> <important> <p>File gateways require AWS Security Token Service (AWS STS) to be activated to enable you to create a file share. Make sure that AWS STS is activated in the AWS Region you are creating your file gateway in. If AWS STS is not activated in this AWS Region, activate it. For information about how to activate AWS STS, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_enable-regions.html">Activating and Deactivating AWS STS in an AWS Region</a> in the <i>AWS Identity and Access Management User Guide.</i> </p> <p>File gateways don't support creating hard or symbolic links on a file share.</p> </important>
  ## 
  let valid = call_602104.validator(path, query, header, formData, body)
  let scheme = call_602104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602104.url(scheme.get, call_602104.host, call_602104.base,
                         call_602104.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602104, url, valid)

proc call*(call_602105: Call_UpdateSMBFileShare_602092; body: JsonNode): Recallable =
  ## updateSMBFileShare
  ## <p>Updates a Server Message Block (SMB) file share.</p> <note> <p>To leave a file share field unchanged, set the corresponding input field to null. This operation is only supported for file gateways.</p> </note> <important> <p>File gateways require AWS Security Token Service (AWS STS) to be activated to enable you to create a file share. Make sure that AWS STS is activated in the AWS Region you are creating your file gateway in. If AWS STS is not activated in this AWS Region, activate it. For information about how to activate AWS STS, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_enable-regions.html">Activating and Deactivating AWS STS in an AWS Region</a> in the <i>AWS Identity and Access Management User Guide.</i> </p> <p>File gateways don't support creating hard or symbolic links on a file share.</p> </important>
  ##   body: JObject (required)
  var body_602106 = newJObject()
  if body != nil:
    body_602106 = body
  result = call_602105.call(nil, nil, nil, nil, body_602106)

var updateSMBFileShare* = Call_UpdateSMBFileShare_602092(
    name: "updateSMBFileShare", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.UpdateSMBFileShare",
    validator: validate_UpdateSMBFileShare_602093, base: "/",
    url: url_UpdateSMBFileShare_602094, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSMBSecurityStrategy_602107 = ref object of OpenApiRestCall_600438
proc url_UpdateSMBSecurityStrategy_602109(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateSMBSecurityStrategy_602108(path: JsonNode; query: JsonNode;
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
  var valid_602110 = header.getOrDefault("X-Amz-Date")
  valid_602110 = validateParameter(valid_602110, JString, required = false,
                                 default = nil)
  if valid_602110 != nil:
    section.add "X-Amz-Date", valid_602110
  var valid_602111 = header.getOrDefault("X-Amz-Security-Token")
  valid_602111 = validateParameter(valid_602111, JString, required = false,
                                 default = nil)
  if valid_602111 != nil:
    section.add "X-Amz-Security-Token", valid_602111
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602112 = header.getOrDefault("X-Amz-Target")
  valid_602112 = validateParameter(valid_602112, JString, required = true, default = newJString(
      "StorageGateway_20130630.UpdateSMBSecurityStrategy"))
  if valid_602112 != nil:
    section.add "X-Amz-Target", valid_602112
  var valid_602113 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602113 = validateParameter(valid_602113, JString, required = false,
                                 default = nil)
  if valid_602113 != nil:
    section.add "X-Amz-Content-Sha256", valid_602113
  var valid_602114 = header.getOrDefault("X-Amz-Algorithm")
  valid_602114 = validateParameter(valid_602114, JString, required = false,
                                 default = nil)
  if valid_602114 != nil:
    section.add "X-Amz-Algorithm", valid_602114
  var valid_602115 = header.getOrDefault("X-Amz-Signature")
  valid_602115 = validateParameter(valid_602115, JString, required = false,
                                 default = nil)
  if valid_602115 != nil:
    section.add "X-Amz-Signature", valid_602115
  var valid_602116 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602116 = validateParameter(valid_602116, JString, required = false,
                                 default = nil)
  if valid_602116 != nil:
    section.add "X-Amz-SignedHeaders", valid_602116
  var valid_602117 = header.getOrDefault("X-Amz-Credential")
  valid_602117 = validateParameter(valid_602117, JString, required = false,
                                 default = nil)
  if valid_602117 != nil:
    section.add "X-Amz-Credential", valid_602117
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602119: Call_UpdateSMBSecurityStrategy_602107; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the SMB security strategy on a file gateway. This action is only supported in file gateways.</p> <note> <p>This API is called Security level in the User Guide.</p> <p>A higher security level can affect performance of the gateway.</p> </note>
  ## 
  let valid = call_602119.validator(path, query, header, formData, body)
  let scheme = call_602119.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602119.url(scheme.get, call_602119.host, call_602119.base,
                         call_602119.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602119, url, valid)

proc call*(call_602120: Call_UpdateSMBSecurityStrategy_602107; body: JsonNode): Recallable =
  ## updateSMBSecurityStrategy
  ## <p>Updates the SMB security strategy on a file gateway. This action is only supported in file gateways.</p> <note> <p>This API is called Security level in the User Guide.</p> <p>A higher security level can affect performance of the gateway.</p> </note>
  ##   body: JObject (required)
  var body_602121 = newJObject()
  if body != nil:
    body_602121 = body
  result = call_602120.call(nil, nil, nil, nil, body_602121)

var updateSMBSecurityStrategy* = Call_UpdateSMBSecurityStrategy_602107(
    name: "updateSMBSecurityStrategy", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.UpdateSMBSecurityStrategy",
    validator: validate_UpdateSMBSecurityStrategy_602108, base: "/",
    url: url_UpdateSMBSecurityStrategy_602109,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSnapshotSchedule_602122 = ref object of OpenApiRestCall_600438
proc url_UpdateSnapshotSchedule_602124(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateSnapshotSchedule_602123(path: JsonNode; query: JsonNode;
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
  var valid_602125 = header.getOrDefault("X-Amz-Date")
  valid_602125 = validateParameter(valid_602125, JString, required = false,
                                 default = nil)
  if valid_602125 != nil:
    section.add "X-Amz-Date", valid_602125
  var valid_602126 = header.getOrDefault("X-Amz-Security-Token")
  valid_602126 = validateParameter(valid_602126, JString, required = false,
                                 default = nil)
  if valid_602126 != nil:
    section.add "X-Amz-Security-Token", valid_602126
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602127 = header.getOrDefault("X-Amz-Target")
  valid_602127 = validateParameter(valid_602127, JString, required = true, default = newJString(
      "StorageGateway_20130630.UpdateSnapshotSchedule"))
  if valid_602127 != nil:
    section.add "X-Amz-Target", valid_602127
  var valid_602128 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602128 = validateParameter(valid_602128, JString, required = false,
                                 default = nil)
  if valid_602128 != nil:
    section.add "X-Amz-Content-Sha256", valid_602128
  var valid_602129 = header.getOrDefault("X-Amz-Algorithm")
  valid_602129 = validateParameter(valid_602129, JString, required = false,
                                 default = nil)
  if valid_602129 != nil:
    section.add "X-Amz-Algorithm", valid_602129
  var valid_602130 = header.getOrDefault("X-Amz-Signature")
  valid_602130 = validateParameter(valid_602130, JString, required = false,
                                 default = nil)
  if valid_602130 != nil:
    section.add "X-Amz-Signature", valid_602130
  var valid_602131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602131 = validateParameter(valid_602131, JString, required = false,
                                 default = nil)
  if valid_602131 != nil:
    section.add "X-Amz-SignedHeaders", valid_602131
  var valid_602132 = header.getOrDefault("X-Amz-Credential")
  valid_602132 = validateParameter(valid_602132, JString, required = false,
                                 default = nil)
  if valid_602132 != nil:
    section.add "X-Amz-Credential", valid_602132
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602134: Call_UpdateSnapshotSchedule_602122; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates a snapshot schedule configured for a gateway volume. This operation is only supported in the cached volume and stored volume gateway types.</p> <p>The default snapshot schedule for volume is once every 24 hours, starting at the creation time of the volume. You can use this API to change the snapshot schedule configured for the volume.</p> <p>In the request you must identify the gateway volume whose snapshot schedule you want to update, and the schedule information, including when you want the snapshot to begin on a day and the frequency (in hours) of snapshots.</p>
  ## 
  let valid = call_602134.validator(path, query, header, formData, body)
  let scheme = call_602134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602134.url(scheme.get, call_602134.host, call_602134.base,
                         call_602134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602134, url, valid)

proc call*(call_602135: Call_UpdateSnapshotSchedule_602122; body: JsonNode): Recallable =
  ## updateSnapshotSchedule
  ## <p>Updates a snapshot schedule configured for a gateway volume. This operation is only supported in the cached volume and stored volume gateway types.</p> <p>The default snapshot schedule for volume is once every 24 hours, starting at the creation time of the volume. You can use this API to change the snapshot schedule configured for the volume.</p> <p>In the request you must identify the gateway volume whose snapshot schedule you want to update, and the schedule information, including when you want the snapshot to begin on a day and the frequency (in hours) of snapshots.</p>
  ##   body: JObject (required)
  var body_602136 = newJObject()
  if body != nil:
    body_602136 = body
  result = call_602135.call(nil, nil, nil, nil, body_602136)

var updateSnapshotSchedule* = Call_UpdateSnapshotSchedule_602122(
    name: "updateSnapshotSchedule", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.UpdateSnapshotSchedule",
    validator: validate_UpdateSnapshotSchedule_602123, base: "/",
    url: url_UpdateSnapshotSchedule_602124, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVTLDeviceType_602137 = ref object of OpenApiRestCall_600438
proc url_UpdateVTLDeviceType_602139(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateVTLDeviceType_602138(path: JsonNode; query: JsonNode;
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
  var valid_602140 = header.getOrDefault("X-Amz-Date")
  valid_602140 = validateParameter(valid_602140, JString, required = false,
                                 default = nil)
  if valid_602140 != nil:
    section.add "X-Amz-Date", valid_602140
  var valid_602141 = header.getOrDefault("X-Amz-Security-Token")
  valid_602141 = validateParameter(valid_602141, JString, required = false,
                                 default = nil)
  if valid_602141 != nil:
    section.add "X-Amz-Security-Token", valid_602141
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602142 = header.getOrDefault("X-Amz-Target")
  valid_602142 = validateParameter(valid_602142, JString, required = true, default = newJString(
      "StorageGateway_20130630.UpdateVTLDeviceType"))
  if valid_602142 != nil:
    section.add "X-Amz-Target", valid_602142
  var valid_602143 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602143 = validateParameter(valid_602143, JString, required = false,
                                 default = nil)
  if valid_602143 != nil:
    section.add "X-Amz-Content-Sha256", valid_602143
  var valid_602144 = header.getOrDefault("X-Amz-Algorithm")
  valid_602144 = validateParameter(valid_602144, JString, required = false,
                                 default = nil)
  if valid_602144 != nil:
    section.add "X-Amz-Algorithm", valid_602144
  var valid_602145 = header.getOrDefault("X-Amz-Signature")
  valid_602145 = validateParameter(valid_602145, JString, required = false,
                                 default = nil)
  if valid_602145 != nil:
    section.add "X-Amz-Signature", valid_602145
  var valid_602146 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602146 = validateParameter(valid_602146, JString, required = false,
                                 default = nil)
  if valid_602146 != nil:
    section.add "X-Amz-SignedHeaders", valid_602146
  var valid_602147 = header.getOrDefault("X-Amz-Credential")
  valid_602147 = validateParameter(valid_602147, JString, required = false,
                                 default = nil)
  if valid_602147 != nil:
    section.add "X-Amz-Credential", valid_602147
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602149: Call_UpdateVTLDeviceType_602137; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the type of medium changer in a tape gateway. When you activate a tape gateway, you select a medium changer type for the tape gateway. This operation enables you to select a different type of medium changer after a tape gateway is activated. This operation is only supported in the tape gateway type.
  ## 
  let valid = call_602149.validator(path, query, header, formData, body)
  let scheme = call_602149.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602149.url(scheme.get, call_602149.host, call_602149.base,
                         call_602149.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602149, url, valid)

proc call*(call_602150: Call_UpdateVTLDeviceType_602137; body: JsonNode): Recallable =
  ## updateVTLDeviceType
  ## Updates the type of medium changer in a tape gateway. When you activate a tape gateway, you select a medium changer type for the tape gateway. This operation enables you to select a different type of medium changer after a tape gateway is activated. This operation is only supported in the tape gateway type.
  ##   body: JObject (required)
  var body_602151 = newJObject()
  if body != nil:
    body_602151 = body
  result = call_602150.call(nil, nil, nil, nil, body_602151)

var updateVTLDeviceType* = Call_UpdateVTLDeviceType_602137(
    name: "updateVTLDeviceType", meth: HttpMethod.HttpPost,
    host: "storagegateway.amazonaws.com",
    route: "/#X-Amz-Target=StorageGateway_20130630.UpdateVTLDeviceType",
    validator: validate_UpdateVTLDeviceType_602138, base: "/",
    url: url_UpdateVTLDeviceType_602139, schemes: {Scheme.Https, Scheme.Http})
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
