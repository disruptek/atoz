
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon CloudFront
## version: 2018-06-18
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon CloudFront</fullname> <p>This is the <i>Amazon CloudFront API Reference</i>. This guide is for developers who need detailed information about CloudFront API actions, data types, and errors. For detailed information about CloudFront features, see the <i>Amazon CloudFront Developer Guide</i>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/cloudfront/
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

  OpenApiRestCall_610658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_610658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_610658): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"cn-northwest-1": "cloudfront.cn-northwest-1.amazonaws.com.cn", "cn-north-1": "cloudfront.cn-north-1.amazonaws.com.cn"}.toTable, Scheme.Https: {
      "cn-northwest-1": "cloudfront.cn-northwest-1.amazonaws.com.cn",
      "cn-north-1": "cloudfront.cn-north-1.amazonaws.com.cn"}.toTable}.toTable
const
  awsServiceName = "cloudfront"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateCloudFrontOriginAccessIdentity20180618_611253 = ref object of OpenApiRestCall_610658
proc url_CreateCloudFrontOriginAccessIdentity20180618_611255(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateCloudFrontOriginAccessIdentity20180618_611254(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new origin access identity. If you're using Amazon S3 for your origin, you can use an origin access identity to require users to access your content using a CloudFront URL instead of the Amazon S3 URL. For more information about how to use origin access identities, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PrivateContent.html">Serving Private Content through CloudFront</a> in the <i>Amazon CloudFront Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611256 = header.getOrDefault("X-Amz-Signature")
  valid_611256 = validateParameter(valid_611256, JString, required = false,
                                 default = nil)
  if valid_611256 != nil:
    section.add "X-Amz-Signature", valid_611256
  var valid_611257 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611257 = validateParameter(valid_611257, JString, required = false,
                                 default = nil)
  if valid_611257 != nil:
    section.add "X-Amz-Content-Sha256", valid_611257
  var valid_611258 = header.getOrDefault("X-Amz-Date")
  valid_611258 = validateParameter(valid_611258, JString, required = false,
                                 default = nil)
  if valid_611258 != nil:
    section.add "X-Amz-Date", valid_611258
  var valid_611259 = header.getOrDefault("X-Amz-Credential")
  valid_611259 = validateParameter(valid_611259, JString, required = false,
                                 default = nil)
  if valid_611259 != nil:
    section.add "X-Amz-Credential", valid_611259
  var valid_611260 = header.getOrDefault("X-Amz-Security-Token")
  valid_611260 = validateParameter(valid_611260, JString, required = false,
                                 default = nil)
  if valid_611260 != nil:
    section.add "X-Amz-Security-Token", valid_611260
  var valid_611261 = header.getOrDefault("X-Amz-Algorithm")
  valid_611261 = validateParameter(valid_611261, JString, required = false,
                                 default = nil)
  if valid_611261 != nil:
    section.add "X-Amz-Algorithm", valid_611261
  var valid_611262 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611262 = validateParameter(valid_611262, JString, required = false,
                                 default = nil)
  if valid_611262 != nil:
    section.add "X-Amz-SignedHeaders", valid_611262
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611264: Call_CreateCloudFrontOriginAccessIdentity20180618_611253;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates a new origin access identity. If you're using Amazon S3 for your origin, you can use an origin access identity to require users to access your content using a CloudFront URL instead of the Amazon S3 URL. For more information about how to use origin access identities, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PrivateContent.html">Serving Private Content through CloudFront</a> in the <i>Amazon CloudFront Developer Guide</i>.
  ## 
  let valid = call_611264.validator(path, query, header, formData, body)
  let scheme = call_611264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611264.url(scheme.get, call_611264.host, call_611264.base,
                         call_611264.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611264, url, valid)

proc call*(call_611265: Call_CreateCloudFrontOriginAccessIdentity20180618_611253;
          body: JsonNode): Recallable =
  ## createCloudFrontOriginAccessIdentity20180618
  ## Creates a new origin access identity. If you're using Amazon S3 for your origin, you can use an origin access identity to require users to access your content using a CloudFront URL instead of the Amazon S3 URL. For more information about how to use origin access identities, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PrivateContent.html">Serving Private Content through CloudFront</a> in the <i>Amazon CloudFront Developer Guide</i>.
  ##   body: JObject (required)
  var body_611266 = newJObject()
  if body != nil:
    body_611266 = body
  result = call_611265.call(nil, nil, nil, nil, body_611266)

var createCloudFrontOriginAccessIdentity20180618* = Call_CreateCloudFrontOriginAccessIdentity20180618_611253(
    name: "createCloudFrontOriginAccessIdentity20180618",
    meth: HttpMethod.HttpPost, host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/origin-access-identity/cloudfront",
    validator: validate_CreateCloudFrontOriginAccessIdentity20180618_611254,
    base: "/", url: url_CreateCloudFrontOriginAccessIdentity20180618_611255,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCloudFrontOriginAccessIdentities20180618_610996 = ref object of OpenApiRestCall_610658
proc url_ListCloudFrontOriginAccessIdentities20180618_610998(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListCloudFrontOriginAccessIdentities20180618_610997(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists origin access identities.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Use this when paginating results to indicate where to begin in your list of origin access identities. The results include identities in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last identity on that page).
  ##   MaxItems: JString
  ##           : The maximum number of origin access identities you want in the response body. 
  section = newJObject()
  var valid_611110 = query.getOrDefault("Marker")
  valid_611110 = validateParameter(valid_611110, JString, required = false,
                                 default = nil)
  if valid_611110 != nil:
    section.add "Marker", valid_611110
  var valid_611111 = query.getOrDefault("MaxItems")
  valid_611111 = validateParameter(valid_611111, JString, required = false,
                                 default = nil)
  if valid_611111 != nil:
    section.add "MaxItems", valid_611111
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611112 = header.getOrDefault("X-Amz-Signature")
  valid_611112 = validateParameter(valid_611112, JString, required = false,
                                 default = nil)
  if valid_611112 != nil:
    section.add "X-Amz-Signature", valid_611112
  var valid_611113 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611113 = validateParameter(valid_611113, JString, required = false,
                                 default = nil)
  if valid_611113 != nil:
    section.add "X-Amz-Content-Sha256", valid_611113
  var valid_611114 = header.getOrDefault("X-Amz-Date")
  valid_611114 = validateParameter(valid_611114, JString, required = false,
                                 default = nil)
  if valid_611114 != nil:
    section.add "X-Amz-Date", valid_611114
  var valid_611115 = header.getOrDefault("X-Amz-Credential")
  valid_611115 = validateParameter(valid_611115, JString, required = false,
                                 default = nil)
  if valid_611115 != nil:
    section.add "X-Amz-Credential", valid_611115
  var valid_611116 = header.getOrDefault("X-Amz-Security-Token")
  valid_611116 = validateParameter(valid_611116, JString, required = false,
                                 default = nil)
  if valid_611116 != nil:
    section.add "X-Amz-Security-Token", valid_611116
  var valid_611117 = header.getOrDefault("X-Amz-Algorithm")
  valid_611117 = validateParameter(valid_611117, JString, required = false,
                                 default = nil)
  if valid_611117 != nil:
    section.add "X-Amz-Algorithm", valid_611117
  var valid_611118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611118 = validateParameter(valid_611118, JString, required = false,
                                 default = nil)
  if valid_611118 != nil:
    section.add "X-Amz-SignedHeaders", valid_611118
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611141: Call_ListCloudFrontOriginAccessIdentities20180618_610996;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists origin access identities.
  ## 
  let valid = call_611141.validator(path, query, header, formData, body)
  let scheme = call_611141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611141.url(scheme.get, call_611141.host, call_611141.base,
                         call_611141.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611141, url, valid)

proc call*(call_611212: Call_ListCloudFrontOriginAccessIdentities20180618_610996;
          Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listCloudFrontOriginAccessIdentities20180618
  ## Lists origin access identities.
  ##   Marker: string
  ##         : Use this when paginating results to indicate where to begin in your list of origin access identities. The results include identities in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last identity on that page).
  ##   MaxItems: string
  ##           : The maximum number of origin access identities you want in the response body. 
  var query_611213 = newJObject()
  add(query_611213, "Marker", newJString(Marker))
  add(query_611213, "MaxItems", newJString(MaxItems))
  result = call_611212.call(nil, query_611213, nil, nil, nil)

var listCloudFrontOriginAccessIdentities20180618* = Call_ListCloudFrontOriginAccessIdentities20180618_610996(
    name: "listCloudFrontOriginAccessIdentities20180618",
    meth: HttpMethod.HttpGet, host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/origin-access-identity/cloudfront",
    validator: validate_ListCloudFrontOriginAccessIdentities20180618_610997,
    base: "/", url: url_ListCloudFrontOriginAccessIdentities20180618_610998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDistribution20180618_611282 = ref object of OpenApiRestCall_610658
proc url_CreateDistribution20180618_611284(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDistribution20180618_611283(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new web distribution. You create a CloudFront distribution to tell CloudFront where you want content to be delivered from, and the details about how to track and manage content delivery. Send a <code>POST</code> request to the <code>/<i>CloudFront API version</i>/distribution</code>/<code>distribution ID</code> resource.</p> <important> <p>When you update a distribution, there are more required fields than when you create a distribution. When you update your distribution by using <a>UpdateDistribution</a>, follow the steps included in the documentation to get the current configuration and then make your updates. This helps to make sure that you include all of the required fields. To view a summary, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-overview-required-fields.html">Required Fields for Create Distribution and Update Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> </important> <p>If you are using Adobe Flash Media Server's RTMP protocol, you set up a different kind of CloudFront distribution. For more information, see <a>CreateStreamingDistribution</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611285 = header.getOrDefault("X-Amz-Signature")
  valid_611285 = validateParameter(valid_611285, JString, required = false,
                                 default = nil)
  if valid_611285 != nil:
    section.add "X-Amz-Signature", valid_611285
  var valid_611286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611286 = validateParameter(valid_611286, JString, required = false,
                                 default = nil)
  if valid_611286 != nil:
    section.add "X-Amz-Content-Sha256", valid_611286
  var valid_611287 = header.getOrDefault("X-Amz-Date")
  valid_611287 = validateParameter(valid_611287, JString, required = false,
                                 default = nil)
  if valid_611287 != nil:
    section.add "X-Amz-Date", valid_611287
  var valid_611288 = header.getOrDefault("X-Amz-Credential")
  valid_611288 = validateParameter(valid_611288, JString, required = false,
                                 default = nil)
  if valid_611288 != nil:
    section.add "X-Amz-Credential", valid_611288
  var valid_611289 = header.getOrDefault("X-Amz-Security-Token")
  valid_611289 = validateParameter(valid_611289, JString, required = false,
                                 default = nil)
  if valid_611289 != nil:
    section.add "X-Amz-Security-Token", valid_611289
  var valid_611290 = header.getOrDefault("X-Amz-Algorithm")
  valid_611290 = validateParameter(valid_611290, JString, required = false,
                                 default = nil)
  if valid_611290 != nil:
    section.add "X-Amz-Algorithm", valid_611290
  var valid_611291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611291 = validateParameter(valid_611291, JString, required = false,
                                 default = nil)
  if valid_611291 != nil:
    section.add "X-Amz-SignedHeaders", valid_611291
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611293: Call_CreateDistribution20180618_611282; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new web distribution. You create a CloudFront distribution to tell CloudFront where you want content to be delivered from, and the details about how to track and manage content delivery. Send a <code>POST</code> request to the <code>/<i>CloudFront API version</i>/distribution</code>/<code>distribution ID</code> resource.</p> <important> <p>When you update a distribution, there are more required fields than when you create a distribution. When you update your distribution by using <a>UpdateDistribution</a>, follow the steps included in the documentation to get the current configuration and then make your updates. This helps to make sure that you include all of the required fields. To view a summary, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-overview-required-fields.html">Required Fields for Create Distribution and Update Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> </important> <p>If you are using Adobe Flash Media Server's RTMP protocol, you set up a different kind of CloudFront distribution. For more information, see <a>CreateStreamingDistribution</a>.</p>
  ## 
  let valid = call_611293.validator(path, query, header, formData, body)
  let scheme = call_611293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611293.url(scheme.get, call_611293.host, call_611293.base,
                         call_611293.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611293, url, valid)

proc call*(call_611294: Call_CreateDistribution20180618_611282; body: JsonNode): Recallable =
  ## createDistribution20180618
  ## <p>Creates a new web distribution. You create a CloudFront distribution to tell CloudFront where you want content to be delivered from, and the details about how to track and manage content delivery. Send a <code>POST</code> request to the <code>/<i>CloudFront API version</i>/distribution</code>/<code>distribution ID</code> resource.</p> <important> <p>When you update a distribution, there are more required fields than when you create a distribution. When you update your distribution by using <a>UpdateDistribution</a>, follow the steps included in the documentation to get the current configuration and then make your updates. This helps to make sure that you include all of the required fields. To view a summary, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-overview-required-fields.html">Required Fields for Create Distribution and Update Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> </important> <p>If you are using Adobe Flash Media Server's RTMP protocol, you set up a different kind of CloudFront distribution. For more information, see <a>CreateStreamingDistribution</a>.</p>
  ##   body: JObject (required)
  var body_611295 = newJObject()
  if body != nil:
    body_611295 = body
  result = call_611294.call(nil, nil, nil, nil, body_611295)

var createDistribution20180618* = Call_CreateDistribution20180618_611282(
    name: "createDistribution20180618", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com", route: "/2018-06-18/distribution",
    validator: validate_CreateDistribution20180618_611283, base: "/",
    url: url_CreateDistribution20180618_611284,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDistributions20180618_611267 = ref object of OpenApiRestCall_610658
proc url_ListDistributions20180618_611269(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDistributions20180618_611268(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List distributions. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Use this when paginating results to indicate where to begin in your list of distributions. The results include distributions in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last distribution on that page).
  ##   MaxItems: JString
  ##           : The maximum number of distributions you want in the response body.
  section = newJObject()
  var valid_611270 = query.getOrDefault("Marker")
  valid_611270 = validateParameter(valid_611270, JString, required = false,
                                 default = nil)
  if valid_611270 != nil:
    section.add "Marker", valid_611270
  var valid_611271 = query.getOrDefault("MaxItems")
  valid_611271 = validateParameter(valid_611271, JString, required = false,
                                 default = nil)
  if valid_611271 != nil:
    section.add "MaxItems", valid_611271
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611272 = header.getOrDefault("X-Amz-Signature")
  valid_611272 = validateParameter(valid_611272, JString, required = false,
                                 default = nil)
  if valid_611272 != nil:
    section.add "X-Amz-Signature", valid_611272
  var valid_611273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611273 = validateParameter(valid_611273, JString, required = false,
                                 default = nil)
  if valid_611273 != nil:
    section.add "X-Amz-Content-Sha256", valid_611273
  var valid_611274 = header.getOrDefault("X-Amz-Date")
  valid_611274 = validateParameter(valid_611274, JString, required = false,
                                 default = nil)
  if valid_611274 != nil:
    section.add "X-Amz-Date", valid_611274
  var valid_611275 = header.getOrDefault("X-Amz-Credential")
  valid_611275 = validateParameter(valid_611275, JString, required = false,
                                 default = nil)
  if valid_611275 != nil:
    section.add "X-Amz-Credential", valid_611275
  var valid_611276 = header.getOrDefault("X-Amz-Security-Token")
  valid_611276 = validateParameter(valid_611276, JString, required = false,
                                 default = nil)
  if valid_611276 != nil:
    section.add "X-Amz-Security-Token", valid_611276
  var valid_611277 = header.getOrDefault("X-Amz-Algorithm")
  valid_611277 = validateParameter(valid_611277, JString, required = false,
                                 default = nil)
  if valid_611277 != nil:
    section.add "X-Amz-Algorithm", valid_611277
  var valid_611278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611278 = validateParameter(valid_611278, JString, required = false,
                                 default = nil)
  if valid_611278 != nil:
    section.add "X-Amz-SignedHeaders", valid_611278
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611279: Call_ListDistributions20180618_611267; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List distributions. 
  ## 
  let valid = call_611279.validator(path, query, header, formData, body)
  let scheme = call_611279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611279.url(scheme.get, call_611279.host, call_611279.base,
                         call_611279.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611279, url, valid)

proc call*(call_611280: Call_ListDistributions20180618_611267; Marker: string = "";
          MaxItems: string = ""): Recallable =
  ## listDistributions20180618
  ## List distributions. 
  ##   Marker: string
  ##         : Use this when paginating results to indicate where to begin in your list of distributions. The results include distributions in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last distribution on that page).
  ##   MaxItems: string
  ##           : The maximum number of distributions you want in the response body.
  var query_611281 = newJObject()
  add(query_611281, "Marker", newJString(Marker))
  add(query_611281, "MaxItems", newJString(MaxItems))
  result = call_611280.call(nil, query_611281, nil, nil, nil)

var listDistributions20180618* = Call_ListDistributions20180618_611267(
    name: "listDistributions20180618", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2018-06-18/distribution",
    validator: validate_ListDistributions20180618_611268, base: "/",
    url: url_ListDistributions20180618_611269,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDistributionWithTags20180618_611296 = ref object of OpenApiRestCall_610658
proc url_CreateDistributionWithTags20180618_611298(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDistributionWithTags20180618_611297(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Create a new distribution with tags.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   WithTags: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `WithTags` field"
  var valid_611299 = query.getOrDefault("WithTags")
  valid_611299 = validateParameter(valid_611299, JBool, required = true, default = nil)
  if valid_611299 != nil:
    section.add "WithTags", valid_611299
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611300 = header.getOrDefault("X-Amz-Signature")
  valid_611300 = validateParameter(valid_611300, JString, required = false,
                                 default = nil)
  if valid_611300 != nil:
    section.add "X-Amz-Signature", valid_611300
  var valid_611301 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611301 = validateParameter(valid_611301, JString, required = false,
                                 default = nil)
  if valid_611301 != nil:
    section.add "X-Amz-Content-Sha256", valid_611301
  var valid_611302 = header.getOrDefault("X-Amz-Date")
  valid_611302 = validateParameter(valid_611302, JString, required = false,
                                 default = nil)
  if valid_611302 != nil:
    section.add "X-Amz-Date", valid_611302
  var valid_611303 = header.getOrDefault("X-Amz-Credential")
  valid_611303 = validateParameter(valid_611303, JString, required = false,
                                 default = nil)
  if valid_611303 != nil:
    section.add "X-Amz-Credential", valid_611303
  var valid_611304 = header.getOrDefault("X-Amz-Security-Token")
  valid_611304 = validateParameter(valid_611304, JString, required = false,
                                 default = nil)
  if valid_611304 != nil:
    section.add "X-Amz-Security-Token", valid_611304
  var valid_611305 = header.getOrDefault("X-Amz-Algorithm")
  valid_611305 = validateParameter(valid_611305, JString, required = false,
                                 default = nil)
  if valid_611305 != nil:
    section.add "X-Amz-Algorithm", valid_611305
  var valid_611306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611306 = validateParameter(valid_611306, JString, required = false,
                                 default = nil)
  if valid_611306 != nil:
    section.add "X-Amz-SignedHeaders", valid_611306
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611308: Call_CreateDistributionWithTags20180618_611296;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Create a new distribution with tags.
  ## 
  let valid = call_611308.validator(path, query, header, formData, body)
  let scheme = call_611308.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611308.url(scheme.get, call_611308.host, call_611308.base,
                         call_611308.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611308, url, valid)

proc call*(call_611309: Call_CreateDistributionWithTags20180618_611296;
          body: JsonNode; WithTags: bool): Recallable =
  ## createDistributionWithTags20180618
  ## Create a new distribution with tags.
  ##   body: JObject (required)
  ##   WithTags: bool (required)
  var query_611310 = newJObject()
  var body_611311 = newJObject()
  if body != nil:
    body_611311 = body
  add(query_611310, "WithTags", newJBool(WithTags))
  result = call_611309.call(nil, query_611310, nil, nil, body_611311)

var createDistributionWithTags20180618* = Call_CreateDistributionWithTags20180618_611296(
    name: "createDistributionWithTags20180618", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com", route: "/2018-06-18/distribution#WithTags",
    validator: validate_CreateDistributionWithTags20180618_611297, base: "/",
    url: url_CreateDistributionWithTags20180618_611298,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFieldLevelEncryptionConfig20180618_611327 = ref object of OpenApiRestCall_610658
proc url_CreateFieldLevelEncryptionConfig20180618_611329(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateFieldLevelEncryptionConfig20180618_611328(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Create a new field-level encryption configuration.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611330 = header.getOrDefault("X-Amz-Signature")
  valid_611330 = validateParameter(valid_611330, JString, required = false,
                                 default = nil)
  if valid_611330 != nil:
    section.add "X-Amz-Signature", valid_611330
  var valid_611331 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611331 = validateParameter(valid_611331, JString, required = false,
                                 default = nil)
  if valid_611331 != nil:
    section.add "X-Amz-Content-Sha256", valid_611331
  var valid_611332 = header.getOrDefault("X-Amz-Date")
  valid_611332 = validateParameter(valid_611332, JString, required = false,
                                 default = nil)
  if valid_611332 != nil:
    section.add "X-Amz-Date", valid_611332
  var valid_611333 = header.getOrDefault("X-Amz-Credential")
  valid_611333 = validateParameter(valid_611333, JString, required = false,
                                 default = nil)
  if valid_611333 != nil:
    section.add "X-Amz-Credential", valid_611333
  var valid_611334 = header.getOrDefault("X-Amz-Security-Token")
  valid_611334 = validateParameter(valid_611334, JString, required = false,
                                 default = nil)
  if valid_611334 != nil:
    section.add "X-Amz-Security-Token", valid_611334
  var valid_611335 = header.getOrDefault("X-Amz-Algorithm")
  valid_611335 = validateParameter(valid_611335, JString, required = false,
                                 default = nil)
  if valid_611335 != nil:
    section.add "X-Amz-Algorithm", valid_611335
  var valid_611336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611336 = validateParameter(valid_611336, JString, required = false,
                                 default = nil)
  if valid_611336 != nil:
    section.add "X-Amz-SignedHeaders", valid_611336
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611338: Call_CreateFieldLevelEncryptionConfig20180618_611327;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Create a new field-level encryption configuration.
  ## 
  let valid = call_611338.validator(path, query, header, formData, body)
  let scheme = call_611338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611338.url(scheme.get, call_611338.host, call_611338.base,
                         call_611338.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611338, url, valid)

proc call*(call_611339: Call_CreateFieldLevelEncryptionConfig20180618_611327;
          body: JsonNode): Recallable =
  ## createFieldLevelEncryptionConfig20180618
  ## Create a new field-level encryption configuration.
  ##   body: JObject (required)
  var body_611340 = newJObject()
  if body != nil:
    body_611340 = body
  result = call_611339.call(nil, nil, nil, nil, body_611340)

var createFieldLevelEncryptionConfig20180618* = Call_CreateFieldLevelEncryptionConfig20180618_611327(
    name: "createFieldLevelEncryptionConfig20180618", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com", route: "/2018-06-18/field-level-encryption",
    validator: validate_CreateFieldLevelEncryptionConfig20180618_611328,
    base: "/", url: url_CreateFieldLevelEncryptionConfig20180618_611329,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFieldLevelEncryptionConfigs20180618_611312 = ref object of OpenApiRestCall_610658
proc url_ListFieldLevelEncryptionConfigs20180618_611314(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListFieldLevelEncryptionConfigs20180618_611313(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List all field-level encryption configurations that have been created in CloudFront for this account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Use this when paginating results to indicate where to begin in your list of configurations. The results include configurations in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last configuration on that page). 
  ##   MaxItems: JString
  ##           : The maximum number of field-level encryption configurations you want in the response body. 
  section = newJObject()
  var valid_611315 = query.getOrDefault("Marker")
  valid_611315 = validateParameter(valid_611315, JString, required = false,
                                 default = nil)
  if valid_611315 != nil:
    section.add "Marker", valid_611315
  var valid_611316 = query.getOrDefault("MaxItems")
  valid_611316 = validateParameter(valid_611316, JString, required = false,
                                 default = nil)
  if valid_611316 != nil:
    section.add "MaxItems", valid_611316
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611317 = header.getOrDefault("X-Amz-Signature")
  valid_611317 = validateParameter(valid_611317, JString, required = false,
                                 default = nil)
  if valid_611317 != nil:
    section.add "X-Amz-Signature", valid_611317
  var valid_611318 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611318 = validateParameter(valid_611318, JString, required = false,
                                 default = nil)
  if valid_611318 != nil:
    section.add "X-Amz-Content-Sha256", valid_611318
  var valid_611319 = header.getOrDefault("X-Amz-Date")
  valid_611319 = validateParameter(valid_611319, JString, required = false,
                                 default = nil)
  if valid_611319 != nil:
    section.add "X-Amz-Date", valid_611319
  var valid_611320 = header.getOrDefault("X-Amz-Credential")
  valid_611320 = validateParameter(valid_611320, JString, required = false,
                                 default = nil)
  if valid_611320 != nil:
    section.add "X-Amz-Credential", valid_611320
  var valid_611321 = header.getOrDefault("X-Amz-Security-Token")
  valid_611321 = validateParameter(valid_611321, JString, required = false,
                                 default = nil)
  if valid_611321 != nil:
    section.add "X-Amz-Security-Token", valid_611321
  var valid_611322 = header.getOrDefault("X-Amz-Algorithm")
  valid_611322 = validateParameter(valid_611322, JString, required = false,
                                 default = nil)
  if valid_611322 != nil:
    section.add "X-Amz-Algorithm", valid_611322
  var valid_611323 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611323 = validateParameter(valid_611323, JString, required = false,
                                 default = nil)
  if valid_611323 != nil:
    section.add "X-Amz-SignedHeaders", valid_611323
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611324: Call_ListFieldLevelEncryptionConfigs20180618_611312;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## List all field-level encryption configurations that have been created in CloudFront for this account.
  ## 
  let valid = call_611324.validator(path, query, header, formData, body)
  let scheme = call_611324.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611324.url(scheme.get, call_611324.host, call_611324.base,
                         call_611324.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611324, url, valid)

proc call*(call_611325: Call_ListFieldLevelEncryptionConfigs20180618_611312;
          Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listFieldLevelEncryptionConfigs20180618
  ## List all field-level encryption configurations that have been created in CloudFront for this account.
  ##   Marker: string
  ##         : Use this when paginating results to indicate where to begin in your list of configurations. The results include configurations in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last configuration on that page). 
  ##   MaxItems: string
  ##           : The maximum number of field-level encryption configurations you want in the response body. 
  var query_611326 = newJObject()
  add(query_611326, "Marker", newJString(Marker))
  add(query_611326, "MaxItems", newJString(MaxItems))
  result = call_611325.call(nil, query_611326, nil, nil, nil)

var listFieldLevelEncryptionConfigs20180618* = Call_ListFieldLevelEncryptionConfigs20180618_611312(
    name: "listFieldLevelEncryptionConfigs20180618", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2018-06-18/field-level-encryption",
    validator: validate_ListFieldLevelEncryptionConfigs20180618_611313, base: "/",
    url: url_ListFieldLevelEncryptionConfigs20180618_611314,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFieldLevelEncryptionProfile20180618_611356 = ref object of OpenApiRestCall_610658
proc url_CreateFieldLevelEncryptionProfile20180618_611358(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateFieldLevelEncryptionProfile20180618_611357(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Create a field-level encryption profile.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611359 = header.getOrDefault("X-Amz-Signature")
  valid_611359 = validateParameter(valid_611359, JString, required = false,
                                 default = nil)
  if valid_611359 != nil:
    section.add "X-Amz-Signature", valid_611359
  var valid_611360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611360 = validateParameter(valid_611360, JString, required = false,
                                 default = nil)
  if valid_611360 != nil:
    section.add "X-Amz-Content-Sha256", valid_611360
  var valid_611361 = header.getOrDefault("X-Amz-Date")
  valid_611361 = validateParameter(valid_611361, JString, required = false,
                                 default = nil)
  if valid_611361 != nil:
    section.add "X-Amz-Date", valid_611361
  var valid_611362 = header.getOrDefault("X-Amz-Credential")
  valid_611362 = validateParameter(valid_611362, JString, required = false,
                                 default = nil)
  if valid_611362 != nil:
    section.add "X-Amz-Credential", valid_611362
  var valid_611363 = header.getOrDefault("X-Amz-Security-Token")
  valid_611363 = validateParameter(valid_611363, JString, required = false,
                                 default = nil)
  if valid_611363 != nil:
    section.add "X-Amz-Security-Token", valid_611363
  var valid_611364 = header.getOrDefault("X-Amz-Algorithm")
  valid_611364 = validateParameter(valid_611364, JString, required = false,
                                 default = nil)
  if valid_611364 != nil:
    section.add "X-Amz-Algorithm", valid_611364
  var valid_611365 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611365 = validateParameter(valid_611365, JString, required = false,
                                 default = nil)
  if valid_611365 != nil:
    section.add "X-Amz-SignedHeaders", valid_611365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611367: Call_CreateFieldLevelEncryptionProfile20180618_611356;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Create a field-level encryption profile.
  ## 
  let valid = call_611367.validator(path, query, header, formData, body)
  let scheme = call_611367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611367.url(scheme.get, call_611367.host, call_611367.base,
                         call_611367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611367, url, valid)

proc call*(call_611368: Call_CreateFieldLevelEncryptionProfile20180618_611356;
          body: JsonNode): Recallable =
  ## createFieldLevelEncryptionProfile20180618
  ## Create a field-level encryption profile.
  ##   body: JObject (required)
  var body_611369 = newJObject()
  if body != nil:
    body_611369 = body
  result = call_611368.call(nil, nil, nil, nil, body_611369)

var createFieldLevelEncryptionProfile20180618* = Call_CreateFieldLevelEncryptionProfile20180618_611356(
    name: "createFieldLevelEncryptionProfile20180618", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/field-level-encryption-profile",
    validator: validate_CreateFieldLevelEncryptionProfile20180618_611357,
    base: "/", url: url_CreateFieldLevelEncryptionProfile20180618_611358,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFieldLevelEncryptionProfiles20180618_611341 = ref object of OpenApiRestCall_610658
proc url_ListFieldLevelEncryptionProfiles20180618_611343(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListFieldLevelEncryptionProfiles20180618_611342(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Request a list of field-level encryption profiles that have been created in CloudFront for this account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Use this when paginating results to indicate where to begin in your list of profiles. The results include profiles in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last profile on that page). 
  ##   MaxItems: JString
  ##           : The maximum number of field-level encryption profiles you want in the response body. 
  section = newJObject()
  var valid_611344 = query.getOrDefault("Marker")
  valid_611344 = validateParameter(valid_611344, JString, required = false,
                                 default = nil)
  if valid_611344 != nil:
    section.add "Marker", valid_611344
  var valid_611345 = query.getOrDefault("MaxItems")
  valid_611345 = validateParameter(valid_611345, JString, required = false,
                                 default = nil)
  if valid_611345 != nil:
    section.add "MaxItems", valid_611345
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611346 = header.getOrDefault("X-Amz-Signature")
  valid_611346 = validateParameter(valid_611346, JString, required = false,
                                 default = nil)
  if valid_611346 != nil:
    section.add "X-Amz-Signature", valid_611346
  var valid_611347 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611347 = validateParameter(valid_611347, JString, required = false,
                                 default = nil)
  if valid_611347 != nil:
    section.add "X-Amz-Content-Sha256", valid_611347
  var valid_611348 = header.getOrDefault("X-Amz-Date")
  valid_611348 = validateParameter(valid_611348, JString, required = false,
                                 default = nil)
  if valid_611348 != nil:
    section.add "X-Amz-Date", valid_611348
  var valid_611349 = header.getOrDefault("X-Amz-Credential")
  valid_611349 = validateParameter(valid_611349, JString, required = false,
                                 default = nil)
  if valid_611349 != nil:
    section.add "X-Amz-Credential", valid_611349
  var valid_611350 = header.getOrDefault("X-Amz-Security-Token")
  valid_611350 = validateParameter(valid_611350, JString, required = false,
                                 default = nil)
  if valid_611350 != nil:
    section.add "X-Amz-Security-Token", valid_611350
  var valid_611351 = header.getOrDefault("X-Amz-Algorithm")
  valid_611351 = validateParameter(valid_611351, JString, required = false,
                                 default = nil)
  if valid_611351 != nil:
    section.add "X-Amz-Algorithm", valid_611351
  var valid_611352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611352 = validateParameter(valid_611352, JString, required = false,
                                 default = nil)
  if valid_611352 != nil:
    section.add "X-Amz-SignedHeaders", valid_611352
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611353: Call_ListFieldLevelEncryptionProfiles20180618_611341;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Request a list of field-level encryption profiles that have been created in CloudFront for this account.
  ## 
  let valid = call_611353.validator(path, query, header, formData, body)
  let scheme = call_611353.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611353.url(scheme.get, call_611353.host, call_611353.base,
                         call_611353.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611353, url, valid)

proc call*(call_611354: Call_ListFieldLevelEncryptionProfiles20180618_611341;
          Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listFieldLevelEncryptionProfiles20180618
  ## Request a list of field-level encryption profiles that have been created in CloudFront for this account.
  ##   Marker: string
  ##         : Use this when paginating results to indicate where to begin in your list of profiles. The results include profiles in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last profile on that page). 
  ##   MaxItems: string
  ##           : The maximum number of field-level encryption profiles you want in the response body. 
  var query_611355 = newJObject()
  add(query_611355, "Marker", newJString(Marker))
  add(query_611355, "MaxItems", newJString(MaxItems))
  result = call_611354.call(nil, query_611355, nil, nil, nil)

var listFieldLevelEncryptionProfiles20180618* = Call_ListFieldLevelEncryptionProfiles20180618_611341(
    name: "listFieldLevelEncryptionProfiles20180618", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/field-level-encryption-profile",
    validator: validate_ListFieldLevelEncryptionProfiles20180618_611342,
    base: "/", url: url_ListFieldLevelEncryptionProfiles20180618_611343,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInvalidation20180618_611401 = ref object of OpenApiRestCall_610658
proc url_CreateInvalidation20180618_611403(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DistributionId" in path, "`DistributionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-06-18/distribution/"),
               (kind: VariableSegment, value: "DistributionId"),
               (kind: ConstantSegment, value: "/invalidation")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateInvalidation20180618_611402(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Create a new invalidation. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DistributionId: JString (required)
  ##                 : The distribution's id.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `DistributionId` field"
  var valid_611404 = path.getOrDefault("DistributionId")
  valid_611404 = validateParameter(valid_611404, JString, required = true,
                                 default = nil)
  if valid_611404 != nil:
    section.add "DistributionId", valid_611404
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611405 = header.getOrDefault("X-Amz-Signature")
  valid_611405 = validateParameter(valid_611405, JString, required = false,
                                 default = nil)
  if valid_611405 != nil:
    section.add "X-Amz-Signature", valid_611405
  var valid_611406 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611406 = validateParameter(valid_611406, JString, required = false,
                                 default = nil)
  if valid_611406 != nil:
    section.add "X-Amz-Content-Sha256", valid_611406
  var valid_611407 = header.getOrDefault("X-Amz-Date")
  valid_611407 = validateParameter(valid_611407, JString, required = false,
                                 default = nil)
  if valid_611407 != nil:
    section.add "X-Amz-Date", valid_611407
  var valid_611408 = header.getOrDefault("X-Amz-Credential")
  valid_611408 = validateParameter(valid_611408, JString, required = false,
                                 default = nil)
  if valid_611408 != nil:
    section.add "X-Amz-Credential", valid_611408
  var valid_611409 = header.getOrDefault("X-Amz-Security-Token")
  valid_611409 = validateParameter(valid_611409, JString, required = false,
                                 default = nil)
  if valid_611409 != nil:
    section.add "X-Amz-Security-Token", valid_611409
  var valid_611410 = header.getOrDefault("X-Amz-Algorithm")
  valid_611410 = validateParameter(valid_611410, JString, required = false,
                                 default = nil)
  if valid_611410 != nil:
    section.add "X-Amz-Algorithm", valid_611410
  var valid_611411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611411 = validateParameter(valid_611411, JString, required = false,
                                 default = nil)
  if valid_611411 != nil:
    section.add "X-Amz-SignedHeaders", valid_611411
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611413: Call_CreateInvalidation20180618_611401; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new invalidation. 
  ## 
  let valid = call_611413.validator(path, query, header, formData, body)
  let scheme = call_611413.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611413.url(scheme.get, call_611413.host, call_611413.base,
                         call_611413.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611413, url, valid)

proc call*(call_611414: Call_CreateInvalidation20180618_611401;
          DistributionId: string; body: JsonNode): Recallable =
  ## createInvalidation20180618
  ## Create a new invalidation. 
  ##   DistributionId: string (required)
  ##                 : The distribution's id.
  ##   body: JObject (required)
  var path_611415 = newJObject()
  var body_611416 = newJObject()
  add(path_611415, "DistributionId", newJString(DistributionId))
  if body != nil:
    body_611416 = body
  result = call_611414.call(path_611415, nil, nil, nil, body_611416)

var createInvalidation20180618* = Call_CreateInvalidation20180618_611401(
    name: "createInvalidation20180618", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/distribution/{DistributionId}/invalidation",
    validator: validate_CreateInvalidation20180618_611402, base: "/",
    url: url_CreateInvalidation20180618_611403,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInvalidations20180618_611370 = ref object of OpenApiRestCall_610658
proc url_ListInvalidations20180618_611372(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DistributionId" in path, "`DistributionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-06-18/distribution/"),
               (kind: VariableSegment, value: "DistributionId"),
               (kind: ConstantSegment, value: "/invalidation")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListInvalidations20180618_611371(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists invalidation batches. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DistributionId: JString (required)
  ##                 : The distribution's ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `DistributionId` field"
  var valid_611387 = path.getOrDefault("DistributionId")
  valid_611387 = validateParameter(valid_611387, JString, required = true,
                                 default = nil)
  if valid_611387 != nil:
    section.add "DistributionId", valid_611387
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Use this parameter when paginating results to indicate where to begin in your list of invalidation batches. Because the results are returned in decreasing order from most recent to oldest, the most recent results are on the first page, the second page will contain earlier results, and so on. To get the next page of results, set <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response. This value is the same as the ID of the last invalidation batch on that page. 
  ##   MaxItems: JString
  ##           : The maximum number of invalidation batches that you want in the response body.
  section = newJObject()
  var valid_611388 = query.getOrDefault("Marker")
  valid_611388 = validateParameter(valid_611388, JString, required = false,
                                 default = nil)
  if valid_611388 != nil:
    section.add "Marker", valid_611388
  var valid_611389 = query.getOrDefault("MaxItems")
  valid_611389 = validateParameter(valid_611389, JString, required = false,
                                 default = nil)
  if valid_611389 != nil:
    section.add "MaxItems", valid_611389
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611390 = header.getOrDefault("X-Amz-Signature")
  valid_611390 = validateParameter(valid_611390, JString, required = false,
                                 default = nil)
  if valid_611390 != nil:
    section.add "X-Amz-Signature", valid_611390
  var valid_611391 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611391 = validateParameter(valid_611391, JString, required = false,
                                 default = nil)
  if valid_611391 != nil:
    section.add "X-Amz-Content-Sha256", valid_611391
  var valid_611392 = header.getOrDefault("X-Amz-Date")
  valid_611392 = validateParameter(valid_611392, JString, required = false,
                                 default = nil)
  if valid_611392 != nil:
    section.add "X-Amz-Date", valid_611392
  var valid_611393 = header.getOrDefault("X-Amz-Credential")
  valid_611393 = validateParameter(valid_611393, JString, required = false,
                                 default = nil)
  if valid_611393 != nil:
    section.add "X-Amz-Credential", valid_611393
  var valid_611394 = header.getOrDefault("X-Amz-Security-Token")
  valid_611394 = validateParameter(valid_611394, JString, required = false,
                                 default = nil)
  if valid_611394 != nil:
    section.add "X-Amz-Security-Token", valid_611394
  var valid_611395 = header.getOrDefault("X-Amz-Algorithm")
  valid_611395 = validateParameter(valid_611395, JString, required = false,
                                 default = nil)
  if valid_611395 != nil:
    section.add "X-Amz-Algorithm", valid_611395
  var valid_611396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611396 = validateParameter(valid_611396, JString, required = false,
                                 default = nil)
  if valid_611396 != nil:
    section.add "X-Amz-SignedHeaders", valid_611396
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611397: Call_ListInvalidations20180618_611370; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists invalidation batches. 
  ## 
  let valid = call_611397.validator(path, query, header, formData, body)
  let scheme = call_611397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611397.url(scheme.get, call_611397.host, call_611397.base,
                         call_611397.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611397, url, valid)

proc call*(call_611398: Call_ListInvalidations20180618_611370;
          DistributionId: string; Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listInvalidations20180618
  ## Lists invalidation batches. 
  ##   Marker: string
  ##         : Use this parameter when paginating results to indicate where to begin in your list of invalidation batches. Because the results are returned in decreasing order from most recent to oldest, the most recent results are on the first page, the second page will contain earlier results, and so on. To get the next page of results, set <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response. This value is the same as the ID of the last invalidation batch on that page. 
  ##   MaxItems: string
  ##           : The maximum number of invalidation batches that you want in the response body.
  ##   DistributionId: string (required)
  ##                 : The distribution's ID.
  var path_611399 = newJObject()
  var query_611400 = newJObject()
  add(query_611400, "Marker", newJString(Marker))
  add(query_611400, "MaxItems", newJString(MaxItems))
  add(path_611399, "DistributionId", newJString(DistributionId))
  result = call_611398.call(path_611399, query_611400, nil, nil, nil)

var listInvalidations20180618* = Call_ListInvalidations20180618_611370(
    name: "listInvalidations20180618", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/distribution/{DistributionId}/invalidation",
    validator: validate_ListInvalidations20180618_611371, base: "/",
    url: url_ListInvalidations20180618_611372,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePublicKey20180618_611432 = ref object of OpenApiRestCall_610658
proc url_CreatePublicKey20180618_611434(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePublicKey20180618_611433(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Add a new public key to CloudFront to use, for example, for field-level encryption. You can add a maximum of 10 public keys with one AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611435 = header.getOrDefault("X-Amz-Signature")
  valid_611435 = validateParameter(valid_611435, JString, required = false,
                                 default = nil)
  if valid_611435 != nil:
    section.add "X-Amz-Signature", valid_611435
  var valid_611436 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611436 = validateParameter(valid_611436, JString, required = false,
                                 default = nil)
  if valid_611436 != nil:
    section.add "X-Amz-Content-Sha256", valid_611436
  var valid_611437 = header.getOrDefault("X-Amz-Date")
  valid_611437 = validateParameter(valid_611437, JString, required = false,
                                 default = nil)
  if valid_611437 != nil:
    section.add "X-Amz-Date", valid_611437
  var valid_611438 = header.getOrDefault("X-Amz-Credential")
  valid_611438 = validateParameter(valid_611438, JString, required = false,
                                 default = nil)
  if valid_611438 != nil:
    section.add "X-Amz-Credential", valid_611438
  var valid_611439 = header.getOrDefault("X-Amz-Security-Token")
  valid_611439 = validateParameter(valid_611439, JString, required = false,
                                 default = nil)
  if valid_611439 != nil:
    section.add "X-Amz-Security-Token", valid_611439
  var valid_611440 = header.getOrDefault("X-Amz-Algorithm")
  valid_611440 = validateParameter(valid_611440, JString, required = false,
                                 default = nil)
  if valid_611440 != nil:
    section.add "X-Amz-Algorithm", valid_611440
  var valid_611441 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611441 = validateParameter(valid_611441, JString, required = false,
                                 default = nil)
  if valid_611441 != nil:
    section.add "X-Amz-SignedHeaders", valid_611441
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611443: Call_CreatePublicKey20180618_611432; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Add a new public key to CloudFront to use, for example, for field-level encryption. You can add a maximum of 10 public keys with one AWS account.
  ## 
  let valid = call_611443.validator(path, query, header, formData, body)
  let scheme = call_611443.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611443.url(scheme.get, call_611443.host, call_611443.base,
                         call_611443.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611443, url, valid)

proc call*(call_611444: Call_CreatePublicKey20180618_611432; body: JsonNode): Recallable =
  ## createPublicKey20180618
  ## Add a new public key to CloudFront to use, for example, for field-level encryption. You can add a maximum of 10 public keys with one AWS account.
  ##   body: JObject (required)
  var body_611445 = newJObject()
  if body != nil:
    body_611445 = body
  result = call_611444.call(nil, nil, nil, nil, body_611445)

var createPublicKey20180618* = Call_CreatePublicKey20180618_611432(
    name: "createPublicKey20180618", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com", route: "/2018-06-18/public-key",
    validator: validate_CreatePublicKey20180618_611433, base: "/",
    url: url_CreatePublicKey20180618_611434, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPublicKeys20180618_611417 = ref object of OpenApiRestCall_610658
proc url_ListPublicKeys20180618_611419(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPublicKeys20180618_611418(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List all public keys that have been added to CloudFront for this account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Use this when paginating results to indicate where to begin in your list of public keys. The results include public keys in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last public key on that page). 
  ##   MaxItems: JString
  ##           : The maximum number of public keys you want in the response body. 
  section = newJObject()
  var valid_611420 = query.getOrDefault("Marker")
  valid_611420 = validateParameter(valid_611420, JString, required = false,
                                 default = nil)
  if valid_611420 != nil:
    section.add "Marker", valid_611420
  var valid_611421 = query.getOrDefault("MaxItems")
  valid_611421 = validateParameter(valid_611421, JString, required = false,
                                 default = nil)
  if valid_611421 != nil:
    section.add "MaxItems", valid_611421
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611422 = header.getOrDefault("X-Amz-Signature")
  valid_611422 = validateParameter(valid_611422, JString, required = false,
                                 default = nil)
  if valid_611422 != nil:
    section.add "X-Amz-Signature", valid_611422
  var valid_611423 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611423 = validateParameter(valid_611423, JString, required = false,
                                 default = nil)
  if valid_611423 != nil:
    section.add "X-Amz-Content-Sha256", valid_611423
  var valid_611424 = header.getOrDefault("X-Amz-Date")
  valid_611424 = validateParameter(valid_611424, JString, required = false,
                                 default = nil)
  if valid_611424 != nil:
    section.add "X-Amz-Date", valid_611424
  var valid_611425 = header.getOrDefault("X-Amz-Credential")
  valid_611425 = validateParameter(valid_611425, JString, required = false,
                                 default = nil)
  if valid_611425 != nil:
    section.add "X-Amz-Credential", valid_611425
  var valid_611426 = header.getOrDefault("X-Amz-Security-Token")
  valid_611426 = validateParameter(valid_611426, JString, required = false,
                                 default = nil)
  if valid_611426 != nil:
    section.add "X-Amz-Security-Token", valid_611426
  var valid_611427 = header.getOrDefault("X-Amz-Algorithm")
  valid_611427 = validateParameter(valid_611427, JString, required = false,
                                 default = nil)
  if valid_611427 != nil:
    section.add "X-Amz-Algorithm", valid_611427
  var valid_611428 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611428 = validateParameter(valid_611428, JString, required = false,
                                 default = nil)
  if valid_611428 != nil:
    section.add "X-Amz-SignedHeaders", valid_611428
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611429: Call_ListPublicKeys20180618_611417; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all public keys that have been added to CloudFront for this account.
  ## 
  let valid = call_611429.validator(path, query, header, formData, body)
  let scheme = call_611429.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611429.url(scheme.get, call_611429.host, call_611429.base,
                         call_611429.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611429, url, valid)

proc call*(call_611430: Call_ListPublicKeys20180618_611417; Marker: string = "";
          MaxItems: string = ""): Recallable =
  ## listPublicKeys20180618
  ## List all public keys that have been added to CloudFront for this account.
  ##   Marker: string
  ##         : Use this when paginating results to indicate where to begin in your list of public keys. The results include public keys in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last public key on that page). 
  ##   MaxItems: string
  ##           : The maximum number of public keys you want in the response body. 
  var query_611431 = newJObject()
  add(query_611431, "Marker", newJString(Marker))
  add(query_611431, "MaxItems", newJString(MaxItems))
  result = call_611430.call(nil, query_611431, nil, nil, nil)

var listPublicKeys20180618* = Call_ListPublicKeys20180618_611417(
    name: "listPublicKeys20180618", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2018-06-18/public-key",
    validator: validate_ListPublicKeys20180618_611418, base: "/",
    url: url_ListPublicKeys20180618_611419, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStreamingDistribution20180618_611461 = ref object of OpenApiRestCall_610658
proc url_CreateStreamingDistribution20180618_611463(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateStreamingDistribution20180618_611462(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new RMTP distribution. An RTMP distribution is similar to a web distribution, but an RTMP distribution streams media files using the Adobe Real-Time Messaging Protocol (RTMP) instead of serving files using HTTP. </p> <p>To create a new web distribution, submit a <code>POST</code> request to the <i>CloudFront API version</i>/distribution resource. The request body must include a document with a <i>StreamingDistributionConfig</i> element. The response echoes the <code>StreamingDistributionConfig</code> element and returns other information about the RTMP distribution.</p> <p>To get the status of your request, use the <i>GET StreamingDistribution</i> API action. When the value of <code>Enabled</code> is <code>true</code> and the value of <code>Status</code> is <code>Deployed</code>, your distribution is ready. A distribution usually deploys in less than 15 minutes.</p> <p>For more information about web distributions, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-rtmp.html">Working with RTMP Distributions</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <important> <p>Beginning with the 2012-05-05 version of the CloudFront API, we made substantial changes to the format of the XML document that you include in the request body when you create or update a web distribution or an RTMP distribution, and when you invalidate objects. With previous versions of the API, we discovered that it was too easy to accidentally delete one or more values for an element that accepts multiple values, for example, CNAMEs and trusted signers. Our changes for the 2012-05-05 release are intended to prevent these accidental deletions and to notify you when there's a mismatch between the number of values you say you're specifying in the <code>Quantity</code> element and the number of values specified.</p> </important>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611464 = header.getOrDefault("X-Amz-Signature")
  valid_611464 = validateParameter(valid_611464, JString, required = false,
                                 default = nil)
  if valid_611464 != nil:
    section.add "X-Amz-Signature", valid_611464
  var valid_611465 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611465 = validateParameter(valid_611465, JString, required = false,
                                 default = nil)
  if valid_611465 != nil:
    section.add "X-Amz-Content-Sha256", valid_611465
  var valid_611466 = header.getOrDefault("X-Amz-Date")
  valid_611466 = validateParameter(valid_611466, JString, required = false,
                                 default = nil)
  if valid_611466 != nil:
    section.add "X-Amz-Date", valid_611466
  var valid_611467 = header.getOrDefault("X-Amz-Credential")
  valid_611467 = validateParameter(valid_611467, JString, required = false,
                                 default = nil)
  if valid_611467 != nil:
    section.add "X-Amz-Credential", valid_611467
  var valid_611468 = header.getOrDefault("X-Amz-Security-Token")
  valid_611468 = validateParameter(valid_611468, JString, required = false,
                                 default = nil)
  if valid_611468 != nil:
    section.add "X-Amz-Security-Token", valid_611468
  var valid_611469 = header.getOrDefault("X-Amz-Algorithm")
  valid_611469 = validateParameter(valid_611469, JString, required = false,
                                 default = nil)
  if valid_611469 != nil:
    section.add "X-Amz-Algorithm", valid_611469
  var valid_611470 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611470 = validateParameter(valid_611470, JString, required = false,
                                 default = nil)
  if valid_611470 != nil:
    section.add "X-Amz-SignedHeaders", valid_611470
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611472: Call_CreateStreamingDistribution20180618_611461;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a new RMTP distribution. An RTMP distribution is similar to a web distribution, but an RTMP distribution streams media files using the Adobe Real-Time Messaging Protocol (RTMP) instead of serving files using HTTP. </p> <p>To create a new web distribution, submit a <code>POST</code> request to the <i>CloudFront API version</i>/distribution resource. The request body must include a document with a <i>StreamingDistributionConfig</i> element. The response echoes the <code>StreamingDistributionConfig</code> element and returns other information about the RTMP distribution.</p> <p>To get the status of your request, use the <i>GET StreamingDistribution</i> API action. When the value of <code>Enabled</code> is <code>true</code> and the value of <code>Status</code> is <code>Deployed</code>, your distribution is ready. A distribution usually deploys in less than 15 minutes.</p> <p>For more information about web distributions, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-rtmp.html">Working with RTMP Distributions</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <important> <p>Beginning with the 2012-05-05 version of the CloudFront API, we made substantial changes to the format of the XML document that you include in the request body when you create or update a web distribution or an RTMP distribution, and when you invalidate objects. With previous versions of the API, we discovered that it was too easy to accidentally delete one or more values for an element that accepts multiple values, for example, CNAMEs and trusted signers. Our changes for the 2012-05-05 release are intended to prevent these accidental deletions and to notify you when there's a mismatch between the number of values you say you're specifying in the <code>Quantity</code> element and the number of values specified.</p> </important>
  ## 
  let valid = call_611472.validator(path, query, header, formData, body)
  let scheme = call_611472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611472.url(scheme.get, call_611472.host, call_611472.base,
                         call_611472.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611472, url, valid)

proc call*(call_611473: Call_CreateStreamingDistribution20180618_611461;
          body: JsonNode): Recallable =
  ## createStreamingDistribution20180618
  ## <p>Creates a new RMTP distribution. An RTMP distribution is similar to a web distribution, but an RTMP distribution streams media files using the Adobe Real-Time Messaging Protocol (RTMP) instead of serving files using HTTP. </p> <p>To create a new web distribution, submit a <code>POST</code> request to the <i>CloudFront API version</i>/distribution resource. The request body must include a document with a <i>StreamingDistributionConfig</i> element. The response echoes the <code>StreamingDistributionConfig</code> element and returns other information about the RTMP distribution.</p> <p>To get the status of your request, use the <i>GET StreamingDistribution</i> API action. When the value of <code>Enabled</code> is <code>true</code> and the value of <code>Status</code> is <code>Deployed</code>, your distribution is ready. A distribution usually deploys in less than 15 minutes.</p> <p>For more information about web distributions, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-rtmp.html">Working with RTMP Distributions</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <important> <p>Beginning with the 2012-05-05 version of the CloudFront API, we made substantial changes to the format of the XML document that you include in the request body when you create or update a web distribution or an RTMP distribution, and when you invalidate objects. With previous versions of the API, we discovered that it was too easy to accidentally delete one or more values for an element that accepts multiple values, for example, CNAMEs and trusted signers. Our changes for the 2012-05-05 release are intended to prevent these accidental deletions and to notify you when there's a mismatch between the number of values you say you're specifying in the <code>Quantity</code> element and the number of values specified.</p> </important>
  ##   body: JObject (required)
  var body_611474 = newJObject()
  if body != nil:
    body_611474 = body
  result = call_611473.call(nil, nil, nil, nil, body_611474)

var createStreamingDistribution20180618* = Call_CreateStreamingDistribution20180618_611461(
    name: "createStreamingDistribution20180618", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com", route: "/2018-06-18/streaming-distribution",
    validator: validate_CreateStreamingDistribution20180618_611462, base: "/",
    url: url_CreateStreamingDistribution20180618_611463,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListStreamingDistributions20180618_611446 = ref object of OpenApiRestCall_610658
proc url_ListStreamingDistributions20180618_611448(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListStreamingDistributions20180618_611447(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List streaming distributions. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : The value that you provided for the <code>Marker</code> request parameter.
  ##   MaxItems: JString
  ##           : The value that you provided for the <code>MaxItems</code> request parameter.
  section = newJObject()
  var valid_611449 = query.getOrDefault("Marker")
  valid_611449 = validateParameter(valid_611449, JString, required = false,
                                 default = nil)
  if valid_611449 != nil:
    section.add "Marker", valid_611449
  var valid_611450 = query.getOrDefault("MaxItems")
  valid_611450 = validateParameter(valid_611450, JString, required = false,
                                 default = nil)
  if valid_611450 != nil:
    section.add "MaxItems", valid_611450
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611451 = header.getOrDefault("X-Amz-Signature")
  valid_611451 = validateParameter(valid_611451, JString, required = false,
                                 default = nil)
  if valid_611451 != nil:
    section.add "X-Amz-Signature", valid_611451
  var valid_611452 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611452 = validateParameter(valid_611452, JString, required = false,
                                 default = nil)
  if valid_611452 != nil:
    section.add "X-Amz-Content-Sha256", valid_611452
  var valid_611453 = header.getOrDefault("X-Amz-Date")
  valid_611453 = validateParameter(valid_611453, JString, required = false,
                                 default = nil)
  if valid_611453 != nil:
    section.add "X-Amz-Date", valid_611453
  var valid_611454 = header.getOrDefault("X-Amz-Credential")
  valid_611454 = validateParameter(valid_611454, JString, required = false,
                                 default = nil)
  if valid_611454 != nil:
    section.add "X-Amz-Credential", valid_611454
  var valid_611455 = header.getOrDefault("X-Amz-Security-Token")
  valid_611455 = validateParameter(valid_611455, JString, required = false,
                                 default = nil)
  if valid_611455 != nil:
    section.add "X-Amz-Security-Token", valid_611455
  var valid_611456 = header.getOrDefault("X-Amz-Algorithm")
  valid_611456 = validateParameter(valid_611456, JString, required = false,
                                 default = nil)
  if valid_611456 != nil:
    section.add "X-Amz-Algorithm", valid_611456
  var valid_611457 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611457 = validateParameter(valid_611457, JString, required = false,
                                 default = nil)
  if valid_611457 != nil:
    section.add "X-Amz-SignedHeaders", valid_611457
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611458: Call_ListStreamingDistributions20180618_611446;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## List streaming distributions. 
  ## 
  let valid = call_611458.validator(path, query, header, formData, body)
  let scheme = call_611458.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611458.url(scheme.get, call_611458.host, call_611458.base,
                         call_611458.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611458, url, valid)

proc call*(call_611459: Call_ListStreamingDistributions20180618_611446;
          Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listStreamingDistributions20180618
  ## List streaming distributions. 
  ##   Marker: string
  ##         : The value that you provided for the <code>Marker</code> request parameter.
  ##   MaxItems: string
  ##           : The value that you provided for the <code>MaxItems</code> request parameter.
  var query_611460 = newJObject()
  add(query_611460, "Marker", newJString(Marker))
  add(query_611460, "MaxItems", newJString(MaxItems))
  result = call_611459.call(nil, query_611460, nil, nil, nil)

var listStreamingDistributions20180618* = Call_ListStreamingDistributions20180618_611446(
    name: "listStreamingDistributions20180618", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2018-06-18/streaming-distribution",
    validator: validate_ListStreamingDistributions20180618_611447, base: "/",
    url: url_ListStreamingDistributions20180618_611448,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStreamingDistributionWithTags20180618_611475 = ref object of OpenApiRestCall_610658
proc url_CreateStreamingDistributionWithTags20180618_611477(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateStreamingDistributionWithTags20180618_611476(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Create a new streaming distribution with tags.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   WithTags: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `WithTags` field"
  var valid_611478 = query.getOrDefault("WithTags")
  valid_611478 = validateParameter(valid_611478, JBool, required = true, default = nil)
  if valid_611478 != nil:
    section.add "WithTags", valid_611478
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611479 = header.getOrDefault("X-Amz-Signature")
  valid_611479 = validateParameter(valid_611479, JString, required = false,
                                 default = nil)
  if valid_611479 != nil:
    section.add "X-Amz-Signature", valid_611479
  var valid_611480 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611480 = validateParameter(valid_611480, JString, required = false,
                                 default = nil)
  if valid_611480 != nil:
    section.add "X-Amz-Content-Sha256", valid_611480
  var valid_611481 = header.getOrDefault("X-Amz-Date")
  valid_611481 = validateParameter(valid_611481, JString, required = false,
                                 default = nil)
  if valid_611481 != nil:
    section.add "X-Amz-Date", valid_611481
  var valid_611482 = header.getOrDefault("X-Amz-Credential")
  valid_611482 = validateParameter(valid_611482, JString, required = false,
                                 default = nil)
  if valid_611482 != nil:
    section.add "X-Amz-Credential", valid_611482
  var valid_611483 = header.getOrDefault("X-Amz-Security-Token")
  valid_611483 = validateParameter(valid_611483, JString, required = false,
                                 default = nil)
  if valid_611483 != nil:
    section.add "X-Amz-Security-Token", valid_611483
  var valid_611484 = header.getOrDefault("X-Amz-Algorithm")
  valid_611484 = validateParameter(valid_611484, JString, required = false,
                                 default = nil)
  if valid_611484 != nil:
    section.add "X-Amz-Algorithm", valid_611484
  var valid_611485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611485 = validateParameter(valid_611485, JString, required = false,
                                 default = nil)
  if valid_611485 != nil:
    section.add "X-Amz-SignedHeaders", valid_611485
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611487: Call_CreateStreamingDistributionWithTags20180618_611475;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Create a new streaming distribution with tags.
  ## 
  let valid = call_611487.validator(path, query, header, formData, body)
  let scheme = call_611487.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611487.url(scheme.get, call_611487.host, call_611487.base,
                         call_611487.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611487, url, valid)

proc call*(call_611488: Call_CreateStreamingDistributionWithTags20180618_611475;
          body: JsonNode; WithTags: bool): Recallable =
  ## createStreamingDistributionWithTags20180618
  ## Create a new streaming distribution with tags.
  ##   body: JObject (required)
  ##   WithTags: bool (required)
  var query_611489 = newJObject()
  var body_611490 = newJObject()
  if body != nil:
    body_611490 = body
  add(query_611489, "WithTags", newJBool(WithTags))
  result = call_611488.call(nil, query_611489, nil, nil, body_611490)

var createStreamingDistributionWithTags20180618* = Call_CreateStreamingDistributionWithTags20180618_611475(
    name: "createStreamingDistributionWithTags20180618",
    meth: HttpMethod.HttpPost, host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/streaming-distribution#WithTags",
    validator: validate_CreateStreamingDistributionWithTags20180618_611476,
    base: "/", url: url_CreateStreamingDistributionWithTags20180618_611477,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCloudFrontOriginAccessIdentity20180618_611491 = ref object of OpenApiRestCall_610658
proc url_GetCloudFrontOriginAccessIdentity20180618_611493(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2018-06-18/origin-access-identity/cloudfront/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetCloudFrontOriginAccessIdentity20180618_611492(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get the information about an origin access identity. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The identity's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_611494 = path.getOrDefault("Id")
  valid_611494 = validateParameter(valid_611494, JString, required = true,
                                 default = nil)
  if valid_611494 != nil:
    section.add "Id", valid_611494
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611495 = header.getOrDefault("X-Amz-Signature")
  valid_611495 = validateParameter(valid_611495, JString, required = false,
                                 default = nil)
  if valid_611495 != nil:
    section.add "X-Amz-Signature", valid_611495
  var valid_611496 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611496 = validateParameter(valid_611496, JString, required = false,
                                 default = nil)
  if valid_611496 != nil:
    section.add "X-Amz-Content-Sha256", valid_611496
  var valid_611497 = header.getOrDefault("X-Amz-Date")
  valid_611497 = validateParameter(valid_611497, JString, required = false,
                                 default = nil)
  if valid_611497 != nil:
    section.add "X-Amz-Date", valid_611497
  var valid_611498 = header.getOrDefault("X-Amz-Credential")
  valid_611498 = validateParameter(valid_611498, JString, required = false,
                                 default = nil)
  if valid_611498 != nil:
    section.add "X-Amz-Credential", valid_611498
  var valid_611499 = header.getOrDefault("X-Amz-Security-Token")
  valid_611499 = validateParameter(valid_611499, JString, required = false,
                                 default = nil)
  if valid_611499 != nil:
    section.add "X-Amz-Security-Token", valid_611499
  var valid_611500 = header.getOrDefault("X-Amz-Algorithm")
  valid_611500 = validateParameter(valid_611500, JString, required = false,
                                 default = nil)
  if valid_611500 != nil:
    section.add "X-Amz-Algorithm", valid_611500
  var valid_611501 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611501 = validateParameter(valid_611501, JString, required = false,
                                 default = nil)
  if valid_611501 != nil:
    section.add "X-Amz-SignedHeaders", valid_611501
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611502: Call_GetCloudFrontOriginAccessIdentity20180618_611491;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Get the information about an origin access identity. 
  ## 
  let valid = call_611502.validator(path, query, header, formData, body)
  let scheme = call_611502.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611502.url(scheme.get, call_611502.host, call_611502.base,
                         call_611502.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611502, url, valid)

proc call*(call_611503: Call_GetCloudFrontOriginAccessIdentity20180618_611491;
          Id: string): Recallable =
  ## getCloudFrontOriginAccessIdentity20180618
  ## Get the information about an origin access identity. 
  ##   Id: string (required)
  ##     : The identity's ID.
  var path_611504 = newJObject()
  add(path_611504, "Id", newJString(Id))
  result = call_611503.call(path_611504, nil, nil, nil, nil)

var getCloudFrontOriginAccessIdentity20180618* = Call_GetCloudFrontOriginAccessIdentity20180618_611491(
    name: "getCloudFrontOriginAccessIdentity20180618", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/origin-access-identity/cloudfront/{Id}",
    validator: validate_GetCloudFrontOriginAccessIdentity20180618_611492,
    base: "/", url: url_GetCloudFrontOriginAccessIdentity20180618_611493,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCloudFrontOriginAccessIdentity20180618_611505 = ref object of OpenApiRestCall_610658
proc url_DeleteCloudFrontOriginAccessIdentity20180618_611507(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2018-06-18/origin-access-identity/cloudfront/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteCloudFrontOriginAccessIdentity20180618_611506(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Delete an origin access identity. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The origin access identity's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_611508 = path.getOrDefault("Id")
  valid_611508 = validateParameter(valid_611508, JString, required = true,
                                 default = nil)
  if valid_611508 != nil:
    section.add "Id", valid_611508
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header you received from a previous <code>GET</code> or <code>PUT</code> request. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611509 = header.getOrDefault("X-Amz-Signature")
  valid_611509 = validateParameter(valid_611509, JString, required = false,
                                 default = nil)
  if valid_611509 != nil:
    section.add "X-Amz-Signature", valid_611509
  var valid_611510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611510 = validateParameter(valid_611510, JString, required = false,
                                 default = nil)
  if valid_611510 != nil:
    section.add "X-Amz-Content-Sha256", valid_611510
  var valid_611511 = header.getOrDefault("X-Amz-Date")
  valid_611511 = validateParameter(valid_611511, JString, required = false,
                                 default = nil)
  if valid_611511 != nil:
    section.add "X-Amz-Date", valid_611511
  var valid_611512 = header.getOrDefault("X-Amz-Credential")
  valid_611512 = validateParameter(valid_611512, JString, required = false,
                                 default = nil)
  if valid_611512 != nil:
    section.add "X-Amz-Credential", valid_611512
  var valid_611513 = header.getOrDefault("X-Amz-Security-Token")
  valid_611513 = validateParameter(valid_611513, JString, required = false,
                                 default = nil)
  if valid_611513 != nil:
    section.add "X-Amz-Security-Token", valid_611513
  var valid_611514 = header.getOrDefault("If-Match")
  valid_611514 = validateParameter(valid_611514, JString, required = false,
                                 default = nil)
  if valid_611514 != nil:
    section.add "If-Match", valid_611514
  var valid_611515 = header.getOrDefault("X-Amz-Algorithm")
  valid_611515 = validateParameter(valid_611515, JString, required = false,
                                 default = nil)
  if valid_611515 != nil:
    section.add "X-Amz-Algorithm", valid_611515
  var valid_611516 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611516 = validateParameter(valid_611516, JString, required = false,
                                 default = nil)
  if valid_611516 != nil:
    section.add "X-Amz-SignedHeaders", valid_611516
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611517: Call_DeleteCloudFrontOriginAccessIdentity20180618_611505;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Delete an origin access identity. 
  ## 
  let valid = call_611517.validator(path, query, header, formData, body)
  let scheme = call_611517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611517.url(scheme.get, call_611517.host, call_611517.base,
                         call_611517.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611517, url, valid)

proc call*(call_611518: Call_DeleteCloudFrontOriginAccessIdentity20180618_611505;
          Id: string): Recallable =
  ## deleteCloudFrontOriginAccessIdentity20180618
  ## Delete an origin access identity. 
  ##   Id: string (required)
  ##     : The origin access identity's ID.
  var path_611519 = newJObject()
  add(path_611519, "Id", newJString(Id))
  result = call_611518.call(path_611519, nil, nil, nil, nil)

var deleteCloudFrontOriginAccessIdentity20180618* = Call_DeleteCloudFrontOriginAccessIdentity20180618_611505(
    name: "deleteCloudFrontOriginAccessIdentity20180618",
    meth: HttpMethod.HttpDelete, host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/origin-access-identity/cloudfront/{Id}",
    validator: validate_DeleteCloudFrontOriginAccessIdentity20180618_611506,
    base: "/", url: url_DeleteCloudFrontOriginAccessIdentity20180618_611507,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDistribution20180618_611520 = ref object of OpenApiRestCall_610658
proc url_GetDistribution20180618_611522(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-06-18/distribution/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDistribution20180618_611521(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get the information about a distribution. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The distribution's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_611523 = path.getOrDefault("Id")
  valid_611523 = validateParameter(valid_611523, JString, required = true,
                                 default = nil)
  if valid_611523 != nil:
    section.add "Id", valid_611523
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611524 = header.getOrDefault("X-Amz-Signature")
  valid_611524 = validateParameter(valid_611524, JString, required = false,
                                 default = nil)
  if valid_611524 != nil:
    section.add "X-Amz-Signature", valid_611524
  var valid_611525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611525 = validateParameter(valid_611525, JString, required = false,
                                 default = nil)
  if valid_611525 != nil:
    section.add "X-Amz-Content-Sha256", valid_611525
  var valid_611526 = header.getOrDefault("X-Amz-Date")
  valid_611526 = validateParameter(valid_611526, JString, required = false,
                                 default = nil)
  if valid_611526 != nil:
    section.add "X-Amz-Date", valid_611526
  var valid_611527 = header.getOrDefault("X-Amz-Credential")
  valid_611527 = validateParameter(valid_611527, JString, required = false,
                                 default = nil)
  if valid_611527 != nil:
    section.add "X-Amz-Credential", valid_611527
  var valid_611528 = header.getOrDefault("X-Amz-Security-Token")
  valid_611528 = validateParameter(valid_611528, JString, required = false,
                                 default = nil)
  if valid_611528 != nil:
    section.add "X-Amz-Security-Token", valid_611528
  var valid_611529 = header.getOrDefault("X-Amz-Algorithm")
  valid_611529 = validateParameter(valid_611529, JString, required = false,
                                 default = nil)
  if valid_611529 != nil:
    section.add "X-Amz-Algorithm", valid_611529
  var valid_611530 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611530 = validateParameter(valid_611530, JString, required = false,
                                 default = nil)
  if valid_611530 != nil:
    section.add "X-Amz-SignedHeaders", valid_611530
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611531: Call_GetDistribution20180618_611520; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the information about a distribution. 
  ## 
  let valid = call_611531.validator(path, query, header, formData, body)
  let scheme = call_611531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611531.url(scheme.get, call_611531.host, call_611531.base,
                         call_611531.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611531, url, valid)

proc call*(call_611532: Call_GetDistribution20180618_611520; Id: string): Recallable =
  ## getDistribution20180618
  ## Get the information about a distribution. 
  ##   Id: string (required)
  ##     : The distribution's ID.
  var path_611533 = newJObject()
  add(path_611533, "Id", newJString(Id))
  result = call_611532.call(path_611533, nil, nil, nil, nil)

var getDistribution20180618* = Call_GetDistribution20180618_611520(
    name: "getDistribution20180618", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2018-06-18/distribution/{Id}",
    validator: validate_GetDistribution20180618_611521, base: "/",
    url: url_GetDistribution20180618_611522, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDistribution20180618_611534 = ref object of OpenApiRestCall_610658
proc url_DeleteDistribution20180618_611536(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-06-18/distribution/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDistribution20180618_611535(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Delete a distribution. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The distribution ID. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_611537 = path.getOrDefault("Id")
  valid_611537 = validateParameter(valid_611537, JString, required = true,
                                 default = nil)
  if valid_611537 != nil:
    section.add "Id", valid_611537
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when you disabled the distribution. For example: <code>E2QWRUHAPOMQZL</code>. 
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611538 = header.getOrDefault("X-Amz-Signature")
  valid_611538 = validateParameter(valid_611538, JString, required = false,
                                 default = nil)
  if valid_611538 != nil:
    section.add "X-Amz-Signature", valid_611538
  var valid_611539 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611539 = validateParameter(valid_611539, JString, required = false,
                                 default = nil)
  if valid_611539 != nil:
    section.add "X-Amz-Content-Sha256", valid_611539
  var valid_611540 = header.getOrDefault("X-Amz-Date")
  valid_611540 = validateParameter(valid_611540, JString, required = false,
                                 default = nil)
  if valid_611540 != nil:
    section.add "X-Amz-Date", valid_611540
  var valid_611541 = header.getOrDefault("X-Amz-Credential")
  valid_611541 = validateParameter(valid_611541, JString, required = false,
                                 default = nil)
  if valid_611541 != nil:
    section.add "X-Amz-Credential", valid_611541
  var valid_611542 = header.getOrDefault("X-Amz-Security-Token")
  valid_611542 = validateParameter(valid_611542, JString, required = false,
                                 default = nil)
  if valid_611542 != nil:
    section.add "X-Amz-Security-Token", valid_611542
  var valid_611543 = header.getOrDefault("If-Match")
  valid_611543 = validateParameter(valid_611543, JString, required = false,
                                 default = nil)
  if valid_611543 != nil:
    section.add "If-Match", valid_611543
  var valid_611544 = header.getOrDefault("X-Amz-Algorithm")
  valid_611544 = validateParameter(valid_611544, JString, required = false,
                                 default = nil)
  if valid_611544 != nil:
    section.add "X-Amz-Algorithm", valid_611544
  var valid_611545 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611545 = validateParameter(valid_611545, JString, required = false,
                                 default = nil)
  if valid_611545 != nil:
    section.add "X-Amz-SignedHeaders", valid_611545
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611546: Call_DeleteDistribution20180618_611534; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a distribution. 
  ## 
  let valid = call_611546.validator(path, query, header, formData, body)
  let scheme = call_611546.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611546.url(scheme.get, call_611546.host, call_611546.base,
                         call_611546.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611546, url, valid)

proc call*(call_611547: Call_DeleteDistribution20180618_611534; Id: string): Recallable =
  ## deleteDistribution20180618
  ## Delete a distribution. 
  ##   Id: string (required)
  ##     : The distribution ID. 
  var path_611548 = newJObject()
  add(path_611548, "Id", newJString(Id))
  result = call_611547.call(path_611548, nil, nil, nil, nil)

var deleteDistribution20180618* = Call_DeleteDistribution20180618_611534(
    name: "deleteDistribution20180618", meth: HttpMethod.HttpDelete,
    host: "cloudfront.amazonaws.com", route: "/2018-06-18/distribution/{Id}",
    validator: validate_DeleteDistribution20180618_611535, base: "/",
    url: url_DeleteDistribution20180618_611536,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFieldLevelEncryption20180618_611549 = ref object of OpenApiRestCall_610658
proc url_GetFieldLevelEncryption20180618_611551(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2018-06-18/field-level-encryption/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFieldLevelEncryption20180618_611550(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get the field-level encryption configuration information.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : Request the ID for the field-level encryption configuration information.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_611552 = path.getOrDefault("Id")
  valid_611552 = validateParameter(valid_611552, JString, required = true,
                                 default = nil)
  if valid_611552 != nil:
    section.add "Id", valid_611552
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611553 = header.getOrDefault("X-Amz-Signature")
  valid_611553 = validateParameter(valid_611553, JString, required = false,
                                 default = nil)
  if valid_611553 != nil:
    section.add "X-Amz-Signature", valid_611553
  var valid_611554 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611554 = validateParameter(valid_611554, JString, required = false,
                                 default = nil)
  if valid_611554 != nil:
    section.add "X-Amz-Content-Sha256", valid_611554
  var valid_611555 = header.getOrDefault("X-Amz-Date")
  valid_611555 = validateParameter(valid_611555, JString, required = false,
                                 default = nil)
  if valid_611555 != nil:
    section.add "X-Amz-Date", valid_611555
  var valid_611556 = header.getOrDefault("X-Amz-Credential")
  valid_611556 = validateParameter(valid_611556, JString, required = false,
                                 default = nil)
  if valid_611556 != nil:
    section.add "X-Amz-Credential", valid_611556
  var valid_611557 = header.getOrDefault("X-Amz-Security-Token")
  valid_611557 = validateParameter(valid_611557, JString, required = false,
                                 default = nil)
  if valid_611557 != nil:
    section.add "X-Amz-Security-Token", valid_611557
  var valid_611558 = header.getOrDefault("X-Amz-Algorithm")
  valid_611558 = validateParameter(valid_611558, JString, required = false,
                                 default = nil)
  if valid_611558 != nil:
    section.add "X-Amz-Algorithm", valid_611558
  var valid_611559 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611559 = validateParameter(valid_611559, JString, required = false,
                                 default = nil)
  if valid_611559 != nil:
    section.add "X-Amz-SignedHeaders", valid_611559
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611560: Call_GetFieldLevelEncryption20180618_611549;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Get the field-level encryption configuration information.
  ## 
  let valid = call_611560.validator(path, query, header, formData, body)
  let scheme = call_611560.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611560.url(scheme.get, call_611560.host, call_611560.base,
                         call_611560.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611560, url, valid)

proc call*(call_611561: Call_GetFieldLevelEncryption20180618_611549; Id: string): Recallable =
  ## getFieldLevelEncryption20180618
  ## Get the field-level encryption configuration information.
  ##   Id: string (required)
  ##     : Request the ID for the field-level encryption configuration information.
  var path_611562 = newJObject()
  add(path_611562, "Id", newJString(Id))
  result = call_611561.call(path_611562, nil, nil, nil, nil)

var getFieldLevelEncryption20180618* = Call_GetFieldLevelEncryption20180618_611549(
    name: "getFieldLevelEncryption20180618", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/field-level-encryption/{Id}",
    validator: validate_GetFieldLevelEncryption20180618_611550, base: "/",
    url: url_GetFieldLevelEncryption20180618_611551,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFieldLevelEncryptionConfig20180618_611563 = ref object of OpenApiRestCall_610658
proc url_DeleteFieldLevelEncryptionConfig20180618_611565(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2018-06-18/field-level-encryption/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteFieldLevelEncryptionConfig20180618_611564(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Remove a field-level encryption configuration.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the configuration you want to delete from CloudFront.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_611566 = path.getOrDefault("Id")
  valid_611566 = validateParameter(valid_611566, JString, required = true,
                                 default = nil)
  if valid_611566 != nil:
    section.add "Id", valid_611566
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the configuration identity to delete. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611567 = header.getOrDefault("X-Amz-Signature")
  valid_611567 = validateParameter(valid_611567, JString, required = false,
                                 default = nil)
  if valid_611567 != nil:
    section.add "X-Amz-Signature", valid_611567
  var valid_611568 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611568 = validateParameter(valid_611568, JString, required = false,
                                 default = nil)
  if valid_611568 != nil:
    section.add "X-Amz-Content-Sha256", valid_611568
  var valid_611569 = header.getOrDefault("X-Amz-Date")
  valid_611569 = validateParameter(valid_611569, JString, required = false,
                                 default = nil)
  if valid_611569 != nil:
    section.add "X-Amz-Date", valid_611569
  var valid_611570 = header.getOrDefault("X-Amz-Credential")
  valid_611570 = validateParameter(valid_611570, JString, required = false,
                                 default = nil)
  if valid_611570 != nil:
    section.add "X-Amz-Credential", valid_611570
  var valid_611571 = header.getOrDefault("X-Amz-Security-Token")
  valid_611571 = validateParameter(valid_611571, JString, required = false,
                                 default = nil)
  if valid_611571 != nil:
    section.add "X-Amz-Security-Token", valid_611571
  var valid_611572 = header.getOrDefault("If-Match")
  valid_611572 = validateParameter(valid_611572, JString, required = false,
                                 default = nil)
  if valid_611572 != nil:
    section.add "If-Match", valid_611572
  var valid_611573 = header.getOrDefault("X-Amz-Algorithm")
  valid_611573 = validateParameter(valid_611573, JString, required = false,
                                 default = nil)
  if valid_611573 != nil:
    section.add "X-Amz-Algorithm", valid_611573
  var valid_611574 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611574 = validateParameter(valid_611574, JString, required = false,
                                 default = nil)
  if valid_611574 != nil:
    section.add "X-Amz-SignedHeaders", valid_611574
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611575: Call_DeleteFieldLevelEncryptionConfig20180618_611563;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Remove a field-level encryption configuration.
  ## 
  let valid = call_611575.validator(path, query, header, formData, body)
  let scheme = call_611575.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611575.url(scheme.get, call_611575.host, call_611575.base,
                         call_611575.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611575, url, valid)

proc call*(call_611576: Call_DeleteFieldLevelEncryptionConfig20180618_611563;
          Id: string): Recallable =
  ## deleteFieldLevelEncryptionConfig20180618
  ## Remove a field-level encryption configuration.
  ##   Id: string (required)
  ##     : The ID of the configuration you want to delete from CloudFront.
  var path_611577 = newJObject()
  add(path_611577, "Id", newJString(Id))
  result = call_611576.call(path_611577, nil, nil, nil, nil)

var deleteFieldLevelEncryptionConfig20180618* = Call_DeleteFieldLevelEncryptionConfig20180618_611563(
    name: "deleteFieldLevelEncryptionConfig20180618", meth: HttpMethod.HttpDelete,
    host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/field-level-encryption/{Id}",
    validator: validate_DeleteFieldLevelEncryptionConfig20180618_611564,
    base: "/", url: url_DeleteFieldLevelEncryptionConfig20180618_611565,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFieldLevelEncryptionProfile20180618_611578 = ref object of OpenApiRestCall_610658
proc url_GetFieldLevelEncryptionProfile20180618_611580(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2018-06-18/field-level-encryption-profile/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFieldLevelEncryptionProfile20180618_611579(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get the field-level encryption profile information.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : Get the ID for the field-level encryption profile information.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_611581 = path.getOrDefault("Id")
  valid_611581 = validateParameter(valid_611581, JString, required = true,
                                 default = nil)
  if valid_611581 != nil:
    section.add "Id", valid_611581
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611582 = header.getOrDefault("X-Amz-Signature")
  valid_611582 = validateParameter(valid_611582, JString, required = false,
                                 default = nil)
  if valid_611582 != nil:
    section.add "X-Amz-Signature", valid_611582
  var valid_611583 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611583 = validateParameter(valid_611583, JString, required = false,
                                 default = nil)
  if valid_611583 != nil:
    section.add "X-Amz-Content-Sha256", valid_611583
  var valid_611584 = header.getOrDefault("X-Amz-Date")
  valid_611584 = validateParameter(valid_611584, JString, required = false,
                                 default = nil)
  if valid_611584 != nil:
    section.add "X-Amz-Date", valid_611584
  var valid_611585 = header.getOrDefault("X-Amz-Credential")
  valid_611585 = validateParameter(valid_611585, JString, required = false,
                                 default = nil)
  if valid_611585 != nil:
    section.add "X-Amz-Credential", valid_611585
  var valid_611586 = header.getOrDefault("X-Amz-Security-Token")
  valid_611586 = validateParameter(valid_611586, JString, required = false,
                                 default = nil)
  if valid_611586 != nil:
    section.add "X-Amz-Security-Token", valid_611586
  var valid_611587 = header.getOrDefault("X-Amz-Algorithm")
  valid_611587 = validateParameter(valid_611587, JString, required = false,
                                 default = nil)
  if valid_611587 != nil:
    section.add "X-Amz-Algorithm", valid_611587
  var valid_611588 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611588 = validateParameter(valid_611588, JString, required = false,
                                 default = nil)
  if valid_611588 != nil:
    section.add "X-Amz-SignedHeaders", valid_611588
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611589: Call_GetFieldLevelEncryptionProfile20180618_611578;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Get the field-level encryption profile information.
  ## 
  let valid = call_611589.validator(path, query, header, formData, body)
  let scheme = call_611589.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611589.url(scheme.get, call_611589.host, call_611589.base,
                         call_611589.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611589, url, valid)

proc call*(call_611590: Call_GetFieldLevelEncryptionProfile20180618_611578;
          Id: string): Recallable =
  ## getFieldLevelEncryptionProfile20180618
  ## Get the field-level encryption profile information.
  ##   Id: string (required)
  ##     : Get the ID for the field-level encryption profile information.
  var path_611591 = newJObject()
  add(path_611591, "Id", newJString(Id))
  result = call_611590.call(path_611591, nil, nil, nil, nil)

var getFieldLevelEncryptionProfile20180618* = Call_GetFieldLevelEncryptionProfile20180618_611578(
    name: "getFieldLevelEncryptionProfile20180618", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/field-level-encryption-profile/{Id}",
    validator: validate_GetFieldLevelEncryptionProfile20180618_611579, base: "/",
    url: url_GetFieldLevelEncryptionProfile20180618_611580,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFieldLevelEncryptionProfile20180618_611592 = ref object of OpenApiRestCall_610658
proc url_DeleteFieldLevelEncryptionProfile20180618_611594(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2018-06-18/field-level-encryption-profile/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteFieldLevelEncryptionProfile20180618_611593(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Remove a field-level encryption profile.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : Request the ID of the profile you want to delete from CloudFront.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_611595 = path.getOrDefault("Id")
  valid_611595 = validateParameter(valid_611595, JString, required = true,
                                 default = nil)
  if valid_611595 != nil:
    section.add "Id", valid_611595
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the profile to delete. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611596 = header.getOrDefault("X-Amz-Signature")
  valid_611596 = validateParameter(valid_611596, JString, required = false,
                                 default = nil)
  if valid_611596 != nil:
    section.add "X-Amz-Signature", valid_611596
  var valid_611597 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611597 = validateParameter(valid_611597, JString, required = false,
                                 default = nil)
  if valid_611597 != nil:
    section.add "X-Amz-Content-Sha256", valid_611597
  var valid_611598 = header.getOrDefault("X-Amz-Date")
  valid_611598 = validateParameter(valid_611598, JString, required = false,
                                 default = nil)
  if valid_611598 != nil:
    section.add "X-Amz-Date", valid_611598
  var valid_611599 = header.getOrDefault("X-Amz-Credential")
  valid_611599 = validateParameter(valid_611599, JString, required = false,
                                 default = nil)
  if valid_611599 != nil:
    section.add "X-Amz-Credential", valid_611599
  var valid_611600 = header.getOrDefault("X-Amz-Security-Token")
  valid_611600 = validateParameter(valid_611600, JString, required = false,
                                 default = nil)
  if valid_611600 != nil:
    section.add "X-Amz-Security-Token", valid_611600
  var valid_611601 = header.getOrDefault("If-Match")
  valid_611601 = validateParameter(valid_611601, JString, required = false,
                                 default = nil)
  if valid_611601 != nil:
    section.add "If-Match", valid_611601
  var valid_611602 = header.getOrDefault("X-Amz-Algorithm")
  valid_611602 = validateParameter(valid_611602, JString, required = false,
                                 default = nil)
  if valid_611602 != nil:
    section.add "X-Amz-Algorithm", valid_611602
  var valid_611603 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611603 = validateParameter(valid_611603, JString, required = false,
                                 default = nil)
  if valid_611603 != nil:
    section.add "X-Amz-SignedHeaders", valid_611603
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611604: Call_DeleteFieldLevelEncryptionProfile20180618_611592;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Remove a field-level encryption profile.
  ## 
  let valid = call_611604.validator(path, query, header, formData, body)
  let scheme = call_611604.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611604.url(scheme.get, call_611604.host, call_611604.base,
                         call_611604.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611604, url, valid)

proc call*(call_611605: Call_DeleteFieldLevelEncryptionProfile20180618_611592;
          Id: string): Recallable =
  ## deleteFieldLevelEncryptionProfile20180618
  ## Remove a field-level encryption profile.
  ##   Id: string (required)
  ##     : Request the ID of the profile you want to delete from CloudFront.
  var path_611606 = newJObject()
  add(path_611606, "Id", newJString(Id))
  result = call_611605.call(path_611606, nil, nil, nil, nil)

var deleteFieldLevelEncryptionProfile20180618* = Call_DeleteFieldLevelEncryptionProfile20180618_611592(
    name: "deleteFieldLevelEncryptionProfile20180618",
    meth: HttpMethod.HttpDelete, host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/field-level-encryption-profile/{Id}",
    validator: validate_DeleteFieldLevelEncryptionProfile20180618_611593,
    base: "/", url: url_DeleteFieldLevelEncryptionProfile20180618_611594,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPublicKey20180618_611607 = ref object of OpenApiRestCall_610658
proc url_GetPublicKey20180618_611609(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-06-18/public-key/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetPublicKey20180618_611608(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get the public key information.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : Request the ID for the public key.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_611610 = path.getOrDefault("Id")
  valid_611610 = validateParameter(valid_611610, JString, required = true,
                                 default = nil)
  if valid_611610 != nil:
    section.add "Id", valid_611610
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611611 = header.getOrDefault("X-Amz-Signature")
  valid_611611 = validateParameter(valid_611611, JString, required = false,
                                 default = nil)
  if valid_611611 != nil:
    section.add "X-Amz-Signature", valid_611611
  var valid_611612 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611612 = validateParameter(valid_611612, JString, required = false,
                                 default = nil)
  if valid_611612 != nil:
    section.add "X-Amz-Content-Sha256", valid_611612
  var valid_611613 = header.getOrDefault("X-Amz-Date")
  valid_611613 = validateParameter(valid_611613, JString, required = false,
                                 default = nil)
  if valid_611613 != nil:
    section.add "X-Amz-Date", valid_611613
  var valid_611614 = header.getOrDefault("X-Amz-Credential")
  valid_611614 = validateParameter(valid_611614, JString, required = false,
                                 default = nil)
  if valid_611614 != nil:
    section.add "X-Amz-Credential", valid_611614
  var valid_611615 = header.getOrDefault("X-Amz-Security-Token")
  valid_611615 = validateParameter(valid_611615, JString, required = false,
                                 default = nil)
  if valid_611615 != nil:
    section.add "X-Amz-Security-Token", valid_611615
  var valid_611616 = header.getOrDefault("X-Amz-Algorithm")
  valid_611616 = validateParameter(valid_611616, JString, required = false,
                                 default = nil)
  if valid_611616 != nil:
    section.add "X-Amz-Algorithm", valid_611616
  var valid_611617 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611617 = validateParameter(valid_611617, JString, required = false,
                                 default = nil)
  if valid_611617 != nil:
    section.add "X-Amz-SignedHeaders", valid_611617
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611618: Call_GetPublicKey20180618_611607; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the public key information.
  ## 
  let valid = call_611618.validator(path, query, header, formData, body)
  let scheme = call_611618.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611618.url(scheme.get, call_611618.host, call_611618.base,
                         call_611618.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611618, url, valid)

proc call*(call_611619: Call_GetPublicKey20180618_611607; Id: string): Recallable =
  ## getPublicKey20180618
  ## Get the public key information.
  ##   Id: string (required)
  ##     : Request the ID for the public key.
  var path_611620 = newJObject()
  add(path_611620, "Id", newJString(Id))
  result = call_611619.call(path_611620, nil, nil, nil, nil)

var getPublicKey20180618* = Call_GetPublicKey20180618_611607(
    name: "getPublicKey20180618", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2018-06-18/public-key/{Id}",
    validator: validate_GetPublicKey20180618_611608, base: "/",
    url: url_GetPublicKey20180618_611609, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePublicKey20180618_611621 = ref object of OpenApiRestCall_610658
proc url_DeletePublicKey20180618_611623(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-06-18/public-key/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeletePublicKey20180618_611622(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Remove a public key you previously added to CloudFront.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the public key you want to remove from CloudFront.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_611624 = path.getOrDefault("Id")
  valid_611624 = validateParameter(valid_611624, JString, required = true,
                                 default = nil)
  if valid_611624 != nil:
    section.add "Id", valid_611624
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the public key identity to delete. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611625 = header.getOrDefault("X-Amz-Signature")
  valid_611625 = validateParameter(valid_611625, JString, required = false,
                                 default = nil)
  if valid_611625 != nil:
    section.add "X-Amz-Signature", valid_611625
  var valid_611626 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611626 = validateParameter(valid_611626, JString, required = false,
                                 default = nil)
  if valid_611626 != nil:
    section.add "X-Amz-Content-Sha256", valid_611626
  var valid_611627 = header.getOrDefault("X-Amz-Date")
  valid_611627 = validateParameter(valid_611627, JString, required = false,
                                 default = nil)
  if valid_611627 != nil:
    section.add "X-Amz-Date", valid_611627
  var valid_611628 = header.getOrDefault("X-Amz-Credential")
  valid_611628 = validateParameter(valid_611628, JString, required = false,
                                 default = nil)
  if valid_611628 != nil:
    section.add "X-Amz-Credential", valid_611628
  var valid_611629 = header.getOrDefault("X-Amz-Security-Token")
  valid_611629 = validateParameter(valid_611629, JString, required = false,
                                 default = nil)
  if valid_611629 != nil:
    section.add "X-Amz-Security-Token", valid_611629
  var valid_611630 = header.getOrDefault("If-Match")
  valid_611630 = validateParameter(valid_611630, JString, required = false,
                                 default = nil)
  if valid_611630 != nil:
    section.add "If-Match", valid_611630
  var valid_611631 = header.getOrDefault("X-Amz-Algorithm")
  valid_611631 = validateParameter(valid_611631, JString, required = false,
                                 default = nil)
  if valid_611631 != nil:
    section.add "X-Amz-Algorithm", valid_611631
  var valid_611632 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611632 = validateParameter(valid_611632, JString, required = false,
                                 default = nil)
  if valid_611632 != nil:
    section.add "X-Amz-SignedHeaders", valid_611632
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611633: Call_DeletePublicKey20180618_611621; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove a public key you previously added to CloudFront.
  ## 
  let valid = call_611633.validator(path, query, header, formData, body)
  let scheme = call_611633.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611633.url(scheme.get, call_611633.host, call_611633.base,
                         call_611633.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611633, url, valid)

proc call*(call_611634: Call_DeletePublicKey20180618_611621; Id: string): Recallable =
  ## deletePublicKey20180618
  ## Remove a public key you previously added to CloudFront.
  ##   Id: string (required)
  ##     : The ID of the public key you want to remove from CloudFront.
  var path_611635 = newJObject()
  add(path_611635, "Id", newJString(Id))
  result = call_611634.call(path_611635, nil, nil, nil, nil)

var deletePublicKey20180618* = Call_DeletePublicKey20180618_611621(
    name: "deletePublicKey20180618", meth: HttpMethod.HttpDelete,
    host: "cloudfront.amazonaws.com", route: "/2018-06-18/public-key/{Id}",
    validator: validate_DeletePublicKey20180618_611622, base: "/",
    url: url_DeletePublicKey20180618_611623, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStreamingDistribution20180618_611636 = ref object of OpenApiRestCall_610658
proc url_GetStreamingDistribution20180618_611638(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2018-06-18/streaming-distribution/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetStreamingDistribution20180618_611637(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about a specified RTMP distribution, including the distribution configuration.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The streaming distribution's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_611639 = path.getOrDefault("Id")
  valid_611639 = validateParameter(valid_611639, JString, required = true,
                                 default = nil)
  if valid_611639 != nil:
    section.add "Id", valid_611639
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611640 = header.getOrDefault("X-Amz-Signature")
  valid_611640 = validateParameter(valid_611640, JString, required = false,
                                 default = nil)
  if valid_611640 != nil:
    section.add "X-Amz-Signature", valid_611640
  var valid_611641 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611641 = validateParameter(valid_611641, JString, required = false,
                                 default = nil)
  if valid_611641 != nil:
    section.add "X-Amz-Content-Sha256", valid_611641
  var valid_611642 = header.getOrDefault("X-Amz-Date")
  valid_611642 = validateParameter(valid_611642, JString, required = false,
                                 default = nil)
  if valid_611642 != nil:
    section.add "X-Amz-Date", valid_611642
  var valid_611643 = header.getOrDefault("X-Amz-Credential")
  valid_611643 = validateParameter(valid_611643, JString, required = false,
                                 default = nil)
  if valid_611643 != nil:
    section.add "X-Amz-Credential", valid_611643
  var valid_611644 = header.getOrDefault("X-Amz-Security-Token")
  valid_611644 = validateParameter(valid_611644, JString, required = false,
                                 default = nil)
  if valid_611644 != nil:
    section.add "X-Amz-Security-Token", valid_611644
  var valid_611645 = header.getOrDefault("X-Amz-Algorithm")
  valid_611645 = validateParameter(valid_611645, JString, required = false,
                                 default = nil)
  if valid_611645 != nil:
    section.add "X-Amz-Algorithm", valid_611645
  var valid_611646 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611646 = validateParameter(valid_611646, JString, required = false,
                                 default = nil)
  if valid_611646 != nil:
    section.add "X-Amz-SignedHeaders", valid_611646
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611647: Call_GetStreamingDistribution20180618_611636;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets information about a specified RTMP distribution, including the distribution configuration.
  ## 
  let valid = call_611647.validator(path, query, header, formData, body)
  let scheme = call_611647.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611647.url(scheme.get, call_611647.host, call_611647.base,
                         call_611647.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611647, url, valid)

proc call*(call_611648: Call_GetStreamingDistribution20180618_611636; Id: string): Recallable =
  ## getStreamingDistribution20180618
  ## Gets information about a specified RTMP distribution, including the distribution configuration.
  ##   Id: string (required)
  ##     : The streaming distribution's ID.
  var path_611649 = newJObject()
  add(path_611649, "Id", newJString(Id))
  result = call_611648.call(path_611649, nil, nil, nil, nil)

var getStreamingDistribution20180618* = Call_GetStreamingDistribution20180618_611636(
    name: "getStreamingDistribution20180618", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/streaming-distribution/{Id}",
    validator: validate_GetStreamingDistribution20180618_611637, base: "/",
    url: url_GetStreamingDistribution20180618_611638,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteStreamingDistribution20180618_611650 = ref object of OpenApiRestCall_610658
proc url_DeleteStreamingDistribution20180618_611652(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2018-06-18/streaming-distribution/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteStreamingDistribution20180618_611651(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Delete a streaming distribution. To delete an RTMP distribution using the CloudFront API, perform the following steps.</p> <p> <b>To delete an RTMP distribution using the CloudFront API</b>:</p> <ol> <li> <p>Disable the RTMP distribution.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to get the current configuration and the <code>Etag</code> header for the distribution. </p> </li> <li> <p>Update the XML document that was returned in the response to your <code>GET Streaming Distribution Config</code> request to change the value of <code>Enabled</code> to <code>false</code>.</p> </li> <li> <p>Submit a <code>PUT Streaming Distribution Config</code> request to update the configuration for your distribution. In the request body, include the XML document that you updated in Step 3. Then set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to the <code>PUT Streaming Distribution Config</code> request to confirm that the distribution was successfully disabled.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> <li> <p>Submit a <code>DELETE Streaming Distribution</code> request. Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to your <code>DELETE Streaming Distribution</code> request to confirm that the distribution was successfully deleted.</p> </li> </ol> <p>For information about deleting a distribution using the CloudFront console, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/HowToDeleteDistribution.html">Deleting a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The distribution ID. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_611653 = path.getOrDefault("Id")
  valid_611653 = validateParameter(valid_611653, JString, required = true,
                                 default = nil)
  if valid_611653 != nil:
    section.add "Id", valid_611653
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when you disabled the streaming distribution. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611654 = header.getOrDefault("X-Amz-Signature")
  valid_611654 = validateParameter(valid_611654, JString, required = false,
                                 default = nil)
  if valid_611654 != nil:
    section.add "X-Amz-Signature", valid_611654
  var valid_611655 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611655 = validateParameter(valid_611655, JString, required = false,
                                 default = nil)
  if valid_611655 != nil:
    section.add "X-Amz-Content-Sha256", valid_611655
  var valid_611656 = header.getOrDefault("X-Amz-Date")
  valid_611656 = validateParameter(valid_611656, JString, required = false,
                                 default = nil)
  if valid_611656 != nil:
    section.add "X-Amz-Date", valid_611656
  var valid_611657 = header.getOrDefault("X-Amz-Credential")
  valid_611657 = validateParameter(valid_611657, JString, required = false,
                                 default = nil)
  if valid_611657 != nil:
    section.add "X-Amz-Credential", valid_611657
  var valid_611658 = header.getOrDefault("X-Amz-Security-Token")
  valid_611658 = validateParameter(valid_611658, JString, required = false,
                                 default = nil)
  if valid_611658 != nil:
    section.add "X-Amz-Security-Token", valid_611658
  var valid_611659 = header.getOrDefault("If-Match")
  valid_611659 = validateParameter(valid_611659, JString, required = false,
                                 default = nil)
  if valid_611659 != nil:
    section.add "If-Match", valid_611659
  var valid_611660 = header.getOrDefault("X-Amz-Algorithm")
  valid_611660 = validateParameter(valid_611660, JString, required = false,
                                 default = nil)
  if valid_611660 != nil:
    section.add "X-Amz-Algorithm", valid_611660
  var valid_611661 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611661 = validateParameter(valid_611661, JString, required = false,
                                 default = nil)
  if valid_611661 != nil:
    section.add "X-Amz-SignedHeaders", valid_611661
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611662: Call_DeleteStreamingDistribution20180618_611650;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Delete a streaming distribution. To delete an RTMP distribution using the CloudFront API, perform the following steps.</p> <p> <b>To delete an RTMP distribution using the CloudFront API</b>:</p> <ol> <li> <p>Disable the RTMP distribution.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to get the current configuration and the <code>Etag</code> header for the distribution. </p> </li> <li> <p>Update the XML document that was returned in the response to your <code>GET Streaming Distribution Config</code> request to change the value of <code>Enabled</code> to <code>false</code>.</p> </li> <li> <p>Submit a <code>PUT Streaming Distribution Config</code> request to update the configuration for your distribution. In the request body, include the XML document that you updated in Step 3. Then set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to the <code>PUT Streaming Distribution Config</code> request to confirm that the distribution was successfully disabled.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> <li> <p>Submit a <code>DELETE Streaming Distribution</code> request. Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to your <code>DELETE Streaming Distribution</code> request to confirm that the distribution was successfully deleted.</p> </li> </ol> <p>For information about deleting a distribution using the CloudFront console, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/HowToDeleteDistribution.html">Deleting a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p>
  ## 
  let valid = call_611662.validator(path, query, header, formData, body)
  let scheme = call_611662.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611662.url(scheme.get, call_611662.host, call_611662.base,
                         call_611662.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611662, url, valid)

proc call*(call_611663: Call_DeleteStreamingDistribution20180618_611650; Id: string): Recallable =
  ## deleteStreamingDistribution20180618
  ## <p>Delete a streaming distribution. To delete an RTMP distribution using the CloudFront API, perform the following steps.</p> <p> <b>To delete an RTMP distribution using the CloudFront API</b>:</p> <ol> <li> <p>Disable the RTMP distribution.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to get the current configuration and the <code>Etag</code> header for the distribution. </p> </li> <li> <p>Update the XML document that was returned in the response to your <code>GET Streaming Distribution Config</code> request to change the value of <code>Enabled</code> to <code>false</code>.</p> </li> <li> <p>Submit a <code>PUT Streaming Distribution Config</code> request to update the configuration for your distribution. In the request body, include the XML document that you updated in Step 3. Then set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to the <code>PUT Streaming Distribution Config</code> request to confirm that the distribution was successfully disabled.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> <li> <p>Submit a <code>DELETE Streaming Distribution</code> request. Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to your <code>DELETE Streaming Distribution</code> request to confirm that the distribution was successfully deleted.</p> </li> </ol> <p>For information about deleting a distribution using the CloudFront console, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/HowToDeleteDistribution.html">Deleting a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p>
  ##   Id: string (required)
  ##     : The distribution ID. 
  var path_611664 = newJObject()
  add(path_611664, "Id", newJString(Id))
  result = call_611663.call(path_611664, nil, nil, nil, nil)

var deleteStreamingDistribution20180618* = Call_DeleteStreamingDistribution20180618_611650(
    name: "deleteStreamingDistribution20180618", meth: HttpMethod.HttpDelete,
    host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/streaming-distribution/{Id}",
    validator: validate_DeleteStreamingDistribution20180618_611651, base: "/",
    url: url_DeleteStreamingDistribution20180618_611652,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCloudFrontOriginAccessIdentity20180618_611679 = ref object of OpenApiRestCall_610658
proc url_UpdateCloudFrontOriginAccessIdentity20180618_611681(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2018-06-18/origin-access-identity/cloudfront/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateCloudFrontOriginAccessIdentity20180618_611680(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Update an origin access identity. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The identity's id.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_611682 = path.getOrDefault("Id")
  valid_611682 = validateParameter(valid_611682, JString, required = true,
                                 default = nil)
  if valid_611682 != nil:
    section.add "Id", valid_611682
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the identity's configuration. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611683 = header.getOrDefault("X-Amz-Signature")
  valid_611683 = validateParameter(valid_611683, JString, required = false,
                                 default = nil)
  if valid_611683 != nil:
    section.add "X-Amz-Signature", valid_611683
  var valid_611684 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611684 = validateParameter(valid_611684, JString, required = false,
                                 default = nil)
  if valid_611684 != nil:
    section.add "X-Amz-Content-Sha256", valid_611684
  var valid_611685 = header.getOrDefault("X-Amz-Date")
  valid_611685 = validateParameter(valid_611685, JString, required = false,
                                 default = nil)
  if valid_611685 != nil:
    section.add "X-Amz-Date", valid_611685
  var valid_611686 = header.getOrDefault("X-Amz-Credential")
  valid_611686 = validateParameter(valid_611686, JString, required = false,
                                 default = nil)
  if valid_611686 != nil:
    section.add "X-Amz-Credential", valid_611686
  var valid_611687 = header.getOrDefault("X-Amz-Security-Token")
  valid_611687 = validateParameter(valid_611687, JString, required = false,
                                 default = nil)
  if valid_611687 != nil:
    section.add "X-Amz-Security-Token", valid_611687
  var valid_611688 = header.getOrDefault("If-Match")
  valid_611688 = validateParameter(valid_611688, JString, required = false,
                                 default = nil)
  if valid_611688 != nil:
    section.add "If-Match", valid_611688
  var valid_611689 = header.getOrDefault("X-Amz-Algorithm")
  valid_611689 = validateParameter(valid_611689, JString, required = false,
                                 default = nil)
  if valid_611689 != nil:
    section.add "X-Amz-Algorithm", valid_611689
  var valid_611690 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611690 = validateParameter(valid_611690, JString, required = false,
                                 default = nil)
  if valid_611690 != nil:
    section.add "X-Amz-SignedHeaders", valid_611690
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611692: Call_UpdateCloudFrontOriginAccessIdentity20180618_611679;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Update an origin access identity. 
  ## 
  let valid = call_611692.validator(path, query, header, formData, body)
  let scheme = call_611692.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611692.url(scheme.get, call_611692.host, call_611692.base,
                         call_611692.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611692, url, valid)

proc call*(call_611693: Call_UpdateCloudFrontOriginAccessIdentity20180618_611679;
          body: JsonNode; Id: string): Recallable =
  ## updateCloudFrontOriginAccessIdentity20180618
  ## Update an origin access identity. 
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : The identity's id.
  var path_611694 = newJObject()
  var body_611695 = newJObject()
  if body != nil:
    body_611695 = body
  add(path_611694, "Id", newJString(Id))
  result = call_611693.call(path_611694, nil, nil, nil, body_611695)

var updateCloudFrontOriginAccessIdentity20180618* = Call_UpdateCloudFrontOriginAccessIdentity20180618_611679(
    name: "updateCloudFrontOriginAccessIdentity20180618",
    meth: HttpMethod.HttpPut, host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/origin-access-identity/cloudfront/{Id}/config",
    validator: validate_UpdateCloudFrontOriginAccessIdentity20180618_611680,
    base: "/", url: url_UpdateCloudFrontOriginAccessIdentity20180618_611681,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCloudFrontOriginAccessIdentityConfig20180618_611665 = ref object of OpenApiRestCall_610658
proc url_GetCloudFrontOriginAccessIdentityConfig20180618_611667(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2018-06-18/origin-access-identity/cloudfront/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetCloudFrontOriginAccessIdentityConfig20180618_611666(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode): JsonNode =
  ## Get the configuration information about an origin access identity. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The identity's ID. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_611668 = path.getOrDefault("Id")
  valid_611668 = validateParameter(valid_611668, JString, required = true,
                                 default = nil)
  if valid_611668 != nil:
    section.add "Id", valid_611668
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611669 = header.getOrDefault("X-Amz-Signature")
  valid_611669 = validateParameter(valid_611669, JString, required = false,
                                 default = nil)
  if valid_611669 != nil:
    section.add "X-Amz-Signature", valid_611669
  var valid_611670 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611670 = validateParameter(valid_611670, JString, required = false,
                                 default = nil)
  if valid_611670 != nil:
    section.add "X-Amz-Content-Sha256", valid_611670
  var valid_611671 = header.getOrDefault("X-Amz-Date")
  valid_611671 = validateParameter(valid_611671, JString, required = false,
                                 default = nil)
  if valid_611671 != nil:
    section.add "X-Amz-Date", valid_611671
  var valid_611672 = header.getOrDefault("X-Amz-Credential")
  valid_611672 = validateParameter(valid_611672, JString, required = false,
                                 default = nil)
  if valid_611672 != nil:
    section.add "X-Amz-Credential", valid_611672
  var valid_611673 = header.getOrDefault("X-Amz-Security-Token")
  valid_611673 = validateParameter(valid_611673, JString, required = false,
                                 default = nil)
  if valid_611673 != nil:
    section.add "X-Amz-Security-Token", valid_611673
  var valid_611674 = header.getOrDefault("X-Amz-Algorithm")
  valid_611674 = validateParameter(valid_611674, JString, required = false,
                                 default = nil)
  if valid_611674 != nil:
    section.add "X-Amz-Algorithm", valid_611674
  var valid_611675 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611675 = validateParameter(valid_611675, JString, required = false,
                                 default = nil)
  if valid_611675 != nil:
    section.add "X-Amz-SignedHeaders", valid_611675
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611676: Call_GetCloudFrontOriginAccessIdentityConfig20180618_611665;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Get the configuration information about an origin access identity. 
  ## 
  let valid = call_611676.validator(path, query, header, formData, body)
  let scheme = call_611676.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611676.url(scheme.get, call_611676.host, call_611676.base,
                         call_611676.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611676, url, valid)

proc call*(call_611677: Call_GetCloudFrontOriginAccessIdentityConfig20180618_611665;
          Id: string): Recallable =
  ## getCloudFrontOriginAccessIdentityConfig20180618
  ## Get the configuration information about an origin access identity. 
  ##   Id: string (required)
  ##     : The identity's ID. 
  var path_611678 = newJObject()
  add(path_611678, "Id", newJString(Id))
  result = call_611677.call(path_611678, nil, nil, nil, nil)

var getCloudFrontOriginAccessIdentityConfig20180618* = Call_GetCloudFrontOriginAccessIdentityConfig20180618_611665(
    name: "getCloudFrontOriginAccessIdentityConfig20180618",
    meth: HttpMethod.HttpGet, host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/origin-access-identity/cloudfront/{Id}/config",
    validator: validate_GetCloudFrontOriginAccessIdentityConfig20180618_611666,
    base: "/", url: url_GetCloudFrontOriginAccessIdentityConfig20180618_611667,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDistribution20180618_611710 = ref object of OpenApiRestCall_610658
proc url_UpdateDistribution20180618_611712(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-06-18/distribution/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDistribution20180618_611711(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates the configuration for a web distribution. </p> <important> <p>When you update a distribution, there are more required fields than when you create a distribution. When you update your distribution by using this API action, follow the steps here to get the current configuration and then make your updates, to make sure that you include all of the required fields. To view a summary, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-overview-required-fields.html">Required Fields for Create Distribution and Update Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> </important> <p>The update process includes getting the current distribution configuration, updating the XML document that is returned to make your changes, and then submitting an <code>UpdateDistribution</code> request to make the updates.</p> <p>For information about updating a distribution using the CloudFront console instead, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-web-creating-console.html">Creating a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <p> <b>To update a web distribution using the CloudFront API</b> </p> <ol> <li> <p>Submit a <a>GetDistributionConfig</a> request to get the current configuration and an <code>Etag</code> header for the distribution.</p> <note> <p>If you update the distribution again, you must get a new <code>Etag</code> header.</p> </note> </li> <li> <p>Update the XML document that was returned in the response to your <code>GetDistributionConfig</code> request to include your changes. </p> <important> <p>When you edit the XML file, be aware of the following:</p> <ul> <li> <p>You must strip out the ETag parameter that is returned.</p> </li> <li> <p>Additional fields are required when you update a distribution. There may be fields included in the XML file for features that you haven't configured for your distribution. This is expected and required to successfully update the distribution.</p> </li> <li> <p>You can't change the value of <code>CallerReference</code>. If you try to change this value, CloudFront returns an <code>IllegalUpdate</code> error. </p> </li> <li> <p>The new configuration replaces the existing configuration; the values that you specify in an <code>UpdateDistribution</code> request are not merged into your existing configuration. When you add, delete, or replace values in an element that allows multiple values (for example, <code>CNAME</code>), you must specify all of the values that you want to appear in the updated distribution. In addition, you must update the corresponding <code>Quantity</code> element.</p> </li> </ul> </important> </li> <li> <p>Submit an <code>UpdateDistribution</code> request to update the configuration for your distribution:</p> <ul> <li> <p>In the request body, include the XML document that you updated in Step 2. The request body must include an XML document with a <code>DistributionConfig</code> element.</p> </li> <li> <p>Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GetDistributionConfig</code> request in Step 1.</p> </li> </ul> </li> <li> <p>Review the response to the <code>UpdateDistribution</code> request to confirm that the configuration was successfully updated.</p> </li> <li> <p>Optional: Submit a <a>GetDistribution</a> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> </ol>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The distribution's id.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_611713 = path.getOrDefault("Id")
  valid_611713 = validateParameter(valid_611713, JString, required = true,
                                 default = nil)
  if valid_611713 != nil:
    section.add "Id", valid_611713
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the distribution's configuration. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611714 = header.getOrDefault("X-Amz-Signature")
  valid_611714 = validateParameter(valid_611714, JString, required = false,
                                 default = nil)
  if valid_611714 != nil:
    section.add "X-Amz-Signature", valid_611714
  var valid_611715 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611715 = validateParameter(valid_611715, JString, required = false,
                                 default = nil)
  if valid_611715 != nil:
    section.add "X-Amz-Content-Sha256", valid_611715
  var valid_611716 = header.getOrDefault("X-Amz-Date")
  valid_611716 = validateParameter(valid_611716, JString, required = false,
                                 default = nil)
  if valid_611716 != nil:
    section.add "X-Amz-Date", valid_611716
  var valid_611717 = header.getOrDefault("X-Amz-Credential")
  valid_611717 = validateParameter(valid_611717, JString, required = false,
                                 default = nil)
  if valid_611717 != nil:
    section.add "X-Amz-Credential", valid_611717
  var valid_611718 = header.getOrDefault("X-Amz-Security-Token")
  valid_611718 = validateParameter(valid_611718, JString, required = false,
                                 default = nil)
  if valid_611718 != nil:
    section.add "X-Amz-Security-Token", valid_611718
  var valid_611719 = header.getOrDefault("If-Match")
  valid_611719 = validateParameter(valid_611719, JString, required = false,
                                 default = nil)
  if valid_611719 != nil:
    section.add "If-Match", valid_611719
  var valid_611720 = header.getOrDefault("X-Amz-Algorithm")
  valid_611720 = validateParameter(valid_611720, JString, required = false,
                                 default = nil)
  if valid_611720 != nil:
    section.add "X-Amz-Algorithm", valid_611720
  var valid_611721 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611721 = validateParameter(valid_611721, JString, required = false,
                                 default = nil)
  if valid_611721 != nil:
    section.add "X-Amz-SignedHeaders", valid_611721
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611723: Call_UpdateDistribution20180618_611710; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the configuration for a web distribution. </p> <important> <p>When you update a distribution, there are more required fields than when you create a distribution. When you update your distribution by using this API action, follow the steps here to get the current configuration and then make your updates, to make sure that you include all of the required fields. To view a summary, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-overview-required-fields.html">Required Fields for Create Distribution and Update Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> </important> <p>The update process includes getting the current distribution configuration, updating the XML document that is returned to make your changes, and then submitting an <code>UpdateDistribution</code> request to make the updates.</p> <p>For information about updating a distribution using the CloudFront console instead, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-web-creating-console.html">Creating a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <p> <b>To update a web distribution using the CloudFront API</b> </p> <ol> <li> <p>Submit a <a>GetDistributionConfig</a> request to get the current configuration and an <code>Etag</code> header for the distribution.</p> <note> <p>If you update the distribution again, you must get a new <code>Etag</code> header.</p> </note> </li> <li> <p>Update the XML document that was returned in the response to your <code>GetDistributionConfig</code> request to include your changes. </p> <important> <p>When you edit the XML file, be aware of the following:</p> <ul> <li> <p>You must strip out the ETag parameter that is returned.</p> </li> <li> <p>Additional fields are required when you update a distribution. There may be fields included in the XML file for features that you haven't configured for your distribution. This is expected and required to successfully update the distribution.</p> </li> <li> <p>You can't change the value of <code>CallerReference</code>. If you try to change this value, CloudFront returns an <code>IllegalUpdate</code> error. </p> </li> <li> <p>The new configuration replaces the existing configuration; the values that you specify in an <code>UpdateDistribution</code> request are not merged into your existing configuration. When you add, delete, or replace values in an element that allows multiple values (for example, <code>CNAME</code>), you must specify all of the values that you want to appear in the updated distribution. In addition, you must update the corresponding <code>Quantity</code> element.</p> </li> </ul> </important> </li> <li> <p>Submit an <code>UpdateDistribution</code> request to update the configuration for your distribution:</p> <ul> <li> <p>In the request body, include the XML document that you updated in Step 2. The request body must include an XML document with a <code>DistributionConfig</code> element.</p> </li> <li> <p>Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GetDistributionConfig</code> request in Step 1.</p> </li> </ul> </li> <li> <p>Review the response to the <code>UpdateDistribution</code> request to confirm that the configuration was successfully updated.</p> </li> <li> <p>Optional: Submit a <a>GetDistribution</a> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> </ol>
  ## 
  let valid = call_611723.validator(path, query, header, formData, body)
  let scheme = call_611723.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611723.url(scheme.get, call_611723.host, call_611723.base,
                         call_611723.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611723, url, valid)

proc call*(call_611724: Call_UpdateDistribution20180618_611710; body: JsonNode;
          Id: string): Recallable =
  ## updateDistribution20180618
  ## <p>Updates the configuration for a web distribution. </p> <important> <p>When you update a distribution, there are more required fields than when you create a distribution. When you update your distribution by using this API action, follow the steps here to get the current configuration and then make your updates, to make sure that you include all of the required fields. To view a summary, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-overview-required-fields.html">Required Fields for Create Distribution and Update Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> </important> <p>The update process includes getting the current distribution configuration, updating the XML document that is returned to make your changes, and then submitting an <code>UpdateDistribution</code> request to make the updates.</p> <p>For information about updating a distribution using the CloudFront console instead, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-web-creating-console.html">Creating a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <p> <b>To update a web distribution using the CloudFront API</b> </p> <ol> <li> <p>Submit a <a>GetDistributionConfig</a> request to get the current configuration and an <code>Etag</code> header for the distribution.</p> <note> <p>If you update the distribution again, you must get a new <code>Etag</code> header.</p> </note> </li> <li> <p>Update the XML document that was returned in the response to your <code>GetDistributionConfig</code> request to include your changes. </p> <important> <p>When you edit the XML file, be aware of the following:</p> <ul> <li> <p>You must strip out the ETag parameter that is returned.</p> </li> <li> <p>Additional fields are required when you update a distribution. There may be fields included in the XML file for features that you haven't configured for your distribution. This is expected and required to successfully update the distribution.</p> </li> <li> <p>You can't change the value of <code>CallerReference</code>. If you try to change this value, CloudFront returns an <code>IllegalUpdate</code> error. </p> </li> <li> <p>The new configuration replaces the existing configuration; the values that you specify in an <code>UpdateDistribution</code> request are not merged into your existing configuration. When you add, delete, or replace values in an element that allows multiple values (for example, <code>CNAME</code>), you must specify all of the values that you want to appear in the updated distribution. In addition, you must update the corresponding <code>Quantity</code> element.</p> </li> </ul> </important> </li> <li> <p>Submit an <code>UpdateDistribution</code> request to update the configuration for your distribution:</p> <ul> <li> <p>In the request body, include the XML document that you updated in Step 2. The request body must include an XML document with a <code>DistributionConfig</code> element.</p> </li> <li> <p>Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GetDistributionConfig</code> request in Step 1.</p> </li> </ul> </li> <li> <p>Review the response to the <code>UpdateDistribution</code> request to confirm that the configuration was successfully updated.</p> </li> <li> <p>Optional: Submit a <a>GetDistribution</a> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> </ol>
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : The distribution's id.
  var path_611725 = newJObject()
  var body_611726 = newJObject()
  if body != nil:
    body_611726 = body
  add(path_611725, "Id", newJString(Id))
  result = call_611724.call(path_611725, nil, nil, nil, body_611726)

var updateDistribution20180618* = Call_UpdateDistribution20180618_611710(
    name: "updateDistribution20180618", meth: HttpMethod.HttpPut,
    host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/distribution/{Id}/config",
    validator: validate_UpdateDistribution20180618_611711, base: "/",
    url: url_UpdateDistribution20180618_611712,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDistributionConfig20180618_611696 = ref object of OpenApiRestCall_610658
proc url_GetDistributionConfig20180618_611698(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-06-18/distribution/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDistributionConfig20180618_611697(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get the configuration information about a distribution. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The distribution's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_611699 = path.getOrDefault("Id")
  valid_611699 = validateParameter(valid_611699, JString, required = true,
                                 default = nil)
  if valid_611699 != nil:
    section.add "Id", valid_611699
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611700 = header.getOrDefault("X-Amz-Signature")
  valid_611700 = validateParameter(valid_611700, JString, required = false,
                                 default = nil)
  if valid_611700 != nil:
    section.add "X-Amz-Signature", valid_611700
  var valid_611701 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611701 = validateParameter(valid_611701, JString, required = false,
                                 default = nil)
  if valid_611701 != nil:
    section.add "X-Amz-Content-Sha256", valid_611701
  var valid_611702 = header.getOrDefault("X-Amz-Date")
  valid_611702 = validateParameter(valid_611702, JString, required = false,
                                 default = nil)
  if valid_611702 != nil:
    section.add "X-Amz-Date", valid_611702
  var valid_611703 = header.getOrDefault("X-Amz-Credential")
  valid_611703 = validateParameter(valid_611703, JString, required = false,
                                 default = nil)
  if valid_611703 != nil:
    section.add "X-Amz-Credential", valid_611703
  var valid_611704 = header.getOrDefault("X-Amz-Security-Token")
  valid_611704 = validateParameter(valid_611704, JString, required = false,
                                 default = nil)
  if valid_611704 != nil:
    section.add "X-Amz-Security-Token", valid_611704
  var valid_611705 = header.getOrDefault("X-Amz-Algorithm")
  valid_611705 = validateParameter(valid_611705, JString, required = false,
                                 default = nil)
  if valid_611705 != nil:
    section.add "X-Amz-Algorithm", valid_611705
  var valid_611706 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611706 = validateParameter(valid_611706, JString, required = false,
                                 default = nil)
  if valid_611706 != nil:
    section.add "X-Amz-SignedHeaders", valid_611706
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611707: Call_GetDistributionConfig20180618_611696; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the configuration information about a distribution. 
  ## 
  let valid = call_611707.validator(path, query, header, formData, body)
  let scheme = call_611707.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611707.url(scheme.get, call_611707.host, call_611707.base,
                         call_611707.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611707, url, valid)

proc call*(call_611708: Call_GetDistributionConfig20180618_611696; Id: string): Recallable =
  ## getDistributionConfig20180618
  ## Get the configuration information about a distribution. 
  ##   Id: string (required)
  ##     : The distribution's ID.
  var path_611709 = newJObject()
  add(path_611709, "Id", newJString(Id))
  result = call_611708.call(path_611709, nil, nil, nil, nil)

var getDistributionConfig20180618* = Call_GetDistributionConfig20180618_611696(
    name: "getDistributionConfig20180618", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/distribution/{Id}/config",
    validator: validate_GetDistributionConfig20180618_611697, base: "/",
    url: url_GetDistributionConfig20180618_611698,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFieldLevelEncryptionConfig20180618_611741 = ref object of OpenApiRestCall_610658
proc url_UpdateFieldLevelEncryptionConfig20180618_611743(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2018-06-18/field-level-encryption/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateFieldLevelEncryptionConfig20180618_611742(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Update a field-level encryption configuration. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the configuration you want to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_611744 = path.getOrDefault("Id")
  valid_611744 = validateParameter(valid_611744, JString, required = true,
                                 default = nil)
  if valid_611744 != nil:
    section.add "Id", valid_611744
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the configuration identity to update. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611745 = header.getOrDefault("X-Amz-Signature")
  valid_611745 = validateParameter(valid_611745, JString, required = false,
                                 default = nil)
  if valid_611745 != nil:
    section.add "X-Amz-Signature", valid_611745
  var valid_611746 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611746 = validateParameter(valid_611746, JString, required = false,
                                 default = nil)
  if valid_611746 != nil:
    section.add "X-Amz-Content-Sha256", valid_611746
  var valid_611747 = header.getOrDefault("X-Amz-Date")
  valid_611747 = validateParameter(valid_611747, JString, required = false,
                                 default = nil)
  if valid_611747 != nil:
    section.add "X-Amz-Date", valid_611747
  var valid_611748 = header.getOrDefault("X-Amz-Credential")
  valid_611748 = validateParameter(valid_611748, JString, required = false,
                                 default = nil)
  if valid_611748 != nil:
    section.add "X-Amz-Credential", valid_611748
  var valid_611749 = header.getOrDefault("X-Amz-Security-Token")
  valid_611749 = validateParameter(valid_611749, JString, required = false,
                                 default = nil)
  if valid_611749 != nil:
    section.add "X-Amz-Security-Token", valid_611749
  var valid_611750 = header.getOrDefault("If-Match")
  valid_611750 = validateParameter(valid_611750, JString, required = false,
                                 default = nil)
  if valid_611750 != nil:
    section.add "If-Match", valid_611750
  var valid_611751 = header.getOrDefault("X-Amz-Algorithm")
  valid_611751 = validateParameter(valid_611751, JString, required = false,
                                 default = nil)
  if valid_611751 != nil:
    section.add "X-Amz-Algorithm", valid_611751
  var valid_611752 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611752 = validateParameter(valid_611752, JString, required = false,
                                 default = nil)
  if valid_611752 != nil:
    section.add "X-Amz-SignedHeaders", valid_611752
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611754: Call_UpdateFieldLevelEncryptionConfig20180618_611741;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Update a field-level encryption configuration. 
  ## 
  let valid = call_611754.validator(path, query, header, formData, body)
  let scheme = call_611754.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611754.url(scheme.get, call_611754.host, call_611754.base,
                         call_611754.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611754, url, valid)

proc call*(call_611755: Call_UpdateFieldLevelEncryptionConfig20180618_611741;
          body: JsonNode; Id: string): Recallable =
  ## updateFieldLevelEncryptionConfig20180618
  ## Update a field-level encryption configuration. 
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : The ID of the configuration you want to update.
  var path_611756 = newJObject()
  var body_611757 = newJObject()
  if body != nil:
    body_611757 = body
  add(path_611756, "Id", newJString(Id))
  result = call_611755.call(path_611756, nil, nil, nil, body_611757)

var updateFieldLevelEncryptionConfig20180618* = Call_UpdateFieldLevelEncryptionConfig20180618_611741(
    name: "updateFieldLevelEncryptionConfig20180618", meth: HttpMethod.HttpPut,
    host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/field-level-encryption/{Id}/config",
    validator: validate_UpdateFieldLevelEncryptionConfig20180618_611742,
    base: "/", url: url_UpdateFieldLevelEncryptionConfig20180618_611743,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFieldLevelEncryptionConfig20180618_611727 = ref object of OpenApiRestCall_610658
proc url_GetFieldLevelEncryptionConfig20180618_611729(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2018-06-18/field-level-encryption/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFieldLevelEncryptionConfig20180618_611728(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get the field-level encryption configuration information.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : Request the ID for the field-level encryption configuration information.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_611730 = path.getOrDefault("Id")
  valid_611730 = validateParameter(valid_611730, JString, required = true,
                                 default = nil)
  if valid_611730 != nil:
    section.add "Id", valid_611730
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611731 = header.getOrDefault("X-Amz-Signature")
  valid_611731 = validateParameter(valid_611731, JString, required = false,
                                 default = nil)
  if valid_611731 != nil:
    section.add "X-Amz-Signature", valid_611731
  var valid_611732 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611732 = validateParameter(valid_611732, JString, required = false,
                                 default = nil)
  if valid_611732 != nil:
    section.add "X-Amz-Content-Sha256", valid_611732
  var valid_611733 = header.getOrDefault("X-Amz-Date")
  valid_611733 = validateParameter(valid_611733, JString, required = false,
                                 default = nil)
  if valid_611733 != nil:
    section.add "X-Amz-Date", valid_611733
  var valid_611734 = header.getOrDefault("X-Amz-Credential")
  valid_611734 = validateParameter(valid_611734, JString, required = false,
                                 default = nil)
  if valid_611734 != nil:
    section.add "X-Amz-Credential", valid_611734
  var valid_611735 = header.getOrDefault("X-Amz-Security-Token")
  valid_611735 = validateParameter(valid_611735, JString, required = false,
                                 default = nil)
  if valid_611735 != nil:
    section.add "X-Amz-Security-Token", valid_611735
  var valid_611736 = header.getOrDefault("X-Amz-Algorithm")
  valid_611736 = validateParameter(valid_611736, JString, required = false,
                                 default = nil)
  if valid_611736 != nil:
    section.add "X-Amz-Algorithm", valid_611736
  var valid_611737 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611737 = validateParameter(valid_611737, JString, required = false,
                                 default = nil)
  if valid_611737 != nil:
    section.add "X-Amz-SignedHeaders", valid_611737
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611738: Call_GetFieldLevelEncryptionConfig20180618_611727;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Get the field-level encryption configuration information.
  ## 
  let valid = call_611738.validator(path, query, header, formData, body)
  let scheme = call_611738.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611738.url(scheme.get, call_611738.host, call_611738.base,
                         call_611738.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611738, url, valid)

proc call*(call_611739: Call_GetFieldLevelEncryptionConfig20180618_611727;
          Id: string): Recallable =
  ## getFieldLevelEncryptionConfig20180618
  ## Get the field-level encryption configuration information.
  ##   Id: string (required)
  ##     : Request the ID for the field-level encryption configuration information.
  var path_611740 = newJObject()
  add(path_611740, "Id", newJString(Id))
  result = call_611739.call(path_611740, nil, nil, nil, nil)

var getFieldLevelEncryptionConfig20180618* = Call_GetFieldLevelEncryptionConfig20180618_611727(
    name: "getFieldLevelEncryptionConfig20180618", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/field-level-encryption/{Id}/config",
    validator: validate_GetFieldLevelEncryptionConfig20180618_611728, base: "/",
    url: url_GetFieldLevelEncryptionConfig20180618_611729,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFieldLevelEncryptionProfile20180618_611772 = ref object of OpenApiRestCall_610658
proc url_UpdateFieldLevelEncryptionProfile20180618_611774(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2018-06-18/field-level-encryption-profile/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateFieldLevelEncryptionProfile20180618_611773(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Update a field-level encryption profile. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the field-level encryption profile request. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_611775 = path.getOrDefault("Id")
  valid_611775 = validateParameter(valid_611775, JString, required = true,
                                 default = nil)
  if valid_611775 != nil:
    section.add "Id", valid_611775
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the profile identity to update. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611776 = header.getOrDefault("X-Amz-Signature")
  valid_611776 = validateParameter(valid_611776, JString, required = false,
                                 default = nil)
  if valid_611776 != nil:
    section.add "X-Amz-Signature", valid_611776
  var valid_611777 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611777 = validateParameter(valid_611777, JString, required = false,
                                 default = nil)
  if valid_611777 != nil:
    section.add "X-Amz-Content-Sha256", valid_611777
  var valid_611778 = header.getOrDefault("X-Amz-Date")
  valid_611778 = validateParameter(valid_611778, JString, required = false,
                                 default = nil)
  if valid_611778 != nil:
    section.add "X-Amz-Date", valid_611778
  var valid_611779 = header.getOrDefault("X-Amz-Credential")
  valid_611779 = validateParameter(valid_611779, JString, required = false,
                                 default = nil)
  if valid_611779 != nil:
    section.add "X-Amz-Credential", valid_611779
  var valid_611780 = header.getOrDefault("X-Amz-Security-Token")
  valid_611780 = validateParameter(valid_611780, JString, required = false,
                                 default = nil)
  if valid_611780 != nil:
    section.add "X-Amz-Security-Token", valid_611780
  var valid_611781 = header.getOrDefault("If-Match")
  valid_611781 = validateParameter(valid_611781, JString, required = false,
                                 default = nil)
  if valid_611781 != nil:
    section.add "If-Match", valid_611781
  var valid_611782 = header.getOrDefault("X-Amz-Algorithm")
  valid_611782 = validateParameter(valid_611782, JString, required = false,
                                 default = nil)
  if valid_611782 != nil:
    section.add "X-Amz-Algorithm", valid_611782
  var valid_611783 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611783 = validateParameter(valid_611783, JString, required = false,
                                 default = nil)
  if valid_611783 != nil:
    section.add "X-Amz-SignedHeaders", valid_611783
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611785: Call_UpdateFieldLevelEncryptionProfile20180618_611772;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Update a field-level encryption profile. 
  ## 
  let valid = call_611785.validator(path, query, header, formData, body)
  let scheme = call_611785.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611785.url(scheme.get, call_611785.host, call_611785.base,
                         call_611785.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611785, url, valid)

proc call*(call_611786: Call_UpdateFieldLevelEncryptionProfile20180618_611772;
          body: JsonNode; Id: string): Recallable =
  ## updateFieldLevelEncryptionProfile20180618
  ## Update a field-level encryption profile. 
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : The ID of the field-level encryption profile request. 
  var path_611787 = newJObject()
  var body_611788 = newJObject()
  if body != nil:
    body_611788 = body
  add(path_611787, "Id", newJString(Id))
  result = call_611786.call(path_611787, nil, nil, nil, body_611788)

var updateFieldLevelEncryptionProfile20180618* = Call_UpdateFieldLevelEncryptionProfile20180618_611772(
    name: "updateFieldLevelEncryptionProfile20180618", meth: HttpMethod.HttpPut,
    host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/field-level-encryption-profile/{Id}/config",
    validator: validate_UpdateFieldLevelEncryptionProfile20180618_611773,
    base: "/", url: url_UpdateFieldLevelEncryptionProfile20180618_611774,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFieldLevelEncryptionProfileConfig20180618_611758 = ref object of OpenApiRestCall_610658
proc url_GetFieldLevelEncryptionProfileConfig20180618_611760(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2018-06-18/field-level-encryption-profile/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFieldLevelEncryptionProfileConfig20180618_611759(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get the field-level encryption profile configuration information.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : Get the ID for the field-level encryption profile configuration information.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_611761 = path.getOrDefault("Id")
  valid_611761 = validateParameter(valid_611761, JString, required = true,
                                 default = nil)
  if valid_611761 != nil:
    section.add "Id", valid_611761
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611762 = header.getOrDefault("X-Amz-Signature")
  valid_611762 = validateParameter(valid_611762, JString, required = false,
                                 default = nil)
  if valid_611762 != nil:
    section.add "X-Amz-Signature", valid_611762
  var valid_611763 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611763 = validateParameter(valid_611763, JString, required = false,
                                 default = nil)
  if valid_611763 != nil:
    section.add "X-Amz-Content-Sha256", valid_611763
  var valid_611764 = header.getOrDefault("X-Amz-Date")
  valid_611764 = validateParameter(valid_611764, JString, required = false,
                                 default = nil)
  if valid_611764 != nil:
    section.add "X-Amz-Date", valid_611764
  var valid_611765 = header.getOrDefault("X-Amz-Credential")
  valid_611765 = validateParameter(valid_611765, JString, required = false,
                                 default = nil)
  if valid_611765 != nil:
    section.add "X-Amz-Credential", valid_611765
  var valid_611766 = header.getOrDefault("X-Amz-Security-Token")
  valid_611766 = validateParameter(valid_611766, JString, required = false,
                                 default = nil)
  if valid_611766 != nil:
    section.add "X-Amz-Security-Token", valid_611766
  var valid_611767 = header.getOrDefault("X-Amz-Algorithm")
  valid_611767 = validateParameter(valid_611767, JString, required = false,
                                 default = nil)
  if valid_611767 != nil:
    section.add "X-Amz-Algorithm", valid_611767
  var valid_611768 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611768 = validateParameter(valid_611768, JString, required = false,
                                 default = nil)
  if valid_611768 != nil:
    section.add "X-Amz-SignedHeaders", valid_611768
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611769: Call_GetFieldLevelEncryptionProfileConfig20180618_611758;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Get the field-level encryption profile configuration information.
  ## 
  let valid = call_611769.validator(path, query, header, formData, body)
  let scheme = call_611769.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611769.url(scheme.get, call_611769.host, call_611769.base,
                         call_611769.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611769, url, valid)

proc call*(call_611770: Call_GetFieldLevelEncryptionProfileConfig20180618_611758;
          Id: string): Recallable =
  ## getFieldLevelEncryptionProfileConfig20180618
  ## Get the field-level encryption profile configuration information.
  ##   Id: string (required)
  ##     : Get the ID for the field-level encryption profile configuration information.
  var path_611771 = newJObject()
  add(path_611771, "Id", newJString(Id))
  result = call_611770.call(path_611771, nil, nil, nil, nil)

var getFieldLevelEncryptionProfileConfig20180618* = Call_GetFieldLevelEncryptionProfileConfig20180618_611758(
    name: "getFieldLevelEncryptionProfileConfig20180618",
    meth: HttpMethod.HttpGet, host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/field-level-encryption-profile/{Id}/config",
    validator: validate_GetFieldLevelEncryptionProfileConfig20180618_611759,
    base: "/", url: url_GetFieldLevelEncryptionProfileConfig20180618_611760,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInvalidation20180618_611789 = ref object of OpenApiRestCall_610658
proc url_GetInvalidation20180618_611791(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DistributionId" in path, "`DistributionId` is a required path parameter"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-06-18/distribution/"),
               (kind: VariableSegment, value: "DistributionId"),
               (kind: ConstantSegment, value: "/invalidation/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetInvalidation20180618_611790(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get the information about an invalidation. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DistributionId: JString (required)
  ##                 : The distribution's ID.
  ##   Id: JString (required)
  ##     : The identifier for the invalidation request, for example, <code>IDFDVBD632BHDS5</code>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `DistributionId` field"
  var valid_611792 = path.getOrDefault("DistributionId")
  valid_611792 = validateParameter(valid_611792, JString, required = true,
                                 default = nil)
  if valid_611792 != nil:
    section.add "DistributionId", valid_611792
  var valid_611793 = path.getOrDefault("Id")
  valid_611793 = validateParameter(valid_611793, JString, required = true,
                                 default = nil)
  if valid_611793 != nil:
    section.add "Id", valid_611793
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611794 = header.getOrDefault("X-Amz-Signature")
  valid_611794 = validateParameter(valid_611794, JString, required = false,
                                 default = nil)
  if valid_611794 != nil:
    section.add "X-Amz-Signature", valid_611794
  var valid_611795 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611795 = validateParameter(valid_611795, JString, required = false,
                                 default = nil)
  if valid_611795 != nil:
    section.add "X-Amz-Content-Sha256", valid_611795
  var valid_611796 = header.getOrDefault("X-Amz-Date")
  valid_611796 = validateParameter(valid_611796, JString, required = false,
                                 default = nil)
  if valid_611796 != nil:
    section.add "X-Amz-Date", valid_611796
  var valid_611797 = header.getOrDefault("X-Amz-Credential")
  valid_611797 = validateParameter(valid_611797, JString, required = false,
                                 default = nil)
  if valid_611797 != nil:
    section.add "X-Amz-Credential", valid_611797
  var valid_611798 = header.getOrDefault("X-Amz-Security-Token")
  valid_611798 = validateParameter(valid_611798, JString, required = false,
                                 default = nil)
  if valid_611798 != nil:
    section.add "X-Amz-Security-Token", valid_611798
  var valid_611799 = header.getOrDefault("X-Amz-Algorithm")
  valid_611799 = validateParameter(valid_611799, JString, required = false,
                                 default = nil)
  if valid_611799 != nil:
    section.add "X-Amz-Algorithm", valid_611799
  var valid_611800 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611800 = validateParameter(valid_611800, JString, required = false,
                                 default = nil)
  if valid_611800 != nil:
    section.add "X-Amz-SignedHeaders", valid_611800
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611801: Call_GetInvalidation20180618_611789; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the information about an invalidation. 
  ## 
  let valid = call_611801.validator(path, query, header, formData, body)
  let scheme = call_611801.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611801.url(scheme.get, call_611801.host, call_611801.base,
                         call_611801.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611801, url, valid)

proc call*(call_611802: Call_GetInvalidation20180618_611789;
          DistributionId: string; Id: string): Recallable =
  ## getInvalidation20180618
  ## Get the information about an invalidation. 
  ##   DistributionId: string (required)
  ##                 : The distribution's ID.
  ##   Id: string (required)
  ##     : The identifier for the invalidation request, for example, <code>IDFDVBD632BHDS5</code>.
  var path_611803 = newJObject()
  add(path_611803, "DistributionId", newJString(DistributionId))
  add(path_611803, "Id", newJString(Id))
  result = call_611802.call(path_611803, nil, nil, nil, nil)

var getInvalidation20180618* = Call_GetInvalidation20180618_611789(
    name: "getInvalidation20180618", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/distribution/{DistributionId}/invalidation/{Id}",
    validator: validate_GetInvalidation20180618_611790, base: "/",
    url: url_GetInvalidation20180618_611791, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePublicKey20180618_611818 = ref object of OpenApiRestCall_610658
proc url_UpdatePublicKey20180618_611820(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-06-18/public-key/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdatePublicKey20180618_611819(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Update public key information. Note that the only value you can change is the comment.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : ID of the public key to be updated.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_611821 = path.getOrDefault("Id")
  valid_611821 = validateParameter(valid_611821, JString, required = true,
                                 default = nil)
  if valid_611821 != nil:
    section.add "Id", valid_611821
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the public key to update. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611822 = header.getOrDefault("X-Amz-Signature")
  valid_611822 = validateParameter(valid_611822, JString, required = false,
                                 default = nil)
  if valid_611822 != nil:
    section.add "X-Amz-Signature", valid_611822
  var valid_611823 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611823 = validateParameter(valid_611823, JString, required = false,
                                 default = nil)
  if valid_611823 != nil:
    section.add "X-Amz-Content-Sha256", valid_611823
  var valid_611824 = header.getOrDefault("X-Amz-Date")
  valid_611824 = validateParameter(valid_611824, JString, required = false,
                                 default = nil)
  if valid_611824 != nil:
    section.add "X-Amz-Date", valid_611824
  var valid_611825 = header.getOrDefault("X-Amz-Credential")
  valid_611825 = validateParameter(valid_611825, JString, required = false,
                                 default = nil)
  if valid_611825 != nil:
    section.add "X-Amz-Credential", valid_611825
  var valid_611826 = header.getOrDefault("X-Amz-Security-Token")
  valid_611826 = validateParameter(valid_611826, JString, required = false,
                                 default = nil)
  if valid_611826 != nil:
    section.add "X-Amz-Security-Token", valid_611826
  var valid_611827 = header.getOrDefault("If-Match")
  valid_611827 = validateParameter(valid_611827, JString, required = false,
                                 default = nil)
  if valid_611827 != nil:
    section.add "If-Match", valid_611827
  var valid_611828 = header.getOrDefault("X-Amz-Algorithm")
  valid_611828 = validateParameter(valid_611828, JString, required = false,
                                 default = nil)
  if valid_611828 != nil:
    section.add "X-Amz-Algorithm", valid_611828
  var valid_611829 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611829 = validateParameter(valid_611829, JString, required = false,
                                 default = nil)
  if valid_611829 != nil:
    section.add "X-Amz-SignedHeaders", valid_611829
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611831: Call_UpdatePublicKey20180618_611818; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Update public key information. Note that the only value you can change is the comment.
  ## 
  let valid = call_611831.validator(path, query, header, formData, body)
  let scheme = call_611831.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611831.url(scheme.get, call_611831.host, call_611831.base,
                         call_611831.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611831, url, valid)

proc call*(call_611832: Call_UpdatePublicKey20180618_611818; body: JsonNode;
          Id: string): Recallable =
  ## updatePublicKey20180618
  ## Update public key information. Note that the only value you can change is the comment.
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : ID of the public key to be updated.
  var path_611833 = newJObject()
  var body_611834 = newJObject()
  if body != nil:
    body_611834 = body
  add(path_611833, "Id", newJString(Id))
  result = call_611832.call(path_611833, nil, nil, nil, body_611834)

var updatePublicKey20180618* = Call_UpdatePublicKey20180618_611818(
    name: "updatePublicKey20180618", meth: HttpMethod.HttpPut,
    host: "cloudfront.amazonaws.com", route: "/2018-06-18/public-key/{Id}/config",
    validator: validate_UpdatePublicKey20180618_611819, base: "/",
    url: url_UpdatePublicKey20180618_611820, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPublicKeyConfig20180618_611804 = ref object of OpenApiRestCall_610658
proc url_GetPublicKeyConfig20180618_611806(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-06-18/public-key/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetPublicKeyConfig20180618_611805(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Return public key configuration informaation
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : Request the ID for the public key configuration.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_611807 = path.getOrDefault("Id")
  valid_611807 = validateParameter(valid_611807, JString, required = true,
                                 default = nil)
  if valid_611807 != nil:
    section.add "Id", valid_611807
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611808 = header.getOrDefault("X-Amz-Signature")
  valid_611808 = validateParameter(valid_611808, JString, required = false,
                                 default = nil)
  if valid_611808 != nil:
    section.add "X-Amz-Signature", valid_611808
  var valid_611809 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611809 = validateParameter(valid_611809, JString, required = false,
                                 default = nil)
  if valid_611809 != nil:
    section.add "X-Amz-Content-Sha256", valid_611809
  var valid_611810 = header.getOrDefault("X-Amz-Date")
  valid_611810 = validateParameter(valid_611810, JString, required = false,
                                 default = nil)
  if valid_611810 != nil:
    section.add "X-Amz-Date", valid_611810
  var valid_611811 = header.getOrDefault("X-Amz-Credential")
  valid_611811 = validateParameter(valid_611811, JString, required = false,
                                 default = nil)
  if valid_611811 != nil:
    section.add "X-Amz-Credential", valid_611811
  var valid_611812 = header.getOrDefault("X-Amz-Security-Token")
  valid_611812 = validateParameter(valid_611812, JString, required = false,
                                 default = nil)
  if valid_611812 != nil:
    section.add "X-Amz-Security-Token", valid_611812
  var valid_611813 = header.getOrDefault("X-Amz-Algorithm")
  valid_611813 = validateParameter(valid_611813, JString, required = false,
                                 default = nil)
  if valid_611813 != nil:
    section.add "X-Amz-Algorithm", valid_611813
  var valid_611814 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611814 = validateParameter(valid_611814, JString, required = false,
                                 default = nil)
  if valid_611814 != nil:
    section.add "X-Amz-SignedHeaders", valid_611814
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611815: Call_GetPublicKeyConfig20180618_611804; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Return public key configuration informaation
  ## 
  let valid = call_611815.validator(path, query, header, formData, body)
  let scheme = call_611815.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611815.url(scheme.get, call_611815.host, call_611815.base,
                         call_611815.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611815, url, valid)

proc call*(call_611816: Call_GetPublicKeyConfig20180618_611804; Id: string): Recallable =
  ## getPublicKeyConfig20180618
  ## Return public key configuration informaation
  ##   Id: string (required)
  ##     : Request the ID for the public key configuration.
  var path_611817 = newJObject()
  add(path_611817, "Id", newJString(Id))
  result = call_611816.call(path_611817, nil, nil, nil, nil)

var getPublicKeyConfig20180618* = Call_GetPublicKeyConfig20180618_611804(
    name: "getPublicKeyConfig20180618", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2018-06-18/public-key/{Id}/config",
    validator: validate_GetPublicKeyConfig20180618_611805, base: "/",
    url: url_GetPublicKeyConfig20180618_611806,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateStreamingDistribution20180618_611849 = ref object of OpenApiRestCall_610658
proc url_UpdateStreamingDistribution20180618_611851(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2018-06-18/streaming-distribution/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateStreamingDistribution20180618_611850(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Update a streaming distribution. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The streaming distribution's id.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_611852 = path.getOrDefault("Id")
  valid_611852 = validateParameter(valid_611852, JString, required = true,
                                 default = nil)
  if valid_611852 != nil:
    section.add "Id", valid_611852
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the streaming distribution's configuration. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611853 = header.getOrDefault("X-Amz-Signature")
  valid_611853 = validateParameter(valid_611853, JString, required = false,
                                 default = nil)
  if valid_611853 != nil:
    section.add "X-Amz-Signature", valid_611853
  var valid_611854 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611854 = validateParameter(valid_611854, JString, required = false,
                                 default = nil)
  if valid_611854 != nil:
    section.add "X-Amz-Content-Sha256", valid_611854
  var valid_611855 = header.getOrDefault("X-Amz-Date")
  valid_611855 = validateParameter(valid_611855, JString, required = false,
                                 default = nil)
  if valid_611855 != nil:
    section.add "X-Amz-Date", valid_611855
  var valid_611856 = header.getOrDefault("X-Amz-Credential")
  valid_611856 = validateParameter(valid_611856, JString, required = false,
                                 default = nil)
  if valid_611856 != nil:
    section.add "X-Amz-Credential", valid_611856
  var valid_611857 = header.getOrDefault("X-Amz-Security-Token")
  valid_611857 = validateParameter(valid_611857, JString, required = false,
                                 default = nil)
  if valid_611857 != nil:
    section.add "X-Amz-Security-Token", valid_611857
  var valid_611858 = header.getOrDefault("If-Match")
  valid_611858 = validateParameter(valid_611858, JString, required = false,
                                 default = nil)
  if valid_611858 != nil:
    section.add "If-Match", valid_611858
  var valid_611859 = header.getOrDefault("X-Amz-Algorithm")
  valid_611859 = validateParameter(valid_611859, JString, required = false,
                                 default = nil)
  if valid_611859 != nil:
    section.add "X-Amz-Algorithm", valid_611859
  var valid_611860 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611860 = validateParameter(valid_611860, JString, required = false,
                                 default = nil)
  if valid_611860 != nil:
    section.add "X-Amz-SignedHeaders", valid_611860
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611862: Call_UpdateStreamingDistribution20180618_611849;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Update a streaming distribution. 
  ## 
  let valid = call_611862.validator(path, query, header, formData, body)
  let scheme = call_611862.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611862.url(scheme.get, call_611862.host, call_611862.base,
                         call_611862.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611862, url, valid)

proc call*(call_611863: Call_UpdateStreamingDistribution20180618_611849;
          body: JsonNode; Id: string): Recallable =
  ## updateStreamingDistribution20180618
  ## Update a streaming distribution. 
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : The streaming distribution's id.
  var path_611864 = newJObject()
  var body_611865 = newJObject()
  if body != nil:
    body_611865 = body
  add(path_611864, "Id", newJString(Id))
  result = call_611863.call(path_611864, nil, nil, nil, body_611865)

var updateStreamingDistribution20180618* = Call_UpdateStreamingDistribution20180618_611849(
    name: "updateStreamingDistribution20180618", meth: HttpMethod.HttpPut,
    host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/streaming-distribution/{Id}/config",
    validator: validate_UpdateStreamingDistribution20180618_611850, base: "/",
    url: url_UpdateStreamingDistribution20180618_611851,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStreamingDistributionConfig20180618_611835 = ref object of OpenApiRestCall_610658
proc url_GetStreamingDistributionConfig20180618_611837(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2018-06-18/streaming-distribution/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetStreamingDistributionConfig20180618_611836(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get the configuration information about a streaming distribution. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The streaming distribution's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_611838 = path.getOrDefault("Id")
  valid_611838 = validateParameter(valid_611838, JString, required = true,
                                 default = nil)
  if valid_611838 != nil:
    section.add "Id", valid_611838
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611839 = header.getOrDefault("X-Amz-Signature")
  valid_611839 = validateParameter(valid_611839, JString, required = false,
                                 default = nil)
  if valid_611839 != nil:
    section.add "X-Amz-Signature", valid_611839
  var valid_611840 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611840 = validateParameter(valid_611840, JString, required = false,
                                 default = nil)
  if valid_611840 != nil:
    section.add "X-Amz-Content-Sha256", valid_611840
  var valid_611841 = header.getOrDefault("X-Amz-Date")
  valid_611841 = validateParameter(valid_611841, JString, required = false,
                                 default = nil)
  if valid_611841 != nil:
    section.add "X-Amz-Date", valid_611841
  var valid_611842 = header.getOrDefault("X-Amz-Credential")
  valid_611842 = validateParameter(valid_611842, JString, required = false,
                                 default = nil)
  if valid_611842 != nil:
    section.add "X-Amz-Credential", valid_611842
  var valid_611843 = header.getOrDefault("X-Amz-Security-Token")
  valid_611843 = validateParameter(valid_611843, JString, required = false,
                                 default = nil)
  if valid_611843 != nil:
    section.add "X-Amz-Security-Token", valid_611843
  var valid_611844 = header.getOrDefault("X-Amz-Algorithm")
  valid_611844 = validateParameter(valid_611844, JString, required = false,
                                 default = nil)
  if valid_611844 != nil:
    section.add "X-Amz-Algorithm", valid_611844
  var valid_611845 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611845 = validateParameter(valid_611845, JString, required = false,
                                 default = nil)
  if valid_611845 != nil:
    section.add "X-Amz-SignedHeaders", valid_611845
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611846: Call_GetStreamingDistributionConfig20180618_611835;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Get the configuration information about a streaming distribution. 
  ## 
  let valid = call_611846.validator(path, query, header, formData, body)
  let scheme = call_611846.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611846.url(scheme.get, call_611846.host, call_611846.base,
                         call_611846.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611846, url, valid)

proc call*(call_611847: Call_GetStreamingDistributionConfig20180618_611835;
          Id: string): Recallable =
  ## getStreamingDistributionConfig20180618
  ## Get the configuration information about a streaming distribution. 
  ##   Id: string (required)
  ##     : The streaming distribution's ID.
  var path_611848 = newJObject()
  add(path_611848, "Id", newJString(Id))
  result = call_611847.call(path_611848, nil, nil, nil, nil)

var getStreamingDistributionConfig20180618* = Call_GetStreamingDistributionConfig20180618_611835(
    name: "getStreamingDistributionConfig20180618", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/streaming-distribution/{Id}/config",
    validator: validate_GetStreamingDistributionConfig20180618_611836, base: "/",
    url: url_GetStreamingDistributionConfig20180618_611837,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDistributionsByWebACLId20180618_611866 = ref object of OpenApiRestCall_610658
proc url_ListDistributionsByWebACLId20180618_611868(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "WebACLId" in path, "`WebACLId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2018-06-18/distributionsByWebACLId/"),
               (kind: VariableSegment, value: "WebACLId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDistributionsByWebACLId20180618_611867(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List the distributions that are associated with a specified AWS WAF web ACL. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   WebACLId: JString (required)
  ##           : The ID of the AWS WAF web ACL that you want to list the associated distributions. If you specify "null" for the ID, the request returns a list of the distributions that aren't associated with a web ACL. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `WebACLId` field"
  var valid_611869 = path.getOrDefault("WebACLId")
  valid_611869 = validateParameter(valid_611869, JString, required = true,
                                 default = nil)
  if valid_611869 != nil:
    section.add "WebACLId", valid_611869
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Use <code>Marker</code> and <code>MaxItems</code> to control pagination of results. If you have more than <code>MaxItems</code> distributions that satisfy the request, the response includes a <code>NextMarker</code> element. To get the next page of results, submit another request. For the value of <code>Marker</code>, specify the value of <code>NextMarker</code> from the last response. (For the first request, omit <code>Marker</code>.) 
  ##   MaxItems: JString
  ##           : The maximum number of distributions that you want CloudFront to return in the response body. The maximum and default values are both 100.
  section = newJObject()
  var valid_611870 = query.getOrDefault("Marker")
  valid_611870 = validateParameter(valid_611870, JString, required = false,
                                 default = nil)
  if valid_611870 != nil:
    section.add "Marker", valid_611870
  var valid_611871 = query.getOrDefault("MaxItems")
  valid_611871 = validateParameter(valid_611871, JString, required = false,
                                 default = nil)
  if valid_611871 != nil:
    section.add "MaxItems", valid_611871
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611872 = header.getOrDefault("X-Amz-Signature")
  valid_611872 = validateParameter(valid_611872, JString, required = false,
                                 default = nil)
  if valid_611872 != nil:
    section.add "X-Amz-Signature", valid_611872
  var valid_611873 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611873 = validateParameter(valid_611873, JString, required = false,
                                 default = nil)
  if valid_611873 != nil:
    section.add "X-Amz-Content-Sha256", valid_611873
  var valid_611874 = header.getOrDefault("X-Amz-Date")
  valid_611874 = validateParameter(valid_611874, JString, required = false,
                                 default = nil)
  if valid_611874 != nil:
    section.add "X-Amz-Date", valid_611874
  var valid_611875 = header.getOrDefault("X-Amz-Credential")
  valid_611875 = validateParameter(valid_611875, JString, required = false,
                                 default = nil)
  if valid_611875 != nil:
    section.add "X-Amz-Credential", valid_611875
  var valid_611876 = header.getOrDefault("X-Amz-Security-Token")
  valid_611876 = validateParameter(valid_611876, JString, required = false,
                                 default = nil)
  if valid_611876 != nil:
    section.add "X-Amz-Security-Token", valid_611876
  var valid_611877 = header.getOrDefault("X-Amz-Algorithm")
  valid_611877 = validateParameter(valid_611877, JString, required = false,
                                 default = nil)
  if valid_611877 != nil:
    section.add "X-Amz-Algorithm", valid_611877
  var valid_611878 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611878 = validateParameter(valid_611878, JString, required = false,
                                 default = nil)
  if valid_611878 != nil:
    section.add "X-Amz-SignedHeaders", valid_611878
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611879: Call_ListDistributionsByWebACLId20180618_611866;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## List the distributions that are associated with a specified AWS WAF web ACL. 
  ## 
  let valid = call_611879.validator(path, query, header, formData, body)
  let scheme = call_611879.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611879.url(scheme.get, call_611879.host, call_611879.base,
                         call_611879.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611879, url, valid)

proc call*(call_611880: Call_ListDistributionsByWebACLId20180618_611866;
          WebACLId: string; Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listDistributionsByWebACLId20180618
  ## List the distributions that are associated with a specified AWS WAF web ACL. 
  ##   Marker: string
  ##         : Use <code>Marker</code> and <code>MaxItems</code> to control pagination of results. If you have more than <code>MaxItems</code> distributions that satisfy the request, the response includes a <code>NextMarker</code> element. To get the next page of results, submit another request. For the value of <code>Marker</code>, specify the value of <code>NextMarker</code> from the last response. (For the first request, omit <code>Marker</code>.) 
  ##   MaxItems: string
  ##           : The maximum number of distributions that you want CloudFront to return in the response body. The maximum and default values are both 100.
  ##   WebACLId: string (required)
  ##           : The ID of the AWS WAF web ACL that you want to list the associated distributions. If you specify "null" for the ID, the request returns a list of the distributions that aren't associated with a web ACL. 
  var path_611881 = newJObject()
  var query_611882 = newJObject()
  add(query_611882, "Marker", newJString(Marker))
  add(query_611882, "MaxItems", newJString(MaxItems))
  add(path_611881, "WebACLId", newJString(WebACLId))
  result = call_611880.call(path_611881, query_611882, nil, nil, nil)

var listDistributionsByWebACLId20180618* = Call_ListDistributionsByWebACLId20180618_611866(
    name: "listDistributionsByWebACLId20180618", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/distributionsByWebACLId/{WebACLId}",
    validator: validate_ListDistributionsByWebACLId20180618_611867, base: "/",
    url: url_ListDistributionsByWebACLId20180618_611868,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource20180618_611883 = ref object of OpenApiRestCall_610658
proc url_ListTagsForResource20180618_611885(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource20180618_611884(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List tags for a CloudFront resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Resource: JString (required)
  ##           :  An ARN of a CloudFront resource.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Resource` field"
  var valid_611886 = query.getOrDefault("Resource")
  valid_611886 = validateParameter(valid_611886, JString, required = true,
                                 default = nil)
  if valid_611886 != nil:
    section.add "Resource", valid_611886
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611887 = header.getOrDefault("X-Amz-Signature")
  valid_611887 = validateParameter(valid_611887, JString, required = false,
                                 default = nil)
  if valid_611887 != nil:
    section.add "X-Amz-Signature", valid_611887
  var valid_611888 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611888 = validateParameter(valid_611888, JString, required = false,
                                 default = nil)
  if valid_611888 != nil:
    section.add "X-Amz-Content-Sha256", valid_611888
  var valid_611889 = header.getOrDefault("X-Amz-Date")
  valid_611889 = validateParameter(valid_611889, JString, required = false,
                                 default = nil)
  if valid_611889 != nil:
    section.add "X-Amz-Date", valid_611889
  var valid_611890 = header.getOrDefault("X-Amz-Credential")
  valid_611890 = validateParameter(valid_611890, JString, required = false,
                                 default = nil)
  if valid_611890 != nil:
    section.add "X-Amz-Credential", valid_611890
  var valid_611891 = header.getOrDefault("X-Amz-Security-Token")
  valid_611891 = validateParameter(valid_611891, JString, required = false,
                                 default = nil)
  if valid_611891 != nil:
    section.add "X-Amz-Security-Token", valid_611891
  var valid_611892 = header.getOrDefault("X-Amz-Algorithm")
  valid_611892 = validateParameter(valid_611892, JString, required = false,
                                 default = nil)
  if valid_611892 != nil:
    section.add "X-Amz-Algorithm", valid_611892
  var valid_611893 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611893 = validateParameter(valid_611893, JString, required = false,
                                 default = nil)
  if valid_611893 != nil:
    section.add "X-Amz-SignedHeaders", valid_611893
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611894: Call_ListTagsForResource20180618_611883; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List tags for a CloudFront resource.
  ## 
  let valid = call_611894.validator(path, query, header, formData, body)
  let scheme = call_611894.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611894.url(scheme.get, call_611894.host, call_611894.base,
                         call_611894.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611894, url, valid)

proc call*(call_611895: Call_ListTagsForResource20180618_611883; Resource: string): Recallable =
  ## listTagsForResource20180618
  ## List tags for a CloudFront resource.
  ##   Resource: string (required)
  ##           :  An ARN of a CloudFront resource.
  var query_611896 = newJObject()
  add(query_611896, "Resource", newJString(Resource))
  result = call_611895.call(nil, query_611896, nil, nil, nil)

var listTagsForResource20180618* = Call_ListTagsForResource20180618_611883(
    name: "listTagsForResource20180618", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2018-06-18/tagging#Resource",
    validator: validate_ListTagsForResource20180618_611884, base: "/",
    url: url_ListTagsForResource20180618_611885,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource20180618_611897 = ref object of OpenApiRestCall_610658
proc url_TagResource20180618_611899(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource20180618_611898(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Add tags to a CloudFront resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Resource: JString (required)
  ##           :  An ARN of a CloudFront resource.
  ##   Operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Resource` field"
  var valid_611900 = query.getOrDefault("Resource")
  valid_611900 = validateParameter(valid_611900, JString, required = true,
                                 default = nil)
  if valid_611900 != nil:
    section.add "Resource", valid_611900
  var valid_611914 = query.getOrDefault("Operation")
  valid_611914 = validateParameter(valid_611914, JString, required = true,
                                 default = newJString("Tag"))
  if valid_611914 != nil:
    section.add "Operation", valid_611914
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611915 = header.getOrDefault("X-Amz-Signature")
  valid_611915 = validateParameter(valid_611915, JString, required = false,
                                 default = nil)
  if valid_611915 != nil:
    section.add "X-Amz-Signature", valid_611915
  var valid_611916 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611916 = validateParameter(valid_611916, JString, required = false,
                                 default = nil)
  if valid_611916 != nil:
    section.add "X-Amz-Content-Sha256", valid_611916
  var valid_611917 = header.getOrDefault("X-Amz-Date")
  valid_611917 = validateParameter(valid_611917, JString, required = false,
                                 default = nil)
  if valid_611917 != nil:
    section.add "X-Amz-Date", valid_611917
  var valid_611918 = header.getOrDefault("X-Amz-Credential")
  valid_611918 = validateParameter(valid_611918, JString, required = false,
                                 default = nil)
  if valid_611918 != nil:
    section.add "X-Amz-Credential", valid_611918
  var valid_611919 = header.getOrDefault("X-Amz-Security-Token")
  valid_611919 = validateParameter(valid_611919, JString, required = false,
                                 default = nil)
  if valid_611919 != nil:
    section.add "X-Amz-Security-Token", valid_611919
  var valid_611920 = header.getOrDefault("X-Amz-Algorithm")
  valid_611920 = validateParameter(valid_611920, JString, required = false,
                                 default = nil)
  if valid_611920 != nil:
    section.add "X-Amz-Algorithm", valid_611920
  var valid_611921 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611921 = validateParameter(valid_611921, JString, required = false,
                                 default = nil)
  if valid_611921 != nil:
    section.add "X-Amz-SignedHeaders", valid_611921
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611923: Call_TagResource20180618_611897; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Add tags to a CloudFront resource.
  ## 
  let valid = call_611923.validator(path, query, header, formData, body)
  let scheme = call_611923.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611923.url(scheme.get, call_611923.host, call_611923.base,
                         call_611923.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611923, url, valid)

proc call*(call_611924: Call_TagResource20180618_611897; Resource: string;
          body: JsonNode; Operation: string = "Tag"): Recallable =
  ## tagResource20180618
  ## Add tags to a CloudFront resource.
  ##   Resource: string (required)
  ##           :  An ARN of a CloudFront resource.
  ##   Operation: string (required)
  ##   body: JObject (required)
  var query_611925 = newJObject()
  var body_611926 = newJObject()
  add(query_611925, "Resource", newJString(Resource))
  add(query_611925, "Operation", newJString(Operation))
  if body != nil:
    body_611926 = body
  result = call_611924.call(nil, query_611925, nil, nil, body_611926)

var tagResource20180618* = Call_TagResource20180618_611897(
    name: "tagResource20180618", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/tagging#Operation=Tag&Resource",
    validator: validate_TagResource20180618_611898, base: "/",
    url: url_TagResource20180618_611899, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource20180618_611927 = ref object of OpenApiRestCall_610658
proc url_UntagResource20180618_611929(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource20180618_611928(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Remove tags from a CloudFront resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Resource: JString (required)
  ##           :  An ARN of a CloudFront resource.
  ##   Operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Resource` field"
  var valid_611930 = query.getOrDefault("Resource")
  valid_611930 = validateParameter(valid_611930, JString, required = true,
                                 default = nil)
  if valid_611930 != nil:
    section.add "Resource", valid_611930
  var valid_611931 = query.getOrDefault("Operation")
  valid_611931 = validateParameter(valid_611931, JString, required = true,
                                 default = newJString("Untag"))
  if valid_611931 != nil:
    section.add "Operation", valid_611931
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611932 = header.getOrDefault("X-Amz-Signature")
  valid_611932 = validateParameter(valid_611932, JString, required = false,
                                 default = nil)
  if valid_611932 != nil:
    section.add "X-Amz-Signature", valid_611932
  var valid_611933 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611933 = validateParameter(valid_611933, JString, required = false,
                                 default = nil)
  if valid_611933 != nil:
    section.add "X-Amz-Content-Sha256", valid_611933
  var valid_611934 = header.getOrDefault("X-Amz-Date")
  valid_611934 = validateParameter(valid_611934, JString, required = false,
                                 default = nil)
  if valid_611934 != nil:
    section.add "X-Amz-Date", valid_611934
  var valid_611935 = header.getOrDefault("X-Amz-Credential")
  valid_611935 = validateParameter(valid_611935, JString, required = false,
                                 default = nil)
  if valid_611935 != nil:
    section.add "X-Amz-Credential", valid_611935
  var valid_611936 = header.getOrDefault("X-Amz-Security-Token")
  valid_611936 = validateParameter(valid_611936, JString, required = false,
                                 default = nil)
  if valid_611936 != nil:
    section.add "X-Amz-Security-Token", valid_611936
  var valid_611937 = header.getOrDefault("X-Amz-Algorithm")
  valid_611937 = validateParameter(valid_611937, JString, required = false,
                                 default = nil)
  if valid_611937 != nil:
    section.add "X-Amz-Algorithm", valid_611937
  var valid_611938 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611938 = validateParameter(valid_611938, JString, required = false,
                                 default = nil)
  if valid_611938 != nil:
    section.add "X-Amz-SignedHeaders", valid_611938
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611940: Call_UntagResource20180618_611927; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove tags from a CloudFront resource.
  ## 
  let valid = call_611940.validator(path, query, header, formData, body)
  let scheme = call_611940.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611940.url(scheme.get, call_611940.host, call_611940.base,
                         call_611940.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611940, url, valid)

proc call*(call_611941: Call_UntagResource20180618_611927; Resource: string;
          body: JsonNode; Operation: string = "Untag"): Recallable =
  ## untagResource20180618
  ## Remove tags from a CloudFront resource.
  ##   Resource: string (required)
  ##           :  An ARN of a CloudFront resource.
  ##   Operation: string (required)
  ##   body: JObject (required)
  var query_611942 = newJObject()
  var body_611943 = newJObject()
  add(query_611942, "Resource", newJString(Resource))
  add(query_611942, "Operation", newJString(Operation))
  if body != nil:
    body_611943 = body
  result = call_611941.call(nil, query_611942, nil, nil, body_611943)

var untagResource20180618* = Call_UntagResource20180618_611927(
    name: "untagResource20180618", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/tagging#Operation=Untag&Resource",
    validator: validate_UntagResource20180618_611928, base: "/",
    url: url_UntagResource20180618_611929, schemes: {Scheme.Https, Scheme.Http})
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

type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  headers[$ContentSha256] = hash(text, SHA256)
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
