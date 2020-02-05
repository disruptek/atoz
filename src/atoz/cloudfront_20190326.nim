
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon CloudFront
## version: 2019-03-26
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

  OpenApiRestCall_612658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612658): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"cn-northwest-1": "cloudfront.cn-northwest-1.amazonaws.com.cn", "cn-north-1": "cloudfront.cn-north-1.amazonaws.com.cn"}.toTable, Scheme.Https: {
      "cn-northwest-1": "cloudfront.cn-northwest-1.amazonaws.com.cn",
      "cn-north-1": "cloudfront.cn-north-1.amazonaws.com.cn"}.toTable}.toTable
const
  awsServiceName = "cloudfront"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateCloudFrontOriginAccessIdentity20190326_613253 = ref object of OpenApiRestCall_612658
proc url_CreateCloudFrontOriginAccessIdentity20190326_613255(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateCloudFrontOriginAccessIdentity20190326_613254(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new origin access identity. If you're using Amazon S3 for your origin, you can use an origin access identity to require users to access your content using a CloudFront URL instead of the Amazon S3 URL. For more information about how to use origin access identities, see <a href="https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PrivateContent.html">Serving Private Content through CloudFront</a> in the <i>Amazon CloudFront Developer Guide</i>.
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
  var valid_613256 = header.getOrDefault("X-Amz-Signature")
  valid_613256 = validateParameter(valid_613256, JString, required = false,
                                 default = nil)
  if valid_613256 != nil:
    section.add "X-Amz-Signature", valid_613256
  var valid_613257 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613257 = validateParameter(valid_613257, JString, required = false,
                                 default = nil)
  if valid_613257 != nil:
    section.add "X-Amz-Content-Sha256", valid_613257
  var valid_613258 = header.getOrDefault("X-Amz-Date")
  valid_613258 = validateParameter(valid_613258, JString, required = false,
                                 default = nil)
  if valid_613258 != nil:
    section.add "X-Amz-Date", valid_613258
  var valid_613259 = header.getOrDefault("X-Amz-Credential")
  valid_613259 = validateParameter(valid_613259, JString, required = false,
                                 default = nil)
  if valid_613259 != nil:
    section.add "X-Amz-Credential", valid_613259
  var valid_613260 = header.getOrDefault("X-Amz-Security-Token")
  valid_613260 = validateParameter(valid_613260, JString, required = false,
                                 default = nil)
  if valid_613260 != nil:
    section.add "X-Amz-Security-Token", valid_613260
  var valid_613261 = header.getOrDefault("X-Amz-Algorithm")
  valid_613261 = validateParameter(valid_613261, JString, required = false,
                                 default = nil)
  if valid_613261 != nil:
    section.add "X-Amz-Algorithm", valid_613261
  var valid_613262 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613262 = validateParameter(valid_613262, JString, required = false,
                                 default = nil)
  if valid_613262 != nil:
    section.add "X-Amz-SignedHeaders", valid_613262
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613264: Call_CreateCloudFrontOriginAccessIdentity20190326_613253;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates a new origin access identity. If you're using Amazon S3 for your origin, you can use an origin access identity to require users to access your content using a CloudFront URL instead of the Amazon S3 URL. For more information about how to use origin access identities, see <a href="https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PrivateContent.html">Serving Private Content through CloudFront</a> in the <i>Amazon CloudFront Developer Guide</i>.
  ## 
  let valid = call_613264.validator(path, query, header, formData, body)
  let scheme = call_613264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613264.url(scheme.get, call_613264.host, call_613264.base,
                         call_613264.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613264, url, valid)

proc call*(call_613265: Call_CreateCloudFrontOriginAccessIdentity20190326_613253;
          body: JsonNode): Recallable =
  ## createCloudFrontOriginAccessIdentity20190326
  ## Creates a new origin access identity. If you're using Amazon S3 for your origin, you can use an origin access identity to require users to access your content using a CloudFront URL instead of the Amazon S3 URL. For more information about how to use origin access identities, see <a href="https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PrivateContent.html">Serving Private Content through CloudFront</a> in the <i>Amazon CloudFront Developer Guide</i>.
  ##   body: JObject (required)
  var body_613266 = newJObject()
  if body != nil:
    body_613266 = body
  result = call_613265.call(nil, nil, nil, nil, body_613266)

var createCloudFrontOriginAccessIdentity20190326* = Call_CreateCloudFrontOriginAccessIdentity20190326_613253(
    name: "createCloudFrontOriginAccessIdentity20190326",
    meth: HttpMethod.HttpPost, host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/origin-access-identity/cloudfront",
    validator: validate_CreateCloudFrontOriginAccessIdentity20190326_613254,
    base: "/", url: url_CreateCloudFrontOriginAccessIdentity20190326_613255,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCloudFrontOriginAccessIdentities20190326_612996 = ref object of OpenApiRestCall_612658
proc url_ListCloudFrontOriginAccessIdentities20190326_612998(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListCloudFrontOriginAccessIdentities20190326_612997(path: JsonNode;
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
  var valid_613110 = query.getOrDefault("Marker")
  valid_613110 = validateParameter(valid_613110, JString, required = false,
                                 default = nil)
  if valid_613110 != nil:
    section.add "Marker", valid_613110
  var valid_613111 = query.getOrDefault("MaxItems")
  valid_613111 = validateParameter(valid_613111, JString, required = false,
                                 default = nil)
  if valid_613111 != nil:
    section.add "MaxItems", valid_613111
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
  var valid_613112 = header.getOrDefault("X-Amz-Signature")
  valid_613112 = validateParameter(valid_613112, JString, required = false,
                                 default = nil)
  if valid_613112 != nil:
    section.add "X-Amz-Signature", valid_613112
  var valid_613113 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613113 = validateParameter(valid_613113, JString, required = false,
                                 default = nil)
  if valid_613113 != nil:
    section.add "X-Amz-Content-Sha256", valid_613113
  var valid_613114 = header.getOrDefault("X-Amz-Date")
  valid_613114 = validateParameter(valid_613114, JString, required = false,
                                 default = nil)
  if valid_613114 != nil:
    section.add "X-Amz-Date", valid_613114
  var valid_613115 = header.getOrDefault("X-Amz-Credential")
  valid_613115 = validateParameter(valid_613115, JString, required = false,
                                 default = nil)
  if valid_613115 != nil:
    section.add "X-Amz-Credential", valid_613115
  var valid_613116 = header.getOrDefault("X-Amz-Security-Token")
  valid_613116 = validateParameter(valid_613116, JString, required = false,
                                 default = nil)
  if valid_613116 != nil:
    section.add "X-Amz-Security-Token", valid_613116
  var valid_613117 = header.getOrDefault("X-Amz-Algorithm")
  valid_613117 = validateParameter(valid_613117, JString, required = false,
                                 default = nil)
  if valid_613117 != nil:
    section.add "X-Amz-Algorithm", valid_613117
  var valid_613118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613118 = validateParameter(valid_613118, JString, required = false,
                                 default = nil)
  if valid_613118 != nil:
    section.add "X-Amz-SignedHeaders", valid_613118
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613141: Call_ListCloudFrontOriginAccessIdentities20190326_612996;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists origin access identities.
  ## 
  let valid = call_613141.validator(path, query, header, formData, body)
  let scheme = call_613141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613141.url(scheme.get, call_613141.host, call_613141.base,
                         call_613141.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613141, url, valid)

proc call*(call_613212: Call_ListCloudFrontOriginAccessIdentities20190326_612996;
          Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listCloudFrontOriginAccessIdentities20190326
  ## Lists origin access identities.
  ##   Marker: string
  ##         : Use this when paginating results to indicate where to begin in your list of origin access identities. The results include identities in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last identity on that page).
  ##   MaxItems: string
  ##           : The maximum number of origin access identities you want in the response body. 
  var query_613213 = newJObject()
  add(query_613213, "Marker", newJString(Marker))
  add(query_613213, "MaxItems", newJString(MaxItems))
  result = call_613212.call(nil, query_613213, nil, nil, nil)

var listCloudFrontOriginAccessIdentities20190326* = Call_ListCloudFrontOriginAccessIdentities20190326_612996(
    name: "listCloudFrontOriginAccessIdentities20190326",
    meth: HttpMethod.HttpGet, host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/origin-access-identity/cloudfront",
    validator: validate_ListCloudFrontOriginAccessIdentities20190326_612997,
    base: "/", url: url_ListCloudFrontOriginAccessIdentities20190326_612998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDistribution20190326_613282 = ref object of OpenApiRestCall_612658
proc url_CreateDistribution20190326_613284(protocol: Scheme; host: string;
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

proc validate_CreateDistribution20190326_613283(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new web distribution. You create a CloudFront distribution to tell CloudFront where you want content to be delivered from, and the details about how to track and manage content delivery. Send a <code>POST</code> request to the <code>/<i>CloudFront API version</i>/distribution</code>/<code>distribution ID</code> resource.</p> <important> <p>When you update a distribution, there are more required fields than when you create a distribution. When you update your distribution by using <a href="https://docs.aws.amazon.com/cloudfront/latest/APIReference/API_UpdateDistribution.html">UpdateDistribution</a>, follow the steps included in the documentation to get the current configuration and then make your updates. This helps to make sure that you include all of the required fields. To view a summary, see <a href="https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-overview-required-fields.html">Required Fields for Create Distribution and Update Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> </important>
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
  var valid_613285 = header.getOrDefault("X-Amz-Signature")
  valid_613285 = validateParameter(valid_613285, JString, required = false,
                                 default = nil)
  if valid_613285 != nil:
    section.add "X-Amz-Signature", valid_613285
  var valid_613286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613286 = validateParameter(valid_613286, JString, required = false,
                                 default = nil)
  if valid_613286 != nil:
    section.add "X-Amz-Content-Sha256", valid_613286
  var valid_613287 = header.getOrDefault("X-Amz-Date")
  valid_613287 = validateParameter(valid_613287, JString, required = false,
                                 default = nil)
  if valid_613287 != nil:
    section.add "X-Amz-Date", valid_613287
  var valid_613288 = header.getOrDefault("X-Amz-Credential")
  valid_613288 = validateParameter(valid_613288, JString, required = false,
                                 default = nil)
  if valid_613288 != nil:
    section.add "X-Amz-Credential", valid_613288
  var valid_613289 = header.getOrDefault("X-Amz-Security-Token")
  valid_613289 = validateParameter(valid_613289, JString, required = false,
                                 default = nil)
  if valid_613289 != nil:
    section.add "X-Amz-Security-Token", valid_613289
  var valid_613290 = header.getOrDefault("X-Amz-Algorithm")
  valid_613290 = validateParameter(valid_613290, JString, required = false,
                                 default = nil)
  if valid_613290 != nil:
    section.add "X-Amz-Algorithm", valid_613290
  var valid_613291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613291 = validateParameter(valid_613291, JString, required = false,
                                 default = nil)
  if valid_613291 != nil:
    section.add "X-Amz-SignedHeaders", valid_613291
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613293: Call_CreateDistribution20190326_613282; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new web distribution. You create a CloudFront distribution to tell CloudFront where you want content to be delivered from, and the details about how to track and manage content delivery. Send a <code>POST</code> request to the <code>/<i>CloudFront API version</i>/distribution</code>/<code>distribution ID</code> resource.</p> <important> <p>When you update a distribution, there are more required fields than when you create a distribution. When you update your distribution by using <a href="https://docs.aws.amazon.com/cloudfront/latest/APIReference/API_UpdateDistribution.html">UpdateDistribution</a>, follow the steps included in the documentation to get the current configuration and then make your updates. This helps to make sure that you include all of the required fields. To view a summary, see <a href="https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-overview-required-fields.html">Required Fields for Create Distribution and Update Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> </important>
  ## 
  let valid = call_613293.validator(path, query, header, formData, body)
  let scheme = call_613293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613293.url(scheme.get, call_613293.host, call_613293.base,
                         call_613293.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613293, url, valid)

proc call*(call_613294: Call_CreateDistribution20190326_613282; body: JsonNode): Recallable =
  ## createDistribution20190326
  ## <p>Creates a new web distribution. You create a CloudFront distribution to tell CloudFront where you want content to be delivered from, and the details about how to track and manage content delivery. Send a <code>POST</code> request to the <code>/<i>CloudFront API version</i>/distribution</code>/<code>distribution ID</code> resource.</p> <important> <p>When you update a distribution, there are more required fields than when you create a distribution. When you update your distribution by using <a href="https://docs.aws.amazon.com/cloudfront/latest/APIReference/API_UpdateDistribution.html">UpdateDistribution</a>, follow the steps included in the documentation to get the current configuration and then make your updates. This helps to make sure that you include all of the required fields. To view a summary, see <a href="https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-overview-required-fields.html">Required Fields for Create Distribution and Update Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> </important>
  ##   body: JObject (required)
  var body_613295 = newJObject()
  if body != nil:
    body_613295 = body
  result = call_613294.call(nil, nil, nil, nil, body_613295)

var createDistribution20190326* = Call_CreateDistribution20190326_613282(
    name: "createDistribution20190326", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com", route: "/2019-03-26/distribution",
    validator: validate_CreateDistribution20190326_613283, base: "/",
    url: url_CreateDistribution20190326_613284,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDistributions20190326_613267 = ref object of OpenApiRestCall_612658
proc url_ListDistributions20190326_613269(protocol: Scheme; host: string;
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

proc validate_ListDistributions20190326_613268(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List CloudFront distributions.
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
  var valid_613270 = query.getOrDefault("Marker")
  valid_613270 = validateParameter(valid_613270, JString, required = false,
                                 default = nil)
  if valid_613270 != nil:
    section.add "Marker", valid_613270
  var valid_613271 = query.getOrDefault("MaxItems")
  valid_613271 = validateParameter(valid_613271, JString, required = false,
                                 default = nil)
  if valid_613271 != nil:
    section.add "MaxItems", valid_613271
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
  var valid_613272 = header.getOrDefault("X-Amz-Signature")
  valid_613272 = validateParameter(valid_613272, JString, required = false,
                                 default = nil)
  if valid_613272 != nil:
    section.add "X-Amz-Signature", valid_613272
  var valid_613273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613273 = validateParameter(valid_613273, JString, required = false,
                                 default = nil)
  if valid_613273 != nil:
    section.add "X-Amz-Content-Sha256", valid_613273
  var valid_613274 = header.getOrDefault("X-Amz-Date")
  valid_613274 = validateParameter(valid_613274, JString, required = false,
                                 default = nil)
  if valid_613274 != nil:
    section.add "X-Amz-Date", valid_613274
  var valid_613275 = header.getOrDefault("X-Amz-Credential")
  valid_613275 = validateParameter(valid_613275, JString, required = false,
                                 default = nil)
  if valid_613275 != nil:
    section.add "X-Amz-Credential", valid_613275
  var valid_613276 = header.getOrDefault("X-Amz-Security-Token")
  valid_613276 = validateParameter(valid_613276, JString, required = false,
                                 default = nil)
  if valid_613276 != nil:
    section.add "X-Amz-Security-Token", valid_613276
  var valid_613277 = header.getOrDefault("X-Amz-Algorithm")
  valid_613277 = validateParameter(valid_613277, JString, required = false,
                                 default = nil)
  if valid_613277 != nil:
    section.add "X-Amz-Algorithm", valid_613277
  var valid_613278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613278 = validateParameter(valid_613278, JString, required = false,
                                 default = nil)
  if valid_613278 != nil:
    section.add "X-Amz-SignedHeaders", valid_613278
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613279: Call_ListDistributions20190326_613267; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List CloudFront distributions.
  ## 
  let valid = call_613279.validator(path, query, header, formData, body)
  let scheme = call_613279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613279.url(scheme.get, call_613279.host, call_613279.base,
                         call_613279.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613279, url, valid)

proc call*(call_613280: Call_ListDistributions20190326_613267; Marker: string = "";
          MaxItems: string = ""): Recallable =
  ## listDistributions20190326
  ## List CloudFront distributions.
  ##   Marker: string
  ##         : Use this when paginating results to indicate where to begin in your list of distributions. The results include distributions in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last distribution on that page).
  ##   MaxItems: string
  ##           : The maximum number of distributions you want in the response body.
  var query_613281 = newJObject()
  add(query_613281, "Marker", newJString(Marker))
  add(query_613281, "MaxItems", newJString(MaxItems))
  result = call_613280.call(nil, query_613281, nil, nil, nil)

var listDistributions20190326* = Call_ListDistributions20190326_613267(
    name: "listDistributions20190326", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2019-03-26/distribution",
    validator: validate_ListDistributions20190326_613268, base: "/",
    url: url_ListDistributions20190326_613269,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDistributionWithTags20190326_613296 = ref object of OpenApiRestCall_612658
proc url_CreateDistributionWithTags20190326_613298(protocol: Scheme; host: string;
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

proc validate_CreateDistributionWithTags20190326_613297(path: JsonNode;
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
  var valid_613299 = query.getOrDefault("WithTags")
  valid_613299 = validateParameter(valid_613299, JBool, required = true, default = nil)
  if valid_613299 != nil:
    section.add "WithTags", valid_613299
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
  var valid_613300 = header.getOrDefault("X-Amz-Signature")
  valid_613300 = validateParameter(valid_613300, JString, required = false,
                                 default = nil)
  if valid_613300 != nil:
    section.add "X-Amz-Signature", valid_613300
  var valid_613301 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613301 = validateParameter(valid_613301, JString, required = false,
                                 default = nil)
  if valid_613301 != nil:
    section.add "X-Amz-Content-Sha256", valid_613301
  var valid_613302 = header.getOrDefault("X-Amz-Date")
  valid_613302 = validateParameter(valid_613302, JString, required = false,
                                 default = nil)
  if valid_613302 != nil:
    section.add "X-Amz-Date", valid_613302
  var valid_613303 = header.getOrDefault("X-Amz-Credential")
  valid_613303 = validateParameter(valid_613303, JString, required = false,
                                 default = nil)
  if valid_613303 != nil:
    section.add "X-Amz-Credential", valid_613303
  var valid_613304 = header.getOrDefault("X-Amz-Security-Token")
  valid_613304 = validateParameter(valid_613304, JString, required = false,
                                 default = nil)
  if valid_613304 != nil:
    section.add "X-Amz-Security-Token", valid_613304
  var valid_613305 = header.getOrDefault("X-Amz-Algorithm")
  valid_613305 = validateParameter(valid_613305, JString, required = false,
                                 default = nil)
  if valid_613305 != nil:
    section.add "X-Amz-Algorithm", valid_613305
  var valid_613306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613306 = validateParameter(valid_613306, JString, required = false,
                                 default = nil)
  if valid_613306 != nil:
    section.add "X-Amz-SignedHeaders", valid_613306
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613308: Call_CreateDistributionWithTags20190326_613296;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Create a new distribution with tags.
  ## 
  let valid = call_613308.validator(path, query, header, formData, body)
  let scheme = call_613308.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613308.url(scheme.get, call_613308.host, call_613308.base,
                         call_613308.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613308, url, valid)

proc call*(call_613309: Call_CreateDistributionWithTags20190326_613296;
          body: JsonNode; WithTags: bool): Recallable =
  ## createDistributionWithTags20190326
  ## Create a new distribution with tags.
  ##   body: JObject (required)
  ##   WithTags: bool (required)
  var query_613310 = newJObject()
  var body_613311 = newJObject()
  if body != nil:
    body_613311 = body
  add(query_613310, "WithTags", newJBool(WithTags))
  result = call_613309.call(nil, query_613310, nil, nil, body_613311)

var createDistributionWithTags20190326* = Call_CreateDistributionWithTags20190326_613296(
    name: "createDistributionWithTags20190326", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com", route: "/2019-03-26/distribution#WithTags",
    validator: validate_CreateDistributionWithTags20190326_613297, base: "/",
    url: url_CreateDistributionWithTags20190326_613298,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFieldLevelEncryptionConfig20190326_613327 = ref object of OpenApiRestCall_612658
proc url_CreateFieldLevelEncryptionConfig20190326_613329(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateFieldLevelEncryptionConfig20190326_613328(path: JsonNode;
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
  var valid_613330 = header.getOrDefault("X-Amz-Signature")
  valid_613330 = validateParameter(valid_613330, JString, required = false,
                                 default = nil)
  if valid_613330 != nil:
    section.add "X-Amz-Signature", valid_613330
  var valid_613331 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613331 = validateParameter(valid_613331, JString, required = false,
                                 default = nil)
  if valid_613331 != nil:
    section.add "X-Amz-Content-Sha256", valid_613331
  var valid_613332 = header.getOrDefault("X-Amz-Date")
  valid_613332 = validateParameter(valid_613332, JString, required = false,
                                 default = nil)
  if valid_613332 != nil:
    section.add "X-Amz-Date", valid_613332
  var valid_613333 = header.getOrDefault("X-Amz-Credential")
  valid_613333 = validateParameter(valid_613333, JString, required = false,
                                 default = nil)
  if valid_613333 != nil:
    section.add "X-Amz-Credential", valid_613333
  var valid_613334 = header.getOrDefault("X-Amz-Security-Token")
  valid_613334 = validateParameter(valid_613334, JString, required = false,
                                 default = nil)
  if valid_613334 != nil:
    section.add "X-Amz-Security-Token", valid_613334
  var valid_613335 = header.getOrDefault("X-Amz-Algorithm")
  valid_613335 = validateParameter(valid_613335, JString, required = false,
                                 default = nil)
  if valid_613335 != nil:
    section.add "X-Amz-Algorithm", valid_613335
  var valid_613336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613336 = validateParameter(valid_613336, JString, required = false,
                                 default = nil)
  if valid_613336 != nil:
    section.add "X-Amz-SignedHeaders", valid_613336
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613338: Call_CreateFieldLevelEncryptionConfig20190326_613327;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Create a new field-level encryption configuration.
  ## 
  let valid = call_613338.validator(path, query, header, formData, body)
  let scheme = call_613338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613338.url(scheme.get, call_613338.host, call_613338.base,
                         call_613338.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613338, url, valid)

proc call*(call_613339: Call_CreateFieldLevelEncryptionConfig20190326_613327;
          body: JsonNode): Recallable =
  ## createFieldLevelEncryptionConfig20190326
  ## Create a new field-level encryption configuration.
  ##   body: JObject (required)
  var body_613340 = newJObject()
  if body != nil:
    body_613340 = body
  result = call_613339.call(nil, nil, nil, nil, body_613340)

var createFieldLevelEncryptionConfig20190326* = Call_CreateFieldLevelEncryptionConfig20190326_613327(
    name: "createFieldLevelEncryptionConfig20190326", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com", route: "/2019-03-26/field-level-encryption",
    validator: validate_CreateFieldLevelEncryptionConfig20190326_613328,
    base: "/", url: url_CreateFieldLevelEncryptionConfig20190326_613329,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFieldLevelEncryptionConfigs20190326_613312 = ref object of OpenApiRestCall_612658
proc url_ListFieldLevelEncryptionConfigs20190326_613314(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListFieldLevelEncryptionConfigs20190326_613313(path: JsonNode;
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
  var valid_613315 = query.getOrDefault("Marker")
  valid_613315 = validateParameter(valid_613315, JString, required = false,
                                 default = nil)
  if valid_613315 != nil:
    section.add "Marker", valid_613315
  var valid_613316 = query.getOrDefault("MaxItems")
  valid_613316 = validateParameter(valid_613316, JString, required = false,
                                 default = nil)
  if valid_613316 != nil:
    section.add "MaxItems", valid_613316
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
  var valid_613317 = header.getOrDefault("X-Amz-Signature")
  valid_613317 = validateParameter(valid_613317, JString, required = false,
                                 default = nil)
  if valid_613317 != nil:
    section.add "X-Amz-Signature", valid_613317
  var valid_613318 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613318 = validateParameter(valid_613318, JString, required = false,
                                 default = nil)
  if valid_613318 != nil:
    section.add "X-Amz-Content-Sha256", valid_613318
  var valid_613319 = header.getOrDefault("X-Amz-Date")
  valid_613319 = validateParameter(valid_613319, JString, required = false,
                                 default = nil)
  if valid_613319 != nil:
    section.add "X-Amz-Date", valid_613319
  var valid_613320 = header.getOrDefault("X-Amz-Credential")
  valid_613320 = validateParameter(valid_613320, JString, required = false,
                                 default = nil)
  if valid_613320 != nil:
    section.add "X-Amz-Credential", valid_613320
  var valid_613321 = header.getOrDefault("X-Amz-Security-Token")
  valid_613321 = validateParameter(valid_613321, JString, required = false,
                                 default = nil)
  if valid_613321 != nil:
    section.add "X-Amz-Security-Token", valid_613321
  var valid_613322 = header.getOrDefault("X-Amz-Algorithm")
  valid_613322 = validateParameter(valid_613322, JString, required = false,
                                 default = nil)
  if valid_613322 != nil:
    section.add "X-Amz-Algorithm", valid_613322
  var valid_613323 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613323 = validateParameter(valid_613323, JString, required = false,
                                 default = nil)
  if valid_613323 != nil:
    section.add "X-Amz-SignedHeaders", valid_613323
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613324: Call_ListFieldLevelEncryptionConfigs20190326_613312;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## List all field-level encryption configurations that have been created in CloudFront for this account.
  ## 
  let valid = call_613324.validator(path, query, header, formData, body)
  let scheme = call_613324.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613324.url(scheme.get, call_613324.host, call_613324.base,
                         call_613324.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613324, url, valid)

proc call*(call_613325: Call_ListFieldLevelEncryptionConfigs20190326_613312;
          Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listFieldLevelEncryptionConfigs20190326
  ## List all field-level encryption configurations that have been created in CloudFront for this account.
  ##   Marker: string
  ##         : Use this when paginating results to indicate where to begin in your list of configurations. The results include configurations in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last configuration on that page). 
  ##   MaxItems: string
  ##           : The maximum number of field-level encryption configurations you want in the response body. 
  var query_613326 = newJObject()
  add(query_613326, "Marker", newJString(Marker))
  add(query_613326, "MaxItems", newJString(MaxItems))
  result = call_613325.call(nil, query_613326, nil, nil, nil)

var listFieldLevelEncryptionConfigs20190326* = Call_ListFieldLevelEncryptionConfigs20190326_613312(
    name: "listFieldLevelEncryptionConfigs20190326", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2019-03-26/field-level-encryption",
    validator: validate_ListFieldLevelEncryptionConfigs20190326_613313, base: "/",
    url: url_ListFieldLevelEncryptionConfigs20190326_613314,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFieldLevelEncryptionProfile20190326_613356 = ref object of OpenApiRestCall_612658
proc url_CreateFieldLevelEncryptionProfile20190326_613358(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateFieldLevelEncryptionProfile20190326_613357(path: JsonNode;
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
  var valid_613359 = header.getOrDefault("X-Amz-Signature")
  valid_613359 = validateParameter(valid_613359, JString, required = false,
                                 default = nil)
  if valid_613359 != nil:
    section.add "X-Amz-Signature", valid_613359
  var valid_613360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613360 = validateParameter(valid_613360, JString, required = false,
                                 default = nil)
  if valid_613360 != nil:
    section.add "X-Amz-Content-Sha256", valid_613360
  var valid_613361 = header.getOrDefault("X-Amz-Date")
  valid_613361 = validateParameter(valid_613361, JString, required = false,
                                 default = nil)
  if valid_613361 != nil:
    section.add "X-Amz-Date", valid_613361
  var valid_613362 = header.getOrDefault("X-Amz-Credential")
  valid_613362 = validateParameter(valid_613362, JString, required = false,
                                 default = nil)
  if valid_613362 != nil:
    section.add "X-Amz-Credential", valid_613362
  var valid_613363 = header.getOrDefault("X-Amz-Security-Token")
  valid_613363 = validateParameter(valid_613363, JString, required = false,
                                 default = nil)
  if valid_613363 != nil:
    section.add "X-Amz-Security-Token", valid_613363
  var valid_613364 = header.getOrDefault("X-Amz-Algorithm")
  valid_613364 = validateParameter(valid_613364, JString, required = false,
                                 default = nil)
  if valid_613364 != nil:
    section.add "X-Amz-Algorithm", valid_613364
  var valid_613365 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613365 = validateParameter(valid_613365, JString, required = false,
                                 default = nil)
  if valid_613365 != nil:
    section.add "X-Amz-SignedHeaders", valid_613365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613367: Call_CreateFieldLevelEncryptionProfile20190326_613356;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Create a field-level encryption profile.
  ## 
  let valid = call_613367.validator(path, query, header, formData, body)
  let scheme = call_613367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613367.url(scheme.get, call_613367.host, call_613367.base,
                         call_613367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613367, url, valid)

proc call*(call_613368: Call_CreateFieldLevelEncryptionProfile20190326_613356;
          body: JsonNode): Recallable =
  ## createFieldLevelEncryptionProfile20190326
  ## Create a field-level encryption profile.
  ##   body: JObject (required)
  var body_613369 = newJObject()
  if body != nil:
    body_613369 = body
  result = call_613368.call(nil, nil, nil, nil, body_613369)

var createFieldLevelEncryptionProfile20190326* = Call_CreateFieldLevelEncryptionProfile20190326_613356(
    name: "createFieldLevelEncryptionProfile20190326", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/field-level-encryption-profile",
    validator: validate_CreateFieldLevelEncryptionProfile20190326_613357,
    base: "/", url: url_CreateFieldLevelEncryptionProfile20190326_613358,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFieldLevelEncryptionProfiles20190326_613341 = ref object of OpenApiRestCall_612658
proc url_ListFieldLevelEncryptionProfiles20190326_613343(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListFieldLevelEncryptionProfiles20190326_613342(path: JsonNode;
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
  var valid_613344 = query.getOrDefault("Marker")
  valid_613344 = validateParameter(valid_613344, JString, required = false,
                                 default = nil)
  if valid_613344 != nil:
    section.add "Marker", valid_613344
  var valid_613345 = query.getOrDefault("MaxItems")
  valid_613345 = validateParameter(valid_613345, JString, required = false,
                                 default = nil)
  if valid_613345 != nil:
    section.add "MaxItems", valid_613345
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
  var valid_613346 = header.getOrDefault("X-Amz-Signature")
  valid_613346 = validateParameter(valid_613346, JString, required = false,
                                 default = nil)
  if valid_613346 != nil:
    section.add "X-Amz-Signature", valid_613346
  var valid_613347 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613347 = validateParameter(valid_613347, JString, required = false,
                                 default = nil)
  if valid_613347 != nil:
    section.add "X-Amz-Content-Sha256", valid_613347
  var valid_613348 = header.getOrDefault("X-Amz-Date")
  valid_613348 = validateParameter(valid_613348, JString, required = false,
                                 default = nil)
  if valid_613348 != nil:
    section.add "X-Amz-Date", valid_613348
  var valid_613349 = header.getOrDefault("X-Amz-Credential")
  valid_613349 = validateParameter(valid_613349, JString, required = false,
                                 default = nil)
  if valid_613349 != nil:
    section.add "X-Amz-Credential", valid_613349
  var valid_613350 = header.getOrDefault("X-Amz-Security-Token")
  valid_613350 = validateParameter(valid_613350, JString, required = false,
                                 default = nil)
  if valid_613350 != nil:
    section.add "X-Amz-Security-Token", valid_613350
  var valid_613351 = header.getOrDefault("X-Amz-Algorithm")
  valid_613351 = validateParameter(valid_613351, JString, required = false,
                                 default = nil)
  if valid_613351 != nil:
    section.add "X-Amz-Algorithm", valid_613351
  var valid_613352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613352 = validateParameter(valid_613352, JString, required = false,
                                 default = nil)
  if valid_613352 != nil:
    section.add "X-Amz-SignedHeaders", valid_613352
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613353: Call_ListFieldLevelEncryptionProfiles20190326_613341;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Request a list of field-level encryption profiles that have been created in CloudFront for this account.
  ## 
  let valid = call_613353.validator(path, query, header, formData, body)
  let scheme = call_613353.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613353.url(scheme.get, call_613353.host, call_613353.base,
                         call_613353.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613353, url, valid)

proc call*(call_613354: Call_ListFieldLevelEncryptionProfiles20190326_613341;
          Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listFieldLevelEncryptionProfiles20190326
  ## Request a list of field-level encryption profiles that have been created in CloudFront for this account.
  ##   Marker: string
  ##         : Use this when paginating results to indicate where to begin in your list of profiles. The results include profiles in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last profile on that page). 
  ##   MaxItems: string
  ##           : The maximum number of field-level encryption profiles you want in the response body. 
  var query_613355 = newJObject()
  add(query_613355, "Marker", newJString(Marker))
  add(query_613355, "MaxItems", newJString(MaxItems))
  result = call_613354.call(nil, query_613355, nil, nil, nil)

var listFieldLevelEncryptionProfiles20190326* = Call_ListFieldLevelEncryptionProfiles20190326_613341(
    name: "listFieldLevelEncryptionProfiles20190326", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/field-level-encryption-profile",
    validator: validate_ListFieldLevelEncryptionProfiles20190326_613342,
    base: "/", url: url_ListFieldLevelEncryptionProfiles20190326_613343,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInvalidation20190326_613401 = ref object of OpenApiRestCall_612658
proc url_CreateInvalidation20190326_613403(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DistributionId" in path, "`DistributionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2019-03-26/distribution/"),
               (kind: VariableSegment, value: "DistributionId"),
               (kind: ConstantSegment, value: "/invalidation")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateInvalidation20190326_613402(path: JsonNode; query: JsonNode;
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
  var valid_613404 = path.getOrDefault("DistributionId")
  valid_613404 = validateParameter(valid_613404, JString, required = true,
                                 default = nil)
  if valid_613404 != nil:
    section.add "DistributionId", valid_613404
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
  var valid_613405 = header.getOrDefault("X-Amz-Signature")
  valid_613405 = validateParameter(valid_613405, JString, required = false,
                                 default = nil)
  if valid_613405 != nil:
    section.add "X-Amz-Signature", valid_613405
  var valid_613406 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613406 = validateParameter(valid_613406, JString, required = false,
                                 default = nil)
  if valid_613406 != nil:
    section.add "X-Amz-Content-Sha256", valid_613406
  var valid_613407 = header.getOrDefault("X-Amz-Date")
  valid_613407 = validateParameter(valid_613407, JString, required = false,
                                 default = nil)
  if valid_613407 != nil:
    section.add "X-Amz-Date", valid_613407
  var valid_613408 = header.getOrDefault("X-Amz-Credential")
  valid_613408 = validateParameter(valid_613408, JString, required = false,
                                 default = nil)
  if valid_613408 != nil:
    section.add "X-Amz-Credential", valid_613408
  var valid_613409 = header.getOrDefault("X-Amz-Security-Token")
  valid_613409 = validateParameter(valid_613409, JString, required = false,
                                 default = nil)
  if valid_613409 != nil:
    section.add "X-Amz-Security-Token", valid_613409
  var valid_613410 = header.getOrDefault("X-Amz-Algorithm")
  valid_613410 = validateParameter(valid_613410, JString, required = false,
                                 default = nil)
  if valid_613410 != nil:
    section.add "X-Amz-Algorithm", valid_613410
  var valid_613411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613411 = validateParameter(valid_613411, JString, required = false,
                                 default = nil)
  if valid_613411 != nil:
    section.add "X-Amz-SignedHeaders", valid_613411
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613413: Call_CreateInvalidation20190326_613401; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new invalidation. 
  ## 
  let valid = call_613413.validator(path, query, header, formData, body)
  let scheme = call_613413.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613413.url(scheme.get, call_613413.host, call_613413.base,
                         call_613413.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613413, url, valid)

proc call*(call_613414: Call_CreateInvalidation20190326_613401;
          DistributionId: string; body: JsonNode): Recallable =
  ## createInvalidation20190326
  ## Create a new invalidation. 
  ##   DistributionId: string (required)
  ##                 : The distribution's id.
  ##   body: JObject (required)
  var path_613415 = newJObject()
  var body_613416 = newJObject()
  add(path_613415, "DistributionId", newJString(DistributionId))
  if body != nil:
    body_613416 = body
  result = call_613414.call(path_613415, nil, nil, nil, body_613416)

var createInvalidation20190326* = Call_CreateInvalidation20190326_613401(
    name: "createInvalidation20190326", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/distribution/{DistributionId}/invalidation",
    validator: validate_CreateInvalidation20190326_613402, base: "/",
    url: url_CreateInvalidation20190326_613403,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInvalidations20190326_613370 = ref object of OpenApiRestCall_612658
proc url_ListInvalidations20190326_613372(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DistributionId" in path, "`DistributionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2019-03-26/distribution/"),
               (kind: VariableSegment, value: "DistributionId"),
               (kind: ConstantSegment, value: "/invalidation")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListInvalidations20190326_613371(path: JsonNode; query: JsonNode;
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
  var valid_613387 = path.getOrDefault("DistributionId")
  valid_613387 = validateParameter(valid_613387, JString, required = true,
                                 default = nil)
  if valid_613387 != nil:
    section.add "DistributionId", valid_613387
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Use this parameter when paginating results to indicate where to begin in your list of invalidation batches. Because the results are returned in decreasing order from most recent to oldest, the most recent results are on the first page, the second page will contain earlier results, and so on. To get the next page of results, set <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response. This value is the same as the ID of the last invalidation batch on that page. 
  ##   MaxItems: JString
  ##           : The maximum number of invalidation batches that you want in the response body.
  section = newJObject()
  var valid_613388 = query.getOrDefault("Marker")
  valid_613388 = validateParameter(valid_613388, JString, required = false,
                                 default = nil)
  if valid_613388 != nil:
    section.add "Marker", valid_613388
  var valid_613389 = query.getOrDefault("MaxItems")
  valid_613389 = validateParameter(valid_613389, JString, required = false,
                                 default = nil)
  if valid_613389 != nil:
    section.add "MaxItems", valid_613389
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
  var valid_613390 = header.getOrDefault("X-Amz-Signature")
  valid_613390 = validateParameter(valid_613390, JString, required = false,
                                 default = nil)
  if valid_613390 != nil:
    section.add "X-Amz-Signature", valid_613390
  var valid_613391 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613391 = validateParameter(valid_613391, JString, required = false,
                                 default = nil)
  if valid_613391 != nil:
    section.add "X-Amz-Content-Sha256", valid_613391
  var valid_613392 = header.getOrDefault("X-Amz-Date")
  valid_613392 = validateParameter(valid_613392, JString, required = false,
                                 default = nil)
  if valid_613392 != nil:
    section.add "X-Amz-Date", valid_613392
  var valid_613393 = header.getOrDefault("X-Amz-Credential")
  valid_613393 = validateParameter(valid_613393, JString, required = false,
                                 default = nil)
  if valid_613393 != nil:
    section.add "X-Amz-Credential", valid_613393
  var valid_613394 = header.getOrDefault("X-Amz-Security-Token")
  valid_613394 = validateParameter(valid_613394, JString, required = false,
                                 default = nil)
  if valid_613394 != nil:
    section.add "X-Amz-Security-Token", valid_613394
  var valid_613395 = header.getOrDefault("X-Amz-Algorithm")
  valid_613395 = validateParameter(valid_613395, JString, required = false,
                                 default = nil)
  if valid_613395 != nil:
    section.add "X-Amz-Algorithm", valid_613395
  var valid_613396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613396 = validateParameter(valid_613396, JString, required = false,
                                 default = nil)
  if valid_613396 != nil:
    section.add "X-Amz-SignedHeaders", valid_613396
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613397: Call_ListInvalidations20190326_613370; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists invalidation batches. 
  ## 
  let valid = call_613397.validator(path, query, header, formData, body)
  let scheme = call_613397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613397.url(scheme.get, call_613397.host, call_613397.base,
                         call_613397.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613397, url, valid)

proc call*(call_613398: Call_ListInvalidations20190326_613370;
          DistributionId: string; Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listInvalidations20190326
  ## Lists invalidation batches. 
  ##   Marker: string
  ##         : Use this parameter when paginating results to indicate where to begin in your list of invalidation batches. Because the results are returned in decreasing order from most recent to oldest, the most recent results are on the first page, the second page will contain earlier results, and so on. To get the next page of results, set <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response. This value is the same as the ID of the last invalidation batch on that page. 
  ##   MaxItems: string
  ##           : The maximum number of invalidation batches that you want in the response body.
  ##   DistributionId: string (required)
  ##                 : The distribution's ID.
  var path_613399 = newJObject()
  var query_613400 = newJObject()
  add(query_613400, "Marker", newJString(Marker))
  add(query_613400, "MaxItems", newJString(MaxItems))
  add(path_613399, "DistributionId", newJString(DistributionId))
  result = call_613398.call(path_613399, query_613400, nil, nil, nil)

var listInvalidations20190326* = Call_ListInvalidations20190326_613370(
    name: "listInvalidations20190326", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/distribution/{DistributionId}/invalidation",
    validator: validate_ListInvalidations20190326_613371, base: "/",
    url: url_ListInvalidations20190326_613372,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePublicKey20190326_613432 = ref object of OpenApiRestCall_612658
proc url_CreatePublicKey20190326_613434(protocol: Scheme; host: string; base: string;
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

proc validate_CreatePublicKey20190326_613433(path: JsonNode; query: JsonNode;
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
  var valid_613435 = header.getOrDefault("X-Amz-Signature")
  valid_613435 = validateParameter(valid_613435, JString, required = false,
                                 default = nil)
  if valid_613435 != nil:
    section.add "X-Amz-Signature", valid_613435
  var valid_613436 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613436 = validateParameter(valid_613436, JString, required = false,
                                 default = nil)
  if valid_613436 != nil:
    section.add "X-Amz-Content-Sha256", valid_613436
  var valid_613437 = header.getOrDefault("X-Amz-Date")
  valid_613437 = validateParameter(valid_613437, JString, required = false,
                                 default = nil)
  if valid_613437 != nil:
    section.add "X-Amz-Date", valid_613437
  var valid_613438 = header.getOrDefault("X-Amz-Credential")
  valid_613438 = validateParameter(valid_613438, JString, required = false,
                                 default = nil)
  if valid_613438 != nil:
    section.add "X-Amz-Credential", valid_613438
  var valid_613439 = header.getOrDefault("X-Amz-Security-Token")
  valid_613439 = validateParameter(valid_613439, JString, required = false,
                                 default = nil)
  if valid_613439 != nil:
    section.add "X-Amz-Security-Token", valid_613439
  var valid_613440 = header.getOrDefault("X-Amz-Algorithm")
  valid_613440 = validateParameter(valid_613440, JString, required = false,
                                 default = nil)
  if valid_613440 != nil:
    section.add "X-Amz-Algorithm", valid_613440
  var valid_613441 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613441 = validateParameter(valid_613441, JString, required = false,
                                 default = nil)
  if valid_613441 != nil:
    section.add "X-Amz-SignedHeaders", valid_613441
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613443: Call_CreatePublicKey20190326_613432; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Add a new public key to CloudFront to use, for example, for field-level encryption. You can add a maximum of 10 public keys with one AWS account.
  ## 
  let valid = call_613443.validator(path, query, header, formData, body)
  let scheme = call_613443.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613443.url(scheme.get, call_613443.host, call_613443.base,
                         call_613443.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613443, url, valid)

proc call*(call_613444: Call_CreatePublicKey20190326_613432; body: JsonNode): Recallable =
  ## createPublicKey20190326
  ## Add a new public key to CloudFront to use, for example, for field-level encryption. You can add a maximum of 10 public keys with one AWS account.
  ##   body: JObject (required)
  var body_613445 = newJObject()
  if body != nil:
    body_613445 = body
  result = call_613444.call(nil, nil, nil, nil, body_613445)

var createPublicKey20190326* = Call_CreatePublicKey20190326_613432(
    name: "createPublicKey20190326", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com", route: "/2019-03-26/public-key",
    validator: validate_CreatePublicKey20190326_613433, base: "/",
    url: url_CreatePublicKey20190326_613434, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPublicKeys20190326_613417 = ref object of OpenApiRestCall_612658
proc url_ListPublicKeys20190326_613419(protocol: Scheme; host: string; base: string;
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

proc validate_ListPublicKeys20190326_613418(path: JsonNode; query: JsonNode;
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
  var valid_613420 = query.getOrDefault("Marker")
  valid_613420 = validateParameter(valid_613420, JString, required = false,
                                 default = nil)
  if valid_613420 != nil:
    section.add "Marker", valid_613420
  var valid_613421 = query.getOrDefault("MaxItems")
  valid_613421 = validateParameter(valid_613421, JString, required = false,
                                 default = nil)
  if valid_613421 != nil:
    section.add "MaxItems", valid_613421
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
  var valid_613422 = header.getOrDefault("X-Amz-Signature")
  valid_613422 = validateParameter(valid_613422, JString, required = false,
                                 default = nil)
  if valid_613422 != nil:
    section.add "X-Amz-Signature", valid_613422
  var valid_613423 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613423 = validateParameter(valid_613423, JString, required = false,
                                 default = nil)
  if valid_613423 != nil:
    section.add "X-Amz-Content-Sha256", valid_613423
  var valid_613424 = header.getOrDefault("X-Amz-Date")
  valid_613424 = validateParameter(valid_613424, JString, required = false,
                                 default = nil)
  if valid_613424 != nil:
    section.add "X-Amz-Date", valid_613424
  var valid_613425 = header.getOrDefault("X-Amz-Credential")
  valid_613425 = validateParameter(valid_613425, JString, required = false,
                                 default = nil)
  if valid_613425 != nil:
    section.add "X-Amz-Credential", valid_613425
  var valid_613426 = header.getOrDefault("X-Amz-Security-Token")
  valid_613426 = validateParameter(valid_613426, JString, required = false,
                                 default = nil)
  if valid_613426 != nil:
    section.add "X-Amz-Security-Token", valid_613426
  var valid_613427 = header.getOrDefault("X-Amz-Algorithm")
  valid_613427 = validateParameter(valid_613427, JString, required = false,
                                 default = nil)
  if valid_613427 != nil:
    section.add "X-Amz-Algorithm", valid_613427
  var valid_613428 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613428 = validateParameter(valid_613428, JString, required = false,
                                 default = nil)
  if valid_613428 != nil:
    section.add "X-Amz-SignedHeaders", valid_613428
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613429: Call_ListPublicKeys20190326_613417; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all public keys that have been added to CloudFront for this account.
  ## 
  let valid = call_613429.validator(path, query, header, formData, body)
  let scheme = call_613429.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613429.url(scheme.get, call_613429.host, call_613429.base,
                         call_613429.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613429, url, valid)

proc call*(call_613430: Call_ListPublicKeys20190326_613417; Marker: string = "";
          MaxItems: string = ""): Recallable =
  ## listPublicKeys20190326
  ## List all public keys that have been added to CloudFront for this account.
  ##   Marker: string
  ##         : Use this when paginating results to indicate where to begin in your list of public keys. The results include public keys in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last public key on that page). 
  ##   MaxItems: string
  ##           : The maximum number of public keys you want in the response body. 
  var query_613431 = newJObject()
  add(query_613431, "Marker", newJString(Marker))
  add(query_613431, "MaxItems", newJString(MaxItems))
  result = call_613430.call(nil, query_613431, nil, nil, nil)

var listPublicKeys20190326* = Call_ListPublicKeys20190326_613417(
    name: "listPublicKeys20190326", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2019-03-26/public-key",
    validator: validate_ListPublicKeys20190326_613418, base: "/",
    url: url_ListPublicKeys20190326_613419, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStreamingDistribution20190326_613461 = ref object of OpenApiRestCall_612658
proc url_CreateStreamingDistribution20190326_613463(protocol: Scheme; host: string;
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

proc validate_CreateStreamingDistribution20190326_613462(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new RTMP distribution. An RTMP distribution is similar to a web distribution, but an RTMP distribution streams media files using the Adobe Real-Time Messaging Protocol (RTMP) instead of serving files using HTTP. </p> <p>To create a new distribution, submit a <code>POST</code> request to the <i>CloudFront API version</i>/distribution resource. The request body must include a document with a <i>StreamingDistributionConfig</i> element. The response echoes the <code>StreamingDistributionConfig</code> element and returns other information about the RTMP distribution.</p> <p>To get the status of your request, use the <i>GET StreamingDistribution</i> API action. When the value of <code>Enabled</code> is <code>true</code> and the value of <code>Status</code> is <code>Deployed</code>, your distribution is ready. A distribution usually deploys in less than 15 minutes.</p> <p>For more information about web distributions, see <a href="https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-rtmp.html">Working with RTMP Distributions</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <important> <p>Beginning with the 2012-05-05 version of the CloudFront API, we made substantial changes to the format of the XML document that you include in the request body when you create or update a web distribution or an RTMP distribution, and when you invalidate objects. With previous versions of the API, we discovered that it was too easy to accidentally delete one or more values for an element that accepts multiple values, for example, CNAMEs and trusted signers. Our changes for the 2012-05-05 release are intended to prevent these accidental deletions and to notify you when there's a mismatch between the number of values you say you're specifying in the <code>Quantity</code> element and the number of values specified.</p> </important>
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
  var valid_613464 = header.getOrDefault("X-Amz-Signature")
  valid_613464 = validateParameter(valid_613464, JString, required = false,
                                 default = nil)
  if valid_613464 != nil:
    section.add "X-Amz-Signature", valid_613464
  var valid_613465 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613465 = validateParameter(valid_613465, JString, required = false,
                                 default = nil)
  if valid_613465 != nil:
    section.add "X-Amz-Content-Sha256", valid_613465
  var valid_613466 = header.getOrDefault("X-Amz-Date")
  valid_613466 = validateParameter(valid_613466, JString, required = false,
                                 default = nil)
  if valid_613466 != nil:
    section.add "X-Amz-Date", valid_613466
  var valid_613467 = header.getOrDefault("X-Amz-Credential")
  valid_613467 = validateParameter(valid_613467, JString, required = false,
                                 default = nil)
  if valid_613467 != nil:
    section.add "X-Amz-Credential", valid_613467
  var valid_613468 = header.getOrDefault("X-Amz-Security-Token")
  valid_613468 = validateParameter(valid_613468, JString, required = false,
                                 default = nil)
  if valid_613468 != nil:
    section.add "X-Amz-Security-Token", valid_613468
  var valid_613469 = header.getOrDefault("X-Amz-Algorithm")
  valid_613469 = validateParameter(valid_613469, JString, required = false,
                                 default = nil)
  if valid_613469 != nil:
    section.add "X-Amz-Algorithm", valid_613469
  var valid_613470 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613470 = validateParameter(valid_613470, JString, required = false,
                                 default = nil)
  if valid_613470 != nil:
    section.add "X-Amz-SignedHeaders", valid_613470
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613472: Call_CreateStreamingDistribution20190326_613461;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a new RTMP distribution. An RTMP distribution is similar to a web distribution, but an RTMP distribution streams media files using the Adobe Real-Time Messaging Protocol (RTMP) instead of serving files using HTTP. </p> <p>To create a new distribution, submit a <code>POST</code> request to the <i>CloudFront API version</i>/distribution resource. The request body must include a document with a <i>StreamingDistributionConfig</i> element. The response echoes the <code>StreamingDistributionConfig</code> element and returns other information about the RTMP distribution.</p> <p>To get the status of your request, use the <i>GET StreamingDistribution</i> API action. When the value of <code>Enabled</code> is <code>true</code> and the value of <code>Status</code> is <code>Deployed</code>, your distribution is ready. A distribution usually deploys in less than 15 minutes.</p> <p>For more information about web distributions, see <a href="https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-rtmp.html">Working with RTMP Distributions</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <important> <p>Beginning with the 2012-05-05 version of the CloudFront API, we made substantial changes to the format of the XML document that you include in the request body when you create or update a web distribution or an RTMP distribution, and when you invalidate objects. With previous versions of the API, we discovered that it was too easy to accidentally delete one or more values for an element that accepts multiple values, for example, CNAMEs and trusted signers. Our changes for the 2012-05-05 release are intended to prevent these accidental deletions and to notify you when there's a mismatch between the number of values you say you're specifying in the <code>Quantity</code> element and the number of values specified.</p> </important>
  ## 
  let valid = call_613472.validator(path, query, header, formData, body)
  let scheme = call_613472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613472.url(scheme.get, call_613472.host, call_613472.base,
                         call_613472.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613472, url, valid)

proc call*(call_613473: Call_CreateStreamingDistribution20190326_613461;
          body: JsonNode): Recallable =
  ## createStreamingDistribution20190326
  ## <p>Creates a new RTMP distribution. An RTMP distribution is similar to a web distribution, but an RTMP distribution streams media files using the Adobe Real-Time Messaging Protocol (RTMP) instead of serving files using HTTP. </p> <p>To create a new distribution, submit a <code>POST</code> request to the <i>CloudFront API version</i>/distribution resource. The request body must include a document with a <i>StreamingDistributionConfig</i> element. The response echoes the <code>StreamingDistributionConfig</code> element and returns other information about the RTMP distribution.</p> <p>To get the status of your request, use the <i>GET StreamingDistribution</i> API action. When the value of <code>Enabled</code> is <code>true</code> and the value of <code>Status</code> is <code>Deployed</code>, your distribution is ready. A distribution usually deploys in less than 15 minutes.</p> <p>For more information about web distributions, see <a href="https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-rtmp.html">Working with RTMP Distributions</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <important> <p>Beginning with the 2012-05-05 version of the CloudFront API, we made substantial changes to the format of the XML document that you include in the request body when you create or update a web distribution or an RTMP distribution, and when you invalidate objects. With previous versions of the API, we discovered that it was too easy to accidentally delete one or more values for an element that accepts multiple values, for example, CNAMEs and trusted signers. Our changes for the 2012-05-05 release are intended to prevent these accidental deletions and to notify you when there's a mismatch between the number of values you say you're specifying in the <code>Quantity</code> element and the number of values specified.</p> </important>
  ##   body: JObject (required)
  var body_613474 = newJObject()
  if body != nil:
    body_613474 = body
  result = call_613473.call(nil, nil, nil, nil, body_613474)

var createStreamingDistribution20190326* = Call_CreateStreamingDistribution20190326_613461(
    name: "createStreamingDistribution20190326", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com", route: "/2019-03-26/streaming-distribution",
    validator: validate_CreateStreamingDistribution20190326_613462, base: "/",
    url: url_CreateStreamingDistribution20190326_613463,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListStreamingDistributions20190326_613446 = ref object of OpenApiRestCall_612658
proc url_ListStreamingDistributions20190326_613448(protocol: Scheme; host: string;
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

proc validate_ListStreamingDistributions20190326_613447(path: JsonNode;
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
  var valid_613449 = query.getOrDefault("Marker")
  valid_613449 = validateParameter(valid_613449, JString, required = false,
                                 default = nil)
  if valid_613449 != nil:
    section.add "Marker", valid_613449
  var valid_613450 = query.getOrDefault("MaxItems")
  valid_613450 = validateParameter(valid_613450, JString, required = false,
                                 default = nil)
  if valid_613450 != nil:
    section.add "MaxItems", valid_613450
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
  var valid_613451 = header.getOrDefault("X-Amz-Signature")
  valid_613451 = validateParameter(valid_613451, JString, required = false,
                                 default = nil)
  if valid_613451 != nil:
    section.add "X-Amz-Signature", valid_613451
  var valid_613452 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613452 = validateParameter(valid_613452, JString, required = false,
                                 default = nil)
  if valid_613452 != nil:
    section.add "X-Amz-Content-Sha256", valid_613452
  var valid_613453 = header.getOrDefault("X-Amz-Date")
  valid_613453 = validateParameter(valid_613453, JString, required = false,
                                 default = nil)
  if valid_613453 != nil:
    section.add "X-Amz-Date", valid_613453
  var valid_613454 = header.getOrDefault("X-Amz-Credential")
  valid_613454 = validateParameter(valid_613454, JString, required = false,
                                 default = nil)
  if valid_613454 != nil:
    section.add "X-Amz-Credential", valid_613454
  var valid_613455 = header.getOrDefault("X-Amz-Security-Token")
  valid_613455 = validateParameter(valid_613455, JString, required = false,
                                 default = nil)
  if valid_613455 != nil:
    section.add "X-Amz-Security-Token", valid_613455
  var valid_613456 = header.getOrDefault("X-Amz-Algorithm")
  valid_613456 = validateParameter(valid_613456, JString, required = false,
                                 default = nil)
  if valid_613456 != nil:
    section.add "X-Amz-Algorithm", valid_613456
  var valid_613457 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613457 = validateParameter(valid_613457, JString, required = false,
                                 default = nil)
  if valid_613457 != nil:
    section.add "X-Amz-SignedHeaders", valid_613457
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613458: Call_ListStreamingDistributions20190326_613446;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## List streaming distributions. 
  ## 
  let valid = call_613458.validator(path, query, header, formData, body)
  let scheme = call_613458.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613458.url(scheme.get, call_613458.host, call_613458.base,
                         call_613458.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613458, url, valid)

proc call*(call_613459: Call_ListStreamingDistributions20190326_613446;
          Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listStreamingDistributions20190326
  ## List streaming distributions. 
  ##   Marker: string
  ##         : The value that you provided for the <code>Marker</code> request parameter.
  ##   MaxItems: string
  ##           : The value that you provided for the <code>MaxItems</code> request parameter.
  var query_613460 = newJObject()
  add(query_613460, "Marker", newJString(Marker))
  add(query_613460, "MaxItems", newJString(MaxItems))
  result = call_613459.call(nil, query_613460, nil, nil, nil)

var listStreamingDistributions20190326* = Call_ListStreamingDistributions20190326_613446(
    name: "listStreamingDistributions20190326", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2019-03-26/streaming-distribution",
    validator: validate_ListStreamingDistributions20190326_613447, base: "/",
    url: url_ListStreamingDistributions20190326_613448,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStreamingDistributionWithTags20190326_613475 = ref object of OpenApiRestCall_612658
proc url_CreateStreamingDistributionWithTags20190326_613477(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateStreamingDistributionWithTags20190326_613476(path: JsonNode;
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
  var valid_613478 = query.getOrDefault("WithTags")
  valid_613478 = validateParameter(valid_613478, JBool, required = true, default = nil)
  if valid_613478 != nil:
    section.add "WithTags", valid_613478
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
  var valid_613479 = header.getOrDefault("X-Amz-Signature")
  valid_613479 = validateParameter(valid_613479, JString, required = false,
                                 default = nil)
  if valid_613479 != nil:
    section.add "X-Amz-Signature", valid_613479
  var valid_613480 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613480 = validateParameter(valid_613480, JString, required = false,
                                 default = nil)
  if valid_613480 != nil:
    section.add "X-Amz-Content-Sha256", valid_613480
  var valid_613481 = header.getOrDefault("X-Amz-Date")
  valid_613481 = validateParameter(valid_613481, JString, required = false,
                                 default = nil)
  if valid_613481 != nil:
    section.add "X-Amz-Date", valid_613481
  var valid_613482 = header.getOrDefault("X-Amz-Credential")
  valid_613482 = validateParameter(valid_613482, JString, required = false,
                                 default = nil)
  if valid_613482 != nil:
    section.add "X-Amz-Credential", valid_613482
  var valid_613483 = header.getOrDefault("X-Amz-Security-Token")
  valid_613483 = validateParameter(valid_613483, JString, required = false,
                                 default = nil)
  if valid_613483 != nil:
    section.add "X-Amz-Security-Token", valid_613483
  var valid_613484 = header.getOrDefault("X-Amz-Algorithm")
  valid_613484 = validateParameter(valid_613484, JString, required = false,
                                 default = nil)
  if valid_613484 != nil:
    section.add "X-Amz-Algorithm", valid_613484
  var valid_613485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613485 = validateParameter(valid_613485, JString, required = false,
                                 default = nil)
  if valid_613485 != nil:
    section.add "X-Amz-SignedHeaders", valid_613485
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613487: Call_CreateStreamingDistributionWithTags20190326_613475;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Create a new streaming distribution with tags.
  ## 
  let valid = call_613487.validator(path, query, header, formData, body)
  let scheme = call_613487.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613487.url(scheme.get, call_613487.host, call_613487.base,
                         call_613487.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613487, url, valid)

proc call*(call_613488: Call_CreateStreamingDistributionWithTags20190326_613475;
          body: JsonNode; WithTags: bool): Recallable =
  ## createStreamingDistributionWithTags20190326
  ## Create a new streaming distribution with tags.
  ##   body: JObject (required)
  ##   WithTags: bool (required)
  var query_613489 = newJObject()
  var body_613490 = newJObject()
  if body != nil:
    body_613490 = body
  add(query_613489, "WithTags", newJBool(WithTags))
  result = call_613488.call(nil, query_613489, nil, nil, body_613490)

var createStreamingDistributionWithTags20190326* = Call_CreateStreamingDistributionWithTags20190326_613475(
    name: "createStreamingDistributionWithTags20190326",
    meth: HttpMethod.HttpPost, host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/streaming-distribution#WithTags",
    validator: validate_CreateStreamingDistributionWithTags20190326_613476,
    base: "/", url: url_CreateStreamingDistributionWithTags20190326_613477,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCloudFrontOriginAccessIdentity20190326_613491 = ref object of OpenApiRestCall_612658
proc url_GetCloudFrontOriginAccessIdentity20190326_613493(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2019-03-26/origin-access-identity/cloudfront/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetCloudFrontOriginAccessIdentity20190326_613492(path: JsonNode;
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
  var valid_613494 = path.getOrDefault("Id")
  valid_613494 = validateParameter(valid_613494, JString, required = true,
                                 default = nil)
  if valid_613494 != nil:
    section.add "Id", valid_613494
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
  var valid_613495 = header.getOrDefault("X-Amz-Signature")
  valid_613495 = validateParameter(valid_613495, JString, required = false,
                                 default = nil)
  if valid_613495 != nil:
    section.add "X-Amz-Signature", valid_613495
  var valid_613496 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613496 = validateParameter(valid_613496, JString, required = false,
                                 default = nil)
  if valid_613496 != nil:
    section.add "X-Amz-Content-Sha256", valid_613496
  var valid_613497 = header.getOrDefault("X-Amz-Date")
  valid_613497 = validateParameter(valid_613497, JString, required = false,
                                 default = nil)
  if valid_613497 != nil:
    section.add "X-Amz-Date", valid_613497
  var valid_613498 = header.getOrDefault("X-Amz-Credential")
  valid_613498 = validateParameter(valid_613498, JString, required = false,
                                 default = nil)
  if valid_613498 != nil:
    section.add "X-Amz-Credential", valid_613498
  var valid_613499 = header.getOrDefault("X-Amz-Security-Token")
  valid_613499 = validateParameter(valid_613499, JString, required = false,
                                 default = nil)
  if valid_613499 != nil:
    section.add "X-Amz-Security-Token", valid_613499
  var valid_613500 = header.getOrDefault("X-Amz-Algorithm")
  valid_613500 = validateParameter(valid_613500, JString, required = false,
                                 default = nil)
  if valid_613500 != nil:
    section.add "X-Amz-Algorithm", valid_613500
  var valid_613501 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613501 = validateParameter(valid_613501, JString, required = false,
                                 default = nil)
  if valid_613501 != nil:
    section.add "X-Amz-SignedHeaders", valid_613501
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613502: Call_GetCloudFrontOriginAccessIdentity20190326_613491;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Get the information about an origin access identity. 
  ## 
  let valid = call_613502.validator(path, query, header, formData, body)
  let scheme = call_613502.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613502.url(scheme.get, call_613502.host, call_613502.base,
                         call_613502.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613502, url, valid)

proc call*(call_613503: Call_GetCloudFrontOriginAccessIdentity20190326_613491;
          Id: string): Recallable =
  ## getCloudFrontOriginAccessIdentity20190326
  ## Get the information about an origin access identity. 
  ##   Id: string (required)
  ##     : The identity's ID.
  var path_613504 = newJObject()
  add(path_613504, "Id", newJString(Id))
  result = call_613503.call(path_613504, nil, nil, nil, nil)

var getCloudFrontOriginAccessIdentity20190326* = Call_GetCloudFrontOriginAccessIdentity20190326_613491(
    name: "getCloudFrontOriginAccessIdentity20190326", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/origin-access-identity/cloudfront/{Id}",
    validator: validate_GetCloudFrontOriginAccessIdentity20190326_613492,
    base: "/", url: url_GetCloudFrontOriginAccessIdentity20190326_613493,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCloudFrontOriginAccessIdentity20190326_613505 = ref object of OpenApiRestCall_612658
proc url_DeleteCloudFrontOriginAccessIdentity20190326_613507(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2019-03-26/origin-access-identity/cloudfront/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteCloudFrontOriginAccessIdentity20190326_613506(path: JsonNode;
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
  var valid_613508 = path.getOrDefault("Id")
  valid_613508 = validateParameter(valid_613508, JString, required = true,
                                 default = nil)
  if valid_613508 != nil:
    section.add "Id", valid_613508
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
  var valid_613509 = header.getOrDefault("X-Amz-Signature")
  valid_613509 = validateParameter(valid_613509, JString, required = false,
                                 default = nil)
  if valid_613509 != nil:
    section.add "X-Amz-Signature", valid_613509
  var valid_613510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613510 = validateParameter(valid_613510, JString, required = false,
                                 default = nil)
  if valid_613510 != nil:
    section.add "X-Amz-Content-Sha256", valid_613510
  var valid_613511 = header.getOrDefault("X-Amz-Date")
  valid_613511 = validateParameter(valid_613511, JString, required = false,
                                 default = nil)
  if valid_613511 != nil:
    section.add "X-Amz-Date", valid_613511
  var valid_613512 = header.getOrDefault("X-Amz-Credential")
  valid_613512 = validateParameter(valid_613512, JString, required = false,
                                 default = nil)
  if valid_613512 != nil:
    section.add "X-Amz-Credential", valid_613512
  var valid_613513 = header.getOrDefault("X-Amz-Security-Token")
  valid_613513 = validateParameter(valid_613513, JString, required = false,
                                 default = nil)
  if valid_613513 != nil:
    section.add "X-Amz-Security-Token", valid_613513
  var valid_613514 = header.getOrDefault("If-Match")
  valid_613514 = validateParameter(valid_613514, JString, required = false,
                                 default = nil)
  if valid_613514 != nil:
    section.add "If-Match", valid_613514
  var valid_613515 = header.getOrDefault("X-Amz-Algorithm")
  valid_613515 = validateParameter(valid_613515, JString, required = false,
                                 default = nil)
  if valid_613515 != nil:
    section.add "X-Amz-Algorithm", valid_613515
  var valid_613516 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613516 = validateParameter(valid_613516, JString, required = false,
                                 default = nil)
  if valid_613516 != nil:
    section.add "X-Amz-SignedHeaders", valid_613516
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613517: Call_DeleteCloudFrontOriginAccessIdentity20190326_613505;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Delete an origin access identity. 
  ## 
  let valid = call_613517.validator(path, query, header, formData, body)
  let scheme = call_613517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613517.url(scheme.get, call_613517.host, call_613517.base,
                         call_613517.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613517, url, valid)

proc call*(call_613518: Call_DeleteCloudFrontOriginAccessIdentity20190326_613505;
          Id: string): Recallable =
  ## deleteCloudFrontOriginAccessIdentity20190326
  ## Delete an origin access identity. 
  ##   Id: string (required)
  ##     : The origin access identity's ID.
  var path_613519 = newJObject()
  add(path_613519, "Id", newJString(Id))
  result = call_613518.call(path_613519, nil, nil, nil, nil)

var deleteCloudFrontOriginAccessIdentity20190326* = Call_DeleteCloudFrontOriginAccessIdentity20190326_613505(
    name: "deleteCloudFrontOriginAccessIdentity20190326",
    meth: HttpMethod.HttpDelete, host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/origin-access-identity/cloudfront/{Id}",
    validator: validate_DeleteCloudFrontOriginAccessIdentity20190326_613506,
    base: "/", url: url_DeleteCloudFrontOriginAccessIdentity20190326_613507,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDistribution20190326_613520 = ref object of OpenApiRestCall_612658
proc url_GetDistribution20190326_613522(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2019-03-26/distribution/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDistribution20190326_613521(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get the information about a distribution.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The distribution's ID. If the ID is empty, an empty distribution configuration is returned.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_613523 = path.getOrDefault("Id")
  valid_613523 = validateParameter(valid_613523, JString, required = true,
                                 default = nil)
  if valid_613523 != nil:
    section.add "Id", valid_613523
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
  var valid_613524 = header.getOrDefault("X-Amz-Signature")
  valid_613524 = validateParameter(valid_613524, JString, required = false,
                                 default = nil)
  if valid_613524 != nil:
    section.add "X-Amz-Signature", valid_613524
  var valid_613525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613525 = validateParameter(valid_613525, JString, required = false,
                                 default = nil)
  if valid_613525 != nil:
    section.add "X-Amz-Content-Sha256", valid_613525
  var valid_613526 = header.getOrDefault("X-Amz-Date")
  valid_613526 = validateParameter(valid_613526, JString, required = false,
                                 default = nil)
  if valid_613526 != nil:
    section.add "X-Amz-Date", valid_613526
  var valid_613527 = header.getOrDefault("X-Amz-Credential")
  valid_613527 = validateParameter(valid_613527, JString, required = false,
                                 default = nil)
  if valid_613527 != nil:
    section.add "X-Amz-Credential", valid_613527
  var valid_613528 = header.getOrDefault("X-Amz-Security-Token")
  valid_613528 = validateParameter(valid_613528, JString, required = false,
                                 default = nil)
  if valid_613528 != nil:
    section.add "X-Amz-Security-Token", valid_613528
  var valid_613529 = header.getOrDefault("X-Amz-Algorithm")
  valid_613529 = validateParameter(valid_613529, JString, required = false,
                                 default = nil)
  if valid_613529 != nil:
    section.add "X-Amz-Algorithm", valid_613529
  var valid_613530 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613530 = validateParameter(valid_613530, JString, required = false,
                                 default = nil)
  if valid_613530 != nil:
    section.add "X-Amz-SignedHeaders", valid_613530
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613531: Call_GetDistribution20190326_613520; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the information about a distribution.
  ## 
  let valid = call_613531.validator(path, query, header, formData, body)
  let scheme = call_613531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613531.url(scheme.get, call_613531.host, call_613531.base,
                         call_613531.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613531, url, valid)

proc call*(call_613532: Call_GetDistribution20190326_613520; Id: string): Recallable =
  ## getDistribution20190326
  ## Get the information about a distribution.
  ##   Id: string (required)
  ##     : The distribution's ID. If the ID is empty, an empty distribution configuration is returned.
  var path_613533 = newJObject()
  add(path_613533, "Id", newJString(Id))
  result = call_613532.call(path_613533, nil, nil, nil, nil)

var getDistribution20190326* = Call_GetDistribution20190326_613520(
    name: "getDistribution20190326", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2019-03-26/distribution/{Id}",
    validator: validate_GetDistribution20190326_613521, base: "/",
    url: url_GetDistribution20190326_613522, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDistribution20190326_613534 = ref object of OpenApiRestCall_612658
proc url_DeleteDistribution20190326_613536(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2019-03-26/distribution/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDistribution20190326_613535(path: JsonNode; query: JsonNode;
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
  var valid_613537 = path.getOrDefault("Id")
  valid_613537 = validateParameter(valid_613537, JString, required = true,
                                 default = nil)
  if valid_613537 != nil:
    section.add "Id", valid_613537
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
  var valid_613538 = header.getOrDefault("X-Amz-Signature")
  valid_613538 = validateParameter(valid_613538, JString, required = false,
                                 default = nil)
  if valid_613538 != nil:
    section.add "X-Amz-Signature", valid_613538
  var valid_613539 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613539 = validateParameter(valid_613539, JString, required = false,
                                 default = nil)
  if valid_613539 != nil:
    section.add "X-Amz-Content-Sha256", valid_613539
  var valid_613540 = header.getOrDefault("X-Amz-Date")
  valid_613540 = validateParameter(valid_613540, JString, required = false,
                                 default = nil)
  if valid_613540 != nil:
    section.add "X-Amz-Date", valid_613540
  var valid_613541 = header.getOrDefault("X-Amz-Credential")
  valid_613541 = validateParameter(valid_613541, JString, required = false,
                                 default = nil)
  if valid_613541 != nil:
    section.add "X-Amz-Credential", valid_613541
  var valid_613542 = header.getOrDefault("X-Amz-Security-Token")
  valid_613542 = validateParameter(valid_613542, JString, required = false,
                                 default = nil)
  if valid_613542 != nil:
    section.add "X-Amz-Security-Token", valid_613542
  var valid_613543 = header.getOrDefault("If-Match")
  valid_613543 = validateParameter(valid_613543, JString, required = false,
                                 default = nil)
  if valid_613543 != nil:
    section.add "If-Match", valid_613543
  var valid_613544 = header.getOrDefault("X-Amz-Algorithm")
  valid_613544 = validateParameter(valid_613544, JString, required = false,
                                 default = nil)
  if valid_613544 != nil:
    section.add "X-Amz-Algorithm", valid_613544
  var valid_613545 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613545 = validateParameter(valid_613545, JString, required = false,
                                 default = nil)
  if valid_613545 != nil:
    section.add "X-Amz-SignedHeaders", valid_613545
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613546: Call_DeleteDistribution20190326_613534; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a distribution. 
  ## 
  let valid = call_613546.validator(path, query, header, formData, body)
  let scheme = call_613546.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613546.url(scheme.get, call_613546.host, call_613546.base,
                         call_613546.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613546, url, valid)

proc call*(call_613547: Call_DeleteDistribution20190326_613534; Id: string): Recallable =
  ## deleteDistribution20190326
  ## Delete a distribution. 
  ##   Id: string (required)
  ##     : The distribution ID. 
  var path_613548 = newJObject()
  add(path_613548, "Id", newJString(Id))
  result = call_613547.call(path_613548, nil, nil, nil, nil)

var deleteDistribution20190326* = Call_DeleteDistribution20190326_613534(
    name: "deleteDistribution20190326", meth: HttpMethod.HttpDelete,
    host: "cloudfront.amazonaws.com", route: "/2019-03-26/distribution/{Id}",
    validator: validate_DeleteDistribution20190326_613535, base: "/",
    url: url_DeleteDistribution20190326_613536,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFieldLevelEncryption20190326_613549 = ref object of OpenApiRestCall_612658
proc url_GetFieldLevelEncryption20190326_613551(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2019-03-26/field-level-encryption/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFieldLevelEncryption20190326_613550(path: JsonNode;
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
  var valid_613552 = path.getOrDefault("Id")
  valid_613552 = validateParameter(valid_613552, JString, required = true,
                                 default = nil)
  if valid_613552 != nil:
    section.add "Id", valid_613552
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
  var valid_613553 = header.getOrDefault("X-Amz-Signature")
  valid_613553 = validateParameter(valid_613553, JString, required = false,
                                 default = nil)
  if valid_613553 != nil:
    section.add "X-Amz-Signature", valid_613553
  var valid_613554 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613554 = validateParameter(valid_613554, JString, required = false,
                                 default = nil)
  if valid_613554 != nil:
    section.add "X-Amz-Content-Sha256", valid_613554
  var valid_613555 = header.getOrDefault("X-Amz-Date")
  valid_613555 = validateParameter(valid_613555, JString, required = false,
                                 default = nil)
  if valid_613555 != nil:
    section.add "X-Amz-Date", valid_613555
  var valid_613556 = header.getOrDefault("X-Amz-Credential")
  valid_613556 = validateParameter(valid_613556, JString, required = false,
                                 default = nil)
  if valid_613556 != nil:
    section.add "X-Amz-Credential", valid_613556
  var valid_613557 = header.getOrDefault("X-Amz-Security-Token")
  valid_613557 = validateParameter(valid_613557, JString, required = false,
                                 default = nil)
  if valid_613557 != nil:
    section.add "X-Amz-Security-Token", valid_613557
  var valid_613558 = header.getOrDefault("X-Amz-Algorithm")
  valid_613558 = validateParameter(valid_613558, JString, required = false,
                                 default = nil)
  if valid_613558 != nil:
    section.add "X-Amz-Algorithm", valid_613558
  var valid_613559 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613559 = validateParameter(valid_613559, JString, required = false,
                                 default = nil)
  if valid_613559 != nil:
    section.add "X-Amz-SignedHeaders", valid_613559
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613560: Call_GetFieldLevelEncryption20190326_613549;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Get the field-level encryption configuration information.
  ## 
  let valid = call_613560.validator(path, query, header, formData, body)
  let scheme = call_613560.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613560.url(scheme.get, call_613560.host, call_613560.base,
                         call_613560.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613560, url, valid)

proc call*(call_613561: Call_GetFieldLevelEncryption20190326_613549; Id: string): Recallable =
  ## getFieldLevelEncryption20190326
  ## Get the field-level encryption configuration information.
  ##   Id: string (required)
  ##     : Request the ID for the field-level encryption configuration information.
  var path_613562 = newJObject()
  add(path_613562, "Id", newJString(Id))
  result = call_613561.call(path_613562, nil, nil, nil, nil)

var getFieldLevelEncryption20190326* = Call_GetFieldLevelEncryption20190326_613549(
    name: "getFieldLevelEncryption20190326", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/field-level-encryption/{Id}",
    validator: validate_GetFieldLevelEncryption20190326_613550, base: "/",
    url: url_GetFieldLevelEncryption20190326_613551,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFieldLevelEncryptionConfig20190326_613563 = ref object of OpenApiRestCall_612658
proc url_DeleteFieldLevelEncryptionConfig20190326_613565(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2019-03-26/field-level-encryption/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteFieldLevelEncryptionConfig20190326_613564(path: JsonNode;
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
  var valid_613566 = path.getOrDefault("Id")
  valid_613566 = validateParameter(valid_613566, JString, required = true,
                                 default = nil)
  if valid_613566 != nil:
    section.add "Id", valid_613566
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
  var valid_613567 = header.getOrDefault("X-Amz-Signature")
  valid_613567 = validateParameter(valid_613567, JString, required = false,
                                 default = nil)
  if valid_613567 != nil:
    section.add "X-Amz-Signature", valid_613567
  var valid_613568 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613568 = validateParameter(valid_613568, JString, required = false,
                                 default = nil)
  if valid_613568 != nil:
    section.add "X-Amz-Content-Sha256", valid_613568
  var valid_613569 = header.getOrDefault("X-Amz-Date")
  valid_613569 = validateParameter(valid_613569, JString, required = false,
                                 default = nil)
  if valid_613569 != nil:
    section.add "X-Amz-Date", valid_613569
  var valid_613570 = header.getOrDefault("X-Amz-Credential")
  valid_613570 = validateParameter(valid_613570, JString, required = false,
                                 default = nil)
  if valid_613570 != nil:
    section.add "X-Amz-Credential", valid_613570
  var valid_613571 = header.getOrDefault("X-Amz-Security-Token")
  valid_613571 = validateParameter(valid_613571, JString, required = false,
                                 default = nil)
  if valid_613571 != nil:
    section.add "X-Amz-Security-Token", valid_613571
  var valid_613572 = header.getOrDefault("If-Match")
  valid_613572 = validateParameter(valid_613572, JString, required = false,
                                 default = nil)
  if valid_613572 != nil:
    section.add "If-Match", valid_613572
  var valid_613573 = header.getOrDefault("X-Amz-Algorithm")
  valid_613573 = validateParameter(valid_613573, JString, required = false,
                                 default = nil)
  if valid_613573 != nil:
    section.add "X-Amz-Algorithm", valid_613573
  var valid_613574 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613574 = validateParameter(valid_613574, JString, required = false,
                                 default = nil)
  if valid_613574 != nil:
    section.add "X-Amz-SignedHeaders", valid_613574
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613575: Call_DeleteFieldLevelEncryptionConfig20190326_613563;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Remove a field-level encryption configuration.
  ## 
  let valid = call_613575.validator(path, query, header, formData, body)
  let scheme = call_613575.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613575.url(scheme.get, call_613575.host, call_613575.base,
                         call_613575.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613575, url, valid)

proc call*(call_613576: Call_DeleteFieldLevelEncryptionConfig20190326_613563;
          Id: string): Recallable =
  ## deleteFieldLevelEncryptionConfig20190326
  ## Remove a field-level encryption configuration.
  ##   Id: string (required)
  ##     : The ID of the configuration you want to delete from CloudFront.
  var path_613577 = newJObject()
  add(path_613577, "Id", newJString(Id))
  result = call_613576.call(path_613577, nil, nil, nil, nil)

var deleteFieldLevelEncryptionConfig20190326* = Call_DeleteFieldLevelEncryptionConfig20190326_613563(
    name: "deleteFieldLevelEncryptionConfig20190326", meth: HttpMethod.HttpDelete,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/field-level-encryption/{Id}",
    validator: validate_DeleteFieldLevelEncryptionConfig20190326_613564,
    base: "/", url: url_DeleteFieldLevelEncryptionConfig20190326_613565,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFieldLevelEncryptionProfile20190326_613578 = ref object of OpenApiRestCall_612658
proc url_GetFieldLevelEncryptionProfile20190326_613580(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2019-03-26/field-level-encryption-profile/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFieldLevelEncryptionProfile20190326_613579(path: JsonNode;
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
  var valid_613581 = path.getOrDefault("Id")
  valid_613581 = validateParameter(valid_613581, JString, required = true,
                                 default = nil)
  if valid_613581 != nil:
    section.add "Id", valid_613581
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
  var valid_613582 = header.getOrDefault("X-Amz-Signature")
  valid_613582 = validateParameter(valid_613582, JString, required = false,
                                 default = nil)
  if valid_613582 != nil:
    section.add "X-Amz-Signature", valid_613582
  var valid_613583 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613583 = validateParameter(valid_613583, JString, required = false,
                                 default = nil)
  if valid_613583 != nil:
    section.add "X-Amz-Content-Sha256", valid_613583
  var valid_613584 = header.getOrDefault("X-Amz-Date")
  valid_613584 = validateParameter(valid_613584, JString, required = false,
                                 default = nil)
  if valid_613584 != nil:
    section.add "X-Amz-Date", valid_613584
  var valid_613585 = header.getOrDefault("X-Amz-Credential")
  valid_613585 = validateParameter(valid_613585, JString, required = false,
                                 default = nil)
  if valid_613585 != nil:
    section.add "X-Amz-Credential", valid_613585
  var valid_613586 = header.getOrDefault("X-Amz-Security-Token")
  valid_613586 = validateParameter(valid_613586, JString, required = false,
                                 default = nil)
  if valid_613586 != nil:
    section.add "X-Amz-Security-Token", valid_613586
  var valid_613587 = header.getOrDefault("X-Amz-Algorithm")
  valid_613587 = validateParameter(valid_613587, JString, required = false,
                                 default = nil)
  if valid_613587 != nil:
    section.add "X-Amz-Algorithm", valid_613587
  var valid_613588 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613588 = validateParameter(valid_613588, JString, required = false,
                                 default = nil)
  if valid_613588 != nil:
    section.add "X-Amz-SignedHeaders", valid_613588
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613589: Call_GetFieldLevelEncryptionProfile20190326_613578;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Get the field-level encryption profile information.
  ## 
  let valid = call_613589.validator(path, query, header, formData, body)
  let scheme = call_613589.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613589.url(scheme.get, call_613589.host, call_613589.base,
                         call_613589.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613589, url, valid)

proc call*(call_613590: Call_GetFieldLevelEncryptionProfile20190326_613578;
          Id: string): Recallable =
  ## getFieldLevelEncryptionProfile20190326
  ## Get the field-level encryption profile information.
  ##   Id: string (required)
  ##     : Get the ID for the field-level encryption profile information.
  var path_613591 = newJObject()
  add(path_613591, "Id", newJString(Id))
  result = call_613590.call(path_613591, nil, nil, nil, nil)

var getFieldLevelEncryptionProfile20190326* = Call_GetFieldLevelEncryptionProfile20190326_613578(
    name: "getFieldLevelEncryptionProfile20190326", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/field-level-encryption-profile/{Id}",
    validator: validate_GetFieldLevelEncryptionProfile20190326_613579, base: "/",
    url: url_GetFieldLevelEncryptionProfile20190326_613580,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFieldLevelEncryptionProfile20190326_613592 = ref object of OpenApiRestCall_612658
proc url_DeleteFieldLevelEncryptionProfile20190326_613594(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2019-03-26/field-level-encryption-profile/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteFieldLevelEncryptionProfile20190326_613593(path: JsonNode;
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
  var valid_613595 = path.getOrDefault("Id")
  valid_613595 = validateParameter(valid_613595, JString, required = true,
                                 default = nil)
  if valid_613595 != nil:
    section.add "Id", valid_613595
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
  var valid_613596 = header.getOrDefault("X-Amz-Signature")
  valid_613596 = validateParameter(valid_613596, JString, required = false,
                                 default = nil)
  if valid_613596 != nil:
    section.add "X-Amz-Signature", valid_613596
  var valid_613597 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613597 = validateParameter(valid_613597, JString, required = false,
                                 default = nil)
  if valid_613597 != nil:
    section.add "X-Amz-Content-Sha256", valid_613597
  var valid_613598 = header.getOrDefault("X-Amz-Date")
  valid_613598 = validateParameter(valid_613598, JString, required = false,
                                 default = nil)
  if valid_613598 != nil:
    section.add "X-Amz-Date", valid_613598
  var valid_613599 = header.getOrDefault("X-Amz-Credential")
  valid_613599 = validateParameter(valid_613599, JString, required = false,
                                 default = nil)
  if valid_613599 != nil:
    section.add "X-Amz-Credential", valid_613599
  var valid_613600 = header.getOrDefault("X-Amz-Security-Token")
  valid_613600 = validateParameter(valid_613600, JString, required = false,
                                 default = nil)
  if valid_613600 != nil:
    section.add "X-Amz-Security-Token", valid_613600
  var valid_613601 = header.getOrDefault("If-Match")
  valid_613601 = validateParameter(valid_613601, JString, required = false,
                                 default = nil)
  if valid_613601 != nil:
    section.add "If-Match", valid_613601
  var valid_613602 = header.getOrDefault("X-Amz-Algorithm")
  valid_613602 = validateParameter(valid_613602, JString, required = false,
                                 default = nil)
  if valid_613602 != nil:
    section.add "X-Amz-Algorithm", valid_613602
  var valid_613603 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613603 = validateParameter(valid_613603, JString, required = false,
                                 default = nil)
  if valid_613603 != nil:
    section.add "X-Amz-SignedHeaders", valid_613603
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613604: Call_DeleteFieldLevelEncryptionProfile20190326_613592;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Remove a field-level encryption profile.
  ## 
  let valid = call_613604.validator(path, query, header, formData, body)
  let scheme = call_613604.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613604.url(scheme.get, call_613604.host, call_613604.base,
                         call_613604.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613604, url, valid)

proc call*(call_613605: Call_DeleteFieldLevelEncryptionProfile20190326_613592;
          Id: string): Recallable =
  ## deleteFieldLevelEncryptionProfile20190326
  ## Remove a field-level encryption profile.
  ##   Id: string (required)
  ##     : Request the ID of the profile you want to delete from CloudFront.
  var path_613606 = newJObject()
  add(path_613606, "Id", newJString(Id))
  result = call_613605.call(path_613606, nil, nil, nil, nil)

var deleteFieldLevelEncryptionProfile20190326* = Call_DeleteFieldLevelEncryptionProfile20190326_613592(
    name: "deleteFieldLevelEncryptionProfile20190326",
    meth: HttpMethod.HttpDelete, host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/field-level-encryption-profile/{Id}",
    validator: validate_DeleteFieldLevelEncryptionProfile20190326_613593,
    base: "/", url: url_DeleteFieldLevelEncryptionProfile20190326_613594,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPublicKey20190326_613607 = ref object of OpenApiRestCall_612658
proc url_GetPublicKey20190326_613609(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2019-03-26/public-key/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetPublicKey20190326_613608(path: JsonNode; query: JsonNode;
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
  var valid_613610 = path.getOrDefault("Id")
  valid_613610 = validateParameter(valid_613610, JString, required = true,
                                 default = nil)
  if valid_613610 != nil:
    section.add "Id", valid_613610
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
  var valid_613611 = header.getOrDefault("X-Amz-Signature")
  valid_613611 = validateParameter(valid_613611, JString, required = false,
                                 default = nil)
  if valid_613611 != nil:
    section.add "X-Amz-Signature", valid_613611
  var valid_613612 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613612 = validateParameter(valid_613612, JString, required = false,
                                 default = nil)
  if valid_613612 != nil:
    section.add "X-Amz-Content-Sha256", valid_613612
  var valid_613613 = header.getOrDefault("X-Amz-Date")
  valid_613613 = validateParameter(valid_613613, JString, required = false,
                                 default = nil)
  if valid_613613 != nil:
    section.add "X-Amz-Date", valid_613613
  var valid_613614 = header.getOrDefault("X-Amz-Credential")
  valid_613614 = validateParameter(valid_613614, JString, required = false,
                                 default = nil)
  if valid_613614 != nil:
    section.add "X-Amz-Credential", valid_613614
  var valid_613615 = header.getOrDefault("X-Amz-Security-Token")
  valid_613615 = validateParameter(valid_613615, JString, required = false,
                                 default = nil)
  if valid_613615 != nil:
    section.add "X-Amz-Security-Token", valid_613615
  var valid_613616 = header.getOrDefault("X-Amz-Algorithm")
  valid_613616 = validateParameter(valid_613616, JString, required = false,
                                 default = nil)
  if valid_613616 != nil:
    section.add "X-Amz-Algorithm", valid_613616
  var valid_613617 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613617 = validateParameter(valid_613617, JString, required = false,
                                 default = nil)
  if valid_613617 != nil:
    section.add "X-Amz-SignedHeaders", valid_613617
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613618: Call_GetPublicKey20190326_613607; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the public key information.
  ## 
  let valid = call_613618.validator(path, query, header, formData, body)
  let scheme = call_613618.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613618.url(scheme.get, call_613618.host, call_613618.base,
                         call_613618.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613618, url, valid)

proc call*(call_613619: Call_GetPublicKey20190326_613607; Id: string): Recallable =
  ## getPublicKey20190326
  ## Get the public key information.
  ##   Id: string (required)
  ##     : Request the ID for the public key.
  var path_613620 = newJObject()
  add(path_613620, "Id", newJString(Id))
  result = call_613619.call(path_613620, nil, nil, nil, nil)

var getPublicKey20190326* = Call_GetPublicKey20190326_613607(
    name: "getPublicKey20190326", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2019-03-26/public-key/{Id}",
    validator: validate_GetPublicKey20190326_613608, base: "/",
    url: url_GetPublicKey20190326_613609, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePublicKey20190326_613621 = ref object of OpenApiRestCall_612658
proc url_DeletePublicKey20190326_613623(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2019-03-26/public-key/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeletePublicKey20190326_613622(path: JsonNode; query: JsonNode;
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
  var valid_613624 = path.getOrDefault("Id")
  valid_613624 = validateParameter(valid_613624, JString, required = true,
                                 default = nil)
  if valid_613624 != nil:
    section.add "Id", valid_613624
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
  var valid_613625 = header.getOrDefault("X-Amz-Signature")
  valid_613625 = validateParameter(valid_613625, JString, required = false,
                                 default = nil)
  if valid_613625 != nil:
    section.add "X-Amz-Signature", valid_613625
  var valid_613626 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613626 = validateParameter(valid_613626, JString, required = false,
                                 default = nil)
  if valid_613626 != nil:
    section.add "X-Amz-Content-Sha256", valid_613626
  var valid_613627 = header.getOrDefault("X-Amz-Date")
  valid_613627 = validateParameter(valid_613627, JString, required = false,
                                 default = nil)
  if valid_613627 != nil:
    section.add "X-Amz-Date", valid_613627
  var valid_613628 = header.getOrDefault("X-Amz-Credential")
  valid_613628 = validateParameter(valid_613628, JString, required = false,
                                 default = nil)
  if valid_613628 != nil:
    section.add "X-Amz-Credential", valid_613628
  var valid_613629 = header.getOrDefault("X-Amz-Security-Token")
  valid_613629 = validateParameter(valid_613629, JString, required = false,
                                 default = nil)
  if valid_613629 != nil:
    section.add "X-Amz-Security-Token", valid_613629
  var valid_613630 = header.getOrDefault("If-Match")
  valid_613630 = validateParameter(valid_613630, JString, required = false,
                                 default = nil)
  if valid_613630 != nil:
    section.add "If-Match", valid_613630
  var valid_613631 = header.getOrDefault("X-Amz-Algorithm")
  valid_613631 = validateParameter(valid_613631, JString, required = false,
                                 default = nil)
  if valid_613631 != nil:
    section.add "X-Amz-Algorithm", valid_613631
  var valid_613632 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613632 = validateParameter(valid_613632, JString, required = false,
                                 default = nil)
  if valid_613632 != nil:
    section.add "X-Amz-SignedHeaders", valid_613632
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613633: Call_DeletePublicKey20190326_613621; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove a public key you previously added to CloudFront.
  ## 
  let valid = call_613633.validator(path, query, header, formData, body)
  let scheme = call_613633.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613633.url(scheme.get, call_613633.host, call_613633.base,
                         call_613633.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613633, url, valid)

proc call*(call_613634: Call_DeletePublicKey20190326_613621; Id: string): Recallable =
  ## deletePublicKey20190326
  ## Remove a public key you previously added to CloudFront.
  ##   Id: string (required)
  ##     : The ID of the public key you want to remove from CloudFront.
  var path_613635 = newJObject()
  add(path_613635, "Id", newJString(Id))
  result = call_613634.call(path_613635, nil, nil, nil, nil)

var deletePublicKey20190326* = Call_DeletePublicKey20190326_613621(
    name: "deletePublicKey20190326", meth: HttpMethod.HttpDelete,
    host: "cloudfront.amazonaws.com", route: "/2019-03-26/public-key/{Id}",
    validator: validate_DeletePublicKey20190326_613622, base: "/",
    url: url_DeletePublicKey20190326_613623, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStreamingDistribution20190326_613636 = ref object of OpenApiRestCall_612658
proc url_GetStreamingDistribution20190326_613638(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2019-03-26/streaming-distribution/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetStreamingDistribution20190326_613637(path: JsonNode;
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
  var valid_613639 = path.getOrDefault("Id")
  valid_613639 = validateParameter(valid_613639, JString, required = true,
                                 default = nil)
  if valid_613639 != nil:
    section.add "Id", valid_613639
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
  var valid_613640 = header.getOrDefault("X-Amz-Signature")
  valid_613640 = validateParameter(valid_613640, JString, required = false,
                                 default = nil)
  if valid_613640 != nil:
    section.add "X-Amz-Signature", valid_613640
  var valid_613641 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613641 = validateParameter(valid_613641, JString, required = false,
                                 default = nil)
  if valid_613641 != nil:
    section.add "X-Amz-Content-Sha256", valid_613641
  var valid_613642 = header.getOrDefault("X-Amz-Date")
  valid_613642 = validateParameter(valid_613642, JString, required = false,
                                 default = nil)
  if valid_613642 != nil:
    section.add "X-Amz-Date", valid_613642
  var valid_613643 = header.getOrDefault("X-Amz-Credential")
  valid_613643 = validateParameter(valid_613643, JString, required = false,
                                 default = nil)
  if valid_613643 != nil:
    section.add "X-Amz-Credential", valid_613643
  var valid_613644 = header.getOrDefault("X-Amz-Security-Token")
  valid_613644 = validateParameter(valid_613644, JString, required = false,
                                 default = nil)
  if valid_613644 != nil:
    section.add "X-Amz-Security-Token", valid_613644
  var valid_613645 = header.getOrDefault("X-Amz-Algorithm")
  valid_613645 = validateParameter(valid_613645, JString, required = false,
                                 default = nil)
  if valid_613645 != nil:
    section.add "X-Amz-Algorithm", valid_613645
  var valid_613646 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613646 = validateParameter(valid_613646, JString, required = false,
                                 default = nil)
  if valid_613646 != nil:
    section.add "X-Amz-SignedHeaders", valid_613646
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613647: Call_GetStreamingDistribution20190326_613636;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets information about a specified RTMP distribution, including the distribution configuration.
  ## 
  let valid = call_613647.validator(path, query, header, formData, body)
  let scheme = call_613647.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613647.url(scheme.get, call_613647.host, call_613647.base,
                         call_613647.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613647, url, valid)

proc call*(call_613648: Call_GetStreamingDistribution20190326_613636; Id: string): Recallable =
  ## getStreamingDistribution20190326
  ## Gets information about a specified RTMP distribution, including the distribution configuration.
  ##   Id: string (required)
  ##     : The streaming distribution's ID.
  var path_613649 = newJObject()
  add(path_613649, "Id", newJString(Id))
  result = call_613648.call(path_613649, nil, nil, nil, nil)

var getStreamingDistribution20190326* = Call_GetStreamingDistribution20190326_613636(
    name: "getStreamingDistribution20190326", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/streaming-distribution/{Id}",
    validator: validate_GetStreamingDistribution20190326_613637, base: "/",
    url: url_GetStreamingDistribution20190326_613638,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteStreamingDistribution20190326_613650 = ref object of OpenApiRestCall_612658
proc url_DeleteStreamingDistribution20190326_613652(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2019-03-26/streaming-distribution/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteStreamingDistribution20190326_613651(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Delete a streaming distribution. To delete an RTMP distribution using the CloudFront API, perform the following steps.</p> <p> <b>To delete an RTMP distribution using the CloudFront API</b>:</p> <ol> <li> <p>Disable the RTMP distribution.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to get the current configuration and the <code>Etag</code> header for the distribution. </p> </li> <li> <p>Update the XML document that was returned in the response to your <code>GET Streaming Distribution Config</code> request to change the value of <code>Enabled</code> to <code>false</code>.</p> </li> <li> <p>Submit a <code>PUT Streaming Distribution Config</code> request to update the configuration for your distribution. In the request body, include the XML document that you updated in Step 3. Then set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to the <code>PUT Streaming Distribution Config</code> request to confirm that the distribution was successfully disabled.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> <li> <p>Submit a <code>DELETE Streaming Distribution</code> request. Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to your <code>DELETE Streaming Distribution</code> request to confirm that the distribution was successfully deleted.</p> </li> </ol> <p>For information about deleting a distribution using the CloudFront console, see <a href="https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/HowToDeleteDistribution.html">Deleting a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The distribution ID. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_613653 = path.getOrDefault("Id")
  valid_613653 = validateParameter(valid_613653, JString, required = true,
                                 default = nil)
  if valid_613653 != nil:
    section.add "Id", valid_613653
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
  var valid_613654 = header.getOrDefault("X-Amz-Signature")
  valid_613654 = validateParameter(valid_613654, JString, required = false,
                                 default = nil)
  if valid_613654 != nil:
    section.add "X-Amz-Signature", valid_613654
  var valid_613655 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613655 = validateParameter(valid_613655, JString, required = false,
                                 default = nil)
  if valid_613655 != nil:
    section.add "X-Amz-Content-Sha256", valid_613655
  var valid_613656 = header.getOrDefault("X-Amz-Date")
  valid_613656 = validateParameter(valid_613656, JString, required = false,
                                 default = nil)
  if valid_613656 != nil:
    section.add "X-Amz-Date", valid_613656
  var valid_613657 = header.getOrDefault("X-Amz-Credential")
  valid_613657 = validateParameter(valid_613657, JString, required = false,
                                 default = nil)
  if valid_613657 != nil:
    section.add "X-Amz-Credential", valid_613657
  var valid_613658 = header.getOrDefault("X-Amz-Security-Token")
  valid_613658 = validateParameter(valid_613658, JString, required = false,
                                 default = nil)
  if valid_613658 != nil:
    section.add "X-Amz-Security-Token", valid_613658
  var valid_613659 = header.getOrDefault("If-Match")
  valid_613659 = validateParameter(valid_613659, JString, required = false,
                                 default = nil)
  if valid_613659 != nil:
    section.add "If-Match", valid_613659
  var valid_613660 = header.getOrDefault("X-Amz-Algorithm")
  valid_613660 = validateParameter(valid_613660, JString, required = false,
                                 default = nil)
  if valid_613660 != nil:
    section.add "X-Amz-Algorithm", valid_613660
  var valid_613661 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613661 = validateParameter(valid_613661, JString, required = false,
                                 default = nil)
  if valid_613661 != nil:
    section.add "X-Amz-SignedHeaders", valid_613661
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613662: Call_DeleteStreamingDistribution20190326_613650;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Delete a streaming distribution. To delete an RTMP distribution using the CloudFront API, perform the following steps.</p> <p> <b>To delete an RTMP distribution using the CloudFront API</b>:</p> <ol> <li> <p>Disable the RTMP distribution.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to get the current configuration and the <code>Etag</code> header for the distribution. </p> </li> <li> <p>Update the XML document that was returned in the response to your <code>GET Streaming Distribution Config</code> request to change the value of <code>Enabled</code> to <code>false</code>.</p> </li> <li> <p>Submit a <code>PUT Streaming Distribution Config</code> request to update the configuration for your distribution. In the request body, include the XML document that you updated in Step 3. Then set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to the <code>PUT Streaming Distribution Config</code> request to confirm that the distribution was successfully disabled.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> <li> <p>Submit a <code>DELETE Streaming Distribution</code> request. Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to your <code>DELETE Streaming Distribution</code> request to confirm that the distribution was successfully deleted.</p> </li> </ol> <p>For information about deleting a distribution using the CloudFront console, see <a href="https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/HowToDeleteDistribution.html">Deleting a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p>
  ## 
  let valid = call_613662.validator(path, query, header, formData, body)
  let scheme = call_613662.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613662.url(scheme.get, call_613662.host, call_613662.base,
                         call_613662.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613662, url, valid)

proc call*(call_613663: Call_DeleteStreamingDistribution20190326_613650; Id: string): Recallable =
  ## deleteStreamingDistribution20190326
  ## <p>Delete a streaming distribution. To delete an RTMP distribution using the CloudFront API, perform the following steps.</p> <p> <b>To delete an RTMP distribution using the CloudFront API</b>:</p> <ol> <li> <p>Disable the RTMP distribution.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to get the current configuration and the <code>Etag</code> header for the distribution. </p> </li> <li> <p>Update the XML document that was returned in the response to your <code>GET Streaming Distribution Config</code> request to change the value of <code>Enabled</code> to <code>false</code>.</p> </li> <li> <p>Submit a <code>PUT Streaming Distribution Config</code> request to update the configuration for your distribution. In the request body, include the XML document that you updated in Step 3. Then set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to the <code>PUT Streaming Distribution Config</code> request to confirm that the distribution was successfully disabled.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> <li> <p>Submit a <code>DELETE Streaming Distribution</code> request. Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to your <code>DELETE Streaming Distribution</code> request to confirm that the distribution was successfully deleted.</p> </li> </ol> <p>For information about deleting a distribution using the CloudFront console, see <a href="https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/HowToDeleteDistribution.html">Deleting a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p>
  ##   Id: string (required)
  ##     : The distribution ID. 
  var path_613664 = newJObject()
  add(path_613664, "Id", newJString(Id))
  result = call_613663.call(path_613664, nil, nil, nil, nil)

var deleteStreamingDistribution20190326* = Call_DeleteStreamingDistribution20190326_613650(
    name: "deleteStreamingDistribution20190326", meth: HttpMethod.HttpDelete,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/streaming-distribution/{Id}",
    validator: validate_DeleteStreamingDistribution20190326_613651, base: "/",
    url: url_DeleteStreamingDistribution20190326_613652,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCloudFrontOriginAccessIdentity20190326_613679 = ref object of OpenApiRestCall_612658
proc url_UpdateCloudFrontOriginAccessIdentity20190326_613681(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2019-03-26/origin-access-identity/cloudfront/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateCloudFrontOriginAccessIdentity20190326_613680(path: JsonNode;
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
  var valid_613682 = path.getOrDefault("Id")
  valid_613682 = validateParameter(valid_613682, JString, required = true,
                                 default = nil)
  if valid_613682 != nil:
    section.add "Id", valid_613682
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
  var valid_613683 = header.getOrDefault("X-Amz-Signature")
  valid_613683 = validateParameter(valid_613683, JString, required = false,
                                 default = nil)
  if valid_613683 != nil:
    section.add "X-Amz-Signature", valid_613683
  var valid_613684 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613684 = validateParameter(valid_613684, JString, required = false,
                                 default = nil)
  if valid_613684 != nil:
    section.add "X-Amz-Content-Sha256", valid_613684
  var valid_613685 = header.getOrDefault("X-Amz-Date")
  valid_613685 = validateParameter(valid_613685, JString, required = false,
                                 default = nil)
  if valid_613685 != nil:
    section.add "X-Amz-Date", valid_613685
  var valid_613686 = header.getOrDefault("X-Amz-Credential")
  valid_613686 = validateParameter(valid_613686, JString, required = false,
                                 default = nil)
  if valid_613686 != nil:
    section.add "X-Amz-Credential", valid_613686
  var valid_613687 = header.getOrDefault("X-Amz-Security-Token")
  valid_613687 = validateParameter(valid_613687, JString, required = false,
                                 default = nil)
  if valid_613687 != nil:
    section.add "X-Amz-Security-Token", valid_613687
  var valid_613688 = header.getOrDefault("If-Match")
  valid_613688 = validateParameter(valid_613688, JString, required = false,
                                 default = nil)
  if valid_613688 != nil:
    section.add "If-Match", valid_613688
  var valid_613689 = header.getOrDefault("X-Amz-Algorithm")
  valid_613689 = validateParameter(valid_613689, JString, required = false,
                                 default = nil)
  if valid_613689 != nil:
    section.add "X-Amz-Algorithm", valid_613689
  var valid_613690 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613690 = validateParameter(valid_613690, JString, required = false,
                                 default = nil)
  if valid_613690 != nil:
    section.add "X-Amz-SignedHeaders", valid_613690
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613692: Call_UpdateCloudFrontOriginAccessIdentity20190326_613679;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Update an origin access identity. 
  ## 
  let valid = call_613692.validator(path, query, header, formData, body)
  let scheme = call_613692.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613692.url(scheme.get, call_613692.host, call_613692.base,
                         call_613692.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613692, url, valid)

proc call*(call_613693: Call_UpdateCloudFrontOriginAccessIdentity20190326_613679;
          body: JsonNode; Id: string): Recallable =
  ## updateCloudFrontOriginAccessIdentity20190326
  ## Update an origin access identity. 
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : The identity's id.
  var path_613694 = newJObject()
  var body_613695 = newJObject()
  if body != nil:
    body_613695 = body
  add(path_613694, "Id", newJString(Id))
  result = call_613693.call(path_613694, nil, nil, nil, body_613695)

var updateCloudFrontOriginAccessIdentity20190326* = Call_UpdateCloudFrontOriginAccessIdentity20190326_613679(
    name: "updateCloudFrontOriginAccessIdentity20190326",
    meth: HttpMethod.HttpPut, host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/origin-access-identity/cloudfront/{Id}/config",
    validator: validate_UpdateCloudFrontOriginAccessIdentity20190326_613680,
    base: "/", url: url_UpdateCloudFrontOriginAccessIdentity20190326_613681,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCloudFrontOriginAccessIdentityConfig20190326_613665 = ref object of OpenApiRestCall_612658
proc url_GetCloudFrontOriginAccessIdentityConfig20190326_613667(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2019-03-26/origin-access-identity/cloudfront/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetCloudFrontOriginAccessIdentityConfig20190326_613666(
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
  var valid_613668 = path.getOrDefault("Id")
  valid_613668 = validateParameter(valid_613668, JString, required = true,
                                 default = nil)
  if valid_613668 != nil:
    section.add "Id", valid_613668
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
  var valid_613669 = header.getOrDefault("X-Amz-Signature")
  valid_613669 = validateParameter(valid_613669, JString, required = false,
                                 default = nil)
  if valid_613669 != nil:
    section.add "X-Amz-Signature", valid_613669
  var valid_613670 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613670 = validateParameter(valid_613670, JString, required = false,
                                 default = nil)
  if valid_613670 != nil:
    section.add "X-Amz-Content-Sha256", valid_613670
  var valid_613671 = header.getOrDefault("X-Amz-Date")
  valid_613671 = validateParameter(valid_613671, JString, required = false,
                                 default = nil)
  if valid_613671 != nil:
    section.add "X-Amz-Date", valid_613671
  var valid_613672 = header.getOrDefault("X-Amz-Credential")
  valid_613672 = validateParameter(valid_613672, JString, required = false,
                                 default = nil)
  if valid_613672 != nil:
    section.add "X-Amz-Credential", valid_613672
  var valid_613673 = header.getOrDefault("X-Amz-Security-Token")
  valid_613673 = validateParameter(valid_613673, JString, required = false,
                                 default = nil)
  if valid_613673 != nil:
    section.add "X-Amz-Security-Token", valid_613673
  var valid_613674 = header.getOrDefault("X-Amz-Algorithm")
  valid_613674 = validateParameter(valid_613674, JString, required = false,
                                 default = nil)
  if valid_613674 != nil:
    section.add "X-Amz-Algorithm", valid_613674
  var valid_613675 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613675 = validateParameter(valid_613675, JString, required = false,
                                 default = nil)
  if valid_613675 != nil:
    section.add "X-Amz-SignedHeaders", valid_613675
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613676: Call_GetCloudFrontOriginAccessIdentityConfig20190326_613665;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Get the configuration information about an origin access identity. 
  ## 
  let valid = call_613676.validator(path, query, header, formData, body)
  let scheme = call_613676.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613676.url(scheme.get, call_613676.host, call_613676.base,
                         call_613676.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613676, url, valid)

proc call*(call_613677: Call_GetCloudFrontOriginAccessIdentityConfig20190326_613665;
          Id: string): Recallable =
  ## getCloudFrontOriginAccessIdentityConfig20190326
  ## Get the configuration information about an origin access identity. 
  ##   Id: string (required)
  ##     : The identity's ID. 
  var path_613678 = newJObject()
  add(path_613678, "Id", newJString(Id))
  result = call_613677.call(path_613678, nil, nil, nil, nil)

var getCloudFrontOriginAccessIdentityConfig20190326* = Call_GetCloudFrontOriginAccessIdentityConfig20190326_613665(
    name: "getCloudFrontOriginAccessIdentityConfig20190326",
    meth: HttpMethod.HttpGet, host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/origin-access-identity/cloudfront/{Id}/config",
    validator: validate_GetCloudFrontOriginAccessIdentityConfig20190326_613666,
    base: "/", url: url_GetCloudFrontOriginAccessIdentityConfig20190326_613667,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDistribution20190326_613710 = ref object of OpenApiRestCall_612658
proc url_UpdateDistribution20190326_613712(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2019-03-26/distribution/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDistribution20190326_613711(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates the configuration for a web distribution. </p> <important> <p>When you update a distribution, there are more required fields than when you create a distribution. When you update your distribution by using this API action, follow the steps here to get the current configuration and then make your updates, to make sure that you include all of the required fields. To view a summary, see <a href="https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-overview-required-fields.html">Required Fields for Create Distribution and Update Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> </important> <p>The update process includes getting the current distribution configuration, updating the XML document that is returned to make your changes, and then submitting an <code>UpdateDistribution</code> request to make the updates.</p> <p>For information about updating a distribution using the CloudFront console instead, see <a href="https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-web-creating-console.html">Creating a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <p> <b>To update a web distribution using the CloudFront API</b> </p> <ol> <li> <p>Submit a <a href="https://docs.aws.amazon.com/cloudfront/latest/APIReference/API_GetDistributionConfig.html">GetDistributionConfig</a> request to get the current configuration and an <code>Etag</code> header for the distribution.</p> <note> <p>If you update the distribution again, you must get a new <code>Etag</code> header.</p> </note> </li> <li> <p>Update the XML document that was returned in the response to your <code>GetDistributionConfig</code> request to include your changes. </p> <important> <p>When you edit the XML file, be aware of the following:</p> <ul> <li> <p>You must strip out the ETag parameter that is returned.</p> </li> <li> <p>Additional fields are required when you update a distribution. There may be fields included in the XML file for features that you haven't configured for your distribution. This is expected and required to successfully update the distribution.</p> </li> <li> <p>You can't change the value of <code>CallerReference</code>. If you try to change this value, CloudFront returns an <code>IllegalUpdate</code> error. </p> </li> <li> <p>The new configuration replaces the existing configuration; the values that you specify in an <code>UpdateDistribution</code> request are not merged into your existing configuration. When you add, delete, or replace values in an element that allows multiple values (for example, <code>CNAME</code>), you must specify all of the values that you want to appear in the updated distribution. In addition, you must update the corresponding <code>Quantity</code> element.</p> </li> </ul> </important> </li> <li> <p>Submit an <code>UpdateDistribution</code> request to update the configuration for your distribution:</p> <ul> <li> <p>In the request body, include the XML document that you updated in Step 2. The request body must include an XML document with a <code>DistributionConfig</code> element.</p> </li> <li> <p>Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GetDistributionConfig</code> request in Step 1.</p> </li> </ul> </li> <li> <p>Review the response to the <code>UpdateDistribution</code> request to confirm that the configuration was successfully updated.</p> </li> <li> <p>Optional: Submit a <a href="https://docs.aws.amazon.com/cloudfront/latest/APIReference/API_GetDistribution.html">GetDistribution</a> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> </ol>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The distribution's id.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_613713 = path.getOrDefault("Id")
  valid_613713 = validateParameter(valid_613713, JString, required = true,
                                 default = nil)
  if valid_613713 != nil:
    section.add "Id", valid_613713
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
  var valid_613714 = header.getOrDefault("X-Amz-Signature")
  valid_613714 = validateParameter(valid_613714, JString, required = false,
                                 default = nil)
  if valid_613714 != nil:
    section.add "X-Amz-Signature", valid_613714
  var valid_613715 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613715 = validateParameter(valid_613715, JString, required = false,
                                 default = nil)
  if valid_613715 != nil:
    section.add "X-Amz-Content-Sha256", valid_613715
  var valid_613716 = header.getOrDefault("X-Amz-Date")
  valid_613716 = validateParameter(valid_613716, JString, required = false,
                                 default = nil)
  if valid_613716 != nil:
    section.add "X-Amz-Date", valid_613716
  var valid_613717 = header.getOrDefault("X-Amz-Credential")
  valid_613717 = validateParameter(valid_613717, JString, required = false,
                                 default = nil)
  if valid_613717 != nil:
    section.add "X-Amz-Credential", valid_613717
  var valid_613718 = header.getOrDefault("X-Amz-Security-Token")
  valid_613718 = validateParameter(valid_613718, JString, required = false,
                                 default = nil)
  if valid_613718 != nil:
    section.add "X-Amz-Security-Token", valid_613718
  var valid_613719 = header.getOrDefault("If-Match")
  valid_613719 = validateParameter(valid_613719, JString, required = false,
                                 default = nil)
  if valid_613719 != nil:
    section.add "If-Match", valid_613719
  var valid_613720 = header.getOrDefault("X-Amz-Algorithm")
  valid_613720 = validateParameter(valid_613720, JString, required = false,
                                 default = nil)
  if valid_613720 != nil:
    section.add "X-Amz-Algorithm", valid_613720
  var valid_613721 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613721 = validateParameter(valid_613721, JString, required = false,
                                 default = nil)
  if valid_613721 != nil:
    section.add "X-Amz-SignedHeaders", valid_613721
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613723: Call_UpdateDistribution20190326_613710; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the configuration for a web distribution. </p> <important> <p>When you update a distribution, there are more required fields than when you create a distribution. When you update your distribution by using this API action, follow the steps here to get the current configuration and then make your updates, to make sure that you include all of the required fields. To view a summary, see <a href="https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-overview-required-fields.html">Required Fields for Create Distribution and Update Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> </important> <p>The update process includes getting the current distribution configuration, updating the XML document that is returned to make your changes, and then submitting an <code>UpdateDistribution</code> request to make the updates.</p> <p>For information about updating a distribution using the CloudFront console instead, see <a href="https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-web-creating-console.html">Creating a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <p> <b>To update a web distribution using the CloudFront API</b> </p> <ol> <li> <p>Submit a <a href="https://docs.aws.amazon.com/cloudfront/latest/APIReference/API_GetDistributionConfig.html">GetDistributionConfig</a> request to get the current configuration and an <code>Etag</code> header for the distribution.</p> <note> <p>If you update the distribution again, you must get a new <code>Etag</code> header.</p> </note> </li> <li> <p>Update the XML document that was returned in the response to your <code>GetDistributionConfig</code> request to include your changes. </p> <important> <p>When you edit the XML file, be aware of the following:</p> <ul> <li> <p>You must strip out the ETag parameter that is returned.</p> </li> <li> <p>Additional fields are required when you update a distribution. There may be fields included in the XML file for features that you haven't configured for your distribution. This is expected and required to successfully update the distribution.</p> </li> <li> <p>You can't change the value of <code>CallerReference</code>. If you try to change this value, CloudFront returns an <code>IllegalUpdate</code> error. </p> </li> <li> <p>The new configuration replaces the existing configuration; the values that you specify in an <code>UpdateDistribution</code> request are not merged into your existing configuration. When you add, delete, or replace values in an element that allows multiple values (for example, <code>CNAME</code>), you must specify all of the values that you want to appear in the updated distribution. In addition, you must update the corresponding <code>Quantity</code> element.</p> </li> </ul> </important> </li> <li> <p>Submit an <code>UpdateDistribution</code> request to update the configuration for your distribution:</p> <ul> <li> <p>In the request body, include the XML document that you updated in Step 2. The request body must include an XML document with a <code>DistributionConfig</code> element.</p> </li> <li> <p>Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GetDistributionConfig</code> request in Step 1.</p> </li> </ul> </li> <li> <p>Review the response to the <code>UpdateDistribution</code> request to confirm that the configuration was successfully updated.</p> </li> <li> <p>Optional: Submit a <a href="https://docs.aws.amazon.com/cloudfront/latest/APIReference/API_GetDistribution.html">GetDistribution</a> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> </ol>
  ## 
  let valid = call_613723.validator(path, query, header, formData, body)
  let scheme = call_613723.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613723.url(scheme.get, call_613723.host, call_613723.base,
                         call_613723.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613723, url, valid)

proc call*(call_613724: Call_UpdateDistribution20190326_613710; body: JsonNode;
          Id: string): Recallable =
  ## updateDistribution20190326
  ## <p>Updates the configuration for a web distribution. </p> <important> <p>When you update a distribution, there are more required fields than when you create a distribution. When you update your distribution by using this API action, follow the steps here to get the current configuration and then make your updates, to make sure that you include all of the required fields. To view a summary, see <a href="https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-overview-required-fields.html">Required Fields for Create Distribution and Update Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> </important> <p>The update process includes getting the current distribution configuration, updating the XML document that is returned to make your changes, and then submitting an <code>UpdateDistribution</code> request to make the updates.</p> <p>For information about updating a distribution using the CloudFront console instead, see <a href="https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-web-creating-console.html">Creating a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <p> <b>To update a web distribution using the CloudFront API</b> </p> <ol> <li> <p>Submit a <a href="https://docs.aws.amazon.com/cloudfront/latest/APIReference/API_GetDistributionConfig.html">GetDistributionConfig</a> request to get the current configuration and an <code>Etag</code> header for the distribution.</p> <note> <p>If you update the distribution again, you must get a new <code>Etag</code> header.</p> </note> </li> <li> <p>Update the XML document that was returned in the response to your <code>GetDistributionConfig</code> request to include your changes. </p> <important> <p>When you edit the XML file, be aware of the following:</p> <ul> <li> <p>You must strip out the ETag parameter that is returned.</p> </li> <li> <p>Additional fields are required when you update a distribution. There may be fields included in the XML file for features that you haven't configured for your distribution. This is expected and required to successfully update the distribution.</p> </li> <li> <p>You can't change the value of <code>CallerReference</code>. If you try to change this value, CloudFront returns an <code>IllegalUpdate</code> error. </p> </li> <li> <p>The new configuration replaces the existing configuration; the values that you specify in an <code>UpdateDistribution</code> request are not merged into your existing configuration. When you add, delete, or replace values in an element that allows multiple values (for example, <code>CNAME</code>), you must specify all of the values that you want to appear in the updated distribution. In addition, you must update the corresponding <code>Quantity</code> element.</p> </li> </ul> </important> </li> <li> <p>Submit an <code>UpdateDistribution</code> request to update the configuration for your distribution:</p> <ul> <li> <p>In the request body, include the XML document that you updated in Step 2. The request body must include an XML document with a <code>DistributionConfig</code> element.</p> </li> <li> <p>Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GetDistributionConfig</code> request in Step 1.</p> </li> </ul> </li> <li> <p>Review the response to the <code>UpdateDistribution</code> request to confirm that the configuration was successfully updated.</p> </li> <li> <p>Optional: Submit a <a href="https://docs.aws.amazon.com/cloudfront/latest/APIReference/API_GetDistribution.html">GetDistribution</a> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> </ol>
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : The distribution's id.
  var path_613725 = newJObject()
  var body_613726 = newJObject()
  if body != nil:
    body_613726 = body
  add(path_613725, "Id", newJString(Id))
  result = call_613724.call(path_613725, nil, nil, nil, body_613726)

var updateDistribution20190326* = Call_UpdateDistribution20190326_613710(
    name: "updateDistribution20190326", meth: HttpMethod.HttpPut,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/distribution/{Id}/config",
    validator: validate_UpdateDistribution20190326_613711, base: "/",
    url: url_UpdateDistribution20190326_613712,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDistributionConfig20190326_613696 = ref object of OpenApiRestCall_612658
proc url_GetDistributionConfig20190326_613698(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2019-03-26/distribution/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDistributionConfig20190326_613697(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get the configuration information about a distribution. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The distribution's ID. If the ID is empty, an empty distribution configuration is returned.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_613699 = path.getOrDefault("Id")
  valid_613699 = validateParameter(valid_613699, JString, required = true,
                                 default = nil)
  if valid_613699 != nil:
    section.add "Id", valid_613699
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
  var valid_613700 = header.getOrDefault("X-Amz-Signature")
  valid_613700 = validateParameter(valid_613700, JString, required = false,
                                 default = nil)
  if valid_613700 != nil:
    section.add "X-Amz-Signature", valid_613700
  var valid_613701 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613701 = validateParameter(valid_613701, JString, required = false,
                                 default = nil)
  if valid_613701 != nil:
    section.add "X-Amz-Content-Sha256", valid_613701
  var valid_613702 = header.getOrDefault("X-Amz-Date")
  valid_613702 = validateParameter(valid_613702, JString, required = false,
                                 default = nil)
  if valid_613702 != nil:
    section.add "X-Amz-Date", valid_613702
  var valid_613703 = header.getOrDefault("X-Amz-Credential")
  valid_613703 = validateParameter(valid_613703, JString, required = false,
                                 default = nil)
  if valid_613703 != nil:
    section.add "X-Amz-Credential", valid_613703
  var valid_613704 = header.getOrDefault("X-Amz-Security-Token")
  valid_613704 = validateParameter(valid_613704, JString, required = false,
                                 default = nil)
  if valid_613704 != nil:
    section.add "X-Amz-Security-Token", valid_613704
  var valid_613705 = header.getOrDefault("X-Amz-Algorithm")
  valid_613705 = validateParameter(valid_613705, JString, required = false,
                                 default = nil)
  if valid_613705 != nil:
    section.add "X-Amz-Algorithm", valid_613705
  var valid_613706 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613706 = validateParameter(valid_613706, JString, required = false,
                                 default = nil)
  if valid_613706 != nil:
    section.add "X-Amz-SignedHeaders", valid_613706
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613707: Call_GetDistributionConfig20190326_613696; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the configuration information about a distribution. 
  ## 
  let valid = call_613707.validator(path, query, header, formData, body)
  let scheme = call_613707.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613707.url(scheme.get, call_613707.host, call_613707.base,
                         call_613707.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613707, url, valid)

proc call*(call_613708: Call_GetDistributionConfig20190326_613696; Id: string): Recallable =
  ## getDistributionConfig20190326
  ## Get the configuration information about a distribution. 
  ##   Id: string (required)
  ##     : The distribution's ID. If the ID is empty, an empty distribution configuration is returned.
  var path_613709 = newJObject()
  add(path_613709, "Id", newJString(Id))
  result = call_613708.call(path_613709, nil, nil, nil, nil)

var getDistributionConfig20190326* = Call_GetDistributionConfig20190326_613696(
    name: "getDistributionConfig20190326", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/distribution/{Id}/config",
    validator: validate_GetDistributionConfig20190326_613697, base: "/",
    url: url_GetDistributionConfig20190326_613698,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFieldLevelEncryptionConfig20190326_613741 = ref object of OpenApiRestCall_612658
proc url_UpdateFieldLevelEncryptionConfig20190326_613743(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2019-03-26/field-level-encryption/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateFieldLevelEncryptionConfig20190326_613742(path: JsonNode;
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
  var valid_613744 = path.getOrDefault("Id")
  valid_613744 = validateParameter(valid_613744, JString, required = true,
                                 default = nil)
  if valid_613744 != nil:
    section.add "Id", valid_613744
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
  var valid_613745 = header.getOrDefault("X-Amz-Signature")
  valid_613745 = validateParameter(valid_613745, JString, required = false,
                                 default = nil)
  if valid_613745 != nil:
    section.add "X-Amz-Signature", valid_613745
  var valid_613746 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613746 = validateParameter(valid_613746, JString, required = false,
                                 default = nil)
  if valid_613746 != nil:
    section.add "X-Amz-Content-Sha256", valid_613746
  var valid_613747 = header.getOrDefault("X-Amz-Date")
  valid_613747 = validateParameter(valid_613747, JString, required = false,
                                 default = nil)
  if valid_613747 != nil:
    section.add "X-Amz-Date", valid_613747
  var valid_613748 = header.getOrDefault("X-Amz-Credential")
  valid_613748 = validateParameter(valid_613748, JString, required = false,
                                 default = nil)
  if valid_613748 != nil:
    section.add "X-Amz-Credential", valid_613748
  var valid_613749 = header.getOrDefault("X-Amz-Security-Token")
  valid_613749 = validateParameter(valid_613749, JString, required = false,
                                 default = nil)
  if valid_613749 != nil:
    section.add "X-Amz-Security-Token", valid_613749
  var valid_613750 = header.getOrDefault("If-Match")
  valid_613750 = validateParameter(valid_613750, JString, required = false,
                                 default = nil)
  if valid_613750 != nil:
    section.add "If-Match", valid_613750
  var valid_613751 = header.getOrDefault("X-Amz-Algorithm")
  valid_613751 = validateParameter(valid_613751, JString, required = false,
                                 default = nil)
  if valid_613751 != nil:
    section.add "X-Amz-Algorithm", valid_613751
  var valid_613752 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613752 = validateParameter(valid_613752, JString, required = false,
                                 default = nil)
  if valid_613752 != nil:
    section.add "X-Amz-SignedHeaders", valid_613752
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613754: Call_UpdateFieldLevelEncryptionConfig20190326_613741;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Update a field-level encryption configuration. 
  ## 
  let valid = call_613754.validator(path, query, header, formData, body)
  let scheme = call_613754.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613754.url(scheme.get, call_613754.host, call_613754.base,
                         call_613754.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613754, url, valid)

proc call*(call_613755: Call_UpdateFieldLevelEncryptionConfig20190326_613741;
          body: JsonNode; Id: string): Recallable =
  ## updateFieldLevelEncryptionConfig20190326
  ## Update a field-level encryption configuration. 
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : The ID of the configuration you want to update.
  var path_613756 = newJObject()
  var body_613757 = newJObject()
  if body != nil:
    body_613757 = body
  add(path_613756, "Id", newJString(Id))
  result = call_613755.call(path_613756, nil, nil, nil, body_613757)

var updateFieldLevelEncryptionConfig20190326* = Call_UpdateFieldLevelEncryptionConfig20190326_613741(
    name: "updateFieldLevelEncryptionConfig20190326", meth: HttpMethod.HttpPut,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/field-level-encryption/{Id}/config",
    validator: validate_UpdateFieldLevelEncryptionConfig20190326_613742,
    base: "/", url: url_UpdateFieldLevelEncryptionConfig20190326_613743,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFieldLevelEncryptionConfig20190326_613727 = ref object of OpenApiRestCall_612658
proc url_GetFieldLevelEncryptionConfig20190326_613729(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2019-03-26/field-level-encryption/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFieldLevelEncryptionConfig20190326_613728(path: JsonNode;
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
  var valid_613730 = path.getOrDefault("Id")
  valid_613730 = validateParameter(valid_613730, JString, required = true,
                                 default = nil)
  if valid_613730 != nil:
    section.add "Id", valid_613730
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
  var valid_613731 = header.getOrDefault("X-Amz-Signature")
  valid_613731 = validateParameter(valid_613731, JString, required = false,
                                 default = nil)
  if valid_613731 != nil:
    section.add "X-Amz-Signature", valid_613731
  var valid_613732 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613732 = validateParameter(valid_613732, JString, required = false,
                                 default = nil)
  if valid_613732 != nil:
    section.add "X-Amz-Content-Sha256", valid_613732
  var valid_613733 = header.getOrDefault("X-Amz-Date")
  valid_613733 = validateParameter(valid_613733, JString, required = false,
                                 default = nil)
  if valid_613733 != nil:
    section.add "X-Amz-Date", valid_613733
  var valid_613734 = header.getOrDefault("X-Amz-Credential")
  valid_613734 = validateParameter(valid_613734, JString, required = false,
                                 default = nil)
  if valid_613734 != nil:
    section.add "X-Amz-Credential", valid_613734
  var valid_613735 = header.getOrDefault("X-Amz-Security-Token")
  valid_613735 = validateParameter(valid_613735, JString, required = false,
                                 default = nil)
  if valid_613735 != nil:
    section.add "X-Amz-Security-Token", valid_613735
  var valid_613736 = header.getOrDefault("X-Amz-Algorithm")
  valid_613736 = validateParameter(valid_613736, JString, required = false,
                                 default = nil)
  if valid_613736 != nil:
    section.add "X-Amz-Algorithm", valid_613736
  var valid_613737 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613737 = validateParameter(valid_613737, JString, required = false,
                                 default = nil)
  if valid_613737 != nil:
    section.add "X-Amz-SignedHeaders", valid_613737
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613738: Call_GetFieldLevelEncryptionConfig20190326_613727;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Get the field-level encryption configuration information.
  ## 
  let valid = call_613738.validator(path, query, header, formData, body)
  let scheme = call_613738.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613738.url(scheme.get, call_613738.host, call_613738.base,
                         call_613738.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613738, url, valid)

proc call*(call_613739: Call_GetFieldLevelEncryptionConfig20190326_613727;
          Id: string): Recallable =
  ## getFieldLevelEncryptionConfig20190326
  ## Get the field-level encryption configuration information.
  ##   Id: string (required)
  ##     : Request the ID for the field-level encryption configuration information.
  var path_613740 = newJObject()
  add(path_613740, "Id", newJString(Id))
  result = call_613739.call(path_613740, nil, nil, nil, nil)

var getFieldLevelEncryptionConfig20190326* = Call_GetFieldLevelEncryptionConfig20190326_613727(
    name: "getFieldLevelEncryptionConfig20190326", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/field-level-encryption/{Id}/config",
    validator: validate_GetFieldLevelEncryptionConfig20190326_613728, base: "/",
    url: url_GetFieldLevelEncryptionConfig20190326_613729,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFieldLevelEncryptionProfile20190326_613772 = ref object of OpenApiRestCall_612658
proc url_UpdateFieldLevelEncryptionProfile20190326_613774(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2019-03-26/field-level-encryption-profile/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateFieldLevelEncryptionProfile20190326_613773(path: JsonNode;
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
  var valid_613775 = path.getOrDefault("Id")
  valid_613775 = validateParameter(valid_613775, JString, required = true,
                                 default = nil)
  if valid_613775 != nil:
    section.add "Id", valid_613775
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
  var valid_613776 = header.getOrDefault("X-Amz-Signature")
  valid_613776 = validateParameter(valid_613776, JString, required = false,
                                 default = nil)
  if valid_613776 != nil:
    section.add "X-Amz-Signature", valid_613776
  var valid_613777 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613777 = validateParameter(valid_613777, JString, required = false,
                                 default = nil)
  if valid_613777 != nil:
    section.add "X-Amz-Content-Sha256", valid_613777
  var valid_613778 = header.getOrDefault("X-Amz-Date")
  valid_613778 = validateParameter(valid_613778, JString, required = false,
                                 default = nil)
  if valid_613778 != nil:
    section.add "X-Amz-Date", valid_613778
  var valid_613779 = header.getOrDefault("X-Amz-Credential")
  valid_613779 = validateParameter(valid_613779, JString, required = false,
                                 default = nil)
  if valid_613779 != nil:
    section.add "X-Amz-Credential", valid_613779
  var valid_613780 = header.getOrDefault("X-Amz-Security-Token")
  valid_613780 = validateParameter(valid_613780, JString, required = false,
                                 default = nil)
  if valid_613780 != nil:
    section.add "X-Amz-Security-Token", valid_613780
  var valid_613781 = header.getOrDefault("If-Match")
  valid_613781 = validateParameter(valid_613781, JString, required = false,
                                 default = nil)
  if valid_613781 != nil:
    section.add "If-Match", valid_613781
  var valid_613782 = header.getOrDefault("X-Amz-Algorithm")
  valid_613782 = validateParameter(valid_613782, JString, required = false,
                                 default = nil)
  if valid_613782 != nil:
    section.add "X-Amz-Algorithm", valid_613782
  var valid_613783 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613783 = validateParameter(valid_613783, JString, required = false,
                                 default = nil)
  if valid_613783 != nil:
    section.add "X-Amz-SignedHeaders", valid_613783
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613785: Call_UpdateFieldLevelEncryptionProfile20190326_613772;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Update a field-level encryption profile. 
  ## 
  let valid = call_613785.validator(path, query, header, formData, body)
  let scheme = call_613785.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613785.url(scheme.get, call_613785.host, call_613785.base,
                         call_613785.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613785, url, valid)

proc call*(call_613786: Call_UpdateFieldLevelEncryptionProfile20190326_613772;
          body: JsonNode; Id: string): Recallable =
  ## updateFieldLevelEncryptionProfile20190326
  ## Update a field-level encryption profile. 
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : The ID of the field-level encryption profile request. 
  var path_613787 = newJObject()
  var body_613788 = newJObject()
  if body != nil:
    body_613788 = body
  add(path_613787, "Id", newJString(Id))
  result = call_613786.call(path_613787, nil, nil, nil, body_613788)

var updateFieldLevelEncryptionProfile20190326* = Call_UpdateFieldLevelEncryptionProfile20190326_613772(
    name: "updateFieldLevelEncryptionProfile20190326", meth: HttpMethod.HttpPut,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/field-level-encryption-profile/{Id}/config",
    validator: validate_UpdateFieldLevelEncryptionProfile20190326_613773,
    base: "/", url: url_UpdateFieldLevelEncryptionProfile20190326_613774,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFieldLevelEncryptionProfileConfig20190326_613758 = ref object of OpenApiRestCall_612658
proc url_GetFieldLevelEncryptionProfileConfig20190326_613760(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2019-03-26/field-level-encryption-profile/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFieldLevelEncryptionProfileConfig20190326_613759(path: JsonNode;
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
  var valid_613761 = path.getOrDefault("Id")
  valid_613761 = validateParameter(valid_613761, JString, required = true,
                                 default = nil)
  if valid_613761 != nil:
    section.add "Id", valid_613761
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
  var valid_613762 = header.getOrDefault("X-Amz-Signature")
  valid_613762 = validateParameter(valid_613762, JString, required = false,
                                 default = nil)
  if valid_613762 != nil:
    section.add "X-Amz-Signature", valid_613762
  var valid_613763 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613763 = validateParameter(valid_613763, JString, required = false,
                                 default = nil)
  if valid_613763 != nil:
    section.add "X-Amz-Content-Sha256", valid_613763
  var valid_613764 = header.getOrDefault("X-Amz-Date")
  valid_613764 = validateParameter(valid_613764, JString, required = false,
                                 default = nil)
  if valid_613764 != nil:
    section.add "X-Amz-Date", valid_613764
  var valid_613765 = header.getOrDefault("X-Amz-Credential")
  valid_613765 = validateParameter(valid_613765, JString, required = false,
                                 default = nil)
  if valid_613765 != nil:
    section.add "X-Amz-Credential", valid_613765
  var valid_613766 = header.getOrDefault("X-Amz-Security-Token")
  valid_613766 = validateParameter(valid_613766, JString, required = false,
                                 default = nil)
  if valid_613766 != nil:
    section.add "X-Amz-Security-Token", valid_613766
  var valid_613767 = header.getOrDefault("X-Amz-Algorithm")
  valid_613767 = validateParameter(valid_613767, JString, required = false,
                                 default = nil)
  if valid_613767 != nil:
    section.add "X-Amz-Algorithm", valid_613767
  var valid_613768 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613768 = validateParameter(valid_613768, JString, required = false,
                                 default = nil)
  if valid_613768 != nil:
    section.add "X-Amz-SignedHeaders", valid_613768
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613769: Call_GetFieldLevelEncryptionProfileConfig20190326_613758;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Get the field-level encryption profile configuration information.
  ## 
  let valid = call_613769.validator(path, query, header, formData, body)
  let scheme = call_613769.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613769.url(scheme.get, call_613769.host, call_613769.base,
                         call_613769.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613769, url, valid)

proc call*(call_613770: Call_GetFieldLevelEncryptionProfileConfig20190326_613758;
          Id: string): Recallable =
  ## getFieldLevelEncryptionProfileConfig20190326
  ## Get the field-level encryption profile configuration information.
  ##   Id: string (required)
  ##     : Get the ID for the field-level encryption profile configuration information.
  var path_613771 = newJObject()
  add(path_613771, "Id", newJString(Id))
  result = call_613770.call(path_613771, nil, nil, nil, nil)

var getFieldLevelEncryptionProfileConfig20190326* = Call_GetFieldLevelEncryptionProfileConfig20190326_613758(
    name: "getFieldLevelEncryptionProfileConfig20190326",
    meth: HttpMethod.HttpGet, host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/field-level-encryption-profile/{Id}/config",
    validator: validate_GetFieldLevelEncryptionProfileConfig20190326_613759,
    base: "/", url: url_GetFieldLevelEncryptionProfileConfig20190326_613760,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInvalidation20190326_613789 = ref object of OpenApiRestCall_612658
proc url_GetInvalidation20190326_613791(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DistributionId" in path, "`DistributionId` is a required path parameter"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2019-03-26/distribution/"),
               (kind: VariableSegment, value: "DistributionId"),
               (kind: ConstantSegment, value: "/invalidation/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetInvalidation20190326_613790(path: JsonNode; query: JsonNode;
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
  var valid_613792 = path.getOrDefault("DistributionId")
  valid_613792 = validateParameter(valid_613792, JString, required = true,
                                 default = nil)
  if valid_613792 != nil:
    section.add "DistributionId", valid_613792
  var valid_613793 = path.getOrDefault("Id")
  valid_613793 = validateParameter(valid_613793, JString, required = true,
                                 default = nil)
  if valid_613793 != nil:
    section.add "Id", valid_613793
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
  var valid_613794 = header.getOrDefault("X-Amz-Signature")
  valid_613794 = validateParameter(valid_613794, JString, required = false,
                                 default = nil)
  if valid_613794 != nil:
    section.add "X-Amz-Signature", valid_613794
  var valid_613795 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613795 = validateParameter(valid_613795, JString, required = false,
                                 default = nil)
  if valid_613795 != nil:
    section.add "X-Amz-Content-Sha256", valid_613795
  var valid_613796 = header.getOrDefault("X-Amz-Date")
  valid_613796 = validateParameter(valid_613796, JString, required = false,
                                 default = nil)
  if valid_613796 != nil:
    section.add "X-Amz-Date", valid_613796
  var valid_613797 = header.getOrDefault("X-Amz-Credential")
  valid_613797 = validateParameter(valid_613797, JString, required = false,
                                 default = nil)
  if valid_613797 != nil:
    section.add "X-Amz-Credential", valid_613797
  var valid_613798 = header.getOrDefault("X-Amz-Security-Token")
  valid_613798 = validateParameter(valid_613798, JString, required = false,
                                 default = nil)
  if valid_613798 != nil:
    section.add "X-Amz-Security-Token", valid_613798
  var valid_613799 = header.getOrDefault("X-Amz-Algorithm")
  valid_613799 = validateParameter(valid_613799, JString, required = false,
                                 default = nil)
  if valid_613799 != nil:
    section.add "X-Amz-Algorithm", valid_613799
  var valid_613800 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613800 = validateParameter(valid_613800, JString, required = false,
                                 default = nil)
  if valid_613800 != nil:
    section.add "X-Amz-SignedHeaders", valid_613800
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613801: Call_GetInvalidation20190326_613789; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the information about an invalidation. 
  ## 
  let valid = call_613801.validator(path, query, header, formData, body)
  let scheme = call_613801.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613801.url(scheme.get, call_613801.host, call_613801.base,
                         call_613801.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613801, url, valid)

proc call*(call_613802: Call_GetInvalidation20190326_613789;
          DistributionId: string; Id: string): Recallable =
  ## getInvalidation20190326
  ## Get the information about an invalidation. 
  ##   DistributionId: string (required)
  ##                 : The distribution's ID.
  ##   Id: string (required)
  ##     : The identifier for the invalidation request, for example, <code>IDFDVBD632BHDS5</code>.
  var path_613803 = newJObject()
  add(path_613803, "DistributionId", newJString(DistributionId))
  add(path_613803, "Id", newJString(Id))
  result = call_613802.call(path_613803, nil, nil, nil, nil)

var getInvalidation20190326* = Call_GetInvalidation20190326_613789(
    name: "getInvalidation20190326", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/distribution/{DistributionId}/invalidation/{Id}",
    validator: validate_GetInvalidation20190326_613790, base: "/",
    url: url_GetInvalidation20190326_613791, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePublicKey20190326_613818 = ref object of OpenApiRestCall_612658
proc url_UpdatePublicKey20190326_613820(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2019-03-26/public-key/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdatePublicKey20190326_613819(path: JsonNode; query: JsonNode;
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
  var valid_613821 = path.getOrDefault("Id")
  valid_613821 = validateParameter(valid_613821, JString, required = true,
                                 default = nil)
  if valid_613821 != nil:
    section.add "Id", valid_613821
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
  var valid_613822 = header.getOrDefault("X-Amz-Signature")
  valid_613822 = validateParameter(valid_613822, JString, required = false,
                                 default = nil)
  if valid_613822 != nil:
    section.add "X-Amz-Signature", valid_613822
  var valid_613823 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613823 = validateParameter(valid_613823, JString, required = false,
                                 default = nil)
  if valid_613823 != nil:
    section.add "X-Amz-Content-Sha256", valid_613823
  var valid_613824 = header.getOrDefault("X-Amz-Date")
  valid_613824 = validateParameter(valid_613824, JString, required = false,
                                 default = nil)
  if valid_613824 != nil:
    section.add "X-Amz-Date", valid_613824
  var valid_613825 = header.getOrDefault("X-Amz-Credential")
  valid_613825 = validateParameter(valid_613825, JString, required = false,
                                 default = nil)
  if valid_613825 != nil:
    section.add "X-Amz-Credential", valid_613825
  var valid_613826 = header.getOrDefault("X-Amz-Security-Token")
  valid_613826 = validateParameter(valid_613826, JString, required = false,
                                 default = nil)
  if valid_613826 != nil:
    section.add "X-Amz-Security-Token", valid_613826
  var valid_613827 = header.getOrDefault("If-Match")
  valid_613827 = validateParameter(valid_613827, JString, required = false,
                                 default = nil)
  if valid_613827 != nil:
    section.add "If-Match", valid_613827
  var valid_613828 = header.getOrDefault("X-Amz-Algorithm")
  valid_613828 = validateParameter(valid_613828, JString, required = false,
                                 default = nil)
  if valid_613828 != nil:
    section.add "X-Amz-Algorithm", valid_613828
  var valid_613829 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613829 = validateParameter(valid_613829, JString, required = false,
                                 default = nil)
  if valid_613829 != nil:
    section.add "X-Amz-SignedHeaders", valid_613829
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613831: Call_UpdatePublicKey20190326_613818; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Update public key information. Note that the only value you can change is the comment.
  ## 
  let valid = call_613831.validator(path, query, header, formData, body)
  let scheme = call_613831.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613831.url(scheme.get, call_613831.host, call_613831.base,
                         call_613831.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613831, url, valid)

proc call*(call_613832: Call_UpdatePublicKey20190326_613818; body: JsonNode;
          Id: string): Recallable =
  ## updatePublicKey20190326
  ## Update public key information. Note that the only value you can change is the comment.
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : ID of the public key to be updated.
  var path_613833 = newJObject()
  var body_613834 = newJObject()
  if body != nil:
    body_613834 = body
  add(path_613833, "Id", newJString(Id))
  result = call_613832.call(path_613833, nil, nil, nil, body_613834)

var updatePublicKey20190326* = Call_UpdatePublicKey20190326_613818(
    name: "updatePublicKey20190326", meth: HttpMethod.HttpPut,
    host: "cloudfront.amazonaws.com", route: "/2019-03-26/public-key/{Id}/config",
    validator: validate_UpdatePublicKey20190326_613819, base: "/",
    url: url_UpdatePublicKey20190326_613820, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPublicKeyConfig20190326_613804 = ref object of OpenApiRestCall_612658
proc url_GetPublicKeyConfig20190326_613806(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2019-03-26/public-key/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetPublicKeyConfig20190326_613805(path: JsonNode; query: JsonNode;
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
  var valid_613807 = path.getOrDefault("Id")
  valid_613807 = validateParameter(valid_613807, JString, required = true,
                                 default = nil)
  if valid_613807 != nil:
    section.add "Id", valid_613807
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
  var valid_613808 = header.getOrDefault("X-Amz-Signature")
  valid_613808 = validateParameter(valid_613808, JString, required = false,
                                 default = nil)
  if valid_613808 != nil:
    section.add "X-Amz-Signature", valid_613808
  var valid_613809 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613809 = validateParameter(valid_613809, JString, required = false,
                                 default = nil)
  if valid_613809 != nil:
    section.add "X-Amz-Content-Sha256", valid_613809
  var valid_613810 = header.getOrDefault("X-Amz-Date")
  valid_613810 = validateParameter(valid_613810, JString, required = false,
                                 default = nil)
  if valid_613810 != nil:
    section.add "X-Amz-Date", valid_613810
  var valid_613811 = header.getOrDefault("X-Amz-Credential")
  valid_613811 = validateParameter(valid_613811, JString, required = false,
                                 default = nil)
  if valid_613811 != nil:
    section.add "X-Amz-Credential", valid_613811
  var valid_613812 = header.getOrDefault("X-Amz-Security-Token")
  valid_613812 = validateParameter(valid_613812, JString, required = false,
                                 default = nil)
  if valid_613812 != nil:
    section.add "X-Amz-Security-Token", valid_613812
  var valid_613813 = header.getOrDefault("X-Amz-Algorithm")
  valid_613813 = validateParameter(valid_613813, JString, required = false,
                                 default = nil)
  if valid_613813 != nil:
    section.add "X-Amz-Algorithm", valid_613813
  var valid_613814 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613814 = validateParameter(valid_613814, JString, required = false,
                                 default = nil)
  if valid_613814 != nil:
    section.add "X-Amz-SignedHeaders", valid_613814
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613815: Call_GetPublicKeyConfig20190326_613804; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Return public key configuration informaation
  ## 
  let valid = call_613815.validator(path, query, header, formData, body)
  let scheme = call_613815.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613815.url(scheme.get, call_613815.host, call_613815.base,
                         call_613815.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613815, url, valid)

proc call*(call_613816: Call_GetPublicKeyConfig20190326_613804; Id: string): Recallable =
  ## getPublicKeyConfig20190326
  ## Return public key configuration informaation
  ##   Id: string (required)
  ##     : Request the ID for the public key configuration.
  var path_613817 = newJObject()
  add(path_613817, "Id", newJString(Id))
  result = call_613816.call(path_613817, nil, nil, nil, nil)

var getPublicKeyConfig20190326* = Call_GetPublicKeyConfig20190326_613804(
    name: "getPublicKeyConfig20190326", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2019-03-26/public-key/{Id}/config",
    validator: validate_GetPublicKeyConfig20190326_613805, base: "/",
    url: url_GetPublicKeyConfig20190326_613806,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateStreamingDistribution20190326_613849 = ref object of OpenApiRestCall_612658
proc url_UpdateStreamingDistribution20190326_613851(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2019-03-26/streaming-distribution/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateStreamingDistribution20190326_613850(path: JsonNode;
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
  var valid_613852 = path.getOrDefault("Id")
  valid_613852 = validateParameter(valid_613852, JString, required = true,
                                 default = nil)
  if valid_613852 != nil:
    section.add "Id", valid_613852
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
  var valid_613853 = header.getOrDefault("X-Amz-Signature")
  valid_613853 = validateParameter(valid_613853, JString, required = false,
                                 default = nil)
  if valid_613853 != nil:
    section.add "X-Amz-Signature", valid_613853
  var valid_613854 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613854 = validateParameter(valid_613854, JString, required = false,
                                 default = nil)
  if valid_613854 != nil:
    section.add "X-Amz-Content-Sha256", valid_613854
  var valid_613855 = header.getOrDefault("X-Amz-Date")
  valid_613855 = validateParameter(valid_613855, JString, required = false,
                                 default = nil)
  if valid_613855 != nil:
    section.add "X-Amz-Date", valid_613855
  var valid_613856 = header.getOrDefault("X-Amz-Credential")
  valid_613856 = validateParameter(valid_613856, JString, required = false,
                                 default = nil)
  if valid_613856 != nil:
    section.add "X-Amz-Credential", valid_613856
  var valid_613857 = header.getOrDefault("X-Amz-Security-Token")
  valid_613857 = validateParameter(valid_613857, JString, required = false,
                                 default = nil)
  if valid_613857 != nil:
    section.add "X-Amz-Security-Token", valid_613857
  var valid_613858 = header.getOrDefault("If-Match")
  valid_613858 = validateParameter(valid_613858, JString, required = false,
                                 default = nil)
  if valid_613858 != nil:
    section.add "If-Match", valid_613858
  var valid_613859 = header.getOrDefault("X-Amz-Algorithm")
  valid_613859 = validateParameter(valid_613859, JString, required = false,
                                 default = nil)
  if valid_613859 != nil:
    section.add "X-Amz-Algorithm", valid_613859
  var valid_613860 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613860 = validateParameter(valid_613860, JString, required = false,
                                 default = nil)
  if valid_613860 != nil:
    section.add "X-Amz-SignedHeaders", valid_613860
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613862: Call_UpdateStreamingDistribution20190326_613849;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Update a streaming distribution. 
  ## 
  let valid = call_613862.validator(path, query, header, formData, body)
  let scheme = call_613862.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613862.url(scheme.get, call_613862.host, call_613862.base,
                         call_613862.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613862, url, valid)

proc call*(call_613863: Call_UpdateStreamingDistribution20190326_613849;
          body: JsonNode; Id: string): Recallable =
  ## updateStreamingDistribution20190326
  ## Update a streaming distribution. 
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : The streaming distribution's id.
  var path_613864 = newJObject()
  var body_613865 = newJObject()
  if body != nil:
    body_613865 = body
  add(path_613864, "Id", newJString(Id))
  result = call_613863.call(path_613864, nil, nil, nil, body_613865)

var updateStreamingDistribution20190326* = Call_UpdateStreamingDistribution20190326_613849(
    name: "updateStreamingDistribution20190326", meth: HttpMethod.HttpPut,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/streaming-distribution/{Id}/config",
    validator: validate_UpdateStreamingDistribution20190326_613850, base: "/",
    url: url_UpdateStreamingDistribution20190326_613851,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStreamingDistributionConfig20190326_613835 = ref object of OpenApiRestCall_612658
proc url_GetStreamingDistributionConfig20190326_613837(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2019-03-26/streaming-distribution/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetStreamingDistributionConfig20190326_613836(path: JsonNode;
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
  var valid_613838 = path.getOrDefault("Id")
  valid_613838 = validateParameter(valid_613838, JString, required = true,
                                 default = nil)
  if valid_613838 != nil:
    section.add "Id", valid_613838
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
  var valid_613839 = header.getOrDefault("X-Amz-Signature")
  valid_613839 = validateParameter(valid_613839, JString, required = false,
                                 default = nil)
  if valid_613839 != nil:
    section.add "X-Amz-Signature", valid_613839
  var valid_613840 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613840 = validateParameter(valid_613840, JString, required = false,
                                 default = nil)
  if valid_613840 != nil:
    section.add "X-Amz-Content-Sha256", valid_613840
  var valid_613841 = header.getOrDefault("X-Amz-Date")
  valid_613841 = validateParameter(valid_613841, JString, required = false,
                                 default = nil)
  if valid_613841 != nil:
    section.add "X-Amz-Date", valid_613841
  var valid_613842 = header.getOrDefault("X-Amz-Credential")
  valid_613842 = validateParameter(valid_613842, JString, required = false,
                                 default = nil)
  if valid_613842 != nil:
    section.add "X-Amz-Credential", valid_613842
  var valid_613843 = header.getOrDefault("X-Amz-Security-Token")
  valid_613843 = validateParameter(valid_613843, JString, required = false,
                                 default = nil)
  if valid_613843 != nil:
    section.add "X-Amz-Security-Token", valid_613843
  var valid_613844 = header.getOrDefault("X-Amz-Algorithm")
  valid_613844 = validateParameter(valid_613844, JString, required = false,
                                 default = nil)
  if valid_613844 != nil:
    section.add "X-Amz-Algorithm", valid_613844
  var valid_613845 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613845 = validateParameter(valid_613845, JString, required = false,
                                 default = nil)
  if valid_613845 != nil:
    section.add "X-Amz-SignedHeaders", valid_613845
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613846: Call_GetStreamingDistributionConfig20190326_613835;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Get the configuration information about a streaming distribution. 
  ## 
  let valid = call_613846.validator(path, query, header, formData, body)
  let scheme = call_613846.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613846.url(scheme.get, call_613846.host, call_613846.base,
                         call_613846.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613846, url, valid)

proc call*(call_613847: Call_GetStreamingDistributionConfig20190326_613835;
          Id: string): Recallable =
  ## getStreamingDistributionConfig20190326
  ## Get the configuration information about a streaming distribution. 
  ##   Id: string (required)
  ##     : The streaming distribution's ID.
  var path_613848 = newJObject()
  add(path_613848, "Id", newJString(Id))
  result = call_613847.call(path_613848, nil, nil, nil, nil)

var getStreamingDistributionConfig20190326* = Call_GetStreamingDistributionConfig20190326_613835(
    name: "getStreamingDistributionConfig20190326", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/streaming-distribution/{Id}/config",
    validator: validate_GetStreamingDistributionConfig20190326_613836, base: "/",
    url: url_GetStreamingDistributionConfig20190326_613837,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDistributionsByWebACLId20190326_613866 = ref object of OpenApiRestCall_612658
proc url_ListDistributionsByWebACLId20190326_613868(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "WebACLId" in path, "`WebACLId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2019-03-26/distributionsByWebACLId/"),
               (kind: VariableSegment, value: "WebACLId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDistributionsByWebACLId20190326_613867(path: JsonNode;
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
  var valid_613869 = path.getOrDefault("WebACLId")
  valid_613869 = validateParameter(valid_613869, JString, required = true,
                                 default = nil)
  if valid_613869 != nil:
    section.add "WebACLId", valid_613869
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Use <code>Marker</code> and <code>MaxItems</code> to control pagination of results. If you have more than <code>MaxItems</code> distributions that satisfy the request, the response includes a <code>NextMarker</code> element. To get the next page of results, submit another request. For the value of <code>Marker</code>, specify the value of <code>NextMarker</code> from the last response. (For the first request, omit <code>Marker</code>.) 
  ##   MaxItems: JString
  ##           : The maximum number of distributions that you want CloudFront to return in the response body. The maximum and default values are both 100.
  section = newJObject()
  var valid_613870 = query.getOrDefault("Marker")
  valid_613870 = validateParameter(valid_613870, JString, required = false,
                                 default = nil)
  if valid_613870 != nil:
    section.add "Marker", valid_613870
  var valid_613871 = query.getOrDefault("MaxItems")
  valid_613871 = validateParameter(valid_613871, JString, required = false,
                                 default = nil)
  if valid_613871 != nil:
    section.add "MaxItems", valid_613871
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
  var valid_613872 = header.getOrDefault("X-Amz-Signature")
  valid_613872 = validateParameter(valid_613872, JString, required = false,
                                 default = nil)
  if valid_613872 != nil:
    section.add "X-Amz-Signature", valid_613872
  var valid_613873 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613873 = validateParameter(valid_613873, JString, required = false,
                                 default = nil)
  if valid_613873 != nil:
    section.add "X-Amz-Content-Sha256", valid_613873
  var valid_613874 = header.getOrDefault("X-Amz-Date")
  valid_613874 = validateParameter(valid_613874, JString, required = false,
                                 default = nil)
  if valid_613874 != nil:
    section.add "X-Amz-Date", valid_613874
  var valid_613875 = header.getOrDefault("X-Amz-Credential")
  valid_613875 = validateParameter(valid_613875, JString, required = false,
                                 default = nil)
  if valid_613875 != nil:
    section.add "X-Amz-Credential", valid_613875
  var valid_613876 = header.getOrDefault("X-Amz-Security-Token")
  valid_613876 = validateParameter(valid_613876, JString, required = false,
                                 default = nil)
  if valid_613876 != nil:
    section.add "X-Amz-Security-Token", valid_613876
  var valid_613877 = header.getOrDefault("X-Amz-Algorithm")
  valid_613877 = validateParameter(valid_613877, JString, required = false,
                                 default = nil)
  if valid_613877 != nil:
    section.add "X-Amz-Algorithm", valid_613877
  var valid_613878 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613878 = validateParameter(valid_613878, JString, required = false,
                                 default = nil)
  if valid_613878 != nil:
    section.add "X-Amz-SignedHeaders", valid_613878
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613879: Call_ListDistributionsByWebACLId20190326_613866;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## List the distributions that are associated with a specified AWS WAF web ACL. 
  ## 
  let valid = call_613879.validator(path, query, header, formData, body)
  let scheme = call_613879.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613879.url(scheme.get, call_613879.host, call_613879.base,
                         call_613879.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613879, url, valid)

proc call*(call_613880: Call_ListDistributionsByWebACLId20190326_613866;
          WebACLId: string; Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listDistributionsByWebACLId20190326
  ## List the distributions that are associated with a specified AWS WAF web ACL. 
  ##   Marker: string
  ##         : Use <code>Marker</code> and <code>MaxItems</code> to control pagination of results. If you have more than <code>MaxItems</code> distributions that satisfy the request, the response includes a <code>NextMarker</code> element. To get the next page of results, submit another request. For the value of <code>Marker</code>, specify the value of <code>NextMarker</code> from the last response. (For the first request, omit <code>Marker</code>.) 
  ##   MaxItems: string
  ##           : The maximum number of distributions that you want CloudFront to return in the response body. The maximum and default values are both 100.
  ##   WebACLId: string (required)
  ##           : The ID of the AWS WAF web ACL that you want to list the associated distributions. If you specify "null" for the ID, the request returns a list of the distributions that aren't associated with a web ACL. 
  var path_613881 = newJObject()
  var query_613882 = newJObject()
  add(query_613882, "Marker", newJString(Marker))
  add(query_613882, "MaxItems", newJString(MaxItems))
  add(path_613881, "WebACLId", newJString(WebACLId))
  result = call_613880.call(path_613881, query_613882, nil, nil, nil)

var listDistributionsByWebACLId20190326* = Call_ListDistributionsByWebACLId20190326_613866(
    name: "listDistributionsByWebACLId20190326", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/distributionsByWebACLId/{WebACLId}",
    validator: validate_ListDistributionsByWebACLId20190326_613867, base: "/",
    url: url_ListDistributionsByWebACLId20190326_613868,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource20190326_613883 = ref object of OpenApiRestCall_612658
proc url_ListTagsForResource20190326_613885(protocol: Scheme; host: string;
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

proc validate_ListTagsForResource20190326_613884(path: JsonNode; query: JsonNode;
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
  var valid_613886 = query.getOrDefault("Resource")
  valid_613886 = validateParameter(valid_613886, JString, required = true,
                                 default = nil)
  if valid_613886 != nil:
    section.add "Resource", valid_613886
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
  var valid_613887 = header.getOrDefault("X-Amz-Signature")
  valid_613887 = validateParameter(valid_613887, JString, required = false,
                                 default = nil)
  if valid_613887 != nil:
    section.add "X-Amz-Signature", valid_613887
  var valid_613888 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613888 = validateParameter(valid_613888, JString, required = false,
                                 default = nil)
  if valid_613888 != nil:
    section.add "X-Amz-Content-Sha256", valid_613888
  var valid_613889 = header.getOrDefault("X-Amz-Date")
  valid_613889 = validateParameter(valid_613889, JString, required = false,
                                 default = nil)
  if valid_613889 != nil:
    section.add "X-Amz-Date", valid_613889
  var valid_613890 = header.getOrDefault("X-Amz-Credential")
  valid_613890 = validateParameter(valid_613890, JString, required = false,
                                 default = nil)
  if valid_613890 != nil:
    section.add "X-Amz-Credential", valid_613890
  var valid_613891 = header.getOrDefault("X-Amz-Security-Token")
  valid_613891 = validateParameter(valid_613891, JString, required = false,
                                 default = nil)
  if valid_613891 != nil:
    section.add "X-Amz-Security-Token", valid_613891
  var valid_613892 = header.getOrDefault("X-Amz-Algorithm")
  valid_613892 = validateParameter(valid_613892, JString, required = false,
                                 default = nil)
  if valid_613892 != nil:
    section.add "X-Amz-Algorithm", valid_613892
  var valid_613893 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613893 = validateParameter(valid_613893, JString, required = false,
                                 default = nil)
  if valid_613893 != nil:
    section.add "X-Amz-SignedHeaders", valid_613893
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613894: Call_ListTagsForResource20190326_613883; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List tags for a CloudFront resource.
  ## 
  let valid = call_613894.validator(path, query, header, formData, body)
  let scheme = call_613894.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613894.url(scheme.get, call_613894.host, call_613894.base,
                         call_613894.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613894, url, valid)

proc call*(call_613895: Call_ListTagsForResource20190326_613883; Resource: string): Recallable =
  ## listTagsForResource20190326
  ## List tags for a CloudFront resource.
  ##   Resource: string (required)
  ##           :  An ARN of a CloudFront resource.
  var query_613896 = newJObject()
  add(query_613896, "Resource", newJString(Resource))
  result = call_613895.call(nil, query_613896, nil, nil, nil)

var listTagsForResource20190326* = Call_ListTagsForResource20190326_613883(
    name: "listTagsForResource20190326", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2019-03-26/tagging#Resource",
    validator: validate_ListTagsForResource20190326_613884, base: "/",
    url: url_ListTagsForResource20190326_613885,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource20190326_613897 = ref object of OpenApiRestCall_612658
proc url_TagResource20190326_613899(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource20190326_613898(path: JsonNode; query: JsonNode;
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
  var valid_613900 = query.getOrDefault("Resource")
  valid_613900 = validateParameter(valid_613900, JString, required = true,
                                 default = nil)
  if valid_613900 != nil:
    section.add "Resource", valid_613900
  var valid_613914 = query.getOrDefault("Operation")
  valid_613914 = validateParameter(valid_613914, JString, required = true,
                                 default = newJString("Tag"))
  if valid_613914 != nil:
    section.add "Operation", valid_613914
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
  var valid_613915 = header.getOrDefault("X-Amz-Signature")
  valid_613915 = validateParameter(valid_613915, JString, required = false,
                                 default = nil)
  if valid_613915 != nil:
    section.add "X-Amz-Signature", valid_613915
  var valid_613916 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613916 = validateParameter(valid_613916, JString, required = false,
                                 default = nil)
  if valid_613916 != nil:
    section.add "X-Amz-Content-Sha256", valid_613916
  var valid_613917 = header.getOrDefault("X-Amz-Date")
  valid_613917 = validateParameter(valid_613917, JString, required = false,
                                 default = nil)
  if valid_613917 != nil:
    section.add "X-Amz-Date", valid_613917
  var valid_613918 = header.getOrDefault("X-Amz-Credential")
  valid_613918 = validateParameter(valid_613918, JString, required = false,
                                 default = nil)
  if valid_613918 != nil:
    section.add "X-Amz-Credential", valid_613918
  var valid_613919 = header.getOrDefault("X-Amz-Security-Token")
  valid_613919 = validateParameter(valid_613919, JString, required = false,
                                 default = nil)
  if valid_613919 != nil:
    section.add "X-Amz-Security-Token", valid_613919
  var valid_613920 = header.getOrDefault("X-Amz-Algorithm")
  valid_613920 = validateParameter(valid_613920, JString, required = false,
                                 default = nil)
  if valid_613920 != nil:
    section.add "X-Amz-Algorithm", valid_613920
  var valid_613921 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613921 = validateParameter(valid_613921, JString, required = false,
                                 default = nil)
  if valid_613921 != nil:
    section.add "X-Amz-SignedHeaders", valid_613921
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613923: Call_TagResource20190326_613897; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Add tags to a CloudFront resource.
  ## 
  let valid = call_613923.validator(path, query, header, formData, body)
  let scheme = call_613923.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613923.url(scheme.get, call_613923.host, call_613923.base,
                         call_613923.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613923, url, valid)

proc call*(call_613924: Call_TagResource20190326_613897; Resource: string;
          body: JsonNode; Operation: string = "Tag"): Recallable =
  ## tagResource20190326
  ## Add tags to a CloudFront resource.
  ##   Resource: string (required)
  ##           :  An ARN of a CloudFront resource.
  ##   Operation: string (required)
  ##   body: JObject (required)
  var query_613925 = newJObject()
  var body_613926 = newJObject()
  add(query_613925, "Resource", newJString(Resource))
  add(query_613925, "Operation", newJString(Operation))
  if body != nil:
    body_613926 = body
  result = call_613924.call(nil, query_613925, nil, nil, body_613926)

var tagResource20190326* = Call_TagResource20190326_613897(
    name: "tagResource20190326", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/tagging#Operation=Tag&Resource",
    validator: validate_TagResource20190326_613898, base: "/",
    url: url_TagResource20190326_613899, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource20190326_613927 = ref object of OpenApiRestCall_612658
proc url_UntagResource20190326_613929(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource20190326_613928(path: JsonNode; query: JsonNode;
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
  var valid_613930 = query.getOrDefault("Resource")
  valid_613930 = validateParameter(valid_613930, JString, required = true,
                                 default = nil)
  if valid_613930 != nil:
    section.add "Resource", valid_613930
  var valid_613931 = query.getOrDefault("Operation")
  valid_613931 = validateParameter(valid_613931, JString, required = true,
                                 default = newJString("Untag"))
  if valid_613931 != nil:
    section.add "Operation", valid_613931
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
  var valid_613932 = header.getOrDefault("X-Amz-Signature")
  valid_613932 = validateParameter(valid_613932, JString, required = false,
                                 default = nil)
  if valid_613932 != nil:
    section.add "X-Amz-Signature", valid_613932
  var valid_613933 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613933 = validateParameter(valid_613933, JString, required = false,
                                 default = nil)
  if valid_613933 != nil:
    section.add "X-Amz-Content-Sha256", valid_613933
  var valid_613934 = header.getOrDefault("X-Amz-Date")
  valid_613934 = validateParameter(valid_613934, JString, required = false,
                                 default = nil)
  if valid_613934 != nil:
    section.add "X-Amz-Date", valid_613934
  var valid_613935 = header.getOrDefault("X-Amz-Credential")
  valid_613935 = validateParameter(valid_613935, JString, required = false,
                                 default = nil)
  if valid_613935 != nil:
    section.add "X-Amz-Credential", valid_613935
  var valid_613936 = header.getOrDefault("X-Amz-Security-Token")
  valid_613936 = validateParameter(valid_613936, JString, required = false,
                                 default = nil)
  if valid_613936 != nil:
    section.add "X-Amz-Security-Token", valid_613936
  var valid_613937 = header.getOrDefault("X-Amz-Algorithm")
  valid_613937 = validateParameter(valid_613937, JString, required = false,
                                 default = nil)
  if valid_613937 != nil:
    section.add "X-Amz-Algorithm", valid_613937
  var valid_613938 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613938 = validateParameter(valid_613938, JString, required = false,
                                 default = nil)
  if valid_613938 != nil:
    section.add "X-Amz-SignedHeaders", valid_613938
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613940: Call_UntagResource20190326_613927; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove tags from a CloudFront resource.
  ## 
  let valid = call_613940.validator(path, query, header, formData, body)
  let scheme = call_613940.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613940.url(scheme.get, call_613940.host, call_613940.base,
                         call_613940.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613940, url, valid)

proc call*(call_613941: Call_UntagResource20190326_613927; Resource: string;
          body: JsonNode; Operation: string = "Untag"): Recallable =
  ## untagResource20190326
  ## Remove tags from a CloudFront resource.
  ##   Resource: string (required)
  ##           :  An ARN of a CloudFront resource.
  ##   Operation: string (required)
  ##   body: JObject (required)
  var query_613942 = newJObject()
  var body_613943 = newJObject()
  add(query_613942, "Resource", newJString(Resource))
  add(query_613942, "Operation", newJString(Operation))
  if body != nil:
    body_613943 = body
  result = call_613941.call(nil, query_613942, nil, nil, body_613943)

var untagResource20190326* = Call_UntagResource20190326_613927(
    name: "untagResource20190326", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/tagging#Operation=Untag&Resource",
    validator: validate_UntagResource20190326_613928, base: "/",
    url: url_UntagResource20190326_613929, schemes: {Scheme.Https, Scheme.Http})
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
  const
    XAmzSecurityToken = "X-Amz-Security-Token"
  if not headers.hasKey(XAmzSecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[XAmzSecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
