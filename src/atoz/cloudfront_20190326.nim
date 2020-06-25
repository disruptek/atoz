
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

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

  OpenApiRestCall_21625435 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625435](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625435): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"cn-northwest-1": "cloudfront.cn-northwest-1.amazonaws.com.cn", "cn-north-1": "cloudfront.cn-north-1.amazonaws.com.cn"}.toTable, Scheme.Https: {
      "cn-northwest-1": "cloudfront.cn-northwest-1.amazonaws.com.cn",
      "cn-north-1": "cloudfront.cn-north-1.amazonaws.com.cn"}.toTable}.toTable
const
  awsServiceName = "cloudfront"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_CreateCloudFrontOriginAccessIdentity20190326_21626019 = ref object of OpenApiRestCall_21625435
proc url_CreateCloudFrontOriginAccessIdentity20190326_21626021(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateCloudFrontOriginAccessIdentity20190326_21626020(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Creates a new origin access identity. If you're using Amazon S3 for your origin, you can use an origin access identity to require users to access your content using a CloudFront URL instead of the Amazon S3 URL. For more information about how to use origin access identities, see <a href="https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PrivateContent.html">Serving Private Content through CloudFront</a> in the <i>Amazon CloudFront Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626022 = header.getOrDefault("X-Amz-Date")
  valid_21626022 = validateParameter(valid_21626022, JString, required = false,
                                   default = nil)
  if valid_21626022 != nil:
    section.add "X-Amz-Date", valid_21626022
  var valid_21626023 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626023 = validateParameter(valid_21626023, JString, required = false,
                                   default = nil)
  if valid_21626023 != nil:
    section.add "X-Amz-Security-Token", valid_21626023
  var valid_21626024 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626024 = validateParameter(valid_21626024, JString, required = false,
                                   default = nil)
  if valid_21626024 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626024
  var valid_21626025 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626025 = validateParameter(valid_21626025, JString, required = false,
                                   default = nil)
  if valid_21626025 != nil:
    section.add "X-Amz-Algorithm", valid_21626025
  var valid_21626026 = header.getOrDefault("X-Amz-Signature")
  valid_21626026 = validateParameter(valid_21626026, JString, required = false,
                                   default = nil)
  if valid_21626026 != nil:
    section.add "X-Amz-Signature", valid_21626026
  var valid_21626027 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626027 = validateParameter(valid_21626027, JString, required = false,
                                   default = nil)
  if valid_21626027 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626027
  var valid_21626028 = header.getOrDefault("X-Amz-Credential")
  valid_21626028 = validateParameter(valid_21626028, JString, required = false,
                                   default = nil)
  if valid_21626028 != nil:
    section.add "X-Amz-Credential", valid_21626028
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

proc call*(call_21626030: Call_CreateCloudFrontOriginAccessIdentity20190326_21626019;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new origin access identity. If you're using Amazon S3 for your origin, you can use an origin access identity to require users to access your content using a CloudFront URL instead of the Amazon S3 URL. For more information about how to use origin access identities, see <a href="https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PrivateContent.html">Serving Private Content through CloudFront</a> in the <i>Amazon CloudFront Developer Guide</i>.
  ## 
  let valid = call_21626030.validator(path, query, header, formData, body, _)
  let scheme = call_21626030.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626030.makeUrl(scheme.get, call_21626030.host, call_21626030.base,
                               call_21626030.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626030, uri, valid, _)

proc call*(call_21626031: Call_CreateCloudFrontOriginAccessIdentity20190326_21626019;
          body: JsonNode): Recallable =
  ## createCloudFrontOriginAccessIdentity20190326
  ## Creates a new origin access identity. If you're using Amazon S3 for your origin, you can use an origin access identity to require users to access your content using a CloudFront URL instead of the Amazon S3 URL. For more information about how to use origin access identities, see <a href="https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PrivateContent.html">Serving Private Content through CloudFront</a> in the <i>Amazon CloudFront Developer Guide</i>.
  ##   body: JObject (required)
  var body_21626032 = newJObject()
  if body != nil:
    body_21626032 = body
  result = call_21626031.call(nil, nil, nil, nil, body_21626032)

var createCloudFrontOriginAccessIdentity20190326* = Call_CreateCloudFrontOriginAccessIdentity20190326_21626019(
    name: "createCloudFrontOriginAccessIdentity20190326",
    meth: HttpMethod.HttpPost, host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/origin-access-identity/cloudfront",
    validator: validate_CreateCloudFrontOriginAccessIdentity20190326_21626020,
    base: "/", makeUrl: url_CreateCloudFrontOriginAccessIdentity20190326_21626021,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCloudFrontOriginAccessIdentities20190326_21625779 = ref object of OpenApiRestCall_21625435
proc url_ListCloudFrontOriginAccessIdentities20190326_21625781(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListCloudFrontOriginAccessIdentities20190326_21625780(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21625882 = query.getOrDefault("Marker")
  valid_21625882 = validateParameter(valid_21625882, JString, required = false,
                                   default = nil)
  if valid_21625882 != nil:
    section.add "Marker", valid_21625882
  var valid_21625883 = query.getOrDefault("MaxItems")
  valid_21625883 = validateParameter(valid_21625883, JString, required = false,
                                   default = nil)
  if valid_21625883 != nil:
    section.add "MaxItems", valid_21625883
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
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
  var valid_21625886 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625886 = validateParameter(valid_21625886, JString, required = false,
                                   default = nil)
  if valid_21625886 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625886
  var valid_21625887 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625887 = validateParameter(valid_21625887, JString, required = false,
                                   default = nil)
  if valid_21625887 != nil:
    section.add "X-Amz-Algorithm", valid_21625887
  var valid_21625888 = header.getOrDefault("X-Amz-Signature")
  valid_21625888 = validateParameter(valid_21625888, JString, required = false,
                                   default = nil)
  if valid_21625888 != nil:
    section.add "X-Amz-Signature", valid_21625888
  var valid_21625889 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625889 = validateParameter(valid_21625889, JString, required = false,
                                   default = nil)
  if valid_21625889 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625889
  var valid_21625890 = header.getOrDefault("X-Amz-Credential")
  valid_21625890 = validateParameter(valid_21625890, JString, required = false,
                                   default = nil)
  if valid_21625890 != nil:
    section.add "X-Amz-Credential", valid_21625890
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21625915: Call_ListCloudFrontOriginAccessIdentities20190326_21625779;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists origin access identities.
  ## 
  let valid = call_21625915.validator(path, query, header, formData, body, _)
  let scheme = call_21625915.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625915.makeUrl(scheme.get, call_21625915.host, call_21625915.base,
                               call_21625915.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625915, uri, valid, _)

proc call*(call_21625978: Call_ListCloudFrontOriginAccessIdentities20190326_21625779;
          Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listCloudFrontOriginAccessIdentities20190326
  ## Lists origin access identities.
  ##   Marker: string
  ##         : Use this when paginating results to indicate where to begin in your list of origin access identities. The results include identities in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last identity on that page).
  ##   MaxItems: string
  ##           : The maximum number of origin access identities you want in the response body. 
  var query_21625980 = newJObject()
  add(query_21625980, "Marker", newJString(Marker))
  add(query_21625980, "MaxItems", newJString(MaxItems))
  result = call_21625978.call(nil, query_21625980, nil, nil, nil)

var listCloudFrontOriginAccessIdentities20190326* = Call_ListCloudFrontOriginAccessIdentities20190326_21625779(
    name: "listCloudFrontOriginAccessIdentities20190326",
    meth: HttpMethod.HttpGet, host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/origin-access-identity/cloudfront",
    validator: validate_ListCloudFrontOriginAccessIdentities20190326_21625780,
    base: "/", makeUrl: url_ListCloudFrontOriginAccessIdentities20190326_21625781,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDistribution20190326_21626048 = ref object of OpenApiRestCall_21625435
proc url_CreateDistribution20190326_21626050(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDistribution20190326_21626049(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a new web distribution. You create a CloudFront distribution to tell CloudFront where you want content to be delivered from, and the details about how to track and manage content delivery. Send a <code>POST</code> request to the <code>/<i>CloudFront API version</i>/distribution</code>/<code>distribution ID</code> resource.</p> <important> <p>When you update a distribution, there are more required fields than when you create a distribution. When you update your distribution by using <a href="https://docs.aws.amazon.com/cloudfront/latest/APIReference/API_UpdateDistribution.html">UpdateDistribution</a>, follow the steps included in the documentation to get the current configuration and then make your updates. This helps to make sure that you include all of the required fields. To view a summary, see <a href="https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-overview-required-fields.html">Required Fields for Create Distribution and Update Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> </important>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626051 = header.getOrDefault("X-Amz-Date")
  valid_21626051 = validateParameter(valid_21626051, JString, required = false,
                                   default = nil)
  if valid_21626051 != nil:
    section.add "X-Amz-Date", valid_21626051
  var valid_21626052 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626052 = validateParameter(valid_21626052, JString, required = false,
                                   default = nil)
  if valid_21626052 != nil:
    section.add "X-Amz-Security-Token", valid_21626052
  var valid_21626053 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626053 = validateParameter(valid_21626053, JString, required = false,
                                   default = nil)
  if valid_21626053 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626053
  var valid_21626054 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626054 = validateParameter(valid_21626054, JString, required = false,
                                   default = nil)
  if valid_21626054 != nil:
    section.add "X-Amz-Algorithm", valid_21626054
  var valid_21626055 = header.getOrDefault("X-Amz-Signature")
  valid_21626055 = validateParameter(valid_21626055, JString, required = false,
                                   default = nil)
  if valid_21626055 != nil:
    section.add "X-Amz-Signature", valid_21626055
  var valid_21626056 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626056 = validateParameter(valid_21626056, JString, required = false,
                                   default = nil)
  if valid_21626056 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626056
  var valid_21626057 = header.getOrDefault("X-Amz-Credential")
  valid_21626057 = validateParameter(valid_21626057, JString, required = false,
                                   default = nil)
  if valid_21626057 != nil:
    section.add "X-Amz-Credential", valid_21626057
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

proc call*(call_21626059: Call_CreateDistribution20190326_21626048;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a new web distribution. You create a CloudFront distribution to tell CloudFront where you want content to be delivered from, and the details about how to track and manage content delivery. Send a <code>POST</code> request to the <code>/<i>CloudFront API version</i>/distribution</code>/<code>distribution ID</code> resource.</p> <important> <p>When you update a distribution, there are more required fields than when you create a distribution. When you update your distribution by using <a href="https://docs.aws.amazon.com/cloudfront/latest/APIReference/API_UpdateDistribution.html">UpdateDistribution</a>, follow the steps included in the documentation to get the current configuration and then make your updates. This helps to make sure that you include all of the required fields. To view a summary, see <a href="https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-overview-required-fields.html">Required Fields for Create Distribution and Update Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> </important>
  ## 
  let valid = call_21626059.validator(path, query, header, formData, body, _)
  let scheme = call_21626059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626059.makeUrl(scheme.get, call_21626059.host, call_21626059.base,
                               call_21626059.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626059, uri, valid, _)

proc call*(call_21626060: Call_CreateDistribution20190326_21626048; body: JsonNode): Recallable =
  ## createDistribution20190326
  ## <p>Creates a new web distribution. You create a CloudFront distribution to tell CloudFront where you want content to be delivered from, and the details about how to track and manage content delivery. Send a <code>POST</code> request to the <code>/<i>CloudFront API version</i>/distribution</code>/<code>distribution ID</code> resource.</p> <important> <p>When you update a distribution, there are more required fields than when you create a distribution. When you update your distribution by using <a href="https://docs.aws.amazon.com/cloudfront/latest/APIReference/API_UpdateDistribution.html">UpdateDistribution</a>, follow the steps included in the documentation to get the current configuration and then make your updates. This helps to make sure that you include all of the required fields. To view a summary, see <a href="https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-overview-required-fields.html">Required Fields for Create Distribution and Update Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> </important>
  ##   body: JObject (required)
  var body_21626061 = newJObject()
  if body != nil:
    body_21626061 = body
  result = call_21626060.call(nil, nil, nil, nil, body_21626061)

var createDistribution20190326* = Call_CreateDistribution20190326_21626048(
    name: "createDistribution20190326", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com", route: "/2019-03-26/distribution",
    validator: validate_CreateDistribution20190326_21626049, base: "/",
    makeUrl: url_CreateDistribution20190326_21626050,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDistributions20190326_21626033 = ref object of OpenApiRestCall_21625435
proc url_ListDistributions20190326_21626035(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDistributions20190326_21626034(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626036 = query.getOrDefault("Marker")
  valid_21626036 = validateParameter(valid_21626036, JString, required = false,
                                   default = nil)
  if valid_21626036 != nil:
    section.add "Marker", valid_21626036
  var valid_21626037 = query.getOrDefault("MaxItems")
  valid_21626037 = validateParameter(valid_21626037, JString, required = false,
                                   default = nil)
  if valid_21626037 != nil:
    section.add "MaxItems", valid_21626037
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626038 = header.getOrDefault("X-Amz-Date")
  valid_21626038 = validateParameter(valid_21626038, JString, required = false,
                                   default = nil)
  if valid_21626038 != nil:
    section.add "X-Amz-Date", valid_21626038
  var valid_21626039 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626039 = validateParameter(valid_21626039, JString, required = false,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "X-Amz-Security-Token", valid_21626039
  var valid_21626040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626040 = validateParameter(valid_21626040, JString, required = false,
                                   default = nil)
  if valid_21626040 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626040
  var valid_21626041 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626041 = validateParameter(valid_21626041, JString, required = false,
                                   default = nil)
  if valid_21626041 != nil:
    section.add "X-Amz-Algorithm", valid_21626041
  var valid_21626042 = header.getOrDefault("X-Amz-Signature")
  valid_21626042 = validateParameter(valid_21626042, JString, required = false,
                                   default = nil)
  if valid_21626042 != nil:
    section.add "X-Amz-Signature", valid_21626042
  var valid_21626043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626043 = validateParameter(valid_21626043, JString, required = false,
                                   default = nil)
  if valid_21626043 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626043
  var valid_21626044 = header.getOrDefault("X-Amz-Credential")
  valid_21626044 = validateParameter(valid_21626044, JString, required = false,
                                   default = nil)
  if valid_21626044 != nil:
    section.add "X-Amz-Credential", valid_21626044
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626045: Call_ListDistributions20190326_21626033;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## List CloudFront distributions.
  ## 
  let valid = call_21626045.validator(path, query, header, formData, body, _)
  let scheme = call_21626045.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626045.makeUrl(scheme.get, call_21626045.host, call_21626045.base,
                               call_21626045.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626045, uri, valid, _)

proc call*(call_21626046: Call_ListDistributions20190326_21626033;
          Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listDistributions20190326
  ## List CloudFront distributions.
  ##   Marker: string
  ##         : Use this when paginating results to indicate where to begin in your list of distributions. The results include distributions in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last distribution on that page).
  ##   MaxItems: string
  ##           : The maximum number of distributions you want in the response body.
  var query_21626047 = newJObject()
  add(query_21626047, "Marker", newJString(Marker))
  add(query_21626047, "MaxItems", newJString(MaxItems))
  result = call_21626046.call(nil, query_21626047, nil, nil, nil)

var listDistributions20190326* = Call_ListDistributions20190326_21626033(
    name: "listDistributions20190326", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2019-03-26/distribution",
    validator: validate_ListDistributions20190326_21626034, base: "/",
    makeUrl: url_ListDistributions20190326_21626035,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDistributionWithTags20190326_21626062 = ref object of OpenApiRestCall_21625435
proc url_CreateDistributionWithTags20190326_21626064(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDistributionWithTags20190326_21626063(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626065 = query.getOrDefault("WithTags")
  valid_21626065 = validateParameter(valid_21626065, JBool, required = true,
                                   default = nil)
  if valid_21626065 != nil:
    section.add "WithTags", valid_21626065
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626066 = header.getOrDefault("X-Amz-Date")
  valid_21626066 = validateParameter(valid_21626066, JString, required = false,
                                   default = nil)
  if valid_21626066 != nil:
    section.add "X-Amz-Date", valid_21626066
  var valid_21626067 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626067 = validateParameter(valid_21626067, JString, required = false,
                                   default = nil)
  if valid_21626067 != nil:
    section.add "X-Amz-Security-Token", valid_21626067
  var valid_21626068 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626068 = validateParameter(valid_21626068, JString, required = false,
                                   default = nil)
  if valid_21626068 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626068
  var valid_21626069 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626069 = validateParameter(valid_21626069, JString, required = false,
                                   default = nil)
  if valid_21626069 != nil:
    section.add "X-Amz-Algorithm", valid_21626069
  var valid_21626070 = header.getOrDefault("X-Amz-Signature")
  valid_21626070 = validateParameter(valid_21626070, JString, required = false,
                                   default = nil)
  if valid_21626070 != nil:
    section.add "X-Amz-Signature", valid_21626070
  var valid_21626071 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626071 = validateParameter(valid_21626071, JString, required = false,
                                   default = nil)
  if valid_21626071 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626071
  var valid_21626072 = header.getOrDefault("X-Amz-Credential")
  valid_21626072 = validateParameter(valid_21626072, JString, required = false,
                                   default = nil)
  if valid_21626072 != nil:
    section.add "X-Amz-Credential", valid_21626072
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

proc call*(call_21626074: Call_CreateDistributionWithTags20190326_21626062;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Create a new distribution with tags.
  ## 
  let valid = call_21626074.validator(path, query, header, formData, body, _)
  let scheme = call_21626074.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626074.makeUrl(scheme.get, call_21626074.host, call_21626074.base,
                               call_21626074.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626074, uri, valid, _)

proc call*(call_21626075: Call_CreateDistributionWithTags20190326_21626062;
          WithTags: bool; body: JsonNode): Recallable =
  ## createDistributionWithTags20190326
  ## Create a new distribution with tags.
  ##   WithTags: bool (required)
  ##   body: JObject (required)
  var query_21626076 = newJObject()
  var body_21626077 = newJObject()
  add(query_21626076, "WithTags", newJBool(WithTags))
  if body != nil:
    body_21626077 = body
  result = call_21626075.call(nil, query_21626076, nil, nil, body_21626077)

var createDistributionWithTags20190326* = Call_CreateDistributionWithTags20190326_21626062(
    name: "createDistributionWithTags20190326", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com", route: "/2019-03-26/distribution#WithTags",
    validator: validate_CreateDistributionWithTags20190326_21626063, base: "/",
    makeUrl: url_CreateDistributionWithTags20190326_21626064,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFieldLevelEncryptionConfig20190326_21626093 = ref object of OpenApiRestCall_21625435
proc url_CreateFieldLevelEncryptionConfig20190326_21626095(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateFieldLevelEncryptionConfig20190326_21626094(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Create a new field-level encryption configuration.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626096 = header.getOrDefault("X-Amz-Date")
  valid_21626096 = validateParameter(valid_21626096, JString, required = false,
                                   default = nil)
  if valid_21626096 != nil:
    section.add "X-Amz-Date", valid_21626096
  var valid_21626097 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626097 = validateParameter(valid_21626097, JString, required = false,
                                   default = nil)
  if valid_21626097 != nil:
    section.add "X-Amz-Security-Token", valid_21626097
  var valid_21626098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626098 = validateParameter(valid_21626098, JString, required = false,
                                   default = nil)
  if valid_21626098 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626098
  var valid_21626099 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626099 = validateParameter(valid_21626099, JString, required = false,
                                   default = nil)
  if valid_21626099 != nil:
    section.add "X-Amz-Algorithm", valid_21626099
  var valid_21626100 = header.getOrDefault("X-Amz-Signature")
  valid_21626100 = validateParameter(valid_21626100, JString, required = false,
                                   default = nil)
  if valid_21626100 != nil:
    section.add "X-Amz-Signature", valid_21626100
  var valid_21626101 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626101 = validateParameter(valid_21626101, JString, required = false,
                                   default = nil)
  if valid_21626101 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626101
  var valid_21626102 = header.getOrDefault("X-Amz-Credential")
  valid_21626102 = validateParameter(valid_21626102, JString, required = false,
                                   default = nil)
  if valid_21626102 != nil:
    section.add "X-Amz-Credential", valid_21626102
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

proc call*(call_21626104: Call_CreateFieldLevelEncryptionConfig20190326_21626093;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Create a new field-level encryption configuration.
  ## 
  let valid = call_21626104.validator(path, query, header, formData, body, _)
  let scheme = call_21626104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626104.makeUrl(scheme.get, call_21626104.host, call_21626104.base,
                               call_21626104.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626104, uri, valid, _)

proc call*(call_21626105: Call_CreateFieldLevelEncryptionConfig20190326_21626093;
          body: JsonNode): Recallable =
  ## createFieldLevelEncryptionConfig20190326
  ## Create a new field-level encryption configuration.
  ##   body: JObject (required)
  var body_21626106 = newJObject()
  if body != nil:
    body_21626106 = body
  result = call_21626105.call(nil, nil, nil, nil, body_21626106)

var createFieldLevelEncryptionConfig20190326* = Call_CreateFieldLevelEncryptionConfig20190326_21626093(
    name: "createFieldLevelEncryptionConfig20190326", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com", route: "/2019-03-26/field-level-encryption",
    validator: validate_CreateFieldLevelEncryptionConfig20190326_21626094,
    base: "/", makeUrl: url_CreateFieldLevelEncryptionConfig20190326_21626095,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFieldLevelEncryptionConfigs20190326_21626078 = ref object of OpenApiRestCall_21625435
proc url_ListFieldLevelEncryptionConfigs20190326_21626080(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListFieldLevelEncryptionConfigs20190326_21626079(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626081 = query.getOrDefault("Marker")
  valid_21626081 = validateParameter(valid_21626081, JString, required = false,
                                   default = nil)
  if valid_21626081 != nil:
    section.add "Marker", valid_21626081
  var valid_21626082 = query.getOrDefault("MaxItems")
  valid_21626082 = validateParameter(valid_21626082, JString, required = false,
                                   default = nil)
  if valid_21626082 != nil:
    section.add "MaxItems", valid_21626082
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626083 = header.getOrDefault("X-Amz-Date")
  valid_21626083 = validateParameter(valid_21626083, JString, required = false,
                                   default = nil)
  if valid_21626083 != nil:
    section.add "X-Amz-Date", valid_21626083
  var valid_21626084 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626084 = validateParameter(valid_21626084, JString, required = false,
                                   default = nil)
  if valid_21626084 != nil:
    section.add "X-Amz-Security-Token", valid_21626084
  var valid_21626085 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626085 = validateParameter(valid_21626085, JString, required = false,
                                   default = nil)
  if valid_21626085 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626085
  var valid_21626086 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626086 = validateParameter(valid_21626086, JString, required = false,
                                   default = nil)
  if valid_21626086 != nil:
    section.add "X-Amz-Algorithm", valid_21626086
  var valid_21626087 = header.getOrDefault("X-Amz-Signature")
  valid_21626087 = validateParameter(valid_21626087, JString, required = false,
                                   default = nil)
  if valid_21626087 != nil:
    section.add "X-Amz-Signature", valid_21626087
  var valid_21626088 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626088 = validateParameter(valid_21626088, JString, required = false,
                                   default = nil)
  if valid_21626088 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626088
  var valid_21626089 = header.getOrDefault("X-Amz-Credential")
  valid_21626089 = validateParameter(valid_21626089, JString, required = false,
                                   default = nil)
  if valid_21626089 != nil:
    section.add "X-Amz-Credential", valid_21626089
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626090: Call_ListFieldLevelEncryptionConfigs20190326_21626078;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## List all field-level encryption configurations that have been created in CloudFront for this account.
  ## 
  let valid = call_21626090.validator(path, query, header, formData, body, _)
  let scheme = call_21626090.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626090.makeUrl(scheme.get, call_21626090.host, call_21626090.base,
                               call_21626090.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626090, uri, valid, _)

proc call*(call_21626091: Call_ListFieldLevelEncryptionConfigs20190326_21626078;
          Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listFieldLevelEncryptionConfigs20190326
  ## List all field-level encryption configurations that have been created in CloudFront for this account.
  ##   Marker: string
  ##         : Use this when paginating results to indicate where to begin in your list of configurations. The results include configurations in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last configuration on that page). 
  ##   MaxItems: string
  ##           : The maximum number of field-level encryption configurations you want in the response body. 
  var query_21626092 = newJObject()
  add(query_21626092, "Marker", newJString(Marker))
  add(query_21626092, "MaxItems", newJString(MaxItems))
  result = call_21626091.call(nil, query_21626092, nil, nil, nil)

var listFieldLevelEncryptionConfigs20190326* = Call_ListFieldLevelEncryptionConfigs20190326_21626078(
    name: "listFieldLevelEncryptionConfigs20190326", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2019-03-26/field-level-encryption",
    validator: validate_ListFieldLevelEncryptionConfigs20190326_21626079,
    base: "/", makeUrl: url_ListFieldLevelEncryptionConfigs20190326_21626080,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFieldLevelEncryptionProfile20190326_21626122 = ref object of OpenApiRestCall_21625435
proc url_CreateFieldLevelEncryptionProfile20190326_21626124(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateFieldLevelEncryptionProfile20190326_21626123(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Create a field-level encryption profile.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626125 = header.getOrDefault("X-Amz-Date")
  valid_21626125 = validateParameter(valid_21626125, JString, required = false,
                                   default = nil)
  if valid_21626125 != nil:
    section.add "X-Amz-Date", valid_21626125
  var valid_21626126 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626126 = validateParameter(valid_21626126, JString, required = false,
                                   default = nil)
  if valid_21626126 != nil:
    section.add "X-Amz-Security-Token", valid_21626126
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

proc call*(call_21626133: Call_CreateFieldLevelEncryptionProfile20190326_21626122;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Create a field-level encryption profile.
  ## 
  let valid = call_21626133.validator(path, query, header, formData, body, _)
  let scheme = call_21626133.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626133.makeUrl(scheme.get, call_21626133.host, call_21626133.base,
                               call_21626133.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626133, uri, valid, _)

proc call*(call_21626134: Call_CreateFieldLevelEncryptionProfile20190326_21626122;
          body: JsonNode): Recallable =
  ## createFieldLevelEncryptionProfile20190326
  ## Create a field-level encryption profile.
  ##   body: JObject (required)
  var body_21626135 = newJObject()
  if body != nil:
    body_21626135 = body
  result = call_21626134.call(nil, nil, nil, nil, body_21626135)

var createFieldLevelEncryptionProfile20190326* = Call_CreateFieldLevelEncryptionProfile20190326_21626122(
    name: "createFieldLevelEncryptionProfile20190326", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/field-level-encryption-profile",
    validator: validate_CreateFieldLevelEncryptionProfile20190326_21626123,
    base: "/", makeUrl: url_CreateFieldLevelEncryptionProfile20190326_21626124,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFieldLevelEncryptionProfiles20190326_21626107 = ref object of OpenApiRestCall_21625435
proc url_ListFieldLevelEncryptionProfiles20190326_21626109(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListFieldLevelEncryptionProfiles20190326_21626108(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626110 = query.getOrDefault("Marker")
  valid_21626110 = validateParameter(valid_21626110, JString, required = false,
                                   default = nil)
  if valid_21626110 != nil:
    section.add "Marker", valid_21626110
  var valid_21626111 = query.getOrDefault("MaxItems")
  valid_21626111 = validateParameter(valid_21626111, JString, required = false,
                                   default = nil)
  if valid_21626111 != nil:
    section.add "MaxItems", valid_21626111
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626112 = header.getOrDefault("X-Amz-Date")
  valid_21626112 = validateParameter(valid_21626112, JString, required = false,
                                   default = nil)
  if valid_21626112 != nil:
    section.add "X-Amz-Date", valid_21626112
  var valid_21626113 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626113 = validateParameter(valid_21626113, JString, required = false,
                                   default = nil)
  if valid_21626113 != nil:
    section.add "X-Amz-Security-Token", valid_21626113
  var valid_21626114 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626114 = validateParameter(valid_21626114, JString, required = false,
                                   default = nil)
  if valid_21626114 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626114
  var valid_21626115 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626115 = validateParameter(valid_21626115, JString, required = false,
                                   default = nil)
  if valid_21626115 != nil:
    section.add "X-Amz-Algorithm", valid_21626115
  var valid_21626116 = header.getOrDefault("X-Amz-Signature")
  valid_21626116 = validateParameter(valid_21626116, JString, required = false,
                                   default = nil)
  if valid_21626116 != nil:
    section.add "X-Amz-Signature", valid_21626116
  var valid_21626117 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626117 = validateParameter(valid_21626117, JString, required = false,
                                   default = nil)
  if valid_21626117 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626117
  var valid_21626118 = header.getOrDefault("X-Amz-Credential")
  valid_21626118 = validateParameter(valid_21626118, JString, required = false,
                                   default = nil)
  if valid_21626118 != nil:
    section.add "X-Amz-Credential", valid_21626118
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626119: Call_ListFieldLevelEncryptionProfiles20190326_21626107;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Request a list of field-level encryption profiles that have been created in CloudFront for this account.
  ## 
  let valid = call_21626119.validator(path, query, header, formData, body, _)
  let scheme = call_21626119.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626119.makeUrl(scheme.get, call_21626119.host, call_21626119.base,
                               call_21626119.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626119, uri, valid, _)

proc call*(call_21626120: Call_ListFieldLevelEncryptionProfiles20190326_21626107;
          Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listFieldLevelEncryptionProfiles20190326
  ## Request a list of field-level encryption profiles that have been created in CloudFront for this account.
  ##   Marker: string
  ##         : Use this when paginating results to indicate where to begin in your list of profiles. The results include profiles in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last profile on that page). 
  ##   MaxItems: string
  ##           : The maximum number of field-level encryption profiles you want in the response body. 
  var query_21626121 = newJObject()
  add(query_21626121, "Marker", newJString(Marker))
  add(query_21626121, "MaxItems", newJString(MaxItems))
  result = call_21626120.call(nil, query_21626121, nil, nil, nil)

var listFieldLevelEncryptionProfiles20190326* = Call_ListFieldLevelEncryptionProfiles20190326_21626107(
    name: "listFieldLevelEncryptionProfiles20190326", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/field-level-encryption-profile",
    validator: validate_ListFieldLevelEncryptionProfiles20190326_21626108,
    base: "/", makeUrl: url_ListFieldLevelEncryptionProfiles20190326_21626109,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInvalidation20190326_21626166 = ref object of OpenApiRestCall_21625435
proc url_CreateInvalidation20190326_21626168(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateInvalidation20190326_21626167(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626169 = path.getOrDefault("DistributionId")
  valid_21626169 = validateParameter(valid_21626169, JString, required = true,
                                   default = nil)
  if valid_21626169 != nil:
    section.add "DistributionId", valid_21626169
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626170 = header.getOrDefault("X-Amz-Date")
  valid_21626170 = validateParameter(valid_21626170, JString, required = false,
                                   default = nil)
  if valid_21626170 != nil:
    section.add "X-Amz-Date", valid_21626170
  var valid_21626171 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626171 = validateParameter(valid_21626171, JString, required = false,
                                   default = nil)
  if valid_21626171 != nil:
    section.add "X-Amz-Security-Token", valid_21626171
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

proc call*(call_21626178: Call_CreateInvalidation20190326_21626166;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Create a new invalidation. 
  ## 
  let valid = call_21626178.validator(path, query, header, formData, body, _)
  let scheme = call_21626178.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626178.makeUrl(scheme.get, call_21626178.host, call_21626178.base,
                               call_21626178.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626178, uri, valid, _)

proc call*(call_21626179: Call_CreateInvalidation20190326_21626166; body: JsonNode;
          DistributionId: string): Recallable =
  ## createInvalidation20190326
  ## Create a new invalidation. 
  ##   body: JObject (required)
  ##   DistributionId: string (required)
  ##                 : The distribution's id.
  var path_21626180 = newJObject()
  var body_21626181 = newJObject()
  if body != nil:
    body_21626181 = body
  add(path_21626180, "DistributionId", newJString(DistributionId))
  result = call_21626179.call(path_21626180, nil, nil, nil, body_21626181)

var createInvalidation20190326* = Call_CreateInvalidation20190326_21626166(
    name: "createInvalidation20190326", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/distribution/{DistributionId}/invalidation",
    validator: validate_CreateInvalidation20190326_21626167, base: "/",
    makeUrl: url_CreateInvalidation20190326_21626168,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInvalidations20190326_21626136 = ref object of OpenApiRestCall_21625435
proc url_ListInvalidations20190326_21626138(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListInvalidations20190326_21626137(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626152 = path.getOrDefault("DistributionId")
  valid_21626152 = validateParameter(valid_21626152, JString, required = true,
                                   default = nil)
  if valid_21626152 != nil:
    section.add "DistributionId", valid_21626152
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Use this parameter when paginating results to indicate where to begin in your list of invalidation batches. Because the results are returned in decreasing order from most recent to oldest, the most recent results are on the first page, the second page will contain earlier results, and so on. To get the next page of results, set <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response. This value is the same as the ID of the last invalidation batch on that page. 
  ##   MaxItems: JString
  ##           : The maximum number of invalidation batches that you want in the response body.
  section = newJObject()
  var valid_21626153 = query.getOrDefault("Marker")
  valid_21626153 = validateParameter(valid_21626153, JString, required = false,
                                   default = nil)
  if valid_21626153 != nil:
    section.add "Marker", valid_21626153
  var valid_21626154 = query.getOrDefault("MaxItems")
  valid_21626154 = validateParameter(valid_21626154, JString, required = false,
                                   default = nil)
  if valid_21626154 != nil:
    section.add "MaxItems", valid_21626154
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626155 = header.getOrDefault("X-Amz-Date")
  valid_21626155 = validateParameter(valid_21626155, JString, required = false,
                                   default = nil)
  if valid_21626155 != nil:
    section.add "X-Amz-Date", valid_21626155
  var valid_21626156 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626156 = validateParameter(valid_21626156, JString, required = false,
                                   default = nil)
  if valid_21626156 != nil:
    section.add "X-Amz-Security-Token", valid_21626156
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
  if body != nil:
    result.add "body", body

proc call*(call_21626162: Call_ListInvalidations20190326_21626136;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists invalidation batches. 
  ## 
  let valid = call_21626162.validator(path, query, header, formData, body, _)
  let scheme = call_21626162.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626162.makeUrl(scheme.get, call_21626162.host, call_21626162.base,
                               call_21626162.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626162, uri, valid, _)

proc call*(call_21626163: Call_ListInvalidations20190326_21626136;
          DistributionId: string; Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listInvalidations20190326
  ## Lists invalidation batches. 
  ##   Marker: string
  ##         : Use this parameter when paginating results to indicate where to begin in your list of invalidation batches. Because the results are returned in decreasing order from most recent to oldest, the most recent results are on the first page, the second page will contain earlier results, and so on. To get the next page of results, set <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response. This value is the same as the ID of the last invalidation batch on that page. 
  ##   MaxItems: string
  ##           : The maximum number of invalidation batches that you want in the response body.
  ##   DistributionId: string (required)
  ##                 : The distribution's ID.
  var path_21626164 = newJObject()
  var query_21626165 = newJObject()
  add(query_21626165, "Marker", newJString(Marker))
  add(query_21626165, "MaxItems", newJString(MaxItems))
  add(path_21626164, "DistributionId", newJString(DistributionId))
  result = call_21626163.call(path_21626164, query_21626165, nil, nil, nil)

var listInvalidations20190326* = Call_ListInvalidations20190326_21626136(
    name: "listInvalidations20190326", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/distribution/{DistributionId}/invalidation",
    validator: validate_ListInvalidations20190326_21626137, base: "/",
    makeUrl: url_ListInvalidations20190326_21626138,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePublicKey20190326_21626197 = ref object of OpenApiRestCall_21625435
proc url_CreatePublicKey20190326_21626199(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePublicKey20190326_21626198(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Add a new public key to CloudFront to use, for example, for field-level encryption. You can add a maximum of 10 public keys with one AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626200 = header.getOrDefault("X-Amz-Date")
  valid_21626200 = validateParameter(valid_21626200, JString, required = false,
                                   default = nil)
  if valid_21626200 != nil:
    section.add "X-Amz-Date", valid_21626200
  var valid_21626201 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626201 = validateParameter(valid_21626201, JString, required = false,
                                   default = nil)
  if valid_21626201 != nil:
    section.add "X-Amz-Security-Token", valid_21626201
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

proc call*(call_21626208: Call_CreatePublicKey20190326_21626197;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Add a new public key to CloudFront to use, for example, for field-level encryption. You can add a maximum of 10 public keys with one AWS account.
  ## 
  let valid = call_21626208.validator(path, query, header, formData, body, _)
  let scheme = call_21626208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626208.makeUrl(scheme.get, call_21626208.host, call_21626208.base,
                               call_21626208.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626208, uri, valid, _)

proc call*(call_21626209: Call_CreatePublicKey20190326_21626197; body: JsonNode): Recallable =
  ## createPublicKey20190326
  ## Add a new public key to CloudFront to use, for example, for field-level encryption. You can add a maximum of 10 public keys with one AWS account.
  ##   body: JObject (required)
  var body_21626210 = newJObject()
  if body != nil:
    body_21626210 = body
  result = call_21626209.call(nil, nil, nil, nil, body_21626210)

var createPublicKey20190326* = Call_CreatePublicKey20190326_21626197(
    name: "createPublicKey20190326", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com", route: "/2019-03-26/public-key",
    validator: validate_CreatePublicKey20190326_21626198, base: "/",
    makeUrl: url_CreatePublicKey20190326_21626199,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPublicKeys20190326_21626182 = ref object of OpenApiRestCall_21625435
proc url_ListPublicKeys20190326_21626184(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPublicKeys20190326_21626183(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626185 = query.getOrDefault("Marker")
  valid_21626185 = validateParameter(valid_21626185, JString, required = false,
                                   default = nil)
  if valid_21626185 != nil:
    section.add "Marker", valid_21626185
  var valid_21626186 = query.getOrDefault("MaxItems")
  valid_21626186 = validateParameter(valid_21626186, JString, required = false,
                                   default = nil)
  if valid_21626186 != nil:
    section.add "MaxItems", valid_21626186
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626187 = header.getOrDefault("X-Amz-Date")
  valid_21626187 = validateParameter(valid_21626187, JString, required = false,
                                   default = nil)
  if valid_21626187 != nil:
    section.add "X-Amz-Date", valid_21626187
  var valid_21626188 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626188 = validateParameter(valid_21626188, JString, required = false,
                                   default = nil)
  if valid_21626188 != nil:
    section.add "X-Amz-Security-Token", valid_21626188
  var valid_21626189 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626189 = validateParameter(valid_21626189, JString, required = false,
                                   default = nil)
  if valid_21626189 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626189
  var valid_21626190 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626190 = validateParameter(valid_21626190, JString, required = false,
                                   default = nil)
  if valid_21626190 != nil:
    section.add "X-Amz-Algorithm", valid_21626190
  var valid_21626191 = header.getOrDefault("X-Amz-Signature")
  valid_21626191 = validateParameter(valid_21626191, JString, required = false,
                                   default = nil)
  if valid_21626191 != nil:
    section.add "X-Amz-Signature", valid_21626191
  var valid_21626192 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626192 = validateParameter(valid_21626192, JString, required = false,
                                   default = nil)
  if valid_21626192 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626192
  var valid_21626193 = header.getOrDefault("X-Amz-Credential")
  valid_21626193 = validateParameter(valid_21626193, JString, required = false,
                                   default = nil)
  if valid_21626193 != nil:
    section.add "X-Amz-Credential", valid_21626193
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626194: Call_ListPublicKeys20190326_21626182;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## List all public keys that have been added to CloudFront for this account.
  ## 
  let valid = call_21626194.validator(path, query, header, formData, body, _)
  let scheme = call_21626194.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626194.makeUrl(scheme.get, call_21626194.host, call_21626194.base,
                               call_21626194.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626194, uri, valid, _)

proc call*(call_21626195: Call_ListPublicKeys20190326_21626182;
          Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listPublicKeys20190326
  ## List all public keys that have been added to CloudFront for this account.
  ##   Marker: string
  ##         : Use this when paginating results to indicate where to begin in your list of public keys. The results include public keys in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last public key on that page). 
  ##   MaxItems: string
  ##           : The maximum number of public keys you want in the response body. 
  var query_21626196 = newJObject()
  add(query_21626196, "Marker", newJString(Marker))
  add(query_21626196, "MaxItems", newJString(MaxItems))
  result = call_21626195.call(nil, query_21626196, nil, nil, nil)

var listPublicKeys20190326* = Call_ListPublicKeys20190326_21626182(
    name: "listPublicKeys20190326", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2019-03-26/public-key",
    validator: validate_ListPublicKeys20190326_21626183, base: "/",
    makeUrl: url_ListPublicKeys20190326_21626184,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStreamingDistribution20190326_21626226 = ref object of OpenApiRestCall_21625435
proc url_CreateStreamingDistribution20190326_21626228(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateStreamingDistribution20190326_21626227(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Creates a new RTMP distribution. An RTMP distribution is similar to a web distribution, but an RTMP distribution streams media files using the Adobe Real-Time Messaging Protocol (RTMP) instead of serving files using HTTP. </p> <p>To create a new distribution, submit a <code>POST</code> request to the <i>CloudFront API version</i>/distribution resource. The request body must include a document with a <i>StreamingDistributionConfig</i> element. The response echoes the <code>StreamingDistributionConfig</code> element and returns other information about the RTMP distribution.</p> <p>To get the status of your request, use the <i>GET StreamingDistribution</i> API action. When the value of <code>Enabled</code> is <code>true</code> and the value of <code>Status</code> is <code>Deployed</code>, your distribution is ready. A distribution usually deploys in less than 15 minutes.</p> <p>For more information about web distributions, see <a href="https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-rtmp.html">Working with RTMP Distributions</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <important> <p>Beginning with the 2012-05-05 version of the CloudFront API, we made substantial changes to the format of the XML document that you include in the request body when you create or update a web distribution or an RTMP distribution, and when you invalidate objects. With previous versions of the API, we discovered that it was too easy to accidentally delete one or more values for an element that accepts multiple values, for example, CNAMEs and trusted signers. Our changes for the 2012-05-05 release are intended to prevent these accidental deletions and to notify you when there's a mismatch between the number of values you say you're specifying in the <code>Quantity</code> element and the number of values specified.</p> </important>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
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
  var valid_21626231 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626231 = validateParameter(valid_21626231, JString, required = false,
                                   default = nil)
  if valid_21626231 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626231
  var valid_21626232 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626232 = validateParameter(valid_21626232, JString, required = false,
                                   default = nil)
  if valid_21626232 != nil:
    section.add "X-Amz-Algorithm", valid_21626232
  var valid_21626233 = header.getOrDefault("X-Amz-Signature")
  valid_21626233 = validateParameter(valid_21626233, JString, required = false,
                                   default = nil)
  if valid_21626233 != nil:
    section.add "X-Amz-Signature", valid_21626233
  var valid_21626234 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626234 = validateParameter(valid_21626234, JString, required = false,
                                   default = nil)
  if valid_21626234 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626234
  var valid_21626235 = header.getOrDefault("X-Amz-Credential")
  valid_21626235 = validateParameter(valid_21626235, JString, required = false,
                                   default = nil)
  if valid_21626235 != nil:
    section.add "X-Amz-Credential", valid_21626235
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

proc call*(call_21626237: Call_CreateStreamingDistribution20190326_21626226;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a new RTMP distribution. An RTMP distribution is similar to a web distribution, but an RTMP distribution streams media files using the Adobe Real-Time Messaging Protocol (RTMP) instead of serving files using HTTP. </p> <p>To create a new distribution, submit a <code>POST</code> request to the <i>CloudFront API version</i>/distribution resource. The request body must include a document with a <i>StreamingDistributionConfig</i> element. The response echoes the <code>StreamingDistributionConfig</code> element and returns other information about the RTMP distribution.</p> <p>To get the status of your request, use the <i>GET StreamingDistribution</i> API action. When the value of <code>Enabled</code> is <code>true</code> and the value of <code>Status</code> is <code>Deployed</code>, your distribution is ready. A distribution usually deploys in less than 15 minutes.</p> <p>For more information about web distributions, see <a href="https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-rtmp.html">Working with RTMP Distributions</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <important> <p>Beginning with the 2012-05-05 version of the CloudFront API, we made substantial changes to the format of the XML document that you include in the request body when you create or update a web distribution or an RTMP distribution, and when you invalidate objects. With previous versions of the API, we discovered that it was too easy to accidentally delete one or more values for an element that accepts multiple values, for example, CNAMEs and trusted signers. Our changes for the 2012-05-05 release are intended to prevent these accidental deletions and to notify you when there's a mismatch between the number of values you say you're specifying in the <code>Quantity</code> element and the number of values specified.</p> </important>
  ## 
  let valid = call_21626237.validator(path, query, header, formData, body, _)
  let scheme = call_21626237.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626237.makeUrl(scheme.get, call_21626237.host, call_21626237.base,
                               call_21626237.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626237, uri, valid, _)

proc call*(call_21626238: Call_CreateStreamingDistribution20190326_21626226;
          body: JsonNode): Recallable =
  ## createStreamingDistribution20190326
  ## <p>Creates a new RTMP distribution. An RTMP distribution is similar to a web distribution, but an RTMP distribution streams media files using the Adobe Real-Time Messaging Protocol (RTMP) instead of serving files using HTTP. </p> <p>To create a new distribution, submit a <code>POST</code> request to the <i>CloudFront API version</i>/distribution resource. The request body must include a document with a <i>StreamingDistributionConfig</i> element. The response echoes the <code>StreamingDistributionConfig</code> element and returns other information about the RTMP distribution.</p> <p>To get the status of your request, use the <i>GET StreamingDistribution</i> API action. When the value of <code>Enabled</code> is <code>true</code> and the value of <code>Status</code> is <code>Deployed</code>, your distribution is ready. A distribution usually deploys in less than 15 minutes.</p> <p>For more information about web distributions, see <a href="https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-rtmp.html">Working with RTMP Distributions</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <important> <p>Beginning with the 2012-05-05 version of the CloudFront API, we made substantial changes to the format of the XML document that you include in the request body when you create or update a web distribution or an RTMP distribution, and when you invalidate objects. With previous versions of the API, we discovered that it was too easy to accidentally delete one or more values for an element that accepts multiple values, for example, CNAMEs and trusted signers. Our changes for the 2012-05-05 release are intended to prevent these accidental deletions and to notify you when there's a mismatch between the number of values you say you're specifying in the <code>Quantity</code> element and the number of values specified.</p> </important>
  ##   body: JObject (required)
  var body_21626239 = newJObject()
  if body != nil:
    body_21626239 = body
  result = call_21626238.call(nil, nil, nil, nil, body_21626239)

var createStreamingDistribution20190326* = Call_CreateStreamingDistribution20190326_21626226(
    name: "createStreamingDistribution20190326", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com", route: "/2019-03-26/streaming-distribution",
    validator: validate_CreateStreamingDistribution20190326_21626227, base: "/",
    makeUrl: url_CreateStreamingDistribution20190326_21626228,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListStreamingDistributions20190326_21626211 = ref object of OpenApiRestCall_21625435
proc url_ListStreamingDistributions20190326_21626213(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListStreamingDistributions20190326_21626212(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626214 = query.getOrDefault("Marker")
  valid_21626214 = validateParameter(valid_21626214, JString, required = false,
                                   default = nil)
  if valid_21626214 != nil:
    section.add "Marker", valid_21626214
  var valid_21626215 = query.getOrDefault("MaxItems")
  valid_21626215 = validateParameter(valid_21626215, JString, required = false,
                                   default = nil)
  if valid_21626215 != nil:
    section.add "MaxItems", valid_21626215
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626216 = header.getOrDefault("X-Amz-Date")
  valid_21626216 = validateParameter(valid_21626216, JString, required = false,
                                   default = nil)
  if valid_21626216 != nil:
    section.add "X-Amz-Date", valid_21626216
  var valid_21626217 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626217 = validateParameter(valid_21626217, JString, required = false,
                                   default = nil)
  if valid_21626217 != nil:
    section.add "X-Amz-Security-Token", valid_21626217
  var valid_21626218 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626218 = validateParameter(valid_21626218, JString, required = false,
                                   default = nil)
  if valid_21626218 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626218
  var valid_21626219 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626219 = validateParameter(valid_21626219, JString, required = false,
                                   default = nil)
  if valid_21626219 != nil:
    section.add "X-Amz-Algorithm", valid_21626219
  var valid_21626220 = header.getOrDefault("X-Amz-Signature")
  valid_21626220 = validateParameter(valid_21626220, JString, required = false,
                                   default = nil)
  if valid_21626220 != nil:
    section.add "X-Amz-Signature", valid_21626220
  var valid_21626221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626221 = validateParameter(valid_21626221, JString, required = false,
                                   default = nil)
  if valid_21626221 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626221
  var valid_21626222 = header.getOrDefault("X-Amz-Credential")
  valid_21626222 = validateParameter(valid_21626222, JString, required = false,
                                   default = nil)
  if valid_21626222 != nil:
    section.add "X-Amz-Credential", valid_21626222
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626223: Call_ListStreamingDistributions20190326_21626211;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## List streaming distributions. 
  ## 
  let valid = call_21626223.validator(path, query, header, formData, body, _)
  let scheme = call_21626223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626223.makeUrl(scheme.get, call_21626223.host, call_21626223.base,
                               call_21626223.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626223, uri, valid, _)

proc call*(call_21626224: Call_ListStreamingDistributions20190326_21626211;
          Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listStreamingDistributions20190326
  ## List streaming distributions. 
  ##   Marker: string
  ##         : The value that you provided for the <code>Marker</code> request parameter.
  ##   MaxItems: string
  ##           : The value that you provided for the <code>MaxItems</code> request parameter.
  var query_21626225 = newJObject()
  add(query_21626225, "Marker", newJString(Marker))
  add(query_21626225, "MaxItems", newJString(MaxItems))
  result = call_21626224.call(nil, query_21626225, nil, nil, nil)

var listStreamingDistributions20190326* = Call_ListStreamingDistributions20190326_21626211(
    name: "listStreamingDistributions20190326", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2019-03-26/streaming-distribution",
    validator: validate_ListStreamingDistributions20190326_21626212, base: "/",
    makeUrl: url_ListStreamingDistributions20190326_21626213,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStreamingDistributionWithTags20190326_21626240 = ref object of OpenApiRestCall_21625435
proc url_CreateStreamingDistributionWithTags20190326_21626242(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateStreamingDistributionWithTags20190326_21626241(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626243 = query.getOrDefault("WithTags")
  valid_21626243 = validateParameter(valid_21626243, JBool, required = true,
                                   default = nil)
  if valid_21626243 != nil:
    section.add "WithTags", valid_21626243
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
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
  var valid_21626246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626246 = validateParameter(valid_21626246, JString, required = false,
                                   default = nil)
  if valid_21626246 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626246
  var valid_21626247 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626247 = validateParameter(valid_21626247, JString, required = false,
                                   default = nil)
  if valid_21626247 != nil:
    section.add "X-Amz-Algorithm", valid_21626247
  var valid_21626248 = header.getOrDefault("X-Amz-Signature")
  valid_21626248 = validateParameter(valid_21626248, JString, required = false,
                                   default = nil)
  if valid_21626248 != nil:
    section.add "X-Amz-Signature", valid_21626248
  var valid_21626249 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626249 = validateParameter(valid_21626249, JString, required = false,
                                   default = nil)
  if valid_21626249 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626249
  var valid_21626250 = header.getOrDefault("X-Amz-Credential")
  valid_21626250 = validateParameter(valid_21626250, JString, required = false,
                                   default = nil)
  if valid_21626250 != nil:
    section.add "X-Amz-Credential", valid_21626250
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

proc call*(call_21626252: Call_CreateStreamingDistributionWithTags20190326_21626240;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Create a new streaming distribution with tags.
  ## 
  let valid = call_21626252.validator(path, query, header, formData, body, _)
  let scheme = call_21626252.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626252.makeUrl(scheme.get, call_21626252.host, call_21626252.base,
                               call_21626252.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626252, uri, valid, _)

proc call*(call_21626253: Call_CreateStreamingDistributionWithTags20190326_21626240;
          WithTags: bool; body: JsonNode): Recallable =
  ## createStreamingDistributionWithTags20190326
  ## Create a new streaming distribution with tags.
  ##   WithTags: bool (required)
  ##   body: JObject (required)
  var query_21626254 = newJObject()
  var body_21626255 = newJObject()
  add(query_21626254, "WithTags", newJBool(WithTags))
  if body != nil:
    body_21626255 = body
  result = call_21626253.call(nil, query_21626254, nil, nil, body_21626255)

var createStreamingDistributionWithTags20190326* = Call_CreateStreamingDistributionWithTags20190326_21626240(
    name: "createStreamingDistributionWithTags20190326",
    meth: HttpMethod.HttpPost, host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/streaming-distribution#WithTags",
    validator: validate_CreateStreamingDistributionWithTags20190326_21626241,
    base: "/", makeUrl: url_CreateStreamingDistributionWithTags20190326_21626242,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCloudFrontOriginAccessIdentity20190326_21626256 = ref object of OpenApiRestCall_21625435
proc url_GetCloudFrontOriginAccessIdentity20190326_21626258(protocol: Scheme;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetCloudFrontOriginAccessIdentity20190326_21626257(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Get the information about an origin access identity. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The identity's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_21626259 = path.getOrDefault("Id")
  valid_21626259 = validateParameter(valid_21626259, JString, required = true,
                                   default = nil)
  if valid_21626259 != nil:
    section.add "Id", valid_21626259
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626260 = header.getOrDefault("X-Amz-Date")
  valid_21626260 = validateParameter(valid_21626260, JString, required = false,
                                   default = nil)
  if valid_21626260 != nil:
    section.add "X-Amz-Date", valid_21626260
  var valid_21626261 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626261 = validateParameter(valid_21626261, JString, required = false,
                                   default = nil)
  if valid_21626261 != nil:
    section.add "X-Amz-Security-Token", valid_21626261
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
  if body != nil:
    result.add "body", body

proc call*(call_21626267: Call_GetCloudFrontOriginAccessIdentity20190326_21626256;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Get the information about an origin access identity. 
  ## 
  let valid = call_21626267.validator(path, query, header, formData, body, _)
  let scheme = call_21626267.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626267.makeUrl(scheme.get, call_21626267.host, call_21626267.base,
                               call_21626267.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626267, uri, valid, _)

proc call*(call_21626268: Call_GetCloudFrontOriginAccessIdentity20190326_21626256;
          Id: string): Recallable =
  ## getCloudFrontOriginAccessIdentity20190326
  ## Get the information about an origin access identity. 
  ##   Id: string (required)
  ##     : The identity's ID.
  var path_21626269 = newJObject()
  add(path_21626269, "Id", newJString(Id))
  result = call_21626268.call(path_21626269, nil, nil, nil, nil)

var getCloudFrontOriginAccessIdentity20190326* = Call_GetCloudFrontOriginAccessIdentity20190326_21626256(
    name: "getCloudFrontOriginAccessIdentity20190326", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/origin-access-identity/cloudfront/{Id}",
    validator: validate_GetCloudFrontOriginAccessIdentity20190326_21626257,
    base: "/", makeUrl: url_GetCloudFrontOriginAccessIdentity20190326_21626258,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCloudFrontOriginAccessIdentity20190326_21626270 = ref object of OpenApiRestCall_21625435
proc url_DeleteCloudFrontOriginAccessIdentity20190326_21626272(protocol: Scheme;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteCloudFrontOriginAccessIdentity20190326_21626271(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Delete an origin access identity. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The origin access identity's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_21626273 = path.getOrDefault("Id")
  valid_21626273 = validateParameter(valid_21626273, JString, required = true,
                                   default = nil)
  if valid_21626273 != nil:
    section.add "Id", valid_21626273
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header you received from a previous <code>GET</code> or <code>PUT</code> request. For example: <code>E2QWRUHAPOMQZL</code>.
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
  var valid_21626276 = header.getOrDefault("If-Match")
  valid_21626276 = validateParameter(valid_21626276, JString, required = false,
                                   default = nil)
  if valid_21626276 != nil:
    section.add "If-Match", valid_21626276
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
  if body != nil:
    result.add "body", body

proc call*(call_21626282: Call_DeleteCloudFrontOriginAccessIdentity20190326_21626270;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Delete an origin access identity. 
  ## 
  let valid = call_21626282.validator(path, query, header, formData, body, _)
  let scheme = call_21626282.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626282.makeUrl(scheme.get, call_21626282.host, call_21626282.base,
                               call_21626282.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626282, uri, valid, _)

proc call*(call_21626283: Call_DeleteCloudFrontOriginAccessIdentity20190326_21626270;
          Id: string): Recallable =
  ## deleteCloudFrontOriginAccessIdentity20190326
  ## Delete an origin access identity. 
  ##   Id: string (required)
  ##     : The origin access identity's ID.
  var path_21626284 = newJObject()
  add(path_21626284, "Id", newJString(Id))
  result = call_21626283.call(path_21626284, nil, nil, nil, nil)

var deleteCloudFrontOriginAccessIdentity20190326* = Call_DeleteCloudFrontOriginAccessIdentity20190326_21626270(
    name: "deleteCloudFrontOriginAccessIdentity20190326",
    meth: HttpMethod.HttpDelete, host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/origin-access-identity/cloudfront/{Id}",
    validator: validate_DeleteCloudFrontOriginAccessIdentity20190326_21626271,
    base: "/", makeUrl: url_DeleteCloudFrontOriginAccessIdentity20190326_21626272,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDistribution20190326_21626285 = ref object of OpenApiRestCall_21625435
proc url_GetDistribution20190326_21626287(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDistribution20190326_21626286(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Get the information about a distribution.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The distribution's ID. If the ID is empty, an empty distribution configuration is returned.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_21626288 = path.getOrDefault("Id")
  valid_21626288 = validateParameter(valid_21626288, JString, required = true,
                                   default = nil)
  if valid_21626288 != nil:
    section.add "Id", valid_21626288
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
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
  var valid_21626291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626291 = validateParameter(valid_21626291, JString, required = false,
                                   default = nil)
  if valid_21626291 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626291
  var valid_21626292 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626292 = validateParameter(valid_21626292, JString, required = false,
                                   default = nil)
  if valid_21626292 != nil:
    section.add "X-Amz-Algorithm", valid_21626292
  var valid_21626293 = header.getOrDefault("X-Amz-Signature")
  valid_21626293 = validateParameter(valid_21626293, JString, required = false,
                                   default = nil)
  if valid_21626293 != nil:
    section.add "X-Amz-Signature", valid_21626293
  var valid_21626294 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626294 = validateParameter(valid_21626294, JString, required = false,
                                   default = nil)
  if valid_21626294 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626294
  var valid_21626295 = header.getOrDefault("X-Amz-Credential")
  valid_21626295 = validateParameter(valid_21626295, JString, required = false,
                                   default = nil)
  if valid_21626295 != nil:
    section.add "X-Amz-Credential", valid_21626295
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626296: Call_GetDistribution20190326_21626285;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Get the information about a distribution.
  ## 
  let valid = call_21626296.validator(path, query, header, formData, body, _)
  let scheme = call_21626296.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626296.makeUrl(scheme.get, call_21626296.host, call_21626296.base,
                               call_21626296.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626296, uri, valid, _)

proc call*(call_21626297: Call_GetDistribution20190326_21626285; Id: string): Recallable =
  ## getDistribution20190326
  ## Get the information about a distribution.
  ##   Id: string (required)
  ##     : The distribution's ID. If the ID is empty, an empty distribution configuration is returned.
  var path_21626298 = newJObject()
  add(path_21626298, "Id", newJString(Id))
  result = call_21626297.call(path_21626298, nil, nil, nil, nil)

var getDistribution20190326* = Call_GetDistribution20190326_21626285(
    name: "getDistribution20190326", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2019-03-26/distribution/{Id}",
    validator: validate_GetDistribution20190326_21626286, base: "/",
    makeUrl: url_GetDistribution20190326_21626287,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDistribution20190326_21626299 = ref object of OpenApiRestCall_21625435
proc url_DeleteDistribution20190326_21626301(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDistribution20190326_21626300(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Delete a distribution. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The distribution ID. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_21626302 = path.getOrDefault("Id")
  valid_21626302 = validateParameter(valid_21626302, JString, required = true,
                                   default = nil)
  if valid_21626302 != nil:
    section.add "Id", valid_21626302
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when you disabled the distribution. For example: <code>E2QWRUHAPOMQZL</code>. 
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626303 = header.getOrDefault("X-Amz-Date")
  valid_21626303 = validateParameter(valid_21626303, JString, required = false,
                                   default = nil)
  if valid_21626303 != nil:
    section.add "X-Amz-Date", valid_21626303
  var valid_21626304 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626304 = validateParameter(valid_21626304, JString, required = false,
                                   default = nil)
  if valid_21626304 != nil:
    section.add "X-Amz-Security-Token", valid_21626304
  var valid_21626305 = header.getOrDefault("If-Match")
  valid_21626305 = validateParameter(valid_21626305, JString, required = false,
                                   default = nil)
  if valid_21626305 != nil:
    section.add "If-Match", valid_21626305
  var valid_21626306 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626306 = validateParameter(valid_21626306, JString, required = false,
                                   default = nil)
  if valid_21626306 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626306
  var valid_21626307 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626307 = validateParameter(valid_21626307, JString, required = false,
                                   default = nil)
  if valid_21626307 != nil:
    section.add "X-Amz-Algorithm", valid_21626307
  var valid_21626308 = header.getOrDefault("X-Amz-Signature")
  valid_21626308 = validateParameter(valid_21626308, JString, required = false,
                                   default = nil)
  if valid_21626308 != nil:
    section.add "X-Amz-Signature", valid_21626308
  var valid_21626309 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626309 = validateParameter(valid_21626309, JString, required = false,
                                   default = nil)
  if valid_21626309 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626309
  var valid_21626310 = header.getOrDefault("X-Amz-Credential")
  valid_21626310 = validateParameter(valid_21626310, JString, required = false,
                                   default = nil)
  if valid_21626310 != nil:
    section.add "X-Amz-Credential", valid_21626310
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626311: Call_DeleteDistribution20190326_21626299;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Delete a distribution. 
  ## 
  let valid = call_21626311.validator(path, query, header, formData, body, _)
  let scheme = call_21626311.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626311.makeUrl(scheme.get, call_21626311.host, call_21626311.base,
                               call_21626311.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626311, uri, valid, _)

proc call*(call_21626312: Call_DeleteDistribution20190326_21626299; Id: string): Recallable =
  ## deleteDistribution20190326
  ## Delete a distribution. 
  ##   Id: string (required)
  ##     : The distribution ID. 
  var path_21626313 = newJObject()
  add(path_21626313, "Id", newJString(Id))
  result = call_21626312.call(path_21626313, nil, nil, nil, nil)

var deleteDistribution20190326* = Call_DeleteDistribution20190326_21626299(
    name: "deleteDistribution20190326", meth: HttpMethod.HttpDelete,
    host: "cloudfront.amazonaws.com", route: "/2019-03-26/distribution/{Id}",
    validator: validate_DeleteDistribution20190326_21626300, base: "/",
    makeUrl: url_DeleteDistribution20190326_21626301,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFieldLevelEncryption20190326_21626314 = ref object of OpenApiRestCall_21625435
proc url_GetFieldLevelEncryption20190326_21626316(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFieldLevelEncryption20190326_21626315(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Get the field-level encryption configuration information.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : Request the ID for the field-level encryption configuration information.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_21626317 = path.getOrDefault("Id")
  valid_21626317 = validateParameter(valid_21626317, JString, required = true,
                                   default = nil)
  if valid_21626317 != nil:
    section.add "Id", valid_21626317
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626318 = header.getOrDefault("X-Amz-Date")
  valid_21626318 = validateParameter(valid_21626318, JString, required = false,
                                   default = nil)
  if valid_21626318 != nil:
    section.add "X-Amz-Date", valid_21626318
  var valid_21626319 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626319 = validateParameter(valid_21626319, JString, required = false,
                                   default = nil)
  if valid_21626319 != nil:
    section.add "X-Amz-Security-Token", valid_21626319
  var valid_21626320 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626320 = validateParameter(valid_21626320, JString, required = false,
                                   default = nil)
  if valid_21626320 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626320
  var valid_21626321 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626321 = validateParameter(valid_21626321, JString, required = false,
                                   default = nil)
  if valid_21626321 != nil:
    section.add "X-Amz-Algorithm", valid_21626321
  var valid_21626322 = header.getOrDefault("X-Amz-Signature")
  valid_21626322 = validateParameter(valid_21626322, JString, required = false,
                                   default = nil)
  if valid_21626322 != nil:
    section.add "X-Amz-Signature", valid_21626322
  var valid_21626323 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626323 = validateParameter(valid_21626323, JString, required = false,
                                   default = nil)
  if valid_21626323 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626323
  var valid_21626324 = header.getOrDefault("X-Amz-Credential")
  valid_21626324 = validateParameter(valid_21626324, JString, required = false,
                                   default = nil)
  if valid_21626324 != nil:
    section.add "X-Amz-Credential", valid_21626324
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626325: Call_GetFieldLevelEncryption20190326_21626314;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Get the field-level encryption configuration information.
  ## 
  let valid = call_21626325.validator(path, query, header, formData, body, _)
  let scheme = call_21626325.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626325.makeUrl(scheme.get, call_21626325.host, call_21626325.base,
                               call_21626325.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626325, uri, valid, _)

proc call*(call_21626326: Call_GetFieldLevelEncryption20190326_21626314; Id: string): Recallable =
  ## getFieldLevelEncryption20190326
  ## Get the field-level encryption configuration information.
  ##   Id: string (required)
  ##     : Request the ID for the field-level encryption configuration information.
  var path_21626327 = newJObject()
  add(path_21626327, "Id", newJString(Id))
  result = call_21626326.call(path_21626327, nil, nil, nil, nil)

var getFieldLevelEncryption20190326* = Call_GetFieldLevelEncryption20190326_21626314(
    name: "getFieldLevelEncryption20190326", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/field-level-encryption/{Id}",
    validator: validate_GetFieldLevelEncryption20190326_21626315, base: "/",
    makeUrl: url_GetFieldLevelEncryption20190326_21626316,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFieldLevelEncryptionConfig20190326_21626328 = ref object of OpenApiRestCall_21625435
proc url_DeleteFieldLevelEncryptionConfig20190326_21626330(protocol: Scheme;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteFieldLevelEncryptionConfig20190326_21626329(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Remove a field-level encryption configuration.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the configuration you want to delete from CloudFront.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_21626331 = path.getOrDefault("Id")
  valid_21626331 = validateParameter(valid_21626331, JString, required = true,
                                   default = nil)
  if valid_21626331 != nil:
    section.add "Id", valid_21626331
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the configuration identity to delete. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626332 = header.getOrDefault("X-Amz-Date")
  valid_21626332 = validateParameter(valid_21626332, JString, required = false,
                                   default = nil)
  if valid_21626332 != nil:
    section.add "X-Amz-Date", valid_21626332
  var valid_21626333 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626333 = validateParameter(valid_21626333, JString, required = false,
                                   default = nil)
  if valid_21626333 != nil:
    section.add "X-Amz-Security-Token", valid_21626333
  var valid_21626334 = header.getOrDefault("If-Match")
  valid_21626334 = validateParameter(valid_21626334, JString, required = false,
                                   default = nil)
  if valid_21626334 != nil:
    section.add "If-Match", valid_21626334
  var valid_21626335 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626335 = validateParameter(valid_21626335, JString, required = false,
                                   default = nil)
  if valid_21626335 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626335
  var valid_21626336 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626336 = validateParameter(valid_21626336, JString, required = false,
                                   default = nil)
  if valid_21626336 != nil:
    section.add "X-Amz-Algorithm", valid_21626336
  var valid_21626337 = header.getOrDefault("X-Amz-Signature")
  valid_21626337 = validateParameter(valid_21626337, JString, required = false,
                                   default = nil)
  if valid_21626337 != nil:
    section.add "X-Amz-Signature", valid_21626337
  var valid_21626338 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626338 = validateParameter(valid_21626338, JString, required = false,
                                   default = nil)
  if valid_21626338 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626338
  var valid_21626339 = header.getOrDefault("X-Amz-Credential")
  valid_21626339 = validateParameter(valid_21626339, JString, required = false,
                                   default = nil)
  if valid_21626339 != nil:
    section.add "X-Amz-Credential", valid_21626339
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626340: Call_DeleteFieldLevelEncryptionConfig20190326_21626328;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Remove a field-level encryption configuration.
  ## 
  let valid = call_21626340.validator(path, query, header, formData, body, _)
  let scheme = call_21626340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626340.makeUrl(scheme.get, call_21626340.host, call_21626340.base,
                               call_21626340.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626340, uri, valid, _)

proc call*(call_21626341: Call_DeleteFieldLevelEncryptionConfig20190326_21626328;
          Id: string): Recallable =
  ## deleteFieldLevelEncryptionConfig20190326
  ## Remove a field-level encryption configuration.
  ##   Id: string (required)
  ##     : The ID of the configuration you want to delete from CloudFront.
  var path_21626342 = newJObject()
  add(path_21626342, "Id", newJString(Id))
  result = call_21626341.call(path_21626342, nil, nil, nil, nil)

var deleteFieldLevelEncryptionConfig20190326* = Call_DeleteFieldLevelEncryptionConfig20190326_21626328(
    name: "deleteFieldLevelEncryptionConfig20190326", meth: HttpMethod.HttpDelete,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/field-level-encryption/{Id}",
    validator: validate_DeleteFieldLevelEncryptionConfig20190326_21626329,
    base: "/", makeUrl: url_DeleteFieldLevelEncryptionConfig20190326_21626330,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFieldLevelEncryptionProfile20190326_21626343 = ref object of OpenApiRestCall_21625435
proc url_GetFieldLevelEncryptionProfile20190326_21626345(protocol: Scheme;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFieldLevelEncryptionProfile20190326_21626344(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Get the field-level encryption profile information.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : Get the ID for the field-level encryption profile information.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_21626346 = path.getOrDefault("Id")
  valid_21626346 = validateParameter(valid_21626346, JString, required = true,
                                   default = nil)
  if valid_21626346 != nil:
    section.add "Id", valid_21626346
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626347 = header.getOrDefault("X-Amz-Date")
  valid_21626347 = validateParameter(valid_21626347, JString, required = false,
                                   default = nil)
  if valid_21626347 != nil:
    section.add "X-Amz-Date", valid_21626347
  var valid_21626348 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626348 = validateParameter(valid_21626348, JString, required = false,
                                   default = nil)
  if valid_21626348 != nil:
    section.add "X-Amz-Security-Token", valid_21626348
  var valid_21626349 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626349 = validateParameter(valid_21626349, JString, required = false,
                                   default = nil)
  if valid_21626349 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626349
  var valid_21626350 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626350 = validateParameter(valid_21626350, JString, required = false,
                                   default = nil)
  if valid_21626350 != nil:
    section.add "X-Amz-Algorithm", valid_21626350
  var valid_21626351 = header.getOrDefault("X-Amz-Signature")
  valid_21626351 = validateParameter(valid_21626351, JString, required = false,
                                   default = nil)
  if valid_21626351 != nil:
    section.add "X-Amz-Signature", valid_21626351
  var valid_21626352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626352 = validateParameter(valid_21626352, JString, required = false,
                                   default = nil)
  if valid_21626352 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626352
  var valid_21626353 = header.getOrDefault("X-Amz-Credential")
  valid_21626353 = validateParameter(valid_21626353, JString, required = false,
                                   default = nil)
  if valid_21626353 != nil:
    section.add "X-Amz-Credential", valid_21626353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626354: Call_GetFieldLevelEncryptionProfile20190326_21626343;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Get the field-level encryption profile information.
  ## 
  let valid = call_21626354.validator(path, query, header, formData, body, _)
  let scheme = call_21626354.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626354.makeUrl(scheme.get, call_21626354.host, call_21626354.base,
                               call_21626354.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626354, uri, valid, _)

proc call*(call_21626355: Call_GetFieldLevelEncryptionProfile20190326_21626343;
          Id: string): Recallable =
  ## getFieldLevelEncryptionProfile20190326
  ## Get the field-level encryption profile information.
  ##   Id: string (required)
  ##     : Get the ID for the field-level encryption profile information.
  var path_21626356 = newJObject()
  add(path_21626356, "Id", newJString(Id))
  result = call_21626355.call(path_21626356, nil, nil, nil, nil)

var getFieldLevelEncryptionProfile20190326* = Call_GetFieldLevelEncryptionProfile20190326_21626343(
    name: "getFieldLevelEncryptionProfile20190326", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/field-level-encryption-profile/{Id}",
    validator: validate_GetFieldLevelEncryptionProfile20190326_21626344,
    base: "/", makeUrl: url_GetFieldLevelEncryptionProfile20190326_21626345,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFieldLevelEncryptionProfile20190326_21626357 = ref object of OpenApiRestCall_21625435
proc url_DeleteFieldLevelEncryptionProfile20190326_21626359(protocol: Scheme;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteFieldLevelEncryptionProfile20190326_21626358(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Remove a field-level encryption profile.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : Request the ID of the profile you want to delete from CloudFront.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_21626360 = path.getOrDefault("Id")
  valid_21626360 = validateParameter(valid_21626360, JString, required = true,
                                   default = nil)
  if valid_21626360 != nil:
    section.add "Id", valid_21626360
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the profile to delete. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626361 = header.getOrDefault("X-Amz-Date")
  valid_21626361 = validateParameter(valid_21626361, JString, required = false,
                                   default = nil)
  if valid_21626361 != nil:
    section.add "X-Amz-Date", valid_21626361
  var valid_21626362 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626362 = validateParameter(valid_21626362, JString, required = false,
                                   default = nil)
  if valid_21626362 != nil:
    section.add "X-Amz-Security-Token", valid_21626362
  var valid_21626363 = header.getOrDefault("If-Match")
  valid_21626363 = validateParameter(valid_21626363, JString, required = false,
                                   default = nil)
  if valid_21626363 != nil:
    section.add "If-Match", valid_21626363
  var valid_21626364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626364 = validateParameter(valid_21626364, JString, required = false,
                                   default = nil)
  if valid_21626364 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626364
  var valid_21626365 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626365 = validateParameter(valid_21626365, JString, required = false,
                                   default = nil)
  if valid_21626365 != nil:
    section.add "X-Amz-Algorithm", valid_21626365
  var valid_21626366 = header.getOrDefault("X-Amz-Signature")
  valid_21626366 = validateParameter(valid_21626366, JString, required = false,
                                   default = nil)
  if valid_21626366 != nil:
    section.add "X-Amz-Signature", valid_21626366
  var valid_21626367 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626367 = validateParameter(valid_21626367, JString, required = false,
                                   default = nil)
  if valid_21626367 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626367
  var valid_21626368 = header.getOrDefault("X-Amz-Credential")
  valid_21626368 = validateParameter(valid_21626368, JString, required = false,
                                   default = nil)
  if valid_21626368 != nil:
    section.add "X-Amz-Credential", valid_21626368
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626369: Call_DeleteFieldLevelEncryptionProfile20190326_21626357;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Remove a field-level encryption profile.
  ## 
  let valid = call_21626369.validator(path, query, header, formData, body, _)
  let scheme = call_21626369.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626369.makeUrl(scheme.get, call_21626369.host, call_21626369.base,
                               call_21626369.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626369, uri, valid, _)

proc call*(call_21626370: Call_DeleteFieldLevelEncryptionProfile20190326_21626357;
          Id: string): Recallable =
  ## deleteFieldLevelEncryptionProfile20190326
  ## Remove a field-level encryption profile.
  ##   Id: string (required)
  ##     : Request the ID of the profile you want to delete from CloudFront.
  var path_21626371 = newJObject()
  add(path_21626371, "Id", newJString(Id))
  result = call_21626370.call(path_21626371, nil, nil, nil, nil)

var deleteFieldLevelEncryptionProfile20190326* = Call_DeleteFieldLevelEncryptionProfile20190326_21626357(
    name: "deleteFieldLevelEncryptionProfile20190326",
    meth: HttpMethod.HttpDelete, host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/field-level-encryption-profile/{Id}",
    validator: validate_DeleteFieldLevelEncryptionProfile20190326_21626358,
    base: "/", makeUrl: url_DeleteFieldLevelEncryptionProfile20190326_21626359,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPublicKey20190326_21626372 = ref object of OpenApiRestCall_21625435
proc url_GetPublicKey20190326_21626374(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetPublicKey20190326_21626373(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Get the public key information.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : Request the ID for the public key.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_21626375 = path.getOrDefault("Id")
  valid_21626375 = validateParameter(valid_21626375, JString, required = true,
                                   default = nil)
  if valid_21626375 != nil:
    section.add "Id", valid_21626375
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626376 = header.getOrDefault("X-Amz-Date")
  valid_21626376 = validateParameter(valid_21626376, JString, required = false,
                                   default = nil)
  if valid_21626376 != nil:
    section.add "X-Amz-Date", valid_21626376
  var valid_21626377 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626377 = validateParameter(valid_21626377, JString, required = false,
                                   default = nil)
  if valid_21626377 != nil:
    section.add "X-Amz-Security-Token", valid_21626377
  var valid_21626378 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626378 = validateParameter(valid_21626378, JString, required = false,
                                   default = nil)
  if valid_21626378 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626378
  var valid_21626379 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626379 = validateParameter(valid_21626379, JString, required = false,
                                   default = nil)
  if valid_21626379 != nil:
    section.add "X-Amz-Algorithm", valid_21626379
  var valid_21626380 = header.getOrDefault("X-Amz-Signature")
  valid_21626380 = validateParameter(valid_21626380, JString, required = false,
                                   default = nil)
  if valid_21626380 != nil:
    section.add "X-Amz-Signature", valid_21626380
  var valid_21626381 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626381 = validateParameter(valid_21626381, JString, required = false,
                                   default = nil)
  if valid_21626381 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626381
  var valid_21626382 = header.getOrDefault("X-Amz-Credential")
  valid_21626382 = validateParameter(valid_21626382, JString, required = false,
                                   default = nil)
  if valid_21626382 != nil:
    section.add "X-Amz-Credential", valid_21626382
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626383: Call_GetPublicKey20190326_21626372; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Get the public key information.
  ## 
  let valid = call_21626383.validator(path, query, header, formData, body, _)
  let scheme = call_21626383.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626383.makeUrl(scheme.get, call_21626383.host, call_21626383.base,
                               call_21626383.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626383, uri, valid, _)

proc call*(call_21626384: Call_GetPublicKey20190326_21626372; Id: string): Recallable =
  ## getPublicKey20190326
  ## Get the public key information.
  ##   Id: string (required)
  ##     : Request the ID for the public key.
  var path_21626385 = newJObject()
  add(path_21626385, "Id", newJString(Id))
  result = call_21626384.call(path_21626385, nil, nil, nil, nil)

var getPublicKey20190326* = Call_GetPublicKey20190326_21626372(
    name: "getPublicKey20190326", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2019-03-26/public-key/{Id}",
    validator: validate_GetPublicKey20190326_21626373, base: "/",
    makeUrl: url_GetPublicKey20190326_21626374,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePublicKey20190326_21626386 = ref object of OpenApiRestCall_21625435
proc url_DeletePublicKey20190326_21626388(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeletePublicKey20190326_21626387(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Remove a public key you previously added to CloudFront.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the public key you want to remove from CloudFront.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_21626389 = path.getOrDefault("Id")
  valid_21626389 = validateParameter(valid_21626389, JString, required = true,
                                   default = nil)
  if valid_21626389 != nil:
    section.add "Id", valid_21626389
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the public key identity to delete. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626390 = header.getOrDefault("X-Amz-Date")
  valid_21626390 = validateParameter(valid_21626390, JString, required = false,
                                   default = nil)
  if valid_21626390 != nil:
    section.add "X-Amz-Date", valid_21626390
  var valid_21626391 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626391 = validateParameter(valid_21626391, JString, required = false,
                                   default = nil)
  if valid_21626391 != nil:
    section.add "X-Amz-Security-Token", valid_21626391
  var valid_21626392 = header.getOrDefault("If-Match")
  valid_21626392 = validateParameter(valid_21626392, JString, required = false,
                                   default = nil)
  if valid_21626392 != nil:
    section.add "If-Match", valid_21626392
  var valid_21626393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626393 = validateParameter(valid_21626393, JString, required = false,
                                   default = nil)
  if valid_21626393 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626393
  var valid_21626394 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626394 = validateParameter(valid_21626394, JString, required = false,
                                   default = nil)
  if valid_21626394 != nil:
    section.add "X-Amz-Algorithm", valid_21626394
  var valid_21626395 = header.getOrDefault("X-Amz-Signature")
  valid_21626395 = validateParameter(valid_21626395, JString, required = false,
                                   default = nil)
  if valid_21626395 != nil:
    section.add "X-Amz-Signature", valid_21626395
  var valid_21626396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626396 = validateParameter(valid_21626396, JString, required = false,
                                   default = nil)
  if valid_21626396 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626396
  var valid_21626397 = header.getOrDefault("X-Amz-Credential")
  valid_21626397 = validateParameter(valid_21626397, JString, required = false,
                                   default = nil)
  if valid_21626397 != nil:
    section.add "X-Amz-Credential", valid_21626397
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626398: Call_DeletePublicKey20190326_21626386;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Remove a public key you previously added to CloudFront.
  ## 
  let valid = call_21626398.validator(path, query, header, formData, body, _)
  let scheme = call_21626398.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626398.makeUrl(scheme.get, call_21626398.host, call_21626398.base,
                               call_21626398.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626398, uri, valid, _)

proc call*(call_21626399: Call_DeletePublicKey20190326_21626386; Id: string): Recallable =
  ## deletePublicKey20190326
  ## Remove a public key you previously added to CloudFront.
  ##   Id: string (required)
  ##     : The ID of the public key you want to remove from CloudFront.
  var path_21626400 = newJObject()
  add(path_21626400, "Id", newJString(Id))
  result = call_21626399.call(path_21626400, nil, nil, nil, nil)

var deletePublicKey20190326* = Call_DeletePublicKey20190326_21626386(
    name: "deletePublicKey20190326", meth: HttpMethod.HttpDelete,
    host: "cloudfront.amazonaws.com", route: "/2019-03-26/public-key/{Id}",
    validator: validate_DeletePublicKey20190326_21626387, base: "/",
    makeUrl: url_DeletePublicKey20190326_21626388,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStreamingDistribution20190326_21626401 = ref object of OpenApiRestCall_21625435
proc url_GetStreamingDistribution20190326_21626403(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetStreamingDistribution20190326_21626402(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Gets information about a specified RTMP distribution, including the distribution configuration.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The streaming distribution's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_21626404 = path.getOrDefault("Id")
  valid_21626404 = validateParameter(valid_21626404, JString, required = true,
                                   default = nil)
  if valid_21626404 != nil:
    section.add "Id", valid_21626404
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626405 = header.getOrDefault("X-Amz-Date")
  valid_21626405 = validateParameter(valid_21626405, JString, required = false,
                                   default = nil)
  if valid_21626405 != nil:
    section.add "X-Amz-Date", valid_21626405
  var valid_21626406 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626406 = validateParameter(valid_21626406, JString, required = false,
                                   default = nil)
  if valid_21626406 != nil:
    section.add "X-Amz-Security-Token", valid_21626406
  var valid_21626407 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626407 = validateParameter(valid_21626407, JString, required = false,
                                   default = nil)
  if valid_21626407 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626407
  var valid_21626408 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626408 = validateParameter(valid_21626408, JString, required = false,
                                   default = nil)
  if valid_21626408 != nil:
    section.add "X-Amz-Algorithm", valid_21626408
  var valid_21626409 = header.getOrDefault("X-Amz-Signature")
  valid_21626409 = validateParameter(valid_21626409, JString, required = false,
                                   default = nil)
  if valid_21626409 != nil:
    section.add "X-Amz-Signature", valid_21626409
  var valid_21626410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626410 = validateParameter(valid_21626410, JString, required = false,
                                   default = nil)
  if valid_21626410 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626410
  var valid_21626411 = header.getOrDefault("X-Amz-Credential")
  valid_21626411 = validateParameter(valid_21626411, JString, required = false,
                                   default = nil)
  if valid_21626411 != nil:
    section.add "X-Amz-Credential", valid_21626411
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626412: Call_GetStreamingDistribution20190326_21626401;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about a specified RTMP distribution, including the distribution configuration.
  ## 
  let valid = call_21626412.validator(path, query, header, formData, body, _)
  let scheme = call_21626412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626412.makeUrl(scheme.get, call_21626412.host, call_21626412.base,
                               call_21626412.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626412, uri, valid, _)

proc call*(call_21626413: Call_GetStreamingDistribution20190326_21626401;
          Id: string): Recallable =
  ## getStreamingDistribution20190326
  ## Gets information about a specified RTMP distribution, including the distribution configuration.
  ##   Id: string (required)
  ##     : The streaming distribution's ID.
  var path_21626414 = newJObject()
  add(path_21626414, "Id", newJString(Id))
  result = call_21626413.call(path_21626414, nil, nil, nil, nil)

var getStreamingDistribution20190326* = Call_GetStreamingDistribution20190326_21626401(
    name: "getStreamingDistribution20190326", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/streaming-distribution/{Id}",
    validator: validate_GetStreamingDistribution20190326_21626402, base: "/",
    makeUrl: url_GetStreamingDistribution20190326_21626403,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteStreamingDistribution20190326_21626415 = ref object of OpenApiRestCall_21625435
proc url_DeleteStreamingDistribution20190326_21626417(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteStreamingDistribution20190326_21626416(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Delete a streaming distribution. To delete an RTMP distribution using the CloudFront API, perform the following steps.</p> <p> <b>To delete an RTMP distribution using the CloudFront API</b>:</p> <ol> <li> <p>Disable the RTMP distribution.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to get the current configuration and the <code>Etag</code> header for the distribution. </p> </li> <li> <p>Update the XML document that was returned in the response to your <code>GET Streaming Distribution Config</code> request to change the value of <code>Enabled</code> to <code>false</code>.</p> </li> <li> <p>Submit a <code>PUT Streaming Distribution Config</code> request to update the configuration for your distribution. In the request body, include the XML document that you updated in Step 3. Then set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to the <code>PUT Streaming Distribution Config</code> request to confirm that the distribution was successfully disabled.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> <li> <p>Submit a <code>DELETE Streaming Distribution</code> request. Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to your <code>DELETE Streaming Distribution</code> request to confirm that the distribution was successfully deleted.</p> </li> </ol> <p>For information about deleting a distribution using the CloudFront console, see <a href="https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/HowToDeleteDistribution.html">Deleting a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The distribution ID. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_21626418 = path.getOrDefault("Id")
  valid_21626418 = validateParameter(valid_21626418, JString, required = true,
                                   default = nil)
  if valid_21626418 != nil:
    section.add "Id", valid_21626418
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when you disabled the streaming distribution. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626419 = header.getOrDefault("X-Amz-Date")
  valid_21626419 = validateParameter(valid_21626419, JString, required = false,
                                   default = nil)
  if valid_21626419 != nil:
    section.add "X-Amz-Date", valid_21626419
  var valid_21626420 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626420 = validateParameter(valid_21626420, JString, required = false,
                                   default = nil)
  if valid_21626420 != nil:
    section.add "X-Amz-Security-Token", valid_21626420
  var valid_21626421 = header.getOrDefault("If-Match")
  valid_21626421 = validateParameter(valid_21626421, JString, required = false,
                                   default = nil)
  if valid_21626421 != nil:
    section.add "If-Match", valid_21626421
  var valid_21626422 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626422 = validateParameter(valid_21626422, JString, required = false,
                                   default = nil)
  if valid_21626422 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626422
  var valid_21626423 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626423 = validateParameter(valid_21626423, JString, required = false,
                                   default = nil)
  if valid_21626423 != nil:
    section.add "X-Amz-Algorithm", valid_21626423
  var valid_21626424 = header.getOrDefault("X-Amz-Signature")
  valid_21626424 = validateParameter(valid_21626424, JString, required = false,
                                   default = nil)
  if valid_21626424 != nil:
    section.add "X-Amz-Signature", valid_21626424
  var valid_21626425 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626425 = validateParameter(valid_21626425, JString, required = false,
                                   default = nil)
  if valid_21626425 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626425
  var valid_21626426 = header.getOrDefault("X-Amz-Credential")
  valid_21626426 = validateParameter(valid_21626426, JString, required = false,
                                   default = nil)
  if valid_21626426 != nil:
    section.add "X-Amz-Credential", valid_21626426
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626427: Call_DeleteStreamingDistribution20190326_21626415;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Delete a streaming distribution. To delete an RTMP distribution using the CloudFront API, perform the following steps.</p> <p> <b>To delete an RTMP distribution using the CloudFront API</b>:</p> <ol> <li> <p>Disable the RTMP distribution.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to get the current configuration and the <code>Etag</code> header for the distribution. </p> </li> <li> <p>Update the XML document that was returned in the response to your <code>GET Streaming Distribution Config</code> request to change the value of <code>Enabled</code> to <code>false</code>.</p> </li> <li> <p>Submit a <code>PUT Streaming Distribution Config</code> request to update the configuration for your distribution. In the request body, include the XML document that you updated in Step 3. Then set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to the <code>PUT Streaming Distribution Config</code> request to confirm that the distribution was successfully disabled.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> <li> <p>Submit a <code>DELETE Streaming Distribution</code> request. Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to your <code>DELETE Streaming Distribution</code> request to confirm that the distribution was successfully deleted.</p> </li> </ol> <p>For information about deleting a distribution using the CloudFront console, see <a href="https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/HowToDeleteDistribution.html">Deleting a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p>
  ## 
  let valid = call_21626427.validator(path, query, header, formData, body, _)
  let scheme = call_21626427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626427.makeUrl(scheme.get, call_21626427.host, call_21626427.base,
                               call_21626427.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626427, uri, valid, _)

proc call*(call_21626428: Call_DeleteStreamingDistribution20190326_21626415;
          Id: string): Recallable =
  ## deleteStreamingDistribution20190326
  ## <p>Delete a streaming distribution. To delete an RTMP distribution using the CloudFront API, perform the following steps.</p> <p> <b>To delete an RTMP distribution using the CloudFront API</b>:</p> <ol> <li> <p>Disable the RTMP distribution.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to get the current configuration and the <code>Etag</code> header for the distribution. </p> </li> <li> <p>Update the XML document that was returned in the response to your <code>GET Streaming Distribution Config</code> request to change the value of <code>Enabled</code> to <code>false</code>.</p> </li> <li> <p>Submit a <code>PUT Streaming Distribution Config</code> request to update the configuration for your distribution. In the request body, include the XML document that you updated in Step 3. Then set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to the <code>PUT Streaming Distribution Config</code> request to confirm that the distribution was successfully disabled.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> <li> <p>Submit a <code>DELETE Streaming Distribution</code> request. Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to your <code>DELETE Streaming Distribution</code> request to confirm that the distribution was successfully deleted.</p> </li> </ol> <p>For information about deleting a distribution using the CloudFront console, see <a href="https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/HowToDeleteDistribution.html">Deleting a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p>
  ##   Id: string (required)
  ##     : The distribution ID. 
  var path_21626429 = newJObject()
  add(path_21626429, "Id", newJString(Id))
  result = call_21626428.call(path_21626429, nil, nil, nil, nil)

var deleteStreamingDistribution20190326* = Call_DeleteStreamingDistribution20190326_21626415(
    name: "deleteStreamingDistribution20190326", meth: HttpMethod.HttpDelete,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/streaming-distribution/{Id}",
    validator: validate_DeleteStreamingDistribution20190326_21626416, base: "/",
    makeUrl: url_DeleteStreamingDistribution20190326_21626417,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCloudFrontOriginAccessIdentity20190326_21626444 = ref object of OpenApiRestCall_21625435
proc url_UpdateCloudFrontOriginAccessIdentity20190326_21626446(protocol: Scheme;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateCloudFrontOriginAccessIdentity20190326_21626445(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Update an origin access identity. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The identity's id.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_21626447 = path.getOrDefault("Id")
  valid_21626447 = validateParameter(valid_21626447, JString, required = true,
                                   default = nil)
  if valid_21626447 != nil:
    section.add "Id", valid_21626447
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the identity's configuration. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626448 = header.getOrDefault("X-Amz-Date")
  valid_21626448 = validateParameter(valid_21626448, JString, required = false,
                                   default = nil)
  if valid_21626448 != nil:
    section.add "X-Amz-Date", valid_21626448
  var valid_21626449 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626449 = validateParameter(valid_21626449, JString, required = false,
                                   default = nil)
  if valid_21626449 != nil:
    section.add "X-Amz-Security-Token", valid_21626449
  var valid_21626450 = header.getOrDefault("If-Match")
  valid_21626450 = validateParameter(valid_21626450, JString, required = false,
                                   default = nil)
  if valid_21626450 != nil:
    section.add "If-Match", valid_21626450
  var valid_21626451 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626451 = validateParameter(valid_21626451, JString, required = false,
                                   default = nil)
  if valid_21626451 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626451
  var valid_21626452 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626452 = validateParameter(valid_21626452, JString, required = false,
                                   default = nil)
  if valid_21626452 != nil:
    section.add "X-Amz-Algorithm", valid_21626452
  var valid_21626453 = header.getOrDefault("X-Amz-Signature")
  valid_21626453 = validateParameter(valid_21626453, JString, required = false,
                                   default = nil)
  if valid_21626453 != nil:
    section.add "X-Amz-Signature", valid_21626453
  var valid_21626454 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626454 = validateParameter(valid_21626454, JString, required = false,
                                   default = nil)
  if valid_21626454 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626454
  var valid_21626455 = header.getOrDefault("X-Amz-Credential")
  valid_21626455 = validateParameter(valid_21626455, JString, required = false,
                                   default = nil)
  if valid_21626455 != nil:
    section.add "X-Amz-Credential", valid_21626455
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

proc call*(call_21626457: Call_UpdateCloudFrontOriginAccessIdentity20190326_21626444;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Update an origin access identity. 
  ## 
  let valid = call_21626457.validator(path, query, header, formData, body, _)
  let scheme = call_21626457.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626457.makeUrl(scheme.get, call_21626457.host, call_21626457.base,
                               call_21626457.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626457, uri, valid, _)

proc call*(call_21626458: Call_UpdateCloudFrontOriginAccessIdentity20190326_21626444;
          Id: string; body: JsonNode): Recallable =
  ## updateCloudFrontOriginAccessIdentity20190326
  ## Update an origin access identity. 
  ##   Id: string (required)
  ##     : The identity's id.
  ##   body: JObject (required)
  var path_21626459 = newJObject()
  var body_21626460 = newJObject()
  add(path_21626459, "Id", newJString(Id))
  if body != nil:
    body_21626460 = body
  result = call_21626458.call(path_21626459, nil, nil, nil, body_21626460)

var updateCloudFrontOriginAccessIdentity20190326* = Call_UpdateCloudFrontOriginAccessIdentity20190326_21626444(
    name: "updateCloudFrontOriginAccessIdentity20190326",
    meth: HttpMethod.HttpPut, host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/origin-access-identity/cloudfront/{Id}/config",
    validator: validate_UpdateCloudFrontOriginAccessIdentity20190326_21626445,
    base: "/", makeUrl: url_UpdateCloudFrontOriginAccessIdentity20190326_21626446,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCloudFrontOriginAccessIdentityConfig20190326_21626430 = ref object of OpenApiRestCall_21625435
proc url_GetCloudFrontOriginAccessIdentityConfig20190326_21626432(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetCloudFrontOriginAccessIdentityConfig20190326_21626431(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Get the configuration information about an origin access identity. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The identity's ID. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_21626433 = path.getOrDefault("Id")
  valid_21626433 = validateParameter(valid_21626433, JString, required = true,
                                   default = nil)
  if valid_21626433 != nil:
    section.add "Id", valid_21626433
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626434 = header.getOrDefault("X-Amz-Date")
  valid_21626434 = validateParameter(valid_21626434, JString, required = false,
                                   default = nil)
  if valid_21626434 != nil:
    section.add "X-Amz-Date", valid_21626434
  var valid_21626435 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626435 = validateParameter(valid_21626435, JString, required = false,
                                   default = nil)
  if valid_21626435 != nil:
    section.add "X-Amz-Security-Token", valid_21626435
  var valid_21626436 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626436 = validateParameter(valid_21626436, JString, required = false,
                                   default = nil)
  if valid_21626436 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626436
  var valid_21626437 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626437 = validateParameter(valid_21626437, JString, required = false,
                                   default = nil)
  if valid_21626437 != nil:
    section.add "X-Amz-Algorithm", valid_21626437
  var valid_21626438 = header.getOrDefault("X-Amz-Signature")
  valid_21626438 = validateParameter(valid_21626438, JString, required = false,
                                   default = nil)
  if valid_21626438 != nil:
    section.add "X-Amz-Signature", valid_21626438
  var valid_21626439 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626439 = validateParameter(valid_21626439, JString, required = false,
                                   default = nil)
  if valid_21626439 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626439
  var valid_21626440 = header.getOrDefault("X-Amz-Credential")
  valid_21626440 = validateParameter(valid_21626440, JString, required = false,
                                   default = nil)
  if valid_21626440 != nil:
    section.add "X-Amz-Credential", valid_21626440
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626441: Call_GetCloudFrontOriginAccessIdentityConfig20190326_21626430;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Get the configuration information about an origin access identity. 
  ## 
  let valid = call_21626441.validator(path, query, header, formData, body, _)
  let scheme = call_21626441.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626441.makeUrl(scheme.get, call_21626441.host, call_21626441.base,
                               call_21626441.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626441, uri, valid, _)

proc call*(call_21626442: Call_GetCloudFrontOriginAccessIdentityConfig20190326_21626430;
          Id: string): Recallable =
  ## getCloudFrontOriginAccessIdentityConfig20190326
  ## Get the configuration information about an origin access identity. 
  ##   Id: string (required)
  ##     : The identity's ID. 
  var path_21626443 = newJObject()
  add(path_21626443, "Id", newJString(Id))
  result = call_21626442.call(path_21626443, nil, nil, nil, nil)

var getCloudFrontOriginAccessIdentityConfig20190326* = Call_GetCloudFrontOriginAccessIdentityConfig20190326_21626430(
    name: "getCloudFrontOriginAccessIdentityConfig20190326",
    meth: HttpMethod.HttpGet, host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/origin-access-identity/cloudfront/{Id}/config",
    validator: validate_GetCloudFrontOriginAccessIdentityConfig20190326_21626431,
    base: "/", makeUrl: url_GetCloudFrontOriginAccessIdentityConfig20190326_21626432,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDistribution20190326_21626475 = ref object of OpenApiRestCall_21625435
proc url_UpdateDistribution20190326_21626477(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDistribution20190326_21626476(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Updates the configuration for a web distribution. </p> <important> <p>When you update a distribution, there are more required fields than when you create a distribution. When you update your distribution by using this API action, follow the steps here to get the current configuration and then make your updates, to make sure that you include all of the required fields. To view a summary, see <a href="https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-overview-required-fields.html">Required Fields for Create Distribution and Update Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> </important> <p>The update process includes getting the current distribution configuration, updating the XML document that is returned to make your changes, and then submitting an <code>UpdateDistribution</code> request to make the updates.</p> <p>For information about updating a distribution using the CloudFront console instead, see <a href="https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-web-creating-console.html">Creating a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <p> <b>To update a web distribution using the CloudFront API</b> </p> <ol> <li> <p>Submit a <a href="https://docs.aws.amazon.com/cloudfront/latest/APIReference/API_GetDistributionConfig.html">GetDistributionConfig</a> request to get the current configuration and an <code>Etag</code> header for the distribution.</p> <note> <p>If you update the distribution again, you must get a new <code>Etag</code> header.</p> </note> </li> <li> <p>Update the XML document that was returned in the response to your <code>GetDistributionConfig</code> request to include your changes. </p> <important> <p>When you edit the XML file, be aware of the following:</p> <ul> <li> <p>You must strip out the ETag parameter that is returned.</p> </li> <li> <p>Additional fields are required when you update a distribution. There may be fields included in the XML file for features that you haven't configured for your distribution. This is expected and required to successfully update the distribution.</p> </li> <li> <p>You can't change the value of <code>CallerReference</code>. If you try to change this value, CloudFront returns an <code>IllegalUpdate</code> error. </p> </li> <li> <p>The new configuration replaces the existing configuration; the values that you specify in an <code>UpdateDistribution</code> request are not merged into your existing configuration. When you add, delete, or replace values in an element that allows multiple values (for example, <code>CNAME</code>), you must specify all of the values that you want to appear in the updated distribution. In addition, you must update the corresponding <code>Quantity</code> element.</p> </li> </ul> </important> </li> <li> <p>Submit an <code>UpdateDistribution</code> request to update the configuration for your distribution:</p> <ul> <li> <p>In the request body, include the XML document that you updated in Step 2. The request body must include an XML document with a <code>DistributionConfig</code> element.</p> </li> <li> <p>Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GetDistributionConfig</code> request in Step 1.</p> </li> </ul> </li> <li> <p>Review the response to the <code>UpdateDistribution</code> request to confirm that the configuration was successfully updated.</p> </li> <li> <p>Optional: Submit a <a href="https://docs.aws.amazon.com/cloudfront/latest/APIReference/API_GetDistribution.html">GetDistribution</a> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> </ol>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The distribution's id.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_21626478 = path.getOrDefault("Id")
  valid_21626478 = validateParameter(valid_21626478, JString, required = true,
                                   default = nil)
  if valid_21626478 != nil:
    section.add "Id", valid_21626478
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the distribution's configuration. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626479 = header.getOrDefault("X-Amz-Date")
  valid_21626479 = validateParameter(valid_21626479, JString, required = false,
                                   default = nil)
  if valid_21626479 != nil:
    section.add "X-Amz-Date", valid_21626479
  var valid_21626480 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626480 = validateParameter(valid_21626480, JString, required = false,
                                   default = nil)
  if valid_21626480 != nil:
    section.add "X-Amz-Security-Token", valid_21626480
  var valid_21626481 = header.getOrDefault("If-Match")
  valid_21626481 = validateParameter(valid_21626481, JString, required = false,
                                   default = nil)
  if valid_21626481 != nil:
    section.add "If-Match", valid_21626481
  var valid_21626482 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626482 = validateParameter(valid_21626482, JString, required = false,
                                   default = nil)
  if valid_21626482 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626482
  var valid_21626483 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626483 = validateParameter(valid_21626483, JString, required = false,
                                   default = nil)
  if valid_21626483 != nil:
    section.add "X-Amz-Algorithm", valid_21626483
  var valid_21626484 = header.getOrDefault("X-Amz-Signature")
  valid_21626484 = validateParameter(valid_21626484, JString, required = false,
                                   default = nil)
  if valid_21626484 != nil:
    section.add "X-Amz-Signature", valid_21626484
  var valid_21626485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626485 = validateParameter(valid_21626485, JString, required = false,
                                   default = nil)
  if valid_21626485 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626485
  var valid_21626486 = header.getOrDefault("X-Amz-Credential")
  valid_21626486 = validateParameter(valid_21626486, JString, required = false,
                                   default = nil)
  if valid_21626486 != nil:
    section.add "X-Amz-Credential", valid_21626486
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

proc call*(call_21626488: Call_UpdateDistribution20190326_21626475;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates the configuration for a web distribution. </p> <important> <p>When you update a distribution, there are more required fields than when you create a distribution. When you update your distribution by using this API action, follow the steps here to get the current configuration and then make your updates, to make sure that you include all of the required fields. To view a summary, see <a href="https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-overview-required-fields.html">Required Fields for Create Distribution and Update Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> </important> <p>The update process includes getting the current distribution configuration, updating the XML document that is returned to make your changes, and then submitting an <code>UpdateDistribution</code> request to make the updates.</p> <p>For information about updating a distribution using the CloudFront console instead, see <a href="https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-web-creating-console.html">Creating a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <p> <b>To update a web distribution using the CloudFront API</b> </p> <ol> <li> <p>Submit a <a href="https://docs.aws.amazon.com/cloudfront/latest/APIReference/API_GetDistributionConfig.html">GetDistributionConfig</a> request to get the current configuration and an <code>Etag</code> header for the distribution.</p> <note> <p>If you update the distribution again, you must get a new <code>Etag</code> header.</p> </note> </li> <li> <p>Update the XML document that was returned in the response to your <code>GetDistributionConfig</code> request to include your changes. </p> <important> <p>When you edit the XML file, be aware of the following:</p> <ul> <li> <p>You must strip out the ETag parameter that is returned.</p> </li> <li> <p>Additional fields are required when you update a distribution. There may be fields included in the XML file for features that you haven't configured for your distribution. This is expected and required to successfully update the distribution.</p> </li> <li> <p>You can't change the value of <code>CallerReference</code>. If you try to change this value, CloudFront returns an <code>IllegalUpdate</code> error. </p> </li> <li> <p>The new configuration replaces the existing configuration; the values that you specify in an <code>UpdateDistribution</code> request are not merged into your existing configuration. When you add, delete, or replace values in an element that allows multiple values (for example, <code>CNAME</code>), you must specify all of the values that you want to appear in the updated distribution. In addition, you must update the corresponding <code>Quantity</code> element.</p> </li> </ul> </important> </li> <li> <p>Submit an <code>UpdateDistribution</code> request to update the configuration for your distribution:</p> <ul> <li> <p>In the request body, include the XML document that you updated in Step 2. The request body must include an XML document with a <code>DistributionConfig</code> element.</p> </li> <li> <p>Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GetDistributionConfig</code> request in Step 1.</p> </li> </ul> </li> <li> <p>Review the response to the <code>UpdateDistribution</code> request to confirm that the configuration was successfully updated.</p> </li> <li> <p>Optional: Submit a <a href="https://docs.aws.amazon.com/cloudfront/latest/APIReference/API_GetDistribution.html">GetDistribution</a> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> </ol>
  ## 
  let valid = call_21626488.validator(path, query, header, formData, body, _)
  let scheme = call_21626488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626488.makeUrl(scheme.get, call_21626488.host, call_21626488.base,
                               call_21626488.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626488, uri, valid, _)

proc call*(call_21626489: Call_UpdateDistribution20190326_21626475; Id: string;
          body: JsonNode): Recallable =
  ## updateDistribution20190326
  ## <p>Updates the configuration for a web distribution. </p> <important> <p>When you update a distribution, there are more required fields than when you create a distribution. When you update your distribution by using this API action, follow the steps here to get the current configuration and then make your updates, to make sure that you include all of the required fields. To view a summary, see <a href="https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-overview-required-fields.html">Required Fields for Create Distribution and Update Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> </important> <p>The update process includes getting the current distribution configuration, updating the XML document that is returned to make your changes, and then submitting an <code>UpdateDistribution</code> request to make the updates.</p> <p>For information about updating a distribution using the CloudFront console instead, see <a href="https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-web-creating-console.html">Creating a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <p> <b>To update a web distribution using the CloudFront API</b> </p> <ol> <li> <p>Submit a <a href="https://docs.aws.amazon.com/cloudfront/latest/APIReference/API_GetDistributionConfig.html">GetDistributionConfig</a> request to get the current configuration and an <code>Etag</code> header for the distribution.</p> <note> <p>If you update the distribution again, you must get a new <code>Etag</code> header.</p> </note> </li> <li> <p>Update the XML document that was returned in the response to your <code>GetDistributionConfig</code> request to include your changes. </p> <important> <p>When you edit the XML file, be aware of the following:</p> <ul> <li> <p>You must strip out the ETag parameter that is returned.</p> </li> <li> <p>Additional fields are required when you update a distribution. There may be fields included in the XML file for features that you haven't configured for your distribution. This is expected and required to successfully update the distribution.</p> </li> <li> <p>You can't change the value of <code>CallerReference</code>. If you try to change this value, CloudFront returns an <code>IllegalUpdate</code> error. </p> </li> <li> <p>The new configuration replaces the existing configuration; the values that you specify in an <code>UpdateDistribution</code> request are not merged into your existing configuration. When you add, delete, or replace values in an element that allows multiple values (for example, <code>CNAME</code>), you must specify all of the values that you want to appear in the updated distribution. In addition, you must update the corresponding <code>Quantity</code> element.</p> </li> </ul> </important> </li> <li> <p>Submit an <code>UpdateDistribution</code> request to update the configuration for your distribution:</p> <ul> <li> <p>In the request body, include the XML document that you updated in Step 2. The request body must include an XML document with a <code>DistributionConfig</code> element.</p> </li> <li> <p>Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GetDistributionConfig</code> request in Step 1.</p> </li> </ul> </li> <li> <p>Review the response to the <code>UpdateDistribution</code> request to confirm that the configuration was successfully updated.</p> </li> <li> <p>Optional: Submit a <a href="https://docs.aws.amazon.com/cloudfront/latest/APIReference/API_GetDistribution.html">GetDistribution</a> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> </ol>
  ##   Id: string (required)
  ##     : The distribution's id.
  ##   body: JObject (required)
  var path_21626490 = newJObject()
  var body_21626491 = newJObject()
  add(path_21626490, "Id", newJString(Id))
  if body != nil:
    body_21626491 = body
  result = call_21626489.call(path_21626490, nil, nil, nil, body_21626491)

var updateDistribution20190326* = Call_UpdateDistribution20190326_21626475(
    name: "updateDistribution20190326", meth: HttpMethod.HttpPut,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/distribution/{Id}/config",
    validator: validate_UpdateDistribution20190326_21626476, base: "/",
    makeUrl: url_UpdateDistribution20190326_21626477,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDistributionConfig20190326_21626461 = ref object of OpenApiRestCall_21625435
proc url_GetDistributionConfig20190326_21626463(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDistributionConfig20190326_21626462(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Get the configuration information about a distribution. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The distribution's ID. If the ID is empty, an empty distribution configuration is returned.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_21626464 = path.getOrDefault("Id")
  valid_21626464 = validateParameter(valid_21626464, JString, required = true,
                                   default = nil)
  if valid_21626464 != nil:
    section.add "Id", valid_21626464
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626465 = header.getOrDefault("X-Amz-Date")
  valid_21626465 = validateParameter(valid_21626465, JString, required = false,
                                   default = nil)
  if valid_21626465 != nil:
    section.add "X-Amz-Date", valid_21626465
  var valid_21626466 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626466 = validateParameter(valid_21626466, JString, required = false,
                                   default = nil)
  if valid_21626466 != nil:
    section.add "X-Amz-Security-Token", valid_21626466
  var valid_21626467 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626467 = validateParameter(valid_21626467, JString, required = false,
                                   default = nil)
  if valid_21626467 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626467
  var valid_21626468 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626468 = validateParameter(valid_21626468, JString, required = false,
                                   default = nil)
  if valid_21626468 != nil:
    section.add "X-Amz-Algorithm", valid_21626468
  var valid_21626469 = header.getOrDefault("X-Amz-Signature")
  valid_21626469 = validateParameter(valid_21626469, JString, required = false,
                                   default = nil)
  if valid_21626469 != nil:
    section.add "X-Amz-Signature", valid_21626469
  var valid_21626470 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626470 = validateParameter(valid_21626470, JString, required = false,
                                   default = nil)
  if valid_21626470 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626470
  var valid_21626471 = header.getOrDefault("X-Amz-Credential")
  valid_21626471 = validateParameter(valid_21626471, JString, required = false,
                                   default = nil)
  if valid_21626471 != nil:
    section.add "X-Amz-Credential", valid_21626471
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626472: Call_GetDistributionConfig20190326_21626461;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Get the configuration information about a distribution. 
  ## 
  let valid = call_21626472.validator(path, query, header, formData, body, _)
  let scheme = call_21626472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626472.makeUrl(scheme.get, call_21626472.host, call_21626472.base,
                               call_21626472.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626472, uri, valid, _)

proc call*(call_21626473: Call_GetDistributionConfig20190326_21626461; Id: string): Recallable =
  ## getDistributionConfig20190326
  ## Get the configuration information about a distribution. 
  ##   Id: string (required)
  ##     : The distribution's ID. If the ID is empty, an empty distribution configuration is returned.
  var path_21626474 = newJObject()
  add(path_21626474, "Id", newJString(Id))
  result = call_21626473.call(path_21626474, nil, nil, nil, nil)

var getDistributionConfig20190326* = Call_GetDistributionConfig20190326_21626461(
    name: "getDistributionConfig20190326", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/distribution/{Id}/config",
    validator: validate_GetDistributionConfig20190326_21626462, base: "/",
    makeUrl: url_GetDistributionConfig20190326_21626463,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFieldLevelEncryptionConfig20190326_21626506 = ref object of OpenApiRestCall_21625435
proc url_UpdateFieldLevelEncryptionConfig20190326_21626508(protocol: Scheme;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateFieldLevelEncryptionConfig20190326_21626507(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Update a field-level encryption configuration. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the configuration you want to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_21626509 = path.getOrDefault("Id")
  valid_21626509 = validateParameter(valid_21626509, JString, required = true,
                                   default = nil)
  if valid_21626509 != nil:
    section.add "Id", valid_21626509
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the configuration identity to update. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626510 = header.getOrDefault("X-Amz-Date")
  valid_21626510 = validateParameter(valid_21626510, JString, required = false,
                                   default = nil)
  if valid_21626510 != nil:
    section.add "X-Amz-Date", valid_21626510
  var valid_21626511 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626511 = validateParameter(valid_21626511, JString, required = false,
                                   default = nil)
  if valid_21626511 != nil:
    section.add "X-Amz-Security-Token", valid_21626511
  var valid_21626512 = header.getOrDefault("If-Match")
  valid_21626512 = validateParameter(valid_21626512, JString, required = false,
                                   default = nil)
  if valid_21626512 != nil:
    section.add "If-Match", valid_21626512
  var valid_21626513 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626513 = validateParameter(valid_21626513, JString, required = false,
                                   default = nil)
  if valid_21626513 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626513
  var valid_21626514 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626514 = validateParameter(valid_21626514, JString, required = false,
                                   default = nil)
  if valid_21626514 != nil:
    section.add "X-Amz-Algorithm", valid_21626514
  var valid_21626515 = header.getOrDefault("X-Amz-Signature")
  valid_21626515 = validateParameter(valid_21626515, JString, required = false,
                                   default = nil)
  if valid_21626515 != nil:
    section.add "X-Amz-Signature", valid_21626515
  var valid_21626516 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626516 = validateParameter(valid_21626516, JString, required = false,
                                   default = nil)
  if valid_21626516 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626516
  var valid_21626517 = header.getOrDefault("X-Amz-Credential")
  valid_21626517 = validateParameter(valid_21626517, JString, required = false,
                                   default = nil)
  if valid_21626517 != nil:
    section.add "X-Amz-Credential", valid_21626517
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

proc call*(call_21626519: Call_UpdateFieldLevelEncryptionConfig20190326_21626506;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Update a field-level encryption configuration. 
  ## 
  let valid = call_21626519.validator(path, query, header, formData, body, _)
  let scheme = call_21626519.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626519.makeUrl(scheme.get, call_21626519.host, call_21626519.base,
                               call_21626519.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626519, uri, valid, _)

proc call*(call_21626520: Call_UpdateFieldLevelEncryptionConfig20190326_21626506;
          Id: string; body: JsonNode): Recallable =
  ## updateFieldLevelEncryptionConfig20190326
  ## Update a field-level encryption configuration. 
  ##   Id: string (required)
  ##     : The ID of the configuration you want to update.
  ##   body: JObject (required)
  var path_21626521 = newJObject()
  var body_21626522 = newJObject()
  add(path_21626521, "Id", newJString(Id))
  if body != nil:
    body_21626522 = body
  result = call_21626520.call(path_21626521, nil, nil, nil, body_21626522)

var updateFieldLevelEncryptionConfig20190326* = Call_UpdateFieldLevelEncryptionConfig20190326_21626506(
    name: "updateFieldLevelEncryptionConfig20190326", meth: HttpMethod.HttpPut,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/field-level-encryption/{Id}/config",
    validator: validate_UpdateFieldLevelEncryptionConfig20190326_21626507,
    base: "/", makeUrl: url_UpdateFieldLevelEncryptionConfig20190326_21626508,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFieldLevelEncryptionConfig20190326_21626492 = ref object of OpenApiRestCall_21625435
proc url_GetFieldLevelEncryptionConfig20190326_21626494(protocol: Scheme;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFieldLevelEncryptionConfig20190326_21626493(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Get the field-level encryption configuration information.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : Request the ID for the field-level encryption configuration information.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_21626495 = path.getOrDefault("Id")
  valid_21626495 = validateParameter(valid_21626495, JString, required = true,
                                   default = nil)
  if valid_21626495 != nil:
    section.add "Id", valid_21626495
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626496 = header.getOrDefault("X-Amz-Date")
  valid_21626496 = validateParameter(valid_21626496, JString, required = false,
                                   default = nil)
  if valid_21626496 != nil:
    section.add "X-Amz-Date", valid_21626496
  var valid_21626497 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626497 = validateParameter(valid_21626497, JString, required = false,
                                   default = nil)
  if valid_21626497 != nil:
    section.add "X-Amz-Security-Token", valid_21626497
  var valid_21626498 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626498 = validateParameter(valid_21626498, JString, required = false,
                                   default = nil)
  if valid_21626498 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626498
  var valid_21626499 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626499 = validateParameter(valid_21626499, JString, required = false,
                                   default = nil)
  if valid_21626499 != nil:
    section.add "X-Amz-Algorithm", valid_21626499
  var valid_21626500 = header.getOrDefault("X-Amz-Signature")
  valid_21626500 = validateParameter(valid_21626500, JString, required = false,
                                   default = nil)
  if valid_21626500 != nil:
    section.add "X-Amz-Signature", valid_21626500
  var valid_21626501 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626501 = validateParameter(valid_21626501, JString, required = false,
                                   default = nil)
  if valid_21626501 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626501
  var valid_21626502 = header.getOrDefault("X-Amz-Credential")
  valid_21626502 = validateParameter(valid_21626502, JString, required = false,
                                   default = nil)
  if valid_21626502 != nil:
    section.add "X-Amz-Credential", valid_21626502
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626503: Call_GetFieldLevelEncryptionConfig20190326_21626492;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Get the field-level encryption configuration information.
  ## 
  let valid = call_21626503.validator(path, query, header, formData, body, _)
  let scheme = call_21626503.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626503.makeUrl(scheme.get, call_21626503.host, call_21626503.base,
                               call_21626503.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626503, uri, valid, _)

proc call*(call_21626504: Call_GetFieldLevelEncryptionConfig20190326_21626492;
          Id: string): Recallable =
  ## getFieldLevelEncryptionConfig20190326
  ## Get the field-level encryption configuration information.
  ##   Id: string (required)
  ##     : Request the ID for the field-level encryption configuration information.
  var path_21626505 = newJObject()
  add(path_21626505, "Id", newJString(Id))
  result = call_21626504.call(path_21626505, nil, nil, nil, nil)

var getFieldLevelEncryptionConfig20190326* = Call_GetFieldLevelEncryptionConfig20190326_21626492(
    name: "getFieldLevelEncryptionConfig20190326", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/field-level-encryption/{Id}/config",
    validator: validate_GetFieldLevelEncryptionConfig20190326_21626493, base: "/",
    makeUrl: url_GetFieldLevelEncryptionConfig20190326_21626494,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFieldLevelEncryptionProfile20190326_21626537 = ref object of OpenApiRestCall_21625435
proc url_UpdateFieldLevelEncryptionProfile20190326_21626539(protocol: Scheme;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateFieldLevelEncryptionProfile20190326_21626538(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Update a field-level encryption profile. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the field-level encryption profile request. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_21626540 = path.getOrDefault("Id")
  valid_21626540 = validateParameter(valid_21626540, JString, required = true,
                                   default = nil)
  if valid_21626540 != nil:
    section.add "Id", valid_21626540
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the profile identity to update. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626541 = header.getOrDefault("X-Amz-Date")
  valid_21626541 = validateParameter(valid_21626541, JString, required = false,
                                   default = nil)
  if valid_21626541 != nil:
    section.add "X-Amz-Date", valid_21626541
  var valid_21626542 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626542 = validateParameter(valid_21626542, JString, required = false,
                                   default = nil)
  if valid_21626542 != nil:
    section.add "X-Amz-Security-Token", valid_21626542
  var valid_21626543 = header.getOrDefault("If-Match")
  valid_21626543 = validateParameter(valid_21626543, JString, required = false,
                                   default = nil)
  if valid_21626543 != nil:
    section.add "If-Match", valid_21626543
  var valid_21626544 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626544 = validateParameter(valid_21626544, JString, required = false,
                                   default = nil)
  if valid_21626544 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626544
  var valid_21626545 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626545 = validateParameter(valid_21626545, JString, required = false,
                                   default = nil)
  if valid_21626545 != nil:
    section.add "X-Amz-Algorithm", valid_21626545
  var valid_21626546 = header.getOrDefault("X-Amz-Signature")
  valid_21626546 = validateParameter(valid_21626546, JString, required = false,
                                   default = nil)
  if valid_21626546 != nil:
    section.add "X-Amz-Signature", valid_21626546
  var valid_21626547 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626547 = validateParameter(valid_21626547, JString, required = false,
                                   default = nil)
  if valid_21626547 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626547
  var valid_21626548 = header.getOrDefault("X-Amz-Credential")
  valid_21626548 = validateParameter(valid_21626548, JString, required = false,
                                   default = nil)
  if valid_21626548 != nil:
    section.add "X-Amz-Credential", valid_21626548
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

proc call*(call_21626550: Call_UpdateFieldLevelEncryptionProfile20190326_21626537;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Update a field-level encryption profile. 
  ## 
  let valid = call_21626550.validator(path, query, header, formData, body, _)
  let scheme = call_21626550.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626550.makeUrl(scheme.get, call_21626550.host, call_21626550.base,
                               call_21626550.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626550, uri, valid, _)

proc call*(call_21626551: Call_UpdateFieldLevelEncryptionProfile20190326_21626537;
          Id: string; body: JsonNode): Recallable =
  ## updateFieldLevelEncryptionProfile20190326
  ## Update a field-level encryption profile. 
  ##   Id: string (required)
  ##     : The ID of the field-level encryption profile request. 
  ##   body: JObject (required)
  var path_21626552 = newJObject()
  var body_21626553 = newJObject()
  add(path_21626552, "Id", newJString(Id))
  if body != nil:
    body_21626553 = body
  result = call_21626551.call(path_21626552, nil, nil, nil, body_21626553)

var updateFieldLevelEncryptionProfile20190326* = Call_UpdateFieldLevelEncryptionProfile20190326_21626537(
    name: "updateFieldLevelEncryptionProfile20190326", meth: HttpMethod.HttpPut,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/field-level-encryption-profile/{Id}/config",
    validator: validate_UpdateFieldLevelEncryptionProfile20190326_21626538,
    base: "/", makeUrl: url_UpdateFieldLevelEncryptionProfile20190326_21626539,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFieldLevelEncryptionProfileConfig20190326_21626523 = ref object of OpenApiRestCall_21625435
proc url_GetFieldLevelEncryptionProfileConfig20190326_21626525(protocol: Scheme;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFieldLevelEncryptionProfileConfig20190326_21626524(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Get the field-level encryption profile configuration information.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : Get the ID for the field-level encryption profile configuration information.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_21626526 = path.getOrDefault("Id")
  valid_21626526 = validateParameter(valid_21626526, JString, required = true,
                                   default = nil)
  if valid_21626526 != nil:
    section.add "Id", valid_21626526
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626527 = header.getOrDefault("X-Amz-Date")
  valid_21626527 = validateParameter(valid_21626527, JString, required = false,
                                   default = nil)
  if valid_21626527 != nil:
    section.add "X-Amz-Date", valid_21626527
  var valid_21626528 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626528 = validateParameter(valid_21626528, JString, required = false,
                                   default = nil)
  if valid_21626528 != nil:
    section.add "X-Amz-Security-Token", valid_21626528
  var valid_21626529 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626529 = validateParameter(valid_21626529, JString, required = false,
                                   default = nil)
  if valid_21626529 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626529
  var valid_21626530 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626530 = validateParameter(valid_21626530, JString, required = false,
                                   default = nil)
  if valid_21626530 != nil:
    section.add "X-Amz-Algorithm", valid_21626530
  var valid_21626531 = header.getOrDefault("X-Amz-Signature")
  valid_21626531 = validateParameter(valid_21626531, JString, required = false,
                                   default = nil)
  if valid_21626531 != nil:
    section.add "X-Amz-Signature", valid_21626531
  var valid_21626532 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626532 = validateParameter(valid_21626532, JString, required = false,
                                   default = nil)
  if valid_21626532 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626532
  var valid_21626533 = header.getOrDefault("X-Amz-Credential")
  valid_21626533 = validateParameter(valid_21626533, JString, required = false,
                                   default = nil)
  if valid_21626533 != nil:
    section.add "X-Amz-Credential", valid_21626533
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626534: Call_GetFieldLevelEncryptionProfileConfig20190326_21626523;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Get the field-level encryption profile configuration information.
  ## 
  let valid = call_21626534.validator(path, query, header, formData, body, _)
  let scheme = call_21626534.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626534.makeUrl(scheme.get, call_21626534.host, call_21626534.base,
                               call_21626534.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626534, uri, valid, _)

proc call*(call_21626535: Call_GetFieldLevelEncryptionProfileConfig20190326_21626523;
          Id: string): Recallable =
  ## getFieldLevelEncryptionProfileConfig20190326
  ## Get the field-level encryption profile configuration information.
  ##   Id: string (required)
  ##     : Get the ID for the field-level encryption profile configuration information.
  var path_21626536 = newJObject()
  add(path_21626536, "Id", newJString(Id))
  result = call_21626535.call(path_21626536, nil, nil, nil, nil)

var getFieldLevelEncryptionProfileConfig20190326* = Call_GetFieldLevelEncryptionProfileConfig20190326_21626523(
    name: "getFieldLevelEncryptionProfileConfig20190326",
    meth: HttpMethod.HttpGet, host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/field-level-encryption-profile/{Id}/config",
    validator: validate_GetFieldLevelEncryptionProfileConfig20190326_21626524,
    base: "/", makeUrl: url_GetFieldLevelEncryptionProfileConfig20190326_21626525,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInvalidation20190326_21626554 = ref object of OpenApiRestCall_21625435
proc url_GetInvalidation20190326_21626556(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetInvalidation20190326_21626555(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Get the information about an invalidation. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The identifier for the invalidation request, for example, <code>IDFDVBD632BHDS5</code>.
  ##   DistributionId: JString (required)
  ##                 : The distribution's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_21626557 = path.getOrDefault("Id")
  valid_21626557 = validateParameter(valid_21626557, JString, required = true,
                                   default = nil)
  if valid_21626557 != nil:
    section.add "Id", valid_21626557
  var valid_21626558 = path.getOrDefault("DistributionId")
  valid_21626558 = validateParameter(valid_21626558, JString, required = true,
                                   default = nil)
  if valid_21626558 != nil:
    section.add "DistributionId", valid_21626558
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
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
  var valid_21626561 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626561 = validateParameter(valid_21626561, JString, required = false,
                                   default = nil)
  if valid_21626561 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626561
  var valid_21626562 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626562 = validateParameter(valid_21626562, JString, required = false,
                                   default = nil)
  if valid_21626562 != nil:
    section.add "X-Amz-Algorithm", valid_21626562
  var valid_21626563 = header.getOrDefault("X-Amz-Signature")
  valid_21626563 = validateParameter(valid_21626563, JString, required = false,
                                   default = nil)
  if valid_21626563 != nil:
    section.add "X-Amz-Signature", valid_21626563
  var valid_21626564 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626564 = validateParameter(valid_21626564, JString, required = false,
                                   default = nil)
  if valid_21626564 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626564
  var valid_21626565 = header.getOrDefault("X-Amz-Credential")
  valid_21626565 = validateParameter(valid_21626565, JString, required = false,
                                   default = nil)
  if valid_21626565 != nil:
    section.add "X-Amz-Credential", valid_21626565
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626566: Call_GetInvalidation20190326_21626554;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Get the information about an invalidation. 
  ## 
  let valid = call_21626566.validator(path, query, header, formData, body, _)
  let scheme = call_21626566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626566.makeUrl(scheme.get, call_21626566.host, call_21626566.base,
                               call_21626566.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626566, uri, valid, _)

proc call*(call_21626567: Call_GetInvalidation20190326_21626554; Id: string;
          DistributionId: string): Recallable =
  ## getInvalidation20190326
  ## Get the information about an invalidation. 
  ##   Id: string (required)
  ##     : The identifier for the invalidation request, for example, <code>IDFDVBD632BHDS5</code>.
  ##   DistributionId: string (required)
  ##                 : The distribution's ID.
  var path_21626568 = newJObject()
  add(path_21626568, "Id", newJString(Id))
  add(path_21626568, "DistributionId", newJString(DistributionId))
  result = call_21626567.call(path_21626568, nil, nil, nil, nil)

var getInvalidation20190326* = Call_GetInvalidation20190326_21626554(
    name: "getInvalidation20190326", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/distribution/{DistributionId}/invalidation/{Id}",
    validator: validate_GetInvalidation20190326_21626555, base: "/",
    makeUrl: url_GetInvalidation20190326_21626556,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePublicKey20190326_21626583 = ref object of OpenApiRestCall_21625435
proc url_UpdatePublicKey20190326_21626585(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdatePublicKey20190326_21626584(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Update public key information. Note that the only value you can change is the comment.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : ID of the public key to be updated.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_21626586 = path.getOrDefault("Id")
  valid_21626586 = validateParameter(valid_21626586, JString, required = true,
                                   default = nil)
  if valid_21626586 != nil:
    section.add "Id", valid_21626586
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the public key to update. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626587 = header.getOrDefault("X-Amz-Date")
  valid_21626587 = validateParameter(valid_21626587, JString, required = false,
                                   default = nil)
  if valid_21626587 != nil:
    section.add "X-Amz-Date", valid_21626587
  var valid_21626588 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626588 = validateParameter(valid_21626588, JString, required = false,
                                   default = nil)
  if valid_21626588 != nil:
    section.add "X-Amz-Security-Token", valid_21626588
  var valid_21626589 = header.getOrDefault("If-Match")
  valid_21626589 = validateParameter(valid_21626589, JString, required = false,
                                   default = nil)
  if valid_21626589 != nil:
    section.add "If-Match", valid_21626589
  var valid_21626590 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626590 = validateParameter(valid_21626590, JString, required = false,
                                   default = nil)
  if valid_21626590 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626590
  var valid_21626591 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626591 = validateParameter(valid_21626591, JString, required = false,
                                   default = nil)
  if valid_21626591 != nil:
    section.add "X-Amz-Algorithm", valid_21626591
  var valid_21626592 = header.getOrDefault("X-Amz-Signature")
  valid_21626592 = validateParameter(valid_21626592, JString, required = false,
                                   default = nil)
  if valid_21626592 != nil:
    section.add "X-Amz-Signature", valid_21626592
  var valid_21626593 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626593 = validateParameter(valid_21626593, JString, required = false,
                                   default = nil)
  if valid_21626593 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626593
  var valid_21626594 = header.getOrDefault("X-Amz-Credential")
  valid_21626594 = validateParameter(valid_21626594, JString, required = false,
                                   default = nil)
  if valid_21626594 != nil:
    section.add "X-Amz-Credential", valid_21626594
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

proc call*(call_21626596: Call_UpdatePublicKey20190326_21626583;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Update public key information. Note that the only value you can change is the comment.
  ## 
  let valid = call_21626596.validator(path, query, header, formData, body, _)
  let scheme = call_21626596.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626596.makeUrl(scheme.get, call_21626596.host, call_21626596.base,
                               call_21626596.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626596, uri, valid, _)

proc call*(call_21626597: Call_UpdatePublicKey20190326_21626583; Id: string;
          body: JsonNode): Recallable =
  ## updatePublicKey20190326
  ## Update public key information. Note that the only value you can change is the comment.
  ##   Id: string (required)
  ##     : ID of the public key to be updated.
  ##   body: JObject (required)
  var path_21626598 = newJObject()
  var body_21626599 = newJObject()
  add(path_21626598, "Id", newJString(Id))
  if body != nil:
    body_21626599 = body
  result = call_21626597.call(path_21626598, nil, nil, nil, body_21626599)

var updatePublicKey20190326* = Call_UpdatePublicKey20190326_21626583(
    name: "updatePublicKey20190326", meth: HttpMethod.HttpPut,
    host: "cloudfront.amazonaws.com", route: "/2019-03-26/public-key/{Id}/config",
    validator: validate_UpdatePublicKey20190326_21626584, base: "/",
    makeUrl: url_UpdatePublicKey20190326_21626585,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPublicKeyConfig20190326_21626569 = ref object of OpenApiRestCall_21625435
proc url_GetPublicKeyConfig20190326_21626571(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetPublicKeyConfig20190326_21626570(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Return public key configuration informaation
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : Request the ID for the public key configuration.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_21626572 = path.getOrDefault("Id")
  valid_21626572 = validateParameter(valid_21626572, JString, required = true,
                                   default = nil)
  if valid_21626572 != nil:
    section.add "Id", valid_21626572
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626573 = header.getOrDefault("X-Amz-Date")
  valid_21626573 = validateParameter(valid_21626573, JString, required = false,
                                   default = nil)
  if valid_21626573 != nil:
    section.add "X-Amz-Date", valid_21626573
  var valid_21626574 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626574 = validateParameter(valid_21626574, JString, required = false,
                                   default = nil)
  if valid_21626574 != nil:
    section.add "X-Amz-Security-Token", valid_21626574
  var valid_21626575 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626575 = validateParameter(valid_21626575, JString, required = false,
                                   default = nil)
  if valid_21626575 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626575
  var valid_21626576 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626576 = validateParameter(valid_21626576, JString, required = false,
                                   default = nil)
  if valid_21626576 != nil:
    section.add "X-Amz-Algorithm", valid_21626576
  var valid_21626577 = header.getOrDefault("X-Amz-Signature")
  valid_21626577 = validateParameter(valid_21626577, JString, required = false,
                                   default = nil)
  if valid_21626577 != nil:
    section.add "X-Amz-Signature", valid_21626577
  var valid_21626578 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626578 = validateParameter(valid_21626578, JString, required = false,
                                   default = nil)
  if valid_21626578 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626578
  var valid_21626579 = header.getOrDefault("X-Amz-Credential")
  valid_21626579 = validateParameter(valid_21626579, JString, required = false,
                                   default = nil)
  if valid_21626579 != nil:
    section.add "X-Amz-Credential", valid_21626579
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626580: Call_GetPublicKeyConfig20190326_21626569;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Return public key configuration informaation
  ## 
  let valid = call_21626580.validator(path, query, header, formData, body, _)
  let scheme = call_21626580.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626580.makeUrl(scheme.get, call_21626580.host, call_21626580.base,
                               call_21626580.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626580, uri, valid, _)

proc call*(call_21626581: Call_GetPublicKeyConfig20190326_21626569; Id: string): Recallable =
  ## getPublicKeyConfig20190326
  ## Return public key configuration informaation
  ##   Id: string (required)
  ##     : Request the ID for the public key configuration.
  var path_21626582 = newJObject()
  add(path_21626582, "Id", newJString(Id))
  result = call_21626581.call(path_21626582, nil, nil, nil, nil)

var getPublicKeyConfig20190326* = Call_GetPublicKeyConfig20190326_21626569(
    name: "getPublicKeyConfig20190326", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2019-03-26/public-key/{Id}/config",
    validator: validate_GetPublicKeyConfig20190326_21626570, base: "/",
    makeUrl: url_GetPublicKeyConfig20190326_21626571,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateStreamingDistribution20190326_21626614 = ref object of OpenApiRestCall_21625435
proc url_UpdateStreamingDistribution20190326_21626616(protocol: Scheme;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateStreamingDistribution20190326_21626615(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Update a streaming distribution. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The streaming distribution's id.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_21626617 = path.getOrDefault("Id")
  valid_21626617 = validateParameter(valid_21626617, JString, required = true,
                                   default = nil)
  if valid_21626617 != nil:
    section.add "Id", valid_21626617
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the streaming distribution's configuration. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626618 = header.getOrDefault("X-Amz-Date")
  valid_21626618 = validateParameter(valid_21626618, JString, required = false,
                                   default = nil)
  if valid_21626618 != nil:
    section.add "X-Amz-Date", valid_21626618
  var valid_21626619 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626619 = validateParameter(valid_21626619, JString, required = false,
                                   default = nil)
  if valid_21626619 != nil:
    section.add "X-Amz-Security-Token", valid_21626619
  var valid_21626620 = header.getOrDefault("If-Match")
  valid_21626620 = validateParameter(valid_21626620, JString, required = false,
                                   default = nil)
  if valid_21626620 != nil:
    section.add "If-Match", valid_21626620
  var valid_21626621 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626621 = validateParameter(valid_21626621, JString, required = false,
                                   default = nil)
  if valid_21626621 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626621
  var valid_21626622 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626622 = validateParameter(valid_21626622, JString, required = false,
                                   default = nil)
  if valid_21626622 != nil:
    section.add "X-Amz-Algorithm", valid_21626622
  var valid_21626623 = header.getOrDefault("X-Amz-Signature")
  valid_21626623 = validateParameter(valid_21626623, JString, required = false,
                                   default = nil)
  if valid_21626623 != nil:
    section.add "X-Amz-Signature", valid_21626623
  var valid_21626624 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626624 = validateParameter(valid_21626624, JString, required = false,
                                   default = nil)
  if valid_21626624 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626624
  var valid_21626625 = header.getOrDefault("X-Amz-Credential")
  valid_21626625 = validateParameter(valid_21626625, JString, required = false,
                                   default = nil)
  if valid_21626625 != nil:
    section.add "X-Amz-Credential", valid_21626625
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

proc call*(call_21626627: Call_UpdateStreamingDistribution20190326_21626614;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Update a streaming distribution. 
  ## 
  let valid = call_21626627.validator(path, query, header, formData, body, _)
  let scheme = call_21626627.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626627.makeUrl(scheme.get, call_21626627.host, call_21626627.base,
                               call_21626627.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626627, uri, valid, _)

proc call*(call_21626628: Call_UpdateStreamingDistribution20190326_21626614;
          Id: string; body: JsonNode): Recallable =
  ## updateStreamingDistribution20190326
  ## Update a streaming distribution. 
  ##   Id: string (required)
  ##     : The streaming distribution's id.
  ##   body: JObject (required)
  var path_21626629 = newJObject()
  var body_21626630 = newJObject()
  add(path_21626629, "Id", newJString(Id))
  if body != nil:
    body_21626630 = body
  result = call_21626628.call(path_21626629, nil, nil, nil, body_21626630)

var updateStreamingDistribution20190326* = Call_UpdateStreamingDistribution20190326_21626614(
    name: "updateStreamingDistribution20190326", meth: HttpMethod.HttpPut,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/streaming-distribution/{Id}/config",
    validator: validate_UpdateStreamingDistribution20190326_21626615, base: "/",
    makeUrl: url_UpdateStreamingDistribution20190326_21626616,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStreamingDistributionConfig20190326_21626600 = ref object of OpenApiRestCall_21625435
proc url_GetStreamingDistributionConfig20190326_21626602(protocol: Scheme;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetStreamingDistributionConfig20190326_21626601(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Get the configuration information about a streaming distribution. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The streaming distribution's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_21626603 = path.getOrDefault("Id")
  valid_21626603 = validateParameter(valid_21626603, JString, required = true,
                                   default = nil)
  if valid_21626603 != nil:
    section.add "Id", valid_21626603
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626604 = header.getOrDefault("X-Amz-Date")
  valid_21626604 = validateParameter(valid_21626604, JString, required = false,
                                   default = nil)
  if valid_21626604 != nil:
    section.add "X-Amz-Date", valid_21626604
  var valid_21626605 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626605 = validateParameter(valid_21626605, JString, required = false,
                                   default = nil)
  if valid_21626605 != nil:
    section.add "X-Amz-Security-Token", valid_21626605
  var valid_21626606 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626606 = validateParameter(valid_21626606, JString, required = false,
                                   default = nil)
  if valid_21626606 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626606
  var valid_21626607 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626607 = validateParameter(valid_21626607, JString, required = false,
                                   default = nil)
  if valid_21626607 != nil:
    section.add "X-Amz-Algorithm", valid_21626607
  var valid_21626608 = header.getOrDefault("X-Amz-Signature")
  valid_21626608 = validateParameter(valid_21626608, JString, required = false,
                                   default = nil)
  if valid_21626608 != nil:
    section.add "X-Amz-Signature", valid_21626608
  var valid_21626609 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626609 = validateParameter(valid_21626609, JString, required = false,
                                   default = nil)
  if valid_21626609 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626609
  var valid_21626610 = header.getOrDefault("X-Amz-Credential")
  valid_21626610 = validateParameter(valid_21626610, JString, required = false,
                                   default = nil)
  if valid_21626610 != nil:
    section.add "X-Amz-Credential", valid_21626610
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626611: Call_GetStreamingDistributionConfig20190326_21626600;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Get the configuration information about a streaming distribution. 
  ## 
  let valid = call_21626611.validator(path, query, header, formData, body, _)
  let scheme = call_21626611.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626611.makeUrl(scheme.get, call_21626611.host, call_21626611.base,
                               call_21626611.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626611, uri, valid, _)

proc call*(call_21626612: Call_GetStreamingDistributionConfig20190326_21626600;
          Id: string): Recallable =
  ## getStreamingDistributionConfig20190326
  ## Get the configuration information about a streaming distribution. 
  ##   Id: string (required)
  ##     : The streaming distribution's ID.
  var path_21626613 = newJObject()
  add(path_21626613, "Id", newJString(Id))
  result = call_21626612.call(path_21626613, nil, nil, nil, nil)

var getStreamingDistributionConfig20190326* = Call_GetStreamingDistributionConfig20190326_21626600(
    name: "getStreamingDistributionConfig20190326", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/streaming-distribution/{Id}/config",
    validator: validate_GetStreamingDistributionConfig20190326_21626601,
    base: "/", makeUrl: url_GetStreamingDistributionConfig20190326_21626602,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDistributionsByWebACLId20190326_21626631 = ref object of OpenApiRestCall_21625435
proc url_ListDistributionsByWebACLId20190326_21626633(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDistributionsByWebACLId20190326_21626632(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## List the distributions that are associated with a specified AWS WAF web ACL. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   WebACLId: JString (required)
  ##           : The ID of the AWS WAF web ACL that you want to list the associated distributions. If you specify "null" for the ID, the request returns a list of the distributions that aren't associated with a web ACL. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `WebACLId` field"
  var valid_21626634 = path.getOrDefault("WebACLId")
  valid_21626634 = validateParameter(valid_21626634, JString, required = true,
                                   default = nil)
  if valid_21626634 != nil:
    section.add "WebACLId", valid_21626634
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Use <code>Marker</code> and <code>MaxItems</code> to control pagination of results. If you have more than <code>MaxItems</code> distributions that satisfy the request, the response includes a <code>NextMarker</code> element. To get the next page of results, submit another request. For the value of <code>Marker</code>, specify the value of <code>NextMarker</code> from the last response. (For the first request, omit <code>Marker</code>.) 
  ##   MaxItems: JString
  ##           : The maximum number of distributions that you want CloudFront to return in the response body. The maximum and default values are both 100.
  section = newJObject()
  var valid_21626635 = query.getOrDefault("Marker")
  valid_21626635 = validateParameter(valid_21626635, JString, required = false,
                                   default = nil)
  if valid_21626635 != nil:
    section.add "Marker", valid_21626635
  var valid_21626636 = query.getOrDefault("MaxItems")
  valid_21626636 = validateParameter(valid_21626636, JString, required = false,
                                   default = nil)
  if valid_21626636 != nil:
    section.add "MaxItems", valid_21626636
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626637 = header.getOrDefault("X-Amz-Date")
  valid_21626637 = validateParameter(valid_21626637, JString, required = false,
                                   default = nil)
  if valid_21626637 != nil:
    section.add "X-Amz-Date", valid_21626637
  var valid_21626638 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626638 = validateParameter(valid_21626638, JString, required = false,
                                   default = nil)
  if valid_21626638 != nil:
    section.add "X-Amz-Security-Token", valid_21626638
  var valid_21626639 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626639 = validateParameter(valid_21626639, JString, required = false,
                                   default = nil)
  if valid_21626639 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626639
  var valid_21626640 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626640 = validateParameter(valid_21626640, JString, required = false,
                                   default = nil)
  if valid_21626640 != nil:
    section.add "X-Amz-Algorithm", valid_21626640
  var valid_21626641 = header.getOrDefault("X-Amz-Signature")
  valid_21626641 = validateParameter(valid_21626641, JString, required = false,
                                   default = nil)
  if valid_21626641 != nil:
    section.add "X-Amz-Signature", valid_21626641
  var valid_21626642 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626642 = validateParameter(valid_21626642, JString, required = false,
                                   default = nil)
  if valid_21626642 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626642
  var valid_21626643 = header.getOrDefault("X-Amz-Credential")
  valid_21626643 = validateParameter(valid_21626643, JString, required = false,
                                   default = nil)
  if valid_21626643 != nil:
    section.add "X-Amz-Credential", valid_21626643
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626644: Call_ListDistributionsByWebACLId20190326_21626631;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## List the distributions that are associated with a specified AWS WAF web ACL. 
  ## 
  let valid = call_21626644.validator(path, query, header, formData, body, _)
  let scheme = call_21626644.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626644.makeUrl(scheme.get, call_21626644.host, call_21626644.base,
                               call_21626644.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626644, uri, valid, _)

proc call*(call_21626645: Call_ListDistributionsByWebACLId20190326_21626631;
          WebACLId: string; Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listDistributionsByWebACLId20190326
  ## List the distributions that are associated with a specified AWS WAF web ACL. 
  ##   Marker: string
  ##         : Use <code>Marker</code> and <code>MaxItems</code> to control pagination of results. If you have more than <code>MaxItems</code> distributions that satisfy the request, the response includes a <code>NextMarker</code> element. To get the next page of results, submit another request. For the value of <code>Marker</code>, specify the value of <code>NextMarker</code> from the last response. (For the first request, omit <code>Marker</code>.) 
  ##   MaxItems: string
  ##           : The maximum number of distributions that you want CloudFront to return in the response body. The maximum and default values are both 100.
  ##   WebACLId: string (required)
  ##           : The ID of the AWS WAF web ACL that you want to list the associated distributions. If you specify "null" for the ID, the request returns a list of the distributions that aren't associated with a web ACL. 
  var path_21626646 = newJObject()
  var query_21626647 = newJObject()
  add(query_21626647, "Marker", newJString(Marker))
  add(query_21626647, "MaxItems", newJString(MaxItems))
  add(path_21626646, "WebACLId", newJString(WebACLId))
  result = call_21626645.call(path_21626646, query_21626647, nil, nil, nil)

var listDistributionsByWebACLId20190326* = Call_ListDistributionsByWebACLId20190326_21626631(
    name: "listDistributionsByWebACLId20190326", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/distributionsByWebACLId/{WebACLId}",
    validator: validate_ListDistributionsByWebACLId20190326_21626632, base: "/",
    makeUrl: url_ListDistributionsByWebACLId20190326_21626633,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource20190326_21626648 = ref object of OpenApiRestCall_21625435
proc url_ListTagsForResource20190326_21626650(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource20190326_21626649(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626651 = query.getOrDefault("Resource")
  valid_21626651 = validateParameter(valid_21626651, JString, required = true,
                                   default = nil)
  if valid_21626651 != nil:
    section.add "Resource", valid_21626651
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626652 = header.getOrDefault("X-Amz-Date")
  valid_21626652 = validateParameter(valid_21626652, JString, required = false,
                                   default = nil)
  if valid_21626652 != nil:
    section.add "X-Amz-Date", valid_21626652
  var valid_21626653 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626653 = validateParameter(valid_21626653, JString, required = false,
                                   default = nil)
  if valid_21626653 != nil:
    section.add "X-Amz-Security-Token", valid_21626653
  var valid_21626654 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626654 = validateParameter(valid_21626654, JString, required = false,
                                   default = nil)
  if valid_21626654 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626654
  var valid_21626655 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626655 = validateParameter(valid_21626655, JString, required = false,
                                   default = nil)
  if valid_21626655 != nil:
    section.add "X-Amz-Algorithm", valid_21626655
  var valid_21626656 = header.getOrDefault("X-Amz-Signature")
  valid_21626656 = validateParameter(valid_21626656, JString, required = false,
                                   default = nil)
  if valid_21626656 != nil:
    section.add "X-Amz-Signature", valid_21626656
  var valid_21626657 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626657 = validateParameter(valid_21626657, JString, required = false,
                                   default = nil)
  if valid_21626657 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626657
  var valid_21626658 = header.getOrDefault("X-Amz-Credential")
  valid_21626658 = validateParameter(valid_21626658, JString, required = false,
                                   default = nil)
  if valid_21626658 != nil:
    section.add "X-Amz-Credential", valid_21626658
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626659: Call_ListTagsForResource20190326_21626648;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## List tags for a CloudFront resource.
  ## 
  let valid = call_21626659.validator(path, query, header, formData, body, _)
  let scheme = call_21626659.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626659.makeUrl(scheme.get, call_21626659.host, call_21626659.base,
                               call_21626659.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626659, uri, valid, _)

proc call*(call_21626660: Call_ListTagsForResource20190326_21626648;
          Resource: string): Recallable =
  ## listTagsForResource20190326
  ## List tags for a CloudFront resource.
  ##   Resource: string (required)
  ##           :  An ARN of a CloudFront resource.
  var query_21626661 = newJObject()
  add(query_21626661, "Resource", newJString(Resource))
  result = call_21626660.call(nil, query_21626661, nil, nil, nil)

var listTagsForResource20190326* = Call_ListTagsForResource20190326_21626648(
    name: "listTagsForResource20190326", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2019-03-26/tagging#Resource",
    validator: validate_ListTagsForResource20190326_21626649, base: "/",
    makeUrl: url_ListTagsForResource20190326_21626650,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource20190326_21626662 = ref object of OpenApiRestCall_21625435
proc url_TagResource20190326_21626664(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource20190326_21626663(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626665 = query.getOrDefault("Resource")
  valid_21626665 = validateParameter(valid_21626665, JString, required = true,
                                   default = nil)
  if valid_21626665 != nil:
    section.add "Resource", valid_21626665
  var valid_21626680 = query.getOrDefault("Operation")
  valid_21626680 = validateParameter(valid_21626680, JString, required = true,
                                   default = newJString("Tag"))
  if valid_21626680 != nil:
    section.add "Operation", valid_21626680
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626681 = header.getOrDefault("X-Amz-Date")
  valid_21626681 = validateParameter(valid_21626681, JString, required = false,
                                   default = nil)
  if valid_21626681 != nil:
    section.add "X-Amz-Date", valid_21626681
  var valid_21626682 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626682 = validateParameter(valid_21626682, JString, required = false,
                                   default = nil)
  if valid_21626682 != nil:
    section.add "X-Amz-Security-Token", valid_21626682
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

proc call*(call_21626689: Call_TagResource20190326_21626662; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Add tags to a CloudFront resource.
  ## 
  let valid = call_21626689.validator(path, query, header, formData, body, _)
  let scheme = call_21626689.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626689.makeUrl(scheme.get, call_21626689.host, call_21626689.base,
                               call_21626689.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626689, uri, valid, _)

proc call*(call_21626690: Call_TagResource20190326_21626662; Resource: string;
          body: JsonNode; Operation: string = "Tag"): Recallable =
  ## tagResource20190326
  ## Add tags to a CloudFront resource.
  ##   Resource: string (required)
  ##           :  An ARN of a CloudFront resource.
  ##   Operation: string (required)
  ##   body: JObject (required)
  var query_21626691 = newJObject()
  var body_21626692 = newJObject()
  add(query_21626691, "Resource", newJString(Resource))
  add(query_21626691, "Operation", newJString(Operation))
  if body != nil:
    body_21626692 = body
  result = call_21626690.call(nil, query_21626691, nil, nil, body_21626692)

var tagResource20190326* = Call_TagResource20190326_21626662(
    name: "tagResource20190326", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/tagging#Operation=Tag&Resource",
    validator: validate_TagResource20190326_21626663, base: "/",
    makeUrl: url_TagResource20190326_21626664,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource20190326_21626694 = ref object of OpenApiRestCall_21625435
proc url_UntagResource20190326_21626696(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource20190326_21626695(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626697 = query.getOrDefault("Resource")
  valid_21626697 = validateParameter(valid_21626697, JString, required = true,
                                   default = nil)
  if valid_21626697 != nil:
    section.add "Resource", valid_21626697
  var valid_21626698 = query.getOrDefault("Operation")
  valid_21626698 = validateParameter(valid_21626698, JString, required = true,
                                   default = newJString("Untag"))
  if valid_21626698 != nil:
    section.add "Operation", valid_21626698
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626699 = header.getOrDefault("X-Amz-Date")
  valid_21626699 = validateParameter(valid_21626699, JString, required = false,
                                   default = nil)
  if valid_21626699 != nil:
    section.add "X-Amz-Date", valid_21626699
  var valid_21626700 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626700 = validateParameter(valid_21626700, JString, required = false,
                                   default = nil)
  if valid_21626700 != nil:
    section.add "X-Amz-Security-Token", valid_21626700
  var valid_21626701 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626701 = validateParameter(valid_21626701, JString, required = false,
                                   default = nil)
  if valid_21626701 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626701
  var valid_21626702 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626702 = validateParameter(valid_21626702, JString, required = false,
                                   default = nil)
  if valid_21626702 != nil:
    section.add "X-Amz-Algorithm", valid_21626702
  var valid_21626703 = header.getOrDefault("X-Amz-Signature")
  valid_21626703 = validateParameter(valid_21626703, JString, required = false,
                                   default = nil)
  if valid_21626703 != nil:
    section.add "X-Amz-Signature", valid_21626703
  var valid_21626704 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626704 = validateParameter(valid_21626704, JString, required = false,
                                   default = nil)
  if valid_21626704 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626704
  var valid_21626705 = header.getOrDefault("X-Amz-Credential")
  valid_21626705 = validateParameter(valid_21626705, JString, required = false,
                                   default = nil)
  if valid_21626705 != nil:
    section.add "X-Amz-Credential", valid_21626705
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

proc call*(call_21626707: Call_UntagResource20190326_21626694;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Remove tags from a CloudFront resource.
  ## 
  let valid = call_21626707.validator(path, query, header, formData, body, _)
  let scheme = call_21626707.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626707.makeUrl(scheme.get, call_21626707.host, call_21626707.base,
                               call_21626707.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626707, uri, valid, _)

proc call*(call_21626708: Call_UntagResource20190326_21626694; Resource: string;
          body: JsonNode; Operation: string = "Untag"): Recallable =
  ## untagResource20190326
  ## Remove tags from a CloudFront resource.
  ##   Resource: string (required)
  ##           :  An ARN of a CloudFront resource.
  ##   Operation: string (required)
  ##   body: JObject (required)
  var query_21626709 = newJObject()
  var body_21626710 = newJObject()
  add(query_21626709, "Resource", newJString(Resource))
  add(query_21626709, "Operation", newJString(Operation))
  if body != nil:
    body_21626710 = body
  result = call_21626708.call(nil, query_21626709, nil, nil, body_21626710)

var untagResource20190326* = Call_UntagResource20190326_21626694(
    name: "untagResource20190326", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/tagging#Operation=Untag&Resource",
    validator: validate_UntagResource20190326_21626695, base: "/",
    makeUrl: url_UntagResource20190326_21626696,
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